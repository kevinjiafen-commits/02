local Rage = {}
;(function()
    local _tgtConn  = nil
    local _labConn  = nil
    local function bump(p) State.RageCharTokens[p] = (State.RageCharTokens[p] or 0) + 1 end
    local function killFloor()
        return workspace.FallenPartsDestroyHeight + Config.RageKillPlaneBuffer
    end
    local function hasLOS(fromPos, toPos, ignore)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local res = workspace:Raycast(fromPos, toPos - fromPos, rp)
        if not res then return true end
        return (res.Position - toPos).Magnitude < 3
    end
    local function lookCF(fromPos, toPos)
        local dir = toPos - fromPos
        if dir.Magnitude < 1e-4 then dir = Vector3.new(0, -1, 0) end
        local up = Vector3.new(0, 1, 0)
        if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0, 0, 1) end
        return CFrame.lookAt(fromPos, fromPos + dir, up)
    end
    Rage._lookCF = lookCF
    local function buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimWorldPos, jitter, clampFrac, jitterFrac)
        local objSpace = hitPart.CFrame:PointToObjectSpace(aimWorldPos)
        local hs = hitPart.Size * (clampFrac or 0.45)
        objSpace = Vector3.new(
            math.clamp(objSpace.X, -hs.X, hs.X),
            math.clamp(objSpace.Y, -hs.Y, hs.Y),
            math.clamp(objSpace.Z, -hs.Z, hs.Z)
        )
        if jitter then
            local jf = jitterFrac or 1.0
            objSpace = Vector3.new(
                math.clamp(objSpace.X + (math.random() - 0.5) * hs.X * jf, -hs.X, hs.X),
                math.clamp(objSpace.Y + (math.random() - 0.5) * hs.Y * jf, -hs.Y, hs.Y),
                math.clamp(objSpace.Z + (math.random() - 0.5) * hs.Z * jf, -hs.Z, hs.Z)
            )
        end
        local hitWorld   = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Rivals.Util:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Rivals.Util:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Rivals.Util:EncodeCFrame(objSpaceCF)
    end
    Rage._buildShotFields = buildShotFields
    local RAGE_CLAMP_FRAC  = 0.30
    local RAGE_JITTER_FRAC = 1.0
    local function encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Rivals.Util then return false end
        local lead      = calculateLead(targetChar, fromCamPos)
        local off       = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF     = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -Config.RageEyeMuzzleSep, 0)
        local muzzleCF  = lookCF(muzzlePos, leadedPos)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, Config.SilentAimJitter, 0.45, 1.0)
        return true
    end
    Rage._encodeShot = encodeShot
    local PICK_SLOT = { Primary = 1, Secondary = 2, Melee = 3 }
    ;(function()
        local function fighterItems()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            return lf and lf.Items or nil
        end
        local function itemIsMelee(item)
            if not item then return false end
            local viaInfo = false
            pcall(function()
                local info = item.Info
                if info == nil then return end
                if info.Type == "Melee" or info.Class == "Melee" then viaInfo = true return end
                if type(info.AttackReach) == "number" and info.MaxAmmo == nil then viaInfo = true end
            end)
            if viaInfo then return true end
            local okN, nm = pcall(function() return item:Get("Name") or item.Name end)
            if okN and type(nm) == "string" and nm:lower():find("melee", 1, true) then return true end
            return false
        end
        Rage._itemIsMelee = itemIsMelee
        local function itemAmmo(item)
            if not item then return nil end
            local ok, a = pcall(function() return item:Get("Ammo") or item:Get("CurrentAmmo") end)
            if ok and type(a) == "number" then return a end
            return nil
        end
        local function slotItemByIndex(idx)
            local items = fighterItems(); if not items then return nil end
            if items[idx] then return items[idx] end
            if items[tostring(idx)] then return items[tostring(idx)] end
            for key, it in pairs(items) do
                if it and typeof(it) == "table" then
                    local okS, s = pcall(function() return tonumber(it:Get("Slot") or it:Get("Index") or it:Get("ItemSlot") or key) end)
                    if okS and s == idx then return it end
                    local okT, t = pcall(function() return it:Get("ItemType") or it:Get("Type") end)
                    if okT then
                        if idx == 1 and (t == "Primary" or t == 1 or t == "1") then return it end
                        if idx == 2 and (t == "Secondary" or t == 2 or t == "2") then return it end
                        if idx == 3 and (t == "Melee" or (type(t) == "string" and t:lower():find("melee", 1, true))) then return it end
                    end
                end
            end
            return nil
        end
        local function whichSlotNow()
            local cur = getEquippedItem(); if not cur then return nil end
            local okId, oid = pcall(function() return cur:Get("ObjectID") end)
            if okId and oid then
                for idx = 1, 3 do
                    local it = slotItemByIndex(idx)
                    if it then
                        local okI, iid = pcall(function() return it:Get("ObjectID") end)
                        if okI and iid == oid then return idx end
                    end
                end
            end
            if itemIsMelee(cur) then return 3 end
            return nil
        end
        local function slotUsable(idx)
            local it = slotItemByIndex(idx); if not it then return false end
            if itemIsMelee(it) then return Config.RageSwitchMelee == true end
            local a = itemAmmo(it)
            return a == nil or a > 0
        end
        local function slotOrder()
            local pref = PICK_SLOT[Config.RageWeaponPick] or 1
            local order = { pref }
            for _, s in ipairs({ 1, 2, 3 }) do
                if s ~= pref then order[#order + 1] = s end
            end
            if not Config.RageSwitchMelee then
                local filtered = {}
                for _, s in ipairs(order) do if s ~= 3 then filtered[#filtered + 1] = s end end
                order = filtered
            end
            return order
        end
        local function nextUsableSlot(excludeIdx)
            for _, s in ipairs(slotOrder()) do
                if s ~= excludeIdx and slotUsable(s) then return s end
            end
            return nil
        end
        local function equipSlot(idx)
            if not idx then return false end
            if whichSlotNow() == idx then return true end
            local now = tick()
            if now - (State.RageSwitchLast or 0) < (Config.RageSwitchRateLimit or 0.06) then return false end
            State.RageSwitchLast = now
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            local equipped = false
            if lf and lf.EquipItem then
                equipped = pcall(function() lf:EquipItem(idx) end)
            end
            if not equipped then
                pcall(function()
                    local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[idx]
                    if kc then
                        VirtualInputMgr:SendKeyEvent(true, kc, false, game)
                        VirtualInputMgr:SendKeyEvent(false, kc, false, game)
                    end
                end)
            end
            return true
        end
        Rage._equipSlot = equipSlot
        Rage._nextUsableSlot = nextUsableSlot
        Rage._whichSlotNow = whichSlotNow
    end)()
    local function encodeRageShot(camData)
        if tick() - (State.RageFireStamp or 0) > 0.03 then return false end
        local hitPart = State.RageFireHitPart
        local eyePos  = State.RageFireFromPos
        local aimPos  = State.RageFireAimPos
        if not (hitPart and hitPart.Parent and eyePos and aimPos) then return false end
        if not isSanePos(eyePos) or not isSanePos(hitPart.Position) then return false end
        if (hitPart.Position - eyePos).Magnitude > (400 - 5) then return false end
        local ignore = { lp.Character }
        local t = State.RageTarget or State.Target
        if t and t.Character then ignore[2] = t.Character end
        if not hasLOS(eyePos, hitPart.Position, ignore) then return false end
        local item = getEquippedItem(); if not item then return false end
        local okE, equipping = pcall(function() return item:IsEquipping() end)
        if okE and equipping then return false end
        if not (Rage._itemIsMelee and Rage._itemIsMelee(item)) then
            local okR, reloading = pcall(function() return (item._reload_cooldown or 0) > tick() end)
            if okR and reloading then return false end
            local okA, ammo = pcall(function() return item:Get("Ammo") end)
            if not okA or type(ammo) ~= "number" or ammo <= 0 then return false end
        end
        local now = tick()
        local interval = 0
        if Rage._fireInterval then interval = Rage._fireInterval() end
        if now - (State.RageLastFireTime or 0) < interval then return false end
        State.RageLastFireTime = now
        local eyeCF    = lookCF(eyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimPos, true, RAGE_CLAMP_FRAC, RAGE_JITTER_FRAC)
        State.Shots = State.Shots + 1
        return true
    end
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands  = {}
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, Config.RageVisCheck, true, true) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local d = 9999
                local sane = myRoot ~= nil and hrp ~= nil and isSanePos(hrp.Position)
                if sane then d = (hrp.Position - myRoot.Position).Magnitude end
                if (not sane) or d <= (Config.MaxDistance or 1200) then
                    table.insert(cands, { p = p, hp = hum.Health, d = d })
                end
            end
        end
        if #cands == 0 then return nil end
        if Config.RageHPPriority then
            table.sort(cands, function(a, b)
                if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
                return a.d < b.d
            end)
        else
            table.sort(cands, function(a, b) return a.d < b.d end)
        end
        return cands[1].p
    end
    Rage._findTarget = findTarget
    local function findTargetHeadSane()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands  = {}
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, Config.RageVisCheck, true, true) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hh  = p.Character:FindFirstChild("HitboxHead") or p.Character:FindFirstChild("Head")
                local headSane = false
                if hh and isSanePos(hh.Position) then headSane = true end
                local d = 9999
                if myRoot and hrp and isSanePos(hrp.Position) then d = (hrp.Position - myRoot.Position).Magnitude end
                table.insert(cands, { p = p, hp = hum.Health, d = d, s = headSane })
            end
        end
        if #cands == 0 then return nil end
        table.sort(cands, function(a, b)
            if a.s ~= b.s then return a.s end
            if Config.RageHPPriority and math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
            return a.d < b.d
        end)
        return cands[1].p
    end
    Rage._findTargetHeadSane = findTargetHeadSane
    local _meleeLogAt = 0
    local function meleeReadout()
        if Config.RageMeleeLog == false then return end
        local now = tick()
        if now - _meleeLogAt < 1 then return end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local item = lf and lf.EquippedItem
        if not item then return end
        if not (Rage._itemIsMelee and Rage._itemIsMelee(item)) then return end
        _meleeLogAt = now
        local mode = Config.RageMode or "Polar"
        if mode ~= "Polar" then
            print("[LuaHook] melee: the knife bot is POLAR-ONLY and rage mode is " .. mode
                .. " — no melee code runs at all in this mode. Switch Rage > Mode to Polar.")
            return
        end
        local why = State.RageKnifeStatus
        if why == nil then
            why = "NEVER REACHED (rage=" .. tostring(State.RageStatus) .. ")"
        end
        print("[LuaHook] melee=" .. tostring(why)
            .. " swings=" .. tostring(State.RageKnifeSwings or 0)
            .. " rage=" .. tostring(State.RageStatus)
            .. " target=" .. tostring(State.RageTarget and State.RageTarget.Name or "none"))
    end
    local function startTargetLoop()
        if _tgtConn then _tgtConn:Disconnect() end
        local lastPosMap, lastTimeMap = {}, {}
        _tgtConn = RunService.Heartbeat:Connect(function()
            if not Config.Rage then return end
            pcall(meleeReadout)
            local nowTime = tick()
            local safe = getSafePlayers() or {}
            for i = 1, #safe do
                local p = safe[i]
                if p ~= lp and p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local currentPos = pRoot.Position
                        if lastPosMap[p] and lastTimeMap[p] then
                            local dt = nowTime - lastTimeMap[p]
                            if dt > 0 then State.RageTrueVelocityMap[p] = (currentPos - lastPosMap[p]) / dt end
                        end
                        lastPosMap[p] = currentPos
                        lastTimeMap[p] = nowTime
                    end
                end
            end
            if Config.RageFastTargetSwitch and State.Target and not isValidTarget(State.Target, false, true, true) then
                State.Target = nil
            end
            State.Target = findTarget()
        end)
    end
    Rage._startTargetLoop = startTargetLoop
    local function startLabPoll()
        if _labConn then return end
        local lastHP = {}
        _labConn = RunService.Heartbeat:Connect(function()
            if not Config.RageLab then return end
            local safe = getSafePlayers() or {}
            for i = 1, #safe do
                local p = safe[i]
                if p ~= lp then
                    local c = p.Character
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local h, last = hum.Health, lastHP[p]
                        if last and h < last - 0.5 then
                            State.RageDealtTotal = (State.RageDealtTotal or 0) + (last - h)
                            if p == State.Target then State.Hits = State.Hits + 1 end
                        end
                        lastHP[p] = h
                    else
                        lastHP[p] = nil
                    end
                end
            end
        end)
    end
    Rage._startLabPoll = startLabPoll
    Rage._isCheater = function() return false end
    function Rage.init()
        for _, p in ipairs(getSafePlayers()) do bump(p) end
        Players.PlayerAdded:Connect(function(p)
            bump(p)
            p.CharacterAdded:Connect(function() bump(p) end)
        end)
        for _, p in ipairs(getSafePlayers()) do
            p.CharacterAdded:Connect(function() bump(p) end)
        end
        Players.PlayerRemoving:Connect(function(p)
            State.RageCharTokens[p] = nil
        end)
        lp.CharacterAdded:Connect(function()
            bump(lp)
            State.RageRealCF = nil; State.RageRealChar = nil
            State.RageParkDirty = false
            State.RageTarget = nil
        end)
        bump(lp)
        startLabPoll()
    end
    local _rageConn, _rageCharConn = nil, nil
    local _rageStepConn = nil
    local _rageRestoreName = "__lh_rage_restore"
    local _rageDiedConn = nil
    local _rageCooldownConn = nil
    local function fireInterval()
        return Config.RageFireRateOverride or 0
    end
    Rage._fireInterval = fireInterval
    local _preParkCF = nil
    local _identGet, _identSet, _identTried = nil, nil, false
    local function rawSetCFrame(hrp, cf)
        if not _identTried then
            _identTried = true
            pcall(function()
                local g = getthreadidentity or get_thread_identity
                local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
                if type(g) == "function" and type(s) == "function" then _identGet, _identSet = g, s end
            end)
        end
        if _identSet ~= nil then
            local okPrev, prev = pcall(_identGet)
            if okPrev then
                pcall(_identSet, 8)
                local wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
                if wrote then return true end
            end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local function displace(hrp, cf)
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        return rawSetCFrame(hrp, cf)
    end
    Rage._displace = displace
    local ORBIT_PRIME_S   = 0.07
    local ORBIT_JITTER_MAX = 0.25
    local ORBIT_JUMP      = 5
    local _orbHiding      = true
    local _orbPrimeUntil  = 0
    local ORB_IMMUNE_MAX_HOLD = 6.0
    local _orbImmuneSince, _orbImmuneTgt = 0, nil
    local _orbLastDisp    = nil
    local function voidAxis()
        local v = math.random(110000, 140000)
        if math.random(0, 1) == 0 then
            return -v
        end
        return v
    end
    local function rollVoid()
        return CFrame.new(voidAxis(), math.random(110000, 140000), voidAxis())
    end
    local function stepClears(cf, prev, minStep)
        if not prev then return true end
        return (cf.Position - prev.Position).Magnitude >= minStep
    end
    local function voidCFrame()
        local now = tick()
        if not Config.RageVoidMove then
            if (not State.RageVoidCF) or now >= (State.RageVoidNext or 0) then
                State.RageVoidCF   = rollVoid()
                State.RageVoidNext = now + 4 + math.random() * 4
            end
            return State.RageVoidCF
        end
        local prev = State.RageVoidCF
        local cf
        if Config.RageVoidJitterLocal then
            if (not State.RageVoidBase) or now >= (State.RageVoidNext or 0) then
                State.RageVoidBase = rollVoid()
                State.RageVoidNext = now + 4 + math.random() * 4
            end
            local base = State.RageVoidBase.Position
            local span = Config.RageVoidJitterStuds or 2000
            local function offset()
                local v = 500 + math.random() * (span - 500)
                if math.random(0, 1) == 0 then
                    return -v
                end
                return v
            end
            local tries = 0
            repeat
                cf = CFrame.new(base.X + offset(), math.max(base.Y + offset(), 110000), base.Z + offset())
                tries = tries + 1
            until tries >= 8 or stepClears(cf, prev, 600)
        else
            local minStep = Config.RageVoidMinStep or 25000
            local tries = 0
            repeat
                cf = rollVoid()
                tries = tries + 1
            until tries >= 8 or stepClears(cf, prev, minStep)
        end
        State.RageVoidCF    = cf
        State.RageVoidSteps = (State.RageVoidSteps or 0) + 1
        return cf
    end
    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        if Rage._itemIsMelee and Rage._itemIsMelee(it) then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    Rage._ensureReload = function(it)
        if it == nil then return "no item" end
        local okR, reloading = pcall(function() return (it._reload_cooldown or 0) > tick() end)
        if okR and reloading then return "waiting" end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        if okA and type(ammo) == "number" and ammo > 0 then return "loaded" end
        local okRes, reserve = pcall(function() return it:Get("AmmoReserve") end)
        if okRes and type(reserve) == "number" and reserve <= 0 then
            local okInf, inf = pcall(function()
                return it.ClientFighter ~= nil and it.ClientFighter:Get("InfiniteAmmoReserve") == true
            end)
            if not okInf or inf ~= true then return "dry" end
        end
        if tick() - (State.RageReloadLast or 0) < 0.5 then return "throttled" end
        State.RageReloadLast = tick()
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf ~= nil then
                task.spawn(function()
                    if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
                    pcall(function() lf:Input("StartReloading") end)
                    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
                end)
            end
        end)
        pcall(function() it:StartReloading() end)
        return "requested"
    end
    local _SLOT_INDEX = { Primary = 1, Secondary = 2 }
    Rage._weaponRecovery = function(it)
        local mode = Config.RageOnEmpty or "Reload"
        local okA, ammo = pcall(function() return it and it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then
            return Rage._ensureReload(it)
        end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local items = lf and lf.Items
        if type(items) ~= "table" then return Rage._ensureReload(it) end
        if tick() - (State.RageSwitchLast or 0) < 0.5 then return "swap-wait" end
        local pref = _SLOT_INDEX[Config.RagePreferredSlot or "Primary"] or 1
        local other = pref == 1 and 2 or 1
        for _, slot in ipairs({ pref, other }) do
            local w = items[slot]
            if w and w ~= it then
                local okW, wammo = pcall(function() return w:Get("Ammo") end)
                if okW and type(wammo) == "number" and wammo > 0 then
                    local busy = false
                    pcall(function()
                        if w:IsEquipping() then busy = true end
                    end)
                    pcall(function()
                        if (w._reload_cooldown or 0) > tick() then busy = true end
                    end)
                    if not busy then
                        State.RageSwitchLast = tick()
                        local okE = pcall(function() lf.EquipItem(lf, slot) end)
                        if okE then
                            State.AutoWeaponFails = 0
                            return "swap"
                        end
                        State.AutoWeaponFails = (State.AutoWeaponFails or 0) + 1
                    end
                end
            end
        end
        return Rage._ensureReload(it)
    end
    local _transportWatchStarted = false
    Rage._startTransportWatcher = function()
        if _transportWatchStarted then return end
        _transportWatchStarted = true
        task.spawn(function()
            local EF
            for _ = 1, 60 do
                local ps = lp and lp:FindFirstChildOfClass("PlayerScripts")
                if ps then
                    local ok, m = pcall(require, ps:WaitForChild("Modules", 5)
                        :WaitForChild("ClientReplicatedClasses", 5)
                        :WaitForChild("ClientDuel", 5)
                        :WaitForChild("DuelInterface", 5)
                        :WaitForChild("EliminationFeed", 5))
                    if ok and type(m) == "table" and type(m.Play) == "function" then EF = m break end
                end
                task.wait(1)
            end
            if not EF then return end
            local orig = EF.Play
            shared._LH_ElimFeedOrig = shared._LH_ElimFeedOrig or orig
            EF.Play = function(self, victim, eliminator, ...)
                local results = { pcall(orig, self, victim, eliminator, ...) }
                if not results[1] then return unpack(results, 2) end
                pcall(function()
                    if victim ~= lp then return end
                    if Config.RageRestoreMode ~= "auto" then return end
                    if eliminator == nil or typeof(eliminator) ~= "Instance" then return end
                    local tgt = State.RageTarget
                    local match = (tgt == eliminator)
                    if not match and tgt and eliminator.Name == tgt.Name then match = true end
                    if not match then return end
                    local now = tick()
                    if now - (State.RageLastLossAt or 0) < 3 then return end
                    State.RageLastLossAt = now
                    State.RageTransportSwitches = (State.RageTransportSwitches or 0) + 1
                    State.RageAutoTransport = (State.RageAutoTransport == "render") and "kicia" or "render"
                    local lib = _G["\76\72"]
                    if lib and lib.Notify then
                        pcall(function()
                            lib:Notify({
                                Title = "Park (Auto)",
                                Description = "Switched to " .. (State.RageAutoTransport == "render" and "render" or "kerp"),
                                Time = 4,
                            })
                        end)
                    end
                end)
                return unpack(results, 2)
            end
        end)
    end
    local _awLast = 0
    Rage.autoWeaponStep = function()
        if not Config.AutoWeaponEnabled then return end
        if Config.Rage then return end
        if (State.AutoWeaponFails or 0) >= 3 then return end
        if tick() - _awLast < 1 then return end
        _awLast = tick()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local items = lf and lf.Items
        if type(items) ~= "table" then return end
        local function itemName(w)
            local n
            pcall(function() n = w.Name end)
            if type(n) ~= "string" then pcall(function() n = w.Info and w.Info.Name end) end
            return n
        end
        local want = {
            [1] = Config.AutoWeaponPrimary or "",
            [2] = Config.AutoWeaponSecondary or "",
            [3] = Config.AutoWeaponMelee or "",
            [4] = Config.AutoWeaponUtility or "",
        }
        for slot = 1, 4 do
            local name = want[slot]
            if name ~= "" then
                if itemName(items[slot]) ~= name then
                    for src = 1, 4 do
                        if itemName(items[src]) == name then
                            State.RageSwitchLast = tick()
                            local okE = pcall(function() lf.EquipItem(lf, src) end)
                            if okE then
                                State.AutoWeaponFails = 0
                            else
                                State.AutoWeaponFails = (State.AutoWeaponFails or 0) + 1
                                State.RageSwitchLast = 0
                            end
                            return
                        end
                    end
                    return
                end
            end
        end
        State.AutoWeaponFails = 0
    end
    local function flankPoint(tgt, hh)
        if not tgt or not tgt.Character or not hh or not isSanePos(hh.Position) then return nil end
        local katana = Config.AvoidDeflect and isKatana(tgt)
        local shield = Config.RageShieldBackstab and isRiotShield(tgt)
        local stowed = Config.RageShieldBackstab and ownsRiotShield(tgt)
        if not (katana or shield or stowed) then return nil end
        local thrp = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not thrp then return nil end
        local look = thrp.CFrame.LookVector
        look = Vector3.new(look.X, 0, look.Z)
        if look.Magnitude < 1e-3 then return nil end
        local inv    = -look.Unit
        if not katana and not shield and stowed then inv = look.Unit end
        local anchor = hh.Position
        local kf     = killFloor()
        local dist   = shield and 2.5 or 3.0
        local ignore = { tgt.Character, lp.Character }
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local flank = anchor + inv * dist
        local wr = workspace:Raycast(anchor, inv * dist, rp)
        if wr then flank = wr.Position - inv * 0.5 end
        flank = Vector3.new(flank.X, math.max(flank.Y, kf + 3), flank.Z)
        if not hasLOS(flank, hh.Position, ignore) then return nil end
        return flank
    end
    local _shootEnum
    local function polarFire(eyePos, aimPos, hh)
        local reach = 1e9
        if hh and hh.Parent then reach = (hh.Position - eyePos).Magnitude end
        if not (reach <= 395) then
            State.RageBlankCanary = State.RageBlankCanary + 1
            return
        end
        local it = getEquippedItem()
        if not it then return end
        if Config.RageDirectFire then
            if Config.RageRateLimit then
                if tick() - (State.RageLastFireTime or 0) < fireInterval() then return end
                State.RageLastFireTime = tick()
            end
            pcall(function()
                it._shoot_cooldown = 0
                it._shoot_cooldown_no_ammo = 0
                it._last_shot = tick() - 1
            end)
            if not (Rivals.Ready and Rivals.Enums and Rivals.Util) then return end
            if _shootEnum == nil then
                pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end)
            end
            if _shootEnum == nil then return end
            local okId, objId = pcall(function() return it:Get("ObjectID") end)
            if not okId or not objId then return end
            local eyeCF    = Rage._lookCF(eyePos, aimPos)
            local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
            local taps = Config.RageTapsPerFrame
            if type(taps) ~= "number" then taps = 1 end
            taps = math.max(1, math.min(math.floor(taps), math.floor(Config.RageTaps or 6)))
            local sent     = 0
            local rayCast  = false
            pcall(function() rayCast = it.Info.IsRaycast == true end)
            State.RageForging = true
            pcall(function()
                local remote = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
                for _ = 1, taps do
                    if not (hh and hh.Parent) then break end
                    local inner = {}
                    Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, 0.30, 1.0)
                    local env = { [utf8.char(1)] = inner }
                    if rayCast then env[utf8.char(2)] = true end
                    remote:FireServer(objId, _shootEnum, env, nil)
                    sent = sent + 1
                end
            end)
            State.RageForging = false
            State.Shots = State.Shots + sent
            return
        end
        if not weaponReady(it) then return end
        if not hh or not hh.Parent or not isSanePos(hh.Position) then return end
        local hpos = hh.Position
        if (hpos - eyePos).Magnitude > (400 - 5) then return end
        local ignore = { lp.Character }
        local tgt = State.RageTarget or State.Target
        if tgt and tgt.Character then ignore[2] = tgt.Character end
        if not hasLOS(eyePos, hpos, ignore) then return end
        if tick() - (State.RageLastFireTime or 0) < fireInterval() then return end
        State.RageFireFromPos = eyePos
        State.RageFireAimPos  = aimPos
        State.RageFireHitPart = hh
        State.RageFireStamp   = tick()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        task.spawn(function()
            if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
            pcall(function() lf:Input("StartShooting") end)
            if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
        end)
    end
    local function clearFireSolution()
        State.RageFireFromPos = nil
        State.RageFireAimPos  = nil
        State.RageFireHitPart = nil
        State.RageFireStamp   = 0
    end
    ;(function()
        local function orbitVantage(aimPos, ignore, kf, knife)
            State.OrbitAngle = ((State.OrbitAngle or 0) + 2.39996) % (math.pi * 2)
            local base = Config.RageCombatOrbitRadius or 60
            local radii
            if knife then
                radii = { math.max(base, 75), 95 }
            else
                radii = { base, base * 0.6, math.min(base * 1.5, 380) }
            end
            for _, r in ipairs(radii) do
                for i = 0, 5 do
                    local ang    = State.OrbitAngle + i * (math.pi / 3)
                    local jitter = 0
                    if Config.RageCombatOrbitJitter then jitter = (math.random() - 0.5) * 14 end
                    local h = (Config.RageCombatOrbitHeight or 8) + jitter
                    local pos = Vector3.new(aimPos.X + math.cos(ang) * r,
                        math.max(aimPos.Y + h, kf + 6),
                        aimPos.Z + math.sin(ang) * r)
                    if isSanePos(pos) and not posIsOOB(pos) and hasLOS(pos, aimPos, ignore) then
                        return pos
                    end
                end
            end
            return nil
        end
        local function orbitVoid(hrp, status)
            State.RageStatus = status
            State.OrbitVantage = nil
            State.OrbitVantageUntil = 0
            State.RageFiring = false
            State.RageVoidActive = true
            clearFireSolution()
            _orbHiding = true
            _orbPrimeUntil = 0
            _orbLastDisp = nil
            Rage._displace(hrp, voidCFrame())
        end
        local _orbDeflectSince = 0
        local function orbitTick(ch, hrp, tgt)
            local kf = killFloor()
            if not tgt or not tgt.Character then
                return orbitVoid(hrp, "No target")
            end
            local tc   = tgt.Character
            local thrp = tc:FindFirstChild("HumanoidRootPart")
            local hh   = tc:FindFirstChild("HitboxHead") or tc:FindFirstChild("Head")
            if not hh or not isSanePos(hh.Position) then
                return orbitVoid(hrp, "Hiding")
            end
            if Config.AvoidDeflect and isDeflecting(tgt) then
                if _orbDeflectSince == 0 then _orbDeflectSince = tick() end
                if tick() - _orbDeflectSince < 1.5 then
                    return orbitVoid(hrp, "Deflecting")
                end
            else
                _orbDeflectSince = 0
            end
            if not weaponReady(getEquippedItem()) then
                local act = Rage._weaponRecovery(getEquippedItem())
                if act == "dry" then
                    return orbitVoid(hrp, "Dry")
                end
                if act == "swap" or act == "swap-wait" then
                    return orbitVoid(hrp, "Swapping")
                end
                return orbitVoid(hrp, "Reloading")
            end
            local aimPos = hh.Position
            if posIsOOB(aimPos) or aimPos.Y < kf + 1 then
                return orbitVoid(hrp, "Hiding")
            end
            local ignore = { tc, lp.Character }
            local vantage, status = nil, nil
            local flank = flankPoint(tgt, hh)
            if not flank and thrp and Config.RageKnifeBackstab and isLocalKnife() then
                local inv = -thrp.CFrame.LookVector
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = ignore
                local f  = thrp.Position + inv * 3.0
                local wr = workspace:Raycast(thrp.Position, inv * 3.0, rp)
                if wr then f = wr.Position - inv * 0.5 end
                local cand = Vector3.new(f.X, math.max(f.Y, kf + 3), f.Z)
                if isSanePos(cand) and not posIsOOB(cand) and hasLOS(cand, hh.Position, ignore) then
                    flank = cand
                end
            end
            if flank then
                vantage = flank
                State.OrbitVantage = nil
                if isRiotShield(tgt) then
                    status = "Anti-riot"
                elseif isKatana(tgt) then
                    status = "Katana flank"
                else
                    status = "Backstab"
                end
            else
                local knife = isEnemyKnife(tgt)
                local held  = State.OrbitVantage
                if (not held) or tick() >= (State.OrbitVantageUntil or 0) or not hasLOS(held, aimPos, ignore) then
                    local v = orbitVantage(aimPos, ignore, kf, knife)
                    if v then
                        State.OrbitVantage = v
                        State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                        held = v
                    elseif held and hasLOS(held, aimPos, ignore) then
                        State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                    else
                        held = nil
                    end
                end
                if held then
                    vantage = held
                    if knife then status = "Orbit (kept dist)" else status = "Orbit" end
                end
            end
            if not vantage or not isSanePos(vantage) or posIsOOB(vantage) then
                return orbitVoid(hrp, "Orbit (hiding)")
            end
            State.RageStatus = status or "Orbit"
            State.RageVoidActive = false
            local jumped = _orbLastDisp == nil or (vantage - _orbLastDisp).Magnitude > ORBIT_JUMP
            _orbLastDisp = vantage
            if _orbHiding or jumped then
                _orbHiding = false
                local extra = 0
                if Config.RageHideJitter ~= false then extra = math.random() * ORBIT_JITTER_MAX end
                _orbPrimeUntil = tick() + ORBIT_PRIME_S + extra
            end
            Rage._displace(hrp, CFrame.new(vantage))
            local holdFire = false
            if Config.RageSkipImmune ~= false then holdFire = isSpawnProtected(tgt) end
            if not holdFire then
                _orbImmuneSince, _orbImmuneTgt = 0, nil
            else
                local nowI = tick()
                if _orbImmuneTgt ~= tgt then
                    _orbImmuneSince, _orbImmuneTgt = nowI, tgt
                end
                if nowI - _orbImmuneSince > ORB_IMMUNE_MAX_HOLD then
                    holdFire = false
                    State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
                end
            end
            if holdFire then
                State.RageFiring = false
                State.RageStatus = "Protected — vantage held, holding fire"
            elseif tick() < _orbPrimeUntil then
                State.RageFiring = false
                State.RageStatus = "Priming"
            else
                State.RageFiring = true
                local eye = vantage + Vector3.new(0, Config.RagePBEyeUp or 3, 0)
                polarFire(eye, aimPos, hh)
            end
            pcall(Visuals.notifyTarget, tgt)
        end
        local function rageTick(ch, hrp, tgt)
            if (Config.RageMode or "Polar") ~= "Orbit" then
                State.RageStatus = "Mode error"
                return
            end
            orbitTick(ch, hrp, tgt)
        end
        Rage._rageTick = rageTick
    end)()
    local function onLocalDied()
        pcall(function()
            if tick() - State.RageBelowPlaneLast < 0.5 then
                State.RageBelowPlaneDeaths = State.RageBelowPlaneDeaths + 1
                State.RageBelowPlaneLast = 0
            end
            if not Config.Rage then
                return
            end
            if Config.RageMode == "Orbit" then
                return
            end
            if tick() - (State.RageKnifeHintLast or 0) < 90 then
                return
            end
            local knifed = false
            local tgt = State.RageTarget
            if tgt and tgt.Parent and isEnemyKnife(tgt) then
                knifed = true
            else
                local dpos = nil
                local real = State.RageRealCF
                if real then
                    dpos = real.Position
                else
                    local ch = lp.Character
                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        dpos = hrp.Position
                    end
                end
                if dpos then
                    for _, plr in ipairs(getSafePlayers()) do
                        if plr ~= lp and not (Config.TeamCheck and isTeammate(plr)) then
                            local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if r and (r.Position - dpos).Magnitude <= 18 and isEnemyKnife(plr) then
                                knifed = true
                                break
                            end
                        end
                    end
                end
            end
            if not knifed then
                return
            end
            State.RageKnifeHintLast = tick()
            local lib = _G["\76\72"]
            if lib and lib.Notify then
                pcall(function() lib:Notify("Knifed by a melee player â€” switch Rage mode to Orbit (our knife counter)", 5) end)
            end
        end)
    end
    local function hookDied(char)
        if _rageDiedConn then
            _rageDiedConn:Disconnect()
            _rageDiedConn = nil
        end
        if not char then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            _rageDiedConn = hum.Died:Connect(onLocalDied)
        end
    end
    local function restoreHome(pin)
        if State.RagePostPark then State.RageOrderCanary = State.RageOrderCanary + 1 end
        local ch = lp.Character
        if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF
        _preParkCF = nil
        if back == nil then
            local real = State.RageRealCF
            if real and State.RageRealChar == ch then
                back = CFrame.new(real.Position) * hrp.CFrame.Rotation
            end
        end
        pcall(function()
            if back then hrp.CFrame = back end
            State.RageParkDirty = false
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    local function startRage()
        if _rageConn then return end
        if Rage._setPhysicsFlags then pcall(Rage._setPhysicsFlags, true) end
        hookDied(lp.Character)
        if not _rageCharConn then
            _rageCharConn = lp.CharacterAdded:Connect(function()
                State.RageRealCF = nil; State.RageRealChar = nil
                State.RageVoidCF = nil; State.RageVoidBase = nil
                State.RageParkDirty = false; State.RageLastParkPos = nil
                hookDied(lp.Character)
            end)
        end
        local function rageRestoreActive()
            if not Config.Rage then return false end
            if not State.RageInMatch then return false end
            if State.RageRealChar ~= lp.Character then return false end
            return true
        end
        pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
        RunService:BindToRenderStep(_rageRestoreName, Enum.RenderPriority.First.Value - 1000, function()
            State.RagePostPark = false
            if rageRestoreActive() then restoreHome(true) end
        end)
        if not _rageStepConn then
            _rageStepConn = RunService.Stepped:Connect(function()
                State.RagePostPark = false
                if rageRestoreActive() then restoreHome(true) end
            end)
        end
        local function defeatCooldowns()
            if not Config.Rage then return end
            local it = getEquippedItem()
            if not it then return end
            it._shoot_cooldown = 0
            it._shoot_cooldown_no_ammo = 0
            if (it._last_shot or 0) > tick() + 1 then it._last_shot = tick() - 1 end
            if it._shot_but_ammo_hasnt_updated then it._shot_but_ammo_hasnt_updated = false end
        end
        if not _rageCooldownConn then
            _rageCooldownConn = RunService.Heartbeat:Connect(function()
                pcall(defeatCooldowns)
            end)
        end
        _rageConn = RunService.Heartbeat:Connect(function()
            if not Config.Rage or (Config.RageMode or "Polar") ~= "Orbit" then
                if Rage._setPhysicsFlags then pcall(Rage._setPhysicsFlags, false) end
                restoreHome(false)
                pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
                if _rageConn then _rageConn:Disconnect(); _rageConn = nil end
                if _rageStepConn then _rageStepConn:Disconnect(); _rageStepConn = nil end
                if _rageCooldownConn then _rageCooldownConn:Disconnect(); _rageCooldownConn = nil end
                if _rageCharConn then _rageCharConn:Disconnect(); _rageCharConn = nil end
                if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
                State.RageRealCF = nil; State.RageRealChar = nil
                State.RageTarget = nil; State.RageVoidCF = nil; State.RageVoidBase = nil
                State.RageParkDirty = false; State.RageLastParkPos = nil
                State.RageInMatch = false
                State.OrbitVantage = nil; State.OrbitVantageUntil = 0
                clearFireSolution()
                return
            end
            local ch  = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then
                if tick() - State.RageBelowPlaneLast < 0.5 then
                    State.RageBelowPlaneDeaths = State.RageBelowPlaneDeaths + 1
                    State.RageBelowPlaneLast = 0
                end
                clearFireSolution()
                return
            end
            if State.RageParkDirty and State.RageRealChar == ch then
                State.RageParkLatchCanary = State.RageParkLatchCanary + 1
                if State.RageLastParkPos then
                    State.RageLatchStuds = (hrp.Position - State.RageLastParkPos).Magnitude
                end
            elseif isSanePos(hrp.Position) then
                State.RageRealCF = hrp.CFrame
                State.RageRealChar = ch
            end
            State.RageInMatch = inMatch()
            if not State.RageInMatch then
                if not isSanePos(hrp.Position) then restoreHome(false) end
                State.RageTarget = nil
                State.RageStatus = "Lobby"
                State.RageFiring = false
                clearFireSolution()
                return
            end
            if not State.RageRealCF or State.RageRealChar ~= ch then
                State.RageStatus = "Waiting"
                State.RageFiring = false
                clearFireSolution()
                return
            end
            local hum0 = ch:FindFirstChildOfClass("Humanoid")
            if hum0 and hum0.Health <= 0 then
                if not isSanePos(hrp.Position) then restoreHome(false) end
                State.RageFiring = false
                State.RageVoidActive = false
                State.RageStatus = "Dead"
                clearFireSolution()
                return
            end
            local tgt = State.RageTarget
            do
                if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt)
                    or (Config.TeamCheck and isTeammate(tgt))) then
                    tgt = nil
                end
                if not tgt then tgt = Rage._findTarget() end
                State.RageTarget = tgt
            end
            State.RagePostPark = true
            Rage._rageTick(ch, hrp, tgt)
            local anchor    = State.RageRealCF
            local displaced = false
            if anchor then displaced = (hrp.Position - anchor.Position).Magnitude > 0.001 end
            State.RageParkDirty = displaced
            if displaced then State.RageLastParkPos = hrp.Position end
        end)
    end
    function Rage.enable()
        Config.Rage = true
        if Rage._startTargetLoop then Rage._startTargetLoop() end
        if (Config.RageMode or "Polar") ~= "Orbit" then
            if Rage._polarCoreStart then Rage._polarCoreStart() end
            return
        end
        startRage()
    end
    function Rage.disable()
        Config.Rage = false
        if Rage._polarCoreStop then Rage._polarCoreStop() end
        State.RagePostPark = false
        pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
        if _rageConn then _rageConn:Disconnect(); _rageConn = nil end
        if _rageStepConn then _rageStepConn:Disconnect(); _rageStepConn = nil end
        if _rageCooldownConn then _rageCooldownConn:Disconnect(); _rageCooldownConn = nil end
        if _rageCharConn then _rageCharConn:Disconnect(); _rageCharConn = nil end
        if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
        restoreHome(false)
        State.RageRealCF = nil; State.RageRealChar = nil
        State.RageTarget = nil; State.RageVoidCF = nil; State.RageVoidBase = nil
        State.RageParkDirty = false; State.RageLastParkPos = nil
        State.RageInMatch = false
        State.OrbitVantage = nil; State.OrbitVantageUntil = 0
        State.RageFiring = false
        State.RageVoidActive = false
        State.RageStatus = "Idle"
        clearFireSolution()
    end
    function Rage.unload()
        Rage.disable()
        if _tgtConn then pcall(function() _tgtConn:Disconnect() end); _tgtConn = nil end
        if _labConn then pcall(function() _labConn:Disconnect() end); _labConn = nil end
    end
    Rage._encodeRageShot = encodeRageShot
end)()
;(function()
    local PolarCore = {}
    local _realCF, _realChar = nil, nil
    local _voidCF     = nil
    local _target     = nil
    local _firing     = false
    local _inMatch    = false
    local _deflectSince = 0
    local _shots      = 0
    local _voidSteps  = 0
    local _shootEnum  = nil
    local _useItem    = nil
    local _notified   = nil
    local _conn, _stepConn, _charConn = nil, nil, nil
    local RENDER_NAME = "LuaHook_PolarCore_Restore"
    local CAMERA_NAME = "LuaHook_PolarCore_CamAnchor"
    local SANE_POS_LIMIT  = 100000
    local MAX_DISTANCE    = 1200
    local VOID_HIDE       = true
    local POLAR_TAPS_SANE = 6
    local EYE_UP_SANE     = 2.5
    local KILL_PLANE_BUF  = 200
    local PARK_DRIFT_STUDS = 1.5
    local VOID_MOVE       = true
    local VOID_MIN_STEP   = 25000
    local VOID_R_MIN      = 110000
    local VOID_R_MAX      = 140000
    local HIDE_WHEN_UNREACHABLE = true
    local DEFLECT_MAX_HOLD = 1.5
    local IMMUNE_MAX_HOLD = 6.0
    local _immuneSince = 0
    local _immuneTgt   = nil
    local EYE_MUZZLE_SEP  = 0.07
    local RAGE_CLAMP_FRAC = 0.30
    local function parity()
        return Config.RagePolarParity ~= false
    end
    local _preParkCF = nil
    local FFLAGS_ON  = { DFIntS2PhysicsSenderRate = "120", DFIntAssemblyHistoryBufferSize = "2147483648", DFIntAssemblyHistorySkipSize = "0" }
    local FFLAGS_OFF = { DFIntS2PhysicsSenderRate = "15",  DFIntAssemblyHistoryBufferSize = "15",         DFIntAssemblyHistorySkipSize = "8" }
    local _fpdhOriginal = nil
    local _flagsOn = false
    local _physSet  = false
    local _physLive = false
    local function fflagApi()
        local set, get, name = nil, nil, "none"
        pcall(function()
            if type(setfflag) == "function" then
                set, name = setfflag, "setfflag"
            elseif type(setfastflag) == "function" then
                set, name = setfastflag, "setfastflag"
            elseif type(set_fflag) == "function" then
                set, name = set_fflag, "set_fflag"
            end
            if type(getfflag) == "function" then
                get = getfflag
            elseif type(getfastflag) == "function" then
                get = getfastflag
            end
        end)
        return set, get, name
    end
    local function readsBack(get, name, want)
        if get == nil then return nil end
        local ok, v = pcall(get, name)
        if not ok or v == nil then return nil end
        if tostring(v) == want then return true end
        local got, req = tonumber(v), tonumber(want)
        if got == nil or req == nil then return false end
        if req >= 2147483647 then return got >= 2147483646 end
        return got == req
    end
    local function setPhysicsFlags(on)
        if on == _flagsOn then return end
        if on and Config.RagePhysicsFlags == false then return end
        _flagsOn = on
        if _fpdhOriginal == nil then
            local prev = workspace.FallenPartsDestroyHeight
            if prev ~= prev then prev = -500 end
            _fpdhOriginal = prev
        end
        local fpdhOk = false
        pcall(function()
            if on then
                workspace.FallenPartsDestroyHeight = 0 / 0
            else
                workspace.FallenPartsDestroyHeight = _fpdhOriginal
            end
            local v = workspace.FallenPartsDestroyHeight
            fpdhOk = v ~= v
        end)
        local set, get, setName = fflagApi()
        if set == nil then
            _physSet, _physLive = false, false
            State.RagePhysVerified = false
            State.RagePhysRate = "no fflag setter — history decimation stays stock"
            return
        end
        local want = FFLAGS_OFF
        if on then want = FFLAGS_ON end
        local threw, detail = false, ""
        local keyOk = false
        for name, value in want do
            local wrote = pcall(set, name, value)
            if not wrote then threw = true end
            local seen = readsBack(get, name, value)
            local tag = "?"
            if seen == true then tag = "ok" end
            if seen == false then tag = "REFUSED" end
            if not wrote then tag = "THREW" end
            if name == "DFIntAssemblyHistorySkipSize" and seen == true then keyOk = true end
            detail = detail .. string.sub(name, 5) .. "=" .. tag .. " "
        end
        _physSet  = on and not threw
        _physLive = _physSet and keyOk and fpdhOk
        State.RagePhysVerified = _physLive
        State.RagePhysSet = _physSet
        State.RagePhysDetail = detail .. "FPDH=" .. tostring(fpdhOk)
        local how = "verified"
        if not on then
            how = "off"
        elseif threw then
            how = "THREW"
        elseif not fpdhOk then
            how = "FPDH refused"
        elseif not keyOk then
            how = "SkipSize unproven"
        end
        State.RagePhysRate = setName .. " " .. how
    end
    local glueActive
    local function restoreMode()
        if glueActive ~= nil and glueActive() then return "kicia" end
        local m = Config.RageRestoreMode
        if m == "kicia" or m == "render" or m == "none" then return m end
        return "none"
    end
    local _identGet, _identSet = nil, nil
    local _identTried = false
    local function identEnsure()
        if _identTried then return _identSet ~= nil end
        _identTried = true
        pcall(function()
            local g = getthreadidentity or get_thread_identity
            local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
            if type(g) == "function" and type(s) == "function" then
                _identGet, _identSet = g, s
            end
        end)
        State.RageRawSet = _identSet ~= nil
        return _identSet ~= nil
    end
    local function rawSetCFrame(hrp, cf)
        identEnsure()
        if _identSet ~= nil then
            local okPrev, prev = pcall(_identGet)
            if okPrev then
                pcall(_identSet, 8)
                local wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
                if wrote then return true end
            end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local _rvCF = nil
    local GLUE_PARK_OFF = Vector3.new(0, -0.7, 0.05)
    local GLUE_CHAR0 = {
        [utf8.char(0)] = -9e37,
        [utf8.char(1)] = 0,
        [utf8.char(2)] = 0,
        [utf8.char(3)] = -math.pi / 2,
        [utf8.char(4)] = math.pi,
        [utf8.char(5)] = math.pi,
    }
    local GLUE_CHAR1 = {
        [utf8.char(0)] = 0,
        [utf8.char(1)] = -90000000,
        [utf8.char(2)] = 0,
        [utf8.char(3)] = -math.pi / 2,
        [utf8.char(4)] = math.pi,
        [utf8.char(5)] = math.pi,
    }
    local GLUE_CHAR3 = {
        [utf8.char(0)] = 0,
        [utf8.char(1)] = 1,
        [utf8.char(2)] = 0,
        [utf8.char(3)] = 0,
        [utf8.char(4)] = 0,
        [utf8.char(5)] = 0,
    }
    local _glueHit       = nil
    local _glueWeld      = nil
    local _glueWeldPart1 = nil
    local _glueAnchored  = nil
    local _gluePrev   = nil
    local _gluePrevOk = false
    local function gumMode()
        local m = Config.RageGumMode
        if m ~= "off" and m ~= "lite" and m ~= "on" then
            local g = Config.RageGlueMode
            if g == "lite" or g == "off" then
                m = g
            elseif g == "full" then
                m = "on"
            else
                m = "off"
            end
        end
        if m == "off" and Config.RagePartGlue == true then return "on" end
        return m
    end
    local _liteHit    = nil
    local _liteDriven = false
    local _glueDriven = false
    local TRANSLOCATE_PULSES_PER_BURST = 2
    local TRANSLOCATE_ARM_FRAMES = 12
    local _translocateFireFrames = 0
    local _translocateNext = false
    local _translocateBurstPulses = 0
    local _translocatePart = nil
    local POISON_ARM_FRAMES = 2
    local POISON_PER_BURST  = 1
    local _poisonFireFrames = 0
    local _poisonBlips      = 0
    local function setRepRoot(part, target)
        if _identSet == nil then return false end
        local ok, seen = false, nil
        pcall(function()
            local prev = _identGet()
            _identSet(8)
            local wrote = pcall(sethiddenproperty, part, "PhysicsRepRootPart", target)
            if wrote and type(gethiddenproperty) == "function" then
                local okR, v = pcall(gethiddenproperty, part, "PhysicsRepRootPart")
                if okR then seen = v end
            end
            _identSet(prev)
            ok = wrote
        end)
        if not ok then return false end
        if seen == nil then
            State.RageGlueVerified = "unverified (no gethiddenproperty)"
            return true
        end
        if seen ~= target then
            State.RageGlueVerified = "REFUSED (read back " .. tostring(seen) .. ")"
            return false
        end
        State.RageGlueVerified = "verified"
        return true
    end
    local function liteRelease()
        if _liteHit == nil then return end
        _liteHit    = nil
        _liteDriven = false
        State.RageGlueBound = false
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = hrp
        if _gluePrevOk then back = _gluePrev end
        setRepRoot(hrp, back)
        State.RageGlueVerified = "released"
    end
    local function liteAcquire(hit, predicting, melee)
        if gumMode() ~= "lite" or predicting or melee then
            liteRelease()
            return false
        end
        if type(sethiddenproperty) ~= "function" then
            liteRelease()
            return false
        end
        if not identEnsure() then
            liteRelease()
            return false
        end
        if hit == nil or hit.Parent == nil then
            liteRelease()
            return false
        end
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then
            liteRelease()
            return false
        end
        if not _gluePrevOk and type(gethiddenproperty) == "function" then
            local okP, v = pcall(gethiddenproperty, hrp, "PhysicsRepRootPart")
            if okP then
                _gluePrev   = v
                _gluePrevOk = true
            end
        end
        if not setRepRoot(hrp, hit) then
            liteRelease()
            return false
        end
        _liteHit    = hit
        _liteDriven = true
        State.RageGlueBound = true
        return true
    end
    glueActive = function()
        return _glueHit ~= nil
    end
    local function glueSetup(hit)
        local weld = hit:FindFirstChildOfClass("WeldConstraint")
        if weld == nil then weld = hit:FindFirstChild("WeldConstraint") end
        if weld == nil then return end
        _glueWeld      = weld
        _glueWeldPart1 = weld.Part1
        _glueAnchored  = hit.Anchored
        pcall(function()
            if _glueWeldPart1 ~= nil then weld.Part1 = nil end
            hit.Anchored = true
        end)
    end
    local function glueTeardown()
        local weld, part1, hit, anch = _glueWeld, _glueWeldPart1, _glueHit, _glueAnchored
        _glueWeld, _glueWeldPart1, _glueAnchored = nil, nil, nil
        pcall(function()
            if weld ~= nil and weld.Parent ~= nil and part1 ~= nil then weld.Part1 = part1 end
            if hit ~= nil and hit.Parent ~= nil and anch ~= nil then hit.Anchored = anch end
        end)
    end
    local function glueRelease()
        State.RageTranslocating = false
        if _glueHit == nil then return end
        glueTeardown()
        _glueHit    = nil
        _glueDriven = false
        State.RageGlueBound = false
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = hrp
        if _gluePrevOk then
            back = _gluePrev
        end
        setRepRoot(hrp, back)
        State.RageGlueVerified = "released"
    end
    local function glueAcquire(hit)
        if gumMode() ~= "on" then return nil end
        if type(sethiddenproperty) ~= "function" then return nil end
        if not identEnsure() then return nil end
        if hit == nil or hit.Parent == nil then return nil end
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return nil end
        if not _gluePrevOk and type(gethiddenproperty) == "function" then
            local okP, v = pcall(gethiddenproperty, hrp, "PhysicsRepRootPart")
            if okP then
                _gluePrev   = v
                _gluePrevOk = true
            end
        end
        if not setRepRoot(hrp, hit) then
            glueRelease()
            return nil
        end
        if _glueHit ~= hit then
            glueTeardown()
            _glueHit = hit
            glueSetup(hit)
        end
        if _rvCF == nil then
            _rvCF = CFrame.new(math.random(-100000, -10000), 100000, math.random(-100000, 10000))
        end
        local rv = _rvCF.Position
        local moved = pcall(function() hit.CFrame = CFrame.new(rv) end)
        if not moved then
            glueRelease()
            return nil
        end
        _glueDriven = true
        State.RageGlueBound = true
        return rv
    end
    local function displace(hrp, cf)
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        return rawSetCFrame(hrp, cf)
    end
    local _prevPark    = nil
    local _prevParkTgt = nil
    local _lastPark    = nil
    local PRIME_S         = 0.07
    local HIDE_JITTER_MAX = 0.25
    local _hiding     = false
    local _primeUntil = 0
    local HACK_SPEED = 120
    local HACK_ACCUM = 0.15
    local _hackTag   = {}
    local _lastSeen  = {}
    local _hackAccum = {}
    local function tickHackers(dt)
        if dt <= 0 or dt > 0.5 then return end
        for _, p in Players:GetPlayers() do
            if p ~= lp and not _hackTag[p] then
                local c = p.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    if not isSanePos(pos) then
                        _hackTag[p] = true
                    else
                        local last = _lastSeen[p]
                        if last then
                            if (pos - last).Magnitude / dt > HACK_SPEED then
                                local a = (_hackAccum[p] or 0) + dt
                                _hackAccum[p] = a
                                if a >= HACK_ACCUM then _hackTag[p] = true end
                            else
                                _hackAccum[p] = 0
                            end
                        end
                        _lastSeen[p] = pos
                    end
                end
            end
        end
    end
    local PRED_LEAD    = 0.15
    local PRED_MIN     = 0.05
    local PRED_MAX     = 120.0
    local PRED_SAMPLES = 5
    local PRED_NEEDED  = 3
    local _predHidden  = {}
    local _predDur     = {}
    local _predLast    = {}
    local PRED_MIN_PRES = 0.004
    local _predShown   = {}
    local _predPres    = {}
    local function isSanePos(p)
        return p == p
            and math.abs(p.X) < SANE_POS_LIMIT
            and math.abs(p.Y) < SANE_POS_LIMIT
            and math.abs(p.Z) < SANE_POS_LIMIT
    end
    local function tickPredict()
        local now = os.clock()
        for _, p in Players:GetPlayers() do
            if p ~= lp then
                local c = p.Character
                local hh = nil
                if c then hh = c:FindFirstChild("HitboxHead") or c:FindFirstChild("Head") end
                isSpawnProtected(p)
                local rp   = c and c:FindFirstChild("HumanoidRootPart") or nil
                local mine = hh ~= nil and hh == _glueHit
                if c == nil and _predHidden[p] ~= nil then
                    _predHidden[p] = nil
                    _predShown[p] = nil
                end
                local ref  = rp
                if ref == nil and not mine then ref = hh end
                if ref ~= nil and isSanePos(ref.Position) then
                    if hh ~= nil and not mine then _predLast[p] = hh.Position end
                    local since = _predHidden[p]
                    if since ~= nil then
                        _predHidden[p] = nil
                        _predShown[p] = now
                        local d = now - since
                        if d >= PRED_MIN and d <= PRED_MAX then
                            local r = _predDur[p]
                            if r == nil then
                                r = {}
                                _predDur[p] = r
                            end
                            r[#r + 1] = d
                            if #r > PRED_SAMPLES then table.remove(r, 1) end
                        end
                    end
                elseif ref ~= nil and _predHidden[p] == nil then
                    _predHidden[p] = now
                    local shown = _predShown[p]
                    if shown ~= nil then
                        _predShown[p] = nil
                        local dp = now - shown
                        if dp >= PRED_MIN_PRES and dp <= PRED_MAX then
                            local rr = _predPres[p]
                            if rr == nil then
                                rr = {}
                                _predPres[p] = rr
                            end
                            rr[#rr + 1] = dp
                            if #rr > PRED_SAMPLES then table.remove(rr, 1) end
                        end
                    end
                end
            end
        end
    end
    local function predMedian(p)
        local r = _predDur[p]
        if r == nil or #r < PRED_NEEDED then return nil end
        local s = {}
        for i = 1, #r do s[i] = r[i] end
        table.sort(s)
        return s[math.floor(#s / 2) + 1]
    end
    local function aboutToResurface(p)
        local since = _predHidden[p]
        if since == nil then return false end
        local m = predMedian(p)
        if m == nil then return false end
        local elapsed = os.clock() - since
        if elapsed > m + PRED_LEAD then return false end
        return elapsed >= m - PRED_LEAD
    end
    local function resurfaceIn(p)
        local since = _predHidden[p]
        if since == nil then return nil end
        local m = predMedian(p)
        if m == nil then return nil end
        return m - (os.clock() - since)
    end
    local function preFireLead()
        local ok, v = pcall(function() return lp:GetNetworkPing() end)
        local ping = 0.05
        if ok and type(v) == "number" and v == v and v > 0 then ping = v end
        if ping > 0.2 then ping = 0.2 end
        return ping
    end
    local function medianOf(tab, p, need)
        local r = tab[p]
        if r == nil or #r < need then return nil end
        local t = {}
        for i = 1, #r do t[i] = r[i] end
        table.sort(t)
        return t[math.floor(#t / 2) + 1]
    end
    local function publishPredict(p)
        if p == nil then
            State.RagePredTarget = nil
            return
        end
        State.RagePredTarget = p.Name
        State.RagePredHide   = predMedian(p) or 0
        State.RagePredHideN  = _predDur[p] and #_predDur[p] or 0
        State.RagePredAtk    = medianOf(_predPres, p, 2) or 0
        State.RagePredAtkN   = _predPres[p] and #_predPres[p] or 0
        local since = _predHidden[p]
        if since ~= nil then
            State.RagePredPhase = "HIDDEN"
            State.RagePredFor   = os.clock() - since
        else
            local shown = _predShown[p]
            State.RagePredPhase = "PRESENT"
            State.RagePredFor   = shown ~= nil and (os.clock() - shown) or 0
        end
        State.RagePredDue    = resurfaceIn(p) or 0
        State.RagePredWindow = aboutToResurface(p)
        local c  = p.Character
        local rr = c and c:FindFirstChild("HumanoidRootPart")
        State.RagePredMag = rr and rr.Position.Magnitude or 0
    end
    local function posInPart(pos, part)
        if not part or not part.Parent then return false end
        local lpv = part.CFrame:PointToObjectSpace(pos)
        local s = part.Size * 0.5
        return math.abs(lpv.X) <= s.X and math.abs(lpv.Y) <= s.Y and math.abs(lpv.Z) <= s.Z
    end
    local function posIsOOB(pos)
        local ok, result = pcall(function()
            for _, p in CollectionService:GetTagged("OutOfBoundsSafePart") do
                if posInPart(pos, p) then return false end
            end
            for _, p in CollectionService:GetTagged("OutOfBoundsPart") do
                if posInPart(pos, p) then return true end
            end
            return false
        end)
        return ok and result == true
    end
    local function killFloor()
        local ok, val = pcall(function() return Workspace.FallenPartsDestroyHeight end)
        if ok and type(val) == "number" and val == val then return val + KILL_PLANE_BUF end
        return -400
    end
    local function envIdOf(player)
        local id = nil
        pcall(function()
            local fc = Rivals.Fighter
            if fc == nil then return end
            local f = (player == lp) and fc.LocalFighter or (fc._player_to_fighter and fc._player_to_fighter[player])
            if f == nil then return end
            id = f:Get("EnvironmentID")
            if id == nil and f.Entity ~= nil then id = f.Entity:Get("EnvironmentID") end
        end)
        return id
    end
    local function isTeammate(player)
        if player == lp then return true end
        local myEnv, theirEnv = envIdOf(lp), envIdOf(player)
        if myEnv ~= nil and theirEnv ~= nil and myEnv ~= theirEnv then return true end
        local a = lp:GetAttribute("TeamID")
        local b = player:GetAttribute("TeamID")
        if a == nil or b == nil then
            if lp.Team ~= nil and player.Team ~= nil then return lp.Team == player.Team end
            return false
        end
        return a == b
    end
    local function isAlive(player)
        local c = player.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        return h ~= nil and h.Health > 0
    end
    local function isProtected(player)
        if not player or not player.Character then return false end
        if player.Character:FindFirstChildOfClass("ForceField") then return true end
        if not Config.RageSkipImmune then return false end
        return isSpawnProtected(player)
    end
    local function inMatch()
        local envOk = false
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
        end)
        if envOk then return true end
        if lp:GetAttribute("TeamID") ~= nil then return true end
        if lp.Team ~= nil then return true end
        return false
    end
    local function getEquippedItem()
        local ok, result = pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf and lf.EquippedItem then return lf.EquippedItem end
            return nil
        end)
        if ok then return result end
        return nil
    end
    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        local magazine = true
        pcall(function() magazine = it.Info.MaxAmmo ~= nil end)
        if not magazine then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands = {}
        local unreachable = {}
        for _, p in Players:GetPlayers() do
            if p ~= lp and not isTeammate(p) and isAlive(p) then
                local c = p.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = 9999
                    if myRoot then d = (hrp.Position - myRoot.Position).Magnitude end
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    local health = 9999
                    if hum then health = hum.Health end
                    local entry = { p = p, hp = health, d = d, prot = isProtected(p),
                                    hack = _hackTag[p] == true }
                    if isSanePos(hrp.Position) and d <= MAX_DISTANCE then
                        table.insert(cands, entry)
                    else
                        table.insert(unreachable, entry)
                    end
                end
            end
        end
        if #cands == 0 then cands = unreachable end
        if #cands == 0 then return nil end
        table.sort(cands, function(a, b)
            if Config.RagePrioritizeHackers ~= false and a.hack ~= b.hack then return a.hack end
            if a.prot ~= b.prot then return b.prot end
            if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
            return a.d < b.d
        end)
        return cands[1].p
    end
    local function voidAxis()
        local v = math.random(VOID_R_MIN, VOID_R_MAX)
        if math.random(0, 1) == 0 then return -v end
        return v
    end
    local VOID_DEEP_AXIS   = 1073741824
    local VOID_DEEP_JITTER = 0.4
    local _voidOrder       = { 1, 2, 3 }
    local function voidDeep()
        return Config.RageVoidDepth ~= "shallow"
    end
    local function deepMag(allowNeg)
        local m = VOID_DEEP_AXIS * (1 + math.random() * VOID_DEEP_JITTER)
        if allowNeg and math.random(0, 1) == 1 then return -m end
        return m
    end
    local function rollVoidDeep()
        local ang = math.random() * math.pi * 2
        local r   = math.random(1000, 1500)
        local x   = math.cos(ang) * r
        local y   = math.random(1000, 1500)
        local z   = math.sin(ang) * r
        local o   = _voidOrder
        o[1], o[2], o[3] = 1, 2, 3
        for i = 3, 2, -1 do
            local j = math.random(1, i)
            o[i], o[j] = o[j], o[i]
        end
        for i = 1, math.random(1, 3) do
            local axis = o[i]
            if axis == 1 then
                x = deepMag(true)
            elseif axis == 2 then
                y = deepMag(false)
            else
                z = deepMag(true)
            end
        end
        return CFrame.new(x, y, z)
    end
    local function rollVoid()
        if voidDeep() then return rollVoidDeep() end
        return CFrame.new(voidAxis(), math.random(VOID_R_MIN, VOID_R_MAX), voidAxis())
    end
    local function voidCFrame()
        local prev = _voidCF
        local cf = rollVoid()
        if VOID_MOVE and prev then
            local tries = 0
            while tries < 8 and (cf.Position - prev.Position).Magnitude < VOID_MIN_STEP do
                cf = rollVoid()
                tries = tries + 1
            end
        end
        _voidCF = cf
        _voidSteps = _voidSteps + 1
        return cf
    end
    local TRANSLOCATE_OFFSET = -5
    local TRANSLOCATE_OFFSET = -5
    local TRANSLOCATE_FALLBACK_MIN = 10000
    local TRANSLOCATE_FALLBACK_MAX = 90000
    local function attackTranslocateCFrame(origin)
        local ok, result = pcall(function()
            local part = _translocatePart
            if part == nil or part.Parent == nil
               or not CollectionService:HasTag(part, "OutOfBoundsPart")
               or part:GetAttribute("KillDelay") ~= 0 then
                part = nil
                for _, candidate in CollectionService:GetTagged("OutOfBoundsPart") do
                    if candidate:GetAttribute("KillDelay") == 0 then
                        part = candidate
                        break
                    end
                end
                _translocatePart = part
            end
            if part ~= nil then
                return part.CFrame * CFrame.new(0, -part.Size.Y / 2 + TRANSLOCATE_OFFSET, 0)
            end
            local ang = math.random() * math.pi * 2
            local dist = TRANSLOCATE_FALLBACK_MIN
                + math.random() * (TRANSLOCATE_FALLBACK_MAX - TRANSLOCATE_FALLBACK_MIN)
            return CFrame.new(origin.X + math.cos(ang) * dist, origin.Y, origin.Z + math.sin(ang) * dist)
        end)
        if not ok then
            _translocatePart = nil
            return nil
        end
        return result
    end
    local PARK_UP_STUDS = 12
    local _parkRP = nil
    local function parkHasLOS(from, to, ourChar, tgtChar)
        if _parkRP == nil then
            _parkRP = RaycastParams.new()
            _parkRP.FilterType = Enum.RaycastFilterType.Exclude
        end
        _parkRP.FilterDescendantsInstances = { ourChar, tgtChar }
        local res = Workspace:Raycast(from, to - from, _parkRP)
        if not res then return true end
        return (res.Position - to).Magnitude < 3
    end
    local function eyeRise(fromPos, tgtChar)
        local rise = EYE_UP_SANE
        pcall(function()
            if _parkRP == nil then
                _parkRP = RaycastParams.new()
                _parkRP.FilterType = Enum.RaycastFilterType.Exclude
            end
            _parkRP.FilterDescendantsInstances = { lp.Character, tgtChar }
            local res = Workspace:Raycast(fromPos, Vector3.new(0, EYE_UP_SANE, 0), _parkRP)
            if res ~= nil then
                local room = (res.Position.Y - fromPos.Y) - 0.25
                if room < rise then
                    rise = math.max(room, 0.15)
                    State.RageEyeClampFrames = (State.RageEyeClampFrames or 0) + 1
                end
            end
        end)
        return rise
    end
    local MELEE_DWELL_S    = 0.07
    local _meleeDwellStart = nil
    local function pointBlank(hp)
        local y = math.max(hp.Y, killFloor() + 3)
        if y > hp.Y + 0.001 then
            State.RageParkClampFrames = (State.RageParkClampFrames or 0) + 1
        end
        return Vector3.new(hp.X, y, hp.Z)
    end
    local function meleeProfile(it)
        local prof = nil
        pcall(function()
            local info = it.Info
            if info == nil then return end
            if info.MaxAmmo ~= nil then return end
            local heavy = info.CriticalDamage ~= nil and type(info.HeavyAttackCooldown) == "number"
            prof = { heavy = heavy }
        end)
        return prof
    end
    local function meleeStrike(firePark, hpos, hh, tgt)
        local it = getEquippedItem()
        if it == nil then State.RageKnifeStatus = "no item" return false end
        local prof = meleeProfile(it)
        if prof == nil then State.RageKnifeStatus = "not a melee item" return false end
        local now = tick()
        if _meleeDwellStart == nil then _meleeDwellStart = now end
        if now - _meleeDwellStart < MELEE_DWELL_S then
            State.RageKnifeStatus = "dwell"
            return false
        end
        local actionName, animName = "StartShooting", "Attack1"
        if prof.heavy then
            actionName, animName = "StartAiming", "HeavyAttack1"
        end
        local actionEnum, animEnum = nil, nil
        pcall(function() actionEnum = Rivals.Enums:ToEnum(actionName) end)
        pcall(function() animEnum = Rivals.Enums:ToEnum(animName) end)
        local tc = tgt.Character
        local trp = tc and tc:FindFirstChild("HumanoidRootPart")
        if trp == nil then State.RageKnifeStatus = "target has no root" return false end
        local vp, vy = trp.CFrame:ToOrientation()
        if prof.heavy and Config.RageKnifeCamForge ~= false then
            ViewAngle.forge(vp, vy)
        end
        local eyePos   = firePark + Vector3.new(0, eyeRise(firePark, tgt and tgt.Character or nil), 0)
        local eyeCF    = Rage._lookCF(eyePos, hpos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local sent = false
        State.RageFireFromPos = eyePos
        State.RageFireAimPos  = hpos
        State.RageFireHitPart = hh
        State.RageFireStamp   = tick()
        pcall(function()
            it._attack_cooldown = 0
            it._last_attack = tick() - 1
        end)
        local function lowerToId2()
            local g = getthreadidentity or get_thread_identity or getidentity or getthreadcontext
            local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
            if g == nil or s == nil then return nil end
            local prev = nil
            pcall(function() prev = g() end)
            if prev == nil or prev == 2 then return nil end
            if not pcall(s, 2) then return nil end
            return function() pcall(s, prev) end
        end
        local function atId2(fn)
            local restoreId = lowerToId2()
            local ok, res = pcall(fn)
            if restoreId ~= nil then restoreId() end
            return ok, res
        end
        local hitData = { part = hh }
        if prof.heavy and type(it.HeavyAttack) == "function" then
            local ok = atId2(function() it:HeavyAttack(eyeCF, eyeCF, hitData) end)
            if ok then sent = true end
        elseif (not prof.heavy) and type(it.Attack) == "function" then
            local ok = atId2(function() it:Attack(eyeCF, eyeCF, hitData) end)
            if ok then sent = true end
        end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not sent then
            if Config.RageMeleeAsk ~= false then
                if lf == nil then State.RageKnifeStatus = "no LocalFighter" return false end
                local restoreId = lowerToId2()
                local ok, err = pcall(function() lf:Input(actionName) end)
                if restoreId ~= nil then restoreId() end
                local ran = false
                pcall(function() ran = (it._attack_cooldown or 0) > 0 end)
                sent = ok and ran
                if not ok then
                    State.RageKnifeStatus = "Input failed: " .. tostring(err)
                elseif not ran then
                    State.RageKnifeStatus = "item refused " .. actionName
                end
            else
                if _useItem == nil then
                    pcall(function() _useItem = ReplicatedStorage.Remotes.Replication.Fighter.UseItem end)
                end
                local okId, objId = pcall(function() return it:Get("ObjectID") end)
                if not okId or objId == nil then
                    pcall(function() objId = it.Info.ObjectID end)
                end
                if _useItem == nil then State.RageKnifeStatus = "no UseItem remote" return false end
                if objId == nil then State.RageKnifeStatus = "no ObjectID" return false end
                if actionEnum == nil then
                    State.RageKnifeStatus = "no " .. actionName .. " enum"
                    return false
                end
                State.RageForging = true
                local ferr = nil
                local fok = atId2(function()
                    local inner = {}
                    Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, hpos, true, RAGE_CLAMP_FRAC, 1.0)
                    local env = { [utf8.char(1)] = inner }
                    if animEnum ~= nil then env[utf8.char(2)] = animEnum end
                    _useItem:FireServer(objId, actionEnum, env, nil)
                    sent = true
                end)
                State.RageForging = false
                if not fok then State.RageKnifeStatus = "FireServer failed: " .. tostring(ferr) end
            end
        end
        if sent then
            _shots = _shots + 1
            State.Shots = State.Shots + 1
            State.RageKnifeSwings = (State.RageKnifeSwings or 0) + 1
            State.RageKnifeStatus = "swinging " .. actionName
        else
            State.RageKnifeStatus = "send failed"
        end
        return sent
    end
    local function polarFire(eyePos, aimPos, hh, taps)
        local it = getEquippedItem()
        if not it then return 0 end
        pcall(function()
            it._shoot_cooldown = 0
            it._shoot_cooldown_no_ammo = 0
            it._last_shot = tick() - 1
        end)
        if _shootEnum == nil then
            pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end)
        end
        if _shootEnum == nil then return 0 end
        if _useItem == nil then
            pcall(function() _useItem = ReplicatedStorage.Remotes.Replication.Fighter.UseItem end)
        end
        if _useItem == nil then return 0 end
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then return 0 end
        local fireEyePos = eyePos
        local base = eyePos - Vector3.new(0, EYE_UP_SANE, 0)
        local ftgt = State.RageTarget or State.Target
        local rise = eyeRise(base, ftgt and ftgt.Character or nil)
        if rise < EYE_UP_SANE then fireEyePos = base + Vector3.new(0, rise, 0) end
        local eyeCF    = Rage._lookCF(fireEyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local sent     = 0
        local rayCast = false
        pcall(function() rayCast = it.Info.IsRaycast == true end)
        local glued = glueActive()
        State.RageForging = true
        pcall(function()
            for _ = 1, taps do
                local inner = {}
                if glued then
                    inner[utf8.char(0)] = GLUE_CHAR0
                    inner[utf8.char(1)] = GLUE_CHAR1
                    inner[utf8.char(2)] = hh
                    inner[utf8.char(3)] = GLUE_CHAR3
                else
                    Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
                end
                local env = { [utf8.char(1)] = inner }
                if rayCast and not parity() then env[utf8.char(2)] = true end
                _useItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        State.RageForging = false
        _shots = _shots + sent
        State.Shots = State.Shots + sent
        return sent
    end
    local function tapsPerFrame()
        local n = Config.RageTapsPerFrame
        if type(n) ~= "number" then return 1 end
        if n < 1 then return 1 end
        if n > POLAR_TAPS_SANE then return POLAR_TAPS_SANE end
        return math.floor(n)
    end
    local ATTACK_GAP_HOLD = 0.30
    local _attackGapTgt = nil
    local _attackGapUntil = 0
    local _attackReadyTgt = nil
    local function clearAttackGap()
        _attackGapTgt = nil
        _attackGapUntil = 0
    end
    local function resetAttackContinuity()
        clearAttackGap()
        _attackReadyTgt = nil
    end
    local function holdAttackGap(hrp, tgt, status)
        if Config.RageAttackContinuity == false then return false end
        local now = os.clock()
        if _attackGapTgt ~= tgt then
            if _attackReadyTgt ~= tgt or _prevPark == nil or _prevParkTgt ~= tgt then
                return false
            end
            _attackGapTgt = tgt
            _attackGapUntil = now + ATTACK_GAP_HOLD
        elseif now > _attackGapUntil then
            clearAttackGap()
            return false
        end
        _firing = false
        State.RageFiring = false
        State.RageStatus = status
        State.RageVoidActive = VOID_HIDE
        _lastPark = nil
        _meleeDwellStart = nil
        _translocateNext = false
        _translocateBurstPulses = 0
        _translocateFireFrames = 0
        _poisonFireFrames = 0
        _poisonBlips = 0
        liteRelease()
        glueRelease()
        if VOID_HIDE then
            displace(hrp, voidCFrame())
        end
        return true
    end
    local function hide(hrp, status)
        resetAttackContinuity()
        _firing = false
        State.RageFiring = false
        State.RageStatus = status
        State.RageVoidActive = VOID_HIDE
        _prevPark    = nil
        _prevParkTgt = nil
        _lastPark    = nil
        _hiding     = true
        _primeUntil = 0
        _meleeDwellStart = nil
        _translocateNext = false
        _translocateBurstPulses = 0
        _translocateFireFrames = 0
        _poisonFireFrames = 0
        _poisonBlips = 0
        liteRelease()
        glueRelease()
        if VOID_HIDE then
            displace(hrp, voidCFrame())
        end
    end
    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt)
                    or isProtected(tgt)) then
            tgt = nil
        end
        if not tgt then tgt = findTarget() end
        _target = tgt
        State.RageTarget = tgt
        publishPredict(tgt)
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        local holdFire = isProtected(tgt)
        if not holdFire then
            _immuneSince, _immuneTgt = 0, nil
        else
            local now = tick()
            if _immuneTgt ~= tgt then
                _immuneSince, _immuneTgt = now, tgt
            end
            if now - _immuneSince > IMMUNE_MAX_HOLD then
                holdFire = false
                State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
            end
        end
        if Config.AvoidDeflect and isDeflecting(tgt) then
            local now = tick()
            if _deflectSince == 0 then _deflectSince = now end
            if now - _deflectSince < DEFLECT_MAX_HOLD then return hide(hrp, "Deflecting") end
        else
            _deflectSince = 0
        end
        local it = getEquippedItem()
        if not weaponReady(it) then
            local act = Rage._weaponRecovery(it)
            if act == "dry" then
                return hide(hrp, "Dry")
            end
            if act == "swap" or act == "swap-wait" then
                return hide(hrp, "Swapping")
            end
            return hide(hrp, "Reloading")
        end
        local hh = tgt.Character:FindFirstChild("HitboxHead") or tgt.Character:FindFirstChild("Head")
        if not hh then return hide(hrp, "Hiding") end
        if _hiding then
            _hiding = false
            local extra = 0
            if Config.RageHideJitter ~= false then
                extra = math.random() * HIDE_JITTER_MAX
            end
            _primeUntil = tick() + PRIME_S + extra
        end
        local trp  = tgt.Character:FindFirstChild("HumanoidRootPart")
        local mine = (hh == _glueHit)
        local hpos = hh.Position
        if mine and trp ~= nil then hpos = trp.Position end
        local predicting = false
        local voidFire   = false
        local rv         = nil
        if not isSanePos(hpos) then
            local pre = nil
            if Config.RagePredictResurface ~= false and aboutToResurface(tgt) then pre = _predLast[tgt] end
            if pre == nil or not isSanePos(pre) then
                if holdAttackGap(hrp, tgt, "Holding target swap") then
                    return nil
                end
                return hide(hrp, "Head voided")
            end
            hpos = pre
            predicting = true
            if Config.RageGumVoidFire ~= false and gumMode() == "on"
               and meleeProfile(it) == nil then
                rv = glueAcquire(hh)
                if rv ~= nil then
                    predicting = false
                    voidFire   = true
                end
            end
        end
        _firing = true
        State.RageFiring = not holdFire
        State.RageVoidActive = false
        local melee = meleeProfile(it) ~= nil
        local park
        if melee then
            local tc = tgt.Character
            local trp = tc and tc:FindFirstChild("HumanoidRootPart")
            if trp and (it.name == "Knife" or (meleeProfile(it) and meleeProfile(it).heavy)) then
                park = trp.Position - (trp.CFrame.LookVector * 1.2) + Vector3.new(0, 0.6, 0)
            else
                park = hpos + (trp and (trp.CFrame.LookVector * -0.8) or Vector3.new(0, -0.5, 0))
            end
        else
            park = pointBlank(hpos)
        end
        if posIsOOB(hpos) or posIsOOB(park) or not isSanePos(park) then
            if holdAttackGap(hrp, tgt, "Holding target swap") then
                return nil
            end
            return hide(hrp, "Hiding")
        end
        clearAttackGap()
        if Config.RageParkLift ~= false and not melee then
            local lifted = park + Vector3.new(0, PARK_UP_STUDS, 0)
            if isSanePos(lifted) and not posIsOOB(lifted)
               and parkHasLOS(lifted, hpos, ch, tgt.Character) then
                park = lifted
            end
        end
        local aimPos = hpos
        if rv == nil and not predicting and not melee then rv = glueAcquire(hh) end
        if rv == nil then liteAcquire(hh, predicting, melee) end
        if rv ~= nil then
            park   = rv + GLUE_PARK_OFF
            aimPos = hh.Position
        else
            glueRelease()
        end
        local firePark = nil
        if _prevPark ~= nil and _prevParkTgt == tgt then firePark = _prevPark end
        if restoreMode() ~= "kicia" then firePark = park end
        local translocateReady = Config.RageAttackTranslocate ~= false
            and restoreMode() == "kicia"
            and not predicting and not holdFire and not melee and firePark ~= nil
            and not voidFire
            and (parity() or tick() >= _primeUntil)
        local startingTranslocate = translocateReady
            and _translocateNext
            and _translocateBurstPulses < TRANSLOCATE_PULSES_PER_BURST
        local translocateCF = nil
        if startingTranslocate then
            translocateCF = attackTranslocateCFrame(hrp.Position)
        end
        local poisonCF = nil
        if translocateCF == nil
           and Config.RageGatePoison ~= false
           and voidDeep()
           and not predicting and not holdFire and not melee and firePark ~= nil
           and _poisonBlips < POISON_PER_BURST
           and _poisonFireFrames >= POISON_ARM_FRAMES then
            poisonCF = rollVoidDeep()
        end
        local desiredCFrame = CFrame.new(park)
        if translocateCF ~= nil then
            desiredCFrame = translocateCF
        elseif poisonCF ~= nil then
            desiredCFrame = poisonCF
        end
        local parked = displace(hrp, desiredCFrame)
        if parked and translocateCF == nil and poisonCF == nil then
            _prevPark, _prevParkTgt = park, tgt
            _lastPark = CFrame.new(park)
        elseif not parked then
            _prevPark, _prevParkTgt = nil, nil
            _lastPark = nil
        end
        if translocateCF ~= nil then
            _translocateNext = false
            if startingTranslocate then
                _translocateBurstPulses = _translocateBurstPulses + 1
                State.RageTranslocateBaits = (State.RageTranslocateBaits or 0) + 1
                _translocateFireFrames = 0
            end
            State.RageFiring = false
            State.RageTranslocating = parked
            if parked then
                State.RageStatus = "Translocating"
            else
                State.RageStatus = "Translocate failed"
            end
        elseif poisonCF ~= nil then
            _translocateNext = false
            State.RageFiring = false
            if parked then
                _poisonBlips = _poisonBlips + 1
                _poisonFireFrames = 0
                State.RagePoisonBlips = (State.RagePoisonBlips or 0) + 1
                State.RageStatus = "Poisoning"
            else
                State.RageStatus = "Poison failed"
            end
        elseif predicting then
            _translocateNext = false
            local lead = nil
            if Config.RagePredictPrefire ~= false and firePark ~= nil then
                lead = resurfaceIn(tgt)
            end
            if lead ~= nil and lead <= preFireLead() and lead > -PRED_LEAD then
                local sent = polarFire(firePark + Vector3.new(0, EYE_UP_SANE, 0), aimPos, hh, tapsPerFrame())
                if sent > 0 then
                    _attackReadyTgt = tgt
                    _poisonFireFrames = _poisonFireFrames + 1
                    State.RagePreFires = (State.RagePreFires or 0) + 1
                end
                State.RageStatus = "Prefiring resurface"
            else
                State.RageFiring = false
                State.RageStatus = "Predicting resurface"
            end
        elseif holdFire then
            _translocateNext = false
            State.RageStatus = "Protected — parked, holding fire"
        elseif firePark == nil then
            _translocateNext = false
            State.RageFiring = false
            State.RageStatus = "Priming"
            _meleeDwellStart = nil
        elseif (not parity()) and (tick() < _primeUntil) then
            _translocateNext = false
            State.RageFiring = false
            State.RageStatus = "Priming"
            _meleeDwellStart = nil
        elseif melee and Config.RageKnifeBot ~= false then
            _translocateNext = false
            if meleeStrike(firePark, aimPos, hh, tgt) then
                _attackReadyTgt = tgt
                State.RageStatus = "Melee"
            else
                State.RageFiring = false
                State.RageStatus = "Melee (cooldown)"
            end
        else
            local sent = polarFire(firePark + Vector3.new(0, EYE_UP_SANE, 0), aimPos, hh, tapsPerFrame())
            if sent > 0 then
                _attackReadyTgt = tgt
                _translocateFireFrames = _translocateFireFrames + 1
                _poisonFireFrames = _poisonFireFrames + 1
            end
            if voidFire and sent > 0 then
                State.RageVoidFires = (State.RageVoidFires or 0) + 1
            end
            _translocateNext = sent > 0 and parked and not melee
                and _translocateFireFrames >= TRANSLOCATE_ARM_FRAMES
                and _translocateBurstPulses < TRANSLOCATE_PULSES_PER_BURST
                and Config.RageAttackTranslocate ~= false
            State.RageStatus = "Attacking"
            if voidFire then State.RageStatus = "Attacking (gum void prefire)" end
        end
        if _notified ~= tgt then
            _notified = tgt
            pcall(Visuals.notifyTarget, tgt)
        end
    end
    local function restoreHome(pin)
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF
        _preParkCF = nil
        pcall(function()
            if back then hrp.CFrame = back end
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall
                   and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    local function cameraAnchor()
        if Config.RageCameraAnchor == false then return end
        local back = _preParkCF
        if back == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local delta = back.Position - hrp.Position
        if not isSanePos(delta) then return end
        Camera.CFrame = Camera.CFrame + delta
    end
    local function reparkAfterRender()
        local cf = _lastPark
        if cf == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        displace(hrp, cf)
    end
    Players.PlayerRemoving:Connect(function(p)
        _hackTag[p]   = nil
        _lastSeen[p]  = nil
        _hackAccum[p] = nil
        _predHidden[p] = nil
        _predDur[p]    = nil
        _predLast[p]   = nil
    end)
    function PolarCore.start()
        if _conn then return end
        _firing = false
        resetAttackContinuity()
        setPhysicsFlags(true)
        _notified = nil
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        RunService:BindToRenderStep(CAMERA_NAME, Enum.RenderPriority.Camera.Value + 5, function()
            pcall(cameraAnchor)
        end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value - 1000, function()
            if _firing and restoreMode() == "none" then return end
            restoreHome(false)
        end)
        _stepConn = RunService.Stepped:Connect(function()
            if _firing then
                local pol = restoreMode()
                if pol == "render" then return reparkAfterRender() end
                if pol ~= "kicia" then return end
            end
            restoreHome(true)
        end)
        _charConn = lp.CharacterAdded:Connect(function()
            pcall(glueTeardown)
            _glueHit = nil
            _gluePrevOk = false
            _glueDriven = false
            _liteHit = nil
            _liteDriven = false
            _translocateNext = false
            _translocateBurstPulses = 0
            _translocateFireFrames = 0
            _poisonFireFrames = 0
            _poisonBlips = 0
            _translocatePart = nil
            State.RageGlueBound = false
            State.RageTranslocating = false
            _realCF = nil
            _realChar = nil
            _voidCF = nil
            _target = nil
            _notified = nil
            _firing = false
            resetAttackContinuity()
            _preParkCF = nil
            _prevPark, _prevParkTgt = nil, nil
            _lastPark = nil
            _hiding, _primeUntil = true, 0
        end)
        _conn = RunService.Heartbeat:Connect(function(dt)
            State.RageTranslocating = false
            tickHackers(dt or 0)
            tickPredict()
            if _glueHit ~= nil and not _glueDriven then
                pcall(glueRelease)
            end
            _glueDriven = false
            if _liteHit ~= nil and not _liteDriven then
                pcall(liteRelease)
            end
            _liteDriven = false
            State.RageGumMode = gumMode()
            if not Config.Rage or (Config.RageMode or "Polar") ~= "Polar" then
                PolarCore.stop()
                return
            end
            local ch  = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then return end
            if _preParkCF == nil and isSanePos(hrp.Position) then
                _realCF   = hrp.CFrame
                _realChar = ch
            end
            if _lastPark ~= nil and _firing and restoreMode() == "none" then
                local ok, d, dy = pcall(function()
                    local off = hrp.Position - _lastPark.Position
                    return off.Magnitude, off.Y
                end)
                if ok and d == d and d > PARK_DRIFT_STUDS then
                    State.RageParkDriftFrames = (State.RageParkDriftFrames or 0) + 1
                    State.RageParkDrift = math.floor(d)
                    State.RageParkDriftY = math.floor(dy or 0)
                end
            end
            _inMatch = inMatch()
            State.RageInMatch = _inMatch
            if not _inMatch then
                _target = nil
                _firing = false
                resetAttackContinuity()
                _translocateNext = false
                _translocateBurstPulses = 0
                _translocateFireFrames = 0
                State.RageFiring = false
                State.RageTarget = nil
                State.RageStatus = "Lobby"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            if not _realCF or _realChar ~= ch then
                _firing = false
                resetAttackContinuity()
                _translocateNext = false
                _translocateBurstPulses = 0
                _translocateFireFrames = 0
                State.RageFiring = false
                State.RageStatus = "Waiting"
                return
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                _firing = false
                resetAttackContinuity()
                _translocateNext = false
                _translocateBurstPulses = 0
                _translocateFireFrames = 0
                State.RageFiring = false
                State.RageVoidActive = false
                State.RageStatus = "Dead"
                pcall(glueRelease)
                pcall(liteRelease)
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            polarTick(ch, hrp)
        end)
    end
    function PolarCore.stop()
        pcall(liteRelease)
        pcall(glueRelease)
        setPhysicsFlags(false)
        pcall(ViewAngle.restore)
        if _conn then _conn:Disconnect(); _conn = nil end
        if _stepConn then _stepConn:Disconnect(); _stepConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        _firing = false
        resetAttackContinuity()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            if _realCF and _realChar == lp.Character then
                pcall(function() hrp.CFrame = CFrame.new(_realCF.Position) * hrp.CFrame.Rotation end)
            elseif not isSanePos(hrp.Position) then
                pcall(function() hrp.CFrame = CFrame.new(0, 100, 0) end)
            end
        end
        _realCF = nil; _realChar = nil; _target = nil; _voidCF = nil; _notified = nil
        _translocateNext = false
        _translocateBurstPulses = 0
        _translocateFireFrames = 0
        _poisonFireFrames = 0
        _poisonBlips = 0
        _translocatePart = nil
        State.RageFiring = false
        State.RageVoidActive = false
        State.RageTranslocating = false
        State.RageTarget = nil
        State.RageInMatch = false
        State.RageStatus = "Idle"
    end
    PolarCore.shots     = function() return _shots end
    PolarCore.voidSteps = function() return _voidSteps end
    Rage._polarCoreStart = PolarCore.start
    Rage._polarCoreStop  = PolarCore.stop
    Rage._setPhysicsFlags = setPhysicsFlags
    function Rage._physDiag()
        local set, get, setName = fflagApi()
        print("[LuaHook] fflag api: setter=" .. setName .. "  getter=" .. tostring(get ~= nil))
        print("[LuaHook] flags:  " .. tostring(State.RagePhysDetail or "(never set — is rage on?)"))
        print("[LuaHook] summary: " .. tostring(State.RagePhysRate or "off")
              .. "   set=" .. tostring(_physSet) .. "  verified=" .. tostring(_physLive))
        print("[LuaHook] immune-hold overrides: " .. tostring(State.RageImmuneOverride or 0))
        print("[LuaHook] gum: mode=" .. tostring(gumMode())
              .. "  (RageGumMode=" .. tostring(Config.RageGumMode)
              .. ", legacy RageGlueMode=" .. tostring(Config.RageGlueMode)
              .. ", RagePartGlue=" .. tostring(Config.RagePartGlue)
              .. ", voidFire=" .. tostring(Config.RageGumVoidFire ~= false) .. ")"
              .. "  liteBound=" .. tostring(_liteHit ~= nil)
              .. "  BOUND=" .. tostring(State.RageGlueBound == true)
              .. "  readback=" .. tostring(State.RageGlueVerified or "n/a")
              .. "  (sethiddenproperty=" .. tostring(type(sethiddenproperty) == "function")
              .. ", gethiddenproperty=" .. tostring(type(gethiddenproperty) == "function")
              .. ", identity=" .. tostring(_identSet ~= nil) .. ")")
        local rvTxt = "unrolled"
        if _rvCF ~= nil then rvTxt = tostring(_rvCF.Position) end
        print("[LuaHook] rendezvous: " .. rvTxt
              .. "   glued to: " .. tostring(_glueHit or _liteHit)
              .. "   (full=" .. tostring(_glueHit ~= nil) .. ", lite=" .. tostring(_liteHit ~= nil) .. ")")
        print("[LuaHook] attack translocate: enabled=" .. tostring(Config.RageAttackTranslocate ~= false)
              .. "  active=" .. tostring(State.RageTranslocating == true)
              .. "  next=" .. tostring(_translocateNext)
              .. "  burst=" .. tostring(_translocateBurstPulses)
              .. "/" .. tostring(TRANSLOCATE_PULSES_PER_BURST)
              .. "  part=" .. tostring(_translocatePart))
        print("[LuaHook] restore mode: " .. restoreMode()
              .. "   (Config.RageRestoreMode=" .. tostring(Config.RageRestoreMode)
              .. ", glue forces kicia=" .. tostring(glueActive())
              .. ", fires from " .. tostring(restoreMode() == "kicia") .. "=prev-frame park)")
        print("[LuaHook] gum void prefire (S45): allowed=" .. tostring(Config.RageGumVoidFire ~= false
                  and gumMode() == "on")
              .. "   shots sent through a hide=" .. tostring(State.RageVoidFires or 0)
              .. "   (0 against a deep-voider means the seam never ran — check the gum mode above first)")
        return restoreMode()
    end
    Rage._gumDiag = Rage._physDiag
end)()
