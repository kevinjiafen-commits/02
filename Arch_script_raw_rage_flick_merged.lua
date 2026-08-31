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
                    Text = "▼",
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
    aimFov = 30,
    silentFov = 30,
    aimTargetPart = "Head",
    silentTargetPart = "Head",
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

local MAX_ESP = 50
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
    outline.BorderSizePixel = 1
    outline.BorderColor3 = Color3.new(1,1,1)
    outline.Parent = box

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1,0,1,0)
    fill.BackgroundTransparency = 0.85
    fill.BackgroundColor3 = Color3.new(0,0,0)
    fill.Parent = box

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.TextSize = 11
    name.Font = Enum.Font.SourceSans
    name.TextColor3 = Color3.new(1,1,1)
    name.Text = ""
    name.Parent = box

    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency = 1
    dist.TextSize = 10
    dist.Font = Enum.Font.SourceSans
    dist.TextColor3 = Color3.new(0.8,0.8,0.8)
    dist.Text = ""
    dist.Parent = box

    local hpBar = Instance.new("Frame")
    hpBar.Size = UDim2.new(1,0,0,3)
    hpBar.BackgroundColor3 = Color3.new(0,0,0)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = box
    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1,0,1,0)
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
            local height = (root.Position - head.Position).Magnitude * 1.8
            local width = height * 0.5
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
                esp.dist.Position = UDim2.new(0.5,0,1,2)
                esp.dist.Visible = true
            else
                esp.dist.Visible = false
            end

            if S.espShowHealthBar then
                esp.hpBar.Visible = true
                esp.hpFill.Size = UDim2.new(hum.Health/hum.MaxHealth, 0, 1, 0)
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
        Gun.StartShooting = function(self, p1, p2)
            if S.silentAimActive then
                local targetPartInstance = nil
                local targetPlayer = nil
                local camPos = Camera.CFrame.Position
                local camDir = Camera.CFrame.LookVector
                local closestAngle = S.silentFov
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
                                closestAngle = degrees
                                targetPartInstance = part
                                targetPlayer = p
                            end
                        end
                    end
                end
                if targetPartInstance then
                    if getgenv().IsKatanaDeflecting and getgenv().IsKatanaDeflecting(targetPlayer) then
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
local gunExceptions = {["Sniper"]=true,["Crossbow"]=true,["Bow"]=true,["RPG"]=true}
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
        if typeof(data) == "table" and not gunExceptions[name] and originalGunStats[name] then
            data.ShootCooldown = delaySec
            if data.ShootBurstCooldown ~= nil then data.ShootBurstCooldown = delaySec end
            data.ShootSpread = 0; data.ShootAccuracy = 0; data.ShootRecoil = 0
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
    S.speedValue = val
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = val
            if speedConn then speedConn:Disconnect() end
            speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if hum.WalkSpeed ~= val then hum.WalkSpeed = val end
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

local RageCore = (function()
    local Settings = {
        Enabled = false,
        RagebotKeybind = Enum.KeyCode.Unknown,
        Stability = 0.15,
        ShootFrames = 1,
        PrioritizeHackers = false,
        WeaponPrimary = true,
        WeaponSecondary = true,
        WeaponMelee = true,
        OnEmpty = "SwapOrReload",
        EvasionMode = "Random",
        TranslocateOffset = -5,
        RandomBaseRadius = 100,
        RandomRadiusFactor = 0.5,
        RandomAnchorFromCharacter = false,
        FlickbotEnabled = false,
        FlickbotKeybind = Enum.KeyCode.Unknown,
        FlickbotShot = false,
        FlickbotShotDelay = 0,
        FlickbotCooldown = 250,
        FlickbotDuration = 110,
        FlickbotCurvature = 12,
        FlickbotHumanness = 30
    }

    local function opt(id, default)
        local map = {
            P8S4S1 = Settings.Stability,
            P8S4S2 = Settings.ShootFrames,
            P8S4S3 = Settings.TranslocateOffset,
            P8S4S4 = Settings.RandomBaseRadius,
            P8S4S5 = Settings.RandomRadiusFactor,
            P8S4D1 = Settings.OnEmpty,
            P8S4D2 = Settings.EvasionMode,
            P2S1S8 = Settings.FlickbotShotDelay,
            P2S1S9 = Settings.FlickbotCooldown,
            P2S1S10 = Settings.FlickbotDuration,
            P2S1S11 = Settings.FlickbotCurvature,
            P2S1S12 = Settings.FlickbotHumanness
        }
        local v = map[id]
        return v ~= nil and v or default
    end

    local function tog(id, default)
        local map = {
            P8S4T1 = Settings.Enabled,
            P8S4T4 = Settings.PrioritizeHackers,
            P8S4T5 = Settings.WeaponPrimary,
            P8S4T6 = Settings.WeaponSecondary,
            P8S4T7 = Settings.WeaponMelee,
            P8S4T8 = Settings.RandomAnchorFromCharacter,
            P2S1T12 = Settings.FlickbotEnabled,
            P2S1T13 = Settings.FlickbotShot
        }
        local v = map[id]
        return v ~= nil and v or default
    end

    local RageToggles = {}
    local RageOptions = {}
    for id, value in pairs({
        P8S4T1=Settings.Enabled,P8S4T4=Settings.PrioritizeHackers,P8S4T5=Settings.WeaponPrimary,
        P8S4T6=Settings.WeaponSecondary,P8S4T7=Settings.WeaponMelee,P8S4T8=Settings.RandomAnchorFromCharacter,
        P2S1T12=Settings.FlickbotEnabled,P2S1T13=Settings.FlickbotShot
    }) do
        RageToggles[id] = {Value=value}
    end
    for id, value in pairs({
        P8S4S1=Settings.Stability,P8S4S2=Settings.ShootFrames,P8S4S3=Settings.TranslocateOffset,
        P8S4S4=Settings.RandomBaseRadius,P8S4S5=Settings.RandomRadiusFactor,P8S4D1=Settings.OnEmpty,
        P8S4D2=Settings.EvasionMode,P2S1S8=Settings.FlickbotShotDelay,P2S1S9=Settings.FlickbotCooldown,
        P2S1S10=Settings.FlickbotDuration,P2S1S11=Settings.FlickbotCurvature,P2S1S12=Settings.FlickbotHumanness
    }) do
        RageOptions[id] = {Value=value}
    end
    RageOptions.P8S4T1K = {
        GetState = function()
            local k = Settings.RagebotKeybind
            return k and k ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(k) or false
        end
    }
    RageOptions.P2S1T12K = {
        GetState = function()
            local k = Settings.FlickbotKeybind
            return k and k ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(k) or false
        end
    }

    local Bridge = {}
    local Genv = _G
    if type(getgenv) == "function" then local ok, env = pcall(getgenv); if ok and type(env) == "table" then Genv = env end end
    if type(Genv) ~= "table" then Genv = _G end
    Genv.KiciaHookCaps = Genv.KiciaHookCaps or {
        gate = function(_, ...)
            local names = {...}
            for _, name in ipairs(names) do
                if type(Genv[name]) ~= "function" then return false end
            end
            return true
        end
    }
    Genv.KiciaHookCaps.gate = Genv.KiciaHookCaps.gate or function(_, ...)
        local names = {...}
        for _, name in ipairs(names) do
            if type(Genv[name]) ~= "function" then return false end
        end
        return true
    end

    local function IsReadyToFight()
        local char = LocalPlayer and LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return hum ~= nil and hum.Health > 0 and root ~= nil
    end
    Bridge.IsReadyToFight = IsReadyToFight

    local FighterDataCache = {LocalDuel = {}}
    local cloneref = cloneref or function(o) return o end
    local clonefunction = clonefunction or copyfunction or function(f) return f end
    local sethiddenproperty = sethiddenproperty or function(obj, prop, value) pcall(function() obj[prop] = value end) end
    local gethiddenproperty = gethiddenproperty or function(obj, prop) local ok,v=pcall(function() return obj[prop] end); return ok and v or nil end
    local setthreadidentity = setthreadidentity or function() end
    local getthreadidentity = getthreadidentity or function() return 0 end
    local sfflag = sfflag or setfflag or function() end
    local RivalsRuntimeBridge = Bridge
    local Options = RageOptions
    local Toggles = RageToggles
    local __kicia_hook_genv = Genv
    local function GetChar()
        return LocalPlayer and LocalPlayer.Character
    end
    local function GetRoot()
        local c = GetChar()
        return c and c:FindFirstChild("HumanoidRootPart")
    end

        
            local KiciaRagebot = {}
            RivalsRuntimeBridge.KiciaRagebot = KiciaRagebot

            local RunService = game:GetService('RunService')
            local HttpServiceRB = cloneref(game:GetService('HttpService'))
            local CollectionServiceRB = cloneref(game:GetService('CollectionService'))
            local PlayersRB = cloneref(game:GetService('Players'))
            local ReplicatedStorageRB = cloneref(game:GetService('ReplicatedStorage'))
            local WorkspaceRB = workspace
            local LPRB = PlayersRB.LocalPlayer
            local rbRandom = Random.new()

            -- Executor capability shims (all feature-detected live on build 17625359962).
            local rbSetHidden = sethiddenproperty
            local rbSetFFlag = (type(setfflag) == 'function') and setfflag or sfflag
            local rbSetThreadIdentity = setthreadidentity
            local rbGetThreadIdentity = getthreadidentity

            -- Clean FireServer stolen off a throwaway RemoteEvent (matches the script's No Spread
            -- calling convention: positional call, never :FireServer()).
            local rbCleanFireEvent = Instance.new('RemoteEvent')
            local rbFireServerNative = clonefunction(rbCleanFireEvent.FireServer)

            local function rbRawWrite(obj, key, value)
                if typeof(obj) == 'Instance' then
                    if not pcall(rbSetHidden, obj, key, value) then
                        pcall(function() obj[key] = value end)
                    end
                else
                    pcall(rawset, obj, key, value)
                end
            end

            -- ---- settings (read live from the Obsidian controls; Kicia defaults as fallback) ----
            local function optValue(id, default)
                local o = Options and Options[id]
                if o and o.Value ~= nil then
                    return o.Value
                end
                return default
            end
            local function togValue(id, default)
                local t = Toggles and Toggles[id]
                if t and t.Value ~= nil then
                    return t.Value == true
                end
                return default
            end
            local Setting = {
                Stability = function() return optValue('P8S4S1', 0.15) end,
                ShootFrames = function() return optValue('P8S4S2', 1) end,
                PrioritizeHackers = function() return togValue('P8S4T4', false) end,
                WeaponPrimary = function() return togValue('P8S4T5', true) end,
                WeaponSecondary = function() return togValue('P8S4T6', true) end,
                WeaponMelee = function() return togValue('P8S4T7', true) end,
                OnEmpty = function() return optValue('P8S4D1', 'SwapOrReload') end,
                EvasionMode = function() return optValue('P8S4D2', 'Random') end,
                TranslocateOffset = function() return optValue('P8S4S3', -5) end,
                RandomBaseRadius = function() return optValue('P8S4S4', 100) end,
                RandomRadiusFactor = function() return optValue('P8S4S5', 0.5) end,
                RandomAnchorFromCharacter = function() return togValue('P8S4T8', false) end,
                -- ProjectileBreaker has no Kicia UI; RepositionInterval keeps Kicia's default.
                RepositionInterval = function() return 0.3 end,
            }
            -- Kicia's ProjectileBreaker depth constants (config present in Kicia; no UI slider).
            local PB_DEPTH_FORWARD = { Min = 0, Max = 4 }
            local PB_DEPTH_FORWARD_FREQ = 5
            local PB_DEPTH_UP = { Min = 0, Max = 5.5 }
            local PB_DEPTH_UP_FREQ = 5
            local PB_FALLBACK_BASE_RADIUS = 100
            local PB_FALLBACK_RADIUS_FACTOR = 0.5
            local PB_FALLBACK_ANCHOR_FROM_CHARACTER = false

            -- ---- self-contained game-handle resolution -----------------------------------
            local function findChild(root, ...)
                local node = root
                for _, name in ipairs({ ... }) do
                    if not node then
                        return nil
                    end
                    node = node:FindFirstChild(name)
                end
                return node
            end

            local cachedEnumLibrary = nil
            local function resolveEnumLibrary()
                if cachedEnumLibrary then
                    return cachedEnumLibrary
                end
                local mod = findChild(ReplicatedStorageRB, 'Modules', 'EnumLibrary')
                if not mod then
                    return nil
                end
                local ok, lib = pcall(require, mod)
                if ok and type(lib) == 'table' then
                    cachedEnumLibrary = lib
                    return lib
                end
                return nil
            end
            local function enc(name)
                local lib = resolveEnumLibrary()
                if not lib then
                    return nil
                end
                local ok, token = pcall(lib.ToEnum, lib, name)
                if ok then
                    return token
                end
                return nil
            end

            local cachedUseItemRemote = nil
            local function resolveUseItemRemote()
                if cachedUseItemRemote and cachedUseItemRemote.Parent then
                    return cachedUseItemRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UseItem')
                if remote and remote:IsA('RemoteEvent') then
                    cachedUseItemRemote = cloneref(remote)
                    return cachedUseItemRemote
                end
                return nil
            end
            local cachedUpdateStateRemote = nil
            local function resolveUpdateStateRemote()
                if cachedUpdateStateRemote and cachedUpdateStateRemote.Parent then
                    return cachedUpdateStateRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UpdateState')
                if remote and remote:IsA('RemoteEvent') then
                    cachedUpdateStateRemote = cloneref(remote)
                    return cachedUpdateStateRemote
                end
                return nil
            end
            local cachedCameraRotationRemote = nil
            local function resolveCameraRotationRemote()
                if cachedCameraRotationRemote and cachedCameraRotationRemote.Parent then
                    return cachedCameraRotationRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UpdateCameraRotation')
                if remote and remote:IsA('RemoteEvent') then
                    cachedCameraRotationRemote = cloneref(remote)
                    return cachedCameraRotationRemote
                end
                return nil
            end
            local function requireModuleRB(name)
                local mod = findChild(ReplicatedStorageRB, 'Modules', name)
                if not mod then
                    return nil
                end
                local ok, result = pcall(require, mod)
                if ok then
                    return result
                end
                return nil
            end

            -- FighterController singleton (carries LocalFighter + Objects) + its prototype
            -- (carries _CameraReplicationLoop).  Cached with cheap revalidation.
            local cachedFighterController = nil
            local function resolveFighterController()
                local cc = cachedFighterController
                if type(cc) == 'table' and rawget(cc, 'LocalFighter') ~= nil then
                    return cc
                end
                for _, m in ipairs(getgc(true)) do
                    if type(m) == 'table' and rawget(m, 'LocalFighter') ~= nil and rawget(m, 'Objects') ~= nil then
                        cachedFighterController = m
                        return m
                    end
                end
                return nil
            end
            local function resolveLocalFighter()
                local controller = resolveFighterController()
                return controller and rawget(controller, 'LocalFighter') or nil
            end
            local cachedFCPrototype = nil
            local function resolveFighterControllerPrototype()
                if type(cachedFCPrototype) == 'table' and rawget(cachedFCPrototype, '_CameraReplicationLoop') ~= nil then
                    return cachedFCPrototype
                end
                local controller = resolveFighterController()
                if controller then
                    local mt = getmetatable(controller)
                    local proto = mt and rawget(mt, '__index') or nil
                    if type(proto) == 'table' and rawget(proto, '_CameraReplicationLoop') ~= nil then
                        cachedFCPrototype = proto
                        return proto
                    end
                end
                for _, m in ipairs(getgc(true)) do
                    if type(m) == 'table' then
                        local idx = rawget(m, '__index')
                        if type(idx) == 'table' and rawget(idx, '_CameraReplicationLoop') ~= nil then
                            cachedFCPrototype = idx
                            return idx
                        end
                    end
                end
                return nil
            end

            -- ---- firing transport (Kicia t157/t16, lines 73511 / 88523 / 88535) ----------
            local function fireGun(objectId, isRaycast, aim1, aim2, hitboxHead, extra)
                local remote = resolveUseItemRemote()
                local token = enc('StartShooting')
                if not remote or not token or not objectId then
                    return
                end
                local inner = { ['\0'] = aim1, ['\1'] = aim2, ['\2'] = hitboxHead, ['\3'] = extra }
                local payload
                if isRaycast then
                    payload = { ['\1'] = inner, ['\2'] = true }
                else
                    payload = { ['\1'] = inner }
                end
                rbFireServerNative(remote, objectId, token, payload, nil)
            end
            local function fireMeleeAttack(objectId, a, b, c, d)
                local remote = resolveUseItemRemote()
                local token = enc('StartShooting')
                local anim = enc('AttackAnimation1')
                if not remote or not token or not anim or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, token, { ['\1'] = { ['\0'] = a, ['\1'] = b, ['\2'] = c, ['\3'] = d }, ['\2'] = anim }, nil)
            end
            local function fireMeleeHeavy(objectId, a, b, c, d)
                local remote = resolveUseItemRemote()
                local token = enc('StartAiming') -- Kicia HeavyAttackEncoded uses StartAiming
                local anim = enc('HeavyAttackAnimation1')
                if not remote or not token or not anim or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, token, { ['\1'] = { ['\0'] = a, ['\1'] = b, ['\2'] = c, ['\3'] = d }, ['\2'] = anim }, nil)
            end
            local function fireReload(objectId)
                local remote = resolveUseItemRemote()
                local start = enc('StartReloading')
                local reload = enc('Reload')
                if not remote or not start or not reload or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, start, { ['\1'] = reload, ['\2'] = reload }, nil)
            end

            -- ---- raw ClientItem helpers --------------------------------------------------
            local function itemObjectId(item)
                local data = rawget(item, 'Data')
                return data and rawget(data, 'ObjectID') or nil
            end
            local function itemInfo(item)
                return rawget(item, 'Info')
            end
            local function itemType(item)
                local info = itemInfo(item)
                return info and rawget(info, 'Type') or nil
            end
            local function itemIsRaycast(item)
                local info = itemInfo(item)
                return info and rawget(info, 'IsRaycast') == true
            end
            local function itemName(item)
                return rawget(item, 'Name') or rawget(item, 'ItemName')
            end
            local function itemAmmo(item)
                local data = rawget(item, 'Data')
                local ammo = data and rawget(data, 'Ammo')
                return type(ammo) == 'number' and ammo or 0
            end
            local function itemAmmoReserve(item)
                local data = rawget(item, 'Data')
                local reserve = data and rawget(data, 'AmmoReserve')
                if type(reserve) ~= 'number' then
                    return math.huge
                end
                return reserve
            end
            -- Kicia t157:IsReloading (lines 73560-73573): _reload_cooldown OR _shoot_cooldown_no_ammo.
            local function itemIsReloading(item)
                local now = tick()
                local cooldown = rawget(item, '_reload_cooldown')
                if type(cooldown) == 'number' and now < cooldown then
                    return true
                end
                local noAmmoCooldown = rawget(item, '_shoot_cooldown_no_ammo')
                return type(noAmmoCooldown) == 'number' and now < noAmmoCooldown
            end
            -- Kicia t157:IsMagFull (line 73575): Info.MaxAmmo <= current ammo.
            local function itemIsMagFull(item)
                local info = itemInfo(item)
                local maxAmmo = info and rawget(info, 'MaxAmmo')
                return type(maxAmmo) == 'number' and maxAmmo <= itemAmmo(item)
            end
            -- Kicia t157:IsEquipped (line 73501): the item's own IsEquipped field - the same
            -- read the game's Items modules (Minigun, Riot Shield) use. The fighter-side
            -- Data.EquippedItemID compare it replaced never matched Kicia and is gone.
            local function itemIsEquipped(item)
                return rawget(item, 'IsEquipped')
            end
            -- Kicia t157:Equip (lines 73493-73499): no-op when equipped, then
            -- item.ClientFighter:EquipItem(index). ClientFighter lives on the ITEM (the
            -- LocalFighter IS a ClientFighter and has no such field; live-verified),
            -- and index is the fighter's Items-table key - the exact value the game's
            -- QuickAttackSystem passes (EquipItem(table.find(ClientFighter.Items, item))).
            local function equipItem(item, index)
                if itemIsEquipped(item) then
                    return
                end
                local clientFighter = rawget(item, 'ClientFighter')
                if clientFighter and index and type(clientFighter.EquipItem) == 'function' then
                    pcall(function() clientFighter:EquipItem(index) end)
                end
            end
            -- Kicia t157:Reload guard (lines 73539-73546).
            local function reloadItem(item)
                if itemIsReloading(item) or itemAmmoReserve(item) <= 0 or itemIsMagFull(item) then
                    return
                end
                fireReload(itemObjectId(item))
            end

            -- ---- spoofed aim payload tables (hitscan strategy, lines 40519-40551) ---------
            local NEG_HUGE = -9e37
            local function buildAim(base, pitch, oy, oz)
                return {
                    ['\0'] = base['\0'], ['\1'] = base['\1'], ['\2'] = base['\2'],
                    ['\3'] = pitch, ['\4'] = oy, ['\5'] = oz,
                }
            end
            local AIM_ABOVE_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t91
            local AIM_ABOVE_END = { ['\0'] = 0, ['\1'] = -90000000, ['\2'] = 0 }           -- t92
            local AIM_BELOW_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t93
            local AIM_BELOW_END = { ['\0'] = 0, ['\1'] = 90000000, ['\2'] = 0 }            -- t94
            local AIM_EXTRA = { ['\0'] = 0, ['\1'] = 1, ['\2'] = 0, ['\3'] = 0, ['\4'] = 0, ['\5'] = 0 } -- t95
            local OFFSET_ABOVE = Vector3.new(0, -0.7, 0.05)                                -- v230/v138
            local OFFSET_BELOW = Vector3.new(0, -3.85, 0.05)                               -- v231/v139
            local PITCH_ABOVE = -math.pi / 2                                               -- v140
            local PITCH_BELOW = math.pi / 2                                                -- v141

            -- Riot-Shield-aware above/below classifier (Kicia ia(), lines 151550-151570).
            -- "None" for shield-less targets (common case) folds to Above.  Enemy
            -- itemObserver/camera are best-effort on this build; shield-less path is exact.
            local function classifyAboveBelow(target)
                local obs = target and target.itemObserver
                if obs then
                    local ok, result = pcall(function()
                        local equipped = obs:GetEquippedItem()
                        if equipped ~= nil and equipped.name == 'Riot Shield' then
                            local pitch = math.deg(target:GetCameraRotation().X)
                            if 22 < pitch and pitch < 91 then
                                return 'Below'
                            end
                            return 'Above'
                        end
                        for _, it in obs:GetItems() do
                            if it.name == 'Riot Shield' then
                                local pitch = math.deg(target:GetCameraRotation().X)
                                if 315 < pitch and pitch < 360 or 0 < pitch and pitch < 91 then
                                    return 'Above'
                                end
                                return 'Below'
                            end
                        end
                        return 'None'
                    end)
                    if ok and result then
                        return result
                    end
                end
                return 'None'
            end
            local function isAbove(target)
                return classifyAboveBelow(target) ~= 'Below'
            end

            -- ---- root virtualization (Kicia t201, lines 145034-145080) -------------------
            local RootDesync = {}
            RootDesync.__index = RootDesync
            function RootDesync.new(rootPart)
                local self = setmetatable({
                    _rootPart = rootPart,
                    _boundId = HttpServiceRB:GenerateGUID(false),
                    _oldCFrame = rootPart.CFrame,
                    _cframe = nil,
                }, RootDesync)
                RunService:BindToRenderStep(self._boundId, Enum.RenderPriority.First.Value, function()
                    self:_RenderStepUpdate()
                end)
                return self
            end
            function RootDesync:_RenderStepUpdate()
                local old = self._oldCFrame
                if old ~= nil then
                    self._rootPart.CFrame = old
                    self._oldCFrame = nil
                end
            end
            function RootDesync:SetServerCFrame(cf)
                self._cframe = cf
            end
            function RootDesync:GetServerCFrame()
                return self._cframe or self._rootPart.CFrame
            end
            function RootDesync:GetClientCFrame()
                return self._oldCFrame or self._rootPart.CFrame
            end
            function RootDesync:HeartbeatUpdate()
                local cf = self._cframe
                if cf ~= nil then
                    self._oldCFrame = self._rootPart.CFrame
                    self._rootPart.CFrame = cf
                end
            end
            function RootDesync:Destroy()
                pcall(function() RunService:UnbindFromRenderStep(self._boundId) end)
            end

            -- ---- view-angle driver (Kicia t1141, lines 196889-197137) --------------------
            -- Hooks ClientFighterCharacterJoints.Update + FighterController._CameraReplicationLoop
            -- to inject a spoofed CameraRotationRaw so the replicated camera does not stare at the
            -- void.  Two deobfuscator artifacts are reconstructed to their unambiguous intent
            -- (recorded as anomalies A/B/C while recovering this function):
            --   * encodeCameraRotation (Vector2->2 bytes) and encodeSingle (scalar->1 byte) were
            --     collapsed onto one key in the dump; both restored from their recovered bodies.
            --   * _Resolve's priority loop was erased (junk filler); reconstructed as "winner =
            --     the highest numeric-priority live slot" (the ragebot uses one slot, priority 20).
            local function encodeSingle(n)
                if n == n then
                    return utf8.char(math.clamp(math.floor(n % (2 * math.pi) / math.pi / 2 * 256 + 0.5), 0, 255))
                end
                return utf8.char(0)
            end
            local function encodeCameraRotation(v)
                if v == v then
                    return utf8.char(math.clamp(math.floor(v.X % (2 * math.pi) / math.pi / 2 * 256 + 0.5), 0, 255))
                        .. utf8.char(math.clamp(math.floor(v.Y % (2 * math.pi) / math.pi / 2 * 256 + 0.5), 0, 255))
                end
                return utf8.char(0) .. utf8.char(0)
            end
            local function decodeSingle(s)
                return utf8.codepoint(s) * math.pi * 2 / 256
            end
            local function anglesToRaw(a)
                if a.kind == 'Unnormalized' then
                    return Vector2.new(a.pitch, 0) * math.pi * 2 / 256
                end
                return Vector2.new(decodeSingle(encodeSingle(math.rad(a.pitch))), decodeSingle(encodeSingle(math.rad(a.yaw))))
            end
            local function anglesToEncoded(a)
                if a.kind == 'Unnormalized' then
                    return utf8.char(math.clamp(a.pitch, 0, 255)) .. utf8.char(math.clamp(a.yaw, 0, 255))
                end
                return encodeSingle(math.rad(a.pitch)) .. encodeSingle(math.rad(a.yaw))
            end

            local ViewAngleDriver = {}
            ViewAngleDriver.__index = ViewAngleDriver
            function ViewAngleDriver.new()
                return setmetatable({
                    _slots = {},
                    _winning = nil,
                    _fullySuppressed = false,
                    _dirty = false,
                }, ViewAngleDriver)
            end
            function ViewAngleDriver:_Resolve()
                local best, winner = nil, nil
                for priority, value in pairs(self._slots) do
                    if value ~= nil and (best == nil or priority > best) then
                        best = priority
                        winner = value
                    end
                end
                self._winning = winner
            end
            function ViewAngleDriver:_LoadJointsHook()
                if self._jointsRestore ~= nil then
                    return true
                end
                local joints = requireModuleRB('ClientFighterCharacterJoints')
                local original = joints and rawget(joints, 'Update') or nil
                if not joints or original == nil then
                    return false
                end
                local driver = self
                local function hooked(jointsSelf, a, b)
                    local cfc = rawget(jointsSelf, 'ClientFighterCharacter')
                    local cf = cfc and rawget(cfc, 'ClientFighter') or nil
                    if cf == nil then
                        return original(jointsSelf, a, b)
                    end
                    if rawget(cf, 'IsLocalPlayer') == true then
                        local winning = driver._winning
                        if winning ~= nil then
                            rbRawWrite(b, 'CameraRotationRaw', anglesToRaw(winning))
                        end
                    end
                    return original(jointsSelf, a, b)
                end
                rawset(joints, 'Update', hooked)
                self._jointsRestore = { joints = joints, original = original }
                return true
            end
            function ViewAngleDriver:_LoadReplicationHook()
                if self._replicationRestore ~= nil then
                    return true
                end
                local proto = resolveFighterControllerPrototype()
                local instance = resolveFighterController()
                local loop = proto and rawget(proto, '_CameraReplicationLoop') or nil
                if not proto or not instance or loop == nil then
                    return false
                end
                local utilIndex, util
                local ok, upvalues = pcall(debug.getupvalues, loop)
                if ok and type(upvalues) == 'table' then
                    for index, value in pairs(upvalues) do
                        if type(value) == 'table' then
                            local vmt = getmetatable(value)
                            local vidx = vmt and rawget(vmt, '__index') or nil
                            if vidx ~= nil and rawget(vidx, 'EncodeCameraRotation') ~= nil then
                                util = value
                                utilIndex = index
                                break
                            end
                        end
                    end
                end
                if utilIndex == nil or util == nil then
                    return false
                end
                local driver = self
                local replacement = {}
                function replacement.EncodeCameraRotation(_, raw)
                    if next(driver._slots) == nil and not driver._fullySuppressed then
                        return encodeCameraRotation(raw)
                    end
                    rbRawWrite(instance, '_replication_stopped', false)
                    local last = rawget(instance, '_last_encoded_camera_rotation')
                    if not last then
                        last = encodeCameraRotation(raw)
                    end
                    return last
                end
                if not pcall(debug.setupvalue, loop, utilIndex, replacement) then
                    return false
                end
                self._replicationRestore = { loop = loop, utilityIndex = utilIndex, utility = util }
                return true
            end
            function ViewAngleDriver:SendViewAngles(priority, value)
                if self._slots[priority] == value then
                    return
                end
                self._slots[priority] = value
                self._dirty = true
                self:_Resolve()
                if self._winning == nil then
                    return
                end
                if self:_LoadJointsHook() then
                    self:_LoadReplicationHook()
                end
            end
            function ViewAngleDriver:Flush()
                if not self._dirty or self._fullySuppressed then
                    return
                end
                local winning = self._winning
                if winning == nil then
                    self._dirty = false
                    return
                end
                self._dirty = false
                local remote = resolveCameraRotationRemote()
                if remote then
                    rbFireServerNative(remote, anglesToEncoded(winning), nil)
                end
            end
            function ViewAngleDriver:ClearAll()
                table.clear(self._slots)
                self._winning = nil
                self._dirty = false
            end
            function ViewAngleDriver:Destroy()
                local jointsRestore = self._jointsRestore
                if jointsRestore ~= nil then
                    self._jointsRestore = nil
                    pcall(rawset, jointsRestore.joints, 'Update', jointsRestore.original)
                end
                local replicationRestore = self._replicationRestore
                if replicationRestore ~= nil then
                    self._replicationRestore = nil
                    pcall(debug.setupvalue, replicationRestore.loop, replicationRestore.utilityIndex, replicationRestore.utility)
                end
            end

            -- ---- character controller wrapper (Kicia t4, lines 25419-25541) --------------
            local CharacterController = {}
            CharacterController.__index = CharacterController
            function CharacterController.new(rootPart)
                return setmetatable({
                    _rootDesync = RootDesync.new(rootPart),
                    _viewAngleDriver = ViewAngleDriver.new(),
                }, CharacterController)
            end
            function CharacterController:SetServerCFrame(cf)
                if self._rootDesync then
                    self._rootDesync:SetServerCFrame(cf)
                end
            end
            function CharacterController:GetClientCFrame()
                return self._rootDesync and self._rootDesync:GetClientCFrame() or nil
            end
            function CharacterController:SendViewAngles(priority, value)
                self._viewAngleDriver:SendViewAngles(priority, value)
            end
            function CharacterController:HeartbeatUpdate()
                if self._rootDesync then
                    self._rootDesync:HeartbeatUpdate()
                end
                self._viewAngleDriver:Flush()
            end
            function CharacterController:Destroy()
                self._viewAngleDriver:ClearAll()
                self._viewAngleDriver:Destroy()
                if self._rootDesync then
                    self._rootDesync:Destroy()
                    self._rootDesync = nil
                end
            end

            -- ---- forced-crouch state hook (Kicia t192, lines 12022-12081, simplified) -----
            -- Kicia additionally installs a dummy _UpdateServerState to suppress the game's
            -- own conflicting sends; the essential forcing is firing UpdateState directly.
            local StateHook = {}
            StateHook.__index = StateHook
            function StateHook.new()
                return setmetatable({ _forced = {} }, StateHook)
            end
            function StateHook:SetForced(name, value)
                local token = enc(name)
                if token == nil or self._forced[token] == value then
                    return
                end
                local remote = resolveUpdateStateRemote()
                if not remote then
                    return
                end
                self._forced[token] = value
                rbFireServerNative(remote, token, value, nil)
            end
            function StateHook:ClearForced(name, offValue)
                local token = enc(name)
                if token == nil or self._forced[token] == nil then
                    return
                end
                self._forced[token] = nil
                local remote = resolveUpdateStateRemote()
                if remote then
                    rbFireServerNative(remote, token, offValue, nil)
                end
            end

            -- ---- part glue (Kicia t116, lines 150715-150820) -----------------------------
            local VOID_CFRAME = CFrame.new(
                math.random(-100000, -10000),
                100000,
                math.random(-100000, 10000)
            )
            local PartGlue = {}
            PartGlue.__index = PartGlue
            function PartGlue.new()
                return setmetatable({ _gluedParts = {}, _bindings = {} }, PartGlue)
            end
            function PartGlue:_SetupGlue(part)
                local entry = self._gluedParts[part]
                if entry ~= nil then
                    entry.refCount = entry.refCount + 1
                    return
                end
                local weld = part:FindFirstChildOfClass('WeldConstraint')
                local originalPart1 = nil
                if weld ~= nil then
                    originalPart1 = weld.Part1
                    if originalPart1 ~= nil then
                        weld.Part1 = nil
                    end
                    part.Anchored = true
                end
                self._gluedParts[part] = { refCount = 1, weld = weld, originalPart1 = originalPart1 }
            end
            function PartGlue:_ReleaseGlue(part)
                local entry = self._gluedParts[part]
                if entry == nil then
                    return
                end
                entry.refCount = entry.refCount - 1
                if 0 < entry.refCount then
                    return
                end
                local weld = entry.weld
                if weld ~= nil and entry.originalPart1 ~= nil then
                    weld.Part1 = entry.originalPart1
                    entry.originalPart1.Anchored = false
                end
                self._gluedParts[part] = nil
            end
            function PartGlue:Acquire(ourPart, hitboxPart, useRotation)
                local prev = rbGetThreadIdentity()
                rbSetThreadIdentity(8)
                pcall(rbSetHidden, ourPart, 'PhysicsRepRootPart', hitboxPart)
                rbSetThreadIdentity(prev)
                local bound = self._bindings[ourPart]
                if bound ~= hitboxPart then
                    if bound ~= nil then
                        self:_ReleaseGlue(bound)
                    end
                    self:_SetupGlue(hitboxPart)
                    self._bindings[ourPart] = hitboxPart
                end
                local cf = CFrame.new(VOID_CFRAME.Position)
                if useRotation then
                    cf = cf * hitboxPart.CFrame.Rotation
                end
                hitboxPart.CFrame = cf
                return VOID_CFRAME
            end
            function PartGlue:Free(ourPart)
                local bound = self._bindings[ourPart]
                if bound == nil then
                    return
                end
                self._bindings[ourPart] = nil
                self:_ReleaseGlue(bound)
                local prev = rbGetThreadIdentity()
                rbSetThreadIdentity(8)
                pcall(rbSetHidden, ourPart, 'PhysicsRepRootPart', nil)
                rbSetThreadIdentity(prev)
            end
            function PartGlue:Destroy()
                for _, entry in pairs(self._gluedParts) do
                    local weld = entry.weld
                    if weld ~= nil and entry.originalPart1 ~= nil then
                        pcall(function()
                            weld.Part1 = entry.originalPart1
                            entry.originalPart1.Anchored = false
                        end)
                    end
                end
                table.clear(self._gluedParts)
                table.clear(self._bindings)
            end

            -- ---- enemy target list + validity (Kicia t190, lines 92617-92664) ------------
            local function isEnemyPlayer(player)
                if player == nil or player == LPRB then
                    return false
                end
                local localTeamId = LPRB:GetAttribute('TeamID')
                local theirTeamId = player:GetAttribute('TeamID')
                if localTeamId ~= nil and theirTeamId ~= nil then
                    return localTeamId ~= theirTeamId
                end
                if LPRB.Team ~= nil and player.Team ~= nil then
                    return LPRB.Team ~= player.Team
                end
                return true
            end
            local function isTargetInvincible(entity)
                local data = entity and rawget(entity, 'Data')
                return data ~= nil and rawget(data, 'IsInvincible') == true
            end
            local function collectEnemies()
                local out = {}
                local controller = resolveFighterController()
                local objects = controller and rawget(controller, 'Objects') or nil
                if type(objects) ~= 'table' then
                    return out
                end
                for _, fighter in ipairs(objects) do
                    local ok, entry = pcall(function()
                        local player = rawget(fighter, 'Player')
                        local entity = rawget(fighter, 'Entity')
                        local model = entity and rawget(entity, 'Model') or nil
                        if not model then
                            return nil
                        end
                        if player ~= nil and not isEnemyPlayer(player) then
                            return nil
                        end
                        local hitboxHead = model:FindFirstChild('HitboxHead')
                        local hitboxBody = model:FindFirstChild('HitboxBody')
                        local rootPart = model:FindFirstChild('HumanoidRootPart') or hitboxBody
                        if not (hitboxHead and rootPart) then
                            return nil
                        end
                        local humanoid = model:FindFirstChildOfClass('Humanoid')
                        return {
                            fighter = fighter,
                            player = player,
                            entity = entity,
                            model = model,
                            hitboxHead = hitboxHead,
                            hitboxBody = hitboxBody,
                            rootPart = rootPart,
                            itemObserver = rawget(fighter, 'itemObserver') or rawget(fighter, 'ItemObserver'),
                            alive = humanoid == nil or humanoid.Health > 0,
                            invincible = isTargetInvincible(entity),
                            hacker = false,
                            equippedGunProjectile = false,
                        }
                    end)
                    if ok and entry then
                        out[#out + 1] = entry
                    end
                end
                return out
            end
            local function isValidTarget(entry)
                return entry ~= nil and entry.alive and not entry.invincible and not entry.deflecting
            end
            local function selectTarget()
                local enemies = collectEnemies()
                local prioritizeHackers = Setting.PrioritizeHackers()
                if prioritizeHackers then
                    for _, entry in ipairs(enemies) do
                        if entry.hacker and isValidTarget(entry) then
                            return entry
                        end
                    end
                end
                for _, entry in ipairs(enemies) do
                    if not (prioritizeHackers and entry.hacker) and isValidTarget(entry) then
                        return entry
                    end
                end
                return nil
            end
            local function hasTargets()
                for _, entry in ipairs(collectEnemies()) do
                    if isValidTarget(entry) then
                        return true
                    end
                end
                return false
            end

            -- ---- weapon selection (Kicia t34.getAction, lines 122419-122490) -------------
            local function itemCategory(slotIndex)
                if slotIndex == 1 then
                    return 'Primary'
                elseif slotIndex == 2 then
                    return 'Secondary'
                elseif slotIndex == 3 then
                    return 'Melee'
                end
                return nil
            end
            local function isCategoryEnabled(category)
                if category == 'Primary' then
                    return Setting.WeaponPrimary()
                elseif category == 'Secondary' then
                    return Setting.WeaponSecondary()
                elseif category == 'Melee' then
                    return Setting.WeaponMelee()
                end
                return false
            end
            local function getAction(fighter)
                if not fighter then
                    return nil
                end
                local items = rawget(fighter, 'Items')
                if type(items) ~= 'table' then
                    return nil
                end
                local onEmpty = Setting.OnEmpty()
                local priorityList = {} -- Kicia default Priority = {} (all equal; first-found wins)
                -- The slot is the Items-table key (1=Primary, 2=Secondary, 3=Melee - the game's
                -- own EquipPrimary input is EquipItem(1)). Kicia's registry passes the same key
                -- into its wrapper as .index; ClientItems carry no index field of their own.
                local bestAttack, bestAttackPri, bestAttackIndex = nil, math.huge, nil
                local bestSwap, bestSwapPri, bestSwapIndex = nil, math.huge, nil
                local anyEnabled = false
                for slotKey, item in next, items do
                    if type(item) == 'table' then
                        local category = itemCategory(slotKey)
                        if category ~= nil and isCategoryEnabled(category) then
                            anyEnabled = true
                            local priority = table.find(priorityList, category) or math.huge
                            if itemType(item) == 'Gun' and itemAmmo(item) == 0 then
                                if itemAmmoReserve(item) > 0 and priority < bestSwapPri then
                                    if onEmpty == 'Reload' then
                                        bestAttackPri = priority
                                        bestAttack = item
                                        bestAttackIndex = slotKey
                                    else
                                        bestSwap = item
                                        bestSwapPri = priority
                                        bestSwapIndex = slotKey
                                    end
                                end
                            elseif bestAttack == nil or priority < bestAttackPri then
                                bestAttackPri = priority
                                bestAttack = item
                                bestAttackIndex = slotKey
                            end
                        end
                    end
                end
                if not anyEnabled then
                    return nil
                end
                if bestAttack == nil then
                    if onEmpty == 'Swap' or bestSwap == nil then
                        return nil
                    end
                    if itemIsEquipped(bestSwap) then
                        return { type = 'Reload', item = bestSwap, itemType = itemType(bestSwap), index = bestSwapIndex }
                    end
                    return { type = 'Swap', item = bestSwap, itemType = itemType(bestSwap), index = bestSwapIndex }
                end
                local emptyGun = itemType(bestAttack) == 'Gun' and itemAmmo(bestAttack) == 0
                if not itemIsEquipped(bestAttack) then
                    return { type = 'Swap', item = bestAttack, itemType = itemType(bestAttack), index = bestAttackIndex }
                end
                if emptyGun then
                    return { type = 'Reload', item = bestAttack, itemType = itemType(bestAttack), index = bestAttackIndex }
                end
                return { type = 'Attack', item = bestAttack, itemType = itemType(bestAttack), index = bestAttackIndex }
            end

            -- ---- shoot lock (Kicia t93, lines 65724-65750) -------------------------------
            local ShootLock = {}
            ShootLock.__index = ShootLock
            function ShootLock.new()
                return setmetatable({ _lockedUntil = nil }, ShootLock)
            end
            function ShootLock:ShouldFire(canFire, lockDuration)
                local now = os.clock()
                local locked = self._lockedUntil ~= nil and now < self._lockedUntil
                if canFire then
                    self._lockedUntil = now + lockDuration
                end
                if not locked then
                    locked = canFire
                end
                return locked
            end
            function ShootLock:Reset()
                self._lockedUntil = nil
            end

            -- ---- spatial limit gate (Kicia t98, lines 142617-142668) ---------------------
            local SPATIAL_BOUND = 4194304
            local function outOfSpatialBound(pos)
                return SPATIAL_BOUND <= math.abs(pos.X) or SPATIAL_BOUND <= math.abs(pos.Y) or SPATIAL_BOUND <= math.abs(pos.Z)
            end
            local SpatialLimitGate = {}
            SpatialLimitGate.__index = SpatialLimitGate
            function SpatialLimitGate.new()
                return setmetatable({ _measurements = {} }, SpatialLimitGate)
            end
            function SpatialLimitGate:Tick(target)
                local key = target.fighter or target
                local m = self._measurements[key]
                if m == nil then
                    m = { expectedDuration = 1 }
                    self._measurements[key] = m
                end
                local now = os.clock()
                local entry = m.limitEntryTime
                local hasAmmo = target.equippedAmmoState ~= false
                if not outOfSpatialBound(target.rootPart.Position) then
                    if entry ~= nil then
                        if hasAmmo then
                            m.expectedDuration = now - entry
                        end
                        m.limitEntryTime = nil
                    end
                    return false
                end
                if entry == nil then
                    m.limitEntryTime = now
                    entry = now
                end
                if hasAmmo and (m.expectedDuration - Setting.Stability()) <= (now - entry) then
                    return false
                end
                return true
            end

            -- ---- defensive module (Kicia t156, lines 151628-151664) ----------------------
            local function localShieldStance(fighter)
                local items = fighter and rawget(fighter, 'Items') or nil
                if type(items) ~= 'table' then
                    return 'None'
                end
                for _, item in next, items do
                    if type(item) == 'table' and itemName(item) == 'Riot Shield' then
                        if itemIsEquipped(item) then
                            return 'Equipped'
                        end
                        return 'Unequipped'
                    end
                end
                return 'None'
            end
            local function getDefensiveCFrame(cframe, stance, targetRootPart)
                if stance == 'Equipped' then
                    return CFrame.new(cframe.Position, targetRootPart.Position)
                end
                if stance == 'Unequipped' then
                    return CFrame.new(cframe.Position, cframe.Position + (cframe.Position - targetRootPart.Position))
                end
                return cframe
            end
            local function getDefensiveViewAngles(stance)
                if stance == 'None' then
                    return nil
                end
                local pitch = (stance == 'Equipped') and 90 or -90
                return { kind = 'Normalized', pitch = pitch, yaw = rbRandom:NextNumber(0, 360) }
            end

            -- ---- evasion (Kicia f573 / f4230 / t167 / t103) ------------------------------
            local FAR_AXIS = 1073741824
            local function ringPoint(anchor, minR, maxR)
                local angle = rbRandom:NextNumber(0, 2 * math.pi)
                local radius = rbRandom:NextNumber(minR, maxR)
                return CFrame.new(anchor + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
                    * CFrame.fromOrientation(
                        rbRandom:NextNumber(0, 2 * math.pi),
                        rbRandom:NextNumber(0, 2 * math.pi),
                        rbRandom:NextNumber(0, 2 * math.pi)
                    )
            end
            local function scatterFar(pos, anchorFromCharacter, baseRadius, radiusFactor)
                local extra = baseRadius * radiusFactor
                local anchor = anchorFromCharacter and pos or Vector3.new(0, pos.Y, 0)
                local ring = ringPoint(anchor, baseRadius, baseRadius + extra)
                local ringPos = ring.Position
                local x, y, z = ringPos.X, ringPos.Y, ringPos.Z
                local pick = rbRandom:NextInteger(1, 3)
                if pick == 1 then
                    x = FAR_AXIS
                elseif pick == 2 then
                    y = FAR_AXIS
                else
                    z = FAR_AXIS
                end
                return ring - ringPos + Vector3.new(x, y, z)
            end
            local function randomEvade(clientCF)
                return scatterFar(clientCF.Position, Setting.RandomAnchorFromCharacter(), Setting.RandomBaseRadius(), Setting.RandomRadiusFactor())
            end
            local function translocateEvade(clientCF, hasTargetsNow)
                -- Kicia fallback (t103.compute): a far ring-scatter (v107(pos, 10000, 1e9)).
                if not hasTargetsNow then
                    return ringPoint(clientCF.Position, 10000, 1000000000)
                end
                local chosen = nil
                for _, part in ipairs(CollectionServiceRB:GetTagged('OutOfBoundsPart')) do
                    if part:GetAttribute('KillDelay') == 0 then
                        chosen = part
                        break
                    end
                end
                if chosen == nil then
                    return ringPoint(clientCF.Position, 10000, 1000000000)
                end
                return chosen.CFrame * CFrame.new(0, -chosen.Size.Y / 2 + Setting.TranslocateOffset(), 0)
            end
            local function depthOsc(range, freq)
                return range.Min + (range.Max - range.Min) * ((math.sin(os.clock() * (2 * math.pi * freq)) + 1) * 0.5)
            end
            local function surfaceCFrame(surface, up, forward)
                return CFrame.fromMatrix(
                    surface.surfacePosition - surface.up * 0.01 - surface.up * up + surface.forward * forward,
                    surface.right,
                    surface.up,
                    -surface.forward
                )
            end
            local PB_OVERLAP = OverlapParams.new()
            PB_OVERLAP.FilterType = Enum.RaycastFilterType.Exclude
            PB_OVERLAP.FilterDescendantsInstances = {}
            PB_OVERLAP.BruteForceAllSlow = true
            local PB_PROBE_SIZE = Vector3.new(5, 5, 5)
            local function isBoundaryPart(part)
                return part.Name == 'Barriers' or part:HasTag('OutOfBoundsPart') or part:HasTag('KillBrick')
            end
            local function hasBoundaryNear(pos)
                for _, part in ipairs(WorkspaceRB:GetPartBoundsInBox(CFrame.new(pos), PB_PROBE_SIZE, PB_OVERLAP)) do
                    if isBoundaryPart(part) then
                        return true
                    end
                end
                return false
            end
            -- Kicia's f6204 (surface descriptor from a part face) is erased; reconstructed as the
            -- part's top-face frame - the only shape consistent with surfaceCFrame's fields.
            local function describeSurface(part)
                local cf = part.CFrame
                return {
                    surfacePosition = (cf * CFrame.new(0, part.Size.Y / 2, 0)).Position,
                    up = cf.UpVector,
                    right = cf.RightVector,
                    forward = cf.LookVector,
                }
            end
            local ProjectileBreaker = {}
            ProjectileBreaker.__index = ProjectileBreaker
            function ProjectileBreaker.new()
                return setmetatable({
                    _nextPositionCooldown = -1,
                    _poolEnvironmentID = nil,
                    _pool = {},
                    _processedParts = {},
                    _lastBreakSurface = nil,
                }, ProjectileBreaker)
            end
            function ProjectileBreaker:BindEnvironment(envId)
                self._poolEnvironmentID = envId
                self._pool = {}
                self._processedParts = {}
            end
            function ProjectileBreaker:_HasProjectileThreat()
                for _, entry in ipairs(collectEnemies()) do
                    if entry.equippedGunProjectile then
                        return true
                    end
                end
                return false
            end
            function ProjectileBreaker:_ScanBatch(envId)
                local depthForwardMax = PB_DEPTH_FORWARD.Min + PB_DEPTH_FORWARD.Max
                local upMid = (PB_DEPTH_UP.Min + PB_DEPTH_UP.Max) * 0.5
                local forwardMid = depthForwardMax * 0.5
                local scanned = 0
                local function consider(part)
                    if not (part:IsA('BasePart') and not self._processedParts[part]) then
                        return
                    end
                    self._processedParts[part] = true
                    scanned = scanned + 1
                    local surface = describeSurface(part)
                    if hasBoundaryNear(surfaceCFrame(surface, upMid, forwardMid).Position) then
                        return
                    end
                    self._pool[#self._pool + 1] = surface
                end
                for _, tagged in ipairs(CollectionServiceRB:GetTagged('RaycastWhitelist' .. tostring(envId))) do
                    if not isBoundaryPart(tagged) then
                        consider(tagged)
                        if 64 <= scanned or 30 <= #self._pool then
                            return
                        end
                        for _, descendant in ipairs(tagged:GetDescendants()) do
                            if not isBoundaryPart(descendant) then
                                consider(descendant)
                                if 64 <= scanned or 30 <= #self._pool then
                                    return
                                end
                            end
                        end
                    end
                end
            end
            function ProjectileBreaker:_BreakLine()
                local envId = self._poolEnvironmentID
                if envId == nil then
                    return nil
                end
                if #self._pool < 30 then
                    self:_ScanBatch(envId)
                end
                if #self._pool < 30 then
                    return nil
                end
                self._nextPositionCooldown = os.clock() + Setting.RepositionInterval()
                return self._pool[rbRandom:NextInteger(1, #self._pool)]
            end
            function ProjectileBreaker:Compute(clientCF)
                if os.clock() < self._nextPositionCooldown then
                    local last = self._lastBreakSurface
                    if last ~= nil then
                        return surfaceCFrame(last, depthOsc(PB_DEPTH_UP, PB_DEPTH_UP_FREQ), depthOsc(PB_DEPTH_FORWARD, PB_DEPTH_FORWARD_FREQ))
                    end
                end
                if not self:_HasProjectileThreat() then
                    self._lastBreakSurface = nil
                    return scatterFar(clientCF.Position, PB_FALLBACK_ANCHOR_FROM_CHARACTER, PB_FALLBACK_BASE_RADIUS, PB_FALLBACK_RADIUS_FACTOR)
                end
                local breakLine = self:_BreakLine()
                if breakLine == nil then
                    return scatterFar(clientCF.Position, PB_FALLBACK_ANCHOR_FROM_CHARACTER, PB_FALLBACK_BASE_RADIUS, PB_FALLBACK_RADIUS_FACTOR)
                end
                self._lastBreakSurface = breakLine
                return surfaceCFrame(breakLine, depthOsc(PB_DEPTH_UP, PB_DEPTH_UP_FREQ), depthOsc(PB_DEPTH_FORWARD, PB_DEPTH_FORWARD_FREQ))
            end
            function ProjectileBreaker:ResetState()
                self._nextPositionCooldown = -1
                self._lastBreakSurface = nil
            end

            -- ---- firing strategies (Kicia t96 hitscan / t98 melee) -----------------------
            local function farMiss()
                return CFrame.new(
                    math.random(-1000000, 1000000),
                    math.random(5000, 10000),
                    math.random(-1000000, 1000000)
                )
            end
            local HitscanStrategy = {}
            HitscanStrategy.__index = HitscanStrategy
            function HitscanStrategy.new(partGlue)
                return setmetatable({ _partGlue = partGlue, _shootLock = ShootLock.new() }, HitscanStrategy)
            end
            function HitscanStrategy:Plan(dt, target, item, ourRootPart, canFire)
                local hitboxHead = target.hitboxHead
                local above = isAbove(target)
                local offset = above and OFFSET_ABOVE or OFFSET_BELOW
                local void = self._partGlue:Acquire(ourRootPart, hitboxHead)
                self._gluedOurPart = ourRootPart
                local cframe
                if above then
                    cframe = void + offset
                else
                    cframe = CFrame.new(void.Position + offset, hitboxHead.Position)
                end
                if not self._shootLock:ShouldFire(canFire, dt * Setting.ShootFrames()) then
                    return farMiss(), nil
                end
                local _, oy, oz = target.rootPart.CFrame:ToOrientation()
                local pitch = above and PITCH_ABOVE or PITCH_BELOW
                local aim1 = buildAim(above and AIM_ABOVE_ORIGIN or AIM_BELOW_ORIGIN, pitch, oy, oz)
                local aim2 = buildAim(above and AIM_ABOVE_END or AIM_BELOW_END, pitch, oy, oz)
                local objectId = itemObjectId(item)
                local isRaycast = itemIsRaycast(item)
                local function weaponAction()
                    fireGun(objectId, isRaycast, aim1, aim2, hitboxHead, AIM_EXTRA)
                end
                return cframe, weaponAction
            end
            function HitscanStrategy:ResetState()
                self._shootLock:Reset()
                local glued = self._gluedOurPart
                if glued ~= nil then
                    self._partGlue:Free(glued)
                    self._gluedOurPart = nil
                end
            end

            local BACKSTAB_WINDOW = 0.625
            local BACKSTAB_COOLDOWN = 1.25
            local MeleeStrategy = {}
            MeleeStrategy.__index = MeleeStrategy
            function MeleeStrategy.new(partGlue)
                return setmetatable({
                    _partGlue = partGlue,
                    _shootLock = ShootLock.new(),
                    _hitboxWindowUntil = -1,
                    _attackCooldown = -1,
                }, MeleeStrategy)
            end
            local function meleeViewAngles(px, oy)
                return { kind = 'Normalized', pitch = math.deg(px), yaw = math.deg(oy) }
            end
            function MeleeStrategy:_RecordBackstab()
                local now = os.clock()
                self._hitboxWindowUntil = now + BACKSTAB_WINDOW
                self._attackCooldown = now + BACKSTAB_COOLDOWN
            end
            function MeleeStrategy:Plan(dt, target, item, ourRootPart, canFire)
                local hitboxHead = target.hitboxHead
                local above = isAbove(target)
                local offset = above and OFFSET_ABOVE or OFFSET_BELOW
                local void = self._partGlue:Acquire(ourRootPart, hitboxHead)
                self._gluedOurPart = ourRootPart
                local cframe
                if above then
                    cframe = void + offset
                else
                    cframe = CFrame.new(void.Position + offset, hitboxHead.Position)
                end
                local px, oy, oz = target.rootPart.CFrame:ToOrientation()
                local pitch = above and PITCH_ABOVE or PITCH_BELOW
                local aim1 = buildAim(above and AIM_ABOVE_ORIGIN or AIM_BELOW_ORIGIN, pitch, oy, oz)
                local aim2 = buildAim(above and AIM_ABOVE_END or AIM_BELOW_END, pitch, oy, oz)
                local objectId = itemObjectId(item)
                local now = os.clock()
                if now < self._hitboxWindowUntil then
                    return cframe, meleeViewAngles(px, oy), function()
                        fireMeleeHeavy(objectId, aim1, aim2, hitboxHead, AIM_EXTRA)
                    end
                end
                if not self._shootLock:ShouldFire(canFire, dt * Setting.ShootFrames()) then
                    return farMiss(), nil, nil
                end
                if now < self._attackCooldown then
                    return farMiss(), nil, nil
                end
                if itemName(item) ~= 'Knife' then
                    return cframe, nil, function()
                        fireMeleeAttack(objectId, aim1, aim2, hitboxHead, AIM_EXTRA)
                    end
                end
                self:_RecordBackstab()
                return cframe, meleeViewAngles(px, oy), function()
                    fireMeleeHeavy(objectId, aim1, aim2, hitboxHead, AIM_EXTRA)
                end
            end
            function MeleeStrategy:ResetState()
                self._hitboxWindowUntil = -1
                self._attackCooldown = -1
                self._shootLock:Reset()
                local glued = self._gluedOurPart
                if glued ~= nil then
                    self._partGlue:Free(glued)
                    self._gluedOurPart = nil
                end
            end

            -- ---- FFlag environment toggles (Kicia SetEnabled, lines 63538-63571) ----------
            local ORIGINAL_FALLEN_PARTS_HEIGHT = nil
            local function applyEnabledFFlags(enabled)
                if enabled and ORIGINAL_FALLEN_PARTS_HEIGHT == nil then
                    ORIGINAL_FALLEN_PARTS_HEIGHT = WorkspaceRB.FallenPartsDestroyHeight
                end
                pcall(function()
                    WorkspaceRB.FallenPartsDestroyHeight = enabled and (0 / 0) or (ORIGINAL_FALLEN_PARTS_HEIGHT or -500)
                end)
                if rbSetFFlag then
                    pcall(rbSetFFlag, 'DFIntS2PhysicsSenderRate', enabled and '120' or '15')
                    pcall(rbSetFFlag, 'DFIntAssemblyHistoryBufferSize', enabled and '2147483648' or '15')
                    pcall(rbSetFFlag, 'DFIntAssemblyHistorySkipSize', enabled and '0' or '8')
                end
            end

            -- ---- controller (Kicia t1, lines 63573-63758) --------------------------------
            local Controller = {}
            Controller.__index = Controller
            function Controller.new()
                local partGlue = PartGlue.new()
                return setmetatable({
                    _enabled = false,
                    _partGlue = partGlue,
                    _hitscanStrategy = HitscanStrategy.new(partGlue),
                    _meleeStrategy = MeleeStrategy.new(partGlue),
                    _projectileBreaker = ProjectileBreaker.new(),
                    _spatialLimitGate = SpatialLimitGate.new(),
                    _stateHook = StateHook.new(),
                    _characterController = nil,
                    _boundRootPart = nil,
                    _lastTargetWorld = nil,
                    _lastDefensiveViewAngles = nil,
                }, Controller)
            end
            function Controller:SetEnabled(enabled)
                if self._enabled == enabled then
                    return
                end
                self._enabled = enabled
                applyEnabledFFlags(enabled)
                self:_Reset()
            end
            function Controller:_ApplyForcedCrouch(on)
                if on then
                    self._stateHook:SetForced('IsCrouching', true)
                else
                    self._stateHook:ClearForced('IsCrouching', false)
                end
            end
            function Controller:_EnsureCharacterController()
                local Char, HumanoidRootPart = GetChar(), GetRoot()
                if not HumanoidRootPart or HumanoidRootPart.Parent ~= Char then
                    if self._characterController then
                        self._characterController:Destroy()
                        self._characterController = nil
                        self._boundRootPart = nil
                    end
                    return nil
                end
                if self._characterController == nil or self._boundRootPart ~= HumanoidRootPart then
                    if self._characterController then
                        self._characterController:Destroy()
                    end
                    self._characterController = CharacterController.new(HumanoidRootPart)
                    self._boundRootPart = HumanoidRootPart
                end
                return self._characterController
            end
            function Controller:_EvadePlan(clientCF, mode)
                if mode == 'Off' then
                    return {}
                end
                if mode ~= 'ProjectileBreaker' then
                    return { cframe = randomEvade(clientCF) }
                end
                return { cframe = self._projectileBreaker:Compute(clientCF), shouldSkipDefense = true }
            end
            function Controller:_Plan(dt, action, target, ourRootPart, clientCF, mode)
                local canFire = true
                if target ~= nil then
                    canFire = not self._spatialLimitGate:Tick(target)
                end
                if action == nil then
                    return self:_EvadePlan(clientCF, mode)
                end
                if action.type == 'Swap' then
                    local plan = self:_EvadePlan(clientCF, mode)
                    local item = action.item
                    local index = action.index
                    plan.weaponAction = function() equipItem(item, index) end
                    return plan
                end
                if action.type == 'Reload' then
                    local plan = self:_EvadePlan(clientCF, mode)
                    local item = action.item
                    plan.weaponAction = function() reloadItem(item) end
                    return plan
                end
                if target == nil then
                    return self:_EvadePlan(clientCF, mode)
                end
                if action.itemType == 'Melee' then
                    local cframe, viewAngles, weaponAction = self._meleeStrategy:Plan(dt, target, action.item, ourRootPart, canFire)
                    return { cframe = cframe, viewAngles = viewAngles, weaponAction = weaponAction, shouldSkipDefense = true, shouldForceCrouch = true }
                end
                if action.itemType ~= 'Gun' then
                    return {}
                end
                if itemIsReloading(action.item) then
                    return self:_EvadePlan(clientCF, mode)
                end
                local cframe, weaponAction = self._hitscanStrategy:Plan(dt, target, action.item, ourRootPart, canFire)
                return { cframe = cframe, weaponAction = weaponAction, shouldForceCrouch = true, isAimPose = weaponAction ~= nil }
            end
            function Controller:_ApplyPlan(plan, target, characterController, fighter)
                local cframe = plan.cframe
                if cframe == nil or target == nil or plan.shouldSkipDefense then
                    characterController:SetServerCFrame(cframe)
                    characterController:SendViewAngles(20, plan.viewAngles)
                    return
                end
                local stance = localShieldStance(fighter)
                characterController:SetServerCFrame(getDefensiveCFrame(cframe, stance, target.rootPart))
                if plan.isAimPose or plan.shouldDefendInPlace then
                    self._lastDefensiveViewAngles = getDefensiveViewAngles(stance)
                end
                characterController:SendViewAngles(20, plan.viewAngles or self._lastDefensiveViewAngles)
            end
            function Controller:Update(dt)
                local fighter = resolveLocalFighter()
                local characterController = self:_EnsureCharacterController()
                if fighter == nil or characterController == nil or not self._enabled then
                    self:_Reset()
                    return
                end
                if RivalsRuntimeBridge.IsReadyToFight and not RivalsRuntimeBridge.IsReadyToFight() then
                    self:_Reset()
                    return
                end
                local ourRootPart = self._boundRootPart
                local clientCF = characterController:GetClientCFrame()
                local mode = Setting.EvasionMode()
                if mode == 'Translocate' then
                    self:_ApplyForcedCrouch(false)
                    characterController:SetServerCFrame(translocateEvade(clientCF, hasTargets()))
                    characterController:HeartbeatUpdate()
                    return
                end
                local target = selectTarget()
                local action = getAction(fighter)
                self._lastTargetWorld = target ~= nil and target.rootPart.Position or nil
                local plan = self:_Plan(dt, action, target, ourRootPart, clientCF, mode)
                self:_ApplyPlan(plan, target, characterController, fighter)
                self:_ApplyForcedCrouch(plan.shouldForceCrouch == true)
                if plan.weaponAction ~= nil then
                    plan.weaponAction()
                end
                characterController:HeartbeatUpdate()
            end
            function Controller:GetLastTargetWorld()
                return self._lastTargetWorld
            end
            function Controller:_Reset()
                self._lastTargetWorld = nil
                self._lastDefensiveViewAngles = nil
                self:_ApplyForcedCrouch(false)
                self._meleeStrategy:ResetState()
                self._hitscanStrategy:ResetState()
                self._projectileBreaker:ResetState()
                if self._characterController then
                    self._characterController:SetServerCFrame(nil)
                    self._characterController:SendViewAngles(20, nil)
                    self._characterController:HeartbeatUpdate()
                end
            end
            function Controller:Destroy()
                self:SetEnabled(false)
                self:_Reset()
                if self._characterController then
                    self._characterController:Destroy()
                    self._characterController = nil
                    self._boundRootPart = nil
                end
                self._partGlue:Destroy()
                applyEnabledFFlags(false)
            end

            -- ---- lifecycle / bridge ------------------------------------------------------
            local controllerInstance = nil
            local function ensureController()
                if controllerInstance == nil then
                    controllerInstance = Controller.new()
                end
                return controllerInstance
            end
            function KiciaRagebot.IsEnabled()
                if not togValue('P8S4T1', false) then
                    return false
                end
                -- Executor support: FighterController discovery walks the GC and the
                -- void redirect writes the hidden PhysicsRepRootPart property. Without
                -- either the bot cannot function, so decline (one-time notice via the
                -- gate) instead of running the loop's side effects for nothing.
                -- Checked after the toggle so the notice fires at enable, not at load;
                -- cached because this runs per-frame.
                if KiciaRagebot.CapsOk == nil then
                    KiciaRagebot.CapsOk = __kicia_hook_genv.KiciaHookCaps.gate('Ragebot', 'getgc', 'sethiddenproperty')
                end
                if not KiciaRagebot.CapsOk then
                    return false
                end
                -- Practice / shooting range: the ragebot must never act here (target dummies, no real
                -- match). Live-verified: the local fighter carries IsInShootingRange=true in
                -- the practice range and IsInDuel=true in real 1v1s. Returning false makes the controller
                -- settle to disabled (release part-glue, restore FFlags) via the normal Update path. The
                -- Seeded guard means we only gate once the duel state has actually been read.
                local localDuel = FighterDataCache and FighterDataCache.LocalDuel
                if localDuel and localDuel.Seeded and localDuel.IsInShootingRange == true then
                    return false
                end
                -- Enabled AND keybind-active (Kicia ObserveEnabledKeybind); Mode 'Always' -> always true.
                local keypicker = Options and Options.P8S4T1K
                if keypicker and type(keypicker.GetState) == 'function' then
                    return keypicker:GetState() == true
                end
                return true
            end
            function KiciaRagebot.Update(dt)
                local controller = ensureController()
                local enabled = KiciaRagebot.IsEnabled()
                if controller._enabled ~= enabled then
                    controller:SetEnabled(enabled)
                end
                controller:Update(dt or 0)
            end
            function KiciaRagebot.Reset()
                if controllerInstance then
                    controllerInstance:_Reset()
                end
            end
            function KiciaRagebot.Destroy()
                if controllerInstance then
                    controllerInstance:Destroy()
                    controllerInstance = nil
                end
            end
            RivalsRuntimeBridge.UpdateKiciaRagebot = KiciaRagebot.Update
            RivalsRuntimeBridge.ResetKiciaRagebot = KiciaRagebot.Reset
            RivalsRuntimeBridge.DestroyKiciaRagebot = KiciaRagebot.Destroy
        

            Bridge.Flickbot = {
                State = 'Idle',
                Trajectory = nil,
                TrajectoryIndex = 1,
                ElapsedMs = 0,
                TotalMs = 0,
                BakedEndDirection = Vector3.zAxis,
                Selected = nil,
                Timer = 0,
                WasHeld = false,
                Rng = Random.new(),
                OuTheta = 3.5,
                TremorFrequencyMin = 8,
                TremorFrequencyMax = 12,
                SampleDeltaMean = 7.8,
                GammaShape = 3.5,
            }

            function Bridge.ResetFlickbot()
                local flickbot = Bridge.Flickbot
                flickbot.State = 'Idle'
                flickbot.Trajectory = nil
                flickbot.TrajectoryIndex = 1
                flickbot.ElapsedMs = 0
                flickbot.TotalMs = 0
                flickbot.BakedEndDirection = Vector3.zAxis
                flickbot.Selected = nil
                flickbot.Timer = 0
                flickbot.WasHeld = false
            end

            function Bridge.FlickbotNormal(rng, mean, standardDeviation)
                local first = math.max(rng:NextNumber(), 1e-15)
                local second = rng:NextNumber()
                return mean + standardDeviation
                    * (math.sqrt(-2 * math.log(first)) * math.cos(2 * math.pi * second))
            end

            function Bridge.FlickbotGamma(rng, shape, scale)
                local factor = 1
                if shape < 1 then
                    factor = rng:NextNumber() ^ (1 / shape)
                    shape = shape + 1
                end
                local adjustedShape = shape - (1 / 3)
                local root = math.sqrt(9 * adjustedShape)
                while true do
                    local sample = Bridge.FlickbotNormal(rng, 0, 1)
                    local candidate = (1 + (sample / root)) ^ 3
                    if candidate > 0 then
                        local uniform = math.max(rng:NextNumber(), 1e-15)
                        if uniform < 1 - (0.0331 * sample ^ 4)
                            or math.log(uniform) < (0.5 * sample * sample)
                                + adjustedShape * (1 - candidate + math.log(candidate)) then
                            return adjustedShape * candidate * scale * factor
                        end
                    end
                end
            end

            function Bridge.FlickbotErf(value)
                local sign = value < 0 and -1 or 1
                local magnitude = math.abs(value)
                local factor = 1 / (1 + 0.3275911 * magnitude)
                local polynomial = 0.254829592 * factor
                    - 0.284496736 * factor ^ 2
                    + 1.421413741 * factor ^ 3
                    - 1.453152027 * factor ^ 4
                    + 1.061405429 * factor ^ 5
                return sign * (1 - polynomial * math.exp(-magnitude * magnitude))
            end

            function Bridge.FlickbotLognormalCdf(timeMs, startMs, mean, sigma)
                if timeMs <= startMs then
                    return 0
                end
                return 0.5 * (1 + Bridge.FlickbotErf(
                    (math.log(timeMs - startMs) - mean) / (sigma * math.sqrt(2))
                ))
            end

            function Bridge.FlickbotLognormalPdf(timeMs, startMs, mean, sigma)
                if timeMs <= startMs then
                    return 0
                end
                local elapsed = timeMs - startMs
                local standardized = (math.log(elapsed) - mean) / sigma
                return math.exp(-0.5 * standardized * standardized)
                    / (sigma * math.sqrt(2 * math.pi) * elapsed)
            end

            function Bridge.FlickbotBump(value)
                if value <= 0 or value >= 1 then
                    return 0
                end
                return value * value * (1 - value) ^ 3 / 0.03456
            end

            function Bridge.ApplyFlickbotProfile()
                local flickbot = Bridge.Flickbot
                local durationMs = math.max(Options.P2S1S10 and Options.P2S1S10.Value or 110, 20)
                flickbot.FittsA = durationMs / 4
                flickbot.FittsB = durationMs / 4
                flickbot.TargetWidth = 80
                flickbot.PeakTimeRatio = 0.32
                flickbot.PrimarySigmaMin = 0.2
                flickbot.PrimarySigmaMax = 0.26
                flickbot.UndershootMin = 0.97
                flickbot.UndershootMax = 1
                flickbot.OvershootProbability = 0.08
                flickbot.OvershootMin = 1.01
                flickbot.OvershootMax = 1.04
                flickbot.SecondCorrectionProbability = 0
                flickbot.CorrectionSigmaMin = 0.1
                flickbot.CorrectionSigmaMax = 0.14
                flickbot.CurvatureScale = math.clamp(
                    Options.P2S1S11 and Options.P2S1S11.Value or 12,
                    0,
                    50
                ) / 1000
                local humanness = math.clamp(
                    Options.P2S1S12 and Options.P2S1S12.Value or 30,
                    0,
                    100
                ) / 30
                flickbot.OuSigma = 0.5 * humanness
                flickbot.TremorAmplitudeMin = 0.05 * humanness
                flickbot.TremorAmplitudeMax = 0.18 * humanness
                flickbot.SignalDependentNoise = 0.02
            end

            function Bridge.GenerateFlickbotTrajectory(startX, startY, targetX, targetY)
                Bridge.ApplyFlickbotProfile()
                local flickbot = Bridge.Flickbot
                local rng = flickbot.Rng
                local function randomBetween(minimum, maximum)
                    return minimum + rng:NextNumber() * (maximum - minimum)
                end
                local function normal(mean, standardDeviation)
                    return Bridge.FlickbotNormal(rng, mean, standardDeviation)
                end

                local deltaX = targetX - startX
                local deltaY = targetY - startY
                local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
                if distance < 1 then
                    return {}
                end
                local directionX = deltaX / distance
                local directionY = deltaY / distance
                local directionAngle = math.atan2(deltaY, deltaX)
                local indexOfDifficulty = math.log(distance / flickbot.TargetWidth + 1) / math.log(2)
                local duration = math.max(
                    (flickbot.FittsA + flickbot.FittsB * indexOfDifficulty)
                        * math.exp(normal(0, 0.08)),
                    80
                )
                local distanceFactor
                if randomBetween(0, 1) < flickbot.OvershootProbability then
                    distanceFactor = randomBetween(flickbot.OvershootMin, flickbot.OvershootMax)
                else
                    distanceFactor = randomBetween(flickbot.UndershootMin, flickbot.UndershootMax)
                end
                local primaryDistance = distance * distanceFactor
                local primarySigma = randomBetween(flickbot.PrimarySigmaMin, flickbot.PrimarySigmaMax)
                local peakRatio = randomBetween(flickbot.PeakTimeRatio - 0.03, flickbot.PeakTimeRatio + 0.03)
                local primaryMean = math.log(duration * peakRatio) + primarySigma * primarySigma
                local corrections = {}
                local remaining = distance - primaryDistance
                if math.abs(remaining) > 0.5 then
                    local sign = remaining > 0 and 1 or -1
                    local correctionDistance = math.abs(remaining) * randomBetween(0.88, 1.02)
                    local correctionSigma = randomBetween(flickbot.CorrectionSigmaMin, flickbot.CorrectionSigmaMax)
                    local correctionPeak = randomBetween(0.12, 0.18)
                    corrections[#corrections + 1] = {
                        distance = correctionDistance,
                        startMs = duration * randomBetween(0.55, 0.68),
                        mean = math.log(duration * correctionPeak) + correctionSigma * correctionSigma,
                        sigma = correctionSigma,
                        directionX = directionX * sign,
                        directionY = directionY * sign,
                    }
                    local secondRemaining = remaining - correctionDistance * sign
                    if math.abs(secondRemaining) > 0.3
                        and randomBetween(0, 1) < flickbot.SecondCorrectionProbability then
                        local secondSign = secondRemaining > 0 and 1 or -1
                        local secondSigma = randomBetween(0.1, 0.16)
                        local secondPeak = randomBetween(0.08, 0.12)
                        corrections[#corrections + 1] = {
                            distance = math.abs(secondRemaining) * randomBetween(0.85, 1.05),
                            startMs = duration * randomBetween(0.78, 0.88),
                            mean = math.log(duration * secondPeak) + secondSigma * secondSigma,
                            sigma = secondSigma,
                            directionX = directionX * secondSign,
                            directionY = directionY * secondSign,
                        }
                    end
                end

                local angleScale = 0.5 + 0.8 * math.abs(math.sin(directionAngle))
                    - 0.15 * math.abs(math.cos(directionAngle))
                local curvature = distance * flickbot.CurvatureScale * angleScale * normal(0, 1)
                local tremorFrequency = randomBetween(flickbot.TremorFrequencyMin, flickbot.TremorFrequencyMax)
                local tremorAmplitude = randomBetween(flickbot.TremorAmplitudeMin, flickbot.TremorAmplitudeMax)
                local tremorPhaseX = randomBetween(0, 2 * math.pi)
                local tremorPhaseY = randomBetween(0, 2 * math.pi)
                local noiseX = 0
                local noiseY = 0
                local endTime = duration * 1.15
                local sampleTimes = {}
                local sampleTime = 0
                while sampleTime < endTime do
                    sampleTime = sampleTime + math.clamp(
                        Bridge.FlickbotGamma(
                            rng,
                            flickbot.GammaShape,
                            flickbot.SampleDeltaMean / flickbot.GammaShape
                        ),
                        2,
                        25
                    )
                    if sampleTime <= endTime + 15 then
                        sampleTimes[#sampleTimes + 1] = sampleTime
                    end
                end

                local trajectory = {}
                for index, timeMs in ipairs(sampleTimes) do
                    local deltaMs = index > 1 and (timeMs - sampleTimes[index - 1]) or flickbot.SampleDeltaMean
                    local deltaSeconds = deltaMs / 1000
                    local primaryProgress = Bridge.FlickbotLognormalCdf(
                        timeMs,
                        0,
                        primaryMean,
                        primarySigma
                    )
                    local x = startX + directionX * primaryDistance * primaryProgress
                        - directionY * curvature * Bridge.FlickbotBump(primaryProgress)
                    local y = startY + directionY * primaryDistance * primaryProgress
                        + directionX * curvature * Bridge.FlickbotBump(primaryProgress)
                    for _, correction in ipairs(corrections) do
                        local correctionProgress = Bridge.FlickbotLognormalCdf(
                            timeMs,
                            correction.startMs,
                            correction.mean,
                            correction.sigma
                        )
                        x = x + correction.directionX * correction.distance * correctionProgress
                        y = y + correction.directionY * correction.distance * correctionProgress
                    end

                    local velocity = primaryDistance * Bridge.FlickbotLognormalPdf(
                        timeMs,
                        0,
                        primaryMean,
                        primarySigma
                    )
                    for _, correction in ipairs(corrections) do
                        velocity = velocity + correction.distance * Bridge.FlickbotLognormalPdf(
                            timeMs,
                            correction.startMs,
                            correction.mean,
                            correction.sigma
                        )
                    end
                    noiseX = noiseX + (-flickbot.OuTheta * noiseX * deltaSeconds
                        + flickbot.OuSigma * math.sqrt(deltaSeconds) * normal(0, 1))
                    noiseY = noiseY + (-flickbot.OuTheta * noiseY * deltaSeconds
                        + flickbot.OuSigma * math.sqrt(deltaSeconds) * normal(0, 1))
                    local timeSeconds = timeMs / 1000
                    local tremorScale = 1 / (1 + velocity * 0.3)
                    local tremorX = math.sin(2 * math.pi * tremorFrequency * timeSeconds + tremorPhaseX)
                    local tremorY = math.sin(2 * math.pi * tremorFrequency * timeSeconds + tremorPhaseY)
                    trajectory[#trajectory + 1] = {
                        x = x + noiseX + tremorAmplitude * tremorScale * tremorX
                            + flickbot.SignalDependentNoise * velocity * normal(0, 1),
                        y = y + noiseY + tremorAmplitude * tremorScale * tremorY
                            + flickbot.SignalDependentNoise * velocity * normal(0, 1),
                        t = timeMs,
                    }
                end
                return trajectory
            end

            function Bridge.StartFlickbot()
                local flickbot = Bridge.Flickbot
                local camera = Workspace.CurrentCamera
                if Bridge.MovementRecorder.IsCameraClaimed()
                    or not camera or not Bridge.IsReadyToFight() then
                    return false
                end
                local targetInfo = SelectTarget()
                local targetPart = targetInfo and targetInfo.part or nil
                if not targetPart or not targetPart.Parent then
                    return false
                end
                local targetPoint = camera:WorldToViewportPoint(targetPart.Position)
                if targetPoint.Z <= 0 then
                    return false
                end
                local viewport = camera.ViewportSize
                local generated = Bridge.GenerateFlickbotTrajectory(
                    viewport.X * 0.5,
                    viewport.Y * 0.5,
                    targetPoint.X,
                    targetPoint.Y
                )
                if #generated < 2 then
                    return false
                end
                local trajectory = table.create(#generated)
                for index, point in ipairs(generated) do
                    trajectory[index] = {
                        direction = camera:ViewportPointToRay(point.x, point.y).Direction,
                        t = point.t,
                    }
                end
                flickbot.Trajectory = trajectory
                flickbot.TrajectoryIndex = 1
                flickbot.ElapsedMs = 0
                flickbot.TotalMs = trajectory[#trajectory].t
                flickbot.BakedEndDirection = trajectory[#trajectory].direction
                flickbot.Selected = targetInfo
                flickbot.State = 'Flicking'
                return true
            end

            function Bridge.SampleFlickbotTrajectory(deltaTime)
                local flickbot = Bridge.Flickbot
                local trajectory = flickbot.Trajectory
                flickbot.ElapsedMs = flickbot.ElapsedMs + deltaTime * 1000
                local index = flickbot.TrajectoryIndex
                while index < #trajectory and trajectory[index + 1].t <= flickbot.ElapsedMs do
                    index = index + 1
                end
                flickbot.TrajectoryIndex = index
                local current = trajectory[index]
                local following = trajectory[index + 1]
                if not following then
                    return trajectory[#trajectory].direction, true
                end
                local interval = following.t - current.t
                local alpha = interval > 0
                    and math.clamp((flickbot.ElapsedMs - current.t) / interval, 0, 1)
                    or 1
                return current.direction:Lerp(following.direction, alpha), false
            end

            function Bridge.FinishFlickbotToCooldown()
                local flickbot = Bridge.Flickbot
                flickbot.Selected = nil
                flickbot.Trajectory = nil
                local cooldownMs = math.clamp(Options.P2S1S9 and Options.P2S1S9.Value or 250, 0, 2000)
                if cooldownMs > 0 then
                    flickbot.State = 'Cooldown'
                    flickbot.Timer = cooldownMs / 1000
                else
                    flickbot.State = 'Idle'
                    flickbot.Timer = 0
                end
            end

            function Bridge.IsFlickbotCameraClaimed()
                local state = Bridge.Flickbot.State
                return state == 'Flicking' or state == 'PostShot'
            end

            function Bridge.UpdateFlickbot(deltaTime)
                local flickbot = Bridge.Flickbot
                if Bridge.MovementRecorder.IsCameraClaimed() then
                    if flickbot.State ~= 'Idle' or flickbot.WasHeld then
                        Bridge.ResetFlickbot()
                    end
                    return
                end
                local enabled = Toggles.P2S1T12 and Toggles.P2S1T12.Value == true
                local keypicker = Options.P2S1T12K
                local held = enabled and keypicker and type(keypicker.GetState) == 'function'
                    and keypicker:GetState() == true
                if not enabled then
                    if flickbot.State ~= 'Idle' or flickbot.WasHeld then
                        Bridge.ResetFlickbot()
                    end
                    return
                end
                if held and not flickbot.WasHeld and flickbot.State == 'Idle'
                    and not false then
                    Bridge.StartFlickbot()
                end
                flickbot.WasHeld = held

                local frameDelta = math.clamp(type(deltaTime) == 'number' and deltaTime or (1 / 60), 0, 0.1)
                if flickbot.State == 'Flicking' then
                    local selected = flickbot.Selected
                    local targetPart = selected and selected.part or nil
                    local camera = Workspace.CurrentCamera
                    if not targetPart or not targetPart.Parent or not camera or not flickbot.Trajectory then
                        Bridge.FinishFlickbotToCooldown()
                        return
                    end
                    local direction, finished = Bridge.SampleFlickbotTrajectory(frameDelta)
                    if flickbot.TotalMs > 0 then
                        local targetOffset = targetPart.Position - camera.CFrame.Position
                        if targetOffset.Magnitude > 0.001 then
                            local progress = math.clamp(flickbot.ElapsedMs / flickbot.TotalMs, 0, 1)
                            local corrected = direction
                                + (targetOffset.Unit - flickbot.BakedEndDirection) * progress
                            if corrected.Magnitude > 0.001 then
                                direction = corrected.Unit
                            end
                        end
                    end
                    local cameraController = CameraControllerAimbot
                    if cameraController and type(cameraController.SetRotation) == 'function' then
                        local pitch, yaw = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + direction):ToOrientation()
                        cameraController:SetRotation(Vector2.new(pitch, yaw))
                    end
                    if finished then
                        if Toggles.P2S1T13 and Toggles.P2S1T13.Value == true then
                            flickbot.State = 'PostShot'
                            flickbot.Timer = math.clamp(
                                Options.P2S1S8 and Options.P2S1S8.Value or 0,
                                0,
                                250
                            ) / 1000
                        else
                            Bridge.FinishFlickbotToCooldown()
                        end
                    end
                elseif flickbot.State == 'PostShot' then
                    -- No camera hold here: SetRotation state persists through PostShot.
                    flickbot.Timer = flickbot.Timer - frameDelta
                    if flickbot.Timer <= 0 then
                        triggerbot_Shoot()
                        Bridge.FinishFlickbotToCooldown()
                    end
                elseif flickbot.State == 'Cooldown' then
                    flickbot.Timer = flickbot.Timer - frameDelta
                    if flickbot.Timer <= 0 then
                        flickbot.State = 'Idle'
                        flickbot.Timer = 0
                    end
                end
            end

    local function UpdateRagebot(dt)
        if Bridge.UpdateKiciaRagebot then
            return Bridge.UpdateKiciaRagebot(dt or 0)
        end
    end

    local function ResetRagebot()
        if Bridge.ResetKiciaRagebot then
            return Bridge.ResetKiciaRagebot()
        end
        if Bridge.ResetFlickbot then
            Bridge.ResetFlickbot()
        end
    end

    local function DestroyRagebot()
        if Bridge.DestroyKiciaRagebot then
            pcall(Bridge.DestroyKiciaRagebot)
        end
        if Bridge.ResetFlickbot then
            pcall(Bridge.ResetFlickbot)
        end
    end

    return {
        Settings = Settings,
        UpdateRagebot = UpdateRagebot,
        UpdateFlickbot = Bridge.UpdateFlickbot,
        ResetRagebot = ResetRagebot,
        DestroyRagebot = DestroyRagebot,
        Bridge = Bridge
    }
end)()

local RageSettings = (RageCore and RageCore.Settings) or {}

local RageUpdateConnection = RunService.Heartbeat:Connect(function(dt)
    if not RageCore then return end
    if RageCore.UpdateRagebot then
        pcall(RageCore.UpdateRagebot, dt or 0)
    end
    if RageCore.UpdateFlickbot then
        pcall(RageCore.UpdateFlickbot, dt or 0)
    end
end)

local Legit = Library:Tab("Legit", 98159911363596)
local Rage = Library:Tab("Rage", 10455604811)
local Visuals = Library:Tab("Visuals", 10455603612)
local Misc = Library:Tab("Misc", 11888734334)

local AimGroup = Legit:Group("Aimbot")
AimGroup:Toggle({Name = "Enabled", Tooltip = "Legit aimbot", Callback = function(v) toggleAimbot(v) end})
AimGroup:Slider({Name = "FOV", Min = 5, Max = 180, Default = 30, Unit = "°", Callback = function(v) S.aimFov = v end})
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
SilentGroup:Slider({Name = "FOV", Min = 5, Max = 180, Default = 30, Unit = "°", Callback = function(v) S.silentFov = v end})
SilentGroup:Dropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart"}, Default = "Head", Callback = function(v) S.silentTargetPart = v end})
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
AntiAimGroup:Slider({Name = "Custom Angle", Min = 0, Max = 360, Default = 0, Unit = "°", Callback = function(v)
    _G.AntiAimSettings.customangle = v
end})
AntiAimGroup:Slider({Name = "Min Speed", Min = 1, Max = 100, Default = 10, Unit = "", Callback = function(v) _G.AntiAimSettings.minspeed = v end})
AntiAimGroup:Slider({Name = "Max Speed", Min = 1, Max = 100, Default = 20, Unit = "", Callback = function(v) _G.AntiAimSettings.maxspeed = v end})
AntiAimGroup:Slider({Name = "Min Angle", Min = 1, Max = 180, Default = 30, Unit = "°", Callback = function(v) _G.AntiAimSettings.minangle = v end})
AntiAimGroup:Slider({Name = "Max Angle", Min = 1, Max = 180, Default = 60, Unit = "°", Callback = function(v) _G.AntiAimSettings.maxangle = v end})
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
local RagebotGroup = RagePlus:Group("Ragebot")
RagebotGroup:Toggle({Name="Enabled",Default=false,Callback=function(v) if RageSettings then RageSettings.Enabled=v end end})
RagebotGroup:Keybind({Name="Keybind",Default=Enum.KeyCode.Unknown,Callback=function(v) if RageSettings then RageSettings.RagebotKeybind=v end end})
RagebotGroup:Slider({Name="Stability",Min=0,Max=1.5,Default=0.15,Callback=function(v) if RageSettings then RageSettings.Stability=v end end})
RagebotGroup:Slider({Name="Shoot Frames",Min=1,Max=5,Default=1,Callback=function(v) if RageSettings then RageSettings.ShootFrames=v end end})
RagebotGroup:Toggle({Name="Prioritize Hackers",Default=false,Callback=function(v) if RageSettings then RageSettings.PrioritizeHackers=v end end})
RagebotGroup:Toggle({Name="Use Primary",Default=true,Callback=function(v) if RageSettings then RageSettings.WeaponPrimary=v end end})
RagebotGroup:Toggle({Name="Use Secondary",Default=true,Callback=function(v) if RageSettings then RageSettings.WeaponSecondary=v end end})
RagebotGroup:Toggle({Name="Use Melee",Default=true,Callback=function(v) if RageSettings then RageSettings.WeaponMelee=v end end})
RagebotGroup:Dropdown({Name="On Empty",Options={"Swap","Reload","SwapOrReload"},Default="SwapOrReload",Callback=function(v) if RageSettings then RageSettings.OnEmpty=v end end})
RagebotGroup:Dropdown({Name="Evasion Mode",Options={"Random","Translocate","ProjectileBreaker"},Default="Random",Callback=function(v) if RageSettings then RageSettings.EvasionMode=v end end})
RagebotGroup:Slider({Name="Translocate Offset",Min=-5,Max=5,Default=-5,Callback=function(v) if RageSettings then RageSettings.TranslocateOffset=v end end})
RagebotGroup:Slider({Name="Random Base Radius",Min=5,Max=100000000,Default=100,Callback=function(v) if RageSettings then RageSettings.RandomBaseRadius=v end end})
RagebotGroup:Slider({Name="Random Range Factor",Min=0,Max=1,Default=0.5,Callback=function(v) if RageSettings then RageSettings.RandomRadiusFactor=v end end})
RagebotGroup:Toggle({Name="Character Origin",Default=false,Callback=function(v) if RageSettings then RageSettings.RandomAnchorFromCharacter=v end end})

local FlickbotGroup = RagePlus:Group("Flickbot")
FlickbotGroup:Toggle({Name="Enabled",Default=false,Callback=function(v) if RageSettings then RageSettings.FlickbotEnabled=v end end})
FlickbotGroup:Keybind({Name="Keybind",Default=Enum.KeyCode.Unknown,Callback=function(v) if RageSettings then RageSettings.FlickbotKeybind=v end end})
FlickbotGroup:Toggle({Name="Auto Shoot",Default=false,Callback=function(v) if RageSettings then RageSettings.FlickbotShot=v end end})
FlickbotGroup:Slider({Name="Shot Delay",Min=0,Max=250,Default=0,Unit="ms",Callback=function(v) if RageSettings then RageSettings.FlickbotShotDelay=v end end})
FlickbotGroup:Slider({Name="Cooldown",Min=0,Max=2000,Default=250,Unit="ms",Callback=function(v) if RageSettings then RageSettings.FlickbotCooldown=v end end})
FlickbotGroup:Slider({Name="Flick Duration",Min=30,Max=400,Default=110,Unit="ms",Callback=function(v) if RageSettings then RageSettings.FlickbotDuration=v end end})
FlickbotGroup:Slider({Name="Curvature",Min=0,Max=50,Default=12,Callback=function(v) if RageSettings then RageSettings.FlickbotCurvature=v end end})
FlickbotGroup:Slider({Name="Humanness",Min=0,Max=100,Default=30,Unit="%",Callback=function(v) if RageSettings then RageSettings.FlickbotHumanness=v end end})

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
        Library:Notify("配置已保存", "success")
    else
        Library:Notify("无法保存配置", "warning")
    end
end

local function loadConfig(silent)
    if not isfile or not readfile then
        if not silent then Library:Notify("无法读取配置", "warning") end
        return
    end
    if not isfile(configName) then
        if not silent then Library:Notify("配置文件不存在", "warning") end
        return
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(configName))
    end)
    if not success or not data then
        if not silent then Library:Notify("配置解析失败", "warning") end
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
    if not silent then Library:Notify("配置已加载", "success") end
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
    Image = "rbxassetid://3926305904",
    ImageColor3 = CFG.AccentColor,
    AutoButtonColor = false
}, {
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
    Create("UIStroke", {Color = CFG.AccentColor, Thickness = 2})
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
