-- =============================================================================
-- ARCH LUA V3 + RCLC PREMIUM FULL PORT (Compkiller UI)
-- Merged: All original Arch features + all RCLC features
-- =============================================================================

repeat task.wait() until game:IsLoaded()

local success, err = pcall(function()

-- ============================================================
-- CORE SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UIS               = game:GetService("UserInputService")
local UserInputService  = UIS
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local camera  = Workspace.CurrentCamera

pcall(function()
    local r = ReplicatedStorage:FindFirstChild("SendLikelySpeakingUsers")
    if r and r:IsA("RemoteEvent") then r.OnClientEvent:Connect(function() end) end
end)

-- ============================================================
-- COMPKILLER UI BOOTSTRAP
-- ============================================================
local Compkiller = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"
))()

local Notifier     = Compkiller.newNotify()
local ConfigManager = Compkiller:ConfigManager({
    Directory = "ArchScripts",
    Config    = "ArchCompkillerConfig",
})

Compkiller:Loader("rbxassetid://120245531583106", 2.5).yield()

local Window = Compkiller.new({
    Name     = "ARCH LUA",
    Keybind  = "LeftAlt",
    Logo     = "rbxassetid://120245531583106",
    Scale    = Compkiller.Scale.Window,
    TextSize = 15,
})

local Watermark = Window:Watermark()
Watermark:AddText({ Icon = "user",   Text = "ARCH LUA V3 + RCLC" })
Watermark:AddText({ Icon = "clock",  Text = Compkiller:GetDate() })
local TimeText = Watermark:AddText({ Icon = "timer", Text = "TIME" })
task.spawn(function()
    while true do task.wait(); TimeText:SetText(Compkiller:GetTimeNow()) end
end)
Watermark:AddText({ Icon = "server", Text = Compkiller.Version })

-- ============================================================
-- NOTIFY HELPER (Compkiller adapter)
-- ============================================================
local function notify(title, message, _, duration)
    Notifier.new({ Title = title, Content = tostring(message), Duration = duration or 3 })
end

-- ============================================================
-- SHARED CHARACTER STATE
-- ============================================================
local character, hrp, humanoid
local connections = {}

local function disconnectConn(name)
    if connections[name] then
        connections[name]:Disconnect()
        connections[name] = nil
    end
end

local function getRoot() return hrp end

local frameStamp, frameCount = -1, 0
local function frameBudgetOk()
    local f = math.floor(tick() * 60 + 0.5)
    if f ~= frameStamp then frameStamp = f; frameCount = 0 end
    if frameCount >= 3 then return false end
    frameCount = frameCount + 1
    return true
end

local function updateChar(c)
    character = c
    if c then
        hrp      = c:WaitForChild("HumanoidRootPart", 5)
        humanoid = c:WaitForChild("Humanoid", 5)
    else
        hrp, humanoid = nil, nil
    end
end
if player.Character then updateChar(player.Character) end
player.CharacterAdded:Connect(updateChar)
player.CharacterRemoving:Connect(function() updateChar(nil) end)

-- ============================================================
-- GAME MODULES (RCLC — Zombie Tower specific)
-- ============================================================
local Utility, EnumLibrary, FighterController = nil, nil, nil
pcall(function()
    Utility      = require(ReplicatedStorage.Modules.Utility)
    EnumLibrary  = require(ReplicatedStorage.Modules.EnumLibrary)
    local ps = player:FindFirstChild("PlayerScripts")
    if ps then
        local ctrl = ps:FindFirstChild("Controllers")
        if ctrl and ctrl:FindFirstChild("FighterController") then
            FighterController = require(ctrl.FighterController)
        end
    end
end)

-- ============================================================
-- RCLC CONFIG TABLES
-- ============================================================
local voidCfg = {
    VOID_ENABLED           = false,
    VOID_METHOD            = "Quantum",
    VOID_ATTACKER_INTERVAL = 4,
    VOID_ATTACKER_DURATION = 0.4,
    VOID_BAIT_INTERVAL     = 3,
    VOID_BAIT_DURATION     = 0.4,
    SPEED                  = 1000000000,
    CHAOS                  = 0.98,
    BASE_X                 = 0,
    BASE_Y                 = 0,
    BASE_Z                 = 0,
    RADIUS                 = 10000000,
    VOID_Y_MIN             = -10000000,
    VOID_Y_MAX             = 10000000,
    VOID_WRITES_PER_FRAME  = 1,
    VOID_INTERP            = true,
    VOID_INTERP_ALPHA      = 0.35,
    VOID_DURATION_ENABLED  = false,
    VOID_DURATION          = 10,
    WIREFRAME_ENABLED      = false,
}

local orbitCfg = {
    orbitEnabled  = false,
    orbitSpeed    = 90,
    orbitDist     = 8,
    orbitHeight   = 0,
    orbitMode     = "Clockwise",
    orbitLockDist = 10000000,
}

local predictCfg = {
    predEnabled      = false,
    predRadius       = 150,
    predDodgeDist    = 80,
    predCooldown     = 0.05,
    predReactionTime = 0.12,
    predBulletSpeed  = 1000,
    predAimThreshold = 0.7,
    predKinematic    = true,
    predPredictive   = true,
    predLookahead    = 0.5,
    predInfiniteRange = false,
}

local translocCfg = {
    enabled    = false,
    frequency  = 1000000,
    jitterX    = 10000000,
    jitterY    = 10000000,
    fixedZ     = 1,
    fakeVel    = true,
    fakeVelMag = 10000000000,
    burstMode  = false,
    burstCount = 10,
}

local fakePosCfg = {
    enabled             = false,
    radius              = 1000000,
    height              = 999999999,
    yDist               = 999999999,
    speed               = 100000,
    pattern             = "Scatter",
    distribution        = "Random",
    axisLock            = "None",
    randomizeEveryFrame = false,
    scatterAngle        = 360,
    pulseRadius         = false,
    pulseRadiusMin      = 100,
    pulseRadiusMax      = 999999,
    pulseSpeed          = 2,
    layeredFake         = false,
    layerCount          = 3,
    chaosMode           = false,
    chaosMult           = 5,
}

local velDesyncCfg = {
    enabled        = false,
    intensity      = 50,
    angle          = 90,
    jitter         = 20,
    flip           = false,
    speed          = 10,
    randomizeAngle = false,
    angleMin       = 0,
    angleMax       = 360,
    multiVector    = false,
    vectorCount    = 3,
    spikeMode      = false,
    spikeInterval  = 0.05,
    spikeMag       = 1000000,
    invertOnTimer  = false,
    invertInterval = 0.2,
    oscillate      = false,
    oscillateFreq  = 5,
    oscillateAmp   = 30,
    noiseVel       = false,
    noiseScale     = 1,
    burstDesync    = false,
    burstEvery     = 0.1,
    burstMag       = 500000,
    counterVel     = false,
    rotateVel      = false,
    rotateVelSpeed = 180,
}

local rclcAntiAimCfg = {
    enabled    = false,
    speed      = 5000,
    chaosLevel = 100,
    pitch      = 360,
    yaw        = 360,
}

local undergroundCfg = {
    enabled     = false,
    depth       = 1.5,
    orbitRadius = 3,
    orbitSpeed  = 200,
    spinSpeed   = 720,
}

local fastMeleeCfg = {
    enabled   = false,
    cached    = {},
    cooldown  = 0,
    animSpeed = 100,
    remoteCount = 5,
}

local fastGunState = {
    primaryOn   = false,
    primaryHits = 0,
    lastPatch   = 0,
}

local excludedGuns = { Sniper=true, Crossbow=true, Bow=true, RPG=true }

local killAuraCfg = {
    enabled        = false,
    fireRate       = 0.02,
    weaponSlot     = "Primary",
    radius         = 5000,
    headshotOffset = 1,
    jitter         = 0.02,
    autoEquip      = true,
}

-- ============================================================
-- RCLC STATE VARIABLES
-- ============================================================
local lastShotTime    = 0
local killAuraConn    = nil
local autoEquipThread = nil
local velTrackers     = {}

local voidState = {
    t=0, pos=Vector3.zero, vel=Vector3.zero,
    phase=0, seed=os.clock(), anchor=Vector3.zero,
}
local voidPhaseTime  = 0
local voidBaitPhase  = false

local wireframeFolder = nil
local wireframeBoxes  = {}
local orbitAngle      = 0

local lastPredFire    = 0
local lastToolUse     = {}
local hookedTools     = {}
local hookedToolCount = 0

local undergroundAngle   = 0
local undergroundConn    = nil
local savedRootJointC0   = nil

local translocConn  = nil
local translocTimer = 0

local fakePosHeartbeat = nil
local fakePosRender    = nil
local fakePosAnchor    = nil
local fakePosAngle     = 0
local fakePosHue       = 0
local fakePosLastWrite = 0
local fakePosTime      = 0

local velDesyncConn   = nil
local velDesyncConn2  = nil
local desyncSavedVel  = nil
local desyncAngle     = 0
local desyncFlipTimer = 0
local desyncOscTime   = 0
local desyncBurstTimer = 0
local desyncFlipState = false

local fastMeleeConn = nil

-- ============================================================
-- RCLC HELPERS
-- ============================================================
local function randomRange(a, b) return a + math.random() * (b - a) end

local function nearestPlayerRoot()
    if not hrp then return nil end
    local nearest, nd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (hrp.Position - r.Position).Magnitude
                if d < nd then nd = d; nearest = p end
            end
        end
    end
    return nearest
end

local function sanitizeVector(vec)
    if not vec or typeof(vec) ~= "Vector3" then return vec end
    local x, y, z = vec.X, vec.Y, vec.Z
    if x ~= x or x == math.huge or x == -math.huge then x = voidCfg.BASE_X end
    if y ~= y or y == math.huge or y == -math.huge then y = 0 end
    if z ~= z or z == math.huge or z == -math.huge then z = voidCfg.BASE_Z end
    y = math.clamp(y, voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX)
    local maxR = math.abs(voidCfg.RADIUS)
    if maxR > 0 then
        local dx, dz = x - voidCfg.BASE_X, z - voidCfg.BASE_Z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist > maxR and dist > 0 then
            local s = maxR / dist
            x = voidCfg.BASE_X + dx * s
            z = voidCfg.BASE_Z + dz * s
        end
    end
    return Vector3.new(x, y, z)
end

local function getHead(p)
    if not p or not p.Character then return nil end
    return p.Character:FindFirstChild("Head")
        or p.Character:FindFirstChild("CameraBone", true)
        or p.Character:FindFirstChild("HumanoidRootPart")
end

local function getTracker(p)
    if not velTrackers[p] then
        velTrackers[p] = {
            vel=Vector3.zero, accel=Vector3.zero,
            lastPos=nil, lastVel=Vector3.zero, lastT=tick(),
        }
    end
    return velTrackers[p]
end

local function updateTracker(p, root)
    local t = getTracker(p)
    local now = tick()
    local dt = now - t.lastT
    if dt > 0.01 then
        local vel = root.AssemblyLinearVelocity
        if t.lastPos and t.lastVel then
            t.accel = t.accel:Lerp((vel - t.lastVel) / dt, 0.2)
        end
        t.vel = vel; t.lastPos = root.Position
        t.lastVel = vel; t.lastT = now
    end
    return t
end

local function sidestepDirection(atkPos, myPos)
    local off = Vector3.new(atkPos.X - myPos.X, 0, atkPos.Z - myPos.Z)
    if off.Magnitude < 0.01 then off = Vector3.new(1,0,0) end
    local d = off.Unit
    local pL = Vector3.new(-d.Z, 0, d.X)
    local pR = Vector3.new(d.Z, 0, -d.X)
    return (math.random(0,1) == 0 and pL or pR)
        + Vector3.new(0, (math.random()-0.5)*0.4, 0)
end

local function scorePlayers(myPos)
    local scores = {}
    if not myPos then return scores end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local tool   = p.Character:FindFirstChildOfClass("Tool")
                local origin = getHead(p) or r
                local lv     = origin.CFrame.LookVector
                local toMe   = myPos - (origin.Position + lv * 0.5)
                local dist   = toMe.Magnitude
                if dist >= 0.01 then
                    local trk = updateTracker(p, r)
                    local dot = lv:Dot(toMe.Unit)
                    scores[p] = {
                        hrp = r, dist = dist, aimDot = dot,
                        score = math.max(0,dot)*45
                            + (tool and 25 or 0)
                            + math.max(0, 1 - dist/250)*30,
                        hasTool = tool ~= nil,
                        origin = origin, trk = trk,
                    }
                end
            end
        end
    end
    return scores
end

-- ============================================================
-- FAST GUN
-- ============================================================
local function patchGun(gs)
    if type(gs) ~= "table" then return false end
    local ok = false
    if gs.ShootSpread       then gs.ShootSpread = 0;         ok = true end
    if gs.ShootAccuracy     then gs.ShootAccuracy = 0;       ok = true end
    if gs.ShootRecoil       then gs.ShootRecoil = 0;         ok = true end
    if gs.ShootCooldown     then gs.ShootCooldown = 0.001;   ok = true end
    if gs.ShootBurstCooldown then gs.ShootBurstCooldown = 0.001; ok = true end
    return ok
end

local function patchEquippedGuns()
    local ok, items = pcall(function()
        return require(ReplicatedStorage.Modules.ItemLibrary).Items
    end)
    if not ok or type(items) ~= "table" then
        notify("Fast Gun", "ItemLibrary unavailable", "Error", 3)
        return false
    end
    local n = 0
    for k, v in pairs(items) do
        if not excludedGuns[k] and type(v) == "table" then
            if patchGun(v) then n = n + 1 end
        end
    end
    fastGunState.primaryHits = n
    fastGunState.lastPatch   = tick()
    notify("Fast Gun", string.format("patched %d guns", n), "Success", 3)
    return n > 0
end

local function fastGunTick()
    if fastGunState.primaryOn then pcall(patchEquippedGuns) end
end

-- ============================================================
-- KILL AURA
-- ============================================================
local weaponSlots = { Primary=1, Secondary=2, Melee=3 }
local function weaponSlotIndex() return weaponSlots[killAuraCfg.weaponSlot] or 1 end

local function stopAutoEquip()
    if autoEquipThread then task.cancel(autoEquipThread); autoEquipThread = nil end
end

local function startAutoEquip()
    stopAutoEquip()
    autoEquipThread = task.spawn(function()
        while killAuraCfg.enabled and killAuraCfg.autoEquip do
            task.wait(1)
            if not killAuraCfg.enabled then break end
            if FighterController and FighterController.LocalFighter
                and FighterController.LocalFighter.EquippedItem == nil then
                pcall(function()
                    FighterController.LocalFighter:EquipItem(weaponSlotIndex())
                end)
            end
        end
    end)
end

local function getNpcTargets()
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local targets = {}
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= myChar then
            local nr  = m:FindFirstChild("HumanoidRootPart")
            local nh  = m:FindFirstChild("Head")
            local nhm = m:FindFirstChildWhichIsA("Humanoid")
            if nr and nh and nhm and nhm.Health > 0
                and not Players:GetPlayerFromCharacter(m) then
                local d = (myRoot.Position - nr.Position).Magnitude
                if d <= killAuraCfg.radius then
                    table.insert(targets, {model=m, root=nr, head=nh, dist=d})
                end
            end
        end
    end
    table.sort(targets, function(a,b) return a.dist < b.dist end)
    return targets
end

local function killAuraStep()
    if not killAuraCfg.enabled or not Utility or not EnumLibrary or not FighterController then return end
    if tick() - lastShotTime < killAuraCfg.fireRate then return end
    local npc = getNpcTargets()
    if #npc == 0 then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local fighter = FighterController.LocalFighter
    if not fighter or not fighter.EquippedItem then return end
    local th = npc[1].head
    local hp = th.Position
    local aim = CFrame.lookAt(hp + Vector3.new(0, killAuraCfg.headshotOffset, 0), hp)
    local hcf = th.CFrame
    local jv  = Vector3.new(
        (math.random()-0.5)*killAuraCfg.jitter,
        (math.random()-0.5)*killAuraCfg.jitter,
        (math.random()-0.5)*killAuraCfg.jitter
    )
    local hitOff = th.CFrame:ToObjectSpace(CFrame.new(hp + jv))
    local payload = {}
    payload[utf8.char(1)] = {
        [utf8.char(0)] = Utility:EncodeCFrame(aim),
        [utf8.char(1)] = Utility:EncodeCFrame(hcf),
        [utf8.char(2)] = th,
        [utf8.char(3)] = Utility:EncodeCFrame(hitOff),
    }
    pcall(function()
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            fighter.EquippedItem:Get("ObjectID"),
            EnumLibrary:ToEnum("StartShooting"),
            payload, nil
        )
    end)
    lastShotTime = tick()
end

local function disableKillAura()
    if killAuraConn then killAuraConn:Disconnect(); killAuraConn = nil end
    stopAutoEquip()
    notify("Kill Aura", "Ka deactivated", "Warning", 3)
end

local function enableKillAura()
    if killAuraConn then killAuraConn:Disconnect() end
    if killAuraCfg.autoEquip then startAutoEquip() end
    killAuraConn = RunService.Heartbeat:Connect(killAuraStep)
    notify("Kill Aura", "Ka activated", "Success", 3)
end

-- ============================================================
-- WIREFRAME ESP
-- ============================================================
local function enableWireframes()
    if not wireframeFolder then
        wireframeFolder = Instance.new("Folder")
        wireframeFolder.Name   = "ARCH_Wireframes"
        wireframeFolder.Parent = game:GetService("CoreGui")
    end
    local function addBox(part)
        if wireframeBoxes[part] then return end
        local b = Instance.new("BoxHandleAdornment")
        b.Name        = "ARCH_Box"
        b.Adornee     = part
        b.AlwaysOnTop = true
        b.ZIndex      = 10
        b.Size        = Vector3.new(4,6,4)
        b.Transparency = 0.5
        b.Color3      = Color3.fromRGB(168,85,247)
        b.Parent      = wireframeFolder
        wireframeBoxes[part] = b
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then addBox(r) end
        end
    end
    connections.wireframe = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            if voidCfg.WIREFRAME_ENABLED then
                local r = c:FindFirstChild("HumanoidRootPart")
                if r then addBox(r) end
            end
        end)
    end)
end

local function disableWireframes()
    if wireframeFolder then wireframeFolder:Destroy(); wireframeFolder = nil end
    wireframeBoxes = {}
    disconnectConn("wireframe")
end

local function setWireframes(state)
    voidCfg.WIREFRAME_ENABLED = state
    if state then enableWireframes() else disableWireframes() end
end

-- ============================================================
-- RCLC VOID
-- ============================================================
local function voidTarget(dt)
    local m = voidCfg.VOID_METHOD
    local radius = voidCfg.RADIUS
    if m == "Freeze Bait" then
        voidPhaseTime = voidPhaseTime + dt
        if voidBaitPhase then
            if voidPhaseTime >= voidCfg.VOID_BAIT_DURATION then
                voidBaitPhase = false; voidPhaseTime = 0
            else
                return hrp and hrp.Position or Vector3.zero
            end
        elseif voidPhaseTime >= voidCfg.VOID_BAIT_INTERVAL then
            voidBaitPhase = true; voidPhaseTime = 0
            return hrp and hrp.Position or Vector3.zero
        end
        return sanitizeVector(Vector3.new(
            voidCfg.BASE_X + randomRange(-radius, radius),
            randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX),
            voidCfg.BASE_Z + randomRange(-radius, radius)
        ))
    elseif m == "Attacker" then
        voidPhaseTime = voidPhaseTime + dt
        if voidBaitPhase then
            if voidPhaseTime >= voidCfg.VOID_ATTACKER_DURATION then
                voidBaitPhase = false; voidPhaseTime = 0
            else
                local np = nearestPlayerRoot()
                if np and np.Character then
                    local nr = np.Character:FindFirstChild("HumanoidRootPart")
                    if nr then return nr.Position end
                end
            end
        elseif voidPhaseTime >= voidCfg.VOID_ATTACKER_INTERVAL then
            voidBaitPhase = true; voidPhaseTime = 0
            local np = nearestPlayerRoot()
            if np and np.Character then
                local nr = np.Character:FindFirstChild("HumanoidRootPart")
                if nr then return nr.Position end
            end
        end
        return sanitizeVector(Vector3.new(
            voidCfg.BASE_X + randomRange(-radius, radius),
            randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX),
            voidCfg.BASE_Z + randomRange(-radius, radius)
        ))
    elseif m == "Chaos" then
        local cmax = radius * voidCfg.CHAOS
        return Vector3.new(
            voidCfg.BASE_X + randomRange(-cmax, cmax),
            randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX),
            voidCfg.BASE_Z + randomRange(-cmax, cmax)
        )
    else -- Quantum
        return Vector3.new(
            voidCfg.BASE_X + randomRange(-radius, radius),
            randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX),
            voidCfg.BASE_Z + randomRange(-radius, radius)
        )
    end
end

local function voidStep(dt)
    voidState.t = voidState.t + dt
    local root = getRoot()
    if not root then return end
    local tp = voidTarget(dt)
    if not tp then return end
    pcall(function()
        root.CFrame = CFrame.new(tp)
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function enableVoidRCLC()
    disconnectConn("rclcVoid")
    voidState.t = 0; voidState.phase = 0; voidState.vel = Vector3.zero
    voidPhaseTime = 0; voidBaitPhase = false
    local root = getRoot()
    if root then
        voidState.pos    = root.Position
        voidState.anchor = root.Position
        pcall(function() root:SetNetworkOwner(player) end)
    end
    connections.rclcVoid = (RunService.PreSimulation or RunService.Heartbeat):Connect(function(dt)
        if not voidCfg.VOID_ENABLED then disconnectConn("rclcVoid"); return end
        if voidCfg.VOID_DURATION_ENABLED
            and tick() - voidState.t > voidCfg.VOID_DURATION then
            voidCfg.VOID_ENABLED = false
            notify("Void", "duration reached", "Warning", 2)
            return
        end
        voidStep(dt)
    end)
end

local function disableVoidRCLC()
    disconnectConn("rclcVoid")
    voidCfg.VOID_ENABLED = false
    voidBaitPhase = false; voidPhaseTime = 0
end

-- ============================================================
-- RCLC ORBIT
-- ============================================================
local function disableOrbitRCLC()
    disconnectConn("rclcOrbit")
    orbitCfg.orbitEnabled = false
    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

local function enableOrbitRCLC()
    disconnectConn("rclcOrbit")
    orbitAngle = 0
    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end
    connections.rclcOrbit = RunService.Heartbeat:Connect(function(dt)
        if not orbitCfg.orbitEnabled then disconnectConn("rclcOrbit"); return end
        if not hrp then return end
        if humanoid then
            pcall(function()
                if humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
                    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                end
            end)
        end
        local np = nearestPlayerRoot()
        local center = hrp.Position
        if np and np.Character then
            local nr = np.Character:FindFirstChild("HumanoidRootPart")
            if nr and (hrp.Position - nr.Position).Magnitude <= orbitCfg.orbitLockDist then
                center = nr.Position
            end
        end
        local dir = orbitCfg.orbitMode == "Counter-Clockwise" and -1 or 1
        orbitAngle = (orbitAngle + math.rad(orbitCfg.orbitSpeed) * dir * dt) % (math.pi*2)
        local r = orbitCfg.orbitDist
        local op = center + Vector3.new(
            math.cos(orbitAngle)*r, orbitCfg.orbitHeight, math.sin(orbitAngle)*r
        )
        pcall(function()
            hrp.CFrame = CFrame.new(op, Vector3.new(center.X, op.Y, center.Z))
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end

-- ============================================================
-- PREDICTION (DODGING)
-- ============================================================
local function disablePrediction()
    disconnectConn("pred")
    predictCfg.predEnabled = false
end

local function hookToolActivate(tool)
    if not tool or hookedTools[tool] or hookedToolCount >= 64 then return end
    hookedTools[tool] = true
    hookedToolCount   = hookedToolCount + 1
    pcall(function()
        hookfunction(tool.Activate, function(self)
            if not checkcaller() and self == tool then
                local owner = tool.Parent and tool.Parent.Parent
                if owner and owner ~= player and owner.Character then
                    lastToolUse[owner] = tick()
                end
            end
            -- BUG (original): `old` and `v346` undefined
            return old(self, unpack(v346))
        end)
    end)
end

local function hookAllPlayerTools()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local tool = p.Character:FindFirstChildOfClass("Tool")
            if tool then hookToolActivate(tool) end
            p.Character.ChildAdded:Connect(function(c)
                if c:IsA("Tool") then hookToolActivate(c) end
            end)
        end
    end
end

local function enablePrediction()
    disconnectConn("pred")
    hookAllPlayerTools()
    connections.pred = RunService.Heartbeat:Connect(function(dt)
        if not predictCfg.predEnabled then disconnectConn("pred"); return end
        if not hrp or (humanoid and humanoid.Health <= 0) then return end
        local myPos = hrp.Position
        local myVel = hrp.AssemblyLinearVelocity
        local now   = tick()
        local best, bestScore = nil, 0
        for p, info in pairs(scorePlayers(myPos)) do
            if info.score > bestScore then
                bestScore = info.score; best = {p=p, d=info}
            end
        end
        if not best then return end
        local maxRange = predictCfg.predInfiniteRange and 5e12 or predictCfg.predRadius
        if best.d.dist > maxRange then return end
        if now - lastPredFire < predictCfg.predCooldown then return end
        local threatened = (lastToolUse[best.p] and now - lastToolUse[best.p] < predictCfg.predReactionTime)
            or best.d.aimDot > predictCfg.predAimThreshold
        if threatened and predictCfg.predPredictive and best.d.trk and best.d.trk.vel then
            local trk = best.d.trk
            local dv  = Vector3.zero
            local found = false
            for step = 1, 10 do
                local t  = predictCfg.predLookahead / 10 * step
                local mf = myPos + myVel * t
                local ef = trk.lastPos + trk.vel*t + 0.5*trk.accel*t^2
                if math.abs((mf-ef).Magnitude / predictCfg.predBulletSpeed - t) < 0.15 then
                    found = true
                    local d2m = (mf - ef).Unit
                    local pa  = Vector3.new(-d2m.Z, 0, d2m.X)
                    local pb  = Vector3.new(d2m.Z, 0, -d2m.X)
                    dv = ((math.random(0,1)==0 and 1 or -1) == 1 and pa or pb).Unit * predictCfg.predDodgeDist
                    break
                end
            end
            if found and dv.Magnitude > 0 then
                local dp = myPos + dv + Vector3.new(0, (math.random()-0.5)*15, 0)
                if frameBudgetOk() then
                    pcall(function()
                        hrp.CFrame = CFrame.new(dp)
                        hrp.AssemblyLinearVelocity = dv.Unit * 150
                    end)
                end
                lastPredFire = now; return
            end
        end
        if threatened and predictCfg.predKinematic then
            lastPredFire = now
            local sd  = sidestepDirection(best.d.hrp.Position, myPos)
            local sp  = myPos + sd * predictCfg.predDodgeDist
            if frameBudgetOk() then
                pcall(function()
                    hrp.CFrame = CFrame.new(sp + Vector3.new((math.random()-0.5)*4, 0, (math.random()-0.5)*4))
                    hrp.AssemblyLinearVelocity = sd * 150
                end)
            end
        end
    end)
end

-- ============================================================
-- UNDERGROUND ANTI-AIM + CHAOS ANTI-AIM
-- ============================================================
local function disableUndergroundAA()
    if undergroundConn then undergroundConn:Disconnect(); undergroundConn = nil end
    if hrp and character and savedRootJointC0 then
        local head = character:FindFirstChild("Head")
        if head then
            local neck = head:FindFirstChild("Neck") or character:FindFirstChild("Neck")
            if neck and neck:IsA("Motor6D") then neck.C0 = savedRootJointC0 end
        end
    end
    notify("Underground AA", "Deactivated", "Warning", 3)
end

local function enableUndergroundAA()
    if undergroundConn then undergroundConn:Disconnect() end
    undergroundAngle = 0
    if hrp and character then
        local head = character:FindFirstChild("Head")
        if head then
            local neck = head:FindFirstChild("Neck") or character:FindFirstChild("Neck")
            if neck and neck:IsA("Motor6D") then
                savedRootJointC0 = neck.C0
                neck.C0 = CFrame.new(0,0,0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end
    end
    undergroundConn = RunService.Heartbeat:Connect(function(dt)
        if not undergroundCfg.enabled then return end
        local root = getRoot()
        if not root then return end
        undergroundAngle = (undergroundAngle + math.rad(undergroundCfg.orbitSpeed)*dt) % (math.pi*2)
        local ca, sa = math.cos(undergroundAngle), math.sin(undergroundAngle)
        local upos = root.Position + Vector3.new(
            ca*undergroundCfg.orbitRadius, -undergroundCfg.depth, sa*undergroundCfg.orbitRadius
        )
        if root.Position.Y - upos.Y > undergroundCfg.depth + 1 then
            upos = Vector3.new(upos.X, root.Position.Y - undergroundCfg.depth, upos.Z)
        end
        local spin = tick() * undergroundCfg.spinSpeed % 360
        pcall(function()
            root.CFrame = CFrame.new(upos) * CFrame.Angles(0, math.rad(spin), 0)
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
    notify("Underground AA", "Activated", "Success", 3)
end

local function enableRCLCAntiAim()
    disconnectConn("rclcAntiAim")
    connections.rclcAntiAim = RunService.Heartbeat:Connect(function(dt)
        if not rclcAntiAimCfg.enabled then disconnectConn("rclcAntiAim"); return end
        if not hrp then return end
        local c     = rclcAntiAimCfg.chaosLevel * 0.01
        local pm    = math.rad(rclcAntiAimCfg.pitch)
        local ym    = math.rad(rclcAntiAimCfg.yaw)
        local ss    = rclcAntiAimCfg.speed / 5000
        hrp.CFrame  = CFrame.new(hrp.Position) * CFrame.Angles(
            (math.random()-0.5)*2*pm*c*ss,
            (math.random()-0.5)*2*ym*c*ss,
            (math.random()-0.5)*math.rad(360)*c*ss
        )
    end)
end

local function disableRCLCAntiAim()
    disconnectConn("rclcAntiAim")
    rclcAntiAimCfg.enabled = false
end

-- ============================================================
-- TRANSLOCATION
-- ============================================================
local function disableTransloc()
    if translocConn then translocConn:Disconnect(); translocConn = nil end
    translocCfg.enabled = false
end

local function enableTransloc()
    if translocConn then translocConn:Disconnect() end
    translocTimer = 0
    translocConn = RunService.Heartbeat:Connect(function(dt)
        if not translocCfg.enabled then disableTransloc(); return end
        if not hrp then return end
        translocTimer = translocTimer + dt
        local interval = 1 / math.max(translocCfg.frequency, 1)
        local iters = 1
        if interval < dt then
            iters = math.clamp(math.floor(dt/interval), 1, 50)
        end
        if translocTimer >= interval then
            translocTimer = translocTimer % interval
            local origin = hrp.Position
            local meta = getrawmetatable and getrawmetatable(hrp)
            local rawNI = meta and rawget(meta, "__newindex")
            for _ = 1, iters do
                local fc = CFrame.new(
                    origin.X + (math.random()*2-1)*translocCfg.jitterX,
                    origin.Y + (math.random()*2-1)*translocCfg.jitterY,
                    translocCfg.fixedZ
                )
                local fv = Vector3.zero
                if translocCfg.fakeVel then
                    local m = translocCfg.fakeVelMag
                    fv = Vector3.new(
                        (math.random()-0.5)*m*2,
                        (math.random()-0.5)*m*2,
                        (math.random()-0.5)*m*2
                    )
                end
                if rawNI then
                    pcall(rawNI, hrp, "CFrame", fc)
                    pcall(rawNI, hrp, "AssemblyLinearVelocity", fv)
                else
                    pcall(function()
                        hrp.CFrame = fc
                        hrp.AssemblyLinearVelocity = fv
                    end)
                end
            end
        end
    end)
end

-- ============================================================
-- FAKE POSITION
-- ============================================================
local function disableFakePos()
    if fakePosHeartbeat then fakePosHeartbeat:Disconnect(); fakePosHeartbeat = nil end
    if fakePosRender    then fakePosRender:Disconnect();    fakePosRender    = nil end
    fakePosAnchor = nil
    fakePosCfg.enabled = false
end

local function enableFakePos()
    if fakePosHeartbeat then fakePosHeartbeat:Disconnect() end
    if fakePosRender    then fakePosRender:Disconnect()    end
    fakePosAnchor = nil; fakePosAngle = 0; fakePosHue = 0
    fakePosLastWrite = 0; fakePosTime = 0

    fakePosHeartbeat = RunService.Heartbeat:Connect(function(dt)
        if not fakePosCfg.enabled or not hrp then return end
        fakePosAnchor = hrp.CFrame
        fakePosTime   = fakePosTime + dt
        local now     = tick()
        local rate    = fakePosCfg.randomizeEveryFrame and 99999
            or math.max(fakePosCfg.speed, 1)
        if now - fakePosLastWrite < 1/rate then return end
        fakePosLastWrite = now

        local meta  = getrawmetatable and getrawmetatable(hrp)
        local rawNI = meta and rawget(meta, "__newindex")
        local radius = math.max(fakePosCfg.radius, 1)
        if fakePosCfg.pulseRadius then
            radius = fakePosCfg.pulseRadiusMin
                + (math.sin(fakePosTime*fakePosCfg.pulseSpeed*2*math.pi)*0.5+0.5)
                * (fakePosCfg.pulseRadiusMax - fakePosCfg.pulseRadiusMin)
        end
        local layers = fakePosCfg.layeredFake and fakePosCfg.layerCount or 1
        for layer = 1, layers do
            local lr = radius * (layer/layers)
            if fakePosCfg.chaosMode then
                lr = lr * (1 + (math.random()-0.5)*fakePosCfg.chaosMult)
            end
            local offX, offY, offZ = 0, 0, 0
            local pat = fakePosCfg.pattern
            if pat == "Scatter" then
                local ang = (math.random()-0.5)*math.rad(fakePosCfg.scatterAngle)
                offX = math.cos(ang)*(math.random()*lr)
                offY = fakePosCfg.height + math.random()*fakePosCfg.yDist
                offZ = math.sin(ang)*(math.random()*lr)
            elseif pat == "Linear" then
                fakePosHue = fakePosHue + 0.05
                local t = fakePosHue % 1
                offX = (t-0.5)*2*lr
                offY = fakePosCfg.height + math.random()*fakePosCfg.yDist
                offZ = (t-0.5)*2*lr
            elseif pat == "Circle" then
                fakePosAngle = (fakePosAngle + math.rad(fakePosCfg.speed*dt*60)) % (math.pi*2)
                offX = math.cos(fakePosAngle)*lr
                offY = fakePosCfg.height + math.random()*fakePosCfg.yDist
                offZ = math.sin(fakePosAngle)*lr
            elseif pat == "Random" then
                offX = (math.random()*2-1)*lr
                offY = fakePosCfg.height + math.random()*fakePosCfg.yDist
                offZ = (math.random()*2-1)*lr
            elseif pat == "Spiral" then
                fakePosAngle = (fakePosAngle + math.rad(fakePosCfg.speed*dt*60)) % (math.pi*2)
                local sr = lr*(0.3 + 0.7*(fakePosAngle/(math.pi*2)%1))
                offX = math.cos(fakePosAngle)*sr
                offY = fakePosCfg.height + math.random()*fakePosCfg.yDist
                offZ = math.sin(fakePosAngle)*sr
            end
            -- distribution
            local dist = fakePosCfg.distribution
            if dist == "Uniform" then
                local len = math.sqrt(offX*offX + offZ*offZ)
                if len > 0 then local s=lr/len; offX=offX*s; offZ=offZ*s end
            elseif dist == "Weighted" then
                offX=offX*0.6; offZ=offZ*0.6
            elseif dist == "Radial" then
                local a=math.atan2(offZ,offX)
                offX=math.cos(a)*lr; offZ=math.sin(a)*lr
            elseif dist == "Clustered" then
                local oct=math.floor(math.random()*8)*(math.pi*0.25)
                offX=math.cos(oct)*lr; offZ=math.sin(oct)*lr
            end
            -- axis lock
            local al = fakePosCfg.axisLock
            if al == "X"  then offZ=0; offY=fakePosCfg.height
            elseif al == "Y" then offX=0; offZ=0
            elseif al == "Z" then offX=0; offY=fakePosCfg.height
            elseif al == "XZ" then offY=fakePosCfg.height end

            local fp = fakePosAnchor + Vector3.new(offX, offY, offZ)
            if rawNI then
                pcall(rawNI, hrp, "AssemblyLinearVelocity", Vector3.zero)
                pcall(rawNI, hrp, "CFrame", fp)
                pcall(rawNI, hrp, "AssemblyLinearVelocity", Vector3.zero)
            else
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = fp
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end)
            end
        end
    end)

    fakePosRender = RunService.RenderStepped:Connect(function()
        if fakePosCfg.enabled and hrp and fakePosAnchor then
            hrp.CFrame = fakePosAnchor
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- ============================================================
-- VELOCITY DESYNC
-- ============================================================
local function disableVelDesync()
    if velDesyncConn  then velDesyncConn:Disconnect();  velDesyncConn  = nil end
    if velDesyncConn2 then velDesyncConn2:Disconnect(); velDesyncConn2 = nil end
    desyncSavedVel = nil; desyncAngle = 0
    velDesyncCfg.enabled = false
end

local function enableVelDesync()
    if velDesyncConn  then velDesyncConn:Disconnect()  end
    if velDesyncConn2 then velDesyncConn2:Disconnect() end
    desyncSavedVel  = nil; desyncAngle     = 0
    desyncFlipTimer = 0;   desyncOscTime   = 0
    desyncBurstTimer= 0;   desyncFlipState = false

    velDesyncConn = RunService.Heartbeat:Connect(function(dt)
        local root = getRoot()
        if not velDesyncCfg.enabled or not root then return end
        desyncSavedVel  = root.AssemblyLinearVelocity
        desyncFlipTimer = desyncFlipTimer  + dt
        desyncBurstTimer= desyncBurstTimer + dt
        desyncOscTime   = desyncOscTime    + dt
        if velDesyncCfg.invertOnTimer and desyncFlipTimer >= velDesyncCfg.invertInterval then
            desyncFlipTimer = 0; desyncFlipState = not desyncFlipState
        end
        local sign  = (velDesyncCfg.flip or desyncFlipState) and -1 or 1
        local speed = math.clamp(velDesyncCfg.speed, 1, 100)
        desyncAngle = (desyncAngle + math.rad(speed*dt*360)) % (math.pi*2)
        local baseAng = velDesyncCfg.randomizeAngle
            and math.rad(velDesyncCfg.angleMin + math.random()*(velDesyncCfg.angleMax-velDesyncCfg.angleMin))
            or math.rad(velDesyncCfg.angle)
        local jd  = math.clamp(velDesyncCfg.jitter, 0, 180)
        local ang = baseAng + math.rad((math.random()-0.5)*jd*2) + desyncAngle
        if velDesyncCfg.oscillate then
            ang = ang + math.rad(math.sin(desyncOscTime*velDesyncCfg.oscillateFreq*2*math.pi)*velDesyncCfg.oscillateAmp)
        end
        if velDesyncCfg.rotateVel then
            ang = ang + math.rad(velDesyncCfg.rotateVelSpeed)*dt
        end
        local mag = math.clamp(velDesyncCfg.intensity, 1, 100)/100 * 50000
        if velDesyncCfg.spikeMode and desyncBurstTimer >= velDesyncCfg.spikeInterval then
            desyncBurstTimer = 0; mag = mag + velDesyncCfg.spikeMag
        end
        if velDesyncCfg.burstDesync and desyncBurstTimer >= velDesyncCfg.burstEvery then
            mag = mag + velDesyncCfg.burstMag
        end
        local nX, nZ = 0, 0
        if velDesyncCfg.noiseVel then
            local nt = tick()*velDesyncCfg.noiseScale
            nX = math.noise(nt,0,0)*mag*0.5
            nZ = math.noise(0,nt,0)*mag*0.5
        end
        local vels  = {}
        local vcount = velDesyncCfg.multiVector and velDesyncCfg.vectorCount or 1
        for i = 1, vcount do
            local va = ang + (i-1)*(math.pi*2/vcount)
            table.insert(vels, Vector3.new(
                math.cos(va)*mag*sign + nX,
                (math.random()-0.5)*mag*0.5,
                math.sin(va)*mag*sign + nZ
            ))
        end
        if velDesyncCfg.counterVel and desyncSavedVel then
            table.insert(vels, -desyncSavedVel * 2)
        end
        local meta  = getrawmetatable and getrawmetatable(root)
        local rawNI = meta and rawget(meta, "__newindex")
        for _, v in ipairs(vels) do
            if rawNI then
                pcall(rawNI, root, "AssemblyLinearVelocity", v)
            else
                pcall(function() root.AssemblyLinearVelocity = v end)
            end
            if sethiddenproperty then
                pcall(sethiddenproperty, root, "AssemblyLinearVelocity", v)
            end
        end
    end)

    velDesyncConn2 = RunService.RenderStepped:Connect(function()
        local root = getRoot()
        if velDesyncCfg.enabled and root and desyncSavedVel then
            root.AssemblyLinearVelocity = desyncSavedVel
        end
    end)
end

-- ============================================================
-- FAST MELEE
-- ============================================================
local function cacheMeleeTables()
    if #fastMeleeCfg.cached > 0 or type(getgc) ~= "function" then return end
    pcall(function()
        for _, t in pairs(getgc(true)) do
            if type(t) == "table"
                and (rawget(t,"MeleeCooldown") or rawget(t,"AttackCooldown")) then
                table.insert(fastMeleeCfg.cached, t)
            end
        end
    end)
end

local function disableFastMelee()
    if fastMeleeConn then fastMeleeConn:Disconnect(); fastMeleeConn = nil end
    fastMeleeCfg.enabled = false
end

local function enableFastMelee()
    cacheMeleeTables()
    if fastMeleeConn then fastMeleeConn:Disconnect() end
    fastMeleeConn = RunService.Heartbeat:Connect(function()
        if not fastMeleeCfg.enabled then return end
        for _, t in ipairs(fastMeleeCfg.cached) do
            if rawget(t, "MeleeCooldown")  then t.MeleeCooldown  = fastMeleeCfg.cooldown end
            if rawget(t, "AttackCooldown") then t.AttackCooldown = fastMeleeCfg.cooldown end
        end
    end)
end

-- ============================================================
-- POSITION HUD (RCLC)
-- ============================================================
local function createPositionHud()
    local CoreGui = game:GetService("CoreGui")
    local old = CoreGui:FindFirstChild("ARCH_PositionHUD")
    if old then old:Destroy() end
    local hudGui = Instance.new("ScreenGui")
    hudGui.Name           = "ARCH_PositionHUD"
    hudGui.ResetOnSpawn   = false
    hudGui.DisplayOrder   = 9998
    hudGui.IgnoreGuiInset = true
    hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if not pcall(function() hudGui.Parent = CoreGui end) or not hudGui.Parent then
        hudGui.Parent = player:WaitForChild("PlayerGui")
    end
    local accent     = Color3.fromRGB(168,85,247)
    local accentDim  = Color3.fromRGB(120,60,180)
    local bgDark     = Color3.fromRGB(8,6,12)
    local bgRow      = Color3.fromRGB(16,12,22)
    local strokeCol  = Color3.fromRGB(90,50,140)
    local textBright = Color3.fromRGB(245,240,255)
    local textDim    = Color3.fromRGB(160,140,190)
    local hudFont    = Enum.Font.Garamond
    local panel = Instance.new("Frame")
    panel.Name                  = "PositionHUD"
    panel.Size                  = UDim2.fromOffset(200,132)
    panel.Position              = UDim2.new(0,16,0.5,-66)
    panel.BackgroundColor3      = bgDark
    panel.BackgroundTransparency = 0.02
    panel.BorderSizePixel       = 0
    panel.Parent                = hudGui
    Instance.new("UICorner",panel).CornerRadius = UDim.new(0,12)
    local ps = Instance.new("UIStroke", panel)
    ps.Color = strokeCol; ps.Thickness = 1.2; ps.Transparency = 0.15
    local pg = Instance.new("UIGradient", panel)
    pg.Rotation = 90
    pg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28,14,44)),
        ColorSequenceKeypoint.new(1, bgDark),
    })
    pg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,0.35),
    })
    local topLine = Instance.new("Frame", panel)
    topLine.Size = UDim2.new(1,-24,0,1)
    topLine.Position = UDim2.fromOffset(12,0)
    topLine.BackgroundColor3 = accent; topLine.BorderSizePixel = 0
    local tlg = Instance.new("UIGradient", topLine)
    tlg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    })
    Instance.new("UICorner", topLine).CornerRadius = UDim.new(1,0)
    local titleL = Instance.new("TextLabel", panel)
    titleL.Size = UDim2.new(1,-40,0,18); titleL.Position = UDim2.fromOffset(14,10)
    titleL.BackgroundTransparency = 1; titleL.Text = "POSITION"
    titleL.TextColor3 = accent; titleL.Font = hudFont
    titleL.TextSize = 12; titleL.TextXAlignment = Enum.TextXAlignment.Left
    local subL = Instance.new("TextLabel", panel)
    subL.Size = UDim2.new(1,-40,0,12); subL.Position = UDim2.fromOffset(14,26)
    subL.BackgroundTransparency = 1; subL.Text = "ARCH+RCLC"
    subL.TextColor3 = textDim; subL.Font = hudFont
    subL.TextSize = 10; subL.TextXAlignment = Enum.TextXAlignment.Left
    local dot = Instance.new("Frame", panel)
    dot.Size = UDim2.fromOffset(6,6); dot.Position = UDim2.new(1,-18,0,16)
    dot.BackgroundColor3 = accent; dot.BorderSizePixel = 0; dot.Rotation = 45
    local div = Instance.new("Frame", panel)
    div.Size = UDim2.new(1,-24,0,1); div.Position = UDim2.fromOffset(12,42)
    div.BackgroundColor3 = accentDim; div.BackgroundTransparency = 0.4; div.BorderSizePixel = 0
    local dg = Instance.new("UIGradient", div)
    dg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, accentDim),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    })
    local vLabels = {}
    for i, axis in ipairs({"X","Y","Z"}) do
        local row = Instance.new("Frame", panel)
        row.Size = UDim2.new(1,-24,0,24); row.Position = UDim2.fromOffset(12, 50+(i-1)*27)
        row.BackgroundColor3 = bgRow; row.BackgroundTransparency = 0.1; row.BorderSizePixel = 0
        Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)
        local rs = Instance.new("UIStroke",row)
        rs.Color = strokeCol; rs.Thickness = 1; rs.Transparency = 0.55
        local ra = Instance.new("Frame",row)
        ra.Size = UDim2.new(0,2,0,12); ra.Position = UDim2.new(0,7,0.5,-6)
        ra.BackgroundColor3 = accent; ra.BorderSizePixel = 0
        Instance.new("UICorner",ra).CornerRadius = UDim.new(1,0)
        local al = Instance.new("TextLabel",row)
        al.Size = UDim2.fromOffset(14,24); al.Position = UDim2.fromOffset(16,0)
        al.BackgroundTransparency = 1; al.Text = axis
        al.TextColor3 = accent; al.Font = hudFont; al.TextSize = 12
        al.TextXAlignment = Enum.TextXAlignment.Left
        local vl = Instance.new("TextLabel",row)
        vl.Size = UDim2.new(1,-40,1,0); vl.Position = UDim2.fromOffset(34,0)
        vl.BackgroundTransparency = 1; vl.Text = "0.00"
        vl.TextColor3 = textBright; vl.Font = hudFont; vl.TextSize = 13
        vl.TextXAlignment = Enum.TextXAlignment.Right
        vLabels[axis] = vl
    end
    local pulseT = 0
    local lx, ly, lz = "","",""
    RunService.Heartbeat:Connect(function(dt)
        if not hudGui.Parent then return end
        pulseT = pulseT + dt * 2.2
        dot.BackgroundTransparency = 1 - (0.5 + (math.sin(pulseT)+1)*0.25)
        local char2 = player and player.Character
        local root2 = char2 and char2:FindFirstChild("HumanoidRootPart")
        if root2 then
            local tx = string.format("%.2f", root2.Position.X)
            local ty = string.format("%.2f", root2.Position.Y)
            local tz = string.format("%.2f", root2.Position.Z)
            if tx ~= lx then vLabels.X.Text = tx; lx = tx end
            if ty ~= ly then vLabels.Y.Text = ty; ly = ty end
            if tz ~= lz then vLabels.Z.Text = tz; lz = tz end
        elseif lx ~= "0.00" then
            vLabels.X.Text="0.00"; vLabels.Y.Text="0.00"; vLabels.Z.Text="0.00"
            lx="0.00"; ly="0.00"; lz="0.00"
        end
    end)
    return hudGui
end
local positionHud = createPositionHud()

-- ============================================================
-- RCLC CHARACTER LIFECYCLE (re-enable on respawn)
-- ============================================================
player.CharacterAdded:Connect(function(newChar)
    task.wait(0.3)
    if voidCfg.VOID_ENABLED         then enableVoidRCLC()      end
    if orbitCfg.orbitEnabled         then enableOrbitRCLC()     end
    if predictCfg.predEnabled        then enablePrediction()    end
    if rclcAntiAimCfg.enabled        then enableRCLCAntiAim()   end
    if undergroundCfg.enabled        then enableUndergroundAA() end
    if translocCfg.enabled           then enableTransloc()      end
    if fakePosCfg.enabled            then enableFakePos()       end
    if velDesyncCfg.enabled          then enableVelDesync()     end
    if fastGunState.primaryOn        then fastGunTick()         end
end)

player.CharacterRemoving:Connect(function()
    disconnectConn("rclcVoid")
    disconnectConn("rclcOrbit")
    disconnectConn("pred")
    disconnectConn("rclcAntiAim")
    disconnectConn("wireframe")
    if translocConn    then translocConn:Disconnect();    translocConn    = nil end
    if fakePosHeartbeat then fakePosHeartbeat:Disconnect(); fakePosHeartbeat = nil end
    if fakePosRender   then fakePosRender:Disconnect();   fakePosRender   = nil end
    if velDesyncConn   then velDesyncConn:Disconnect();   velDesyncConn   = nil end
    if velDesyncConn2  then velDesyncConn2:Disconnect();  velDesyncConn2  = nil end
    if undergroundConn then undergroundConn:Disconnect(); undergroundConn = nil end
end)

-- ============================================================
-- ARCH — ORIGINAL MOVEMENT VARIABLES
-- ============================================================
local running, riotRunning, evasionEnabled, blinkEnabled, ghostEnabled = false, false, false, false, false
local currentDistance, teleportInterval, jitterStrength = 500, 0.035, 14
local tpScaleX, tpScaleY, tpScaleZ = 1, 1, 1
local riotXJitter, riotYJitter, riotZJitter, riotDistance, spinSpeed = 30, 8, 30, 300, 720
local riotPitchMult, riotRollMult, riotOscFreq = 0.37, 0.19, 3.1
local riotAsymmetryXPos, riotAsymmetryXNeg = 1, 1
local riotAsymmetryYPos, riotAsymmetryYNeg = 1, 1
local riotAsymmetryZPos, riotAsymmetryZNeg = 1, 1
local teleportMode = "RANDOM"
local lastTeleport = 0
local closestEnabled, enemyPositionMode, enemyTeleportDistance = false, "Behind", 10
local enemyOffsetX, enemyOffsetY, enemyOffsetZ = 0, 0, 0
local ignoreDeathCheck = false
local evasionIntensityX, evasionIntensityY, evasionIntensityZ = 3.0, 3.0, 3.0
local blinkRadiusX, blinkRadiusY, blinkRadiusZ = 80, 80, 80
local blinkRate = 60
local ghostDistanceX, ghostDistanceY, ghostDistanceZ = 150, 150, 150
local autocollectEnabled, autocollectRadius = false, 60
local returnHomeEnabled, homeReturnDelay, homePosition = false, 3.0, nil
local safeZoneEnabled, safeZoneY, safeZoneSavedPos = false, -10, nil
local teleportLoopEnabled, teleportLoopPositions, teleportLoopDelay, teleportLoopIndex = false, {}, 1.5, 1
local clickTeleportHotkey = Enum.KeyCode.Z
local orbitEnemyEnabled, orbitRadius_arch, orbitSpeed_arch = false, 15, 5
local yoyoStrikeEnabled, yoyoAnchor = false, nil
local noclipBypassEnabled = false
local cframeFlightEnabled, flightSpeedX, flightSpeedY, flightSpeedZ = false, 50, 50, 50
local fakeLagEnabled, fakeLagInterval, lastFakeLagUpdate = false, 0.2, 0
local antiAimEnabled, antiAimSpeed = false, 1500
local autoHealEnabled = false
local projectileDodgeEnabled, projectileDodgeRadius = false, 40
local dynamicSafeAnchorEnabled, dynamicTargetPlayer = false, ""
local espBoxTracersEnabled, waypointEspEnabled = false, false
local targetSpectateEnabled = false
local hitboxExpanderEnabled, hitboxSize = false, 10
local autoFacingEnabled = false
local clientInvisibilityEnabled, fakeDeathNPC = false, nil
local originalCFrame = nil

local SAFE_FLOOR   = 2
local SAFE_MAX_RISE = 800

local function safeTeleport(pos)
    if not hrp then return end
    local x, y, z = pos.X, pos.Y, pos.Z
    y = math.min(y, hrp.Position.Y + SAFE_MAX_RISE)
    y = math.max(y, SAFE_FLOOR)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local hit = Workspace:Raycast(Vector3.new(x,y+60,z), Vector3.new(0,-220,0), params)
    if hit then y = math.max(hit.Position.Y + 3, SAFE_FLOOR) end
    hrp.CFrame = CFrame.new(x,y,z)
end

local function getClosestHRP()
    if not hrp then return nil end
    local closest, minD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChild("Humanoid")
            if t and h and h.Health > 0 then
                local d = (t.Position - hrp.Position).Magnitude
                if d < minD then minD = d; closest = t end
            end
        end
    end
    return closest
end

local function runRiotAbuser(dt)
    if not riotRunning or not hrp then return end
    local yaw   = math.rad(spinSpeed * dt)
    local pitch = math.rad(spinSpeed * riotPitchMult * dt * math.sin(tick() * riotOscFreq))
    local roll  = math.rad(spinSpeed * riotRollMult  * dt * math.cos(tick() * (riotOscFreq+2.6)))
    local spinCF = hrp.CFrame * CFrame.Angles(pitch, yaw, roll)
    local spread = riotDistance / 300
    local jX = (math.random()*(riotAsymmetryXPos+riotAsymmetryXNeg)-riotAsymmetryXNeg)*riotXJitter*spread*2
    local jY = (math.random()*(riotAsymmetryYPos+riotAsymmetryYNeg)-riotAsymmetryYNeg)*riotYJitter*spread
    local jZ = (math.random()*(riotAsymmetryZPos+riotAsymmetryZNeg)-riotAsymmetryZNeg)*riotZJitter*spread*2
    local nY = math.max(spinCF.Position.Y + jY, SAFE_FLOOR)
    hrp.CFrame = spinCF + Vector3.new(jX, nY - spinCF.Position.Y, jZ)
end

local function runEvasion()
    if not evasionEnabled or not hrp then return end
    local t = tick()
    local oX = math.cos(t*18.7)*currentDistance*0.18*evasionIntensityX
    local oZ = math.sin(t*18.7)*currentDistance*0.18*evasionIntensityZ
    local oY = math.sin(t*11.3)*currentDistance*0.12*evasionIntensityY
    safeTeleport(hrp.CFrame.Position + Vector3.new(oX,oY,oZ))
end

local function runBlink()
    if not blinkEnabled or not hrp then return end
    if math.random() < blinkRate/60 then
        safeTeleport(hrp.Position + Vector3.new(
            (math.random()*2-1)*blinkRadiusX,
            (math.random()*2-1)*blinkRadiusY,
            (math.random()*2-1)*blinkRadiusZ
        ))
    end
end

local function runGhost()
    if not ghostEnabled or not hrp then return end
    safeTeleport(hrp.Position + Vector3.new(
        math.sin(tick()*5)*ghostDistanceX,
        math.cos(tick()*7)*ghostDistanceY,
        math.sin(tick()*6)*ghostDistanceZ
    ))
end

local function runOrbitEnemy()
    if not orbitEnemyEnabled or not hrp then return end
    local t = getClosestHRP()
    if t then
        local a = tick() * orbitSpeed_arch
        safeTeleport(t.Position + Vector3.new(math.sin(a)*orbitRadius_arch, 2, math.cos(a)*orbitRadius_arch))
        hrp.CFrame = CFrame.new(hrp.Position, t.Position)
    end
end

local function runCFrameFlight(dt)
    if not cframeFlightEnabled or not hrp or not humanoid then return end
    humanoid.PlatformStand = true
    local md  = humanoid.MoveDirection
    local ccf = camera.CFrame
    local fw  = ccf:VectorToWorldSpace(Vector3.new(0,0,-1))
    local rt  = ccf:VectorToWorldSpace(Vector3.new(1,0,0))
    local up  = Vector3.new(0,1,0)
    local vel = fw*md.Z*flightSpeedZ + rt*md.X*flightSpeedX
    if UIS:IsKeyDown(Enum.KeyCode.Space)      then vel = vel + up*flightSpeedY end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift)  then vel = vel - up*flightSpeedY end
    local np = hrp.Position + vel*dt
    hrp.CFrame = CFrame.new(np) * CFrame.Angles(ccf:ToEulerAnglesXYZ())
end

local function runFakeLag()
    if not fakeLagEnabled or not hrp then return end
    if tick() - lastFakeLagUpdate > fakeLagInterval then
        lastFakeLagUpdate = tick(); hrp.Anchored = false
    else hrp.Anchored = true end
end

local function runAntiAim()
    if not antiAimEnabled or not hrp then return end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(
        math.rad(math.random(-180,180)),
        math.rad(tick()*antiAimSpeed%360),
        math.rad(math.random(-180,180))
    )
end

local function runAutoFacing()
    if not autoFacingEnabled or not hrp then return end
    local t = getClosestHRP()
    if t then hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(t.Position.X, hrp.Position.Y, t.Position.Z)) end
end

connections["Noclip"] = RunService.Stepped:Connect(function()
    if noclipBypassEnabled and character then
        for _, p in ipairs(character:GetChildren()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

local HEAL_WORDS = {"heal","health","medkit","medic","kit","potion","pack","firstaid","bandage","hp",
    "restore","pickup","orb","heart","regen","pill","syringe","cure","bottle","food","apple"}

connections["AutoHeal"] = RunService.Heartbeat:Connect(function()
    if autoHealEnabled and humanoid and humanoid.Health < humanoid.MaxHealth * 0.5 then
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                for _, w in ipairs(HEAL_WORDS) do
                    if tool.Name:lower():find(w) then
                        humanoid:EquipTool(tool); tool:Activate(); task.wait(0.3); break
                    end
                end
            end
        end
    end
end)

connections["ProjectileDodge"] = RunService.Heartbeat:Connect(function()
    if projectileDodgeEnabled and hrp then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") and not d.Anchored
                and d.AssemblyLinearVelocity.Magnitude > 50 then
                if (d.Position - hrp.Position).Magnitude < projectileDodgeRadius then
                    local dot = d.AssemblyLinearVelocity.Unit:Dot((hrp.Position - d.Position).Unit)
                    if dot > 0.7 then
                        local sv = Vector3.new(-d.AssemblyLinearVelocity.Z, 0, d.AssemblyLinearVelocity.X).Unit * 15
                        safeTeleport(hrp.Position + sv); break
                    end
                end
            end
        end
    end
end)

connections["DynamicAnchor"] = RunService.Heartbeat:Connect(function()
    if dynamicSafeAnchorEnabled and hrp and dynamicTargetPlayer ~= "" then
        local tp = Players:FindFirstChild(dynamicTargetPlayer)
        if tp and tp.Character and tp.Character:FindFirstChild("HumanoidRootPart") then
            local th = tp.Character.HumanoidRootPart
            if humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
                or hrp.AssemblyLinearVelocity.Magnitude > 120) then
                task.wait(0.2); safeTeleport(th.Position + Vector3.new(0,3,0))
            end
        end
    end
end)

local function runMainTeleport(dt)
    if not (running or closestEnabled) or not hrp then return end
    if closestEnabled then
        local enemy = getClosestHRP()
        if enemy then
            local off = Vector3.new(0,0,0)
            if     enemyPositionMode == "Above"   then off = Vector3.new(0, enemyTeleportDistance, 0)
            elseif enemyPositionMode == "Behind"  then off = -enemy.CFrame.LookVector * enemyTeleportDistance
            elseif enemyPositionMode == "Under"   then off = Vector3.new(0, -enemyTeleportDistance, 0)
            elseif enemyPositionMode == "InFront" then off = enemy.CFrame.LookVector * enemyTeleportDistance
            end
            off = off + Vector3.new(enemyOffsetX, enemyOffsetY, enemyOffsetZ)
            local tp = enemy.Position + off
            if not ignoreDeathCheck and tp.Y < -20 then return end
            safeTeleport(tp)
        end
        return
    end
    if tick() - lastTeleport < teleportInterval then return end
    lastTeleport = tick()
    if teleportMode == "RANDOM" then
        local ph = tick() * 28
        local r1 = currentDistance * (0.60 + 0.40*math.sin(ph*2.3))
        safeTeleport(hrp.Position + Vector3.new(
            math.cos(ph*7.1)*r1*tpScaleX,
            math.sin(ph*11.3)*r1*tpScaleY,
            math.sin(ph*7.1)*r1*tpScaleZ
        ))
    elseif teleportMode == "FORWARD" then
        safeTeleport(hrp.Position + (hrp.CFrame.LookVector * currentDistance))
    elseif teleportMode == "CAMERA" then
        safeTeleport(hrp.Position + (camera.CFrame.LookVector * currentDistance))
    end
end

connections["MainLoop"] = RunService.Heartbeat:Connect(function(dt)
    runMainTeleport(dt)
    runRiotAbuser(dt)
    runEvasion()
    runBlink()
    runGhost()
    runOrbitEnemy()
    runCFrameFlight(dt)
    runFakeLag()
    runAntiAim()
    runAutoFacing()
end)

connections["ClickTeleport"] = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == clickTeleportHotkey then
        local mouse = player:GetMouse()
        if mouse.Hit then safeTeleport(mouse.Hit.Position) end
    end
end)

connections["YoYoStrike"] = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V and hrp and not yoyoStrikeEnabled then
        local t = getClosestHRP()
        if t then
            yoyoAnchor = hrp.CFrame; yoyoStrikeEnabled = true
            safeTeleport(t.Position - t.CFrame.LookVector * 4)
        end
    end
end)
connections["YoYoStrikeEnd"] = UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V and yoyoStrikeEnabled and yoyoAnchor then
        if hrp then hrp.CFrame = yoyoAnchor end
        yoyoStrikeEnabled = false; yoyoAnchor = nil
    end
end)

connections["SafeZoneRescue"] = RunService.Heartbeat:Connect(function()
    if not hrp then return end
    if hrp.Position.Y > safeZoneY then safeZoneSavedPos = hrp.Position
    elseif safeZoneEnabled and safeZoneSavedPos then hrp.CFrame = CFrame.new(safeZoneSavedPos) end
end)

connections["AutocollectHeals"] = RunService.Heartbeat:Connect(function()
    if not autocollectEnabled or not hrp then return end
    local bestPos, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        local isH = false
        for _, w in ipairs(HEAL_WORDS) do if n:find(w) then isH=true; break end end
        if isH then
            local pos = obj:IsA("BasePart") and obj.Position
                or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
            if pos then
                local d = (pos - hrp.Position).Magnitude
                if d < bestDist and d <= autocollectRadius then bestDist=d; bestPos=pos end
            end
        end
    end
    if bestPos then safeTeleport(bestPos) end
end)

connections["ReturnHomeLoop"] = task.spawn(function()
    while true do
        task.wait(homeReturnDelay)
        if returnHomeEnabled and hrp and homePosition then
            if (hrp.Position - homePosition).Magnitude > 50 then safeTeleport(homePosition) end
        end
    end
end)

connections["WaypointLoop"] = task.spawn(function()
    while true do
        task.wait(teleportLoopDelay)
        if teleportLoopEnabled and #teleportLoopPositions > 0 and hrp then
            local t = teleportLoopPositions[teleportLoopIndex]
            if t then safeTeleport(t) end
            teleportLoopIndex = (teleportLoopIndex % #teleportLoopPositions) + 1
        end
    end
end)

local function createESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            if espBoxTracersEnabled and not p.Character:FindFirstChild("ArchESP") then
                local h = Instance.new("Highlight")
                h.Name = "ArchESP"; h.FillColor = Color3.fromRGB(255,0,0)
                h.OutlineColor = Color3.fromRGB(255,255,255); h.Parent = p.Character
            elseif not espBoxTracersEnabled and p.Character:FindFirstChild("ArchESP") then
                p.Character.ArchESP:Destroy()
            end
        end
    end
end
task.spawn(function() while true do task.wait(1); pcall(createESP) end end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if targetSpectateEnabled then
            local t = getClosestHRP()
            if t and t.Parent and t.Parent:FindFirstChild("Humanoid") then
                camera.CameraSubject = t.Parent.Humanoid
            end
        else if humanoid then camera.CameraSubject = humanoid end end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if hitboxExpanderEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    p.Character.HumanoidRootPart.CanCollide = false
                end
            end
        end
    end
end)

local function toggleInvisibility(state)
    clientInvisibilityEnabled = state
    if state and hrp then
        originalCFrame = hrp.CFrame
        character.Archivable = true
        fakeDeathNPC = character:Clone()
        fakeDeathNPC.Parent = Workspace
        fakeDeathNPC:MoveTo(hrp.Position)
        safeTeleport(Vector3.new(99999, -500, 99999))
    else
        if fakeDeathNPC then fakeDeathNPC:Destroy(); fakeDeathNPC = nil end
        if originalCFrame then safeTeleport(originalCFrame.Position) end
    end
end

-- ============================================================
-- CSYNC VOID (original Arch)
-- ============================================================
local CSync = {
    settings = {
        enable_void       = false,
        switchSpeed       = 0.05,
        depthMultiplier   = 1,
        rand_vel_x        = 0,
        rand_vel_y        = 0,
        rand_vel_z        = 0,
        jerk_intensity    = 20,
        random_vel_intensity = 15,
        void_keybind      = Enum.KeyCode.H
    },
    voidActive=false, lastSwitch=0, currentVoidIndex=1,
    originalCFrame=nil, csyncConnection=nil,
    desyncEnabled=false, simPosition=Vector3.new(0,0,0),
    simVelocity=Vector3.new(0,0,0), jerkTimer=0,
    keybindPressed=false, deepVoidPositions={}
}

local function find(obj, name) return obj and obj:FindFirstChild(name) end

local function cframeInvalid(cf)
    if not cf then return true end
    local p = cf.Position; if not p then return true end
    return p.Y < -10000 or math.abs(p.X) > 500000 or math.abs(p.Z) > 500000
end

local function generateDeepVoid()
    local pos = {}
    local depths = {-1e6,-2e6,-5e6,-1e7,-2e7}
    local far    = {-1e6,-5e5,-2e5,-1e5,1e5,2e5,5e5,1e6}
    for i = 1,20 do
        pos[i] = CFrame.new(
            far[math.random(1,#far)] + math.random(-5000,5000),
            depths[math.random(1,#depths)] + math.random(-5000,5000),
            far[math.random(1,#far)] + math.random(-5000,5000)
        )
    end
    return pos
end
CSync.deepVoidPositions = generateDeepVoid()

local function updateSimulation(dt)
    if not CSync.desyncEnabled then return end
    local S = CSync.settings
    CSync.jerkTimer = CSync.jerkTimer - dt
    if CSync.jerkTimer <= 0 then
        CSync.jerkTimer = math.random(3,10)/10
        local ji = S.jerk_intensity/100
        CSync.simVelocity = CSync.simVelocity + Vector3.new(
            math.random(-40,40)*ji, math.random(-40,40)*ji, math.random(-40,40)*ji
        )
    end
    local ri = S.random_vel_intensity/100
    local chaos = Vector3.new(
        math.random(-60,60)*ri, math.random(-60,60)*ri, math.random(-60,60)*ri
    )
    local base = Vector3.new(
        math.random(-S.rand_vel_x, S.rand_vel_x),
        math.random(-S.rand_vel_y, S.rand_vel_y),
        math.random(-S.rand_vel_z, S.rand_vel_z)
    )
    CSync.simVelocity  = CSync.simVelocity*0.9 + base + chaos
    CSync.simPosition  = CSync.simPosition + CSync.simVelocity*dt
end

local function getDesyncOffset()
    local S = CSync.settings
    local anchor = Vector3.new(0,0,0)
    if CSync.voidActive and CSync.deepVoidPositions[CSync.currentVoidIndex] then
        local bp = CSync.deepVoidPositions[CSync.currentVoidIndex].Position
        local d  = S.depthMultiplier or 1
        anchor   = Vector3.new(bp.X*d, bp.Y*d, bp.Z*d)
    end
    return anchor + CSync.simPosition
end

local function stopCSync()
    if CSync.csyncConnection then
        CSync.csyncConnection:Disconnect(); CSync.csyncConnection = nil
    end
end

local function startCSync()
    local char2 = player.Character
    local hrp2  = char2 and find(char2,"HumanoidRootPart")
    if not hrp2 or CSync.csyncConnection then return end
    CSync.csyncConnection = RunService.Heartbeat:Connect(function()
        local c2 = player.Character
        local h2 = c2 and find(c2,"HumanoidRootPart")
        if not h2 then return end
        local realCF = h2.CFrame
        h2.CFrame = CFrame.new(getDesyncOffset())
        RunService.RenderStepped:Wait()
        h2.CFrame = realCF
    end)
end

local function updateVoid(dt)
    if not CSync.voidActive then return end
    if tick() - CSync.lastSwitch < CSync.settings.switchSpeed then return end
    CSync.lastSwitch = tick()
    CSync.currentVoidIndex = (CSync.currentVoidIndex % #CSync.deepVoidPositions) + 1
end

local function startVoid()
    local c2 = player.Character
    local h2 = c2 and find(c2,"HumanoidRootPart")
    if not h2 then return end
    CSync.originalCFrame = h2.CFrame
    CSync.voidActive = true; CSync.desyncEnabled = true
    startCSync()
end

local function stopVoid()
    CSync.voidActive = false; CSync.desyncEnabled = false; stopCSync()
end

local function safeReturn()
    stopCSync(); task.wait(0.1)
    local c2 = player.Character
    local h2 = c2 and find(c2,"HumanoidRootPart")
    if not h2 then return end
    local rcf = CSync.originalCFrame or CFrame.new(0,20,0)
    if cframeInvalid(rcf) then rcf = CFrame.new(0,20,0) end
    h2.CFrame = rcf
end

connections["CSyncMainLoop"] = RunService.Heartbeat:Connect(function(dt)
    updateVoid(dt); updateSimulation(dt)
end)

-- ============================================================
-- ARCH EMOTE V3 SYSTEM (unchanged)
-- ============================================================
local isCustomEmoteActive = false
local currentRotationSpeed = 0
local defaultSpeedFactor = 1
local rotationAngle = 0
local currentEmoteStyle = "Glitched Chaos"
local characterParts = nil
local chaoticSeed = tick()
local perlinOffset = 0
local targetPlayer = player
local lastTargetPlayer = nil
local currentEmoteConfig = nil
local isEmoteEnabled = false

local isNoodleMode=false; local isNeonGlitchMode=false; local isPaperMode=false
local isJitterMode=false; local isMeatballMode=false; local isGhostMode=false
local isTrailsMode=false; local isRainbowMode=false; local isMorphMode=false
local currentMatIndex = 1
local customMatList = {
    {name="Original",mat=nil},
    {name="ForceField",mat=Enum.Material.ForceField},
    {name="Glass",mat=Enum.Material.Glass},
    {name="Foil",mat=Enum.Material.Foil},
    {name="Marble",mat=Enum.Material.Marble}
}

local fakePartsFolder = workspace:FindFirstChild("ArchEmoteEnhancementsV3_FakeParts")
if not fakePartsFolder then
    fakePartsFolder = Instance.new("Folder")
    fakePartsFolder.Name = "ArchEmoteEnhancementsV3_FakeParts"
    fakePartsFolder.Parent = workspace
end

local allowedBodyParts = {
    Head=true,Torso=true,UpperTorso=true,LowerTorso=true,
    ["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,
    LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,
    RightUpperArm=true,RightLowerArm=true,RightHand=true,
    LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,
    RightUpperLeg=true,RightLowerLeg=true,RightFoot=true
}

local function isValidPart(part)
    if not part:IsA("BasePart") then return false end
    if allowedBodyParts[part.Name] then return true end
    if part.Parent and part.Parent:IsA("Accessory") and part.Name == "Handle" then return true end
    return false
end

local function getCharacterParts(char)
    local rp = char:FindFirstChild("HumanoidRootPart"); if not rp then return nil end
    local pi = {RootPart=rp, Pieces={}}
    char.Archivable = true
    for _, child in ipairs(char:GetDescendants()) do
        if isValidPart(child) then
            child.Archivable = true
            local fp = child:Clone()
            for _, sc in ipairs(fp:GetDescendants()) do
                if sc:IsA("JointInstance") or sc:IsA("Script") or sc:IsA("LocalScript")
                    or sc:IsA("Constraint") or sc:IsA("BodyMover") or sc:IsA("Attachment") then
                    sc:Destroy()
                end
            end
            fp.Name = "EmoteVisual_"..child.Name
            fp.Anchored=true; fp.CanCollide=false; fp.CanQuery=false
            fp.Massless=true; fp.CastShadow=false; fp.Parent=fakePartsFolder
            fp.Material = isNeonGlitchMode and Enum.Material.Neon
                or (customMatList[currentMatIndex].mat or fp.Material)
            local a0 = Instance.new("Attachment",fp); a0.Position=Vector3.new(0,fp.Size.Y/2,0)
            local a1 = Instance.new("Attachment",fp); a1.Position=Vector3.new(0,-fp.Size.Y/2,0)
            local trail = Instance.new("Trail",fp)
            trail.Attachment0=a0; trail.Attachment1=a1; trail.Enabled=isTrailsMode
            trail.Lifetime=0.4; trail.LightEmission=0.8
            trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            trail.Color=ColorSequence.new(fp.Color)
            local emitter = Instance.new("ParticleEmitter",fp)
            emitter.Enabled=isGhostMode or isNeonGlitchMode; emitter.Rate=15
            emitter.Speed=NumberRange.new(1,3); emitter.Lifetime=NumberRange.new(0.5,1)
            emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)})
            emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,1)})
            table.insert(pi.Pieces,{
                realPart=child, fakePart=fp, trail=trail, emitter=emitter,
                physicsSeed=chaoticSeed+#pi.Pieces*13,
                spinAxis=Vector3.new(math.random(-100,100),math.random(-100,100),math.random(-100,100)).Unit,
                originalMaterial=child.Material, originalColor=fp.Color
            })
        end
    end
    return pi
end

function stopCustomEmote()
    isCustomEmoteActive=false; currentRotationSpeed=0
    if characterParts then
        for _, info in ipairs(characterParts.Pieces) do
            if info.realPart and info.realPart.Parent then info.realPart.LocalTransparencyModifier=0 end
        end
        characterParts=nil
    end
    fakePartsFolder:ClearAllChildren()
    workspace.CurrentCamera.FieldOfView=70
    lastTargetPlayer=nil; currentEmoteConfig=nil
end

function playCustomEmote(baseSpeed, style)
    currentEmoteConfig={speed=baseSpeed, style=style}
    if not isCustomEmoteActive or targetPlayer ~= lastTargetPlayer then
        stopCustomEmote()
        local ok = false
        for _ = 1,15 do
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                fakePartsFolder:ClearAllChildren()
                characterParts=getCharacterParts(targetPlayer.Character)
                if characterParts and #characterParts.Pieces > 0 then
                    ok=true; lastTargetPlayer=targetPlayer; break
                end
            end
            task.wait(0.2)
        end
        if not ok then
            Notifier.new({Title="Emote Failed",Content="Target not fully loaded.",Duration=3}); return
        end
        isCustomEmoteActive=true
    end
    currentRotationSpeed=baseSpeed; currentEmoteStyle=style; rotationAngle=0; chaoticSeed=tick()
end

local renderConnection
if renderConnection then renderConnection:Disconnect() end
renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not isCustomEmoteActive or not characterParts then return end
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        stopCustomEmote(); return
    end
    rotationAngle  = rotationAngle + (currentRotationSpeed * defaultSpeedFactor * dt)
    perlinOffset   = perlinOffset + dt * 0.5
    local rootCF   = characterParts.RootPart.CFrame
    local numPieces= #characterParts.Pieces
    local timeE    = tick() * (1 + defaultSpeedFactor/100)
    for i, info in ipairs(characterParts.Pieces) do
        if info.realPart and info.realPart.Parent then info.realPart.LocalTransparencyModifier=1 end
        if not info.fakePart or not info.fakePart.Parent then continue end
        local seed = info.physicsSeed
        local cs   = info.realPart.Size
        local tt   = 0
        if isRainbowMode then
            local hue = (timeE*0.3 + i/numPieces) % 1
            info.fakePart.Color = Color3.fromHSV(hue,1,1)
            info.trail.Color = ColorSequence.new(info.fakePart.Color)
        elseif isNeonGlitchMode then
            local r = math.noise(timeE*20,seed,0)+0.5
            local g = math.noise(0,timeE*25,seed)+0.5
            local b = math.noise(seed,0,timeE*18)+0.5
            if math.random()>0.4 then
                info.fakePart.Color=Color3.new(math.clamp(r,0,1),math.clamp(g,0,1),math.clamp(b,0,1))
            else info.fakePart.Color=math.random()>0.5 and Color3.new(0,0,0) or Color3.new(1,1,1) end
            info.trail.Color=ColorSequence.new(info.fakePart.Color)
        end
        local ang = math.rad(rotationAngle)
        local rr  = math.random(50,200)/100
        local rX,rY,rZ = ang*rr, ang*rr, ang*rr
        local fp  = Vector3.new(0,0,0)
        if isMorphMode then
            local sx=1+math.abs(math.sin(timeE*3.1+seed))*3
            local sy=1+math.abs(math.cos(timeE*4.2+seed))*3
            local sz=1+math.abs(math.sin(timeE*5.3+seed))*3
            cs=cs*Vector3.new(sx,sy,sz)
        end
        if isMeatballMode then
            local mr=1+math.sin(timeE*5+seed)*0.5
            fp=Vector3.new(math.sin(seed)*mr,math.cos(seed*1.5)*mr,math.sin(seed*2)*mr)
            cs=cs*math.max(0.1,math.abs(math.sin(timeE*10+seed))*3)
        end
        if isNoodleMode then
            local cn=math.noise(seed,timeE*15,0)
            cs=Vector3.new(
                math.clamp(math.abs(math.sin(timeE*25+seed)*8)+cn*5,0.01,10),
                math.clamp(math.abs(math.cos(timeE*18+seed*1.5)*8)-cn*5,0.01,10),
                info.realPart.Size.Magnitude*(25+math.sin(timeE*15+seed)*math.cos(timeE*9+seed)*20)
            )
            local sr=5+cn*8
            fp=fp+Vector3.new(math.cos(timeE*20+seed)*sr,math.sin(timeE*22+seed)*sr,math.sin(timeE*14+seed)*sr)
            rX=rX+math.sin(timeE*15+seed)*5; rY=rY+math.cos(timeE*12+seed)*5; rZ=rZ+cn*15
        end
        if isPaperMode then cs=Vector3.new(cs.X,cs.Y,0.01); rZ=rZ+timeE*50 end
        if isJitterMode then
            local go=Vector3.new(math.random(-20,20)/10,math.random(-20,20)/10,math.random(-20,20)/10)
            if math.random()>0.9 then go=go*5 end; fp=fp+go
        end
        if isGhostMode then
            local fl=math.noise(timeE*30,seed,0)
            if fl>0.2 then tt=1 elseif fl<-0.2 then tt=0.8 end
            info.emitter.Color=ColorSequence.new(Color3.new(0,0,0))
        end
        info.fakePart.Size=cs; info.fakePart.Transparency=tt
        info.fakePart.CFrame=(rootCF*CFrame.new(fp))*CFrame.Angles(rX,rY,rZ)
    end
end)

local emotePacks = {
    ["The Ultimates"]  = {{name="Omni Singularity",speed=2000,style="Omniversal Singularity"},{name="Reality Disintegration",speed=2000,style="Reality Disintegration"}},
    ["Cosmic Chaos"]   = {{name="Head Spin",speed=400,style="Head Centric Orbit"},{name="Orbital Glitch",speed=200,style="Glitched Chaos"},{name="Black Hole",speed=300,style="Black Hole"},{name="Drift",speed=250,style="Hyperspace Drift"},{name="Scatter",speed=350,style="Quantum Scatter"},{name="Tornado",speed=280,style="Explosive Tornado"},{name="Fracture",speed=450,style="Dimensional Fracture"},{name="Swarm",speed=500,style="Brownian Swarm"},{name="Eruption",speed=400,style="Void Eruption"},{name="Neural",speed=600,style="Neural Glitch"},{name="Orbit",speed=350,style="Plasma Orbit"}},
    ["Chill Modes"]    = {{name="Slow Orbit",speed=50,style="Plasma Orbit"},{name="Gentle Drift",speed=30,style="Hyperspace Drift"},{name="Soft Swarm",speed=40,style="Brownian Swarm"},{name="Lazy Tornado",speed=60,style="Explosive Tornado"}},
    ["Insanity"]       = {{name="Hyper Glitch",speed=1500,style="Glitched Chaos"},{name="Max Tornado",speed=1200,style="Explosive Tornado"},{name="Quantum Death",speed=2000,style="Quantum Scatter"}},
    ["Cyber Matrix"]   = {{name="System Override",speed=800,style="Neural Glitch"},{name="Data Corrupted",speed=750,style="Glitched Chaos"},{name="Code Scatter",speed=900,style="Quantum Scatter"}},
    ["Divine Halo"]    = {{name="Angelic Orbit",speed=100,style="Plasma Orbit"},{name="Holy Rings",speed=150,style="Hyperspace Drift"},{name="Ascension",speed=80,style="Brownian Swarm"}},
    ["Abyssal Curse"]  = {{name="Dark Grasp",speed=120,style="Black Hole"},{name="Void Consume",speed=180,style="Void Eruption"},{name="Shattered Soul",speed=200,style="Dimensional Fracture"}},
    ["Galactic Core"]  = {{name="Stellar Spin",speed=400,style="Plasma Orbit"},{name="Core Collapse",speed=600,style="Black Hole"},{name="Nebula Storm",speed=500,style="Explosive Tornado"}},
    ["Time Warp"]      = {{name="Slow Motion",speed=10,style="Glitched Chaos"},{name="Fast Forward",speed=1000,style="Brownian Swarm"},{name="Time Fracture",speed=450,style="Dimensional Fracture"}},
    ["Nuclear Fallout"]= {{name="Atomic Blast",speed=700,style="Void Eruption"},{name="Radiation Swarm",speed=650,style="Brownian Swarm"},{name="Mushroom Cloud",speed=550,style="Explosive Tornado"}},
    ["Glitch Dimension"]={{name="Reality Tear",speed=850,style="Dimensional Fracture"},{name="404 Error",speed=900,style="Neural Glitch"},{name="Z-Fighting",speed=950,style="Glitched Chaos"}},
    ["Supernova"]      = {{name="Star Death",speed=800,style="Plasma Orbit"},{name="Energy Burst",speed=1000,style="Void Eruption"},{name="Light Speed",speed=1200,style="Hyperspace Drift"}},
    ["Poltergeist"]    = {{name="Ghostly Float",speed=60,style="Quantum Scatter"},{name="Possession",speed=150,style="Neural Glitch"},{name="Ectoplasm",speed=120,style="Brownian Swarm"}},
    ["Absolute Zero"]  = {{name="Frozen Particles",speed=5,style="Quantum Scatter"},{name="Ice Crystals",speed=15,style="Dimensional Fracture"},{name="Blizzard",speed=400,style="Explosive Tornado"}},
    ["Sacred Geometry"]= {{name="Pulsing Sphere",speed=100,style="Pulsing Sphere"},{name="Saturn Rings",speed=150,style="Saturn Rings"},{name="Hyper Torus",speed=250,style="Hyper Torus"}},
    ["Biohazard"]      = {{name="DNA Helix",speed=150,style="DNA Helix"},{name="Viral Swarm",speed=400,style="Brownian Swarm"},{name="Parasite",speed=600,style="Neural Glitch"}},
    ["Armageddon"]     = {{name="Meteor Strike",speed=300,style="Meteor Strike"},{name="World Ender",speed=2000,style="Reality Disintegration"},{name="Doomsday",speed=800,style="Black Hole"}}
}

-- ============================================================
-- KEYBIND HANDLER
-- ============================================================
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then running = not running end
    if input.KeyCode == Enum.KeyCode.R then riotRunning = not riotRunning end
    if input.KeyCode == Enum.KeyCode.E then evasionEnabled = not evasionEnabled end
    if input.KeyCode == Enum.KeyCode.B then blinkEnabled = not blinkEnabled end
    if input.KeyCode == Enum.KeyCode.G then ghostEnabled = not ghostEnabled end
    if input.KeyCode == CSync.settings.void_keybind then
        if CSync.keybindPressed then return end
        CSync.keybindPressed = true
        local ns = not CSync.settings.enable_void
        if ns then startVoid() else stopVoid() end
        CSync.settings.enable_void = ns
        task.delay(0.2, function() CSync.keybindPressed = false end)
    end
end)

-- ============================================================
-- CHARACTER EVENTS (emote)
-- ============================================================
player.CharacterAdded:Connect(function()
    if targetPlayer == player then stopCustomEmote() end
end)
player.CharacterRemoving:Connect(function()
    if targetPlayer == player then stopCustomEmote() end
end)

-- ============================================================
-- ==================== UI TABS =============================
-- ============================================================

-- ── MOVEMENT ─────────────────────────────────────────────
Window:DrawCategory({ Name = "Movement" })
local TabMovement = Window:DrawTab({ Name="Movement", Icon="shield", EnableScrolling=true })

local MoveBasicSection = TabMovement:DrawSection({ Name="Basic Teleport", Position="left" })
MoveBasicSection:AddToggle({ Name="Random TP (Key T)", Flag="Toggle_RandomTP", Default=false, Callback=function(v) running=v end })
MoveBasicSection:AddDropdown({ Name="TP Mode", Flag="Dropdown_TPMode", Default="RANDOM", Values={"RANDOM","FORWARD","CAMERA"}, Callback=function(o) teleportMode=o end })
MoveBasicSection:AddSlider({ Name="Range", Min=50, Max=10000000000, Default=500, Round=0, Flag="Slider_TPRadius", Callback=function(v) currentDistance=v end })
MoveBasicSection:AddTextBox({ Name="Interval (s)", Placeholder="0.035", Default="0.035", Flag="Input_TPInterval", Callback=function(t) local n=tonumber(t); if n and n>0 then teleportInterval=math.max(1e-20,math.min(n,1)) end end })

local AxisSection = TabMovement:DrawSection({ Name="Axis Scaling", Position="left" })
AxisSection:AddSlider({ Name="X Scale", Min=0, Max=10000000000, Default=1, Increment=0.1, Flag="Slider_TPScaleX", Callback=function(v) tpScaleX=v end })
AxisSection:AddSlider({ Name="Y Scale", Min=0, Max=10000000000, Default=1, Increment=0.1, Flag="Slider_TPScaleY", Callback=function(v) tpScaleY=v end })
AxisSection:AddSlider({ Name="Z Scale", Min=0, Max=10000000000, Default=1, Increment=0.1, Flag="Slider_TPScaleZ", Callback=function(v) tpScaleZ=v end })

local RiotSection = TabMovement:DrawSection({ Name="Riot Jitter (Key R)", Position="left" })
RiotSection:AddToggle({ Name="Enable Riot Jitter", Flag="Toggle_Riot", Default=false, Callback=function(v) riotRunning=v end })
RiotSection:AddSlider({ Name="Spin Speed", Min=100, Max=10000000000, Default=720, Increment=50, Flag="Slider_SpinSpeed", Callback=function(v) spinSpeed=v end })
RiotSection:AddSlider({ Name="Distance", Min=50, Max=10000000000, Default=300, Increment=10, Flag="Slider_RiotDist", Callback=function(v) riotDistance=v end })
RiotSection:AddSlider({ Name="Jitter X", Min=0, Max=10000000000, Default=30, Increment=1, Flag="Slider_RiotX", Callback=function(v) riotXJitter=v end })
RiotSection:AddSlider({ Name="Jitter Y", Min=0, Max=10000000000, Default=8, Increment=1, Flag="Slider_RiotY", Callback=function(v) riotYJitter=v end })
RiotSection:AddSlider({ Name="Jitter Z", Min=0, Max=10000000000, Default=30, Increment=1, Flag="Slider_RiotZ", Callback=function(v) riotZJitter=v end })
RiotSection:AddSlider({ Name="Pitch Mult", Min=0.1, Max=10, Default=0.37, Increment=0.01, Flag="Slider_RiotPitch", Callback=function(v) riotPitchMult=v end })
RiotSection:AddSlider({ Name="Roll Mult", Min=0.1, Max=10, Default=0.19, Increment=0.01, Flag="Slider_RiotRoll", Callback=function(v) riotRollMult=v end })
RiotSection:AddSlider({ Name="Osc Freq", Min=0.5, Max=20, Default=3.1, Increment=0.1, Flag="Slider_RiotFreq", Callback=function(v) riotOscFreq=v end })

local AsymSection = TabMovement:DrawSection({ Name="Asymmetry Multipliers", Position="left" })
AsymSection:AddSlider({ Name="X Pos", Min=0, Max=10, Default=1, Increment=0.1, Flag="Slider_RiotAsymXPos", Callback=function(v) riotAsymmetryXPos=v end })
AsymSection:AddSlider({ Name="X Neg", Min=0, Max=10, Default=1, Increment=0.1, Flag="Slider_RiotAsymXNeg", Callback=function(v) riotAsymmetryXNeg=v end })
AsymSection:AddSlider({ Name="Y Pos", Min=0, Max=10, Default=1, Increment=0.1, Flag="Slider_RiotAsymYPos", Callback=function(v) riotAsymmetryYPos=v end })
AsymSection:AddSlider({ Name="Y Neg", Min=0, Max=10, Default=1, Increment=0.1, Flag="Slider_RiotAsymYNeg", Callback=function(v) riotAsymmetryYNeg=v end })
AsymSection:AddSlider({ Name="Z Pos", Min=0, Max=10, Default=1, Increment=0.1, Flag="Slider_RiotAsymZPos", Callback=function(v) riotAsymmetryZPos=v end })
AsymSection:AddSlider({ Name="Z Neg", Min=0, Max=10, Default=1, Increment=0.1, Flag="Slider_RiotAsymZNeg", Callback=function(v) riotAsymmetryZNeg=v end })

local AdvMoveSection = TabMovement:DrawSection({ Name="Advanced Movement", Position="right" })
AdvMoveSection:AddToggle({ Name="Orbit Enemy", Flag="Toggle_OrbitEnemy", Default=false, Callback=function(v) orbitEnemyEnabled=v end })
AdvMoveSection:AddSlider({ Name="Radius", Min=5, Max=10000000000, Default=15, Increment=1, Flag="Slider_OrbitRadius", Callback=function(v) orbitRadius_arch=v end })
AdvMoveSection:AddSlider({ Name="Speed", Min=1, Max=10000000000, Default=5, Increment=1, Flag="Slider_OrbitSpeed", Callback=function(v) orbitSpeed_arch=v end })
AdvMoveSection:AddToggle({ Name="Noclip", Flag="Toggle_Noclip", Default=false, Callback=function(v) noclipBypassEnabled=v end })
AdvMoveSection:AddToggle({ Name="CFrame Flight", Flag="Toggle_Flight", Default=false, Callback=function(v) cframeFlightEnabled=v; if not v and humanoid then humanoid.PlatformStand=false end end })
AdvMoveSection:AddSlider({ Name="Speed X", Min=10, Max=10000000000, Default=50, Increment=5, Flag="Slider_FlightX", Callback=function(v) flightSpeedX=v end })
AdvMoveSection:AddSlider({ Name="Speed Y", Min=10, Max=10000000000, Default=50, Increment=5, Flag="Slider_FlightY", Callback=function(v) flightSpeedY=v end })
AdvMoveSection:AddSlider({ Name="Speed Z", Min=10, Max=10000000000, Default=50, Increment=5, Flag="Slider_FlightZ", Callback=function(v) flightSpeedZ=v end })
AdvMoveSection:AddToggle({ Name="Fake Lag", Flag="Toggle_FakeLag", Default=false, Callback=function(v) fakeLagEnabled=v; if not v and hrp then hrp.Anchored=false end end })
AdvMoveSection:AddSlider({ Name="Lag Interval (s)", Min=0.01, Max=10, Default=0.2, Increment=0.01, Flag="Slider_FakeLagInt", Callback=function(v) fakeLagInterval=v end })

local BlinkSection = TabMovement:DrawSection({ Name="Blink / Ghost / Evasion", Position="right" })
BlinkSection:AddToggle({ Name="Blink (Key B)", Flag="Toggle_Blink", Default=false, Callback=function(v) blinkEnabled=v end })
BlinkSection:AddSlider({ Name="Blink X", Min=10, Max=10000000000, Default=80, Increment=5, Flag="Slider_BlinkX", Callback=function(v) blinkRadiusX=v end })
BlinkSection:AddSlider({ Name="Blink Y", Min=10, Max=10000000000, Default=80, Increment=5, Flag="Slider_BlinkY", Callback=function(v) blinkRadiusY=v end })
BlinkSection:AddSlider({ Name="Blink Z", Min=10, Max=10000000000, Default=80, Increment=5, Flag="Slider_BlinkZ", Callback=function(v) blinkRadiusZ=v end })
BlinkSection:AddSlider({ Name="Rate /sec", Min=1, Max=10000000000, Default=60, Increment=1, Flag="Slider_BlinkRate", Callback=function(v) blinkRate=v end })
BlinkSection:AddToggle({ Name="Ghost (Key G)", Flag="Toggle_Ghost", Default=false, Callback=function(v) ghostEnabled=v end })
BlinkSection:AddSlider({ Name="Ghost X", Min=50, Max=10000000000, Default=150, Increment=10, Flag="Slider_GhostX", Callback=function(v) ghostDistanceX=v end })
BlinkSection:AddSlider({ Name="Ghost Y", Min=50, Max=10000000000, Default=150, Increment=10, Flag="Slider_GhostY", Callback=function(v) ghostDistanceY=v end })
BlinkSection:AddSlider({ Name="Ghost Z", Min=50, Max=10000000000, Default=150, Increment=10, Flag="Slider_GhostZ", Callback=function(v) ghostDistanceZ=v end })
BlinkSection:AddToggle({ Name="Evasion (Key E)", Flag="Toggle_Evasion", Default=false, Callback=function(v) evasionEnabled=v end })
BlinkSection:AddSlider({ Name="Evasion X", Min=0.1, Max=10000000000, Default=3.0, Increment=0.1, Flag="Slider_EvasionX", Callback=function(v) evasionIntensityX=v end })
BlinkSection:AddSlider({ Name="Evasion Y", Min=0.1, Max=10000000000, Default=3.0, Increment=0.1, Flag="Slider_EvasionY", Callback=function(v) evasionIntensityY=v end })
BlinkSection:AddSlider({ Name="Evasion Z", Min=0.1, Max=10000000000, Default=3.0, Increment=0.1, Flag="Slider_EvasionZ", Callback=function(v) evasionIntensityZ=v end })

local SurvivalSection = TabMovement:DrawSection({ Name="Auto Survival", Position="right" })
SurvivalSection:AddToggle({ Name="Auto Heal", Flag="Toggle_AutoHeal", Default=false, Callback=function(v) autoHealEnabled=v end })
SurvivalSection:AddToggle({ Name="Dodge Projectiles", Flag="Toggle_ProjDodge", Default=false, Callback=function(v) projectileDodgeEnabled=v end })
SurvivalSection:AddSlider({ Name="Dodge Radius", Min=10, Max=10000000000, Default=40, Increment=5, Flag="Slider_ProjDodgeRad", Callback=function(v) projectileDodgeRadius=v end })
SurvivalSection:AddToggle({ Name="Dynamic Anchor", Flag="Toggle_DynAnchor", Default=false, Callback=function(v) dynamicSafeAnchorEnabled=v end })
SurvivalSection:AddTextBox({ Name="Anchor Player", Placeholder="PlayerName", Default="", Flag="Input_AnchorPlayer", Callback=function(t) dynamicTargetPlayer=t end })
SurvivalSection:AddToggle({ Name="Safe Zone", Flag="Toggle_SafeZone", Default=false, Callback=function(v) safeZoneEnabled=v end })
SurvivalSection:AddSlider({ Name="Trigger Y", Min=-500, Max=10000000000, Default=-10, Increment=1, Flag="Slider_SafeZoneY", Callback=function(v) safeZoneY=v end })
SurvivalSection:AddToggle({ Name="Auto Collect", Flag="Toggle_AutoCollect", Default=false, Callback=function(v) autocollectEnabled=v end })
SurvivalSection:AddSlider({ Name="Collect Radius", Min=10, Max=10000000000, Default=60, Increment=5, Flag="Slider_AutoCollectRad", Callback=function(v) autocollectRadius=v end })

-- ── COMBAT ────────────────────────────────────────────────
Window:DrawCategory({ Name = "Combat" })
local TabCombat = Window:DrawTab({ Name="Combat", Icon="crosshair", EnableScrolling=true })

local CombatESP = TabCombat:DrawSection({ Name="ESP & Visuals", Position="left" })
CombatESP:AddToggle({ Name="ESP Box (Highlight)", Flag="Toggle_ESPBox", Default=false, Callback=function(v) espBoxTracersEnabled=v end })
CombatESP:AddToggle({ Name="Wireframe ESP (RCLC)", Flag="Toggle_Wireframe", Default=false, Callback=function(v) setWireframes(v) end })
CombatESP:AddToggle({ Name="Waypoint ESP", Flag="Toggle_ESPWaypoint", Default=false, Callback=function(v) waypointEspEnabled=v end })
CombatESP:AddToggle({ Name="Target Spectate", Flag="Toggle_TargetSpec", Default=false, Callback=function(v) targetSpectateEnabled=v end })

local CombatAim = TabCombat:DrawSection({ Name="Aimbot & Hitbox", Position="left" })
CombatAim:AddToggle({ Name="Lock Enemy TP", Flag="Toggle_ClosestEnemy", Default=false, Callback=function(v) closestEnabled=v end })
CombatAim:AddDropdown({ Name="Position", Flag="Dropdown_EnemyPos", Default="Behind", Values={"Above","Behind","Under","InFront"}, Callback=function(o) enemyPositionMode=o end })
CombatAim:AddSlider({ Name="Distance", Min=1, Max=10000000000, Default=10, Increment=1, Flag="Slider_EnemyTPDist", Callback=function(v) enemyTeleportDistance=v end })
CombatAim:AddSlider({ Name="Offset X", Min=-1000, Max=1000, Default=0, Increment=1, Flag="Slider_EnemyOffX", Callback=function(v) enemyOffsetX=v end })
CombatAim:AddSlider({ Name="Offset Y", Min=-1000, Max=1000, Default=0, Increment=1, Flag="Slider_EnemyOffY", Callback=function(v) enemyOffsetY=v end })
CombatAim:AddSlider({ Name="Offset Z", Min=-1000, Max=1000, Default=0, Increment=1, Flag="Slider_EnemyOffZ", Callback=function(v) enemyOffsetZ=v end })
CombatAim:AddToggle({ Name="Auto Face", Flag="Toggle_AutoFace", Default=false, Callback=function(v) autoFacingEnabled=v end })
CombatAim:AddToggle({ Name="Hitbox Expand", Flag="Toggle_Hitbox", Default=false, Callback=function(v)
    hitboxExpanderEnabled=v
    if not v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size=Vector3.new(2,2,1)
            end
        end
    end
end })
CombatAim:AddSlider({ Name="Hitbox Size", Min=2, Max=100, Default=10, Increment=1, Flag="Slider_HitboxSize", Callback=function(v) hitboxSize=v end })
CombatAim:AddToggle({ Name="Anti-Aim (Arch)", Flag="Toggle_AntiAim", Default=false, Callback=function(v) antiAimEnabled=v end })
CombatAim:AddSlider({ Name="Spin Speed", Min=100, Max=10000000000, Default=1500, Increment=100, Flag="Slider_AntiAimSpeed", Callback=function(v) antiAimSpeed=v end })
CombatAim:AddToggle({ Name="Fake Death / Invis", Flag="Toggle_Invisibility", Default=false, Callback=function(v) toggleInvisibility(v) end })

local CombatRCLC = TabCombat:DrawSection({ Name="Zombie Tower Kill Aura", Position="right" })
CombatRCLC:AddToggle({ Name="Enable Kill Aura", Flag="Toggle_KillAura", Default=false, Callback=function(v)
    killAuraCfg.enabled=v
    if v then enableKillAura() else disableKillAura() end
end })
CombatRCLC:AddSlider({ Name="Radius", Min=50, Max=100000, Default=5000, Increment=50, Flag="Slider_KARadius", Callback=function(v) killAuraCfg.radius=v end })
CombatRCLC:AddSlider({ Name="Fire Rate (s)", Min=0.01, Max=1, Default=0.02, Increment=0.01, Flag="Slider_KAFireRate", Callback=function(v) killAuraCfg.fireRate=v end })
CombatRCLC:AddSlider({ Name="Headshot Offset", Min=0, Max=5, Default=1, Increment=0.1, Flag="Slider_KAHSOffset", Callback=function(v) killAuraCfg.headshotOffset=v end })
CombatRCLC:AddSlider({ Name="Jitter", Min=0, Max=1, Default=0.02, Increment=0.01, Flag="Slider_KAJitter", Callback=function(v) killAuraCfg.jitter=v end })
CombatRCLC:AddDropdown({ Name="Weapon Slot", Flag="Dropdown_KASlot", Default="Primary", Values={"Primary","Secondary","Melee"}, Callback=function(o) killAuraCfg.weaponSlot=o end })
CombatRCLC:AddToggle({ Name="Auto Equip", Flag="Toggle_KAAutoEquip", Default=true, Callback=function(v) killAuraCfg.autoEquip=v end })

local CombatMelee = TabCombat:DrawSection({ Name="Fast Melee", Position="right" })
CombatMelee:AddToggle({ Name="Enable Fast Melee", Flag="Toggle_FastMelee", Default=false, Callback=function(v)
    fastMeleeCfg.enabled=v
    if v then enableFastMelee() else disableFastMelee() end
end })
CombatMelee:AddSlider({ Name="Cooldown", Min=0, Max=5, Default=0, Increment=0.01, Flag="Slider_MeleeCD", Callback=function(v) fastMeleeCfg.cooldown=v end })

local CombatGun = TabCombat:DrawSection({ Name="Fast Gun (Zombie Tower)", Position="right" })
CombatGun:AddToggle({ Name="Enable Fast Gun", Flag="Toggle_FastGun", Default=false, Callback=function(v)
    fastGunState.primaryOn=v
    if v then patchEquippedGuns() end
end })
CombatGun:AddButton({ Name="Rescan & Repatch All Guns", Callback=function()
    fastGunState.primaryOn=true; patchEquippedGuns()
end })

local CombatTools = TabCombat:DrawSection({ Name="Tools", Position="right" })
CombatTools:AddButton({ Name="Server Hop", Callback=function()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
        ))
    end)
    if ok and data and data.data then
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player); break
            end
        end
    end
end })
CombatTools:AddButton({ Name="Set Home", Callback=function() if hrp then homePosition=hrp.Position end end })
CombatTools:AddToggle({ Name="Auto Return Home", Flag="Toggle_ReturnHome", Default=false, Callback=function(v) returnHomeEnabled=v end })
CombatTools:AddSlider({ Name="Return Interval (s)", Min=1, Max=60, Default=3.0, Increment=0.5, Flag="Slider_ReturnDelay", Callback=function(v) homeReturnDelay=v end })
CombatTools:AddButton({ Name="Add Waypoint", Callback=function() if hrp then if #teleportLoopPositions>=5 then table.remove(teleportLoopPositions,1) end; table.insert(teleportLoopPositions, hrp.Position) end end })
CombatTools:AddButton({ Name="Clear Waypoints", Callback=function() teleportLoopPositions={}; teleportLoopIndex=1 end })
CombatTools:AddToggle({ Name="Waypoint Loop", Flag="Toggle_TPLoop", Default=false, Callback=function(v) teleportLoopEnabled=v end })
CombatTools:AddSlider({ Name="Loop Interval (s)", Min=0.1, Max=30, Default=1.5, Increment=0.1, Flag="Slider_TPLoopDelay", Callback=function(v) teleportLoopDelay=v end })

-- ── CSYNC VOID (Arch original) ────────────────────────────
Window:DrawCategory({ Name = "CSync Void" })
local TabCSyncVoid = Window:DrawTab({ Name="CSync Void", Icon="ghost", EnableScrolling=true })

local CSyncMain = TabCSyncVoid:DrawSection({ Name="Main", Position="left" })
CSyncMain:AddToggle({ Name="Enable CSync Void (Key H)", Flag="Toggle_VoidEnabled", Default=false,
    Callback=function(v) CSync.settings.enable_void=v; if v then startVoid() else stopVoid() end end })

local CSyncSettings = TabCSyncVoid:DrawSection({ Name="Settings", Position="left" })
CSyncSettings:AddSlider({ Name="Switch Speed", Min=0.0001, Max=1, Default=0.05, Increment=0.0001, Flag="Slider_VoidSwitchSpeed", Callback=function(v) CSync.settings.switchSpeed=v end })
CSyncSettings:AddSlider({ Name="Depth Multiplier", Min=1, Max=1000, Default=1, Increment=1, Flag="Slider_VoidDepthMult", Callback=function(v) CSync.settings.depthMultiplier=v end })
CSyncSettings:AddSlider({ Name="Rand Vel X", Min=0, Max=1000, Default=0, Increment=1, Flag="Slider_VoidRandVelX", Callback=function(v) CSync.settings.rand_vel_x=v end })
CSyncSettings:AddSlider({ Name="Rand Vel Y", Min=0, Max=1000, Default=0, Increment=1, Flag="Slider_VoidRandVelY", Callback=function(v) CSync.settings.rand_vel_y=v end })
CSyncSettings:AddSlider({ Name="Rand Vel Z", Min=0, Max=1000, Default=0, Increment=1, Flag="Slider_VoidRandVelZ", Callback=function(v) CSync.settings.rand_vel_z=v end })
CSyncSettings:AddSlider({ Name="Jerk Intensity", Min=0, Max=200, Default=20, Increment=1, Flag="Slider_VoidJerkIntensity", Callback=function(v) CSync.settings.jerk_intensity=v end })
CSyncSettings:AddSlider({ Name="Random Vel Intensity", Min=0, Max=200, Default=15, Increment=1, Flag="Slider_VoidRandIntensity", Callback=function(v) CSync.settings.random_vel_intensity=v end })

local CSyncPulse = TabCSyncVoid:DrawSection({ Name="Auto Pulse", Position="right" })
local autoPulseVoidEnabled, autoPulseVoidInterval, autoPulseVoidThread = false, 1, nil
local function startAutoPulseVoid()
    if autoPulseVoidThread then return end
    autoPulseVoidThread = task.spawn(function()
        while autoPulseVoidEnabled do
            if CSync.settings.enable_void then stopVoid(); CSync.settings.enable_void=false
            else startVoid(); CSync.settings.enable_void=true end
            task.wait(autoPulseVoidInterval)
        end
    end)
end
local function stopAutoPulseVoid()
    autoPulseVoidEnabled=false
    if autoPulseVoidThread then task.cancel(autoPulseVoidThread); autoPulseVoidThread=nil end
end
CSyncPulse:AddToggle({ Name="Auto Pulse", Flag="Toggle_AutoPulseVoid", Default=false, Callback=function(v) autoPulseVoidEnabled=v; if v then startAutoPulseVoid() else stopAutoPulseVoid() end end })
CSyncPulse:AddSlider({ Name="Interval (s)", Min=0.0001, Max=10, Default=1, Increment=0.0001, Flag="Slider_AutoPulseInterval", Callback=function(v) autoPulseVoidInterval=v end })
CSyncPulse:AddButton({ Name="Emergency Return", Callback=function()
    safeReturn(); CSync.settings.enable_void=false
end })

-- ── RCLC VOID ────────────────────────────────────────────
Window:DrawCategory({ Name = "RCLC Void" })
local TabRCLCVoid = Window:DrawTab({ Name="RCLC Void", Icon="activity", EnableScrolling=true })

local RVoidEngine = TabRCLCVoid:DrawSection({ Name="Engine", Position="left" })
RVoidEngine:AddToggle({ Name="Enable Void", Flag="Toggle_RCLCVoid", Default=false, Callback=function(v)
    voidCfg.VOID_ENABLED=v
    if v then enableVoidRCLC() else disableVoidRCLC() end
end })
RVoidEngine:AddDropdown({ Name="Method", Flag="Dropdown_VoidMethod", Default="Quantum",
    Values={"Quantum","Attacker","Chaos","Freeze Bait"},
    Callback=function(o) voidCfg.VOID_METHOD=o; voidPhaseTime=0; voidBaitPhase=false end })
RVoidEngine:AddToggle({ Name="Wireframe ESP", Flag="Toggle_RCLCWireframe", Default=false, Callback=function(v) setWireframes(v) end })
RVoidEngine:AddToggle({ Name="Duration Limit", Flag="Toggle_VoidDuration", Default=false, Callback=function(v) voidCfg.VOID_DURATION_ENABLED=v end })
RVoidEngine:AddSlider({ Name="Duration (s)", Min=1, Max=300, Default=10, Increment=1, Flag="Slider_VoidDuration", Callback=function(v) voidCfg.VOID_DURATION=v end })

local RVoidAttacker = TabRCLCVoid:DrawSection({ Name="Attacker Settings", Position="left" })
RVoidAttacker:AddSlider({ Name="Attacker Interval (s)", Min=1, Max=10, Default=4, Increment=0.5, Flag="Slider_VoidAttInterval", Callback=function(v) voidCfg.VOID_ATTACKER_INTERVAL=v end })
RVoidAttacker:AddSlider({ Name="Attacker Freeze (s)", Min=0.1, Max=2, Default=0.4, Increment=0.1, Flag="Slider_VoidAttDuration", Callback=function(v) voidCfg.VOID_ATTACKER_DURATION=v end })

local RVoidBait = TabRCLCVoid:DrawSection({ Name="Freeze Bait Settings", Position="left" })
RVoidBait:AddSlider({ Name="Bait Interval (s)", Min=1, Max=10, Default=3, Increment=0.5, Flag="Slider_VoidBaitInterval", Callback=function(v) voidCfg.VOID_BAIT_INTERVAL=v end })
RVoidBait:AddSlider({ Name="Bait Freeze (s)", Min=0.1, Max=2, Default=0.4, Increment=0.1, Flag="Slider_VoidBaitDuration", Callback=function(v) voidCfg.VOID_BAIT_DURATION=v end })

local RVoidSpace = TabRCLCVoid:DrawSection({ Name="Space", Position="right" })
RVoidSpace:AddSlider({ Name="Radius", Min=1, Max=10000000, Default=10000000, Increment=1, Flag="Slider_VoidRadius", Callback=function(v) voidCfg.RADIUS=v end })
RVoidSpace:AddSlider({ Name="Y Min", Min=-10000000, Max=0, Default=-10000000, Increment=1, Flag="Slider_VoidYMin", Callback=function(v) voidCfg.VOID_Y_MIN=v end })
RVoidSpace:AddSlider({ Name="Y Max", Min=0, Max=10000000, Default=10000000, Increment=1, Flag="Slider_VoidYMax", Callback=function(v) voidCfg.VOID_Y_MAX=v end })
RVoidSpace:AddSlider({ Name="Chaos Factor", Min=0.1, Max=1, Default=0.98, Increment=0.01, Flag="Slider_VoidChaos", Callback=function(v) voidCfg.CHAOS=v end })

-- ── RCLC ORBIT ───────────────────────────────────────────
Window:DrawCategory({ Name = "RCLC Orbit" })
local TabRCLCOrbit = Window:DrawTab({ Name="RCLC Orbit", Icon="refresh-cw", EnableScrolling=true })

local ROrbitMain = TabRCLCOrbit:DrawSection({ Name="Orbit Around Nearest Player", Position="left" })
ROrbitMain:AddToggle({ Name="Enable Orbit", Flag="Toggle_RCLCOrbit", Default=false, Callback=function(v)
    orbitCfg.orbitEnabled=v
    if v then enableOrbitRCLC() else disableOrbitRCLC() end
end })
ROrbitMain:AddDropdown({ Name="Direction", Flag="Dropdown_OrbitMode", Default="Clockwise", Values={"Clockwise","Counter-Clockwise"}, Callback=function(o) orbitCfg.orbitMode=o end })
ROrbitMain:AddSlider({ Name="Speed (deg/s)", Min=5, Max=1000, Default=90, Increment=1, Flag="Slider_RCLCOrbitSpeed", Callback=function(v) orbitCfg.orbitSpeed=v end })
ROrbitMain:AddSlider({ Name="Radius", Min=1, Max=50, Default=8, Increment=1, Flag="Slider_RCLCOrbitDist", Callback=function(v) orbitCfg.orbitDist=v end })
ROrbitMain:AddSlider({ Name="Height", Min=-100, Max=100, Default=0, Increment=1, Flag="Slider_RCLCOrbitHeight", Callback=function(v) orbitCfg.orbitHeight=v end })
ROrbitMain:AddSlider({ Name="Lock Distance", Min=1, Max=10000000, Default=10000000, Increment=1, Flag="Slider_RCLCOrbitLock", Callback=function(v) orbitCfg.orbitLockDist=v end })

-- ── DEFENSE ──────────────────────────────────────────────
Window:DrawCategory({ Name = "Defense" })
local TabDefense = Window:DrawTab({ Name="Defense", Icon="shield", EnableScrolling=true })

local DefAASection = TabDefense:DrawSection({ Name="Chaos Anti-Aim (RCLC)", Position="left" })
DefAASection:AddToggle({ Name="Enable Chaos Anti-Aim", Flag="Toggle_RCLCAntiAim", Default=false, Callback=function(v)
    rclcAntiAimCfg.enabled=v
    if v then enableRCLCAntiAim() else disableRCLCAntiAim() end
end })
DefAASection:AddSlider({ Name="Speed", Min=100, Max=10000, Default=5000, Increment=100, Flag="Slider_RCLCAASpeed", Callback=function(v) rclcAntiAimCfg.speed=v end })
DefAASection:AddSlider({ Name="Chaos Level %", Min=1, Max=100, Default=100, Increment=1, Flag="Slider_RCLCAAChaos", Callback=function(v) rclcAntiAimCfg.chaosLevel=v end })
DefAASection:AddSlider({ Name="Pitch Max (deg)", Min=1, Max=360, Default=360, Increment=1, Flag="Slider_RCLCAAPitch", Callback=function(v) rclcAntiAimCfg.pitch=v end })
DefAASection:AddSlider({ Name="Yaw Max (deg)", Min=1, Max=360, Default=360, Increment=1, Flag="Slider_RCLCAAYaw", Callback=function(v) rclcAntiAimCfg.yaw=v end })

local DefUGSection = TabDefense:DrawSection({ Name="Underground Anti-Aim", Position="left" })
DefUGSection:AddToggle({ Name="Enable Underground AA", Flag="Toggle_UgAA", Default=false, Callback=function(v)
    undergroundCfg.enabled=v
    if v then enableUndergroundAA() else disableUndergroundAA() end
end })
DefUGSection:AddSlider({ Name="Depth", Min=1, Max=5, Default=1.5, Increment=0.1, Flag="Slider_UgAADepth", Callback=function(v) undergroundCfg.depth=v end })
DefUGSection:AddSlider({ Name="Orbit Radius", Min=0, Max=10, Default=3, Increment=0.1, Flag="Slider_UgAAOrbRad", Callback=function(v) undergroundCfg.orbitRadius=v end })
DefUGSection:AddSlider({ Name="Orbit Speed", Min=50, Max=1000, Default=200, Increment=10, Flag="Slider_UgAAOrbSpeed", Callback=function(v) undergroundCfg.orbitSpeed=v end })
DefUGSection:AddSlider({ Name="Spin Speed", Min=100, Max=2000, Default=720, Increment=10, Flag="Slider_UgAASpinSpeed", Callback=function(v) undergroundCfg.spinSpeed=v end })

local DefPredSection = TabDefense:DrawSection({ Name="Prediction (Dodging)", Position="right" })
DefPredSection:AddToggle({ Name="Enable Prediction", Flag="Toggle_Pred", Default=false, Callback=function(v)
    predictCfg.predEnabled=v
    if v then enablePrediction() else disablePrediction() end
end })
DefPredSection:AddToggle({ Name="Kinematic Sidestep", Flag="Toggle_PredKinematic", Default=true, Callback=function(v) predictCfg.predKinematic=v end })
DefPredSection:AddToggle({ Name="Predict Shot Path", Flag="Toggle_PredPredictive", Default=true, Callback=function(v) predictCfg.predPredictive=v end })
DefPredSection:AddToggle({ Name="Infinite Range", Flag="Toggle_PredInfRange", Default=false, Callback=function(v) predictCfg.predInfiniteRange=v end })
DefPredSection:AddSlider({ Name="Danger Radius", Min=5, Max=5000, Default=150, Increment=1, Flag="Slider_PredRadius", Callback=function(v) predictCfg.predRadius=v end })
DefPredSection:AddSlider({ Name="Dodge Distance", Min=5, Max=500, Default=80, Increment=1, Flag="Slider_PredDodge", Callback=function(v) predictCfg.predDodgeDist=v end })
DefPredSection:AddSlider({ Name="Reaction Time ms", Min=1, Max=500, Default=120, Increment=1, Flag="Slider_PredReact", Callback=function(v) predictCfg.predReactionTime=v*0.001 end })
DefPredSection:AddSlider({ Name="Aim Threshold %", Min=50, Max=99, Default=70, Increment=1, Flag="Slider_PredAimThresh", Callback=function(v) predictCfg.predAimThreshold=v*0.01 end })
DefPredSection:AddSlider({ Name="Cooldown ms", Min=10, Max=2000, Default=50, Increment=1, Flag="Slider_PredCooldown", Callback=function(v) predictCfg.predCooldown=v/1000 end })
DefPredSection:AddSlider({ Name="Bullet Speed", Min=100, Max=10000, Default=1000, Increment=10, Flag="Slider_PredBulletSpeed", Callback=function(v) predictCfg.predBulletSpeed=v end })
DefPredSection:AddSlider({ Name="Lookahead (s)", Min=0.1, Max=2, Default=0.5, Increment=0.05, Flag="Slider_PredLookahead", Callback=function(v) predictCfg.predLookahead=v end })

local DefVDSection = TabDefense:DrawSection({ Name="Velocity Desync", Position="right" })
DefVDSection:AddToggle({ Name="Enable Vel Desync", Flag="Toggle_VelDesync", Default=false, Callback=function(v)
    velDesyncCfg.enabled=v
    if v then enableVelDesync() else disableVelDesync() end
end })
DefVDSection:AddSlider({ Name="Intensity %", Min=1, Max=100, Default=50, Increment=1, Flag="Slider_VDIntensity", Callback=function(v) velDesyncCfg.intensity=v end })
DefVDSection:AddSlider({ Name="Base Angle", Min=0, Max=360, Default=90, Increment=1, Flag="Slider_VDAngle", Callback=function(v) velDesyncCfg.angle=v end })
DefVDSection:AddSlider({ Name="Jitter", Min=0, Max=180, Default=20, Increment=1, Flag="Slider_VDJitter", Callback=function(v) velDesyncCfg.jitter=v end })
DefVDSection:AddSlider({ Name="Rotation Speed", Min=1, Max=100, Default=10, Increment=1, Flag="Slider_VDSpeed", Callback=function(v) velDesyncCfg.speed=v end })
DefVDSection:AddToggle({ Name="Flip Direction", Flag="Toggle_VDFlip", Default=false, Callback=function(v) velDesyncCfg.flip=v end })
DefVDSection:AddToggle({ Name="Oscillate", Flag="Toggle_VDOsc", Default=false, Callback=function(v) velDesyncCfg.oscillate=v end })
DefVDSection:AddSlider({ Name="Osc Freq", Min=1, Max=20, Default=5, Increment=1, Flag="Slider_VDOscFreq", Callback=function(v) velDesyncCfg.oscillateFreq=v end })
DefVDSection:AddSlider({ Name="Osc Amp", Min=1, Max=90, Default=30, Increment=1, Flag="Slider_VDOscAmp", Callback=function(v) velDesyncCfg.oscillateAmp=v end })
DefVDSection:AddToggle({ Name="Spike Mode", Flag="Toggle_VDSpike", Default=false, Callback=function(v) velDesyncCfg.spikeMode=v end })
DefVDSection:AddSlider({ Name="Spike Interval (s)", Min=0.01, Max=1, Default=0.05, Increment=0.01, Flag="Slider_VDSpikeInt", Callback=function(v) velDesyncCfg.spikeInterval=v end })
DefVDSection:AddSlider({ Name="Spike Magnitude", Min=1000, Max=10000000, Default=1000000, Increment=1000, Flag="Slider_VDSpikeMag", Callback=function(v) velDesyncCfg.spikeMag=v end })
DefVDSection:AddToggle({ Name="Multi Vector", Flag="Toggle_VDMulti", Default=false, Callback=function(v) velDesyncCfg.multiVector=v end })
DefVDSection:AddSlider({ Name="Vector Count", Min=2, Max=8, Default=3, Increment=1, Flag="Slider_VDVecCount", Callback=function(v) velDesyncCfg.vectorCount=v end })
DefVDSection:AddToggle({ Name="Noise Velocity", Flag="Toggle_VDNoise", Default=false, Callback=function(v) velDesyncCfg.noiseVel=v end })
DefVDSection:AddSlider({ Name="Noise Scale", Min=0.1, Max=10, Default=1, Increment=0.1, Flag="Slider_VDNoiseScale", Callback=function(v) velDesyncCfg.noiseScale=v end })
DefVDSection:AddToggle({ Name="Burst Desync", Flag="Toggle_VDBurst", Default=false, Callback=function(v) velDesyncCfg.burstDesync=v end })
DefVDSection:AddSlider({ Name="Burst Every (s)", Min=0.01, Max=1, Default=0.1, Increment=0.01, Flag="Slider_VDBurstEvery", Callback=function(v) velDesyncCfg.burstEvery=v end })
DefVDSection:AddSlider({ Name="Burst Magnitude", Min=1000, Max=10000000, Default=500000, Increment=1000, Flag="Slider_VDBurstMag", Callback=function(v) velDesyncCfg.burstMag=v end })
DefVDSection:AddToggle({ Name="Counter Velocity", Flag="Toggle_VDCounter", Default=false, Callback=function(v) velDesyncCfg.counterVel=v end })
DefVDSection:AddToggle({ Name="Rotate Velocity", Flag="Toggle_VDRotate", Default=false, Callback=function(v) velDesyncCfg.rotateVel=v end })
DefVDSection:AddSlider({ Name="Rotate Speed (deg/s)", Min=10, Max=720, Default=180, Increment=10, Flag="Slider_VDRotateSpeed", Callback=function(v) velDesyncCfg.rotateVelSpeed=v end })
DefVDSection:AddToggle({ Name="Invert On Timer", Flag="Toggle_VDInvert", Default=false, Callback=function(v) velDesyncCfg.invertOnTimer=v end })
DefVDSection:AddSlider({ Name="Invert Interval (s)", Min=0.05, Max=2, Default=0.2, Increment=0.05, Flag="Slider_VDInvertInt", Callback=function(v) velDesyncCfg.invertInterval=v end })
DefVDSection:AddToggle({ Name="Randomize Angle", Flag="Toggle_VDRandAngle", Default=false, Callback=function(v) velDesyncCfg.randomizeAngle=v end })
DefVDSection:AddSlider({ Name="Angle Min", Min=0, Max=360, Default=0, Increment=1, Flag="Slider_VDAngleMin", Callback=function(v) velDesyncCfg.angleMin=v end })
DefVDSection:AddSlider({ Name="Angle Max", Min=0, Max=360, Default=360, Increment=1, Flag="Slider_VDAngleMax", Callback=function(v) velDesyncCfg.angleMax=v end })

local DefFPSection = TabDefense:DrawSection({ Name="Fake Position", Position="left" })
DefFPSection:AddToggle({ Name="Enable Fake Position", Flag="Toggle_FakePos", Default=false, Callback=function(v)
    fakePosCfg.enabled=v
    if v then enableFakePos() else disableFakePos() end
end })
DefFPSection:AddDropdown({ Name="Pattern", Flag="Dropdown_FPPattern", Default="Scatter", Values={"Scatter","Linear","Circle","Random","Spiral"}, Callback=function(o) fakePosCfg.pattern=o end })
DefFPSection:AddDropdown({ Name="Distribution", Flag="Dropdown_FPDist", Default="Random", Values={"Random","Uniform","Weighted","Radial","Clustered"}, Callback=function(o) fakePosCfg.distribution=o end })
DefFPSection:AddDropdown({ Name="Axis Lock", Flag="Dropdown_FPAxis", Default="None", Values={"None","X","Y","Z","XZ"}, Callback=function(o) fakePosCfg.axisLock=o end })
DefFPSection:AddSlider({ Name="Radius", Min=1, Max=10000000, Default=1000000, Increment=1000, Flag="Slider_FPRadius", Callback=function(v) fakePosCfg.radius=v end })
DefFPSection:AddSlider({ Name="Height Offset", Min=-1000000000, Max=1000000000, Default=999999999, Increment=1000, Flag="Slider_FPHeight", Callback=function(v) fakePosCfg.height=v end })
DefFPSection:AddSlider({ Name="Y Distance", Min=0, Max=1000000000, Default=999999999, Increment=1000, Flag="Slider_FPYDist", Callback=function(v) fakePosCfg.yDist=v end })
DefFPSection:AddSlider({ Name="Speed", Min=1, Max=100000, Default=100000, Increment=100, Flag="Slider_FPSpeed", Callback=function(v) fakePosCfg.speed=v end })
DefFPSection:AddToggle({ Name="Randomize Every Frame", Flag="Toggle_FPRandFrame", Default=false, Callback=function(v) fakePosCfg.randomizeEveryFrame=v end })
DefFPSection:AddToggle({ Name="Layered Fake", Flag="Toggle_FPLayered", Default=false, Callback=function(v) fakePosCfg.layeredFake=v end })
DefFPSection:AddSlider({ Name="Layer Count", Min=1, Max=10, Default=3, Increment=1, Flag="Slider_FPLayers", Callback=function(v) fakePosCfg.layerCount=v end })
DefFPSection:AddToggle({ Name="Chaos Mode", Flag="Toggle_FPChaos", Default=false, Callback=function(v) fakePosCfg.chaosMode=v end })
DefFPSection:AddSlider({ Name="Chaos Mult", Min=1, Max=20, Default=5, Increment=1, Flag="Slider_FPChaosMult", Callback=function(v) fakePosCfg.chaosMult=v end })
DefFPSection:AddToggle({ Name="Pulse Radius", Flag="Toggle_FPPulse", Default=false, Callback=function(v) fakePosCfg.pulseRadius=v end })
DefFPSection:AddSlider({ Name="Pulse Min", Min=1, Max=1000000, Default=100, Increment=1, Flag="Slider_FPPulseMin", Callback=function(v) fakePosCfg.pulseRadiusMin=v end })
DefFPSection:AddSlider({ Name="Pulse Max", Min=1, Max=1000000, Default=999999, Increment=1, Flag="Slider_FPPulseMax", Callback=function(v) fakePosCfg.pulseRadiusMax=v end })
DefFPSection:AddSlider({ Name="Pulse Speed", Min=0.1, Max=20, Default=2, Increment=0.1, Flag="Slider_FPPulseSpeed", Callback=function(v) fakePosCfg.pulseSpeed=v end })

-- ── TRANSLOCATION ────────────────────────────────────────
Window:DrawCategory({ Name = "Translocation" })
local TabTransloc = Window:DrawTab({ Name="Translocation", Icon="move", EnableScrolling=true })

local TranslocEngine = TabTransloc:DrawSection({ Name="Engine", Position="left" })
TranslocEngine:AddToggle({ Name="Enable Translocation", Flag="Toggle_Transloc", Default=false, Callback=function(v)
    translocCfg.enabled=v
    if v then enableTransloc() else disableTransloc() end
end })
TranslocEngine:AddSlider({ Name="Frequency (Hz)", Min=1, Max=1000000, Default=1000000, Increment=1000, Flag="Slider_TranslocFreq", Callback=function(v) translocCfg.frequency=v end })
TranslocEngine:AddSlider({ Name="X Jitter Range", Min=1, Max=100000000, Default=10000000, Increment=1000, Flag="Slider_TranslocJitterX", Callback=function(v) translocCfg.jitterX=v end })
TranslocEngine:AddSlider({ Name="Y Jitter Range", Min=1, Max=100000000, Default=10000000, Increment=1000, Flag="Slider_TranslocJitterY", Callback=function(v) translocCfg.jitterY=v end })
TranslocEngine:AddSlider({ Name="Fixed Z Position", Min=0, Max=100, Default=1, Increment=0.1, Flag="Slider_TranslocFixedZ", Callback=function(v) translocCfg.fixedZ=v end })

local TranslocPulse = TabTransloc:DrawSection({ Name="Pulse Options", Position="right" })
TranslocPulse:AddToggle({ Name="Fake Velocity", Flag="Toggle_TranslocFakeVel", Default=true, Callback=function(v) translocCfg.fakeVel=v end })
TranslocPulse:AddSlider({ Name="Fake Vel Magnitude", Min=1, Max=1000000000000, Default=10000000000, Increment=1000, Flag="Slider_TranslocVelMag", Callback=function(v) translocCfg.fakeVelMag=v end })
TranslocPulse:AddToggle({ Name="Burst Mode", Flag="Toggle_TranslocBurst", Default=false, Callback=function(v) translocCfg.burstMode=v end })
TranslocPulse:AddSlider({ Name="Burst Count", Min=2, Max=50, Default=10, Increment=1, Flag="Slider_TranslocBurstCount", Callback=function(v) translocCfg.burstCount=v end })

-- ── EMOTE V3 ─────────────────────────────────────────────
Window:DrawCategory({ Name = "Emote V3" })
local TabEmote = Window:DrawTab({ Name="Emote V3", Icon="sparkles", EnableScrolling=true })

local EmoteTargetSection = TabEmote:DrawSection({ Name="Target Player", Position="left" })
local targetPlayerNames = {}
for _, p in ipairs(Players:GetPlayers()) do table.insert(targetPlayerNames, p.Name) end
local targetDropdown = EmoteTargetSection:AddDropdown({ Name="Select Target", Flag="Dropdown_TargetPlayer", Default=player.Name, Values=targetPlayerNames,
    Callback=function(o)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == o then
                targetPlayer=p
                if isEmoteEnabled and currentEmoteConfig then
                    stopCustomEmote(); task.wait(0.1)
                    playCustomEmote(currentEmoteConfig.speed, currentEmoteConfig.style)
                end
                break
            end
        end
    end
})
task.spawn(function()
    while true do
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
        pcall(function() targetDropdown:SetValues(names) end)
        task.wait(3)
    end
end)

local EmotePackSection = TabEmote:DrawSection({ Name="Emotes", Position="left" })
local packNames = {}
for n in pairs(emotePacks) do packNames[#packNames+1]=n end
local emoteDropdown
local packDropdown = EmotePackSection:AddDropdown({ Name="Pack", Flag="Dropdown_EmotePack", Default="Cosmic Chaos", Values=packNames,
    Callback=function(o)
        if emotePacks[o] then
            local names = {}
            for _, e in ipairs(emotePacks[o]) do table.insert(names, e.name) end
            pcall(function() emoteDropdown:SetValues(names) end)
        end
    end
})
local initialPack = "Cosmic Chaos"
local initialEmotes = {}
for _, e in ipairs(emotePacks[initialPack]) do table.insert(initialEmotes, e.name) end
emoteDropdown = EmotePackSection:AddDropdown({ Name="Play", Flag="Dropdown_Emote", Default=initialEmotes[1] or "", Values=initialEmotes,
    Callback=function(o)
        if isEmoteEnabled then
            local pn = pcall(function() return packDropdown:GetValue() end) and packDropdown:GetValue() or "Cosmic Chaos"
            if emotePacks[pn] then
                for _, e in ipairs(emotePacks[pn]) do
                    if e.name==o then stopCustomEmote(); task.wait(0.1); playCustomEmote(e.speed, e.style); break end
                end
            end
        end
    end
})

local EmoteControlSection = TabEmote:DrawSection({ Name="Control", Position="right" })
EmoteControlSection:AddToggle({ Name="Enable", Flag="Toggle_EmoteEnabled", Default=false, Callback=function(v)
    isEmoteEnabled=v
    if v then
        local ok, pn = pcall(function() return packDropdown:GetValue() end)
        local ok2, en = pcall(function() return emoteDropdown:GetValue() end)
        pn = ok and pn or "Cosmic Chaos"; en = ok2 and en or ""
        if emotePacks[pn] then
            for _, e in ipairs(emotePacks[pn]) do
                if e.name==en then stopCustomEmote(); task.wait(0.1); playCustomEmote(e.speed, e.style); break end
            end
        end
    else stopCustomEmote() end
end })
EmoteControlSection:AddSlider({ Name="Speed Multiplier", Min=1, Max=1000, Default=1, Increment=1, Flag="Slider_EmoteSpeed", Callback=function(v) defaultSpeedFactor=v end })
EmoteControlSection:AddButton({ Name="Stop", Callback=function() stopCustomEmote(); isEmoteEnabled=false end })

local EmoteEffectsSection = TabEmote:DrawSection({ Name="Effects", Position="right" })
EmoteEffectsSection:AddToggle({ Name="Noodle", Flag="Toggle_Noodle", Default=false, Callback=function(v) isNoodleMode=v end })
EmoteEffectsSection:AddToggle({ Name="Neon Glitch", Flag="Toggle_Neon", Default=false, Callback=function(v)
    isNeonGlitchMode=v
    if characterParts then
        for _, info in ipairs(characterParts.Pieces) do
            if info.fakePart then
                info.fakePart.Material = v and Enum.Material.Neon
                    or (customMatList[currentMatIndex].mat or info.originalMaterial)
                if info.emitter then info.emitter.Enabled = v or isGhostMode end
                if not v and not isRainbowMode then info.fakePart.Color=info.originalColor end
            end
        end
    end
end })
EmoteEffectsSection:AddToggle({ Name="Paper", Flag="Toggle_Paper", Default=false, Callback=function(v) isPaperMode=v end })
EmoteEffectsSection:AddToggle({ Name="Jitter", Flag="Toggle_Jitter", Default=false, Callback=function(v) isJitterMode=v end })
EmoteEffectsSection:AddToggle({ Name="Meatball", Flag="Toggle_Meatball", Default=false, Callback=function(v) isMeatballMode=v end })
EmoteEffectsSection:AddToggle({ Name="Ghost", Flag="Toggle_GhostMode", Default=false, Callback=function(v)
    isGhostMode=v
    if characterParts then
        for _, info in ipairs(characterParts.Pieces) do
            if info.emitter then info.emitter.Enabled = v or isNeonGlitchMode end
        end
    end
end })
EmoteEffectsSection:AddToggle({ Name="Trails", Flag="Toggle_Trails", Default=false, Callback=function(v)
    isTrailsMode=v
    if characterParts then
        for _, info in ipairs(characterParts.Pieces) do
            if info.trail then info.trail.Enabled=v end
        end
    end
end })
EmoteEffectsSection:AddToggle({ Name="Rainbow", Flag="Toggle_Rainbow", Default=false, Callback=function(v)
    isRainbowMode=v
    if not v and characterParts then
        for _, info in ipairs(characterParts.Pieces) do
            if info.fakePart then info.fakePart.Color=info.originalColor end
        end
    end
end })
EmoteEffectsSection:AddToggle({ Name="Morph", Flag="Toggle_Morph", Default=false, Callback=function(v) isMorphMode=v end })
EmoteEffectsSection:AddButton({ Name="Cycle Material", Callback=function()
    currentMatIndex=(currentMatIndex % #customMatList)+1
    if characterParts then
        for _, info in ipairs(characterParts.Pieces) do
            if info.fakePart and not isNeonGlitchMode then
                info.fakePart.Material = customMatList[currentMatIndex].mat or info.originalMaterial
            end
        end
    end
end })
EmoteEffectsSection:AddButton({ Name="Reset All Effects", Callback=function()
    isNoodleMode=false; isNeonGlitchMode=false; isPaperMode=false; isJitterMode=false
    isMeatballMode=false; isGhostMode=false; isTrailsMode=false; isRainbowMode=false
    isMorphMode=false; currentMatIndex=1; defaultSpeedFactor=1; targetPlayer=player
    stopCustomEmote(); isEmoteEnabled=false
end })

-- ── CONFIG ───────────────────────────────────────────────
Window:DrawCategory({ Name = "Config" })
local ConfigUI = Window:DrawConfig({ Name="Config", Icon="folder", Config=ConfigManager })
ConfigUI:Init()

-- Kill Everything preset (global reset)
local TabSettings = Window:DrawTab({ Name="Presets", Icon="settings", EnableScrolling=true })
local PresetSection = TabSettings:DrawSection({ Name="Quick Presets", Position="left" })
PresetSection:AddButton({ Name="Kill Everything (All Off)", Callback=function()
    -- Arch
    running=false; riotRunning=false; evasionEnabled=false; blinkEnabled=false; ghostEnabled=false
    cframeFlightEnabled=false; fakeLagEnabled=false; antiAimEnabled=false
    noclipBypassEnabled=false; orbitEnemyEnabled=false; closestEnabled=false
    autoHealEnabled=false; projectileDodgeEnabled=false; dynamicSafeAnchorEnabled=false
    safeZoneEnabled=false; autocollectEnabled=false; returnHomeEnabled=false
    teleportLoopEnabled=false; targetSpectateEnabled=false; hitboxExpanderEnabled=false
    autoFacingEnabled=false; clientInvisibilityEnabled=false
    if humanoid then humanoid.PlatformStand=false end
    if hrp then hrp.Anchored=false end
    -- CSync Void
    CSync.settings.enable_void=false; stopVoid()
    -- RCLC
    voidCfg.VOID_ENABLED=false;        disableVoidRCLC()
    orbitCfg.orbitEnabled=false;       disableOrbitRCLC()
    predictCfg.predEnabled=false;      disablePrediction()
    rclcAntiAimCfg.enabled=false;      disableRCLCAntiAim()
    undergroundCfg.enabled=false;      disableUndergroundAA()
    translocCfg.enabled=false;         disableTransloc()
    fakePosCfg.enabled=false;          disableFakePos()
    velDesyncCfg.enabled=false;        disableVelDesync()
    fastMeleeCfg.enabled=false;        disableFastMelee()
    killAuraCfg.enabled=false;         disableKillAura()
    fastGunState.primaryOn=false
    disableWireframes()
    notify("Preset", "All systems off", "Warning", 3)
end })

local CharSection = TabSettings:DrawSection({ Name="Character", Position="left" })
CharSection:AddButton({ Name="Reload Character", Callback=function()
    if player.Character then player.Character:BreakJoints() end
end })
CharSection:AddButton({ Name="Rejoin Server", Callback=function()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, player)
    end)
end })

-- ============================================================
-- CONFIG LOAD
-- ============================================================
pcall(function() ConfigManager:LoadConfig() end)

-- ============================================================
-- LOADED NOTIFICATION
-- ============================================================
Notifier.new({
    Title   = "Arch Lua V3 + RCLC",
    Content = "All systems loaded. Toggle UI: LeftAlt",
    Duration = 5,
})

end) -- pcall end

if not success then
    warn("Arch Lua + RCLC init failed: ", err)
end
