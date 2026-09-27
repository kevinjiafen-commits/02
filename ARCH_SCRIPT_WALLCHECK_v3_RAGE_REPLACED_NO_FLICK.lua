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
    _fakeEv.Parent = LocalPlayer
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Controllers = PlayerScripts:WaitForChild("Controllers")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local CosmeticLibrary = require(Modules:WaitForChild("CosmeticLibrary"))
local FighterController = require(Controllers:WaitForChild("FighterController"))
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

local _cfgFile = "rivals_unlocker_config.json"
local _saveLock = false

local function _stripForSave()
    local _out = {}
    for wn, cos in pairs(_eq) do
        _out[wn] = {}
        for ct, cd in pairs(cos) do
            if cd and cd.Name then
                _out[wn][ct] = {
                    Name = cd.Name,
                    Inverted = cd.Inverted,
                    OnlyUseFavorites = cd.OnlyUseFavorites
                }
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
    if _dec.favorites then
        _favs = _dec.favorites
    end
    if _dec.equipped then
        _eq = {}
        local _cnt = 0
        for wn, cos in pairs(_dec.equipped) do
            _eq[wn] = {}
            for ct, sd in pairs(cos) do
                if sd and sd.Name then
                    if _cosLib.Cosmetics[sd.Name] then
                        local _cloned = _mkCosmetic(sd.Name, ct, {
                            inverted = sd.Inverted,
                            favoritesOnly = sd.OnlyUseFavorites
                        })
                        if _cloned then
                            _eq[wn][ct] = _cloned
                            _cnt += 1
                        end
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
        if _ok then
            pcall(writefile, _cfgFile, _enc)
        end
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
    if nm:find("MISSING_") or nm == "Bubble Gun" then
        return _origOwns(self, inv, nm, wep)
    end
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
                if c and _isCosType(c) then
                    _res[wep][nm] = isFav
                end
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
        for ct, cd in pairs(_eq[wn]) do
            pcall(function() _d[ct] = cd end)
        end
    end
    return _d
end

local _fightCtrl
pcall(function()
    _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
end)

if hookmetamethod then
    local _remotes   = _rs:FindFirstChild("Remotes")
    local _dataRem   = _remotes and _remotes:FindFirstChild("Data")
    local _equipRem  = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
    local _favRem    = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
    local _repRem    = _remotes and _remotes:FindFirstChild("Replication")
    local _fightRem  = _repRem and _repRem:FindFirstChild("Fighter")
    local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

    if _equipRem then
        local _onc
        _onc = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() ~= "FireServer" then
                return _onc(self, ...)
            end
            local _a = {...}

            if _useItmRem and self == _useItmRem then
                local _oid = _a[1]
                if _fightCtrl then
                    pcall(function()
                        local _f = _fightCtrl:GetFighter(_lp)
                        if _f and _f.Items then
                            for _, itm in pairs(_f.Items) do
                                if itm:Get("ObjectID") == _oid then
                                    _lastWep = itm.Name
                                    break
                                end
                            end
                        end
                    end)
                end
            end

            if self == _equipRem then
                local _wn   = _a[1]
                local _ct   = _a[2]
                local _cn   = _a[3]
                local _opts = _a[4] or {}
                if _cn and _cn ~= "None" and _cn ~= "" then
                    local _inv = _datCtrl:Get("CosmeticInventory")
                    if _inv and rawget(_inv, _cn) then
                        return _onc(self, ...)
                    end
                end
                _eq[_wn] = _eq[_wn] or {}
                if not _cn or _cn == "None" or _cn == "" then
                    _eq[_wn][_ct] = nil
                    if not next(_eq[_wn]) then _eq[_wn] = nil end
                else
                    local _cloned = _mkCosmetic(_cn, _ct, {
                        inverted = _opts.IsInverted,
                        favoritesOnly = _opts.OnlyUseFavorites
                    })
                    if _cloned then _eq[_wn][_ct] = _cloned end
                end
                task.defer(function()
                    pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                end)
                _saveCfg()
                return
            end

            if self == _favRem then
                local _cos = _cosLib.Cosmetics[_a[2]]
                if _cos then
                    _favs[_a[1]] = _favs[_a[1]] or {}
                    _favs[_a[1]][_a[2]] = _a[3] or nil
                    task.spawn(function()
                        pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                    end)
                    _saveCfg()
                end
                return
            end

            return _onc(self, ...)
        end)
    end
end

local _cliItem
pcall(function()
    _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
end)

if _cliItem and _cliItem._CreateViewModel then
    local _origCVM = _cliItem._CreateViewModel
    _cliItem._CreateViewModel = function(self, vmRef)
        local _wn  = self.Name
        local _wp  = self.ClientFighter and self.ClientFighter.Player
        _buildingWep = (_wp == _lp) and _wn or nil
        if _wp == _lp and _eq[_wn] then
            local _dk = self:ToEnum("Data")
            if vmRef[_dk] then
                if _eq[_wn].Skin then
                    vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin
                    vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name
                end
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
        local _wp  = cliItm.ClientFighter and cliItm.ClientFighter.Player
        local _wn  = _buildingWep or cliItm.Name
        if _wp == _lp and _eq[_wn] then
            local _RC  = require(_rs.Modules.ReplicatedClass)
            local _dk  = _RC:ToEnum("Data")
            repData[_dk] = repData[_dk] or {}
            local _cos = _eq[_wn]
            if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
            if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
            if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
        end
        return _origNew(repData, cliItm)
    end
end

local AntiKatanaModule = (function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local antikatana = false
    local katanausers = {}

    local function detectkatana()
        local lp = Players.LocalPlayer
        if not lp:FindFirstChild("PlayerScripts") then
            lp.PlayerScriptsAdded:Wait()
        end
        task.spawn(function()
            local katana, attempts = nil, 0
            while attempts < 10 do
                pcall(function()
                    local m = lp.PlayerScripts.Modules.Items:FindFirstChild("Katana", true)
                    if m then katana = require(m) end
                end)
                if not katana then
                    for _, m in pairs(lp.PlayerScripts:GetDescendants()) do
                        if m.Name == "Katana" and m:IsA("ModuleScript") then
                            local ok, res = pcall(require, m)
                            if ok then katana = res; break end
                        end
                    end
                end
                if katana and type(katana) == "table" and katana.StartAiming then break end
                attempts = attempts + 1
                task.wait(1)
            end
            if katana and type(katana) == "table" and katana.StartAiming then
                local old = katana.StartAiming
                katana.StartAiming = function(self, force)
                    local fighter = self.ClientFighter
                    local player = fighter and fighter.Player
                    if player then
                        katanausers[player] = true
                        local dur = self.Info.DeflectDuration or 0.6
                        task.delay(dur, function() katanausers[player] = nil end)
                    end
                    return old(self, force)
                end
            end
        end)
    end

    local function katanadeflect(player)
        return antikatana and (katanausers[player] == true)
    end

    local function setAntiKatana(enabled)
        antikatana = enabled
    end

    detectkatana()

    return {
        setAntiKatana = setAntiKatana,
        katanadeflect = katanadeflect,
        isEnabled = function() return antikatana end,
    }
end)()

getgenv().SetAntiKatana = AntiKatanaModule.setAntiKatana
getgenv().IsKatanaDeflecting = AntiKatanaModule.katanadeflect

do
    local function safeRequire(module)
        local ok, result = pcall(require, module)
        return ok and result or nil
    end

    local function getControllers()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return nil, nil end
        local controllers = playerScripts:FindFirstChild("Controllers")
        if not controllers then return nil, nil end
        local fighter = controllers:FindFirstChild("FighterController")
        local camera = controllers:FindFirstChild("CameraController")
        return fighter and safeRequire(fighter), camera and safeRequire(camera)
    end

    local FighterControllerAA, CameraControllerAA = getControllers()
    if not FighterControllerAA then
        warn("FighterController not found, anti-aim may not work")
    end
    if not CameraControllerAA then
        warn("CameraController not found, underground may not work")
    end

    local settings = {
        enabled = false,
        yawtype = "none",
        pitchtype = "none",
        angletype = "none",
        customangle = 0,
        minspeed = 10,
        maxspeed = 20,
        minangle = 30,
        maxangle = 60,
        randomangle = false,
        fakelag = false,
        fakelagstuds = 4,
        desync = false,
        desyncstuds = 3,
        microjitter = false,
        microstrength = 25,
        velocitybreaker = false,
    }

    local statemanager = {
        lastupdate = tick(),
        invertstate = false,
        smoothyaw = 0,
        smoothpitch = 0,
        smoothroll = 0,
        framecounter = 0
    }

    local utils = {
        getrandominrange = function(min, max)
            return min + math.random() * (max - min)
        end
    }

    local antiaim = {}

    function antiaim.calculateyaw(deltatime)
        local yaw = 0
        local currenttime = tick()
        if settings.yawtype == "jitter" then
            local minangle = math.rad(settings.minangle)
            local maxangle = math.rad(settings.maxangle)
            if settings.randomangle then
                yaw = utils.getrandominrange(-maxangle, maxangle)
            else
                yaw = math.random() > 0.5 and minangle or -minangle
            end
        elseif settings.yawtype == "spinbot" then
            local speed = utils.getrandominrange(
                settings.minspeed / 10,
                settings.maxspeed / 10
            )
            yaw = (currenttime * speed) % (2 * math.pi)
        elseif settings.yawtype == "random" then
            if statemanager.framecounter % 30 == 0 then
                yaw = utils.getrandominrange(
                    -math.rad(settings.maxangle),
                    math.rad(settings.maxangle)
                )
            else
                yaw = statemanager.smoothyaw
            end
        end
        statemanager.smoothyaw = yaw
        return yaw
    end

    function antiaim.calculatepitch()
        local pitch = 0
        if settings.pitchtype == "jitter" then
            local minangle = math.rad(settings.minangle)
            local maxangle = math.rad(settings.maxangle)
            if settings.randomangle then
                pitch = utils.getrandominrange(-maxangle, maxangle)
            else
                pitch = math.random() > 0.5 and minangle or -minangle
            end
        elseif settings.pitchtype == "spinbot" then
            pitch = math.sin(tick() * (settings.maxspeed / 10)) * math.rad(settings.maxangle)
        elseif settings.pitchtype == "random" then
            if statemanager.framecounter % 20 == 0 then
                pitch = utils.getrandominrange(math.rad(-89), math.rad(89))
            else
                pitch = statemanager.smoothpitch
            end
        end
        statemanager.smoothpitch = pitch
        return pitch
    end

    function antiaim.calculateroll()
        local roll = 0
        if settings.angletype == "tilt 45" then
            roll = math.rad(45)
        elseif settings.angletype == "tilt 90" then
            roll = math.rad(90)
        elseif settings.angletype == "upside down" then
            roll = math.rad(180)
        elseif settings.angletype == "custom" then
            roll = math.rad(settings.customangle)
        end
        statemanager.smoothroll = roll
        return roll
    end

    local function updantiaim(deltatime)
        if not settings.enabled then return end
        if settings.yawtype == "none" and settings.pitchtype == "none" and settings.angletype == "none" then
            return
        end
        local character = LocalPlayer.Character
        if not character then return end
        local rootpart = character:FindFirstChild("HumanoidRootPart")
        if not rootpart then return end
        statemanager.framecounter = statemanager.framecounter + 1
        local calculatedyaw = antiaim.calculateyaw(deltatime)
        local calculatedpitch = antiaim.calculatepitch()
        local calculatedroll = antiaim.calculateroll()
        local rotationcframe = CFrame.Angles(calculatedpitch, calculatedyaw, calculatedroll)
        rootpart.CFrame = rootpart.CFrame * rotationcframe
    end

    local function flushAntiAimMovementState()
        statemanager.framecounter = 0
        statemanager.smoothyaw = 0
        statemanager.smoothpitch = 0
        statemanager.smoothroll = 0
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    getgenv().InstanceFlushMovementState = flushAntiAimMovementState

    local underground_enabled = false
    local underground_oldpos = nil
    local undergroundDepthOffset = -2

    local function getFloorBelowPosition(pos)
        local rayOrigin = pos
        local rayDirection = Vector3.new(0, -500, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local fighter = FighterControllerAA and FighterControllerAA.LocalFighter
        if fighter and fighter.Entity and fighter.Entity.RootPart then
            raycastParams.FilterDescendantsInstances = {fighter.Entity.RootPart.Parent}
        end
        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if result then
            return CFrame.new(Vector3.new(pos.X, result.Position.Y + undergroundDepthOffset, pos.Z))
        end
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
            if not underground_enabled then
                underground_oldpos = nil
                return
            end
            local fighter = FighterControllerAA and FighterControllerAA.LocalFighter
            if not fighter or not fighter.Entity or not fighter.Entity.RootPart then
                underground_oldpos = nil
                return
            end
            underground_oldpos = fighter.Entity.RootPart.CFrame
            local currentPos = fighter.Entity.RootPart.Position
            local floorCFrame = getFloorBelowPosition(currentPos)
            if floorCFrame then
                fighter.Entity.RootPart.CFrame = floorCFrame
            end
        end)
    end

    local _antiAimConn = nil

    function _G.StartAntiAimExt()
        if not settings.enabled then
            settings.enabled = true
        end
        if not _antiAimConn then
            _antiAimConn = game:GetService("RunService").Heartbeat:Connect(updantiaim)
        end
    end

    function _G.StopAntiAimExt()
        settings.enabled = false
        if _antiAimConn then
            _antiAimConn:Disconnect()
            _antiAimConn = nil
        end
        flushAntiAimMovementState()
    end

    function _G.SetUndergroundExt(state)
        underground_enabled = state
        getgenv().InstanceUndergroundEnabled = state
        if state then
            startUndergroundHeartbeat()
        else
            underground_oldpos = nil
            if undergroundHeartbeatConn then
                undergroundHeartbeatConn:Disconnect()
                undergroundHeartbeatConn = nil
            end
        end
    end

    function _G.SetUndergroundDepthExt(depth)
        undergroundDepthOffset = depth
    end

    _G.AntiAimSettings = settings
end

local SlideBoostModule = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    _G.Features = _G.Features or {}
    _G.Features.SlideBoost = _G.Features.SlideBoost or {
        Enabled = false,
        Speed = 300
    }

    local mech = nil
    local connection = nil

    local function getMechanicsController()
        local success, result = pcall(function()
            return require(LocalPlayer.PlayerScripts.Controllers.MechanicsController)
        end)
        if success then
            mech = result
        else
            mech = nil
        end
        return mech
    end

    local function startSlideBoost()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        local function boostLoop()
            if not _G.Features.SlideBoost.Enabled then
                return
            end
            if not mech then
                getMechanicsController()
            end
            if mech and mech.IsSliding then
                pcall(function()
                    mech._sliding_velocity.Velocity = mech._sliding_velocity.Velocity.Unit * _G.Features.SlideBoost.Speed
                end)
            end
        end
        connection = RunService.RenderStepped:Connect(boostLoop)
    end

    local function stopSlideBoost()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end

    local function setSlideBoost(enabled, speed)
        _G.Features.SlideBoost.Enabled = enabled
        if speed then
            _G.Features.SlideBoost.Speed = speed
        end
        if enabled then
            startSlideBoost()
        else
            stopSlideBoost()
        end
    end

    getMechanicsController()
    if _G.Features.SlideBoost.Enabled then
        startSlideBoost()
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        getMechanicsController()
        if _G.Features.SlideBoost.Enabled then
            startSlideBoost()
        end
    end)

    return {
        setSlideBoost = setSlideBoost,
        getEnabled = function() return _G.Features.SlideBoost.Enabled end,
        getSpeed = function() return _G.Features.SlideBoost.Speed end,
    }
end)()

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local ViewportSize = workspace.CurrentCamera.ViewportSize

local CFG = {
    MainColor = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor = Color3.fromRGB(189, 172, 255),
    TextColor = Color3.fromRGB(200, 200, 200),
    TextDark = Color3.fromRGB(120, 120, 120),
    StrokeColor = Color3.fromRGB(40, 40, 40),
    Font = Enum.Font.Code,
    BaseSize = Vector2.new(600, 450)
}

local Library = {
    Flags = {},
    Connections = {},
    Unloaded = false
}

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do
        inst[i] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

local ScreenGui = Create("ScreenGui", {
    Name = "ArchScriptsUI",
    Parent = game:GetService("CoreGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true
})

local UIScale = Create("UIScale", {Parent = ScreenGui})

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local widthRatio = (vp.X - 40) / CFG.BaseSize.X
    local heightRatio = (vp.Y - 40) / CFG.BaseSize.Y
    local scale = math.min(widthRatio, heightRatio, 1)
    UIScale.Scale = math.max(scale, 0.6)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

local NotificationContainer = Create("Frame", {
    Parent = ScreenGui,
    Position = UDim2.new(1, -20, 0, 20),
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 100
})
local UIListNotif = Create("UIListLayout", {
    Parent = NotificationContainer,
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top
})

function Library:Notify(msg, type)
    local color = (type == "success" and Color3.fromRGB(100, 255, 100)) or 
                  (type == "warning" and Color3.fromRGB(255, 100, 100)) or 
                  CFG.AccentColor
    local Frame = Create("Frame", {
        Parent = NotificationContainer,
        Size = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, {
        Create("UIStroke", {Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5}),
        Create("Frame", {
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = color
        }),
        Create("TextLabel", {
            Text = msg,
            TextColor3 = CFG.TextColor,
            Font = CFG.Font,
            TextSize = 12,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })
    Tween(Frame, {Size = UDim2.new(0, 250, 0, 35)}, 0.5, Enum.EasingStyle.Back)
    task.delay(3, function()
        Tween(Frame, {Size = UDim2.new(0, 250, 0, 0), BackgroundTransparency = 1}, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

local TooltipLabel = Create("TextLabel", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3 = CFG.TextColor,
    TextSize = 11,
    Font = CFG.Font,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200
}, {
    Create("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}),
    Create("UIStroke", {Color = CFG.StrokeColor})
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        TooltipLabel.Size = UDim2.fromOffset(GetTextSize(text, 11, CFG.Font).X + 12, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function()
        TooltipLabel.Visible = false
    end)
end

RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
    end
end)

local MainFrame = Create("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position = UDim2.new(0.5, -300, 0.5, -225),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("UIStroke", {Color = CFG.StrokeColor}),
    Create("UICorner", {CornerRadius = UDim.new(0, 3)})
})

local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        Tween(MainFrame, {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)}, 0.05)
    end
end)

local TopBar = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor
    })
})

local TitleLabel = Create("TextLabel", {
    Parent = TopBar,
    Text = "arch scripts | fallen",
    TextColor3 = CFG.TextDark,
    TextSize = 13,
    Font = CFG.Font,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText = true
})

task.spawn(function()
    local textList = {
        '', 'a', 'ar', 'arc', 'arch', 'arch ', 'arch s', 'arch sc', 'arch scr', 'arch scri', 'arch scrip', 'arch script', 'arch scripts',
        'arch scripts ', 'arch scripts |', 'arch scripts | f', 'arch scripts | fa', 'arch scripts | fal', 'arch scripts | fall',
        'arch scripts | falle', 'arch scripts | fallen', 'arch scripts | falle', 'arch scripts | fall', 'arch scripts | fal',
        'arch scripts | fa', 'arch scripts | f', 'arch scripts |', 'arch scripts', 'arch scrip', 'arch scri', 'arch scr',
        'arch sc', 'arch s', 'arch ', 'arch', 'arc', 'ar', 'a'
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "fallen") then
                display = string.gsub(text, "fallen", '<font color="#bdacff">fallen</font>')
            elseif string.find(text, "scripts") and not string.find(text, "fall") then
                display = string.gsub(text, "scripts", '<font color="#bdacff">scripts</font>')
            end
            TitleLabel.Text = display
            task.wait(0.2)
        end
    end
end)

local ContentContainer = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1
})

local Sidebar = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(0, 60, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0)
}, {
    Create("Frame", {Size = UDim2.new(0, 1, 0, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BackgroundColor3 = CFG.StrokeColor}),
    Create("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top}),
    Create("UIPadding", {PaddingTop = UDim.new(0, 15)})
})

local PagesContainer = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 60, 0, 0),
    BackgroundTransparency = 1
})

local Tabs = {}
local CurrentTab = nil

function Library:Tab(name, icon)
    local TabButton = Create("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = CFG.MainColor,
        Text = "",
        TextSize = 20,
        TextColor3 = CFG.TextDark,
        Font = CFG.Font,
        AutoButtonColor = false
    }, {
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. icon,
            ImageColor3 = CFG.TextDark
        }),
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })

    local PageFrame = Create("ScrollingFrame", {
        Parent = PagesContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CFG.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    PageFrame:ClearAllChildren()
    local Padding = Create("UIPadding", {Parent = PageFrame, PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15)})
    local LeftCol = Create("Frame", {Parent = PageFrame, Size = UDim2.new(0.48, 0, 1, 0), BackgroundTransparency = 1}, {
        Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
    })
    local RightCol = Create("Frame", {Parent = PageFrame, Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0), BackgroundTransparency = 1}, {
        Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
    })

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn, {TextColor3 = CFG.TextDark, BackgroundColor3 = CFG.MainColor}, 0.2)
            t.Page.Visible = false
        end
        Tween(TabButton, {TextColor3 = CFG.AccentColor, BackgroundColor3 = CFG.SecondaryColor}, 0.2)
        PageFrame.Visible = true
        CurrentTab = PageFrame
    end)

    table.insert(Tabs, {Btn = TabButton, Page = PageFrame})
    if #Tabs == 1 then
        Tween(TabButton, {TextColor3 = CFG.AccentColor, BackgroundColor3 = CFG.SecondaryColor}, 0.2)
        PageFrame.Visible = true
    end

    local GroupFunctions = {}
    local LeftSide = true

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol
        LeftSide = not LeftSide

        local GroupFrame = Create("Frame", {
            Parent = ParentCol,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel = 0
        }, {
            Create("UIStroke", {Color = CFG.StrokeColor}),
            Create("UICorner", {CornerRadius = UDim.new(0, 2)})
        })

        Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel = 0
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
            Create("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }),
            Create("TextLabel", {
                Text = title,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = CFG.TextColor,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Create("Frame", {
                Size = UDim2.new(0, 4, 0, 4),
                Position = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel = 0
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
        })

        local Content = Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 25),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
        })

        local ItemFuncs = {}

        function ItemFuncs:Toggle(cfg)
            local Enabled = false
            local Frame = Create("TextButton", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = ""
            })
            local Box = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {Create("UIStroke", {Color = CFG.StrokeColor})})
            local Check = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, -4, 1, -4),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = CFG.AccentColor,
                BackgroundTransparency = 1
            })
            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 18, 0, 0),
                Size = UDim2.new(1, -18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            if cfg.Risky then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
            local function Update()
                Enabled = not Enabled
                Tween(Check, {BackgroundTransparency = Enabled and 0 or 1}, 0.1)
                Tween(Label, {TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)}, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end
            Frame.MouseButton1Click:Connect(Update)
            return {Set = function(v) if v ~= Enabled then Update() end end}
        end

        function ItemFuncs:Slider(cfg)
            local Value = cfg.Default or cfg.Min
            local DraggingSlider = false
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1
            })
            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local function formatValue(v)
                if cfg.Decimals then
                    return string.format("%." .. cfg.Decimals .. "f", v)
                else
                    return tostring(v)
                end
            end

            local function roundValue(v)
                if cfg.Decimals then
                    local mult = 10 ^ cfg.Decimals
                    return math.floor(v * mult + 0.5) / mult
                else
                    return math.floor(v)
                end
            end

            local ValueLabel = Create("TextLabel", {
                Parent = Frame,
                Text = formatValue(Value) .. (cfg.Unit or ""),
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Right
            })
            local SliderBG = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            local Fill = Create("Frame", {
                Parent = SliderBG,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

            local function Update(input)
                local SizeX = SliderBG.AbsoluteSize.X
                local PosX = SliderBG.AbsolutePosition.X
                local InputX = input.Position.X
                local Percent = math.clamp((InputX - PosX) / SizeX, 0, 1)
                local rawValue = cfg.Min + (cfg.Max - cfg.Min) * Percent
                Value = roundValue(rawValue)
                Fill.Size = UDim2.new(Percent, 0, 1, 0)
                ValueLabel.Text = formatValue(Value) .. (cfg.Unit or "")
                if cfg.Callback then cfg.Callback(Value) end
            end
            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                    Update(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if DraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)
            local percent = (Value - cfg.Min) / (cfg.Max - cfg.Min)
            Fill.Size = UDim2.new(percent, 0, 1, 0)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current = cfg.Default or cfg.Options[1]
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex = 20
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local MainBox = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("TextLabel", {
                    Name = "Val",
                    Text = Current,
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextColor,
                    TextSize = 11,
                    Font = CFG.Font,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                Create("TextLabel", {
                    Text = "â–¼",
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextDark,
                    TextSize = 10
                })
            })
            local ListFrame = Create("ScrollingFrame", {
                Parent = MainBox,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 50,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })
            for _, opt in pairs(cfg.Options) do
                local Btn = Create("TextButton", {
                    Parent = ListFrame,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = opt,
                    TextColor3 = (opt == Current) and CFG.AccentColor or CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font
                })
                Btn.MouseButton1Click:Connect(function()
                    Current = opt
                    MainBox.Val.Text = opt
                    if cfg.Callback then cfg.Callback(opt) end
                    Expanded = false
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end)
            end
            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, math.min(#cfg.Options * 20, 100))}, 0.1)
                else
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:ColorPicker(cfg)
            local Color = cfg.Default or Color3.fromRGB(255, 255, 255)
            local Opened = false
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 15
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local Preview = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 30, 0, 14),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundColor3 = Color,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })
            local PickerFrame = Create("Frame", {
                Parent = Preview,
                Size = UDim2.new(0, 180, 0, 0),
                Position = UDim2.new(1, 0, 1, 5),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = CFG.MainColor,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 60
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })
            local SatValPanel = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 100),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019"
                }),
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019",
                    ImageColor3 = Color3.new(0,0,0),
                    Rotation = 90
                })
            })
            local Cursor = Create("Frame", {
                Parent = SatValPanel,
                Size = UDim2.new(0, 4, 0, 4),
                BackgroundColor3 = Color3.new(1,1,1),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
            local HueSlider = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 10),
                Position = UDim2.new(0, 10, 0, 120),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1))
                    })
                }),
                Create("UICorner", {CornerRadius = UDim.new(0, 2)})
            })
            local H, S, V = 0, 1, 1
            local DraggingHSV, DraggingHue = false, false
            local function UpdateColor()
                Color = Color3.fromHSV(H, S, V)
                Preview.BackgroundColor3 = Color
                SatValPanel.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                Cursor.Position = UDim2.new(S, 0, 1 - V, 0)
                if cfg.Callback then cfg.Callback(Color) end
            end
            SatValPanel.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = true
                end
            end)
            HueSlider.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHue = true
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = false; DraggingHue = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    if DraggingHSV then
                        local size = SatValPanel.AbsoluteSize
                        local pos = SatValPanel.AbsolutePosition
                        local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                        local y = math.clamp((inp.Position.Y - pos.Y) / size.Y, 0, 1)
                        S = x
                        V = 1 - y
                        UpdateColor()
                    elseif DraggingHue then
                        local size = HueSlider.AbsoluteSize
                        local pos = HueSlider.AbsolutePosition
                        local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                        H = x
                        UpdateColor()
                    end
                end
            end)
            Preview.MouseButton1Click:Connect(function()
                Opened = not Opened
                if Opened then
                    Tween(PickerFrame, {Size = UDim2.new(0, 180, 0, 170)}, 0.2)
                else
                    Tween(PickerFrame, {Size = UDim2.new(0, 180, 0, 0)}, 0.2)
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Textbox(cfg)
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundTransparency = 1
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local Box = Create("TextBox", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 15),
                BackgroundColor3 = CFG.SecondaryColor,
                TextColor3 = CFG.TextColor,
                PlaceholderText = cfg.Placeholder or "...",
                Text = "",
                Font = CFG.Font,
                TextSize = 11,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("UIPadding", {PaddingLeft = UDim.new(0, 5)})
            })
            Box.FocusLost:Connect(function()
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Keybind(cfg)
            local Key = cfg.Default or Enum.KeyCode.Insert
            local Waiting = false
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local Btn = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 60, 1, 0),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = Key.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 10,
                Font = CFG.Font
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })
            Btn.MouseButton1Click:Connect(function()
                Waiting = true
                Btn.Text = "..."
                Btn.TextColor3 = CFG.AccentColor
            end)
            UserInputService.InputBegan:Connect(function(inp)
                if Waiting and inp.UserInputType == Enum.UserInputType.Keyboard then
                    Waiting = false
                    Key = inp.KeyCode
                    Btn.Text = Key.Name
                    Btn.TextColor3 = CFG.TextDark
                    if cfg.Callback then cfg.Callback(Key) end
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Button(cfg)
            local Btn = Create("TextButton", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                Font = Enum.Font.GothamBold,
                TextSize = 10
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })
            if cfg.Variant == "Primary" then
                Btn.BackgroundColor3 = CFG.AccentColor
                Btn.TextColor3 = Color3.new(0,0,0)
            elseif cfg.Variant == "Danger" then
                Btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                Btn.TextColor3 = Color3.new(0,0,0)
            end
            Btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
            end)
            if cfg.Tooltip then AddTooltip(Btn, cfg.Tooltip) end
        end

        return ItemFuncs
    end
    return GroupFunctions
end

local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local S = {
    voidActive = false,
    orbActive = false,
    fistActive = false,
    roitActive = false,
    scytheActive = false,
    wallbangActive = false,
    wallbangHeadActive = false,
    espActive = false,
    aimbotActive = false,
    silentAimActive = false,
    rapidFireActive = false,
    noclipActive = false,
    infiniteJumpActive = false,
    speedValue = 16,
    speedEnabled = false,
    aimFov = 30,
    silentFov = 30,
    aimTargetPart = "Head",
    silentTargetPart = "Head",
    silentTargetNPC = true,  -- 人偶/标把: silent aim 也打练习场靶子和人偶
    wallCheck = true,
    teamCheck = false,
    fireDelay = 1,
    instantAdsEnabled = false,
    noEquipAnimEnabled = false,
    noShootAnimEnabled = false,
    noSpreadEnabled = false,
    noSmokeEnabled = false,
    noFlashEnabled = false,
    deviceSpoofEnabled = false,
    spoofDevice = "VR",

    espShowBox = true,
    espBoxType = "2D",
    espShowName = true,
    espShowDistance = true,
    espShowTracers = true,
    espShowHealthBar = true,
    espShowSkeleton = false,

    aimSmooth = 1,

    flyActive = false,
    flySpeed = 50,
    spinActive = false,
    spinSpeed = 10,
    noFallActive = false,

    headDownActive = false,
    antiAimMode = "None",
    irregularMoveActive = false,

    aimFovColor = Color3.new(1, 1, 1),
    silentFovColor = Color3.new(1, 0, 0),

    showFovCircles = false,
    fovStyle = "Outline",

    undergroundActive = false,
    undergroundDepth = -5,

    triggerbotEnabled = false,
    triggerbotKey = Enum.KeyCode.T,
    triggerbotDelay = 50,
    triggerbotWallCheck = false,
    triggerbotTeamCheck = false,
    triggerbotOnlyADS = false,
    triggerbotActive = false,
    triggerbotLastShot = 0,
}

local aimFovCircle = Drawing.new("Circle")
aimFovCircle.Visible = false
aimFovCircle.Thickness = 2
aimFovCircle.Filled = false
aimFovCircle.NumSides = 64
aimFovCircle.Color = Color3.new(1,1,1)
aimFovCircle.Radius = 0
aimFovCircle.Position = Vector2.new(0,0)
aimFovCircle.Transparency = 0

local silentFovCircle = Drawing.new("Circle")
silentFovCircle.Visible = false
silentFovCircle.Thickness = 2
silentFovCircle.Filled = false
silentFovCircle.NumSides = 64
silentFovCircle.Color = Color3.new(1,0,0)
silentFovCircle.Radius = 0
silentFovCircle.Position = Vector2.new(0,0)
silentFovCircle.Transparency = 0

task.wait(0.5)
local camReady = workspace.CurrentCamera
if not camReady then
    repeat task.wait() camReady = workspace.CurrentCamera until camReady
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cam = workspace.CurrentCamera
        local screenSize = cam.ViewportSize

        local aimShow = S.aimbotActive and S.showFovCircles
        aimFovCircle.Visible = aimShow
        if aimShow and cam.FieldOfView > 0 then
            aimFovCircle.Position = Vector2.new(screenSize.X/2, screenSize.Y/2)
            aimFovCircle.Radius = (S.aimFov / cam.FieldOfView) * screenSize.Y / 2
            aimFovCircle.Color = S.aimFovColor
            aimFovCircle.Filled = (S.fovStyle == "Filled")
            aimFovCircle.Transparency = (S.fovStyle == "Filled") and 0.5 or 0
        end

        local silentShow = S.silentAimActive and S.showFovCircles
        silentFovCircle.Visible = silentShow
        if silentShow and cam.FieldOfView > 0 then
            silentFovCircle.Position = Vector2.new(screenSize.X/2, screenSize.Y/2)
            silentFovCircle.Radius = (S.silentFov / cam.FieldOfView) * screenSize.Y / 2
            silentFovCircle.Color = S.silentFovColor
            silentFovCircle.Filled = (S.fovStyle == "Filled")
            silentFovCircle.Transparency = (S.fovStyle == "Filled") and 0.5 or 0
        end
    end)
end)

local function isEnemy(player)
    return player ~= LocalPlayer and player:GetAttribute("TeamID") ~= LocalPlayer:GetAttribute("TeamID")
end

local function getClosestEnemy()
    local closest = nil
    local minDist = math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = p.Character
            end
        end
    end
    return closest
end

local function isClearLineOfSight(origin, targetPos, targetCharacter)
    local direction = (targetPos - origin)
    local distance = direction.Magnitude
    if distance < 0.01 then return true end
    direction = direction.Unit
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local raycastResult = Workspace:Raycast(origin, direction * distance, rayParams)
    return raycastResult == nil
end

local function toggleVoid(on)
    S.voidActive = on
    if on then
        local flip = true
        local lastPos = HRP.CFrame
        task.spawn(function()
            while S.voidActive do
                local h = HRP
                if h then
                    if flip then h.CFrame = CFrame.new(0, -321730912732103712003733333177387219676767, 0)
                    else h.CFrame = CFrame.new(0, 39126371928633123561237812537, 0) end
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
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
            if lastPos then h.CFrame = lastPos else h.CFrame = CFrame.new(0,10,0) end
        end
    end
end

local orbConn; local orbAngle = 0
local function toggleOrbit(on)
    S.orbActive = on
    if on then
        orbConn = RunService.Heartbeat:Connect(function()
            local enemy = getClosestEnemy()
            if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                orbAngle = orbAngle + 0.5
                HRP.CFrame = CFrame.new(
                    enemy.HumanoidRootPart.Position + Vector3.new(math.cos(orbAngle)*6, 4, math.sin(orbAngle)*6),
                    enemy.HumanoidRootPart.Position
                )
            end
        end)
    else
        if orbConn then orbConn:Disconnect() orbConn = nil end
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
        local meleeCooldowns = {
            "Cooldown", "AttackCooldown", "UseDelay", "SpinCooldown",
            "HeavyAttackCooldown", "AbilityCooldown", "FireCooldown"
        }
        for name, item in pairs(items) do
            if type(item) == "table" then
                local itemName = item.Name or name
                local isMelee = (item.Type == "Melee" or item.Category == "Melee" or (item.Damage and not item.AmmoType))
                if isMelee then
                    for _, field in ipairs(meleeCooldowns) do
                        if item[field] ~= nil then item[field] = 0 end
                    end
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
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Velocity = Vector3.new(0,0,0) end
        end
        local enemy = getClosestEnemy()
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            local enemyRoot = enemy.HumanoidRootPart
            local tickTime = tick() * 4010
            local offsetX = math.cos(tickTime) * 0.1
            local offsetZ = math.sin(tickTime) * 0.1
            root.CFrame = enemyRoot.CFrame * CFrame.new(offsetX, 0, offsetZ)
        end
    end)
end
local function stopFist()
    S.fistActive = false
    if fistConn then fistConn:Disconnect() fistConn = nil end
end
local function toggleFist(on)
    S.fistActive = on
    if on then startFist() else stopFist() end
end

local roitConn
local function startRiot()
    if roitConn then roitConn:Disconnect() end
    roitConn = RunService.Stepped:Connect(function()
        if not S.roitActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Velocity = Vector3.new(0,0,0) end
        end
        local enemy = getClosestEnemy()
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            local enemyRoot = enemy.HumanoidRootPart
            local randomOffset = Vector3.new(math.random(-5, 5), math.random(0, 5), math.random(-5, 5))
            root.CFrame = enemyRoot.CFrame + randomOffset
        end
    end)
end
local function stopRiot()
    S.roitActive = false
    if roitConn then roitConn:Disconnect() roitConn = nil end
end
local function toggleRiot(on)
    S.roitActive = on
    if on then startRiot() else stopRiot() end
end

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
            local c = __k7l8m9.Character
            if not c then return nil end
            if k == "__root" then return c:FindFirstChild("HumanoidRootPart")
            elseif k == "__head" then return c:FindFirstChild("Head") end
            return nil
        end})
        local obj = {}
        function obj:__init()
            self.__active = true
            self.__target = nil
            self.__desync = false
            self.__conn1 = nil
            self.__conn2 = nil
            self.__task1 = nil
            self.__oldfunc = nil
            self.__hadEnemy = false
            self.__teleportedToVoid = false
            self.__preVoidCFrame = nil
            self:__setup()
        end
        function obj:__setup()
            self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__active then return end
                self.__target = self:__find()
            end)
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
                if not self.__desync or self.__curr ~= target then
                    self:__desync_start(target)
                    task.wait(0.1)
                end
                if self.__task1 then
                    task.cancel(self.__task1)
                    self.__task1 = nil
                end
                local head = target.Character:FindFirstChild("Head")
                if not head then return unpack(results) end
                local headPos = head.Position
                local below = headPos - Vector3.new(0, 5, 0)
                local cf = CFrame.lookAt(below, headPos)
                data[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(below, headPos) * CFrame.Angles(cf:ToOrientation()))
                data[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(headPos) * CFrame.Angles(cf:ToOrientation()))
                data[utf8.char(2)] = head
                data[utf8.char(3)] = __w9x0y1:EncodeCFrame(CFrame.new())
                self.__task1 = task.delay(0.15, function() self:__desync_stop() end)
                return unpack(results)
            end
        end
        function obj:__find()
            local myChar = __k7l8m9.Character
            if not myChar then return nil end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end

            local aliveEnemies = 0
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 then
                        aliveEnemies = aliveEnemies + 1
                    end
                end
            end

            if aliveEnemies == 0 then
                if self.__hadEnemy then
                    if not self.__teleportedToVoid then
                        self.__preVoidCFrame = myRoot.CFrame
                        myRoot.CFrame = CFrame.new(0, 1000000, 0)
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                        self.__teleportedToVoid = true
                    end
                end
                return nil
            else
                self.__hadEnemy = true
                self.__teleportedToVoid = false
            end

            local closest = nil
            local closestDist = math.huge
            local MAX_DISTANCE = 200
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character
                if not char then continue end
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if not (root and head and hum and hum.Health > 0) then continue end
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist > MAX_DISTANCE then continue end
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
            return closest
        end
        function obj:__desync_start(target)
            if self.__conn2 then self.__conn2:Disconnect() end
            self.__desync = true
            self.__curr = target
            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__desync then return end
                local myRoot = __z2a3b4.__root
                if not myRoot then return end
                local enemyRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if not enemyRoot then
                    self:__desync_stop()
                    return
                end
                local oldCF = myRoot.CFrame
                local oldVel = myRoot.Velocity
                local oldRV = myRoot.RotVelocity
                myRoot.CFrame = enemyRoot.CFrame * CFrame.new(0, -5, 0)
                __y5z6a7:BindToRenderStep("__restore", 101, function()
                    myRoot.CFrame = oldCF
                    myRoot.Velocity = oldVel
                    myRoot.RotVelocity = oldRV
                    __y5z6a7:UnbindFromRenderStep("__restore")
                end)
            end)
        end
        function obj:__desync_stop()
            self.__desync = false
            self.__curr = nil
            if self.__conn2 then self.__conn2:Disconnect() self.__conn2 = nil end
        end
        function obj:Shutdown()
            self.__active = false
            if self.__conn1 then self.__conn1:Disconnect() end
            if self.__conn2 then self.__conn2:Disconnect() end
            if self.__task1 then task.cancel(self.__task1) end
            if self.__oldfunc then __t6u7v8.StartShooting = self.__oldfunc end
            if self.__preVoidCFrame then
                local myRoot = __z2a3b4.__root
                if myRoot then
                    myRoot.CFrame = self.__preVoidCFrame
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.AssemblyAngularVelocity = Vector3.zero
                end
                self.__preVoidCFrame = nil
            end
        end
        return obj
    end
    function startWallbang()
        if wallbangObject then return end
        local obj = _wallbangFunc()
        obj:__init()
        wallbangObject = obj
        wallbangActive = true
    end
    function stopWallbang()
        if wallbangObject then
            wallbangObject:Shutdown()
            wallbangObject = nil
            wallbangActive = false
        end
    end
end
local function toggleWallbang(on)
    S.wallbangActive = on
    if on then
        startWallbang()
    else
        stopWallbang()
    end
end

local function toggleUnderground(on)
    S.undergroundActive = on
    _G.SetUndergroundExt(on)
    if on then
        _G.SetUndergroundDepthExt(S.undergroundDepth)
    end
end

local noclipConn
local function startNoClip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not S.noclipActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end
local function stopNoClip()
    S.noclipActive = false
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end
local function toggleNoclip(on)
    S.noclipActive = on
    if on then startNoClip() else stopNoClip() end
end

local espGui = Instance.new("ScreenGui")
espGui.Name = "MobileESP"
espGui.ResetOnSpawn = false
espGui.Parent = game.CoreGui

local MAX_ESP = 60
local espPool = {}

for i = 1, MAX_ESP do
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0,0,0,0)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false

    local outline = Instance.new("Frame")
    outline.Size = UDim2.new(1,2,1,2)
    outline.Position = UDim2.new(0,-1,0,-1)
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 2
    outline.BorderColor3 = Color3.new(1,1,1)
    outline.Parent = box

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1,0,1,0)
    fill.BackgroundTransparency = 0.85
    fill.BackgroundColor3 = Color3.new(0,0,0)
    fill.Parent = box

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.TextSize = 15
    name.Font = Enum.Font.SourceSans
    name.TextColor3 = Color3.new(1,1,1)
    name.Text = ""
    name.Parent = box

    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency = 1
    dist.TextSize = 20
    dist.Font = Enum.Font.SourceSans
    dist.TextColor3 = Color3.new(0.8,0.8,0.8)
    dist.Text = ""
    dist.Parent = box

    local hpBar = Instance.new("Frame")
    hpBar.Size = UDim2.new(10,0,0,9)
    hpBar.BackgroundColor3 = Color3.new(0,0,0)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = box
    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(-1.0,0,-1,0)
    hpFill.BorderSizePixel = 0
    hpFill.BackgroundColor3 = Color3.new(0,1,0)
    hpFill.Parent = hpBar

    box.Parent = espGui
    table.insert(espPool, {box = box, outline = outline, fill = fill, name = name, dist = dist, hpBar = hpBar, hpFill = hpFill})
end

local function hideAllESP()
    for _, esp in ipairs(espPool) do
        esp.box.Visible = false
    end
end

local function updateMobileESP()
    if not S.espActive then
        hideAllESP()
        return
    end
    local myChar = LocalPlayer.Character
    if not myChar then hideAllESP(); return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then hideAllESP(); return end

    local cam = workspace.CurrentCamera
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if player:GetAttribute("TeamID") == LocalPlayer:GetAttribute("TeamID") then continue end
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root and head and hum and hum.Health > 0 then
                table.insert(enemies, {Char = char, Root = root, Head = head, Hum = hum, Player = player})
            end
        end
    end

    local idx = 1
    for _, enemy in ipairs(enemies) do
        if idx > MAX_ESP then break end
        local head = enemy.Head
        local root = enemy.Root
        local hum = enemy.Hum
        local headPos, onScreen = cam:WorldToViewportPoint(head.Position)
        local rootPos = cam:WorldToViewportPoint(root.Position)

        if onScreen then
            local height = (root.Position - head.Position).Magnitude * 3.0
            local width = height * 1.0
            local boxX = headPos.X - width/2
            local boxY = headPos.Y

            local esp = espPool[idx]
            esp.box.Visible = true
            esp.box.Position = UDim2.new(0, boxX, 0, boxY)
            esp.box.Size = UDim2.new(0, width, 0, height)
            esp.outline.BorderColor3 = Color3.fromHSV(hum.Health/hum.MaxHealth*0.33, 1, 1)

            if S.espShowName then
                esp.name.Text = enemy.Player.Name
                esp.name.Position = UDim2.new(0.5,0,0,-16)
                esp.name.Visible = true
            else
                esp.name.Visible = false
            end

            if S.espShowDistance then
                esp.dist.Text = math.floor((myRoot.Position - root.Position).Magnitude) .. "m"
                esp.dist.Position = UDim2.new(0.5,0,1,9)
                esp.dist.Visible = true
            else
                esp.dist.Visible = false
            end

            if S.espShowHealthBar then
                esp.hpBar.Visible = true
                esp.hpFill.Size = UDim2.new(hum.Health/hum.MaxHealth, 1, 1, 0)
                esp.hpFill.BackgroundColor3 = Color3.fromHSV(hum.Health/hum.MaxHealth*0.33, 1, 1)
            else
                esp.hpBar.Visible = false
            end

            idx = idx + 1
        end
    end

    for i = idx, MAX_ESP do
        espPool[i].box.Visible = false
    end
end

local espConn
local function toggleESP(on)
    S.espActive = on
    if on then
        if espConn then espConn:Disconnect() end
        espConn = RunService.RenderStepped:Connect(updateMobileESP)
    else
        if espConn then espConn:Disconnect(); espConn = nil end
        hideAllESP()
    end
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
local function toggleAimbot(on)
    S.aimbotActive = on
    if on then
        if aimbotConn then aimbotConn:Disconnect() end
        aimbotConn = RunService.RenderStepped:Connect(function(dt)
            if not S.aimbotActive then return end
            local targetPart = nil
            local camPos = Camera.CFrame.Position
            local camDir = Camera.CFrame.LookVector
            local closestAngle = S.aimFov
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                if S.teamCheck and not isEnemy(p) then continue end
                local char = p.Character
                if char then
                    local part = char:FindFirstChild(S.aimTargetPart)
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if part and hum and hum.Health > 0 then
                        local toTarget = (part.Position - camPos).Unit
                        local angle = math.acos(math.clamp(camDir:Dot(toTarget), -1, 1))
                        local degrees = math.deg(angle)
                        if degrees <= closestAngle then
                            if isClearLineOfSight(camPos, part.Position, char) then
                                closestAngle = degrees
                                targetPart = part
                            end
                        end
                    end
                end
            end
            if targetPart then
                local targetCF = CFrame.lookAt(camPos, targetPart.Position)
                if S.aimSmooth <= 0.01 then
                    if CameraControllerAimbot and CameraControllerAimbot.MimicRotation then
                        pcall(function()
                            CameraControllerAimbot:MimicRotation(targetCF)
                        end)
                    else
                        Camera.CFrame = targetCF
                    end
                else
                    local smoothFactor = 1 - math.pow(0.001, dt / S.aimSmooth)
                    local newCF = Camera.CFrame:Lerp(targetCF, math.clamp(smoothFactor, 0, 1))
                    if CameraControllerAimbot and CameraControllerAimbot.MimicRotation then
                        pcall(function()
                            CameraControllerAimbot:MimicRotation(newCF)
                        end)
                    else
                        Camera.CFrame = newCF
                    end
                end
            end
        end)
    else
        if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    end
end

local originalGunFunctions = {}
local function saveOriginalGunFunctions()
    local ok, Gun = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
    if not ok or not Gun then return false end
    originalGunFunctions.StartAiming = Gun.StartAiming
    originalGunFunctions.GetAimSpeed = Gun.GetAimSpeed
    originalGunFunctions.Equip = Gun.Equip
    originalGunFunctions.StartShooting = Gun.StartShooting
    originalGunFunctions.FinishShooting = Gun.FinishShooting
    originalGunFunctions.ShootBurst = Gun.ShootBurst
    return true
end
task.spawn(function() task.wait(2); saveOriginalGunFunctions() end)

local function applyGunEnhancements()
    local ok, Gun = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
    if not ok or not Gun then return end

    if S.instantAdsEnabled then
        Gun.StartAiming = function(self, p)
            self:SetReplicate("IsAiming", true)
            self.StopSprinting:Fire()
            self.ViewModel:SetAiming(true)
            self:SetReplicate("FOVOffset", self.Info.AimFOVOffset)
            if self.ViewModel.CurrentAimValue then self.ViewModel.CurrentAimValue = 1 end
            return true, "StartAiming"
        end
        Gun.GetAimSpeed = function(self) return 999 end
    else
        if originalGunFunctions.StartAiming then Gun.StartAiming = originalGunFunctions.StartAiming end
        if originalGunFunctions.GetAimSpeed then Gun.GetAimSpeed = originalGunFunctions.GetAimSpeed end
    end

    if S.noEquipAnimEnabled then
        Gun.Equip = function(self, ...)
            local r = {originalGunFunctions.Equip(self, ...)}
            if self.ViewModel then
                self.ViewModel:StopAnimation("Equip")
                self.ViewModel:StopAnimation("EquipEmpty")
            end
            return table.unpack(r)
        end
    else
        if originalGunFunctions.Equip then Gun.Equip = originalGunFunctions.Equip end
    end

    if S.silentAimActive or S.noShootAnimEnabled then
        local currentShooting = Gun.StartShooting

        -- ── 人偶 / 标把 追踪 ──────────────────────────────────────────────
        -- 练习场靶子 (RangeTarget) 和人偶 (PracticeDummy) 不在 Players 列表里，
        -- 它们由 RIVALS 的 EnemyController 管理，但 ARCH 没有接那个 controller。
        -- 改用 CollectionService 标签 + Workspace 扫描两路兜底。
        local _NPC_CACHE = {}
        local _NPC_CACHE_AT  = 0
        local _NPC_CACHE_TTL = 1.5  -- 秒, 减少每帧扫 Workspace 的开销

        local function _collectNPCModels()
            local now = tick()
            if now - _NPC_CACHE_AT < _NPC_CACHE_TTL then return _NPC_CACHE end
            _NPC_CACHE_AT = now
            local out = {}
            local cs  = game:GetService("CollectionService")

            -- 路线 A: CollectionService 标签 (Yuno 用的方案)
            for _, tagged in ipairs(cs:GetTagged("PracticeDummy")) do
                if tagged:IsA("Model") and tagged.Parent then
                    out[#out+1] = tagged
                end
            end
            for _, tagged in ipairs(cs:GetTagged("RangeTarget")) do
                if tagged:IsA("Model") and tagged.Parent then
                    out[#out+1] = tagged
                end
            end

            -- 路线 B: 扫 Workspace，按 HitboxHead + Humanoid 识别
            -- (标把可能没有 Humanoid，所以只要有 HitboxHead 就进候选)
            if #out == 0 then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Parent
                        and obj:FindFirstChild("HitboxHead")
                        and not Players:GetPlayerFromCharacter(obj)
                        and obj ~= LocalPlayer.Character then
                        out[#out+1] = obj
                    end
                end
            end

            _NPC_CACHE = out
            return out
        end
        -- ─────────────────────────────────────────────────────────────────

        Gun.StartShooting = function(self, p1, p2)
            if S.silentAimActive then
                local targetPartInstance = nil
                local targetPlayer = nil
                local camPos = Camera.CFrame.Position
                local camDir = Camera.CFrame.LookVector
                local closestAngle = S.silentFov

                -- ① 真玩家 (原逻辑不变)
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LocalPlayer then continue end
                    if p:GetAttribute("TeamID") == LocalPlayer:GetAttribute("TeamID") then continue end
                    local char = p.Character
                    if char then
                        local part = char:FindFirstChild(S.silentTargetPart)
                        if part then
                            local toTarget = (part.Position - camPos).Unit
                            local angle = math.acos(math.clamp(camDir:Dot(toTarget), -1, 1))
                            local degrees = math.deg(angle)
                            if degrees <= closestAngle then
                                if not S.wallCheck or isClearLineOfSight(camPos, part.Position, char) then
                                    closestAngle = degrees
                                    targetPartInstance = part
                                    targetPlayer = p
                                end
                            end
                        end
                    end
                end

                -- ② 人偶 / 标把 (新增)
                if S.silentTargetNPC then
                    for _, npcModel in ipairs(_collectNPCModels()) do
                        -- 优先 HitboxHead，fallback HumanoidRootPart / Head
                        local partNames = {"HitboxHead", "HitboxBody", "Head", "HumanoidRootPart"}
                        if S.silentTargetPart == "HumanoidRootPart" then
                            partNames = {"HitboxBody", "HumanoidRootPart", "HitboxHead", "Head"}
                        end
                        local hum = npcModel:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then continue end -- 跳过死亡人偶
                        for _, pname in ipairs(partNames) do
                            local part = npcModel:FindFirstChild(pname)
                            if part and part:IsA("BasePart") then
                                local toTarget = (part.Position - camPos).Unit
                                local angle = math.acos(math.clamp(camDir:Dot(toTarget), -1, 1))
                                local degrees = math.deg(angle)
                                if degrees <= closestAngle then
                                    if not S.wallCheck or isClearLineOfSight(camPos, part.Position, npcModel) then
                                        closestAngle = degrees
                                        targetPartInstance = part
                                        targetPlayer = nil  -- NPC 没有对应 Player
                                    end
                                end
                                break
                            end
                        end
                    end
                end

                if targetPartInstance then
                    if targetPlayer and getgenv().IsKatanaDeflecting and getgenv().IsKatanaDeflecting(targetPlayer) then
                        return currentShooting(self, p1, p2)
                    end
                    local oldCamCF = Camera.CFrame
                    Camera.CFrame = CFrame.lookAt(camPos, targetPartInstance.Position)
                    local vm = self.ViewModel
                    local savedPlay
                    if vm and S.noShootAnimEnabled then savedPlay = vm.PlayAnimation; vm.PlayAnimation = function() end end
                    local results = {currentShooting(self, p1, p2)}
                    if vm and savedPlay then vm.PlayAnimation = savedPlay end
                    Camera.CFrame = oldCamCF
                    if vm and S.noShootAnimEnabled then
                        for _, name in ipairs({"Shoot","Fire","ShootBurst","Shoot_ADS","ShootHip","ShootEmpty","ShootADS","Burst"}) do
                            vm:StopAnimation(name)
                        end
                    end
                    return unpack(results)
                end
            end
            if S.noShootAnimEnabled then
                local vm = self.ViewModel
                local savedPlay
                if vm then savedPlay = vm.PlayAnimation; vm.PlayAnimation = function() end end
                local result = {currentShooting(self, p1, p2)}
                if vm and savedPlay then
                    vm.PlayAnimation = savedPlay
                    for _, name in ipairs({"Shoot","Fire","ShootBurst","Shoot_ADS","ShootHip","ShootEmpty","ShootADS","Burst"}) do
                        vm:StopAnimation(name)
                    end
                end
                return table.unpack(result)
            end
            return currentShooting(self, p1, p2)
        end
    end

    if S.noShootAnimEnabled then
        if originalGunFunctions.FinishShooting then
            local currentFinish = Gun.FinishShooting
            Gun.FinishShooting = function(self, ...)
                local vm = self.ViewModel
                local savedPlay
                if vm then savedPlay = vm.PlayAnimation; vm.PlayAnimation = function() end end
                local result = {currentFinish(self, ...)}
                if vm and savedPlay then
                    vm.PlayAnimation = savedPlay
                    vm:StopAnimation("Shoot"); vm:StopAnimation("Fire")
                end
                return table.unpack(result)
            end
        end
        if originalGunFunctions.ShootBurst then
            local currentBurst = Gun.ShootBurst
            Gun.ShootBurst = function(self, ...)
                local vm = self.ViewModel
                local savedPlay
                if vm then savedPlay = vm.PlayAnimation; vm.PlayAnimation = function() end end
                local result = {currentBurst(self, ...)}
                if vm and savedPlay then
                    vm.PlayAnimation = savedPlay
                    for _, name in ipairs({"Shoot","Fire","ShootBurst","Shoot_ADS","ShootHip","ShootEmpty","ShootADS","Burst"}) do
                        vm:StopAnimation(name)
                    end
                end
                return table.unpack(result)
            end
        end
    else
        if originalGunFunctions.FinishShooting then Gun.FinishShooting = originalGunFunctions.FinishShooting end
        if originalGunFunctions.ShootBurst then Gun.ShootBurst = originalGunFunctions.ShootBurst end
    end
end

local function toggleSilentAim(on)
    S.silentAimActive = on
    applyGunEnhancements()
end

local originalGunStats = {}
local gunExceptions = {} -- all weapon types, including Sniper, are supported
local function initRapidFireItems()
    if not ReplicatedStorage then return end
    local itemLib = ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("ItemLibrary")
    if not itemLib then task.wait(1); return initRapidFireItems() end
    local success, library = pcall(require, itemLib)
    if not success or type(library) ~= "table" then return end
    local items = library.Items
    if not items then return end
    for name, data in pairs(items) do
        if typeof(data) == "table" and not gunExceptions[name] then
            local stats = {}
            if data.ShootCooldown ~= nil then stats.ShootCooldown = data.ShootCooldown end
            if data.ShootBurstCooldown ~= nil then stats.ShootBurstCooldown = data.ShootBurstCooldown end
            if data.ShootSpread ~= nil then stats.ShootSpread = data.ShootSpread end
            if data.ShootAccuracy ~= nil then stats.ShootAccuracy = data.ShootAccuracy end
            if data.ShootRecoil ~= nil then stats.ShootRecoil = data.ShootRecoil end
            if next(stats) then originalGunStats[name] = stats end
        end
    end
end
task.spawn(initRapidFireItems)
local function applyRapidFire()
    local ok, lib = pcall(function() return require(ReplicatedStorage.Modules.ItemLibrary) end)
    if not ok then return end
    local items = lib.Items
    if not items then return end
    local delaySec = S.fireDelay / 1000
    for name, data in pairs(items) do
        if typeof(data) == "table" and not gunExceptions[name] then
            -- Some weapons (notably Sniper variants) may not have been captured
            -- during the first scan. Patch only fields that actually exist.
            if data.ShootCooldown ~= nil then data.ShootCooldown = delaySec end
            if data.ShootBurstCooldown ~= nil then data.ShootBurstCooldown = delaySec end
            if data.ShootSpread ~= nil then data.ShootSpread = 0 end
            if data.ShootAccuracy ~= nil then data.ShootAccuracy = 0 end
            if data.ShootRecoil ~= nil then data.ShootRecoil = 0 end
        end
    end
end
local function restoreRapidFire()
    local ok, lib = pcall(function() return require(ReplicatedStorage.Modules.ItemLibrary) end)
    if not ok then return end
    local items = lib.Items
    if not items then return end
    for name, orig in pairs(originalGunStats) do
        local data = items[name]
        if data then
            if orig.ShootCooldown ~= nil then data.ShootCooldown = orig.ShootCooldown end
            if orig.ShootBurstCooldown ~= nil then data.ShootBurstCooldown = orig.ShootBurstCooldown end
            if orig.ShootSpread ~= nil then data.ShootSpread = orig.ShootSpread end
            if orig.ShootAccuracy ~= nil then data.ShootAccuracy = orig.ShootAccuracy end
            if orig.ShootRecoil ~= nil then data.ShootRecoil = orig.ShootRecoil end
        end
    end
end
local function toggleRapidFire(on)
    S.rapidFireActive = on
    if on then applyRapidFire() else restoreRapidFire() end
end

local originalGetSpread, originalGUSpread
local function patchGunSpread()
    if S.noSpreadEnabled then
        local ok, Gun = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
        if ok and Gun and Gun.GetSpread then
            if not originalGetSpread then originalGetSpread = Gun.GetSpread end
            Gun.GetSpread = function(...) return Vector2.new(0, 0) end
        end
        pcall(function()
            local gu = require(ReplicatedStorage.Modules:WaitForChild("GameplayUtility", 5))
            if gu and gu.GetSpread then
                if not originalGUSpread then originalGUSpread = gu.GetSpread end
                gu.GetSpread = function() return CFrame.identity end
            end
        end)
    else
        if originalGetSpread then
            pcall(function()
                local Gun = require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
                Gun.GetSpread = originalGetSpread
            end)
        end
        if originalGUSpread then
            pcall(function()
                local gu = require(ReplicatedStorage.Modules:WaitForChild("GameplayUtility"))
                gu.GetSpread = originalGUSpread
            end)
        end
    end
end

local originalSmokeUpdate, originalCloudUpdate
local function applyNoSmoke()
    if S.noSmokeEnabled then
        pcall(function()
            local SmokeScreen = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("ClientReplicatedClasses"):WaitForChild("ClientFighter"):WaitForChild("FighterInterface"):WaitForChild("SmokeScreen", 10))
            if SmokeScreen and SmokeScreen.Update then
                if not originalSmokeUpdate then originalSmokeUpdate = SmokeScreen.Update end
                SmokeScreen.Update = function(self)
                    self._smoke_cloud_spring.Target = 0
                    self._smoke_cloud_cover.Transparency = 1
                    if self._smoke_cloud_dof then
                        self._smoke_cloud_dof.Parent = nil
                    end
                end
            end
        end)
        pcall(function()
            local SmokeCloud = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("SmokeCloud", 10))
            if SmokeCloud and SmokeCloud.Update then
                if not originalCloudUpdate then originalCloudUpdate = SmokeCloud.Update end
                SmokeCloud.Update = function(self)
                    if self.Model then
                        self.Model:Destroy()
                    end
                    return true
                end
            end
        end)
    else
        if originalSmokeUpdate then
            pcall(function()
                local SmokeScreen = require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.FighterInterface.SmokeScreen)
                SmokeScreen.Update = originalSmokeUpdate
            end)
        end
        if originalCloudUpdate then
            pcall(function()
                local SmokeCloud = require(LocalPlayer.PlayerScripts.Modules.SmokeCloud)
                SmokeCloud.Update = originalCloudUpdate
            end)
        end
    end
end

local originalFlashFunc
local function applyNoFlash()
    if S.noFlashEnabled then
        pcall(function()
            local Flashed = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("ClientReplicatedClasses"):WaitForChild("ClientFighter"):WaitForChild("FighterInterface"):WaitForChild("Flashed", 10))
            if Flashed and Flashed.Flash then
                if not originalFlashFunc then originalFlashFunc = Flashed.Flash end
                Flashed.Flash = function() end
            end
        end)
    else
        if originalFlashFunc then
            pcall(function()
                local Flashed = require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.FighterInterface.Flashed)
                Flashed.Flash = originalFlashFunc
            end)
        end
    end
end

local originalReplicateControls
local function applyDeviceSpoof()
    pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
        if S.deviceSpoofEnabled then
            if not originalReplicateControls then
                originalReplicateControls = FighterController._ReplicateControls
            end
            FighterController._ReplicateControls = function(self)
                remote:FireServer(S.spoofDevice)
                self._last_controls_replicated_time = tick()
            end
            remote:FireServer(S.spoofDevice)
        else
            if originalReplicateControls then
                FighterController._ReplicateControls = originalReplicateControls
            end
        end
    end)
end

local speedConn
local function setSpeed(val)
    if val then S.speedValue = val end
    -- 如果 speed hack 未开启，断开锁定并还原默认速度
    if not S.speedEnabled then
        if speedConn then speedConn:Disconnect(); speedConn = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
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
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                hum:ChangeState("Jumping")
            end
        end
    end
end)

local FlyEnabled = false
local flyAttachment, flyVelocity, flyAlign
local flyHumanoid, flyRoot

local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local function setupFlyPhysics()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    flyHumanoid = char:WaitForChild("Humanoid")
    flyRoot = char:WaitForChild("HumanoidRootPart")
    
    if FlyEnabled then
        if flyAttachment then flyAttachment:Destroy() end
        flyHumanoid.PlatformStand = true
        
        flyAttachment = Instance.new("Attachment", flyRoot)
        flyVelocity = Instance.new("LinearVelocity", flyAttachment)
        flyVelocity.MaxForce = 9e9
        flyVelocity.VectorVelocity = Vector3.zero
        flyVelocity.Attachment0 = flyAttachment
        
        flyAlign = Instance.new("AlignOrientation", flyAttachment)
        flyAlign.MaxTorque = 9e9
        flyAlign.Responsiveness = 200
        flyAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
        flyAlign.Attachment0 = flyAttachment
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    setupFlyPhysics()
end)

setupFlyPhysics()

RunService.RenderStepped:Connect(function()
    if FlyEnabled and flyRoot and workspace.CurrentCamera and flyVelocity and flyAlign then
        local cam = workspace.CurrentCamera
        local moveVector = Controls:GetMoveVector()
        local speed = S.flySpeed or 50
        
        if moveVector.Magnitude > 0 then
            flyVelocity.VectorVelocity = (cam.CFrame.LookVector * -moveVector.Z + cam.CFrame.RightVector * moveVector.X).Unit * speed
        else
            flyVelocity.VectorVelocity = Vector3.zero
        end
        
        flyAlign.CFrame = cam.CFrame
    end
end)

local function EnableFly()
    FlyEnabled = true
    setupFlyPhysics()
end

local function DisableFly()
    FlyEnabled = false
    
    if flyHumanoid then flyHumanoid.PlatformStand = false end
    if flyAttachment then flyAttachment:Destroy() end
    
    flyAttachment = nil
    flyVelocity = nil
    flyAlign = nil
end

local function toggleFly(on)
    S.flyActive = on
    if on then
        EnableFly()
    else
        DisableFly()
    end
end

local spinConn
local function toggleSpin(on)
    S.spinActive = on
    if on then
        spinConn = RunService.Stepped:Connect(function(_, dt)
            if not S.spinActive then return end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(S.spinSpeed * dt * 60), 0)
            end
        end)
    else
        if spinConn then spinConn:Disconnect(); spinConn = nil end
    end
end

local irregularMoveConn
local function startIrregularMove()
    stopIrregularMove()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    irregularMoveConn = RunService.Stepped:Connect(function()
        if not S.irregularMoveActive then return end
        char = LocalPlayer.Character
        if not char then return end
        root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local vel = root.Velocity
        if vel.Magnitude > 1 then
            local randX = math.random(-3, 3) / 10
            local randZ = math.random(-3, 3) / 10
            root.CFrame = root.CFrame * CFrame.new(randX, 0, randZ)
        end
    end)
end

local function stopIrregularMove()
    if irregularMoveConn then
        irregularMoveConn:Disconnect()
        irregularMoveConn = nil
    end
end

local function toggleNoFall(on)
    S.noFallActive = on
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if on then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            else
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            end
        end
    end)
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local triggerbotConn

local function triggerbot_IsADS()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("GunMixin") then
        local gun = require(tool.GunMixin)
        return gun.IsAiming
    end
    pcall(function()
        local fc = require(LocalPlayer.PlayerScripts.Controllers.FighterController)
        local fighter = fc:GetFighter(LocalPlayer)
        if fighter and fighter.IsAiming then
            return fighter:IsAiming()
        end
    end)
    return false
end

local function triggerbot_GetTarget()
    local camPos = Camera.CFrame.Position
    local camDir = Camera.CFrame.LookVector
    local closestAngle = S.silentFov
    local targetPart = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if S.triggerbotTeamCheck and p:GetAttribute("TeamID") == LocalPlayer:GetAttribute("TeamID") then continue end
        local char = p.Character
        if char then
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local toTarget = (head.Position - camPos).Unit
                local angle = math.acos(math.clamp(camDir:Dot(toTarget), -1, 1))
                local degrees = math.deg(angle)
                if degrees <= closestAngle then
                    if not S.triggerbotWallCheck or isClearLineOfSight(camPos, head.Position, char) then
                        closestAngle = degrees
                        targetPart = head
                    end
                end
            end
        end
    end
    return targetPart
end

local function triggerbot_Shoot()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Replication"):FindFirstChild("Fighter"):FindFirstChild("FireServer")
        if remote then
            remote:FireServer()
        else
            VirtualInputManager:SendMouseButtonEvent(
                ViewportSize.X/2, ViewportSize.Y/2,
                0, true, game, 1
            )
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(
                ViewportSize.X/2, ViewportSize.Y/2,
                0, false, game, 1
            )
        end
    end)
end

local function triggerbotUpdate()
    if not S.triggerbotEnabled then return end
    if not UserInputService:IsKeyDown(S.triggerbotKey) then
        S.triggerbotActive = false
        return
    end
    if S.triggerbotOnlyADS and not triggerbot_IsADS() then return end
    local target = triggerbot_GetTarget()
    if target then
        local now = tick()
        local delay = S.triggerbotDelay / 1000
        if now - S.triggerbotLastShot >= delay then
            S.triggerbotLastShot = now
            triggerbot_Shoot()
        end
    end
end

local function startTriggerbot()
    if triggerbotConn then triggerbotConn:Disconnect() end
    triggerbotConn = RunService.RenderStepped:Connect(triggerbotUpdate)
end

local function stopTriggerbot()
    S.triggerbotEnabled = false
    if triggerbotConn then triggerbotConn:Disconnect(); triggerbotConn = nil end
end

local function toggleTriggerbot(on)
    S.triggerbotEnabled = on
    if on then
        startTriggerbot()
    else
        stopTriggerbot()
    end
end

local wallbangHeadObject = nil
local wallbangHeadActive = false
do
    local function _createWallbangHead()
        local __a1b2c3 = setmetatable({}, {__index = function(_, s) return cloneref(game:GetService(s)) end})
        local __v2w3x4 = __a1b2c3.Players
        local __y5z6a7 = __a1b2c3.RunService
        local __b8c9d0 = __a1b2c3.ReplicatedStorage
        local __e1f2g3 = __a1b2c3.Workspace
        local __h4i5j6 = __a1b2c3.UserInputService
        local __k7l8m9 = __v2w3x4.LocalPlayer
        local __n0o1p2 = __e1f2g3.CurrentCamera
        local __q3r4s5 = __k7l8m9.PlayerScripts
        local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
        local __w9x0y1 = require(__b8c9d0.Modules.Utility)

        local __z2a3b4 = setmetatable({}, {
            __index = function(_, __c5d6e7)
                local __f8g9h0 = __k7l8m9.Character
                if not __f8g9h0 then return nil end
                if __c5d6e7 == "__root" then
                    return __f8g9h0:FindFirstChild("HumanoidRootPart")
                elseif __c5d6e7 == "__head" then
                    return __f8g9h0:FindFirstChild("Head")
                end
                return nil
            end
        })

        local obj = {}
        function obj:__init()
            self.__active = true
            self.__target = nil
            self.__desync = false
            self.__conn1 = nil
            self.__conn2 = nil
            self.__task1 = nil
            self.__oldfunc = nil
            self.__hadEnemy = false
            self.__teleportedToVoid = false
            self.__preVoidCFrame = nil
            self:__setup()
        end

        function obj:__setup()
            self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__active then return end
                self.__target = self:__find()
            end)

            local __l4m5n6 = __t6u7v8.StartShooting
            self.__oldfunc = __l4m5n6
            __t6u7v8.StartShooting = function(__o7p8q9, ...)
                if S.silentAimActive then return __l4m5n6(__o7p8q9, ...) end
                local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
                if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                    return unpack(__r0s1t2)
                end

                local __u3v4w5 = __r0s1t2[3]
                if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                    return unpack(__r0s1t2)
                end

                __r0s1t2[4] = true
                local __x6y7z8 = self.__target

                if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                    return unpack(__r0s1t2)
                end

                if not self.__desync or self.__curr ~= __x6y7z8 then
                    self:__desync_start(__x6y7z8)
                    task.wait(0.1)
                end

                if self.__task1 then
                    task.cancel(self.__task1)
                    self.__task1 = nil
                end

                local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
                if not __a9b0c1 then return unpack(__r0s1t2) end

                local __d2e3f4 = __a9b0c1.Position
                local __g5h6i7 = __a9b0c1.CFrame
                local __j8k9l0 = __d2e3f4 
                local __m1n2o3 = CFrame.lookAt(__j8k9l0, __d2e3f4 + __a9b0c1.CFrame.LookVector)
                local __p4q5r6 = __g5h6i7:ToObjectSpace(CFrame.new(__d2e3f4 + Vector3.new(math.random() * 0.1, math.random() * 0.1, math.random() * 0.1)))

                __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(__j8k9l0, __d2e3f4 + __a9b0c1.CFrame.LookVector))
                __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4))
                __u3v4w5[utf8.char(2)] = __a9b0c1
                __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)

                self.__task1 = task.delay(0.15, function()
                    self:__desync_stop()
                end)

                return unpack(__r0s1t2)
            end
        end

        function obj:__find()
            local myChar = __k7l8m9.Character
            if not myChar then return nil end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end

            local aliveEnemies = 0
            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 then
                        aliveEnemies = aliveEnemies + 1
                    end
                end
            end

            if aliveEnemies == 0 then
                if self.__hadEnemy then
                    if not self.__teleportedToVoid then
                        self.__preVoidCFrame = myRoot.CFrame
                        myRoot.CFrame = CFrame.new(0, 1000000, 0)
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                        self.__teleportedToVoid = true
                    end
                end
                return nil
            else
                self.__hadEnemy = true
                self.__teleportedToVoid = false
            end

            local closest = nil
            local closestDist = math.huge
            local MAX_DISTANCE = 200

            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end

                local char = player.Character
                if not char then continue end

                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildWhichIsA("Humanoid")

                if not (root and head and hum and hum.Health > 0) then continue end

                local dist = (myRoot.Position - root.Position).Magnitude

                if dist > MAX_DISTANCE then continue end

                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end

            return closest
        end

        function obj:__desync_start(target)
            if self.__conn2 then self.__conn2:Disconnect() end
            self.__desync = true
            self.__curr = target

            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__desync then return end
                local myRoot = __z2a3b4.__root
                if not myRoot then return end

                local enemyHead = target.Character and target.Character:FindFirstChild("Head")
                if not enemyHead then
                    self:__desync_stop()
                    return
                end

                local oldCF = myRoot.CFrame
                local oldVel = myRoot.Velocity
                local oldRV = myRoot.RotVelocity

                myRoot.CFrame = enemyHead.CFrame

                __y5z6a7:BindToRenderStep("__restore", 101, function()
                    myRoot.CFrame = oldCF
                    myRoot.Velocity = oldVel
                    myRoot.RotVelocity = oldRV
                    __y5z6a7:UnbindFromRenderStep("__restore")
                end)
            end)
        end

        function obj:__desync_stop()
            self.__desync = false
            self.__curr = nil
            if self.__conn2 then
                self.__conn2:Disconnect()
                self.__conn2 = nil
            end
        end

        function obj:Shutdown()
            self.__active = false
            if self.__conn1 then self.__conn1:Disconnect() end
            if self.__conn2 then self.__conn2:Disconnect() end
            if self.__task1 then task.cancel(self.__task1) end
            if self.__oldfunc then
                __t6u7v8.StartShooting = self.__oldfunc
            end
            if self.__preVoidCFrame then
                local myRoot = __z2a3b4.__root
                if myRoot then
                    myRoot.CFrame = self.__preVoidCFrame
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.AssemblyAngularVelocity = Vector3.zero
                end
                self.__preVoidCFrame = nil
            end
        end

        return obj
    end

    function startWallbangHead()
        if wallbangHeadObject then return end
        local obj = _createWallbangHead()
        obj:__init()
        wallbangHeadObject = obj
        wallbangHeadActive = true
    end

    function stopWallbangHead()
        if wallbangHeadObject then
            wallbangHeadObject:Shutdown()
            wallbangHeadObject = nil
            wallbangHeadActive = false
        end
    end
end

local function toggleWallbangHead(on)
    S.wallbangHeadActive = on
    if on then
        stopWallbang()
        startWallbangHead()
    else
        stopWallbangHead()
    end
end

function ApplyAllSettings()
    toggleAimbot(false)
    toggleSilentAim(false)
    toggleESP(false)
    toggleVoid(false)
    toggleOrbit(false)
    toggleFist(false)
    toggleRiot(false)
    toggleScythe(false)
    toggleWallbang(false)
    toggleWallbangHead(false)
    toggleNoclip(false)
    toggleFly(false)
    toggleSpin(false)
    toggleNoFall(false)
    toggleRapidFire(false)
    stopIrregularMove()
    stopTriggerbot()
    _G.StopAntiAimExt()
    toggleUnderground(false)

    if S.aimbotActive then toggleAimbot(true) end
    if S.silentAimActive then toggleSilentAim(true) end
    if S.espActive then toggleESP(true) end
    if S.voidActive then toggleVoid(true) end
    if S.orbActive then toggleOrbit(true) end
    if S.fistActive then toggleFist(true) end
    if S.roitActive then toggleRiot(true) end
    if S.scytheActive then toggleScythe(true) end
    if S.wallbangActive then toggleWallbang(true) end
    if S.wallbangHeadActive then toggleWallbangHead(true) end
    if S.noclipActive then toggleNoclip(true) end
    if S.flyActive then toggleFly(true) end
    if S.spinActive then toggleSpin(true) end
    if S.noFallActive then toggleNoFall(true) end
    if S.rapidFireActive then toggleRapidFire(true) end
    if S.irregularMoveActive then startIrregularMove() end
    if S.triggerbotEnabled then startTriggerbot() end
    if _G.AntiAimSettings.enabled then
        _G.StartAntiAimExt()
    end
    if S.undergroundActive then toggleUnderground(true) end
    setSpeed(S.speedValue)
    applyGunEnhancements()
    patchGunSpread()
    applyNoSmoke()
    applyNoFlash()
    applyDeviceSpoof()
end

-- [[ RAGE ENGINE COMPATIBILITY LAYER ]]
-- Source: 827luahook.lua (Config/State/helpers required by the extracted Rage engine)
local lp = LocalPlayer
local Camera = Workspace.CurrentCamera
local CollectionService = game:GetService("CollectionService")
local VirtualInputMgr = VirtualInputManager
local RageVisuals = {
    notifyTarget = function(...) end
}
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

local function getSafePlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        list[#list + 1] = p
    end
    return list
end

local Rivals = { Ready = false }
pcall(function()
    Rivals.Fighter = FighterController
    Rivals.Util = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"))
    Rivals.Enums = _enumLib
    Rivals.ItemLib = _itmLib
    Rivals.Ready = Rivals.Fighter ~= nil and Rivals.Util ~= nil
end)

local Config = {
    GUIToggleKey = "RightShift",
    SilentAim = false, SilentAimVisCheck = false, SilentAimJitter = true,
    SilentAimTargetPart = "Head", SilentAimFOV = 250, AvoidDeflect = true,
    SilentAimStickiness = 0.05,
    SilentAimMultipoint = false,
    SilentAimMultipointCount = 5,
    SilentAimTorsoFallback = false,
    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0,
    AimbotSmoothnessX = 0,
    AimbotSmoothnessY = 0,
    AimbotLinkAxes = true,
    AimbotJumpDamping = 40,
    AimbotCancelSprings = true,
    AimbotCurvedFlick = false,
    AimbotCurvedIntensity = 0.35,
    AimbotTrackAssist = 100,
    AimbotFOVDeg = 20,
    AimbotMaxSpeed = 0,
    AimbotDeadzoneDeg = 0,
    AimbotSwitchDeg = 2,
    AimbotStickiness = 0.15,
    AimbotForgetTime = 0.2,
    AimbotTargetPart = "Best",
    AimbotPriority = "Crosshair",
    AimbotSkipImmune = true,
    AimbotPrediction = false,
    AimbotShotOverride = false,
    AimbotShowFOV = false, AimbotShowLock = false,
    AimbotDebug = false,
    AimbotReactionMs = 0,
    AimbotNoiseDeg = 0,
    AimbotOvershoot = 0,
    AimbotDirectCamera = false,
    Trigger = false,
    TriggerKey = "Always",
    TriggerDelayMs = 0,
    TriggerRefireMs = 0,
    TriggerHeadOnly = false,
    TriggerMaxDist = 400,
    MaxDistance = 1200, TeamCheck = true,
    PredictiveLead = true, LeadCap = 15, ServerProcessingMs = 30,
    ProjectileLead = false,
    ProjectileSpeed = 300,
    Rage = false,
    RageFireRateOverride = 0,
    RageRestoreWhileFiring = false,
    RageVoidMove         = true,
    RageVoidMinStep      = 25000,
    RageVoidJitterLocal  = false,
    RageVoidJitterStuds  = 2000,
    RageEyeMuzzleSep     = 0.07,
    RageVoidDepth        = "deep",
    RageGatePoison       = true,
    RagePredictPrefire   = true,
    RageSkipImmune       = true,
    RagePredictResurface = true,
    RageAttackContinuity = true,
    RageKnifeBot         = true,
    RageMeleeAsk         = true,
    RageMeleeLog         = false,
    RageKnifeCamForge    = true,
    RageParkLift         = false,
    RagePolarParity      = true,
    RagePhysicsFlags     = true,
    RageRestoreMode      = "auto",
    RageCameraAnchor     = true,
    RagePartGlue         = false,
    RageGumMode          = "on",
    RageGumVoidFire      = true,
    RageAttackTranslocate = false,
    RageTapsPerFrame     = 1,
    RagePrioritizeHackers = true,
    RageHideJitter        = true,
    RageHPPriority       = true,
    RageFastTargetSwitch = true,
    RageVisCheck         = false,
    AvoidDeflect       = true,
    RageShieldBackstab = true,
    RageKnifeBackstab  = true,
    RageKillPlaneBuffer = 200,
    RageLab = false,
    RageVoidPhase = true,
    RageMode = "Polar",
    RageDirectFire        = true,
    RageRateLimit         = false,
    RageTaps              = 6,
    RageCombatOrbitRadius = 60,
    RageOrbitDwell        = 0.30,
    RageCombatOrbitHeight = 8,
    RageCombatOrbitJitter = true,
    RagePBEyeUp           = 3,
    RageOnEmpty          = "Swap",
    RagePreferredSlot    = "Primary",
    TriggerScopeCheck    = false,
    SilentAimHitChance   = 85,
    SilentAimBodyMix     = 25,
    SilentAimJitterDeg   = 1.5,
    AutoWeaponEnabled    = false,
    AutoWeaponPrimary    = "",
    AutoWeaponSecondary  = "",
    AutoWeaponMelee      = "",
    AutoWeaponUtility    = "",
    RageMultiTap  = 1,
    RageCombatMode = "Nullpoint",
    ESP = false, ESPTeamCheck = true,
    ESPMaxDistance = 1200, ESPMaxPlayers = 0,
    ESPFont = "Code",
    ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1,
    ESPTextCasing = 1,
    ESPDistanceScaling    = true,
    ESPDistanceScalingRef = 50,
    ESPCasingThickness = 1,
    ESPBoxScale = 1,
    ESPBox = true, ESPBoxStyle = "Full Box", ESPBoxBrackets = false, ESPCornerLength = 0.28,
    ESPBoxFill = false, ESPBoxThickness = 1,
    ESPName = true, ESPDistance = true, ESPWeapon = false,
    ESPHealth = true, ESPHealthNumberMode = "OnDamage",
    ESPSkeleton = false, ESPSkeletonThickness = 1,
    ESPChams = false,
    ESPTracers = false, ESPTracerThickness = 1, ESPTracerOrigin = "Bottom",
    ESPArrows = false,
    ESPFlagStaring = false, ESPFlagDeflect = true, ESPFlagShield = true, ESPFlagInvincible = true, ESPFlagLowHP = true,
    ESPHeadDot = false, ESPHeadDotSize = 4,
    ESPBoxColorMode      = "Solid",
    ESPBoxColor          = Color3.fromRGB(255, 255, 255),
    ESPBoxGradA          = Color3.fromRGB(255,  59,  78),
    ESPBoxGradB          = Color3.fromRGB(255, 194,  75),
    ESPBoxFillColor      = Color3.fromRGB(255,  59,  78),
    ESPHealthColorMode   = "Ramp",
    ESPHealthColor       = Color3.fromRGB( 61, 224, 122),
    ESPHealthGradA       = Color3.fromRGB(255,  68,  54),
    ESPHealthGradB       = Color3.fromRGB( 61, 224, 122),
    ESPNameColorMode     = "Solid",
    ESPNameColor         = Color3.fromRGB(255, 255, 255),
    ESPNameGradA         = Color3.fromRGB(255, 255, 255),
    ESPNameGradB         = Color3.fromRGB(255, 194,  75),
    ESPInfoColorMode     = "Solid",
    ESPInfoColor         = Color3.fromRGB(255, 255, 255),
    ESPInfoGradA         = Color3.fromRGB(255, 255, 255),
    ESPInfoGradB         = Color3.fromRGB(255, 158,  75),
    ESPFlagColorMode     = "PerFlag",
    ESPFlagColor         = Color3.fromRGB(255, 194,  75),
    ESPFlagGradA         = Color3.fromRGB(255, 194,  75),
    ESPFlagGradB         = Color3.fromRGB(255,  70,  85),
    ESPSkeletonColorMode = "Solid",
    ESPSkeletonColor     = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradA     = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradB     = Color3.fromRGB(120, 180, 255),
    ESPTracerColorMode   = "Solid",
    ESPTracerColor       = Color3.fromRGB(255, 255, 255),
    ESPTracerGradA       = Color3.fromRGB(255, 255, 255),
    ESPTracerGradB       = Color3.fromRGB(255,  59,  78),
    ESPMarkColorMode     = "Solid",
    ESPMarkColor         = Color3.fromRGB(255, 255, 255),
    ESPMarkGradA         = Color3.fromRGB(255, 255, 255),
    ESPMarkGradB         = Color3.fromRGB(255, 194,  75),
    ESPGradientSpeed     = 0,
    ESPGradientRotBox    = 0,
    ESPGradientRotText   = 90,
    ESPHeadDotColor      = Color3.fromRGB(255, 255, 255),
    ESPChamsFillColor    = Color3.fromRGB(255, 59, 78),
    ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ColorEnemy       = Color3.fromRGB(255, 59, 78),
    ColorTeam        = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc    = Color3.fromRGB(168, 85, 96),
    ColorTeamOcc     = Color3.fromRGB(92, 153, 147),
    ColorVisible     = Color3.fromRGB(41, 224, 255),
    ESPDistNearColor = Color3.fromRGB(80, 255, 140),
    ESPDistFarColor  = Color3.fromRGB(255, 70, 90),
    ESPBoxTransparency          = 0,
    ESPBoxFillTransparency      = 0.75,
    ESPNameTransparency         = 0,
    ESPHealthTransparency       = 0.1,
    ESPSkeletonTransparency     = 0.2,
    ESPTracerTransparency       = 0.35,
    ESPHeadDotTransparency      = 0,
    ESPChamsFillTransparency    = 0.6,
    ESPChamsOutlineTransparency = 0,
    Visuals = false, VisualsPreset = "Neutral", VisualsPerformanceMode = false,
    VisualsFullbright = false,
    VisualsNoFog = false,
    VisualsHolograms = false, VisualsRainbowMap = false,
    VisualsRainbowMapSpeed = 0.15, VisualsStretch = 1.0,
    VisualsStretchMin = 0.5, VisualsStretchMax = 1.2,
    VisualsCameraSway = false,
    VisualsCameraSwayAmount = 0.5,
    VisualsHologramDuration = 3.5, VisualsHologramRange = 300,
    VisualsHologramVisibility = 1.4,
    VisualsHologramColor  = Color3.fromRGB(0, 220, 255),
    VisualsHologramAccent = Color3.fromRGB(255, 60, 200),
    VisualsGrade = "Crisp",
    VisualsGradeStrength = 0.6,
    VisualsBloom = false,
    VisualsBloomIntensity = 1.0,
    VisualsVignette = false,
    VisualsVignetteStrength = 0.6,
    VisualsLetterbox = false,
    VisualsLetterboxSize = 0.10,
    VisualsDOF = false,
    VisualsDOFDistance = 28,
    VisualsDOFBlur = 0.5,
    VisualsHologramStyle = "Orb",
    VisualsHologramLethal = true,
    VisualsHologramLethalColor = Color3.fromRGB(255, 200, 60),
    HUD = false,
    FXHitMarker = true,
    FXHitMarkerColor = Color3.fromRGB(255, 255, 255),
    FXHitMarkerCritColor = Color3.fromRGB(255, 194, 75),
    FXHitMarkerLethalColor = Color3.fromRGB(255, 64, 78),
    FXHitMarkerGap = 5,
    FXHitMarkerLen = 8,
    FXHitMarkerThickness = 2,
    FXHitSound = true,
    FXHitSoundId = "",
    FXKillSoundId = "",
    FXHitSoundVolume = 0.5,
    FXDamageNumbers = true,
    FXDamageAccumWindow = 0.9,
    FXKillBanner = true,
    FXKillBannerColor = Color3.fromRGB(255, 194, 75),
    FXKillFeed = true,
    FXHeadshotSpark = true,
    FXHitFlash = true,
    FXDamageDirection = true,
    FXLowHPVignette = true,
    FXLowHPThreshold = 0.35,
    FXCritDamage = 30,
    FXBeamTracer     = false,
    FXBeamStyle      = "Glow",
    FXBeamHitColor   = Color3.fromRGB(255, 194, 75),
    FXBeamMissColor  = Color3.fromRGB(143, 160, 176),
    FXFovRing        = false,
    FXFovColorA      = Color3.fromRGB(53, 215, 199),
    FXFovColorB      = Color3.fromRGB(255, 194, 75),
    FXFovThickness   = 1.5,
    FXFovDriftSpeed  = 0.15,
    FXFovFill        = false,
    FXFovRotate      = true,
    FXWorldSpark     = false,
    FXBeamWidth0    = 0.18,
    FXBeamWidth1    = 0.04,
    FXBeamDur       = 0.55,
    FXBeamGlowLight = true,
    FXBeamTravel      = true,
    FXBeamTravelSpeed = 1400,
    FXBeamImpact      = true,
    FXWorldSparkBloom = true,
    FXKillPillar      = false,
    FXKillPillarColor = Color3.fromRGB(255, 194, 75),
    FXKillShards      = false,
    FXKillShardsColor = Color3.fromRGB(155, 232, 255),
    FXKillPulse       = false,
    FXKillPulseAmount = 0.6,
    FXFovCasing     = true,
    FXCrosshair          = false,
    FXCrosshairStyle     = "Cross",
    FXCrosshairColor     = Color3.fromRGB(243, 246, 250),
    FXCrosshairDot       = true,
    FXCrosshairGap       = 4,
    FXCrosshairLen       = 7,
    FXCrosshairThickness = 2,
    FXCrosshairOutline   = true,
    FXCrosshairHitPop    = true,
    HUDWatermark      = true,
    HUDWatermarkStats = true,
    FXTargetInfo       = false,
    FXTargetInfoOffset = 110,
    HUDBindList     = false,
    HUDBindListSide = "Left",
    FXHitMarkerStyle = "X",
    FXCrosshairBloom = false,
    HUDCompass       = false,
    HUDCompassWidth  = 380,
    HUDCompassPips   = true,
    HUDThreatArc     = false,
    HUDRangeReadout  = false,
    ESPRadarGrid  = true,
    ESPRadarSweep = false,
    ESPFadeIn = true,
    ESPArrowDistFade  = true,
    ESPArrowDistLabel = false,
    ESPLookLine       = false,
    ESPLookLineLength = 8,
    ESPHealthSmooth = true,
    ESPHealthGhost = true,
    ESPDeclutter = true,
    ESPChamsVisSplit = true,
    ESPRadar = false,
    ESPRadarSize = 200,
    ESPRadarRange = 150,
    ESPRadarRotate = true,
    ESPRadarVisSplit = true,
    ESPRadarInset = 24,
    ESPPeekAlert = false,
    ESPThreatCount = false,
    ESPPrimaryEmphasis = false,
    ESPHealTick = false,
    ESPNameHealthUnderline = false,
    ESPLockChevron         = false,
    ESPChamsStyle          = "Shade",
    ESPNameMode            = "Display",
    UtilityESP            = false,
    UtilityESPMaxDistance = 250,
    UtilityESPRing        = true,
    UtilityESPLabels      = true,
    Weather          = false,
    WeatherType      = "Rain",
    WeatherIntensity = 1.0,
    WeatherMeteors   = false,
    WeatherMeteorRate = 1.0,
    WeatherStarRate  = 1.0,
    WeatherClockDial = false,
    WeatherClockCycleMin = 8,
    WeatherStorm     = false,
    WeatherStormFlash= true,
    WeatherStormMin  = 4,
    WeatherStormVar  = 8,
    WeatherThunderId = "rbxassetid://9113169432",
    WeatherSoundIds  = {
        rain  = "rbxassetid://9112858162",
        wind  = "rbxassetid://9112854440",
        fire  = "rbxassetid://2787093357",
        night = "rbxassetid://9112764573",
        birds = "rbxassetid://9112749254",
    },
    WeatherSoundVolume = 0.35,
    WeatherMood      = true,
    SkyboxPreset        = "Off",
    SkyboxHideCelestial = false,
    WeatherGodRays      = false,
    WeatherRainbow      = false,
    WeatherShootingStars = false,
    WeatherPuddles   = false,
    GameVisuals = false,
    GVUnlockAll     = true,
    GVUnlockWeapons = false,
    GVWrapInverted  = false,
    GVEveryone      = false,
    GVBirthHook     = true,
    GVFinisherClone = true,
    GVRemember      = true,
    GVRankCharmOn    = false,
    GVRankCharmRank  = "",
    GVRankCharmLb    = 0,
    GVEmotes         = false,
    SpooferNameEnabled        = false,
    SpooferName               = "ProPlayer",
    SpooferDisplayName        = "ProPlayer",
    SpooferLevelEnabled       = false,
    SpooferLevel              = 100,
    SpooferCasualWinsEnabled  = false,
    SpooferCasualWins         = 500,
    SpooferRankedWinsEnabled  = false,
    SpooferRankedWins         = 250,
    SpooferRankedEloEnabled   = false,
    SpooferRankedElo          = 2400,
    SpooferWinPercentEnabled  = false,
    SpooferWinPercent         = 75,
    SpooferWinStreakEnabled   = false,
    SpooferWinStreak          = 25,
    SpooferFavoriteMapEnabled = false,
    SpooferFavoriteMap        = "Arena",
    VMOffsetEnabled      = false,
    VMOffsetX            = 0,
    VMOffsetY            = 0,
    VMOffsetZ            = 0,
    VMOffsetPitch        = 0,
    VMOffsetYaw          = 0,
    VMOffsetRoll         = 0,
    VMChamsEnabled       = false,
    VMChamsMaterial      = "ForceField",
    VMChamsColor         = Color3.fromRGB(53, 215, 199),
    VMChamsTransparency  = 0.5,
    VMDisableTextures    = false,
    FXCrosshairAngle     = 0,
    FXCrosshairSpin      = false,
    FXCrosshairSpinSpeed = 1.0,
    FXCrosshairSniper    = false,
    FXCrosshairBounce    = false,
    FXCrosshairBounceAmt = 4,
    CameraAspectRatioEnabled = false,
    CameraAspectRatioX       = 4,
    CameraAspectRatioY       = 3,
    CameraFovOverride        = false,
    CameraFovAmount          = 90,
    ThirdPersonEnabled       = false,
    ThirdPersonDistance      = 12,
    ESPAmmoBar           = false,
    ESPHealthNumber      = true,
    AutoQueue            = false,
    AutoQueueMode        = "1v1",
    AutoCollectDrops     = false,
    CollectHealth        = true,
    CollectAmmo          = true,
}

local State = {
    Target = nil, CamPos = Vector3.zero,
    AimbotTarget = nil, AimbotPart = nil,
    AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, SilentLastTarget = nil,
    RageAutoTransport = "kicia", RageTransportSwitches = 0, RageLastLossAt = 0,
    AutoWeaponFails = 0,
    AimbotFlickActive = false, AimbotSpringOffset = Vector2.zero,
    RageRealCF   = nil,
    RageRealChar = nil,
    RageTarget   = nil,
    RageVoidCF   = nil,
    RageVoidNext = 0,
    RageVoidBase = nil,
    RageVoidSteps = 0,
    RageLastFireTime = 0,
    RageReloadLast   = 0,
    RageSwitchLast   = 0,
    OrbitAngle        = 0,
    OrbitVantage      = nil,
    OrbitVantageUntil = 0,
    RageForging          = false,
    RageLeakCanary       = 0,
    RageTracerCanary     = 0,
    RageBlankCanary      = 0,
    RageOOBParkCanary    = 0,
    RageHitsOn           = 0,
    RageHitsOff          = 0,
    RageOffFromSelf      = 0,
    RageOffFromTarget    = 0,
    ViewAngleForged      = false,
    RageKnifeSwings      = 0,
    RageKnifeStatus      = "idle",
    RageRawSet           = false,
    RagePhysRate         = "off",
    RageParkDirty        = false,
    RageLastParkPos      = nil,
    RageParkLatchCanary  = 0,
    RageLatchStuds       = 0,
    RageOrderCanary      = 0,
    RagePostPark         = false,
    RageBelowPlaneFrames = 0,
    RageBelowPlaneLast   = 0,
    RageBelowPlaneDeaths = 0,
    RageParkDriftFrames  = 0,
    RageParkDrift        = 0,
    RageParkDriftY       = 0,
    RageEyeClampFrames   = 0,
    RageParkClampFrames  = 0,
    RageTranslocateBaits = 0,
    RageVoidFires = 0,
    RagePoisonBlips = 0,
    RagePreFires = 0,
    RagePredTarget = nil,
    RagePredHide = 0, RagePredHideN = 0,
    RagePredAtk = 0,  RagePredAtkN = 0,
    RagePredPhase = "?", RagePredFor = 0,
    RagePredDue = 0,
    RagePredWindow = false,
    RagePredMag = 0,
    RageGumMode = "off",
    RageKnifeHintLast = 0,
    RageInMatch  = false,
    RageStatus   = "Idle",
    RageFireFromPos = nil,
    RageFireAimPos  = nil,
    RageFireHitPart = nil,
    RageFireStamp   = 0,
    RageDealtTotal  = 0,
    RageFiring          = false,
    RageVoidActive      = false,
    RageTranslocating   = false,
    RageTrueVelocityMap = {},
    RageSuspectedProtection = {},
    RageBacktrackBuf    = {},
    RageCharTokens      = {},
    Shots = 0, Hits = 0,
    ESPObjects = {}, RainbowHue = 0,
    VisualsCurrentPreset = nil,
    GVApplied = 0,
    GVStatus  = "idle",
}

-- Keys referenced by the extracted Rage engine but not present in the original Config table.
Config.RageWeaponPick = Config.RageWeaponPick or Config.RagePreferredSlot or "Primary"
Config.RageSwitchMelee = (Config.RageSwitchMelee == nil) and true or Config.RageSwitchMelee
Config.RageSwitchRateLimit = Config.RageSwitchRateLimit or 0.06
Config.RageGlueMode = Config.RageGlueMode or "auto"

local CLOSEST_PARTS = {
    "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
    "LeftHand","RightHand","LeftFoot","RightFoot",
    "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
}
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
local SANE_POS_LIMIT = 100000
local function isSanePos(p)
    return p == p
        and math.abs(p.X) < SANE_POS_LIMIT
        and math.abs(p.Y) < SANE_POS_LIMIT
        and math.abs(p.Z) < SANE_POS_LIMIT
end
local VFR_LIM, VFR_DEAD = 2147483646, 1147483646
local function rndSkip()
    local v
    repeat v = math.random(-VFR_LIM, VFR_LIM) until v < -VFR_DEAD or v > VFR_DEAD
    return v
end
local function voidShellVec()
    return Vector3.new(rndSkip(), rndSkip(), rndSkip())
end
local function posInPart(pos, part)
    if not part or not part.Parent then return false end
    local lpv = part.CFrame:PointToObjectSpace(pos)
    local s = part.Size * 0.5
    return math.abs(lpv.X) <= s.X and math.abs(lpv.Y) <= s.Y and math.abs(lpv.Z) <= s.Z
end
local function posIsOOB(pos)
    local ok, result = pcall(function()
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsSafePart")) do
            if posInPart(pos, p) then return false end
        end
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsPart")) do
            if posInPart(pos, p) then return true end
        end
        return false
    end)
    return ok and result == true
end
local function clampHop(targetPos, fromPos, maxHop)
    local d = targetPos - fromPos
    local m = d.Magnitude
    if m <= maxHop or m == 0 then return targetPos end
    return fromPos + d * (maxHop / m)
end
local function getHealth(player)
    if not player.Character then return 0, 100 end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
end
local HP_RAMP_STOPS = {
    { 0.00, Color3.fromRGB(255,  68,  54) },
    { 0.20, Color3.fromRGB(255, 122,  61) },
    { 0.40, Color3.fromRGB(255, 194,  75) },
    { 0.60, Color3.fromRGB(196, 226,  78) },
    { 1.00, Color3.fromRGB( 61, 224, 122) },
}
local function hpRamp(frac)
    frac = math.clamp(frac or 0, 0, 1)
    for i = 1, #HP_RAMP_STOPS - 1 do
        local a, b = HP_RAMP_STOPS[i], HP_RAMP_STOPS[i + 1]
        if frac <= b[1] then
            local span = b[1] - a[1]
            local t = span > 0 and (frac - a[1]) / span or 0
            return a[2]:Lerp(b[2], math.clamp(t, 0, 1))
        end
    end
    return HP_RAMP_STOPS[#HP_RAMP_STOPS][2]
end
local function getWeaponName(player)
    if not player or not player.Character then return "?" end
    local ok, res = pcall(function()
        if Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter then
            local f = Rivals.Fighter._player_to_fighter[player]
            if f and f.EquippedItem and f.EquippedItem.Info then
                return f.EquippedItem.Info.Name
            end
        end
        return nil
    end)
    if ok and type(res) == "string" and res ~= "" then return res end
    local ok2, fallback = pcall(function()
        for _, c in ipairs(player.Character:GetChildren()) do
            if c:IsA("Model") and not c:FindFirstChildOfClass("Humanoid") then
                if c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart") then
                    return c.Name
                end
            end
            if c:IsA("Tool") then return c.Name end
        end
        return "?"
    end)
    return (ok2 and type(fallback) == "string") and fallback or "?"
end
local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp     = Camera.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        for _, name in ipairs(CLOSEST_PARTS) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then best, bestDist = p, d end
                end
            end
        end
        if best then return best end
    end
    local list = mode == "Torso" and TORSO_PARTS or HEAD_PARTS
    for _, name in ipairs(list) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end
local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
local _visFilterChar = nil
local function isVisible(worldPos)
    local origin = Camera.CFrame.Position
    local _vc = lp.Character
    if _vc ~= _visFilterChar then
        visParams.FilterDescendantsInstances = { _vc }
        _visFilterChar = _vc
    end
    local result = Workspace:Raycast(origin, worldPos - origin, visParams)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end
local DEFLECT_ANIM_IDS = {
    ["14761240825"] = true, ["14761220206"] = true,
    ["14761234917"] = true, ["14761221711"] = true, ["14761223422"] = true, ["14761225204"] = true, ["14761232380"] = true,
    ["90436105114997"] = true, ["90797895557136"] = true, ["77995180947430"] = true, ["111943779640553"] = true,
    ["131072510521727"] = true, ["132022220827223"] = true, ["116315405171252"] = true, ["110358509711635"] = true, ["98242486936084"] = true, ["81132288854196"] = true,
    ["123293403148826"] = true, ["136354716301184"] = true, ["120567011479119"] = true, ["92502373956550"] = true, ["83541611040586"] = true, ["92773106977434"] = true,
    ["75844592081515"] = true, ["75381142568185"] = true,
}
local function isDeflectingAnim(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Name:lower():find("deflect") then return true end
        local anim = track.Animation
        local id = anim and anim.AnimationId
        if id then
            local num = id:match("(%d+)")
            if num and DEFLECT_ANIM_IDS[num] then return true end
        end
    end
    return false
end
local _deflecting = {}
local _deflGen    = {}
local _deflHookLive = false
local DEFLECT_CLEAR_PAD = 0.05
local function isDeflecting(player)
    if not player then return false end
    if _deflecting[player.UserId] then return true end
    if _deflHookLive then return false end
    return isDeflectingAnim(player)
end
;(function()
    local function recordDeflect(self)
        local fighter = self and self.ClientFighter
        local plr = fighter and fighter.Player
        if not plr then return end
        local uid = plr.UserId
        local dur = self.Info and self.Info.DeflectDuration
        if type(dur) ~= "number" then dur = 0.1 end
        _deflecting[uid] = true
        local gen = (_deflGen[uid] or 0) + 1
        _deflGen[uid] = gen
        task.delay(dur + DEFLECT_CLEAR_PAD, function()
            if _deflGen[uid] == gen then
                _deflecting[uid] = nil
            end
        end)
    end
    task.spawn(function()
        local ok, katana = pcall(loadGameModule, lp.PlayerScripts, {"Modules", "Items", "Katana"})
        if not ok or type(katana) ~= "table" or type(katana._StartDeflecting) ~= "function" then
            return
        end
        local orig = shared._LH_KatanaDeflOrig
        if not orig then orig = clonefunction(katana._StartDeflecting) end
        shared._LH_KatanaMod     = katana
        shared._LH_KatanaDeflOrig = orig
        if setreadonly then pcall(setreadonly, katana, false) end
        katana._StartDeflecting = function(self, ...)
            pcall(recordDeflect, self)
            return orig(self, ...)
        end
        _deflHookLive = true
    end)
end)()
local _invincible = {}
local _invincEnt  = {}
local function isSpawnProtected(player)
    if not player then return false end
    if not (Rivals.Ready and Rivals.Fighter) then return false end
    local map = Rivals.Fighter._player_to_fighter
    if not map then return false end
    local f = map[player]
    if not f then return false end
    local e = f.Entity
    if not e then return false end
    local uid = player.UserId
    if _invincEnt[uid] ~= e then
        _invincible[uid] = nil
        local ok = pcall(function()
            local live = e:Get("IsInvincible") == true
            e:GetDataChangedSignal("IsInvincible"):Connect(function()
                _invincible[uid] = e:Get("IsInvincible") == true
            end)
            _invincible[uid] = live
        end)
        if ok then _invincEnt[uid] = e end
    end
    return _invincible[uid] == true
end
local function isRiotShield(player)
    local w = getWeaponName(player):lower()
    return w:find("riot shield") or w:find("energy shield") or w:find("tombstone shield")
        or w:find("broken surfboard", 1, true) or w == "door" or w == "sled" or w == "masterpiece"
end
local function ownsRiotShield(player)
    if not player then return false end
    local ok, res = pcall(function()
        if not (Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter) then return false end
        local f = Rivals.Fighter._player_to_fighter[player]
        local items = f and f.Items
        if type(items) ~= "table" then return false end
        for _, it in items do
            local n = nil
            if type(it) == "table" then
                n = it.Name
                if n == nil and it.Info then n = it.Info.Name end
            end
            if type(n) == "string" then
                local low = n:lower()
                if low:find("riot shield") or low:find("energy shield") or low:find("tombstone shield") then
                    return true
                end
            end
        end
        return false
    end)
    return ok and res == true
end
local KATANA_NAMES = { "katana", "saber", "lightning bolt", "evil trident", "tridant", "devil's trident", "linked sword", "keytana", "cutlass", "swordfish", "riptide" }
local function isKatana(player)
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KATANA_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return isDeflecting(player)
end
local function isLocalKnife()
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf and lf.EquippedItem then
        local name = lf.EquippedItem.Name:lower()
        if name:find("knife") or name:find("karambit") or name:find("balisong") or name:find("chancla") or name:find("machete") or name:find("candy cane") or name:find("armature") or name:find("daggers") or name:find("axe") then
            return true
        end
    end
    return false
end
local KNIFE_NAMES = { "knife", "karambit", "balisong", "chancla", "machete", "candy cane", "armature", "daggers", "axe" }
local function isEnemyKnife(player)
    if not player then return false end
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KNIFE_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return false
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
    local lf = Rivals.Ready and Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf then
        local ok, objId = pcall(function() return lf.EquippedItem and lf.EquippedItem:Get("ObjectID") end)
        if ok and objId then return true end
    end
    return false
end
local function isFfaMode()
    local ok, res = pcall(function()
        local wsMode = workspace:GetAttribute("ArcadeMode")
        if wsMode == "arc_freeforall" or wsMode == "Free For All" then return true end
        local duel = Rivals and Rivals.ClientDuel
        if duel and type(duel.Get) == "function" then
            local mode = duel:Get("ArcadeMode")
            if mode == "arc_freeforall" or mode == "Free For All" then return true end
        end
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "_drop" and child:IsA("BasePart") then
                return true
            end
        end
        return false
    end)
    return ok and res == true
end
local function isValidTarget(player, checkVis, keepDeflect, rageScope)
    if not player or player == lp then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    if Config.AvoidDeflect and not keepDeflect and isDeflecting(player) then return false end
    if Config.RageSkipImmune and not rageScope and isSpawnProtected(player) then return false end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local sane = isSanePos(hrp.Position)
    if not rageScope then
        if not sane then return false end
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (hrp.Position - myRoot.Position).Magnitude > Config.MaxDistance then return false end
    end
    if checkVis and sane and not isVisible(hrp.Position) then return false end
    return true
end
local _sharedVelMap = {}
do
    local _svPos, _svTime = {}, {}
    local _svAccum = 0
    local SV_INTERVAL = 1 / 30
    local function velTrackerStep(dt)
        if not (Config.Aimbot or Config.SilentAim or Config.Rage) then return end
        _svAccum = _svAccum + (dt or 0)
        if _svAccum < SV_INTERVAL then return end
        _svAccum = 0
        local now = tick()
        for _, p in ipairs(getSafePlayers() or {}) do
            if p ~= lp and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    local lt  = _svTime[p]
                    if _svPos[p] and lt then
                        local d = now - lt
                        if d > 0 then
                            local v = (pos - _svPos[p]) / d
                            if v.Magnitude < 500 then _sharedVelMap[p] = v end
                        end
                    end
                    _svPos[p]  = pos
                    _svTime[p] = now
                end
            end
        end
    end
    if shared._LH_velConn then pcall(function() shared._LH_velConn:Disconnect() end) end
    shared._LH_velConn = RunService.Heartbeat:Connect(velTrackerStep)
end
local function calculateLead(targetChar, fromPos, wantLead)
    if wantLead == nil then wantLead = Config.PredictiveLead end
    if not targetChar then return Vector3.new() end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return Vector3.new() end
    local lat = (lp:GetNetworkPing() or 0.05) + ((Config.ServerProcessingMs or 30) / 1000)
    if Config.ProjectileLead and (Config.ProjectileSpeed or 0) > 0 then
        lat = lat + (hrp.Position - fromPos).Magnitude / Config.ProjectileSpeed
    end
    local lead = Vector3.new()
    if wantLead then
        local ply     = Players:GetPlayerFromCharacter(targetChar)
        local trueVel = hrp.AssemblyLinearVelocity
        local calcVel = ply and (_sharedVelMap[ply] or State.RageTrueVelocityMap[ply])
        if calcVel then
            if (trueVel - calcVel).Magnitude > 25 then trueVel = calcVel end
        else
            if trueVel.Magnitude > 100 then trueVel = Vector3.new() end
        end
        if trueVel.Magnitude > 120 then trueVel = Vector3.new() end
        local md = hum.MoveDirection
        if md.Magnitude > 0.1 then
            lead = lead + Vector3.new(trueVel.X, 0, trueVel.Z) * lat
        end
        lead = lead + Vector3.new(0, trueVel.Y * lat, 0)
    end
    local cap = Config.LeadCap or 15
    if lead.Magnitude > cap then lead = lead.Unit * cap end
    return lead
end
local function selectTarget(opts)
    opts = opts or {}
    local fov         = opts.fov or 90
    local checkVis    = opts.checkVis or false
    local mode        = opts.partMode or "Head"
    local sticky      = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= lp and isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part and (not checkVis or isVisible(part.Position)) then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= fov then
                        local score = d
                        if player == sticky then score = score * (1 - stickyBonus) end
                        if score < bestScore then bestScore, best, bestPart = score, player, part end
                    end
                end
            end
        end
    end
    return best, bestPart
end
local function aimbotKeyDown()
    return isInputActive(Config.AimbotKey)
end

-- [[ EXTRACTED RAGE ENGINE ]]
local RageEngine = {}
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
    RageEngine._lookCF = lookCF
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
    RageEngine._buildShotFields = buildShotFields
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
    RageEngine._encodeShot = encodeShot
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
        RageEngine._itemIsMelee = itemIsMelee
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
        RageEngine._equipSlot = equipSlot
        RageEngine._nextUsableSlot = nextUsableSlot
        RageEngine._whichSlotNow = whichSlotNow
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
        if not (RageEngine._itemIsMelee and RageEngine._itemIsMelee(item)) then
            local okR, reloading = pcall(function() return (item._reload_cooldown or 0) > tick() end)
            if okR and reloading then return false end
            local okA, ammo = pcall(function() return item:Get("Ammo") end)
            if not okA or type(ammo) ~= "number" or ammo <= 0 then return false end
        end
        local now = tick()
        local interval = 0
        if RageEngine._fireInterval then interval = RageEngine._fireInterval() end
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
    RageEngine._findTarget = findTarget
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
    RageEngine._findTargetHeadSane = findTargetHeadSane
    local _meleeLogAt = 0
    local function meleeReadout()
        if Config.RageMeleeLog == false then return end
        local now = tick()
        if now - _meleeLogAt < 1 then return end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local item = lf and lf.EquippedItem
        if not item then return end
        if not (RageEngine._itemIsMelee and RageEngine._itemIsMelee(item)) then return end
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
    RageEngine._startTargetLoop = startTargetLoop
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
    RageEngine._startLabPoll = startLabPoll
    RageEngine._isCheater = function() return false end
    function RageEngine.init()
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
    RageEngine._fireInterval = fireInterval
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
    RageEngine._displace = displace
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
        if RageEngine._itemIsMelee and RageEngine._itemIsMelee(it) then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    RageEngine._ensureReload = function(it)
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
    RageEngine._weaponRecovery = function(it)
        local mode = Config.RageOnEmpty or "Reload"
        local okA, ammo = pcall(function() return it and it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then
            return RageEngine._ensureReload(it)
        end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local items = lf and lf.Items
        if type(items) ~= "table" then return RageEngine._ensureReload(it) end
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
        return RageEngine._ensureReload(it)
    end
    local _transportWatchStarted = false
    RageEngine._startTransportWatcher = function()
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
    RageEngine.autoWeaponStep = function()
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
            local eyeCF    = RageEngine._lookCF(eyePos, aimPos)
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
                    RageEngine._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, 0.30, 1.0)
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
            RageEngine._displace(hrp, voidCFrame())
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
                local act = RageEngine._weaponRecovery(getEquippedItem())
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
            RageEngine._displace(hrp, CFrame.new(vantage))
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
            pcall(RageVisuals.notifyTarget, tgt)
        end
        local function rageTick(ch, hrp, tgt)
            if (Config.RageMode or "Polar") ~= "Orbit" then
                State.RageStatus = "Mode error"
                return
            end
            orbitTick(ch, hrp, tgt)
        end
        RageEngine._rageTick = rageTick
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
        if RageEngine._setPhysicsFlags then pcall(RageEngine._setPhysicsFlags, true) end
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
                if RageEngine._setPhysicsFlags then pcall(RageEngine._setPhysicsFlags, false) end
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
                if not tgt then tgt = RageEngine._findTarget() end
                State.RageTarget = tgt
            end
            State.RagePostPark = true
            RageEngine._rageTick(ch, hrp, tgt)
            local anchor    = State.RageRealCF
            local displaced = false
            if anchor then displaced = (hrp.Position - anchor.Position).Magnitude > 0.001 end
            State.RageParkDirty = displaced
            if displaced then State.RageLastParkPos = hrp.Position end
        end)
    end
    function RageEngine.enable()
        Config.Rage = true
        if RageEngine._startTargetLoop then RageEngine._startTargetLoop() end
        if (Config.RageMode or "Polar") ~= "Orbit" then
            if RageEngine._polarCoreStart then RageEngine._polarCoreStart() end
            return
        end
        startRage()
    end
    function RageEngine.disable()
        Config.Rage = false
        if RageEngine._polarCoreStop then RageEngine._polarCoreStop() end
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
    function RageEngine.unload()
        RageEngine.disable()
        if _tgtConn then pcall(function() _tgtConn:Disconnect() end); _tgtConn = nil end
        if _labConn then pcall(function() _labConn:Disconnect() end); _labConn = nil end
    end
    RageEngine._encodeRageShot = encodeRageShot
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
        local eyeCF    = RageEngine._lookCF(eyePos, hpos)
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
                    RageEngine._buildShotFields(inner, eyeCF, muzzleCF, hh, hpos, true, RAGE_CLAMP_FRAC, 1.0)
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
        local eyeCF    = RageEngine._lookCF(fireEyePos, aimPos)
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
                    RageEngine._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
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
            local act = RageEngine._weaponRecovery(it)
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
            pcall(RageVisuals.notifyTarget, tgt)
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
    RageEngine._polarCoreStart = PolarCore.start
    RageEngine._polarCoreStop  = PolarCore.stop
    RageEngine._setPhysicsFlags = setPhysicsFlags
    function RageEngine._physDiag()
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
    RageEngine._gumDiag = RageEngine._physDiag
end)()

local RageSettings = Config

local Legit = Library:Tab("Legit", 98159911363596)
local Rage = Library:Tab("Rage", 10455604811)
local Visuals = Library:Tab("Visuals", 10455603612)
local Misc = Library:Tab("Misc", 11888734334)

local AimGroup = Legit:Group("Aimbot")
AimGroup:Toggle({Name = "Enabled", Tooltip = "Legit aimbot", Callback = function(v) toggleAimbot(v) end})
AimGroup:Slider({Name = "FOV", Min = 5, Max = 180, Default = 30, Unit = "Â°", Callback = function(v) S.aimFov = v end})
AimGroup:Slider({
    Name = "Smoothness",
    Min = 0.1,
    Max = 10,
    Default = 1,
    Decimals = 1,
    Unit = "",
    Tooltip = "0.1 = Fastest, 10 = Most smooth",
    Callback = function(v) S.aimSmooth = v end
})
AimGroup:Dropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart"}, Default = "Head", Callback = function(v) S.aimTargetPart = v end})
AimGroup:Toggle({Name = "Team Check", Callback = function(v) S.teamCheck = v end})
AimGroup:ColorPicker({Name = "FOV Color", Default = Color3.new(1,1,1), Tooltip = "Aimbot FOV circle color", Callback = function(c) S.aimFovColor = c end})

local TriggerGroup = Legit:Group("Triggerbot")
TriggerGroup:Toggle({Name = "Enabled", Callback = function(v) toggleTriggerbot(v) end})
TriggerGroup:Keybind({Name = "Key", Default = Enum.KeyCode.T, Callback = function(k) S.triggerbotKey = k end})
TriggerGroup:Slider({Name = "Delay", Min = 0, Max = 200, Default = 50, Unit = "ms", Callback = function(v) S.triggerbotDelay = v end})
TriggerGroup:Toggle({Name = "Wall Check", Callback = function(v) S.triggerbotWallCheck = v end})
TriggerGroup:Toggle({Name = "Team Check", Callback = function(v) S.triggerbotTeamCheck = v end})
TriggerGroup:Toggle({Name = "Only ADS", Tooltip = "Only fire when aiming", Callback = function(v) S.triggerbotOnlyADS = v end})

local AntiKatanaGroup = Legit:Group("Anti Katana")
AntiKatanaGroup:Toggle({
    Name = "Enabled",
    Tooltip = "Detect Katana deflect and prevent shooting",
    Callback = function(v)
        getgenv().SetAntiKatana(v)
    end
})

local SilentGroup = Legit:Group("Silent Aim")
SilentGroup:Toggle({Name = "Enabled", Callback = function(v) toggleSilentAim(v) end})
SilentGroup:Slider({Name = "FOV", Min = 5, Max = 180, Default = 30, Unit = "Â°", Callback = function(v) S.silentFov = v end})
SilentGroup:Dropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart"}, Default = "Head", Callback = function(v) S.silentTargetPart = v end})
SilentGroup:Toggle({Name = "Target NPC (人偶/标把)", Default = true, Tooltip = "Silent Aim 打练习场人偶和射击靶子", Callback = function(v) S.silentTargetNPC = v end})
SilentGroup:Toggle({Name = "Wall Check", Default = true, Tooltip = "只锁定视线内的目标，隔墙不打", Callback = function(v) S.wallCheck = v end})
SilentGroup:ColorPicker({Name = "FOV Color", Default = Color3.new(1,0,0), Tooltip = "Silent Aim FOV circle color", Callback = function(c) S.silentFovColor = c end})

local FovDispGroup = Legit:Group("FOV Display")
FovDispGroup:Toggle({Name = "Show FOV", Tooltip = "Show/Hide all FOV circles", Callback = function(v) S.showFovCircles = v end})
FovDispGroup:Dropdown({Name = "Style", Options = {"Outline", "Filled"}, Default = "Outline", Callback = function(v) S.fovStyle = v end})

local MovementGroup = Rage:Group("Movement")
MovementGroup:Toggle({Name = "Void", Callback = function(v) toggleVoid(v) end})
MovementGroup:Toggle({Name = "Orbit", Callback = function(v) toggleOrbit(v) end})
MovementGroup:Toggle({Name = "Noclip", Callback = function(v) toggleNoclip(v) end})
MovementGroup:Toggle({Name = "Fly", Callback = function(v) toggleFly(v) end})
MovementGroup:Slider({Name = "Fly Speed", Min = 16, Max = 200, Default = 50, Unit = " studs", Callback = function(v) S.flySpeed = v; if S.flyActive then toggleFly(true) end end})
MovementGroup:Toggle({Name = "SpinBot", Callback = function(v) toggleSpin(v) end})
MovementGroup:Slider({Name = "Spin Speed", Min = 1, Max = 50, Default = 10, Unit = "", Callback = function(v) S.spinSpeed = v end})

local AntiAimGroup = Rage:Group("Anti-Aim")
AntiAimGroup:Toggle({Name = "Enabled", Tooltip = "Master anti-aim switch", Callback = function(v)
    if v then
        _G.StartAntiAimExt()
    else
        _G.StopAntiAimExt()
    end
end})
AntiAimGroup:Dropdown({Name = "Yaw Type", Options = {"none", "jitter", "spinbot", "random"}, Default = "none", Callback = function(v)
    _G.AntiAimSettings.yawtype = v
end})
AntiAimGroup:Dropdown({Name = "Pitch Type", Options = {"none", "jitter", "spinbot", "random"}, Default = "none", Callback = function(v)
    _G.AntiAimSettings.pitchtype = v
end})
AntiAimGroup:Dropdown({Name = "Angle Type", Options = {"none", "tilt 45", "tilt 90", "upside down", "custom"}, Default = "none", Callback = function(v)
    _G.AntiAimSettings.angletype = v
end})
AntiAimGroup:Slider({Name = "Custom Angle", Min = 0, Max = 360, Default = 0, Unit = "Â°", Callback = function(v)
    _G.AntiAimSettings.customangle = v
end})
AntiAimGroup:Slider({Name = "Min Speed", Min = 1, Max = 100, Default = 10, Unit = "", Callback = function(v) _G.AntiAimSettings.minspeed = v end})
AntiAimGroup:Slider({Name = "Max Speed", Min = 1, Max = 100, Default = 20, Unit = "", Callback = function(v) _G.AntiAimSettings.maxspeed = v end})
AntiAimGroup:Slider({Name = "Min Angle", Min = 1, Max = 180, Default = 30, Unit = "Â°", Callback = function(v) _G.AntiAimSettings.minangle = v end})
AntiAimGroup:Slider({Name = "Max Angle", Min = 1, Max = 180, Default = 60, Unit = "Â°", Callback = function(v) _G.AntiAimSettings.maxangle = v end})
AntiAimGroup:Toggle({Name = "Random Angle (Jitter)", Callback = function(v) _G.AntiAimSettings.randomangle = v end})

AntiAimGroup:Toggle({Name = "Irregular Move", Tooltip = "Random offsets while moving", Callback = function(v)
    S.irregularMoveActive = v
    if v then startIrregularMove() else stopIrregularMove() end
end})

MovementGroup:Toggle({Name = "NoFall", Callback = function(v) toggleNoFall(v) end})

local CombatGroup = Rage:Group("Combat")
CombatGroup:Toggle({Name = "Fist", Callback = function(v) toggleFist(v) end})
CombatGroup:Toggle({Name = "Riot", Callback = function(v) toggleRiot(v) end})
CombatGroup:Toggle({Name = "Scythe", Callback = function(v) toggleScythe(v) end})
CombatGroup:Toggle({Name = "Wallbang", Callback = function(v) toggleWallbang(v) end})
CombatGroup:Toggle({Name = "Wallbang Head", Callback = function(v) toggleWallbangHead(v) end})

local UndergroundGroup = Rage:Group("Underground")
UndergroundGroup:Toggle({
    Name = "Underground",
    Tooltip = "Server-side underground teleport with visual fix",
    Callback = function(v) toggleUnderground(v) end
})
UndergroundGroup:Slider({
    Name = "Depth Offset",
    Min = -20,
    Max = 20,
    Default = -2,
    Unit = "",
    Tooltip = "Offset below detected floor (negative = deeper)",
    Callback = function(v)
        S.undergroundDepth = v
        _G.SetUndergroundDepthExt(v)
        if S.undergroundActive then
            toggleUnderground(true)
        end
    end
})

local ESPGroup = Visuals:Group("ESP")
ESPGroup:Toggle({Name = "Enabled", Callback = function(v) toggleESP(v) end})
ESPGroup:Toggle({Name = "Box", Callback = function(v) S.espShowBox = v end})
ESPGroup:Dropdown({Name = "Box Type", Options = {"2D", "Corner", "Filled"}, Default = "2D", Callback = function(v) S.espBoxType = v end})
ESPGroup:Toggle({Name = "Tracers", Callback = function(v) S.espShowTracers = v end})
ESPGroup:Toggle({Name = "Name", Callback = function(v) S.espShowName = v end})
ESPGroup:Toggle({Name = "Distance", Callback = function(v) S.espShowDistance = v end})
ESPGroup:Toggle({Name = "Health Bar", Callback = function(v) S.espShowHealthBar = v end})
ESPGroup:Toggle({Name = "Skeleton", Callback = function(v) S.espShowSkeleton = v end})

local PlayerGroup = Misc:Group("Player")
PlayerGroup:Toggle({Name = "Speed Hack", Default = false, Tooltip = "开启/关闭速度锁定", Callback = function(v)
    S.speedEnabled = v
    setSpeed(nil) -- 内部读 S.speedValue，不重置数值
end})
PlayerGroup:Slider({Name = "Speed", Min = 16, Max = 500, Default = 16, Unit = " studs", Callback = function(v) setSpeed(v) end})
PlayerGroup:Toggle({Name = "Infinite Jump", Callback = function(v) S.infiniteJumpActive = v end})

PlayerGroup:Toggle({
    Name = "Slide Boost",
    Tooltip = "Boost sliding speed",
    Callback = function(v)
        SlideBoostModule.setSlideBoost(v, _G.Features.SlideBoost.Speed)
    end
})
PlayerGroup:Slider({
    Name = "Boost Speed",
    Min = 100,
    Max = 1000,
    Default = _G.Features.SlideBoost.Speed,
    Unit = "",
    Tooltip = "Slide speed when boosting",
    Callback = function(v)
        _G.Features.SlideBoost.Speed = v
        if _G.Features.SlideBoost.Enabled then
            SlideBoostModule.setSlideBoost(true, v)
        end
    end
})

local WeaponGroup = Misc:Group("Weapon")
WeaponGroup:Toggle({Name = "Rapid Fire", Callback = function(v) toggleRapidFire(v) end})
WeaponGroup:Slider({Name = "Delay (ms)", Min = 1, Max = 200, Default = 1, Unit = "ms", Callback = function(v) S.fireDelay = v; if S.rapidFireActive then applyRapidFire() end end})
WeaponGroup:Toggle({Name = "Instant ADS", Callback = function(v) S.instantAdsEnabled = v; applyGunEnhancements() end})
WeaponGroup:Toggle({Name = "No Equip Anim", Callback = function(v) S.noEquipAnimEnabled = v; applyGunEnhancements() end})
WeaponGroup:Toggle({Name = "No Shoot Anim", Callback = function(v) S.noShootAnimEnabled = v; applyGunEnhancements() end})
WeaponGroup:Toggle({Name = "No Spread", Callback = function(v) S.noSpreadEnabled = v; patchGunSpread() end})
WeaponGroup:Toggle({Name = "No Smoke", Callback = function(v) S.noSmokeEnabled = v; applyNoSmoke() end})
WeaponGroup:Toggle({Name = "No Flash", Callback = function(v) S.noFlashEnabled = v; applyNoFlash() end})

local DeviceGroup = Misc:Group("Device Spoof")
DeviceGroup:Toggle({Name = "Enabled", Callback = function(v) S.deviceSpoofEnabled = v; applyDeviceSpoof() end})
DeviceGroup:Dropdown({Name = "Spoof As", Options = {"VR", "Touch", "Gamepad"}, Default = "VR", Callback = function(v) S.spoofDevice = v; if S.deviceSpoofEnabled then applyDeviceSpoof() end end})

local RagePlus = Library:Tab("Rage+", 10455604811)
local RagebotGroup = RagePlus:Group("Rage Engine")
RagebotGroup:Toggle({Name="Enabled", Default=Config.Rage, Callback=function(v)
    if v then
        RageEngine.enable()
    else
        RageEngine.disable()
    end
end})
RagebotGroup:Dropdown({Name="Mode", Options={"Polar", "Orbit"}, Default=Config.RageMode, Callback=function(v)
    Config.RageMode = v
    if Config.Rage then RageEngine.enable() end
end})
RagebotGroup:Dropdown({Name="Preferred Slot", Options={"Primary", "Secondary", "Melee"}, Default=Config.RagePreferredSlot, Callback=function(v)
    Config.RagePreferredSlot = v
    Config.RageWeaponPick = v
end})
RagebotGroup:Dropdown({Name="On Empty", Options={"Swap", "Reload"}, Default=Config.RageOnEmpty, Callback=function(v) Config.RageOnEmpty = v end})
RagebotGroup:Toggle({Name="Use Melee", Default=Config.RageSwitchMelee, Callback=function(v) Config.RageSwitchMelee = v end})
RagebotGroup:Toggle({Name="Prioritize Hackers", Default=Config.RagePrioritizeHackers, Callback=function(v) Config.RagePrioritizeHackers = v end})
RagebotGroup:Toggle({Name="Skip Immune Targets", Default=Config.RageSkipImmune, Callback=function(v) Config.RageSkipImmune = v end})
RagebotGroup:Toggle({Name="Predictive Prefire", Default=Config.RagePredictPrefire, Callback=function(v) Config.RagePredictPrefire = v end})
RagebotGroup:Toggle({Name="Attack Translocate", Default=Config.RageAttackTranslocate, Callback=function(v) Config.RageAttackTranslocate = v end})
RagebotGroup:Toggle({Name="Void Move", Default=Config.RageVoidMove, Callback=function(v) Config.RageVoidMove = v end})
RagebotGroup:Dropdown({Name="Void Depth", Options={"shallow", "deep"}, Default=Config.RageVoidDepth, Callback=function(v) Config.RageVoidDepth = v end})
RagebotGroup:Dropdown({Name="Gum Mode", Options={"off", "lite", "on"}, Default=Config.RageGumMode, Callback=function(v) Config.RageGumMode = v end})
RagebotGroup:Slider({Name="Orbit Radius", Min=20, Max=380, Default=Config.RageCombatOrbitRadius, Callback=function(v) Config.RageCombatOrbitRadius = v end})
RagebotGroup:Slider({Name="Orbit Height", Min=0, Max=40, Default=Config.RageCombatOrbitHeight, Callback=function(v) Config.RageCombatOrbitHeight = v end})
RagebotGroup:Slider({Name="Orbit Dwell", Min=0.10, Max=0.60, Default=Config.RageOrbitDwell, Decimals=2, Callback=function(v) Config.RageOrbitDwell = v end})
local ConfigTab = Library:Tab("Settings", 12403097620)
local ConfigGroup = ConfigTab:Group("Config")
local configName = "ArchScripts_Config.json"
local autoLoadConfig = false

local function saveConfig()
    local data = {}
    for k, v in pairs(S) do
        if typeof(v) == "Color3" then
            data[k] = {__type = "Color3", r = v.R, g = v.G, b = v.B}
        elseif typeof(v) == "EnumItem" then
            data[k] = {__type = "Enum", enum = tostring(v.EnumType), name = v.Name}
        elseif type(v) ~= "function" and typeof(v) ~= "RBXScriptConnection" and typeof(v) ~= "Instance" and typeof(v) ~= "userdata" then
            data[k] = v
        end
    end
    local json = HttpService:JSONEncode(data)
    if writefile then
        pcall(writefile, configName, json)
        Library:Notify("é…ç½®å·²ä¿å­˜", "success")
    else
        Library:Notify("æ— æ³•ä¿å­˜é…ç½®", "warning")
    end
end

local function loadConfig(silent)
    if not isfile or not readfile then
        if not silent then Library:Notify("æ— æ³•è¯»å–é…ç½®", "warning") end
        return
    end
    if not isfile(configName) then
        if not silent then Library:Notify("é…ç½®æ–‡ä»¶ä¸å­˜åœ¨", "warning") end
        return
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(configName))
    end)
    if not success or not data then
        if not silent then Library:Notify("é…ç½®è§£æžå¤±è´¥", "warning") end
        return
    end
    for k, v in pairs(data) do
        if type(v) == "table" then
            if v.__type == "Color3" then
                S[k] = Color3.new(v.r, v.g, v.b)
            elseif v.__type == "Enum" then
                local enumType = Enum[v.enum]
                if enumType then
                    S[k] = enumType[v.name]
                end
            else
                S[k] = v
            end
        else
            S[k] = v
        end
    end
    ApplyAllSettings()
    if not silent then Library:Notify("é…ç½®å·²åŠ è½½", "success") end
end

ConfigGroup:Toggle({
    Name = "Auto Load Config",
    Default = autoLoadConfig,
    Callback = function(on)
        autoLoadConfig = on
    end
})
ConfigGroup:Button({Name = "Save Config", Variant = "Primary", Callback = saveConfig})
ConfigGroup:Button({Name = "Load Config", Callback = function() loadConfig(false) end})

if autoLoadConfig then
    loadConfig(true)
end

Library.MenuKey = Enum.KeyCode.Insert
local Visible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Library.MenuKey then
        Visible = not Visible
        MainFrame.Visible = Visible
    end
end)

local MobileToggle = Create("ImageButton", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = CFG.MainColor,
    BackgroundTransparency = 1,          -- 背景完全透明
    Image = "rbxassetid://3926305904",
    ImageColor3 = CFG.AccentColor,
    ImageTransparency = 1,               -- 图标也完全透明（可选）
    AutoButtonColor = false
}, {
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
    Create("UIStroke", {Color = CFG.AccentColor, Thickness = 0})  -- 边框粗细改为0隐藏边框
})

MobileToggle.MouseButton1Click:Connect(function()
    Visible = not Visible
    MainFrame.Visible = Visible
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    setSpeed(S.speedValue)

    if S.voidActive then
        task.wait(0.5)
        toggleVoid(true)
    end
    if S.orbActive then toggleOrbit(true) end
    if S.fistActive then toggleFist(true) end
    if S.roitActive then toggleRiot(true) end
    if S.noclipActive then toggleNoclip(true) end
    if S.wallbangActive then
        stopWallbang()
        startWallbang()
    end
    if S.espActive then
        if espConn then espConn:Disconnect() end
        espConn = RunService.RenderStepped:Connect(updateMobileESP)
    end
    if S.aimbotActive then
        toggleAimbot(true)
    end
    if S.flyActive then toggleFly(true) end
    if S.spinActive then toggleSpin(true) end
    if S.noFallActive then toggleNoFall(true) end

    if _G.AntiAimSettings.enabled then
        _G.StartAntiAimExt()
    end
    if S.undergroundActive then
        task.wait(0.5)
        toggleUnderground(true)
    end

    if S.irregularMoveActive then
        startIrregularMove()
    end

    if S.triggerbotEnabled then
        startTriggerbot()
    end

    task.wait(1)
    applyGunEnhancements()
    patchGunSpread()
    applyNoSmoke()
    applyNoFlash()
    applyDeviceSpoof()
end)

Library:Notify("Arch Scripts + Mobile ESP + Advanced Anti-Aim/Underground + Anti Katana + Slide Boost + Config loaded", "success")
