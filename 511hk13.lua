local HttpService = game:GetService("HttpService")  
local UIS = game:GetService("UserInputService")  
local Players = game:GetService("Players")  
local Lighting = game:GetService("Lighting")  
local RunService = game:GetService("RunService")  
local TweenService = game:GetService("TweenService")  
local Stats = game:GetService("Stats")  
local lp = Players.LocalPlayer  
local cam = workspace.CurrentCamera  
local mouse = lp:GetMouse()  
  
  
  
local statusById = {}  
  
local function getStatusById(uid)  
	return statusById[uid] or "Neutral"  
end  
  
local function getStatusForPlayer(p)  
	return getStatusById(p.UserId)  
end  
  
local cfg = {  
	notificationsEnabled=true, watermark=true,  
	camlock=false, camlockKey=Enum.KeyCode.Q, camlockSmooth=0.15,  
	camlockPredX=0.13, camlockPredY=0.08, camlockPredZ=0.13,  
	camlockJumpPredEnabled=false, camlockJumpPredY=0.15,  
	camlockFallPredEnabled=false, camlockFallPredY=0.05,  
	camlockStaticOffsetEnabled=false, camlockStaticOffsetY=0,  
	camlockAirPredXEnabled=false, camlockAirPredX=0, camlockAirPredSmooth=0.3, camlockAirPredCurve=2, camlockAirPredCurveHeight=0,  
	camlockSensitivity=1,  
	camlockPart="Head", camlockTeamCheck=false, camlockWallCheck=false,  
	camlockKOCheck=false, camlockMaxDist=500,  
	camlockFOVEnabled=false, camlockFOVRadius=300,  
	camlockFOVColor=Color3.fromRGB(0,200,130),  
	camlockClosestPart=false, camlockMode="Toggle", camlockAimStyle="Linear",  
	camlockAirPart="LowerTorso", camlockUseAirPart=false,  
	camlockFOVFilled=false, camlockFOVOpacity=0.1, camlockTargetBots=false,  
	silentAim=false, silentAimPredX=0.12, silentAimPredY=0.12,  
	silentAimPart="Head", silentAimFOV=200, silentAimFOVShow=false,  
	silentAimTeamCheck=false, silentAimWallCheck=false, silentAimKOCheck=false,  
	silentAimUseAirPart=false, silentAimAirPart="LowerTorso",  
	silentAimMaxDist=500, silentAimFOVColor=Color3.fromRGB(0,200,130),  
	silentAimFOVFilled=false, silentAimKey=Enum.KeyCode.Unknown,  
	silentAimMode="Toggle", silentAimMethod="Lethal", silentAimClosestPart=false,  
	silentAimHitChance=100, silentAimFOVOpacity=0.1, silentAimTargetBots=false,  
	esp=false, espBones=false, espBoxes=false, espBoxFilled=false,  
	espNames=false, espHealth=false, espDistance=false, espChams=false,  
	espNameStyle="Default", espMode="Dynamic",
	espMaxDist=500, espTracers=false, espHeadDot=false, espFillTransparency=0.85,  
	espBoxColor=Color3.fromRGB(0,200,130), espBoxFillColor=Color3.fromRGB(0,200,130), espBoneColor=Color3.fromRGB(0,200,130),  
	espNameColor=Color3.fromRGB(255,255,255), espDistColor=Color3.fromRGB(140,140,170),  
	espHealthColor=Color3.fromRGB(100,255,150), espTracerColor=Color3.fromRGB(0,200,130),  
	espHeadDotColor=Color3.fromRGB(0,200,130), espChamsFillColor=Color3.fromRGB(0,200,130),
	espChamsOutlineColor=Color3.fromRGB(0,200,130), espChamsTransparency=0.5,
	espTargetNameColor=Color3.fromRGB(255,50,50),  
	weaponChams=false, weaponChamsRainbow=false, weaponChamsFill=false,  
	weaponChamsTransparency=0.65, weaponChamsColor=Color3.fromRGB(255,170,0),
	weaponChamsFillColor=Color3.fromRGB(255,170,0), weaponChamsOutlineColor=Color3.fromRGB(255,170,0),
	rapidFireEnabled=false, rapidFireDelay=0.01, rapidFireKey=Enum.KeyCode.Unknown,  
	rapidFireSpecificEnabled=false, rapidFireWeapons="Revolver,Double-Barrel SG,TacticalShotgun",  
	spreadEnabled=false, spreadAmount=10, spreadSpecificEnabled=false, spreadWeapons="Revolver,Double-Barrel SG,TacticalShotgun",  
	bulletTeleportEnabled=false, bulletTeleportOffset=5,  
	rangeExpanderEnabled=true, rangeExpanderRange=999999,  
	forceHitEnabled=false, forceHitKey=Enum.KeyCode.Unknown,  
	bulletTeleportLineEnabled=true, bulletTeleportLineColor=Color3.fromRGB(255,100,0),  
	walkspeed=16, walkspeedKey=Enum.KeyCode.Unknown, slippery=false,  
	jumppower=50, jumppowerKey=Enum.KeyCode.Unknown,  
	fov=70, flightEnabled=false, flightSpeed=50, flightKey=Enum.KeyCode.Unknown,  
	noclip=false, infiniteJump=false,  
	spin360Key=Enum.KeyCode.C, spin360Speed=5, spin360Direction=1, spin360Loops=1,  
	textureColorEnabled=false, textureColor=Color3.fromRGB(255,255,255),  
	fogEnabled=false, fogStart=0, fogEnd=1000, fogColor=Color3.fromRGB(180,180,200),  
	rotatingSkybox=false, selectedSkybox=nil, lightingMode=nil,  
	fpsBoostEnabled=false, currentMaterial=nil,  
	fullbrightEnabled=false,  
	rainEnabled=false, rainbowRain=false, rainRadius=68, rainSpeed=3,  
	rainAmount=60, rainLength=2, rainColor=Color3.fromRGB(0,200,130), rainTransparency=0.3,  
	guiKey=Enum.KeyCode.RightControl,  
}  

local camlockTarget=nil  

-- Screen Indicator (cider-style panel)
local indicatorEnabled   = true
local indicatorAccent    = Color3.fromRGB(0, 200, 130)
local indicatorFeature   = Color3.fromRGB(255, 255, 255)
local indicatorPos       = "Bottom Center"  -- "Bottom Center" | "Top Left" | "Top Right" | "Bottom Left" | "Bottom Right"
local indicatorUI        = nil   -- ScreenGui
local indicatorTitle     = nil   -- TextLabel
local indicatorLabels    = {}    -- array of TextLabel
local INDICATOR_MAX_ROWS = 10


local flightBody=nil  
local airPredCurrentX=0  
local spinActive=false  
local noclipConn=nil  
local walkspeedConn=nil  
local walkspeedEnabled=false  
local jumpConnection=nil  
local infiniteJumpConn=nil  
local fullbrightConn=nil  
local lightingConn=nil  
local rotatingSkyConn=nil  
local silentAimHooksInstalled=false  
local oldIndexHook=nil  
local _checkcaller = checkcaller  
local silentAimCachedPart=nil  
local silentAimCachedPred=nil  
local isfiring=false  
local lastRapidFire=0  
local btpLine=Drawing.new("Line")  
btpLine.Thickness=1.5; btpLine.Color=Color3.fromRGB(255,100,0); btpLine.Visible=false  
local origL={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,GlobalShadows=Lighting.GlobalShadows,FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor}  
local origMats={}  
local origColors={}  
local origSky=nil  
local activeWeaponHighlights={}  
local rainDrops={}  
local rainbowHue=0  
local espData={}  
local botEspData={}  
local fovCircle=Drawing.new("Circle")  
fovCircle.Thickness=1.5;fovCircle.NumSides=64;fovCircle.Radius=200  
fovCircle.Color=Color3.fromRGB(0,200,130);fovCircle.Filled=false;fovCircle.Visible=false;fovCircle.Transparency=0.9  
  
local camlockFOVCircle=Drawing.new("Circle")  
camlockFOVCircle.Thickness=1.5;camlockFOVCircle.NumSides=64;camlockFOVCircle.Radius=300  
camlockFOVCircle.Color=Color3.fromRGB(0,200,130);camlockFOVCircle.Filled=false;camlockFOVCircle.Visible=false;camlockFOVCircle.Transparency=0.9  
  
local function getHum(p) local c=p and ((type(p)=="table" and p.char) or p.Character); return c and c:FindFirstChildOfClass("Humanoid") end  
local function getHRP(p) local c=p and p.Character; return c and c:FindFirstChild("HumanoidRootPart") end  
  
local function isAlive(p)  
	local h=getHum(p); if not h or h.Health<=0 then return false end  
	local c=p.Character; if c then local be=c:FindFirstChild("BodyEffects"); if be then local ko=be:FindFirstChild("K.O"); if ko and ko.Value then return false end end end  
	return true  
end  
  
local function sameTeam(p) return lp.Team and p.Team and lp.Team==p.Team end  
  
local function wallBetween(pos)  
	local ro=cam.CFrame.Position; local rd=pos-ro  
	local params=RaycastParams.new(); params.FilterDescendantsInstances={lp.Character}; params.FilterType=Enum.RaycastFilterType.Exclude  
	local hit=workspace:Raycast(ro,rd,params); if not hit then return false end  
	for _,p in pairs(Players:GetPlayers()) do if p.Character and hit.Instance:IsDescendantOf(p.Character) then return false end end  
	return true  
end  

local function getTargets(teamCheck,maxDist,targetBots,cursorPos,fovR)  
	local results={}  
	local priorityResults={}  
	local mloc=UIS:GetMouseLocation()  
	local center=cursorPos or mloc  
	local distLimit=maxDist or 500  
  
	for _,p in pairs(Players:GetPlayers()) do  
		if p==lp then continue end  
		local st=getStatusById(p.UserId)  
		if st=="Friendly" then continue end  
		if teamCheck and sameTeam(p) then continue end  
		if not isAlive(p) then continue end  
		local hrp=getHRP(p); if not hrp then continue end  
		if (hrp.Position-cam.CFrame.Position).Magnitude>distLimit then continue end  
		local sp,on=cam:WorldToViewportPoint(hrp.Position)  
		local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude  
		if st=="Priority" then  
			if not on then continue end  
			if fovR and d>fovR then continue end  
			table.insert(priorityResults,{char=p.Character,player=p,isBot=false,dist=d,hrp=hrp})  
		else  
			if not on then continue end  
			if not fovR or d<=fovR then  
				table.insert(results,{char=p.Character,player=p,isBot=false,dist=d,hrp=hrp})  
			end  
		end  
	end  
  
	if targetBots then  
		local pc={}; for _,p in pairs(Players:GetPlayers()) do if p.Character then pc[p.Character]=true end end  
		for _,obj in pairs(workspace:GetDescendants()) do  
			if obj:IsA("Humanoid") and obj.Health>0 then  
				local char=obj.Parent  
				if char and not pc[char] then  
					local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end  
					if (hrp.Position-cam.CFrame.Position).Magnitude>distLimit then continue end  
					local sp,on=cam:WorldToViewportPoint(hrp.Position); if not on then continue end  
					local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude  
					if not fovR or d<=fovR then table.insert(results,{char=char,player=nil,isBot=true,dist=d,hrp=hrp}) end  
					if cfg.esp and not botEspData[char] then  
						local bd={}  
						local function nd(t,props) local dr=Drawing.new(t); for k,v in pairs(props) do dr[k]=v end; return dr end  
						bd.box=nd("Square",{Thickness=1,Color=Color3.fromRGB(255,120,0),Filled=false,Visible=false})  
						bd.name=nd("Text",{Size=11,Color=Color3.fromRGB(255,200,100),Outline=true,Center=true,Visible=false,Text="[BOT]"})  
						bd.dist=nd("Text",{Size=10,Color=Color3.fromRGB(200,150,80),Outline=true,Center=true,Visible=false})  
						bd.hbg=nd("Square",{Thickness=1,Color=Color3.fromRGB(20,20,20),Filled=true,Visible=false})  
						bd.hfill=nd("Square",{Thickness=1,Color=Color3.fromRGB(255,180,0),Filled=true,Visible=false})  
						botEspData[char]=bd  
					end  
				end  
			end  
		end  
	end  
  
	table.sort(priorityResults,function(a,b) return a.dist<b.dist end)  
	table.sort(results,function(a,b) return a.dist<b.dist end)  
	local combined={}  
	for _,v in ipairs(priorityResults) do table.insert(combined,v) end  
	for _,v in ipairs(results) do table.insert(combined,v) end  
	return combined  
end  
  
local function closestToCursor(fovR,teamCheck,maxDist)  
	local targets=getTargets(teamCheck,maxDist,cfg.camlockTargetBots,nil,fovR)  
	if #targets>0 then local t=targets[1]; if t.player then return t.player end; return t end  
	return nil  
end  
  
local function closestToCursorSilent(fovR,teamCheck,maxDist)  
	local targets=getTargets(teamCheck,maxDist,cfg.silentAimTargetBots,nil,fovR)  
	if #targets>0 then local t=targets[1]; if t.player then return t.player end; return t end  
	return nil  
end  

local function getPredicted(part)  
	if not part then return nil end  
	local v=part.AssemblyLinearVelocity; local predY=cfg.camlockPredY  
	if camlockTarget then  
		local ch=(type(camlockTarget)=="table" and camlockTarget.char) or camlockTarget.Character  
		if ch then local hum=ch:FindFirstChildOfClass("Humanoid"); if hum then  
			if cfg.camlockJumpPredEnabled and v.Y>5 and hum.FloorMaterial==Enum.Material.Air then predY=cfg.camlockJumpPredY  
			elseif cfg.camlockFallPredEnabled and v.Y<-5 and hum.FloorMaterial==Enum.Material.Air then predY=cfg.camlockFallPredY end  
		end end  
	end  
	local base=part.Position+Vector3.new(v.X*cfg.camlockPredX,v.Y*predY,v.Z*cfg.camlockPredZ)  
	if cfg.camlockStaticOffsetEnabled then base=base+Vector3.new(0,cfg.camlockStaticOffsetY,0) end  
	if cfg.camlockAirPredXEnabled and cfg.camlockAirPredX~=0 then  
		local ch=(type(camlockTarget)=="table" and camlockTarget.char) or (camlockTarget and camlockTarget.Character)  
		if ch then  
			local hm=ch:FindFirstChildOfClass("Humanoid")  
			if hm then  
				local inAir=hm.FloorMaterial==Enum.Material.Air  
				local targetX=0; local targetYOffset=0  
				if inAir then  
					local velY=v.Y; local norm=math.clamp(velY/50,-1,1)  
					local curved=(norm>=0 and 1 or -1)*(math.abs(norm)^math.max(cfg.camlockAirPredCurve,0.5))  
					targetX=cfg.camlockAirPredX*curved  
					if cfg.camlockAirPredCurveHeight~=0 then  
						local hf=1-math.abs(norm); hf=hf^0.5; targetYOffset=cfg.camlockAirPredCurveHeight*hf  
					end  
				end  
				local ls=math.clamp(cfg.camlockAirPredSmooth,0.01,1)  
				airPredCurrentX=airPredCurrentX+(targetX-airPredCurrentX)*ls  
				if math.abs(airPredCurrentX)<0.001 then airPredCurrentX=0 end  
				if math.abs(airPredCurrentX)>0 then base=base+cam.CFrame.RightVector*airPredCurrentX end  
				if targetYOffset~=0 then base=base+Vector3.new(0,targetYOffset,0) end  
			end  
		end  
	else airPredCurrentX=0 end  
	return base  
end  
  
local BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"}}  
  
local function newDraw(t,props) local d=Drawing.new(t); for k,v in pairs(props) do d[k]=v end; return d end  
  
local function createESP(plr)  
	if plr==lp or espData[plr] then return end  
	local d={}  
	d.hl=Instance.new("Highlight");d.hl.FillTransparency=1;d.hl.OutlineColor=cfg.espChamsOutlineColor;d.hl.Enabled=false
	d.box=newDraw("Square",{Thickness=1,Color=cfg.espBoxColor,Filled=false,Visible=false})  
	d.boxFill=newDraw("Square",{Thickness=1,Color=cfg.espBoxColor,Filled=true,Transparency=0.85,Visible=false})  
	d.name=newDraw("Text",{Size=11,Color=cfg.espNameColor,Outline=true,Center=true,Visible=false,Font=2})  
	d.dist=newDraw("Text",{Size=10,Color=cfg.espDistColor,Outline=true,Center=true,Visible=false,Font=2,Text="0m"})  
	d.hbg=newDraw("Square",{Thickness=1,Color=Color3.fromRGB(20,20,20),Filled=true,Visible=false})  
	d.hfill=newDraw("Square",{Thickness=1,Color=cfg.espHealthColor,Filled=true,Visible=false})  
	d.headDot=newDraw("Circle",{Thickness=1,NumSides=16,Radius=4,Color=cfg.espHeadDotColor,Filled=true,Visible=false})  
	d.tracer=newDraw("Line",{Thickness=1,Color=cfg.espTracerColor,Visible=false})  
	d.bones={}; for _=1,#BONES do table.insert(d.bones,newDraw("Line",{Thickness=1,Color=cfg.espBoneColor,Visible=false})) end  
	d.billboard=nil  
	espData[plr]=d
	-- on respawn: rebuild the ESP entry cleanly so the render loop picks up the new character
	plr.CharacterAdded:Connect(function(char)
		if not cfg.esp then return end
		task.defer(function()
			removeESP(plr)
			char:WaitForChild("HumanoidRootPart", 5)
			task.wait(0.1)
			createESP(plr)
		end)
	end)
end  
  
local function buildBillboard(plr, d)  
	if d.billboard then pcall(function() d.billboard:Destroy() end); d.billboard=nil end  
	local char=plr.Character; if not char then return end  
	local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end  
	local bb=Instance.new("BillboardGui")  
	bb.Name="KlaxESPName"; bb.AlwaysOnTop=true  
	bb.Size=UDim2.new(0,200,0,30); bb.StudsOffset=Vector3.new(0,3,0)  
	bb.Adornee=hrp; bb.Parent=hrp  
	local lbl=Instance.new("TextLabel",bb)  
	lbl.Name="NameLabel"; lbl.BackgroundTransparency=1  
	lbl.Size=UDim2.new(1,0,1,0); lbl.TextColor3=cfg.espNameColor  
	lbl.TextSize=14; lbl.Font=Enum.Font.GothamBold  
	lbl.Text=plr.Name; lbl.TextStrokeTransparency=0  
	lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.TextScaled=false; lbl.ZIndex=10  
	d.billboard=bb  
end  
  
local function destroyBillboard(d)  
	if d.billboard then pcall(function() d.billboard:Destroy() end); d.billboard=nil end  
end  
  
local function removeESP(plr)  
	local d=espData[plr]; if not d then return end  
	pcall(function() d.hl:Destroy() end)
	destroyBillboard(d)  
	d.box:Remove();d.boxFill:Remove();d.name:Remove();d.dist:Remove()  
	d.hbg:Remove();d.hfill:Remove();d.headDot:Remove();d.tracer:Remove()  
	for _,b in pairs(d.bones) do b:Remove() end; espData[plr]=nil  
end  
  
local function hideAllESP(d)  
	d.box.Visible=false;d.boxFill.Visible=false;d.name.Visible=false;d.dist.Visible=false  
	d.hbg.Visible=false;d.hfill.Visible=false;d.headDot.Visible=false;d.tracer.Visible=false  
	for _,b in pairs(d.bones) do b.Visible=false end  
end  
  
local function toggleESP(state)  
	if state then for _,p in pairs(Players:GetPlayers()) do createESP(p) end  
	else for p in pairs(espData) do removeESP(p) end end  
end  
  
Players.PlayerAdded:Connect(function(p) if cfg.esp then createESP(p) end end)  
Players.PlayerRemoving:Connect(removeESP)  

local function getWCOutlineColor() if cfg.weaponChamsRainbow then return Color3.fromHSV((tick()%5)/5,1,1) end; return cfg.weaponChamsOutlineColor end
local function getWCFillColor() if cfg.weaponChamsRainbow then return Color3.fromHSV((tick()%5)/5,1,1) end; return cfg.weaponChamsFillColor end
local function getWCColor() return getWCOutlineColor() end
local function weaponAllowed(n) n=n:lower(); return n:find("rev") or n:find("db") or n:find("tac") or n:find("revolver") or n:find("double") or n:find("shotgun") end  
local function removeWeaponGlow(m) local g=activeWeaponHighlights[m]; if g then g:Destroy(); activeWeaponHighlights[m]=nil end end  
  
local function addWeaponGlow(m)  
	if activeWeaponHighlights[m] then return end  
	local g=Instance.new("Highlight");g.Adornee=m;g.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop  
	g.OutlineTransparency=0;g.FillTransparency=cfg.weaponChamsFill and(1-cfg.weaponChamsTransparency)or 1  
	g.OutlineColor=getWCOutlineColor();g.FillColor=getWCFillColor();g.Parent=m;activeWeaponHighlights[m]=g  
end  
  
local function refreshWeaponGlow()  
	for m,g in pairs(activeWeaponHighlights) do  
		if not m or not m.Parent then activeWeaponHighlights[m]=nil  
		else g.OutlineColor=getWCOutlineColor();g.FillColor=getWCFillColor();g.FillTransparency=cfg.weaponChamsFill and(1-cfg.weaponChamsTransparency)or 1 end  
	end  
end  
  
local function updateWeaponChams()  
	if not cfg.weaponChams then for m in pairs(activeWeaponHighlights) do removeWeaponGlow(m) end; return end  
	local c=lp.Character; if c then for _,v in ipairs(c:GetChildren()) do if v:IsA("Tool") and weaponAllowed(v.Name) then addWeaponGlow(v) end end end  
	for _,v in ipairs(cam:GetChildren()) do if v:IsA("Model") and weaponAllowed(v.Name) then addWeaponGlow(v) end end  
end  
  
local function getRainbowColor() rainbowHue=(rainbowHue+0.01)%1; return Color3.fromHSV(rainbowHue,1,1) end  
  
-- SKIN CHANGER
local SC_SKINS = {
	"None","Ascension","Galaxy","Neon","Inferno","Void","Frost","Shadow","Gold","Silver",
	"Diamond","Ruby","Emerald","Sapphire","Obsidian","Phantom","Ghost","Toxic","Cyber",
	"Retro","Anime","Nature","Ocean","Lava","Storm","Arctic","Crimson","Midnight",
	"Sunrise","Sunset","Beta","Alpha","Classic","Legacy","Prestige","Elite","Champion",
	"Titan","Colossus","Specter","Wraith","Banshee","Reaper","Hunter","Stalker",
	"Predator","Viper","Cobra","Dragon","Phoenix","Hydra","Kraken","Tempest",
	"Blizzard","Thunder","Lightning","Earthquake","Volcano","Tsunami","Avalanche",
	"GPOII","Brainrot","Zombie","Robot","Ninja","Hero","Toy","Pirate","Knight",
	"Vampire","Werewolf","Elder","Cartoony","Mage","Bubbly","Astronaut","Stylish",
	"Wild West","XMAS","Halloween","Jellyfish","Duck","Flower","Cat","Ice","Shrimp",
	"Arcane","Blaze","Heartbreak","Sushi","SoulII","Short Cake","Music","Car","Beary",
}

local scSkins = {
	DB  = "None",
	Rev = "None",
	Tac = "None",
	SMG = "None",
	SG  = "None",
}

local scHandleMap = { DB_HANDLE="DB", REV_HANDLE="Rev" }

local function scIsBasePart(x) return typeof(x)=="Instance" and x:IsA("BasePart") end

local function scEnsurePrimary(model)
	if not(model and model:IsA("Model")) then return end
	if not scIsBasePart(model.PrimaryPart) then
		local f=model:FindFirstChildWhichIsA("BasePart"); if f then model.PrimaryPart=f end
	end
	return model.PrimaryPart
end

local function scPrepParts(model, isKnife)
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide=false;p.Anchored=false;p.Massless=true end
		if isKnife and p:IsA("MeshPart") then
			local sa=p:FindFirstChildOfClass("SurfaceAppearance"); if sa then sa:Destroy() end
			if p.TextureID=="" then local n=p.Name:lower(); if n:find("box") or n:find("cube") or n:find("hit") then p.Transparency=1 end end
		end
	end
end

local function scWeld(a,b)
	if scIsBasePart(a) and scIsBasePart(b) then
		local w=Instance.new("WeldConstraint"); w.Part0=a; w.Part1=b; w.Parent=a
	end
end

local function scApplyOnHolder(holder, skinmodel)
	if not holder or not skinmodel then return end
	local handle=holder:FindFirstChild("Handle"); if not scIsBasePart(handle) then return end
	local old=holder:FindFirstChild("SkinModel"); if old then old:Destroy() end
	handle.Transparency=0 -- reset first
	local clone=skinmodel:Clone(); clone.Name="SkinModel"
	local pp=scEnsurePrimary(clone); if not scIsBasePart(pp) then return end
	scPrepParts(clone, holder.Name:find("Knife") and true or false)
	clone.Parent=holder; clone:PivotTo(handle.CFrame)
	for _,p in ipairs(clone:GetDescendants()) do if p:IsA("BasePart") then scWeld(handle,p) end end
	handle.Transparency=1
end

local function scRemoveSkin(holder)
	if not holder then return end
	local old=holder:FindFirstChild("SkinModel"); if old then old:Destroy() end
	local handle=holder:FindFirstChild("Handle"); if scIsBasePart(handle) then handle.Transparency=0 end
end

local scWeaponMap = { DB="DoubleBarrel", Rev="Revolver", Tac="TacticalShotgun", SMG="SMG", SG="Shotgun" }
local scToolMap   = { DoubleBarrel="DB", Revolver="Rev", TacticalShotgun="Tac", SMG="SMG", Shotgun="SG" }

local function scGetModel(weaponName, skinName, timeout)
	if not skinName or skinName=="" or skinName=="None" then return nil end
	local wraps=game:GetService("ReplicatedStorage"):WaitForChild("Wraps", timeout or 3)
	if not wraps then return nil end
	local folder=wraps:WaitForChild("["..weaponName.."]", timeout or 3)
	if not folder then return nil end
	return folder:FindFirstChild(skinName)
end

local function scApplyTool(tool)
	if not tool or not tool:IsA("Tool") then return end
	local wn=tool.Name:match("^%[(.+)%]$"); if not wn then return end
	local key=scToolMap[wn]; if not key then return end
	local skin=scSkins[key]
	if not skin or skin=="None" then scRemoveSkin(tool); return end
	local model=scGetModel(wn, skin)
	if model then pcall(scApplyOnHolder, tool, model) else scRemoveSkin(tool) end
end

local function scApplyChar(char)
	if not char then return end
	for _,tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then scApplyTool(tool) end
	end
	for handleName,key in pairs(scHandleMap) do
		local folder=char:FindFirstChild(handleName)
		if folder then
			local wn=scWeaponMap[key]
			local skin=scSkins[key]
			if not skin or skin=="None" then scRemoveSkin(folder)
			elseif wn then
				local model=scGetModel(wn, skin)
				if model then pcall(scApplyOnHolder, folder, model) else scRemoveSkin(folder) end
			end
		end
	end
end

lp.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	scApplyChar(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then task.wait(0.1); scApplyTool(child) end
		if scHandleMap[child.Name] then task.defer(function() scApplyChar(char) end) end
	end)
end)
if lp.Character then
	scApplyChar(lp.Character)
	lp.Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then task.wait(0.1); scApplyTool(child) end
	end)
end

local function rebuildRain()  
	for _,d in pairs(rainDrops) do if d.line then d.line:Remove() end end; rainDrops={}  
	for i=1,cfg.rainAmount do  
		local line=Drawing.new("Line");line.Thickness=1;line.Transparency=1-cfg.rainTransparency;line.Color=cfg.rainColor;line.Visible=cfg.rainEnabled  
		table.insert(rainDrops,{line=line,offset=Vector3.new(math.random(-cfg.rainRadius,cfg.rainRadius),math.random(0,35),math.random(-cfg.rainRadius,cfg.rainRadius)),yPos=math.random(0,50)})  
	end  
end  
  
rebuildRain()  
  
RunService.RenderStepped:Connect(function(dt)  
	if not cfg.rainEnabled then return end  
	local c=lp.Character; if not c then return end; local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end  
	for _,drop in pairs(rainDrops) do  
		if drop.line then  
			drop.yPos=drop.yPos-(cfg.rainSpeed*dt*60)  
			if drop.yPos<-10 then drop.yPos=50; drop.offset=Vector3.new(math.random(-cfg.rainRadius,cfg.rainRadius),0,math.random(-cfg.rainRadius,cfg.rainRadius)) end  
			local s=hrp.Position+drop.offset+Vector3.new(0,drop.yPos,0)  
			local e=s-Vector3.new(0,cfg.rainLength,0)  
			local ss,so=cam:WorldToViewportPoint(s); local es,eo=cam:WorldToViewportPoint(e)  
			if so or eo then drop.line.From=Vector2.new(ss.X,ss.Y);drop.line.To=Vector2.new(es.X,es.Y);drop.line.Visible=true;drop.line.Color=cfg.rainbowRain and getRainbowColor() or cfg.rainColor;drop.line.Transparency=1-cfg.rainTransparency  
			else drop.line.Visible=false end  
		end  
	end  
end)  

-- ─────────────────────────────────────────────
-- CIDER-STYLE SCREEN INDICATOR
-- ─────────────────────────────────────────────

local function _indMakeLabel(parent, size, fontFace)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0, 300, 0, size + 4)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = size
	lbl.RichText = true
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Visible = false
	lbl.ZIndex = 10
	local stroke = Instance.new("UIStroke", lbl)
	stroke.Thickness = 0.7
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0
	lbl.Parent = parent
	return lbl
end

local function CreateIndicatorUI()
	-- destroy old if any
	if indicatorUI and indicatorUI.Parent then
		pcall(function() indicatorUI:Destroy() end)
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "KlaxIndicator"
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	pcall(function()
		local CoreGui = game:GetService("CoreGui")
		gui.Parent = CoreGui
	end)
	if not gui.Parent then
		gui.Parent = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")
	end

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, 300, 0, 300)
	container.ClipsDescendants = false
	container.ZIndex = 9
	container.Parent = gui

	indicatorTitle = _indMakeLabel(container, 15, Enum.Font.GothamMedium)
	indicatorLabels = {}
	for i = 1, INDICATOR_MAX_ROWS do
		indicatorLabels[i] = _indMakeLabel(container, 12, Enum.Font.GothamMedium)
	end

	indicatorUI = gui
end

local function _indGetAnchor(vp)
	local pos = indicatorPos or "Bottom Center"
	if pos == "Bottom Center" then
		return vp.X * 0.5, vp.Y - 110
	elseif pos == "Bottom Left" then
		return 160, vp.Y - 110
	elseif pos == "Bottom Right" then
		return vp.X - 160, vp.Y - 110
	elseif pos == "Top Left" then
		return 160, 60
	elseif pos == "Top Right" then
		return vp.X - 160, 60
	end
	return vp.X * 0.5, vp.Y - 110
end

local function _indRGB(c)
	return string.format("rgb(%d,%d,%d)",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

local function UpdateIndicator()
	if not indicatorEnabled then
		if indicatorTitle then indicatorTitle.Visible = false end
		for _, l in ipairs(indicatorLabels) do l.Visible = false end
		return
	end
	if not indicatorUI or not indicatorUI.Parent then
		CreateIndicatorUI()
	end

	local vp = cam.ViewportSize
	local scale = math.clamp(math.min(vp.X / 1920, vp.Y / 1080), 0.55, 1.35)
	local titleSize = math.floor(15 * scale + 0.5)
	local labelSize = math.floor(12 * scale + 0.5)
	local lineH     = math.floor(14 * scale + 0.5)
	local titleGap  = math.floor(20 * scale + 0.5)

	-- collect active rows
	local rows = {}

	-- camlock
	if cfg.camlock and camlockTarget then
		local tName = "none"
		local tHP = nil
		local tgtPlayer = type(camlockTarget) ~= "table" and camlockTarget or nil
		if tgtPlayer and tgtPlayer.DisplayName then
			tName = tgtPlayer.DisplayName
			local tChar = tgtPlayer.Character
			local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
			if tHum then tHP = math.floor(tHum.Health + 0.5) end
		end
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		local hpStr = tHP and string.format(' <font color="rgb(180,180,180)">(%d)</font>', tHP) or ""
		rows[#rows+1] = string.format(
			'<font color="%s">camlock</font> <font color="%s">&gt; %s</font>%s', fc, ac, tName, hpStr)
	end

	-- silent aim
	if cfg.silentAim and silentAimCachedPart then
		local tName = "none"
		local tHP = nil
		local tgtChar = silentAimCachedPart and silentAimCachedPart.Parent
		if tgtChar then
			local p = Players:GetPlayerFromCharacter(tgtChar)
			if p then tName = p.DisplayName end
			local tHum = tgtChar:FindFirstChildOfClass("Humanoid")
			if tHum then tHP = math.floor(tHum.Health + 0.5) end
		end
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		local hpStr = tHP and string.format(' <font color="rgb(180,180,180)">(%d)</font>', tHP) or ""
		rows[#rows+1] = string.format(
			'<font color="%s">silent aim</font> <font color="%s">&gt; %s</font>%s', fc, ac, tName, hpStr)
	end

	-- esp
	if cfg.esp then
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		rows[#rows+1] = string.format('<font color="%s">esp</font> <font color="%s">&gt; on</font>', fc, ac)
	end

	-- walkspeed
	if walkspeedEnabled then
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		rows[#rows+1] = string.format('<font color="%s">speed</font> <font color="%s">&gt; %d</font>', fc, ac, cfg.walkspeed)
	end

	-- rapid fire
	if cfg.rapidFireEnabled then
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		rows[#rows+1] = string.format('<font color="%s">rapid fire</font> <font color="%s">&gt; on</font>', fc, ac)
	end

	-- flight
	if cfg.flightEnabled then
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		rows[#rows+1] = string.format('<font color="%s">flight</font> <font color="%s">&gt; on</font>', fc, ac)
	end

	-- spread mod
	if cfg.spreadEnabled then
		local ac = _indRGB(indicatorAccent)
		local fc = _indRGB(indicatorFeature)
		rows[#rows+1] = string.format('<font color="%s">spread</font> <font color="%s">&gt; %d%%</font>', fc, ac, cfg.spreadAmount)
	end

	local totalH = titleGap + #rows * lineH
	local bx, by = _indGetAnchor(vp)
	local baseX = math.clamp(math.floor(bx + 0.5), 154, vp.X - 154)
	local baseY = math.clamp(math.floor(by - totalH + 0.5), 4, vp.Y - totalH - 4)

	local container = indicatorUI:FindFirstChild("Container")
	if not container then return end

	-- title: "klax" + accent ".cc"
	local ac = _indRGB(indicatorAccent)
	indicatorTitle.TextSize = titleSize
	indicatorTitle.Text = string.format('<font color="rgb(255,255,255)">klax</font><font color="%s">.cc</font>', ac)
	indicatorTitle.Position = UDim2.fromOffset(baseX - 150, baseY)
	indicatorTitle.Visible = true

	local offsetY = baseY + titleGap
	for i = 1, INDICATOR_MAX_ROWS do
		local lbl = indicatorLabels[i]
		if not lbl then break end
		if rows[i] then
			lbl.TextSize = labelSize
			lbl.Text = rows[i]
			lbl.Position = UDim2.fromOffset(baseX - 150, offsetY)
			lbl.Visible = true
			offsetY = offsetY + lineH
		else
			lbl.Visible = false
		end
	end
end

-- initialise on first run
task.defer(CreateIndicatorUI)

local function startFlight()  
	local c=lp.Character; if not c then return end; local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end  
	local bg=Instance.new("BodyGyro",hrp);bg.MaxTorque=Vector3.new(1e5,1e5,1e5);bg.P=1e4;bg.Name="FlyGyro"  
	local bv=Instance.new("BodyVelocity",hrp);bv.MaxForce=Vector3.new(1e5,1e5,1e5);bv.Velocity=Vector3.zero;bv.Name="FlyVel"  
	flightBody={bg=bg,bv=bv}  
end  
  
local function stopFlight()  
	local c=lp.Character; if c then local hrp=c:FindFirstChild("HumanoidRootPart"); if hrp then local bg=hrp:FindFirstChild("FlyGyro"); local bv=hrp:FindFirstChild("FlyVel"); if bg then bg:Destroy() end; if bv then bv:Destroy() end end end  
	flightBody=nil  
end  
  
local function enableNoclip() noclipConn=RunService.Stepped:Connect(function() local c=lp.Character; if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end  
local function disableNoclip() if noclipConn then noclipConn:Disconnect(); noclipConn=nil end end  
  
local function startWalkspeed()  
	cfg.walkspeedException=true  
	local c=lp.Character; if not c then return end  
	local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end  
	h.WalkSpeed=cfg.walkspeed  
	if walkspeedConn then walkspeedConn:Disconnect() end  
	walkspeedConn=h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()  
		if cfg.walkspeedException then h.WalkSpeed=cfg.walkspeed end  
	end)  
end  
  
local function stopWalkspeed()  
	cfg.walkspeedException=false; walkspeedEnabled=false  
	if walkspeedConn then walkspeedConn:Disconnect(); walkspeedConn=nil end  
	local c=lp.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end end  
end  
  
local function startInfiniteJump()  
	if infiniteJumpConn then infiniteJumpConn:Disconnect() end  
	infiniteJumpConn=RunService.RenderStepped:Connect(function()  
		if not cfg.infiniteJump then return end; local c=lp.Character; if not c then return end; local h=c:FindFirstChild("Humanoid"); if not h then return end  
		h.UseJumpPower=true;h.JumpPower=50;h.JumpHeight=7.2;h:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)  
	end)  
end  
  
local function stopInfiniteJump() if infiniteJumpConn then infiniteJumpConn:Disconnect(); infiniteJumpConn=nil end end  
  
local function getrapidgun()  
	local c=lp.Character; if not c then return nil end  
	for _,tool in next,c:GetChildren() do  
		if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then return tool end  
	end  
	return nil  
end  
  
local function patchtool(tool)  
	pcall(function()  
		for _,conn in pairs(getconnections(tool.Activated)) do  
			local info=debug.getinfo(conn.Function)  
			for i=1,info.nups do  
				local val=debug.getupvalue(conn.Function,i)  
				-- Zero out fire delays/cooldowns (floats 0–10), not integer ammo counts  
				if type(val)=="number" and val>0 and val<10 and math.floor(val)~=val then  
					debug.setupvalue(conn.Function,i,0)  
				end  
			end  
		end  
	end)  
end  
  
local function rapidFireWeaponAllowed(gun)  
	if not cfg.rapidFireSpecificEnabled then return true end  
	for _,name in ipairs(string.split(cfg.rapidFireWeapons,",")) do  
		local clean=name:gsub("^%s*",""):gsub("%s*$","")  
		if gun.Name==clean or gun.Name:find(clean,1,true) then return true end  
	end  
	return false  
end  
  
local function doRapidFire()  
	if not cfg.rapidFireEnabled or not isfiring then return end  
	if tick()-lastRapidFire<cfg.rapidFireDelay then return end  
	local gun=getrapidgun(); if not gun then return end  
	if not rapidFireWeaponAllowed(gun) then isfiring=false; return end  
	gun:Activate()  
	lastRapidFire=tick()  
end  
  
local function setupRapidFireOnChar(char)  
	if not cfg.rapidFireEnabled then return end  
	char.ChildAdded:Connect(function(tool)  
		if tool:IsA("Tool") then task.wait(0.1); patchtool(tool) end  
	end)  
	local gun=getrapidgun(); if gun then patchtool(gun) end  
end  
  
local function setupJumpPower()  
	if jumpConnection then jumpConnection:Disconnect() end  
	jumpConnection=UIS.InputBegan:Connect(function(i,gp)  
		if gp or i.KeyCode~=Enum.KeyCode.Space or cfg.jumppower<=50 then return end  
		local c=lp.Character; if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); local hrp=c:FindFirstChild("HumanoidRootPart")  
		if not hum or not hrp then return end  
		if hum.FloorMaterial~=Enum.Material.Air then hrp.Velocity=Vector3.new(hrp.Velocity.X,math.sqrt(2*cfg.jumppower*workspace.Gravity),hrp.Velocity.Z) end  
	end)  
end  
  
local function applySlippery() local c=lp.Character; if not c then return end; for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.01,0.1,0,0) end end end  
local function removeSlippery() local c=lp.Character; if not c then return end; for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5,0,0) end end end  
  
-- ANIMATION CHANGER
local ANIM_PRESETS = {
	["Zombie"]    = { idle1="10921344533", idle2="10921345304", run="616163682", walk="616168032", jump="616161997", fall="616157476", climb="616156119", swim="616165109" },
	["Ninja"]     = { idle1="656117400",   idle2="656118341",   run="616118852", walk="656121766", jump="656117878", fall="656115606", climb="656114359", swim="656119721" },
	["Robot"]     = { idle1="616136790",   idle2="616138447",   run="616140816", walk="616146177", jump="616139451", fall="616134815", climb="616133594", swim="616143378" },
	["Levitate"]  = { idle1="616006778",   idle2="616008087",   run="616010382", walk="616013216", jump="616008936", fall="616005863", climb="616003713", swim="616011509" },
	["Cartoony"]  = { idle1="742637544",   idle2="742638445",   run="742638842", walk="742640026", jump="742637942", fall="742637151", climb="742636889", swim="742639220" },
	["Super Hero"]= { idle1="616111295",   idle2="616113536",   run="616117076", walk="616122287", jump="616115533", fall="616118211", climb="616120861", swim="616119360" },
	["Elder"]     = { idle1="845397899",   idle2="845400520",   run="845386501", walk="845403856", jump="845398858", fall="845396048", climb="845392038", swim="845401742" },
	["Toy"]       = { idle1="782841498",   idle2="782845736",   run="782842708", walk="782843345", jump="782847020", fall="782846423", climb="782843869", swim="782845186" },
	["Old School"]= { idle1="5319828216",  idle2="5319831086",  run="5319844329",walk="5319847204",jump="5319841935",fall="5319839762",climb="5319816685",swim="5319850266" },
	["Stylish"]   = { idle1="616136790",   idle2="616138447",   run="616140816", walk="616146177", jump="616139451", fall="616134815", climb="616133594", swim="616143378" },
	["Default"]   = { idle1="507766388",   idle2="507766666",   run="507767714", walk="507777826", jump="507765000", fall="507767968", climb="507765644", swim="507784897" },
}
local ANIM_NAMES = {"Default","Zombie","Ninja","Robot","Levitate","Cartoony","Super Hero","Elder","Toy","Old School","Stylish"}

-- per-slot selections
local animSlots = {
	idle  = "Default",
	run   = "Default",
	walk  = "Default",
	jump  = "Default",
	fall  = "Default",
	climb = "Default",
	swim  = "Default",
}
local animChangerEnabled = false
local animChangerConn    = nil

local function applyAnimSlots()
	local c = lp.Character
	if not c then return end
	local animate = c:FindFirstChild("Animate")
	if not animate then return end

	local function set(path, id)
		local node = animate
		for _, part in ipairs(path) do
			node = node and node:FindFirstChild(part)
		end
		if node and node:IsA("Animation") then
			node.AnimationId = "rbxassetid://" .. id
		end
	end

	local function id(slot, key)
		local preset = animSlots[slot]
		local p = ANIM_PRESETS[preset]
		return p and p[key] or ANIM_PRESETS["Default"][key]
	end

	set({"idle",  "Animation1"}, id("idle",  "idle1"))
	set({"idle",  "Animation2"}, id("idle",  "idle2"))
	set({"run",   "RunAnim"},    id("run",   "run"))
	set({"walk",  "WalkAnim"},   id("walk",  "walk"))
	set({"jump",  "JumpAnim"},   id("jump",  "jump"))
	set({"fall",  "FallAnim"},   id("fall",  "fall"))
	set({"climb", "ClimbAnim"},  id("climb", "climb"))
	set({"swim",  "Swim"},       id("swim",  "swim"))

	-- restart Animate so changes take effect immediately
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			pcall(function() track:Stop(0) end)
		end
	end
	pcall(function()
		animate.Disabled = true
		task.wait()
		animate.Disabled = false
	end)
end

local function startAnimChanger()
	if animChangerConn then animChangerConn:Disconnect(); animChangerConn = nil end
	applyAnimSlots()
	animChangerConn = lp.CharacterAdded:Connect(function()
		task.wait(1)
		if animChangerEnabled then applyAnimSlots() end
	end)
end

local function stopAnimChanger()
	if animChangerConn then animChangerConn:Disconnect(); animChangerConn = nil end
end

local function do360()  
	if spinActive then return end; spinActive=true  
	local steps=60*cfg.spin360Loops; local angle=(-360*cfg.spin360Direction)/60; local wait=(1/cfg.spin360Speed)/60  
	for i=1,steps do if not spinActive then break end; cam.CFrame=cam.CFrame*CFrame.Angles(0,math.rad(angle),0); task.wait(wait) end  
	spinActive=false  
end  

-- INFINITE AMMO
-- Watches the equipped tool's Ammo IntValue and refills it whenever it drops.
local function toggleFB()  
	if cfg.fullbrightEnabled then  
		Lighting.Brightness=5;Lighting.ClockTime=12  
		if fullbrightConn then fullbrightConn:Disconnect() end  
		fullbrightConn=RunService.RenderStepped:Connect(function() Lighting.Brightness=5;Lighting.ClockTime=12 end)  
	else  
		if fullbrightConn then fullbrightConn:Disconnect();fullbrightConn=nil end  
		Lighting.Brightness=origL.Brightness;Lighting.ClockTime=origL.ClockTime  
	end  
end  
  
local function setLightingMode(mode)  
	if lightingConn then lightingConn:Disconnect();lightingConn=nil end  
	if mode=="Day" then Lighting.ClockTime=14;Lighting.Brightness=2;lightingConn=RunService.RenderStepped:Connect(function() Lighting.ClockTime=14;Lighting.Brightness=2 end)  
	elseif mode=="Night" then Lighting.ClockTime=0;Lighting.Brightness=1;lightingConn=RunService.RenderStepped:Connect(function() Lighting.ClockTime=0;Lighting.Brightness=1 end)  
	elseif mode=="Sunset" then Lighting.ClockTime=18;lightingConn=RunService.RenderStepped:Connect(function() Lighting.ClockTime=18 end) end  
	cfg.lightingMode=mode  
end  
  
local function setFog(on)  
	if on then Lighting.FogStart=cfg.fogStart;Lighting.FogEnd=cfg.fogEnd;Lighting.FogColor=cfg.fogColor  
	else Lighting.FogStart=origL.FogStart;Lighting.FogEnd=origL.FogEnd;Lighting.FogColor=origL.FogColor end  
end  
  
local function fpsBoost()  
	for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic;v.Reflectance=0 end end  
	Lighting.GlobalShadows=false  
end  
  
local skyboxes={  
	Piss={SkyboxUp="rbxassetid://2651437350",SkyboxRt="rbxassetid://2651436979",SkyboxLf="rbxassetid://2651436494",SkyboxFt="rbxassetid://2651435990",SkyboxBk="rbxassetid://2651432901",SkyboxDn="rbxassetid://2651434974"},  
	Peach={SkyboxUp="rbxassetid://566616187",SkyboxRt="rbxassetid://566616082",SkyboxLf="rbxassetid://566616044",SkyboxFt="rbxassetid://566616141",SkyboxBk="rbxassetid://566616113",SkyboxDn="rbxassetid://566616232"},  
	Saku={SkyboxUp="http://www.roblox.com/asset/?id=271077958",SkyboxRt="http://www.roblox.com/asset/?id=271042467",SkyboxLf="http://www.roblox.com/asset/?id=271042310",SkyboxFt="http://www.roblox.com/asset/?id=271042556",SkyboxBk="http://www.roblox.com/asset/?id=271042516",SkyboxDn="http://www.roblox.com/asset/?id=271077243"},  
	Purple={SkyboxUp="rbxassetid://570557727",SkyboxRt="rbxassetid://570557672",SkyboxLf="rbxassetid://570557620",SkyboxFt="rbxassetid://570557559",SkyboxBk="rbxassetid://570557514",SkyboxDn="rbxassetid://570557775"},  
	Retro={SkyboxUp="rbxassetid://18164890128",SkyboxRt="rbxassetid://18164873920",SkyboxLf="rbxassetid://18164877945",SkyboxFt="rbxassetid://18164870251",SkyboxBk="rbxassetid://18164881924",SkyboxDn="rbxassetid://18166113875"},  
	Space={SkyboxUp="rbxassetid://15983964246",SkyboxRt="rbxassetid://15983966246",SkyboxLf="rbxassetid://15983967420",SkyboxFt="rbxassetid://15983965025",SkyboxBk="rbxassetid://15983968922",SkyboxDn="rbxassetid://15983966825"},  
	Sea={SkyboxUp="http://www.roblox.com/asset/?id=321846070",SkyboxRt="http://www.roblox.com/asset/?id=321846207",SkyboxLf="http://www.roblox.com/asset/?id=321846162",SkyboxFt="http://www.roblox.com/asset/?id=321845951",SkyboxBk="http://www.roblox.com/asset/?id=321846018",SkyboxDn="http://www.roblox.com/asset/?id=321846104"},  
	["Night V2"]={SkyboxUp="http://www.roblox.com/Asset/?ID=12064131",SkyboxRt="http://www.roblox.com/Asset/?ID=12064115",SkyboxLf="http://www.roblox.com/Asset/?ID=12063984",SkyboxFt="http://www.roblox.com/Asset/?ID=12064121",SkyboxBk="http://www.roblox.com/Asset/?ID=12064107",SkyboxDn="http://www.roblox.com/Asset/?ID=12064152"},  
	Dark={SkyboxUp="rbxassetid://15470160563",SkyboxRt="rbxassetid://15470158022",SkyboxLf="rbxassetid://15470155938",SkyboxFt="rbxassetid://15470153860",SkyboxBk="rbxassetid://15470149279",SkyboxDn="rbxassetid://15470151245"},  
	Anime={SkyboxUp="http://www.roblox.com/asset/?id=104038404823203",SkyboxRt="http://www.roblox.com/asset/?id=99961685452126",SkyboxLf="http://www.roblox.com/asset/?id=84924000207295",SkyboxFt="http://www.roblox.com/asset/?id=95687237979398",SkyboxBk="http://www.roblox.com/asset/?id=81858382098344",SkyboxDn="http://www.roblox.com/asset/?id=138472117789684"},  
	Beach={SkyboxUp="http://www.roblox.com/asset/?id=151165227",SkyboxRt="http://www.roblox.com/asset/?id=151165206",SkyboxLf="http://www.roblox.com/asset/?id=151165191",SkyboxFt="http://www.roblox.com/asset/?id=151165224",SkyboxBk="http://www.roblox.com/asset/?id=151165214",SkyboxDn="http://www.roblox.com/asset/?id=151165197"},  
	["Space V2"]={SkyboxUp="http://www.roblox.com/asset/?id=16262366016",SkyboxRt="http://www.roblox.com/asset/?id=16262363873",SkyboxLf="http://www.roblox.com/asset/?id=16262362003",SkyboxFt="http://www.roblox.com/asset/?id=16262360469",SkyboxBk="http://www.roblox.com/asset/?id=16262356578",SkyboxDn="http://www.roblox.com/asset/?id=16262358026"},  
	Pink={SkyboxUp="rbxassetid://12635316856",SkyboxRt="rbxassetid://12635315817",SkyboxLf="rbxassetid://12635313718",SkyboxFt="rbxassetid://12635312870",SkyboxBk="rbxassetid://12635309703",SkyboxDn="rbxassetid://12635311686"},  
	Rainbow={SkyboxUp="rbxassetid://12877083856",SkyboxRt="rbxassetid://12877085497",SkyboxLf="rbxassetid://12877085497",SkyboxFt="rbxassetid://12877085497",SkyboxBk="rbxassetid://12877085497",SkyboxDn="rbxassetid://12877086914"},  
	Forest={SkyboxUp="http://www.roblox.com/asset/?id=237593929",SkyboxRt="http://www.roblox.com/asset/?id=237593835",SkyboxLf="http://www.roblox.com/asset/?id=237593861",SkyboxFt="http://www.roblox.com/asset/?id=237593922",SkyboxBk="http://www.roblox.com/asset/?id=237593887",SkyboxDn="http://www.roblox.com/asset/?id=237593849"},  
	Night={SkyboxUp="http://www.roblox.com/asset/?id=154185031",SkyboxRt="http://www.roblox.com/asset/?id=154184972",SkyboxLf="http://www.roblox.com/asset/?id=154184943",SkyboxFt="http://www.roblox.com/asset/?id=154185021",SkyboxBk="http://www.roblox.com/asset/?id=154185004",SkyboxDn="http://www.roblox.com/asset/?id=154184960"},  
	Lava={SkyboxUp="http://www.roblox.com/asset/?id=4776130793",SkyboxRt="http://www.roblox.com/asset/?id=4776133150",SkyboxLf="http://www.roblox.com/asset/?id=4776128425",SkyboxFt="http://www.roblox.com/asset/?id=4776131365",SkyboxBk="http://www.roblox.com/asset/?id=4776124334",SkyboxDn="http://www.roblox.com/asset/?id=4776125375"},  
	Rainy={SkyboxUp="http://www.roblox.com/asset/?id=4495867486",SkyboxRt="http://www.roblox.com/asset/?id=4495866584",SkyboxLf="http://www.roblox.com/asset/?id=4495866035",SkyboxFt="http://www.roblox.com/asset/?id=4495865458",SkyboxBk="http://www.roblox.com/asset/?id=4495864450",SkyboxDn="http://www.roblox.com/asset/?id=4495864887"},  
	Green={SkyboxUp="rbxassetid://566611218",SkyboxRt="rbxassetid://566611300",SkyboxLf="rbxassetid://566611266",SkyboxFt="rbxassetid://566611142",SkyboxBk="rbxassetid://566611187",SkyboxDn="rbxassetid://566613198"},  
	Volcanic={SkyboxUp="http://www.roblox.com/asset/?id=150281471",SkyboxRt="http://www.roblox.com/asset/?id=150281426",SkyboxLf="http://www.roblox.com/asset/?id=150281400",SkyboxFt="http://www.roblox.com/asset/?id=150281461",SkyboxBk="http://www.roblox.com/asset/?id=150281446",SkyboxDn="http://www.roblox.com/asset/?id=150281418"},  
	Minecraft={SkyboxUp="http://www.roblox.com/asset/?id=8735166729",SkyboxRt="http://www.roblox.com/asset/?id=8735166751",SkyboxLf="http://www.roblox.com/asset/?id=8735166755",SkyboxFt="http://www.roblox.com/asset/?id=8735231668",SkyboxBk="rbxassetid://8735166756",SkyboxDn="http://www.roblox.com/asset/?id=8735166707"},  
	Lucid={SkyboxUp="rbxassetid://8508112781",SkyboxRt="rbxassetid://8508111092",SkyboxLf="rbxassetid://8508107681",SkyboxFt="rbxassetid://8508104949",SkyboxBk="rbxassetid://8508098796",SkyboxDn="rbxassetid://8508103588"},  
	Nebulous={SkyboxUp="rbxassetid://131036626982613",SkyboxRt="rbxassetid://103716549795832",SkyboxLf="rbxassetid://126542804346203",SkyboxFt="rbxassetid://107665368823185",SkyboxBk="rbxassetid://95020137072033",SkyboxDn="rbxassetid://92862258103959"},  
}  
  
local function applySky(preset)  
	local sky=Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",Lighting)  
	if not origSky then origSky={SkyboxBk=sky.SkyboxBk,SkyboxDn=sky.SkyboxDn,SkyboxFt=sky.SkyboxFt,SkyboxLf=sky.SkyboxLf,SkyboxRt=sky.SkyboxRt,SkyboxUp=sky.SkyboxUp} end  
	local src=preset and skyboxes[preset] or origSky  
	if src then for k,v in pairs(src) do sky[k]=v end end; cfg.selectedSkybox=preset  
end  
  
local function toggleRotatingSkybox(en)  
	if rotatingSkyConn then rotatingSkyConn:Disconnect();rotatingSkyConn=nil end  
	if en then local sky=Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",Lighting)  
		rotatingSkyConn=RunService.PreRender:Connect(function(dt) sky.SkyboxOrientation=sky.SkyboxOrientation+Vector3.new(0,30*dt,0) end)  
	else local sky=Lighting:FindFirstChildOfClass("Sky"); if sky then sky.SkyboxOrientation=Vector3.new(0,0,0) end end  
end  
  
local function applyTextureColor(color)  
	for _,obj in pairs(workspace:GetDescendants()) do  
		if obj:IsA("BasePart") and not(lp.Character and obj:IsDescendantOf(lp.Character)) then  
			if not origColors[obj] then origColors[obj]=obj.Color end; obj.Color=color  
		end  
	end  
end  
  
local function resetTextureColors()  
	for obj,color in pairs(origColors) do if obj and obj.Parent then if obj:IsA("BasePart") then obj.Color=color end end end  
	origColors={}; cfg.textureColorEnabled=false  
end  
  
local function applyMat(mat)  
	for _,p in pairs(workspace:GetDescendants()) do  
		if p:IsA("BasePart") and not(lp.Character and p:IsDescendantOf(lp.Character)) then  
			if not origMats[p] then origMats[p]=p.Material end; p.Material=mat  
		end  
	end  
end  
  
local function resetMats() for p,m in pairs(origMats) do if p and p.Parent then p.Material=m end end; origMats={} end  

local function getBodyParts(char)  
	return {  
		char:FindFirstChild("Head"),  
		char:FindFirstChild("UpperTorso"),  
		char:FindFirstChild("HumanoidRootPart"),  
		char:FindFirstChild("LowerTorso"),  
		char:FindFirstChild("LeftUpperArm"),  
		char:FindFirstChild("RightUpperArm"),  
		char:FindFirstChild("LeftLowerArm"),  
		char:FindFirstChild("RightLowerArm"),  
		char:FindFirstChild("LeftHand"),  
		char:FindFirstChild("RightHand"),  
		char:FindFirstChild("LeftUpperLeg"),  
		char:FindFirstChild("RightUpperLeg"),  
		char:FindFirstChild("LeftLowerLeg"),  
		char:FindFirstChild("RightLowerLeg"),  
		char:FindFirstChild("LeftFoot"),  
		char:FindFirstChild("RightFoot"),  
	}  
end  
  
local function getClosestBodyPart(char)  
	local closestPart, shortestDist = nil, math.huge  
	local mousePos = UIS:GetMouseLocation()  
	for _, part in pairs(getBodyParts(char)) do  
		if part then  
			local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)  
			local dist  
			if onScreen then  
				dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude  
			else  
				dist = (cam.CFrame.Position - part.Position).Magnitude + 10000  
			end  
			if dist < shortestDist then shortestDist = dist; closestPart = part end  
		end  
	end  
	return closestPart  
end  
  
local function getSilentAimPart(char)  
	if not char then return nil end  
	if cfg.silentAimClosestPart then  
		return getClosestBodyPart(char)  
	end  
	local pn = cfg.silentAimPart  
	local hum = char:FindFirstChildOfClass("Humanoid")  
	if cfg.silentAimUseAirPart and hum and hum.FloorMaterial == Enum.Material.Air then  
		pn = cfg.silentAimAirPart  
	end  
	return char:FindFirstChild(pn) or char:FindFirstChild("HumanoidRootPart")  
end  
  
local function getSilentAimTarget(part)  
	if not part then return nil end  
	local char = part.Parent  
	local hum = char and char:FindFirstChildOfClass("Humanoid")  
	if not char or not hum then return nil end  
	if hum.Health <= 0 then return nil end  
	if cfg.silentAimKOCheck then  
		local be = char:FindFirstChild("BodyEffects")  
		if be then local ko = be:FindFirstChild("K.O") or be:FindFirstChild("KO"); if ko and ko.Value then return nil end end  
	end  
	if cfg.silentAimTeamCheck then  
		local p = Players:GetPlayerFromCharacter(char)  
		if p and sameTeam(p) then return nil end  
	end  
	local dist = (part.Position - cam.CFrame.Position).Magnitude  
	if dist > cfg.silentAimMaxDist then return nil end  
	if cfg.silentAimWallCheck and wallBetween(part.Position) then return nil end  
	return part  
end  
  
local function getSilentAimHitPart()  
	local target = closestToCursorSilent(cfg.silentAimFOV, cfg.silentAimTeamCheck, cfg.silentAimMaxDist)  
	if not target then return nil end  
	local part = getSilentAimPart((type(target) == "table" and target.char) or target.Character)  
	return getSilentAimTarget(part)  
end  
  
local function getSilentAimPred(part)  
	local vel = part.AssemblyLinearVelocity  
	return part.Position + Vector3.new(  
		vel.X * cfg.silentAimPredX,  
		vel.Y * cfg.silentAimPredY,  
		vel.Z * cfg.silentAimPredX  
	)  
end  
  
local function uninstallSilentAimHooks()  
	if not silentAimHooksInstalled then return end  
	silentAimCachedPart = nil  
	silentAimCachedPred = nil  
	silentAimHooksInstalled = false  
end  
  
local function uninstallSilentAimHooksHard()  
	silentAimCachedPart = nil  
	silentAimCachedPred = nil  
	silentAimHooksInstalled = false  
	pcall(function()  
		setreadonly(_grm, false)  
		_grm.__index = _oldIndex  
		setreadonly(_grm, true)  
	end)  
end  
  
local _grm = getrawmetatable(game)  
local _oldIndex = _grm.__index  
setreadonly(_grm, false)  
  
local _saRayParams = RaycastParams.new()  
_saRayParams.FilterType = Enum.RaycastFilterType.Exclude  
_saRayParams.FilterDescendantsInstances = lp.Character and {lp.Character} or {}  
lp.CharacterAdded:Connect(function(c) _saRayParams.FilterDescendantsInstances = {c} end)  

_grm.__index = function(self, key)  
	if not checkcaller() and self == mouse then  
		if cfg.forceHitEnabled and camlockTarget and (key == "Hit" or key == "Target") then  
			local _fhChar = (type(camlockTarget)=="table" and camlockTarget.char) or camlockTarget.Character  
			if _fhChar then  
				local _fhHead = _fhChar:FindFirstChild("Head")  
				if _fhHead then  
					local _fhPos = _fhHead.Position  
					if cfg.bulletTeleportEnabled then  
						_fhPos = _fhPos + (cam.CFrame.Position - _fhPos).Unit * cfg.bulletTeleportOffset  
					end  
					if key == "Hit" then return CFrame.new(_fhPos) end  
					if key == "Target" then return _fhHead end  
				end  
			end  
		end  
		if (key == "Hit" or key == "Target" or key == "UnitRay")  
			and silentAimCachedPart and silentAimCachedPred  
			and math.random(1, 100) <= cfg.silentAimHitChance then  
  
			if cfg.silentAimMethod == "Raycast" then  
				local origin = cam.CFrame.Position  
				local pred   = silentAimCachedPred  
				local delta  = pred - origin  
				local dist   = delta.Magnitude  
				local dir    = delta.Unit  
				if key == "UnitRay" then  
					return Ray.new(origin, dir)  
				end  
				if key == "Hit" then  
					local res = workspace:Raycast(origin, dir * (dist + 5), _saRayParams)  
					local hitPos = res and res.Position or pred  
					if cfg.bulletTeleportEnabled then  
						hitPos = hitPos + (origin - hitPos).Unit * cfg.bulletTeleportOffset  
					end  
					return CFrame.new(hitPos)  
				end  
				if key == "Target" then return silentAimCachedPart end  
			else  
				if key == "Hit" then  
					local hitPos = silentAimCachedPred  
					if cfg.bulletTeleportEnabled then  
						hitPos = hitPos + (cam.CFrame.Position - hitPos).Unit * cfg.bulletTeleportOffset  
					end  
					return CFrame.new(hitPos)  
				end  
				if key == "Target" then return silentAimCachedPart end  
			end  
		end  
  
		if cfg.rangeExpanderEnabled and key == "Hit" then  
			local unitRay = _oldIndex(self, "UnitRay")  
			if unitRay then  
				local origin = unitRay.Origin  
				local res = workspace:Raycast(origin, unitRay.Direction * cfg.rangeExpanderRange, _saRayParams)  
				local hitPos = res and res.Position or (origin + unitRay.Direction * cfg.rangeExpanderRange)  
				return CFrame.new(hitPos)  
			end  
		end  
	end  
	return _oldIndex(self, key)  
end  
  
setreadonly(_grm, true)  
  
local _oldRandom  
_oldRandom = hookfunction(math.random, function(...)  
	if checkcaller() then return _oldRandom(...) end  
	local args = {...}  
	if cfg.spreadEnabled and (  
		(#args == 0) or  
		(args[1] == -0.05 and args[2] == 0.05) or  
		(args[1] == -0.1) or  
		(args[1] == -0.05)  
	) then  
		if cfg.spreadSpecificEnabled then  
			local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")  
			if tool then  
				for _, name in ipairs(string.split(cfg.spreadWeapons, ",")) do  
					local clean = name:gsub("^%s*", ""):gsub("%s*$", "")  
					if tool.Name == clean or tool.Name:find(clean, 1, true) then  
						return _oldRandom(...) * (cfg.spreadAmount / 100)  
					end  
				end  
			end  
		else  
			return _oldRandom(...) * (cfg.spreadAmount / 100)  
		end  
	end  
	return _oldRandom(...)  
end)  
  
local function installLethalHooks()  
	if silentAimHooksInstalled then return end  
	silentAimHooksInstalled = true  
	oldIndexHook = _oldIndex  
end  
  
local function installRaycastHooks()  
	installLethalHooks()  
end  
  
local function installSilentAimHooks()  
	silentAimHooksInstalled = true  
	oldIndexHook = _oldIndex  
end  
  
local CF="klax_cfgs"  
if makefolder and not isfolder(CF) then makefolder(CF) end  
  
local function saveConfig(name)  
	if not writefile then return false end  
	local data={}  
	for k,v in pairs(cfg) do  
		local t=type(v)  
		if t=="boolean" or t=="number" or t=="string" then data[k]=v  
		elseif t=="userdata" then  
			local okC,r,g,b=pcall(function() return v.R,v.G,v.B end)  
			if okC and r then data[k]={_type="Color3",r=r,g=g,b=b};continue end  
			local okE=pcall(function() local _=v.Name end)  
			if okE then data[k]={_type="EnumItem",enum=tostring(v)};continue end  
		end  
	end  
	writefile(CF.."/"..name..".json",HttpService:JSONEncode(data)); return true  
end  
  
local function loadConfig(name)  
	local p=CF.."/"..name..".json"  
	if not isfile or not isfile(p) then return false end  
	local data=HttpService:JSONDecode(readfile(p))  
	for k,v in pairs(data) do  
		if type(v)=="table" then  
			if v._type=="Color3" then cfg[k]=Color3.new(v.r,v.g,v.b)  
			elseif v._type=="EnumItem" then  
				local parts=tostring(v.enum):split(".")  
				local ok,ev=pcall(function() return Enum[parts[#parts-1]][parts[#parts]] end)  
				if ok and ev then cfg[k]=ev end  
			end  
		else cfg[k]=v end  
	end  
	return true  
end  
  
local function listConfigs()  
	local lst={}; if not listfiles then return lst end  
	for _,f in ipairs(listfiles(CF)) do  
		local nm=tostring(f):match("([^/\\]+)%.json$"); if nm then table.insert(lst,nm) end  
	end  
	table.sort(lst); return lst  
end  

-- split out from RenderStepped to stay under Lua's 200 local register limit
local function _renderFOV(mousePos)
	if fovCircle then fovCircle.Position=mousePos;fovCircle.Radius=cfg.silentAimFOV;fovCircle.Filled=cfg.silentAimFOVFilled;fovCircle.Transparency=1-cfg.silentAimFOVOpacity;fovCircle.Color=cfg.silentAimFOVColor;fovCircle.Visible=cfg.silentAim and cfg.silentAimFOVShow end
	if camlockFOVCircle then camlockFOVCircle.Position=mousePos;camlockFOVCircle.Radius=cfg.camlockFOVRadius;camlockFOVCircle.Filled=cfg.camlockFOVFilled;camlockFOVCircle.Transparency=1-cfg.camlockFOVOpacity;camlockFOVCircle.Color=cfg.camlockFOVColor;camlockFOVCircle.Visible=cfg.camlockFOVEnabled end
end

local function _renderFlight()
	if not cfg.flightEnabled or not flightBody then return end
	local c=lp.Character; if not c then return end
	local hrp=c:FindFirstChild("HumanoidRootPart")
	if hrp and flightBody.bv and flightBody.bg then
		local mv=Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv=mv-Vector3.new(0,1,0) end
		flightBody.bv.Velocity=mv*cfg.flightSpeed;flightBody.bg.CFrame=cam.CFrame
	end
end

local function _renderESPPlayer(plr,d,vp)
	if getStatusById(plr.UserId)=="Friendly" then hideAllESP(d);d.hl.Enabled=false;return end
	local char=plr.Character
	if not char then d.hl.Adornee=nil;d.hl.Enabled=false;hideAllESP(d);return end
	local hrp=char:FindFirstChild("HumanoidRootPart");local hum=char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then hideAllESP(d);d.hl.Enabled=false;return end
	local head=char:FindFirstChild("Head")
	local dist3d=(hrp.Position-cam.CFrame.Position).Magnitude
	if dist3d>cfg.espMaxDist then hideAllESP(d);d.hl.Enabled=false;return end
	local isStatic=cfg.espMode=="Static"

	-- chams always use highlight regardless of mode
	if cfg.espChams then
		if d.hl.Parent~=workspace then d.hl.Parent=workspace end
		d.hl.Adornee=char;d.hl.FillColor=cfg.espChamsFillColor;d.hl.OutlineColor=cfg.espChamsOutlineColor
		d.hl.FillTransparency=cfg.espChamsTransparency;d.hl.Enabled=true
	else d.hl.Enabled=false;d.hl.Adornee=nil end

	-- head dot always uses real head position
	if cfg.espHeadDot and head then
		local hp,hon=cam:WorldToViewportPoint(head.Position)
		if hon then d.headDot.Position=Vector2.new(hp.X,hp.Y);d.headDot.Color=cfg.espHeadDotColor;d.headDot.Visible=true
		else d.headDot.Visible=false end
	else d.headDot.Visible=false end

	-- bones always use real skeleton positions
	if cfg.espBones then
		for i,conn in ipairs(BONES) do
			local p1=char:FindFirstChild(conn[1]);local p2=char:FindFirstChild(conn[2])
			if p1 and p2 then
				local s1,o1=cam:WorldToViewportPoint(p1.Position);local s2,o2=cam:WorldToViewportPoint(p2.Position)
				if o1 and o2 then d.bones[i].From=Vector2.new(s1.X,s1.Y);d.bones[i].To=Vector2.new(s2.X,s2.Y);d.bones[i].Color=cfg.espBoneColor;d.bones[i].Visible=true
				else d.bones[i].Visible=false end
			else d.bones[i].Visible=false end
		end
	else for _,b in pairs(d.bones) do b.Visible=false end end

	-- project HRP to screen for both modes
	local hrpSP,hrpOn=cam:WorldToViewportPoint(hrp.Position)
	if not hrpOn or hrpSP.Z<=0 then
		d.box.Visible=false;d.boxFill.Visible=false;d.name.Visible=false
		d.dist.Visible=false;d.hbg.Visible=false;d.hfill.Visible=false;d.tracer.Visible=false;return
	end
	local cx,cy=hrpSP.X,hrpSP.Y

	-- compute box dimensions
	local boxW,boxH,boxX,boxY
	if isStatic then
		-- use camera FOV + distance to get consistent screen-space size
		local fov=cam.FieldOfView
		local screenH=vp.Y
		-- project a point 3 studs above HRP and 3 studs below to get a stable reference height
		-- but don't let pose/animation affect it — use fixed offsets from HRP
		local topSP=cam:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
		local botSP=cam:WorldToViewportPoint(hrp.Position-Vector3.new(0,2.6,0))
		local h=math.abs(topSP.Y-botSP.Y)
		boxH=math.max(h,6)
		boxW=boxH*0.45
		boxX=cx-boxW/2;boxY=cy-boxH/2
	else
		local topPos,topOn=cam:WorldToViewportPoint(head and(head.Position+Vector3.new(0,0.7,0))or hrp.Position+Vector3.new(0,3,0))
		local botPos,botOn=cam:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
		if not topOn or not botOn then
			d.box.Visible=false;d.boxFill.Visible=false;d.name.Visible=false
			d.dist.Visible=false;d.hbg.Visible=false;d.hfill.Visible=false;d.tracer.Visible=false;return
		end
		boxH=math.abs(topPos.Y-botPos.Y)
		if boxH<6 then d.box.Visible=false;d.boxFill.Visible=false;return end
		boxW=boxH*0.45;boxX=topPos.X-boxW/2;boxY=topPos.Y
	end

	if cfg.espBoxes then
		d.box.Thickness=1;d.box.Size=Vector2.new(boxW,boxH);d.box.Position=Vector2.new(boxX,boxY);d.box.Color=cfg.espBoxColor;d.box.Visible=true
		if cfg.espBoxFilled then d.boxFill.Size=Vector2.new(boxW,boxH);d.boxFill.Position=Vector2.new(boxX,boxY);d.boxFill.Color=cfg.espBoxFillColor;d.boxFill.Transparency=cfg.espFillTransparency;d.boxFill.Visible=true else d.boxFill.Visible=false end
	else d.box.Visible=false;d.boxFill.Visible=false end

	if cfg.espNames then
		local isTarget=camlockTarget~=nil and(camlockTarget==plr or(type(camlockTarget)~="table" and camlockTarget==plr))
		local nameCol=isTarget and cfg.espTargetNameColor or cfg.espNameColor
		if cfg.espNameStyle=="Lethal" then
			d.name.Visible=false
			if not d.billboard or not d.billboard.Parent then buildBillboard(plr,d) end
			if d.billboard then d.billboard.Enabled=true;local lbl=d.billboard:FindFirstChild("NameLabel");if lbl then lbl.TextColor3=nameCol;lbl.Text=plr.Name end end
		else destroyBillboard(d);d.name.Text=plr.DisplayName;d.name.Font=2;d.name.Size=11;d.name.Color=nameCol;d.name.Position=Vector2.new(cx,boxY-13);d.name.Visible=true end
	else d.name.Visible=false;destroyBillboard(d) end
	if cfg.espDistance then d.dist.Text=tostring(math.floor(dist3d)).."m";d.dist.Size=10;d.dist.Font=2;d.dist.Color=cfg.espDistColor;d.dist.Position=Vector2.new(cx,boxY+boxH+2);d.dist.Visible=true else d.dist.Visible=false end
	if cfg.espHealth then local hpR=hum.Health/hum.MaxHealth;d.hbg.Size=Vector2.new(3,boxH);d.hbg.Position=Vector2.new(boxX-5,boxY);d.hbg.Color=Color3.fromRGB(20,20,20);d.hbg.Visible=true;d.hfill.Size=Vector2.new(3,boxH*hpR);d.hfill.Position=Vector2.new(boxX-5,boxY+boxH*(1-hpR));d.hfill.Color=cfg.espHealthColor;d.hfill.Visible=true else d.hbg.Visible=false;d.hfill.Visible=false end
	if cfg.espTracers then d.tracer.From=Vector2.new(vp.X/2,vp.Y);d.tracer.To=Vector2.new(cx,cy);d.tracer.Color=cfg.espTracerColor;d.tracer.Visible=true else d.tracer.Visible=false end
end

local function _renderESPBot(char,d)
	if not char or not char.Parent then d.box.Visible=false;d.name.Visible=false;d.dist.Visible=false;d.hbg.Visible=false;d.hfill.Visible=false;return end
	local hrp=char:FindFirstChild("HumanoidRootPart");local hum=char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health<=0 then d.box.Visible=false;d.name.Visible=false;return end
	local dist3d=(hrp.Position-cam.CFrame.Position).Magnitude
	if dist3d>cfg.espMaxDist then d.box.Visible=false;d.name.Visible=false;d.dist.Visible=false;d.hbg.Visible=false;d.hfill.Visible=false;return end
	local head=char:FindFirstChild("Head")
	local topPos,topOn=cam:WorldToViewportPoint(head and(head.Position+Vector3.new(0,0.7,0))or hrp.Position+Vector3.new(0,3,0))
	local botPos,botOn=cam:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
	if not topOn or not botOn then d.box.Visible=false;d.name.Visible=false;d.dist.Visible=false;d.hbg.Visible=false;d.hfill.Visible=false;return end
	local boxH=math.abs(topPos.Y-botPos.Y);if boxH<4 then d.box.Visible=false;d.name.Visible=false;return end
	local boxW=boxH*0.45;local boxX=topPos.X-boxW/2;local boxY=topPos.Y
	d.box.Thickness=1;d.box.Size=Vector2.new(boxW,boxH);d.box.Position=Vector2.new(boxX,boxY);d.box.Visible=cfg.espBoxes
	d.name.Text="[BOT] "..char.Name;d.name.Position=Vector2.new(topPos.X,boxY-13);d.name.Visible=cfg.espNames
	d.dist.Text=tostring(math.floor(dist3d)).."m";d.dist.Font=2;d.dist.Size=10;d.dist.Color=cfg.espDistColor;d.dist.Position=Vector2.new(topPos.X,botPos.Y+2);d.dist.Visible=cfg.espDistance
	local hpR=hum.Health/hum.MaxHealth;d.hbg.Size=Vector2.new(3,boxH);d.hbg.Position=Vector2.new(boxX-5,boxY);d.hbg.Visible=cfg.espHealth;d.hfill.Size=Vector2.new(3,boxH*hpR);d.hfill.Position=Vector2.new(boxX-5,boxY+boxH*(1-hpR));d.hfill.Visible=cfg.espHealth
end

local function _renderESP(vp)
	if cfg.esp then
		for plr,d in pairs(espData) do _renderESPPlayer(plr,d,vp) end
		for char,d in pairs(botEspData) do _renderESPBot(char,d) end
	else
		for _,d in pairs(espData) do d.hl.Enabled=false;hideAllESP(d) end
		for _,d in pairs(botEspData) do d.box.Visible=false;d.name.Visible=false;d.dist.Visible=false;d.hbg.Visible=false;d.hfill.Visible=false end
	end
end

RunService.RenderStepped:Connect(function()
	local vp=cam.ViewportSize
	local mousePos=UIS:GetMouseLocation()
	_renderFOV(mousePos)
	if cfg.silentAim or cfg.silentAimMode=="Always" then
		local part=getSilentAimHitPart()
		if part then silentAimCachedPart=part;silentAimCachedPred=getSilentAimPred(part)
		else silentAimCachedPart=nil;silentAimCachedPred=nil end
	else silentAimCachedPart=nil;silentAimCachedPred=nil end
	if cfg.bulletTeleportEnabled and camlockTarget and cfg.bulletTeleportLineEnabled then
		local char=(type(camlockTarget)=="table" and camlockTarget.char) or camlockTarget.Character
		local head=char and char:FindFirstChild("Head")
		if head then
			local sp,on=cam:WorldToViewportPoint(head.Position)
			if on then btpLine.From=mousePos;btpLine.To=Vector2.new(sp.X,sp.Y);btpLine.Color=cfg.bulletTeleportLineColor;btpLine.Visible=true
			else btpLine.Visible=false end
		else btpLine.Visible=false end
	else btpLine.Visible=false end
	_renderFlight()
	_renderESP(vp)
	updateWeaponChams();refreshWeaponGlow()
	UpdateIndicator()
end)

pcall(function() RunService:UnbindFromRenderStep("KlaxCamlock") end)  
RunService:BindToRenderStep("KlaxCamlock",Enum.RenderPriority.Camera.Value+1,function()  
	if cfg.camlock and cfg.camlockMode=="Always" and not camlockTarget then  
		camlockTarget=closestToCursor(cfg.camlockFOVEnabled and cfg.camlockFOVRadius or nil,cfg.camlockTeamCheck,cfg.camlockMaxDist)  
	end  
	if not cfg.camlock or not camlockTarget then if cam.CameraType==Enum.CameraType.Scriptable then cam.CameraType=Enum.CameraType.Custom end;return end  
	local char=(type(camlockTarget)=="table" and camlockTarget.char) or camlockTarget.Character  
	if not char then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom;return end  
	local tgtId = type(camlockTarget)~="table" and camlockTarget.UserId or nil  
	if tgtId and getStatusById(tgtId)=="Friendly" then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom;return end  
	local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom;return end  
	if cfg.camlockKOCheck then  
		local be=char:FindFirstChild("BodyEffects")  
		if be then local ko=be:FindFirstChild("K.O"); if ko and ko.Value==true then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom;return end end  
		if hum.Health<=0 then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom;return end  
	end  
	local partName=cfg.camlockPart; if cfg.camlockUseAirPart and hum.FloorMaterial==Enum.Material.Air then partName=cfg.camlockAirPart end  
	local part  
	if cfg.camlockClosestPart then  
		local center=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2); local best,bestD=char:FindFirstChild("HumanoidRootPart"),math.huge  
		for _,p in ipairs(char:GetChildren()) do if p:IsA("BasePart") and (p.Size.X*p.Size.Y*p.Size.Z)>=0.1 then local sp,on=cam:WorldToViewportPoint(p.Position); if on then local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude; if d<bestD then bestD=d;best=p end end end end  
		part=best  
	else part=char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart") end  
	if not part then return end  
	if cfg.camlockWallCheck and wallBetween(part.Position) then return end  
	local pred=getPredicted(part); if not pred then return end  
	local from=cam.CFrame; local to=CFrame.new(from.Position,pred)  
	local t=cfg.camlockSmooth; local style=cfg.camlockAimStyle; local e=t  
	if style=="Sine In" then e=1-math.cos((t*math.pi)/2)  
	elseif style=="Sine Out" then e=math.sin((t*math.pi)/2)  
	elseif style=="Sine In-Out" then e=-(math.cos(math.pi*t)-1)/2  
	elseif style=="Quad In" then e=t*t  
	elseif style=="Quad Out" then e=1-(1-t)*(1-t)  
	elseif style=="Quad In-Out" then e=t<0.5 and 2*t*t or 1-(-2*t+2)^2/2  
	elseif style=="Cubic In" then e=t*t*t  
	elseif style=="Cubic Out" then e=1-(1-t)^3  
	elseif style=="Cubic In-Out" then e=t<0.5 and 4*t*t*t or 1-(-2*t+2)^3/2  
	elseif style=="Expo In" then e=t==0 and 0 or 2^(10*t-10)  
	elseif style=="Expo Out" then e=t==1 and 1 or 1-2^(-10*t)  
	elseif style=="Spring" then e=math.clamp(math.sin(t*math.pi)*0.3+t,0,1)  
	elseif style=="Velocity" then local a=math.acos(math.clamp(from.LookVector:Dot(to.LookVector),-1,1));e=math.clamp(t+a*0.5,0.01,1) end  
	e=math.clamp(e*cfg.camlockSensitivity,0.001,1)  
	cam.CFrame=from:Lerp(to,e)  
end)  
  
RunService.Heartbeat:Connect(function()  
	doRapidFire()  
	if camlockTarget and cfg.camlockKOCheck then  
		local char=(type(camlockTarget)=="table" and camlockTarget.char) or camlockTarget.Character  
		local hum=char and char:FindFirstChildOfClass("Humanoid")  
		if hum then  
			local be=char:FindFirstChild("BodyEffects")  
			if be then local ko=be:FindFirstChild("K.O") or be:FindFirstChild("KO") or be:FindFirstChild("Knocked"); if hum.Health<=0 or(ko and ko.Value) then camlockTarget=nil end  
			elseif hum.Health<=0 then camlockTarget=nil end  
		else camlockTarget=nil end  
	end  
end)  
  
UIS.InputBegan:Connect(function(i,gp)  
	if i.UserInputType==Enum.UserInputType.MouseButton1 then  
		if cfg.rapidFireEnabled then  
			local gun=getrapidgun()  
			if gun then patchtool(gun); isfiring=true end  
		end  
	end  
	if gp then return end  
	if i.UserInputType~=Enum.UserInputType.Keyboard then return end  
	if cfg.camlock and i.KeyCode==cfg.camlockKey then  
		if cfg.camlockMode=="Hold" then  
			camlockTarget=closestToCursor(cfg.camlockFOVEnabled and cfg.camlockFOVRadius or nil,cfg.camlockTeamCheck,cfg.camlockMaxDist)  
		elseif cfg.camlockMode=="Toggle" then  
			if camlockTarget then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom  
			else camlockTarget=closestToCursor(cfg.camlockFOVEnabled and cfg.camlockFOVRadius or nil,cfg.camlockTeamCheck,cfg.camlockMaxDist) end  
		end  
	end  
	if cfg.silentAim and cfg.silentAimKey~=Enum.KeyCode.Unknown and i.KeyCode==cfg.silentAimKey then  
		if cfg.silentAimMode=="Hold" then cfg.silentAim=true end  
	end  
	if cfg.spin360Key~=Enum.KeyCode.Unknown and i.KeyCode==cfg.spin360Key then task.spawn(do360) end  
	if cfg.forceHitKey~=Enum.KeyCode.Unknown and i.KeyCode==cfg.forceHitKey then  
		cfg.forceHitEnabled = not cfg.forceHitEnabled  
		notify("Force Hit: "..(cfg.forceHitEnabled and "Enabled" or "Disabled"))  
	end  
	if cfg.walkspeedException and cfg.walkspeedKey~=Enum.KeyCode.Unknown and i.KeyCode==cfg.walkspeedKey then  
		stopWalkspeed()  
	elseif not cfg.walkspeedException and cfg.walkspeedKey~=Enum.KeyCode.Unknown and i.KeyCode==cfg.walkspeedKey then  
		startWalkspeed(); walkspeedEnabled=true  
	end  
end)  
  
UIS.InputEnded:Connect(function(i)  
	if i.UserInputType==Enum.UserInputType.MouseButton1 then isfiring=false end  
	if i.UserInputType~=Enum.UserInputType.Keyboard then return end  
	if cfg.camlock and i.KeyCode==cfg.camlockKey and cfg.camlockMode=="Hold" then camlockTarget=nil end  
	if cfg.silentAim and cfg.silentAimKey~=Enum.KeyCode.Unknown and i.KeyCode==cfg.silentAimKey and cfg.silentAimMode=="Hold" then cfg.silentAim=false end  
end)  
  
setupJumpPower()  
startInfiniteJump()  
  
lp.CharacterAdded:Connect(function(char)  
	local hum=char:WaitForChild("Humanoid")  
	hum.WalkSpeed=cfg.walkspeed;hum.JumpPower=cfg.jumppower  
	if cfg.flightEnabled then task.wait(0.5);startFlight() end  
	if cfg.esp then for _,p in pairs(Players:GetPlayers()) do createESP(p) end end  
	if walkspeedEnabled then task.wait(0.1);startWalkspeed() end  
	task.wait(0.1);setupJumpPower()  
	if cfg.currentMaterial then task.wait(0.2);applyMat(cfg.currentMaterial) end  
	if cfg.textureColorEnabled then applyTextureColor(cfg.textureColor) end  
	if cfg.fogEnabled then setFog(true) end  
	setupRapidFireOnChar(char)  
end)  
  
if lp.Character then  
	local gun=getrapidgun(); if gun and cfg.rapidFireEnabled then patchtool(gun) end  
end  
  
task.spawn(function()  
	local rs = game:GetService("ReplicatedStorage")  
	local modules = rs:WaitForChild("Modules", 10)  
	if not modules then return end  
	local gunhandler = modules:WaitForChild("GunHandler", 10)  
	if not gunhandler then return end  
	local ok, handler = pcall(require, gunhandler)  
	if not ok or type(handler) ~= "table" then return end  
  
	local function patchShootFn(original)  
		if type(original) ~= "function" then return original end  
		return function(t, ...)  
			if type(t) == "table" then  
				if cfg.rangeExpanderEnabled then  
					t.Range = cfg.rangeExpanderRange  
					if t.range then t.range = cfg.rangeExpanderRange end  
				end  
				if (cfg.forceHitEnabled or cfg.bulletTeleportEnabled) and camlockTarget then  
					local char = (type(camlockTarget)=="table" and camlockTarget.char) or camlockTarget.Character  
					if char then  
						local player = Players:GetPlayerFromCharacter(char)  
						if player then  
							local hum = char:FindFirstChildOfClass("Humanoid")  
							if hum and hum.Health > 0 then  
								local head = char:FindFirstChild("Head")  
								if head then  
									t.AimPosition = head.Position  
									if t.aimPosition then t.aimPosition = head.Position end  
									if cfg.bulletTeleportEnabled then  
										local dir = (cam.CFrame.Position - head.Position).Unit  
										local origin = head.Position + dir * cfg.bulletTeleportOffset  
										t.ForcedOrigin = origin  
										if t.forcedOrigin then t.forcedOrigin = origin end  
									end  
								end  
							end  
						end  
					end  
				end  
			end  
			return original(t, ...)  
		end  
	end  
  
	if handler.Shoot then handler.Shoot = patchShootFn(handler.Shoot) end  
	if handler.shoot then handler.shoot = patchShootFn(handler.shoot) end  

	-- Rapid fire: continuously zero upvalue 7 (last-fire timestamp) on GunHandler.shoot
	local shootFn = handler.shoot or handler.Shoot
	if shootFn then
		RunService.Heartbeat:Connect(function()
			if cfg.rapidFireEnabled then
				pcall(debug.setupvalue, shootFn, 7, 0)
			end
		end)
	end
end)  

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Zoophack/Library.lua"))()  
  
local Window = Library:Window({  
	Name = "",  
	GradientTitle = {Enabled=false,Start=Color3.fromRGB(255,255,255),Middle=Color3.fromRGB(0,251,255),End=Color3.fromRGB(50,135,168),Speed=1}  
})  

-- Replace the title text with the klax logo image
task.defer(function()
	task.wait(0.1)
	pcall(function()
		local hui = (gethui and gethui()) or game:GetService("CoreGui")
		for _, gui in ipairs(hui:GetDescendants()) do
			if gui:IsA("Frame") and gui.Size == UDim2.new(0.188, 0, 0, 37) then
				local titleFrame = gui
				-- hide text and remove the box
				titleFrame.BackgroundTransparency = 1
				titleFrame.BorderSizePixel = 0
				for _, child in ipairs(titleFrame:GetDescendants()) do
					if child:IsA("TextLabel") then
						child.Visible = false
					elseif child:IsA("UIStroke") then
						child.Enabled = false
					end
				end
				-- inject logo — slightly smaller, lowered to match tab bar height
				local img = Instance.new("ImageLabel")
				img.BackgroundTransparency = 1
				img.Size = UDim2.new(1.55, 0, 1.55, 0)
				img.Position = UDim2.new(-0.5, 0, -0.35, 0)
				img.Image = "rbxassetid://125378598957071"
				img.ScaleType = Enum.ScaleType.Fit
				img.ImageTransparency = 0
				img.ZIndex = 5
				img.ClipsDescendants = false
				img.Parent = titleFrame

				-- "klax" text to the right of the logo
				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Size = UDim2.new(1.5, 0, 0.7, 0)
				lbl.Position = UDim2.new(0.5, 0, 0.15, 0)
				lbl.Text = "klax"
				lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				lbl.TextSize = 15
				lbl.Font = Enum.Font.GothamBold
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 6
				lbl.Parent = titleFrame

				-- center the main window frame on screen
				local windowFrame = titleFrame.Parent
				while windowFrame and not windowFrame:IsA("ScreenGui") do
					if windowFrame.Parent and windowFrame.Parent:IsA("ScreenGui") then
						-- this is the top-level window frame
						windowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
						windowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

						-- find the tab bar by its horizontal UIListLayout and shift it left
						for _, child in ipairs(windowFrame:GetDescendants()) do
							if child:IsA("UIListLayout")
								and child.FillDirection == Enum.FillDirection.Horizontal
								and child.Parent and child.Parent:IsA("Frame") then
								local tabBar = child.Parent
								tabBar.Position = UDim2.new(
									tabBar.Position.X.Scale - 0.04,
									tabBar.Position.X.Offset,
									tabBar.Position.Y.Scale,
									tabBar.Position.Y.Offset
								)
								break
							end
						end

						break
					end
					windowFrame = windowFrame.Parent
				end

				break
			end
		end
	end)
end)
  
local Watermark = Library:Watermark("klax.cc", {"125378598957071", Color3.fromRGB(255,255,255)})  
  
local function notify(text, duration, color)  
	if not cfg.notificationsEnabled then return end  
	Library:Notification(text, duration or 3, color or Color3.fromRGB(0,200,130))  
end  
  
local KeybindList = Library:KeybindList()  
  
-- UI sections wrapped in own function to stay under Lua 200 local register limit
;(function()
local CombatTab  = Window:Page({Name="Combat",  Columns=2})
local MiscTab    = Window:Page({Name="Misc",    Columns=2})  
local VisualsTab = Window:Page({Name="Visuals", Columns=2})  
local WorldTab   = Window:Page({Name="World",   Columns=2})  
local PlayersTab = Window:Page({Name="Players", Columns=1})  
local SettingsTab= Window:Page({Name="Settings",Columns=2})  
  
local SilentSec = CombatTab:Section({Name="Silent Aim", Side=1})  
SilentSec:Toggle({Name="Enabled",Flag="silentAim",Default=false,Callback=function(v) cfg.silentAim=v; if v then installSilentAimHooks() else uninstallSilentAimHooks() end end})  
SilentSec:Dropdown({Name="Method",Flag="silentAimMethod",Items={"Lethal","Raycast"},Default="Lethal",Callback=function(v) cfg.silentAimMethod=v; if cfg.silentAim then installSilentAimHooks() end end})  
local silKeyLbl=SilentSec:Label("Keybind","Left")  
silKeyLbl:Keybind({Name="Keybind",Flag="silentAimKey",Default=Enum.KeyCode.Unknown,Mode="Toggle",Callback=function()  
	local f=Library.Flags["silentAimKey"]; if f and f.Key then  
		local ok,kc=pcall(function() local p=tostring(f.Key):split("."); return Enum.KeyCode[p[#p]] end)  
		if ok and kc then cfg.silentAimKey=kc end  
	end  
end})  
SilentSec:Dropdown({Name="Mode",Flag="silentAimMode",Items={"Toggle","Hold","Always"},Default="Toggle",Callback=function(v) cfg.silentAimMode=v end})  
SilentSec:Slider({Name="FOV Radius",Flag="silentAimFOV",Min=50,Max=800,Default=200,Suffix="",Callback=function(v) cfg.silentAimFOV=v; if fovCircle then fovCircle.Radius=v end end})  
SilentSec:Toggle({Name="Show FOV",Flag="silentAimFOVShow",Default=false,Callback=function(v) cfg.silentAimFOVShow=v; if fovCircle then fovCircle.Visible=v and cfg.silentAim end end})  
SilentSec:Toggle({Name="FOV Filled",Flag="silentFOVFill",Default=false,Callback=function(v) cfg.silentAimFOVFilled=v end})  
SilentSec:Slider({Name="FOV Opacity",Flag="silentFOVOp",Min=0,Max=1,Default=0.1,Decimals=0.05,Suffix="",Callback=function(v) cfg.silentAimFOVOpacity=v end})  
local sfc=SilentSec:Label("FOV Color","Left");sfc:Colorpicker({Name="FOV Color",Flag="silentFOVCol",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.silentAimFOVColor=c; if fovCircle then fovCircle.Color=c end end})  
SilentSec:Slider({Name="Pred X",Flag="silentPX",Min=0,Max=1,Default=0.12,Decimals=0.01,Suffix="",Callback=function(v) cfg.silentAimPredX=v end})  
SilentSec:Slider({Name="Pred Y",Flag="silentPY",Min=0,Max=1,Default=0.12,Decimals=0.01,Suffix="",Callback=function(v) cfg.silentAimPredY=v end})  
SilentSec:Dropdown({Name="Hit Part",Flag="silentPart",Items={"Head","HumanoidRootPart","UpperTorso","LowerTorso","Neck"},Default="Head",Callback=function(v) cfg.silentAimPart=v end})  
SilentSec:Toggle({Name="Closest Part",Flag="silentClose",Default=false,Callback=function(v) cfg.silentAimClosestPart=v end})  
SilentSec:Toggle({Name="Use Air Part",Flag="silentAirUse",Default=false,Callback=function(v) cfg.silentAimUseAirPart=v end})  
SilentSec:Dropdown({Name="Air Part",Flag="silentAirPart",Items={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},Default="LowerTorso",Callback=function(v) cfg.silentAimAirPart=v end})  
SilentSec:Toggle({Name="Wall Check",Flag="silentWall",Default=false,Callback=function(v) cfg.silentAimWallCheck=v end})  
SilentSec:Toggle({Name="Team Check",Flag="silentTeam",Default=false,Callback=function(v) cfg.silentAimTeamCheck=v end})  
SilentSec:Toggle({Name="KO Check",Flag="silentKO",Default=false,Callback=function(v) cfg.silentAimKOCheck=v end})  
SilentSec:Toggle({Name="Target Bots",Flag="silentBots",Default=false,Callback=function(v) cfg.silentAimTargetBots=v end})  
SilentSec:Slider({Name="Max Distance",Flag="silentDist",Min=50,Max=2000,Default=500,Suffix="",Callback=function(v) cfg.silentAimMaxDist=v end})  
SilentSec:Slider({Name="Hit Chance %",Flag="silentHit",Min=0,Max=100,Default=100,Suffix="%",Callback=function(v) cfg.silentAimHitChance=v end})  

local CamSec = CombatTab:Section({Name="Camlock", Side=2})  
CamSec:Toggle({Name="Enabled",Flag="camlock",Default=false,Callback=function(v) cfg.camlock=v; if not v then camlockTarget=nil;cam.CameraType=Enum.CameraType.Custom end; for _,d in pairs(espData) do d.name.Color=v and Color3.fromRGB(255,50,50) or cfg.espNameColor end end})  
local camKeyLbl=CamSec:Label("Keybind","Left")  
camKeyLbl:Keybind({Name="Keybind",Flag="camlockKey",Default=Enum.KeyCode.Q,Mode="Toggle",Callback=function()  
	local f=Library.Flags["camlockKey"]; if f and f.Key then  
		local ok,kc=pcall(function() local p=tostring(f.Key):split("."); return Enum.KeyCode[p[#p]] end)  
		if ok and kc then cfg.camlockKey=kc end  
	end  
end})  
CamSec:Dropdown({Name="Mode",Flag="camlockMode",Items={"Toggle","Hold","Always"},Default="Toggle",Callback=function(v) cfg.camlockMode=v end})  
CamSec:Slider({Name="Smoothness",Flag="camlockSmooth",Min=0.01,Max=1,Default=0.15,Decimals=0.01,Suffix="",Callback=function(v) cfg.camlockSmooth=v end})  
CamSec:Slider({Name="Sensitivity",Flag="camlockSens",Min=0.1,Max=5,Default=1,Decimals=0.1,Suffix="x",Callback=function(v) cfg.camlockSensitivity=v end})  
CamSec:Dropdown({Name="Aim Style",Flag="camlockStyle",Items={"Linear","Sine In","Sine Out","Sine In-Out","Quad In","Quad Out","Quad In-Out","Cubic In","Cubic Out","Cubic In-Out","Expo In","Expo Out","Spring","Velocity"},Default="Linear",Callback=function(v) cfg.camlockAimStyle=v end})  
CamSec:Toggle({Name="Show FOV",Flag="camlockFOVEnabled",Default=false,Callback=function(v) cfg.camlockFOVEnabled=v; if camlockFOVCircle then camlockFOVCircle.Visible=v end end})  
CamSec:Toggle({Name="FOV Filled",Flag="camlockFOVFill",Default=false,Callback=function(v) cfg.camlockFOVFilled=v end})  
CamSec:Slider({Name="FOV Radius",Flag="camlockFOVRad",Min=50,Max=800,Default=300,Suffix="",Callback=function(v) cfg.camlockFOVRadius=v; if camlockFOVCircle then camlockFOVCircle.Radius=v end end})  
CamSec:Slider({Name="FOV Opacity",Flag="camlockFOVOp",Min=0,Max=1,Default=0.1,Decimals=0.05,Suffix="",Callback=function(v) cfg.camlockFOVOpacity=v end})  
local cfc=CamSec:Label("FOV Color","Left");cfc:Colorpicker({Name="FOV Color",Flag="camlockFOVCol",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.camlockFOVColor=c; if camlockFOVCircle then camlockFOVCircle.Color=c end end})  
CamSec:Slider({Name="Pred X",Flag="camlockPX",Min=0,Max=1,Default=0.13,Decimals=0.01,Suffix="",Callback=function(v) cfg.camlockPredX=v end})  
CamSec:Slider({Name="Pred Y",Flag="camlockPY",Min=0,Max=1,Default=0.08,Decimals=0.01,Suffix="",Callback=function(v) cfg.camlockPredY=v end})  
CamSec:Toggle({Name="Air Pred X",Flag="camlockAirPredXEn",Default=false,Callback=function(v) cfg.camlockAirPredXEnabled=v; if not v then airPredCurrentX=0 end end})  
CamSec:Slider({Name="Air Pred X (-left/+right)",Flag="camlockAirPX",Min=-5,Max=5,Default=0,Decimals=0.1,Suffix="",Callback=function(v) cfg.camlockAirPredX=v end})  
CamSec:Slider({Name="Air Pred Speed",Flag="camlockAirPredSmooth",Min=0.01,Max=1,Default=0.3,Decimals=0.01,Suffix="",Callback=function(v) cfg.camlockAirPredSmooth=v end})  
CamSec:Slider({Name="Air Pred Curvature",Flag="camlockAirPredCurve",Min=0.5,Max=5,Default=2,Decimals=0.1,Suffix="",Callback=function(v) cfg.camlockAirPredCurve=v end})  
CamSec:Slider({Name="Curve Height (-body/+neck)",Flag="camlockAirPredCurveHeight",Min=-3,Max=3,Default=0,Decimals=0.1,Suffix="",Callback=function(v) cfg.camlockAirPredCurveHeight=v end})  
CamSec:Toggle({Name="Jump Prediction",Flag="camlockJump",Default=false,Callback=function(v) cfg.camlockJumpPredEnabled=v end})  
CamSec:Slider({Name="Jump Pred Y",Flag="camlockJPY",Min=0,Max=1,Default=0.15,Decimals=0.01,Suffix="",Callback=function(v) cfg.camlockJumpPredY=v end})  
CamSec:Toggle({Name="Fall Prediction",Flag="camlockFall",Default=false,Callback=function(v) cfg.camlockFallPredEnabled=v end})  
CamSec:Slider({Name="Fall Pred Y",Flag="camlockFPY",Min=0,Max=1,Default=0.05,Decimals=0.01,Suffix="",Callback=function(v) cfg.camlockFallPredY=v end})  
CamSec:Toggle({Name="Static Offset",Flag="camlockStatOff",Default=false,Callback=function(v) cfg.camlockStaticOffsetEnabled=v end})  
CamSec:Slider({Name="Offset Y (-leg/+neck)",Flag="camlockStatOffY",Min=-5,Max=5,Default=0,Decimals=0.1,Suffix="",Callback=function(v) cfg.camlockStaticOffsetY=v end})  
CamSec:Dropdown({Name="Hit Part",Flag="camlockPart",Items={"Head","HumanoidRootPart","UpperTorso","LowerTorso","Neck"},Default="Head",Callback=function(v) cfg.camlockPart=v end})  
CamSec:Toggle({Name="Use Air Part",Flag="camlockAirUse",Default=false,Callback=function(v) cfg.camlockUseAirPart=v end})  
CamSec:Dropdown({Name="Air Part",Flag="camlockAirPart",Items={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},Default="LowerTorso",Callback=function(v) cfg.camlockAirPart=v end})  
CamSec:Toggle({Name="Closest Part",Flag="camlockClose",Default=false,Callback=function(v) cfg.camlockClosestPart=v end})  
CamSec:Toggle({Name="Wall Check",Flag="camlockWall",Default=false,Callback=function(v) cfg.camlockWallCheck=v end})  
CamSec:Toggle({Name="Team Check",Flag="camlockTeam",Default=false,Callback=function(v) cfg.camlockTeamCheck=v end})  
CamSec:Toggle({Name="KO Check",Flag="camlockKO",Default=false,Callback=function(v) cfg.camlockKOCheck=v end})  
CamSec:Toggle({Name="Target Bots",Flag="camlockBots",Default=false,Callback=function(v) cfg.camlockTargetBots=v end})  
CamSec:Slider({Name="Max Distance",Flag="camlockDist",Min=50,Max=2000,Default=500,Suffix="",Callback=function(v) cfg.camlockMaxDist=v end})  

local MoveSec = MiscTab:Section({Name="Movement", Side=1})  
MoveSec:Slider({Name="Walk Speed",Flag="ws",Min=16,Max=1000,Default=16,Suffix="",Callback=function(v) cfg.walkspeed=v; local c=lp.Character; if c then if v>16 then applySlippery() else removeSlippery() end end end})  
MoveSec:Toggle({Name="Walkspeed",Flag="wsEnabled",Default=false,Callback=function(v) if v then startWalkspeed();walkspeedEnabled=true else stopWalkspeed() end end})  
local wsKeyLbl=MoveSec:Label("Walkspeed Key","Left")  
wsKeyLbl:Keybind({Name="Walkspeed Key",Flag="wsKeyBind",Default=Enum.KeyCode.Unknown,Mode="Toggle",Callback=function()  
	local f=Library.Flags["wsKeyBind"]; if f and f.Key then  
		local ok,kc=pcall(function() local p=tostring(f.Key):split("."); return Enum.KeyCode[p[#p]] end)  
		if ok and kc then cfg.walkspeedKey=kc end  
	end  
end})  
MoveSec:Slider({Name="Jump Power",Flag="jp",Min=50,Max=400,Default=50,Suffix="",Callback=function(v) cfg.jumppower=v end})  
MoveSec:Slider({Name="FOV",Flag="fovSlider",Min=30,Max=120,Default=70,Suffix="",Callback=function(v) cfg.fov=v; cam.FieldOfView=v end})  
MoveSec:Toggle({Name="Flight",Flag="fly",Default=false,Callback=function(v) cfg.flightEnabled=v; if v then startFlight() else stopFlight() end end})  
MoveSec:Slider({Name="Flight Speed",Flag="flySpd",Min=10,Max=1000,Default=50,Suffix="",Callback=function(v) cfg.flightSpeed=v end})  
MoveSec:Toggle({Name="Noclip",Flag="noclip",Default=false,Callback=function(v) cfg.noclip=v; if v then enableNoclip() else disableNoclip() end end})  
MoveSec:Toggle({Name="Infinite Jump",Flag="ijump",Default=false,Callback=function(v) cfg.infiniteJump=v; if v then startInfiniteJump() else stopInfiniteJump() end end})  
  
local SpinSec = MiscTab:Section({Name="360 Spin", Side=2})  
local spinKeyLbl=SpinSec:Label("Spin Key","Left")  
spinKeyLbl:Keybind({Name="Spin Key",Flag="spinKeyBind",Default=Enum.KeyCode.C,Mode="Toggle",Callback=function()  
	local f=Library.Flags["spinKeyBind"]; if f and f.Key then  
		local ok,kc=pcall(function() local p=tostring(f.Key):split("."); return Enum.KeyCode[p[#p]] end)  
		if ok and kc then cfg.spin360Key=kc end  
	end  
end})  
SpinSec:Slider({Name="Speed",Flag="spinSpd",Min=1,Max=500,Default=5,Suffix="",Callback=function(v) cfg.spin360Speed=v end})  
SpinSec:Slider({Name="Loops",Flag="spinLoops",Min=1,Max=10,Default=1,Suffix="",Callback=function(v) cfg.spin360Loops=math.floor(v) end})  
local _spinDirBtn  
_spinDirBtn = SpinSec:Button({Name="Direction: Clockwise",Callback=function()  
	cfg.spin360Direction = cfg.spin360Direction * -1  
	local dirName = cfg.spin360Direction == 1 and "Clockwise" or "Counter-Clockwise"  
	local newText = "Direction: " .. dirName  
	pcall(function()  
		for _, v in ipairs(Library.Holder.Instance:GetDescendants()) do  
			if v:IsA("TextLabel") and v.Text:find("Direction:") then  
				v.Text = newText  
				break  
			end  
		end  
	end)  
end})  
  
local AnimSec = MiscTab:Section({Name="Animation Changer", Side=2})
AnimSec:Toggle({Name="Enabled", Flag="animChanger", Default=false, Callback=function(v)
	animChangerEnabled = v
	if v then startAnimChanger() else stopAnimChanger() end
end})
AnimSec:Dropdown({Name="Idle", Flag="animIdle", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.idle = v
	if animChangerEnabled then applyAnimSlots() end
end})
AnimSec:Dropdown({Name="Run", Flag="animRun", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.run = v
	if animChangerEnabled then applyAnimSlots() end
end})
AnimSec:Dropdown({Name="Walk", Flag="animWalk", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.walk = v
	if animChangerEnabled then applyAnimSlots() end
end})
AnimSec:Dropdown({Name="Jump", Flag="animJump", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.jump = v
	if animChangerEnabled then applyAnimSlots() end
end})
AnimSec:Dropdown({Name="Fall", Flag="animFall", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.fall = v
	if animChangerEnabled then applyAnimSlots() end
end})
AnimSec:Dropdown({Name="Climb", Flag="animClimb", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.climb = v
	if animChangerEnabled then applyAnimSlots() end
end})
AnimSec:Dropdown({Name="Swim", Flag="animSwim", Items=ANIM_NAMES, Default="Default", Callback=function(v)
	animSlots.swim = v
	if animChangerEnabled then applyAnimSlots() end
end})

local RapidSec = MiscTab:Section({Name="Rapid Fire", Side=1})  
RapidSec:Toggle({Name="Enabled",Flag="rfEnabled",Default=false,Callback=function(v)  
	cfg.rapidFireEnabled=v  
	if not v then isfiring=false end  
	if v then local gun=getrapidgun(); if gun then patchtool(gun) end end  
end})  
RapidSec:Slider({Name="Delay",Flag="rfDelay",Min=0,Max=0.5,Default=0.01,Decimals=0.01,Suffix="s",Callback=function(v) cfg.rapidFireDelay=v end})  
RapidSec:Toggle({Name="Specific Weapons Only",Flag="rfSpecific",Default=false,Callback=function(v) cfg.rapidFireSpecificEnabled=v end})  
RapidSec:Dropdown({Name="Weapons",Flag="rfWeapons",Items={"Revolver","Double-Barrel SG","TacticalShotgun","Shotgun","DrumShotgun","AK-47","AR","Silencer AR","Drum Gun","AUG","P90","Rifle","Silencer","Glock"},Default={"Revolver","Double-Barrel SG","TacticalShotgun"},Multi=true,Callback=function(v)  
	if type(v)=="table" then cfg.rapidFireWeapons=table.concat(v,",") elseif type(v)=="string" then cfg.rapidFireWeapons=v end  
end})  
  
local SpreadSec = MiscTab:Section({Name="Spread Modifier", Side=2})  
SpreadSec:Toggle({Name="Enabled",Flag="spreadEnabled",Default=false,Callback=function(v) cfg.spreadEnabled=v end})  
SpreadSec:Slider({Name="Amount",Flag="spreadAmount",Min=0,Max=100,Default=10,Suffix="%",Callback=function(v) cfg.spreadAmount=v end})  
SpreadSec:Toggle({Name="Specific Weapons Only",Flag="spreadSpecific",Default=false,Callback=function(v) cfg.spreadSpecificEnabled=v end})  
SpreadSec:Dropdown({Name="Weapons",Flag="spreadWeapons",Items={"Revolver","Double-Barrel SG","TacticalShotgun","Shotgun","DrumShotgun","AK-47","AR","Silencer AR","Drum Gun","AUG","P90","Rifle","Silencer","Glock"},Default={"Revolver","Double-Barrel SG","TacticalShotgun"},Multi=true,Callback=function(v)  
	if type(v)=="table" then cfg.spreadWeapons=table.concat(v,",") elseif type(v)=="string" then cfg.spreadWeapons=v end  
end})  
  
local BTPSec = MiscTab:Section({Name="Bullet Teleport", Side=2})  
BTPSec:Toggle({Name="Enabled",Flag="btpEnabled",Default=false,Callback=function(v)  
	cfg.bulletTeleportEnabled=v; if not v then btpLine.Visible=false end  
end})  
BTPSec:Slider({Name="Offset",Flag="btpOffset",Min=1,Max=50,Default=5,Suffix=" studs",Callback=function(v) cfg.bulletTeleportOffset=v end})  
BTPSec:Toggle({Name="Show Line",Flag="btpLine",Default=true,Callback=function(v) cfg.bulletTeleportLineEnabled=v; if not v then btpLine.Visible=false end end})  
BTPSec:Label("Line Color","Left"):Colorpicker({Name="Line Color",Flag="btpLineCol",Default=Color3.fromRGB(255,100,0),Callback=function(c) cfg.bulletTeleportLineColor=c end})  
BTPSec:Toggle({Name="Force Hit",Flag="forceHitToggle",Default=false,Callback=function(v) cfg.forceHitEnabled=v end})  
local fhKeyLbl=BTPSec:Label("Force Hit Key","Left")  
fhKeyLbl:Keybind({Name="Force Hit Key",Flag="fhKey",Default=Enum.KeyCode.Unknown,Mode="Toggle",Callback=function()  
	local f=Library.Flags["fhKey"]; if f and f.Key then  
		local ok,kc=pcall(function() local p=tostring(f.Key):split("."); return Enum.KeyCode[p[#p]] end)  
		if ok and kc then cfg.forceHitKey=kc end  
	end  
end})  
  
local RangeSec = MiscTab:Section({Name="Range Expander", Side=1})  
RangeSec:Toggle({Name="Enabled",Flag="rangeExpEnabled",Default=true,Callback=function(v) cfg.rangeExpanderEnabled=v end})  
RangeSec:Slider({Name="Range",Flag="rangeExpRange",Min=500,Max=999999,Default=999999,Suffix=" studs",Callback=function(v) cfg.rangeExpanderRange=v end})  
  
local EspSec = VisualsTab:Section({Name="ESP", Side=1})  
EspSec:Toggle({Name="Enabled",Flag="esp",Default=false,Callback=function(v) cfg.esp=v; toggleESP(v) end})  
EspSec:Toggle({Name="Boxes",Flag="espBox",Default=false,Callback=function(v) cfg.espBoxes=v end})  
local bxc=EspSec:Label("Box Color","Left");bxc:Colorpicker({Name="Box Color",Flag="espBoxC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espBoxColor=c end})  
EspSec:Toggle({Name="Box Fill",Flag="espBoxFill",Default=false,Callback=function(v) cfg.espBoxFilled=v end})
local bfc=EspSec:Label("Box Fill Color","Left");bfc:Colorpicker({Name="Box Fill Color",Flag="espBoxFillC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espBoxFillColor=c end})  
EspSec:Slider({Name="Fill Transparency",Flag="espFillTr",Min=0,Max=1,Default=0.85,Decimals=0.01,Suffix="",Callback=function(v) cfg.espFillTransparency=v end})  
EspSec:Toggle({Name="Bones",Flag="espBone",Default=false,Callback=function(v) cfg.espBones=v end})  
local bnc=EspSec:Label("Bone Color","Left");bnc:Colorpicker({Name="Bone Color",Flag="espBoneC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espBoneColor=c end})  
EspSec:Toggle({Name="Names",Flag="espName",Default=false,Callback=function(v) cfg.espNames=v end})  
EspSec:Dropdown({Name="Name Style",Flag="espNameStyle",Items={"Default","Lethal"},Default="Default",Callback=function(v)  
	cfg.espNameStyle=v  
	for plr,d in pairs(espData) do  
		if v=="Lethal" then d.name.Visible=false  
		else destroyBillboard(d) end  
	end  
end})  
local nmc=EspSec:Label("Name Color","Left");nmc:Colorpicker({Name="Name Color",Flag="espNameC",Default=Color3.fromRGB(255,255,255),Callback=function(c) cfg.espNameColor=c end})  
-- TASK #7: target name color picker  
local tnc=EspSec:Label("Target Name Color","Left");tnc:Colorpicker({Name="Target Name Color",Flag="espTargetNameC",Default=Color3.fromRGB(255,50,50),Callback=function(c) cfg.espTargetNameColor=c end})  
EspSec:Toggle({Name="Health",Flag="espHp",Default=false,Callback=function(v) cfg.espHealth=v end})  
local hpc=EspSec:Label("Health Color","Left");hpc:Colorpicker({Name="Health Color",Flag="espHpC",Default=Color3.fromRGB(100,255,150),Callback=function(c) cfg.espHealthColor=c end})  
EspSec:Toggle({Name="Distance",Flag="espDist",Default=false,Callback=function(v) cfg.espDistance=v end})  
local dc=EspSec:Label("Distance Color","Left");dc:Colorpicker({Name="Dist Color",Flag="espDistC",Default=Color3.fromRGB(140,140,170),Callback=function(c) cfg.espDistColor=c end})  
EspSec:Toggle({Name="Tracers",Flag="espTrace",Default=false,Callback=function(v) cfg.espTracers=v end})  
local tc=EspSec:Label("Tracer Color","Left");tc:Colorpicker({Name="Tracer Color",Flag="espTraceC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espTracerColor=c end})  
EspSec:Toggle({Name="Head Dot",Flag="espHD",Default=false,Callback=function(v) cfg.espHeadDot=v end})  
local hdc=EspSec:Label("Head Dot Color","Left");hdc:Colorpicker({Name="Head Dot Color",Flag="espHDC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espHeadDotColor=c end})  
EspSec:Toggle({Name="Chams",Flag="espCham",Default=false,Callback=function(v) cfg.espChams=v end})  
local chc=EspSec:Label("Chams Fill Color","Left");chc:Colorpicker({Name="Chams Fill Color",Flag="espChamC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espChamsFillColor=c end})  
local choc=EspSec:Label("Chams Outline Color","Left");choc:Colorpicker({Name="Chams Outline Color",Flag="espChamOC",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.espChamsOutlineColor=c end})  
EspSec:Slider({Name="Chams Transparency",Flag="espChamTr",Min=0,Max=1,Default=0.5,Decimals=0.05,Suffix="",Callback=function(v) cfg.espChamsTransparency=v end})  
EspSec:Dropdown({Name="ESP Mode",Flag="espMode",Items={"Dynamic","Static"},Default="Dynamic",Callback=function(v) cfg.espMode=v end})  
EspSec:Slider({Name="Max Distance",Flag="espMaxD",Min=50,Max=2000,Default=500,Suffix="",Callback=function(v) cfg.espMaxDist=v end})  

local EspPreviewSec = VisualsTab:Section({Name="ESP Preview", Side=2})  
task.spawn(function()  
	task.wait(1)  
	pcall(function()  
		local previewContent = EspPreviewSec.Items["Content"].Instance  
		local vpf = Instance.new("ViewportFrame", previewContent)  
		vpf.Size = UDim2.new(1, 0, 0, 280)  
		vpf.BackgroundColor3 = Color3.fromRGB(8, 8, 12)  
		vpf.BorderSizePixel = 0  
		vpf.LightColor = Color3.fromRGB(255, 255, 255)  
		vpf.LightDirection = Vector3.new(-1, -2, -1)  
		vpf.Ambient = Color3.fromRGB(160, 160, 160)  
		Instance.new("UICorner", vpf).CornerRadius = UDim.new(0, 4)  
		local vpCam = Instance.new("Camera", vpf)  
		vpf.CurrentCamera = vpCam  
		vpCam.CFrame = CFrame.new(Vector3.new(0, 2.5, 6), Vector3.new(0, 2.5, 0))  
		local dummy = Instance.new("Model", vpf)  
		local function mp(n,sz,cf,col)  
			local p=Instance.new("Part",dummy); p.Name=n; p.Size=sz; p.CFrame=cf  
			p.Anchored=true; p.CanCollide=false; p.CastShadow=false  
			p.Color=col; p.Material=Enum.Material.SmoothPlastic; return p  
		end  
		local G=Color3.fromRGB(163,162,165); local S=Color3.fromRGB(196,145,105)  
		mp("Head",Vector3.new(2,1,1),CFrame.new(0,4.5,0),S)  
		mp("Torso",Vector3.new(2,2,1),CFrame.new(0,3,0),G)  
		mp("Left Arm",Vector3.new(1,2,1),CFrame.new(-1.5,3,0),S)  
		mp("Right Arm",Vector3.new(1,2,1),CFrame.new(1.5,3,0),S)  
		mp("Left Leg",Vector3.new(1,2,1),CFrame.new(-0.5,1,0),G)  
		mp("Right Leg",Vector3.new(1,2,1),CFrame.new(0.5,1,0),G)  
		local face=Instance.new("Decal",dummy:FindFirstChild("Head"))  
		face.Face=Enum.NormalId.Front; face.Texture="rbxasset://textures/face.png"  
		dummy.Parent=vpf  
		local selBox=Instance.new("SelectionBox",vpf)  
		selBox.Adornee=dummy; selBox.LineThickness=0.04  
		selBox.SurfaceTransparency=0.5  
		selBox.Color3=cfg.espChamsFillColor; selBox.SurfaceColor3=cfg.espChamsFillColor  
		selBox.Visible=cfg.espChams  
		local overlay=Instance.new("Frame",vpf)  
		overlay.Size=UDim2.new(1,0,1,0); overlay.BackgroundTransparency=1; overlay.BorderSizePixel=0; overlay.ZIndex=10  
		local boxFrame=Instance.new("Frame",overlay)  
		boxFrame.BackgroundTransparency=1; boxFrame.BorderSizePixel=0; boxFrame.ZIndex=11  
		local boxStroke=Instance.new("UIStroke",boxFrame)  
		boxStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; boxStroke.Thickness=1  
		local boxFill=Instance.new("Frame",overlay)  
		boxFill.BorderSizePixel=0; boxFill.ZIndex=10  
		local hbg=Instance.new("Frame",overlay)  
		hbg.BackgroundColor3=Color3.fromRGB(20,20,20); hbg.BorderSizePixel=0; hbg.ZIndex=11  
		local hfill=Instance.new("Frame",hbg)  
		hfill.BorderSizePixel=0; hfill.AnchorPoint=Vector2.new(0,1)  
		hfill.Position=UDim2.new(0,0,1,0); hfill.Size=UDim2.new(1,0,0.75,0); hfill.ZIndex=12  
		local nameLbl=Instance.new("TextLabel",overlay)  
		nameLbl.BackgroundTransparency=1; nameLbl.Font=Enum.Font.Code  
		nameLbl.TextSize=11; nameLbl.ZIndex=12; nameLbl.TextXAlignment=Enum.TextXAlignment.Center  
		local distLbl=Instance.new("TextLabel",overlay)  
		distLbl.BackgroundTransparency=1; distLbl.Font=Enum.Font.Code  
		distLbl.TextSize=10; distLbl.ZIndex=12; distLbl.Text="12m"  
		distLbl.TextXAlignment=Enum.TextXAlignment.Center  
		local tracerLine=Instance.new("Frame",overlay)  
		tracerLine.BorderSizePixel=0; tracerLine.ZIndex=11  
		local headDot=Instance.new("Frame",overlay)  
		headDot.BorderSizePixel=0; headDot.ZIndex=12  
		Instance.new("UICorner",headDot).CornerRadius=UDim.new(1,0)  
		local boneConns={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}  
		local bonePartPos={Head=Vector3.new(0,4.5,0),Torso=Vector3.new(0,3,0),["Left Arm"]=Vector3.new(-1.5,3,0),["Right Arm"]=Vector3.new(1.5,3,0),["Left Leg"]=Vector3.new(-0.5,1,0),["Right Leg"]=Vector3.new(0.5,1,0)}  
		local boneLines={}  
		for _=1,#boneConns do  
			local l=Instance.new("Frame",overlay); l.BorderSizePixel=0; l.ZIndex=11; l.AnchorPoint=Vector2.new(0.5,0.5)  
			table.insert(boneLines,l)  
		end  
		local BH=220; local BW=BH*0.52; local BY=15

		-- project3D defined outside Heartbeat to avoid inflating its local count
		local _W,_H = 1,1
		local function project3D(worldPos)
			local cf=vpCam.CFrame; local localPos=cf:PointToObjectSpace(worldPos)
			if localPos.Z>=0 then return nil end
			local fov=vpCam.FieldOfView; local halfTan=math.tan(math.rad(fov/2))
			local aspect=_W/_H
			local px=(-localPos.X/-localPos.Z)/(halfTan*aspect)*(_W/2)+_W/2
			local py=(localPos.Y/-localPos.Z)/halfTan*(-_H/2)+_H/2
			return Vector2.new(px,py)
		end

		local function updateBones()
			for i,conn in ipairs(boneConns) do
				local line=boneLines[i]; local p1=bonePartPos[conn[1]]; local p2=bonePartPos[conn[2]]
				if p1 and p2 and cfg.espBones then
					local s1=project3D(p1); local s2=project3D(p2)
					if s1 and s2 then
						local dx=s2.X-s1.X; local dy=s2.Y-s1.Y; local len=math.sqrt(dx*dx+dy*dy)
						line.Position=UDim2.new(0,(s1.X+s2.X)/2,0,(s1.Y+s2.Y)/2)
						line.Size=UDim2.new(0,len,0,1); line.Rotation=math.deg(math.atan2(dy,dx))
						line.BackgroundColor3=cfg.espBoneColor; line.Visible=true
					else line.Visible=false end
				else line.Visible=false end
			end
		end

		RunService.Heartbeat:Connect(function()
			if not vpf.Parent then return end
			local W=vpf.AbsoluteSize.X; local H=vpf.AbsoluteSize.Y
			if W<10 then return end
			_W=W; _H=H
			local BX=(W-BW)/2
			boxFrame.Position=UDim2.new(0,BX,0,BY); boxFrame.Size=UDim2.new(0,BW,0,BH)
			boxFrame.Visible=cfg.espBoxes; boxStroke.Color=cfg.espBoxColor
			boxFill.Position=UDim2.new(0,BX,0,BY); boxFill.Size=UDim2.new(0,BW,0,BH)
			boxFill.BackgroundColor3=cfg.espBoxFillColor
			boxFill.BackgroundTransparency=cfg.espFillTransparency
			boxFill.Visible=cfg.espBoxFilled and cfg.espBoxes
			hbg.Position=UDim2.new(0,BX-5,0,BY); hbg.Size=UDim2.new(0,3,0,BH); hbg.Visible=cfg.espHealth
			hfill.BackgroundColor3=cfg.espHealthColor
			nameLbl.Position=UDim2.new(0,BX,0,BY-15); nameLbl.Size=UDim2.new(0,BW,0,14)
			nameLbl.TextColor3=cfg.espNameColor; nameLbl.Text=lp.Name; nameLbl.Visible=cfg.espNames
			distLbl.Position=UDim2.new(0,BX,0,BY+BH+2); distLbl.Size=UDim2.new(0,BW,0,12)
			distLbl.TextColor3=cfg.espDistColor; distLbl.Visible=cfg.espDistance
			tracerLine.Position=UDim2.new(0,BX+BW/2-1,0,BY+BH)
			tracerLine.Size=UDim2.new(0,1,0,H-BY-BH)
			tracerLine.BackgroundColor3=cfg.espTracerColor; tracerLine.Visible=cfg.espTracers
			if cfg.espHeadDot then
				local hs=project3D(Vector3.new(0,5.2,0))
				if hs then headDot.Position=UDim2.new(0,hs.X-4,0,hs.Y-4);headDot.Size=UDim2.new(0,8,0,8);headDot.BackgroundColor3=cfg.espHeadDotColor;headDot.Visible=true
				else headDot.Visible=false end
			else headDot.Visible=false end
			updateBones()
			selBox.Color3=cfg.espChamsFillColor; selBox.SurfaceColor3=cfg.espChamsFillColor
			selBox.SurfaceTransparency=0.5; selBox.Visible=cfg.espChams
		end)
	end)
end)  
  
local IndSec = VisualsTab:Section({Name="Screen Indicator", Side=1})
IndSec:Toggle({Name="Enabled", Flag="indEnabled", Default=true, Callback=function(v)
	indicatorEnabled = v
	if not v then
		if indicatorTitle then indicatorTitle.Visible = false end
		for _, l in ipairs(indicatorLabels) do l.Visible = false end
	end
end})
IndSec:Dropdown({Name="Position", Flag="indPos", Items={"Bottom Center","Bottom Left","Bottom Right","Top Left","Top Right"}, Default="Bottom Center", Callback=function(v)
	indicatorPos = v
end})
local indAc = IndSec:Label("Accent Color", "Left")
indAc:Colorpicker({Name="Accent Color", Flag="indAccent", Default=Color3.fromRGB(0,200,130), Callback=function(c)
	indicatorAccent = c
end})
local indFc = IndSec:Label("Feature Color", "Left")
indFc:Colorpicker({Name="Feature Color", Flag="indFeature", Default=Color3.fromRGB(255,255,255), Callback=function(c)
	indicatorFeature = c
end})

local WCSec = VisualsTab:Section({Name="Weapon Chams", Side=2})  
WCSec:Toggle({Name="Enabled",Flag="wChams",Default=false,Callback=function(v) cfg.weaponChams=v; updateWeaponChams() end})  
WCSec:Toggle({Name="Rainbow",Flag="wChamsRB",Default=false,Callback=function(v) cfg.weaponChamsRainbow=v end})  
WCSec:Toggle({Name="Fill",Flag="wChamsFill",Default=false,Callback=function(v) cfg.weaponChamsFill=v; refreshWeaponGlow() end})  
WCSec:Slider({Name="Transparency",Flag="wChamsTr",Min=0,Max=1,Default=0.65,Decimals=0.05,Suffix="",Callback=function(v) cfg.weaponChamsTransparency=v; refreshWeaponGlow() end})  
local wfc=WCSec:Label("Fill Color","Left");wfc:Colorpicker({Name="Fill Color",Flag="wChamsFillC",Default=Color3.fromRGB(255,170,0),Callback=function(c) cfg.weaponChamsFillColor=c; refreshWeaponGlow() end})  
local woc=WCSec:Label("Outline Color","Left");woc:Colorpicker({Name="Outline Color",Flag="wChamsOC",Default=Color3.fromRGB(255,170,0),Callback=function(c) cfg.weaponChamsOutlineColor=c; refreshWeaponGlow() end})  
  
-- BULLET CHANGER
-- hooks workspace BULLET_RAYS parts and swaps GunBeam with one from ReplicatedStorage.BulletBeams
local bcSelected = "None"
local bcHookConn = nil

local function bcSwapBeam(bulletRays)
	if bcSelected == "None" then return end
	pcall(function()
		local beams = game:GetService("ReplicatedStorage"):FindFirstChild("BulletBeams")
		if not beams then return end
		local beamModel = beams:FindFirstChild(bcSelected)
		if not beamModel then return end
		local beamPart = beamModel:FindFirstChildWhichIsA("BasePart")
		if not beamPart then return end
		local col = beamPart.Color
		local gunBeam = bulletRays:FindFirstChild("GunBeam")
		if not gunBeam or not gunBeam:IsA("Beam") then return end
		gunBeam.Color = ColorSequence.new(col)
		gunBeam.LightEmission = 1
		gunBeam.LightInfluence = 0
	end)
end

local function bcStartHook()
	if bcHookConn then bcHookConn:Disconnect(); bcHookConn = nil end
	if bcSelected == "None" then return end
	bcHookConn = workspace.DescendantAdded:Connect(function(obj)
		if obj.Name == "BULLET_RAYS" and obj:IsA("BasePart") then
			task.defer(function()
				if obj and obj.Parent then bcSwapBeam(obj) end
			end)
		end
	end)
end

local function bcStopHook()
	if bcHookConn then bcHookConn:Disconnect(); bcHookConn = nil end
end

local SkinSec = VisualsTab:Section({Name="Skin Changer", Side=1})

-- scan real skin names from Wraps folder at runtime
local function scGetSkinList(weaponName)
	local list = {"None"}
	pcall(function()
		local wraps = game:GetService("ReplicatedStorage"):FindFirstChild("Wraps")
		local folder = wraps and wraps:FindFirstChild("["..weaponName.."]")
		if folder then
			for _,child in ipairs(folder:GetChildren()) do
				table.insert(list, child.Name)
			end
		end
	end)
	return list
end

task.defer(function()
	task.wait(2) -- wait for RS to load
	local dbList  = scGetSkinList("DoubleBarrel")
	local revList = scGetSkinList("Revolver")
	local tacList = scGetSkinList("TacticalShotgun")
	local smgList = scGetSkinList("SMG")
	local sgList  = scGetSkinList("Shotgun")

	SkinSec:Dropdown({Name="Double Barrel", Flag="scDB", Items=dbList, Default="None", Callback=function(v)
		scSkins.DB=v; local c=lp.Character; if c then scApplyChar(c) end
	end})
	SkinSec:Dropdown({Name="Revolver", Flag="scRev", Items=revList, Default="None", Callback=function(v)
		scSkins.Rev=v; local c=lp.Character; if c then scApplyChar(c) end
	end})
	SkinSec:Dropdown({Name="Tac Shotgun", Flag="scTac", Items=tacList, Default="None", Callback=function(v)
		scSkins.Tac=v; local c=lp.Character; if c then scApplyChar(c) end
	end})
	SkinSec:Dropdown({Name="SMG", Flag="scSMG", Items=smgList, Default="None", Callback=function(v)
		scSkins.SMG=v; local c=lp.Character; if c then scApplyChar(c) end
	end})
	SkinSec:Dropdown({Name="Shotgun", Flag="scSG", Items=sgList, Default="None", Callback=function(v)
		scSkins.SG=v; local c=lp.Character; if c then scApplyChar(c) end
	end})
	SkinSec:Button({Name="Apply / Refresh", Callback=function()
		local c=lp.Character; if c then scApplyChar(c) end
	end})
end)

local BulletSec = VisualsTab:Section({Name="Bullet Changer", Side=2})

task.spawn(function()
	-- wait until BulletBeams is actually loaded
	local rs = game:GetService("ReplicatedStorage")
	local beams = rs:FindFirstChild("BulletBeams")
	if not beams then
		beams = rs:WaitForChild("BulletBeams", 15)
	end
	if not beams then return end

	local beamList = {"None"}
	for _, child in ipairs(beams:GetChildren()) do
		table.insert(beamList, child.Name)
	end

	BulletSec:Dropdown({Name="Bullet Effect", Flag="bcEffect", Items=beamList, Default="None", Callback=function(v)
		bcSelected = v
		if v == "None" then bcStopHook() else bcStartHook() end
	end})
	BulletSec:Button({Name="Stop / Reset", Callback=function()
		bcSelected = "None"
		bcStopHook()
	end})
end)

local RainSec = VisualsTab:Section({Name="Rain", Side=2})  
RainSec:Toggle({Name="Enabled",Flag="rain",Default=false,Callback=function(v) cfg.rainEnabled=v; for _,d in pairs(rainDrops) do if d.line then d.line.Visible=v end end; if v then rebuildRain() end end})  
RainSec:Toggle({Name="Rainbow Rain",Flag="rainRB",Default=false,Callback=function(v) cfg.rainbowRain=v end})  
RainSec:Slider({Name="Radius",Flag="rainRad",Min=20,Max=150,Default=68,Suffix="",Callback=function(v) cfg.rainRadius=v; rebuildRain() end})  
RainSec:Slider({Name="Speed",Flag="rainSpd",Min=1,Max=10,Default=3,Decimals=0.5,Suffix="",Callback=function(v) cfg.rainSpeed=v end})  
RainSec:Slider({Name="Amount",Flag="rainAmt",Min=10,Max=150,Default=60,Suffix="",Callback=function(v) cfg.rainAmount=v; rebuildRain() end})  
RainSec:Slider({Name="Length",Flag="rainLen",Min=1,Max=5,Default=2,Decimals=0.5,Suffix="",Callback=function(v) cfg.rainLength=v end})  
RainSec:Slider({Name="Transparency",Flag="rainTr",Min=0,Max=1,Default=0.3,Decimals=0.05,Suffix="",Callback=function(v) cfg.rainTransparency=v; for _,d in pairs(rainDrops) do if d.line then d.line.Transparency=1-v end end end})  
local rc=RainSec:Label("Rain Color","Left");rc:Colorpicker({Name="Rain Color",Flag="rainCol",Default=Color3.fromRGB(0,200,130),Callback=function(c) cfg.rainColor=c; if not cfg.rainbowRain then for _,d in pairs(rainDrops) do if d.line then d.line.Color=c end end end end})  

local FogSec = WorldTab:Section({Name="Fog", Side=1})  
FogSec:Toggle({Name="Enabled",Flag="fog",Default=false,Callback=function(v) cfg.fogEnabled=v; setFog(v) end})  
FogSec:Slider({Name="Fog Start",Flag="fogS",Min=0,Max=1000,Default=0,Suffix="",Callback=function(v) cfg.fogStart=v; if cfg.fogEnabled then Lighting.FogStart=v end end})  
FogSec:Slider({Name="Fog End",Flag="fogE",Min=100,Max=5000,Default=1000,Suffix="",Callback=function(v) cfg.fogEnd=v; if cfg.fogEnabled then Lighting.FogEnd=v end end})  
local fogc=FogSec:Label("Fog Color","Left");fogc:Colorpicker({Name="Fog Color",Flag="fogCol",Default=Color3.fromRGB(180,180,200),Callback=function(c) cfg.fogColor=c; if cfg.fogEnabled then Lighting.FogColor=c end end})  
  
local SkySec = WorldTab:Section({Name="Skybox", Side=1})  
SkySec:Toggle({Name="Rotating",Flag="rotSky",Default=false,Callback=function(v) cfg.rotatingSkybox=v; toggleRotatingSkybox(v) end})  
for _,name in ipairs({"Piss","Peach","Saku","Purple","Retro","Space","Sea","Night V2","Dark","Anime","Beach","Space V2","Pink","Rainbow","Forest","Night","Lava","Rainy","Green","Volcanic","Minecraft","Lucid","Nebulous"}) do  
	SkySec:Button({Name=name,Callback=function() applySky(name) end})  
end  
SkySec:Button({Name="Default Sky",Callback=function() applySky(nil) end})  
  
local LightSec = WorldTab:Section({Name="Lighting", Side=2})  
LightSec:Toggle({Name="Fullbright",Flag="fullbright",Default=false,Callback=function(v) cfg.fullbrightEnabled=v; toggleFB() end})  
LightSec:Button({Name="Day",Callback=function() setLightingMode("Day") end})  
LightSec:Button({Name="Night",Callback=function() setLightingMode("Night") end})  
LightSec:Button({Name="Sunset",Callback=function() setLightingMode("Sunset") end})  
LightSec:Button({Name="Reset Lighting",Callback=function() if lightingConn then lightingConn:Disconnect();lightingConn=nil end; Lighting.Brightness=origL.Brightness;Lighting.ClockTime=origL.ClockTime;Lighting.GlobalShadows=origL.GlobalShadows;cfg.lightingMode=nil end})  
LightSec:Button({Name="FPS Boost",Callback=function() fpsBoost() end})  
  
local MatSec = WorldTab:Section({Name="Textures & Materials", Side=2})  
MatSec:Toggle({Name="Custom Color",Flag="texCol",Default=false,Callback=function(v) cfg.textureColorEnabled=v; if v then applyTextureColor(cfg.textureColor) else resetTextureColors() end end})  
local texc=MatSec:Label("Color","Left");texc:Colorpicker({Name="Tex Color",Flag="texColPick",Default=Color3.fromRGB(255,255,255),Callback=function(c) cfg.textureColor=c; if cfg.textureColorEnabled then applyTextureColor(c) end end})  
MatSec:Button({Name="Reset Materials",Callback=function() cfg.currentMaterial=nil; resetMats() end})  
for _,e in ipairs({{"Grass",Enum.Material.Grass},{"Leafy Grass",Enum.Material.LeafyGrass},{"Ground",Enum.Material.Ground},{"Mud",Enum.Material.Mud},{"Sand",Enum.Material.Sand},{"Rock",Enum.Material.Rock},{"Concrete",Enum.Material.Concrete},{"Asphalt",Enum.Material.Asphalt},{"Cobblestone",Enum.Material.Cobblestone},{"Brick",Enum.Material.Brick},{"Smooth Plastic",Enum.Material.SmoothPlastic},{"Wood",Enum.Material.Wood},{"Wood Planks",Enum.Material.WoodPlanks},{"Marble",Enum.Material.Marble},{"Granite",Enum.Material.Granite},{"Ice",Enum.Material.Ice},{"Neon",Enum.Material.Neon},{"Glass",Enum.Material.Glass},{"Metal",Enum.Material.Metal},{"Diamond Plate",Enum.Material.DiamondPlate},{"Foil",Enum.Material.Foil},{"Fabric",Enum.Material.Fabric}}) do  
	MatSec:Button({Name=e[1],Callback=function() cfg.currentMaterial=e[2]; applyMat(e[2]) end})  
end  
  
local _plCurrentPlayer = nil  
PlayersTab:PlayerList({  
	Name = "Playerlist",  
	Flag = "Playerlist",  
	Callback = function(player)  
		_plCurrentPlayer = player  
		Library.Flags["PlayerListPlayerStatus"] = "--"  
	end  
})  
  
task.spawn(function()  
	task.wait(0.5)  
	local lastUid = nil  
	local lastVal = "--"  
	while true do  
		task.wait(0.05)  
		if not _plCurrentPlayer then lastUid=nil; lastVal="--"; continue end  
		local uid = _plCurrentPlayer.UserId  
		local val = Library.Flags["PlayerListPlayerStatus"]  
		if type(val) ~= "string" then continue end  
		if uid ~= lastUid then  
			lastUid = uid  
			lastVal = "--"  
		elseif val ~= lastVal then  
			lastVal = val  
			if val == "Friendly" then  
				statusById[uid] = "Friendly"  
				if camlockTarget then  
					local tgt = type(camlockTarget)~="table" and camlockTarget or nil  
					if tgt and tgt.UserId==uid then camlockTarget=nil; cam.CameraType=Enum.CameraType.Custom end  
				end  
			elseif val == "Priority" then  
				statusById[uid] = "Priority"  
			elseif val == "Neutral" or val == "All" or val == "--" then  
				statusById[uid] = "Neutral"  
			end  
		end  
	end  
end)  

local ThemeSec = SettingsTab:Section({Name="Themes", Side=1})  
Library.ThemeColorpickers = Library.ThemeColorpickers or {}  
for Index, Value in pairs(Library.Theme) do  
	Library.ThemeColorpickers[Index] = ThemeSec:Label(Index,"Left"):Colorpicker({  
		Name=Index, Flag="Theme"..Index, Default=Value,  
		Callback=function(v) Library.Theme[Index]=v; Library:ChangeTheme(Index,v) end  
	})  
end  
ThemeSec:Dropdown({Name="Theme Preset",Items={"Default","Bitchbot","Onetap","Aqua"},Default="Default",Callback=function(v)  
	local t=Library.Themes[v]; if not t then return end  
	for k,col in pairs(t) do Library.Theme[k]=col; Library:ChangeTheme(k,col); if Library.ThemeColorpickers[k] then Library.ThemeColorpickers[k]:Set(col) end end  
end})  
local ThemeListbox = ThemeSec:Listbox({Name="Saved Themes",Flag="ThemesList",Items={},Multi=false,Default=nil,Callback=function(v) end})  
ThemeSec:Textbox({Name="Name",Flag="ThemeName",Default="",Placeholder="theme name...",Callback=function(v) end})  
ThemeSec:Button({Name="Save Theme",Callback=function()  
	local n=Library.Flags["ThemeName"]; if not n or n=="" then return end  
	if not isfile(Library.Folders.Themes.."/"..n..".json") then writefile(Library.Folders.Themes.."/"..n..".json",Library:GetTheme()); Library:RefreshThemeList(ThemeListbox) end  
end}):SubButton({Name="Load Theme",Callback=function()  
	local sel=Library.Flags["ThemesList"]; if sel then Library:LoadTheme(readfile(Library.Folders.Themes.."/"..sel)) end  
end})  
ThemeSec:Button({Name="Refresh",Callback=function() Library:RefreshThemeList(ThemeListbox) end})  
Library:RefreshThemeList(ThemeListbox)  
  
local CfgSec = SettingsTab:Section({Name="Configs", Side=2})  
local ConfigListbox = CfgSec:Listbox({Name="Saved Configs",Flag="ConfigsList",Items={},Multi=false,Default=nil,Callback=function(v) end})  
CfgSec:Textbox({Name="Name",Flag="ConfigName",Default="",Placeholder="config name...",Callback=function(v) end})  
CfgSec:Button({Name="Create Config",Callback=function()  
	local n=Library.Flags["ConfigName"]; if not n or n=="" then return end  
	if not isfile(Library.Folders.Configs.."/"..n..".json") then writefile(Library.Folders.Configs.."/"..n..".json",Library:GetConfig()); Library:RefreshConfigsList(ConfigListbox) end  
end}):SubButton({Name="Save Config",Callback=function()  
	local sel=Library.Flags["ConfigsList"]; if sel then Library:SaveConfig(sel) end  
end})  
CfgSec:Button({Name="Load Config",Callback=function()  
	local sel=Library.Flags["ConfigsList"]; if sel then Library:LoadConfig(readfile(Library.Folders.Configs.."/"..sel)) end  
end}):SubButton({Name="Delete Config",Callback=function()  
	local sel=Library.Flags["ConfigsList"]; if sel then Library:DeleteConfig(sel); Library:RefreshConfigsList(ConfigListbox) end  
end})  
CfgSec:Button({Name="Refresh",Callback=function() Library:RefreshConfigsList(ConfigListbox) end})  
Library:RefreshConfigsList(ConfigListbox)  
  
local mkLbl=CfgSec:Label("Menu Keybind","Left")  
mkLbl:Keybind({Name="Menu Key",Flag="MenuKeybind",Default=Enum.KeyCode.RightControl,Mode="Toggle",Callback=function()  
	local f=Library.Flags["MenuKeybind"]; if f and f.Key then Library.MenuKeybind=f.Key end  
end})  
CfgSec:Toggle({Name="Keybind List",Flag="KeybindList",Default=true,Callback=function(v) KeybindList:SetVisibility(v) end})  
KeybindList:SetVisibility(true)  
CfgSec:Toggle({Name="Watermark",Flag="wmToggle",Default=true,Callback=function(v) cfg.watermark=v; Watermark:SetVisibility(v) end})  
CfgSec:Toggle({Name="Screen Indicator",Flag="indToggle",Default=true,Callback=function(v)
	indicatorEnabled=v
	if not v then
		if indicatorTitle then indicatorTitle.Visible=false end
		for _,l in ipairs(indicatorLabels) do l.Visible=false end
	end
end})  
CfgSec:Toggle({Name="Notifications",Flag="notifsToggle",Default=true,Callback=function(v) cfg.notificationsEnabled=v end})  
CfgSec:Dropdown({Name="Style",Flag="TweenStyle",Default="Exponential",Items={"Linear","Sine","Quad","Cubic","Quart","Quint","Exponential","Circular","Back","Elastic","Bounce"},Callback=function(v) Library.Tween.Style=Enum.EasingStyle[v] end})  
CfgSec:Dropdown({Name="Direction",Flag="TweenDir",Default="Out",Items={"In","Out","InOut"},Callback=function(v) Library.Tween.Direction=Enum.EasingDirection[v] end})  
CfgSec:Slider({Name="Tweening Time",Flag="TweenTime",Min=0,Max=5,Default=0.25,Decimals=0.01,Suffix="s",Callback=function(v) Library.Tween.Time=v end})  
CfgSec:Slider({Name="FPS Cap",Flag="fpsCap",Min=15,Max=1000,Default=240,Suffix="",Callback=function(v)  
	if setfpscap then setfpscap(math.floor(v)) elseif settings then pcall(function() settings().Rendering.FrameRateManager=0;settings().Rendering.MaxFrameRate=math.floor(v) end) end  
end})  
CfgSec:Button({Name="Panic Reset",Callback=function()  
	cfg.camlock=false;camlockTarget=nil;cfg.silentAim=false;uninstallSilentAimHooks();cfg.esp=false;toggleESP(false)  
	cfg.flightEnabled=false;stopFlight();cfg.noclip=false;disableNoclip()  
	cfg.rapidFireEnabled=false;isfiring=false  
	cfg.bulletTeleportEnabled=false;btpLine.Visible=false  
	cfg.rangeExpanderEnabled=false  
	cfg.forceHitEnabled=false  
	walkspeedEnabled=false;stopWalkspeed();spinActive=false  
	cfg.fogEnabled=false;setFog(false);cfg.fullbrightEnabled=false  
	if fullbrightConn then fullbrightConn:Disconnect();fullbrightConn=nil end  
	Lighting.Brightness=origL.Brightness;Lighting.ClockTime=origL.ClockTime;Lighting.GlobalShadows=origL.GlobalShadows  
	if fovCircle then fovCircle.Visible=false end  
	if camlockFOVCircle then camlockFOVCircle.Visible=false end  
	Library:Notification("Panic reset done",2,Color3.fromRGB(0,200,130))  
end})  
CfgSec:Button({Name="Unload",Callback=function()  
	cfg.camlock=false; camlockTarget=nil; cam.CameraType=Enum.CameraType.Custom  
	cfg.silentAim=false  
	cfg.esp=false; toggleESP(false)  
	cfg.flightEnabled=false; stopFlight()  
	cfg.noclip=false; disableNoclip()  
	walkspeedEnabled=false; stopWalkspeed(); stopInfiniteJump()  
	cfg.bulletTeleportEnabled=false; pcall(function() btpLine:Remove() end)  
	cfg.rangeExpanderEnabled=false  
	cfg.forceHitEnabled=false  
	if jumpConnection then jumpConnection:Disconnect(); jumpConnection=nil end  
	if fullbrightConn then fullbrightConn:Disconnect(); fullbrightConn=nil end  
	if lightingConn then lightingConn:Disconnect(); lightingConn=nil end  
	if rotatingSkyConn then rotatingSkyConn:Disconnect(); rotatingSkyConn=nil end  
	cfg.fogEnabled=false; setFog(false)  
	Lighting.Brightness=origL.Brightness; Lighting.ClockTime=origL.ClockTime; Lighting.GlobalShadows=origL.GlobalShadows  
	resetMats(); resetTextureColors()  
	if origSky then applySky(nil) end  
	if fovCircle then pcall(function() fovCircle:Remove() end) end  
	if camlockFOVCircle then pcall(function() camlockFOVCircle:Remove() end) end  
	for _,d in pairs(rainDrops) do if d.line then pcall(function() d.line:Remove() end) end end  
	rainDrops={}  
	for m in pairs(activeWeaponHighlights) do removeWeaponGlow(m) end  
	cam.FieldOfView=70  
	pcall(function() RunService:UnbindFromRenderStep("KlaxCamlock") end)  
	uninstallSilentAimHooksHard()  
	if _oldRandom then pcall(function() hookfunction(math.random, _oldRandom) end) end  
	Library:Unload()  
end})  
end)() -- end UI sections function

local _fps = 0  
local _frameCount = 0  
local _lastFPSUpdate = tick()  
  
RunService.RenderStepped:Connect(function()  
	_frameCount = _frameCount + 1  
	local now = tick()  
	local elapsed = now - _lastFPSUpdate  
	if elapsed >= 0.5 then  
		_fps = math.floor(_frameCount / elapsed)  
		_frameCount = 0  
		_lastFPSUpdate = now  
	end  
end)  
  
local function getPing()  
	local ok, val = pcall(function()  
		return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())  
	end)  
	return (ok and type(val)=="number" and val >= 0) and val or 0  
end  
  
task.spawn(function()  
	local wmFrame = nil  
	local wmLabel = nil  
  
	local origSV = Watermark.SetVisibility  
	Watermark.SetVisibility = function(self, bool)  
		origSV(self, bool)  
		if not wmFrame then  
			pcall(function()  
				local function scanForWatermark(parent)  
					for _, child in ipairs(parent:GetChildren()) do  
						if child:IsA("Frame") and child.AutomaticSize == Enum.AutomaticSize.X then  
							local hasImage = false  
							local textLabel = nil  
							for _, sub in ipairs(child:GetChildren()) do  
								if sub:IsA("ImageLabel") then hasImage = true end  
								if sub:IsA("TextLabel") then textLabel = sub end  
							end  
							if hasImage and textLabel then  
								wmFrame = child  
								wmLabel = textLabel  
								return true  
							end  
						end  
						if scanForWatermark(child) then return true end  
					end  
					return false  
				end  
				local hui = (gethui and gethui()) or game:GetService("CoreGui")  
				scanForWatermark(hui)  
			end)  
		end  
	end  
  
	Watermark:SetVisibility(cfg.watermark)  
  
	for _ = 1, 40 do  
		if wmLabel then break end  
		Watermark:SetVisibility(cfg.watermark)  
		task.wait(0.05)  
	end  
  
	while Library and Library.Holder do  
		task.wait(0.25)  
		Watermark:SetVisibility(cfg.watermark)  
		if not cfg.watermark then continue end  
		if not wmLabel or not wmLabel.Parent then  
			Watermark:SetVisibility(true)  
			task.wait(0.05)  
		end  
		local ping = getPing()  
		local text = string.format("klax.cc | %d fps | %dms", _fps, ping)  
		if wmLabel and wmLabel.Parent then  
			wmLabel.Text = text  
		end  
	end  
end)  
  
Library:Notification("klax.cc loaded",3,Color3.fromRGB(0,200,130))

-- smooth scroll for all column ScrollingFrames
task.defer(function()
	task.wait(0.5)
	local SCROLL_SPEED = 32  -- pixels per scroll step
	local SMOOTH      = 0.18 -- lerp factor per frame (lower = smoother)

	local scrollTargets = {} -- [ScrollingFrame] = targetY

	local function hookScroll(sf)
		if scrollTargets[sf] then return end
		scrollTargets[sf] = sf.CanvasPosition.Y

		sf.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local cur = scrollTargets[sf]
				local max = sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y
				scrollTargets[sf] = math.clamp(cur - input.Position.Z * SCROLL_SPEED, 0, math.max(max, 0))
			end
		end)
	end

	-- find all column ScrollingFrames (ScrollBarThickness == 0)
	local function scanForScrollFrames()
		local hui = (gethui and gethui()) or game:GetService("CoreGui")
		for _, obj in ipairs(hui:GetDescendants()) do
			if obj:IsA("ScrollingFrame") and obj.ScrollBarThickness == 0 then
				hookScroll(obj)
			end
		end
	end

	scanForScrollFrames()

	-- also catch any that appear later (dropdowns etc)
	local hui = (gethui and gethui()) or game:GetService("CoreGui")
	hui.DescendantAdded:Connect(function(obj)
		if obj:IsA("ScrollingFrame") and obj.ScrollBarThickness == 0 then
			task.defer(function() hookScroll(obj) end)
		end
	end)

	-- lerp canvas positions every frame
	RunService.RenderStepped:Connect(function()
		for sf, targetY in pairs(scrollTargets) do
			if not sf or not sf.Parent then
				scrollTargets[sf] = nil
				continue
			end
			local cur = sf.CanvasPosition.Y
			local diff = targetY - cur
			if math.abs(diff) < 0.5 then
				sf.CanvasPosition = Vector2.new(0, targetY)
			else
				sf.CanvasPosition = Vector2.new(0, cur + diff * SMOOTH)
			end
		end
	end)
end)  
