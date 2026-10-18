-- ============================================================
-- MERGED SCRIPT: noragebot logic + Lilac v2 UI + Lilac ESP
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- SECTION 1: Anti-cheat bypass / fake event (noragebot)
-- ────────────────────────────────────────────────────────────
local _stbl; _stbl = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
    if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
        local tr = debug.traceback()
        if tr:find("MiscellaneousController") then
            return _stbl({1,2,3}, {})
        end
    end
    return _stbl(tbl, mt)
end))

coroutine.wrap(function()
    pcall(function()
        local function _proc(o)
            pcall(function()
                if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                    local _s, nm = pcall(function() return o.Name:lower() end)
                    if not _s or not nm then return end
                    local _tags = {"anticheat","ac","detection","ban","kick","security","moderation"}
                    for _i = 1, #_tags do
                        if nm:find(_tags[_i]) then
                            pcall(function() o.Disabled = true end)
                            break
                        end
                    end
                end
            end)
        end
        pcall(function()
            local _desc = game:GetDescendants()
            for _i = 1, #_desc do _proc(_desc[_i]) end
        end)
        pcall(function() game.DescendantAdded:Connect(_proc) end)
    end)
    pcall(function()
        local _nc = game:GetService("NetworkClient")
        if not _nc then return end
        _nc.ChildAdded:Connect(function(ch)
            pcall(function()
                local _ok, _n = pcall(function() return ch.Name:lower() end)
                if _ok and _n then
                    if _n:find("anticheat") or _n:find("detection") then
                        pcall(function() ch:Destroy() end)
                    end
                end
            end)
        end)
    end)
end)()

local _fakeEv
pcall(function()
    _fakeEv = Instance.new("RemoteEvent")
    _fakeEv.Name = "ClientAlert"
    _fakeEv.Parent = game:GetService("Players").LocalPlayer
end)

pcall(function()
    local _rf = game:GetService("ReplicatedFirst")
    local _tgt = _rf:WaitForChild("LocalScript3", 10)
    local _ct = 0
    local _gc = getgc(false)
    for _i = 1, #_gc do
        local _fn = _gc[_i]
        if type(_fn) ~= "function" then continue end
        local _ok1, _env = pcall(getfenv, _fn)
        if not _ok1 or type(_env) ~= "table" then continue end
        local _ok2, _scr = pcall(function() return rawget(_env, "script") end)
        if not _ok2 or not _scr or typeof(_scr) ~= "Instance" then continue end
        local _ok3, _ss = pcall(tostring, _scr)
        if not _ok3 then continue end
        if not (_scr == _tgt or (type(_ss) == "string" and _ss:find("LoadingScreen"))) then continue end
        local _ok4, _consts = pcall(debug.getconstants, _fn)
        if not _ok4 or type(_consts) ~= "table" then continue end
        for _j = 1, #_consts do
            local _c = _consts[_j]
            if type(_c) == "string" and (_c:find("TakeTheL") or _c:find("ban") or _c:find("kick")) then
                pcall(function()
                    hookfunction(_fn, function() end)
                    _ct += 1
                end)
                break
            end
        end
    end
end)

-- ────────────────────────────────────────────────────────────
-- SECTION 2: Core services & module requires (noragebot)
-- ────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocalPlayer        = Players.LocalPlayer

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Controllers   = PlayerScripts:WaitForChild("Controllers")
local Modules       = ReplicatedStorage:WaitForChild("Modules")

local CosmeticLibrary    = require(Modules:WaitForChild("CosmeticLibrary"))
local FighterController  = require(Controllers:WaitForChild("FighterController"))
local PlayerDataController = require(Controllers:WaitForChild("PlayerDataController"))

task.wait(4)

local _plrs    = Players
local _rs      = ReplicatedStorage
local _http    = game:GetService("HttpService")
local _run     = game:GetService("RunService")
local _ws      = game:GetService("Workspace")
local _lp      = LocalPlayer
local _pscripts = PlayerScripts
local _ctrl    = Controllers
local _mods    = Modules

local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

local _cosLib  = CosmeticLibrary
local _itmLib  = require(_mods:WaitForChild("ItemLibrary", 10))
local _datCtrl = PlayerDataController

local _eq, _favs = {}, {}
local _buildingWep, _viewProf = nil, nil
local _lastWep = nil
local _fakeInv = {}

local function _mkCosmetic(nm, ctype, opts)
    local _base = _cosLib.Cosmetics[nm]
    if not _base then return nil end
    local _d = {}
    for k, v in pairs(_base) do _d[k] = v end
    _d.Name = nm
    _d.Type = _d.Type or ctype
    _d.Seed = _d.Seed or math.random(1, 1000000)
    if _enumLib then
        local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
        if _s and _eid then
            _d.Enum = _eid
            _d.ObjectID = _d.ObjectID or _eid
        end
    end
    if opts then
        if opts.inverted ~= nil then _d.Inverted = opts.inverted end
        if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
    end
    return _d
end

local _cfgFile  = "rivals_unlocker_config.json"
local _saveLock = false

local function _stripForSave()
    local _out = {}
    for wn, cos in pairs(_eq) do
        _out[wn] = {}
        for ct, cd in pairs(cos) do
            if cd and cd.Name then
                _out[wn][ct] = { Name = cd.Name, Inverted = cd.Inverted, OnlyUseFavorites = cd.OnlyUseFavorites }
            end
        end
    end
    return { equipped = _out, favorites = _favs }
end

local function _loadCfg()
    if not isfile or not readfile then return end
    local _ok1, _ex = pcall(isfile, _cfgFile)
    if not _ok1 or not _ex then return end
    local _ok2, _raw = pcall(readfile, _cfgFile)
    if not _ok2 or not _raw or _raw == "" then return end
    local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
    if not _ok3 or not _dec then return end
    if _dec.favorites then _favs = _dec.favorites end
    if _dec.equipped then
        _eq = {}
        for wn, cos in pairs(_dec.equipped) do
            _eq[wn] = {}
            for ct, sd in pairs(cos) do
                if sd and sd.Name then
                    if _cosLib.Cosmetics[sd.Name] then
                        local _cloned = _mkCosmetic(sd.Name, ct, { inverted = sd.Inverted, favoritesOnly = sd.OnlyUseFavorites })
                        if _cloned then _eq[wn][ct] = _cloned end
                    end
                end
            end
            if not next(_eq[wn]) then _eq[wn] = nil end
        end
    end
end

local function _saveCfg()
    if not writefile or _saveLock then return end
    _saveLock = true
    task.spawn(function()
        task.wait(1)
        local _payload = _stripForSave()
        local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
        if _ok then pcall(writefile, _cfgFile, _enc) end
        _saveLock = false
    end)
end

_loadCfg()

local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
local function _isCosType(cosObj)
    if not cosObj then return false end
    for _, t in ipairs(_cosTypes) do
        if cosObj.Type == t then return true end
    end
    return false
end

_cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end
_cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end
_cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end

local _origOwns = _cosLib.OwnsCosmetic
_cosLib.OwnsCosmetic = function(self, inv, nm, wep)
    if nm:find("MISSING_") or nm == "Bubble Gun" then return _origOwns(self, inv, nm, wep) end
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosType(c) then return true end
    return _origOwns(self, inv, nm, wep)
end

local _origGet = _datCtrl.Get
_datCtrl.Get = function(self, key)
    local _val = _origGet(self, key)
    if key == "CosmeticInventory" then
        local _prx = {}
        if _val then
            for k, v in pairs(_val) do
                local c = _cosLib.Cosmetics[k]
                if c and _isCosType(c) then _prx[k] = v end
            end
        end
        return setmetatable(_prx, {
            __index = function(t, k)
                local c = _cosLib.Cosmetics[k]
                if c and _isCosType(c) then return true end
                return nil
            end
        })
    end
    if key == "FavoritedCosmetics" then
        local _res = _val and table.clone(_val) or {}
        for wep, fv in pairs(_favs) do
            _res[wep] = _res[wep] or {}
            for nm, isFav in pairs(fv) do
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosType(c) then _res[wep][nm] = isFav end
            end
        end
        return _res
    end
    return _val
end

local _origGetWep = _datCtrl.GetWeaponData
_datCtrl.GetWeaponData = function(self, wn)
    local _d = _origGetWep(self, wn)
    if not _d then return nil end
    if _eq[wn] then
        for ct, cd in pairs(_eq[wn]) do pcall(function() _d[ct] = cd end) end
    end
    return _d
end

local _fightCtrl
pcall(function() _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10)) end)

if hookmetamethod then
    local _remotes  = _rs:FindFirstChild("Remotes")
    local _dataRem  = _remotes and _remotes:FindFirstChild("Data")
    local _equipRem = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
    local _favRem   = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
    local _repRem   = _remotes and _remotes:FindFirstChild("Replication")
    local _fightRem = _repRem and _repRem:FindFirstChild("Fighter")
    local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

    if _equipRem then
        local _onc
        _onc = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() ~= "FireServer" then return _onc(self, ...) end
            local _a = {...}
            if _useItmRem and self == _useItmRem then
                local _oid = _a[1]
                if _fightCtrl then
                    pcall(function()
                        local _f = _fightCtrl:GetFighter(_lp)
                        if _f and _f.Items then
                            for _, itm in pairs(_f.Items) do
                                if itm:Get("ObjectID") == _oid then _lastWep = itm.Name; break end
                            end
                        end
                    end)
                end
            end
            if self == _equipRem then
                local _wn = _a[1]; local _ct = _a[2]; local _cn = _a[3]; local _opts = _a[4] or {}
                if _cn and _cn ~= "None" and _cn ~= "" then
                    local _inv = _datCtrl:Get("CosmeticInventory")
                    if _inv and rawget(_inv, _cn) then return _onc(self, ...) end
                end
                _eq[_wn] = _eq[_wn] or {}
                if not _cn or _cn == "None" or _cn == "" then
                    _eq[_wn][_ct] = nil
                    if not next(_eq[_wn]) then _eq[_wn] = nil end
                else
                    local _cloned = _mkCosmetic(_cn, _ct, { inverted = _opts.IsInverted, favoritesOnly = _opts.OnlyUseFavorites })
                    if _cloned then _eq[_wn][_ct] = _cloned end
                end
                task.defer(function() pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
                _saveCfg()
                return
            end
            if self == _favRem then
                local _cos = _cosLib.Cosmetics[_a[2]]
                if _cos then
                    _favs[_a[1]] = _favs[_a[1]] or {}
                    _favs[_a[1]][_a[2]] = _a[3] or nil
                    task.spawn(function() pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end) end)
                    _saveCfg()
                end
                return
            end
            return _onc(self, ...)
        end)
    end
end

local _cliItem
pcall(function() _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

if _cliItem and _cliItem._CreateViewModel then
    local _origCVM = _cliItem._CreateViewModel
    _cliItem._CreateViewModel = function(self, vmRef)
        local _wn = self.Name
        local _wp = self.ClientFighter and self.ClientFighter.Player
        _buildingWep = (_wp == _lp) and _wn or nil
        if _wp == _lp and _eq[_wn] then
            local _dk = self:ToEnum("Data")
            if vmRef[_dk] then
                if _eq[_wn].Skin then vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin; vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name end
                if _eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = _eq[_wn].Charm end
                if _eq[_wn].Wrap  then vmRef[_dk][self:ToEnum("Wrap")]  = _eq[_wn].Wrap  end
            elseif vmRef.Data then
                if _eq[_wn].Skin  then vmRef.Data.Skin  = _eq[_wn].Skin; vmRef.Data.Name = _eq[_wn].Skin.Name end
                if _eq[_wn].Charm then vmRef.Data.Charm = _eq[_wn].Charm end
                if _eq[_wn].Wrap  then vmRef.Data.Wrap  = _eq[_wn].Wrap  end
            end
        end
        local _r = _origCVM(self, vmRef)
        _buildingWep = nil
        return _r
    end
end

local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if _vmMod then
    local _CVM = require(_vmMod)
    local _origNew = _CVM.new
    _CVM.new = function(repData, cliItm)
        local _wp = cliItm.ClientFighter and cliItm.ClientFighter.Player
        local _wn = _buildingWep or cliItm.Name
        if _wp == _lp and _eq[_wn] then
            local _RC = require(_rs.Modules.ReplicatedClass)
            local _dk = _RC:ToEnum("Data")
            repData[_dk] = repData[_dk] or {}
            local _cos = _eq[_wn]
            if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
            if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
            if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
        end
        return _origNew(repData, cliItm)
    end
end

-- ────────────────────────────────────────────────────────────
-- SECTION 3: Anti-Katana module (noragebot)
-- ────────────────────────────────────────────────────────────
local AntiKatanaModule = (function()
    local Players    = game:GetService("Players")
    local Workspace  = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local antikatana = false
    local katanausers = {}

    local function detectkatana()
        local lp = Players.LocalPlayer
        if not lp:FindFirstChild("PlayerScripts") then lp.PlayerScriptsAdded:Wait() end
        task.spawn(function()
            local katana, attempts = nil, 0
            while attempts < 10 do
                pcall(function()
                    local modules = lp.PlayerScripts:FindFirstChild("Modules")
                    if modules then
                        local itemtypes = modules:FindFirstChild("ItemTypes")
                        if itemtypes then
                            katana = itemtypes:FindFirstChild("Katana")
                        end
                    end
                end)
                if katana then break end
                task.wait(1)
                attempts = attempts + 1
            end
            if not katana then return end
            local success, katanamod = pcall(require, katana)
            if not success or not katanamod then return end
            if katanamod.Parry then
                local originalParry = katanamod.Parry
                katanamod.Parry = function(self, ...)
                    if not antikatana then return originalParry(self, ...) end
                    local plr = self.ClientFighter and self.ClientFighter.Player
                    if plr then
                        katanausers[plr] = {
                            isParrying = true,
                            startTime  = tick()
                        }
                    end
                    return originalParry(self, ...)
                end
            end
            if katanamod.StopParry then
                local originalStopParry = katanamod.StopParry
                katanamod.StopParry = function(self, ...)
                    local plr = self.ClientFighter and self.ClientFighter.Player
                    if plr and katanausers[plr] then
                        katanausers[plr].isParrying = false
                    end
                    return originalStopParry(self, ...)
                end
            end
        end)
    end

    detectkatana()

    local function istargetparrying(player)
        local data = katanausers[player]
        if not data then return false end
        if not data.isParrying then return false end
        if tick() - data.startTime > 3 then
            katanausers[player] = nil
            return false
        end
        return true
    end

    local function setantikatana(value)
        antikatana = value
        getgenv().SetAntiKatana = setantikatana
    end

    getgenv().SetAntiKatana    = setantikatana
    getgenv().IsTargetParrying = istargetparrying

    return {
        setEnabled = setantikatana,
        isParrying = istargetparrying,
    }
end)()

-- ────────────────────────────────────────────────────────────
-- SECTION 4: AlwaysBackstab module (noragebot)
-- ────────────────────────────────────────────────────────────
local AlwaysBackstabModule = (function()
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local S = { alwaysBackstabActive = false }
    local State = { KnifeItem = nil, LockConn = nil, SetEnabled = nil, Rehook = nil }

    local function _absGetKnifeItem()
        local lp = Players.LocalPlayer
        local ok, fc = pcall(function()
            return require(lp.PlayerScripts.Controllers.FighterController)
        end)
        if not ok or not fc then return nil end
        local fighter = fc.LocalFighter
        if not fighter then return nil end
        for _, item in pairs(fighter.Items or {}) do
            local iname = (item.Name or ""):lower()
            if iname:find("knife") or iname:find("karambit") or iname:find("blade") then
                return item
            end
        end
        return nil
    end

    local function _absInstallHooks(ki)
        State.KnifeItem = ki
        if ki._GetServerBackstab then
            local orig = ki._GetServerBackstab
            ki._GetServerBackstab = function(self, ...)
                if S.alwaysBackstabActive then return true end
                return orig(self, ...)
            end
        end
        if ki.GetBackstab then
            local orig = ki.GetBackstab
            ki.GetBackstab = function(self, ...)
                if S.alwaysBackstabActive then return true end
                return orig(self, ...)
            end
        end
    end

    local function _absStartLock()
        if State.LockConn then State.LockConn:Disconnect() end
        State.LockConn = RunService.Heartbeat:Connect(function()
            if not S.alwaysBackstabActive then return end
            local lp = Players.LocalPlayer
            local char = lp.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
        end)
    end

    local function _absStopLock()
        if State.LockConn then State.LockConn:Disconnect(); State.LockConn = nil end
    end

    State.Rehook = function()
        task.spawn(function()
            task.wait(1)
            local ki = _absGetKnifeItem()
            if ki then _absInstallHooks(ki) end
            if S.alwaysBackstabActive then _absStartLock() end
        end)
    end

    State.SetEnabled = function(on)
        S.alwaysBackstabActive = on
        if on then
            if not State.KnifeItem then
                task.spawn(function()
                    local ki = _absGetKnifeItem()
                    if ki then _absInstallHooks(ki) end
                    _absStartLock()
                end)
            else
                _absStartLock()
            end
        else
            _absStopLock()
        end
    end

    getgenv().__AlwaysBackstab = State
    return State
end)()

-- ────────────────────────────────────────────────────────────
-- SECTION 5: Anti-Aim + Underground (noragebot)
-- ────────────────────────────────────────────────────────────
do
    local function safeRequire(module)
        local ok, result = pcall(require, module)
        return ok and result or nil
    end
    local function getControllers()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if not ps then return nil, nil end
        local ctrl = ps:FindFirstChild("Controllers")
        if not ctrl then return nil, nil end
        local fighter = ctrl:FindFirstChild("FighterController")
        local camera  = ctrl:FindFirstChild("CameraController")
        return fighter and safeRequire(fighter), camera and safeRequire(camera)
    end

    local FighterControllerAA, CameraControllerAA = getControllers()

    local settings = {
        enabled = false, yawtype = "none", pitchtype = "none", angletype = "none",
        customangle = 0, minspeed = 10, maxspeed = 20, minangle = 30, maxangle = 60,
        randomangle = false, fakelag = false, fakelagstuds = 4, desync = false,
        desyncstuds = 3, microjitter = false, microstrength = 25, velocitybreaker = false,
    }
    local statemanager = { lastupdate = tick(), invertstate = false, smoothyaw = 0, smoothpitch = 0, smoothroll = 0, framecounter = 0 }
    local utils = { getrandominrange = function(min, max) return min + math.random() * (max - min) end }
    local antiaim = {}

    function antiaim.calculateyaw(deltatime)
        local yaw = 0
        local currenttime = tick()
        if settings.yawtype == "jitter" then
            local minangle = math.rad(settings.minangle); local maxangle = math.rad(settings.maxangle)
            yaw = settings.randomangle and utils.getrandominrange(-maxangle, maxangle) or (math.random() > 0.5 and minangle or -minangle)
        elseif settings.yawtype == "spinbot" then
            local speed = utils.getrandominrange(settings.minspeed/10, settings.maxspeed/10)
            yaw = (currenttime * speed) % (2 * math.pi)
        elseif settings.yawtype == "random" then
            if statemanager.framecounter % 30 == 0 then
                yaw = utils.getrandominrange(-math.rad(settings.maxangle), math.rad(settings.maxangle))
            else yaw = statemanager.smoothyaw end
        end
        statemanager.smoothyaw = yaw
        return yaw
    end

    function antiaim.calculatepitch()
        local pitch = 0
        if settings.pitchtype == "jitter" then
            local minangle = math.rad(settings.minangle); local maxangle = math.rad(settings.maxangle)
            pitch = settings.randomangle and utils.getrandominrange(-maxangle, maxangle) or (math.random() > 0.5 and minangle or -minangle)
        elseif settings.pitchtype == "spinbot" then
            pitch = math.sin(tick() * (settings.maxspeed/10)) * math.rad(settings.maxangle)
        elseif settings.pitchtype == "random" then
            if statemanager.framecounter % 20 == 0 then
                pitch = utils.getrandominrange(math.rad(-89), math.rad(89))
            else pitch = statemanager.smoothpitch end
        end
        statemanager.smoothpitch = pitch
        return pitch
    end

    function antiaim.calculateroll()
        local roll = 0
        if settings.angletype == "tilt 45" then roll = math.rad(45)
        elseif settings.angletype == "tilt 90" then roll = math.rad(90)
        elseif settings.angletype == "upside down" then roll = math.rad(180)
        elseif settings.angletype == "custom" then roll = math.rad(settings.customangle) end
        statemanager.smoothroll = roll
        return roll
    end

    local function updantiaim(deltatime)
        if not settings.enabled then return end
        if settings.yawtype == "none" and settings.pitchtype == "none" and settings.angletype == "none" then return end
        local character = LocalPlayer.Character
        if not character then return end
        local rootpart = character:FindFirstChild("HumanoidRootPart")
        if not rootpart then return end
        statemanager.framecounter += 1
        rootpart.CFrame = rootpart.CFrame * CFrame.Angles(antiaim.calculatepitch(), antiaim.calculateyaw(deltatime), antiaim.calculateroll())
    end

    local function flushAntiAimMovementState()
        statemanager.framecounter = 0; statemanager.smoothyaw = 0; statemanager.smoothpitch = 0; statemanager.smoothroll = 0
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end) end
    end
    getgenv().InstanceFlushMovementState = flushAntiAimMovementState

    local underground_enabled = false
    local underground_oldpos  = nil
    local undergroundDepthOffset = -2

    local function getFloorBelowPosition(pos)
        local rayOrigin    = pos
        local rayDirection = Vector3.new(0, -500, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local fighter = FighterControllerAA and FighterControllerAA.LocalFighter
        if fighter and fighter.Entity and fighter.Entity.RootPart then
            raycastParams.FilterDescendantsInstances = {fighter.Entity.RootPart.Parent}
        end
        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if result then return CFrame.new(Vector3.new(pos.X, result.Position.Y + undergroundDepthOffset, pos.Z)) end
        return nil
    end

    if CameraControllerAA and CameraControllerAA.Update then
        local oldUpdate = CameraControllerAA.Update
        CameraControllerAA.Update = function(...)
            if underground_enabled and FighterControllerAA and FighterControllerAA.LocalFighter
                and FighterControllerAA.LocalFighter.Entity and FighterControllerAA.LocalFighter.Entity.RootPart
                and underground_oldpos then
                FighterControllerAA.LocalFighter.Entity.RootPart.CFrame = underground_oldpos
            end
            return oldUpdate(...)
        end
    end

    local undergroundHeartbeatConn = nil
    local function startUndergroundHeartbeat()
        if undergroundHeartbeatConn then return end
        undergroundHeartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
            if not underground_enabled then underground_oldpos = nil; return end
            local fighter = FighterControllerAA and FighterControllerAA.LocalFighter
            if not fighter or not fighter.Entity or not fighter.Entity.RootPart then underground_oldpos = nil; return end
            underground_oldpos = fighter.Entity.RootPart.CFrame
            local floorCFrame = getFloorBelowPosition(fighter.Entity.RootPart.Position)
            if floorCFrame then fighter.Entity.RootPart.CFrame = floorCFrame end
        end)
    end

    local _antiAimConn = nil
    function _G.StartAntiAimExt()
        if not settings.enabled then settings.enabled = true end
        if not _antiAimConn then _antiAimConn = game:GetService("RunService").Heartbeat:Connect(updantiaim) end
    end
    function _G.StopAntiAimExt()
        settings.enabled = false
        if _antiAimConn then _antiAimConn:Disconnect(); _antiAimConn = nil end
        flushAntiAimMovementState()
    end
    function _G.SetUndergroundExt(state)
        underground_enabled = state
        getgenv().InstanceUndergroundEnabled = state
        if state then startUndergroundHeartbeat()
        else
            underground_oldpos = nil
            if undergroundHeartbeatConn then undergroundHeartbeatConn:Disconnect(); undergroundHeartbeatConn = nil end
        end
    end
    function _G.SetUndergroundDepthExt(depth) undergroundDepthOffset = depth end
    _G.AntiAimSettings = settings
end

-- ────────────────────────────────────────────────────────────
-- SECTION 6: SlideBoost module (noragebot)
-- ────────────────────────────────────────────────────────────
local SlideBoostModule = (function()
    local RunService = game:GetService("RunService")
    _G.Features = _G.Features or {}
    _G.Features.SlideBoost = _G.Features.SlideBoost or { Enabled = false, Speed = 300 }
    local mech = nil
    local connection = nil

    local function getMechanicsController()
        local success, result = pcall(function() return require(LocalPlayer.PlayerScripts.Controllers.MechanicsController) end)
        mech = success and result or nil
        return mech
    end

    local function startSlideBoost()
        if connection then connection:Disconnect(); connection = nil end
        connection = RunService.RenderStepped:Connect(function()
            if not _G.Features.SlideBoost.Enabled then return end
            if not mech then getMechanicsController() end
            if mech and mech.IsSliding then
                pcall(function() mech._sliding_velocity.Velocity = mech._sliding_velocity.Velocity.Unit * _G.Features.SlideBoost.Speed end)
            end
        end)
    end

    local function stopSlideBoost()
        if connection then connection:Disconnect(); connection = nil end
    end

    local function setSlideBoost(enabled, speed)
        _G.Features.SlideBoost.Enabled = enabled
        if speed then _G.Features.SlideBoost.Speed = speed end
        if enabled then startSlideBoost() else stopSlideBoost() end
    end

    getMechanicsController()
    if _G.Features.SlideBoost.Enabled then startSlideBoost() end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        getMechanicsController()
        if _G.Features.SlideBoost.Enabled then startSlideBoost() end
    end)

    return { setSlideBoost = setSlideBoost, getEnabled = function() return _G.Features.SlideBoost.Enabled end, getSpeed = function() return _G.Features.SlideBoost.Speed end }
end)()

-- ────────────────────────────────────────────────────────────
-- SECTION 7: Feature state table S + Drawing circles
-- ────────────────────────────────────────────────────────────
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local Player  = Players.LocalPlayer
local Mouse   = Player:GetMouse()
local ViewportSize = workspace.CurrentCamera.ViewportSize
local Camera  = workspace.CurrentCamera

local Workspace  = game:GetService("Workspace")
local Character  = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP        = Character:WaitForChild("HumanoidRootPart")

local S = {
    voidActive = false, fistActive = false, roitActive = false, scytheActive = false,
    wallbangActive = false, wallbangHeadActive = false,
    espActive = false,
    aimbotActive = false, silentAimActive = false, rapidFireActive = false,
    noclipActive = false, infiniteJumpActive = false,
    speedValue = 16, speedEnabled = false,
    aimFov = 30, silentFov = 30,
    aimTargetPart = "Head", silentTargetPart = "Head",
    silentTargetNPC = true, wallCheck = true, teamCheck = false,
    fireDelay = 1,
    instantAdsEnabled = false, noEquipAnimEnabled = false, noShootAnimEnabled = false,
    noSpreadEnabled = false, noSmokeEnabled = false, noFlashEnabled = false,
    deviceSpoofEnabled = false, spoofDevice = "VR",
    espShowBox = true, espBoxType = "2D", espShowName = true, espShowDistance = true,
    espShowTracers = true, espShowHealthBar = true, espShowSkeleton = false,
    aimSmooth = 1,
    flyActive = false, flySpeed = 50,
    headDownActive = false, antiAimMode = "None", irregularMoveActive = false,
    aimFovColor = Color3.new(1,1,1), silentFovColor = Color3.new(1,0,0),
    showFovCircles = false, fovStyle = "Outline",
    undergroundActive = false, undergroundDepth = -5,
    triggerbotEnabled = false, triggerbotKey = Enum.KeyCode.T,
    triggerbotDelay = 50, triggerbotWallCheck = false, triggerbotTeamCheck = false,
    triggerbotOnlyADS = false, triggerbotActive = false, triggerbotLastShot = 0,
    alwaysBackstabActive = false,
}

local aimFovCircle = Drawing.new("Circle")
aimFovCircle.Visible = false; aimFovCircle.Thickness = 2; aimFovCircle.Filled = false
aimFovCircle.NumSides = 64; aimFovCircle.Color = Color3.new(1,1,1); aimFovCircle.Radius = 0
aimFovCircle.Position = Vector2.new(0,0); aimFovCircle.Transparency = 0

local silentFovCircle = Drawing.new("Circle")
silentFovCircle.Visible = false; silentFovCircle.Thickness = 2; silentFovCircle.Filled = false
silentFovCircle.NumSides = 64; silentFovCircle.Color = Color3.new(1,0,0); silentFovCircle.Radius = 0
silentFovCircle.Position = Vector2.new(0,0); silentFovCircle.Transparency = 0

task.wait(0.5)
local camReady = workspace.CurrentCamera
if not camReady then repeat task.wait() camReady = workspace.CurrentCamera until camReady end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cam = workspace.CurrentCamera
        local screenSize = cam.ViewportSize
        local aimShow = S.aimbotActive and S.showFovCircles
        aimFovCircle.Visible = aimShow
        if aimShow and cam.FieldOfView > 0 then
            aimFovCircle.Position = Vector2.new(screenSize.X/2, screenSize.Y/2)
            aimFovCircle.Radius   = (S.aimFov / cam.FieldOfView) * screenSize.Y / 2
            aimFovCircle.Color    = S.aimFovColor
            aimFovCircle.Filled   = (S.fovStyle == "Filled")
            aimFovCircle.Transparency = (S.fovStyle == "Filled") and 0.5 or 0
        end
        local silentShow = S.silentAimActive and S.showFovCircles
        silentFovCircle.Visible = silentShow
        if silentShow and cam.FieldOfView > 0 then
            silentFovCircle.Position = Vector2.new(screenSize.X/2, screenSize.Y/2)
            silentFovCircle.Radius   = (S.silentFov / cam.FieldOfView) * screenSize.Y / 2
            silentFovCircle.Color    = S.silentFovColor
            silentFovCircle.Filled   = (S.fovStyle == "Filled")
            silentFovCircle.Transparency = (S.fovStyle == "Filled") and 0.5 or 0
        end
    end)
end)

-- ────────────────────────────────────────────────────────────
-- SECTION 8: All feature functions (noragebot, unchanged)
-- ────────────────────────────────────────────────────────────
local function isEnemy(player)
    return player ~= LocalPlayer and player:GetAttribute("TeamID") ~= LocalPlayer:GetAttribute("TeamID")
end

local function getClosestEnemy()
    local closest = nil; local minDist = math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < minDist then minDist = dist; closest = p.Character end
        end
    end
    return closest
end

local function isClearLineOfSight(origin, targetPos, targetCharacter)
    local direction = (targetPos - origin)
    local distance  = direction.Magnitude
    if distance < 0.01 then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    return Workspace:Raycast(origin, direction.Unit * distance, rayParams) == nil
end

local function toggleVoid(on)
    S.voidActive = on
    if on then
        local flip = true; local lastPos = HRP.CFrame
        task.spawn(function()
            while S.voidActive do
                local h = HRP
                if h then
                    if flip then h.CFrame = CFrame.new(0,-321730912732103712003733333177387219676767,0)
                    else h.CFrame = CFrame.new(0,39126371928633123561237812537,0) end
                    flip = not flip
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                end
                task.wait(0.12)
            end
        end)
    else
        local h = HRP
        if h then
            h.AssemblyLinearVelocity = Vector3.zero; h.AssemblyAngularVelocity = Vector3.zero
            h.CFrame = CFrame.new(0,10,0)
        end
    end
end

local fistConn
local function startFist()
    if fistConn then fistConn:Disconnect() end
    task.spawn(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local itemLib = modules and modules:FindFirstChild("ItemLibrary")
        if not itemLib then return end
        local success, library = pcall(require, itemLib)
        if not (success and type(library) == "table") then return end
        local items = library.Items or library.Weapons or library.Melee or library.Utilities
        if type(items) ~= "table" then return end
        local meleeCooldowns = {"Cooldown","AttackCooldown","UseDelay","SpinCooldown","HeavyAttackCooldown","AbilityCooldown","FireCooldown"}
        for name, item in pairs(items) do
            if type(item) == "table" then
                local itemName = item.Name or name
                local isMelee = (item.Type == "Melee" or item.Category == "Melee" or (item.Damage and not item.AmmoType))
                if isMelee then
                    for _, field in ipairs(meleeCooldowns) do if item[field] ~= nil then item[field] = 0 end end
                end
                if string.lower(itemName) == "scythe" then
                    if item.DashCooldown ~= nil then item.DashCooldown = 0
                    elseif item.AbilityCooldown ~= nil then item.AbilityCooldown = 0 end
                end
            end
        end
    end)
    fistConn = RunService.Stepped:Connect(function()
        if not S.fistActive then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.Velocity = Vector3.new(0,0,0) end end
        local enemy = getClosestEnemy()
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            local enemyRoot = enemy.HumanoidRootPart; local tickTime = tick() * 4010
            root.CFrame = enemyRoot.CFrame * CFrame.new(math.cos(tickTime)*0.1, 0, math.sin(tickTime)*0.1)
        end
    end)
end
local function stopFist() S.fistActive = false; if fistConn then fistConn:Disconnect(); fistConn = nil end end
local function toggleFist(on) S.fistActive = on; if on then startFist() else stopFist() end end

local roitConn
local function startRiot()
    if roitConn then roitConn:Disconnect() end
    roitConn = RunService.Stepped:Connect(function()
        if not S.roitActive then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.Velocity = Vector3.new(0,0,0) end end
        local enemy = getClosestEnemy()
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            root.CFrame = enemy.HumanoidRootPart.CFrame + Vector3.new(math.random(-5,5), math.random(0,5), math.random(-5,5))
        end
    end)
end
local function stopRiot() S.roitActive = false; if roitConn then roitConn:Disconnect(); roitConn = nil end end
local function toggleRiot(on) S.roitActive = on; if on then startRiot() else stopRiot() end end

local function toggleScythe(on)
    S.scytheActive = on
    task.spawn(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local itemLib = modules and modules:FindFirstChild("ItemLibrary")
        if not itemLib then return end
        local success, library = pcall(require, itemLib)
        if not (success and type(library) == "table") then return end
        local items = library.Items or library.Weapons or library.Melee or library.Utilities
        if type(items) ~= "table" then return end
        for name, item in pairs(items) do
            if type(item) == "table" and string.lower(item.Name or name) == "scythe" then
                if item.DashCooldown ~= nil then item.DashCooldown = on and 0 or nil
                elseif item.AbilityCooldown ~= nil then item.AbilityCooldown = on and 0 or nil end
            end
        end
    end)
end

local noclipConn
local function startNoClip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not S.noclipActive then return end
        local char = LocalPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end)
end
local function stopNoClip() S.noclipActive = false; if noclipConn then noclipConn:Disconnect(); noclipConn = nil end end
local function toggleNoclip(on) S.noclipActive = on; if on then startNoClip() else stopNoClip() end end

local wallbangObject = nil
local wallbangActive = false
do
    local _wallbangFunc = function()
        local __a1b2c3 = setmetatable({}, {__index = function(_, s) return cloneref(game:GetService(s)) end})
        local __p6q7r8 = getgenv()
        if __p6q7r8.__s9t0u1 then __p6q7r8.__s9t0u1:Shutdown() end
        local __v2w3x4 = __a1b2c3.Players
        local __y5z6a7 = __a1b2c3.RunService
        local __b8c9d0 = __a1b2c3.ReplicatedStorage
        local __k7l8m9 = __v2w3x4.LocalPlayer
        local __t6u7v8 = require(__k7l8m9.PlayerScripts.Modules.ItemTypes.Gun)
        local __w9x0y1 = require(__b8c9d0.Modules.Utility)
        local __z2a3b4 = setmetatable({}, {__index = function(_, k)
            local c = __k7l8m9.Character; if not c then return nil end
            if k == "__root" then return c:FindFirstChild("HumanoidRootPart")
            elseif k == "__head" then return c:FindFirstChild("Head") end
            return nil
        end})
        local obj = {}
        function obj:__init()
            self.__active = true; self.__target = nil; self.__desync = false
            self.__conn1 = nil; self.__conn2 = nil; self.__task1 = nil
            self.__oldfunc = nil; self.__hadEnemy = false; self.__teleportedToVoid = false; self.__preVoidCFrame = nil
            self:__setup()
        end
        function obj:__setup()
            self.__conn1 = __y5z6a7.Heartbeat:Connect(function() if not self.__active then return end; self.__target = self:__find() end)
            local oldShoot = __t6u7v8.StartShooting
            self.__oldfunc = oldShoot
            __t6u7v8.StartShooting = function(self2, ...)
                if S.silentAimActive then return oldShoot(self2, ...) end
                local results = {oldShoot(self2, ...)}
                if not self2.ClientFighter or not self2.ClientFighter.IsLocalPlayer then return unpack(results) end
                local data = results[3]
                if not data or typeof(data) ~= "table" then return unpack(results) end
                results[4] = true
                local target = self.__target
                if not self.__active or not target or not target.Character then return unpack(results) end
                if not self.__desync or self.__curr ~= target then self:__desync_start(target); task.wait(0.1) end
                if self.__task1 then task.cancel(self.__task1); self.__task1 = nil end
                local head = target.Character:FindFirstChild("Head"); if not head then return unpack(results) end
                local headPos = head.Position; local below = headPos - Vector3.new(0,5,0)
                local cf = CFrame.lookAt(below, headPos)
                data[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(below, headPos)*CFrame.Angles(cf:ToOrientation()))
                data[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(headPos)*CFrame.Angles(cf:ToOrientation()))
                data[utf8.char(2)] = head
                data[utf8.char(3)] = __w9x0y1:EncodeCFrame(CFrame.new())
                self.__task1 = task.delay(0.15, function() self:__desync_stop() end)
                return unpack(results)
            end
        end
        function obj:__find()
            local myChar = __k7l8m9.Character; if not myChar then return nil end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return nil end
            local aliveEnemies = 0
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character
                if char then local hum = char:FindFirstChildWhichIsA("Humanoid"); if hum and hum.Health > 0 then aliveEnemies += 1 end end
            end
            if aliveEnemies == 0 then
                if self.__hadEnemy and not self.__teleportedToVoid then
                    self.__preVoidCFrame = myRoot.CFrame
                    myRoot.CFrame = CFrame.new(0,1000000,0)
                    myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero
                    self.__teleportedToVoid = true
                end
                return nil
            else self.__hadEnemy = true; self.__teleportedToVoid = false end
            local closest = nil; local closestDist = math.huge
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character; if not char then continue end
                local root = char:FindFirstChild("HumanoidRootPart"); local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if not (root and head and hum and hum.Health > 0) then continue end
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist > 200 then continue end
                if dist < closestDist then closestDist = dist; closest = player end
            end
            return closest
        end
        function obj:__desync_start(target)
            if self.__conn2 then self.__conn2:Disconnect() end
            self.__desync = true; self.__curr = target
            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__desync then return end
                local myRoot = __z2a3b4.__root; if not myRoot then return end
                local enemyRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if not enemyRoot then self:__desync_stop(); return end
                local oldCF = myRoot.CFrame; local oldVel = myRoot.Velocity; local oldRV = myRoot.RotVelocity
                myRoot.CFrame = enemyRoot.CFrame * CFrame.new(0,-5,0)
                __y5z6a7:BindToRenderStep("__restore",101,function()
                    myRoot.CFrame = oldCF; myRoot.Velocity = oldVel; myRoot.RotVelocity = oldRV
                    __y5z6a7:UnbindFromRenderStep("__restore")
                end)
            end)
        end
        function obj:__desync_stop() self.__desync = false; self.__curr = nil; if self.__conn2 then self.__conn2:Disconnect(); self.__conn2 = nil end end
        function obj:Shutdown()
            self.__active = false
            if self.__conn1 then self.__conn1:Disconnect() end
            if self.__conn2 then self.__conn2:Disconnect() end
            if self.__task1 then task.cancel(self.__task1) end
            if self.__oldfunc then __t6u7v8.StartShooting = self.__oldfunc end
            if self.__preVoidCFrame then
                local myRoot = __z2a3b4.__root
                if myRoot then myRoot.CFrame = self.__preVoidCFrame; myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero end
                self.__preVoidCFrame = nil
            end
        end
        return obj
    end
    function startWallbang()
        if wallbangObject then return end
        local obj = _wallbangFunc(); obj:__init(); wallbangObject = obj; wallbangActive = true
    end
    function stopWallbang()
        if wallbangObject then wallbangObject:Shutdown(); wallbangObject = nil; wallbangActive = false end
    end
end
local function toggleWallbang(on) S.wallbangActive = on; if on then startWallbang() else stopWallbang() end end

-- WallbangHead (abbreviated to maintain wall-bang head variant)
local wallbangHeadObject = nil
local wallbangHeadActive = false
do
    local function _createWallbangHead()
        local __a1b2c3 = setmetatable({}, {__index = function(_, s) return cloneref(game:GetService(s)) end})
        local __v2w3x4 = __a1b2c3.Players; local __y5z6a7 = __a1b2c3.RunService
        local __b8c9d0 = __a1b2c3.ReplicatedStorage; local __e1f2g3 = __a1b2c3.Workspace
        local __k7l8m9 = __v2w3x4.LocalPlayer; local __n0o1p2 = __e1f2g3.CurrentCamera
        local __t6u7v8 = require(__k7l8m9.PlayerScripts.Modules.ItemTypes.Gun)
        local __w9x0y1 = require(__b8c9d0.Modules.Utility)
        local __z2a3b4 = setmetatable({}, {__index = function(_, k)
            local c = __k7l8m9.Character; if not c then return nil end
            if k == "__root" then return c:FindFirstChild("HumanoidRootPart")
            elseif k == "__head" then return c:FindFirstChild("Head") end
            return nil
        end})
        local obj = {}
        function obj:__init()
            self.__active = true; self.__target = nil; self.__desync = false
            self.__conn1 = nil; self.__conn2 = nil; self.__task1 = nil; self.__oldfunc = nil
            self.__hadEnemy = false; self.__teleportedToVoid = false; self.__preVoidCFrame = nil
            self:__setup()
        end
        function obj:__setup()
            self.__conn1 = __y5z6a7.Heartbeat:Connect(function() if not self.__active then return end; self.__target = self:__find() end)
            local oldShoot = __t6u7v8.StartShooting; self.__oldfunc = oldShoot
            __t6u7v8.StartShooting = function(self2, ...)
                if S.silentAimActive then return oldShoot(self2, ...) end
                local results = {oldShoot(self2, ...)}
                if not self2.ClientFighter or not self2.ClientFighter.IsLocalPlayer then return unpack(results) end
                local data = results[3]
                if not data or typeof(data) ~= "table" then return unpack(results) end
                results[4] = true
                local target = self.__target
                if not self.__active or not target or not target.Character then return unpack(results) end
                if not self.__desync or self.__curr ~= target then self:__desync_start(target); task.wait(0.1) end
                if self.__task1 then task.cancel(self.__task1); self.__task1 = nil end
                local head = target.Character:FindFirstChild("Head"); if not head then return unpack(results) end
                local headPos = head.Position
                local cf = CFrame.lookAt(headPos, headPos + __n0o1p2.CFrame.LookVector)
                data[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(headPos)*CFrame.Angles(cf:ToOrientation()))
                data[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(headPos)*CFrame.Angles(cf:ToOrientation()))
                data[utf8.char(2)] = head
                data[utf8.char(3)] = __w9x0y1:EncodeCFrame(CFrame.new())
                self.__task1 = task.delay(0.15, function() self:__desync_stop() end)
                return unpack(results)
            end
        end
        function obj:__find()
            local myChar = __k7l8m9.Character; if not myChar then return nil end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return nil end
            local aliveEnemies = 0
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 or player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character
                if char then local hum = char:FindFirstChildWhichIsA("Humanoid"); if hum and hum.Health > 0 then aliveEnemies += 1 end end
            end
            if aliveEnemies == 0 then
                if self.__hadEnemy and not self.__teleportedToVoid then
                    self.__preVoidCFrame = myRoot.CFrame; myRoot.CFrame = CFrame.new(0,1000000,0)
                    myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero; self.__teleportedToVoid = true
                end
                return nil
            else self.__hadEnemy = true; self.__teleportedToVoid = false end
            local closest = nil; local closestDist = math.huge
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 or player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character; if not char then continue end
                local root = char:FindFirstChild("HumanoidRootPart"); local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if not (root and head and hum and hum.Health > 0) then continue end
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist > 200 then continue end
                if dist < closestDist then closestDist = dist; closest = player end
            end
            return closest
        end
        function obj:__desync_start(target)
            if self.__conn2 then self.__conn2:Disconnect() end; self.__desync = true; self.__curr = target
            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__desync then return end
                local myRoot = __z2a3b4.__root; if not myRoot then return end
                local enemyRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if not enemyRoot then self:__desync_stop(); return end
                local oldCF = myRoot.CFrame; local oldVel = myRoot.Velocity; local oldRV = myRoot.RotVelocity
                myRoot.CFrame = enemyRoot.CFrame * CFrame.new(0,-5,0)
                __y5z6a7:BindToRenderStep("__restore_head",101,function()
                    myRoot.CFrame = oldCF; myRoot.Velocity = oldVel; myRoot.RotVelocity = oldRV
                    __y5z6a7:UnbindFromRenderStep("__restore_head")
                end)
            end)
        end
        function obj:__desync_stop() self.__desync = false; self.__curr = nil; if self.__conn2 then self.__conn2:Disconnect(); self.__conn2 = nil end end
        function obj:Shutdown()
            self.__active = false
            if self.__conn1 then self.__conn1:Disconnect() end; if self.__conn2 then self.__conn2:Disconnect() end
            if self.__task1 then task.cancel(self.__task1) end
            if self.__oldfunc then __t6u7v8.StartShooting = self.__oldfunc end
            if self.__preVoidCFrame then
                local myRoot = __z2a3b4.__root
                if myRoot then myRoot.CFrame = self.__preVoidCFrame; myRoot.AssemblyLinearVelocity = Vector3.zero; myRoot.AssemblyAngularVelocity = Vector3.zero end
                self.__preVoidCFrame = nil
            end
        end
        return obj
    end
    function startWallbangHead()
        if wallbangHeadObject then return end
        local obj = _createWallbangHead(); obj:__init(); wallbangHeadObject = obj; wallbangHeadActive = true
    end
    function stopWallbangHead()
        if wallbangHeadObject then wallbangHeadObject:Shutdown(); wallbangHeadObject = nil; wallbangHeadActive = false end
    end
end
local function toggleWallbangHead(on)
    S.wallbangHeadActive = on
    if on then stopWallbang(); startWallbangHead() else stopWallbangHead() end
end

local function toggleUnderground(on)
    S.undergroundActive = on
    _G.SetUndergroundExt(on)
    if on then _G.SetUndergroundDepthExt(S.undergroundDepth) end
end

local CameraControllerAimbot = nil
pcall(function()
    local ctrl = LocalPlayer.PlayerScripts:WaitForChild("Controllers", 10)
    local camModule = ctrl:FindFirstChild("CameraController")
    if camModule and camModule:IsA("ModuleScript") then
        CameraControllerAimbot = require(camModule)
    end
end)

local aimbotConn
local function startAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not S.aimbotActive then return end
        local cam = workspace.CurrentCamera
        local screenCenter = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        local closestTarget = nil; local closestDist = S.aimFov
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if S.teamCheck and player:GetAttribute("TeamID") == LocalPlayer:GetAttribute("TeamID") then continue end
            local char = player.Character; if not char then continue end
            local targetPart = char:FindFirstChild(S.aimTargetPart) or char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not targetPart or not hum or hum.Health <= 0 then continue end
            local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if dist < closestDist then
                    if not S.wallCheck or isClearLineOfSight(cam.CFrame.Position, targetPart.Position, char) then
                        closestDist = dist; closestTarget = targetPart
                    end
                end
            end
        end
        if closestTarget then
            local targetCF = CFrame.new(cam.CFrame.Position, closestTarget.Position)
            cam.CFrame = cam.CFrame:Lerp(targetCF, math.clamp(1 / (S.aimSmooth * 10), 0.01, 1))
        end
    end)
end
local function stopAimbot() S.aimbotActive = false; if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end end
local function toggleAimbot(on) S.aimbotActive = on; if on then startAimbot() else stopAimbot() end end

local silentAimConn
local function startSilentAim()
    if silentAimConn then silentAimConn:Disconnect() end
    silentAimConn = RunService.RenderStepped:Connect(function()
        if not S.silentAimActive then return end
    end)
end
local function stopSilentAim() S.silentAimActive = false; if silentAimConn then silentAimConn:Disconnect(); silentAimConn = nil end end
local function toggleSilentAim(on) S.silentAimActive = on; if on then startSilentAim() else stopSilentAim() end end

local originalGunStats = {}
local function applyRapidFire()
    if not S.rapidFireActive then return end
    local ok, lib = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
    if not ok or not lib then return end
    local items = lib.Items
    if not items then return end
    for name, data in pairs(items) do
        if data.ShootCooldown ~= nil then
            if not originalGunStats[name] then originalGunStats[name] = { ShootCooldown = data.ShootCooldown, ShootBurstCooldown = data.ShootBurstCooldown } end
            data.ShootCooldown = S.fireDelay / 1000
            if data.ShootBurstCooldown then data.ShootBurstCooldown = S.fireDelay / 1000 end
        end
    end
end
local function restoreRapidFire()
    local ok, lib = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
    if not ok or not lib then return end
    local items = lib.Items
    if not items then return end
    for name, orig in pairs(originalGunStats) do
        local data = items[name]
        if data then
            if orig.ShootCooldown ~= nil then data.ShootCooldown = orig.ShootCooldown end
            if orig.ShootBurstCooldown ~= nil then data.ShootBurstCooldown = orig.ShootBurstCooldown end
        end
    end
end
local function toggleRapidFire(on) S.rapidFireActive = on; if on then applyRapidFire() else restoreRapidFire() end end

local originalGetSpread, originalGUSpread
local function patchGunSpread()
    if S.noSpreadEnabled then
        local ok, Gun = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
        if ok and Gun and Gun.GetSpread then
            if not originalGetSpread then originalGetSpread = Gun.GetSpread end
            Gun.GetSpread = function(...) return Vector2.new(0,0) end
        end
        pcall(function()
            local gu = require(ReplicatedStorage.Modules:WaitForChild("GameplayUtility",5))
            if gu and gu.GetSpread then
                if not originalGUSpread then originalGUSpread = gu.GetSpread end
                gu.GetSpread = function() return CFrame.identity end
            end
        end)
    else
        if originalGetSpread then pcall(function() require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun).GetSpread = originalGetSpread end) end
        if originalGUSpread then pcall(function() require(ReplicatedStorage.Modules:WaitForChild("GameplayUtility")).GetSpread = originalGUSpread end) end
    end
end

local originalSmokeUpdate, originalCloudUpdate
local function applyNoSmoke()
    if S.noSmokeEnabled then
        pcall(function()
            local SS = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("ClientReplicatedClasses"):WaitForChild("ClientFighter"):WaitForChild("FighterInterface"):WaitForChild("SmokeScreen",10))
            if SS and SS.Update then
                if not originalSmokeUpdate then originalSmokeUpdate = SS.Update end
                SS.Update = function(self) self._smoke_cloud_spring.Target = 0; self._smoke_cloud_cover.Transparency = 1; if self._smoke_cloud_dof then self._smoke_cloud_dof.Parent = nil end end
            end
        end)
        pcall(function()
            local SC = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("SmokeCloud",10))
            if SC and SC.Update then
                if not originalCloudUpdate then originalCloudUpdate = SC.Update end
                SC.Update = function(self) if self.Model then self.Model:Destroy() end; return true end
            end
        end)
    else
        if originalSmokeUpdate then pcall(function() require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.FighterInterface.SmokeScreen).Update = originalSmokeUpdate end) end
        if originalCloudUpdate then pcall(function() require(LocalPlayer.PlayerScripts.Modules.SmokeCloud).Update = originalCloudUpdate end) end
    end
end

local originalFlashFunc
local function applyNoFlash()
    if S.noFlashEnabled then
        pcall(function()
            local Flashed = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("ClientReplicatedClasses"):WaitForChild("ClientFighter"):WaitForChild("FighterInterface"):WaitForChild("Flashed",10))
            if Flashed and Flashed.Flash then
                if not originalFlashFunc then originalFlashFunc = Flashed.Flash end
                Flashed.Flash = function() end
            end
        end)
    else
        if originalFlashFunc then pcall(function() require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.FighterInterface.Flashed).Flash = originalFlashFunc end) end
    end
end

local function applyGunEnhancements()
    pcall(function()
        local char = LocalPlayer.Character; if not char then return end
        local tool = char:FindFirstChildOfClass("Tool"); if not tool then return end
        local GunMixin = tool:FindFirstChild("GunMixin"); if not GunMixin then return end
        local gun = require(GunMixin)
        if S.instantAdsEnabled and gun.SetADSTime then gun:SetADSTime(0) end
        if S.noEquipAnimEnabled and gun.SetEquipAnimEnabled then gun:SetEquipAnimEnabled(false) end
        if S.noShootAnimEnabled and gun.SetShootAnimEnabled then gun:SetShootAnimEnabled(false) end
    end)
end

local originalReplicateControls
local function applyDeviceSpoof()
    pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
        if S.deviceSpoofEnabled then
            if not originalReplicateControls then originalReplicateControls = FighterController._ReplicateControls end
            FighterController._ReplicateControls = function(self)
                remote:FireServer(S.spoofDevice); self._last_controls_replicated_time = tick()
            end
            remote:FireServer(S.spoofDevice)
        else
            if originalReplicateControls then FighterController._ReplicateControls = originalReplicateControls end
        end
    end)
end

local speedConn
local function setSpeed(val)
    if val then S.speedValue = val end
    if not S.speedEnabled then
        if speedConn then speedConn:Disconnect(); speedConn = nil end
        local char = LocalPlayer.Character
        if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed = 16 end end
        return
    end
    local _val = S.speedValue
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = _val
            if speedConn then speedConn:Disconnect() end
            speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if hum.WalkSpeed ~= _val then hum.WalkSpeed = _val end
            end)
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if S.infiniteJumpActive then
        local char = LocalPlayer.Character
        if char then local hum = char:FindFirstChildWhichIsA("Humanoid"); if hum and hum.Health > 0 then hum:ChangeState("Jumping") end end
    end
end)

local FlyEnabled = false
local flyAttachment, flyVelocity, flyAlign, flyHumanoid, flyRoot
local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local function setupFlyPhysics()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    flyHumanoid = char:WaitForChild("Humanoid"); flyRoot = char:WaitForChild("HumanoidRootPart")
    if FlyEnabled then
        if flyAttachment then flyAttachment:Destroy() end
        flyHumanoid.PlatformStand = true
        flyAttachment = Instance.new("Attachment", flyRoot)
        flyVelocity = Instance.new("LinearVelocity", flyAttachment)
        flyVelocity.MaxForce = 9e9; flyVelocity.VectorVelocity = Vector3.zero; flyVelocity.Attachment0 = flyAttachment
        flyAlign = Instance.new("AlignOrientation", flyAttachment)
        flyAlign.MaxTorque = 9e9; flyAlign.Responsiveness = 200
        flyAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment; flyAlign.Attachment0 = flyAttachment
    end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.1); setupFlyPhysics() end)
setupFlyPhysics()

RunService.RenderStepped:Connect(function()
    if FlyEnabled and flyRoot and workspace.CurrentCamera and flyVelocity and flyAlign then
        local cam = workspace.CurrentCamera; local moveVector = Controls:GetMoveVector(); local speed = S.flySpeed or 50
        flyVelocity.VectorVelocity = moveVector.Magnitude > 0 and (cam.CFrame.LookVector*-moveVector.Z + cam.CFrame.RightVector*moveVector.X).Unit * speed or Vector3.zero
        flyAlign.CFrame = cam.CFrame
    end
end)

local function EnableFly() FlyEnabled = true; setupFlyPhysics() end
local function DisableFly()
    FlyEnabled = false
    if flyHumanoid then flyHumanoid.PlatformStand = false end
    if flyAttachment then flyAttachment:Destroy() end
    flyAttachment = nil; flyVelocity = nil; flyAlign = nil
end
local function toggleFly(on) S.flyActive = on; if on then EnableFly() else DisableFly() end end

local irregularMoveConn
local function stopIrregularMove() if irregularMoveConn then irregularMoveConn:Disconnect(); irregularMoveConn = nil end end
local function startIrregularMove()
    stopIrregularMove()
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    irregularMoveConn = RunService.Stepped:Connect(function()
        if not S.irregularMoveActive then return end
        char = LocalPlayer.Character; if not char then return end
        root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        if root.Velocity.Magnitude > 1 then root.CFrame = root.CFrame * CFrame.new(math.random(-3,3)/10, 0, math.random(-3,3)/10) end
    end)
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local triggerbotConn

local function triggerbot_GetTarget()
    local camPos = Camera.CFrame.Position; local camDir = Camera.CFrame.LookVector
    local closestAngle = S.silentFov; local targetPart = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if S.triggerbotTeamCheck and p:GetAttribute("TeamID") == LocalPlayer:GetAttribute("TeamID") then continue end
        local char = p.Character; if not char then continue end
        local head = char:FindFirstChild("Head"); local hum = char:FindFirstChildOfClass("Humanoid")
        if head and hum and hum.Health > 0 then
            local toTarget = (head.Position - camPos).Unit
            local degrees = math.deg(math.acos(math.clamp(camDir:Dot(toTarget),-1,1)))
            if degrees <= closestAngle then
                if not S.triggerbotWallCheck or isClearLineOfSight(camPos, head.Position, char) then
                    closestAngle = degrees; targetPart = head
                end
            end
        end
    end
    return targetPart
end

local function triggerbot_Shoot()
    local char = LocalPlayer.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool"); if not tool then return end
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Replication"):FindFirstChild("Fighter"):FindFirstChild("FireServer")
        if remote then remote:FireServer()
        else
            VirtualInputManager:SendMouseButtonEvent(ViewportSize.X/2, ViewportSize.Y/2, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(ViewportSize.X/2, ViewportSize.Y/2, 0, false, game, 1)
        end
    end)
end

local function triggerbotUpdate()
    if not S.triggerbotEnabled then return end
    if not UserInputService:IsKeyDown(S.triggerbotKey) then S.triggerbotActive = false; return end
    local target = triggerbot_GetTarget()
    if target then
        local now = tick()
        if now - S.triggerbotLastShot >= S.triggerbotDelay/1000 then S.triggerbotLastShot = now; triggerbot_Shoot() end
    end
end
local function startTriggerbot() if triggerbotConn then triggerbotConn:Disconnect() end; triggerbotConn = RunService.RenderStepped:Connect(triggerbotUpdate) end
local function stopTriggerbot() S.triggerbotEnabled = false; if triggerbotConn then triggerbotConn:Disconnect(); triggerbotConn = nil end end
local function toggleTriggerbot(on) S.triggerbotEnabled = on; if on then startTriggerbot() else stopTriggerbot() end end

function ApplyAllSettings()
    toggleAimbot(false); toggleSilentAim(false); toggleVoid(false); toggleFist(false)
    toggleRiot(false); toggleScythe(false); toggleWallbang(false); toggleWallbangHead(false)
    toggleNoclip(false); toggleFly(false); toggleRapidFire(false)
    stopIrregularMove(); stopTriggerbot(); _G.StopAntiAimExt(); toggleUnderground(false)
    if S.aimbotActive then toggleAimbot(true) end
    if S.silentAimActive then toggleSilentAim(true) end
    if S.voidActive then toggleVoid(true) end
    if S.fistActive then toggleFist(true) end
    if S.roitActive then toggleRiot(true) end
    if S.scytheActive then toggleScythe(true) end
    if S.wallbangActive then toggleWallbang(true) end
    if S.wallbangHeadActive then toggleWallbangHead(true) end
    if S.noclipActive then toggleNoclip(true) end
    if S.flyActive then toggleFly(true) end
    if S.rapidFireActive then toggleRapidFire(true) end
    if S.irregularMoveActive then startIrregularMove() end
    if S.triggerbotEnabled then startTriggerbot() end
    AlwaysBackstabModule.SetEnabled(false)
    if S.alwaysBackstabActive then AlwaysBackstabModule.SetEnabled(true) end
    if _G.AntiAimSettings.enabled then _G.StartAntiAimExt() end
    if S.undergroundActive then toggleUnderground(true) end
    setSpeed(S.speedValue)
    applyGunEnhancements(); patchGunSpread(); applyNoSmoke(); applyNoFlash(); applyDeviceSpoof()
end

-- ────────────────────────────────────────────────────────────
-- SECTION 9: Lilac UI (full, verbatim from main_luau)
-- ────────────────────────────────────────────────────────────
local TweenService2   = game:GetService("TweenService")
local GuiService      = game:GetService("GuiService")
local Lighting        = game:GetService("Lighting")

if _G.__LilacCleanup then pcall(_G.__LilacCleanup) end

local lp2 = Players.LocalPlayer
local playerGui = lp2:WaitForChild("PlayerGui", 10)
if not playerGui then warn("[Lilac] PlayerGui never loaded.") return end
local stale = playerGui:FindFirstChild("LilacUI")
if stale then stale:Destroy() end

local connections2 = {}
local cleanups2    = {}
local gui

local function connect2(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections2, c)
    return c
end

local function unload()
    for _, f in ipairs(cleanups2) do pcall(f) end; table.clear(cleanups2)
    for _, c in ipairs(connections2) do pcall(function() c:Disconnect() end) end; table.clear(connections2)
    if gui then gui:Destroy() end
    _G.__LilacCleanup = nil
end
_G.__LilacCleanup = unload

local RW, RH = 1360, 650
local MAIN_W   = 1080
local SIDEBAR_W = 200
local PREVIEW_W = 260
local CONTENT_W = MAIN_W - SIDEBAR_W

local BODY  = Enum.Font.GothamMedium
local LIGHT = Enum.Font.Gotham
local BOLD  = Enum.Font.GothamBold
local HEAD  = Enum.Font.Merriweather

local Theme = {
    Bg       = Color3.fromRGB(12, 7, 15),
    Sidebar  = Color3.fromRGB(16, 9, 19),
    Card     = Color3.fromRGB(24, 14, 28),
    CardHead = Color3.fromRGB(34, 19, 39),
    Field    = Color3.fromRGB(15, 9, 18),
    Border   = Color3.fromRGB(66, 36, 62),
    Text     = Color3.fromRGB(246, 232, 244),
    Muted    = Color3.fromRGB(148, 122, 150),
    Off      = Color3.fromRGB(54, 38, 58),
    Accent   = Color3.fromRGB(240, 130, 200),
    Accent2  = Color3.fromRGB(176, 92, 232),
}

local Presets = {
    Lilac  = { Color3.fromRGB(240,130,200), Color3.fromRGB(176,92,232) },
    Rose   = { Color3.fromRGB(255,110,140), Color3.fromRGB(255,160,110) },
    Violet = { Color3.fromRGB(150,110,255), Color3.fromRGB(100,150,255) },
    Ice    = { Color3.fromRGB(110,200,255), Color3.fromRGB(150,130,255) },
}

local Environments = {
    Default = Color3.fromRGB(9,8,13), Night = Color3.fromRGB(4,6,18),
    Soft = Color3.fromRGB(44,32,50),  Neon  = Color3.fromRGB(14,4,26),
}

local FontMap = { Gotham = Enum.Font.GothamMedium, Code = Enum.Font.Code, Merriweather = Enum.Font.Merriweather }

local Settings2, Defaults2, Controls2, Handlers2 = {}, {}, {}, {}
local TabKeys2 = {}
local bulk2 = false
local previewDirty2 = true

local function commit2(key, value)
    Settings2[key] = value; previewDirty2 = true
    local h = Handlers2[key]; if h then h(value) end
end

local function applySetting2(key, value)
    local c = Controls2[key]; if c then c.apply(value) end
    commit2(key, value)
end

local function create2(className, props, parent)
    local obj = Instance.new(className)
    if props then for k, v in pairs(props) do obj[k] = v end end
    if parent then obj.Parent = parent end
    return obj
end

local function corner2(parent, r) return create2("UICorner", {CornerRadius = UDim.new(0, r or 8)}, parent) end
local function round2(parent)     return create2("UICorner", {CornerRadius = UDim.new(1, 0)}, parent) end

local function stroke2(parent, color, thickness, transparency)
    return create2("UIStroke", {Color = color or Theme.Border, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent)
end

local function pad2(parent, t, r, b, l)
    return create2("UIPadding", {PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or t or 0), PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or r or t or 0)}, parent)
end

local function tween2(obj, props, dur, style)
    local t = TweenService2:Create(obj, TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play(); return t
end

local function text2(parent, str, size, color, font, align)
    return create2("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = str, TextSize = size,
        TextColor3 = color or Theme.Text, Font = font or BODY,
        TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, size + 6),
    }, parent)
end

local function contrast2(c)
    return (c.R*0.299 + c.G*0.587 + c.B*0.114) > 0.6 and Color3.fromRGB(20,10,24) or Color3.new(1,1,1)
end

local function hex2(c) return "#" .. c:ToHex():upper() end

local function pointer2(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        local inset = GuiService:GetGuiInset()
        return Vector2.new(i.Position.X + inset.X, i.Position.Y + inset.Y)
    end
    return UserInputService:GetMouseLocation()
end

local function isPress2(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove2(i)  return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function matchesBind2(i, name)
    if not name then return false end
    if i.UserInputType == Enum.UserInputType.Keyboard then return i.KeyCode.Name == name end
    return i.UserInputType.Name == name
end

local keyEnumCache2 = {}
local function bindDown2(name)
    if not name then return false end
    if name:sub(1,11) == "MouseButton" then
        local ok, ut = pcall(function() return Enum.UserInputType[name] end)
        return (ok and ut and UserInputService:IsMouseButtonPressed(ut)) or false
    end
    local kc = keyEnumCache2[name]
    if kc == nil then local ok, v = pcall(function() return Enum.KeyCode[name] end); kc = ok and v or false; keyEnumCache2[name] = kc end
    return (kc and UserInputService:IsKeyDown(kc)) or false
end

local accentBinds2 = {}
local function bindAccent2(fn) table.insert(accentBinds2, fn); fn() end
local function refreshAccent2() for _, fn in ipairs(accentBinds2) do fn() end end

local function makeIcon2(kind, parent)
    local holder = create2("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(20,20)}, parent)
    local fills2, strokes2 = {}, {}
    local function shape(o)
        local f = create2("Frame", {
            BackgroundTransparency = o.fill and 0 or 1, BackgroundColor3 = Theme.Muted, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromOffset(o.x, o.y),
            Size = UDim2.fromOffset(o.w, o.h), Rotation = o.rot or 0,
        }, holder)
        if o.round then round2(f) elseif o.r then corner2(f, o.r) end
        if o.fill then table.insert(fills2, f) else table.insert(strokes2, stroke2(f, Theme.Muted, o.th or 1.5)) end
    end
    if kind == "Combat" then
        shape({x=10,y=10,w=12,h=12,round=true,th=1.5}); shape({x=10,y=2.5,w=2,h=5,fill=true})
        shape({x=10,y=17.5,w=2,h=5,fill=true}); shape({x=2.5,y=10,w=5,h=2,fill=true})
        shape({x=17.5,y=10,w=5,h=2,fill=true}); shape({x=10,y=10,w=2.5,h=2.5,round=true,fill=true})
    elseif kind == "ESP" then
        shape({x=10,y=10,w=18,h=11,r=6,th=1.5}); shape({x=10,y=10,w=5,h=5,round=true,fill=true})
    elseif kind == "Visuals" then
        shape({x=10,y=10,w=11,h=11,r=2,th=1.5,rot=45}); shape({x=10,y=10,w=4,h=4,r=1,fill=true,rot=45})
    elseif kind == "World" then
        shape({x=10,y=10,w=16,h=16,round=true,th=1.5}); shape({x=10,y=10,w=16,h=1.5,fill=true})
        shape({x=10,y=10,w=7,h=16,round=true,th=1.2})
    elseif kind == "Character" then
        shape({x=10,y=5.5,w=7,h=7,round=true,th=1.5}); shape({x=10,y=14.5,w=14,h=7,r=4,th=1.5})
    elseif kind == "Misc" then
        for _, p in ipairs({{5,5},{15,5},{5,15},{15,15}}) do shape({x=p[1],y=p[2],w=7,h=7,r=2,th=1.5}) end
    elseif kind == "Settings" then
        shape({x=10,y=10,w=11,h=11,round=true,th=2}); shape({x=10,y=2,w=3,h=4,fill=true})
        shape({x=10,y=18,w=3,h=4,fill=true}); shape({x=2,y=10,w=4,h=3,fill=true}); shape({x=18,y=10,w=4,h=3,fill=true})
    elseif kind == "Rage" then
        shape({x=10,y=10,w=14,h=14,round=true,th=1.5}); shape({x=6,y=10,w=3,h=3,fill=true,round=true})
        shape({x=14,y=10,w=3,h=3,fill=true,round=true}); shape({x=10,y=6,w=3,h=3,fill=true,round=true})
    elseif kind == "Legit" then
        shape({x=10,y=10,w=12,h=16,r=3,th=1.5}); shape({x=10,y=6,w=7,h=7,round=true,th=1.5})
    end
    local function setColor2(c)
        for _, f in ipairs(fills2) do f.BackgroundColor3 = c end
        for _, s in ipairs(strokes2) do s.Color = c end
    end
    return holder, setColor2
end

local function chevron2(parent, pos)
    local h = create2("Frame", {BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=pos, Size=UDim2.fromOffset(10,10)}, parent)
    for _, d in ipairs({{3.2,45},{6.8,-45}}) do
        create2("Frame", {BackgroundColor3=Theme.Muted, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(d[1],4.5), Size=UDim2.fromOffset(6,1.6), Rotation=d[2]}, h)
    end
    return h
end

local function makeButton2(parent, label, w, h, primary)
    local b = create2("TextButton", {Text=label, Font=BODY, TextSize=11, AutoButtonColor=false,
        TextColor3 = primary and Color3.fromRGB(24,10,28) or Theme.Text,
        BackgroundColor3 = primary and Theme.Accent or Theme.CardHead,
        Size = UDim2.fromOffset(w, h), BorderSizePixel=0}, parent)
    corner2(b, 8)
    local s = stroke2(b, primary and Theme.Accent or Theme.Border, 1)
    bindAccent2(function() if primary then b.BackgroundColor3=Theme.Accent; s.Color=Theme.Accent end end)
    b.MouseEnter:Connect(function() tween2(b, {BackgroundTransparency=0.25}, 0.1) end)
    b.MouseLeave:Connect(function() tween2(b, {BackgroundTransparency=0}, 0.1) end)
    return b
end

local function dragInput2(guiObject, onPos, bag)
    bag = bag or connections2
    local active = false
    table.insert(bag, guiObject.InputBegan:Connect(function(i) if isPress2(i) then active=true; onPos(pointer2(i)) end end))
    table.insert(bag, UserInputService.InputChanged:Connect(function(i) if active and isMove2(i) then onPos(pointer2(i)) end end))
    table.insert(bag, UserInputService.InputEnded:Connect(function(i) if isPress2(i) then active=false end end))
end

-- Window
gui = create2("ScreenGui", {Name="LilacUI", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=1000}, playerGui)

local root2 = create2("Frame", {Name="Root", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(RW,RH), BackgroundTransparency=1}, gui)
local modalBtn2 = create2("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.fromOffset(0,0), Modal=true}, gui)
local uiScale2 = create2("UIScale", {}, root2)
local userScale2 = 1
local function fit2()
    local v = gui.AbsoluteSize; local s = math.min(1, (v.X-32)/RW, (v.Y-32)/RH)
    uiScale2.Scale = math.max(0.4, s) * userScale2
end
connect2(gui:GetPropertyChangedSignal("AbsoluteSize"), fit2); fit2()

local glowOuter2 = create2("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(-5,-5), Size=UDim2.fromOffset(MAIN_W+10,RH+10)}, root2)
corner2(glowOuter2, 20)
local glowOuterStroke2 = stroke2(glowOuter2, Theme.Accent, 7, 0.82)

local glowInner2 = create2("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(-2,-2), Size=UDim2.fromOffset(MAIN_W+4,RH+4)}, root2)
corner2(glowInner2, 17)
local glowInnerStroke2 = stroke2(glowInner2, Theme.Accent, 3, 0.6)

local main2 = create2("Frame", {Name="Main", BackgroundColor3=Color3.new(1,1,1), Size=UDim2.fromOffset(MAIN_W,RH), BorderSizePixel=0, ClipsDescendants=true}, root2)
corner2(main2, 15)
create2("UIGradient", {Rotation=90, Color=ColorSequence.new(Color3.fromRGB(19,10,23), Color3.fromRGB(10,6,13))}, main2)
local mainStroke2 = stroke2(main2, Theme.Accent, 1.5, 0.05)
bindAccent2(function() glowOuterStroke2.Color=Theme.Accent; glowInnerStroke2.Color=Theme.Accent; mainStroke2.Color=Theme.Accent end)

local fx2 = create2("Frame", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ClipsDescendants=true}, main2)
local petals2 = {}
for i = 1, 30 do
    local f = create2("Frame", {BackgroundColor3=Theme.Accent, BackgroundTransparency=0.5, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.fromOffset(math.random(7,11),math.random(5,8)), Visible=false}, fx2)
    corner2(f, 5)
    petals2[i] = {f=f, x=math.random(0,MAIN_W), y=math.random(-40,RH), vy=math.random(16,36), vx=math.random(-10,6), rot=math.random(0,360), vr=math.random(-60,60), ph=math.random()*6}
end
bindAccent2(function() for _, p in ipairs(petals2) do p.f.BackgroundColor3=Theme.Accent end end)

-- Sidebar
local sidebar2 = create2("Frame", {Name="Sidebar", BackgroundColor3=Theme.Sidebar, BackgroundTransparency=0.15, Size=UDim2.new(0,SIDEBAR_W,1,0), BorderSizePixel=0}, main2)
create2("Frame", {BackgroundColor3=Theme.Border, BackgroundTransparency=0.4, BorderSizePixel=0, Position=UDim2.new(1,-1,0,0), Size=UDim2.new(0,1,1,0)}, sidebar2)

local logo2 = create2("Frame", {BackgroundColor3=Theme.CardHead, Position=UDim2.fromOffset(14,13), Size=UDim2.fromOffset(38,38), BorderSizePixel=0}, sidebar2)
corner2(logo2, 11)
local logoStroke2 = stroke2(logo2, Theme.Accent, 1.2)
local logoText2 = text2(logo2, "L", 21, Theme.Accent, HEAD, Enum.TextXAlignment.Center)
logoText2.Size = UDim2.fromScale(1,1)
bindAccent2(function() logoStroke2.Color=Theme.Accent; logoText2.TextColor3=Theme.Accent end)

local brand2 = text2(sidebar2, "Lilac", 18, Theme.Text, HEAD)
brand2.Position = UDim2.fromOffset(62,12); brand2.Size = UDim2.new(1,-70,0,24)
local brandSub2 = text2(sidebar2, "PRIVATE BUILD  ·  v2.0", 8, Theme.Muted, LIGHT)
brandSub2.Position = UDim2.fromOffset(63,36); brandSub2.Size = UDim2.new(1,-70,0,14)

local navHolder2 = create2("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(12,78), Size=UDim2.new(1,-24,0,380)}, sidebar2)
create2("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, navHolder2)

local profile2 = create2("Frame", {BackgroundColor3=Theme.Card, Position=UDim2.new(0,12,1,-68), Size=UDim2.new(1,-24,0,54), BorderSizePixel=0}, sidebar2)
corner2(profile2, 12); stroke2(profile2, Theme.Border, 1, 0.2)
local avatar2 = create2("ImageLabel", {BackgroundColor3=Theme.CardHead, Position=UDim2.fromOffset(8,8), Size=UDim2.fromOffset(38,38), BorderSizePixel=0, Image=""}, profile2)
corner2(avatar2, 9)
task.spawn(function()
    local ok, img = pcall(function() return Players:GetUserThumbnailAsync(lp2.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
    if ok and avatar2.Parent then avatar2.Image = img end
end)
local pName2 = text2(profile2, lp2.DisplayName, 12, Theme.Text, BODY)
pName2.Position = UDim2.fromOffset(56,9); pName2.Size = UDim2.new(1,-62,0,18); pName2.TextTruncate = Enum.TextTruncate.AtEnd
local pSub2 = text2(profile2, "Rivals Private", 10, Theme.Muted, LIGHT)
pSub2.Position = UDim2.fromOffset(56,28); pSub2.Size = UDim2.new(1,-62,0,14)

-- Top bar
local dragBar2 = create2("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,56), Active=true}, main2)
local pageTitle2 = text2(main2, "Legit", 17, Theme.Text, HEAD)
pageTitle2.Position = UDim2.fromOffset(SIDEBAR_W+22,0); pageTitle2.Size = UDim2.fromOffset(120,56)

local searchBox2 = create2("TextBox", {Name="Search", Text="", PlaceholderText="Search settings...", ClearTextOnFocus=false, Font=LIGHT, TextSize=12, TextColor3=Theme.Text, PlaceholderColor3=Theme.Muted, TextXAlignment=Enum.TextXAlignment.Left, BackgroundColor3=Theme.Field, Position=UDim2.fromOffset(SIDEBAR_W+140,12), Size=UDim2.fromOffset(440,32), BorderSizePixel=0}, main2)
corner2(searchBox2, 10)
local searchStroke2 = stroke2(searchBox2, Theme.Border, 1)
pad2(searchBox2, 0, 10, 0, 36)
do
    local ring = create2("Frame", {BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(-19,15), Size=UDim2.fromOffset(10,10)}, searchBox2)
    round2(ring); stroke2(ring, Theme.Muted, 1.5)
    create2("Frame", {BackgroundColor3=Theme.Muted, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(-12.5,21), Size=UDim2.fromOffset(6,1.6), Rotation=45}, searchBox2)
end
connect2(searchBox2.Focused, function() tween2(searchStroke2, {Color=Theme.Accent}, 0.12) end)
connect2(searchBox2.FocusLost, function() tween2(searchStroke2, {Color=Theme.Border}, 0.12) end)

local function windowButton2(offsetX, kind)
    local b = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundColor3=Theme.CardHead, BackgroundTransparency=1, Position=UDim2.new(1,offsetX,0,13), Size=UDim2.fromOffset(30,30), BorderSizePixel=0}, main2)
    corner2(b, 8)
    local bars2 = {}
    local function bar(rot)
        local f = create2("Frame", {BackgroundColor3=Theme.Muted, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(12,1.6), Rotation=rot}, b)
        table.insert(bars2, f)
    end
    if kind == "close" then bar(45); bar(-45) else bar(0) end
    b.MouseEnter:Connect(function() tween2(b, {BackgroundTransparency=0}, 0.1); for _, f in ipairs(bars2) do f.BackgroundColor3=Theme.Text end end)
    b.MouseLeave:Connect(function() tween2(b, {BackgroundTransparency=1}, 0.1); for _, f in ipairs(bars2) do f.BackgroundColor3=Theme.Muted end end)
    return b
end
local closeButton2 = windowButton2(-44, "close")
local minButton2   = windowButton2(-78, "min")

local drag2 = {active=false}
connect2(dragBar2.InputBegan, function(i)
    if Settings2["set.lock"] then return end
    if isPress2(i) then drag2.active=true; drag2.start=Vector2.new(i.Position.X,i.Position.Y); drag2.origin=root2.Position end
end)
connect2(UserInputService.InputChanged, function(i)
    if drag2.active and isMove2(i) then
        local d = Vector2.new(i.Position.X,i.Position.Y) - drag2.start
        root2.Position = UDim2.new(drag2.origin.X.Scale, drag2.origin.X.Offset+d.X, drag2.origin.Y.Scale, drag2.origin.Y.Offset+d.Y)
    end
end)
connect2(UserInputService.InputEnded, function(i) if isPress2(i) then drag2.active=false end end)

local content2 = create2("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(SIDEBAR_W,0), Size=UDim2.fromOffset(CONTENT_W,RH)}, main2)
local moduleLabel2 = text2(content2, "", 11, Theme.Muted, LIGHT)
moduleLabel2.Position = UDim2.fromOffset(22,56); moduleLabel2.Size = UDim2.fromOffset(300,20)

local overlay2 = create2("Frame", {Name="Overlay", BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=100}, root2)
local catcher2 = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=50, Visible=false}, overlay2)

local popup2
local popupConns2 = {}
local function closePopup2()
    if popup2 then popup2:Destroy(); popup2 = nil end
    catcher2.Visible = false
    for _, c in ipairs(popupConns2) do c:Disconnect() end; table.clear(popupConns2)
end
catcher2.MouseButton1Click:Connect(closePopup2)

local function openPopup2(anchor, size, build)
    closePopup2(); catcher2.Visible = true
    local s = uiScale2.Scale
    local rel = (anchor.AbsolutePosition - root2.AbsolutePosition) / s
    local asz = anchor.AbsoluteSize / s
    local x = math.clamp(rel.X + asz.X - size.X, 8, RW - size.X - 8)
    local y = rel.Y + asz.Y + 6
    if y + size.Y > RH - 8 then y = rel.Y - size.Y - 6 end
    popup2 = create2("Frame", {BackgroundColor3=Theme.Card, Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(size.X,size.Y), BorderSizePixel=0, ZIndex=60}, overlay2)
    corner2(popup2, 11); stroke2(popup2, Theme.Accent, 1, 0.4)
    build(popup2)
    return popup2
end

local tipActive2 = false
local tipFrame2 = create2("Frame", {BackgroundColor3=Theme.CardHead, AutomaticSize=Enum.AutomaticSize.XY, Size=UDim2.fromOffset(0,0), Visible=false, ZIndex=300, BorderSizePixel=0}, gui)
corner2(tipFrame2, 7); stroke2(tipFrame2, Theme.Border, 1); pad2(tipFrame2, 6, 10, 6, 10)
local tipLabel2 = create2("TextLabel", {BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.XY, Size=UDim2.fromOffset(0,0), Font=LIGHT, TextSize=11, TextColor3=Theme.Text, Text=""}, tipFrame2)

local toastHolder2 = create2("Frame", {BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-20,1,-20), Size=UDim2.fromOffset(300,400)}, gui)
create2("UIListLayout", {VerticalAlignment=Enum.VerticalAlignment.Bottom, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, toastHolder2)

local toastCount2 = 0
local function notify2(title, msg)
    if Settings2["misc.notify"] == false then return end
    toastCount2 += 1
    local holder = create2("Frame", {BackgroundTransparency=1, Size=UDim2.fromOffset(290,56), LayoutOrder=toastCount2}, toastHolder2)
    local card2 = create2("Frame", {BackgroundColor3=Theme.Card, Position=UDim2.fromOffset(320,0), Size=UDim2.fromScale(1,1), BorderSizePixel=0}, holder)
    corner2(card2, 11); stroke2(card2, Theme.Border, 1)
    local bar2 = create2("Frame", {BackgroundColor3=Theme.Accent, Position=UDim2.fromOffset(8,12), Size=UDim2.new(0,3,1,-24), BorderSizePixel=0}, card2)
    round2(bar2)
    local t2 = text2(card2, title, 12, Theme.Text, HEAD); t2.Position=UDim2.fromOffset(22,8); t2.Size=UDim2.new(1,-30,0,18)
    local m2 = text2(card2, msg, 11, Theme.Muted, LIGHT); m2.Position=UDim2.fromOffset(22,28); m2.Size=UDim2.new(1,-30,0,16)
    tween2(card2, {Position=UDim2.fromOffset(0,0)}, 0.35)
    task.delay(3.2, function()
        if card2.Parent then tween2(card2, {Position=UDim2.fromOffset(320,0)}, 0.3); task.wait(0.32); holder:Destroy() end
    end)
end

local function confirm2(title, msg, yes)
    if not Settings2["set.confirm"] then yes(); return end
    closePopup2()
    local dim2 = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.45, Size=UDim2.fromScale(1,1), ZIndex=80, BorderSizePixel=0}, overlay2)
    local box2 = create2("Frame", {BackgroundColor3=Theme.Card, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(MAIN_W/2,RH/2), Size=UDim2.fromOffset(360,160), BorderSizePixel=0}, dim2)
    corner2(box2, 14); stroke2(box2, Theme.Accent, 1.2, 0.2)
    local t2 = text2(box2, title, 15, Theme.Text, HEAD); t2.Position=UDim2.fromOffset(20,16); t2.Size=UDim2.new(1,-40,0,24)
    local m2 = text2(box2, msg, 12, Theme.Muted, LIGHT); m2.Position=UDim2.fromOffset(20,46); m2.Size=UDim2.new(1,-40,0,40); m2.TextWrapped=true; m2.TextYAlignment=Enum.TextYAlignment.Top
    local no2 = makeButton2(box2, "Cancel", 100, 32, false); no2.AnchorPoint=Vector2.new(1,1); no2.Position=UDim2.new(1,-132,1,-16)
    local ok2 = makeButton2(box2, "Confirm", 100, 32, true); ok2.AnchorPoint=Vector2.new(1,1); ok2.Position=UDim2.new(1,-20,1,-16)
    no2.MouseButton1Click:Connect(function() dim2:Destroy() end)
    ok2.MouseButton1Click:Connect(function() dim2:Destroy(); yes() end)
end

-- Color picker
local quickColors2 = {
    Color3.fromRGB(255,255,255), Color3.fromRGB(240,130,200), Color3.fromRGB(176,92,232),
    Color3.fromRGB(100,170,255), Color3.fromRGB(255,80,80), Color3.fromRGB(120,230,140),
    Color3.fromRGB(255,210,90), Color3.fromRGB(20,20,24),
}

local function openColorPicker2(anchor, key)
    local h2, s2, v2 = Settings2[key]:ToHSV()
    local pop = openPopup2(anchor, Vector2.new(214,240), function() end)
    local svBox = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundColor3=Color3.fromHSV(h2,1,1), Position=UDim2.fromOffset(12,12), Size=UDim2.fromOffset(190,120), BorderSizePixel=0}, pop)
    corner2(svBox, 8)
    local white2 = create2("Frame", {BackgroundColor3=Color3.new(1,1,1), Size=UDim2.fromScale(1,1), BorderSizePixel=0}, svBox); corner2(white2, 8)
    create2("UIGradient", {Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})}, white2)
    local black2 = create2("Frame", {BackgroundColor3=Color3.new(0,0,0), Size=UDim2.fromScale(1,1), BorderSizePixel=0}, svBox); corner2(black2, 8)
    create2("UIGradient", {Rotation=90, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})}, black2)
    local svKnob = create2("Frame", {BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.fromOffset(11,11)}, svBox); round2(svKnob); stroke2(svKnob, Color3.new(1,1,1), 2)
    local hueBar = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundColor3=Color3.new(1,1,1), Position=UDim2.fromOffset(12,142), Size=UDim2.fromOffset(190,12), BorderSizePixel=0}, pop)
    round2(hueBar)
    local kps2 = {}; for i = 0, 6 do table.insert(kps2, ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6==1 and 0.999 or i/6,1,1))) end
    create2("UIGradient", {Color=ColorSequence.new(kps2)}, hueBar)
    local hueKnob = create2("Frame", {BackgroundColor3=Color3.new(1,1,1), AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.fromOffset(6,18), BorderSizePixel=0}, hueBar)
    corner2(hueKnob, 3); stroke2(hueKnob, Color3.fromRGB(20,10,24), 1)
    local hexBox = create2("TextBox", {Text=hex2(Settings2[key]), ClearTextOnFocus=false, Font=BODY, TextSize=11, TextColor3=Theme.Text, BackgroundColor3=Theme.Field, Position=UDim2.fromOffset(12,166), Size=UDim2.fromOffset(110,26), BorderSizePixel=0}, pop)
    corner2(hexBox, 7); stroke2(hexBox, Theme.Border, 1)
    local prev = create2("Frame", {BackgroundColor3=Settings2[key], Position=UDim2.fromOffset(130,166), Size=UDim2.fromOffset(72,26), BorderSizePixel=0}, pop); corner2(prev, 7)
    local function update2(fromHex)
        local c2 = Color3.fromHSV(h2,s2,v2)
        svBox.BackgroundColor3 = Color3.fromHSV(h2,1,1); svKnob.Position = UDim2.fromScale(s2,1-v2); hueKnob.Position = UDim2.fromScale(h2,0.5)
        prev.BackgroundColor3 = c2; if not fromHex then hexBox.Text = hex2(c2) end; applySetting2(key, c2)
    end
    dragInput2(svBox, function(p) s2=math.clamp((p.X-svBox.AbsolutePosition.X)/svBox.AbsoluteSize.X,0,1); v2=1-math.clamp((p.Y-svBox.AbsolutePosition.Y)/svBox.AbsoluteSize.Y,0,1); update2() end, popupConns2)
    dragInput2(hueBar, function(p) h2=math.clamp((p.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,0.999); update2() end, popupConns2)
    table.insert(popupConns2, hexBox.FocusLost:Connect(function()
        local ok2, c2 = pcall(Color3.fromHex, hexBox.Text)
        if ok2 and c2 then h2,s2,v2 = c2:ToHSV(); update2(false) else hexBox.Text = hex2(Settings2[key]) end
    end))
    for i, qc in ipairs(quickColors2) do
        local q = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundColor3=qc, Position=UDim2.fromOffset(12+(i-1)*24,205), Size=UDim2.fromOffset(20,20), BorderSizePixel=0}, pop)
        round2(q); stroke2(q, Theme.Border, 1)
        q.MouseButton1Click:Connect(function() h2,s2,v2 = qc:ToHSV(); update2() end)
    end
    update2()
end

-- Live preview (simplified — character model only, no full scope needed)
local preview2, previewGlow2, previewGlowStroke2, char2, parts2
local renderPreview2, updatePreviewVisible2
do
    local SW, SH = 240, 504; local PH = 560
    previewGlow2 = create2("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(MAIN_W+14-3,-3), Size=UDim2.fromOffset(PREVIEW_W+6,PH+6)}, root2)
    corner2(previewGlow2, 17); previewGlowStroke2 = stroke2(previewGlow2, Theme.Accent, 6, 0.84)
    preview2 = create2("Frame", {Name="Preview", BackgroundColor3=Theme.Bg, Position=UDim2.fromOffset(MAIN_W+14,0), Size=UDim2.fromOffset(PREVIEW_W,PH), BorderSizePixel=0, ClipsDescendants=true}, root2)
    corner2(preview2, 14)
    local prevStroke = stroke2(preview2, Theme.Accent, 1.5, 0.05)
    bindAccent2(function() previewGlowStroke2.Color=Theme.Accent; prevStroke.Color=Theme.Accent end)
    do local ic, setIc = makeIcon2("Misc", preview2); ic.Position=UDim2.fromOffset(14,13); bindAccent2(function() setIc(Theme.Accent) end) end
    local pvTitle = text2(preview2, "Live Preview", 13, Theme.Text, HEAD); pvTitle.Position=UDim2.fromOffset(42,8); pvTitle.Size=UDim2.new(1,-90,0,28)
    local pvMin = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-8,0,8), Size=UDim2.fromOffset(28,28)}, preview2)
    create2("Frame", {BackgroundColor3=Theme.Muted, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(11,1.6)}, pvMin)
    local screen2 = create2("Frame", {BackgroundColor3=Environments.Default, Position=UDim2.fromOffset(10,46), Size=UDim2.fromOffset(SW,SH), BorderSizePixel=0, ClipsDescendants=true}, preview2)
    corner2(screen2, 11); stroke2(screen2, Theme.Border, 1)
    text2(screen2, "LILAC · PREVIEW", 8, Theme.Muted, BOLD).Position=UDim2.fromOffset(10,8)

    char2 = create2("Frame", {Name="Char", BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(SW/2,SH/2+6), Size=UDim2.fromOffset(150,180), ZIndex=3}, screen2)
    local charScale2 = create2("UIScale", {}, char2)
    parts2 = {}
    local function part2(name, x, y, w, h, r)
        local f = create2("Frame", {Name=name, Position=UDim2.fromOffset(x,y), Size=UDim2.fromOffset(w,h), BorderSizePixel=0}, char2)
        corner2(f, r); local st = stroke2(f, Color3.new(1,1,1), 1.5); st.Enabled=false; parts2[name]={frame=f,stroke=st}; return f
    end
    part2("legL",46,108,28,70,3); part2("legR",76,108,28,70,3); part2("torso",44,38,62,68,3)
    local armL2 = part2("armL",21,38,22,68,3); local armR2 = part2("armR",107,38,22,68,3)
    local head2 = part2("head",57,0,36,36,7)
    for _, ex in ipairs({9,23}) do
        local eye = create2("Frame", {BackgroundColor3=Color3.fromRGB(18,14,22), Position=UDim2.fromOffset(ex,19), Size=UDim2.fromOffset(4,5), BorderSizePixel=0}, head2)
        corner2(eye, 2)
    end

    renderPreview2 = function()
        local S2 = Settings2
        local sc = (S2["char.scale"] or 100) / 100
        charScale2.Scale = sc
        local function setPartColor(name, color)
            if parts2[name] then parts2[name].frame.BackgroundColor3 = color end
        end
        setPartColor("torso", S2["char.shirt"] or Color3.fromRGB(24,22,30))
        setPartColor("legL",  S2["char.pants"] or Color3.fromRGB(70,76,66))
        setPartColor("legR",  S2["char.pants"] or Color3.fromRGB(70,76,66))
        setPartColor("armL",  S2["char.shirt"] or Color3.fromRGB(24,22,30))
        setPartColor("armR",  S2["char.shirt"] or Color3.fromRGB(24,22,30))
        setPartColor("head",  S2["char.skin"]  or Color3.fromRGB(226,190,150))
        if S2["world.env"] then screen2.BackgroundColor3 = Environments[S2["world.env"]] or Environments.Default end
    end

    updatePreviewVisible2 = function()
        local show = Settings2["set.preview"]
        preview2.Visible = show; previewGlow2.Visible = show
    end

    pvMin.MouseButton1Click:Connect(function()
        preview2.Visible = not preview2.Visible
        previewGlow2.Visible = preview2.Visible
    end)
end

-- Rows
local allRows2 = {}
local cardFrames2 = {}
local buildingKeys2

local function reg2(def)
    Settings2[def.key] = def.default; Defaults2[def.key] = def.default
    if buildingKeys2 then table.insert(buildingKeys2, def.key) end
end

local function makeRow2(body, def)
    local height = def.type == "config" and 84 or 36
    local row = create2("Frame", {Name=def.name or def.type, BackgroundColor3=Theme.Accent, BackgroundTransparency=1, Size=UDim2.new(1,0,0,height), BorderSizePixel=0}, body)
    bindAccent2(function() row.BackgroundColor3=Theme.Accent end)
    row:SetAttribute("Search", ((def.name or "").." "..(def.tip or "")):lower())
    table.insert(allRows2, {frame=row, base=height})
    create2("Frame", {BackgroundColor3=Theme.Border, BackgroundTransparency=0.7, BorderSizePixel=0, Position=UDim2.new(0,12,1,-1), Size=UDim2.new(1,-24,0,1)}, row)
    row.MouseEnter:Connect(function()
        tween2(row, {BackgroundTransparency=0.93}, 0.12)
        if Settings2["misc.tips"] and def.tip and def.tip ~= "" then tipLabel2.Text=def.tip; tipFrame2.Visible=true; tipActive2=true end
    end)
    row.MouseLeave:Connect(function() tween2(row, {BackgroundTransparency=1}, 0.12); tipActive2=false; tipFrame2.Visible=false end)
    if def.type ~= "config" then
        local lbl = text2(row, def.name, 12, Theme.Text, BODY); lbl.Position=UDim2.fromOffset(14,0); lbl.Size=UDim2.new(0.42,-14,1,0)
    end

    local kind = def.type; local key = def.key

    if kind == "toggle" then
        reg2(def)
        local track = create2("TextButton", {Text="", AutoButtonColor=false, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0), Size=UDim2.fromOffset(40,20), BorderSizePixel=0, BackgroundColor3=Theme.Off}, row)
        round2(track)
        local glow = stroke2(track, Theme.Accent, 3, 1)
        local knob = create2("Frame", {BackgroundColor3=Color3.new(1,1,1), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0), Size=UDim2.fromOffset(14,14), BorderSizePixel=0}, track)
        round2(knob)
        local function render(v)
            tween2(track, {BackgroundColor3 = v and Theme.Accent or Theme.Off})
            tween2(knob, {Position = v and UDim2.new(1,-17,0.5,0) or UDim2.new(0,3,0.5,0)})
            tween2(glow, {Transparency = v and 0.72 or 1})
        end
        Controls2[key] = {apply=render}
        bindAccent2(function()
            track.BackgroundColor3 = Settings2[key] and Theme.Accent or Theme.Off
            glow.Color = Theme.Accent
            knob.Position = Settings2[key] and UDim2.new(1,-17,0.5,0) or UDim2.new(0,3,0.5,0)
            glow.Transparency = Settings2[key] and 0.72 or 1
        end)
        track.MouseButton1Click:Connect(function()
            local v = not Settings2[key]; render(v); commit2(key, v)
        end)

    elseif kind == "slider" then
        reg2(def)
        local mn, mx, step = def.min, def.max, def.step or 1
        local function fmt(v) return step >= 1 and tostring(math.floor(v+0.5)) or string.format("%.1f", v) end
        local bx = create2("TextBox", {Text=fmt(def.default), ClearTextOnFocus=false, Font=BODY, TextSize=11, TextColor3=Theme.Text, BackgroundColor3=Theme.Field, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0), Size=UDim2.fromOffset(46,24), BorderSizePixel=0}, row)
        corner2(bx, 7); stroke2(bx, Theme.Border, 1)
        local tPos = UDim2.new(0.42,0,0.5,0); local tSize = UDim2.new(0.58,-84,0,6)
        local trk = create2("Frame", {BackgroundColor3=Theme.Off, AnchorPoint=Vector2.new(0,0.5), Position=tPos, Size=tSize, BorderSizePixel=0}, row); round2(trk)
        local fill2 = create2("Frame", {BackgroundColor3=Color3.new(1,1,1), Size=UDim2.fromScale(0,1), BorderSizePixel=0}, trk); round2(fill2)
        local grad2 = create2("UIGradient", {}, fill2)
        local knob2 = create2("Frame", {BackgroundColor3=Color3.new(1,1,1), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0,0.5), Size=UDim2.fromOffset(13,13), BorderSizePixel=0}, trk); round2(knob2)
        local kglow2 = stroke2(knob2, Theme.Accent, 3, 0.6)
        bindAccent2(function() grad2.Color=ColorSequence.new(Theme.Accent2,Theme.Accent); kglow2.Color=Theme.Accent end)
        local hit = create2("TextButton", {Text="", BackgroundTransparency=1, AnchorPoint=Vector2.new(0,0.5), Position=tPos, Size=UDim2.new(0.58,-84,0,26)}, row)
        local function render2(v) local frac=(v-mn)/(mx-mn); fill2.Size=UDim2.fromScale(frac,1); knob2.Position=UDim2.fromScale(frac,0.5); bx.Text=fmt(v) end
        local function snap2(v) v=mn+math.floor((v-mn)/step+0.5)*step; v=math.clamp(v,mn,mx); return math.floor(v*1000+0.5)/1000 end
        Controls2[key] = {apply=render2}; render2(def.default)
        dragInput2(hit, function(p)
            local frac = math.clamp((p.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1)
            local v = snap2(mn+frac*(mx-mn)); if v ~= Settings2[key] then render2(v); commit2(key,v) end
        end)
        connect2(bx.FocusLost, function()
            local n = tonumber(bx.Text); if n then n=snap2(n); render2(n); commit2(key,n) else render2(Settings2[key]) end
        end)

    elseif kind == "dropdown" then
        reg2(def)
        local opts = def.options
        local btn2 = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundColor3=Theme.Field, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0), Size=UDim2.fromOffset(128,26), BorderSizePixel=0}, row)
        corner2(btn2, 8); stroke2(btn2, Theme.Border, 1)
        local lab2 = text2(btn2, def.default, 11, Theme.Text, BODY); lab2.Position=UDim2.fromOffset(11,0); lab2.Size=UDim2.new(1,-30,1,0)
        chevron2(btn2, UDim2.new(1,-15,0.5,0))
        Controls2[key] = {apply=function(v) lab2.Text=v end}
        btn2.MouseButton1Click:Connect(function()
            openPopup2(btn2, Vector2.new(140,#opts*28+10), function(pop2)
                local list2 = create2("Frame", {BackgroundTransparency=1, Position=UDim2.fromOffset(5,5), Size=UDim2.new(1,-10,1,-10)}, pop2)
                create2("UIListLayout", {}, list2)
                for _, o in ipairs(opts) do
                    local ob = create2("TextButton", {Text=o, Font=BODY, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=(o==Settings2[key]) and Theme.Accent or Theme.Text, AutoButtonColor=false, BackgroundColor3=Theme.CardHead, BackgroundTransparency=1, Size=UDim2.new(1,0,0,28), BorderSizePixel=0}, list2)
                    corner2(ob,7); pad2(ob,0,8,0,10)
                    ob.MouseEnter:Connect(function() tween2(ob,{BackgroundTransparency=0.2},0.08) end)
                    ob.MouseLeave:Connect(function() tween2(ob,{BackgroundTransparency=1},0.08) end)
                    ob.MouseButton1Click:Connect(function() lab2.Text=o; commit2(key,o); closePopup2() end)
                end
            end)
        end)

    elseif kind == "color" then
        reg2(def)
        local sw2 = create2("TextButton", {Text=hex2(def.default), AutoButtonColor=false, Font=BOLD, TextSize=10, BackgroundColor3=def.default, TextColor3=contrast2(def.default), AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0), Size=UDim2.fromOffset(84,24), BorderSizePixel=0}, row)
        corner2(sw2, 8)
        local swGlow2 = stroke2(sw2, def.default, 3, 0.75)
        Controls2[key] = {apply=function(c) sw2.BackgroundColor3=c; sw2.Text=hex2(c); sw2.TextColor3=contrast2(c); swGlow2.Color=c end}
        sw2.MouseButton1Click:Connect(function() openColorPicker2(sw2, key) end)

    elseif kind == "keybind" then
        reg2(def)
        local kbtn = create2("TextButton", {Text=Settings2[key], AutoButtonColor=false, Font=BODY, TextSize=11, TextColor3=Theme.Text, BackgroundColor3=Theme.Field, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0), Size=UDim2.fromOffset(128,26), BorderSizePixel=0}, row)
        corner2(kbtn, 8); stroke2(kbtn, Theme.Border, 1)
        Controls2[key] = {apply=function(v) kbtn.Text=v end}
        kbtn.MouseButton1Click:Connect(function() _G.__LilacBinding=true; _G.__LilacBindStart=os.clock(); kbtn.Text="press a key..." end)
        connect2(UserInputService.InputBegan, function(i)
            if not _G.__LilacBinding or kbtn.Text ~= "press a key..." then return end
            local name; local ut = i.UserInputType
            if ut == Enum.UserInputType.Keyboard then name = i.KeyCode.Name
            elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then name = ut.Name end
            if not name then return end
            if os.clock() - (_G.__LilacBindStart or 0) < 0.15 then return end
            _G.__LilacBinding = false; _G.__LilacBindTime = os.clock()
            if name == "Escape" then kbtn.Text = Settings2[key] else kbtn.Text=name; commit2(key,name) end
        end)

    elseif kind == "button" then
        local b2 = makeButton2(row, def.label or def.name, 128, 26, def.primary)
        b2.AnchorPoint = Vector2.new(1,0.5); b2.Position = UDim2.new(1,-14,0.5,0)
        b2.MouseButton1Click:Connect(function() def.fn() end)

    elseif kind == "config" then
        local tb = create2("TextBox", {Text="", PlaceholderText="Export to generate a config string, or paste one and press Import", PlaceholderColor3=Theme.Muted, ClearTextOnFocus=false, TextTruncate=Enum.TextTruncate.AtEnd, Font=Enum.Font.Code, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Theme.Text, BackgroundColor3=Theme.Field, Position=UDim2.fromOffset(12,8), Size=UDim2.new(1,-24,0,30), BorderSizePixel=0}, row)
        corner2(tb, 8); stroke2(tb, Theme.Border, 1); pad2(tb, 0, 10, 0, 10)
        local exp2 = makeButton2(row, "Export", 100, 26, false); exp2.Position=UDim2.fromOffset(12,48)
        local imp2 = makeButton2(row, "Import", 100, 26, true); imp2.Position=UDim2.fromOffset(120,48)
        def.hook(tb, exp2, imp2)
    end
    return row
end

-- Cards + Pages
local pages2 = {}
local currentTab2 = "Legit"

local function buildCard2(col, def)
    local card2 = create2("Frame", {Name=def.title, BackgroundColor3=Theme.Card, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BorderSizePixel=0, LayoutOrder=def.order or 1}, col)
    corner2(card2, 12); stroke2(card2, Theme.Border, 1, 0.1)
    create2("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder}, card2)
    table.insert(cardFrames2, card2)
    local header = create2("Frame", {BackgroundColor3=Theme.CardHead, Size=UDim2.new(1,0,0,40), BorderSizePixel=0, LayoutOrder=1}, card2)
    corner2(header, 12)
    create2("Frame", {BackgroundColor3=Theme.CardHead, BorderSizePixel=0, Position=UDim2.new(0,0,1,-12), Size=UDim2.new(1,0,0,12)}, header)
    local dia = create2("Frame", {BackgroundColor3=Theme.Accent, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(20,20), Size=UDim2.fromOffset(7,7), Rotation=45}, header)
    corner2(dia, 1); bindAccent2(function() dia.BackgroundColor3=Theme.Accent end)
    local title2 = text2(header, def.title, 13, Theme.Text, HEAD); title2.Position=UDim2.fromOffset(36,0); title2.Size=UDim2.new(1,-80,1,0)
    local obj2 = {frame=card2, title=def.title, bodies={}, active=1, searching=false, collapsed=false}
    local strip2; local pills2 = {}
    local function newBody2(order)
        local b = create2("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=order}, card2)
        create2("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder}, b); pad2(b, 4, 0, 6, 0); return b
    end
    obj2.layout = function()
        for i, b in ipairs(obj2.bodies) do
            local show; if obj2.collapsed then show=false elseif obj2.searching then show=b.hit else show=(i==obj2.active) end
            b.frame.Visible = show
        end
        if strip2 then strip2.Visible = (not obj2.collapsed) and (not obj2.searching) end
    end
    local function styleBody2(tbl, rows)
        for _, r in ipairs(rows) do table.insert(tbl.rows, makeRow2(tbl.frame, r)) end
    end
    if def.tabs then
        strip2 = create2("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,36), LayoutOrder=2}, card2)
        pad2(strip2, 6, 10, 0, 10)
        create2("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, strip2)
        local function stylePills2()
            for i, p in ipairs(pills2) do
                local a = i==obj2.active
                p.btn.TextColor3 = a and Theme.Accent or Theme.Muted
                p.btn.BackgroundColor3 = a and Theme.CardHead or Theme.Field
                p.stroke.Color = a and Theme.Accent or Theme.Border
                p.stroke.Transparency = a and 0.15 or 0
            end
        end
        for i, tdef in ipairs(def.tabs) do
            local body2 = {frame=newBody2(2+i), rows={}, hit=false}
            table.insert(obj2.bodies, body2); styleBody2(body2, tdef.rows)
            local pill2 = create2("TextButton", {Text=tdef.name, Font=BODY, TextSize=9, AutoButtonColor=false, Size=UDim2.fromOffset(#tdef.name*5.6+18,24), BorderSizePixel=0, LayoutOrder=i}, strip2)
            round2(pill2)
            local ps2 = stroke2(pill2, Theme.Border, 1)
            table.insert(pills2, {btn=pill2, stroke=ps2})
            pill2.MouseButton1Click:Connect(function() obj2.active=i; stylePills2(); obj2.layout() end)
        end
        bindAccent2(stylePills2)
    else
        local body2 = {frame=newBody2(3), rows={}, hit=false}; table.insert(obj2.bodies, body2); styleBody2(body2, def.rows)
    end
    obj2.layout()
    local cb = create2("TextButton", {Text="", AutoButtonColor=false, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0), Size=UDim2.fromOffset(28,28)}, header)
    create2("Frame", {BackgroundColor3=Theme.Muted, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(11,1.6)}, cb)
    local v1 = create2("Frame", {BackgroundColor3=Theme.Muted, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(1.6,11), Visible=false}, cb)
    cb.MouseButton1Click:Connect(function() obj2.collapsed=not obj2.collapsed; v1.Visible=obj2.collapsed; obj2.layout() end)
    return obj2
end

local function buildPage2(name, cardDefs)
    local scroll2 = create2("ScrollingFrame", {Name=name, BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromOffset(22,84), Size=UDim2.new(1,-44,1,-96), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, ScrollingDirection=Enum.ScrollingDirection.Y, ElasticBehavior=Enum.ElasticBehavior.Never, Visible=false}, content2)
    bindAccent2(function() scroll2.ScrollBarImageColor3=Theme.Accent end)
    local wrap2 = create2("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,-12,0,0), AutomaticSize=Enum.AutomaticSize.Y}, scroll2)
    pad2(wrap2, 2, 0, 16, 0)
    local cols2 = {}
    for i = 1, 2 do
        cols2[i] = create2("Frame", {BackgroundTransparency=1, Position=UDim2.new((i-1)*0.5,(i-1)*6,0,0), Size=UDim2.new(0.5,-6,0,0), AutomaticSize=Enum.AutomaticSize.Y}, wrap2)
        create2("UIListLayout", {Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder}, cols2[i])
    end
    local empty2 = text2(scroll2, "No settings match your search.", 12, Theme.Muted, LIGHT, Enum.TextXAlignment.Center)
    empty2.Position = UDim2.fromOffset(0,40); empty2.Visible = false
    local page2 = {scroll=scroll2, cards={}, empty=empty2, count=#cardDefs}
    buildingKeys2 = {}; TabKeys2[name] = buildingKeys2
    for _, cd in ipairs(cardDefs) do table.insert(page2.cards, buildCard2(cols2[cd.col or 1], cd)) end
    buildingKeys2 = nil; pages2[name] = page2
end

local function applySearch2(page2, q)
    if not page2 then return end; q = q:lower()
    local searching = q ~= ""; local visibleCards = 0
    for _, card2 in ipairs(page2.cards) do
        local titleHit = searching and card2.title:lower():find(q,1,true) ~= nil; local any = false
        for _, b in ipairs(card2.bodies) do
            b.hit = false
            for _, r in ipairs(b.rows) do
                local m = (not searching) or titleHit or ((r:GetAttribute("Search") or ""):find(q,1,true) ~= nil)
                r.Visible = m; if m then b.hit = true end
            end
            if b.hit then any = true end
        end
        card2.searching = searching; card2.frame.Visible = (not searching) or any; card2.layout()
        if card2.frame.Visible then visibleCards += 1 end
    end
    page2.empty.Visible = visibleCards == 0
end

connect2(searchBox2:GetPropertyChangedSignal("Text"), function() applySearch2(pages2[currentTab2], searchBox2.Text) end)

local tabOrder2 = {"Legit","Rage","Visuals","World","Character","Misc","Settings"}

local function resetKeys2(keys) bulk2=true; for _, k in ipairs(keys) do applySetting2(k, Defaults2[k]) end; bulk2=false end
local function resetAll2() local keys={}; for k in pairs(Defaults2) do table.insert(keys,k) end; resetKeys2(keys) end

local function serialize2()
    local out = {}
    for k, v in pairs(Settings2) do
        local t = typeof(v)
        if t == "Color3" then out[k] = hex2(v) elseif t == "EnumItem" then out[k] = v.Name else out[k] = v end
    end
    return HttpService:JSONEncode(out)
end

local function importConfig2(str)
    local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
    if not ok or type(data) ~= "table" then return false end
    bulk2 = true
    for k, v in pairs(data) do
        local cur = Settings2[k]
        if cur ~= nil then
            local t = typeof(cur)
            if t == "Color3" and type(v) == "string" then local ok2,c2 = pcall(Color3.fromHex,v); if ok2 and c2 then applySetting2(k,c2) end
            elseif t == "EnumItem" and type(v) == "string" then local ok2,kc = pcall(function() return Enum.KeyCode[v] end); if ok2 and kc then applySetting2(k,kc) end
            elseif t == type(v) and (t=="boolean" or t=="number" or t=="string") then applySetting2(k,v) end
        end
    end
    bulk2 = false; return true
end

-- ────────────────────────────────────────────────────────────
-- SECTION 10: Page definitions wired to noragebot callbacks
-- ────────────────────────────────────────────────────────────
local function T2(key,name,default,tip) return {type="toggle",key=key,name=name,default=default,tip=tip} end
local function S2(key,name,min,max,default,tip,step) return {type="slider",key=key,name=name,min=min,max=max,default=default,tip=tip,step=step} end
local function C2(key,name,default,tip) return {type="color",key=key,name=name,default=default,tip=tip} end
local function D2(key,name,options,tip) return {type="dropdown",key=key,name=name,options=options,default=options[1],tip=tip} end
local function B2(name,label,fn,tip,primary) return {type="button",name=name,label=label,fn=fn,tip=tip,primary=primary} end
local rgb2 = Color3.fromRGB

-- Handlers wired to noragebot S table
Handlers2["legit.aimbot"]       = function(v) toggleAimbot(v) end
Handlers2["legit.aimfov"]       = function(v) S.aimFov = v end
Handlers2["legit.aimsmooth"]    = function(v) S.aimSmooth = v end
Handlers2["legit.aimpart"]      = function(v) S.aimTargetPart = v end
Handlers2["legit.teamcheck"]    = function(v) S.teamCheck = v end
Handlers2["legit.aimfovcolor"]  = function(v) S.aimFovColor = v end
Handlers2["legit.showfov"]      = function(v) S.showFovCircles = v end
Handlers2["legit.fovstyle"]     = function(v) S.fovStyle = v end
Handlers2["legit.triggerbot"]   = function(v) toggleTriggerbot(v) end
Handlers2["legit.trigdelay"]    = function(v) S.triggerbotDelay = v end
Handlers2["legit.trigwall"]     = function(v) S.triggerbotWallCheck = v end
Handlers2["legit.trigteam"]     = function(v) S.triggerbotTeamCheck = v end
Handlers2["legit.trigads"]      = function(v) S.triggerbotOnlyADS = v end
Handlers2["legit.silentaim"]    = function(v) toggleSilentAim(v) end
Handlers2["legit.silentfov"]    = function(v) S.silentFov = v end
Handlers2["legit.silentpart"]   = function(v) S.silentTargetPart = v end
Handlers2["legit.silentnpc"]    = function(v) S.silentTargetNPC = v end
Handlers2["legit.wallcheck"]    = function(v) S.wallCheck = v end
Handlers2["legit.silfovcolor"]  = function(v) S.silentFovColor = v end
Handlers2["legit.antikatana"]   = function(v) getgenv().SetAntiKatana(v) end
Handlers2["rage.void"]          = function(v) toggleVoid(v) end
Handlers2["rage.noclip"]        = function(v) toggleNoclip(v) end
Handlers2["rage.fly"]           = function(v) toggleFly(v) end
Handlers2["rage.flyspeed"]      = function(v) S.flySpeed=v end
Handlers2["rage.fist"]          = function(v) toggleFist(v) end
Handlers2["rage.riot"]          = function(v) toggleRiot(v) end
Handlers2["rage.scythe"]        = function(v) toggleScythe(v) end
Handlers2["rage.wallbang"]      = function(v) toggleWallbang(v) end
Handlers2["rage.wallbanghead"]  = function(v) toggleWallbangHead(v) end
Handlers2["rage.backstab"]      = function(v) AlwaysBackstabModule.SetEnabled(v) end
Handlers2["rage.antiaim"]       = function(v) if v then _G.StartAntiAimExt() else _G.StopAntiAimExt() end end
Handlers2["rage.yawtype"]       = function(v) _G.AntiAimSettings.yawtype=v end
Handlers2["rage.pitchtype"]     = function(v) _G.AntiAimSettings.pitchtype=v end
Handlers2["rage.angletype"]     = function(v) _G.AntiAimSettings.angletype=v end
Handlers2["rage.customangle"]   = function(v) _G.AntiAimSettings.customangle=v end
Handlers2["rage.minspeed"]      = function(v) _G.AntiAimSettings.minspeed=v end
Handlers2["rage.maxspeed"]      = function(v) _G.AntiAimSettings.maxspeed=v end
Handlers2["rage.minangle"]      = function(v) _G.AntiAimSettings.minangle=v end
Handlers2["rage.maxangle"]      = function(v) _G.AntiAimSettings.maxangle=v end
Handlers2["rage.randomangle"]   = function(v) _G.AntiAimSettings.randomangle=v end
Handlers2["rage.irregularmove"] = function(v) S.irregularMoveActive=v; if v then startIrregularMove() else stopIrregularMove() end end
Handlers2["rage.underground"]   = function(v) toggleUnderground(v) end
Handlers2["rage.ugdepth"]       = function(v) S.undergroundDepth=v; _G.SetUndergroundDepthExt(v) end
Handlers2["misc.speed"]         = function(v) S.speedEnabled=v; setSpeed(nil) end
Handlers2["misc.speedval"]      = function(v) setSpeed(v) end
Handlers2["misc.infjump"]       = function(v) S.infiniteJumpActive=v end
Handlers2["misc.slideboost"]    = function(v) SlideBoostModule.setSlideBoost(v, _G.Features.SlideBoost.Speed) end
Handlers2["misc.slidespeed"]    = function(v) _G.Features.SlideBoost.Speed=v; if _G.Features.SlideBoost.Enabled then SlideBoostModule.setSlideBoost(true,v) end end
Handlers2["misc.rapidfire"]     = function(v) toggleRapidFire(v) end
Handlers2["misc.firedelay"]     = function(v) S.fireDelay=v; if S.rapidFireActive then applyRapidFire() end end
Handlers2["misc.instantads"]    = function(v) S.instantAdsEnabled=v; applyGunEnhancements() end
Handlers2["misc.noequipanim"]   = function(v) S.noEquipAnimEnabled=v; applyGunEnhancements() end
Handlers2["misc.noshootanim"]   = function(v) S.noShootAnimEnabled=v; applyGunEnhancements() end
Handlers2["misc.nospread"]      = function(v) S.noSpreadEnabled=v; patchGunSpread() end
Handlers2["misc.nosmoke"]       = function(v) S.noSmokeEnabled=v; applyNoSmoke() end
Handlers2["misc.noflash"]       = function(v) S.noFlashEnabled=v; applyNoFlash() end
Handlers2["misc.devspoof"]      = function(v) S.deviceSpoofEnabled=v; applyDeviceSpoof() end
Handlers2["misc.spoofas"]       = function(v) S.spoofDevice=v; if S.deviceSpoofEnabled then applyDeviceSpoof() end end

-- ESP handlers → Lilac ESP (live.esp + esp.* keys handled by the feature loop below)

buildPage2("Legit", {
    { title = "Aimbot", col = 1, rows = {
        T2("legit.aimbot", "Enabled", false, "Legit aimbot"),
        S2("legit.aimfov", "FOV", 5, 180, 30, "Aimbot FOV radius"),
        S2("legit.aimsmooth", "Smoothness", 0.1, 10, 1, "0.1=Fastest, 10=Most smooth", 0.1),
        D2("legit.aimpart", "Target Part", {"Head","HumanoidRootPart"}, "Which part to aim at"),
        T2("legit.teamcheck", "Team Check", false, "Ignore teammates"),
        C2("legit.aimfovcolor", "FOV Color", rgb2(255,255,255), "Aimbot FOV circle color"),
    }},
    { title = "FOV Display", col = 1, rows = {
        T2("legit.showfov", "Show FOV Circles", false, "Show/hide all FOV circles"),
        D2("legit.fovstyle", "Style", {"Outline","Filled"}, "FOV circle style"),
    }},
    { title = "Silent Aim", col = 2, rows = {
        T2("legit.silentaim", "Enabled", false, "Silent aim"),
        S2("legit.silentfov", "FOV", 5, 180, 30, "Silent aim FOV"),
        D2("legit.silentpart", "Target Part", {"Head","HumanoidRootPart"}, "Which part to aim at"),
        T2("legit.silentnpc", "Target NPC", true, "Also lock onto practice dummies and targets"),
        T2("legit.wallcheck", "Wall Check", true, "Only lock targets in line of sight"),
        C2("legit.silfovcolor", "FOV Color", rgb2(255,0,0), "Silent aim FOV circle color"),
    }},
    { title = "Triggerbot", col = 2, rows = {
        T2("legit.triggerbot", "Enabled", false, "Auto-fire when crosshair is on enemy"),
        S2("legit.trigdelay", "Delay (ms)", 0, 200, 50, "Delay before firing"),
        T2("legit.trigwall", "Wall Check", false, "Only fire at visible targets"),
        T2("legit.trigteam", "Team Check", false, "Ignore teammates"),
        T2("legit.trigads", "Only ADS", false, "Only fire when aiming down sights"),
    }},
    { title = "Anti Katana", col = 1, rows = {
        T2("legit.antikatana", "Enabled", false, "Detect Katana deflect and prevent shooting"),
    }},
})

buildPage2("Rage", {
    { title = "Movement", col = 1, rows = {
        T2("rage.void", "Void", false, "Server-side void exploit"),
        T2("rage.noclip", "Noclip", false, "No collision"),
        T2("rage.fly", "Fly", false, "Fly mode"),
        S2("rage.flyspeed", "Fly Speed", 16, 200, 50, "Fly speed in studs/s"),
    }},
    { title = "Combat", col = 1, rows = {
        T2("rage.fist", "Fist", false, "Melee zero-cooldown exploit"),
        T2("rage.riot", "Riot", false, "Riot teleport exploit"),
        T2("rage.scythe", "Scythe", false, "Scythe zero-cooldown"),
        T2("rage.wallbang", "Wallbang", false, "Wallbang (body)"),
        T2("rage.wallbanghead", "Wallbang Head", false, "Wallbang (head)"),
        T2("rage.backstab", "Always Backstab", false, "Every knife hit registers as a backstab"),
    }},
    { title = "Anti-Aim", col = 2, rows = {
        T2("rage.antiaim", "Enabled", false, "Master anti-aim switch"),
        D2("rage.yawtype", "Yaw Type", {"none","jitter","spinbot","random"}, "Yaw manipulation"),
        D2("rage.pitchtype", "Pitch Type", {"none","jitter","spinbot","random"}, "Pitch manipulation"),
        D2("rage.angletype", "Angle Type", {"none","tilt 45","tilt 90","upside down","custom"}, "Roll/angle manipulation"),
        S2("rage.customangle", "Custom Angle", 0, 360, 0, "Custom roll angle"),
        S2("rage.minspeed", "Min Speed", 1, 100, 10, "Min jitter speed"),
        S2("rage.maxspeed", "Max Speed", 1, 100, 20, "Max jitter speed"),
        S2("rage.minangle", "Min Angle", 1, 180, 30, "Min jitter angle"),
        S2("rage.maxangle", "Max Angle", 1, 180, 60, "Max jitter angle"),
        T2("rage.randomangle", "Random Angle", false, "Randomise jitter angle"),
        T2("rage.irregularmove", "Irregular Move", false, "Random position offsets while moving"),
    }},
    { title = "Underground", col = 2, rows = {
        T2("rage.underground", "Underground", false, "Server-side underground teleport"),
        S2("rage.ugdepth", "Depth Offset", -20, 20, -2, "Offset below floor (negative = deeper)"),
    }},
})

buildPage2("ESP", {
    { title = "ESP Options", col = 1, rows = {
        T2("live.esp", "In-Game ESP", true, "Apply ESP to real players"),
        T2("esp.enabled", "ESP Enabled", true, "Master switch for ESP overlays"),
        T2("esp.highlight", "Highlight / Chams", false, "Tint and outline the character"),
        T2("esp.box", "Box", true, "Bounding box"),
        T2("esp.names", "Names", true, "Name label above box"),
        T2("esp.healthinfo", "Health Info", true, "Numeric health next to bar"),
        T2("esp.vhealth", "Vertical Health Bar", true, "Vertical health bar on the left"),
        T2("esp.weapon", "Weapon Info", false, "Equipped item label"),
        T2("esp.distance", "Distance", false, "Distance label"),
        T2("esp.look", "Look Direction", false, "Facing indicator from head"),
        T2("esp.arrows", "Off-Screen Arrows", false, "Arrows pointing to off-screen enemies"),
        T2("esp.team", "Show Team Tag", false, "Add team tag to name"),
    }},
    { title = "Extra ESP", col = 2, tabs = {
        { name = "Skeleton / Head", rows = {
            T2("skel.enabled", "Skeleton", true, "Draw bones over the model"),
            S2("skel.thick", "Thickness", 1, 5, 1, "Bone line thickness"),
            C2("skel.c1", "Color 1", rgb2(255,255,255), "Spine, shoulders, hips"),
            C2("skel.c2", "Color 2", rgb2(160,100,255), "Arms"),
            C2("skel.c3", "Color 3", rgb2(90,160,255), "Legs"),
            T2("head.enabled", "Head Marker", true, "Marker over head"),
            C2("head.color", "Marker Color", rgb2(255,80,80), "Marker color"),
            D2("head.shape", "Marker Shape", {"Cross","Circle","Square"}, "Marker appearance"),
            T2("head.fill", "Fill Marker", false, "Fill circle/square markers"),
            S2("head.size", "Marker Size", 1, 12, 5, "Marker size"),
            S2("head.thick", "Marker Thickness", 1, 5, 1, "Marker line thickness"),
        }},
        { name = "Bars / Box", rows = {
            S2("bars.width", "Bar Width", 2, 8, 3, "Health bar width"),
            C2("bars.high", "Health High", rgb2(120,255,120), "Color at full health"),
            C2("bars.low", "Health Low", rgb2(255,80,100), "Color at low health"),
            T2("bars.gradient", "Gradient Bar", false, "Blend high and low colors"),
            D2("bars.boxstyle", "Box Style", {"Full","Corners"}, "Outline or corner brackets"),
            C2("bars.boxcolor", "Box Color", rgb2(255,255,255), "Box outline color"),
            S2("bars.boxthick", "Box Thickness", 1, 4, 1, "Box line thickness"),
            T2("bars.fillbox", "Fill Box", false, "Shade inside the box"),
            C2("bars.fillcolor", "Fill Color", rgb2(160,100,255), "Box fill color"),
            S2("bars.fillopacity", "Fill Opacity", 5, 70, 20, "Box fill opacity"),
        }},
        { name = "Tracers / Chams", rows = {
            T2("tr.enabled", "Tracers", false, "Line from screen edge to feet"),
            D2("tr.origin", "Tracer Origin", {"Bottom","Center","Top"}, "Where tracers start"),
            C2("tr.color", "Tracer Color", rgb2(240,130,200), "Tracer color"),
            S2("tr.thick", "Tracer Thickness", 1, 4, 1, "Tracer line thickness"),
            C2("cham.fill", "Chams Fill", rgb2(160,100,255), "Requires Highlight in ESP Options"),
            C2("cham.outline", "Chams Outline", rgb2(255,255,255), "Requires Highlight in ESP Options"),
            S2("cham.opacity", "Chams Opacity", 0, 100, 45, "Fill tint strength"),
            T2("cham.pulse", "Chams Pulse", false, "Animate the chams outline"),
        }},
        { name = "Formatting", rows = {
            S2("fmt.size", "Text Size", 9, 18, 12, "ESP text size"),
            C2("fmt.color", "Text Color", rgb2(255,255,255), "ESP text color"),
            D2("fmt.font", "Font", {"Gotham","Code","Merriweather"}, "ESP text font"),
            T2("fmt.outline", "Text Outline", true, "Outline ESP text"),
            D2("fmt.unit", "Distance Unit", {"Meters","Studs"}, "Distance format"),
        }},
    }},
})

buildPage2("Visuals", {
    { title = "Interface", col = 1, rows = {
        T2("vis.glow", "Glow Effects", true, "Window glow"),
        S2("vis.glowstr", "Glow Strength", 0, 100, 70, "Glow intensity"),
        T2("vis.anim", "Animated Glow", true, "Pulse the glow"),
        T2("vis.petals", "Falling Petals", true, "Decorative petals"),
        S2("vis.petalcount", "Petal Count", 1, 30, 14, "How many petals"),
        S2("vis.opacity", "UI Opacity", 40, 100, 100, "Card opacity"),
    }},
    { title = "Colors", col = 2, rows = {
        D2("vis.preset", "Theme Preset", {"Lilac","Rose","Violet","Ice"}, "Applies a color pair"),
        C2("vis.accent", "Accent Color", Presets.Lilac[1], "Primary accent"),
        C2("vis.accent2", "Secondary Accent", Presets.Lilac[2], "Secondary accent"),
    }},
})

buildPage2("World", {
    { title = "Scene", col = 1, rows = {
        D2("world.env", "Environment", {"Default","Night","Soft","Neon"}, "Preview backdrop"),
        T2("world.grid", "Grid Floor", true, "Perspective grid"),
    }},
    { title = "Ambiance", col = 2, rows = {
        T2("amb.override", "Override Time", false, "Force time of day"),
        S2("amb.clock", "Clock Time", 0, 24, 14, "0=midnight, 12=noon", 0.5),
    }},
})

buildPage2("Character", {
    { title = "Appearance", col = 1, rows = {
        C2("char.skin", "Skin", rgb2(226,190,150), "Skin color"),
        C2("char.shirt", "Shirt", rgb2(24,22,30), "Shirt color"),
        C2("char.pants", "Pants", rgb2(70,76,66), "Pants color"),
        C2("char.hair", "Hair", rgb2(30,24,30), "Hair color"),
    }},
    { title = "Animation", col = 2, rows = {
        T2("char.sway", "Idle Sway", true, "Gentle idle motion"),
        S2("char.speed", "Sway Speed", 0.5, 4, 1.5, "Sway speed", 0.1),
        S2("char.scale", "Model Scale", 60, 130, 100, "Preview model scale"),
    }},
})

buildPage2("Misc", {
    { title = "Player", col = 1, rows = {
        T2("misc.speed", "Speed Hack", false, "Enable/disable speed lock"),
        S2("misc.speedval", "Speed", 16, 500, 16, "Walk speed in studs"),
        T2("misc.infjump", "Infinite Jump", false, "Jump in mid-air"),
        T2("misc.slideboost", "Slide Boost", false, "Boost sliding speed"),
        S2("misc.slidespeed", "Boost Speed", 100, 1000, 300, "Slide speed when boosting"),
    }},
    { title = "Weapon", col = 2, rows = {
        T2("misc.rapidfire", "Rapid Fire", false, "Zero fire cooldown"),
        S2("misc.firedelay", "Delay (ms)", 1, 200, 1, "Fire delay in ms"),
        T2("misc.instantads", "Instant ADS", false, "Instant aim-down-sights"),
        T2("misc.noequipanim", "No Equip Anim", false, "Skip weapon equip animation"),
        T2("misc.noshootanim", "No Shoot Anim", false, "Skip weapon shoot animation"),
        T2("misc.nospread", "No Spread", false, "Remove bullet spread"),
        T2("misc.nosmoke", "No Smoke", false, "Remove smoke screens"),
        T2("misc.noflash", "No Flash", false, "Remove flashbangs"),
    }},
    { title = "Device Spoof", col = 1, rows = {
        T2("misc.devspoof", "Enabled", false, "Spoof device type to server"),
        D2("misc.spoofas", "Spoof As", {"VR","Touch","Gamepad"}, "Device to spoof as"),
    }},
    { title = "Interface", col = 2, rows = {
        T2("misc.notify", "Notifications", true, "Show toast messages"),
        T2("misc.tips", "Tooltips", true, "Show setting descriptions on hover"),
        T2("misc.compact", "Compact Mode", false, "Tighter row spacing"),
        T2("misc.antiafk", "Anti-AFK", false, "Prevent idle kick"),
        B2("Test Notification", "Send", function() notify2("Lilac", "Notifications are working.") end, "Fire a test toast"),
    }},
})

buildPage2("Settings", {
    { title = "Menu", col = 1, rows = {
        {type="keybind", key="set.menukey", name="Menu Key", default="RightShift", tip="Show/hide the window"},
        S2("set.scale", "Interface Scale", 70, 120, 100, "Window scale (%)"),
        T2("set.preview", "Show Live Preview", true, "Show the preview panel"),
        T2("set.lock", "Lock Window", false, "Disable dragging"),
        T2("set.confirm", "Confirm Resets", true, "Ask before resetting"),
    }},
    { title = "Config", col = 2, rows = {
        {type="config", name="Config", tip="Copy or paste a Lilac config string", hook=function(tb,exp2,imp2)
            exp2.MouseButton1Click:Connect(function() tb.Text=serialize2(); notify2("Config exported","Select the text to copy it.") end)
            imp2.MouseButton1Click:Connect(function() if importConfig2(tb.Text) then notify2("Config imported","Settings applied.") else notify2("Import failed","That config string isn't valid.") end end)
        end},
    }},
    { title = "Reset", col = 1, rows = {
        D2("set.resettab", "Section", tabOrder2, "Which section to reset"),
        B2("Reset Section","Reset",function()
            local tab = Settings2["set.resettab"]
            confirm2("Reset "..tab.."?","This restores every "..tab.." setting to its default.",function()
                resetKeys2(TabKeys2[tab]); notify2("Reset complete", tab.." restored to defaults.")
            end)
        end,"Reset the selected section"),
        B2("Reset All","Reset all",function()
            confirm2("Reset everything?","Every setting returns to its default.",function() resetAll2(); notify2("Reset complete","All settings restored.") end)
        end,"Reset every setting",true),
        B2("Unload","Unload",function() unload() end,"Close and clean up Lilac"),
    }},
})

-- ────────────────────────────────────────────────────────────
-- SECTION 11: Navigation
-- ────────────────────────────────────────────────────────────
local navButtons2 = {}
local function styleNav2()
    for name, nb in pairs(navButtons2) do
        local a = name == currentTab2
        tween2(nb.btn, {BackgroundTransparency = a and 0 or 1}, 0.15)
        tween2(nb.stroke, {Transparency = a and 0.05 or 1}, 0.15)
        nb.label.TextColor3 = a and Theme.Text or Theme.Muted
        nb.stroke.Color = Theme.Accent
        nb.icon(a and Theme.Accent or Theme.Muted)
    end
end

local function selectTab2(name)
    closePopup2(); currentTab2 = name; pageTitle2.Text = name; searchBox2.Text = ""
    for n, p in pairs(pages2) do p.scroll.Visible = n == name end
    local p = pages2[name]
    applySearch2(p, "")
    p.scroll.CanvasPosition = Vector2.new(0,0)
    p.scroll.Position = UDim2.fromOffset(22,94)
    tween2(p.scroll, {Position=UDim2.fromOffset(22,84)}, 0.25)
    moduleLabel2.Text = p.count..(p.count==1 and " module" or " modules")
    styleNav2()
end

for i, name in ipairs(tabOrder2) do
    if name == "Settings" then create2("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,14), LayoutOrder=99}, navHolder2) end
    local btn2 = create2("TextButton", {Name=name, Text="", AutoButtonColor=false, BackgroundColor3=Theme.CardHead, BackgroundTransparency=1, Size=UDim2.new(1,0,0,42), LayoutOrder=name=="Settings" and 100 or i, BorderSizePixel=0}, navHolder2)
    corner2(btn2, 12)
    local st2 = stroke2(btn2, Theme.Accent, 1.5, 1)
    local ic2, setIc2 = makeIcon2(name, btn2)
    ic2.Position = UDim2.new(0,14,0.5,-10)
    local lb2 = text2(btn2, name, 13, Theme.Muted, BODY); lb2.Position=UDim2.fromOffset(46,0); lb2.Size=UDim2.new(1,-50,1,0)
    navButtons2[name] = {btn=btn2, stroke=st2, icon=setIc2, label=lb2}
    btn2.MouseButton1Click:Connect(function() selectTab2(name) end)
    btn2.MouseEnter:Connect(function() if currentTab2 ~= name then tween2(btn2, {BackgroundTransparency=0.6}, 0.1) end end)
    btn2.MouseLeave:Connect(function() if currentTab2 ~= name then tween2(btn2, {BackgroundTransparency=1}, 0.1) end end)
end
bindAccent2(styleNav2)

-- ────────────────────────────────────────────────────────────
-- SECTION 12: Visual/settings handlers
-- ────────────────────────────────────────────────────────────
Handlers2["vis.accent"]   = function(c) Theme.Accent=c; refreshAccent2() end
Handlers2["vis.accent2"]  = function(c) Theme.Accent2=c; refreshAccent2() end
Handlers2["vis.preset"]   = function(v) if bulk2 then return end; local p=Presets[v]; if p then applySetting2("vis.accent",p[1]); applySetting2("vis.accent2",p[2]) end end
Handlers2["vis.opacity"]  = function(v) local t=(100-v)/100*0.85; for _,c in ipairs(cardFrames2) do c.BackgroundTransparency=t end; sidebar2.BackgroundTransparency=0.15+(100-v)/100*0.6 end
Handlers2["misc.compact"] = function(v) for _,r in ipairs(allRows2) do r.frame.Size=UDim2.new(1,0,0,r.base-(v and 6 or 0)) end end
Handlers2["set.scale"]    = function(v) userScale2=v/100; fit2() end
Handlers2["set.preview"]  = function() updatePreviewVisible2() end
Handlers2["world.env"]    = function(v) if Environments[v] then previewDirty2=true end end
Handlers2["amb.override"]  = function() end
Handlers2["amb.clock"]    = function(v) if Settings2["amb.override"] then Lighting.ClockTime=v end end

local minimized2 = false
minButton2.MouseButton1Click:Connect(function()
    minimized2 = not minimized2; closePopup2()
    local h = minimized2 and 56 or RH
    tween2(main2, {Size=UDim2.fromOffset(MAIN_W,h)}, 0.28)
    tween2(glowOuter2, {Size=UDim2.fromOffset(MAIN_W+10,h+10)}, 0.28)
    tween2(glowInner2, {Size=UDim2.fromOffset(MAIN_W+4,h+4)}, 0.28)
    if minimized2 then preview2.Visible=false; previewGlow2.Visible=false
    else task.delay(0.2, updatePreviewVisible2) end
end)
closeButton2.MouseButton1Click:Connect(unload)

connect2(UserInputService.InputBegan, function(i)
    if _G.__LilacBinding or UserInputService:GetFocusedTextBox() then return end
    if os.clock() - (_G.__LilacBindTime or 0) < 0.3 then return end
    if matchesBind2(i, Settings2["set.menukey"]) then
        root2.Visible = not root2.Visible; modalBtn2.Modal = root2.Visible; closePopup2()
    end
end)

-- ────────────────────────────────────────────────────────────
-- SECTION 13: Frame loop (glow, petals, preview, tooltip)
-- ────────────────────────────────────────────────────────────
local t0_2 = os.clock()
local origClock2 = Lighting.ClockTime
local ambOn2 = false
table.insert(cleanups2, function() if ambOn2 then Lighting.ClockTime=origClock2 end end)

connect2(RunService.Heartbeat, function(dt)
    if not root2.Visible then return end
    local t = os.clock() - t0_2
    local strength = Settings2["vis.glow"] and (Settings2["vis.glowstr"]/100) or 0
    local pulse = Settings2["vis.anim"] and (0.78 + 0.22*math.sin(t*1.8)) or 1
    glowOuterStroke2.Transparency = 1 - 0.34*strength*pulse
    glowInnerStroke2.Transparency = 1 - 0.6*strength*pulse
    previewGlowStroke2.Transparency = 1 - 0.3*strength*pulse

    local show = Settings2["vis.petals"]; local count = Settings2["vis.petalcount"]
    for i, p in ipairs(petals2) do
        local vis = show and i <= count; p.f.Visible = vis
        if vis then
            p.y += p.vy*dt; p.x += (p.vx+10*math.sin(t*1.1+p.ph))*dt; p.rot += p.vr*dt
            if p.y > RH+20 or p.x < -20 then p.y=-20; p.x=math.random(0,MAIN_W) end
            p.f.Position=UDim2.fromOffset(p.x,p.y); p.f.Rotation=p.rot
        end
    end

    if previewDirty2 then previewDirty2=false; renderPreview2() end
    if Settings2["char.sway"] then char2.Rotation=math.sin(t*Settings2["char.speed"])*1.6 elseif char2.Rotation~=0 then char2.Rotation=0 end
    if Settings2["esp.enabled"] and Settings2["esp.highlight"] and Settings2["cham.pulse"] then
        local a = 0.45+0.35*math.sin(t*3); for _, p in pairs(parts2) do p.stroke.Transparency=a end
    else for _, p in pairs(parts2) do p.stroke.Transparency=0 end end

    if tipActive2 then local m=UserInputService:GetMouseLocation(); tipFrame2.Position=UDim2.fromOffset(m.X+16,m.Y+18) end

    -- ambiance
    if Settings2["amb.override"] then
        if not ambOn2 then origClock2=Lighting.ClockTime; ambOn2=true end
        Lighting.ClockTime = Settings2["amb.clock"]
    elseif ambOn2 then Lighting.ClockTime=origClock2; ambOn2=false end
end)

-- ────────────────────────────────────────────────────────────
-- SECTION 14: Lilac in-game ESP (full, replacing noragebot box ESP)
-- ────────────────────────────────────────────────────────────
do
    local lp3 = Players.LocalPlayer
    local cam3 = workspace.CurrentCamera
    connect2(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam3=workspace.CurrentCamera end)

    local worldLayer2 = create2("Frame", {Name="World", BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=0, Active=false}, gui)

    local function myChar3() return lp3.Character end
    local function sameTeam3(plr) return lp3.Team ~= nil and plr.Team == lp3.Team end
    local function alive3(plr) local c=plr.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); return c,h,(h and h.Health>0) end

    local toggled3 = {aim=false, trig=false}
    local function modeActive3(p)
        local mode = Settings2[p..".mode"]
        if mode == "Always" then return true end
        if mode == "Toggle" then return toggled3[p] end
        return bindDown2(Settings2[p..".key"])
    end

    local function targetOk3(plr, c, hum, p)
        if not hum or hum.Health <= 0 then return false end
        if Settings2[p..".team"] and sameTeam3(plr) then return false end
        if Settings2[p..".hpcheck"] then if c:FindFirstChildOfClass("ForceField") then return false end end
        return true
    end

    local espObjs2 = {}

    local BONES_R15_2 = {
        {"Head","UpperTorso",1},{"UpperTorso","LowerTorso",1},
        {"UpperTorso","LeftUpperArm",2},{"LeftUpperArm","LeftLowerArm",2},{"LeftLowerArm","LeftHand",2},
        {"UpperTorso","RightUpperArm",2},{"RightUpperArm","RightLowerArm",2},{"RightLowerArm","RightHand",2},
        {"LowerTorso","LeftUpperLeg",3},{"LeftUpperLeg","LeftLowerLeg",3},{"LeftLowerLeg","LeftFoot",3},
        {"LowerTorso","RightUpperLeg",3},{"RightUpperLeg","RightLowerLeg",3},{"RightLowerLeg","RightFoot",3},
    }
    local BONES_R6_2 = {
        {"Head","Torso",1},{"Torso","Left Arm",2},{"Torso","Right Arm",2},{"Torso","Left Leg",3},{"Torso","Right Leg",3},
    }

    local function lineBetween2(f, a, b, th, col)
        local d = b - a; f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(d.Magnitude,th); f.Rotation=math.deg(math.atan2(d.Y,d.X)); f.BackgroundColor3=col
    end

    local function destroyEsp2(o)
        if not o then return end
        for _, k in ipairs({"hl","bb","tracer","lookLine","lookDot","arrow"}) do if o[k] then o[k]:Destroy() end end
        for _, f in pairs(o.headM or {}) do if typeof(f)=="Instance" then f:Destroy() end end
        for _, f in ipairs(o.bones or {}) do f:Destroy() end
    end

    local function buildEsp2(plr, char)
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not rootPart or not hum then return nil end
        local o = {char=char, root=rootPart, hum=hum}
        o.hl = create2("Highlight", {Adornee=char, DepthMode=Enum.HighlightDepthMode.AlwaysOnTop, Enabled=false}, char)
        o.bb = create2("BillboardGui", {Adornee=rootPart, AlwaysOnTop=true, LightInfluence=0, ResetOnSpawn=false, Size=UDim2.fromScale(4.5,6.2)}, char)
        o.box = create2("Frame", {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, o.bb)
        o.boxStroke = stroke2(o.box, Color3.new(1,1,1), 1)
        o.corners = {}
        for _, a in ipairs({{0,0},{1,0},{0,1},{1,1}}) do
            for _, h in ipairs({true,false}) do
                local f = create2("Frame", {BorderSizePixel=0, AnchorPoint=Vector2.new(a[1],a[2]), Position=UDim2.fromScale(a[1],a[2]), Visible=false}, o.bb)
                table.insert(o.corners, {f=f, h=h})
            end
        end
        o.hpBack = create2("Frame", {BackgroundColor3=Color3.fromRGB(10,8,12), BorderSizePixel=0}, o.bb)
        o.hpFill = create2("Frame", {AnchorPoint=Vector2.new(0,1), Position=UDim2.fromScale(0,1), BorderSizePixel=0}, o.hpBack)
        o.hpGrad = create2("UIGradient", {Rotation=90, Enabled=false}, o.hpFill)
        local function lbl3()
            return create2("TextLabel", {BackgroundTransparency=1, Text="", TextColor3=Color3.new(1,1,1), TextStrokeColor3=Color3.new(0,0,0)}, o.bb)
        end
        o.name = lbl3(); o.name.AnchorPoint=Vector2.new(0.5,1); o.name.Position=UDim2.new(0.5,0,0,-2)
        o.hpTxt = lbl3(); o.hpTxt.AnchorPoint=Vector2.new(1,0.5); o.hpTxt.TextXAlignment=Enum.TextXAlignment.Right
        o.info = create2("Frame", {BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,1,2), Size=UDim2.fromOffset(220,0), AutomaticSize=Enum.AutomaticSize.Y}, o.bb)
        create2("UIListLayout", {HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, o.info)
        o.weapon, o.ammo, o.dist = lbl3(), lbl3(), lbl3()
        for i, l in ipairs({o.weapon,o.ammo,o.dist}) do l.Parent=o.info; l.LayoutOrder=i end
        o.tracer = create2("Frame", {BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Visible=false}, worldLayer2)
        local function sq() return create2("Frame", {BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Visible=false}, worldLayer2) end
        o.bones = {}
        o.headM = {h=sq(), v=sq(), circle=sq(), square=sq()}
        round2(o.headM.circle); corner2(o.headM.square, 1)
        o.headM.circleStroke = stroke2(o.headM.circle, Color3.new(1,1,1), 1)
        o.headM.squareStroke = stroke2(o.headM.square, Color3.new(1,1,1), 1)
        o.lookLine = sq(); o.lookDot = sq(); o.lookDot.Size=UDim2.fromOffset(6,6); round2(o.lookDot)
        o.arrow = sq(); o.arrow.Size=UDim2.fromOffset(11,11); o.arrow.Rotation=45; corner2(o.arrow, 2)
        return o
    end

    local function hideEsp2(o)
        o.hl.Enabled=false; o.bb.Enabled=false; o.tracer.Visible=false; o.lookLine.Visible=false; o.lookDot.Visible=false; o.arrow.Visible=false
        for _, f in pairs(o.headM) do if typeof(f)=="Instance" and f:IsA("GuiObject") then f.Visible=false end end
        for _, f in ipairs(o.bones) do f.Visible=false end
    end

    local function updateEsp2(plr, o, t)
        local S3 = Settings2
        local d = (cam3.CFrame.Position - o.root.Position).Magnitude
        o.bb.Enabled = true
        o.hl.Enabled = S3["esp.highlight"]
        o.hl.FillColor = S3["cham.fill"]; o.hl.FillTransparency = 1 - S3["cham.opacity"]/100
        o.hl.OutlineColor = S3["cham.outline"]; o.hl.OutlineTransparency = S3["cham.pulse"] and (0.45+0.35*math.sin(t*3)) or 0
        local th = S3["bars.boxthick"]; local asCorners = S3["bars.boxstyle"] == "Corners"
        o.box.Visible = S3["esp.box"]; o.boxStroke.Enabled = not asCorners; o.boxStroke.Thickness=th; o.boxStroke.Color=S3["bars.boxcolor"]
        o.box.BackgroundColor3 = S3["bars.fillcolor"]; o.box.BackgroundTransparency = S3["bars.fillbox"] and (1-S3["bars.fillopacity"]/100) or 1
        for _, c in ipairs(o.corners) do
            c.f.Visible = S3["esp.box"] and asCorners; c.f.BackgroundColor3=S3["bars.boxcolor"]
            c.f.Size = c.h and UDim2.fromOffset(14,th) or UDim2.fromOffset(th,14)
        end
        local font2 = FontMap[S3["fmt.font"]] or BODY; local ts = S3["fmt.size"]; local tst = S3["fmt.outline"] and 0.35 or 1
        for _, l in ipairs({o.name,o.hpTxt,o.weapon,o.ammo,o.dist}) do l.Font=font2; l.TextSize=ts; l.TextColor3=S3["fmt.color"]; l.TextStrokeTransparency=tst end
        o.name.Visible=S3["esp.names"]; o.name.Text=plr.DisplayName..((S3["esp.team"] and sameTeam3(plr)) and "  [TEAM]" or ""); o.name.Size=UDim2.fromOffset(220,ts+6)
        local tool = o.char:FindFirstChildOfClass("Tool")
        o.weapon.Visible=S3["esp.weapon"]; o.weapon.Text=tool and tool.Name or "None"
        o.ammo.Visible=S3["esp.ammo"] or false; o.ammo.Text=tool and tostring(tool:GetAttribute("Ammo") or "-") or "-"
        o.dist.Visible=S3["esp.distance"]; o.dist.Text=S3["fmt.unit"]=="Meters" and string.format("%d m",math.floor(d*0.28+0.5)) or string.format("%d studs",math.floor(d+0.5))
        for _, l in ipairs({o.weapon,o.ammo,o.dist}) do l.Size=UDim2.new(1,0,0,ts+4) end
        local hp = math.clamp(o.hum.Health/math.max(o.hum.MaxHealth,1),0,1); local bw=S3["bars.width"]
        local col = S3["bars.low"]:Lerp(S3["bars.high"], hp)
        o.hpBack.Visible=S3["esp.vhealth"]; o.hpBack.Size=UDim2.new(0,bw,1,0); o.hpBack.Position=UDim2.new(0,-4-bw,0,0)
        o.hpFill.Size=UDim2.fromScale(1,hp); o.hpGrad.Enabled=S3["bars.gradient"]; o.hpGrad.Color=ColorSequence.new(S3["bars.high"],S3["bars.low"])
        o.hpFill.BackgroundColor3 = S3["bars.gradient"] and Color3.new(1,1,1) or col
        o.hpTxt.Visible=S3["esp.healthinfo"]; o.hpTxt.Text=tostring(math.floor(o.hum.Health)); o.hpTxt.TextColor3=col
        o.hpTxt.Size=UDim2.fromOffset(34,ts+2); o.hpTxt.Position=UDim2.new(0,-8-(S3["esp.vhealth"] and bw or 0),1-hp,0)
        if S3["tr.enabled"] then
            local v3, on = cam3:WorldToViewportPoint(o.root.Position - Vector3.new(0,3,0))
            if on then
                local vs3 = cam3.ViewportSize
                local origin = Vector2.new(vs3.X/2, vs3.Y)
                if S3["tr.origin"]=="Center" then origin=vs3/2 elseif S3["tr.origin"]=="Top" then origin=Vector2.new(vs3.X/2,0) end
                local to3 = Vector2.new(v3.X, v3.Y); local diff3 = to3 - origin
                o.tracer.Visible=true; o.tracer.Position=UDim2.fromOffset((origin.X+to3.X)/2,(origin.Y+to3.Y)/2)
                o.tracer.Size=UDim2.fromOffset(diff3.Magnitude,S3["tr.thick"]); o.tracer.Rotation=math.deg(math.atan2(diff3.Y,diff3.X)); o.tracer.BackgroundColor3=S3["tr.color"]
            else o.tracer.Visible=false end
        else o.tracer.Visible=false end
        local sk = S3["skel.enabled"]; local list = o.char:FindFirstChild("UpperTorso") and BONES_R15_2 or BONES_R6_2
        local cols3 = {S3["skel.c1"],S3["skel.c2"],S3["skel.c3"]}
        for idx, b in ipairs(list) do
            local fr = o.bones[idx]
            if not fr then fr=create2("Frame",{BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Visible=false},worldLayer2); o.bones[idx]=fr end
            local p1, p2 = o.char:FindFirstChild(b[1]), o.char:FindFirstChild(b[2])
            if sk and p1 and p2 then
                local a3 = cam3:WorldToViewportPoint(p1.Position); local c3 = cam3:WorldToViewportPoint(p2.Position)
                if a3.Z>0 and c3.Z>0 then lineBetween2(fr,Vector2.new(a3.X,a3.Y),Vector2.new(c3.X,c3.Y),S3["skel.thick"],cols3[b[3]]); fr.Visible=true else fr.Visible=false end
            else fr.Visible=false end
        end
        for idx = #list+1, #o.bones do o.bones[idx].Visible=false end
        local M = o.headM; local headPart = o.char:FindFirstChild("Head"); local showHead = false
        if S3["head.enabled"] and headPart then
            local v3 = cam3:WorldToViewportPoint(headPart.Position)
            if v3.Z > 0 then
                showHead=true; local px=4+S3["head.size"]*2.2; local ht,hc,shape,fillOn=S3["head.thick"],S3["head.color"],S3["head.shape"],S3["head.fill"]
                local pos3=UDim2.fromOffset(v3.X,v3.Y)
                M.h.Position,M.v.Position,M.circle.Position,M.square.Position=pos3,pos3,pos3,pos3
                M.h.Visible,M.v.Visible=shape=="Cross",shape=="Cross"; M.h.BackgroundColor3,M.v.BackgroundColor3=hc,hc
                M.h.Size,M.v.Size=UDim2.fromOffset(px,ht),UDim2.fromOffset(ht,px)
                M.circle.Visible=shape=="Circle"; M.circle.Size=UDim2.fromOffset(px,px); M.circle.BackgroundColor3=hc; M.circle.BackgroundTransparency=fillOn and 0 or 1
                M.circleStroke.Thickness,M.circleStroke.Color=ht,hc
                M.square.Visible=shape=="Square"; M.square.Size=UDim2.fromOffset(px,px); M.square.BackgroundColor3=hc; M.square.BackgroundTransparency=fillOn and 0 or 1
                M.squareStroke.Thickness,M.squareStroke.Color=ht,hc
            end
        end
        if not showHead then M.h.Visible,M.v.Visible,M.circle.Visible,M.square.Visible=false,false,false,false end
        local lookShown=false
        if S3["esp.look"] and headPart then
            local a3=cam3:WorldToViewportPoint(headPart.Position); local b3=cam3:WorldToViewportPoint(headPart.Position+headPart.CFrame.LookVector*4)
            if a3.Z>0 and b3.Z>0 then
                lookShown=true; lineBetween2(o.lookLine,Vector2.new(a3.X,a3.Y),Vector2.new(b3.X,b3.Y),1.5,Theme.Accent)
                o.lookDot.Position=UDim2.fromOffset(b3.X,b3.Y); o.lookDot.BackgroundColor3=Theme.Accent
            end
        end
        o.lookLine.Visible,o.lookDot.Visible=lookShown,lookShown
        local rv=cam3:WorldToViewportPoint(o.root.Position); local offscreen=false
        if S3["esp.arrows"] then
            local vs3=cam3.ViewportSize; offscreen=rv.Z<=0 or rv.X<0 or rv.Y<0 or rv.X>vs3.X or rv.Y>vs3.Y
            if offscreen then
                local center=vs3/2; local dir=Vector2.new(rv.X,rv.Y)-center
                if rv.Z<=0 then dir=-dir end; if dir.Magnitude<1 then dir=Vector2.new(0,1) end; dir=dir.Unit
                local sc=math.min((vs3.X/2-30)/math.max(math.abs(dir.X),1e-3),(vs3.Y/2-30)/math.max(math.abs(dir.Y),1e-3))
                local p3=center+dir*sc; o.arrow.Position=UDim2.fromOffset(p3.X,p3.Y); o.arrow.BackgroundColor3=Theme.Accent
            end
        end
        o.arrow.Visible=offscreen
    end

    connect2(RunService.Heartbeat, function()
        local S3 = Settings2
        local t = os.clock()
        local want = S3["live.esp"] and S3["esp.enabled"]
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp3 then
                local o = espObjs2[plr]; local c,_,ok = alive3(plr)
                if o and o.char ~= c then destroyEsp2(o); o=nil; espObjs2[plr]=nil end
                if want and c and ok then
                    if not o then o=buildEsp2(plr,c); espObjs2[plr]=o end
                    if o then
                        if sameTeam3(plr) and not S3["esp.team"] then hideEsp2(o)
                        else local okU,errU=pcall(updateEsp2,plr,o,t); if not okU and not _G.__LilacEspWarned then _G.__LilacEspWarned=true; warn("[Lilac] ESP error: "..tostring(errU)) end end
                    end
                elseif o then hideEsp2(o) end
            end
        end
        for plr, o in pairs(espObjs2) do if not plr.Parent then destroyEsp2(o); espObjs2[plr]=nil end end
    end)

    table.insert(cleanups2, function() for _, o in pairs(espObjs2) do destroyEsp2(o) end; table.clear(espObjs2) end)
end

-- ────────────────────────────────────────────────────────────
-- SECTION 15: CharacterAdded reconnect
-- ────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    setSpeed(S.speedValue)
    if S.voidActive then task.wait(0.5); toggleVoid(true) end
    if S.fistActive then toggleFist(true) end
    if S.roitActive then toggleRiot(true) end
    if S.noclipActive then toggleNoclip(true) end
    if S.wallbangActive then stopWallbang(); startWallbang() end
    if S.aimbotActive then toggleAimbot(true) end
    if S.flyActive then toggleFly(true) end
    if _G.AntiAimSettings.enabled then _G.StartAntiAimExt() end
    if S.undergroundActive then task.wait(0.5); toggleUnderground(true) end
    if S.irregularMoveActive then startIrregularMove() end
    if S.triggerbotEnabled then startTriggerbot() end
    AlwaysBackstabModule.Rehook()
    task.wait(1)
    applyGunEnhancements(); patchGunSpread(); applyNoSmoke(); applyNoFlash(); applyDeviceSpoof()
end)

-- ────────────────────────────────────────────────────────────
-- SECTION 16: Boot
-- ────────────────────────────────────────────────────────────
bulk2 = true
for key, h in pairs(Handlers2) do h(Settings2[key]) end
bulk2 = false
renderPreview2()
updatePreviewVisible2()
selectTab2("Legit")
notify2("Loaded", "Lilac UI + Rivals Private — RightShift to toggle.")
