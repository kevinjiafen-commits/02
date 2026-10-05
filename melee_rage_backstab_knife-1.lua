--[[
    KICIA REBUILD — Extreme Melee Rage / Always Backstab / Knife Rage
    Self-contained extraction  (tbl17 removed, v86 constants inlined)

    Blocks:
      AlwaysBackstab   — di
      FighterState     — jy
      DefensiveCFrame  — jz
      ShootLock        — jA
      TargetSelection  — jB
      LookAtCFrame     — jC
      HitscanMelee     — jD   (non-Knife ragebot planner)
      KnifeMelee       — jE   (Knife rage + backstab planner)  ← core
      Ragebot          — jO   (full orchestrator)

    v86 constants used (all inlined below):
      [9]   = 20        SendViewAngles low-priority
      [18]  = "0"       DFIntAssemblyHistorySkipSize off value
      [34]  = true      ShouldSkipDefense / boolean true
      [45]  = 90        pitch 90° (looking up)
      [63]  = 1         integer 1 / unit
      [75]  = "None"    default FighterState string
      [133] = 10        SendViewAngles backstab priority
      [153] = false     boolean false (HasTargets default)
      [186] = 0         zero constant
      [195] = 0.7       jE vector Y offset

    Usage:
      local Mods = require(this_module)   -- or loadstring/dofile
      local AlwaysBackstab = Mods.AlwaysBackstab   -- di
      local KnifeStrategy  = Mods.KnifeStrategy    -- jE
      local Ragebot        = Mods.Ragebot           -- jO
      -- Wire them into KiciaRebuild's Heartbeat / combat context.
--]]

local Modules = {}

-- ============================================================
--  ShootLock  (jA)
--  Fire-rate gate: locks for ShootFrames * delta after each shot.
-- ============================================================
local ShootLock = {}
ShootLock.__index = ShootLock

function ShootLock.new()
    return setmetatable({}, ShootLock)
end

function ShootLock:ShouldFire(shouldFire, lockDuration)
    local now = os.clock()
    local lockedUntil = self._lockedUntil
    local isLocked = lockedUntil ~= nil and now < lockedUntil

    if shouldFire then
        self._lockedUntil = now + lockDuration
    end

    return isLocked or shouldFire
end

function ShootLock:Reset()
    self._lockedUntil = nil
end

Modules.ShootLock = ShootLock

-- ============================================================
--  FighterState helper  (jy)
--  Returns "Above" / "Below" based on Riot Shield orientation.
--  Used by melee planners to pick the correct hitbox offset.
-- ============================================================
local function getFighterVerticalState(fighterState)
    local itemObserver = fighterState.ItemObserver
    local equippedItem = itemObserver:GetEquippedItem()

    if equippedItem ~= nil and equippedItem.Name == "Riot Shield" then
        local pitch = math.deg(fighterState:GetCameraRotation().X)
        if pitch > 22 and pitch < 91 then
            return "Below"
        end
        return "Above"
    end

    for _, item in itemObserver:GetItems() do
        if item.Name == "Riot Shield" then
            local pitch = math.deg(fighterState:GetCameraRotation().X)
            if pitch > 315 and pitch < 360 or pitch > 0 and pitch < 91 then
                return "Above"
            end
            return "Below"
        end
    end

    return "None"   -- v86[75]
end

Modules.getFighterVerticalState = getFighterVerticalState

-- ============================================================
--  DefensiveCFrame helper  (jz)
--  Returns defensive position / view-angles during ragebot evasion.
--  Knife gets a full-random CFrame so server cannot predict backstab direction.
-- ============================================================
local _jzRng = Random.new()

local DefensiveCFrame = {}

function DefensiveCFrame.getDefensiveCFrame(cframe, shieldState, fighterState, enemyRootPart)
    if shieldState == "Equipped" then
        return CFrame.new(cframe.Position, enemyRootPart.Position)
    end

    if shieldState == "Unequipped" then
        local pos = cframe.Position
        return CFrame.new(pos, pos + pos - enemyRootPart.Position)
    end

    local meleItem = fighterState.ItemObserver:EquippedItemAsMelee()
    if meleItem ~= nil and meleItem.Name == "Knife" then
        -- Full random orientation — no angle leaks to server
        local tau = math.pi * 2
        return CFrame.new(cframe.Position)
            * CFrame.fromOrientation(
                _jzRng:NextNumber(0, tau),
                _jzRng:NextNumber(0, tau),
                _jzRng:NextNumber(0, tau)
            )
    end

    return cframe
end

function DefensiveCFrame.getDefensiveViewAngles(shieldState, fighterState)
    if shieldState == "None" then
        return nil
    end

    return {
        Kind  = "Normalized",
        Pitch = (shieldState == "Equipped") ~= (getFighterVerticalState(fighterState) ~= "Below")
                    and 90      -- v86[45]
                    or -90,
        Yaw   = _jzRng:NextNumber(0, 360),
    }
end

Modules.DefensiveCFrame = DefensiveCFrame

-- ============================================================
--  LookAt CFrame (XZ plane only)  (jC)
--  Returns CFrame at `from` looking toward `to`, Y-axis flat.
-- ============================================================
local _jCup  = Vector3.new(0, -1, 0)   -- v86[63] = 1
local _jCfwd = Vector3.new(0, 0, -1)

local function lookAtFlat(from, to)
    local delta = to - from
    local flat  = Vector3.new(delta.X, 0, delta.Z)   -- v86[186] = 0

    if flat.Magnitude < 0.001 then
        flat = _jCfwd
    end

    return CFrame.lookAt(from, from + flat, _jCup)
end

Modules.lookAtFlat = lookAtFlat

-- ============================================================
--  TargetSelection  (jB)
--  Iterates EnemyByPlayer; skips invincible / dead / deflecting.
--  Optionally prioritises players tagged "Hacker".
-- ============================================================
local TargetSelection = {}
TargetSelection.__index = TargetSelection

function TargetSelection.new(fighters, playerTags)
    return setmetatable({ _fighters = fighters, _playerTags = playerTags }, TargetSelection)
end

local function _isValidTarget(fighter)
    if not fighter.IsEnemy or fighter:IsInvincible() then return false end
    if not fighter.Character.State.Alive then return false end
    local melee = fighter.ItemObserver:EquippedItemAsMelee()
    if melee ~= nil and melee:IsDeflecting() then return false end
    return true
end

local function _wrapTarget(fighter)
    return { FighterState = fighter, AliveState = fighter.Character.State }
end

function TargetSelection:GetTarget()
    local prioritize = _store.Data.Ragebot.PrioritizeHackers

    if prioritize and self._playerTags then
        for _, player in self._playerTags:GetPlayersWith("Hacker") do
            local state = self._fighters.StateByPlayer[player]
            if state ~= nil and _isValidTarget(state) then
                return _wrapTarget(state)
            end
        end
    end

    for player, fighter in self._fighters.EnemyByPlayer do
        if prioritize and self._playerTags and self._playerTags:Has(player, "Hacker") then
            continue
        end
        if _isValidTarget(fighter) then
            return _wrapTarget(fighter)
        end
    end

    return nil
end

function TargetSelection:HasTargets()
    for _, fighter in self._fighters.EnemyByPlayer do
        if _isValidTarget(fighter) then return true end
    end
    return false    -- v86[153]
end

function TargetSelection:IsSameTarget(a, b)
    return a.FighterState == b.FighterState and a.AliveState == b.AliveState
end

Modules.TargetSelection = TargetSelection

-- ============================================================
--  HitscanMelee strategy  (jD)  — non-Knife melee ragebot planner
--  Plan() → server CFrame + ShootEncoded callback.
-- ============================================================
local _jD_vec1 = Vector3.new(0, -0.7,  0.05)
local _jD_vec2 = Vector3.new(0, -3.85, 0.05)

-- Encoded angle payloads (server-side attack packets)
local _jD_tbl18 = { ["\0"]=-9e37, ["\1"]=0,         ["\2"]=0,   ["\3"]=-math.pi/2, ["\4"]=math.pi, ["\5"]=math.pi }
local _jD_tbl19 = { ["\0"]=0,     ["\1"]=-90000000,  ["\2"]=0,   ["\3"]=-math.pi/2, ["\4"]=math.pi, ["\5"]=math.pi }
local _jD_tbl20 = { ["\0"]=-9e37, ["\1"]=0,          ["\2"]=0,   ["\3"]=math.pi/2,  ["\4"]=math.pi, ["\5"]=math.pi }
local _jD_tbl21 = { ["\0"]=0,     ["\1"]=90000000,   ["\2"]=0,   ["\3"]=math.pi/2,  ["\4"]=math.pi, ["\5"]=math.pi }
local _jD_tbl22 = { ["\0"]=0,     ["\1"]=1,          ["\2"]=0,   ["\3"]=0,          ["\4"]=0,       ["\5"]=0       }

local function _encodeAngles(base, pitch, yaw, roll)
    return {
        ["\0"]=base["\0"], ["\1"]=base["\1"], ["\2"]=base["\2"],
        ["\3"]=pitch, ["\4"]=yaw, ["\5"]=roll,
    }
end

local HitscanMelee = {}
HitscanMelee.__index = HitscanMelee

-- `partGlue` is the PartGlue service passed in from jO
function HitscanMelee.new(partGlue)
    return setmetatable({ _partGlue = partGlue, _shootLock = ShootLock.new() }, HitscanMelee)
end

function HitscanMelee:Plan(delta, target, item, ourPart, canFire)
    local aliveState  = target.AliveState
    local hitboxHead  = aliveState.HitboxHead
    local isAbove     = getFighterVerticalState(target.FighterState) ~= "Below"
    local ragebot     = _store.Data.Ragebot
    local offset      = isAbove and _jD_vec1 or _jD_vec2
    local glued       = self._partGlue:Acquire(ourPart, hitboxHead)
    local targetCF

    if isAbove then
        targetCF = glued + offset
    else
        targetCF = lookAtFlat(glued.Position + offset, hitboxHead.Position)
    end

    if not self._shootLock:ShouldFire(canFire, delta * ragebot.ShootFrames) then
        return CFrame.new(
            math.random(-1000000, 1000000),
            math.random(5000, 10000),
            math.random(-1000000, 1000000)
        ), nil
    end

    local pitch = isAbove and -math.pi/2 or math.pi/2
    local left  = isAbove and _jD_tbl18 or _jD_tbl20
    local right = isAbove and _jD_tbl19 or _jD_tbl21

    return targetCF, function()
        item:ShootEncoded(
            _encodeAngles(left,  pitch, 0, 0),
            _encodeAngles(right, pitch, 0, 0),
            hitboxHead,
            _jD_tbl22
        )
    end
end

Modules.HitscanMelee = HitscanMelee

-- ============================================================
--  KnifeStrategy  (jE)  — EXTREME MELEE RAGE / KNIFE RAGE
--
--  Plan() flow:
--    1. Inside 0.625 s backstab window → keep HeavyAttackEncoded
--    2. ShootLock gate (ShootFrames throttle)
--    3. Attack cooldown gate (1.25 s post-backstab debounce)
--    4. Knife → _RecordBackstab() + HeavyAttackEncoded (guaranteed backstab)
--    5. Other melee → standard AttackEncoded
--
--  _RecordBackstab:
--    _hitboxWindowUntil = now + 0.625  (keep spamming HeavyAttack)
--    _attackCooldown    = now + 1.25   (debounce)
-- ============================================================
local _jE_vec1 = Vector3.new(0, -0.7,  0.05)   -- v86[195] = 0.7
local _jE_vec2 = Vector3.new(0, -3.85, 0.05)

local _jE_tbl18 = { ["\0"]=-9e37, ["\1"]=0,        ["\2"]=0,   ["\3"]=-math.pi/2, ["\4"]=math.pi, ["\5"]=math.pi }
local _jE_tbl19 = { ["\0"]=0,     ["\1"]=-90000000, ["\2"]=0,   ["\3"]=-math.pi/2, ["\4"]=math.pi, ["\5"]=math.pi }
local _jE_tbl20 = { ["\0"]=-9e37, ["\1"]=0,         ["\2"]=0,   ["\3"]=math.pi/2,  ["\4"]=math.pi, ["\5"]=math.pi }
local _jE_tbl21 = { ["\0"]=0,     ["\1"]=90000000,  ["\2"]=0,   ["\3"]=math.pi/2,  ["\4"]=math.pi, ["\5"]=math.pi }
local _jE_tbl22 = { ["\0"]=0,     ["\1"]=1,          ["\2"]=0,  ["\3"]=0,          ["\4"]=0,       ["\5"]=0       }

local function _jE_encodeAngles(base, pitch, yaw, roll)
    return {
        ["\0"]=base["\0"], ["\1"]=base["\1"], ["\2"]=base["\2"],
        ["\3"]=pitch, ["\4"]=yaw, ["\5"]=roll,
    }
end

local function _jE_missShot()
    return CFrame.new(
        math.random(-10000000, -100000),
        math.random(5000, 10000),
        math.random(-10000000, -100000)
    )
end

local KnifeStrategy = {}
KnifeStrategy.__index = KnifeStrategy

function KnifeStrategy.new(partGlue)
    return setmetatable({
        _partGlue          = partGlue,
        _shootLock         = ShootLock.new(),
        _hitboxWindowUntil = -1,
        _attackCooldown    = -1,
        _gluedOurPart      = nil,
    }, KnifeStrategy)
end

function KnifeStrategy:Plan(delta, target, item, ourPart, canFire)
    local aliveState = target.AliveState
    local hitboxHead = aliveState.HitboxHead
    local isAbove    = getFighterVerticalState(target.FighterState) ~= "Below"
    local ragebot    = _store.Data.Ragebot
    local offset     = isAbove and _jE_vec1 or _jE_vec2
    local glued      = self._partGlue:Acquire(ourPart, hitboxHead)
    self._gluedOurPart = ourPart

    local targetCF
    if isAbove then
        targetCF = glued + offset
    else
        targetCF = lookAtFlat(glued.Position + offset, hitboxHead.Position)
    end

    local rx, ry, rz = aliveState.RootPart.CFrame:ToOrientation()
    local pitch      = isAbove and -math.pi/2 or math.pi/2
    local leftBase   = isAbove and _jE_tbl18 or _jE_tbl20
    local rightBase  = isAbove and _jE_tbl19 or _jE_tbl21
    local leftPkt    = _jE_encodeAngles(leftBase,  pitch, ry, rz)
    local rightPkt   = _jE_encodeAngles(rightBase, pitch, ry, rz)
    local viewAngles = { Kind = "Normalized", Pitch = math.deg(rx), Yaw = math.deg(ry) }
    local now        = os.clock()

    -- [1] Still inside backstab hitbox window → spam HeavyAttack
    if now < self._hitboxWindowUntil then
        return targetCF, viewAngles, function()
            item:HeavyAttackEncoded(leftPkt, rightPkt, hitboxHead, _jE_tbl22)
        end
    end

    -- [2] ShootLock gate
    if not self._shootLock:ShouldFire(canFire, delta * ragebot.ShootFrames) then
        return _jE_missShot(), nil, nil
    end

    -- [3] Attack cooldown gate (post-backstab debounce)
    if now < self._attackCooldown then
        return _jE_missShot(), nil, nil
    end

    -- [4] Knife → guaranteed backstab via HeavyAttackEncoded
    if item.Name == "Knife" then
        self:_RecordBackstab()
        return targetCF, viewAngles, function()
            item:HeavyAttackEncoded(leftPkt, rightPkt, hitboxHead, _jE_tbl22)
        end
    end

    -- [5] Other melee → standard AttackEncoded
    return targetCF, nil, function()
        item:AttackEncoded(leftPkt, rightPkt, hitboxHead, _jE_tbl22)
    end
end

-- Sets 0.625 s hitbox window and 1.25 s cooldown after a backstab hit
function KnifeStrategy:_RecordBackstab()
    local now = os.clock()
    self._hitboxWindowUntil = now + 0.625
    self._attackCooldown    = now + 1.25
end

function KnifeStrategy:ResetState()
    self._hitboxWindowUntil = -1
    self._attackCooldown    = -1
    self._shootLock:Reset()
    if self._gluedOurPart ~= nil then
        self._partGlue:Free(self._gluedOurPart)
        self._gluedOurPart = nil
    end
end

Modules.KnifeStrategy = KnifeStrategy

-- ============================================================
--  AlwaysBackstab  (di)
--  Tracks closest enemy ≤20 studs and spoofs server view-angles
--  so every Knife swing registers as a backstab hit.
--  Activated by: store.Data.ItemModifiers.AlwaysBackstab = true
-- ============================================================
local AlwaysBackstab = {}
AlwaysBackstab.__index = AlwaysBackstab

-- `playerContext` — the player's combat context (ObserveContext source)
-- `fighters`      — fighters registry (EnemyByPlayer)
-- `store`         — the reactive config store (store.Data.ItemModifiers...)
function AlwaysBackstab.new(playerContext, fighters, store)
    local self = setmetatable({
        _innerContext = nil,
        _fighters     = fighters,
        _store        = store,
        _connections  = {},
    }, AlwaysBackstab)
    self:_Initialize(playerContext)
    return self
end

function AlwaysBackstab:_Initialize(playerContext)
    -- Subscribe to the "always_backstab" combat context
    table.insert(self._connections,
        playerContext:ObserveContext("always_backstab", function(ctx)
            self._innerContext = ctx
        end)
    )
    table.insert(self._connections,
        playerContext.ContextRemoved:Connect(function()
            self._innerContext = nil
        end)
    )
end

-- Call this every Heartbeat
function AlwaysBackstab:Update()
    local ctx = self._innerContext
    if ctx == nil then return end
    if not self._store.Data.ItemModifiers.AlwaysBackstab then return end

    -- Only active with Knife equipped
    if ctx.ItemBehaviors:FindMeleeByName("Knife") == nil then return end

    local charCtrl        = ctx.CharacterController
    local serverHeadOrigin = charCtrl:GetServerHeadOrigin()

    if serverHeadOrigin == nil then
        charCtrl:SendViewAngles(10, nil)   -- v86[133] = 10
        return
    end

    local enemy = self:_FindClosestEnemy(serverHeadOrigin.Position)
    if enemy == nil then
        charCtrl:SendViewAngles(10, nil)   -- v86[133]
        return
    end

    -- Spoof view to face AWAY from enemy → backstab on every swing
    local rx, ry = enemy.CFrame:ToOrientation()
    charCtrl:SendViewAngles(10, {
        Kind  = "Normalized",
        Pitch = math.deg(rx),
        Yaw   = math.deg(ry),
    })
end

function AlwaysBackstab:_FindClosestEnemy(origin)
    local best = math.huge
    local found

    for _, fighter in self._fighters.EnemyByPlayer do
        local state = fighter.Character.State
        if state.Alive then
            local dist = (state.RootPart.Position - origin).Magnitude
            if dist < 20 and dist < best then
                best  = dist
                found = state.RootPart
            end
        end
    end

    return found
end

function AlwaysBackstab:Destroy()
    for _, c in self._connections do
        if type(c) == "table" and c.Disconnect then
            pcall(c.Disconnect, c)
        elseif typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
    end
    self._connections = {}
    self._innerContext = nil
end

Modules.AlwaysBackstab = AlwaysBackstab

-- ============================================================
--  Ragebot orchestrator  (jO)
--  Wires TargetSelection, HitscanMelee (jD), KnifeStrategy (jE),
--  DefensiveCFrame (jz), and ProjectileBreaker evasion.
--
--  Key dispatch:
--    Gun  equipped → _hitscanStrategy:Plan()
--    Melee equipped → _meleeStrategy:Plan()   ← KnifeStrategy (jE)
--    No target      → _evade()
--    Reload needed  → _planReloadTransport()
-- ============================================================
local Ragebot = {}
Ragebot.__index = Ragebot

--[[
  Dependencies (all passed in via .new()):
    fighters         — fighters registry
    playerTags       — player tags (for PrioritizeHackers)
    playerContext    — the local player's combat context
    stateHook        — forced-crouch hook
    partGlue         — PartGlue service
    store            — reactive config store
    keybindObserver  — ObserveEnabledKeybind source
    evasionCompute   — evasion CFrame compute function
    projectileBreaker — ProjectileBreaker teleport controller
    immune           — function() → immune CFrame
    replicationUtils — {getEstimatedReplicationDelay, getEstimatedRemoteDelay}
    spatialLimitGate — Tick(part) → bool (returns true if outside limit)
    actionGetter     — getAction(context) → current action or nil
    shieldStateGetter — (itemBehaviors) → "None"/"Equipped"/"Unequipped"
--]]
function Ragebot.new(deps)
    local self = setmetatable({
        _enabled              = false,
        _innerContext         = nil,
        _lastTargetWorld      = nil,
        _lastDefViewAngles    = nil,
        _targetSelection      = TargetSelection.new(deps.fighters, deps.playerTags),
        _hitscanStrategy      = HitscanMelee.new(deps.partGlue),
        _meleeStrategy        = KnifeStrategy.new(deps.partGlue),
        _spatialLimitGate     = deps.spatialLimitGate,
        _stateHook            = deps.stateHook,
        _projectileBreaker    = deps.projectileBreaker,
        _evasionCompute       = deps.evasionCompute,
        _immune               = deps.immune,
        _repl                 = deps.replicationUtils,
        _actionGetter         = deps.actionGetter,
        _shieldStateGetter    = deps.shieldStateGetter,
        _store                = deps.store,
        _reloadGun            = nil,
        _reloadReadyAt        = nil,
        _reloadAcknDdl        = nil,
        _pendingDepletionAmmo = nil,
        _connections          = {},
    }, Ragebot)
    self:_initialize(deps.playerContext, deps.keybindObserver)
    return self
end

function Ragebot:_initialize(playerContext, keybindObserver)
    table.insert(self._connections,
        playerContext:ObserveContext("ragebot", function(ctx)
            self._innerContext = ctx
            self:_clearReloadTransport()
        end)
    )
    table.insert(self._connections,
        playerContext.ContextRemoved:Connect(function()
            self:_reset()
            self._innerContext = nil
        end)
    )
    if keybindObserver then
        table.insert(self._connections,
            keybindObserver:ObserveEnabledKeybind({"Ragebot"}, function(enabled)
                self:SetEnabled(enabled)
                self:_reset()
            end)
        )
    end
end

function Ragebot:SetEnabled(enabled)
    if self._enabled == enabled then return end
    self._enabled = enabled
    if not enabled then
        self:_clearReloadTransport()
    end
end

-- Call every Heartbeat
function Ragebot:Update(delta)
    local ctx = self._innerContext
    if ctx == nil then self:_reset(); return end

    local fs = ctx.FighterState
    if fs.EnvironmentId == nil or not self._enabled then self:_reset(); return end

    local state = fs.Character.State
    if not state.Alive then self:_reset(); return end

    local charCtrl    = ctx.CharacterController
    local clientCF    = charCtrl:GetClientCFrame()
    local evasionMode = self._store.Data.Ragebot.Evasion.Mode
    local action      = self._actionGetter(ctx)

    if evasionMode == "Translocate" and self._reloadGun == nil
        and (action == nil or action.Type ~= "Reload")
    then
        self:_applyForcedCrouch(false)
        charCtrl:SetServerCFrame(
            self._evasionCompute(clientCF, self._targetSelection:HasTargets())
        )
        return
    end

    local target = self._targetSelection:GetTarget()
    self._lastTargetWorld = target ~= nil
        and target.AliveState.RootPart.Position
        or nil

    local plan = self:_plan(delta, action, target, state.RootPart, clientCF, evasionMode)
    self:_applyPlan(plan, target, ctx)

    local reloadGun = self._reloadGun
    if reloadGun ~= nil and self._reloadReadyAt == nil
        and self._pendingDepletionAmmo == nil
        and not reloadGun:IsReloading()
    then
        self._reloadReadyAt = os.clock() + self._repl.getEstimatedReplicationDelay()
    end

    self:_applyForcedCrouch(plan.ShouldForceCrouch == true)

    local gun = ctx.ItemBehaviors:EquippedItemAsGun()
    local ammo = gun and gun:GetAmmo() or 0
    local shotsBefore = gun and gun.ShotRequestCount or 0
    local weaponAction = plan.WeaponAction

    if weaponAction ~= nil then
        weaponAction()
        if gun ~= nil
            and (gun.ShotRequestCount - shotsBefore) > 0
            and gun:GetExpectedAmmoAfterPendingShots() <= 0
        then
            charCtrl:SetServerCFrame(self._immune())
            local now = os.clock()
            self._reloadGun            = gun
            self._reloadReadyAt        = now + self._repl.getEstimatedReplicationDelay()
            self._pendingDepletionAmmo = ammo
            self._reloadAcknDdl        = now
                + self._repl.getEstimatedRemoteDelay()
                + self._repl.getEstimatedReplicationDelay()
        end
    end
end

function Ragebot:_plan(delta, action, target, rootPart, clientCF, evasionMode)
    local outsideLimit = rootPart ~= nil and not self._spatialLimitGate:Tick(rootPart)

    local reloadPlan = self:_planReloadTransport(action)
    if reloadPlan then return reloadPlan end

    if action == nil then return self:_evade(evasionMode) end

    if action.Type == "Swap" then
        local plan = self:_evade(evasionMode)
        local item = action.Item
        plan.WeaponAction = function() item:Equip() end
        return plan
    end

    if action.Type == "Reload" then
        return { CFrame = self._immune(), ShouldSkipDefense = true }
    end

    if target == nil then return self:_evade(evasionMode) end

    local item = action.Item

    -- Gun path
    if item.__type == "Gun" then
        if item:IsReloading() then
            return { CFrame = self._immune(), ShouldSkipDefense = true }
        end
        local cf, wa = self._hitscanStrategy:Plan(delta, target, item, rootPart, outsideLimit)
        return { CFrame = cf, WeaponAction = wa, ShouldForceCrouch = true, IsAimPose = wa ~= nil }
    end

    -- Melee path ← KnifeStrategy fires here
    if item.__type == "Melee" then
        local cf, va, wa = self._meleeStrategy:Plan(delta, target, item, rootPart, outsideLimit)
        return {
            CFrame            = cf,
            ViewAngles        = va,
            WeaponAction      = wa,
            ShouldSkipDefense = true,   -- v86[34]
            ShouldForceCrouch = true,
        }
    end

    return {}
end

function Ragebot:_evade(mode)
    if mode == "Off" then return {} end
    if mode == "ProjectileBreaker" then
        return { CFrame = self._projectileBreaker:Compute(), ShouldSkipDefense = true }
    end
    return { CFrame = self._evasionCompute() }
end

function Ragebot:_applyPlan(plan, target, ctx)
    local charCtrl   = ctx.CharacterController
    local cf         = plan.CFrame

    if cf == nil or target == nil or plan.ShouldSkipDefense then
        charCtrl:SetServerCFrame(cf)
        charCtrl:SendViewAngles(20, plan.ViewAngles)   -- v86[9] = 20
        return
    end

    local shieldState = self._shieldStateGetter(ctx.ItemBehaviors)
    local defensiveCF = DefensiveCFrame.getDefensiveCFrame(
        cf, shieldState, target.FighterState, target.AliveState.RootPart
    )
    charCtrl:SetServerCFrame(defensiveCF)

    if plan.IsAimPose or plan.ShouldDefendInPlace then
        self._lastDefViewAngles = DefensiveCFrame.getDefensiveViewAngles(
            shieldState, target.FighterState
        )
    end

    charCtrl:SendViewAngles(20, plan.ViewAngles or self._lastDefViewAngles)
end

function Ragebot:_clearReloadTransport()
    self._reloadGun            = nil
    self._reloadReadyAt        = nil
    self._reloadAcknDdl        = nil
    self._pendingDepletionAmmo = nil
end

function Ragebot:_planReloadTransport(action)
    local gun = self._reloadGun
    if gun == nil then
        if action ~= nil and action.Type == "Reload" then
            self._reloadGun = action.Item
        end
        return nil
    end

    local ctx        = self._innerContext
    local equippedGun = ctx ~= nil
        and ctx.ItemBehaviors:EquippedItemAsGun()
        or nil

    if equippedGun ~= gun
        or (action ~= nil and (action.Type == "Swap" or action.Type == "Attack")
            and action.Item ~= gun)
    then
        self:_clearReloadTransport()
        return nil
    end

    if gun:IsReloading() then
        self._reloadReadyAt        = nil
        self._pendingDepletionAmmo = nil
        self._reloadAcknDdl        = nil
        return { CFrame = self._immune(), ShouldSkipDefense = true }
    end

    local ammo = gun:GetAmmo()
    local now  = os.clock()

    if self._pendingDepletionAmmo ~= nil then
        if not (ammo <= 0 and gun:GetAmmoReserve() > 0) then
            local ackDone = self._reloadAcknDdl == nil or now >= self._reloadAcknDdl
            if not ackDone then
                ackDone = gun:GetExpectedAmmoAfterPendingShots() > 0
            end
            if ackDone then
                self:_clearReloadTransport()
                return nil
            end
            return { CFrame = self._immune(), ShouldSkipDefense = true }
        end
        self._pendingDepletionAmmo = nil
        self._reloadAcknDdl        = nil
    end

    if ammo > 0 or gun:GetAmmoReserve() <= 0 then
        self:_clearReloadTransport()
        return nil
    end

    if self._reloadReadyAt == nil then
        self._reloadReadyAt = now + self._repl.getEstimatedReplicationDelay()
    end

    local plan = { CFrame = self._immune(), ShouldSkipDefense = true }

    if now >= self._reloadReadyAt
        and (self._reloadAcknDdl == nil or now >= self._reloadAcknDdl)
    then
        plan.WeaponAction = function()
            if gun:Reload() then
                self._reloadAcknDdl = os.clock()
                    + self._repl.getEstimatedRemoteDelay()
                    + self._repl.getEstimatedReplicationDelay()
            end
        end
    end

    return plan
end

function Ragebot:_applyForcedCrouch(force)
    if force then
        self._stateHook:SetForced("IsCrouching", true)
    else
        self._stateHook:ClearForced("IsCrouching")
    end
end

function Ragebot:GetLastTargetWorld()
    return self._lastTargetWorld
end

function Ragebot:_reset()
    self:_clearReloadTransport()
    self._lastTargetWorld   = nil
    self._lastDefViewAngles = nil
    self:_applyForcedCrouch(false)
    self._meleeStrategy:ResetState()
    if self._projectileBreaker then
        self._projectileBreaker:ResetState()
    end
    local ctx = self._innerContext
    if ctx == nil then return end
    ctx.CharacterController:SetServerCFrame(nil)
    ctx.CharacterController:SendViewAngles(20, nil)   -- v86[9]
end

function Ragebot:Destroy()
    self:_reset()
    for _, c in self._connections do
        if type(c) == "table" and c.Disconnect then
            pcall(c.Disconnect, c)
        elseif typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
    end
    self._connections = {}
end

Modules.Ragebot = Ragebot

return Modules
