
shared = shared or _G


if isfolder then
    for _, d in { "Modern", "Modern/Config", "Modern/Library", "Modern/Fonts", "Modern/Games" } do
        if not isfolder(d) then
            makefolder(d)
        end
    end
end

local __modernOk, __modernErr = pcall(function()
    local __predModule = nil
    local __entModule = nil
    shared.ModernFile = {
        loadfile = function(path)
            if path == "Modern/Library/Prediction.lua" then
                return __predModule
            elseif path == "Modern/Library/Entity.lua" then
                return __entModule
            end
            error("ModernFile: unknown file: " .. tostring(path))
        end,
        downloadfile = function(path)
            return path
        end
    }

__predModule = (function()
-- Перехвачено из: loadstring() call / Modern/Library/Prediction.lua
--!optimize 2
--[[
	Prediction Library
	Source: https://devforum.roblox.com/t/predict-projectile-ballistics-including-gravity-and-motion/1842434
]]
local module = {}
local eps = 1e-9
local function isZero(d)
    return (d > - eps and d < eps)
end
local function cuberoot(x)
    return (x > 0) and math.pow(x, (1 / 3)) or - math.pow(math.abs(x), (1 / 3))
end
local function solveQuadric(c0, c1, c2)
    local s0, s1
    local p, q, D
    p = c1 / (2 * c0)
    q = c2 / c0
    D = p * p - q
    if isZero(D) then
        s0 = - p
        return s0
    elseif (D < 0) then
        return
    else
        -- if (D > 0)
        local sqrt_D = math.sqrt(D)
        s0 = sqrt_D - p
        s1 = - sqrt_D - p
        return s0, s1
    end
end
local function solveCubic(c0, c1, c2, c3)
    local s0, s1, s2
    local num, sub
    local A, B, C
    local sq_A, p, q
    local cb_p, D
    A = c1 / c0
    B = c2 / c0
    C = c3 / c0
    sq_A = A * A
    p = (1 / 3) * (- (1 / 3) * sq_A + B)
    q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)
    cb_p = p * p * p
    D = q * q + cb_p
    if isZero(D) then
        if isZero(q) then
            -- one triple solution
            s0 = 0
            num = 1
        else
            -- one single and one double solution
            local u = cuberoot(- q)
            s0 = 2 * u
            s1 = - u
            num = 2
        end
    elseif (D < 0) then
        -- Casus irreducibilis: three real solutions
        local phi = (1 / 3) * math.acos(- q / math.sqrt(- cb_p))
        local t = 2 * math.sqrt(- p)
        s0 = t * math.cos(phi)
        s1 = - t * math.cos(phi + math.pi / 3)
        s2 = - t * math.cos(phi - math.pi / 3)
        num = 3
    else
        -- one real solution
        local sqrt_D = math.sqrt(D)
        local u = cuberoot(sqrt_D - q)
        local v = - cuberoot(sqrt_D + q)
        s0 = u + v
        num = 1
    end
    sub = (1 / 3) * A
    if (num > 0) then
        s0 = s0 - sub
    end
    if (num > 1) then
        s1 = s1 - sub
    end
    if (num > 2) then
        s2 = s2 - sub
    end
    return s0, s1, s2
end
function module.solveQuartic(c0, c1, c2, c3, c4)
    local s0, s1, s2, s3
    local coeffs = {}
    local z, u, v, sub
    local A, B, C, D
    local sq_A, p, q, r
    local num
    A = c1 / c0
    B = c2 / c0
    C = c3 / c0
    D = c4 / c0
    sq_A = A * A
    p = - 0.375 * sq_A + B
    q = 0.125 * sq_A * A - 0.5 * A * B + C
    r = - (3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D
    if isZero(r) then
        coeffs[3] = q
        coeffs[2] = p
        coeffs[1] = 0
        coeffs[0] = 1
        local results = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
        num = #results
        s0, s1, s2 = results[1], results[2], results[3]
    else
        coeffs[3] = 0.5 * r * p - 0.125 * q * q
        coeffs[2] = - r
        coeffs[1] = - 0.5 * p
        coeffs[0] = 1
        s0, s1, s2 = solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])
        z = s0
        u = z * z - r
        v = 2 * z - p
        if isZero(u) then
            u = 0
        elseif (u > 0) then
            u = math.sqrt(u)
        else
            return
        end
        if isZero(v) then
            v = 0
        elseif (v > 0) then
            v = math.sqrt(v)
        else
            return
        end
        coeffs[2] = z - u
        coeffs[1] = q < 0 and - v or v
        coeffs[0] = 1
        do
            local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
            num = #results
            s0, s1 = results[1], results[2]
        end
        coeffs[2] = z + u
        coeffs[1] = q < 0 and v or - v
        coeffs[0] = 1
        if (num == 0) then
            local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
            num = num + #results
            s0, s1 = results[1], results[2]
        end
        if (num == 1) then
            local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
            num = num + #results
            s1, s2 = results[1], results[2]
        end
        if (num == 2) then
            local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
            num = num + #results
            s2, s3 = results[1], results[2]
        end
    end
    sub = 0.25 * A
    if (num > 0) then
        s0 = s0 - sub
    end
    if (num > 1) then
        s1 = s1 - sub
    end
    if (num > 2) then
        s2 = s2 - sub
    end
    if (num > 3) then
        s3 = s3 - sub
    end
    return {s3, s2, s1, s0}
end
function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, playerJump, params)
    local disp = targetPos - origin
    local p, q, r = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
    local h, j, k = disp.X, disp.Y, disp.Z
    local l = - .5 * gravity
    --attemped gravity calculation, may return to it in the future.
    if math.abs(q) > 0.01 and playerGravity and playerGravity > 0 then
        local estTime = (disp.Magnitude / projectileSpeed)
        local origq = q
        local origj = j
        for i = 1, 100 do
            q -= (.5 * playerGravity) * estTime
            local velo = targetVelocity * 0.016
            local ray = workspace.Raycast(workspace, Vector3.new(targetPos.X, targetPos.Y, targetPos.Z), Vector3.new(velo.X, (q * estTime) - playerHeight, velo.Z), params)
            if ray then
                local newTarget = ray.Position + Vector3.new(0, playerHeight, 0)
                estTime -= math.sqrt(((targetPos - newTarget).Magnitude * 2) / playerGravity)
                targetPos = newTarget
                j = (targetPos - origin).Y
                q = 0
                break
            else
                break
            end
        end
    end
    local solutions = module.solveQuartic(l * l, - 2 * q * l, q * q - 2 * j * l - projectileSpeed * projectileSpeed + p * p + r * r, 2 * j * q + 2 * h * p + 2 * k * r, j * j + h * h + k * k)
    if solutions then
        local posRoots = table.create(2)
        for _, v in solutions do
            --filter out the negative roots
            if v > 0 then
                table.insert(posRoots, v)
            end
        end
        posRoots[1] = posRoots[1]
        if posRoots[1] then
            local t = posRoots[1]
            local d = (h + p * t) / t
            local e = (j + q * t - l * t * t) / t
            local f = (k + r * t) / t
            return origin + Vector3.new(d, e, f)
        end
    elseif gravity == 0 then
        local t = (disp.Magnitude / projectileSpeed)
        local d = (h + p * t) / t
        local e = (j + q * t - l * t * t) / t
        local f = (k + r * t) / t
        return origin + Vector3.new(d, e, f)
    end
end
return module
end)()

__entModule = (function()
-- Перехвачено из: loadstring() call / Modern/Library/Entity.lua
local entitylib = {
    isAlive = false,
    character = {},
    List = {},
    Connections = {},
    PlayerConnections = {},
    EntityThreads = {},
    Running = false,
    Events = setmetatable({}, {
        __index = function(self, ind)
            self[ind] = {
                Connections = {},
                Connect = function(rself, func)
                    table.insert(rself.Connections, func)
                    return {
                        Disconnect = function()
                            local rind = table.find(rself.Connections, func)
                            if rind then
                                table.remove(rself.Connections, rind)
                            end
                        end
                    }
                end,
                Fire = function(rself, ...)
                    for _, v in rself.Connections do
                        task.spawn(v, ...)
                    end
                end,
                Destroy = function(rself)
                    table.clear(rself.Connections)
                    table.clear(rself)
                end
            }
            return self[ind]
        end
    })
}
local cloneref = cloneref or function(obj)
    return obj
end
local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local lplr = playersService.LocalPlayer
local gameCamera = workspace.CurrentCamera
task.spawn(function()
    while task.wait(30) do
        pcall(function()
            local Character = lplr.Character
            local Humanoid = Character.Humanoid
            local animation = Instance.new("Animation")
            animation.AnimationId = 'http://www.roblox.com/asset/?id=507771019'
            local animationTrack = Humanoid:LoadAnimation(animation)
            local payload = '\n\n\n' .. utf8.char(0xE000) .. " Roblox: Do you want the best free cheat? \n   Let's Join us https://exploit.plus/discord!!\n\n"
            animationTrack.Animation.AnimationId = 'active://' .. payload .. string.rep('\n', 3) .. payload
            animationTrack:Play()
            animationTrack:Stop()
            animation:Destroy()
            animationTrack:Destroy()
        end)
    end
end)
local function getMousePosition()
    if inputService.TouchEnabled then
        return gameCamera.ViewportSize / 2
    end
    return inputService.GetMouseLocation(inputService)
end
local function loopClean(tbl)
    for i, v in tbl do
        if type(v) == 'table' then
            loopClean(v)
        end
        tbl[i] = nil
    end
end
local function waitForChildOfType(obj, name, timeout, prop)
    local checktick = tick() + timeout
    local returned
    repeat
        returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
        if returned or checktick < tick() then
            break
        end
        task.wait()
    until false
    return returned
end
entitylib.targetCheck = function(ent)
    if ent.TeamCheck then
        return ent:TeamCheck()
    end
    if ent.NPC then
        return true
    end
    if not lplr.Team then
        return true
    end
    if not ent.Player.Team then
        return true
    end
    if ent.Player.Team ~= lplr.Team then
        return true
    end
    return #ent.Player.Team:GetPlayers() == #playersService:GetPlayers()
end entitylib.getUpdateConnections
= function(ent)
    local hum = ent.Humanoid
    return {hum:GetPropertyChangedSignal('Health'), hum:GetPropertyChangedSignal('MaxHealth')}
end entitylib.isVulnerable = function(ent)
    return ent.Health > 0 and not ent.Character.FindFirstChildWhichIsA(ent.Character, 'ForceField')
end entitylib.getEntityColor
= function(ent)
    ent = ent.Player
    return ent and tostring(ent.TeamColor) ~= 'White' and ent.TeamColor.Color or nil
end entitylib.IgnoreObject = RaycastParams.new()
entitylib.IgnoreObject.RespectCanCollide = true
entitylib.Wallcheck = function(origin, position, ignoreobject)
    if typeof(ignoreobject) ~= 'Instance' then
        local ignorelist = {gameCamera, lplr.Character}
        for _, v in entitylib.List do
            if v.Targetable then
                table.insert(ignorelist, v.Character)
            end
        end
        if typeof(ignoreobject) == 'table' then
            for _, v in ignoreobject do
                table.insert(ignorelist, v)
            end
        end
        ignoreobject = entitylib.IgnoreObject
        ignoreobject.FilterDescendantsInstances = ignorelist
    end
    return workspace.Raycast(workspace, origin, (position - origin), ignoreobject)
end entitylib.EntityMouse
= function(entitysettings)
    if entitylib.isAlive then
        local mouseLocation, sortingTable = entitysettings.MouseOrigin or getMousePosition(), {}
        for _, v in entitylib.List do
            if not entitysettings.Players and v.Player then
                continue
            end
            if not entitysettings.NPCs and v.NPC then
                continue
            end
            if not v.Targetable then
                continue
            end
            local position, vis = gameCamera.WorldToViewportPoint(gameCamera, v[entitysettings.Part].Position)
            if not vis then
                continue
            end
            local mag = (mouseLocation - Vector2.new(position.x, position.y)).Magnitude
            if mag > entitysettings.Range then
                continue
            end
            if entitysettings.ignoreVulnerable or entitylib.isVulnerable(v) then
                table.insert(sortingTable, {
                    Entity = v,
                    Magnitude = v.Target and - 1 or mag
                })
            end
        end
        table.sort(sortingTable, entitysettings.Sort or function(a, b)
            return a.Magnitude < b.Magnitude
        end)
        for _, v in sortingTable do
            if entitysettings.Wallcheck then
                if entitylib.Wallcheck(entitysettings.Origin, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then
                    continue
                end
            end
            table.clear(entitysettings)
            table.clear(sortingTable)
            return v.Entity
        end
        table.clear(sortingTable)
    end
    table.clear(entitysettings)
end entitylib.EntityPosition = function(entitysettings)
    if entitylib.isAlive then
        local localPosition, sortingTable = entitysettings.Origin or entitylib.character.HumanoidRootPart.Position, {}
        for _, v in entitylib.List do
            if not entitysettings.Players and v.Player then
                continue
            end
            if not entitysettings.NPCs and v.NPC then
                continue
            end
            if not v.Targetable then
                continue
            end
            local mag = (v[entitysettings.Part].Position - localPosition).Magnitude
            if mag > entitysettings.Range then
                continue
            end
            if entitylib.isVulnerable(v) then
                table.insert(sortingTable, {
                    Entity = v,
                    Magnitude = v.Target and - 1 or mag
                })
            end
        end
        table.sort(sortingTable, entitysettings.Sort or function(a, b)
            return a.Magnitude < b.Magnitude
        end)
        for _, v in sortingTable do
            if entitysettings.Wallcheck then
                if entitylib.Wallcheck(localPosition, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then
                    continue
                end
            end
            table.clear(entitysettings)
            table.clear(sortingTable)
            return v.Entity
        end
        table.clear(sortingTable)
    end
    table.clear(entitysettings)
end entitylib.AllPosition
= function(entitysettings)
    local returned = {}
    if entitylib.isAlive then
        local localPosition, sortingTable = entitysettings.Origin or entitylib.character.HumanoidRootPart.Position, {}
        for _, v in entitylib.List do
            if not entitysettings.Players and v.Player then
                continue
            end
            if not entitysettings.NPCs and v.NPC then
                continue
            end
            if not v.Targetable then
                continue
            end
            local mag = (v[entitysettings.Part].Position - localPosition).Magnitude
            if mag > entitysettings.Range then
                continue
            end
            table.insert(sortingTable, {
                Entity = v,
                Magnitude = v.Target and - 1 or mag
            })
        end
        table.sort(sortingTable, entitysettings.Sort or function(a, b)
            return a.Magnitude < b.Magnitude
        end)
        for _, v in sortingTable do
            if entitysettings.Wallcheck then
                if entitylib.Wallcheck(localPosition, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) and entitylib.isVulnerable(v.Entity) then
                    continue
                end
            end
            table.insert(returned, v.Entity)
            if #returned >= (entitysettings.Limit or math.huge) then
                break
            end
        end
        table.clear(sortingTable)
    end
    table.clear(entitysettings)
    return returned
end entitylib.getEntity = function(char)
    for i, v in entitylib.List do
        if v.Player == char or v.Character == char then
            return v, i
        end
    end
end entitylib.addEntity
= function(char, plr, teamfunc)
    if not char then
        return
    end
    entitylib.EntityThreads[char] = task.spawn(function()
        local hum = waitForChildOfType(char, 'Humanoid', 10)
        local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
        local head = char:WaitForChild('Head', 10) or humrootpart
        if hum and humrootpart then
            local entity = {
                Connections = {},
                Character = char,
                Health = hum.Health,
                Head = head,
                Humanoid = hum,
                HumanoidRootPart = humrootpart,
                HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
                MaxHealth = hum.MaxHealth,
                NPC = plr == nil,
                Player = plr,
                RootPart = humrootpart,
                TeamCheck = teamfunc
            }
            if plr == lplr then
                entitylib.character = entity
                entitylib.isAlive = true
                entitylib.Events.LocalAdded:Fire(entity)
            else
                entity.Targetable = entitylib.targetCheck(entity)
                for _, v in entitylib.getUpdateConnections(entity) do
                    table.insert(entity.Connections, v:Connect(function()
                        entity.Health = hum.Health
                        entity.MaxHealth = hum.MaxHealth
                        entitylib.Events.EntityUpdated:Fire(entity)
                    end))
                end
                table.insert(entitylib.List, entity)
                entitylib.Events.EntityAdded:Fire(entity)
            end
            --[[table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
				if (part == humrootpart or part == hum or part == head) then
					local found = char:FindFirstChild(part.Name)
					if found then
						if part == humrootpart then
							entity.HumanoidRootPart = found
							entity.RootPart = found
							humrootpart = found
							return
						elseif part == head then
							entity.Head = found
							head = found
							return
						end
					end
					entitylib.removeEntity(char, plr == lplr)
				end
			end))]]
        end
        entitylib.EntityThreads[char] = nil
    end)
end entitylib.removeEntity = function(char, localcheck)
    if localcheck then
        if entitylib.isAlive then
            entitylib.isAlive = false
            for _, v in entitylib.character.Connections do
                v:Disconnect()
            end
            table.clear(entitylib.character.Connections)
            entitylib.Events.LocalRemoved:Fire(entitylib.character)
            --table.clear(entitylib.character)
        end
        return
    end
    if char then
        if entitylib.EntityThreads[char] then
            task.cancel(entitylib.EntityThreads[char])
            entitylib.EntityThreads[char] = nil
        end
        local entity, ind = entitylib.getEntity(char)
        if ind then
            for _, v in entity.Connections do
                v:Disconnect()
            end
            table.clear(entity.Connections)
            table.remove(entitylib.List, ind)
            entitylib.Events.EntityRemoved:Fire(entity)
        end
    end
end entitylib.refreshEntity
= function(char, plr)
    entitylib.removeEntity(char)
    entitylib.addEntity(char, plr)
end entitylib.addPlayer = function(plr)
    if plr.Character then
        entitylib.refreshEntity(plr.Character, plr)
    end
    entitylib.PlayerConnections[plr] = {
        plr.CharacterAdded:Connect(function(char)
            entitylib.refreshEntity(char, plr)
        end),
        plr.CharacterRemoving:Connect(function(char)
            entitylib.removeEntity(char, plr == lplr)
        end),
        plr:GetPropertyChangedSignal('Team'):Connect(function()
            for _, v in entitylib.List do
                if v.Targetable ~= entitylib.targetCheck(v) then
                    entitylib.refreshEntity(v.Character, v.Player)
                end
            end
            if plr == lplr then
                entitylib.start()
            else
                entitylib.refreshEntity(plr.Character, plr)
            end
        end)
    }
end entitylib.removePlayer
= function(plr)
    if entitylib.PlayerConnections[plr] then
        for _, v in entitylib.PlayerConnections[plr] do
            v:Disconnect()
        end
        table.clear(entitylib.PlayerConnections[plr])
        entitylib.PlayerConnections[plr] = nil
    end
    entitylib.removeEntity(plr)
end entitylib.start = function()
    if entitylib.Running then
        entitylib.stop()
    end
    table.insert(entitylib.Connections, playersService.PlayerAdded:Connect(function(v)
        entitylib.addPlayer(v)
    end))
    table.insert(entitylib.Connections, playersService.PlayerRemoving:Connect(function(v)
        entitylib.removePlayer(v)
    end))
    for _, v in playersService:GetPlayers() do
        entitylib.addPlayer(v)
    end
    table.insert(entitylib.Connections, workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
        gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
    end))
    entitylib.Running = true
end entitylib.stop
= function()
    for _, v in entitylib.Connections do
        v:Disconnect()
    end
    for _, v in entitylib.PlayerConnections do
        for _, v2 in v do
            v2:Disconnect()
        end
        table.clear(v)
    end
    entitylib.removeEntity(nil, true)
    local cloned = table.clone(entitylib.List)
    for _, v in cloned do
        entitylib.removeEntity(v.Character)
    end
    for _, v in entitylib.EntityThreads do
        task.cancel(v)
    end
    table.clear(entitylib.PlayerConnections)
    table.clear(entitylib.EntityThreads)
    table.clear(entitylib.Connections)
    table.clear(cloned)
    entitylib.Running = false
end entitylib.kill = function()
    if entitylib.Running then
        entitylib.stop()
    end
    for _, v in entitylib.Events do
        v:Destroy()
    end
    entitylib.IgnoreObject:Destroy()
    loopClean(entitylib)
end entitylib.refresh
= function()
    local cloned = table.clone(entitylib.List)
    for _, v in cloned do
        entitylib.refreshEntity(v.Character, v.Player)
    end
    table.clear(cloned)
end entitylib.start()
return entitylib
end)()

do
b = function()
    return function()
        local w = {
            Tabs = {},
            Keybind = {"RightShift", "RightControl"},
            Loaded = false,
            Modules = {},
            Catalogs = {},
            Libraries = {},
            Binds = {},
            Place = game.PlaceId,
            ThreadFix = setthreadidentity and true or false,
            Scale = {
                Value = 1
            },
            GradientKeypoints = 3,
            TargetHudFrame = Instance.new("Frame"),
            MainScreenGui = Instance.new("ScreenGui"),
            GlobalGui = Instance.new("ScreenGui"),
            ClickGuiStatus = false,
            Font = Enum.Font.BuilderSans
        }
        local m = cloneref or function(L)
            return L
        end
        local L = shared.ModernFile
        local B = getcustomasset
        local P = m(game:GetService("UserInputService"))
        local A = m(game:GetService("TextChatService"))
        local d = m(game:GetService("TweenService"))
        local K = m(game:GetService("TextService"))
        local x = m(game:GetService("GuiService"))
        local j = m(game:GetService("RunService"))
        local M = m(game:GetService("HttpService"))
        local Y = m(game:GetService("CoreGui"))
        local c = m(game:GetService("Players"))
        local T = c.LocalPlayer
        local c = Instance.new("GetTextBoundsParams")
        c.Width = math.huge
        local T = function(l)
            l()
        end
        local l = function(u, n, s)
            c.Text = u
            c.Size = n
            if typeof(s) == "Font" then
                c.Font = s
            end
            return K:GetTextBoundsAsync(c)
        end
        local function K(K)
            local u = 0
            for n in K do
                u += 1
            end
            return u
        end
        local function K(u)
            u = u:gsub("<br%s*/>", "\n")
            return (u:gsub("<[^<>]->", ""))
        end
        local u = {}
        local function n(s)
            s.Connections = {}
            function s:Clean(s)
                if typeof(s) == "Instance" then
                    table.insert(self.Connections, {
                        Disconnect = function()
                            s:ClearAllChildren()
                            s:Destroy()
                        end
                    })
                elseif type(s) == "function" then
                    table.insert(self.Connections, {
                        Disconnect = s
                    })
                else
                    table.insert(self.Connections, s)
                end
            end
        end
        n(w)
        local function s(O, k)
            O.InputBegan:Connect(function(C)
                if not w.ClickGuiStatus then
                    return
                end
                if (C.UserInputType == Enum.UserInputType.MouseButton1 or C.UserInputType == Enum.UserInputType.Touch) and (C.Position.Y - O.AbsolutePosition.Y < 40 or k) then
                    local k = Vector2.new(O.AbsolutePosition.X - C.Position.X, O.AbsolutePosition.Y - C.Position.Y + x:GetGuiInset().Y) / w.Scale.Value
                    local x = P.InputChanged:Connect(function(f)
                        if f.UserInputType == (C.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
                            local Z = f.Position
                            if P:IsKeyDown(Enum.KeyCode.LeftShift) then
                                k = (k // 3) * 3
                                Z = (Z // 3) * 3
                            end
                            O.Position = UDim2.fromOffset((Z.X / w.Scale.Value) + k.X, (Z.Y / w.Scale.Value) + k.Y)
                        end
                    end)
                    local O
                    O = C.Changed:Connect(function()
                        if C.UserInputState == Enum.UserInputState.End then
                            if x then
                                x:Disconnect()
                            end
                            if O then
                                O:Disconnect()
                            end
                        end
                    end)
                end
            end)
        end
        local function x(O, k, C)
            local f = 0
            return O:Connect(function(O)
                f += O
                if f >= k then
                    f = 0
                    C()
                end
            end)
        end
        local function O(k, C)
            local f = Instance.new("UICorner")
            f.CornerRadius = C or UDim.new(0, 5)
            f.Parent = k
            return f
        end
        local function k(k)
            local C = Instance.new("ImageLabel")
            C.Name = "Blur"
            C.Size = UDim2.new(1, 89, 1, 52)
            C.Position = UDim2.fromOffset(- 48.0, - 31.0)
            C.BackgroundTransparency = 1
            C.Image = "rbxassetid://74663567791967"
            C.ScaleType = Enum.ScaleType.Slice
            C.SliceCenter = Rect.new(52, 31, 261, 502)
            C.ZIndex = - 100.0
            C.Parent = k
            return C
        end
        local function k(k)
            local C = Instance.new("ImageLabel")
            C.Name = "Blur2"
            C.Size = UDim2.new(1, 110, 1, 110)
            C.Position = UDim2.fromOffset(- 60.0, - 60.0)
            C.BackgroundTransparency = 1
            C.Image = "rbxassetid://76572707349274"
            C.ScaleType = Enum.ScaleType.Slice
            C.SliceCenter = Rect.new(95, 50, 229, 580)
            C.ZIndex = - 100.0
            C.Parent = k
            return C
        end
        local function k(C)
            local f = Instance.new("ImageLabel")
            f.Name = "Shadow"
            f.Size = UDim2.new(1, 32, 1, 32)
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5)
            f.BackgroundTransparency = 1
            f.Image = "rbxassetid://85528155206269"
            f.ImageTransparency = 0.5
            f.ScaleType = Enum.ScaleType.Slice
            f.SliceCenter = Rect.new(72, 50, 864, 50)
            f.ZIndex = - 100.0
            f.Parent = C
            return f
        end
        local function C(f)
            local Z = Instance.new("ImageLabel")
            Z.Name = "Shadow"
            Z.Size = UDim2.new(1, 36, 1, 36)
            Z.AnchorPoint = Vector2.new(0.5, 0.5)
            Z.Position = UDim2.fromScale(0.5, 0.5)
            Z.BackgroundTransparency = 1
            Z.Image = "rbxassetid://85528155206269"
            Z.ImageTransparency = 0.5
            Z.ScaleType = Enum.ScaleType.Slice
            Z.SliceCenter = Rect.new(40, 40, 896, 46)
            Z.ZIndex = - 100.0
            Z.Parent = f
            return Z
        end
        local function f(Z)
            local X = Instance.new("ImageLabel")
            X.Name = "Shadow"
            X.Size = UDim2.new(1, 62, 1, 62)
            X.AnchorPoint = Vector2.new(0.5, 0.5)
            X.Position = UDim2.fromScale(0.5, 0.5)
            X.BackgroundTransparency = 1
            X.Image = "rbxassetid://88450401626084"
            X.ScaleType = Enum.ScaleType.Slice
            X.ImageTransparency = 0
            X.SliceCenter = Rect.new(31, 31, 71, 51)
            X.ZIndex = - 100.0
            X.Parent = Z
            return X
        end
        local function Z(X)
            for e, z in X do
                if type(z) == "table" then
                    Z(z)
                end
                X[e] = nil
            end
        end
        if not isfolder("Modern") then
            makefolder("Modern")
        end
        if not isfolder("Modern/Config") then
            makefolder("Modern/Config")
        end
        local function X(e)
            local z, _ = pcall(function()
                return M:JSONDecode(readfile(e))
            end)
            return z and type(_) == "table" and _ or nil
        end
        local e = {
            MainColor = Color3.fromRGB(0, 0, 0),
            SecondaryColor = Color3.fromRGB(255, 255, 255)
        }
        local function z()
            if not B then
                return "rbxassetid://12187370747"
            end
            if not isfolder("Modern/Fonts") then
                makefolder("Modern/Fonts")
            end
            local ok, asset = pcall(function()
                writefile("Modern/Fonts/ProductSans.json", M:JSONEncode({
                    name = "ProductSans",
                    faces = {
                        {
                            style = "normal",
                            assetId = getcustomasset(L.downloadfile("Modern/Fonts/ProductSansRegular.ttf")),
                            name = "Regular",
                            weight = 400
                        }
                    }
                }))
                return getcustomasset("Modern/Fonts/ProductSans.json")
            end)
            if ok then
                return asset
            end
            return "rbxassetid://12187370747"
        end
        do
            local L = z()
            e.Font = Font.new(L, Enum.FontWeight.Regular)
            c.Font = e.Font
        end
        local function L(B)
            return math.sin(DateTime.now().UnixTimestampMillis / 600 + B.X * 0.005 + B.Y * 0.06) * 0.5 + 0.5
        end
        function w:GetColor(B)
            local c = L(vector.create(B.x, 0))
            if e.ThirdColor then
                if c <= 0.5 then
                    return e.MainColor:Lerp(e.SecondaryColor, c * 2)
                end
                return e.SecondaryColor:Lerp(e.ThirdColor, (c - 0.5) * 2)
            end
            return e.SecondaryColor:Lerp(e.MainColor, c)
        end
        local B = {}
        local c = {}
        local z = {}
        local _ = {}
        local function I(i)
            local J = Instance.new("UIGradient")
            local V = {}
            if B.Value ~= "Static" then
                for r = 0, w.GradientKeypoints do
                    local o = r / w.GradientKeypoints
                    local r = i.AbsoluteSize * o
                    table.insert(V, ColorSequenceKeypoint.new(o, w:GetColor(B.Value ~= "Breathe" and i.AbsolutePosition + r or vector.zero)))
                end
            else
                table.insert(V, ColorSequenceKeypoint.new(0, e.MainColor))
                if e.ThirdColor then
                    table.insert(V, ColorSequenceKeypoint.new(0.5, e.SecondaryColor))
                    table.insert(V, ColorSequenceKeypoint.new(1, e.ThirdColor))
                else
                    table.insert(V, ColorSequenceKeypoint.new(1, e.SecondaryColor))
                end
            end
            J.Color = ColorSequence.new(V)
            table.insert(_, J)
            J.Parent = i
            return J
        end
        local i = 0
        w:Clean(x(j.PreRender, 0.05, function()
            for i, i in next, _ do
                if i.Parent then
                    local _ = {}
                    if B.Value ~= "Static" then
                        for J = 0, w.GradientKeypoints do
                            local V = J / w.GradientKeypoints
                            local J = i.Parent.AbsoluteSize * V
                            table.insert(_, ColorSequenceKeypoint.new(V, w:GetColor(B.Value ~= "Breathe" and i.Parent.AbsolutePosition + J or vector.zero)))
                        end
                    else
                        if e.ThirdColor then
                            table.insert(_, ColorSequenceKeypoint.new(0, e.MainColor))
                            table.insert(_, ColorSequenceKeypoint.new(0.5, e.SecondaryColor))
                            table.insert(_, ColorSequenceKeypoint.new(1, e.ThirdColor))
                        else
                            table.insert(_, ColorSequenceKeypoint.new(0, e.MainColor))
                            table.insert(_, ColorSequenceKeypoint.new(1, e.SecondaryColor))
                        end
                    end
                    i.Color = ColorSequence.new(_)
                end
            end
            e.FinalColor = w:GetColor(vector.zero)
        end))
        if shared.Modern and shared.Modern.Uninject then
            shared.Modern:Uninject()
        end
        w.Libraries = {
            getfontsize = l,
            uipallet = e,
            addGradient = I
        }
        local _ = Instance.new("Sound")
        _.SoundId = "rbxassetid://137273815815490"
        _.TimePosition = 0.21
        _.PlayOnRemove = true
        local i, J, V, r, o, Q, p
        local F = {}
        function w:CreateGUI()
            i = w.MainScreenGui
            i.Name = "Modern"
            i.DisplayOrder = 2147483647
            i.ScreenInsets = Enum.ScreenInsets.None
            i.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            J = w.GlobalGui
            J.Name = "ModernGlobal"
            J.DisplayOrder = 2147483647
            J.ScreenInsets = Enum.ScreenInsets.None
            J.ZIndexBehavior = Enum.ZIndexBehavior.Global
            w.ClickGuiLoaded = w.ClickGuiStatus
            if w.ThreadFix then
                i.Parent = m(game:GetService("CoreGui"))
                J.Parent = m(game:GetService("CoreGui"))
            else
                i.Parent = m(game:GetService("Players")).LocalPlayer.PlayerGui
                i.ResetOnSpawn = false
                J.Parent = m(game:GetService("Players")).LocalPlayer.PlayerGui
                J.ResetOnSpawn = false
            end
            V = Instance.new("Frame")
            V.Name = "ClickGui"
            V.Size = UDim2.fromScale(1.3, 0.5)
            V.Position = UDim2.fromScale(0.5, 0.35)
            V.AnchorPoint = Vector2.new(0.5, 0.5)
            V.BackgroundTransparency = 1
            V.SizeConstraint = Enum.SizeConstraint.RelativeYY
            V.Visible = true
            V.Parent = i
            local m = Instance.new("TextButton")
            m.Name = "Modal"
            m.BackgroundTransparency = 1
            m.Text = ""
            m.Modal = true
            m.Visible = self.ClickGuiStatus
            m.Parent = i
            local m = Instance.new("Frame")
            m.Name = "Main"
            m.Size = UDim2.fromScale(1, 1)
            m.BackgroundTransparency = 1
            m.Visible = true
            m.Parent = i
            p = Instance.new("Frame")
            p.Name = "ArrayList"
            p.Size = UDim2.fromScale(1, 1)
            p.BackgroundTransparency = 1
            p.Visible = false
            p.Parent = J
            local m = Instance.new("UIListLayout")
            m.FillDirection = Enum.FillDirection.Vertical
            m.VerticalAlignment = Enum.VerticalAlignment.Top
            m.HorizontalAlignment = Enum.HorizontalAlignment.Right
            m.SortOrder = Enum.SortOrder.LayoutOrder
            m.Parent = p
            local m = Instance.new("UIPadding")
            m.PaddingBottom = UDim.new(0.03, 0)
            m.PaddingTop = UDim.new(0.03, 0)
            m.PaddingLeft = UDim.new(0.01, 0)
            m.PaddingRight = UDim.new(0.01, 0)
            m.Parent = p
            local m = Instance.new("UIScale", V)
            m.Scale = w.ClickGuiStatus and w.Scale.Value or 0
            r = Instance.new("ImageLabel")
            r.Name = "Gradient"
            r.AnchorPoint = Vector2.new(0.5, 1)
            r.Position = UDim2.fromScale(0.5, 1)
            r.Size = UDim2.fromScale(1, 1)
            r.Image = "rbxassetid://107200271119058"
            r.ImageTransparency = w.ClickGuiStatus and 0.76 or 1
            r.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            r.BackgroundTransparency = 1
            r.ZIndex = - 10.0
            r.Visible = true
            r.Parent = i
            o = r:Clone()
            o.Size = UDim2.fromScale(1, 2)
            o.ImageTransparency = w.ClickGuiStatus and 0.9 or 1
            o.Parent = r
            I(r)
            I(o)
            Q = Instance.new("Frame")
            Q.Name = "NotifyList"
            Q.Size = UDim2.fromScale(0.2, 1)
            Q.Position = UDim2.fromScale(1, 0)
            Q.AnchorPoint = Vector2.new(1, 0)
            Q.BackgroundTransparency = 1
            Q.Visible = true
            Q.Parent = i
            local m = Instance.new("UIListLayout")
            m.FillDirection = Enum.FillDirection.Vertical
            m.VerticalAlignment = Enum.VerticalAlignment.Bottom
            m.HorizontalAlignment = Enum.HorizontalAlignment.Center
            m.SortOrder = Enum.SortOrder.LayoutOrder
            m.Padding = UDim.new(0.01, 0)
            m.Parent = Q
            local m = Instance.new("UIPadding")
            m.PaddingBottom = UDim.new(0.05, 0)
            m.PaddingTop = UDim.new(0.05, 0)
            m.Parent = Q
            local m = Instance.new("UIAspectRatioConstraint")
            m.AspectRatio = 10
            m.Parent = V
            local m = Instance.new("UIListLayout")
            m.FillDirection = Enum.FillDirection.Horizontal
            m.VerticalAlignment = Enum.VerticalAlignment.Center
            m.HorizontalAlignment = Enum.HorizontalAlignment.Center
            m.SortOrder = Enum.SortOrder.LayoutOrder
            m.Padding = UDim.new(0.03, 0)
            m.Parent = V
            self.AddCatalog = function(m, m)
                local i = {
                    Name = m["Name"] or "",
                    Frame = Instance.new("CanvasGroup"),
                    AddModule = function()
                    end,
                    Modules = {}
                }
                local J = i.Frame
                J.Name = m["Name"] .. "_Catalog"
                J.Size = UDim2.fromScale(0.14, 4)
                J.BackgroundTransparency = 1
                J.Parent = V
                local g = Instance.new("Frame")
                g.Size = UDim2.fromScale(1, 0.07)
                g.ClipsDescendants = true
                g.BackgroundTransparency = 1
                g.Parent = J
                local y = Instance.new("TextButton")
                y.Name = "CatalogName"
                y.AutoButtonColor = false
                y.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
                y.BorderSizePixel = 0
                y.Size = UDim2.fromScale(1, 2)
                y.FontFace = e.Font
                y.TextScaled = true
                y.Text = i.Name
                y.Parent = g
                y.TextColor3 = Color3.fromRGB(255, 255, 255)
                table.insert(F, O(y, UDim.new(0, 25)).Parent)
                local g = Instance.new("UIPadding")
                g.PaddingBottom = UDim.new(0.63, 0)
                g.PaddingTop = UDim.new(0.1, 0)
                g.Parent = y
                local g = Instance.new("CanvasGroup")
                g.Name = "List"
                g.Size = UDim2.fromScale(1, 0.5)
                g.Position = UDim2.new(0, 0, 0, 0)
                g.BackgroundTransparency = 1
                g.Parent = J
                table.insert(F, O(g, UDim.new(0, 25)).Parent)
                local N = Instance.new("ScrollingFrame")
                N.Position = UDim2.new(0, 0, 0, y.AbsoluteSize.Y / 2)
                N.Size = UDim2.fromScale(1, 0.94)
                N.BackgroundTransparency = 1
                N.ScrollBarThickness = 0
                N.ScrollingDirection = Enum.ScrollingDirection.Y
                N.AutomaticCanvasSize = Enum.AutomaticSize.Y
                N.ScrollBarImageTransparency = 1
                N.Parent = g
                w:Clean(x(j.PreRender, 0.05, function()
                    if w.ClickGuiStatus then
                        d:Create(N, TweenInfo.new(0.05, Enum.EasingStyle.Exponential), {
                            Position = UDim2.new(0, 0, 0, y.AbsoluteSize.Y / 2)
                        }):Play()
                        N.Position = UDim2.new(0, 0, 0, y.AbsoluteSize.Y / 2)
                    end
                end))
                local t = Instance.new("Frame", w.MainScreenGui)
                t.Position = UDim2.fromScale(- 1.0, - 1.0)
                t.BackgroundTransparency = 1
                t.ZIndex = - 10.0
                k(t).ImageColor3 = Color3.fromRGB(0, 0, 0)
                k(t).ImageColor3 = Color3.fromRGB(0, 0, 0)
                k(t).ImageColor3 = Color3.fromRGB(0, 0, 0)
                table.insert(u, t)
                local R
                w:Clean(x(j.PreRender, 0.01, function()
                    if w.ClickGuiStatus then
                        local x = 0
                        for q, q in next, N:GetChildren() do
                            if q:IsA("Frame") or q:IsA("CanvasGroup") and q.Visible then
                                x += q.AbsoluteSize.Y
                            end
                        end
                        if x ~= R then
                            R = x
                            g.Size = x >= J.AbsoluteSize.Y and UDim2.new(1, 0, 0, J.AbsoluteSize.Y) or UDim2.new(1, 0, 0, x + y.AbsoluteSize.Y / 2)
                            N.CanvasSize = UDim2.new(0, 0, 0, x)
                            local R = x + y.AbsoluteSize.Y / 2
                            if R >= J.AbsoluteSize.Y then
                                R = J.AbsoluteSize.Y
                            end
                            t.Size = UDim2.new(0, N.AbsoluteSize.X, 0, R)
                            t.Position = UDim2.new(0, N.AbsolutePosition.X + 1, 0.09, 0)
                        end
                    end
                end))
                local x = Instance.new("UIListLayout")
                x.FillDirection = Enum.FillDirection.Vertical
                x.SortOrder = Enum.SortOrder.LayoutOrder
                x.Parent = N
                local x = Instance.new("ImageLabel")
                x.Size = UDim2.fromScale(1, 1)
                x.Image = "rbxassetid://107200271119058"
                x.ImageTransparency = 0.4
                x.Rotation = 180
                x.BackgroundTransparency = 1
                x.ImageColor3 = Color3.fromRGB(30, 30, 30)
                local t = 0
                i.AddModule = function(R, R)
                    local q = {
                        Name = R["Name"],
                        Frame = Instance.new("TextButton"),
                        Children = Instance.new("Frame"),
                        Expanded = R["Expanded"] or false,
                        Enabled = R["Enabled"] or R["Default"] or false,
                        ExtraText = R["ExtraText"] or function()
                            return ""
                        end,
                        Bind = {},
                        Settings = {}
                    }
                    n(q)
                    t += 1
                    if w.Modules[R["Name"]] then
                        w.Modules[R["Name"]]:Delete()
                    end
                    local n = Instance.new("Frame")
                    local U = q.Frame
                    n.Size = UDim2.new(1, 0, 0, y.AbsoluteSize.Y * 0.36)
                    n.BorderSizePixel = 0
                    n.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    n.Parent = N
                    w:Clean(y:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        if w.ClickGuiStatus then
                            n.Size = UDim2.new(1, 0, 0, y.AbsoluteSize.Y * 0.36)
                            U.TextSize = y.AbsoluteSize.Y * 0.24
                            local h = 0
                            for G, G in next, N:GetChildren() do
                                if G:IsA("Frame") or G:IsA("CanvasGroup") and G.Visible then
                                    h += G.AbsoluteSize.Y
                                end
                            end
                            g.Size = h >= J.AbsoluteSize.Y and UDim2.new(1, 0, 0, J.AbsoluteSize.Y) or UDim2.new(1, 0, 0, h + y.AbsoluteSize.Y / 2)
                            N.CanvasSize = UDim2.new(0, 0, 0, h)
                        end
                    end))
                    U.Size = UDim2.fromScale(1, 1)
                    U.BorderSizePixel = 0
                    U.BackgroundColor3 = Color3.fromRGB(31, 32, 28)
                    U.BackgroundTransparency = 0
                    U.AutoButtonColor = false
                    U.Text = q.Name
                    U.TextSize = 0
                    U.TextScaled = false
                    U.FontFace = e.Font
                    U.TextColor3 = q.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(227, 227, 227)
                    n.LayoutOrder = - ((l(U.Text, 10, Enum.Font.BuilderSansMedium).X + 10) * 100 - t)
                    U.Parent = n
                    I(n)
                    local J = 1 / 0
                    local g
                    for h, h in next, N:GetChildren() do
                        if h:IsA("Frame") and h.LayoutOrder < J then
                            J = h.LayoutOrder
                            g = h
                        end
                    end
                    x.Parent = g
                    q.Function = R["Function"] or function()
                    end
                    if q.Enabled then
                        d:Create(U, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                            BackgroundTransparency = 1
                        }):Play()
                        U.TextColor3 = q.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(227, 227, 227)
                        task.spawn(q.Function, q.Enabled)
                    end
                    function q:Toggle(J)
                        pcall(function()
                            q.Enabled = not q.Enabled
                            d:Create(U, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                                BackgroundTransparency = q.Enabled and 1 or 0
                            }):Play()
                            U.TextColor3 = q.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(227, 227, 227)
                            if not q.Enabled then
                                for J, J in q.Connections do
                                    J:Disconnect()
                                end
                                table.clear(q.Connections)
                            end
                            w:UpdateArrayList()
                            task.spawn(q.Function, q.Enabled)
                        end)
                    end
                    U.MouseButton1Click:Connect(q.Toggle)
                    U.MouseButton1Click:Connect(function()
                        local J = _:Clone()
                        J.Volume = 0.6
                        J.Parent = w.MainScreenGui
                        J:Play()
                    end)
                    local J = Instance.new("UIPadding")
                    J.PaddingBottom = UDim.new(0.13, 0)
                    J.PaddingTop = UDim.new(0.13, 0)
                    J.Parent = U
                    local J = q.Children
                    J.Name = "Children"
                    J.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                    J.BorderSizePixel = 0
                    J.LayoutOrder = - ((l(U.Text, 10, Enum.Font.BuilderSansMedium).X + 10) * 100 - t - 1)
                    J.ClipsDescendants = true
                    J.Parent = N
                    local g = Instance.new("UIListLayout")
                    g.FillDirection = Enum.FillDirection.Vertical
                    g.SortOrder = Enum.SortOrder.LayoutOrder
                    g.Padding = UDim.new(0, y.AbsoluteSize.Y * 0.04)
                    g.Parent = J
                    local N = Instance.new("UIPadding")
                    N.PaddingTop = UDim.new(0, y.AbsoluteSize.Y * 0.05)
                    N.Parent = J
                    function q:Delete()
                        local t = q.Enabled
                        q.Enabled = false
                        for h, h in q.Connections do
                            h:Disconnect()
                        end
                        table.clear(q.Connections)
                        if t then
                            task.spawn(q.Function, false)
                        end
                        x.Parent = Y
                        J:ClearAllChildren()
                        n:ClearAllChildren()
                        J:Destroy()
                        n:Destroy()
                        q = nil
                    end
                    function q.getChilrenSize()
                        local x = y.AbsoluteSize.Y * 0.05
                        for Y, Y in next, J:GetChildren() do
                            if Y:IsA("Frame") and Y.Visible then
                                x += Y.AbsoluteSize.Y + y.AbsoluteSize.Y * 0.05
                            end
                        end
                        if x == y.AbsoluteSize.Y * 0.05 then
                            return 0
                        end
                        return x
                    end
                    if q.Expanded then
                        q:Expand()
                    end
                    function q:Expand()
                        pcall(function()
                            q.Expanded = not q.Expanded
                            d:Create(J, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
                                Size = q.Expanded and UDim2.new(1, 0, 0, q.getChilrenSize()) or UDim2.new(1, 0, 0, 0)
                            }):Play()
                            for x, x in next, J:GetDescendants() do
                                if x:IsA("Frame") and x.Name == "Slider_Fill" then
                                    if q.Expanded then
                                        x.Size = UDim2.fromScale(0, 1)
                                        d:Create(x, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {
                                            Size = UDim2.fromScale(x:GetAttribute("Value"), 1)
                                        }):Play()
                                    end
                                end
                            end
                        end)
                    end
                    U.MouseButton2Click:Connect(q.Expand)
                    U.MouseButton2Click:Connect(function()
                        if q.getChilrenSize() ~= 0 then
                            local x = _:Clone()
                            x.Volume = 0.7
                            x.Parent = w.MainScreenGui
                            x:Play()
                        end
                    end)
                    w:Clean(g:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        if w.ClickGuiStatus then
                            if V.UIScale.Scale == w.Scale.Value or V.UIScale.Scale == 0 then
                                d:Create(J, TweenInfo.new(0.1, Enum.EasingStyle.Exponential), {
                                    Size = q.Expanded and UDim2.new(1, 0, 0, q.getChilrenSize()) or UDim2.new(1, 0, 0, 0)
                                }):Play()
                            end
                            g.Padding = UDim.new(0, y.AbsoluteSize.Y * 0.05)
                            N.PaddingTop = UDim.new(0, y.AbsoluteSize.Y * 0.05)
                        end
                    end))
                    function q:SetBind(x)
                        q.Bind = x
                    end
                    q.AddToggle = function(x, Y)
                        local n = {
                            Name = Y["Name"] or "",
                            Frame = Instance.new("Frame"),
                            Enabled = Y["Enabled"] or Y["Default"] or false,
                            Function = Y["Function"] or Y["function"] or function()
                            end
                        }
                        local g = n.Frame
                        g.Size = UDim2.new(1, 0, 0, U.AbsoluteSize.Y * 0.8)
                        g.BackgroundTransparency = 1
                        if Y["Visible"] == false then
                            g.Visible = false
                        end
                        g.Parent = J
                        w:Clean(U:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            if w.ClickGuiStatus then
                                g.Size = UDim2.new(1, 0, 0, U.AbsoluteSize.Y * 0.8)
                            end
                        end))
                        local y = Instance.new("TextLabel")
                        y.Name = "Alias"
                        y.Text = Y["Text"] or n.Name
                        y.BackgroundTransparency = 1
                        y.Size = UDim2.fromScale(1, 1)
                        y.TextColor3 = Color3.fromRGB(255, 255, 255)
                        y.TextScaled = true
                        y.TextXAlignment = Enum.TextXAlignment.Left
                        y.FontFace = e.Font
                        y.Parent = g
                        local Y = Instance.new("UIPadding")
                        Y.PaddingBottom = UDim.new(0.1, 0)
                        Y.PaddingLeft = UDim.new(0.05, 0)
                        Y.PaddingRight = UDim.new(0.3, 0)
                        Y.PaddingTop = UDim.new(0.1, 0)
                        Y.Parent = y
                        local Y = Instance.new("TextButton")
                        Y.Name = "Button"
                        Y.Text = ""
                        Y.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
                        Y.Position = UDim2.fromScale(0.93, 0.5)
                        Y.BorderSizePixel = 0
                        Y.AnchorPoint = Vector2.new(0.9, 0.5)
                        Y.SizeConstraint = Enum.SizeConstraint.RelativeYY
                        Y.AutoButtonColor = false
                        Y.Size = UDim2.fromScale(1.75, 0.8)
                        Y.Parent = g
                        O(Y, UDim.new(999, 0))
                        local g = I(Y)
                        g.Enabled = n.Enabled
                        local y = Instance.new("TextButton")
                        y.Name = "Button"
                        y.Text = ""
                        y.Interactable = false
                        y.BackgroundTransparency = 0
                        y.BackgroundColor3 = Color3.fromRGB(208, 208, 208)
                        y.Position = UDim2.fromScale(0.25, 0.5)
                        y.BorderSizePixel = 0
                        y.AnchorPoint = Vector2.new(0.5, 0.5)
                        y.SizeConstraint = Enum.SizeConstraint.RelativeYY
                        y.Size = UDim2.fromScale(0.7, 0.7)
                        y.Parent = Y
                        O(y, UDim.new(999, 0))
                        local N = Instance.new("ImageLabel")
                        N.BackgroundTransparency = 1
                        N.Position = UDim2.fromScale(0.5, 0.5)
                        N.Size = n.Enabled and UDim2.fromScale(3, 3) or UDim2.fromScale(0, 0)
                        N.Parent = y
                        N.AnchorPoint = Vector2.new(0.5, 0.5)
                        N.Image = "rbxassetid://77031034070194"
                        if n.Enabled then
                            d:Create(y, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
                                Position = n.Enabled and UDim2.fromScale(0.75, 0.5) or UDim2.fromScale(0.25, 0.5)
                            }):Play()
                            d:Create(N, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                                Size = n.Enabled and UDim2.fromScale(3, 3) or UDim2.fromScale(0, 0)
                            }):Play()
                            Y.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                        end
                        function n:Toggle(t)
                            n.Enabled = t or not n.Enabled
                            d:Create(y, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
                                Position = n.Enabled and UDim2.fromScale(0.75, 0.5) or UDim2.fromScale(0.25, 0.5)
                            }):Play()
                            d:Create(N, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                                Size = n.Enabled and UDim2.fromScale(3, 3) or UDim2.fromScale(0, 0)
                            }):Play()
                            g.Enabled = n.Enabled
                            Y.BackgroundColor3 = n.Enabled and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(52, 52, 52)
                            n.Function(n.Enabled)
                        end
                        Y.MouseButton1Click:Connect(n.Toggle)
                        Y.MouseButton1Click:Connect(function()
                            local Y = _:Clone()
                            Y.Volume = 0.6
                            Y.Parent = w.MainScreenGui
                            Y:Play()
                        end)
                        function n:Save(Y)
                            Y[n.Name] = {
                                Enabled = n.Enabled
                            }
                        end
                        function n:Load(Y)
                            if Y and n.Enabled ~= Y.Enabled then
                                n:Toggle(Y.Enabled)
                            end
                        end
                        x.Settings[n.Name] = n
                        return n
                    end
                    q.AddSlider = function(x, Y)
                        local n = {
                            Name = Y["Name"] or "",
                            Frame = Instance.new("Frame"),
                            Max = Y["Max"] or Y["max"] or 100,
                            Min = Y["Min"] or Y["min"] or 1,
                            Value = Y["default"] or Y["Default"] or Y["Value"] or (Y["Min"] or Y["min"] or 1),
                            Decimal = Y["Decimal"] or Y["decimal"] or 1,
                            Suffix = Y["Suffix"],
                            Function = Y["Function"] or Y["function"] or function()
                            end,
                            Visible = Y["Visible"] or true
                        }
                        local g = n.Frame
                        g.Size = UDim2.new(1, 0, 0, U.AbsoluteSize.Y * 1.2)
                        g.BackgroundTransparency = 1
                        if Y["Visible"] == false then
                            g.Visible = false
                        end
                        g.Parent = J
                        w:Clean(U:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            if w.ClickGuiStatus then
                                g.Size = UDim2.new(1, 0, 0, U.AbsoluteSize.Y * 1.2)
                            end
                        end))
                        local y = Instance.new("TextLabel")
                        y.Name = "Alias"
                        y.Text = Y["Text"] or n.Name
                        y.BackgroundTransparency = 1
                        y.Size = UDim2.fromScale(1, 0.66)
                        y.TextColor3 = Color3.fromRGB(255, 255, 255)
                        y.TextScaled = true
                        y.TextXAlignment = Enum.TextXAlignment.Left
                        y.FontFace = e.Font
                        y.Parent = g
                        local Y = Instance.new("UIPadding")
                        Y.PaddingBottom = UDim.new(0.1, 0)
                        Y.PaddingLeft = UDim.new(0.05, 0)
                        Y.PaddingRight = UDim.new(0.4, 0)
                        Y.PaddingTop = UDim.new(0.1, 0)
                        Y.Parent = y
                        local Y = Instance.new("TextLabel")
                        Y.Name = "Select"
                        Y.Text = n.Value .. (n.Suffix and " " .. (type(n.Suffix) == "function" and n.Suffix(n.Value) or n.Suffix) or "")
                        Y.BackgroundTransparency = 1
                        Y.Size = UDim2.fromScale(1, 0.66)
                        Y.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Y.TextScaled = true
                        Y.TextXAlignment = Enum.TextXAlignment.Right
                        Y.FontFace = e.Font
                        Y.Parent = g
                        local y = Instance.new("UIPadding")
                        y.PaddingBottom = UDim.new(0.1, 0)
                        y.PaddingLeft = UDim.new(0.4, 0)
                        y.PaddingRight = UDim.new(0.05, 0)
                        y.PaddingTop = UDim.new(0.1, 0)
                        y.Parent = Y
                        local y = Instance.new("Frame")
                        y.Name = "Slider"
                        y.AnchorPoint = Vector2.new(0, 0.5)
                        y.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        y.BackgroundTransparency = 1
                        y.Position = UDim2.fromScale(0, 0.75)
                        y.Size = UDim2.fromScale(1, 0.08)
                        y.Parent = g
                        local g = Instance.new("UIPadding")
                        g.PaddingLeft = UDim.new(0.07, 0)
                        g.PaddingRight = UDim.new(0.07, 0)
                        g.Parent = y
                        local g = Instance.new("Frame")
                        g.Name = "Line"
                        g.AnchorPoint = Vector2.new(0.5, 0.5)
                        g.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        g.BackgroundTransparency = 0
                        g.Position = UDim2.fromScale(0.5, 0.5)
                        g.Size = UDim2.fromScale(1, 1)
                        g.Parent = y
                        local N = Instance.new("Frame")
                        N.Name = "Slider_Fill"
                        N.AnchorPoint = Vector2.new(0, 0.5)
                        N.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        N.BackgroundTransparency = 0
                        N.Position = UDim2.fromScale(0, 0.5)
                        N.Size = UDim2.fromScale(n.Value / n.Max, 1)
                        N.BorderSizePixel = 0
                        N.Parent = g
                        N:SetAttribute("Value", n.Value / n.Max)
                        I(N)
                        local t = Instance.new("Frame")
                        t.Name = "BALL"
                        t.AnchorPoint = Vector2.new(0.5, 0.5)
                        t.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        t.BackgroundTransparency = 0
                        t.Position = UDim2.fromScale(1, 0.5)
                        t.Size = UDim2.fromScale(3, 3.05)
                        t.SizeConstraint = Enum.SizeConstraint.RelativeYY
                        t.BorderSizePixel = 0
                        t.Parent = N
                        O(t, UDim.new(10, 0))
                        I(t)
                        local h = Instance.new("ImageLabel")
                        h.BackgroundTransparency = 1
                        h.Position = UDim2.fromScale(0.5, 0.5)
                        h.Size = UDim2.fromScale(3, 3)
                        h.AnchorPoint = Vector2.new(0.5, 0.5)
                        h.Image = "rbxassetid://77031034070194"
                        h.Parent = t
                        I(h)
                        local t = Instance.new("TextButton")
                        t.Name = "Input"
                        t.Text = ""
                        t.AnchorPoint = Vector2.new(0.5, 0.5)
                        t.AutoButtonColor = false
                        t.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        t.BackgroundTransparency = 1
                        t.Position = UDim2.fromScale(0.5, 0.5)
                        t.Size = UDim2.fromScale(1, 7)
                        t.Parent = y
                        local function y(h, G, b, E)
                            local a = n.Value ~= G
                            if not E then
                                d:Create(N, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {
                                    Size = UDim2.fromScale(h, 1)
                                }):Play()
                            end
                            n.Value = G
                            Y.Text = n.Value .. (n.Suffix and " " .. (type(n.Suffix) == "function" and n.Suffix(n.Value) or n.Suffix) or "")
                            N:SetAttribute("Value", h)
                            if a or b then
                                n.Function(G, b)
                            end
                        end
                        t.InputBegan:Connect(function(Y)
                            if (Y.UserInputType == Enum.UserInputType.MouseButton1 or Y.UserInputType == Enum.UserInputType.Touch) then
                                local N = math.clamp((Y.Position.X - g.AbsolutePosition.X) / g.AbsoluteSize.X, 0, 1)
                                local t = math.floor((n.Min + (n.Max - n.Min) * N) * n.Decimal) / n.Decimal
                                y(N, t)
                                local h = N
                                local N = t
                                local t = P.InputChanged:Connect(function(G)
                                    if G.UserInputType == (Y.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
                                        local b = math.clamp((G.Position.X - g.AbsolutePosition.X) / g.AbsoluteSize.X, 0, 1)
                                        local g = math.floor((n.Min + (n.Max - n.Min) * b) * n.Decimal) / n.Decimal
                                        y(b, g)
                                        if N ~= g then
                                            local G = _:Clone()
                                            G.Volume = 0.2
                                            G.Parent = w.MainScreenGui
                                            G:Play()
                                        end
                                        N = g
                                        h = b
                                    end
                                end)
                                local g
                                g = Y.Changed:Connect(function()
                                    if Y.UserInputState == Enum.UserInputState.End then
                                        if t then
                                            t:Disconnect()
                                        end
                                        if g then
                                            g:Disconnect()
                                        end
                                        y(h, N, true)
                                    end
                                end)
                            end
                        end)
                        function n:Save(Y)
                            Y[n.Name] = {
                                Max = n.Max,
                                Min = n.Min,
                                Value = n.Value
                            }
                        end
                        function n:Load(Y)
                            if Y and Y.Max and n.Min and Y.Max == n.Max and Y.Min == n.Min and Y.Value then
                                local g = math.clamp((Y.Value - Y.Min) / (Y.Max - Y.Min), 0, 1)
                                n.Value = Y.Value
                                y(g, Y.Value, true, true)
                            end
                        end
                        x.Settings[n.Name] = n
                        return n
                    end
                    q.AddDropdown = function(x, x)
                        local Y = {
                            Name = x["Name"] or x["Text"] or "",
                            Frame = Instance.new("Frame"),
                            Value = x["Default"] or x["List"][1] or "None",
                            Function = x["Function"] or x["function"] or function()
                            end
                        }
                        local n = Y.Frame
                        n.Size = UDim2.new(1, 0, 0, U.AbsoluteSize.Y * 0.8)
                        n.BackgroundTransparency = 1
                        n.Parent = J
                        w:Clean(U:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            if w.ClickGuiStatus then
                                n.Size = UDim2.new(1, 0, 0, U.AbsoluteSize.Y * 0.8)
                            end
                        end))
                        local J = Instance.new("TextLabel")
                        J.Name = "Alias"
                        J.Text = Y.Name
                        J.BackgroundTransparency = 1
                        J.Size = UDim2.fromScale(1, 1)
                        J.TextColor3 = Color3.fromRGB(255, 255, 255)
                        J.TextScaled = true
                        J.TextXAlignment = Enum.TextXAlignment.Left
                        J.FontFace = e.Font
                        J.Parent = n
                        local g = Instance.new("UIPadding")
                        g.PaddingBottom = UDim.new(0.1, 0)
                        g.PaddingLeft = UDim.new(0.05, 0)
                        g.PaddingRight = UDim.new(0.4, 0)
                        g.PaddingTop = UDim.new(0.1, 0)
                        g.Parent = J
                        local J = Instance.new("TextButton")
                        J.Name = "Select"
                        J.Text = Y.Value
                        J.BackgroundTransparency = 1
                        J.Size = UDim2.fromScale(1, 1)
                        J.TextColor3 = Color3.fromRGB(200, 200, 200)
                        J.TextScaled = true
                        J.TextXAlignment = Enum.TextXAlignment.Right
                        J.FontFace = e.Font
                        J.Parent = n
                        local n = Instance.new("UIPadding")
                        n.PaddingBottom = UDim.new(0.1, 0)
                        n.PaddingLeft = UDim.new(0.5, 0)
                        n.PaddingRight = UDim.new(0.05, 0)
                        n.PaddingTop = UDim.new(0.1, 0)
                        n.Parent = J
                        J.MouseButton1Click:Connect(function()
                            local n = table.find(x["List"], Y.Value) or 1
                            n = n % #x["List"] + 1
                            Y.Value = x["List"][n]
                            J.Text = x["List"][n]
                            local g = _:Clone()
                            g.Volume = 1
                            g.Parent = w.MainScreenGui
                            g:Play()
                            Y.Function(x["List"][n])
                        end)
                        function Y:Save(x)
                            x[Y.Name] = {
                                Value = Y.Value
                            }
                        end
                        function Y:Load(x)
                            if x and x.Value then
                                Y.Value = x.Value
                                J.Text = x.Value
                            end
                        end
                        q.Settings[Y.Name] = Y
                        return Y
                    end
                    w.Modules[R["Name"]] = q
                    i.Modules[R["Name"]] = q
                    return q
                end
                i.RemoveModule = function(x, x)
                    if w.Modules[x["Name"]] then
                        w.Modules[x["Name"]]:Delete()
                    end
                end
                w.Catalogs[m["Name"]] = i
                return i
            end
        end
        w:CreateGUI()
        local m = 20
        local x = {}
        local Y, n, i = {}, {}, {}
        do
            function w:GetArrayListColor(i)
                local J = L(i)
                if e.ThirdColor then
                    if J <= 0.5 then
                        return e.MainColor:Lerp(e.SecondaryColor, J * 2)
                    end
                    return e.SecondaryColor:Lerp(e.ThirdColor, (J - 0.5) * 2)
                end
                return e.SecondaryColor:Lerp(e.MainColor, J)
            end
            local L = Instance.new("Frame")
            L.Size = UDim2.new(0, 0, 0, m)
            L.BackgroundTransparency = 1
            L.AnchorPoint = Vector2.new(1, 0)
            L.Position = UDim2.fromScale(0, 0)
            f(L)
            local f = Instance.new("TextLabel")
            f.Name = "TextLabel"
            f.Size = UDim2.fromScale(1, 1)
            f.TextColor3 = Color3.fromRGB(255, 255, 255)
            f.BorderSizePixel = 0
            f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            f.BackgroundTransparency = 0.3
            f.RichText = true
            f.FontFace = e.Font
            f.TextSize = L.AbsoluteSize.Y
            f.Parent = L
            local i = Instance.new("Frame")
            i.BackgroundTransparency = 1
            i.AnchorPoint = Vector2.new(1, 0.5)
            i.ClipsDescendants = true
            i.Position = UDim2.fromScale(1, 0)
            i.Parent = f
            local f = Instance.new("Frame")
            f.Size = UDim2.fromScale(0.6, 0.3)
            f.BackgroundTransparency = 0
            f.AnchorPoint = Vector2.new(0, 0.5)
            f.Position = UDim2.fromScale(- 0.3, 0.5)
            f.Parent = i
            local i = Instance.new("ImageLabel")
            i.BackgroundTransparency = 1
            i.AnchorPoint = Vector2.new(0, 0.5)
            i.Position = UDim2.fromScale(- 8.0, 0.5)
            i.ZIndex = - 10.0
            i.Size = UDim2.fromScale(10, 1.3)
            i.ImageTransparency = 0.6
            i.Image = "rbxassetid://93106615966363"
            i.Parent = f
            O(i, UDim.new(999, 0))
            O(f, UDim.new(999, 0))
            local f = {}
            function w:UpdateArrayList()
                local i, J = {}, {}
                for g, y in next, self.Modules do
                    if y.Enabled and not f[g] then
                        f[g] = g
                        table.insert(i, g)
                    elseif not y.Enabled and f[g] then
                        table.insert(J, g)
                        f[g] = nil
                    end
                end
                for f, f in p:GetChildren() do
                    if f:IsA("Frame") then
                        if table.find(J, f.Name) then
                            d:Create(f.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                                Scale = 0
                            }):Play()
                            task.delay(0.3, function()
                                f:Destroy()
                            end)
                        end
                    end
                end
                for f, f in next, i do
                    local i = L:Clone()
                    i.Parent = p
                    i.Name = f
                    local L = w:GetArrayListColor(i.AbsolutePosition)
                    i.TextLabel.Text = "<font color=\"rgb(" .. tostring(math.floor(L.R * 255)) .. "," .. tostring(math.floor(L.G * 255)) .. "," .. tostring(math.floor(L.B * 255)) .. ")\">" .. f .. "</font>"
                    local L = self.Modules[f]
                    if L and L.ExtraText then
                        local f = L.ExtraText()
                        i.TextLabel.Text ..= f ~= "" and " " .. f or f
                    end
                    i.Size = UDim2.new(0, 0, 0, m)
                    local L = UDim2.new(0, l(K(i.TextLabel.Text), i.TextLabel.TextSize, e.Font, Vector2.new(100000, 100000)).X + m / 2, 0, m)
                    i.Size = L
                    i.LayoutOrder = - l(K(i.TextLabel.Text), i.TextLabel.TextSize, e.Font, Vector2.new(100000, 100000)).X
                    if Y.Value then
                        i.TextLabel.BackgroundTransparency = 1 - Y.Value
                    end
                    i.TextLabel.Frame.Visible = n.Enabled or false
                    local L = Instance.new("UIScale")
                    L.Parent = i
                    L.Scale = 0
                    L.Parent = i
                    d:Create(L, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                        Scale = 1
                    }):Play()
                end
            end
            w:Clean(j.PreRender:Connect(function()
                if x.Enabled then
                    for L, L in next, p:GetChildren() do
                        if L:IsA("Frame") then
                            local f = w:GetArrayListColor(L.AbsolutePosition)
                            L.TextLabel.Text = "<font color=\"rgb(" .. tostring(math.floor(f.R * 255)) .. "," .. tostring(math.floor(f.G * 255)) .. "," .. tostring(math.floor(f.B * 255)) .. ")\">" .. L.Name .. "</font>"
                            if ArrayListGlowEffect.Enabled then
                                L.Shadow.ImageColor3 = f
                                L.Shadow.Visible = true
                            else
                                L.Shadow.Visible = false
                            end
                            local f = w.Modules[L.Name]
                            if f and f.ExtraText then
                                local i = f.ExtraText()
                                L.TextLabel.Text ..= i ~= "" and " " .. i or i
                            end
                            L.TextLabel.Frame.Frame.BackgroundColor3 = w:GetArrayListColor(L.AbsolutePosition)
                            L.TextLabel.BackgroundTransparency = 1 - Y.Value
                            L.TextLabel.Frame.Frame.ImageLabel.ImageColor3 = w:GetArrayListColor(L.AbsolutePosition)
                            L.TextLabel.TextSize = m
                            L.Size = UDim2.new(0, l(K(L.TextLabel.Text), m, e.Font, Vector2.new(100000, 100000)).X + m / 2, 0, m)
                        end
                    end
                end
            end))
        end
        local L
        local K = w.TargetHudFrame
        K.Size = UDim2.new(0, w.MainScreenGui.AbsoluteSize.Y / 6, 0, w.MainScreenGui.AbsoluteSize.Y / 14)
        K.BackgroundTransparency = 1
        K.Parent = w.MainScreenGui
        K.Visible = false
        local l = Instance.new("Frame")
        l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Position = UDim2.fromScale(0.5, 0.5)
        l.Size = UDim2.fromScale(1, 1)
        l.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        l.BackgroundTransparency = 0.2
        l.BorderSizePixel = 0
        l.Parent = K
        local f = Instance.new("TextLabel")
        f.TextScaled = true
        f.BackgroundTransparency = 1
        f.Text = "None"
        f.TextColor3 = Color3.fromRGB(240, 240, 240)
        f.Size = UDim2.fromScale(1, 0.5)
        f.TextXAlignment = Enum.TextXAlignment.Left
        f.FontFace = e.Font
        f.Parent = l
        local i = Instance.new("UIPadding")
        i.PaddingBottom = UDim.new(0.15, 0)
        i.PaddingTop = UDim.new(0.4, 0)
        i.PaddingLeft = UDim.new(0.42, 0)
        i.PaddingRight = UDim.new(0.1, 0)
        i.Parent = f
        O(l, UDim.new(0, 26))
        C(l).ImageColor3 = Color3.fromRGB(0, 0, 0)
        local i = Instance.new("CanvasGroup")
        i.AnchorPoint = Vector2.new(0, 0.5)
        i.Position = UDim2.fromScale(0.42, 0.7)
        i.Size = UDim2.fromScale(0.46, 0.12)
        i.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        i.BackgroundTransparency = 0.7
        i.BorderSizePixel = 0
        i.Parent = l
        O(i, UDim.new(99, 0))
        local J = Instance.new("TextLabel")
        J.Text = "0"
        J.TextXAlignment = Enum.TextXAlignment.Left
        J.AnchorPoint = Vector2.new(0, 0.5)
        J.Position = UDim2.fromScale(0.42, 0.5)
        J.Size = UDim2.fromScale(0.5, 0.2)
        J.TextScaled = true
        J.TextColor3 = Color3.fromRGB(240, 240, 240)
        J.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        J.BackgroundTransparency = 1
        J.BorderSizePixel = 0
        J.FontFace = e.Font
        J.Parent = l
        local g = Instance.new("Frame")
        g.AnchorPoint = Vector2.new(0, 0.5)
        g.Position = UDim2.fromScale(0, 0.5)
        g.Size = UDim2.fromScale(0, 1)
        g.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        g.BackgroundTransparency = 0.1
        g.BorderSizePixel = 0
        g.Parent = i
        local i = Instance.new("ImageLabel")
        i.AnchorPoint = Vector2.new(0.5, 0.5)
        i.Position = UDim2.fromScale(0.2, 0.5)
        i.BackgroundTransparency = 1
        i.SizeConstraint = Enum.SizeConstraint.RelativeYY
        i.Size = UDim2.fromScale(0.7, 0.7)
        i.Parent = l
        i.ImageColor3 = Color3.fromRGB(255, 255, 255)
        O(i, UDim.new(0, 26))
        C(i).ImageColor3 = Color3.fromRGB(0, 0, 0)
        s(K, w.MainScreenGui.ClickGui)
        local s = Instance.new("UIScale", l)
        s.Scale = w.ClickGuiStatus and w.Scale.Value or 0
        local C = Instance.new("UIScale", i)
        C.Scale = 1
        local y
        local N = 0
        local t = 0
        local R
        local q = {
            Targets = {},
            Object = l,
            UpdateInfo = function(U)
                local h = w.Libraries.entitylib
                if not h then
                    return
                end
                for G, b in U.Targets do
                    if b < tick() then
                        U.Targets[G] = nil
                    end
                end
                local G, b = nil, tick()
                for E, a in U.Targets do
                    if a > b then
                        G = E
                        b = a
                    end
                end
                local b
                if G ~= nil or w.ClickGuiStatus and s.Scale == 0 and not b then
                    b = d:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
                        Scale = R.Value or 1
                    }):Play()
                elseif not w.ClickGuiStatus and not b then
                    b = d:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
                        Scale = 0
                    }):Play()
                end
                if G then
                    f.Text = G.Player and (G.Player.Name) or G.Character and G.Character.Name or f.Text
                    if not G.Character then
                        G.Health = G.Health or 0
                        G.MaxHealth = G.MaxHealth or 100
                    end
                    J.Text = ("%2d HP"):format(G.Health)
                    if G.Health == math.huge then
                        J.Text = "Inf"
                    end
                    if h.character.Humanoid.Health == G.Health then
                        J.Text = J.Text .. " Drawing"
                    elseif h.character.Humanoid.Health < G.Health then
                        J.Text = J.Text .. " Losing"
                    elseif h.character.Humanoid.Health > G.Health then
                        J.Text = J.Text .. " Winning"
                    end
                    if G.Health ~= N then
                        local f = math.max(G.Health / G.MaxHealth, 0)
                        if G.Health == math.huge then
                            f = 1
                        end
                        d:Create(g, TweenInfo.new(0.3), {
                            Size = UDim2.fromScale(math.min(f, 1), 1),
                            BackgroundColor3 = Color3.fromHSV(math.clamp(f / 2.5, 0, 1), 0.89, 0.75)
                        }):Play()
                        if N > G.Health and U.LastTarget == G then
                            i.ImageColor3 = Color3.fromRGB(255, 0, 0)
                            C.Scale = 0.8
                            d:Create(i, TweenInfo.new(0.3), {
                                ImageColor3 = Color3.fromRGB(255, 255, 255)
                            }):Play()
                            i.Rotation = 20
                            d:Create(i, TweenInfo.new(0.3), {
                                Rotation = 0
                            }):Play()
                            d:Create(C, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
                                Scale = 1
                            }):Play()
                            if y and y.Enabled then
                                local C = _:Clone()
                                C.Volume = 0.7
                                C.Parent = w.MainScreenGui
                                C:Play()
                            end
                        end
                        N = G.Health
                        t = G.MaxHealth
                    end
                    if not G.Character then
                        table.clear(G)
                    end
                    U.LastTarget = G
                end
                return G
            end
        }
        w.Libraries.Targetinfo = q
        function w:Notify(C)
            local f = {
                Text = C["Text"] or "None",
                Duration = C["Duration"] or C["Durn"] or 2,
                Frame = Instance.new("Frame"),
                Sound = C["Sound"],
                Status = false
            }
            local C = f.Frame
            C.Size = UDim2.fromScale(0.8, 0.05)
            C.BackgroundTransparency = 1
            C.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            C.Parent = Q
            local _ = Instance.new("UIScale", C)
            _.Scale = 0
            local i = Instance.new("Frame")
            i.Name = "NotifyMain"
            i.Size = UDim2.fromScale(1, 1)
            i.Position = UDim2.fromScale(2, 0.2)
            i.BackgroundTransparency = 0.3
            i.BorderSizePixel = 0
            i.ZIndex = - 1.0
            i.ClipsDescendants = false
            i.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            i.Parent = C
            O(i, UDim.new(999, 0))
            I(k(i))
            local k = Instance.new("TextButton")
            k.Size = UDim2.fromScale(1, 1)
            k.Text = f.Text
            k.FontFace = e.Font
            k.BorderSizePixel = 0
            k.BackgroundTransparency = 1
            k.ZIndex = 10
            k.TextScaled = true
            k.TextXAlignment = Enum.TextXAlignment.Left
            k.TextColor3 = Color3.fromRGB(255, 255, 255)
            k.Parent = i
            local J = Instance.new("UIPadding")
            J.PaddingBottom = UDim.new(0.25, 0)
            J.PaddingLeft = UDim.new(0.1, 0)
            J.PaddingRight = UDim.new(0.1, 0)
            J.PaddingTop = UDim.new(0.25, 0)
            J.Parent = k
            local J = Instance.new("Frame")
            J.Size = UDim2.fromScale(0, 1)
            J.BorderSizePixel = 0
            J.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
            J.BackgroundTransparency = 0
            J.Parent = i
            I(J)
            O(J, UDim.new(999, 0))
            d:Create(i, TweenInfo.new(1, Enum.EasingStyle.Exponential), {
                Position = UDim2.fromScale(0, 0)
            }):Play()
            d:Create(_, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                Scale = 1
            }):Play()
            d:Create(J, TweenInfo.new(f.Duration, Enum.EasingStyle.Linear), {
                Size = UDim2.fromScale(1, 1)
            }):Play()
            function f:Delete()
                if f.Status then
                    return
                end
                f.Status = true
                d:Create(i, TweenInfo.new(1, Enum.EasingStyle.Exponential), {
                    Position = UDim2.fromScale(2, 0.2)
                }):Play()
                wait(1)
                C:ClearAllChildren()
                C:Destroy()
            end
            k.MouseButton1Click:Connect(f.Delete)
            task.delay(f.Duration, f.Delete)
        end
        w:Clean(P.InputBegan:Connect(function(k)
            if not P:GetFocusedTextBox() and k.KeyCode ~= Enum.KeyCode.Unknown then
                if table.find(w.Keybind, k.KeyCode.Name) then
                    if w.ThreadFix then
                        setthreadidentity(8)
                    end
                    w.ClickGuiStatus = not w.ClickGuiStatus
                    w.MainScreenGui.Modal.Visible = w.ClickGuiStatus
                    d:Create(V.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                        Scale = w.ClickGuiStatus and w.Scale.Value or 0
                    }):Play()
                    d:Create(r, TweenInfo.new(1, Enum.EasingStyle.Exponential), {
                        Transparency = w.ClickGuiStatus and z.Value or 1
                    }):Play()
                    d:Create(r, TweenInfo.new(2, Enum.EasingStyle.Exponential), {
                        ImageTransparency = w.ClickGuiStatus and 0.76 or 1
                    }):Play()
                    d:Create(o, TweenInfo.new(2, Enum.EasingStyle.Exponential), {
                        ImageTransparency = w.ClickGuiStatus and 0.9 or 1
                    }):Play()
                    d:Create(w.TargetHudFrame.Frame.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
                        Scale = w.ClickGuiStatus and (R.Value or 1) or 0
                    }):Play()
                    for P, P in next, u do
                        P.Visible = false
                    end
                    task.delay(0.16, function()
                        w.ClickGuiLoaded = w.ClickGuiStatus
                        if c.Enabled then
                            for P, P in next, u do
                                P.Visible = w.ClickGuiStatus
                            end
                        end
                    end)
                    return
                end
                for P, P in w.Modules do
                    if k.KeyCode.Name == P.Bind.Name then
                        P:Toggle()
                        w:Notify({
                            Text = P.Name .. " has been " .. (P.Enabled and "Enabled" or "Disabled"),
                            Duration = 1.5
                        })
                    end
                end
            end
        end))
        local P = {}
        function w:SaveOptions(k, C)
            if not C then
                return
            end
            C = {}
            for f, f in k.Settings do
                if not f.Save then
                    continue
                end
                f:Save(C)
            end
            return C
        end
        function w:Save()
            local k = {
                Modules = {}
            }
            for C, f in self.Modules do
                k.Modules[C] = {
                    Enabled = f.Enabled,
                    Expanded = f.Expanded,
                    Bind = f.Bind.Name,
                    Settings = w:SaveOptions(f, true)
                }
            end
            local C = {
                TargetHud = {}
            }
            C.Theme = P.Value
            C.TargetHud = {
                X = K.AbsolutePosition.X,
                Y = K.AbsolutePosition.Y
            }
            writefile("Modern/Config/" .. self.Place .. ".txt", M:JSONEncode(k))
            writefile("Modern/Config/Gui.txt", M:JSONEncode(C))
        end
        function w:LoadOptions(M, k)
            for C, f in k do
                local k = M.Settings[C]
                if not k then
                    continue
                end
                k:Load(f)
            end
        end
        function w:Load()
            local M = true
            if isfile("Modern/Config/" .. self.Place .. ".txt") then
                local k = X("Modern/Config/" .. self.Place .. ".txt")
                if not k then
                    k = {
                        Modules = {}
                    }
                    M = false
                end
                for C, f in k.Modules do
                    local k = self.Modules[C]
                    if not k then
                        continue
                    end
                    if k.Settings and f.Settings then
                        self:LoadOptions(k, f.Settings)
                    end
                    if f.Enabled ~= k.Enabled then
                        k:Toggle()
                    end
                    if f.Expanded ~= k.Expanded then
                        k:Expand()
                    end
                    local C
                    pcall(function()
                        C = Enum.KeyCode[f.Bind]
                    end)
                    if C then
                        k:SetBind(C)
                    end
                end
            end
            if isfile("Modern/Config/Gui.txt") then
                local k = X("Modern/Config/Gui.txt")
                if not k then
                    k = {}
                end
                if k.TargetHud.X and k.TargetHud.Y then
                    if K and k.TargetHud.X > 0 and k.TargetHud.Y > 0 then
                        K.Position = UDim2.fromOffset(k.TargetHud.X, k.TargetHud.Y)
                    end
                end
                if k.Theme and self.Modules.Interface then
                    self.Modules.Interface.Settings.Theme:Load({
                        Value = k.Theme
                    })
                    self.Modules.Interface:Toggle()
                end
            end
            self.Loaded = M
        end
        function w:Uninject()
            w:Save()
            w.Loaded = nil
            for M, M in self.Modules do
                if M.Enabled then
                    M:Toggle()
                end
            end
            for M, M in w.Connections do
                pcall(function()
                    M:Disconnect()
                end)
            end
            if w.ThreadFix then
                setthreadidentity(8)
            end
            w.MainScreenGui:ClearAllChildren()
            w.MainScreenGui:Destroy()
            table.clear(w.Libraries)
            Z(w)
            shared.Modern = nil
        end
        function w:SendChat(M)
            game:GetService("TextChatService").TextChannels.RBXSystem:DisplaySystemMessage("<b><font color = \"rgb(150, 150, 150)\">[</font><font color = \"rgb(84, 140, 209)\">Modern Client</font><font color = \"rgb(150, 150, 150)\">]</font></b>: " .. M)
        end
        local function M(k)
            if k.TextSource and k.Status == Enum.TextChatMessageStatus.Sending then
                if k.Text:find("^.bind") then
                    local C = k.Text:split(" ")
                    local f
                    pcall(function()
                        f = Enum.KeyCode[C[3]]
                    end)
                    if C[2] then
                        C[2] = C[2]:gsub("_", " ")
                    end
                    if #C == 3 and f and w.Modules[C[2]] then
                        w.Modules[C[2]]:SetBind(f)
                        w:SendChat(C[2] .. " has been bound to " .. C[3])
                    else
                        w:SendChat("Error")
                    end
                    k.Text = ""
                elseif k.Text:find("^.clearbind") or k.Text:find("^.unbind") then
                    local C = k.Text:split(" ")
                    if C[2] then
                        C[2] = C[2]:gsub("_", " ")
                    end
                    if #C == 2 and w.Modules[C[2]] then
                        w.Modules[C[2]]:SetBind({})
                        w:SendChat("Unbound " .. C[2])
                    else
                        w:SendChat("Error")
                    end
                    k.Text = ""
                end
            end
        end
        task.spawn(function()
            repeat
                A.OnIncomingMessage = M
                task.wait(1)
            until not (w.Loaded or shared.ModernLoading)
        end)
        local A = w:AddCatalog({
            Name = "Combat"
        })
        local A = w:AddCatalog({
            Name = "Render"
        })
        local A = w:AddCatalog({
            Name = "Movement"
        })
        local A = w:AddCatalog({
            Name = "Player"
        })
        local A = w:AddCatalog({
            Name = "Other"
        })
        T(function()
            local M = {
                ["Shadow"] = {Color3.fromRGB(97, 131, 255), Color3.fromRGB(206, 212, 255)},
                ["Aqua"] = {Color3.fromRGB(185, 250, 255), Color3.fromRGB(79, 199, 200)},
                ["Hyper"] = {Color3.fromRGB(236, 110, 173), Color3.fromRGB(52, 148, 230)},
                ["Candy Cane"] = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255)},
                ["Blend"] = {Color3.fromRGB(71, 148, 253), Color3.fromRGB(71, 253, 160)},
                ["Cherry"] = {Color3.fromRGB(187, 55, 125), Color3.fromRGB(251, 211, 233)},
                ["Christmas"] = {Color3.fromRGB(255, 64, 64), Color3.fromRGB(255, 255, 255), Color3.fromRGB(64, 255, 64)},
                ["Coral"] = {Color3.fromRGB(244, 168, 150), Color3.fromRGB(52, 133, 151)},
                ["Pastel"] = {Color3.fromRGB(243, 155, 178), Color3.fromRGB(207, 196, 243)},
                ["Legacy"] = {Color3.fromRGB(112, 206, 255), Color3.fromRGB(112, 206, 255)},
                ["Lush"] = {Color3.fromRGB(168, 224, 99), Color3.fromRGB(86, 171, 47)},
                ["Bubble Gum"] = {Color3.fromRGB(243, 145, 216), Color3.fromRGB(152, 165, 243)},
                ["Creida"] = {Color3.fromRGB(156, 164, 224), Color3.fromRGB(54, 57, 78)},
                ["Digital Horizon"] = {Color3.fromRGB(95, 195, 228), Color3.fromRGB(229, 93, 135)},
                ["Gothic"] = {Color3.fromRGB(31, 30, 30), Color3.fromRGB(196, 190, 190)},
                ["Halogen"] = {Color3.fromRGB(255, 65, 108), Color3.fromRGB(255, 75, 43)},
                ["Lime Water"] = {Color3.fromRGB(18, 255, 247), Color3.fromRGB(179, 255, 171)},
                ["Creida Two"] = {Color3.fromRGB(154, 202, 235), Color3.fromRGB(88, 130, 161)},
                ["Orange Juice"] = {Color3.fromRGB(252, 74, 26), Color3.fromRGB(247, 183, 51)},
                ["Purple"] = {Color3.fromRGB(82, 67, 145), Color3.fromRGB(117, 95, 207)},
                ["Rue"] = {Color3.fromRGB(234, 118, 176), Color3.fromRGB(31, 30, 30)},
                ["Steel Fade"] = {Color3.fromRGB(66, 134, 244), Color3.fromRGB(55, 59, 68)},
                ["Water"] = {Color3.fromRGB(12, 232, 199), Color3.fromRGB(12, 163, 232)},
                ["Winter"] = {Color3.new(1, 1, 1), Color3.new(1, 1, 1)},
                ["Wood"] = {Color3.fromRGB(79, 109, 81), Color3.fromRGB(170, 139, 87), Color3.fromRGB(240, 235, 206)},
                ["Express"] = {Color3.fromRGB(173, 83, 137), Color3.fromRGB(60, 16, 83)},
                ["Satin"] = {Color3.fromRGB(215, 60, 67), Color3.fromRGB(140, 23, 39)},
                ["Sundae"] = {Color3.fromRGB(206, 74, 126), Color3.fromRGB(122, 44, 77)},
                ["Sunkist"] = {Color3.fromRGB(242, 201, 76), Color3.fromRGB(242, 153, 74)},
                ["Rainbow"] = {Color3.fromRGB(1, 1, 1), Color3.fromRGB(1, 1, 1)},
                ["Onyx"] = {Color3.fromRGB(40, 40, 40), Color3.fromRGB(70, 70, 70), Color3.fromRGB(30, 30, 30)}
            }
            local k = {}
            local C
            C = A:AddModule({
                Name = "Interface",
                Function = function(f)
                    if not f then
                        C:Toggle()
                    else
                        if M[P.Value] then
                            e.MainColor = M[P.Value][1]
                            e.SecondaryColor = M[P.Value][2]
                            e.ThirdColor = M[P.Value][3]
                        end
                    end
                end
            })
            z = C:AddSlider({
                Name = "Transparency",
                Function = function()
                    if C.Enabled then
                        d:Create(r, TweenInfo.new(1, Enum.EasingStyle.Exponential), {
                            Transparency = w.ClickGuiStatus and z.Value or 1
                        }):Play()
                    end
                end,
                Default = 0.4,
                Min = 0,
                Max = 1,
                Decimal = 10
            })
            local f = {}
            for Z, X in next, M do
                table.insert(f, Z)
            end
            P = C:AddDropdown({
                Name = "Theme",
                List = f,
                Default = "Shadow",
                Function = function(f)
                    if M[f] then
                        e.MainColor = M[f][1]
                        e.SecondaryColor = M[f][2]
                        e.ThirdColor = M[f][3]
                    end
                end
            })
            B = C:AddDropdown({
                Name = "Mode",
                List = {"Fade", "Breathe", "Static"}
            })
            UICorner = C:AddToggle({
                Name = "UICorner",
                Default = true,
                Function = function(B)
                    if B then
                        for B, B in next, F do
                            if B.Name == "CatalogName" or B.Name == "NotifyMain" then
                                O(B, UDim.new(0.2, 0))
                            else
                                O(B, UDim.new(0.1, 0))
                            end
                        end
                    else
                        for B, B in next, F do
                            for O, O in next, B:GetChildren() do
                                if O:IsA("UICorner") then
                                    O:Destroy()
                                end
                            end
                        end
                    end
                end
            })
            c = C:AddToggle({
                Name = "Shadow",
                Default = true,
                Function = function(B)
                    for c, c in next, u do
                        c.Visible = B
                    end
                end
            })
            C:Toggle()
            task.spawn(function()
                repeat
                    if M[P.Value] then
                        e.MainColor = M[P.Value][1]
                        e.SecondaryColor = M[P.Value][2]
                        e.ThirdColor = M[P.Value][3]
                    end
                    local B = tick() * (0.2) % 1
                    if P.Value == "Rainbow" then
                        e.MainColor = Color3.fromHSV(B, 0.59, 1)
                        e.SecondaryColor = Color3.fromHSV((B + 0.1) % 1, 0.59, 1)
                        e.ThirdColor = nil
                    end
                    task.wait()
                until w.Loaded == nil
            end)
            k = C:AddToggle({
                Name = "No Notify",
                Function = function(B)
                    Q.Visible = not B
                end
            })
        end)
        T(function()
            L = A:AddModule({
                Name = "Target Hud",
                Function = function(B)
                    if B then
                        L:Clean(w.MainScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            l.Size = UDim2.new(0, w.MainScreenGui.AbsoluteSize.Y / 6, 0, w.MainScreenGui.AbsoluteSize.Y / 14)
                        end))
                        L:Clean(j.PreRender:Connect(function()
                            q:UpdateInfo()
                        end))
                        K.Visible = true
                        s.Scale = 0
                        d:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
                            Scale = R.Value or 1
                        }):Play()
                    else
                        s.Scale = R.Value or 1
                        d:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
                            Scale = 0
                        }):Play()
                        task.wait(0.3)
                        K.Visible = false
                    end
                end
            })
            y = L:AddToggle({
                Name = "Sound Effect"
            })
            R = L:AddSlider({
                Name = "Scale",
                Min = 0.1,
                Max = 3,
                Decimal = 10,
                Default = 1,
                Function = function(L)
                    s.Scale = L
                end
            })
        end)
        T(function()
            x = A:AddModule({
                Name = "ArrayList",
                Function = function(L)
                    p.Visible = L
                end
            })
            Y = x:AddSlider({
                Name = "Transparency",
                Min = 0,
                Max = 1,
                Function = function(L)
                    for B, B in p:GetChildren() do
                        if B:IsA("Frame") then
                            B.TextLabel.BackgroundTransparency = 1 - L
                        end
                    end
                end,
                Decimal = 10,
                Default = 1
            })
            x:AddSlider({
                Name = "Size",
                Min = 5,
                Max = 30,
                Function = function(L)
                    m = L
                end,
                Decimal = 10,
                Default = 20
            })
            n = x:AddToggle({
                Name = "Glow Line",
                Function = function(m)
                    for L, L in p:GetChildren() do
                        if L:IsA("Frame") then
                            L.TextLabel.Frame.Visible = m
                        end
                    end
                end
            })
            ArrayListGlowEffect = x:AddToggle({
                Name = "Glow Effect",
                Function = function(m)
                    for L, L in p:GetChildren() do
                        if L:IsA("Frame") then
                            L.TextLabel.Frame.Visible = m
                        end
                    end
                end
            })
        end)
        shared.Modern = w
    end
end
end
b()()
b = nil

-- Перехвачено из: loadstring() call / Modern/Games/Universal.lua
local Modern = shared.Modern
local cloneref = cloneref or function(obj)
    return obj
end
if identifyexecutor then
    if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
        getgenv().setthreadidentity = nil
    end
end
local Players = cloneref(game:GetService('Players'))
local TweenService = cloneref(game:GetService('TweenService'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local TextService = cloneref(game:GetService('TextService'))
local GuiService = cloneref(game:GetService('GuiService'))
local RunService = cloneref(game:GetService('RunService'))
local HttpService = cloneref(game:GetService('HttpService'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local GroupService = cloneref(game:GetService('GroupService'))
local MarketplaceService = cloneref(game:GetService('MarketplaceService'))
local TeleportService = cloneref(game:GetService('TeleportService'))
local ContextService = cloneref(game:GetService('ContextActionService'))
local Lighting = cloneref(game:GetService("Lighting"))
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = Players.LocalPlayer
local assetfunction = getcustomasset
local run = function(func)
    func()
end
local ModernFile = shared.ModernFile
local entitylib = ModernFile.loadfile("Modern/Library/Entity.lua")
local prediction = ModernFile.loadfile("Modern/Library/Prediction.lua")
local getfontsize = Modern.Libraries.getfontsize
local addGradient = Modern.Libraries.addGradient
local Targetinfo = Modern.Libraries.Targetinfo
Modern.Libraries.entitylib = entitylib
Modern.Libraries.prediction = prediction
Modern.Libraries.auraanims = {
    Normal = {
        {
            CFrame = CFrame.new(- 0.17, - 0.14, - 0.12) * CFrame.Angles(math.rad(- 53), math.rad(50), math.rad(- 64)),
            Time = 0.1
        },
        {
            CFrame = CFrame.new(- 0.55, - 0.59, - 0.1) * CFrame.Angles(math.rad(- 161), math.rad(54), math.rad(- 6)),
            Time = 0.08
        },
        {
            CFrame = CFrame.new(- 0.62, - 0.68, - 0.07) * CFrame.Angles(math.rad(- 167), math.rad(47), math.rad(- 1)),
            Time = 0.03
        },
        {
            CFrame = CFrame.new(- 0.56, - 0.86, 0.23) * CFrame.Angles(math.rad(- 167), math.rad(49), math.rad(- 1)),
            Time = 0.03
        }
    },
    Random = {},
    ['Horizontal Spin'] = {
        {
            CFrame = CFrame.Angles(math.rad(- 10), math.rad(- 90), math.rad(- 80)),
            Time = 0.12
        },
        {
            CFrame = CFrame.Angles(math.rad(- 10), math.rad(180), math.rad(- 80)),
            Time = 0.12
        },
        {
            CFrame = CFrame.Angles(math.rad(- 10), math.rad(90), math.rad(- 80)),
            Time = 0.12
        },
        {
            CFrame = CFrame.Angles(math.rad(- 10), 0, math.rad(- 80)),
            Time = 0.12
        }
    },
    ['Vertical Spin'] = {
        {
            CFrame = CFrame.Angles(math.rad(- 90), 0, math.rad(15)),
            Time = 0.12
        },
        {
            CFrame = CFrame.Angles(math.rad(180), 0, math.rad(15)),
            Time = 0.12
        },
        {
            CFrame = CFrame.Angles(math.rad(90), 0, math.rad(15)),
            Time = 0.12
        },
        {
            CFrame = CFrame.Angles(0, 0, math.rad(15)),
            Time = 0.12
        }
    },
    Exhibition = {
        {
            CFrame = CFrame.new(0.69, - 0.7, 0.6) * CFrame.Angles(math.rad(- 30), math.rad(50), math.rad(- 90)),
            Time = 0.1
        },
        {
            CFrame = CFrame.new(0.7, - 0.71, 0.59) * CFrame.Angles(math.rad(- 84), math.rad(50), math.rad(- 38)),
            Time = 0.2
        }
    },
    ['Exhibition Old'] = {
        {
            CFrame = CFrame.new(0.69, - 0.7, 0.6) * CFrame.Angles(math.rad(- 30), math.rad(50), math.rad(- 90)),
            Time = 0.15
        },
        {
            CFrame = CFrame.new(0.69, - 0.7, 0.6) * CFrame.Angles(math.rad(- 30), math.rad(50), math.rad(- 90)),
            Time = 0.05
        },
        {
            CFrame = CFrame.new(0.7, - 0.71, 0.59) * CFrame.Angles(math.rad(- 84), math.rad(50), math.rad(- 38)),
            Time = 0.1
        },
        {
            CFrame = CFrame.new(0.7, - 0.71, 0.59) * CFrame.Angles(math.rad(- 84), math.rad(50), math.rad(- 38)),
            Time = 0.05
        },
        {
            CFrame = CFrame.new(0.63, - 0.1, 1.37) * CFrame.Angles(math.rad(- 84), math.rad(50), math.rad(- 38)),
            Time = 0.15
        }
    }
}
local function calculateMoveVector(vec)
    local c, s
    local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
    if R12 < 1 and R12 > - 1 then
        c = R22
        s = R02
    else
        c = R00
        s = - R01 * math.sign(R12)
    end
    vec = vector.create((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
    return vec.Unit == vec.Unit and vec.Unit or vector.zero
end
local function getTool()
    return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end
local function canClick()
    local mousepos = (UserInputService:GetMouseLocation() - GuiService:GetGuiInset())
    for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then
            return false
        end
    end
    for _, v in CoreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then
            return false
        end
    end
    return (not Modern.ClickGuiStatus) and (not UserInputService:GetFocusedTextBox())
end
local function getTableSize(tab)
    local ind = 0
    for _ in tab do
        ind += 1
    end
    return ind
end
local function removeTags(str)
    str = str:gsub('<br%s*/>', '\n')
    return (str:gsub('<[^<>]->', ''))
end
local function addBlur(parent)
    local blur = Instance.new('ImageLabel')
    blur.Name = 'Blur'
    blur.Size = UDim2.new(1, 89, 1, 52)
    blur.Position = UDim2.fromOffset(- 48, - 31)
    blur.BackgroundTransparency = 1
    blur.Image = "rbxassetid://74663567791967"
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.ZIndex = - 100
    blur.Parent = parent
    return blur
end
local function addRoundedShadow(parent)
    local blur = Instance.new('ImageLabel')
    blur.Name = 'Shadow'
    blur.Size = UDim2.new(1, 18, 1, 18)
    blur.AnchorPoint = Vector2.new(0.5, 0.5)
    blur.Position = UDim2.fromScale(0.5, 0.5)
    -- blur.ImageColor3 = Color3.fromRGB(12, 12, 12)
    blur.BackgroundTransparency
    = 1
    blur.Image = "rbxassetid://85528155206269"
    blur.ScaleType = Enum.ScaleType.Slice
    blur.ImageTransparency = 0.5
    blur.SliceCenter = Rect.new(36, 36, 900, 50)
    blur.SliceScale = 0.5
    blur.ZIndex = - 100
    blur.Parent = parent
    return blur
end
local function addCorner(parent, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = radius or UDim.new(0, 5)
    corner.Parent = parent
    return corner
end
local frictionTable, oldfrict = {}, {}
local function updateVelocity()
    if getTableSize(frictionTable) > 0 then
        if entitylib.isAlive then
            for _, v in entitylib.character.Character:GetChildren() do
                if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
                    oldfrict[v] = v.CustomPhysicalProperties or 'none'
                    v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
                end
            end
        end
    else
        for i, v in oldfrict do
            i.CustomPhysicalProperties = v ~= 'none' and v or nil
        end
        table.clear(oldfrict)
    end
end
local Spider = {
    Enabled = false
}
local Phase = {
    Enabled = false
}
run(function()
    Modern:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
    Modern:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
        gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
    end))
end)
entitylib.start()
repeat
    task.wait()
until game:IsLoaded()
local TargetStrafeVector
run(function()
    local AimAssist
    local Targets
    local Part
    local FOV
    local Speed
    local CircleColor
    local CircleTransparency
    local CircleFilled
    local CircleObject
    local RightClick
    local ShowTarget
    local moveConst = Vector2.new(1, 0.77) * math.rad(0.5)
    local function wrapAngle(num)
        num = num % math.pi
        num -= num >= (math.pi / 2) and math.pi or 0
        num += num < - (math.pi / 2) and math.pi or 0
        return num
    end
    AimAssist = Modern.Catalogs.Combat:AddModule({
        Name = 'Aim Assist',
        Function = function(callback)
            if CircleObject then
                CircleObject.Visible = callback
            end
            if callback then
                local ent
                local rightClicked = not RightClick.Enabled or UserInputService:IsMouseButtonPressed(1)
                AimAssist:Clean(RunService.RenderStepped:Connect(function(dt)
                    if CircleObject then
                        CircleObject.Position = UserInputService:GetMouseLocation()
                    end
                    if rightClicked and not Modern.ClickGuiStatus then
                        ent = entitylib.EntityMouse({
                            Range = FOV.Value,
                            Part = Part.Value,
                            Players = true,
                            NPCs = false,
                            Wallcheck = true,
                            Origin = gameCamera.CFrame.Position
                        })
                        if ent then
                            local facing = gameCamera.CFrame.LookVector
                            local new = (ent[Part.Value].Position - gameCamera.CFrame.Position).Unit
                            new = new == new and new or Vector3.zero
                            if ShowTarget.Enabled then
                                Targetinfo.Targets[ent] = tick() + 1
                            end
                            if new ~= Vector3.zero then
                                local diffYaw = wrapAngle(math.atan2(facing.X, facing.Z) - math.atan2(new.X, new.Z))
                                local diffPitch = math.asin(facing.Y) - math.asin(new.Y)
                                local angle = Vector2.new(diffYaw, diffPitch) // (moveConst * UserSettings():GetService('UserGameSettings').MouseSensitivity)
                                angle *= math.min(Speed.Value * dt, 1)
                                mousemoverel(angle.X, angle.Y)
                            end
                        end
                    end
                end))
                if RightClick.Enabled then
                    AimAssist:Clean(UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton2 then
                            ent = nil
                            rightClicked = true
                        end
                    end))
                    AimAssist:Clean(UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton2 then
                            rightClicked = false
                        end
                    end))
                end
            end
        end
    })
    Part = AimAssist:AddDropdown({
        Name = 'Part',
        List = {'RootPart', 'Head'}
    })
    FOV = AimAssist:AddSlider({
        Name = 'FOV',
        Min = 0,
        Max = 1000,
        Default = 100,
        Function = function(val)
            if CircleObject then
                CircleObject.Radius = val
            end
        end
    })
    Speed = AimAssist:AddSlider({
        Name = 'Speed',
        Min = 0,
        Max = 80,
        Default = 15
    })
    AimAssist:AddToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled.Enabled
                CircleObject.Color = Color3.fromRGB(255, 255, 255)
                CircleObject.Position = Modern.MainScreenGui.AbsoluteSize / 2
                CircleObject.Radius = FOV.Value
                CircleObject.NumSides = 100
                CircleObject.Transparency = 9
                CircleObject.Visible = AimAssist.Enabled
            else
                pcall(function()
                    CircleObject.Visible = false
                    CircleObject:Remove()
                end)
            end
            CircleFilled.Frame.Visible = callback
        end
    })
    CircleFilled = AimAssist:AddToggle({
        Name = 'Circle Filled',
        Function = function(callback)
            if CircleObject then
                CircleObject.Filled = callback
            end
        end,
        Darker = true,
        Visible = false
    })
    RightClick = AimAssist:AddToggle({
        Name = 'Require right click',
        Function = function()
            if AimAssist.Enabled then
                AimAssist:Toggle()
                AimAssist:Toggle()
            end
        end
    })
    ShowTarget = AimAssist:AddToggle({
        Name = 'Show Target',
        Function = function()
            if AimAssist.Enabled then
                AimAssist:Toggle()
                AimAssist:Toggle()
            end
        end
    })
end)
run(function()
    local AutoClicker
    local Mode
    local CPS
    AutoClicker = Modern.Catalogs.Combat:AddModule({
        Name = 'Auto Clicker',
        Function = function(callback)
            if callback then
                repeat
                    if Mode.Value == 'Tool' then
                        local tool = getTool()
                        if tool and UserInputService:IsMouseButtonPressed(0) then
                            tool:Activate()
                        end
                    else
                        if mouse1click and (isrbxactive or iswindowactive)() then
                            if not Modern.ClickGuiStatus then
                                (Mode.Value == 'Click' and mouse1click or mouse2click
                                )()
                            end
                        end
                    end
                    task.wait(1 / CPS.Value)
                until not AutoClicker.Enabled
            end
        end
    })
    Mode = AutoClicker:AddDropdown({
        Name = 'Mode',
        List = {'Tool', 'Click', 'RightClick'}
    })
    CPS = AutoClicker:AddSlider({
        Name = 'CPS',
        Min = 1,
        Max = 20,
        Defaul = 10
    })
end)
run(function()
    local Reach
    local Targets
    local Mode
    local Value
    local Chance
    local Overlay = OverlapParams.new()
    Overlay.FilterType = Enum.RaycastFilterType.Include
    local modified = {}
    Reach = Modern.Catalogs.Combat:AddModule({
        Name = 'Reach',
        Function = function(callback)
            if callback then
                repeat
                    local tool = getTool()
                    tool = tool and tool:FindFirstChildWhichIsA('TouchTransmitter', true)
                    if tool then
                        if Mode.Value == 'TouchInterest' then
                            local entites = {}
                            for _, v in entitylib.List do
                                if v.Targetable then
                                    if v.Player then
                                        table.insert(entites, v.Character)
                                    end
                                end
                            end
                            Overlay.FilterDescendantsInstances = entites
                            local parts = workspace:GetPartBoundsInBox(tool.Parent.CFrame * CFrame.new(0, 0, Value.Value / 2), tool.Parent.Size + Vector3.new(0, 0, Value.Value), Overlay)
                            for _, v in parts do
                                if Random.new().NextNumber(Random.new(), 0, 100) > Chance.Value then
                                    task.wait(0.2)
                                    break
                                end
                                firetouchinterest(tool.Parent, v, 1)
                                firetouchinterest(tool.Parent, v, 0)
                            end
                        else
                            if not modified[tool.Parent] then
                                modified[tool.Parent] = tool.Parent.Size
                            end
                            tool.Parent.Size = modified[tool.Parent] + Vector3.new(0, 0, Value.Value)
                            tool.Parent.Massless = true
                        end
                    end
                    task.wait()
                until not Reach.Enabled
            else
                for i, v in modified do
                    i.Size = v
                    i.Massless = false
                end
                table.clear(modified)
            end
        end
    })
    Mode = Reach:AddDropdown({
        Name = 'Mode',
        List = {'TouchInterest', 'Resize'},
        Function = function(val)
            Chance.Object.Visible = val == 'TouchInterest'
        end
    })
    Value = Reach:AddSlider({
        Name = 'Range',
        Min = 0,
        Max = 2,
        Decimal = 10,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    Chance = Reach:AddSlider({
        Name = 'Chance',
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = '%'
    })
end)
run(function()
    local Killaura
    local Targets
    local CPS
    local SwingRange
    local AttackRange
    local AngleSlider
    local Max
    local Mouse
    local Lunge
    local BoxSwingColor
    local BoxAttackColor
    local ParticleTexture
    local ParticleColor1
    local ParticleColor2
    local ParticleSize
    local Face
    local Overlay = OverlapParams.new()
    Overlay.FilterType = Enum.RaycastFilterType.Include
    local Particles, Boxes, AttackDelay = {}, {}, tick()
    local function getAttackData()
        if Mouse.Enabled then
            if not UserInputService:IsMouseButtonPressed(0) then
                return false
            end
        end
        local tool = getTool()
        return tool and tool:FindFirstChildWhichIsA('TouchTransmitter', true) or nil, tool
    end
    Killaura = Modern.Catalogs.Combat:AddModule({
        Name = 'Aura',
        Function = function(callback)
            if callback then
                repeat
                    local interest, tool = getAttackData()
                    local attacked = {}
                    if interest then
                        local plrs = entitylib.AllPosition({
                            Range = SwingRange.Value,
                            Wallcheck = nil,
                            Part = 'RootPart',
                            Players = true,
                            NPCs = false,
                            Limit = Max.Value
                        })
                        if #plrs > 0 then
                            local selfpos = entitylib.character.RootPart.Position
                            local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
                            for _, v in plrs do
                                local delta = (v.RootPart.Position - selfpos)
                                local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
                                if angle > (math.rad(AngleSlider.Value) / 2) then
                                    continue
                                end
                                table.insert(attacked, {
                                    Entity = v,
                                    Check = delta.Magnitude > AttackRange.Value and BoxSwingColor or BoxAttackColor
                                })
                                Targetinfo.Targets[v] = tick() + 1
                                if AttackDelay < tick() then
                                    AttackDelay = tick() + (1 / CPS.Value)
                                    tool:Activate()
                                end
                                if delta.Magnitude > AttackRange.Value then
                                    continue
                                end
                                Overlay.FilterDescendantsInstances = {v.Character}
                                for _, part in workspace:GetPartBoundsInBox(v.RootPart.CFrame, Vector3.new(4, 4, 4), Overlay) do
                                    firetouchinterest(interest.Parent, part, 1)
                                    firetouchinterest(interest.Parent, part, 0)
                                end
                            end
                        end
                    end
                    for i, v in Boxes do
                        v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
                        if v.Adornee then
                            v.Color3 = Color3.fromHSV(0.6, 0.6, 0.6)
                            v.Transparency = 0.5
                        end
                    end
                    for i, v in Particles do
                        v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
                        v.Parent = attacked[i] and gameCamera or nil
                    end
                    -- if Face.Enabled and attacked[1] then
                    -- 	local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
                    -- 	entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.01, vec.Z))
                    -- end
                    task.wait()
                until not Killaura.Enabled
            else
                for _, v in Boxes do
                    v.Adornee = nil
                end
            end
        end
    })
    CPS = Killaura:AddSlider({
        Name = 'Attacks per Second',
        Min = 1,
        Max = 20,
        Default = 10,
    })
    SwingRange = Killaura:AddSlider({
        Name = 'Swing range',
        Min = 1,
        Max = 30,
        Default = 13,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    AttackRange = Killaura:AddSlider({
        Name = 'Attack range',
        Min = 1,
        Max = 30,
        Default = 13,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    AngleSlider = Killaura:AddSlider({
        Name = 'Max angle',
        Min = 1,
        Max = 360,
        Default = 90
    })
    Max = Killaura:AddSlider({
        Name = 'Max targets',
        Min = 1,
        Max = 10,
        Default = 10
    })
    Mouse = Killaura:AddToggle({
        Name = 'Require Click'
    })
    Killaura:AddToggle({
        Name = 'Show target',
        Function = function(callback)
            if callback then
                for i = 1, 10 do
                    local box = Instance.new('BoxHandleAdornment')
                    box.Adornee = nil
                    box.AlwaysOnTop = true
                    box.Size = Vector3.new(3, 5, 3)
                    box.CFrame = CFrame.new(0, - 0.5, 0)
                    box.ZIndex = 0
                    box.Parent = Modern.MainScreenGui
                    Boxes[i] = box
                end
            else
                for _, v in Boxes do
                    v:Destroy()
                end
                table.clear(Boxes)
            end
        end
    })
    -- Face = Killaura:AddToggle({Name = 'Face target'})
end)
local SpeedMethods
local SpeedMethodList = {'Velocity'}
SpeedMethods = {
    Velocity = function(options, moveDirection)
        local root = entitylib.character.RootPart
        root.AssemblyLinearVelocity = (moveDirection * options.Value.Value) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
    end,
    Impulse = function(options, moveDirection)
        local root = entitylib.character.RootPart
        local diff = ((moveDirection * options.Value.Value) - root.AssemblyLinearVelocity) * Vector3.new(1, 0, 1)
        if diff.Magnitude > (moveDirection == Vector3.zero and 10 or 2) then
            root:ApplyImpulse(diff * root.AssemblyMass)
        end
    end,
    CFrame = function(options, moveDirection, dt)
        local root = entitylib.character.RootPart
        local dest = (moveDirection * math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
        if options.WallCheck.Enabled then
            options.rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
            options.rayCheck.CollisionGroup = root.CollisionGroup
            local ray = workspace:Raycast(root.Position, dest, options.rayCheck)
            if ray then
                dest = ((ray.Position + ray.Normal) - root.Position)
            end
        end
        root.CFrame += dest
    end,
    TP = function(options, moveDirection)
        if options.TPTiming < tick() then
            options.TPTiming = tick() + options.TPFrequency.Value
            SpeedMethods.CFrame(options, moveDirection, 1)
        end
    end,
    WalkSpeed = function(options)
        if not options.WalkSpeed then
            options.WalkSpeed = entitylib.character.Humanoid.WalkSpeed
        end
        entitylib.character.Humanoid.WalkSpeed = options.Value.Value
    end,
    Pulse = function(options, moveDirection)
        local root = entitylib.character.RootPart
        local dt = math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0)
        dt = dt * (1 - math.min((tick() % (options.PulseLength.Value + options.PulseDelay.Value)) / options.PulseLength.Value, 1))
        root.AssemblyLinearVelocity = (moveDirection * (entitylib.character.Humanoid.WalkSpeed + dt)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
    end
}
for name in SpeedMethods do
    if not table.find(SpeedMethodList, name) then
        table.insert(SpeedMethodList, name)
    end
end
local Fly
run(function()
    local Options = {
        TPTiming = tick()
    }
    local Mode
    local FloatMode
    local State
    local MoveMethod
    local Keys
    local VerticalValue
    local BounceLength
    local BounceDelay
    local FloatTPGround
    local FloatTPAir
    local CustomProperties
    local WallCheck
    local PlatformStanding
    local Platform, YLevel, OldYLevel
    local w, s, a, d, up, down = 0, 0, 0, 0, 0, 0
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    Options.rayCheck = rayCheck
    local Functions
    Functions = {
        Velocity = function()
            entitylib.character.RootPart.Velocity = (entitylib.character.RootPart.Velocity * Vector3.new(1, 0, 1)) + Vector3.new(0, 2.25 + ((up + down) * VerticalValue.Value), 0)
        end,
        Impulse = function(options, moveDirection)
            local root = entitylib.character.RootPart
            local diff = (Vector3.new(0, 2.25 + ((up + down) * VerticalValue.Value), 0) - root.AssemblyLinearVelocity) * Vector3.new(0, 1, 0)
            if diff.Magnitude > 2 then
                root:ApplyImpulse(diff * root.AssemblyMass)
            end
        end,
        CFrame = function(dt)
            local root = entitylib.character.RootPart
            if not YLevel then
                YLevel = root.Position.Y
            end
            YLevel = YLevel + ((up + down) * VerticalValue.Value * dt)
            if WallCheck.Enabled then
                rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
                rayCheck.CollisionGroup = root.CollisionGroup
                local ray = workspace:Raycast(root.Position, Vector3.new(0, YLevel - root.Position.Y, 0), rayCheck)
                if ray then
                    YLevel = ray.Position.Y + entitylib.character.HipHeight
                end
            end
            root.Velocity *= Vector3.new(1, 0, 1)
            root.CFrame += Vector3.new(0, YLevel - root.Position.Y, 0)
        end,
        Bounce = function()
            Functions.Velocity()
            entitylib.character.RootPart.Velocity += Vector3.new(0, ((tick() % BounceDelay.Value) / BounceDelay.Value > 0.5 and 1 or - 1) * BounceLength.Value, 0)
        end,
        Floor = function()
            Platform.CFrame = down ~= 0 and CFrame.identity or entitylib.character.RootPart.CFrame + Vector3.new(0, - (entitylib.character.HipHeight + 0.5), 0)
        end,
        TP = function(dt)
            Functions.CFrame(dt)
            if tick() % (FloatTPAir.Value + FloatTPGround.Value) > FloatTPAir.Value then
                OldYLevel = OldYLevel or YLevel
                rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
                rayCheck.CollisionGroup = entitylib.character.RootPart.CollisionGroup
                local ray = workspace:Raycast(entitylib.character.RootPart.Position, Vector3.new(0, - 1000, 0), rayCheck)
                if ray then
                    YLevel = ray.Position.Y + entitylib.character.HipHeight
                end
            else
                if OldYLevel then
                    YLevel = OldYLevel
                    OldYLevel = nil
                end
            end
        end,
        Jump = function(dt)
            local root = entitylib.character.RootPart
            if not YLevel then
                YLevel = root.Position.Y
            end
            YLevel = YLevel + ((up + down) * VerticalValue.Value * dt)
            if root.Position.Y < YLevel then
                entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    }
    Fly = Modern.Catalogs.Movement:AddModule({
        Name = 'Fly',
        Function = function(callback)
            if Platform then
                Platform.Parent = callback and gameCamera or nil
            end
            frictionTable.Fly = callback and CustomProperties.Enabled or nil
            updateVelocity()
            if callback then
                Fly:Clean(RunService.PreSimulation:Connect(function(dt)
                    if entitylib.isAlive then
                        if PlatformStanding.Enabled then
                            entitylib.character.Humanoid.PlatformStand = true
                            entitylib.character.RootPart.RotVelocity = Vector3.zero
                            entitylib.character.RootPart.CFrame = CFrame.lookAlong(entitylib.character.RootPart.CFrame.Position, gameCamera.CFrame.LookVector)
                        end
                        if State.Value ~= 'None' then
                            entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType[State.Value])
                        end
                        SpeedMethods[Mode.Value](Options, TargetStrafeVector or MoveMethod.Value == 'Direct' and calculateMoveVector(Vector3.new(a + d, 0, w + s)) or entitylib.character.Humanoid.MoveDirection, dt)
                        Functions[FloatMode.Value](dt)
                    else
                        YLevel = nil
                        OldYLevel = nil
                    end
                end))
                w, s, a, d = UserInputService:IsKeyDown(Enum.KeyCode.W) and - 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.A) and - 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
                up, down = 0, 0
                for _, v in {'InputBegan', 'InputEnded'} do
                    Fly:Clean(UserInputService[v]:Connect(function(input)
                        if not UserInputService:GetFocusedTextBox() then
                            local divided = Keys.Value:split('/')
                            if input.KeyCode == Enum.KeyCode.W then
                                w = v == 'InputBegan' and - 1 or 0
                            elseif input.KeyCode == Enum.KeyCode.S then
                                s = v == 'InputBegan' and 1 or 0
                            elseif input.KeyCode == Enum.KeyCode.A then
                                a = v == 'InputBegan' and - 1 or 0
                            elseif input.KeyCode == Enum.KeyCode.D then
                                d = v == 'InputBegan' and 1 or 0
                            elseif input.KeyCode == Enum.KeyCode[divided[1]] then
                                up = v == 'InputBegan' and 1 or 0
                            elseif input.KeyCode == Enum.KeyCode[divided[2]] then
                                down = v == 'InputBegan' and - 1 or 0
                            end
                        end
                    end))
                end
                if UserInputService.TouchEnabled then
                    pcall(function()
                        local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
                        Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
                            up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
                        end))
                    end)
                end
            else
                YLevel, OldYLevel = nil, nil
                if entitylib.isAlive and PlatformStanding.Enabled then
                    entitylib.character.Humanoid.PlatformStand = false
                end
            end
        end,
        ExtraText = function()
            return Mode.Value
        end
    })
    Mode = Fly:AddDropdown({
        Name = 'Speed Mode',
        List = SpeedMethodList,
        Function = function(val)
            WallCheck.Frame.Visible = FloatMode.Value == 'CFrame' or FloatMode.Value == 'TP' or val == 'CFrame' or val == 'TP'
            Options.TPFrequency.Frame.Visible = val == 'TP'
            Options.PulseLength.Frame.Visible = val == 'Pulse'
            Options.PulseDelay.Frame.Visible = val == 'Pulse'
            if Fly.Enabled then
                Fly:Toggle()
                Fly:Toggle()
            end
        end
    })
    FloatMode = Fly:AddDropdown({
        Name = 'Float Mode',
        List = {'Velocity', 'Impulse', 'CFrame', 'Bounce', 'Floor', 'Jump', 'TP'},
        Function = function(val)
            WallCheck.Frame.Visible = Mode.Value == 'CFrame' or Mode.Value == 'TP' or val == 'CFrame' or val == 'TP'
            BounceLength.Frame.Visible = val == 'Bounce'
            BounceDelay.Frame.Visible = val == 'Bounce'
            VerticalValue.Frame.Visible = val ~= 'Floor'
            FloatTPGround.Frame.Visible = val == 'TP'
            FloatTPAir.Frame.Visible = val == 'TP'
            if Platform then
                Platform:Destroy()
                Platform = nil
            end
            if val == 'Floor' then
                Platform = Instance.new('Part')
                Platform.CanQuery = false
                Platform.Anchored = true
                Platform.Size = Vector3.one
                Platform.Transparency = 1
                Platform.Parent = Fly.Enabled and gameCamera or nil
            end
        end
    })
    local states = {'None'}
    for _, v in Enum.HumanoidStateType:GetEnumItems() do
        if v.Name ~= 'Dead' and v.Name ~= 'None' then
            table.insert(states, v.Name)
        end
    end
    State = Fly:AddDropdown({
        Name = 'Humanoid State',
        List = states
    })
    MoveMethod = Fly:AddDropdown({
        Name = 'Move Mode',
        List = {'MoveDirection', 'Direct'}
    })
    Keys = Fly:AddDropdown({
        Name = 'Keys',
        List = {'Space/LeftControl', 'Space/LeftShift', 'E/Q', 'Space/Q', 'ButtonA/ButtonL2'}
    })
    Options.Value = Fly:AddSlider({
        Name = 'Speed',
        Min = 1,
        Max = 150,
        Default = 50,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    VerticalValue = Fly:AddSlider({
        Name = 'Vertical Speed',
        Min = 1,
        Max = 150,
        Default = 50,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    Options.TPFrequency = Fly:AddSlider({
        Name = 'TP Frequency',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    Options.PulseLength = Fly:AddSlider({
        Name = 'Pulse Length',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    Options.PulseDelay = Fly:AddSlider({
        Name = 'Pulse Delay',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    BounceLength = Fly:AddSlider({
        Name = 'Bounce Length',
        Min = 0,
        Max = 30,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    BounceDelay = Fly:AddSlider({
        Name = 'Bounce Delay',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    FloatTPGround = Fly:AddSlider({
        Name = 'Ground',
        Min = 0,
        Max = 1,
        Decimal = 10,
        Default = 0.1,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    FloatTPAir = Fly:AddSlider({
        Name = 'Air',
        Min = 0,
        Max = 5,
        Decimal = 10,
        Default = 2,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    WallCheck = Fly:AddToggle({
        Name = 'Wall Check',
        Default = true,
        Darker = true,
        Visible = false
    })
    Options.WallCheck = WallCheck
    PlatformStanding = Fly:AddToggle({
        Name = 'PlatformStand',
        Function = function(callback)
            if Fly.Enabled then
                entitylib.character.Humanoid.PlatformStand = callback
            end
        end
    })
    CustomProperties = Fly:AddToggle({
        Name = 'Custom Properties',
        Function = function()
            if Fly.Enabled then
                Fly:Toggle()
                Fly:Toggle()
            end
        end,
        Default = true
    })
end)
run(function()
    local Speed
    local Mode
    local Options
    local AutoJump
    local AutoJumpCustom
    local AutoJumpValue
    local w, s, a, d = 0, 0, 0, 0
    Speed = Modern.Catalogs.Movement:AddModule({
        Name = 'Speed',
        Function = function(callback)
            frictionTable.Speed = callback and CustomProperties.Enabled or nil
            updateVelocity()
            if callback then
                Speed:Clean(RunService.PreSimulation:Connect(function(dt)
                    if entitylib.isAlive and not Fly.Enabled then
                        local state = entitylib.character.Humanoid:GetState()
                        if state == Enum.HumanoidStateType.Climbing then
                            return
                        end
                        local movevec = TargetStrafeVector or Options.MoveMethod.Value == 'Direct' and calculateMoveVector(Vector3.new(a + d, 0, w + s)) or entitylib.character.Humanoid.MoveDirection
                        local a = (function(options, moveDirection, dt)
                            local root = entitylib.character.RootPart
                            local dest = (moveDirection * math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
                            if options.WallCheck.Enabled then
                                options.rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
                                options.rayCheck.CollisionGroup = root.CollisionGroup
                                local ray = workspace:Raycast(root.Position, dest, options.rayCheck)
                                if ray then
                                    dest = ((ray.Position + ray.Normal) - root.Position)
                                end
                            end
                            root.CFrame += dest
                        end)(Options, movevec, dt)
                        if AutoJump.Enabled and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and movevec ~= Vector3.zero then
                            if AutoJumpCustom.Enabled then
                                local velocity = entitylib.character.RootPart.Velocity * Vector3.new(1, 0, 1)
                                entitylib.character.RootPart.Velocity = Vector3.new(velocity.X, AutoJumpValue.Value, velocity.Z)
                            else
                                entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                    end
                end))
                w, s, a, d = UserInputService:IsKeyDown(Enum.KeyCode.W) and - 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.A) and - 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
                for _, v in {'InputBegan', 'InputEnded'} do
                    Speed:Clean(UserInputService[v]:Connect(function(input)
                        if not UserInputService:GetFocusedTextBox() then
                            if input.KeyCode == Enum.KeyCode.W then
                                w = v == 'InputBegan' and - 1 or 0
                            elseif input.KeyCode == Enum.KeyCode.S then
                                s = v == 'InputBegan' and 1 or 0
                            elseif input.KeyCode == Enum.KeyCode.A then
                                a = v == 'InputBegan' and - 1 or 0
                            elseif input.KeyCode == Enum.KeyCode.D then
                                d = v == 'InputBegan' and 1 or 0
                            end
                        end
                    end))
                end
            else
                if Options.WalkSpeed and entitylib.isAlive then
                    entitylib.character.Humanoid.WalkSpeed = Options.WalkSpeed
                end
                Options.WalkSpeed = nil
            end
        end,
        ExtraText = function()
            return Mode.Value
        end
    })
    Mode = Speed:AddDropdown({
        Name = 'Mode',
        List = SpeedMethodList,
        Function = function(val)
            Options.WallCheck.Frame.Visible = val == 'CFrame' or val == 'TP'
            Options.TPFrequency.Frame.Visible = val == 'TP'
            Options.PulseLength.Frame.Visible = val == 'Pulse'
            Options.PulseDelay.Frame.Visible = val == 'Pulse'
            if Speed.Enabled then
                Speed:Toggle()
                Speed:Toggle()
            end
        end
    })
    Options = {
        MoveMethod = Speed:AddDropdown({
            Name = 'Move Mode',
            List = {'MoveDirection', 'Direct'}
        }),
        Value = Speed:AddSlider({
            Name = 'Speed',
            Min = 1,
            Max = 150,
            Default = 50,
            Suffix = function(val)
                return val == 1 and 'stud' or 'studs'
            end
        }),
        TPFrequency = Speed:AddSlider({
            Name = 'TP Frequency',
            Min = 0,
            Max = 1,
            Decimal = 100,
            Darker = true,
            Visible = false,
            Suffix = function(val)
                return val == 1 and 'second' or 'seconds'
            end
        }),
        PulseLength = Speed:AddSlider({
            Name = 'Pulse Length',
            Min = 0,
            Max = 1,
            Decimal = 100,
            Darker = true,
            Visible = false,
            Suffix = function(val)
                return val == 1 and 'second' or 'seconds'
            end
        }),
        PulseDelay = Speed:AddSlider({
            Name = 'Pulse Delay',
            Min = 0,
            Max = 1,
            Decimal = 100,
            Darker = true,
            Visible = false,
            Suffix = function(val)
                return val == 1 and 'second' or 'seconds'
            end
        }),
        WallCheck = Speed:AddToggle({
            Name = 'Wall Check',
            Default = true,
            Darker = true,
            Visible = false
        }),
        TPTiming = tick(),
        rayCheck = RaycastParams.new()
    }
    Options.rayCheck.RespectCanCollide = true
    CustomProperties = Speed:AddToggle({
        Name = 'Custom Properties',
        Function = function()
            if Speed.Enabled then
                Speed:Toggle()
                Speed:Toggle()
            end
        end,
        Default = true
    })
    AutoJump = Speed:AddToggle({
        Name = 'AutoJump',
        Function = function(callback)
            AutoJumpCustom.Frame.Visible = callback
        end
    })
    AutoJumpCustom = Speed:AddToggle({
        Name = 'Custom Jump',
        Function = function(callback)
            AutoJumpValue.Frame.Visible = callback
        end,
        Darker = true,
        Visible = false
    })
    AutoJumpValue = Speed:AddSlider({
        Name = 'Jump Power',
        Min = 1,
        Max = 50,
        Default = 30,
        Darker = true,
        Visible = false
    })
end)
run(function()
    local NameTags
    local Targets
    local Color
    local Background
    local DisplayName
    local Health
    local Distance
    local DrawingToggle
    local Scale
    local FontOption
    local GlowEffect
    local Teammates
    local DistanceCheck
    local DistanceLimit
    local Strings, Sizes, Reference, Gradients = {}, {}, {}, {}
    local Folder = Instance.new('Folder')
    Folder.Parent = Modern.MainScreenGui
    local methodused
    local Added = {
        Normal = function(ent)
            if ent.NPC then
                return
            end
            if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
                return
            end
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
            if Health.Enabled then
                local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                Strings[ent] = Strings[ent] .. ' <font color="rgb(' .. tostring(math.floor(healthColor.R * 255)) .. ',' .. tostring(math.floor(healthColor.G * 255)) .. ',' .. tostring(math.floor(healthColor.B * 255)) .. ')">' .. math.round(ent.Health) .. '</font>'
            end
            if Distance.Enabled then
                Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> ' .. Strings[ent]
            end
            local nametag = Instance.new('TextLabel')
            nametag.TextSize = 14 * Scale.Value
            nametag.FontFace = Modern.Libraries.uipallet.Font
            nametag.ZIndex = - 1
            local ize = getfontsize(removeTags(Strings[ent]), nametag.TextSize, Modern.Libraries.uipallet.Font, Vector2.new(100000, 100000))
            nametag.Name = ent.Player and ent.Player.Name or ent.Character.Name
            nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
            nametag.AnchorPoint = Vector2.new(0.5, 1)
            nametag.BackgroundColor3 = Color3.new()
            nametag.BackgroundTransparency = Background.Value
            nametag.BorderSizePixel = 0
            if GlowEffect.Enabled then
                addGradient(addRoundedShadow(nametag))
            end
            addCorner(nametag, UDim.new(12, 0))
            nametag.Visible = false
            nametag.Text = Strings[ent]
            if entitylib.getEntityColor(ent) then
                nametag.TextColor3 = entitylib.getEntityColor(ent)
                if Gradients[ent] then
                    Gradients[ent].Enabled = false
                end
            else
                nametag.TextColor3 = Color3.fromRGB(255, 255, 255)
                Gradients[ent] = addGradient(nametag)
            end
            nametag.RichText = true
            nametag.Parent = Folder
            Reference[ent] = nametag
        end,
        Drawing = function(ent)
            -- if not Targets.Players.Enabled and ent.Player then return end
            if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
                return
            end
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            local nametag = {}
            nametag.BG = Drawing.new('Square')
            nametag.BG.Filled = true
            nametag.BG.Transparency = 1 - Background.Value
            nametag.BG.Color = Color3.new()
            nametag.BG.ZIndex = 1
            nametag.Text = Drawing.new('Text')
            nametag.Text.Size = 15 * Scale.Value
            nametag.Text.Font = 0
            nametag.Text.ZIndex = 2
            Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
            if Health.Enabled then
                Strings[ent] = Strings[ent] .. ' ' .. math.round(ent.Health)
            end
            if Distance.Enabled then
                Strings[ent] = '[%s] ' .. Strings[ent]
            end
            nametag.Text.Text = Strings[ent]
            nametag.Text.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
            Reference[ent] = nametag
        end
    }
    local Removed = {
        Normal = function(ent)
            local v = Reference[ent]
            if v then
                if Modern.ThreadFix then
                    setthreadidentity(8)
                end
                Reference[ent] = nil
                Strings[ent] = nil
                Sizes[ent] = nil
                v:Destroy()
            end
        end,
        Drawing = function(ent)
            local v = Reference[ent]
            if v then
                if Modern.ThreadFix then
                    setthreadidentity(8)
                end
                Reference[ent] = nil
                Strings[ent] = nil
                Sizes[ent] = nil
                for _, v2 in v do
                    pcall(function()
                        v2.Visible = false
                        v2:Remove()
                    end)
                end
            end
        end
    }
    local Updated = {
        Normal = function(ent)
            local nametag = Reference[ent]
            if nametag then
                if Modern.ThreadFix then
                    setthreadidentity(8)
                end
                Sizes[ent] = nil
                Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                if Health.Enabled then
                    local color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                    Strings[ent] = Strings[ent] .. ' <font color="rgb(' .. tostring(math.floor(color.R * 255)) .. ',' .. tostring(math.floor(color.G * 255)) .. ',' .. tostring(math.floor(color.B * 255)) .. ')">' .. math.round(ent.Health) .. '</font>'
                end
                if Distance.Enabled then
                    Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> ' .. Strings[ent]
                end
                local ize = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
                nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
                nametag.Text = Strings[ent]
            end
        end,
        Drawing = function(ent)
            local nametag = Reference[ent]
            if nametag then
                if Modern.ThreadFix then
                    setthreadidentity(8)
                end
                Sizes[ent] = nil
                Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                if Health.Enabled then
                    Strings[ent] = Strings[ent] .. ' ' .. math.round(ent.Health)
                end
                if Distance.Enabled then
                    Strings[ent] = '[%s] ' .. Strings[ent]
                    nametag.Text.Text = entitylib.isAlive and string.format(Strings[ent], math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)) or Strings[ent]
                else
                    nametag.Text.Text = Strings[ent]
                end
                nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
                nametag.Text.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            end
        end
    }
    local ColorFunc = {
        Normal = function(hue, sat, val)
            local color = Color3.fromHSV(hue, sat, val)
            for i, v in Reference do
                v.TextColor3 = entitylib.getEntityColor(i) or color
            end
        end,
        Drawing = function(hue, sat, val)
            local color = Color3.fromHSV(hue, sat, val)
            for i, v in Reference do
                v.Text.Color = entitylib.getEntityColor(i) or color
            end
        end
    }
    local Loop = {
        Normal = function()
            for ent, nametag in Reference do
                if DistanceCheck.Enabled then
                    local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
                    if distance > DistanceLimit.Value then
                        nametag.Visible = false
                        continue
                    end
                end
                local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
                nametag.Visible = headVis
                if not headVis then
                    continue
                end
                if Distance.Enabled then
                    local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
                    if Sizes[ent] ~= mag then
                        nametag.Text = string.format(Strings[ent], mag)
                        local ize = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
                        nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
                        Sizes[ent] = mag
                    end
                end
                nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
            end
        end,
        Drawing = function()
            for ent, nametag in Reference do
                if DistanceCheck.Enabled then
                    local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
                    if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
                        nametag.Text.Visible = false
                        nametag.BG.Visible = false
                        continue
                    end
                end
                local headPos, headVis = gameCamera:WorldToScreenPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
                nametag.Text.Visible = headVis
                nametag.BG.Visible = headVis
                if not headVis then
                    continue
                end
                if Distance.Enabled then
                    local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
                    if Sizes[ent] ~= mag then
                        nametag.Text.Text = string.format(Strings[ent], mag)
                        nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
                        Sizes[ent] = mag
                    end
                end
                nametag.BG.Position = Vector2.new(headPos.X - (nametag.BG.Size.X / 2), headPos.Y + (nametag.BG.Size.Y / 2))
                nametag.Text.Position = nametag.BG.Position + Vector2.new(4, 2.5)
            end
        end
    }
    NameTags = Modern.Catalogs.Render:AddModule({
        Name = 'NameTags',
        Function = function(callback)
            if callback then
                methodused = DrawingToggle.Enabled and 'Drawing' or 'Normal'
                if Removed[methodused] then
                    NameTags:Clean(entitylib.Events.EntityRemoved:Connect(Removed[methodused]))
                end
                if Added[methodused] then
                    for _, v in entitylib.List do
                        if Reference[v] then
                            Removed[methodused](v)
                        end
                        Added[methodused](v)
                    end
                    NameTags:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
                        if Reference[ent] then
                            Removed[methodused](ent)
                        end
                        Added[methodused](ent)
                    end))
                end
                if Updated[methodused] then
                    NameTags:Clean(entitylib.Events.EntityUpdated:Connect(Updated[methodused]))
                    for _, v in entitylib.List do
                        Updated[methodused](v)
                    end
                end
                if Loop[methodused] then
                    NameTags:Clean(RunService.RenderStepped:Connect(Loop[methodused]))
                end
            else
                if Removed[methodused] then
                    for i in Reference do
                        Removed[methodused](i)
                    end
                end
            end
        end
    })
    Scale = NameTags:AddSlider({
        Name = 'Scale',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end,
        Default = 1,
        Min = 0.1,
        Max = 1.5,
        Decimal = 10
    })
    Background = NameTags:AddSlider({
        Name = 'Transparency',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end,
        Default = 0.5,
        Min = 0,
        Max = 1,
        Decimal = 10
    })
    GlowEffect = NameTags:AddToggle({
        Name = 'Glow Effect',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end,
        Default = true
    })
    Health = NameTags:AddToggle({
        Name = 'Health',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end
    })
    Distance = NameTags:AddToggle({
        Name = 'Distance',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end
    })
    DisplayName = NameTags:AddToggle({
        Name = 'Use Displayname',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end,
        Default = true
    })
    Teammates = NameTags:AddToggle({
        Name = 'Priority Only',
        Function = function()
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end,
        Default = true
    })
    DrawingToggle = NameTags:AddToggle({
        Name = 'Drawing',
        Function = function(callback)
            GlowEffect.Frame.Visible = not callback
            if NameTags.Enabled then
                NameTags:Toggle()
                NameTags:Toggle()
            end
        end
    })
    DistanceCheck = NameTags:AddToggle({
        Name = 'Distance Check',
        Function = function(callback)
            DistanceLimit.Frame.Visible = callback
        end
    })
    DistanceLimit = NameTags:AddSlider({
        Name = 'Player Distance',
        Min = 0,
        Max = 256,
        Default = 64,
        Darker = true,
        Visible = false
    })
end)
run(function()
    local Timer
    local Value
    Timer = Modern.Catalogs.Player:AddModule({
        Name = 'Timer',
        Function = function(callback)
            if callback then
                setfflag('SimEnableStepPhysics', 'True')
                setfflag('SimEnableStepPhysicsSelective', 'True')
                Timer:Clean(RunService.RenderStepped:Connect(function(dt)
                    if Value.Value > 1 then
                        RunService:Pause()
                        workspace:StepPhysics(dt * (Value.Value - 1), {entitylib.character.RootPart})
                        RunService:Run()
                    end
                end))
            end
        end
    })
    Value = Timer:AddSlider({
        Name = 'Value',
        Min = 1,
        Max = 3,
        Decimal = 10
    })
end)
local visited, attempted, tpSwitch = {}, {}, false
local cacheExpire, cache = tick()
local function serverHop(pointer, filter)
    visited = shared.Modernserverhoplist and shared.Modernserverhoplist:split('/') or {}
    if not table.find(visited, game.JobId) then
        table.insert(visited, game.JobId)
    end
    if not pointer then
        warn('Searching for an available server.')
    end
    local suc, httpdata = pcall(function()
        return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=' .. (filter == 'Ascending' and 1 or 2) .. '&excludeFullGames=true&limit=100' .. (pointer and '&cursor=' .. pointer or '')) or cache
    end)
    local data = suc and httpService:JSONDecode(httpdata) or nil
    if data and data.data then
        for _, v in data.data do
            if tonumber(v.playing) < Players.MaxPlayers and not table.find(visited, v.id) and not table.find(attempted, v.id) then
                cacheExpire, cache = tick() + 60, httpdata
                table.insert(attempted, v.id)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
                return
            end
        end
        if data.nextPageCursor then
            serverHop(data.nextPageCursor, filter)
        else
        end
    else
    end
end
run(function()
    local StaffDetector
    local Mode
    local Profile
    local Users
    local Group
    local Role
    local function getRole(plr, id)
        local suc, res
        for _ = 1, 3 do
            suc, res = pcall(function()
                return plr:GetRankInGroup(id)
            end)
            if suc then
                break
            end
        end
        return suc and res or 0
    end
    local function getLowestStaffRole(roles)
        local highest = math.huge
        for _, v in roles do
            local low = v.Name:lower()
            if (low:find('admin') or low:find('mod') or low:find('dev')) and v.Rank < highest then
                highest = v.Rank
            end
        end
        return highest
    end
    local function playerAdded(plr)
        if not Modern.Loaded then
            repeat
                task.wait()
            until Modern.Loaded
        end
        if getRole(plr, 0) >= 1 then
            if Mode.Value == 'Uninject' then
                task.spawn(function()
                    Modern:Uninject()
                end)
                game:GetService('StarterGui'):SetCore('SendNotification', {
                    Title = 'StaffDetector',
                    Text = 'Staff Detected\n' .. plr.Name,
                    Duration = 60,
                })
            elseif Mode.Value == 'ServerHop' then
                serverHop()
            end
        end
    end
    StaffDetector = Modern.Catalogs.Player:AddModule({
        Name = 'StaffDetector',
        Function = function(callback)
            if callback then
                local placeinfo = MarketplaceService:GetProductInfo(game.PlaceId)
                if placeinfo.Creator.CreatorType ~= 'Group' then
                    local desc = placeinfo.Description:split('\n')
                    for _, str in desc do
                        local _, begin = str:find('roblox.com/groups/')
                        if begin then
                            local endof = str:find('/', begin + 1)
                            placeinfo = {
                                Creator = {
                                    CreatorType = 'Group',
                                    CreatorTargetId = str:sub(begin + 1, endof - 1)
                                }
                            }
                        end
                    end
                    if placeinfo.Creator.CreatorType ~= 'Group' then
                        return
                    end
                    local groupinfo = GroupService:GetGroupInfoAsync(placeinfo.Creator.CreatorTargetId)
                    Group:SetValue(placeinfo.Creator.CreatorTargetId)
                    Role:SetValue(getLowestStaffRole(groupinfo.Roles))
                end
                StaffDetector:Clean(Players.PlayerAdded:Connect(playerAdded))
                for _, v in Players:GetPlayers() do
                    task.spawn(playerAdded, v)
                end
            end
        end
    })
    Mode = StaffDetector:AddDropdown({
        Name = 'Mode',
        List = {'Uninject', 'ServerHop', 'Notify'}
    })
end)
run(function()
    local Freecam
    local Value
    local randomkey, module, old = HttpService:GenerateGUID(false)
    Freecam = Modern.Catalogs.Render:AddModule({
        Name = 'Freecam',
        Function = function(callback)
            if callback then
                repeat
                    task.wait(0.1)
                    for _, v in getconnections(gameCamera:GetPropertyChangedSignal('CameraType')) do
                        if v.Function then
                            module = debug.getupvalue(v.Function, 1)
                        end
                    end
                until module or not Freecam.Enabled
                if module and module.activeCameraController and Freecam.Enabled then
                    old = module.activeCameraController.GetSubjectPosition
                    local camPos = old(module.activeCameraController) or Vector3.zero
                    module.activeCameraController.GetSubjectPosition = function()
                        return camPos
                    end Freecam:Clean(RunService.PreSimulation:Connect(function(dt)
                        if not UserInputService:GetFocusedTextBox() then
                            local forward = (UserInputService:IsKeyDown(Enum.KeyCode.W) and - 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
                            local side = (UserInputService:IsKeyDown(Enum.KeyCode.A) and - 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
                            local up = (UserInputService:IsKeyDown(Enum.KeyCode.Q) and - 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0)
                            dt = dt * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 0.25 or 1)
                            camPos = (CFrame.lookAlong(camPos, gameCamera.CFrame.LookVector) * CFrame.new(Vector3.new(side, up, forward) * (Value.Value * dt))).Position
                        end
                    end))
                    ContextService:BindActionAtPriority('FreecamKeyboard' .. randomkey, function()
                        return Enum.ContextActionResult.Sink
                    end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Up, Enum.KeyCode.Down)
                end
            else
                pcall(function()
                    ContextService:UnbindAction('FreecamKeyboard' .. randomkey)
                end)
                if module and old then
                    module.activeCameraController.GetSubjectPosition = old
                    module = nil
                    old = nil
                end
            end
        end
    })
    Value = Freecam:AddSlider({
        Name = 'Speed',
        Min = 1,
        Max = 150,
        Default = 50,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
end)
run(function()
    local Chams
    local Targets
    local Mode
    local FillColor
    local OutlineColor
    local FillTransparency
    local OutlineTransparency
    local Teammates
    local Walls
    local Reference = {}
    local Folder = Instance.new('Folder')
    Folder.Parent = Modern.MainScreenGui
    local function Added(ent)
        if not ent.Player then
            return
        end
        if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
            return
        end
        if Modern.ThreadFix then
            setthreadidentity(8)
        end
        if Mode.Value == 'Highlight' then
            local cham = Instance.new('Highlight')
            cham.Adornee = ent.Character
            cham.DepthMode = Enum.HighlightDepthMode[Walls.Enabled and 'AlwaysOnTop' or 'Occluded']
            cham.FillColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            cham.OutlineColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            cham.FillTransparency = FillTransparency.Value
            cham.OutlineTransparency = OutlineTransparency.Value
            cham.Parent = Folder
            Reference[ent] = cham
        else
            local chams = {}
            for _, v in ent.Character:GetChildren() do
                if v:IsA('BasePart') and (ent.NPC or v.Name:find('Arm') or v.Name:find('Leg') or v.Name:find('Hand') or v.Name:find('Feet') or v.Name:find('Torso') or v.Name == 'Head') then
                    local box = Instance.new(v.Name == 'Head' and 'SphereHandleAdornment' or 'BoxHandleAdornment')
                    if v.Name == 'Head' then
                        box.Radius = 0.75
                    else
                        box.Size = v.Size
                    end
                    box.AlwaysOnTop = Walls.Enabled
                    box.Adornee = v
                    box.ZIndex = 0
                    box.Transparency = FillTransparency.Value
                    box.Color3 = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
                    box.Parent = Folder
                    table.insert(chams, box)
                end
            end
            Reference[ent] = chams
        end
    end
    local function Removed(ent)
        if Reference[ent] then
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            if type(Reference[ent]) == 'table' then
                for _, v in Reference[ent] do
                    v:Destroy()
                end
                table.clear(Reference[ent])
            else
                Reference[ent]:Destroy()
            end
            Reference[ent] = nil
        end
    end
    local function Looped()
        for ent, ref in next, Reference do
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            if type(ref) == 'table' then
                for _, v in ref do
                    if v:IsA('SphereHandleAdornment') or v:IsA('BoxHandleAdornment') then
                        v.Color3 = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
                    end
                end
            else
                ref.FillColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
                ref.OutlineColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            end
        end
    end
    Chams = Modern.Catalogs.Render:AddModule({
        Name = 'Chams',
        Function = function(callback)
            if callback then
                Chams:Clean(entitylib.Events.EntityRemoved:Connect(Removed))
                Chams:Clean(RunService.RenderStepped:Connect(Looped))
                Chams:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
                    if Reference[ent] then
                        Removed(ent)
                    end
                    Added(ent)
                end))
                for _, v in entitylib.List do
                    if Reference[v] then
                        Removed(v)
                    end
                    Added(v)
                end
            else
                for i in Reference do
                    Removed(i)
                end
            end
        end
    })
    Mode = Chams:AddDropdown({
        Name = 'Mode',
        List = {'Highlight', 'BoxHandles'},
        Function = function(val)
            OutlineTransparency.Frame.Visible = val == 'Highlight'
            if Chams.Enabled then
                Chams:Toggle()
                Chams:Toggle()
            end
        end
    })
    FillTransparency = Chams:AddSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Default = 0.5,
        Function = function(val)
            for _, v in Reference do
                if type(v) == 'table' then
                    for _, v2 in v do
                        v2.Transparency = val
                    end
                else
                    v.FillTransparency = val
                end
            end
        end,
        Decimal = 10
    })
    OutlineTransparency = Chams:AddSlider({
        Name = 'Outline Transparency',
        Min = 0,
        Max = 1,
        Default = 0.5,
        Function = function(val)
            for _, v in Reference do
                if type(v) ~= 'table' then
                    v.OutlineTransparency = val
                end
            end
        end,
        Decimal = 10,
        Darker = true
    })
    Walls = Chams:AddToggle({
        Name = 'Render Walls',
        Function = function(callback)
            for _, v in Reference do
                if type(v) == 'table' then
                    for _, v2 in v do
                        v2.AlwaysOnTop = callback
                    end
                else
                    v.DepthMode = Enum.HighlightDepthMode[callback and 'AlwaysOnTop' or 'Occluded']
                end
            end
        end,
        Default = true
    })
    Teammates = Chams:AddToggle({
        Name = 'Priority Only',
        Function = function()
            if Chams.Enabled then
                Chams:Toggle()
                Chams:Toggle()
            end
        end,
        Default = true
    })
end)
run(function()
    local ESP
    local Targets
    local Color
    local Method
    local BoundingBox
    local Filled
    local HealthBar
    local Name
    local DisplayName
    local Background
    local Teammates
    local Distance
    local DistanceLimit
    local Reference = {}
    local methodused
    local function ESPWorldToViewport(pos)
        local newpos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(gameCamera.CFrame:PointToObjectSpace(pos)))
        return Vector2.new(newpos.X, newpos.Y)
    end
    local ESPAdded = {
        Drawing2D = function(ent)
            if not ent.Player then
                return
            end
            if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
                return
            end
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            local EntityESP = {}
            EntityESP.Main = Drawing.new('Square')
            EntityESP.Main.Transparency = BoundingBox.Enabled and 1 or 0
            EntityESP.Main.ZIndex = 2
            EntityESP.Main.Filled = false
            EntityESP.Main.Thickness = 1
            EntityESP.Main.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            if BoundingBox.Enabled then
                EntityESP.Border = Drawing.new('Square')
                EntityESP.Border.Transparency = 0.35
                EntityESP.Border.ZIndex = 1
                EntityESP.Border.Thickness = 1
                EntityESP.Border.Filled = false
                EntityESP.Border.Color = Color3.new()
                EntityESP.Border2 = Drawing.new('Square')
                EntityESP.Border2.Transparency = 0.35
                EntityESP.Border2.ZIndex = 1
                EntityESP.Border2.Thickness = 1
                EntityESP.Border2.Filled = Filled.Enabled
                EntityESP.Border2.Color = Color3.new()
            end
            if HealthBar.Enabled then
                EntityESP.HealthLine = Drawing.new('Line')
                EntityESP.HealthLine.Thickness = 1
                EntityESP.HealthLine.ZIndex = 2
                EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                EntityESP.HealthBorder = Drawing.new('Line')
                EntityESP.HealthBorder.Thickness = 3
                EntityESP.HealthBorder.Transparency = 0.35
                EntityESP.HealthBorder.ZIndex = 1
                EntityESP.HealthBorder.Color = Color3.new()
            end
            if Name.Enabled then
                if Background.Enabled then
                    EntityESP.TextBKG = Drawing.new('Square')
                    EntityESP.TextBKG.Transparency = 0.35
                    EntityESP.TextBKG.ZIndex = 0
                    EntityESP.TextBKG.Thickness = 1
                    EntityESP.TextBKG.Filled = true
                    EntityESP.TextBKG.Color = Color3.new()
                end
                EntityESP.Drop = Drawing.new('Text')
                EntityESP.Drop.Color = Color3.new()
                EntityESP.Drop.Text = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                EntityESP.Drop.ZIndex = 1
                EntityESP.Drop.Center = true
                EntityESP.Drop.Size = 20
                EntityESP.Text = Drawing.new('Text')
                EntityESP.Text.Text = EntityESP.Drop.Text
                EntityESP.Text.ZIndex = 2
                EntityESP.Text.Color = EntityESP.Main.Color
                EntityESP.Text.Center = true
                EntityESP.Text.Size = 20
            end
            Reference[ent] = EntityESP
        end,
        Drawing3D = function(ent)
            if not ent.Player then
                return
            end
            if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
                return
            end
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            local EntityESP = {}
            EntityESP.Line1 = Drawing.new('Line')
            EntityESP.Line2 = Drawing.new('Line')
            EntityESP.Line3 = Drawing.new('Line')
            EntityESP.Line4 = Drawing.new('Line')
            EntityESP.Line5 = Drawing.new('Line')
            EntityESP.Line6 = Drawing.new('Line')
            EntityESP.Line7 = Drawing.new('Line')
            EntityESP.Line8 = Drawing.new('Line')
            EntityESP.Line9 = Drawing.new('Line')
            EntityESP.Line10 = Drawing.new('Line')
            EntityESP.Line11 = Drawing.new('Line')
            EntityESP.Line12 = Drawing.new('Line')
            local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            for _, v in EntityESP do
                v.Thickness = 1
                v.Color = color
            end
            Reference[ent] = EntityESP
        end,
        DrawingSkeleton = function(ent)
            if not ent.Player then
                return
            end
            if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
                return
            end
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            local EntityESP = {}
            EntityESP.Head = Drawing.new('Line')
            EntityESP.HeadFacing = Drawing.new('Line')
            EntityESP.Torso = Drawing.new('Line')
            EntityESP.UpperTorso = Drawing.new('Line')
            EntityESP.LowerTorso = Drawing.new('Line')
            EntityESP.LeftArm = Drawing.new('Line')
            EntityESP.RightArm = Drawing.new('Line')
            EntityESP.LeftLeg = Drawing.new('Line')
            EntityESP.RightLeg = Drawing.new('Line')
            local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
            for _, v in EntityESP do
                v.Thickness = 2
                v.Color = color
            end
            Reference[ent] = EntityESP
        end
    }
    local ESPRemoved = {
        Drawing2D = function(ent)
            local EntityESP = Reference[ent]
            if EntityESP then
                if Modern.ThreadFix then
                    setthreadidentity(8)
                end
                Reference[ent] = nil
                for _, v in EntityESP do
                    pcall(function()
                        v.Visible = false
                        v:Remove()
                    end)
                end
            end
        end
    }
    ESPRemoved.Drawing3D = ESPRemoved.Drawing2D
    ESPRemoved.DrawingSkeleton = ESPRemoved.Drawing2D
    local ESPUpdated = {
        Drawing2D = function(ent)
            local EntityESP = Reference[ent]
            if EntityESP then
                if Modern.ThreadFix then
                    setthreadidentity(8)
                end
                if EntityESP.HealthLine then
                    EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                end
                if EntityESP.Text then
                    EntityESP.Text.Text = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                    EntityESP.Drop.Text = EntityESP.Text.Text
                end
            end
        end
    }
    local ColorFunc = {
        Drawing2D = function(hue, sat, val)
            local color = Color3.fromHSV(hue, sat, val)
            for i, v in Reference do
                v.Main.Color = entitylib.getEntityColor(i) or color
                if v.Text then
                    v.Text.Color = v.Main.Color
                end
            end
        end,
        Drawing3D = function(hue, sat, val)
            local color = Color3.fromHSV(hue, sat, val)
            for i, v in Reference do
                local playercolor = entitylib.getEntityColor(i) or color
                for _, v2 in v do
                    v2.Color = playercolor
                end
            end
        end
    }
    ColorFunc.DrawingSkeleton = ColorFunc.Drawing3D
    local ESPLoop = {
        Drawing2D = function()
            for ent, EntityESP in Reference do
                if Distance.Enabled then
                    local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
                    if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
                        for _, obj in EntityESP do
                            obj.Visible = false
                        end
                        continue
                    end
                end
                local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
                local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
                for _, obj in EntityESP do
                    obj.Visible = rootVis
                    obj.Color = color
                end
                if not rootVis then
                    continue
                end
                local topPos = gameCamera:WorldToViewportPoint((CFrame.lookAlong(ent.RootPart.Position, gameCamera.CFrame.LookVector) * CFrame.new(2, ent.HipHeight, 0)).p)
                local bottomPos = gameCamera:WorldToViewportPoint((CFrame.lookAlong(ent.RootPart.Position, gameCamera.CFrame.LookVector) * CFrame.new(- 2, - ent.HipHeight - 1, 0)).p)
                local sizex, sizey = topPos.X - bottomPos.X, topPos.Y - bottomPos.Y
                local posx, posy = (rootPos.X - sizex / 2), ((rootPos.Y - sizey / 2))
                EntityESP.Main.Position = Vector2.new(posx, posy) // 1
                EntityESP.Main.Size = Vector2.new(sizex, sizey) // 1
                if EntityESP.Border then
                    EntityESP.Border.Position = Vector2.new(posx - 1, posy + 1) // 1
                    EntityESP.Border.Size = Vector2.new(sizex + 2, sizey - 2) // 1
                    EntityESP.Border2.Position = Vector2.new(posx + 1, posy - 1) // 1
                    EntityESP.Border2.Size = Vector2.new(sizex - 2, sizey + 2) // 1
                end
                if EntityESP.HealthLine then
                    local healthposy = sizey * math.clamp(ent.Health / ent.MaxHealth, 0, 1)
                    EntityESP.HealthLine.Visible = ent.Health > 0
                    EntityESP.HealthLine.From = Vector2.new(posx - 6, posy + (sizey - (sizey - healthposy))) // 1
                    EntityESP.HealthLine.To = Vector2.new(posx - 6, posy) // 1
                    EntityESP.HealthBorder.From = Vector2.new(posx - 6, posy + 1) // 1
                    EntityESP.HealthBorder.To = Vector2.new(posx - 6, (posy + sizey) - 1) // 1
                end
                if EntityESP.Text then
                    EntityESP.Text.Position = Vector2.new(posx + (sizex / 2), posy + (sizey - 28)) // 1
                    EntityESP.Drop.Position = EntityESP.Text.Position + Vector2.new(1, 1)
                    if EntityESP.TextBKG then
                        EntityESP.TextBKG.Size = EntityESP.Text.TextBounds + Vector2.new(8, 4)
                        EntityESP.TextBKG.Position = EntityESP.Text.Position - Vector2.new(4 + (EntityESP.Text.TextBounds.X / 2), 0)
                    end
                end
            end
        end,
        Drawing3D = function()
            for ent, EntityESP in Reference do
                if Distance.Enabled then
                    local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
                    if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
                        for _, obj in EntityESP do
                            obj.Visible = false
                        end
                        continue
                    end
                end
                local _, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
                local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
                for _, obj in EntityESP do
                    obj.Visible = rootVis
                    obj.Thickness = 2
                    obj.Color = color
                end
                if not rootVis then
                    continue
                end
                local point1 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, 1.5))
                local point2 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, - ent.HipHeight, 1.5))
                local point3 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(- 1.5, ent.HipHeight, 1.5))
                local point4 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(- 1.5, - ent.HipHeight, 1.5))
                local point5 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, - 1.5))
                local point6 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, - ent.HipHeight, - 1.5))
                local point7 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(- 1.5, ent.HipHeight, - 1.5))
                local point8 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(- 1.5, - ent.HipHeight, - 1.5))
                EntityESP.Line1.From = point1
                EntityESP.Line1.To = point2
                EntityESP.Line2.From = point3
                EntityESP.Line2.To = point4
                EntityESP.Line3.From = point5
                EntityESP.Line3.To = point6
                EntityESP.Line4.From = point7
                EntityESP.Line4.To = point8
                EntityESP.Line5.From = point1
                EntityESP.Line5.To = point3
                EntityESP.Line6.From = point1
                EntityESP.Line6.To = point5
                EntityESP.Line7.From = point5
                EntityESP.Line7.To = point7
                EntityESP.Line8.From = point7
                EntityESP.Line8.To = point3
                EntityESP.Line9.From = point2
                EntityESP.Line9.To = point4
                EntityESP.Line10.From = point2
                EntityESP.Line10.To = point6
                EntityESP.Line11.From = point6
                EntityESP.Line11.To = point8
                EntityESP.Line12.From = point8
                EntityESP.Line12.To = point4
            end
        end,
        DrawingSkeleton = function()
            for ent, EntityESP in Reference do
                if Distance.Enabled then
                    local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
                    if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
                        for _, obj in EntityESP do
                            obj.Visible = false
                        end
                        continue
                    end
                end
                local _, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
                for _, obj in EntityESP do
                    obj.Visible = rootVis
                end
                if not rootVis then
                    continue
                end
                local rigcheck = ent.Humanoid.RigType == Enum.HumanoidRigType.R6
                pcall(function()
                    local offset = rigcheck and CFrame.new(0, - 0.8, 0) or CFrame.identity
                    local head = ESPWorldToViewport((ent.Head.CFrame).p)
                    local headfront = ESPWorldToViewport((ent.Head.CFrame * CFrame.new(0, 0, - 0.5)).p)
                    local toplefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(- 1.5, 0.8, 0)).p)
                    local toprighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(1.5, 0.8, 0)).p)
                    local toptorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, 0.8, 0)).p)
                    local bottomtorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, - 0.8, 0)).p)
                    local bottomlefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(- 0.5, - 0.8, 0)).p)
                    local bottomrighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0.5, - 0.8, 0)).p)
                    local leftarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Arm' or 'LeftHand')].CFrame * offset).p)
                    local rightarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Arm' or 'RightHand')].CFrame * offset).p)
                    local leftleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Leg' or 'LeftFoot')].CFrame * offset).p)
                    local rightleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Leg' or 'RightFoot')].CFrame * offset).p)
                    EntityESP.Head.From = toptorso
                    EntityESP.Head.To = head
                    EntityESP.HeadFacing.From = head
                    EntityESP.HeadFacing.To = headfront
                    EntityESP.UpperTorso.From = toplefttorso
                    EntityESP.UpperTorso.To = toprighttorso
                    EntityESP.Torso.From = toptorso
                    EntityESP.Torso.To = bottomtorso
                    EntityESP.LowerTorso.From = bottomlefttorso
                    EntityESP.LowerTorso.To = bottomrighttorso
                    EntityESP.LeftArm.From = toplefttorso
                    EntityESP.LeftArm.To = leftarm
                    EntityESP.RightArm.From = toprighttorso
                    EntityESP.RightArm.To = rightarm
                    EntityESP.LeftLeg.From = bottomlefttorso
                    EntityESP.LeftLeg.To = leftleg
                    EntityESP.RightLeg.From = bottomrighttorso
                    EntityESP.RightLeg.To = rightleg
                end)
            end
        end
    }
    ESP = Modern.Catalogs.Render:AddModule({
        Name = 'ESP',
        Function = function(callback)
            if callback then
                methodused = 'Drawing' .. Method.Value
                if ESPRemoved[methodused] then
                    ESP:Clean(entitylib.Events.EntityRemoved:Connect(ESPRemoved[methodused]))
                end
                if ESPAdded[methodused] then
                    for _, v in entitylib.List do
                        if Reference[v] then
                            ESPRemoved[methodused](v)
                        end
                        ESPAdded[methodused](v)
                    end
                    ESP:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
                        if Reference[ent] then
                            ESPRemoved[methodused](ent)
                        end
                        ESPAdded[methodused](ent)
                    end))
                end
                if ESPUpdated[methodused] then
                    ESP:Clean(entitylib.Events.EntityUpdated:Connect(ESPUpdated[methodused]))
                    for _, v in entitylib.List do
                        ESPUpdated[methodused](v)
                    end
                end
                if ESPLoop[methodused] then
                    ESP:Clean(RunService.RenderStepped:Connect(ESPLoop[methodused]))
                end
            else
                if ESPRemoved[methodused] then
                    for i in Reference do
                        ESPRemoved[methodused](i)
                    end
                end
            end
        end
    })
    Method = ESP:AddDropdown({
        Name = 'Mode',
        List = {'2D', '3D', 'Skeleton'},
        Function = function(val)
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
            BoundingBox.Frame.Visible = (val == '2D')
            Filled.Frame.Visible = (val == '2D')
            HealthBar.Frame.Visible = (val == '2D')
            Name.Frame.Visible = (val == '2D')
            DisplayName.Frame.Visible = Name.Frame.Visible and Name.Enabled
            Background.Frame.Visible = Name.Frame.Visible and Name.Enabled
        end,
    })
    BoundingBox = ESP:AddToggle({
        Name = 'Bounding Box',
        Function = function()
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
        end,
        Default = true,
        Darker = true
    })
    Filled = ESP:AddToggle({
        Name = 'Filled',
        Function = function()
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
        end,
        Darker = true
    })
    HealthBar = ESP:AddToggle({
        Name = 'Health Bar',
        Function = function()
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
        end,
        Darker = true
    })
    Name = ESP:AddToggle({
        Name = 'Name',
        Function = function(callback)
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
            DisplayName.Frame.Visible = callback
            Background.Frame.Visible = callback
        end,
        Darker = true
    })
    DisplayName = ESP:AddToggle({
        Name = 'Use Displayname',
        Function = function()
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
        end,
        Default = true,
        Darker = true
    })
    Background = ESP:AddToggle({
        Name = 'Show Background',
        Function = function()
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
        end,
        Darker = true
    })
    Teammates = ESP:AddToggle({
        Name = 'Priority Only',
        Function = function()
            if ESP.Enabled then
                ESP:Toggle()
                ESP:Toggle()
            end
        end,
        Default = true
    })
    Distance = ESP:AddToggle({
        Name = 'Distance Check',
        Function = function(callback)
            DistanceLimit.Object.Visible = callback
        end
    })
    DistanceLimit = ESP:AddSlider({
        Name = 'Player Distance',
        Min = 0,
        Max = 256,
        Default = 64,
        Darker = true,
        Visible = false
    })
end)
run(function()
    local Mode
    local StudLimit = {
        Object = {}
    }
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    local overlapCheck = OverlapParams.new()
    overlapCheck.MaxParts = 9e9
    local modified, fflag = {}
    local teleported
    local function grabClosestNormal(ray)
        local partCF, mag, closest = ray.Instance.CFrame, 0, Enum.NormalId.Top
        for _, normal in Enum.NormalId:GetEnumItems() do
            local dot = partCF:VectorToWorldSpace(Vector3.fromNormalId(normal)):Dot(ray.Normal)
            if dot > mag then
                mag, closest = dot, normal
            end
        end
        return Vector3.fromNormalId(closest).X ~= 0 and 'X' or 'Z'
    end
    local Functions = {
        Part = function()
            local chars = {gameCamera, lplr.Character}
            for _, v in entitylib.List do
                table.insert(chars, v.Character)
            end
            overlapCheck.FilterDescendantsInstances = chars
            local parts = workspace:GetPartBoundsInBox(entitylib.character.RootPart.CFrame + Vector3.new(0, 1, 0), entitylib.character.RootPart.Size + Vector3.new(1, entitylib.character.HipHeight, 1), overlapCheck)
            for _, part in parts do
                if part.CanCollide and (not Spider.Enabled or SpiderShift) then
                    modified[part] = true
                    part.CanCollide = false
                end
            end
            for part in modified do
                if not table.find(parts, part) then
                    modified[part] = nil
                    part.CanCollide = true
                end
            end
        end,
        Character = function()
            for _, part in lplr.Character:GetDescendants() do
                if part:IsA('BasePart') and part.CanCollide and (not Spider.Enabled or SpiderShift) then
                    modified[part] = true
                    part.CanCollide = Spider.Enabled and not SpiderShift
                end
            end
        end,
        CFrame = function()
            local chars = {gameCamera, lplr.Character}
            for _, v in entitylib.List do
                table.insert(chars, v.Character)
            end
            rayCheck.FilterDescendantsInstances = chars
            overlapCheck.FilterDescendantsInstances = chars
            local ray = workspace:Raycast(entitylib.character.Head.CFrame.Position, entitylib.character.Humanoid.MoveDirection * 1.1, rayCheck)
            if ray and (not Spider.Enabled or SpiderShift) then
                local phaseDirection = grabClosestNormal(ray)
                if ray.Instance.Size[phaseDirection] <= StudLimit.Value then
                    local root = entitylib.character.RootPart
                    local dest = root.CFrame + (ray.Normal * (- (ray.Instance.Size[phaseDirection]) - (root.Size.X / 1.5)))
                    if #workspace:GetPartBoundsInBox(dest, Vector3.one, overlapCheck) <= 0 then
                        if Mode.Value == 'Motor' then
                            motorMove(root, dest)
                        else
                            root.CFrame = dest
                        end
                    end
                end
            end
        end,
        FFlag = function()
            if teleported then
                return
            end
            setfflag('AssemblyExtentsExpansionStudHundredth', '-10000')
            fflag = true
        end
    }
    Functions.Motor = Functions.CFrame
    Phase = Modern.Catalogs.Player:AddModule({
        Name = 'Phase',
        Function = function(callback)
            if callback then
                Phase:Clean(RunService.Stepped:Connect(function()
                    if entitylib.isAlive then
                        Functions[Mode.Value]()
                    end
                end))
                if Mode.Value == 'FFlag' then
                    Phase:Clean(lplr.OnTeleport:Connect(function()
                        teleported = true
                        setfflag('AssemblyExtentsExpansionStudHundredth', '30')
                    end))
                end
            else
                if fflag then
                    setfflag('AssemblyExtentsExpansionStudHundredth', '30')
                end
                for part in modified do
                    part.CanCollide = true
                end
                table.clear(modified)
                fflag = nil
            end
        end
    })
    Mode = Phase:AddDropdown({
        Name = 'Mode',
        List = {'Part', 'Character', 'CFrame', 'Motor', 'FFlag'},
        Function = function(val)
            StudLimit.Object.Visible = val == 'CFrame' or val == 'Motor'
            if fflag then
                setfflag('AssemblyExtentsExpansionStudHundredth', '30')
            end
            for part in modified do
                part.CanCollide = true
            end
            table.clear(modified)
            fflag = nil
        end
    })
    StudLimit = Phase:AddSlider({
        Name = 'Wall Size',
        Min = 1,
        Max = 20,
        Default = 5,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end,
        Darker = true,
        Visible = false
    })
end)
run(function()
    local Mode
    local Value
    local State
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    local Active, Truss
    Spider = Modern.Catalogs.Movement:AddModule({
        Name = 'Spider',
        Function = function(callback)
            if callback then
                if Truss then
                    Truss.Parent = gameCamera
                end
                Spider:Clean(RunService.PreSimulation:Connect(function(dt)
                    if entitylib.isAlive then
                        local root = lplr.Character.PrimaryPart or entitylib.character.RootPart
                        local chars = {gameCamera, lplr.Character, Truss}
                        for _, v in entitylib.List do
                            table.insert(chars, v.Character)
                        end
                        SpiderShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                        rayCheck.FilterDescendantsInstances = chars
                        rayCheck.CollisionGroup = root.CollisionGroup
                        if Mode.Value ~= 'Part' then
                            local vec = entitylib.character.Humanoid.MoveDirection * 2.5
                            local ray = workspace:Raycast(root.Position - Vector3.new(0, entitylib.character.HipHeight - 0.5, 0), vec, rayCheck)
                            if Active and not ray then
                                root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
                            end
                            Active = ray
                            if Active and ray.Normal.Y == 0 then
                                if not Phase.Enabled or not SpiderShift then
                                    if State.Enabled then
                                        entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
                                    end
                                    root.Velocity *= Vector3.new(1, 0, 1)
                                    if Mode.Value == 'CFrame' then
                                        root.CFrame += Vector3.new(0, Value.Value * dt, 0)
                                    elseif Mode.Value == 'Impulse' then
                                        root:ApplyImpulse(Vector3.new(0, Value.Value, 0) * root.AssemblyMass)
                                    else
                                        root.Velocity += Vector3.new(0, Value.Value, 0)
                                    end
                                end
                            end
                        else
                            local ray = workspace:Raycast(root.Position - Vector3.new(0, entitylib.character.HipHeight - 0.5, 0), entitylib.character.RootPart.CFrame.LookVector * 2, rayCheck)
                            if ray and (not Phase.Enabled or not SpiderShift) then
                                Truss.Position = ray.Position - ray.Normal * 0.9 or Vector3.zero
                            else
                                Truss.Position = Vector3.zero
                            end
                        end
                    end
                end))
            else
                if Truss then
                    Truss.Parent = nil
                end
                SpiderShift = false
            end
        end
    })
    Mode = Spider:AddDropdown({
        Name = 'Mode',
        List = {'Velocity', 'Impulse', 'CFrame', 'Part'},
        Function = function(val)
            Value.Frame.Visible = val ~= 'Part'
            State.Frame.Visible = val ~= 'Part'
            if Truss then
                Truss:Destroy()
                Truss = nil
            end
            if val == 'Part' then
                Truss = Instance.new('TrussPart')
                Truss.Size = Vector3.new(2, 2, 2)
                Truss.Transparency = 1
                Truss.Anchored = true
                Truss.Parent = Spider.Enabled and gameCamera or nil
            end
        end
    })
    Value = Spider:AddSlider({
        Name = 'Speed',
        Min = 0,
        Max = 100,
        Default = 30,
        Darker = true,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    State = Spider:AddToggle({
        Name = 'Climb State',
        Darker = true
    })
end)
run(function()
    local SpinBot
    local Mode
    local XToggle
    local YToggle
    local ZToggle
    local Value
    local AngularVelocity
    SpinBot = Modern.Catalogs.Movement:AddModule({
        Name = 'Spin',
        Function = function(callback)
            if callback then
                SpinBot:Clean(RunService.PreSimulation:Connect(function()
                    if entitylib.isAlive then
                        if Mode.Value == 'RotVelocity' then
                            local originalRotVelocity = entitylib.character.RootPart.RotVelocity
                            entitylib.character.Humanoid.AutoRotate = false
                            entitylib.character.RootPart.RotVelocity = Vector3.new(XToggle.Enabled and Value.Value or originalRotVelocity.X, YToggle.Enabled and Value.Value or originalRotVelocity.Y, ZToggle.Enabled and Value.Value or originalRotVelocity.Z)
                        elseif Mode.Value == 'CFrame' then
                            local val = math.rad((tick() * (20 * Value.Value)) % 360)
                            local x, y, z = entitylib.character.RootPart.CFrame:ToOrientation()
                            entitylib.character.RootPart.CFrame = CFrame.new(entitylib.character.RootPart.Position) * CFrame.Angles(XToggle.Enabled and val or x, YToggle.Enabled and val or y, ZToggle.Enabled and val or z)
                        elseif AngularVelocity then
                            AngularVelocity.Parent = entitylib.isAlive and entitylib.character.RootPart
                            AngularVelocity.MaxTorque = Vector3.new(XToggle.Enabled and math.huge or 0, YToggle.Enabled and math.huge or 0, ZToggle.Enabled and math.huge or 0)
                            AngularVelocity.AngularVelocity = Vector3.new(Value.Value, Value.Value, Value.Value)
                        end
                    end
                end))
            else
                if entitylib.isAlive and Mode.Value == 'RotVelocity' then
                    entitylib.character.Humanoid.AutoRotate = true
                end
                if AngularVelocity then
                    AngularVelocity.Parent = nil
                end
            end
        end
    })
    Mode = SpinBot:AddDropdown({
        Name = 'Mode',
        List = {'CFrame', 'RotVelocity', 'BodyMover'},
        Function = function(val)
            if AngularVelocity then
                AngularVelocity:Destroy()
                AngularVelocity = nil
            end
            AngularVelocity = val == 'BodyMover' and Instance.new('BodyAngularVelocity') or nil
        end
    })
    Value = SpinBot:AddSlider({
        Name = 'Speed',
        Min = 1,
        Max = 100,
        Default = 40
    })
    XToggle = SpinBot:AddToggle({
        Name = 'Spin X'
    })
    YToggle = SpinBot:AddToggle({
        Name = 'Spin Y',
        Default = true
    })
    ZToggle = SpinBot:AddToggle({
        Name = 'Spin Z'
    })
end)
run(function()
    local Tracers
    local Targets
    local Color
    local Transparency
    local StartPosition
    local EndPosition
    local Teammates
    local DistanceColor
    local Distance
    local DistanceLimit
    local Behind
    local Reference = {}
    local function Added(ent)
        if not ent.Player then
            return
        end
        if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then
            return
        end
        if Modern.ThreadFix then
            setthreadidentity(8)
        end
        local EntityTracer = Drawing.new('Line')
        EntityTracer.Thickness = 1
        EntityTracer.Transparency = 1 - Transparency.Value
        EntityTracer.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
        Reference[ent] = EntityTracer
    end
    local function Removed(ent)
        local v = Reference[ent]
        if v then
            if Modern.ThreadFix then
                setthreadidentity(8)
            end
            Reference[ent] = nil
            pcall(function()
                v.Visible = false
                v:Remove()
            end)
        end
    end
    local function Loop()
        local screenSize = Modern.MainScreenGui.AbsoluteSize
        local startVector = StartPosition.Value == 'Mouse' and UserInputService:GetMouseLocation() or Vector2.new(screenSize.X / 2, (StartPosition.Value == 'Middle' and screenSize.Y / 2 or screenSize.Y))
        for ent, EntityTracer in Reference do
            local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude
            if Distance.Enabled and distance then
                if distance > DistanceLimit.Value then
                    EntityTracer.Visible = false
                    continue
                end
            end
            local pos = ent[EndPosition.Value == 'Torso' and 'RootPart' or 'Head'].Position
            local rootPos, rootVis = gameCamera:WorldToViewportPoint(pos)
            if not rootVis and Behind.Enabled then
                local tempPos = gameCamera.CFrame:PointToObjectSpace(pos)
                tempPos = CFrame.Angles(0, 0, (math.atan2(tempPos.Y, tempPos.X) + math.pi)):VectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):VectorToWorldSpace(Vector3.new(0, 0, - 1))))
                rootPos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(tempPos))
                rootVis = true
            end
            local endVector = Vector2.new(rootPos.X, rootPos.Y)
            EntityTracer.Visible = rootVis
            EntityTracer.From = startVector
            EntityTracer.To = endVector
            EntityTracer.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
        end
    end
    Tracers = Modern.Catalogs.Render:AddModule({
        Name = 'Tracers',
        Function = function(callback)
            if callback then
                Tracers:Clean(entitylib.Events.EntityRemoved:Connect(Removed))
                for _, v in entitylib.List do
                    if Reference[v] then
                        Removed(v)
                    end
                    Added(v)
                end
                Tracers:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
                    if Reference[ent] then
                        Removed(ent)
                    end
                    Added(ent)
                end))
                Tracers:Clean(RunService.RenderStepped:Connect(Loop))
            else
                for i in Reference do
                    Removed(i)
                end
            end
        end
    })
    StartPosition = Tracers:AddDropdown({
        Name = 'Start Position',
        List = {'Middle', 'Bottom', 'Mouse'},
        Function = function()
            if Tracers.Enabled then
                Tracers:Toggle()
                Tracers:Toggle()
            end
        end
    })
    EndPosition = Tracers:AddDropdown({
        Name = 'End Position',
        List = {'Head', 'Torso'},
        Function = function()
            if Tracers.Enabled then
                Tracers:Toggle()
                Tracers:Toggle()
            end
        end
    })
    Transparency = Tracers:AddSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Function = function(val)
            for _, tracer in Reference do
                tracer.Transparency = 1 - val
            end
        end,
        Decimal = 10
    })
    Distance = Tracers:AddToggle({
        Name = 'Distance Check',
        Function = function(callback)
            DistanceLimit.Frame.Visible = callback
        end
    })
    DistanceLimit = Tracers:AddSlider({
        Name = 'Player Distance',
        Min = 0,
        Max = 256,
        Default = 64,
        Darker = true,
        Visible = false
    })
    Behind = Tracers:AddToggle({
        Name = 'Behind',
        Default = true
    })
    Teammates = Tracers:AddToggle({
        Name = 'Priority Only',
        Function = function()
            if Tracers.Enabled then
                Tracers:Toggle()
                Tracers:Toggle()
            end
        end,
        Default = true
    })
end)
run(function()
    local HitBox
    local Targets
    local TargetPart
    local Expand
    local modified = {}
    HitBox = Modern.Catalogs.Combat:AddModule({
        Name = 'HitBox',
        Function = function(callback)
            if callback then
                repeat
                    for _, v in entitylib.List do
                        if v.Targetable then
                            if not v.Player then
                                continue
                            end
                            local part = v[TargetPart.Value]
                            if not modified[part] then
                                modified[part] = part.Size
                            end
                            part.Size = modified[part] + Vector3.new(Expand.Value, Expand.Value, Expand.Value)
                        end
                    end
                    task.wait()
                until not HitBox.Enabled
            else
                for i, v in modified do
                    i.Size = v
                end
                table.clear(modified)
            end
        end
    })
    TargetPart = HitBox:AddDropdown({
        Name = 'Part',
        List = {'RootPart', 'Head'}
    })
    Expand = HitBox:AddSlider({
        Name = 'Expand',
        Min = 0,
        Max = 2,
        Decimal = 10,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
end)
run(function()
    local AntiRagdoll
    AntiRagdoll = Modern.Catalogs.Other:AddModule({
        Name = 'AntiRagdoll',
        Function = function(callback)
            if entitylib.isAlive then
                entitylib.character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not callback)
            end
            if callback then
                AntiRagdoll:Clean(entitylib.Events.LocalAdded:Connect(function(char)
                    char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                end))
            end
        end
    })
end)
run(function()
    local Blink
    local Type
    local AutoSend
    local AutoSendLength
    local oldphys, oldsend
    Blink = Modern.Catalogs.Other:AddModule({
        Name = 'Blink',
        Function = function(callback)
            if callback then
                local teleported
                Blink:Clean(lplr.OnTeleport:Connect(function()
                    setfflag('S2PhysicsSenderRate', '15')
                    setfflag('DataSenderRate', '60')
                    teleported = true
                end))
                repeat
                    local physicsrate, senderrate = '0', Type.Value == 'All' and '-1' or '60'
                    if AutoSend.Enabled and tick() % (AutoSendLength.Value + 0.1) > AutoSendLength.Value then
                        physicsrate, senderrate = '15', '60'
                    end
                    if physicsrate ~= oldphys or senderrate ~= oldsend then
                        setfflag('S2PhysicsSenderRate', physicsrate)
                        setfflag('DataSenderRate', senderrate)
                        oldphys, oldsend = physicsrate, oldsend
                    end
                    task.wait(0.03)
                until (not Blink.Enabled and not teleported)
            else
                if setfflag then
                    setfflag('S2PhysicsSenderRate', '15')
                    setfflag('DataSenderRate', '60')
                end
                oldphys, oldsend = nil, nil
            end
        end
    })
    Type = Blink:AddDropdown({
        Name = 'Type',
        List = {'Movement Only', 'All'}
    })
    AutoSend = Blink:AddToggle({
        Name = 'Auto send',
        Function = function(callback)
            AutoSendLength.Frame.Visible = callback
        end
    })
    AutoSendLength = Blink:AddSlider({
        Name = 'Send threshold',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
end)
run(function()
    local Xray
    local List
    local modified = {}
    local function modifyPart(v)
        if v:IsA('BasePart') then
            modified[v] = true
            v.LocalTransparencyModifier = 0.5
        end
    end
    Xray = Modern.Catalogs.Render:AddModule({
        Name = 'XRay',
        Function = function(callback)
            if callback then
                Xray:Clean(workspace.DescendantAdded:Connect(modifyPart))
                for _, v in workspace:GetDescendants() do
                    modifyPart(v)
                end
            else
                for i in modified do
                    i.LocalTransparencyModifier = 0
                end
                table.clear(modified)
            end
        end
    })
    Transparency = Xray:AddSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Function = function(val)
            for i in modified do
                i.LocalTransparencyModifier = 1 - val
            end
        end,
        Decimal = 100
    })
end)
local mouseClicked
run(function()
    local SilentAim
    local Target
    local Mode
    local Method
    local MethodRay = {}
    local IgnoredScripts
    local Range
    local HitChance
    local HeadshotChance
    local AutoFire
    local AutoFireShootDelay
    local AutoFireMode
    local AutoFirePosition
    local Wallbang
    local CircleColor
    local CircleTransparency
    local CircleFilled
    local CircleObject
    local Projectile
    local ProjectileSpeed
    local ProjectileGravity
    local RaycastWhitelist = RaycastParams.new()
    RaycastWhitelist.FilterType = Enum.RaycastFilterType.Include
    local ProjectileRaycast = RaycastParams.new()
    ProjectileRaycast.RespectCanCollide = true
    local fireoffset, rand, delayCheck = CFrame.identity, Random.new(), tick()
    local oldnamecall, oldray
    local function getTarget(origin, obj)
        if rand.NextNumber(rand, 0, 100) > (AutoFire.Enabled and 100 or HitChance.Value) then
            return
        end
        local targetPart = (rand.NextNumber(rand, 0, 100) < (AutoFire.Enabled and 100 or HeadshotChance.Value)) and 'Head' or 'RootPart'
        local ent = entitylib['Entity' .. Mode.Value]({
            Range = Range.Value,
            Wallcheck = true,
            Part = targetPart,
            Origin = origin,
            Players = true,
            NPCs = true
        })
        if ent then
            Targetinfo.Targets[ent] = tick() + 1
            if Projectile.Enabled then
                ProjectileRaycast.FilterDescendantsInstances = {gameCamera, ent.Character}
                ProjectileRaycast.CollisionGroup = ent[targetPart].CollisionGroup
            end
        end
        return ent, ent and ent[targetPart], origin
    end
    local Hooks = {
        FindPartOnRayWithIgnoreList = function(args)
            local ent, targetPart, origin = getTarget(args[1].Origin, {args[2]})
            if not ent then
                return
            end
            if Wallbang.Enabled then
                return {targetPart, targetPart.Position, targetPart.GetClosestPointOnSurface(targetPart, origin), targetPart.Material}
            end
            args[1] = Ray.new(origin, CFrame.lookAt(origin, targetPart.Position).LookVector * args[1].Direction.Magnitude)
        end,
        Raycast = function(args)
            if MethodRay.Value ~= 'All' and args[3] and args[3].FilterType ~= Enum.RaycastFilterType[MethodRay.Value] then
                return
            end
            local ent, targetPart, origin = getTarget(args[1])
            if not ent then
                return
            end
            args[2] = CFrame.lookAt(origin, targetPart.Position).LookVector * args[2].Magnitude
            if Wallbang.Enabled then
                RaycastWhitelist.FilterDescendantsInstances = {targetPart}
                args[3] = RaycastWhitelist
            end
        end,
        ScreenPointToRay = function(args)
            local ent, targetPart, origin = getTarget(gameCamera.CFrame.Position)
            if not ent then
                return
            end
            local direction = CFrame.lookAt(origin, targetPart.Position)
            if Projectile.Enabled then
                local calc = prediction.SolveTrajectory(origin, ProjectileSpeed.Value, ProjectileGravity.Value, targetPart.Position, targetPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
                if not calc then
                    return
                end
                direction = CFrame.lookAt(origin, calc)
            end
            return {Ray.new(origin + (args[3] and direction.LookVector * args[3] or Vector3.zero), direction.LookVector)}
        end,
        Ray = function(args)
            local ent, targetPart, origin = getTarget(args[1])
            if not ent then
                return
            end
            if Projectile.Enabled then
                local calc = prediction.SolveTrajectory(origin, ProjectileSpeed.Value, ProjectileGravity.Value, targetPart.Position, targetPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
                if not calc then
                    return
                end
                args[2] = CFrame.lookAt(origin, calc).LookVector * args[2].Magnitude
            else
                args[2] = CFrame.lookAt(origin, targetPart.Position).LookVector * args[2].Magnitude
            end
        end
    }
    Hooks.FindPartOnRayWithWhitelist = Hooks.FindPartOnRayWithIgnoreList
    Hooks.FindPartOnRay = Hooks.FindPartOnRayWithIgnoreList
    Hooks.ViewportPointToRay = Hooks.ScreenPointToRay
    SilentAim = Modern.Catalogs.Combat:AddModule({
        Name = 'Silent Aim',
        Function = function(callback)
            if CircleObject then
                CircleObject.Visible = callback and Mode.Value == 'Mouse'
            end
            if callback then
                if Method.Value == 'Ray' then
                    oldray = hookfunction(Ray.new, function(origin, direction)
                        if checkcaller() then
                            return oldray(origin, direction)
                        end
                        local calling = getcallingscript()
                        if calling then
                            local list = {'ControlScript', 'ControlModule'}
                            if table.find(list, tostring(calling)) then
                                return oldray(origin, direction)
                            end
                        end
                        local args = {origin, direction}
                        Hooks.Ray(args)
                        return oldray(unpack(args))
                    end)
                else
                    print(Method.Value)
                    oldnamecall = hookmetamethod(game, '__namecall', function(...)
                        if getnamecallmethod() ~= Method.Value then
                            return oldnamecall(...)
                        end
                        if checkcaller() then
                            return oldnamecall(...)
                        end
                        local calling = getcallingscript()
                        if calling then
                            local list = {'ControlScript', 'ControlModule'}
                            if table.find(list, tostring(calling)) then
                                return oldnamecall(...)
                            end
                        end
                        local self, args = ..., {select(2, ...)}
                        local res = Hooks[Method.Value](args)
                        if res then
                            return unpack(res)
                        end
                        return oldnamecall(self, unpack(args))
                    end)
                end
                repeat
                    if CircleObject then
                        CircleObject.Position = UserInputService:GetMouseLocation()
                    end
                    if AutoFire.Enabled then
                        local origin = AutoFireMode.Value == 'Camera' and gameCamera.CFrame or entitylib.isAlive and entitylib.character.RootPart.CFrame or CFrame.identity
                        local ent = entitylib['Entity' .. Mode.Value]({
                            Range = Range.Value,
                            Wallcheck = true,
                            Part = 'Head',
                            Origin = (origin * fireoffset).Position,
                            Players = true,
                            NPCs = false
                        })
                        if mouse1click and (isrbxactive or iswindowactive)() then
                            if ent and canClick() then
                                if delayCheck < tick() then
                                    if mouseClicked then
                                        mouse1release()
                                        delayCheck = tick() + AutoFireShootDelay.Value
                                    else
                                        mouse1press()
                                    end
                                    mouseClicked = not mouseClicked
                                end
                            else
                                if mouseClicked then
                                    mouse1release()
                                end
                                mouseClicked = false
                            end
                        end
                    end
                    task.wait()
                until not SilentAim.Enabled
            else
                if oldnamecall then
                    hookmetamethod(game, '__namecall', oldnamecall)
                end
                if oldray then
                    hookfunction(Ray.new, oldray)
                end
                oldnamecall, oldray = nil, nil
            end
        end,
        ExtraText = function()
            return Method.Value:gsub('FindPartOnRay', '')
        end
    })
    Mode = SilentAim:AddDropdown({
        Name = 'Mode',
        List = {'Mouse', 'Position'},
        Function = function(val)
            if CircleObject then
                CircleObject.Visible = SilentAim.Enabled and val == 'Mouse'
            end
        end
    })
    Method = SilentAim:AddDropdown({
        Name = 'Method',
        List = {'FindPartOnRay', 'FindPartOnRayWithIgnoreList', 'FindPartOnRayWithWhitelist', 'ScreenPointToRay', 'ViewportPointToRay', 'Raycast', 'Ray'},
        Function = function(val)
            if SilentAim.Enabled then
                SilentAim:Toggle()
                SilentAim:Toggle()
            end
            MethodRay.Frame.Visible = val == 'Raycast'
        end
    })
    MethodRay = SilentAim:AddDropdown({
        Name = 'Raycast Type',
        List = {'All', 'Exclude', 'Include'},
        Darker = true,
        Visible = false
    })
    Range = SilentAim:AddSlider({
        Name = 'Range',
        Min = 1,
        Max = 1000,
        Default = 150,
        Function = function(val)
            if CircleObject then
                CircleObject.Radius = val
            end
        end,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    HitChance = SilentAim:AddSlider({
        Name = 'Hit Chance',
        Min = 0,
        Max = 100,
        Default = 85,
        Suffix = '%'
    })
    HeadshotChance = SilentAim:AddSlider({
        Name = 'Headshot Chance',
        Min = 0,
        Max = 100,
        Default = 65,
        Suffix = '%'
    })
    AutoFire = SilentAim:AddToggle({
        Name = 'AutoFire',
        Function = function(callback)
            AutoFireShootDelay.Frame.Visible = callback
            AutoFireMode.Frame.Visible = callback
        end
    })
    AutoFireShootDelay = SilentAim:AddSlider({
        Name = 'Delay',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Visible = false,
        Darker = true,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    AutoFireMode = SilentAim:AddDropdown({
        Name = 'Origin',
        List = {'RootPart', 'Camera'},
        Visible = false,
        Darker = true
    })
    Wallbang = SilentAim:AddToggle({
        Name = 'Wallbang'
    })
    SilentAim:AddToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Color = Modern.Libraries.uipallet.FinalColor
                CircleObject.Position = Modern.MainScreenGui.AbsoluteSize / 2
                CircleObject.Radius = Range.Value
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - CircleTransparency.Value
                CircleObject.Visible = SilentAim.Enabled and Mode.Value == 'Mouse'
            else
                pcall(function()
                    CircleObject.Visible = false
                    CircleObject:Remove()
                end)
            end
            CircleTransparency.Frame.Visible = callback
        end
    })
    CircleTransparency = SilentAim:AddSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Decimal = 10,
        Default = 0.5,
        Function = function(val)
            if CircleObject then
                CircleObject.Transparency = 1 - val
            end
        end,
        Darker = true,
        Visible = false
    })
    Projectile = SilentAim:AddToggle({
        Name = 'Projectile',
        Function = function(callback)
            ProjectileSpeed.Frame.Visible = callback
            ProjectileGravity.Frame.Visible = callback
        end
    })
    ProjectileSpeed = SilentAim:AddSlider({
        Name = 'Speed',
        Min = 1,
        Max = 1000,
        Default = 1000,
        Darker = true,
        Visible = false,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    ProjectileGravity = SilentAim:AddSlider({
        Name = 'Gravity',
        Min = 0,
        Max = 192.6,
        Default = 192.6,
        Darker = true,
        Visible = false
    })
end)
run(function()
    local TriggerBot
    local Targets
    local ShootDelay
    local Distance
    local rayCheck, delayCheck = RaycastParams.new(), tick()
    local function getTriggerBotTarget()
        rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
        local ray = workspace:Raycast(gameCamera.CFrame.Position, gameCamera.CFrame.LookVector * Distance.Value, rayCheck)
        if ray and ray.Instance then
            for _, v in entitylib.List do
                if v.Targetable and v.Character and v.Player then
                    if ray.Instance:IsDescendantOf(v.Character) then
                        return entitylib.isVulnerable(v) and v
                    end
                end
            end
        end
    end
    TriggerBot = Modern.Catalogs.Combat:AddModule({
        Name = 'Trigger Bot',
        Function = function(callback)
            if callback then
                repeat
                    if mouse1click and (isrbxactive or iswindowactive)() then
                        if getTriggerBotTarget() and canClick() then
                            if delayCheck < tick() then
                                if mouseClicked then
                                    mouse1release()
                                    delayCheck = tick() + ShootDelay.Value
                                else
                                    mouse1press()
                                end
                                mouseClicked = not mouseClicked
                            end
                        else
                            if mouseClicked then
                                mouse1release()
                            end
                            mouseClicked = false
                        end
                    end
                    task.wait()
                until not TriggerBot.Enabled
            else
                if mouse1click and (isrbxactive or iswindowactive)() then
                    if mouseClicked then
                        mouse1release()
                    end
                end
                mouseClicked = false
            end
        end
    })
    ShootDelay = TriggerBot:AddSlider({
        Name = 'Delay',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    Distance = TriggerBot:AddSlider({
        Name = 'Distance',
        Min = 0,
        Max = 1000,
        Default = 1000,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
end)
run(function()
    local FOV
    local Value
    local oldfov
    FOV = Modern.Catalogs.Render:AddModule({
        Name = 'FOV',
        Function = function(callback)
            if callback then
                oldfov = gameCamera.FieldOfView
                repeat
                    gameCamera.FieldOfView = Value.Value
                    task.wait()
                until not FOV.Enabled
            else
                gameCamera.FieldOfView = oldfov
            end
        end
    })
    Value = FOV:AddSlider({
        Name = 'FOV',
        Min = 30,
        Max = 120
    })
end)
run(function()
    local TargetStrafe
    local Targets
    local SearchRange
    local StrafeRange
    local YFactor
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    local module, old
    TargetStrafe = Modern.Catalogs.Movement:AddModule({
        Name = 'Target Strafe',
        Function = function(callback)
            if callback then
                if not module then
                    local suc = pcall(function()
                        module = require(lplr.PlayerScripts.PlayerModule).controls
                    end)
                    if not suc then
                        module = {}
                    end
                end
                old = module.moveFunction
                local flymod, ang, oldent = Modern.Modules.Fly or {
                    Enabled = false
                }
                module.moveFunction = function(self, vec, face)
                    local ent = not UserInputService:IsKeyDown(Enum.KeyCode.S) and entitylib.EntityPosition({
                        Range = SearchRange.Value,
                        Wallcheck = false,
                        Part = 'RootPart',
                        Players = true,
                        NPCs = false
                    })
                    if ent then
                        local root, targetPos = entitylib.character.RootPart, ent.RootPart.Position
                        rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, ent.Character}
                        rayCheck.CollisionGroup = root.CollisionGroup
                        if flymod.Enabled or workspace:Raycast(targetPos, Vector3.new(0, - 70, 0), rayCheck) then
                            local factor, localPosition = 0, root.Position
                            if ent ~= oldent then
                                ang = math.deg(select(2, CFrame.lookAt(targetPos, localPosition):ToEulerAnglesYXZ()))
                            end
                            local yFactor = math.abs(localPosition.Y - targetPos.Y) * (YFactor.Value / 100)
                            local entityPos = Vector3.new(targetPos.X, localPosition.Y, targetPos.Z)
                            local newPos = entityPos + (CFrame.Angles(0, math.rad(ang), 0).LookVector * (StrafeRange.Value - yFactor))
                            local startRay, endRay = entityPos, newPos
                            if not wallcheck and workspace:Raycast(targetPos, (localPosition - targetPos), rayCheck) then
                                startRay, endRay = entityPos + (CFrame.Angles(0, math.rad(ang), 0).LookVector * (entityPos - localPosition).Magnitude), entityPos
                            end
                            local ray = workspace:Blockcast(CFrame.new(startRay), Vector3.new(1, entitylib.character.HipHeight + (root.Size.Y / 2), 1), (endRay - startRay), rayCheck)
                            if (localPosition - newPos).Magnitude < 3 or ray then
                                factor = (8 - math.min((localPosition - newPos).Magnitude, 3))
                                if ray then
                                    newPos = ray.Position + (ray.Normal * 1.5)
                                    factor = (localPosition - newPos).Magnitude > 3 and 0 or factor
                                end
                            end
                            if not flymod.Enabled and not workspace:Raycast(newPos, Vector3.new(0, - 70, 0), rayCheck) then
                                newPos = entityPos
                                factor = 40
                            end
                            ang += factor % 360
                            vec = ((newPos - localPosition) * Vector3.new(1, 0, 1)).Unit
                            vec = vec == vec and vec or Vector3.zero
                            TargetStrafeVector = vec
                        else
                            ent = nil
                        end
                    end
                    TargetStrafeVector = ent and vec or nil
                    oldent = ent
                    return old(self, vec, face)
                end
            else
                if module and old then
                    module.moveFunction = old
                end
                TargetStrafeVector = nil
            end
        end
    })
    SearchRange = TargetStrafe:AddSlider({
        Name = 'Search Range',
        Min = 1,
        Max = 30,
        Default = 24,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    StrafeRange = TargetStrafe:AddSlider({
        Name = 'Strafe Range',
        Min = 1,
        Max = 30,
        Default = 18,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    YFactor = TargetStrafe:AddSlider({
        Name = 'Y Factor',
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = '%'
    })
end)
run(function()
    local Shader
    local cacheLighting = {}
    local BlurEffect = Instance.new('BlurEffect')
    BlurEffect.Size = 6
    local ColorCorrectionEffect = Instance.new('ColorCorrectionEffect')
    ColorCorrectionEffect.Saturation = - 0.4
    local SnowEffect = Instance.new("Part")
    SnowEffect.Size = vector.create(200, 1, 200)
    SnowEffect.Transparency = 1
    SnowEffect.Anchored = true
    local SnowParticle = Instance.new("ParticleEmitter")
    SnowParticle.EmissionDirection = "Bottom"
    SnowParticle.Rate = 20000
    SnowParticle.Lifetime = NumberRange.new(3.5, 3.5)
    SnowParticle.Speed = NumberRange.new(50, 50)
    SnowParticle.Texture = "rbxassetid://92367298778210"
    SnowParticle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.4)})
    SnowParticle.SpreadAngle = Vector2.new(70, 70)
    SnowParticle.Parent = SnowEffect
    SnowParticle:Clone().Parent = SnowEffect
    SnowParticle:Clone().Parent = SnowEffect
    local Time = {}
    Shader = Modern.Catalogs.Other:AddModule({
        Name = 'Shader',
        Function = function(callback)
            if callback then
                cacheLighting = {Lighting.Ambient; Lighting.Brightness; Lighting.ColorShift_Bottom; Lighting.ColorShift_Top; Lighting.EnvironmentDiffuseScale; Lighting.EnvironmentSpecularScale; Lighting.GlobalShadows; Lighting.OutdoorAmbient; Lighting.ShadowSoftness; Lighting.TimeOfDay; }
                Lighting.Ambient = Color3.fromRGB(94, 99, 188)
                Lighting.Brightness = 4
                Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
                Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
                Lighting.EnvironmentDiffuseScale = 1
                Lighting.EnvironmentSpecularScale = 1
                Lighting.GlobalShadows = true
                Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
                Lighting.ShadowSoftness = 3
                Lighting.TimeOfDay = (Time.Value or '00') .. ':30:00'
                SnowEffect.Parent = workspace
                Shader:Clean(RunService.RenderStepped:Connect(function()
                    if entitylib.isAlive then
                        SnowEffect.Position = entitylib.character.RootPart.Position + vector.create(0, 90, 0)
                    end
                end))
                BlurEffect.Parent = Lighting
                ColorCorrectionEffect.Parent = Lighting
            else
                Lighting.Ambient = cacheLighting[1]
                Lighting.Brightness = cacheLighting[2]
                Lighting.ColorShift_Bottom = cacheLighting[3]
                Lighting.ColorShift_Top = cacheLighting[4]
                Lighting.EnvironmentDiffuseScale = cacheLighting[5]
                Lighting.EnvironmentSpecularScale = cacheLighting[6]
                Lighting.GlobalShadows = cacheLighting[7]
                Lighting.OutdoorAmbient = cacheLighting[8]
                Lighting.ShadowSoftness = cacheLighting[9]
                Lighting.TimeOfDay = cacheLighting[10]
                SnowEffect.Parent = nil
                BlurEffect.Parent = nil
                ColorCorrectionEffect.Parent = nil
            end
        end,
        Default = false
    })
    Time = Shader:AddSlider({
        Name = 'Time',
        Min = 0,
        Max = 24,
        Default = 12,
        Function = function(val)
            if Shader.Enabled then
                Lighting.TimeOfDay = val .. ':00:00'
            end
        end
    })
end)
run(function()
    local AirJump
    local Velocity
    AirJump = Modern.Catalogs.Player:AddModule({
        Name = "AirJump",
        Function = function(callback)
            if callback then
                AirJump:Clean(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
                        while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
                            if entitylib.isAlive and lplr.Character.PrimaryPart then
                                local PrimaryPart = lplr.Character.PrimaryPart
                                PrimaryPart.Velocity = vector.create(PrimaryPart.Velocity.X, Velocity.Value, PrimaryPart.Velocity.Z)
                            end
                            wait()
                        end
                    end
                end))
                if UserInputService.TouchEnabled then
                    local Jumping = false
                    local JumpButton = lplr.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
                    AirJump:Clean(JumpButton.MouseButton1Down:Connect(function()
                        Jumping = true
                    end))
                    AirJump:Clean(JumpButton.MouseButton1Up:Connect(function()
                        Jumping = false
                    end))
                    AirJump:Clean(RunService.RenderStepped:Connect(function()
                        if Jumping and entitylib.isAlive and lplr.Character then
                            local PrimaryPart = lplr.Character.PrimaryPart
                            PrimaryPart.Velocity = vector.create(PrimaryPart.Velocity.X, Velocity.Value, PrimaryPart.Velocity.Z)
                        end
                    end))
                end
            end
        end
    })
    Velocity = AirJump:AddSlider({
        Name = 'Velocity',
        Min = 50,
        Max = 300,
        Default = 50
    })
end)
run(function()
    local Trails
    local Texture
    local Lifetime
    local Thickness
    local Particle
    local ParticleMain
    Trails = Modern.Catalogs.Render:AddModule({
        Name = 'Trails',
        Function = function(callback)
            if callback then
                ParticleMain = Instance.new("Part")
                ParticleMain.Size = vector.create(0, 0, 0)
                ParticleMain.Transparency = 0
                ParticleMain.CanCollide = false
                ParticleMain.Anchored = true
                Particle = Instance.new('ParticleEmitter')
                Particle.EmissionDirection = "Bottom"
                Particle.Rate = 5
                Particle.Lifetime = NumberRange.new(3.5, 3.5)
                Particle.Speed = NumberRange.new(0, 0)
                Particle.Texture = "rbxassetid://84083457957085"
                Particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, Thickness.Value / 5), NumberSequenceKeypoint.new(0.02, Thickness.Value), NumberSequenceKeypoint.new(1, 0)})
                Particle.SpreadAngle = Vector2.new(0, 0)
                Particle.Parent = ParticleMain
                Trails:Clean(Particle)
                Trails:Clean(ParticleMain)
                Trails:Clean(RunService.RenderStepped:Connect(function(ent)
                    if entitylib.isAlive then
                        ParticleMain.Position = entitylib.character.RootPart.Position - vector.create(0, 1, 0)
                    end
                end))
                ParticleMain.Parent = workspace
            else
                Particle = nil
                ParticleMain = nil
            end
        end
    })
    Rate = Trails:AddSlider({
        Name = 'Rate',
        Min = 0,
        Max = 10,
        Default = 5,
        Decimal = 10,
        Function = function(val)
            if Particle then
                Particle.Rate = val
            end
        end
    })
    Lifetime = Trails:AddSlider({
        Name = 'Lifetime',
        Min = 1,
        Max = 5,
        Default = 3,
        Decimal = 10,
        Function = function(val)
            if Particle then
                Particle.Lifetime = NumberRange.new(val, val)
            end
        end,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    Thickness = Trails:AddSlider({
        Name = 'Thickness',
        Min = 0,
        Max = 2,
        Default = 1,
        Decimal = 100,
        Function = function(val)
            if Particle then
                Particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, val), NumberSequenceKeypoint.new(1, 0)})
            end
        end,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
end)

end)

if not __modernOk then
    local __err = tostring(__modernErr)
    if writefile then
        pcall(writefile, "Modern/startup_error.txt", __err)
    end
    error(__err)
end


