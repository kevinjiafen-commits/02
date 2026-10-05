--[[
    KICIA REBUILD — EXTRACTED MODULES
    Extreme Melee Rage / Always Backstab / Knife Rage

    Blocks extracted (in dependency order):
      di   — AlwaysBackstab controller
      jy   — FighterState / RiotShield helper  (melee planner dependency)
      jz   — Defensive CFrame helper (knife random evasion)
      jA   — ShootLock (fire-rate gate)
      jB   — TargetSelection (melee target picker)
      jC   — CFrame helper (look-at, XZ-plane)
      jD   — Hitscan melee strategy (non-Knife melee ragebot planner)
      jE   — Knife melee strategy  (Knife rage + backstab planner)  ← core
      jO   — Ragebot orchestrator  (wires jD + jE + target + evasion)
--]]

-- ============================================================
--  MODULE: di  —  AlwaysBackstab
--  Tracks closest enemy within 20 studs and spoofs server
--  view-angles so every Knife swing registers as a backstab.
-- ============================================================
do -- di
local function fn35()
local v115 = tbl17.bG()
tbl17.cF()
tbl17.cX()
local v116 = tbl17.k()
local index2 = {}
index2.__index = index2

index2.new = function(arg, arg2)
local tbl18 = { _trove = v116.new("always_backstab"), _fighters = arg2 }
setmetatable(tbl18, index2)
tbl18:_Initialize(arg)
return tbl18
end

index2._Initialize = function(arg, arg2)
arg._trove:Add(arg2:ObserveContext("always_backstab", function(innerContext)
arg._innerContext = innerContext
end))

arg._trove:Connect(arg2.ContextRemoved, function()
arg._innerContext = nil
end)
end

index2.Update = function(arg)
local innerContext = arg._innerContext
if innerContext == nil or not v115.Data.ItemModifiers.AlwaysBackstab then
return
end

-- Only active when the Knife is equipped
if innerContext.ItemBehaviors:FindMeleeByName("Knife") == nil then
return
end
local serverHeadOrigin = innerContext.CharacterController:GetServerHeadOrigin()
if serverHeadOrigin == nil then
innerContext.CharacterController:SendViewAngles(10, nil)
return
end
local v117 = arg:_FindClosestEnemy(serverHeadOrigin.Position)
if v117 == nil then
innerContext.CharacterController:SendViewAngles(v86[133], nil)
return
end
-- Spoof view to face AWAY from enemy (backstab angle)
local v118, v119 = v117.CFrame:ToOrientation()
innerContext.CharacterController:SendViewAngles(10, { Kind = "Normalized", Pitch = math.deg(v118), Yaw = math.deg(v119) })
end

index2._FindClosestEnemy = function(arg, arg2)
local huge = math.huge
local v117 = nil

for _, v118 in arg._fighters.EnemyByPlayer, nil, nil do
local state = v118.Character.State

if state.Alive then
local rootPart = state.RootPart
local magnitude = (rootPart.Position - arg2).Magnitude

if magnitude < 20 and magnitude < huge then
huge = magnitude
v117 = rootPart
end
end
end

return v117
end

index2.Destroy = function(arg)
arg._trove:Destroy()
end

return index2
end

tbl17.di = function()
local di = tbl17.cache.di

if not di then
local di2 = { c = fn35() }
tbl17.cache.di = di2
di = di2
end

return di.c
end
end

-- ============================================================
--  MODULE: jy  —  FighterState helper
--  Returns "Above" / "Below" based on Riot Shield position.
--  Used by melee planners to pick the correct hitbox offset.
-- ============================================================
do -- jy
local function fn35()
tbl17.cF()
tbl17.jx()

local function fn36(arg)
local itemObserver = arg.ItemObserver
local equippedItem = itemObserver:GetEquippedItem()

if equippedItem ~= nil and equippedItem.Name == "Riot Shield" then
local v115 = math.deg(arg:GetCameraRotation().X)
if v115 > 22 and v115 < 91 then
return "Below"
end
return "Above"
end

for _, v115 in itemObserver:GetItems() do
if v115.Name == "Riot Shield" then
local v116 = math.deg(arg:GetCameraRotation().X)
if v116 > 315 and v116 < 360 or v116 > 0 and v116 < 91 then
return "Above"
end
return "Below"
end
end

return v86[75]
end

if not flag2 then
return
end
return fn36
end

tbl17.jy = function()
local jy = tbl17.cache.jy

if not jy then
local jy2 = { c = fn35() }
tbl17.cache.jy = jy2
jy = jy2
end

return jy.c
end
end

-- ============================================================
--  MODULE: jz  —  Defensive CFrame helper
--  Returns defensive position / view-angles during ragebot
--  evasion. Knife gets a random full-rotation CFrame so the
--  server cannot predict backstab direction.
-- ============================================================
do -- jz
local function fn35()
tbl17.cE()
tbl17.jx()
tbl17.cI()
local v115 = tbl17.jy()
local v116 = Random.new()

return {
getDefensiveCFrame = function(arg, arg2, arg3, arg4)
if arg2 == "Equipped" then
return CFrame.new(arg.Position, arg4.Position)
end

if arg2 == "Unequipped" then
return CFrame.new(arg.Position, arg.Position + arg.Position - arg4.Position)
end
local v117 = arg3.ItemObserver:EquippedItemAsMelee()

-- Knife: full random orientation so no angle is leaked to server
if v117 ~= nil and v117.Name == "Knife" then
local cframe = CFrame.fromOrientation
local nextNumber = v116.NextNumber
local tau = math.tau
return CFrame.new(arg.Position) * cframe(v116:NextNumber(0, math.tau), v116:NextNumber(0, math.tau), nextNumber(v116, 0, tau))
end

return arg
end,
getDefensiveViewAngles = function(arg, arg2)
if arg == "None" then
return nil
end

return {
Kind = "Normalized",
Pitch = (arg == "Equipped") ~= (v115(arg2) ~= "Below") and v86[45] or -90,
Yaw = v116:NextNumber(0, 360),
}
end,
}
end

tbl17.jz = function()
local jz = tbl17.cache.jz

if not jz then
jz = { c = fn35() }
tbl17.cache.jz = jz
end

return jz.c
end
end

-- ============================================================
--  MODULE: jA  —  ShootLock
--  Simple fire-rate gate: locks out further shots for
--  ShootFrames * delta after each fire request.
-- ============================================================
do -- jA
local function fn35()
local index2 = {}
index2.__index = index2

index2.new = function()
return setmetatable({}, index2)
end

index2.ShouldFire = function(arg, arg2, arg3)
local now2 = os.clock()
local lockedUntil = arg._lockedUntil
local flag19 = lockedUntil ~= nil and now2 < lockedUntil

if arg2 then
arg._lockedUntil = now2 + arg3
end

return flag19 or arg2
end

index2.Reset = function(arg)
arg._lockedUntil = nil
end

return index2
end

tbl17.jA = function()
local ja = tbl17.cache.jA

if not ja then
local ja2 = { c = fn35() }
tbl17.cache.jA = ja2
ja = ja2
end

return ja.c
end
end

-- ============================================================
--  MODULE: jB  —  TargetSelection
--  Iterates EnemyByPlayer, skipping invincible / dead /
--  deflecting targets. Optionally prioritises "Hacker" tags.
-- ============================================================
do -- jB
local function fn35()
tbl17.cr()
local v115 = tbl17.bG()
tbl17.cF()
tbl17.bM()

local function fn36(arg)
if not arg.IsEnemy or arg:IsInvincible() then
return false
end

if not arg.Character.State.Alive then
return false
end
local v116 = arg.ItemObserver:EquippedItemAsMelee()
if v116 ~= nil and v116:IsDeflecting() then
return false
end
return true
end

local function fn37(arg)
return { FighterState = arg, AliveState = arg.Character.State }
end

local index2 = {}
index2.__index = index2

index2.new = function(arg, arg2)
return setmetatable({ _fighters = arg, _playerTags = arg2 }, index2)
end

index2.GetTarget = function(arg)
local prioritizeHackers = v115.Data.Ragebot.PrioritizeHackers

if prioritizeHackers then
for _, v116 in arg._playerTags:GetPlayersWith("Hacker") do
local v117 = arg._fighters.StateByPlayer[v116]
if v117 ~= nil and fn36(v117) then
return fn37(v117)
end
end
end

for k, v116 in arg._fighters.EnemyByPlayer, nil, nil do
if prioritizeHackers and arg._playerTags:Has(k, "Hacker") then
continue
end

if fn36(v116) then
return fn37(v116)
end
end

return nil
end

index2.HasTargets = function(arg)
for _, v116 in arg._fighters.EnemyByPlayer, nil, nil do
if fn36(v116) then
return true
end
end

return v86[153]
end

index2.IsSameTarget = function(arg, arg2)
return arg.FighterState == arg2.FighterState and arg.AliveState == arg2.AliveState
end

return index2
end

tbl17.jB = function()
local jb = tbl17.cache.jB

if not jb then
jb = { c = fn35() }
tbl17.cache.jB = jb
end

return jb.c
end
end

-- ============================================================
--  MODULE: jC  —  CFrame look-at (XZ plane only)
--  Returns a CFrame at `arg` looking toward `arg2`,
--  ignoring Y-axis delta (flat ground look-at).
-- ============================================================
do -- jC
local function fn35()
local vector = Vector3.new(0, -v86[63], 0)
local vector2 = Vector3.new(0, 0, -v86[63])

return function(arg, arg2)
local n = arg2 - arg
local vector3 = Vector3.new(n.X, v86[186], n.Z)

if vector3.Magnitude < 0.001 then
vector3 = vector2
end

return CFrame.lookAt(arg, arg + vector3, vector)
end
end

tbl17.jC = function()
local jc = tbl17.cache.jC

if not jc then
jc = { c = fn35() }
tbl17.cache.jC = jc
end

return jc.c
end
end

-- ============================================================
--  MODULE: jD  —  Hitscan melee strategy  (non-Knife)
--  Plan() returns the spoofed server CFrame + ShootEncoded
--  callback for non-Knife melee weapons in the ragebot.
--  Uses ShootLock (jA) to throttle by ShootFrames.
-- ============================================================
do -- jD
local function fn35()
tbl17.cr()
local v115 = tbl17.bG()
tbl17.cF()
local v116 = tbl17.jA()
tbl17.jB()
local v117 = tbl17.jy()
local v118 = tbl17.jC()
local vector = Vector3.new(0, -0.7, 0.05)
local vector2 = Vector3.new(0, -3.85, 0.05)

-- Encoded attack payloads (angle + origin packed as string-keyed tables)
local tbl18 = {
["\0"] = -9e37,
["\1"] = 0,
["\2"] = v86[186],
["\3"] = -1.5707963267948966,
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl19 = {
["\0"] = v86[186],
["\1"] = -90000000,
["\2"] = 0,
["\3"] = -1.5707963267948966,
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl20 = {
["\0"] = -9e37,
["\1"] = v86[186],
["\2"] = 0,
["\3"] = 1.5707963267948966,
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl21 = {
["\0"] = 0,
["\1"] = 90000000,
["\2"] = 0,
["\3"] = 1.5707963267948966,
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl22 = { ["\0"] = 0, ["\1"] = 1, ["\2"] = v86[186], ["\3"] = v86[186], ["\4"] = 0, ["\5"] = 0 }

local index2 = {}
index2.__index = index2

index2.new = function(arg)
return setmetatable({ _partGlue = arg, _shootLock = v116.new() }, index2)
end

index2.Plan = function(arg, arg2, arg3, arg4, arg5, arg6)
local hitboxHead = arg3.AliveState.HitboxHead
local flag19 = v117(arg3.FighterState) ~= "Below"
local ragebot = v115.Data.Ragebot
local v119 = flag19 and vector or vector2
local v120 = arg._partGlue:Acquire(arg5, hitboxHead)
local n

if flag19 then
n = v120 + v119
else
n = v118(v120.Position + v119, hitboxHead.Position)
end

if not arg._shootLock:ShouldFire(arg6, arg2 * ragebot.ShootFrames) then
local random2 = math.random
return CFrame.new(math.random(-1000000, 1000000), math.random(5000, 10000), random2(-1000000, 1000000)), nil
end
local v121 = (flag19 and { tbl18 } or { tbl20 })[1]
local v122 = (flag19 and { tbl19 } or { tbl21 })[v86[63]]

return n, function()
arg4:ShootEncoded(v121, v122, hitboxHead, tbl22)
end
end

return index2
end

tbl17.jD = function()
local jd = tbl17.cache.jD

if not jd then
local jd2 = { c = fn35() }
tbl17.cache.jD = jd2
jd = jd2
end

return jd.c
end
end

-- ============================================================
--  MODULE: jE  —  Knife melee strategy  (EXTREME MELEE / KNIFE RAGE)
--
--  Plan() logic:
--    1. If inside the 0.625 s backstab hitbox window → keep
--       firing HeavyAttackEncoded (exploit extended window).
--    2. ShootLock gate (ShootFrames throttle).
--    3. Attack cooldown gate (1.25 s post-backstab).
--    4. Knife branch → _RecordBackstab() then HeavyAttackEncoded
--       (guaranteed backstab damage every swing).
--    5. All other melee → AttackEncoded (standard hit).
--
--  _RecordBackstab sets:
--    _hitboxWindowUntil  = now + 0.625  (keep spamming heavy)
--    _attackCooldown     = now + 1.25   (debounce)
-- ============================================================
do -- jE
local function fn35()
tbl17.cJ()
local v115 = tbl17.bG()
tbl17.cS()
tbl17.gA()
local v116 = tbl17.jA()
tbl17.jB()
local v117 = tbl17.jy()
local v118 = tbl17.jC()
local vector = Vector3.new(0, -v86[195], 0.05)
local vector2 = Vector3.new(v86[186], -3.85, 0.05)

-- Encoded angle tables for left-side and right-side backstab approach
local tbl18 = {
["\0"] = -9e37,
["\1"] = 0,
["\2"] = 0,
["\3"] = -1.5707963267948966,   -- pitch: -π/2  (face down → backstab registration)
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl19 = {
["\0"] = 0,
["\1"] = -90000000,             -- extreme Y offset (off-map anchor)
["\2"] = v86[186],
["\3"] = -1.5707963267948966,
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl20 = {
["\0"] = -9e37,
["\1"] = 0,
["\2"] = v86[186],
["\3"] = 1.5707963267948966,    -- pitch: +π/2
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl21 = {
["\0"] = 0,
["\1"] = 90000000,              -- extreme Y offset (opposite side)
["\2"] = v86[186],
["\3"] = 1.5707963267948966,
["\4"] = 3.1415926535897931,
["\5"] = 3.1415926535897931,
}

local tbl22 = { ["\0"] = 0, ["\1"] = 1, ["\2"] = v86[186], ["\3"] = 0, ["\4"] = 0, ["\5"] = 0 }

-- Returns a far-away CFrame used to "miss" safely while on cooldown
local function fn36()
local random2 = math.random
return CFrame.new(math.random(-10000000, -100000), math.random(5000, 10000), random2(-10000000, -100000))
end

local function fn37(arg, arg2)
return { Kind = "Normalized", Pitch = math.deg(arg), Yaw = math.deg(arg2) }
end

local function fn38(arg, arg2, arg3, arg4)
return {
["\0"] = arg["\0"],
["\1"] = arg["\1"],
["\2"] = arg["\2"],
["\3"] = arg2,
["\4"] = arg3,
["\5"] = arg4,
}
end

local index2 = {}
index2.__index = index2

index2.new = function(arg)
return setmetatable({ _partGlue = arg, _shootLock = v116.new(), _hitboxWindowUntil = -1, _attackCooldown = -1 }, index2)
end

index2.Plan = function(arg, arg2, arg3, arg4, gluedOurPart, arg5)
local aliveState = arg3.AliveState
local hitboxHead = aliveState.HitboxHead
local flag19 = v117(arg3.FighterState) ~= "Below"
local ragebot = v115.Data.Ragebot
local v119 = flag19 and vector or vector2
local v120 = arg._partGlue:Acquire(gluedOurPart, hitboxHead)
arg._gluedOurPart = gluedOurPart
local n

if flag19 then
n = v120 + v119
else
n = v118(v120.Position + v119, hitboxHead.Position)
end

local v121, v122, v123 = aliveState.RootPart.CFrame:ToOrientation()
local n33 = flag19 and -1.5707963267948966 or 1.5707963267948966
local v124 = (flag19 and { tbl18 } or { tbl20 })[1]
local v125 = (flag19 and { tbl19 } or { tbl21 })[1]
local v126 = fn38(v124, n33, v122, v123)
local v127 = fn38(v125, n33, v122, v123)
local now2 = os.clock()

-- [1] Still inside backstab hitbox window → keep spamming HeavyAttack
if now2 < arg._hitboxWindowUntil then
return n, fn37(v121, v122), function()
arg4:HeavyAttackEncoded(v126, v127, hitboxHead, tbl22)
end
end

-- [2] ShootLock gate
if not arg._shootLock:ShouldFire(arg5, arg2 * ragebot.ShootFrames) then
return fn36(), nil, nil
end

-- [3] Attack cooldown gate
if now2 < arg._attackCooldown then
return fn36(), nil, nil
end

-- [4] Knife → record backstab, fire HeavyAttackEncoded
if arg4.Name == "Knife" then
arg:_RecordBackstab()

return n, fn37(v121, v122), function()
arg4:HeavyAttackEncoded(v126, v127, hitboxHead, tbl22)
end
end

-- [5] Other melee → standard AttackEncoded
return n, nil, function()
arg4:AttackEncoded(v126, v127, hitboxHead, tbl22)
end
end

-- Sets the 0.625 s hitbox window and 1.25 s cooldown after a backstab
index2._RecordBackstab = function(arg)
local now2 = os.clock()
arg._hitboxWindowUntil = now2 + 0.625
arg._attackCooldown = now2 + 1.25
end

index2.ResetState = function(arg)
arg._hitboxWindowUntil = -1
arg._attackCooldown = -1
arg._shootLock:Reset()
local gluedOurPart = arg._gluedOurPart

if gluedOurPart ~= nil then
arg._partGlue:Free(gluedOurPart)
arg._gluedOurPart = nil
end
end

return index2
end

tbl17.jE = function()
local je = tbl17.cache.jE

if not je then
local je2 = { c = fn35() }
tbl17.cache.jE = je2
je = je2
end

return je.c
end
end

-- ============================================================
--  MODULE: jO  —  Ragebot orchestrator
--  Wires TargetSelection (jB), hitscan strategy (jD),
--  melee/knife strategy (jE), defensive CFrame (jz), and
--  ProjectileBreaker evasion into a single Update() loop.
--
--  Key paths:
--    Gun  equipped → _hitscanStrategy:Plan()
--    Melee equipped → _meleeStrategy:Plan()   ← jE (knife rage)
--    No target      → _EvadePlan()
--    Reload needed  → _PlanReloadTransport()
-- ============================================================
do -- jO
local function fn35()
tbl17.cJ()
local v115 = tbl17.bG()
local v116 = tbl17.jz()
tbl17.cF()
local v117 = tbl17.jD()
tbl17.cU()
local v118 = tbl17.c4()
local v119 = tbl17.jE()
tbl17.gA()
tbl17.cX()
tbl17.bM()
local v120 = tbl17.jH()
local v121 = tbl17.jI()
local v122 = tbl17.cG()
local v123 = tbl17.jJ()
tbl17.g_()
local v124 = tbl17.jB()
local v125 = tbl17.jK()
local v126 = tbl17.k()
local v127 = tbl17.jL()
local v128 = tbl17.jM()
local v129 = tbl17.jN()
local fallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight

local function fn36()
return { CFrame = v127.getImmune(), ShouldSkipDefense = true }
end

local index2 = {}
index2.__index = index2

index2.new = function(arg, arg2, arg3, arg4, arg5)
local ragebot = v126.new("ragebot")
local v130 = ragebot:Add(v123.new(arg))

local tbl18 = {
_trove = ragebot,
_enabled = false,
_lastTargetWorld = nil,
_lastDefensiveViewAngles = nil,
_playerContext = arg3,
_targetSelection = v124.new(arg, arg2),
_spatialLimitGate = v130,
_hitscanStrategy = v117.new(arg5),        -- jD: non-Knife melee / gun hitscan
_meleeStrategy = v119.new(arg5),           -- jE: Knife rage + backstab
_projectileBreakerTeleport = ragebot:Add(v120.new(arg, arg3)),
_stateHook = arg4,
_reloadGun = nil,
_reloadReadyAt = nil,
_reloadAcknowledgementDeadline = nil,
_pendingDepletionAmmo = nil,
}

setmetatable(tbl18, index2)
tbl18:_Initialize()
return tbl18
end

index2._Initialize = function(arg)
arg._trove:Add(arg._playerContext:ObserveContext("ragebot", function(innerContext)
if not flag2 then
return
end
arg._innerContext = innerContext
arg:_ClearReloadTransport()
end))

arg._trove:Connect(arg._playerContext.ContextRemoved, function()
arg:_Reset()
arg._innerContext = nil
end)

arg._trove:Add(v118:ObserveEnabledKeybind({ "Ragebot" }, function(arg2)
arg:SetEnabled(arg2)
arg:_Reset()
end))
end

index2.SetEnabled = function(arg, enabled)
if arg._enabled == enabled then
return
end
arg._enabled = enabled
-- Physics sender rate boost when ragebot is live
v112(workspace, "FallenPartsDestroyHeight", enabled and (0/0) or fallenPartsDestroyHeight)
v107(v108, "DFIntS2PhysicsSenderRate", enabled and "120" or "15")
v107(v108, "DFIntAssemblyHistoryBufferSize", enabled and "2147483648" or "15")
v107(v108, "DFIntAssemblyHistorySkipSize", enabled and v86[18] or "8")

if not enabled then
arg:_ClearReloadTransport()
end
end

index2.Update = function(arg, arg2)
local innerContext = arg._innerContext
if innerContext == nil then
arg:_Reset()
return
end
local fighterState = innerContext.FighterState
if fighterState.EnvironmentId == nil or not arg._enabled then
arg:_Reset()
return
end
local state = fighterState.Character.State
if not state.Alive then
arg:_Reset()
return
end
local characterController = innerContext.CharacterController
local clientCFrame = characterController:GetClientCFrame()
local mode = v115.Data.Ragebot.Evasion.Mode
local v130 = v128.getAction(innerContext)

if mode == "Translocate" and arg._reloadGun == nil and (v130 == nil or v130.Type ~= "Reload") then
arg:_ApplyForcedCrouch(v86[153])
characterController:SetServerCFrame(v125.compute(clientCFrame, arg._targetSelection:HasTargets()))
return
end

local target = arg._targetSelection:GetTarget()

if target ~= nil then
arg._lastTargetWorld = target.AliveState.RootPart.Position
else
arg._lastTargetWorld = nil
end

local v131 = arg:_Plan(arg2, v130, target, state.RootPart, clientCFrame, mode)
arg:_ApplyPlan(v131, target, innerContext)
local reloadGun = arg._reloadGun

if reloadGun ~= nil and arg._reloadReadyAt == nil and arg._pendingDepletionAmmo == nil and not reloadGun:IsReloading() then
arg._reloadReadyAt = os.clock() + v122.getEstimatedReplicationDelay()
end

arg:_ApplyForcedCrouch(v131.ShouldForceCrouch == true)
local v132 = innerContext.ItemBehaviors:EquippedItemAsGun()
local ammo = v132 ~= nil and v132:GetAmmo() or 0
local shotRequestCount = v132 ~= nil and v132.ShotRequestCount or 0
local weaponAction = v131.WeaponAction

if weaponAction ~= nil then
weaponAction()

if v132 ~= nil and (v132 ~= nil and v132.ShotRequestCount - shotRequestCount or 0) > 0 and v132:GetExpectedAmmoAfterPendingShots() <= 0 then
innerContext.CharacterController:SetServerCFrame(v127.getImmune())
local now2 = os.clock()
arg._reloadGun = v132
arg._reloadReadyAt = now2 + v122.getEstimatedReplicationDelay()
arg._pendingDepletionAmmo = ammo
arg._reloadAcknowledgementDeadline = now2 + v122.getEstimatedRemoteDelay() + v122.getEstimatedReplicationDelay()
end
end
end

index2._Plan = function(arg, arg2, arg3, arg4, arg5, arg6, arg7)
local flag19 = arg4 ~= nil and not arg._spatialLimitGate:Tick(arg4)
local v130 = arg:_PlanReloadTransport(arg3)
if v130 ~= nil then
return v130
end

if arg3 == nil then
return arg:_EvadePlan(arg6, arg7)
end

if arg3.Type == "Swap" then
local item = arg3.Item
local v131 = arg:_EvadePlan(arg6, arg7)

v131.WeaponAction = function()
item:Equip()
end

return v131
end

if arg3.Type == "Reload" then
return fn36()
end

if arg4 == nil then
return arg:_EvadePlan(arg6, arg7)
end
local item = arg3.Item

if item.__type == "Gun" then
if item:IsReloading() then
return fn36()
end
local v131, v132 = arg._hitscanStrategy:Plan(arg2, arg4, item, arg5, flag19)
return { CFrame = v131, WeaponAction = v132, ShouldForceCrouch = true, IsAimPose = v132 ~= nil }
end

-- ← MELEE PATH (Knife rage fires through here)
if item.__type == "Melee" then
local v131, v132, v133 = arg._meleeStrategy:Plan(arg2, arg4, item, arg5, flag19)

return {
CFrame = v131,
ViewAngles = v132,
WeaponAction = v133,
ShouldSkipDefense = v86[34],
ShouldForceCrouch = true,
}
end

return {}
end

index2._ClearReloadTransport = function(arg)
arg._reloadGun = nil
arg._reloadReadyAt = nil
arg._reloadAcknowledgementDeadline = nil
arg._pendingDepletionAmmo = nil
end

index2._PlanReloadTransport = function(arg, arg2)
local reloadGun = arg._reloadGun
local now2 = os.clock()

if reloadGun ~= nil then
if (arg._innerContext ~= nil and arg._innerContext.ItemBehaviors:EquippedItemAsGun() or nil) ~= reloadGun or arg2 ~= nil and (arg2.Type == "Swap" or arg2.Type == "Attack") and arg2.Item ~= reloadGun then
arg:_ClearReloadTransport()
return nil
end

if reloadGun:IsReloading() then
arg._reloadReadyAt = nil
arg._pendingDepletionAmmo = nil
arg._reloadAcknowledgementDeadline = nil
return fn36()
end

local ammo = reloadGun:GetAmmo()

if arg._pendingDepletionAmmo ~= nil then
local reloadAcknowledgementDeadline = arg._reloadAcknowledgementDeadline

if not (ammo <= 0 and reloadGun:GetAmmoReserve() > 0) then
local flag19 = reloadAcknowledgementDeadline == nil or now2 >= reloadAcknowledgementDeadline

if not flag19 then
local v130 = v86[186]
flag19 = reloadGun:GetExpectedAmmoAfterPendingShots() > v130
end

if flag19 then
arg:_ClearReloadTransport()
return nil
end
return fn36()
end

arg._pendingDepletionAmmo = nil
arg._reloadAcknowledgementDeadline = nil
end

if ammo > 0 or reloadGun:GetAmmoReserve() <= 0 then
arg:_ClearReloadTransport()
return nil
end
local reloadReadyAt = arg._reloadReadyAt

if reloadReadyAt == nil then
reloadReadyAt = now2 + v122.getEstimatedReplicationDelay()
arg._reloadReadyAt = reloadReadyAt
end

local v130 = fn36()
local reloadAcknowledgementDeadline = arg._reloadAcknowledgementDeadline

if now2 >= reloadReadyAt and (reloadAcknowledgementDeadline == nil or now2 >= reloadAcknowledgementDeadline) then
v130.WeaponAction = function()
if reloadGun:Reload() then
arg._reloadAcknowledgementDeadline = os.clock() + v122.getEstimatedRemoteDelay() + v122.getEstimatedReplicationDelay()
end
end
end

return v130
end

if arg2 == nil or arg2.Type ~= "Reload" then
return nil
end
arg._reloadGun = arg2.Item
arg._reloadReadyAt = nil
arg._reloadAcknowledgementDeadline = nil
arg._pendingDepletionAmmo = nil
return fn36()
end

index2._EvadePlan = function(arg, arg2, arg3)
if arg3 == "Off" then
return {}
end

if arg3 == "ProjectileBreaker" then
return { CFrame = arg._projectileBreakerTeleport:Compute(arg2), ShouldSkipDefense = v86[34] }
end
return { CFrame = v121.compute(arg2) }
end

index2._ApplyPlan = function(arg, arg2, arg3, arg4)
local characterController = arg4.CharacterController
local cFrame = arg2.CFrame

if cFrame == nil or arg3 == nil or arg2.ShouldSkipDefense then
characterController:SetServerCFrame(cFrame)
characterController:SendViewAngles(20, arg2.ViewAngles)
return
end

local aliveState = arg3.AliveState
local v130 = v129(arg4.ItemBehaviors)
local v131 = v116.getDefensiveCFrame(cFrame, v130, arg3.FighterState, aliveState.RootPart)
characterController:SetServerCFrame(v131)

if arg2.IsAimPose or arg2.ShouldDefendInPlace then
arg._lastDefensiveViewAngles = v116.getDefensiveViewAngles(v130, arg3.FighterState)
end

characterController:SendViewAngles(v86[9], arg2.ViewAngles or arg._lastDefensiveViewAngles)
end

index2.GetLastTargetWorld = function(arg)
return arg._lastTargetWorld
end

index2._ApplyForcedCrouch = function(arg, arg2)
if arg2 then
arg._stateHook:SetForced("IsCrouching", true)
else
arg._stateHook:ClearForced("IsCrouching")
end
end

index2._Reset = function(arg)
arg:_ClearReloadTransport()
arg._lastTargetWorld = nil
arg._lastDefensiveViewAngles = nil
arg:_ApplyForcedCrouch(false)
arg._meleeStrategy:ResetState()
arg._projectileBreakerTeleport:ResetState()
local innerContext = arg._innerContext
if innerContext == nil then
return
end
innerContext.CharacterController:SetServerCFrame(nil)
innerContext.CharacterController:SendViewAngles(20, nil)
end

index2.Destroy = function(arg)
arg._trove:Destroy()
end

return index2
end

tbl17.jO = function()
local jo = tbl17.cache.jO

if not jo then
jo = { c = fn35() }
tbl17.cache.jO = jo
end

return jo.c
end
end
