--==========================================================================
--  KICIA REBUILD — RAGEBOT & FLICKBOT
--  完整提取 / Full extraction, zero omissions
--  Source: message-222.txt (KiciaRebuild / Rivals)
--==========================================================================

-- =========================================================
-- SECTION 1 — DEFAULT CONFIG (module: be / bd)
-- Defines all default values for Ragebot and Flickbot
-- =========================================================

--[[
Ragebot = {
    Enabled = false,
    Keybind = {
        State   = false,
        Kind    = "Always",   -- "Always" | "Toggle" | "Hold"
        Bind    = nil,
        ShowInList = true,
        Invisible  = false,
    },
    Stability      = 0.15,   -- seconds; how long the bot stays inside the spatial limit before firing
    ShootFrames    = 1,      -- multiplier on the shoot-lock window (1–5)
    PrioritizeHackers = false,

    Weapons = {
        Priority = { "Primary", "Secondary", "Melee" },  -- ordered list
        Enabled  = { Primary = true, Secondary = true, Melee = true },
        OnEmpty  = "SwapOrReload",   -- "Reload" | "Swap" | "SwapOrReload"
    },

    Evasion = {
        Mode = "Random",   -- "Off" | "Random" | "Translocate" | "ProjectileBreaker"

        Random = {
            AnchorFromCharacter = false,
            BaseRadius          = 100,
            RadiusRandomFactor  = 0.5,
        },

        ProjectileBreaker = {
            DepthForward          = { Min = 0, Max = 4 },
            DepthForwardFrequency = 5,
            DepthUp               = { Min = 0, Max = 5.5 },
            DepthUpFrequency      = 5,
            RepositionInterval    = 0.3,
            FallbackAnchorFromCharacter = false,
            FallbackBaseRadius          = 100,
            FallbackRadiusRandomFactor  = 0.5,
        },

        Translocate = {
            Offset = -5,   -- Y offset from OOB part surface (range −5 to +5)
        },
    },

    UtilizeHealthLead = false,
},

Flickbot = {
    Enabled  = false,
    Keybind  = {
        State   = false,
        Kind    = "Hold",   -- "Hold" | "Toggle"
        Bind    = nil,
        ShowInList = true,
        Invisible  = false,
    },
    Shoot        = false,   -- fire a shot at end of flick
    ShotDelay    = 0,       -- ms after flick end before firing (0–250)
    Cooldown     = 250,     -- ms between flick cycles (0–2000)
    FlickDuration = 110,    -- ms for the flick curve (30–400)
    Curvature    = 12,      -- arc curvature (0–50)
    Humanness    = 30,      -- path irregularity (0–100)
},
]]

-- =========================================================
-- SECTION 2 — UI PANELS (modules: ie, ih, ii)
-- =========================================================

-- module: ie  — Arcade-server Ragebot panel (simplified, no evasion/stability controls)
do -- ie (ArcadeServer variant)
local function fn35()
    local I = tbl17.gR()
    tbl17.aE()
    local W = tbl17.h6()

    local function l(N)
        W(N, "Enable Ragebot", {"Always","Toggle","Hold"}, {"Ragebot"}, true)
        if not I.IsArcadeServer then
            N:AddToggle({Label="Utilize Health Lead", Config={"Ragebot","UtilizeHealthLead"}})
        end
    end

    return function(I)
        l(I:AddSection({Title="Activation", Side="left"}))
        local l, W = I:AddSection({Title="Weapon Strategy", Side="left"}), {"Primary","Secondary","Melee"}
        for I, I_149 in W, nil, nil do
            l:AddToggle({Label=string.format("%s Enabled", tostring(I_149)), Config={"Ragebot","Weapons","Enabled",I_149}})
        end
    end
end
tbl17.ie = function()
    local ie = tbl17.cache.ie
    if not ie then ie = { c = fn35() }; tbl17.cache.ie = ie end
    return ie.c
end
end

-- module: ih  — Full Ragebot panel (non-arcade: stability, shoot frames, evasion)
do -- ih
local function fn35()
    tbl17.aE()
    local I = tbl17.h6()

    -- Activation section
    local function l(W)
        I(W, "Enable Ragebot", {"Always","Toggle","Hold"}, {"Ragebot"}, true)
        W:AddToggle({Label="Prioritize Hackers",  Config={"Ragebot","PrioritizeHackers"}})
        W:AddSlider({Label="Stability",           Min=0, Max=1.5, Step=0.001, Config={"Ragebot","Stability"}})
        W:AddSlider({Label="Shoot Frames",        Min=1, Max=5,              Config={"Ragebot","ShootFrames"}})
    end

    -- Weapon strategy section
    local function I_150(W)
        local N = {"Primary","Secondary","Melee"}
        for P, P_151 in N, nil, nil do
            W:AddToggle({Label=string.format("%s Enabled", tostring(P_151)), Config={"Ragebot","Weapons","Enabled",P_151}})
        end
        W:AddOrderedList({Label="Weapon Priority", Items=N, Default=N, Config={"Ragebot","Weapons","Priority"}})
        W:AddDropdown({
            Label   = "On Empty",
            Options = {"Reload","Swap","SwapOrReload"},
            Labels  = {SwapOrReload="Swap or Reload"},
            Config  = {"Ragebot","Weapons","OnEmpty"},
        })
    end

    -- ProjectileBreaker sub-group builder
    local function W(N, P)
        local a = N:AddGroup({Source=P, Option="ProjectileBreaker"})
        a:AddRangeSlider({Label="Forward Depth",      Min=0,    Max=10,  Step=0.1,  Config={"Ragebot","Evasion","ProjectileBreaker","DepthForward"}})
        a:AddSlider({     Label="Forward Frequency",  Min=0,    Max=20,  Step=0.1,  Config={"Ragebot","Evasion","ProjectileBreaker","DepthForwardFrequency"}})
        a:AddRangeSlider({Label="Upward Depth",       Min=0,    Max=10,  Step=0.1,  Config={"Ragebot","Evasion","ProjectileBreaker","DepthUp"}})
        a:AddSlider({     Label="Upward Frequency",   Min=0,    Max=20,  Step=0.1,  Config={"Ragebot","Evasion","ProjectileBreaker","DepthUpFrequency"}})
        a:AddSlider({     Label="Reposition Interval (s)", Min=0.05, Max=2, Step=0.01, Config={"Ragebot","Evasion","ProjectileBreaker","RepositionInterval"}})
        a:AddToggle({     Label="Fallback Character Origin", Config={"Ragebot","Evasion","ProjectileBreaker","FallbackAnchorFromCharacter"}})
        a:AddSlider({     Label="Fallback Radius",    Min=5, Max=100000000, Config={"Ragebot","Evasion","ProjectileBreaker","FallbackBaseRadius"}})
        a:AddSlider({     Label="Fallback Random Factor", Min=0, Max=1, Step=0.1, Config={"Ragebot","Evasion","ProjectileBreaker","FallbackRadiusRandomFactor"}})
    end

    -- Evasion section
    local function N(P)
        local a = P:AddDropdown({
            Label   = "Evasion Mode",
            Options = {"Off","Random","Translocate","ProjectileBreaker"},
            Labels  = {ProjectileBreaker="Projectile Breaker"},
            Config  = {"Ragebot","Evasion","Mode"},
        })
        local e = P:AddGroup({Source=a, Option="Random"})
        e:AddToggle({Label="Character Origin",  Config={"Ragebot","Evasion","Random","AnchorFromCharacter"}})
        e:AddSlider({Label="Base Radius",       Min=5, Max=100000000, Config={"Ragebot","Evasion","Random","BaseRadius"}})
        e:AddSlider({Label="Random Factor",     Min=0, Max=1, Step=0.1, Config={"Ragebot","Evasion","Random","RadiusRandomFactor"}})
        P:AddGroup({Source=a, Option="Translocate"}):AddSlider({
            Label  = "Offset",
            Min    = -5, Max=5, Step=0.1,
            Config = {"Ragebot","Evasion","Translocate","Offset"},
        })
        W(P, a)
    end

    return function(W)
        l(     W:AddSection({Title="Activation",      Side="left"}))
        I_150( W:AddSection({Title="Weapon Strategy", Side="left"}))
        N(     W:AddSection({Title="Evasion",         Side="right"}))
    end
end
tbl17.ih = function()
    local ih = tbl17.cache.ih
    if not ih then ih = { c = fn35() }; tbl17.cache.ih = ih end
    return ih.c
end
end

-- module: ii  — Flickbot UI panel (lives inside Fire Assist tab)
do -- ii
local function fn35()
    tbl17.aE()
    local I = tbl17.h6()

    return function(l, W)
        local N = l:AddSection({Title="Flickbot", Side="right"})
        I(N, "Enable Flickbot", {"Hold","Toggle"}, {"Flickbot"}, true)

        -- Shoot toggle + shot delay (child group only visible when Shoot = true)
        N:AddGroup({Source=N:AddToggle({Label="Shoot", Config={"Flickbot","Shoot"}})}):AddSlider({
            Label  = "Shot Delay (ms)",
            Min    = 0, Max=250,
            Config = {"Flickbot","ShotDelay"},
        })

        N:AddSlider({Label="Cooldown (ms)",      Min=0,  Max=2000, Config={"Flickbot","Cooldown"}})
        N:AddSlider({Label="Flick Duration (ms)",Min=30, Max=400,  Config={"Flickbot","FlickDuration"}})
        N:AddSlider({Label="Curvature",          Min=0,  Max=50,   Config={"Flickbot","Curvature"}})
        N:AddSlider({Label="Humanness",          Min=0,  Max=100,  Config={"Flickbot","Humanness"}})
        N:AddButton({Label="Open Aimbot Targeting", OnClick=W})
    end
end
tbl17.ii = function()
    local ii = tbl17.cache.ii
    if not ii then ii = { c = fn35() }; tbl17.cache.ii = ii end
    return ii.c
end
end

-- =========================================================
-- SECTION 3 — jy  Shield/camera-angle check used by hitscan + melee planners
-- =========================================================
do -- jy
local function fn35()
    tbl17.cF()
    tbl17.jx()

    local function fn36(arg)
        local itemObserver  = arg.ItemObserver
        local equippedItem  = itemObserver:GetEquippedItem()

        if equippedItem ~= nil and equippedItem.Name == "Riot Shield" then
            local v115 = math.deg(arg:GetCameraRotation().X)
            if v115 > 22 and v115 < 91 then return "Below" end
            return "Above"
        end

        for _, v115 in itemObserver:GetItems() do
            if v115.Name == "Riot Shield" then
                local v116 = math.deg(arg:GetCameraRotation().X)
                if (v116 > 315 and v116 < 360) or (v116 > 0 and v116 < 91) then
                    return "Above"
                end
                return "Below"
            end
        end

        return v86[75]   -- "None" sentinel
    end

    if not flag2 then return end
    return fn36
end
tbl17.jy = function()
    local jy = tbl17.cache.jy
    if not jy then local jy2 = { c = fn35() }; tbl17.cache.jy = jy2; jy = jy2 end
    return jy.c
end
end

-- =========================================================
-- SECTION 4 — jz  Defensive CFrame / ViewAngles helpers
-- =========================================================
do -- jz
local function fn35()
    tbl17.cE()
    tbl17.jx()
    tbl17.cI()
    local v115 = tbl17.jy()
    local v116 = Random.new()

    return {
        -- Orient server CFrame to face (or away from) target, or random for Knife
        getDefensiveCFrame = function(arg, arg2, arg3, arg4)
            if arg2 == "Equipped" then
                return CFrame.new(arg.Position, arg4.Position)
            end
            if arg2 == "Unequipped" then
                return CFrame.new(arg.Position, arg.Position + arg.Position - arg4.Position)
            end
            local v117 = arg3.ItemObserver:EquippedItemAsMelee()
            if v117 ~= nil and v117.Name == "Knife" then
                local cframe      = CFrame.fromOrientation
                local nextNumber  = v116.NextNumber
                local tau         = math.tau
                return CFrame.new(arg.Position)
                    * cframe(v116:NextNumber(0, tau), v116:NextNumber(0, tau), nextNumber(v116, 0, tau))
            end
            return arg
        end,

        -- Randomise pitch/yaw to defend against melee reads
        getDefensiveViewAngles = function(arg, arg2)
            if arg == "None" then return nil end
            return {
                Kind  = "Normalized",
                Pitch = ((arg == "Equipped") ~= (v115(arg2) ~= "Below")) and v86[45] or -90,
                Yaw   = v116:NextNumber(0, 360),
            }
        end,
    }
end
tbl17.jz = function()
    local jz = tbl17.cache.jz
    if not jz then jz = { c = fn35() }; tbl17.cache.jz = jz end
    return jz.c
end
end

-- =========================================================
-- SECTION 5 — jA  ShootLock
-- Gate that enforces ShootFrames: fires on the first tick that
-- satisfies the frame-window, then locks out for ShootFrames * dt.
-- =========================================================
do -- jA
local function fn35()
    local index2 = {}
    index2.__index = index2

    index2.new = function()
        return setmetatable({}, index2)
    end

    -- arg2 = canFire (bool), arg3 = lockDuration (ShootFrames * dt)
    index2.ShouldFire = function(arg, arg2, arg3)
        local now2       = os.clock()
        local lockedUntil = arg._lockedUntil
        local flag19     = lockedUntil ~= nil and now2 < lockedUntil

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
    if not ja then local ja2 = { c = fn35() }; tbl17.cache.jA = ja2; ja = ja2 end
    return ja.c
end
end

-- =========================================================
-- SECTION 6 — jB  Target selector (PrioritizeHackers logic)
-- =========================================================
do -- jB
local function fn35()
    tbl17.cr()
    local v115 = tbl17.bG()
    tbl17.cF()
    tbl17.bM()

    -- Reject: not enemy, invincible, dead, or actively deflecting with melee
    local function fn36(arg)
        if not arg.IsEnemy or arg:IsInvincible() then return false end
        if not arg.Character.State.Alive then return false end
        local v116 = arg.ItemObserver:EquippedItemAsMelee()
        if v116 ~= nil and v116:IsDeflecting() then return false end
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

        -- First pass: hacker-tagged players
        if prioritizeHackers then
            for _, v116 in arg._playerTags:GetPlayersWith("Hacker") do
                local v117 = arg._fighters.StateByPlayer[v116]
                if v117 ~= nil and fn36(v117) then return fn37(v117) end
            end
        end

        -- Second pass: all enemies (skip hackers already tried)
        for k, v116 in arg._fighters.EnemyByPlayer, nil, nil do
            if prioritizeHackers and arg._playerTags:Has(k, "Hacker") then continue end
            if fn36(v116) then return fn37(v116) end
        end

        return nil
    end

    index2.HasTargets = function(arg)
        for _, v116 in arg._fighters.EnemyByPlayer, nil, nil do
            if fn36(v116) then return true end
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
    if not jb then jb = { c = fn35() }; tbl17.cache.jB = jb end
    return jb.c
end
end

-- =========================================================
-- SECTION 7 — jC  Ground-plane CFrame helper
-- =========================================================
do -- jC
local function fn35()
    local vector  = Vector3.new(0, -v86[63], 0)
    local vector2 = Vector3.new(0, 0, -v86[63])

    return function(arg, arg2)
        local n       = arg2 - arg
        local vector3 = Vector3.new(n.X, v86[186], n.Z)
        if vector3.Magnitude < 0.001 then vector3 = vector2 end
        return CFrame.lookAt(arg, arg + vector3, vector)
    end
end
tbl17.jC = function()
    local jc = tbl17.cache.jC
    if not jc then jc = { c = fn35() }; tbl17.cache.jC = jc end
    return jc.c
end
end

-- =========================================================
-- SECTION 8 — jD  Hitscan planner (guns)
-- Computes server-side CFrame + ShootEncoded call.
-- ShootFrames and Stability both feed through _shootLock here.
-- =========================================================
do -- jD
local function fn35()
    local v115 = tbl17.bG()
    tbl17.cR()
    tbl17.gA()
    local v116 = tbl17.jA()   -- ShootLock
    tbl17.jB()
    local v117 = tbl17.jy()   -- shield/angle check
    local v118 = tbl17.jC()   -- ground CFrame helper

    local vector  = Vector3.new(0, -0.7,  0.05)
    local vector2 = Vector3.new(0, -3.85, 0.05)

    -- Encoded orientation tables for ShootEncoded (standing / crouching)
    local tbl18 = { ["\0"]=-9e37, ["\1"]=0,         ["\2"]=v86[186], ["\3"]=-1.5707963267948966, ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl19 = { ["\0"]=v86[186], ["\1"]=-90000000, ["\2"]=0, ["\3"]=-1.5707963267948966, ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl20 = { ["\0"]=-9e37, ["\1"]=v86[186], ["\2"]=0,    ["\3"]=1.5707963267948966,  ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl21 = { ["\0"]=0,     ["\1"]=90000000,  ["\2"]=0,   ["\3"]=1.5707963267948966,  ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl22 = { ["\0"]=0, ["\1"]=1, ["\2"]=v86[186], ["\3"]=v86[186], ["\4"]=0, ["\5"]=0 }

    local index2 = {}
    index2.__index = index2

    index2.new = function(arg)
        return setmetatable({ _partGlue = arg, _shootLock = v116.new() }, index2)
    end

    -- arg2 = dt*ShootFrames, arg3 = target, arg4 = item, arg5 = gluedPart, arg6 = inSpatialLimit
    index2.Plan = function(arg, arg2, arg3, arg4, arg5, arg6)
        local hitboxHead = arg3.AliveState.HitboxHead
        local flag19     = v117(arg3.FighterState) ~= "Below"
        local ragebot    = v115.Data.Ragebot
        local v119       = flag19 and vector or vector2
        local v120       = arg._partGlue:Acquire(arg5, hitboxHead)
        local n

        if flag19 then
            n = v120 + v119
        else
            n = v118(v120.Position + v119, hitboxHead.Position)
        end

        -- ShootFrames gate: if not allowed to fire, send garbage CFrame to waste the tick
        if not arg._shootLock:ShouldFire(arg6, arg2 * ragebot.ShootFrames) then
            local random2 = math.random
            return CFrame.new(math.random(-1000000,1000000), math.random(5000,10000), random2(-1000000,1000000)), nil
        end

        local v121 = (flag19 and {tbl18} or {tbl20})[1]
        local v122 = (flag19 and {tbl19} or {tbl21})[v86[63]]

        return n, function()
            arg4:ShootEncoded(v121, v122, hitboxHead, tbl22)
        end
    end

    return index2
end
tbl17.jD = function()
    local jd = tbl17.cache.jD
    if not jd then local jd2 = { c = fn35() }; tbl17.cache.jD = jd2; jd = jd2 end
    return jd.c
end
end

-- =========================================================
-- SECTION 9 — jE  Melee planner (includes Knife backstab window)
-- =========================================================
do -- jE
local function fn35()
    tbl17.cJ()
    local v115 = tbl17.bG()
    tbl17.cS()
    tbl17.gA()
    local v116 = tbl17.jA()   -- ShootLock
    tbl17.jB()
    local v117 = tbl17.jy()   -- shield/angle
    local v118 = tbl17.jC()   -- ground CFrame

    local vector  = Vector3.new(0, -v86[195], 0.05)
    local vector2 = Vector3.new(v86[186], -3.85, 0.05)

    local tbl18 = { ["\0"]=-9e37,     ["\1"]=0,         ["\2"]=0,          ["\3"]=-1.5707963267948966, ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl19 = { ["\0"]=0,         ["\1"]=-90000000, ["\2"]=v86[186],   ["\3"]=-1.5707963267948966, ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl20 = { ["\0"]=-9e37,     ["\1"]=0,         ["\2"]=v86[186],   ["\3"]=1.5707963267948966,  ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl21 = { ["\0"]=0,         ["\1"]=90000000,  ["\2"]=v86[186],   ["\3"]=1.5707963267948966,  ["\4"]=3.1415926535897931, ["\5"]=3.1415926535897931 }
    local tbl22 = { ["\0"]=0, ["\1"]=1, ["\2"]=v86[186], ["\3"]=0, ["\4"]=0, ["\5"]=0 }

    -- Dummy CFrame sent when not allowed to fire (outside ShootFrames window)
    local function fn36()
        local random2 = math.random
        return CFrame.new(math.random(-10000000,-100000), math.random(5000,10000), random2(-10000000,-100000))
    end

    local function fn37(arg, arg2)
        return { Kind="Normalized", Pitch=math.deg(arg), Yaw=math.deg(arg2) }
    end

    local function fn38(arg, arg2, arg3, arg4)
        return { ["\0"]=arg["\0"], ["\1"]=arg["\1"], ["\2"]=arg["\2"], ["\3"]=arg2, ["\4"]=arg3, ["\5"]=arg4 }
    end

    local index2 = {}
    index2.__index = index2

    index2.new = function(arg)
        return setmetatable({
            _partGlue           = arg,
            _shootLock          = v116.new(),
            _hitboxWindowUntil  = -1,
            _attackCooldown     = -1,
        }, index2)
    end

    -- arg2=dt*ShootFrames, arg3=target, arg4=item, gluedOurPart, arg5=inSpatialLimit
    index2.Plan = function(arg, arg2, arg3, arg4, gluedOurPart, arg5)
        local aliveState = arg3.AliveState
        local hitboxHead = aliveState.HitboxHead
        local flag19     = v117(arg3.FighterState) ~= "Below"
        local ragebot    = v115.Data.Ragebot
        local v119       = flag19 and vector or vector2
        local v120       = arg._partGlue:Acquire(gluedOurPart, hitboxHead)
        arg._gluedOurPart = gluedOurPart
        local n

        if flag19 then
            n = v120 + v119
        else
            n = v118(v120.Position + v119, hitboxHead.Position)
        end

        local v121, v122, v123 = aliveState.RootPart.CFrame:ToOrientation()
        local n33  = flag19 and -1.5707963267948966 or 1.5707963267948966
        local v124 = (flag19 and {tbl18} or {tbl20})[1]
        local v125 = (flag19 and {tbl19} or {tbl21})[1]
        local v126 = fn38(v124, n33, v122, v123)
        local v127 = fn38(v125, n33, v122, v123)
        local now2 = os.clock()

        -- Inside backstab hitbox window: always HeavyAttack
        if now2 < arg._hitboxWindowUntil then
            return n, fn37(v121, v122), function()
                arg4:HeavyAttackEncoded(v126, v127, hitboxHead, tbl22)
            end
        end

        -- ShootFrames gate
        if not arg._shootLock:ShouldFire(arg5, arg2 * ragebot.ShootFrames) then
            return fn36(), nil, nil
        end

        -- Attack cooldown (post-backstab lockout)
        if now2 < arg._attackCooldown then
            return fn36(), nil, nil
        end

        -- Knife: record backstab, use HeavyAttack
        if arg4.Name == "Knife" then
            arg:_RecordBackstab()
            return n, fn37(v121, v122), function()
                arg4:HeavyAttackEncoded(v126, v127, hitboxHead, tbl22)
            end
        end

        -- Generic melee: normal attack
        return n, nil, function()
            arg4:AttackEncoded(v126, v127, hitboxHead, tbl22)
        end
    end

    -- Sets hitbox window (625ms) and attack cooldown (1.25s) after backstab
    index2._RecordBackstab = function(arg)
        local now2 = os.clock()
        arg._hitboxWindowUntil = now2 + 0.625
        arg._attackCooldown    = now2 + 1.25
    end

    index2.ResetState = function(arg)
        arg._hitboxWindowUntil = -1
        arg._attackCooldown    = -1
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
    if not je then local je2 = { c = fn35() }; tbl17.cache.jE = je2; je = je2 end
    return je.c
end
end

-- =========================================================
-- SECTION 10 — jF  Random-position CFrame generator
-- Used by both Random evasion mode and ProjectileBreaker fallback
-- =========================================================
do -- jF
local function fn35()
    local v115 = Random.new()

    return function(arg, arg2, arg3)
        local v116   = v115:NextNumber(0, 6.2831853071795862)
        local v117   = v115:NextNumber(arg2, arg3)
        local cframe = CFrame.new(arg + Vector3.new(math.cos(v116)*v117, 0, math.sin(v116)*v117))
        local nextNumber = v115.NextNumber
        return cframe * CFrame.fromOrientation(
            v115:NextNumber(0, 6.2831853071795862),
            v115:NextNumber(0, 6.2831853071795862),
            nextNumber(v115, 0, 6.2831853071795862)
        )
    end
end
tbl17.jF = function()
    local jf = tbl17.cache.jF
    if not jf then jf = { c = fn35() }; tbl17.cache.jF = jf end
    return jf.c
end
end

-- =========================================================
-- SECTION 11 — jG  Closest-surface-point + normal helper
-- Used by ProjectileBreaker to find valid hide surfaces
-- =========================================================
do -- jG
local function fn35()
    return function(arg, arg2)
        local closestPointOnSurface = arg:GetClosestPointOnSurface(arg2)
        local n = arg2 - closestPointOnSurface
        if n.Magnitude < 1e-06 then return closestPointOnSurface, nil end

        local n33 = arg:GetClosestPointOnSurface(arg2 + Vector3.xAxis*0.05) - closestPointOnSurface
        local n34 = arg:GetClosestPointOnSurface(arg2 + Vector3.yAxis*0.05) - closestPointOnSurface
        local n35 = arg:GetClosestPointOnSurface(arg2 + Vector3.zAxis*0.05) - closestPointOnSurface

        local n36 = n34:Cross(n33)
        if n36.Magnitude < 1e-06 then n36 = n34:Cross(n35) end
        if n36.Magnitude < 1e-06 then n36 = n33:Cross(n35) end
        if n36.Magnitude < 1e-06 then return closestPointOnSurface, nil end
        if n36:Dot(n) < 0 then n36 = -n36 end
        return closestPointOnSurface, n36.Unit
    end
end
tbl17.jG = function()
    local jg = tbl17.cache.jG
    if not jg then local jg2 = { c = fn35() }; tbl17.cache.jG = jg2; jg = jg2 end
    return jg.c
end
end

-- =========================================================
-- SECTION 12 — jH  ProjectileBreaker evasion engine
-- Scans CollectionService-tagged parts to find hide surfaces;
-- positions the character behind geometry relative to projectile
-- trajectories, using sinusoidal depth offsets.
-- =========================================================
do -- jH
local function fn35()
    local v115 = tbl17.bG()
    tbl17.cF()
    tbl17.cX()
    local v116 = tbl17.k()
    local v117 = tbl17.jF()   -- random CFrame
    local v118 = tbl17.jG()   -- surface-point helper
    local v119 = cloneref(game:GetService("CollectionService"))
    local v120 = Random.new()
    local vector = Vector3.new(5,5,5)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = {}
    overlapParams.BruteForceAllSlow = v86[34]

    -- Build surface coordinate frame (Right/Up/Forward) from a normal vector
    local function fn36(arg, arg2, arg3)
        local unit = arg2.Unit
        local n    = arg3.Position - arg
        local n33  = n - unit * n:Dot(unit)
        if n33.Magnitude < 0.0001 then
            local lookVector = arg3.CFrame.LookVector
            n33 = lookVector - unit * lookVector:Dot(unit)
            if n33.Magnitude < 0.0001 then
                n33 = Vector3.xAxis - unit * unit:Dot(Vector3.xAxis)
            end
        end
        local unit2 = n33.Unit:Cross(unit).Unit
        return { SurfacePosition=arg, Right=unit2, Up=unit, Forward=unit:Cross(unit2).Unit }
    end

    -- Sinusoidal depth modulator (drives the oscillating hide offset)
    local function fn37(arg, arg2)
        local n = 6.2831853071795862 * arg2
        return arg.Min + (arg.Max - arg.Min) * (math.sin(os.clock()*n)+1) * v86[101]
    end

    local function fn38()  -- upward depth
        local pb = v115.Data.Ragebot.Evasion.ProjectileBreaker
        return fn37(pb.DepthUp, pb.DepthUpFrequency)
    end

    local function fn39()  -- forward depth
        local pb = v115.Data.Ragebot.Evasion.ProjectileBreaker
        return fn37(pb.DepthForward, pb.DepthForwardFrequency)
    end

    -- Build hide CFrame from surface frame + depth offsets
    local function fn40(arg, arg2, arg3)
        return CFrame.fromMatrix(
            arg.SurfacePosition - arg.Up*0.01 - arg.Up*arg2 + arg.Forward*arg3,
            arg.Right, arg.Up, -arg.Forward
        )
    end

    -- Reject kill/barrier parts
    local function fn41(arg)
        return arg.Name == "Barriers" or arg:HasTag("OutOfBoundsPart") or arg:HasTag("KillBrick")
    end

    -- Check whether a candidate hide position is inside a kill zone
    local function fn42(arg)
        for _, v121 in workspace:GetPartBoundsInBox(CFrame.new(arg), vector, overlapParams), nil, nil do
            if fn41(v121) then return true end
        end
        return false
    end

    -- Validate a single part as a viable hide surface (non-transparent, big enough, flat top)
    local function fn43(arg)
        if arg.Transparency == 1 then return nil end
        local size = arg.Size
        if size.X * size.Y * size.Z < 64 then return nil end
        local n = size.Magnitude + 1000
        for i = 1, v86[175] do
            local v121, v122 = v118(arg, arg.Position + v120:NextUnitVector()*n)
            if v122 == nil or v122.Y < 0.98 then continue end
            return fn36(v121, v122, arg)
        end
        local v121, v122 = v118(arg, arg.Position + Vector3.yAxis*n)
        if v122 ~= nil and v122.Y >= 0.98 then return fn36(v121, v122, arg) end
        return nil
    end

    -- Fallback: random CFrame when no surface found, using FallbackBaseRadius / FallbackRadiusRandomFactor
    local function fn44(arg)
        local pb             = v115.Data.Ragebot.Evasion.ProjectileBreaker
        local fallbackRadius = pb.FallbackBaseRadius
        local n              = fallbackRadius + fallbackRadius * pb.FallbackRadiusRandomFactor
        local position       = arg.Position
        local v121 = v117(pb.FallbackAnchorFromCharacter and position or Vector3.new(v86[186], position.Y, v86[186]), fallbackRadius, n)
        local v122 = v120:NextInteger(v86[63], 3)
        local position2 = v121.Position
        local x, y, z = position2.X, position2.Y, position2.Z
        if v122 == 1 then x = 1073741824
        elseif v122 == v86[56] then y = 1073741824
        else z = 1073741824 end
        return v121 - position2 + Vector3.new(x, y, z)
    end

    local index2 = {}
    index2.__index = index2

    index2.new = function(arg, arg2)
        local ProjectileBreakerTeleport = v116.new("ragebot.ProjectileBreakerTeleport")
        local tbl18 = {
            _trove                 = ProjectileBreakerTeleport,
            _fighters              = arg,
            _nextPositionCooldown  = -v86[63],
            _poolEnvironmentId     = nil,
            _pool                  = {},
            _processedPartSet      = {},
        }
        setmetatable(tbl18, index2)

        ProjectileBreakerTeleport:Add(arg2:ObserveContext("ragebot.ProjectileBreakerTeleport", function(arg3, arg4)
            tbl18:_BindEnvironment(arg3.FighterState.EnvironmentId)
            arg4:Connect(arg3.FighterState.EnvironmentIdChanged, function(arg5)
                tbl18:_BindEnvironment(arg5)
            end)
        end))

        ProjectileBreakerTeleport:Connect(arg2.ContextRemoved, function()
            tbl18:_BindEnvironment(nil)
        end)

        return tbl18
    end

    index2.Destroy = function(arg)
        arg._trove:Destroy()
    end

    index2._BindEnvironment = function(arg, poolEnvironmentId)
        arg._poolEnvironmentId = poolEnvironmentId
        arg._pool              = {}
        arg._processedPartSet  = {}
    end

    -- Main compute: return hide CFrame or fallback
    index2.Compute = function(arg, arg2)
        local nextPositionCooldown = arg._nextPositionCooldown
        if os.clock() < nextPositionCooldown then
            local lastBreakSurface = arg._lastBreakSurface
            if lastBreakSurface ~= nil then
                return fn40(lastBreakSurface, fn38(), fn39())
            end
        end

        if not arg:_HasProjectileThreat() then
            arg._lastBreakSurface = nil
            return fn44(arg2)
        end

        local v121 = arg:_BreakLine()
        if v121 ~= nil then
            arg._lastBreakSurface = v121
            return fn40(v121, fn38(), fn39())
        end
        return fn44(arg2)
    end

    -- Only active against Slingshot (sole non-raycast projectile in Rivals)
    index2._HasProjectileThreat = function(arg)
        for _, v121 in arg._fighters.EnemyByPlayer, nil, nil do
            local v122 = v121.ItemObserver:EquippedItemAsGun()
            if v122 ~= nil and not v122.IsRaycast and v122.Name == "Slingshot" then return true end
        end
        return false
    end

    -- Scan RaycastWhitelist-tagged geometry for viable surfaces, build pool
    index2._ScanBatch = function(arg, arg2)
        local pb   = v115.Data.Ragebot.Evasion.ProjectileBreaker
        local n    = (pb.DepthUp.Min    + pb.DepthUp.Max)    * v86[101]
        local n33  = (pb.DepthForward.Min + pb.DepthForward.Max) * 0.5
        local v121 = v86[186]

        local function fn45(arg3)
            if not arg3:IsA("BasePart") or arg._processedPartSet[arg3] then return end
            arg._processedPartSet[arg3] = true
            v121 += 1
            local v122 = fn43(arg3)
            if v122 == nil then return end
            if fn42(fn40(v122, n, n33).Position) then return end
            table.insert(arg._pool, v122)
        end

        for _, v122 in v119:GetTagged("RaycastWhitelist"..arg2) do
            if fn41(v122) then continue end
            fn45(v122)
            if v121 >= v86[83] or #arg._pool >= 30 then return end
            for _, v123 in v122:GetDescendants() do
                if fn41(v123) then continue end
                fn45(v123)
                if v121 >= 64 or #arg._pool >= v86[192] then return end
            end
        end
    end

    -- Pick a surface from the pool; refresh pool every RepositionInterval seconds
    index2._BreakLine = function(arg)
        local poolEnvironmentId = arg._poolEnvironmentId
        if poolEnvironmentId == nil then return nil end
        if #arg._pool < 30 then arg:_ScanBatch(poolEnvironmentId) end
        if #arg._pool < 30 then return nil end
        local repositionInterval = v115.Data.Ragebot.Evasion.ProjectileBreaker.RepositionInterval
        arg._nextPositionCooldown = os.clock() + repositionInterval
        return arg._pool[v120:NextInteger(1, #arg._pool)]
    end

    index2.ResetState = function(arg)
        arg._nextPositionCooldown = -1
        arg._lastBreakSurface     = nil
    end

    return index2
end
tbl17.jH = function()
    local jh = tbl17.cache.jH
    if not jh then jh = { c = fn35() }; tbl17.cache.jH = jh end
    return jh.c
end
end

-- =========================================================
-- SECTION 13 — jI  Random evasion mode
-- Teleports to a random position within BaseRadius, biased by
-- RadiusRandomFactor. One axis is clamped to 1073741824 (OOB).
-- AnchorFromCharacter = true → anchor at character pos; false → world Y-only.
-- =========================================================
do -- jI
local function fn35()
    local v115 = tbl17.bG()
    local v116 = tbl17.jF()
    local v117 = Random.new()

    return { compute = function(arg)
        local random2      = v115.Data.Ragebot.Evasion.Random
        local baseRadius   = random2.BaseRadius
        local n            = baseRadius + baseRadius * random2.RadiusRandomFactor
        local position     = arg.Position
        local v118 = v116(
            random2.AnchorFromCharacter and position or Vector3.new(0, position.Y, 0),
            baseRadius, n
        )
        local v119    = v117:NextInteger(v86[63], 3)
        local position2 = v118.Position
        local x, y, z  = position2.X, position2.Y, position2.Z
        if v119 == 1 then x = 1073741824
        elseif v119 == 2 then y = 1073741824
        else z = 1073741824 end
        return v118 - position2 + Vector3.new(x, y, z)
    end }
end
tbl17.jI = function()
    local ji = tbl17.cache.jI
    if not ji then ji = { c = fn35() }; tbl17.cache.jI = ji end
    return ji.c
end
end

-- =========================================================
-- SECTION 14 — jJ  SpatialLimitGate (Stability)
-- Measures how long the character has been inside the spatial
-- limit (OOB coords). Compares elapsed vs ExpectedDuration - Stability.
-- Returns true (block fire) while inside the window; false once
-- Stability-adjusted time has elapsed → ShootLock fires.
-- =========================================================
do -- jJ
local function fn35()
    local v115 = tbl17.bG()
    tbl17.cF()
    tbl17.jB()
    local v116 = tbl17.k()

    -- Positions with |x|,|y|, or |z| >= 4194304 are considered inside the spatial limit
    local function fn36(arg)
        return math.abs(arg.X)>=4194304 or math.abs(arg.Y)>=4194304 or math.abs(arg.Z)>=4194304
    end

    local index2 = {}
    index2.__index = index2

    index2.new = function(arg)
        local tbl18 = { _trove=v116.new("ragebot.SpatialLimitGate"), _measurementByFighterState={} }
        setmetatable(tbl18, index2)
        tbl18:_Initialize(arg)
        return tbl18
    end

    index2._Initialize = function(arg, arg2)
        arg._trove:Add(arg2:ObserveRemoteStates(function(arg3)
            arg._measurementByFighterState[arg3] = { ExpectedDuration=1 }
        end, function(arg3)
            arg._measurementByFighterState[arg3] = nil
        end))
    end

    -- Returns true = still in window (do NOT fire); false = window expired (fire allowed)
    index2.Tick = function(arg, arg2)
        local now2       = os.clock()
        local fighterState = arg2.FighterState
        local v117       = arg._measurementByFighterState[fighterState]
        local limitEntryTime = v117.LimitEntryTime
        local flag19     = fighterState.ItemObserver:GetEquippedAmmoState() ~= false

        if not fn36(arg2.AliveState.RootPart.Position) then
            if limitEntryTime ~= nil then
                if flag19 then v117.ExpectedDuration = now2 - limitEntryTime end
                v117.LimitEntryTime = nil
            end
            return false
        end

        if limitEntryTime == nil then
            v117.LimitEntryTime = now2
            limitEntryTime      = now2
        end

        if flag19 then
            -- Stability = how many seconds BEFORE ExpectedDuration we fire
            if v117.ExpectedDuration - v115.Data.Ragebot.Stability <= now2 - limitEntryTime then
                return false
            end
        end

        return v86[34]   -- true: still waiting
    end

    index2.Destroy = function(arg)
        arg._trove:Destroy()
    end

    return index2
end
tbl17.jJ = function()
    local jj = tbl17.cache.jJ
    if not jj then jj = { c = fn35() }; tbl17.cache.jJ = jj end
    return jj.c
end
end

-- =========================================================
-- SECTION 15 — jK  Translocate evasion mode
-- Finds OutOfBoundsPart with KillDelay==0 and snaps to its
-- underside + Offset. Falls back to random CFrame if none found.
-- =========================================================
do -- jK
local function fn35()
    local v115 = tbl17.bG()
    local v116 = tbl17.jF()
    local v117 = cloneref(game:GetService("CollectionService"))

    return { compute = function(arg, arg2)
        if not arg2 then
            return v116(arg.Position, 10000, 1e9)
        end

        local v118 = nil
        for _, v119 in v117:GetTagged("OutOfBoundsPart") do
            if v119:GetAttribute("KillDelay") == 0 then
                v118 = v119
                break
            else
                v118 = nil
            end
        end

        if v118 == nil then return v116(arg.Position, 10000, 1e9) end

        -- Land at the underside of the OOB part + Translocate.Offset
        return v118.CFrame * CFrame.new(0, -v118.Size.Y/2 + v115.Data.Ragebot.Evasion.Translocate.Offset, 0)
    end }
end
tbl17.jK = function()
    local jk = tbl17.cache.jK
    if not jk then jk = { c = fn35() }; tbl17.cache.jK = jk end
    return jk.c
end
end

-- =========================================================
-- SECTION 16 — jM  Weapon strategy resolver
-- Reads Weapons.Priority + Weapons.Enabled + OnEmpty to decide
-- what action (Attack / Swap / Reload) to take each tick.
-- =========================================================
do -- jM
local function fn35()
    local v115 = tbl17.bG()
    tbl17.cU()
    tbl17.cX()

    local function fn36(arg)
        local index2 = arg.Index
        return index2==v86[63] and "Primary" or index2==2 and "Secondary" or index2==3 and "Melee" or nil
    end

    local function fn37(arg)
        return v115.Data.Ragebot.Weapons.Enabled[arg]
    end

    return { getAction = function(arg)
        local weapons  = v115.Data.Ragebot.Weapons
        local onEmpty  = weapons.OnEmpty
        local huge     = math.huge
        local huge2    = math.huge
        local flag19   = false
        local v116, v117 = nil, nil

        for _, v118 in arg.ItemBehaviors:GetItems(), nil, nil do
            local v119 = fn36(v118)
            if v119 == nil or not fn37(v119) then
                -- not an enabled weapon slot; skip
            else
                flag19 = v86[34]
                local huge3 = table.find(weapons.Priority, v119) or math.huge

                if v118.__type == "Gun" and v118:GetAmmo() == 0 then
                    if v118:GetAmmoReserve() > 0 then
                        if huge3 < huge2 then
                            if onEmpty == "Reload" then
                                v116 = v118; huge = huge3
                            else
                                huge2 = huge3; v117 = v118
                            end
                        end
                    end
                elseif v116 == nil or huge3 < huge then
                    v116 = v118; huge = huge3
                end
            end
        end

        if not flag19 then return nil end

        if v116 ~= nil then
            local flag20 = v116.__type == "Gun"
            if flag20 then flag20 = v116:GetAmmo() == v86[186] end
            if v116:IsEquipped() then
                if flag20 then return { Type="Reload", Item=v116 } end
                return { Type="Attack", Item=v116 }
            end
            return { Type="Swap", Item=v116 }
        end

        if onEmpty == "Swap" then return nil end

        if v117 ~= nil then
            if v117:IsEquipped() then return { Type="Reload", Item=v117 } end
            return { Type="Swap", Item=v117 }
        end

        return nil
    end }
end
tbl17.jM = function()
    local jm = tbl17.cache.jM
    if not jm then jm = { c = fn35() }; tbl17.cache.jM = jm end
    return jm.c
end
end

-- =========================================================
-- SECTION 17 — jN  Riot Shield state reader
-- =========================================================
do -- jN
local function fn35()
    tbl17.cU()
    tbl17.jx()

    return function(arg)
        local v115 = arg:FindMeleeByName("Riot Shield")
        if v115 == nil then return "None" end
        return v115:IsEquipped() and "Equipped" or "Unequipped"
    end
end
tbl17.jN = function()
    local jn = tbl17.cache.jN
    if not jn then jn = { c = fn35() }; tbl17.cache.jN = jn end
    return jn.c
end
end

-- =========================================================
-- SECTION 18 — jO  Ragebot orchestrator (main class)
-- Wires together all the above subsystems.
-- SetEnabled tweaks engine FastFlags for max server send rate.
-- Update() runs every heartbeat; dispatches _Plan → _ApplyPlan.
-- =========================================================
do -- jO
local function fn35()
    tbl17.cJ()
    local v115 = tbl17.bG()
    local v116 = tbl17.jz()        -- defensive CFrame helpers
    tbl17.cF()
    local v117 = tbl17.jD()        -- hitscan planner
    tbl17.cU()
    local v118 = tbl17.c4()        -- keybind observer
    local v119 = tbl17.jE()        -- melee planner
    tbl17.gA()
    tbl17.cX()
    tbl17.bM()
    local v120 = tbl17.jH()        -- ProjectileBreaker engine
    local v121 = tbl17.jI()        -- Random evasion
    local v122 = tbl17.cG()        -- replication delay estimator
    local v123 = tbl17.jJ()        -- SpatialLimitGate (Stability)
    tbl17.g_()
    local v124 = tbl17.jB()        -- target selector
    local v125 = tbl17.jK()        -- Translocate evasion
    local v126 = tbl17.k()         -- Trove
    local v127 = tbl17.jL()        -- ring-zone helper
    local v128 = tbl17.jM()        -- weapon strategy
    local v129 = tbl17.jN()        -- shield state
    local fallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight

    -- Plan used when going immune (e.g., during reload transport, post-shot)
    local function fn36()
        return { CFrame = v127.getImmune(), ShouldSkipDefense = true }
    end

    local index2 = {}
    index2.__index = index2

    index2.new = function(arg, arg2, arg3, arg4, arg5)
        local ragebot = v126.new("ragebot")
        local v130    = ragebot:Add(v123.new(arg))   -- SpatialLimitGate

        local tbl18 = {
            _trove                     = ragebot,
            _enabled                   = false,
            _lastTargetWorld           = nil,
            _lastDefensiveViewAngles   = nil,
            _playerContext             = arg3,
            _targetSelection           = v124.new(arg, arg2),
            _spatialLimitGate          = v130,
            _hitscanStrategy           = v117.new(arg5),
            _meleeStrategy             = v119.new(arg5),
            _projectileBreakerTeleport = ragebot:Add(v120.new(arg, arg3)),
            _stateHook                 = arg4,
            _reloadGun                 = nil,
            _reloadReadyAt             = nil,
            _reloadAcknowledgementDeadline = nil,
            _pendingDepletionAmmo      = nil,
        }
        setmetatable(tbl18, index2)
        tbl18:_Initialize()
        return tbl18
    end

    index2._Initialize = function(arg)
        arg._trove:Add(arg._playerContext:ObserveContext("ragebot", function(innerContext)
            if not flag2 then return end
            arg._innerContext = innerContext
            arg:_ClearReloadTransport()
        end))

        arg._trove:Connect(arg._playerContext.ContextRemoved, function()
            arg:_Reset()
            arg._innerContext = nil
        end)

        arg._trove:Add(v118:ObserveEnabledKeybind({"Ragebot"}, function(arg2)
            arg:SetEnabled(arg2)
            arg:_Reset()
        end))
    end

    -- Toggle engine-level FastFlags when ragebot enables/disables
    index2.SetEnabled = function(arg, enabled)
        if arg._enabled == enabled then return end
        arg._enabled = enabled
        -- Disable FallenPartsDestroyHeight so teleported parts aren't cleaned up
        v112(workspace, "FallenPartsDestroyHeight", enabled and (0/0) or fallenPartsDestroyHeight)
        -- Maximise physics sender rate for smooth remote replication
        v107(v108, "DFIntS2PhysicsSenderRate",         enabled and "120"        or "15")
        v107(v108, "DFIntAssemblyHistoryBufferSize",    enabled and "2147483648" or "15")
        v107(v108, "DFIntAssemblyHistorySkipSize",      enabled and v86[18]      or "8")
        if not enabled then arg:_ClearReloadTransport() end
    end

    index2.Update = function(arg, arg2)
        local innerContext = arg._innerContext
        if innerContext == nil then arg:_Reset(); return end
        local fighterState = innerContext.FighterState
        if fighterState.EnvironmentId == nil or not arg._enabled then arg:_Reset(); return end
        local state = fighterState.Character.State
        if not state.Alive then arg:_Reset(); return end

        local characterController = innerContext.CharacterController
        local clientCFrame        = characterController:GetClientCFrame()
        local mode                = v115.Data.Ragebot.Evasion.Mode
        local v130                = v128.getAction(innerContext)

        -- Translocate mode: no targeting, just teleport continuously
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

        -- Reload transport: start timing once reload begins
        local reloadGun = arg._reloadGun
        if reloadGun ~= nil and arg._reloadReadyAt == nil and arg._pendingDepletionAmmo == nil and not reloadGun:IsReloading() then
            arg._reloadReadyAt = os.clock() + v122.getEstimatedReplicationDelay()
        end

        arg:_ApplyForcedCrouch(v131.ShouldForceCrouch == true)

        local v132           = innerContext.ItemBehaviors:EquippedItemAsGun()
        local ammo           = v132 ~= nil and v132:GetAmmo() or 0
        local shotRequestCount = v132 ~= nil and v132.ShotRequestCount or 0
        local weaponAction   = v131.WeaponAction

        if weaponAction ~= nil then
            weaponAction()
            -- After a shot that depletes the clip: go immune and start reload sequence
            if v132 ~= nil and (v132.ShotRequestCount - shotRequestCount) > 0 and v132:GetExpectedAmmoAfterPendingShots() <= 0 then
                innerContext.CharacterController:SetServerCFrame(v127.getImmune())
                local now2 = os.clock()
                arg._reloadGun                     = v132
                arg._reloadReadyAt                 = now2 + v122.getEstimatedReplicationDelay()
                arg._pendingDepletionAmmo          = ammo
                arg._reloadAcknowledgementDeadline = now2 + v122.getEstimatedRemoteDelay() + v122.getEstimatedReplicationDelay()
            end
        end
    end

    -- Decide what CFrame + WeaponAction to apply this tick
    index2._Plan = function(arg, arg2, arg3, arg4, arg5, arg6, arg7)
        local flag19 = arg4 ~= nil and not arg._spatialLimitGate:Tick(arg4)
        local v130   = arg:_PlanReloadTransport(arg3)
        if v130 ~= nil then return v130 end

        if arg3 == nil then return arg:_EvadePlan(arg6, arg7) end

        if arg3.Type == "Swap" then
            local item  = arg3.Item
            local v131  = arg:_EvadePlan(arg6, arg7)
            v131.WeaponAction = function() item:Equip() end
            return v131
        end

        if arg3.Type == "Reload" then return fn36() end

        if arg4 == nil then return arg:_EvadePlan(arg6, arg7) end

        local item = arg3.Item

        if item.__type == "Gun" then
            if item:IsReloading() then return fn36() end
            local v131, v132 = arg._hitscanStrategy:Plan(arg2, arg4, item, arg5, flag19)
            return { CFrame=v131, WeaponAction=v132, ShouldForceCrouch=true, IsAimPose=v132~=nil }
        end

        if item.__type == "Melee" then
            local v131, v132, v133 = arg._meleeStrategy:Plan(arg2, arg4, item, arg5, flag19)
            return { CFrame=v131, ViewAngles=v132, WeaponAction=v133, ShouldSkipDefense=v86[34], ShouldForceCrouch=true }
        end

        return {}
    end

    index2._ClearReloadTransport = function(arg)
        arg._reloadGun                     = nil
        arg._reloadReadyAt                 = nil
        arg._reloadAcknowledgementDeadline = nil
        arg._pendingDepletionAmmo          = nil
    end

    -- Manages reload-immune teleport during reload sequence
    index2._PlanReloadTransport = function(arg, arg2)
        local reloadGun = arg._reloadGun
        local now2      = os.clock()

        if reloadGun ~= nil then
            -- Abort if weapon changed or non-reload action requested
            if (arg._innerContext ~= nil and arg._innerContext.ItemBehaviors:EquippedItemAsGun() or nil) ~= reloadGun
                or arg2 ~= nil and (arg2.Type=="Swap" or arg2.Type=="Attack") and arg2.Item ~= reloadGun then
                arg:_ClearReloadTransport()
                return nil
            end

            if reloadGun:IsReloading() then
                arg._reloadReadyAt                 = nil
                arg._pendingDepletionAmmo          = nil
                arg._reloadAcknowledgementDeadline = nil
                return fn36()
            end

            local ammo = reloadGun:GetAmmo()

            if arg._pendingDepletionAmmo ~= nil then
                local reloadAcknowledgementDeadline = arg._reloadAcknowledgementDeadline
                if not (ammo <= 0 and reloadGun:GetAmmoReserve() > 0) then
                    local flag19 = reloadAcknowledgementDeadline==nil or now2>=reloadAcknowledgementDeadline
                    if not flag19 then flag19 = reloadGun:GetExpectedAmmoAfterPendingShots() > v86[186] end
                    if flag19 then arg:_ClearReloadTransport(); return nil end
                    return fn36()
                end
                arg._pendingDepletionAmmo          = nil
                arg._reloadAcknowledgementDeadline = nil
            end

            if ammo > 0 or reloadGun:GetAmmoReserve() <= 0 then arg:_ClearReloadTransport(); return nil end

            local reloadReadyAt = arg._reloadReadyAt
            if reloadReadyAt == nil then
                reloadReadyAt      = now2 + v122.getEstimatedReplicationDelay()
                arg._reloadReadyAt = reloadReadyAt
            end

            local v130 = fn36()
            local reloadAcknowledgementDeadline = arg._reloadAcknowledgementDeadline
            if now2 >= reloadReadyAt and (reloadAcknowledgementDeadline==nil or now2>=reloadAcknowledgementDeadline) then
                v130.WeaponAction = function()
                    if reloadGun:Reload() then
                        arg._reloadAcknowledgementDeadline = os.clock() + v122.getEstimatedRemoteDelay() + v122.getEstimatedReplicationDelay()
                    end
                end
            end
            return v130
        end

        if arg2 == nil or arg2.Type ~= "Reload" then return nil end
        arg._reloadGun                     = arg2.Item
        arg._reloadReadyAt                 = nil
        arg._reloadAcknowledgementDeadline = nil
        arg._pendingDepletionAmmo          = nil
        return fn36()
    end

    -- Route to the correct evasion engine based on Mode
    index2._EvadePlan = function(arg, arg2, arg3)
        if arg3 == "Off" then return {} end
        if arg3 == "ProjectileBreaker" then
            return { CFrame=arg._projectileBreakerTeleport:Compute(arg2), ShouldSkipDefense=v86[34] }
        end
        return { CFrame=v121.compute(arg2) }   -- Random
    end

    -- Apply the planned CFrame and optional ViewAngles to the character controller
    index2._ApplyPlan = function(arg, arg2, arg3, arg4)
        local characterController = arg4.CharacterController
        local cFrame              = arg2.CFrame

        if cFrame == nil or arg3 == nil or arg2.ShouldSkipDefense then
            characterController:SetServerCFrame(cFrame)
            characterController:SendViewAngles(20, arg2.ViewAngles)
            return
        end

        local aliveState = arg3.AliveState
        local v130       = v129(arg4.ItemBehaviors)
        local v131       = v116.getDefensiveCFrame(cFrame, v130, arg3.FighterState, aliveState.RootPart)
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
        if arg2 then arg._stateHook:SetForced("IsCrouching", true)
        else          arg._stateHook:ClearForced("IsCrouching") end
    end

    index2._Reset = function(arg)
        arg:_ClearReloadTransport()
        arg._lastTargetWorld         = nil
        arg._lastDefensiveViewAngles = nil
        arg:_ApplyForcedCrouch(false)
        arg._meleeStrategy:ResetState()
        arg._projectileBreakerTeleport:ResetState()
        local innerContext = arg._innerContext
        if innerContext == nil then return end
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
    if not jo then jo = { c = fn35() }; tbl17.cache.jO = jo end
    return jo.c
end
end

-- =========================================================
-- SECTION 19 — jw  Flickbot class (complete)
-- =========================================================
do -- jw
local function fn35()
    local v115 = tbl17.cn()
    local v116 = tbl17.co()
    local v117 = tbl17.jv()        -- DirectionToOrientation helper
    local set   = tbl17.cp().set   -- camera orientation setter
    local v118  = tbl17.bG()
    tbl17.c_()
    tbl17.cF()
    local v119 = tbl17.c4()        -- keybind observer
    tbl17.cX()
    tbl17.cE()
    local v120 = tbl17.cd()        -- flick trajectory generator
    local v121 = tbl17.dc()
    local v122 = tbl17.ci()
    local v123 = tbl17.k()         -- Trove
    local v124 = tbl17.aH()
    local v125 = tbl17.de()
    local v126 = tbl17.df()
    local v127 = tbl17.dg()
    local v128 = cloneref(game:GetService("Workspace"))
    local data  = v118.Data

    local index2 = {}
    index2.__index = index2

    -- Project a world part to viewport coordinates; nil if behind camera
    local function fn36(arg)
        local v129 = v128.CurrentCamera:WorldToViewportPoint(arg.Position)
        return v129.Z > 0 and Vector2.new(v129.X, v129.Y) or nil
    end

    index2.new = function(arg, arg2, arg3)
        local flickbot  = v123.new("flickbot")
        local aimbot    = data.Aimbot
        local v129 = v121.new(arg2, arg, aimbot.TargetConditions, aimbot.TargetHitboxes[v124.DefaultProfile.Class],
            function(I,W) return arg3:Check(I,W,W.Parent) end)

        local tbl18 = {
            _trove           = flickbot,
            _playerContext   = arg2,
            _targetSelection = v122.new(v129, v115.buildMeasure(aimbot.Fov.Radius, aimbot.TargetConditions.WithinFov), v126),
            _state           = "Idle",
            _selected        = nil,
            _trajectory      = nil,
            _trajectoryIndex = v86[63],
            _elapsedMs       = 0,
            _totalMs         = 0,
            _bakedEndDirection = Vector3.zAxis,
            _timer           = 0,
            _isEnabledHeld   = v86[153],
        }
        setmetatable(tbl18, index2)

        -- Keybind: trigger a flick on leading edge
        flickbot:Add(v119:ObserveEnabledKeybind({"Flickbot"}, function(arg4)
            tbl18:_OnKeybindChanged(arg4)
        end))

        -- Mirror aimbot targeting settings into flickbot's target selector
        local v130 = v125(arg2, flickbot, "features.Aimbot", v129, function() return data.Aimbot.TargetHitboxes end)
        local function fn37(selection) tbl18._targetSelection:SetHitboxSelectionMode(v115.buildHitboxSelectionMode(selection)) end
        flickbot:Connect(v118:GetPropertyChangedSignal({"Aimbot","Fov"}), function(f)
            tbl18._targetSelection:SetMeasure(v115.buildMeasure(f.Radius, data.Aimbot.TargetConditions.WithinFov))
        end)
        flickbot:Connect(v118:GetPropertyChangedSignal({"Aimbot","TargetConditions"}), function(c)
            v129:SetConditions(c)
            tbl18._targetSelection:SetMeasure(v115.buildMeasure(data.Aimbot.Fov.Radius, c.WithinFov))
        end)
        flickbot:Connect(v118:GetPropertyChangedSignal({"Aimbot","TargetHitboxes"}), v130)
        flickbot:Connect(v118:GetPropertyChangedSignal({"Aimbot","HitboxSelection"}), fn37)
        fn37(aimbot.HitboxSelection)
        v130()
        return tbl18
    end

    index2._OnKeybindChanged = function(arg, arg2)
        if not arg2 then arg._isEnabledHeld = false; return end
        if arg._isEnabledHeld then return end
        arg._isEnabledHeld = true
        if arg._state ~= "Idle" then return end
        arg:_StartFlick()
    end

    -- Pick the best target, bake a curve trajectory from current camera to target viewport coords
    index2._StartFlick = function(arg)
        local currentCamera = v128.CurrentCamera
        local v129, v130    = arg._targetSelection:SelectBest(nil)
        if v129 == nil or v130 == nil then return end

        local selected = { Target=v129, Part=v130 }
        local v131     = fn36(v130)
        if v131 == nil then return end

        local v132 = v127()          -- current camera look direction
        local v133 = v120.new()
        local flickbot = v118.Data.Flickbot
        -- Bake the curve using FlickDuration, Curvature, Humanness
        v133:ApplyFlickProfile({ DurationMs=flickbot.FlickDuration, Curvature=flickbot.Curvature, Humanness=flickbot.Humanness })

        local trajectory = {}
        for k, v134 in v133:Generate(v132.X, v132.Y, v131.X, v131.Y), nil, nil do
            trajectory[k] = {
                Direction = currentCamera:ViewportPointToRay(v134.X, v134.Y).Direction,
                T = v134.T,
            }
        end

        arg._trajectory      = trajectory
        arg._trajectoryIndex = 1
        arg._elapsedMs       = v86[186]
        arg._totalMs         = trajectory[#trajectory].T
        arg._bakedEndDirection = trajectory[#trajectory].Direction
        arg._selected        = selected
        arg._state           = "Flicking"
        v116.claim("Flickbot", 10)
    end

    index2._FinishToCooldown = function(arg)
        arg._selected  = nil
        arg._trajectory = nil
        v116.release("Flickbot")
        local cooldown = v118.Data.Flickbot.Cooldown
        if cooldown > 0 then
            arg._state = "Cooldown"
            arg._timer = cooldown / 1000
        else
            arg._state = "Idle"
        end
    end

    -- Step through the baked trajectory; returns (direction, isDone)
    index2._SampleTrajectory = function(arg, arg2, arg3)
        arg._elapsedMs = arg._elapsedMs + arg3 * 1000
        local trajectoryIndex = arg._trajectoryIndex

        while trajectoryIndex < #arg2 and arg2[trajectoryIndex+1].T <= arg._elapsedMs do
            trajectoryIndex += 1
        end

        arg._trajectoryIndex = trajectoryIndex
        local v129 = arg2[trajectoryIndex]
        local v130 = arg2[trajectoryIndex+1]
        if v130 == nil then return arg2[#arg2].Direction, true end

        local n   = v130.T - v129.T
        local n33 = 1
        if n > 0 then n33 = math.clamp((arg._elapsedMs - v129.T) / n, 0, 1) end
        return v129.Direction:Lerp(v130.Direction, n33), false
    end

    -- Per-heartbeat state machine
    index2.Update = function(arg, arg2)
        local state = arg._state

        if state == "Flicking" then
            local selected   = arg._selected
            local trajectory = arg._trajectory

            if selected == nil or trajectory == nil then
                arg:_FinishToCooldown()
                if not flag2 then return end
                return
            end

            if selected.Part.Parent == nil then
                arg:_FinishToCooldown()
                return
            end

            local unit, v129 = arg:_SampleTrajectory(trajectory, arg2)

            -- Late-correct baked direction toward live target position
            if v86[186] < arg._totalMs then
                unit = (unit + (
                    (selected.Part.Position - v128.CurrentCamera.CFrame.Position).Unit - arg._bakedEndDirection
                ) * math.clamp(arg._elapsedMs / arg._totalMs, 0, 1)).Unit
            end

            -- Apply orientation to camera
            local v130, v131 = v117.DirectionToOrientation(unit)
            set(Vector2.new(v130, v131))

            if v129 then   -- trajectory finished
                local flickbot = v118.Data.Flickbot
                if flickbot.Shoot then
                    arg._state = "PostShot"
                    arg._timer = flickbot.ShotDelay / 1000
                else
                    arg:_FinishToCooldown()
                end
            end

        elseif state == "PostShot" then
            arg._timer = arg._timer - arg2
            if arg._timer <= 0 then
                arg:_FireShot()
                arg:_FinishToCooldown()
            end

        elseif state == "Cooldown" then
            arg._timer = arg._timer - arg2
            if arg._timer <= 0 then
                arg._state = "Idle"
            end
        end
    end

    -- Send StartShooting input to trigger a shot
    index2._FireShot = function(arg)
        local inner = arg._playerContext.Inner
        if inner == nil then return end
        inner.FighterState:Input("StartShooting")
    end

    index2.Destroy = function(arg)
        v116.release("Flickbot")
        arg._trove:Destroy()
    end

    return index2
end
tbl17.jw = function()
    local jw = tbl17.cache.jw
    if not jw then jw = { c = fn35() }; tbl17.cache.jw = jw end
    return jw.c
end
end
