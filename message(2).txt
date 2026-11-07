-- Paste this entire file into your executor. No HTTP loader or external assets required.
-- SerotoninUI RIVALS menu. Keep all companion modules beside this LocalScript.
local Library = (function()
-- SerotoninUI | reusable client-side Luau UI library
-- No external dependencies. Return value: Library. See README.md for the API.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local Library = {}
local Window = {}; Window.__index = Window
local Tab = {}; Tab.__index = Tab
local Section = {}; Section.__index = Section
local C = {Bg=Color3.fromRGB(24,24,24), Panel=Color3.fromRGB(30,30,30), Field=Color3.fromRGB(40,40,40),
    Hover=Color3.fromRGB(48,48,48), Line=Color3.fromRGB(53,53,53), Text=Color3.fromRGB(193,193,193),
    Muted=Color3.fromRGB(153,153,153), Accent=Color3.fromRGB(27,185,167)}
local function make(class, props, parent)
    local v=Instance.new(class)
    for k,val in pairs(props or {}) do v[k]=val end
    v.Parent=parent; return v
end
local function frame(parent, props)
    local p={BackgroundColor3=C.Panel, BorderSizePixel=0}
    for k,v in pairs(props or {}) do p[k]=v end
    return make("Frame",p,parent)
end
local function text(parent, value, props, class)
    local p={Text=tostring(value or ""), Font=Enum.Font.Arial, TextSize=11, TextColor3=C.Text,
        BackgroundTransparency=1, BorderSizePixel=0, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,0,0,20), TextTruncate=Enum.TextTruncate.AtEnd}
    if class=="TextButton" then p.AutoButtonColor=false end
    for k,v in pairs(props or {}) do p[k]=v end
    return make(class or "TextLabel",p,parent)
end
local function stroke(parent, color, transparency, thickness)
    return make("UIStroke",{Color=color or C.Line,Transparency=transparency or 0,Thickness=thickness or 1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border},parent)
end
local function gradient(parent, top, bottom)
    return make("UIGradient",{Rotation=90,Color=ColorSequence.new(top,bottom)},parent)
end
local function copy(v)
    if typeof(v)~="table" then return v end
    local out={}; for k,x in pairs(v) do out[k]=copy(x) end; return out
end
local function pointer(i)
    return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch
end
local function keyName(v)
    if v==Enum.KeyCode.Unknown then return "Unbound" end
    return ({MouseButton1="Mouse 1",MouseButton2="Mouse 2",MouseButton3="Mouse 3"})[v.Name] or v.Name
end
local function inputKey(i)
    if i.UserInputType==Enum.UserInputType.Keyboard then return i.KeyCode end
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.MouseButton2
        or i.UserInputType==Enum.UserInputType.MouseButton3 then return i.UserInputType end
end
local function validKey(v)
    return typeof(v)=="EnumItem" and (v.EnumType==Enum.KeyCode or v==Enum.UserInputType.MouseButton1
        or v==Enum.UserInputType.MouseButton2 or v==Enum.UserInputType.MouseButton3)
end
function Window:_releaseBinds()
    for _,bind in ipairs(self._binds or {}) do bind:Release() end
end
function Window:_inputBegan(i,processed)
    local key=inputKey(i)
    if self._binding then
        if key then
            local control=self._binding; self._binding=nil
            control.IgnoreActivationUntil=os.clock()+.2
            if key==Enum.KeyCode.Escape then control:Set(control.Value,true)
            else control:Set(key==Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or key) end
        end
        return
    end
    if processed or UIS:GetFocusedTextBox() or not key or key==Enum.KeyCode.Unknown then return end
    if key==self.ToggleKey then self:SetVisible(not self._visible); return end
    for _,bind in ipairs(self._binds or {}) do if key==bind.Value then bind:Press() end end
end
function Window:_connect(event, fn, bucket)
    local conn=event:Connect(fn); table.insert(bucket or self._connections,conn); return conn
end
function Window:_tween(obj, properties, seconds)
    if self._dead then return end
    if self._tweens[obj] then self._tweens[obj]:Cancel() end
    if self.ReducedMotion then for k,v in pairs(properties) do obj[k]=v end; return end
    local t=TS:Create(obj,TweenInfo.new(seconds or .14,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),properties)
    self._tweens[obj]=t; t:Play(); return t
end
function Window:_accent(obj, property)
    obj[property]=self.Accent; table.insert(self._accents,{obj,property}); return obj
end
function Window:SetAccent(color)
    assert(typeof(color)=="Color3","SetAccent expects a Color3")
    self.Accent=color
    for _,entry in ipairs(self._accents) do if entry[1].Parent then entry[1][entry[2]]=color end end
    for _,control in pairs(self.Controls) do if control._paint then control:_paint() end end
end
function Window:_callback(fn,...)
    if not fn or self._loading or self._dead then return end
    local ok,err=pcall(fn,...); if not ok then warn("[SerotoninUI callback] "..tostring(err)) end
end
function Window:_hover(button, surface)
    surface=surface or button
    local restingColor=surface.BackgroundColor3
    local glow=self:_accent(stroke(surface,self.Accent,1,3),"Color")
    self:_connect(button.MouseEnter,function() self:_tween(glow,{Transparency=.78},.15) end)
    self:_connect(button.MouseLeave,function() self:_tween(glow,{Transparency=1},.2) end)
    self:_connect(button.MouseEnter,function() self:_tween(surface,{BackgroundColor3=C.Hover}) end)
    self:_connect(button.MouseLeave,function() self:_tween(surface,{BackgroundColor3=restingColor}) end)
    self:_connect(button.MouseButton1Down,function() self:_tween(surface,{BackgroundColor3=self.Accent:Lerp(C.Field,.7)},.08) end)
    self:_connect(button.MouseButton1Up,function() self:_tween(surface,{BackgroundColor3=C.Hover},.12) end)
end
function Window:_drag(target, fn, bucket)
    local active=nil
    self:_connect(target.InputBegan,function(i) if pointer(i) then active=i; fn(i.Position) end end,bucket)
    self:_connect(UIS.InputChanged,function(i)
        if active and ((active.UserInputType==Enum.UserInputType.Touch and i==active)
            or (active.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseMovement)) then fn(i.Position) end
    end,bucket)
    self:_connect(UIS.InputEnded,function(i) if i==active then active=nil end end,bucket)
end
function Window:_register(control, o, default)
    local flag=o.Flag or o.Text
    assert(type(flag)=="string" and flag~="","Controls require Text or Flag")
    assert(not self.Controls[flag],"Duplicate flag: "..flag)
    control.Flag=flag; control.Window=self; control.Value=copy(default); control.Default=copy(default)
    control.Callback=o.Callback; self.Controls[flag]=control; self.Flags[flag]=copy(default)
    function control:Get() return copy(self.Value) end
    function control:_commit(value,silent)
        self.Value=copy(value); self.Window.Flags[self.Flag]=copy(value)
        if not silent then self.Window:_callback(self.Callback,copy(value)) end
    end
    return control
end
function Window:ClosePopup()
    for _,conn in ipairs(self._popupConnections) do conn:Disconnect() end
    self._popupConnections={}
    self._popupAnchor=nil
    if self._popup then self._popup:Destroy(); self._popup=nil end
end
function Window:_popupAt(anchor, width, height)
    self:ClosePopup()
    local overlay=text(self.Gui,"",{Size=UDim2.fromScale(1,1),ZIndex=80},"TextButton")
    self._popup=overlay
    local ap,sz=anchor.AbsolutePosition,anchor.AbsoluteSize
    local view=self.Gui.AbsoluteSize
    local x=math.clamp(ap.X,6,math.max(6,view.X-width-6))
    local y=ap.Y+sz.Y+4
    if y+height>view.Y-6 then y=math.max(6,ap.Y-height-4) end
    local panel=text(overlay,"",{BackgroundTransparency=0,BackgroundColor3=C.Panel,Position=UDim2.fromOffset(x,y),
        Size=UDim2.fromOffset(width,height),ZIndex=81},"TextButton")
    stroke(panel,self.Accent,.35)
    self:_connect(overlay.Activated,function() self:ClosePopup() end,self._popupConnections)
    return panel
end
function Window:Notify(message)
    self._noticeToken=self._noticeToken+1; local token=self._noticeToken
    self.Notice.Text=tostring(message); self.Notice.Visible=true
    task.delay(3,function() if not self._dead and token==self._noticeToken then self.Notice.Visible=false end end)
end
function Window:TextDialog(title, value, onApply)
    self:ClosePopup()
    local overlay=text(self.Gui,"",{Size=UDim2.fromScale(1,1),BackgroundTransparency=.35,
        BackgroundColor3=Color3.new(0,0,0),ZIndex=80},"TextButton"); self._popup=overlay
    local box=text(overlay,"",{Size=UDim2.new(.8,0,.6,0),Position=UDim2.fromScale(.1,.2),BackgroundTransparency=0,
        BackgroundColor3=C.Panel,ZIndex=81},"TextButton"); stroke(box,self.Accent,.3)
    text(box,title,{Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-28,0,24),ZIndex=82})
    local input=text(box,value,{Position=UDim2.fromOffset(14,40),Size=UDim2.new(1,-28,1,-92),BackgroundTransparency=0,
        BackgroundColor3=C.Field,ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,
        TextTruncate=Enum.TextTruncate.None,ZIndex=82},"TextBox")
    local apply=text(box,onApply and "Apply" or "Close",{Position=UDim2.new(1,-112,1,-38),Size=UDim2.fromOffset(98,24),
        BackgroundTransparency=0,BackgroundColor3=C.Field,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=82},"TextButton")
    local cancel=text(box,"Cancel",{Position=UDim2.fromOffset(14,0),AnchorPoint=Vector2.new(0,1),Size=UDim2.fromOffset(98,24),
        BackgroundTransparency=0,BackgroundColor3=C.Field,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=82},"TextButton")
    cancel.Position=UDim2.new(0,14,1,-14)
    self:_connect(cancel.Activated,function() self:ClosePopup() end,self._popupConnections)
    self:_connect(apply.Activated,function()
        local str=input.Text; self:ClosePopup(); if onApply then self:_callback(onApply,str) end
    end,self._popupConnections)
    return input
end
function Library.new(options)
    options=options or {}
    local self=setmetatable({_connections={},_popupConnections={},_tweens=setmetatable({},{__mode="k"}),_accents={},
        _noticeToken=0,Tabs={},Controls={},Flags={},Accent=options.Accent or C.Accent,Options=options,
        ToggleKey=options.ToggleKey or Enum.KeyCode.Insert,ReducedMotion=false,_selected=1,_visible=true},Window)
    local parent=options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui=make("ScreenGui",{Name=options.Id or "SerotoninUI",ResetOnSpawn=false,IgnoreGuiInset=true,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=10000},parent)
    self.Width=options.Width or 460; self.Height=options.Height or 400; self.UserScale=1
    self.Root=frame(self.Gui,{Name="Window",Size=UDim2.fromOffset(self.Width,self.Height),
        Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.Bg,Active=true})
    self.Scale=make("UIScale",{Scale=1},self.Root)
    for _,v in ipairs({{1,.58},{3,.95},{7,.98},{13,.992}}) do self:_accent(stroke(self.Root,self.Accent,v[2],v[1]),"Color") end
    local inner=frame(self.Root,{Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-10,1,-10),BackgroundTransparency=1}); stroke(inner,C.Line,.55)
    local titlebar=frame(self.Root,{Name="Titlebar",Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Active=true})
    self:_logo(titlebar,6,3,13)
    text(titlebar,options.Title or "Serotonin",{Position=UDim2.fromOffset(24,0),Size=UDim2.new(1,-86,1,0)})
    local hide=text(titlebar,"−",{Position=UDim2.new(1,-27,0,2),Size=UDim2.fromOffset(21,22),TextXAlignment=Enum.TextXAlignment.Center,
        TextColor3=C.Muted},"TextButton")
    self:_connect(hide.Activated,function() self:SetVisible(false) end)
    self.Nav=frame(self.Root,{Position=UDim2.fromOffset(9,21),Size=UDim2.new(1,-18,0,24),BackgroundTransparency=1})
    self.Indicator=self:_accent(frame(self.Nav,{Size=UDim2.fromOffset(0,1),Position=UDim2.fromOffset(0,0),ZIndex=4}),"BackgroundColor3")
    self.View=frame(self.Root,{Position=UDim2.fromOffset(13,53),Size=UDim2.new(1,-26,1,-66),BackgroundTransparency=1,ClipsDescendants=true})
    self.Track=frame(self.View,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    self.Notice=text(self.Root,"",{Position=UDim2.new(0,16,1,-36),Size=UDim2.new(1,-32,0,23),BackgroundTransparency=0,
        BackgroundColor3=C.Field,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=50,Visible=false}); stroke(self.Notice,self.Accent,.5)
    self.Reopen=text(self.Gui,options.Title or "Serotonin",{Position=UDim2.fromOffset(12,60),Size=UDim2.fromOffset(110,26),
        BackgroundTransparency=0,BackgroundColor3=C.Bg,TextXAlignment=Enum.TextXAlignment.Center,Visible=false},"TextButton")
    self:_accent(stroke(self.Reopen,self.Accent,.4),"Color")
    self:_connect(self.Reopen.Activated,function() self:SetVisible(true) end)
    local dragStart,origin
    self:_drag(titlebar,function(pos)
        if not dragStart then dragStart=pos; origin=self.Root.Position end
        local delta=pos-dragStart
        local viewport=self.Gui.AbsoluteSize
        local absolute=Vector2.new(origin.X.Scale*viewport.X+origin.X.Offset+delta.X,origin.Y.Scale*viewport.Y+origin.Y.Offset+delta.Y)
        local half=self.Root.AbsoluteSize/2
        local minX,maxX=math.min(half.X,viewport.X/2),math.max(half.X,viewport.X-half.X)
        local minY,maxY=math.min(half.Y,viewport.Y/2),math.max(half.Y,viewport.Y-half.Y)
        self.Root.Position=UDim2.fromOffset(math.clamp(absolute.X,minX,maxX),math.clamp(absolute.Y,minY,maxY))
    end)
    self:_connect(UIS.InputEnded,function(i) if pointer(i) then dragStart=nil end end)
    self:_connect(UIS.InputBegan,function(i,processed) self:_inputBegan(i,processed) end)
    self:_connect(UIS.InputEnded,function(i)
        local key=inputKey(i)
        for _,bind in ipairs(self._binds or {}) do if bind.Value==key then bind:Release() end end
    end)
    self:_connect(UIS.WindowFocusReleased,function() self:_releaseBinds() end)
    self:_connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"),function() self:_fit() end)
    self:_connect(self.Root:GetPropertyChangedSignal("AbsolutePosition"),function() self:ClosePopup() end)
    self:_fit(); return self
end
function Window:_logo(parent,x,y,size)
    if self.Options.Logo then
        return make("ImageLabel",{Image=self.Options.Logo,BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),
            Size=UDim2.fromOffset(size,size),ScaleType=Enum.ScaleType.Fit},parent)
    end
    local box=frame(parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),BackgroundTransparency=1})
    if Library.LogoRuns then
        for _,r in ipairs(Library.LogoRuns) do
            frame(box,{Position=UDim2.fromScale(r[1]/Library.LogoWidth,r[2]/Library.LogoHeight),
                Size=UDim2.fromScale(r[3]/Library.LogoWidth,1/Library.LogoHeight),BackgroundColor3=Library.LogoPalette[r[4]]})
        end
    else
        text(box,"◖◗",{Size=UDim2.fromScale(1,1),TextColor3=self.Accent,TextSize=size,TextXAlignment=Enum.TextXAlignment.Center})
    end
    return box
end
function Window:_fit()
    local view=self.Gui.AbsoluteSize
    local total=self.Width+((self.Preview and self.Preview.Visible) and 220 or 0)
    self.Scale.Scale=math.min(self.UserScale,math.max(.1,(view.X-36)/total),math.max(.1,(view.Y-36)/self.Height))
    local full=total*self.Scale.Scale
    local maxX=math.max(self.Width*self.Scale.Scale/2,view.X-(total-self.Width/2)*self.Scale.Scale-12)
    local current=self.Root.AbsolutePosition.X+self.Root.AbsoluteSize.X/2
    if full>view.X-24 or current>maxX then self.Root.Position=UDim2.new(0,maxX,self.Root.Position.Y.Scale,self.Root.Position.Y.Offset) end
end
function Window:SetScale(scale) self.UserScale=math.clamp(tonumber(scale) or 1,.5,1.5); self:ClosePopup(); self:_fit() end
function Window:SetVisible(visible)
    self._visible=visible==true; self:ClosePopup(); self.Root.Visible=self._visible; self.Reopen.Visible=not self._visible
end
function Window:AddTab(name)
    local index=#self.Tabs+1
    local page=frame(self.Track,{Name=name,Position=UDim2.fromScale(index-1,0),Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    local button=text(self.Nav,name,{BackgroundTransparency=0,BackgroundColor3=C.Bg,TextXAlignment=Enum.TextXAlignment.Center},"TextButton")
    stroke(button,C.Line,.5)
    local tab=setmetatable({Window=self,Name=name,Index=index,Page=page,Button=button,Columns={}},Tab)
    for col=1,2 do
        local pane=make("ScrollingFrame",{Name="Column"..col,BackgroundColor3=C.Panel,BorderSizePixel=0,
            Position=UDim2.new((col-1)*.5,col==2 and 5 or 0,0,0),Size=UDim2.new(.5,-5,1,0),
            CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=1,ScrollBarImageTransparency=.8,
            ScrollBarImageColor3=C.Muted,ScrollingDirection=Enum.ScrollingDirection.Y,Active=true},page)
        stroke(pane,C.Line,.1); -- Keep the scrollbar subdued like the reference.
        make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},pane)
        make("UIPadding",{PaddingBottom=UDim.new(0,8)},pane)
        tab.Columns[col]=pane
    end
    table.insert(self.Tabs,tab)
    for i,t in ipairs(self.Tabs) do
        t.Button.Position=UDim2.fromScale((i-1)/#self.Tabs,0); t.Button.Size=UDim2.new(1/#self.Tabs,0,1,0)
    end
    self:_connect(button.Activated,function() self:SelectTab(index) end)
    self:_connect(button.MouseEnter,function() if self._selected~=index then self:_tween(button,{BackgroundColor3=C.Field}) end end)
    self:_connect(button.MouseLeave,function() if self._selected~=index then self:_tween(button,{BackgroundColor3=C.Bg}) end end)
    self:SelectTab(self._selected,true); return tab
end
function Window:SelectTab(index,instant)
    if type(index)=="string" then for i,t in ipairs(self.Tabs) do if t.Name==index then index=i; break end end end
    assert(type(index)=="number" and self.Tabs[index],"Unknown tab")
    self:ClosePopup(); local last=self._selected; self._selected=index
    local goal={Position=UDim2.fromScale(-(index-1),0)}
    if instant then if self._tweens[self.Track] then self._tweens[self.Track]:Cancel() end; self.Track.Position=goal.Position
    else self:_tween(self.Track,goal,.20+math.min(math.abs(last-index),6)*.035) end
    self:_tween(self.Indicator,{Position=UDim2.fromScale((index-1)/#self.Tabs,0),Size=UDim2.new(1/#self.Tabs,0,0,1)},instant and 0 or .2)
    for i,t in ipairs(self.Tabs) do
        self:_tween(t.Button,{BackgroundColor3=i==index and Color3.fromRGB(26,26,26) or C.Bg,
            TextColor3=i==index and C.Text or C.Muted},instant and 0 or .14)
    end
    if self.Preview then self.Preview.Visible=self._previewEnabled and self.Tabs[index].Name=="Visuals"; self:_fit() end
end
function Tab:AddSection(title,column)
    local parent=self.Columns[column or 1]; assert(parent,"Column must be 1 or 2")
    local pane=frame(parent,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,
        LayoutOrder=#parent:GetChildren()})
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},pane)
    local head=frame(pane,{Size=UDim2.new(1,0,0,18),LayoutOrder=0,BackgroundColor3=Color3.new(1,1,1)})
    gradient(head,Color3.fromRGB(45,45,45),Color3.fromRGB(31,31,31))
    self.Window:_accent(frame(head,{Position=UDim2.fromOffset(1,3),Size=UDim2.new(0,1,1,-6)}),"BackgroundColor3")
    text(head,title,{Position=UDim2.fromOffset(7,0),Size=UDim2.new(1,-18,1,0)})
    local body=frame(pane,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1})
    make("UIPadding",{PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7),PaddingBottom=UDim.new(0,3)},body)
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},body)
    return setmetatable({Window=self.Window,Body=body,_order=0},Section)
end
function Section:_row(height)
    self._order=self._order+1
    return frame(self.Body,{Size=UDim2.new(1,0,0,height),BackgroundTransparency=1,LayoutOrder=self._order})
end
function Section:Label(value)
    local row=self:_row(19); return text(row,value,{TextColor3=C.Muted})
end
function Section:Button(o)
    if type(o)=="string" then o={Text=o} end
    local w=self.Window; local row=self:_row(17)
    -- Keep the gradient on a separate surface: gradients on TextButtons also tint their text.
    -- Neutral stops shade the existing gray instead of multiplying two dark colors together.
    local surface=frame(row,{Name="ButtonSurface",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(42,42,42)})
    gradient(surface,Color3.new(1,1,1),Color3.fromRGB(210,210,210))
    stroke(surface,C.Line,.95)
    local button=text(row,o.Text,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,TextColor3=C.Text,
        TextTransparency=0,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=2},"TextButton")
    w:_hover(button,surface); w:_connect(button.Activated,function() w:_callback(o.Callback) end)
    return button
end
function Section:Toggle(o)
    local w=self.Window; local row=self:_row(15)
    local hit=text(row,"",{Size=UDim2.fromScale(1,1)},"TextButton")
    local square=frame(hit,{Position=UDim2.fromOffset(0,3),Size=UDim2.fromOffset(10,10),BackgroundColor3=C.Field})
    local border=stroke(square,C.Line,.25)
    gradient(square,Color3.new(1,1,1),Color3.fromRGB(220,220,220))
    local fill=w:_accent(frame(square,{Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),BackgroundTransparency=1}),"BackgroundColor3")
    local label=text(hit,o.Text,{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-16,1,0)})
    local c=w:_register({Instance=row},o,o.Default==true)
    function c:Set(value,silent)
        assert(type(value)=="boolean","Toggle expects boolean"); self:_commit(value,silent)
        w:_tween(fill,{BackgroundTransparency=value and 0 or 1},.12)
        w:_tween(label,{TextColor3=value and C.Text or C.Muted},.12)
    end
    w:_connect(hit.Activated,function() c:Set(not c.Value) end)
    w:_connect(hit.MouseEnter,function() w:_tween(border,{Color=w.Accent},.12) end)
    w:_connect(hit.MouseLeave,function() w:_tween(border,{Color=C.Line},.12) end)
    c:Set(c.Value,true)
    if o.Color then
        hit.Size=UDim2.new(1,-28,1,0)
        self:_colorButton(row,{Text=o.Text.." color",Flag=(o.Flag or o.Text)..".color",Default=o.Color,Callback=o.ColorCallback})
    end
    if o.Keybind~=nil then
        hit.Size=UDim2.new(1,-64,1,0)
        self:_keyButton(row,{Text=o.Text.." key",Flag=(o.Flag or o.Text)..".key",Default=o.Keybind,Target=c,
            OnPress=function() c:Set(not c.Value) end},true)
    end
    return c
end
function Section:Slider(o)
    local w=self.Window; local row=self:_row(30)
    local min,max,step=o.Min or 0,o.Max or 100,o.Step or 1
    assert(max>min and step>0,"Slider requires Max > Min and Step > 0")
    text(row,o.Text,{TextColor3=C.Muted,Size=UDim2.new(1,-85,0,19)})
    local value=text(row,"",{Position=UDim2.new(1,-85,0,0),Size=UDim2.fromOffset(85,19),TextXAlignment=Enum.TextXAlignment.Right,
        ClearTextOnFocus=false,TextColor3=C.Muted},"TextBox")
    local track=text(row,"",{Position=UDim2.fromOffset(0,19),Size=UDim2.new(1,0,0,9),BackgroundTransparency=0,BackgroundColor3=C.Field},"TextButton")
    local border=stroke(track,C.Line,.15)
    gradient(track,Color3.new(1,1,1),Color3.fromRGB(240,240,240))
    local fill=w:_accent(frame(track,{Position=UDim2.fromOffset(1,1),Size=UDim2.new(0,0,1,-2)}),"BackgroundColor3")
    gradient(fill,Color3.new(1,1,1),Color3.fromRGB(235,250,247))
    local c=w:_register({Instance=row},o,o.Default or min)
    local digits=o.Decimals or (step<1 and math.ceil(-math.log10(step)) or 0)
    function c:Set(v,silent)
        assert(type(v)=="number" and v==v and math.abs(v)<math.huge,"Slider expects a finite number")
        v=math.clamp(min+math.floor((v-min)/step+.5)*step,min,max)
        self:_commit(v,silent); value.Text=string.format("%."..digits.."f",v)..(o.Suffix or "")
        local ratio=(v-min)/(max-min)
        w:_tween(fill,{Size=UDim2.new(ratio,-2*ratio,1,-2)},.1)
    end
    w:_drag(track,function(pos) if track.AbsoluteSize.X>0 then c:Set(min+math.clamp((pos.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(max-min)) end end)
    w:_connect(track.MouseEnter,function() w:_tween(border,{Color=w.Accent},.15) end)
    w:_connect(track.MouseLeave,function() w:_tween(border,{Color=C.Line},.15) end)
    w:_connect(value.FocusLost,function() local n=tonumber(value.Text); c:Set(n or c.Value,n==nil) end)
    c:Set(c.Value,true); return c
end
function Section:Dropdown(o)
    local w=self.Window; local row=self:_row(30); local items=copy(o.Options or {})
    text(row,o.Text,{TextColor3=C.Muted,Size=UDim2.new(1,0,0,19)})
    local button=text(row,"",{Position=UDim2.fromOffset(0,17),Size=UDim2.new(1,0,0,13),BackgroundTransparency=0,BackgroundColor3=C.Field},"TextButton")
    stroke(button,C.Line,.3); gradient(button,Color3.new(1,1,1),Color3.fromRGB(245,245,245)); w:_hover(button)
    local label=text(button,"",{Position=UDim2.fromOffset(5,0),Size=UDim2.new(1,-27,1,0)})
    text(button,"",{Position=UDim2.new(1,-17,0,0),Size=UDim2.fromOffset(13,13),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=C.Muted})
    local default=o.Default
    if default==nil then default=o.Multi and {} or (items[1] or "None") end
    local c=w:_register({Instance=row,Options=items},o,default)
    function c:Set(v,silent)
        if o.Multi then
            assert(type(v)=="table","Multi dropdown expects an array")
            local selected,seen={},{}
            for _,x in ipairs(v) do assert(table.find(self.Options,x),"Unknown dropdown option: "..tostring(x)); if not seen[x] then table.insert(selected,x); seen[x]=true end end
            v=selected; label.Text=#v>0 and table.concat(v,", ") or "None"
        else assert(type(v)=="string" and (table.find(self.Options,v) or (#self.Options==0 and v=="None")),"Unknown dropdown option: "..tostring(v)); label.Text=v end
        self:_commit(v,silent)
    end
    function c:SetOptions(options)
        self.Options=copy(options); w:ClosePopup()
        if o.Multi then local keep={}; for _,v in ipairs(self.Value) do if table.find(options,v) then table.insert(keep,v) end end; self:Set(keep)
        elseif not table.find(options,self.Value) then self:Set(options[1] or "None") end
    end
    w:_connect(button.Activated,function()
        if w._popupAnchor==button and w._popup then w:ClosePopup(); w._popupAnchor=nil; return end
        local panel=w:_popupAt(button,math.max(140,button.AbsoluteSize.X),math.min(math.max(#c.Options,1)*25+6,206)); w._popupAnchor=button
        local list=make("ScrollingFrame",{Size=UDim2.new(1,-6,1,-6),Position=UDim2.fromOffset(3,3),BackgroundTransparency=1,BorderSizePixel=0,
            CanvasSize=UDim2.fromOffset(0,#c.Options*25),ScrollBarThickness=2,ScrollBarImageColor3=w.Accent,ZIndex=82},panel)
        local rendered={}
        local function repaint()
            for item,b in pairs(rendered) do
                local active=o.Multi and table.find(c.Value,item)~=nil or (not o.Multi and c.Value==item)
                b.TextColor3=active and w.Accent or C.Text; b.BackgroundTransparency=active and 0 or 1
            end
        end
        for i,item in ipairs(c.Options) do
            local choice=text(list,"  "..item,{Position=UDim2.fromOffset(0,(i-1)*25),Size=UDim2.new(1,-2,0,24),
                BackgroundColor3=C.Field,ZIndex=83},"TextButton"); rendered[item]=choice
            w:_connect(choice.Activated,function()
                if o.Multi then local v=c:Get(); local at=table.find(v,item); if at then table.remove(v,at) else table.insert(v,item) end; c:Set(v); repaint()
                else c:Set(item); w:ClosePopup() end
            end,w._popupConnections)
        end
        repaint()
    end)
    c:Set(c.Value,true); return c
end
function Section:_keyButton(row,o,inline)
    local w=self.Window
    local surface=frame(row,{Position=UDim2.new(1,-60,0,0),Size=UDim2.fromOffset(60,14),BackgroundColor3=C.Field})
    gradient(surface,Color3.new(1,1,1),Color3.fromRGB(220,220,220)); stroke(surface,C.Line,.35)
    local button=text(row,"Unbound",{Position=UDim2.new(1,-60,0,0),Size=UDim2.fromOffset(60,14),BackgroundTransparency=1,ZIndex=2,
        BackgroundColor3=C.Field,TextColor3=C.Muted,TextXAlignment=Enum.TextXAlignment.Center},"TextButton")
    local c=w:_register({Instance=row,Button=button,OnPress=o.OnPress,Target=o.Target,Mode="Toggle",Held=false},o,o.Default or Enum.KeyCode.Unknown)
    function c:Release(silent)
        local held=self.Held; self.Held=false
        if held and self.Mode=="Hold" and self.Target and not w._loading then self.Target:Set(false,silent) end
    end
    function c:Press()
        if self.Held or self.Mode=="Always" then return end
        self.Held=true
        if self.Mode=="Hold" and self.Target then self.Target:Set(true)
        else w:_callback(self.OnPress) end
    end
    function c:SetMode(mode,silent)
        assert(mode=="Hold" or mode=="Toggle" or mode=="Always","Invalid keybind mode")
        self:Release(silent); self.Mode=mode
        if self.Target and not silent then
            if mode=="Always" then self.Target:Set(true)
            elseif mode=="Hold" then self.Target:Set(false) end
        end
    end
    function c:Set(v,silent)
        assert(validKey(v),"Keybind expects a keyboard key or MouseButton1/2/3")
        self:Release(silent)
        if w._binding==self then w._binding=nil end
        self:_commit(v,silent); button.Text=keyName(v); button.TextColor3=C.Muted
    end
    w._binds=w._binds or {}; table.insert(w._binds,c); w:_hover(button,surface)
    w:_connect(button.Activated,function()
        if os.clock()<(c.IgnoreActivationUntil or 0) then return end
        w:ClosePopup(); w:_releaseBinds()
        if w._binding then w._binding:Set(w._binding.Value,true) end
        w._binding=c; button.Text="Key / mouse…"; button.TextColor3=w.Accent
    end)
    if o.Target then w:_connect(button.MouseButton2Click,function()
        if w._binding or os.clock()<(c.IgnoreActivationUntil or 0) then return end
        local panel=w:_popupAt(button,104,78)
        for index,mode in ipairs({"Hold","Toggle","Always"}) do
            local choice=text(panel,"  "..mode,{Position=UDim2.fromOffset(3,3+(index-1)*24),
                Size=UDim2.new(1,-6,0,24),ZIndex=83,TextColor3=c.Mode==mode and w.Accent or C.Text},"TextButton")
            w:_connect(choice.Activated,function() c:SetMode(mode); w:ClosePopup() end,w._popupConnections)
        end
    end) end
    c:Set(c.Value,true); return c
end
function Section:Keybind(o)
    local row=self:_row(22); text(row,o.Text,{Size=UDim2.new(1,-64,1,0),TextColor3=C.Muted})
    return self:_keyButton(row,o)
end
function Section:Textbox(o)
    local w=self.Window; local row=self:_row(o.Inline and 18 or (o.Multiline and 110 or 32))
    text(row,o.Text,{TextColor3=o.Inline and C.Text or C.Muted,
        Position=o.Inline and UDim2.new(1,-58,0,0) or UDim2.new(),
        Size=o.Inline and UDim2.fromOffset(58,18) or UDim2.new(1,0,0,17)})
    local box=text(row,"",{Position=o.Inline and UDim2.new() or UDim2.fromOffset(0,17),
        Size=o.Inline and UDim2.new(1,-61,1,0) or UDim2.new(1,0,1,-17),BackgroundTransparency=0,BackgroundColor3=C.Field,
        ClearTextOnFocus=false,PlaceholderText=o.Placeholder or "",PlaceholderColor3=C.Muted,MultiLine=o.Multiline==true,
        TextWrapped=o.Multiline==true,TextTruncate=Enum.TextTruncate.None},"TextBox"); stroke(box,C.Line,.1)
    local c=w:_register({Instance=row},o,o.Default or "")
    function c:Set(v,silent) assert(type(v)=="string","Textbox expects string"); self:_commit(v:sub(1,o.MaxLength or 20000),silent); box.Text=self.Value end
    w:_connect(box.FocusLost,function() c:Set(box.Text) end)
    c:Set(c.Value,true); return c
end
function Section:_colorButton(row,o)
    local w=self.Window
    local swatch=text(row,"",{Position=UDim2.new(1,-15,0,3),Size=UDim2.fromOffset(10,10),BackgroundTransparency=0},"TextButton"); stroke(swatch,C.Line)
    local c=w:_register({Instance=row},o,o.Default or Color3.new(1,1,1))
    function c:Set(v,silent) assert(typeof(v)=="Color3","Color picker expects Color3"); self:_commit(v,silent); w:_tween(swatch,{BackgroundColor3=v},.12) end
    w:_connect(swatch.Activated,function()
        local panel=w:_popupAt(swatch,226,224)
        local h,s,v=c.Value:ToHSV()
        local area=text(panel,"",{Position=UDim2.fromOffset(10,10),Size=UDim2.fromOffset(180,150),BackgroundTransparency=0,
            BackgroundColor3=Color3.fromHSV(h,1,1),ZIndex=82},"TextButton")
        local white=frame(area,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),ZIndex=83})
        make("UIGradient",{Transparency=NumberSequence.new(0,1)},white)
        local black=frame(area,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),ZIndex=84})
        make("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0)},black)
        local cursor=frame(area,{Size=UDim2.fromOffset(5,5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,ZIndex=85}); stroke(cursor,Color3.new(1,1,1))
        local hue=text(panel,"",{Position=UDim2.fromOffset(200,10),Size=UDim2.fromOffset(16,150),BackgroundTransparency=0,
            BackgroundColor3=Color3.new(1,1,1),ZIndex=82},"TextButton")
        local points={}; for i=0,6 do table.insert(points,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))) end
        make("UIGradient",{Rotation=90,Color=ColorSequence.new(points)},hue)
        local hueCursor=frame(hue,{Size=UDim2.new(1,4,0,2),Position=UDim2.fromOffset(-2,0),ZIndex=85,BackgroundColor3=Color3.new(1,1,1)})
        local hex=text(panel,"#"..c.Value:ToHex(),{Position=UDim2.fromOffset(10,172),Size=UDim2.fromOffset(206,21),BackgroundTransparency=0,
            BackgroundColor3=C.Field,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=82},"TextBox")
        text(panel,"Drag to pick · click outside to close",{Position=UDim2.fromOffset(10,196),Size=UDim2.fromOffset(206,19),TextSize=12,TextColor3=C.Muted,ZIndex=82})
        local function paint()
            area.BackgroundColor3=Color3.fromHSV(h,1,1); cursor.Position=UDim2.fromScale(s,1-v); hueCursor.Position=UDim2.new(0,-2,h,0)
            c:Set(Color3.fromHSV(h,s,v)); hex.Text="#"..c.Value:ToHex()
        end
        cursor.Position=UDim2.fromScale(s,1-v); hueCursor.Position=UDim2.new(0,-2,h,0)
        w:_drag(area,function(pos) s=math.clamp((pos.X-area.AbsolutePosition.X)/area.AbsoluteSize.X,0,1); v=1-math.clamp((pos.Y-area.AbsolutePosition.Y)/area.AbsoluteSize.Y,0,1); paint() end,w._popupConnections)
        w:_drag(hue,function(pos) h=math.clamp((pos.Y-hue.AbsolutePosition.Y)/hue.AbsoluteSize.Y,0,1); paint() end,w._popupConnections)
        w:_connect(hex.FocusLost,function()
            local str=hex.Text:gsub("#","")
            if #str==6 and str:match("^%x+$") then h,s,v=Color3.fromHex(str):ToHSV(); paint() else hex.Text="#"..c.Value:ToHex() end
        end,w._popupConnections)
    end)
    c:Set(c.Value,true); return c
end
function Section:Colorpicker(o)
    local row=self:_row(21); text(row,o.Text,{Size=UDim2.new(1,-24,1,0),TextColor3=C.Muted}); return self:_colorButton(row,o)
end
function Section:List(o)
    local w=self.Window; local row=self:_row(o.Height or 145)
    text(row,o.Text,{Size=UDim2.new(1,0,0,19),TextColor3=C.Text})
    local list=make("ScrollingFrame",{Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,0,1,-23),BackgroundColor3=C.Field,
        BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=w.Accent},row); stroke(list,C.Line)
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},list)
    local c=w:_register({Instance=row,Options=copy(o.Options or {}),_rowConnections={}},o,o.Default or "")
    function c:_paint()
        for _,b in ipairs(list:GetChildren()) do if b:IsA("TextButton") then
            b.BackgroundColor3=w.Accent:Lerp(C.Field,.87); b.BackgroundTransparency=b.Name==self.Value and 0 or 1
        end end
    end
    function c:Set(v,silent)
        assert(type(v)=="string" and (v=="" or table.find(self.Options,v)),"Unknown list item")
        self:_commit(v,silent); self:_paint()
    end
    function c:SetOptions(options)
        for _,conn in ipairs(self._rowConnections) do conn:Disconnect() end; self._rowConnections={}
        for _,b in ipairs(list:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
        self.Options=copy(options)
        for i,item in ipairs(self.Options) do
            local b=text(list," "..item,{Name=item,Size=UDim2.new(1,-3,0,21),LayoutOrder=i},"TextButton")
            w:_connect(b.Activated,function() self:Set(item) end,self._rowConnections)
        end
        if self.Value~="" and not table.find(options,self.Value) then self:Set("",true) end; self:_paint()
    end
    c:SetOptions(c.Options); c:Set(c.Value,true); return c
end
function Window:AddPreview()
    if self.Preview then return self.Preview end
    self._previewEnabled=true
    local panel=frame(self.Root,{Name="ESP Preview",Position=UDim2.new(1,10,0,0),Size=UDim2.new(0,210,1,0),BackgroundColor3=C.Bg,Visible=false})
    self:_accent(stroke(panel,self.Accent,.6),"Color"); self:_logo(panel,6,3,13)
    text(panel,"ESP Preview",{Position=UDim2.fromOffset(24,0),Size=UDim2.new(1,-30,0,20)})
    local field=frame(panel,{Position=UDim2.fromOffset(7,22),Size=UDim2.new(1,-14,1,-30),BackgroundColor3=C.Panel}); stroke(field,C.Line)
    local target=frame(field,{Name="Target",Position=UDim2.fromScale(.5,.55),AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(83,124),BackgroundTransparency=1})
    local outline=stroke(target,self.Accent,.2)
    local viewport=make("ViewportFrame",{Name="YourCharacter",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
        Ambient=Color3.fromRGB(180,180,180),LightColor=Color3.fromRGB(255,250,240),LightDirection=Vector3.new(-1,-1,-2),ZIndex=2},target)
    local camera=make("Camera",{FieldOfView=30},viewport); viewport.CurrentCamera=camera
    local world=make("WorldModel",{Name="PreviewWorld"},viewport)
    local tint=frame(target,{Size=UDim2.fromScale(1,1),BackgroundTransparency=.82,BackgroundColor3=self.Accent,ZIndex=4})
    local health=frame(target,{Position=UDim2.fromOffset(-4,0),Size=UDim2.new(0,2,1,0),BackgroundColor3=Color3.fromRGB(74,228,84),ZIndex=5})
    local name=text(target,Players.LocalPlayer.DisplayName,{Position=UDim2.new(0,-15,0,-15),Size=UDim2.new(1,30,0,14),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5})
    local distance=text(target,"",{Position=UDim2.new(0,-15,1,2),Size=UDim2.new(1,30,0,14),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=C.Muted,ZIndex=5})
    local tracer=frame(field,{Size=UDim2.new(0,1,.55,-62),Position=UDim2.fromScale(.5,0),BackgroundColor3=self.Accent})
    local status=text(field,"Loading your character…",{Position=UDim2.fromScale(0,.8),Size=UDim2.new(1,0,0,18),TextColor3=C.Muted,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6})
    self.Preview=panel
    self.PreviewParts={Target=target,Outline=outline,Tint=tint,Health=health,Name=name,Distance=distance,Tracer=tracer,Viewport=viewport,Camera=camera}
    self._characterConnections={}
    local player=Players.LocalPlayer
    local character,clone,partPairs,humanoid,root=nil,nil,{},nil,nil
    local revision=0
    local function destroyClone()
        if clone then clone:Destroy(); clone=nil end
        partPairs={}
    end
    local function updatePose()
        if not root or not root.Parent then return end
        local origin=root.CFrame
        for _,pair in ipairs(partPairs) do
            local src,dst=pair[1],pair[2]
            if src.Parent and dst.Parent then
                dst.CFrame=origin:ToObjectSpace(src.CFrame)
                dst.Color=src.Color; dst.Material=src.Material; dst.Transparency=src.Transparency
                dst.LocalTransparencyModifier=0
            end
        end
    end
    local function fitCamera()
        if not clone or #partPairs==0 then return end
        local box,size=clone:GetBoundingBox()
        local aspect=math.max(viewport.AbsoluteSize.X,1)/math.max(viewport.AbsoluteSize.Y,1)
        local half=math.max(size.Y*.5,size.X*.5/aspect)
        local padding=tonumber(self.Flags["visual.padding"]) or .5
        local dist=(half+padding*.15)/math.tan(math.rad(camera.FieldOfView*.5))+size.Z*.5
        -- Roblox characters face -Z; this camera faces the front of the normalized clone.
        camera.CFrame=CFrame.lookAt(box.Position+Vector3.new(0,0,-dist),box.Position)
        camera.Focus=CFrame.new(box.Position)
    end
    local function pairParts(src,dst)
        if src:IsA("BasePart") then table.insert(partPairs,{src,dst}) end
        local buckets={}
        for _,child in ipairs(dst:GetChildren()) do
            local key=child.ClassName.."\0"..child.Name
            buckets[key]=buckets[key] or {}; table.insert(buckets[key],child)
        end
        for _,child in ipairs(src:GetChildren()) do
            local bucket=buckets[child.ClassName.."\0"..child.Name]
            if bucket and #bucket>0 then pairParts(child,table.remove(bucket,1)) end
        end
    end
    local function rebuild()
        if self._dead or not character or character~=player.Character then return end
        root=character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        humanoid=character:FindFirstChildOfClass("Humanoid")
        if not root then status.Text="Waiting for your character…"; status.Visible=true; return end
        local original={}
        local objects=character:GetDescendants(); table.insert(objects,character)
        -- Restore every original Archivable flag immediately, including when cloning fails.
        local ok,result=pcall(function()
            for _,obj in ipairs(objects) do original[obj]=obj.Archivable; obj.Archivable=true end
            return character:Clone()
        end)
        for obj,value in pairs(original) do pcall(function() obj.Archivable=value end) end
        if not ok or not result then status.Text="Character preview unavailable"; status.Visible=true; return end
        destroyClone(); clone=result; pairParts(character,clone)
        -- No character scripts or physics run inside the preview.
        for _,obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("JointInstance") or obj:IsA("Constraint")
                or obj:IsA("Sound") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then obj:Destroy()
            elseif obj:IsA("BasePart") then obj.Anchored=true; obj.CanCollide=false; obj.CanTouch=false; obj.CanQuery=false; obj.LocalTransparencyModifier=0
            elseif obj:IsA("Humanoid") then obj.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
        end
        clone.Parent=world
        updatePose(); fitCamera(); status.Visible=false
    end
    local function schedule()
        revision=revision+1; local token=revision
        task.delay(.15,function() if not self._dead and token==revision then rebuild() end end)
    end
    local function attach(newCharacter)
        revision=revision+1
        for _,conn in ipairs(self._characterConnections) do conn:Disconnect() end
        self._characterConnections={}; destroyClone(); character=newCharacter; root=nil; humanoid=nil
        status.Text="Loading your character…"; status.Visible=true
        if not character then return end
        self:_connect(character.DescendantAdded,schedule,self._characterConnections)
        self:_connect(character.DescendantRemoving,schedule,self._characterConnections)
        for _,obj in ipairs(character:GetDescendants()) do
            if obj:IsA("Clothing") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") or obj:IsA("SurfaceAppearance") or obj:IsA("Decal") then
                self:_connect(obj.Changed,schedule,self._characterConnections)
            end
        end
        schedule()
    end
    self:_connect(player.CharacterAdded,attach)
    self:_connect(player.CharacterRemoving,function(old) if old==character then attach(nil) end end)
    self:_connect(player.CharacterAppearanceLoaded,function(loaded) if loaded==character then attach(loaded) end end)
    self:_connect(viewport:GetPropertyChangedSignal("AbsoluteSize"),fitCamera)
    local elapsed=0
    self:_connect(game:GetService("RunService").RenderStepped,function(dt)
        elapsed=elapsed+dt
        if elapsed<1/30 or not self._visible or not panel.Visible or not clone then return end
        elapsed=0; updatePose()
        if humanoid then
            local fraction=math.clamp(humanoid.Health/math.max(humanoid.MaxHealth,1),0,1)
            health.Size=UDim2.new(0,2,fraction,0); health.Position=UDim2.new(0,-4,1-fraction,0)
        end
        if root and workspace.CurrentCamera then distance.Text=string.format("%.0f studs",(workspace.CurrentCamera.CFrame.Position-root.Position).Magnitude) end
        local from=self.Flags["visual.tracerOrigin"] or "Top"
        if from=="Bottom" then tracer.Position=UDim2.new(.5,0,.55,62); tracer.Size=UDim2.new(0,1,.45,-62)
        elseif from=="Center" then tracer.Position=UDim2.new(.5,0,.55,-62); tracer.Size=UDim2.new(0,1,0,62)
        else tracer.Position=UDim2.fromScale(.5,0); tracer.Size=UDim2.new(0,1,.55,-62) end
    end)
    self.RefreshPreview=schedule
    self.FitPreviewCamera=fitCamera
    attach(player.Character)
    return panel
end

function Window:SetPreviewEnabled(value)
    self._previewEnabled=value==true
    if self.Preview then self.Preview.Visible=self._previewEnabled and self.Tabs[self._selected].Name=="Visuals"; self:_fit() end
end

function Window:BindVisibility(flag, controls)
    local source=assert(self.Controls[flag],"Unknown visibility flag")
    local previous=source.Callback
    local function update(value)
        for _,control in ipairs(controls) do
            local row=control.Instance
            if row then
                local full=row:GetAttribute("ExpandedHeight") or row.Size.Y.Offset
                row:SetAttribute("ExpandedHeight",full)
                row.ClipsDescendants=true
                if value then row.Visible=true end
                self:_tween(row,{Size=UDim2.new(1,0,0,value and full or 0)},.18)
                if not value then task.delay(self.ReducedMotion and 0 or .18,function()
                    if not self._dead and not source.Value then row.Visible=false end
                end) end
            end
        end
    end
    source.Callback=function(value) self:_callback(previous,value); update(value) end
    update(source.Value)
end

function Window:ExportConfig()
    local values,modes={},{}
    for flag,control in pairs(self.Controls) do if not control.Transient then
        local value=control:Get()
        if typeof(value)=="Color3" then value={_type="Color3",hex=value:ToHex()}
        elseif typeof(value)=="EnumItem" then value={_type=value.EnumType==Enum.UserInputType and "UserInputType" or "KeyCode",name=value.Name} end
        values[flag]=value
        if control.Mode then modes[flag]=control.Mode end
    end end
    return Http:JSONEncode({version=1,values=values,keybindModes=modes})
end
function Window:LoadConfig(json)
    local ok,data=pcall(function() return Http:JSONDecode(json) end)
    if not ok or type(data)~="table" or data.version~=1 or type(data.values)~="table" then return false,"Invalid config format" end
    if data.keybindModes~=nil and type(data.keybindModes)~="table" then return false,"Invalid keybind modes" end
    for flag,mode in pairs(data.keybindModes or {}) do
        if self.Controls[flag] and self.Controls[flag].Mode and mode~="Hold" and mode~="Toggle" and mode~="Always" then return false,"Invalid keybind mode" end
    end
    local old,changes,held={},{},{}
    for _,bind in ipairs(self._binds or {}) do held[bind]=bind.Held end
    self._loading=true
    for flag,value in pairs(data.values) do
        local c=self.Controls[flag]
        if c and not c.Transient then
            old[flag]=c:Get()
            local success,err=pcall(function()
                if type(value)=="table" and value._type=="Color3" then
                    assert(type(value.hex)=="string" and #value.hex==6 and value.hex:match("^%x+$"),"Invalid color")
                    value=Color3.fromHex(value.hex)
                elseif type(value)=="table" and value._type=="KeyCode" then value=Enum.KeyCode[value.name]; assert(value,"Invalid key")
                elseif type(value)=="table" and value._type=="UserInputType" then value=Enum.UserInputType[value.name]; assert(validKey(value),"Invalid mouse binding") end
                c:Set(value,true); changes[flag]=c:Get()
            end)
            if not success then
                for f,v in pairs(old) do self.Controls[f]:Set(v,true) end
                for bind,wasHeld in pairs(held) do bind.Held=wasHeld end
                self._loading=false; return false,"Invalid value for "..flag..": "..tostring(err)
            end
        end
    end
    for _,bind in ipairs(self._binds or {}) do
        bind:SetMode((data.keybindModes or {})[bind.Flag] or "Toggle",true)
        if bind.Mode=="Hold" and bind.Target then bind.Target:Set(false,true); changes[bind.Target.Flag]=false end
    end
    self._loading=false
    -- Commit all state before callbacks, so callbacks can read a consistent config.
    for flag,value in pairs(changes) do self:_callback(self.Controls[flag].Callback,value) end
    return true
end
function Window:Reset()
    self:_releaseBinds()
    for _,bind in ipairs(self._binds or {}) do bind:SetMode("Toggle",true) end
    for _,c in pairs(self.Controls) do if not c.Transient then c:Set(copy(c.Default)) end end
end
function Window:Destroy()
    if self._dead then return end
    self:_releaseBinds()
    self:ClosePopup(); self._dead=true
    for _,conn in ipairs(self._characterConnections or {}) do conn:Disconnect() end
    for _,conn in ipairs(self._connections) do conn:Disconnect() end
    for _,control in pairs(self.Controls) do for _,conn in ipairs(control._rowConnections or {}) do conn:Disconnect() end end
    for _,t in pairs(self._tweens) do t:Cancel() end
    self.Gui:Destroy(); self._connections={}; self.Controls={}; self.Flags={}
end
-- EMBEDDED LOGO BEGIN
Library.LogoWidth=36; Library.LogoHeight=34
Library.LogoPalette={Color3.fromRGB(35,45,47),Color3.fromRGB(23,116,112),Color3.fromRGB(17,165,156),Color3.fromRGB(20,192,180),Color3.fromRGB(40,209,195),Color3.fromRGB(67,213,202)}
Library.LogoRuns={
{11,1,6,1},{20,1,5,1},{10,2,2,1},{12,2,1,3},{13,2,1,4},{14,2,1,3},{15,2,1,2},{16,2,2,1},{19,2,2,1},{21,2,3,3},{24,2,1,2},{25,2,1,1},{9,3,1,1},{10,3,1,2},{11,3,5,6},{16,3,1,2},{17,3,3,1},{20,3,5,6},{25,3,1,2},{26,3,1,1},{7,4,3,1},{10,4,1,4},{11,4,1,6},{12,4,1,5},{13,4,1,6},{14,4,1,5},{15,4,1,6},{16,4,1,5},{17,4,2,1},{19,4,1,3},{20,4,1,6},{21,4,1,5},{22,4,3,6},{25,4,1,5},{26,4,3,1},{6,5,1,1},{7,5,1,2},{8,5,1,3},{9,5,1,1},{10,5,1,6},{11,5,2,5},{13,5,1,3},{14,5,1,5},{15,5,1,6},{16,5,1,5},{17,5,2,1},{19,5,1,5},{20,5,2,6},{22,5,1,3},{23,5,1,4},{24,5,2,6},{26,5,3,2},{29,5,2,1},{5,6,1,1},{6,6,1,2},{7,6,1,6},{8,6,1,4},{9,6,1,1},{10,6,1,6},{11,6,1,5},{12,6,1,6},{13,6,2,2},{15,6,1,6},{16,6,1,5},{17,6,2,1},{19,6,1,4},{20,6,1,6},{21,6,1,3},{22,6,1,1},{23,6,1,4},{24,6,2,6},{26,6,1,2},{27,6,1,3},{28,6,1,6},{29,6,1,3},{30,6,1,1},{4,7,2,1},{6,7,1,6},{7,7,2,5},{9,7,1,1},{10,7,1,3},{11,7,2,6},{13,7,1,5},{14,7,1,1},{15,7,1,4},{16,7,1,5},{17,7,2,1},{19,7,1,5},{20,7,1,6},{21,7,1,1},{22,7,1,3},{23,7,2,6},{25,7,1,3},{26,7,1,1},{27,7,1,5},{28,7,2,6},{30,7,1,2},{31,7,1,1},{4,8,1,1},{5,8,1,2},{6,8,1,6},{7,8,1,5},{8,8,1,6},{9,8,1,4},{10,8,1,2},{11,8,2,5},{13,8,1,6},{14,8,1,2},{15,8,1,3},{16,8,1,6},{17,8,2,1},{19,8,2,5},{21,8,1,1},{22,8,1,5},{23,8,2,6},{25,8,1,2},{26,8,1,3},{27,8,1,6},{28,8,1,5},{29,8,1,6},{30,8,1,2},{31,8,1,1},{4,9,1,1},{5,9,1,2},{6,9,1,6},{7,9,2,5},{9,9,2,6},{11,9,1,5},{12,9,1,6},{13,9,1,4},{14,9,1,1},{15,9,2,5},{17,9,2,1},{19,9,1,5},{20,9,1,6},{21,9,1,1},{22,9,1,2},{23,9,4,6},{27,9,2,5},{29,9,1,6},{30,9,1,2},{31,9,1,1},{3,10,1,1},{4,10,1,2},{5,10,1,1},{6,10,1,3},{7,10,2,6},{9,10,3,5},{12,10,1,2},{13,10,1,1},{14,10,1,3},{15,10,1,6},{16,10,1,5},{17,10,2,1},{19,10,1,4},{20,10,1,6},{21,10,1,3},{22,10,1,1},{23,10,1,2},{24,10,1,5},{25,10,1,6},{26,10,2,5},{28,10,1,6},{29,10,1,4},{30,10,1,1},{31,10,1,2},{32,10,2,1},{2,11,1,1},{3,11,1,2},{4,11,1,6},{5,11,1,3},{6,11,1,1},{7,11,1,2},{8,11,2,5},{10,11,1,4},{11,11,1,1},{12,11,1,2},{13,11,1,4},{14,11,3,5},{17,11,2,1},{19,11,1,4},{20,11,2,5},{22,11,1,4},{23,11,1,2},{24,11,1,1},{25,11,1,3},{26,11,1,6},{27,11,1,5},{28,11,1,2},{29,11,1,1},{30,11,1,2},{31,11,1,6},{32,11,1,3},{33,11,1,1},{1,12,1,1},{2,12,1,2},{3,12,1,6},{4,12,1,5},{5,12,1,6},{6,12,4,5},{10,12,1,1},{11,12,1,3},{12,12,1,6},{13,12,4,5},{17,12,2,1},{19,12,1,4},{20,12,3,5},{23,12,1,6},{24,12,1,3},{25,12,1,1},{26,12,4,5},{30,12,1,6},{31,12,1,5},{32,12,1,6},{33,12,1,2},{34,12,1,1},{1,13,1,1},{2,13,1,2},{3,13,1,6},{4,13,5,5},{9,13,1,3},{10,13,1,1},{11,13,1,6},{12,13,1,5},{13,13,1,4},{14,13,3,5},{17,13,2,1},{19,13,1,4},{20,13,4,5},{24,13,1,6},{25,13,2,2},{27,13,1,6},{28,13,1,5},{29,13,1,6},{30,13,2,5},{32,13,1,6},{33,13,1,3},{34,13,1,1},{1,14,1,1},{2,14,1,2},{3,14,2,5},{5,14,2,2},{7,14,2,5},{9,14,1,4},{10,14,1,3},{11,14,2,5},{13,14,1,1},{14,14,1,2},{15,14,2,5},{17,14,2,1},{19,14,1,4},{20,14,1,5},{21,14,1,3},{22,14,1,1},{23,14,1,4},{24,14,1,5},{25,14,2,3},{27,14,2,5},{29,14,2,2},{31,14,1,5},{32,14,1,6},{33,14,1,2},{34,14,1,1},{1,15,1,1},{2,15,1,2},{3,15,3,5},{6,15,2,2},{8,15,6,5},{14,15,1,1},{15,15,1,3},{16,15,1,5},{17,15,2,1},{19,15,1,4},{20,15,1,5},{21,15,1,1},{22,15,1,3},{23,15,5,5},{28,15,1,3},{29,15,1,1},{30,15,3,5},{33,15,1,2},{34,15,1,1},{1,16,1,1},{2,16,1,3},{3,16,4,5},{7,16,1,1},{8,16,6,5},{14,16,2,2},{16,16,1,5},{17,16,2,1},{19,16,1,5},{20,16,2,2},{22,16,6,5},{28,16,1,2},{29,16,1,3},{30,16,3,5},{33,16,1,3},{34,16,1,1},{0,17,1,1},{1,17,1,2},{2,17,5,5},{7,17,1,1},{8,17,1,4},{9,17,5,5},{14,17,2,2},{16,17,1,5},{17,17,2,1},{19,17,1,5},{20,17,2,2},{22,17,6,5},{28,17,1,2},{29,17,1,3},{30,17,4,5},{34,17,1,2},{35,17,1,1},{0,18,1,1},{1,18,1,3},{2,18,4,5},{6,18,2,2},{8,18,3,5},{11,18,2,4},{13,18,1,2},{14,18,1,1},{15,18,1,4},{16,18,1,5},{17,18,2,1},{19,18,2,4},{21,18,1,1},{22,18,1,3},{23,18,5,5},{28,18,2,2},{30,18,4,5},{34,18,1,3},{35,18,1,1},{0,19,1,1},{1,19,1,3},{2,19,2,5},{4,19,1,3},{5,19,1,2},{6,19,1,1},{7,19,1,4},{8,19,3,5},{11,19,1,3},{12,19,2,2},{14,19,1,4},{15,19,1,5},{16,19,1,4},{17,19,2,1},{19,19,1,4},{20,19,1,5},{21,19,1,3},{22,19,2,1},{24,19,1,2},{25,19,4,5},{29,19,1,1},{30,19,2,2},{32,19,1,4},{33,19,1,5},{34,19,1,3},{35,19,1,1},{0,20,1,1},{1,20,1,2},{2,20,2,5},{4,20,2,2},{6,20,1,4},{7,20,3,5},{10,20,1,4},{11,20,5,5},{16,20,1,4},{17,20,2,1},{19,20,1,4},{20,20,3,5},{23,20,1,4},{24,20,1,5},{25,20,1,4},{26,20,4,5},{30,20,1,3},{31,20,1,2},{32,20,1,4},{33,20,1,5},{34,20,1,2},{35,20,1,1},{0,21,2,1},{2,21,8,5},{10,21,2,2},{12,21,1,5},{13,21,2,4},{15,21,1,5},{16,21,1,4},{17,21,2,1},{19,21,1,4},{20,21,1,5},{21,21,1,4},{22,21,2,5},{24,21,2,2},{26,21,1,4},{27,21,6,5},{33,21,1,4},{34,21,2,1},{1,22,1,1},{2,22,1,2},{3,22,1,4},{4,22,3,5},{7,22,2,4},{9,22,1,5},{10,22,1,4},{11,22,1,1},{12,22,1,2},{13,22,1,5},{14,22,3,4},{17,22,2,1},{19,22,1,4},{20,22,1,5},{21,22,1,4},{22,22,1,5},{23,22,1,2},{24,22,1,1},{25,22,1,4},{26,22,1,5},{27,22,2,4},{29,22,3,5},{32,22,1,4},{33,22,1,2},{34,22,1,1},{2,23,2,1},{4,23,4,2},{8,23,2,4},{10,23,1,5},{11,23,1,3},{12,23,1,1},{13,23,1,4},{14,23,1,5},{15,23,2,4},{17,23,2,1},{19,23,1,4},{20,23,1,5},{21,23,1,4},{22,23,1,5},{23,23,1,1},{24,23,1,3},{25,23,1,5},{26,23,2,4},{28,23,4,2},{32,23,2,1},{3,24,1,1},{4,24,3,2},{7,24,3,4},{10,24,1,5},{11,24,2,2},{13,24,1,4},{14,24,1,3},{15,24,2,4},{17,24,2,1},{19,24,2,4},{21,24,1,3},{22,24,1,4},{23,24,1,1},{24,24,1,2},{25,24,1,5},{26,24,3,4},{29,24,3,2},{32,24,1,1},{3,25,1,1},{4,25,1,4},{5,25,2,5},{7,25,3,4},{10,25,1,3},{11,25,1,1},{12,25,1,3},{13,25,1,4},{14,25,1,2},{15,25,1,3},{16,25,1,4},{17,25,2,1},{19,25,2,4},{21,25,1,1},{22,25,1,5},{23,25,1,3},{24,25,1,1},{25,25,1,3},{26,25,3,4},{29,25,2,5},{31,25,1,4},{32,25,1,1},{3,26,1,1},{4,26,1,3},{5,26,1,5},{6,26,3,4},{9,26,1,2},{10,26,1,1},{11,26,1,3},{12,26,1,5},{13,26,1,4},{14,26,1,1},{15,26,2,4},{17,26,2,1},{19,26,2,4},{21,26,1,1},{22,26,1,3},{23,26,1,5},{24,26,1,3},{25,26,1,1},{26,26,1,2},{27,26,3,4},{30,26,1,5},{31,26,1,3},{32,26,1,1},{3,27,2,1},{5,27,1,4},{6,27,3,5},{9,27,3,4},{12,27,1,3},{13,27,1,1},{14,27,1,2},{15,27,1,5},{16,27,1,4},{17,27,2,1},{19,27,1,3},{20,27,1,5},{21,27,1,3},{22,27,1,1},{23,27,1,3},{24,27,4,4},{28,27,2,5},{30,27,1,4},{31,27,2,1},{4,28,2,1},{6,28,1,2},{7,28,1,3},{8,28,1,2},{9,28,3,4},{12,28,1,2},{13,28,1,3},{14,28,1,4},{15,28,1,5},{16,28,1,3},{17,28,2,1},{19,28,1,2},{20,28,1,5},{21,28,1,4},{22,28,1,3},{23,28,1,2},{24,28,3,4},{27,28,1,2},{28,28,1,3},{29,28,1,2},{30,28,2,1},{6,29,3,1},{9,29,1,2},{10,29,1,4},{11,29,4,5},{15,29,1,4},{16,29,4,1},{20,29,1,3},{21,29,3,5},{24,29,1,4},{25,29,1,5},{26,29,1,2},{27,29,3,1},{9,30,1,1},{10,30,1,2},{11,30,1,3},{12,30,1,4},{13,30,1,3},{14,30,1,2},{15,30,2,1},{19,30,2,1},{21,30,1,2},{22,30,1,3},{23,30,1,4},{24,30,1,3},{25,30,1,2},{26,30,1,1},{10,31,6,1},{20,31,6,1}
}
-- EMBEDDED LOGO END
return Library

end)()
local Detector=(function()
-- Frekks Hail v3: independent match/opponent detector (adaptation).
-- Derived from the EnvironmentID + TeamID checks in the supplied source.
-- This utility only reads Roblox player attributes. It does not alter matches.
-- Use as a ModuleScript or evaluate with loadstring in a suitable Luau context.
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Detector = {}
Detector.__index = Detector

function Detector.new()
    local self = setmetatable({}, Detector)
    self.ChangedEvent = Instance.new("BindableEvent")
    self.Changed = self.ChangedEvent.Event
    self.Connections = {}
    self.PlayerConnections = {}
    self.Destroyed = false

    local function update()
        if not self.Destroyed then self.ChangedEvent:Fire(self:GetMatchPlayers(),self:GetOpponents(),self:GetTeammates()) end
    end

    local function track(player)
        if self.PlayerConnections[player] then return end
        self.PlayerConnections[player] = {
            player:GetAttributeChangedSignal("EnvironmentID"):Connect(update),
            player:GetAttributeChangedSignal("TeamID"):Connect(update),
        }
    end
    for _,player in ipairs(Players:GetPlayers()) do track(player) end
    table.insert(self.Connections,Players.PlayerAdded:Connect(function(player)
        track(player)
        update()
    end))
    table.insert(self.Connections,Players.PlayerRemoving:Connect(function(player)
        for _,connection in ipairs(self.PlayerConnections[player] or {}) do connection:Disconnect() end
        self.PlayerConnections[player] = nil
        update()
    end))
    update()
    return self
end

function Detector:IsInSameMatch(player)
    if not player or player==LocalPlayer then return false end
    local localEnvironment = LocalPlayer:GetAttribute("EnvironmentID")
    return localEnvironment ~= nil and player:GetAttribute("EnvironmentID") == localEnvironment
end

function Detector:IsOpponent(player)
    if not self:IsInSameMatch(player) then return false end
    -- Same condition as RemoteFighterState.SetLocalFighter in the source.
    local theirTeam = player:GetAttribute("TeamID")
    local myTeam = LocalPlayer:GetAttribute("TeamID")
    return myTeam == nil or theirTeam ~= myTeam
end

function Detector:IsTeammate(player)
    return self:IsInSameMatch(player) and not self:IsOpponent(player)
end

function Detector:GetMatchPlayers()
    local results = {}
    for _,player in ipairs(Players:GetPlayers()) do
        if self:IsInSameMatch(player) then results[#results+1] = player end
    end
    return results
end

function Detector:GetOpponents()
    local results = {}
    for _,player in ipairs(self:GetMatchPlayers()) do
        if self:IsOpponent(player) then results[#results+1] = player end
    end
    return results
end

function Detector:GetTeammates()
    local results = {}
    for _,player in ipairs(self:GetMatchPlayers()) do
        if self:IsTeammate(player) then results[#results+1] = player end
    end
    return results
end

function Detector:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _,c in ipairs(self.Connections) do c:Disconnect() end
    for _,list in pairs(self.PlayerConnections) do
        for _,c in ipairs(list) do c:Disconnect() end
    end
    self.ChangedEvent:Destroy()
end

return Detector

end)()
local Policy=(function()
-- Match policy for ESP, camera aim, silent aim and triggerbot.
-- EnvironmentID/TeamID predicate adapted from the supplied opponent detector.
local Policy={}
function Policy.IsOpponent(localState,remote)
    if not localState.Ready or remote.IsLocal then return false end
    local environment=localState.EnvironmentID
    if environment==nil or environment=="" or remote.EnvironmentID~=environment then return false end
    return localState.TeamID==nil or remote.TeamID~=localState.TeamID
end
function Policy.Roll(chance,random)
    chance=math.clamp(tonumber(chance) or 0,0,100)
    if chance==0 then return false end
    if chance==100 then return true end
    return (random or math.random)()*100<chance
end
function Policy.InFov(x,y,cx,cy,radius,shape)
    local dx,dy=x-cx,y-cy
    if shape=="Square" then return math.max(math.abs(dx),math.abs(dy))<=radius end
    if shape=="Hexagon" then return math.abs(dx)<=radius and math.abs(dy)<=math.sqrt(3)*radius*.5 and math.sqrt(3)*math.abs(dx)+math.abs(dy)<=math.sqrt(3)*radius end
    return dx*dx+dy*dy<=radius*radius
end
return Policy

end)()
local ConfigStore=(function()
-- Storage is injected: executor file APIs are optional and never used as paths for names.
local Store={}; Store.__index=Store
function Store.new(codec,read,write)
    local self=setmetatable({Codec=codec,Read=read,Write=write,Data={version=1,configs={},autoload="",waypoints={}}},Store)
    self:Refresh(); return self
end
function Store:Refresh()
    if not self.Read then return true end
    local ok,raw=pcall(self.Read)
    if not ok then return false,"No saved storage: "..tostring(raw) end
    local valid,data=pcall(self.Codec.JSONDecode,self.Codec,raw)
    if not valid or type(data)~="table" or type(data.configs)~="table" then return false,"Saved storage is invalid; existing data retained" end
    local configs={}
    for name,json in pairs(data.configs) do if type(name)=="string" and type(json)=="string" then configs[name]=json end end
    local waypoints={}
    for name,points in pairs(type(data.waypoints)=="table" and data.waypoints or {}) do
        if type(name)=="string" and type(points)=="table" then waypoints[name]=points end
    end
    self.Data={version=1,configs=configs,autoload=type(data.autoload)=="string" and data.autoload or "",waypoints=waypoints}
    return true
end
function Store:Persist(nextData)
    if self.Write then
        local ok,err=pcall(function() self.Write(self.Codec:JSONEncode(nextData)) end)
        if not ok then return false,"Could not save storage: "..tostring(err) end
    end
    self.Data=nextData; return true
end
function Store:_next()
    local configs={}; for k,v in pairs(self.Data.configs) do configs[k]=v end
    local waypoints={}; for k,v in pairs(self.Data.waypoints) do waypoints[k]=v end
    return {version=1,configs=configs,autoload=self.Data.autoload,waypoints=waypoints}
end
function Store:Names(kind)
    local list={}; for name in pairs(self.Data[kind or "configs"]) do table.insert(list,name) end; table.sort(list); return list
end
function Store:Save(name,json)
    if type(name)~="string" or name:match("^%s*$") then return false,"Enter a config name" end
    name=name:match("^%s*(.-)%s*$")
    local data=self:_next(); data.configs[name]=json; return self:Persist(data)
end
function Store:Delete(name)
    if not self.Data.configs[name] then return false,"Select a config" end
    local data=self:_next(); data.configs[name]=nil
    if data.autoload==name then data.autoload="" end
    return self:Persist(data)
end
function Store:SetAutoload(name)
    if name~="" and not self.Data.configs[name] then return false,"Select a config" end
    local data=self:_next(); data.autoload=name; return self:Persist(data)
end
function Store:SaveWaypoints(name,points)
    if name=="" then return false,"Enter a set name" end
    local snapshot={}
    for _,p in ipairs(points) do table.insert(snapshot,{name=p.name,x=p.x,y=p.y,z=p.z,death=p.death==true}) end
    local data=self:_next(); data.waypoints[name]=snapshot; return self:Persist(data)
end
function Store:DeleteWaypoints(name)
    local data=self:_next(); data.waypoints[name]=nil; return self:Persist(data)
end
return Store

end)()
local Runtime=(function()
-- RIVALS client adapter. Wire format, fighter fields and match rules adapted from
-- the supplied Frekks Hail v3 excerpts (cK/cN/gV and IsReadyToFight).
local Runtime={}; Runtime.__index=Runtime
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Replicated=game:GetService("ReplicatedStorage")
local Local=Players.LocalPlayer
local function read(object,key)
    local ok,result=pcall(function() return object and object[key] end)
    if ok then return result end
    return nil
end
local function path(root,...)
    for _,name in ipairs({...}) do root=root and root:FindFirstChild(name) end
    return root
end
local function encode(cf)
    local x,y,z=cf:ToOrientation()
    return {["\0"]=cf.X,["\1"]=cf.Y,["\2"]=cf.Z,["\3"]=x,["\4"]=y,["\5"]=z}
end
local function decode(data)
    if type(data)~="table" then return nil end
    for i=0,5 do if type(data[string.char(i)])~="number" then return nil end end
    return CFrame.new(data["\0"],data["\1"],data["\2"])*CFrame.fromOrientation(data["\3"],data["\4"],data["\5"])
end
function Runtime.new(ui,Detector,Policy,Visuals,Client)
    local self=setmetatable({UI=ui,Policy=Policy,Alive=true,Connections={},Notified={},Fighters={},Targets={},
        Switches={},Detector=Detector.new(),Hooked=false,Status={},SpringVelocity=Vector3.zero},Runtime)
    self.Visuals=Visuals.new(self); self.Client=Client.new(self)
    self:Connect(self.Detector.Changed,function() self:ClearTargets(); self.Visuals:Hide() end)
    self:Connect(Players.PlayerRemoving,function(player) self.Fighters[player]=nil; self:ClearTargets(); self.Visuals:Remove(player) end)
    self:Connect(Local.CharacterRemoving,function(character)
        self.RemovingCharacter=character
        self:ClearTargets(); self:ResetTrigger(); self:ReleaseShot()
    end)
    self:Connect(Local.CharacterAdded,function(character)
        if self.RemovingCharacter==character then self.RemovingCharacter=nil end
    end)
    self:Connect(Run.RenderStepped,function(dt)
        if not self.Alive then return end
        local ok,err=pcall(function() self:Step(math.min(dt,.1)) end)
        if not ok then self:ClearTargets(); self:ReleaseShot(); self.Visuals:Hide(); self:Report("runtime",err) end
    end)
    self:Connect(Run.Heartbeat,function(dt)
        if self.Alive then local ok,err=pcall(function() self.Client:Step(dt) end); if not ok then self:Report("client",err) end end
    end)
    self:Connect(Local.Idled,function()
        if self:On("e.9") then
            pcall(function() local vu=game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.zero) end)
        end
    end)
    self:Connect(Input.JumpRequest,function()
        if self:On("e.8") or self:On("misc2.4") then local hum=self:Character(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end)
    local originalDestroy=ui.Destroy
    ui.Destroy=function(window) self:Destroy(); originalDestroy(window) end
    ui.Runtime=self
    task.spawn(function() self:ResolveControllers() end)
    return self
end
function Runtime:Connect(event,callback)
    local connect=read(event,"Connect")
    if type(connect)~="function" then return nil end
    local c=connect(event,callback); table.insert(self.Connections,c); return c
end
function Runtime:Value(flag,default)
    local value=self.UI and self.UI.Flags[flag]
    if value==nil then return default end; return value
end
function Runtime:On(flag)
    local bind=self.UI and self.UI.Controls[flag..".key"]
    if bind and bind.Mode=="Hold" and not bind.Held then return false end
    return self:Value(flag,false)==true
end
function Runtime:Color(flag,default)
    local value=self:Value(flag..".color",default or Color3.new(1,1,1))
    return typeof(value)=="Color3" and value or Color3.new(1,1,1)
end
function Runtime:Report(key,message)
    local now=os.clock(); local previous=self.Notified[key]
    if previous and now-previous<8 then return end
    self.Notified[key]=now; warn("[Serotonin / RIVALS] "..tostring(message))
    if self.UI and not self.UI._dead then self.UI:Notify(tostring(message)) end
end
function Runtime:Unsupported(flag,message)
    local c=self.UI.Controls[flag]
    if c and c.Value then c:Set(false,true); self.Status[flag]=message; self:Report(flag,message) end
end
function Runtime:ResolveControllers()
    local scripts=Local:FindFirstChild("PlayerScripts") or Local:WaitForChild("PlayerScripts",15)
    if not self.Alive then return end
    local controllers=scripts and (scripts:FindFirstChild("Controllers") or scripts:WaitForChild("Controllers",15))
    local function module(parent,name)
        local source=parent and parent:FindFirstChild(name)
        if not source then return nil end
        local ok,result=pcall(require,source)
        if not ok then self:Report(name,"Cannot load RIVALS "..name..": "..tostring(result)); return nil end
        return result
    end
    local fighter=self.FighterController or module(controllers,"FighterController")
    local camera=self.CameraController or module(controllers,"CameraController")
    local enums=self.EnumLibrary or module(Replicated:FindFirstChild("Modules"),"EnumLibrary")
    local clientItem=self.ClientItem or module(path(scripts,"Modules","ClientReplicatedClasses","ClientFighter"),"ClientItem")
    local enemies=self.EnemyController or module(controllers,"EnemyController")
    if not self.Alive then return end
    self.FighterController=fighter; self.CameraController=camera; self.EnumLibrary=enums; self.ClientItem=clientItem
    self.EnemyController=enemies
    self.UseItem=path(Replicated,"Remotes","Replication","Fighter","UseItem")
    if fighter and fighter~=self.BoundFighterController then
        self.BoundFighterController=fighter
        for _,entry in pairs(read(fighter,"Objects") or {}) do local p=read(entry,"Player"); if p then self.Fighters[p]=entry end end
        self:Connect(read(fighter,"ObjectAdded"),function(entry) local p=read(entry,"Player"); if p then self.Fighters[p]=entry; self:ClearTargets() end end)
        self:Connect(read(fighter,"ObjectRemoved"),function(entry) local p=read(entry,"Player"); if p and self.Fighters[p]==entry then self.Fighters[p]=nil; self:ClearTargets() end end)
    elseif not fighter then
        self:Report("fighter","RIVALS fighter controller unavailable; match targeting stays off until it loads")
    end
    self:InstallSilentHook()
    if not (fighter and enemies and enums and self.UseItem and camera and clientItem) then
        task.delay(3,function() if self.Alive then self:ResolveControllers() end end)
    end
end
function Runtime:Fighter(player)
    local map=read(self.FighterController,"_player_to_fighter")
    local fighter=map and map[player] or self.Fighters[player]
    if fighter then return fighter end
    -- Objects can populate after the module loads without an ObjectAdded replay.
    for _,entry in pairs(read(self.FighterController,"Objects") or {}) do
        if read(entry,"Player")==player then self.Fighters[player]=entry; return entry end
    end
end
function Runtime:FighterValue(fighter,key)
    local value=read(read(fighter,"Data"),key)
    if value~=nil then return value end
    local getter=read(fighter,"GetData")
    if type(getter)=="function" then
        local ok,result=pcall(getter,fighter,key)
        if ok and result~=nil then return result end
    end
    return read(fighter,key)
end
local function characterParts(model)
    local humanoid=model and model:FindFirstChildOfClass("Humanoid")
    local root=model and model:FindFirstChild("HumanoidRootPart")
    return humanoid,root,model
end
function Runtime:MatchMode(fighter)
    if self:FighterValue(fighter,"IsInShootingRange")==true then return "Range" end
    if self:FighterValue(fighter,"IsInDuel")==true then return "Duel" end
end
function Runtime:CombatModel(fighter)
    local entity=read(fighter,"Entity")
    local model=read(entity,"Model")
    if not model or not model:IsA("Model") then return nil,"Local fighter has no combat model" end
    if model==self.RemovingCharacter then return nil,"Local fighter combat model is being removed" end
    local inWorld=read(entity,"_is_in_world")
    if inWorld==false or not model:IsDescendantOf(workspace) then
        return nil,"Local fighter combat model is outside Workspace"
    end
    if model~=Local.Character and inWorld~=true then return nil,"Local fighter combat model is still spawning" end
    local environment=Local:GetAttribute("EnvironmentID")
    local modelEnvironment=model:GetAttribute("EnvironmentID")
    if environment~=nil and modelEnvironment~=nil and environment~=modelEnvironment then
        return nil,"Local fighter combat model belongs to a different environment"
    end
    local hum,root=characterParts(model)
    if not hum or hum.Health<=0 or not root or not root:IsA("BasePart") then
        return nil,"Local fighter combat model has no living humanoid and root"
    end
    return model
end
function Runtime:Character()
    local fighter=self:Fighter(Local)
    local mode=self:MatchMode(fighter)
    local model=nil
    if mode=="Range" or (mode=="Duel" and self:FighterValue(fighter,"IsSpectating")~=true) then
        model=self:CombatModel(fighter)
    end
    local character=model or Local.Character
    if character==self.RemovingCharacter then character=nil end
    return characterParts(character)
end
function Runtime:Ready()
    local fighter=self:Fighter(Local)
    if not fighter then return false,"Local fighter missing from FighterController" end
    local mode=self:MatchMode(fighter)
    -- The live fighter can move and shoot in the range while IsSpectating is true.
    -- Outside the range, spectators still cannot use combat targeting.
    if mode~="Range" and self:FighterValue(fighter,"IsSpectating")==true then
        return false,"Local fighter is spectating"
    end
    if not mode then return false,"Local fighter is outside a duel or shooting range" end
    local environment=Local:GetAttribute("EnvironmentID")
    if mode=="Duel" and (environment==nil or environment=="") then return false,"Local EnvironmentID is missing" end
    local model,reason=self:CombatModel(fighter)
    if not model then return false,reason end
    return true
end
function Runtime:IsOpponent(player,passive)
    if not player or not player.Parent then return false end
    return self.Policy.IsOpponent({Ready=passive==true or self:Ready(),EnvironmentID=Local:GetAttribute("EnvironmentID"),TeamID=Local:GetAttribute("TeamID")},
        {IsLocal=player==Local,EnvironmentID=player:GetAttribute("EnvironmentID"),TeamID=player:GetAttribute("TeamID")})
end
function Runtime:ClearTargets()
    self.Targets={}; self.Switches={}; self.SpringVelocity=Vector3.zero; self.OpponentCache=nil; self.CandidateCache={}
end
function Runtime:Opponents()
    if not self.OpponentCache or os.clock()>=(self.OpponentExpires or 0) then
        self.OpponentCache=self.Detector:GetOpponents(); self.OpponentExpires=os.clock()+self:Value("settings.mapRate",15)
    end
    return self.OpponentCache
end
function Runtime:Pointer()
    local camera=workspace.CurrentCamera
    -- ESP uses a full-screen, inset-free overlay and WorldToViewportPoint coordinates.
    -- GetMouseLocation already uses that origin; subtracting GetGuiInset shifts the FOV up.
    if camera and (not Input.MouseEnabled or Input.MouseBehavior==Enum.MouseBehavior.LockCenter
        or self:MatchMode(self:Fighter(Local))=="Range") then
        return camera.ViewportSize*.5
    end
    return Input:GetMouseLocation()
end
function Runtime:InputBlocked()
    return Input:GetFocusedTextBox()~=nil or game:GetService("GuiService").MenuIsOpen
        or self.UI._popup~=nil or self.UI._binding~=nil
end
function Runtime:Checks(flag,name)
    return table.find(self:Value(flag,{}),name)~=nil
end
function Runtime:Visible(part,model,origin)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    local _,_,character=self:Character()
    params.FilterDescendantsInstances={character,workspace.CurrentCamera}
    local direction=part.Position-origin
    local hit=workspace:Raycast(origin,direction,params)
    return not hit or hit.Instance:IsDescendantOf(model)
end
function Runtime:Vulnerable(player,char)
    local fighter=player and self:Fighter(player)
    local entity=read(fighter,"Entity"); local data=read(entity,"Data")
    return not char:FindFirstChildOfClass("ForceField") and read(data,"IsInvincible")~=true
end
function Runtime:Parts(char,selection,allAliases,rangeTarget)
    local names={Head={"HitboxHead","HitboxHeadSmall","Head"},Torso={"HitboxBody","HitboxBodySmall","UpperTorso","Torso","HumanoidRootPart"},
        Arms={"LeftUpperArm","RightUpperArm","Left Arm","Right Arm"},Legs={"LeftUpperLeg","RightUpperLeg","Left Leg","Right Leg"}}
    local result={}; local selected=#selection>0 and selection or {"Head","Torso"}
    for _,category in ipairs(selected) do
        for _,name in ipairs(names[category] or {}) do
            local part=char:FindFirstChild(name,rangeTarget==true)
            if part and part:IsA("BasePart") then table.insert(result,part); if not allAliases and (category=="Head" or category=="Torso") then break end end
        end
    end
    if rangeTarget and char.Name=="Target" and (#selection==0 or table.find(selection,"Torso")) then
        local part=char:FindFirstChild("Hitbox",true) or char:FindFirstChild("Target",true) or char.PrimaryPart
        if part and part:IsA("BasePart") then table.insert(result,part) end
    end
    return result
end
function Runtime:OpponentCharacter(player,includeDead)
    local entity=read(self:Fighter(player),"Entity")
    local model=read(entity,"Model")
    if not model or not model:IsA("Model") or not model:IsDescendantOf(workspace) then model=player.Character end
    if not model or not model:IsA("Model") or not model:IsDescendantOf(workspace) then return nil end
    if read(entity,"_is_in_world")==false then
        local hum=includeDead and model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health>0 then return nil end
    end
    return model
end
function Runtime:RangeModels()
    local models={}
    if self:FighterValue(self:Fighter(Local),"IsInShootingRange")~=true then return models end
    local environment=Local:GetAttribute("EnvironmentID")
    local byModel=read(self.EnemyController,"_model_to_enemy") or {}
    local objects=read(self.EnemyController,"Objects") or {}
    local seen={}
    for _,registry in ipairs({byModel,objects}) do
        for _,enemy in pairs(registry) do
            local model=read(enemy,"Model")
            if model and not seen[model] and model:IsA("Model") and model:IsDescendantOf(workspace)
                and (model.Name=="Target" or model.Name=="Dummy" or model.Name=="DPS Dummy")
                and model:GetAttribute("EnvironmentID")==environment then
                seen[model]=true
                table.insert(models,model)
            end
        end
    end
    return models
end
function Runtime:MatchTargets()
    local fighter=self:Fighter(Local)
    local mode=self:MatchMode(fighter)
    local spectating=self:FighterValue(fighter,"IsSpectating")==true
    local targets={}
    if not mode and not spectating then return targets end
    for _,player in ipairs(self:Opponents()) do
        if self:IsOpponent(player,true) and (mode or self:MatchMode(self:Fighter(player))=="Duel") then
            local model=self:OpponentCharacter(player,true)
            if model then table.insert(targets,{Player=player,Character=model}) end
        end
    end
    if mode=="Range" then
        for _,model in ipairs(self:RangeModels()) do
            table.insert(targets,{Character=model})
        end
    end
    return targets
end
function Runtime:Candidate(player,mode,rangeModel)
    if player and not self:IsOpponent(player) then return nil end
    local char=rangeModel or self:OpponentCharacter(player)
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not char or (hum and hum.Health<=0) or (player and not hum) then return nil end
    if (mode=="Silent" or self:Checks("aim.checks","Forcefield")) and not self:Vulnerable(player,char) then return nil end
    self.CandidateCache=self.CandidateCache or {}
    local byMode=self.CandidateCache[mode] or {}
    self.CandidateCache[mode]=byMode
    local cacheKey=player or char
    local cached=byMode[cacheKey]
    if cached and os.clock()-cached.At<self:Value("settings.cacheRate",7)/1000 and cached.Character==char then return cached.Target end
    local camera=workspace.CurrentCamera; if not camera then return nil end
    local origin=camera.CFrame.Position; local pointer=self:Pointer(); local best=nil
    if self:Value("settings.raycast","Camera")=="Character" then local _,root=self:Character(); if root then origin=root.Position end end
    local radius=mode=="Silent" and self:Value("aim.silentFov",150) or self:Value("aim.fov",150)
    if self:On("aim.smartFov") and self:Value("aim.fovType")=="Dynamic" then radius=radius*70/math.max(camera.FieldOfView,1) end
    for _,part in ipairs(self:Parts(char,self:Value("aim.hitboxes",{}),false,rangeModel~=nil)) do
        local point,onScreen=camera:WorldToViewportPoint(part.Position)
        local distance=(part.Position-origin).Magnitude
        local inFov=self.Policy.InFov(point.X,point.Y,pointer.X,pointer.Y,radius,self:Value("aim.fovShape","Circle"))
        if onScreen and point.Z>0 and inFov and distance<=self:Value("aim.distance",1000)
            and (not self:Checks("aim.checks","Visible") or self:Visible(part,char,origin)) then
            local screen=Vector2.new(point.X,point.Y); local error=(screen-pointer).Magnitude
            local targeting=self:Value("aim.targeting","Closest to Crosshair")
            local score=targeting=="Closest to Player" and distance or targeting=="Lowest Health" and (hum and hum.Health or math.huge) or error
            if not best or score<best.Score then best={Player=player,Character=char,Part=part,Humanoid=hum,Screen=screen,Distance=distance,Error=error,Score=score} end
        end
    end
    byMode[cacheKey]={At=os.clock(),Character=char,Target=best}
    return best
end
function Runtime:Select(mode)
    if not self:Ready() then self:ClearTargets(); return nil end
    local current=self.Targets[mode]
    local rangeModels=self:RangeModels()
    local retained=nil
    if current then
        if current.Player then retained=self:Candidate(current.Player,mode)
        elseif table.find(rangeModels,current.Character) then retained=self:Candidate(nil,mode,current.Character) end
    end
    if self:On("aim.sticky") and retained then return retained end
    local best=nil
    for _,player in ipairs(self:Opponents()) do
        local candidate=self:Candidate(player,mode)
        if candidate and (not best or candidate.Score<best.Score) then best=candidate end
    end
    for _,model in ipairs(rangeModels) do
        local candidate=self:Candidate(nil,mode,model)
        if candidate and (not best or candidate.Score<best.Score) then best=candidate end
    end
    if retained and best and retained.Character~=best.Character then
        local state=self.Switches[mode]
        if not state or state.Character~=best.Character then state={Character=best.Character,Since=os.clock()}; self.Switches[mode]=state end
        if os.clock()-state.Since<self:Value("aim.switchDelay",0)/1000 then return retained end
    else self.Switches[mode]=nil end
    return best
end
function Runtime:Position(target,mode)
    local position=target.Part.Position
    local predict=mode=="Trigger" and self:On("trigger.prediction") or self:On("aim.prediction")
    if predict then
        local latency=.05; pcall(function() latency=Local:GetNetworkPing() end)
        position=position+target.Part.AssemblyLinearVelocity*math.clamp(latency,0,.25)
    end
    if self:On("aim.offset") then position=position+Vector3.new(0,target.Part.Size.Y*.1*self:Value("aim.multipoint",1),0) end
    return position
end
function Runtime:Aim(dt)
    local target=self.Targets.Camera; if not target then return end
    local method=self:Value("aim.method","None")
    if method=="None" then return end
    local camera=workspace.CurrentCamera; if not camera then return end
    local position=self:Position(target,"Camera")
    if (position-camera.CFrame.Position).Magnitude<.001 then return end
    local smoothing=self:Value("aim.smoothing",75); local speed=self:Value("aim.speed",1)
    local style=self:Value("aim.style","Spring")
    local alpha=style=="Linear" and math.clamp((1-smoothing/101)*speed*dt*60,0,1) or 1-math.exp(-math.max(.1,(101-smoothing)*speed)*dt)
    if style=="Spring" then alpha=1-math.exp(-math.sqrt(math.max(.1,(101-smoothing)*speed))*dt*3) end
    if method=="Mouse" then
        if type(mousemoverel)~="function" then self:Unsupported("aim.enabled","Mouse aiming requires mousemoverel support"); return end
        local p=camera:WorldToViewportPoint(position); if p.Z<=0 then return end
        local delta=(Vector2.new(p.X,p.Y)-self:Pointer())*alpha
        mousemoverel(delta.X,delta.Y)
    else
        local controller=self.CameraController
        local setter=read(controller,"SetRotation")
        if type(setter)~="function" then setter=read(read(getmetatable(controller),"__index"),"SetRotation") end
        if type(setter)~="function" then
            self:Report("camera-controller","CameraController.SetRotation is unavailable")
            return
        end
        local rotation=read(controller,"Rotation")
        if typeof(rotation)~="Vector2" then
            local pitch,yaw=camera.CFrame:ToOrientation()
            rotation=Vector2.new(pitch,yaw)
        end
        local pitch,yaw=CFrame.lookAt(camera.CFrame.Position,position):ToOrientation()
        setter(controller,self.BlendRotation(rotation,pitch,yaw,alpha))
    end
end
function Runtime.BlendRotation(rotation,pitch,yaw,alpha)
    local delta=(yaw-rotation.Y+math.pi)%(2*math.pi)-math.pi
    return Vector2.new(rotation.X+(pitch-rotation.X)*alpha,rotation.Y+delta*alpha)
end
function Runtime:DispatchShot(args)
    if not self.Alive then return args end
    self.UseItemObserved=true
    pcall(self.ObserveShot,self,args)
    local ok,changed=pcall(self.RewriteShot,self,args)
    if not ok then self:Report("silent-hook",changed) end
    return ok and changed or args
end
-- Adapted from the supplied host_modifiers ClientItem.Input dispatcher.
-- Only the exact ReplicatedStorage dependency is replaced; other accesses forward unchanged.
function Runtime:InstallInputDispatcher()
    if self.InputRestore then return true end
    local input=read(self.ClientItem,"Input")
    if type(input)~="function" then return false,"ClientItem.Input unavailable" end
    if not debug or type(debug.getupvalues)~="function" or type(debug.setupvalue)~="function"
        or type(setrawmetatable)~="function" or type(clonefunction)~="function" then
        return false,"ClientItem dispatcher requires debug upvalue APIs, setrawmetatable and clonefunction"
    end
    local ok,result=pcall(function()
        local cleanRemote=Instance.new("RemoteEvent")
        local send=clonefunction(cleanRemote.FireServer)
        cleanRemote:Destroy()
        local runtime=self
        local remote={FireServer=function(_,...)
            local args=runtime:DispatchShot(table.pack(...))
            return send(runtime.UseItem,table.unpack(args,1,args.n))
        end}
        local function forward(original,overrides)
            return setmetatable(overrides,{__index=function(_,key)
                local value=original[key]
                if type(value)=="function" then return function(_,...) return value(original,...) end end
                return value
            end})
        end
        local remotes=Replicated.Remotes
        local branch=forward(remotes.Replication.Fighter,{UseItem=remote})
        branch=forward(remotes.Replication,{Fighter=branch})
        branch=forward(remotes,{Replication=branch})
        local proxy=forward(Replicated,{Remotes=branch})
        local dummy=Color3.new()
        setrawmetatable(dummy,{__index=function(_,key) return proxy[key] end})
        local function matches(value)
            if value==Replicated then return true end
            if typeof(value)=="Instance" and type(compareinstances)=="function" then
                local success,equal=pcall(compareinstances,value,Replicated); return success and equal
            end
            return false
        end
        local upvalues=debug.getupvalues(input)
        for index,value in pairs(upvalues) do
            if matches(value) then
                debug.setupvalue(input,index,dummy)
                if debug.getupvalues(input)[index]==dummy then
                    self.InputRestore={Method=input,Index=index,Original=value,Proxy=dummy}
                    return true
                end
            end
        end
        for _,bundle in pairs(upvalues) do if type(bundle)=="table" then
            for key,value in pairs(bundle) do if matches(value) then
                bundle[key]=dummy
                self.InputRestore={Bundle=bundle,Key=key,Original=value,Proxy=dummy}
                return true
            end end
        end end
        return false
    end)
    if not ok then return false,tostring(result) end
    if result then return true end
    return false,"ClientItem.Input ReplicatedStorage dependency was not found"
end
function Runtime:RestoreInputDispatcher()
    local record=self.InputRestore; self.InputRestore=nil
    if not record then return end
    pcall(function()
        if record.Bundle then
            if record.Bundle[record.Key]==record.Proxy then record.Bundle[record.Key]=record.Original end
        elseif debug.getupvalues(record.Method)[record.Index]==record.Proxy then
            debug.setupvalue(record.Method,record.Index,record.Original)
        end
    end)
end
function Runtime:InstallSilentHook()
    if not self.UseItem then self.Status["aim.silent"]="RIVALS UseItem remote is unavailable"; return end
    local installed,reason=self:InstallInputDispatcher()
    self.InputDispatcherStatus=reason
    if installed then self.Hooked=true; self.HookPath="ClientItem.Input"; self.Status["aim.silent"]=nil; return end
    if self.Hooked then return end
    if type(hookmetamethod)~="function" or type(getnamecallmethod)~="function" then
        self.Status["aim.silent"]="Silent aim requires hookmetamethod/getnamecallmethod"; return
    end
    local original; local runtime=self
    local function wrapper(remote,...)
        if runtime.Alive and not runtime.InputRestore and remote==runtime.UseItem and getnamecallmethod()=="FireServer" then
            local args=runtime:DispatchShot(table.pack(...))
            return original(remote,table.unpack(args,1,args.n))
        end
        return original(remote,...)
    end
    local closure=type(newcclosure)=="function" and newcclosure(wrapper) or wrapper
    local ok,result=pcall(hookmetamethod,game,"__namecall",closure)
    if ok and type(result)=="function" then
        original=result; self.Hooked=true; self.OriginalHook=result; self.Hook=closure; self.HookPath="Namecall fallback"; self.Status["aim.silent"]=nil
    else self.Status["aim.silent"]="Silent aim hook failed: "..tostring(result) end
end
function Runtime:IsShotAction(action)
    if action=="StartShooting" then return true end
    if action==nil then return false end
    local from=read(self.EnumLibrary,"_from_enum")
    local to=read(self.EnumLibrary,"_to_enum")
    return read(from,action)=="StartShooting" or read(to,"StartShooting")==action
end
function Runtime:EquippedItem(fighter)
    local item=read(fighter,"EquippedItem")
    if type(item)=="table" then return item end
    return read(read(fighter,"Items"),item)
end
function Runtime:ObserveShot(args)
    if not self:IsShotAction(args[2]) then return end
    self.LastShotAt=os.clock()
    if not self:Ready() then return end
    local target=self.Targets.Silent or self.Targets.Camera or self:Select("Camera")
    if target and target.Player and (self:On("aim.silent") or target.Error<=12) then
        self.PendingHit={Player=target.Player,Health=target.Humanoid.Health,Until=os.clock()+.5}
    end
end
function Runtime:RewriteShot(args)
    if not self:On("aim.silent") or not self:Ready() or self:InputBlocked() then return nil end
    local function skip(reason) self.SilentShotStatus=reason; return nil end
    if not self:IsShotAction(args[2]) then
        if not self.EnumLibrary and type(args[2])~="string" then return skip("RIVALS shot action codec is unavailable") end
        return nil
    end
    if type(args[3])~="table" or type(args[3]["\1"])~="table" then return skip("Unrecognized shot payload") end
    local fighter=self:Fighter(Local)
    local item=self:EquippedItem(fighter)
    if args[1]==nil or self:FighterValue(item,"ObjectID")~=args[1] then
        item=nil
        for _,candidate in pairs(read(fighter,"Items") or {}) do
            if args[1]~=nil and self:FighterValue(candidate,"ObjectID")==args[1] then item=candidate; break end
        end
    end
    if not item or read(read(item,"Info"),"Type")~="Gun" then return skip("Shot item not resolved as Gun") end
    self.CandidateCache={}
    local target=self:Select("Silent")
    if not target then return skip("No eligible target inside silent FOV") end
    if not self:Vulnerable(target.Player,target.Character) then return skip("Opponent has spawn protection") end
    if not self.Policy.Roll(self:Value("aim.silentHitchance",100)) then return skip("Hitchance skipped shot") end
    local shot=args[3]["\1"]
    local from,view=decode(shot["\0"]),decode(shot["\1"])
    if not from or not view then return skip("Unrecognized shot CFrame encoding") end
    local aim=self:Position(target,"Silent")
    if (aim-from.Position).Magnitude<.001 or (aim-view.Position).Magnitude<.001 then return skip("Shot origin is on target") end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={target.Part}
    local hit=workspace:Raycast(from.Position,aim-from.Position,params)
    if not hit then return skip("Shot ray missed selected hitbox") end
    local impact=target.Part.CFrame:PointToObjectSpace(hit.Position)
    if impact.Magnitude<.001 then return skip("Shot impact is at hitbox center") end
    local outer=table.clone(args[3]); local payload=table.clone(shot)
    payload["\0"]=encode(CFrame.lookAt(from.Position,aim)); payload["\1"]=encode(CFrame.lookAt(view.Position,aim))
    payload["\2"]=target.Part
    -- The supplied gV runtime encodes the selected hit in part-local coordinates.
    payload["\3"]=encode(CFrame.new(impact))
    outer["\1"]=payload; local result=table.clone(args); result[3]=outer
    self.Targets.Silent=target; self.SilentShotStatus="Payload rewritten"; return result
end
function Runtime:ResetTrigger()
    self.TriggerCharacter=nil
    self.TriggerSince=nil
end
function Runtime:ReleaseShot()
    local release=self.ReleaseInput
    self.ReleaseInput=nil
    if release then
        local ok,err=pcall(release)
        if not ok then self:Report("trigger-release",err) end
    end
end
function Runtime:PressShot(pointer)
    if type(mouse1press)=="function" and type(mouse1release)=="function" then
        if pcall(mouse1press) then return mouse1release end
    end
    local ok,release=pcall(function()
        if not self.VirtualInput then
            local created,manager=pcall(Instance.new,"VirtualInputManager")
            self.VirtualInput=created and manager or game:GetService("VirtualInputManager")
            self.OwnsVirtualInput=created
        end
        local manager=self.VirtualInput
        manager:SendMouseButtonEvent(pointer.X,pointer.Y,0,true,game,1)
        return function() manager:SendMouseButtonEvent(pointer.X,pointer.Y,0,false,game,1) end
    end)
    if ok then return release end
    return nil,release
end
function Runtime:TriggerTarget(hit)
    if not hit then return nil end
    local char=nil
    local player=nil
    for _,opponent in ipairs(self:Opponents()) do
        local model=self:OpponentCharacter(opponent)
        if model and hit.Instance:IsDescendantOf(model) and self:IsOpponent(opponent) then
            char,player=model,opponent
            break
        end
    end
    if not char then
        for _,model in ipairs(self:RangeModels()) do
            if hit.Instance:IsDescendantOf(model) then char=model; break end
        end
    end
    if not char or not self:Vulnerable(player,char) then return nil end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if (hum and hum.Health<=0) or (player and not hum) then return nil end
    local parts=self:Parts(char,self:Value("trigger.hitboxes",{}),true,player==nil)
    if table.find(parts,hit.Instance) then return char end
    return nil
end
function Runtime:Trigger()
    local camera=workspace.CurrentCamera
    if not self:On("trigger.enabled") or not camera or not self:Ready() or self:InputBlocked() then
        self:ResetTrigger(); self:ReleaseShot(); return
    end
    local now=os.clock()
    if self.ReleaseInput then
        if now>=self.ReleaseAt then self:ReleaseShot() end
        return
    end
    if Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then self:ResetTrigger(); return end
    local pointer=self:Pointer()
    local _,root,character=self:Character()
    local ray=camera:ViewportPointToRay(pointer.X,pointer.Y)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={character,camera}
    local distance=self:Value("trigger.distance",1000)
    local origin=ray.Origin; local direction=ray.Direction*distance
    if self:Value("settings.raycast","Camera")=="Character" and root then
        origin=root.Position; direction=ray.Origin+direction-origin
    end
    local hit=workspace:Raycast(origin,direction,params)
    local target=hit and (hit.Position-origin).Magnitude<=distance and self:TriggerTarget(hit)
    if not target then self:ResetTrigger(); return end
    if self.TriggerCharacter~=target or not self.TriggerSince then
        self.TriggerCharacter=target
        self.TriggerSince=now
    end
    if now-self.TriggerSince<self:Value("trigger.delay",75)/1000 or now<(self.NextShot or 0) then return end
    local item=self:EquippedItem(self:Fighter(Local))
    if item and (read(item,"_is_charging")==true or (tonumber(read(item,"_reload_cooldown")) or 0)>tick()
        or (tonumber(read(item,"_shoot_cooldown")) or 0)>tick()) then return end
    self.NextShot=now+.05
    if not self.Policy.Roll(self:Value("trigger.hitchance",100)) then return end
    local release,err=self:PressShot(pointer)
    if release then
        self.ReleaseInput=release
        self.ReleaseAt=now+self:Value("trigger.duration",50)/1000
    else
        self:ResetTrigger()
        self:Unsupported("trigger.enabled","Trigger input unavailable: "..tostring(err))
    end
end
function Runtime:Guard(key,callback)
    local ok,err=pcall(callback)
    if not ok then self:Report(key,err) end
    return ok
end
function Runtime:Diagnostics()
    local ready,reason=self:Ready()
    local fighter=self:Fighter(Local)
    local entity=read(fighter,"Entity")
    local model=read(entity,"Model")
    return {Ready=ready,Reason=reason or "Ready",FighterController=self.FighterController~=nil,
        LocalFighter=fighter~=nil,MatchMode=self:MatchMode(fighter),Spectating=self:FighterValue(fighter,"IsSpectating"),
        EntityInWorld=read(entity,"_is_in_world"),EntityModelMatchesCharacter=model~=nil and model==Local.Character,
        EnvironmentID=Local:GetAttribute("EnvironmentID"),
        TeamID=Local:GetAttribute("TeamID"),Opponents=#self.Detector:GetOpponents(),
        EnemyController=self.EnemyController~=nil,RangeTargets=#self:RangeModels(),
        AimbotEnabled=self:On("aim.enabled"),SilentAimEnabled=self:On("aim.silent"),
        SilentHook=self.Hooked,SilentStatus=self.Status["aim.silent"],HookPath=self.HookPath,InputDispatcherStatus=self.InputDispatcherStatus,AimMethod=self:Value("aim.method"),
        InputBlocked=self:InputBlocked(),UseItemObserved=self.UseItemObserved==true,ShotObserved=self.LastShotAt~=nil,SilentShotStatus=self.SilentShotStatus,
        TriggerStatus=self.Status["trigger.enabled"],TriggerTracking=self.TriggerCharacter~=nil,
        CameraTarget=self.Targets.Camera~=nil,SilentTarget=self.Targets.Silent~=nil}
end
function Runtime:WriteDiagnostics()
    local data=self:Diagnostics()
    local ok,json=pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
    if not ok then return end
    if json~=self.LastDiagnostics then
        self.LastDiagnostics=json
        print("[Serotonin / RIVALS] "..json)
        if type(writefile)=="function" then pcall(writefile,"SerotoninUI/diagnostics.json",json) end
    end
end
function Runtime:Step(dt)
    local ready,reason=self:Ready()
    if not ready and (self:On("aim.enabled") or self:On("aim.silent") or self:On("trigger.enabled") or self:On("e.1") or self:On("misc2.0")) then
        if self.LastBlockedReason~=reason then
            self.LastBlockedReason=reason; self:Report("readiness", "Combat targeting blocked: "..tostring(reason))
        end
    elseif ready then self.LastBlockedReason=nil end
    if ready and not self:InputBlocked() then
        self:Guard("target-selection",function()
            self.Targets.Camera=self:On("aim.enabled") and self:Select("Camera") or nil
            self.Targets.Silent=self:On("aim.silent") and self:Select("Silent") or nil
        end)
        if self:On("aim.enabled") and self:Value("aim.method")=="None" then self:Report("aim-method","Aimbot is enabled but Aim Method is None. Select Camera or Mouse.") end
        if self:On("aim.silent") and not self.Hooked then self:Report("silent-unavailable",self.Status["aim.silent"] or "RIVALS silent aim hook is still loading") end
        if self:On("aim.enabled") then self:Guard("aim",function() self:Aim(dt) end) end
    else self:ClearTargets() end
    if not self:Guard("trigger",function() self:Trigger() end) then self:ResetTrigger(); self:ReleaseShot() end
    self:Guard("visuals",function() self.Visuals:Step(dt) end)
    self:Guard("client-render",function() self.Client:Render(dt) end)
    if os.clock()>=(self.NextDiagnostics or 0) then
        self.NextDiagnostics=os.clock()+5
        self:Guard("diagnostics",function() self:WriteDiagnostics() end)
    end
end
function Runtime:Destroy()
    if not self.Alive then return end
    self:ReleaseShot(); self.Alive=false
    if self.OwnsVirtualInput then pcall(function() self.VirtualInput:Destroy() end) end
    self:RestoreInputDispatcher()
    for _,c in ipairs(self.Connections) do c:Disconnect() end
    self.Detector:Destroy(); self.Visuals:Destroy(); self.Client:Destroy()
    if self.Hooked and type(getrawmetatable)=="function" then
        pcall(function() if getrawmetatable(game).__namecall==self.Hook then hookmetamethod(game,"__namecall",self.OriginalHook) end end)
    end
    self:ClearTargets(); self.UI=nil
end
Runtime.EncodeCFrame=encode; Runtime.DecodeCFrame=decode
return Runtime

end)()
local Visuals=(function()
-- ESP uses native GUI primitives and Highlights; no Drawing API dependency.
local Visuals={}; Visuals.__index=Visuals
local Players=game:GetService("Players")
local function make(class,props,parent)
    local obj=Instance.new(class); for k,v in pairs(props) do obj[k]=v end; obj.Parent=parent; return obj
end
function Visuals.new(runtime)
    local gui=make("ScreenGui",{Name="SerotoninRivalsESP",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=9999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},runtime.UI.Gui.Parent)
    -- Keep this non-interactive overlay in raw viewport pixels on devices with safe-area insets.
    pcall(function() gui.ScreenInsets=Enum.ScreenInsets.None; gui.ClipToDeviceSafeArea=false end)
    return setmetatable({Runtime=runtime,Gui=gui,Entries={},Hud={Pool={},Used=0},Dead={}},Visuals)
end
function Visuals:Primitive(e,class)
    e.Used=e.Used+1
    local obj=e.Pool[e.Used]
    if obj and obj.ClassName~=class then obj:Destroy(); obj=nil end
    if not obj then
        obj=make(class,{BorderSizePixel=0,BackgroundTransparency=1},self.Gui)
        e.Pool[e.Used]=obj
    end
    obj.Visible=true; return obj
end
function Visuals:Finish(e)
    for i=e.Used+1,#e.Pool do e.Pool[i].Visible=false end
end
function Visuals:Rect(e,x,y,w,h,color,alpha)
    if w<=0 or h<=0 then return end
    local f=self:Primitive(e,"Frame")
    f.AnchorPoint=Vector2.zero; f.Position=UDim2.fromOffset(x,y); f.Size=UDim2.fromOffset(w,h); f.Rotation=0
    f.BackgroundColor3=color; f.BackgroundTransparency=1-(alpha or 1)
    local corner=f:FindFirstChildOfClass("UICorner"); if corner then corner.CornerRadius=UDim.new() end
    local border=f:FindFirstChildOfClass("UIStroke"); if border then border:Destroy() end
end
function Visuals:Line(e,a,b,color,width,alpha)
    local delta=b-a; local length=delta.Magnitude
    if length<.01 then return end
    local f=self:Primitive(e,"Frame"); f.AnchorPoint=Vector2.new(.5,.5)
    local corner=f:FindFirstChildOfClass("UICorner"); if corner then corner.CornerRadius=UDim.new() end
    f.Position=UDim2.fromOffset((a.X+b.X)*.5,(a.Y+b.Y)*.5); f.Size=UDim2.fromOffset(length,width or 1)
    f.Rotation=math.deg(math.atan2(delta.Y,delta.X)); f.BackgroundColor3=color; f.BackgroundTransparency=1-(alpha or 1)
end
function Visuals:Text(e,value,x,y,color,size,center)
    local label=self:Primitive(e,"TextLabel")
    label.BackgroundTransparency=1; label.Text=tostring(value); label.TextColor3=color; label.Font=Enum.Font.Arial
    label.TextSize=size or 12; label.TextStrokeColor3=Color3.new(); label.TextStrokeTransparency=.2
    label.AnchorPoint=center and Vector2.new(.5,0) or Vector2.zero
    label.Position=UDim2.fromOffset(x,y); label.Size=UDim2.fromOffset(300,18)
    label.TextXAlignment=center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
end
function Visuals:Ring(e,center,radius,color,alpha,filled,shape)
    if radius<=0 then return end
    if filled and shape~="Hexagon" then
        self:Rect(e,center.X-radius,center.Y-radius,radius*2,radius*2,color,alpha*.07)
        local f=e.Pool[e.Used]
        if shape~="Square" then
            local corner=f:FindFirstChildOfClass("UICorner") or make("UICorner",{},f); corner.CornerRadius=UDim.new(1,0)
        end
    end
    local sides=shape=="Square" and 4 or shape=="Hexagon" and 6 or 64
    if shape=="Square" then
        local pts={center+Vector2.new(-radius,-radius),center+Vector2.new(radius,-radius),center+Vector2.new(radius,radius),center+Vector2.new(-radius,radius)}
        for i=1,4 do self:Line(e,pts[i],pts[i%4+1],color,1,alpha) end
    else
        for i=0,sides-1 do
            local a,b=i*math.pi*2/sides,(i+1)*math.pi*2/sides
            self:Line(e,center+Vector2.new(math.cos(a),math.sin(a))*radius,center+Vector2.new(math.cos(b),math.sin(b))*radius,color,1,alpha)
        end
    end
end
function Visuals:Entry(player,char)
    local e=self.Entries[player]
    if e and e.Character~=char then self:Remove(player); e=nil end
    if not e then e={Pool={},Used=0,Character=char}; self.Entries[player]=e end
    return e
end
function Visuals:Remove(player)
    local e=self.Entries[player]; if not e then return end
    for _,p in ipairs(e.Pool) do p:Destroy() end
    if e.Highlight then e.Highlight:Destroy() end
    if e.Trail then e.Trail:Destroy(); e.A0:Destroy(); e.A1:Destroy() end
    self.Entries[player]=nil
end
function Visuals:Hide()
    for _,e in pairs(self.Entries) do
        e.Used=0; self:Finish(e)
        if e.Highlight then e.Highlight.Enabled=false end
        if e.Trail then e.Trail.Enabled=false end
    end
end
function Visuals:Bounds(char,camera)
    local cf,size=char:GetBoundingBox()
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
        local p=camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(x*size.X*.5,y*size.Y*.5,z*size.Z*.5)))
        if p.Z<=.05 then return nil end
        minX=math.min(minX,p.X); minY=math.min(minY,p.Y); maxX=math.max(maxX,p.X); maxY=math.max(maxY,p.Y)
    end end end
    local padding=self.Runtime:Value("visual.padding",.5)*2
    return minX-padding,minY-padding,maxX+padding,maxY+padding
end
function Visuals:Animated(color,mode,phase)
    if mode=="Pulse" then return color:Lerp(Color3.new(1,1,1),(.5+.5*math.sin(os.clock()*3+phase))*.35),1 end
    if mode=="Breathe" then return color,.45+.55*(.5+.5*math.sin(os.clock()*2+phase)) end
    return color,1
end
function Visuals:Draw(player,e,camera)
    local rt=self.Runtime; local char=e.Character
    local hum=char:FindFirstChildOfClass("Humanoid")
    local root=char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    local position=root and root.Position or char:GetPivot().Position
    local phase=player and player.UserId or 0
    local distance=(camera.CFrame.Position-position).Magnitude
    if distance>rt:Value("visual.maxDistance",1000) then return end
    local alive=not hum or hum.Health>0
    local pending=rt.PendingHit
    if player and hum and pending and pending.Player==player and os.clock()<=pending.Until and hum.Health<pending.Health then
        rt.PendingHit=nil; self.HitAt=os.clock()
        if rt:On("settings.hitSound") then
            self.HitSound=self.HitSound or make("Sound",{SoundId="rbxasset://sounds/button.wav",Volume=.5},game:GetService("SoundService"))
            self.HitSound:Play()
        end
    end
    if rt:On("visual.chams") or (not alive and rt:On("visual.deadChams")) then
        if not e.Highlight then e.Highlight=make("Highlight",{DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Adornee=char},self.Gui) end
        e.Highlight.Enabled=true
        local c=rt:Color(alive and "visual.chams" or "visual.deadChams")
        e.Highlight.FillColor=c; e.Highlight.OutlineColor=c; e.Highlight.OutlineTransparency=.2
        e.Highlight.FillTransparency=1-rt:Value("visual.chamsAmount",50)/100
    end
    if not alive then return end
    if root and rt:On("visual.trails") then
        if not e.Trail then
            e.A0=make("Attachment",{Position=Vector3.new(-.5,0,0)},root); e.A1=make("Attachment",{Position=Vector3.new(.5,0,0)},root)
            e.Trail=make("Trail",{Attachment0=e.A0,Attachment1=e.A1,FaceCamera=true,MinLength=.1},root)
        end
        e.Trail.Enabled=true; e.Trail.Lifetime=rt:Value("visual.trailsAmount",2)
        e.Trail.Color=ColorSequence.new(rt:Color("visual.trails")); e.Trail.Transparency=NumberSequence.new(.2,1)
    end
    local p,onScreen=camera:WorldToViewportPoint(position)
    if not onScreen or p.Z<=0 then
        if rt:On("visual.arrows") then
            local relative=camera.CFrame:PointToObjectSpace(position)
            local angle=math.atan2(-relative.X,-relative.Z)
            local center=camera.ViewportSize*.5; local direction=Vector2.new(math.sin(angle),-math.cos(angle))
            local position=center+direction*math.min(center.X,center.Y)*.78
            local side=Vector2.new(-direction.Y,direction.X); local size=rt:Value("visual.arrowsAmount",10)
            local c=rt:Color("visual.arrows")
            self:Line(e,position+direction*size,position-direction*size+side*size*.6,c,2)
            self:Line(e,position+direction*size,position-direction*size-side*size*.6,c,2)
            self:Line(e,position-direction*size+side*size*.6,position-direction*size-side*size*.6,c,2)
        end
        return
    end
    local x1,y1,x2,y2=self:Bounds(char,camera); if not x1 then return end
    local width,height=x2-x1,y2-y1; if width<=0 or height<=0 then return end
    if rt:On("visual.boxes") then
        local c,a=self:Animated(rt:Color("visual.boxes"),rt:Value("visual.boxAnimation","Static"),phase)
        self:Line(e,Vector2.new(x1,y1),Vector2.new(x2,y1),c,1,a); self:Line(e,Vector2.new(x2,y1),Vector2.new(x2,y2),c,1,a)
        self:Line(e,Vector2.new(x2,y2),Vector2.new(x1,y2),c,1,a); self:Line(e,Vector2.new(x1,y2),Vector2.new(x1,y1),c,1,a)
    end
    if hum and rt:On("visual.health") then
        local fraction=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local mode=rt:Value("visual.healthType","Health Based")
        local c=mode=="Health Based" and Color3.fromHSV(fraction/3,1,1) or rt:Color("visual.health")
        self:Rect(e,x1-5,y1,3,height,Color3.new(),.85)
        if mode=="Gradient" then
            for i=0,15 do local t=i/16; if t<fraction then self:Rect(e,x1-4,y2-height*math.min(fraction,t+1/16),1,height*math.min(1/16,fraction-t),Color3.fromHSV(t/3,1,1)) end end
        else self:Rect(e,x1-4,y2-height*fraction,1,height*fraction,c) end
    end
    if rt:On("visual.name") then self:Text(e,player and player.DisplayName or char.Name,(x1+x2)*.5,y1-17,rt:Color("visual.name"),12,true) end
    local bottom=y2+2
    if player and rt:On("visual.weapon") then
        local item=rt:EquippedItem(rt:Fighter(player))
        local name=item and (item.Name or item.Info and item.Info.Name) or ""
        self:Text(e,name,(x1+x2)*.5,bottom,rt:Color("visual.weapon"),11,true); bottom=bottom+14
    end
    if rt:On("visual.distance") then self:Text(e,string.format("%.0f studs",distance),(x1+x2)*.5,bottom,rt:Color("visual.distance"),11,true) end
    if rt:On("visual.flags") then
        local flags={}
        if not rt:Vulnerable(player,char) then table.insert(flags,"SHIELDED") end
        if hum then
            if hum:GetState()==Enum.HumanoidStateType.Freefall then table.insert(flags,"AIR") end
            table.insert(flags,string.format("%d HP",hum.Health))
        end
        self:Text(e,table.concat(flags," · "),x2+5,y1,rt:Color("visual.flags"),11)
    end
    if player and rt:On("visual.team") then self:Text(e,"ENEMY · "..tostring(player:GetAttribute("TeamID") or "FFA"),x2+5,y1+14,rt:Color("visual.team"),11) end
    if rt:On("visual.tracers") then
        local origin=rt:Value("visual.tracerOrigin","Top")
        self:Line(e,Vector2.new(camera.ViewportSize.X*.5,origin=="Bottom" and camera.ViewportSize.Y or origin=="Center" and camera.ViewportSize.Y*.5 or 0),Vector2.new(p.X,p.Y),rt:Color("visual.tracers"),1)
    end
    local head=char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head")
    if head then
        local hp=camera:WorldToViewportPoint(head.Position)
        if hp.Z>0 and rt:On("visual.head") then self:Ring(e,Vector2.new(hp.X,hp.Y),rt:Value("visual.headAmount",4),rt:Color("visual.head"),1,true,"Circle") end
        if hp.Z>0 and rt:On("visual.look") then
            local endpoint=camera:WorldToViewportPoint(head.Position+head.CFrame.LookVector*5)
            if endpoint.Z>0 then self:Line(e,Vector2.new(hp.X,hp.Y),Vector2.new(endpoint.X,endpoint.Y),rt:Color("visual.look"),1) end
        end
    end
    if rt:On("visual.skeletons") then
        local c,a=self:Animated(rt:Color("visual.skeletons"),rt:Value("visual.skeletonAnimation","Static"),phase)
        local count=0
        for _,joint in ipairs(char:GetDescendants()) do
            if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 and joint.Part0.Name~="HumanoidRootPart" then
                local a0=camera:WorldToViewportPoint(joint.Part0.Position); local a1=camera:WorldToViewportPoint(joint.Part1.Position)
                if a0.Z>0 and a1.Z>0 then self:Line(e,Vector2.new(a0.X,a0.Y),Vector2.new(a1.X,a1.Y),c,1,a); count=count+1 end
            end
        end
        if count==0 and head then local h=camera:WorldToViewportPoint(head.Position); if h.Z>0 then self:Line(e,Vector2.new(h.X,h.Y),Vector2.new(p.X,p.Y),c,1,a) end end
    end
    if rt:On("visual.sonar") then local t=(os.clock()*.65)%1; self:Ring(e,Vector2.new(p.X,p.Y),t*rt:Value("visual.sonarAmount",100),rt:Color("visual.sonar"),1-t,false,"Circle") end
    if rt:On("visual.sound") then
        local playing=false
        for _,sound in ipairs(char:GetDescendants()) do if sound:IsA("Sound") and sound.IsPlaying and sound.Volume>0 then playing=true; break end end
        if playing then self:Ring(e,Vector2.new(p.X,p.Y),math.min(80,rt:Value("visual.soundAmount",100))*(.4+.6*((os.clock()*2)%1)),rt:Color("visual.sound"),.8,false,"Circle") end
    end
end
function Visuals:HudStep(camera)
    local rt=self.Runtime; local e=self.Hud; e.Used=0
    local pointer=rt:Pointer()
    if rt:On("aim.drawFov") then
        local radius=rt:Value("aim.fov",150)
        if rt:On("aim.smartFov") and rt:Value("aim.fovType")=="Dynamic" then radius=radius*70/math.max(camera.FieldOfView,1) end
        self:Ring(e,pointer,radius,rt:Color("aim.drawFov"),.8,rt:On("aim.fillFov"),rt:Value("aim.fovShape","Circle"))
        if rt:On("aim.silent") then self:Ring(e,pointer,rt:Value("aim.silentFov",150),rt.UI.Accent,.6,false,rt:Value("aim.fovShape","Circle")) end
    end
    local target=rt.Targets.Camera or rt.Targets.Silent
    if target and rt:On("aim.snaplines") then self:Line(e,pointer,target.Screen,rt.UI.Accent,1) end
    if target and rt:On("aim.targetInfo") then
        local name=target.Player and target.Player.DisplayName or target.Character.Name
        local health=target.Humanoid and string.format(" · %d HP",target.Humanoid.Health) or ""
        self:Text(e,name..string.format(" · %.0f studs",target.Distance)..health,pointer.X,pointer.Y+35,Color3.new(1,1,1),12,true)
    end
    if rt:On("cross.enabled") then
        local center=camera.ViewportSize*.5; local gap=rt:Value("cross.gap",4); local size=rt:Value("cross.size",8); local color=rt:Value("cross.color",Color3.new(1,1,1))
        for _,dir in ipairs({Vector2.new(1,0),Vector2.new(-1,0),Vector2.new(0,1),Vector2.new(0,-1)}) do self:Line(e,center+dir*gap,center+dir*(gap+size),color,1) end
    end
    if rt:On("settings.hitmarker") and self.HitAt and os.clock()-self.HitAt<.25 then
        local center=camera.ViewportSize*.5
        for _,dir in ipairs({Vector2.new(1,1),Vector2.new(-1,1),Vector2.new(1,-1),Vector2.new(-1,-1)}) do
            self:Line(e,center+dir*4,center+dir*9,Color3.new(1,1,1),1,1-(os.clock()-self.HitAt)/.25)
        end
    end
    if rt:On("settings.toggle0") then self:Text(e,"Serotonin · RIVALS",14,14,rt.UI.Accent,12) end
    if rt:On("settings.toggle1") then
        local y=40
        for _,bind in ipairs(rt.UI._binds or {}) do if bind.Value~=Enum.KeyCode.Unknown then self:Text(e,bind.Flag.." ["..bind.Value.Name.."]",14,y,Color3.new(1,1,1),11); y=y+14 end end
    end
    self:Finish(e)
end
function Visuals:Step()
    local camera=workspace.CurrentCamera
    self:Hide()
    if not camera then
        self.Hud.Used=0; self:Finish(self.Hud)
        return
    end
    self:HudStep(camera)
    local seen={}
    for _,target in ipairs(self.Runtime:MatchTargets()) do
        local key=target.Player or target.Character
        seen[key]=true
        local entry=self:Entry(key,target.Character)
        self:Draw(target.Player,entry,camera)
        self:Finish(entry)
    end
    for key in pairs(self.Entries) do
        if not seen[key] then self:Remove(key) end
    end
end
function Visuals:Destroy()
    local players={}; for p in pairs(self.Entries) do table.insert(players,p) end
    for _,p in ipairs(players) do self:Remove(p) end
    self.Gui:Destroy()
    if self.HitSound then self.HitSound:Destroy() end
end
return Visuals

end)()
local Client=(function()
-- Local movement, camera, environment, waypoint and utility bindings.
local Client={}; Client.__index=Client
local Lighting=game:GetService("Lighting")
local Input=game:GetService("UserInputService")
local Players=game:GetService("Players")
local Local=Players.LocalPlayer
local function object(class,props,parent)
    local v=Instance.new(class); for k,x in pairs(props or {}) do v[k]=x end; v.Parent=parent; return v
end
function Client.new(runtime)
    local self=setmetatable({Runtime=runtime,Leases={},Points={},Last={},Time=0,Markers={}},Client)
    self.Folder=object("Folder",{Name="SerotoninWaypoints"},workspace)
    return self
end
function Client:Lease(obj,property,enabled,value)
    if not obj then return end
    local saved=self.Leases[obj]
    if enabled then
        if not saved then saved={}; self.Leases[obj]=saved end
        if not saved[property] then local ok,previous=pcall(function() return obj[property] end); if not ok then return false end; saved[property]={previous} end
        local ok=pcall(function() obj[property]=value end); return ok
    elseif saved and saved[property] then
        pcall(function() obj[property]=saved[property][1] end); saved[property]=nil
    end
end
function Client:Once(flag,callback)
    local value=self.Runtime:On(flag)
    if value~=self.Last[flag] then self.Last[flag]=value; callback(value) end
end
function Client:ShowManager()
    local rt=self.Runtime; local _,root=rt:Character(); local list={}
    for _,p in ipairs(self.Points) do table.insert(list,{name=p.name,x=p.x,y=p.y,z=p.z,death=p.death==true}) end
    if root then table.insert(list,{name="New waypoint",x=math.round(root.Position.X),y=math.round(root.Position.Y),z=math.round(root.Position.Z)}) end
    local http=game:GetService("HttpService")
    rt.UI:TextDialog("Waypoint Manager · edit names / coordinates; delete rows to remove",http:JSONEncode(list),function(text)
        local ok,value=pcall(http.JSONDecode,http,text)
        if not ok then rt.UI:Notify("Invalid waypoint JSON"); return end
        local valid,err=self:SetPoints(value)
        rt.UI:Notify(valid and "Waypoints updated" or err)
    end)
end
function Client:SetPoints(points)
    if type(points)~="table" or #points>300 then return false,"Expected at most 300 waypoints" end
    local result={}
    for _,p in ipairs(points) do
        if type(p)~="table" or type(p.name)~="string" or type(p.x)~="number" or type(p.y)~="number" or type(p.z)~="number"
            or p.x~=p.x or p.y~=p.y or p.z~=p.z or math.max(math.abs(p.x),math.abs(p.y),math.abs(p.z))>1e7 then return false,"Invalid waypoint entry" end
        table.insert(result,{name=p.name:sub(1,80),x=p.x,y=p.y,z=p.z,death=p.death==true})
    end
    self.Points=result; self:RefreshMarkers(); return true
end
function Client:RefreshMarkers()
    for _,v in ipairs(self.Markers) do v:Destroy() end; self.Markers={}
    local rt=self.Runtime
    for _,p in ipairs(self.Points) do
        local part=object("Part",{Name="Waypoint",Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Transparency=1,
            Size=Vector3.new(.1,.1,.1),Position=Vector3.new(p.x,p.y,p.z)},self.Folder)
        local gui=object("BillboardGui",{AlwaysOnTop=true,Size=UDim2.fromOffset(200,50),Adornee=part},part)
        local label=object("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.Arial,TextSize=12,
            TextStrokeTransparency=.3,TextColor3=rt:Color("waypoints.markers"),Text=p.name},gui)
        local a=object("Attachment",{},part); local b=object("Attachment",{Position=Vector3.new(0,rt:Value("waypoints.beamHeight",50),0)},part)
        local beam=object("Beam",{Attachment0=a,Attachment1=b,FaceCamera=true,Width0=1,Width1=1,Color=ColorSequence.new(rt:Color("waypoints.markers"))},part)
        table.insert(self.Markers,part); self.Markers[#self.Markers]:SetAttribute("PointIndex",#self.Markers)
    end
end
function Client:StepWaypoints()
    local rt=self.Runtime; local _,root=rt:Character()
    for i,part in ipairs(self.Markers) do
        local point=self.Points[i]; local gui=part:FindFirstChildOfClass("BillboardGui"); local label=gui:FindFirstChildOfClass("TextLabel")
        local distance=root and (root.Position-part.Position).Magnitude or math.huge
        local show=rt:On("waypoints.markers") and distance<=rt:Value("waypoints.distance",1000) and (not point.death or rt:On("waypoints.deathMarkers"))
        gui.Enabled=show; label.Text=point.name..string.format("\n%.0f studs",distance)
        label.TextColor3=point.death and Color3.fromRGB(240,80,80) or rt:Color("waypoints.markers")
        local icon=rt:On("waypoints.icon") and "◆ " or ""
        label.Text=icon..label.Text; label.TextSize=rt:On("waypoints.icon") and math.clamp(rt:Value("waypoints.iconSize",24)*.5,8,32) or 12
        local location=rt:Value("waypoints.location","Bottom")
        gui.StudsOffset=Vector3.new(0,location=="Top" and 3 or location=="Center" and 0 or -2,0)
        local beam=part:FindFirstChildOfClass("Beam"); beam.Enabled=show and rt:On("waypoints.beams")
        beam.Color=ColorSequence.new(label.TextColor3)
        beam.Attachment1.Position=Vector3.new(0,rt:Value("waypoints.beamHeight",50),0)
        beam.Width0=rt:Value("waypoints.beamWidth",15)*.1; beam.Width1=beam.Width0
    end
end
function Client:Environment()
    local rt=self.Runtime
    local props={{"ambient","Ambient",rt:Color("lighting.ambient")},{"outdoor","OutdoorAmbient",rt:Color("lighting.outdoor")},
        {"shiftTop","ColorShift_Top",rt:Color("lighting.shiftTop")},{"shiftBottom","ColorShift_Bottom",rt:Color("lighting.shiftBottom")},
        {"exposure","ExposureCompensation",.5},{"brightness","Brightness",3},{"clock","ClockTime",14},{"shadow","ShadowSoftness",1},
        {"fogStart","FogStart",1e5},{"fogEnd","FogEnd",1e6},{"fogColor","FogColor",rt:Color("lighting.fogColor")},
        {"diffuse","EnvironmentDiffuseScale",1},{"specular","EnvironmentSpecularScale",1}}
    for _,v in ipairs(props) do self:Lease(Lighting,v[2],rt:On("lighting."..v[1]),v[3]) end
    self:Once("lighting.technology",function(enabled)
        if type(sethiddenproperty)~="function" then if enabled then rt:Unsupported("lighting.technology","Lighting Technology requires sethiddenproperty") end; return end
        if enabled then
            pcall(function() self.OriginalTechnology=Lighting.Technology end)
            local ok,err=pcall(sethiddenproperty,Lighting,"Technology",Enum.Technology.Future)
            if not ok then rt:Unsupported("lighting.technology",tostring(err)) end
        elseif self.OriginalTechnology then pcall(sethiddenproperty,Lighting,"Technology",self.OriginalTechnology); self.OriginalTechnology=nil end
    end)
    -- These operations require server authority or host hooks absent from the supplied excerpts.
    for flag,reason in pairs({["unsafe.0"]="Network tick rate is server controlled",["unsafe.2"]="Freezing other players requires server authority",
        ["unsafe.3"]="The supplied snippets do not include the desync implementation",["unsafe.6"]="Network ping manipulation is unavailable",
        ["settings.toggle2"]="This executor has no verified capture-exclusion API"}) do rt:Unsupported(flag,reason) end
    local gpu=rt:Value("settings.gpu","Default")
    if gpu~="Default" then rt.UI.Controls["settings.gpu"]:Set("Default",true); rt:Report("gpu","GPU scheduling priority is controlled by the operating system") end
    self:Once("settings.toggle3",function(enabled)
        if type(setfpscap)~="function" then if enabled then rt:Unsupported("settings.toggle3","Uncap Overlay requires setfpscap") end; return end
        if enabled then self.FpsCap=type(getfpscap)=="function" and getfpscap() or 60; pcall(setfpscap,1000)
        elseif self.FpsCap then pcall(setfpscap,self.FpsCap); self.FpsCap=nil end
    end)
end
function Client:StopUnderground(restore)
    local state=self.Underground
    if not state then return end
    state.Hold:Destroy()
    if restore and state.Root.Parent then
        local root=state.Root
        root.CFrame=root.CFrame+Vector3.new(0,state.SurfaceY-root.Position.Y,0)
        root.AssemblyLinearVelocity=Vector3.zero
    end
    self.Underground=nil
end
function Client:UpdateUnderground(root,enabled)
    if self.Underground and (not enabled or self.Underground.Root~=root) then
        self:StopUnderground(self.Underground.Root==root)
    end
    if not enabled or not root then return end
    if not self.Underground then
        local surfaceY=root.Position.Y
        root.CFrame=root.CFrame-Vector3.new(0,8,0)
        root.AssemblyLinearVelocity=Vector3.zero
        local hold=object("BodyPosition",{Name="SerotoninUnderground",MaxForce=Vector3.new(0,math.huge,0),
            P=50000,D=1500,Position=root.Position},root)
        self.Underground={Root=root,SurfaceY=surfaceY,Hold=hold}
    end
end
function Client:Orbit(root)
    local rt=self.Runtime
    if not (rt:On("e.1") or rt:On("misc2.0")) or not rt:Ready() or rt:InputBlocked() then
        self.OrbitCharacter=nil
        return
    end
    local nearestDistance=math.huge
    local nearest,center=nil,nil
    for _,target in ipairs(rt:MatchTargets()) do
        local model=target.Character
        local hum=model:FindFirstChildOfClass("Humanoid")
        if (hum and hum.Health>0) or (not hum and not target.Player) then
            local targetRoot=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            local position=targetRoot and targetRoot.Position or model:GetPivot().Position
            if model==self.OrbitCharacter then
                nearest,center=model,position
                break
            end
            local distance=(root.Position-position).Magnitude
            if distance<nearestDistance then
                nearest,center,nearestDistance=model,position,distance
            end
        end
    end
    self.OrbitCharacter=nearest
    if center then
        local position=center+Vector3.new(math.cos(self.Time*2)*6,0,math.sin(self.Time*2)*6)
        root.CFrame=CFrame.lookAt(position,center)
    end
end
function Client:Step(dt)
    local rt=self.Runtime; self.Time=self.Time+dt
    local hum,root,char=rt:Character()
    if char~=self.Character then
        self.OrbitCharacter=nil
        if self.Character then
            for obj,properties in pairs(self.Leases) do
                if obj==self.Character or obj:IsDescendantOf(self.Character) then
                    for property,saved in pairs(properties) do
                        pcall(function() obj[property]=saved[1] end)
                    end
                    self.Leases[obj]=nil
                end
            end
        end
        if self.FlightVelocity then
            self.FlightVelocity:Destroy(); self.FlightAttachment:Destroy()
            self.FlightVelocity=nil; self.FlightAttachment=nil
        end
        self:StopUnderground(false)
        if self.Died then self.Died:Disconnect(); self.Died=nil end
        self.Character=char
        if hum then self.Died=hum.Died:Connect(function()
            if rt:On("waypoints.death") and root then
                table.insert(self.Points,{name="Death "..os.date("%H:%M:%S"),x=root.Position.X,y=root.Position.Y,z=root.Position.Z,death=true}); self:RefreshMarkers()
            end
        end) end
    end
    self:Environment()
    self:Once("settings.explorer",function(value)
        if not value then for _,box in ipairs(self.SelectionBoxes or {}) do box:Destroy() end; self.SelectionBoxes={} end
    end)
    if rt:On("settings.explorer") and os.clock()>=(self.NextSelection or 0) then
        self.NextSelection=os.clock()+rt:Value("settings.explorerRate",5)
        local ok,selected=pcall(function() return game:GetService("Selection"):Get() end)
        for _,box in ipairs(self.SelectionBoxes or {}) do box:Destroy() end; self.SelectionBoxes={}
        if ok then for _,item in ipairs(selected) do if item:IsA("BasePart") and item:IsDescendantOf(workspace) then
            table.insert(self.SelectionBoxes,object("SelectionBox",{Adornee=item,Color3=rt.UI.Accent,LineThickness=.02},self.Folder))
        end end else rt:Unsupported("settings.explorer","This client does not expose Explorer selection") end
    end
    self:Once("waypoints.manager",function(value)
        if value then self:ShowManager(); rt.UI.Controls["waypoints.manager"]:Set(false,true); self.Last["waypoints.manager"]=false end
    end)
    if self.Time>(self.NextMarkers or 0) then self.NextMarkers=self.Time+.15; self:StepWaypoints() end
    if not hum or not root or hum.Health<=0 or not char:IsDescendantOf(workspace) then
        self.OrbitCharacter=nil; self:StopUnderground(false); return
    end
    self:UpdateUnderground(root,rt:On("misc3.0"))
    self:Lease(hum,"WalkSpeed",rt:On("e.4"),32)
    self:Lease(hum,"UseJumpPower",rt:On("e.5"),true); self:Lease(hum,"JumpPower",rt:On("e.5"),100)
    self:Lease(hum,"HipHeight",rt:On("e.6"),5)
    self:Lease(hum,"PlatformStand",rt:On("misc2.1"),true)
    self:Lease(workspace,"Gravity",rt:On("misc.2"),rt:Value("misc.gravity",196))
    if rt:On("e.7") and hum.FloorMaterial~=Enum.Material.Air and hum.MoveDirection.Magnitude>.1 then hum.Jump=true end
    local fly=rt:On("e.0"); local jet=rt:On("misc2.5")
    if fly or jet then
        if not self.FlightAttachment or self.FlightAttachment.Parent~=root then
            if self.FlightVelocity then self.FlightVelocity:Destroy(); self.FlightAttachment:Destroy() end
            self.FlightAttachment=object("Attachment",{},root)
            self.FlightVelocity=object("LinearVelocity",{Attachment0=self.FlightAttachment,MaxForce=math.huge,RelativeTo=Enum.ActuatorRelativeTo.World},root)
        end
        self.FlightVelocity.Enabled=true
        local camera=workspace.CurrentCamera; local up=0
        if not rt:InputBlocked() then up=(Input:IsKeyDown(Enum.KeyCode.Space) and 1 or 0)-(Input:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0) end
        self.FlightVelocity.VectorVelocity=fly and (hum.MoveDirection*50+Vector3.new(0,up*50,0)) or Vector3.new(root.AssemblyLinearVelocity.X,rt:Value("misc.jetpack",10),root.AssemblyLinearVelocity.Z)
    elseif self.FlightVelocity then self.FlightVelocity.Enabled=false end
    local noclip=rt:On("misc2.3") or fly or rt:On("misc3.0")
    for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then self:Lease(part,"CanCollide",noclip,false) end end
    if rt:On("e.3") and not fly then root.CFrame=root.CFrame+hum.MoveDirection*24*dt end
    if rt:On("e.2") and hum.MoveDirection.Magnitude>.1 then
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
        if workspace:Raycast(root.Position,hum.MoveDirection*2,params) then root.AssemblyLinearVelocity=Vector3.new(0,30,0) end
    end
    if rt:On("misc3.1") and root.AssemblyLinearVelocity.Y<rt:Value("misc.fall",-10) then local v=root.AssemblyLinearVelocity; root.AssemblyLinearVelocity=Vector3.new(v.X,rt:Value("misc.fall",-10),v.Z) end
    if rt:On("misc4.0") and hum.FloorMaterial==Enum.Material.Air then local v=root.AssemblyLinearVelocity; root.AssemblyLinearVelocity=Vector3.new(v.X,-200,v.Z) end
    if rt:On("misc4.1") and hum.MoveDirection.Magnitude<.1 then root.AssemblyLinearVelocity=Vector3.new(0,root.AssemblyLinearVelocity.Y,0) end
    if rt:On("unsafe.5") then local v=root.AssemblyLinearVelocity; root.AssemblyLinearVelocity=hum.MoveDirection*hum.WalkSpeed+Vector3.new(0,v.Y,0) end
    self:Lease(hum,"AutoRotate",rt:On("misc2.2"),false)
    if rt:On("misc2.2") then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,self.Time*8,0) end
    self:Orbit(root)
    self:Once("misc.1",function(value)
        if value and workspace.CurrentCamera then root.CFrame=CFrame.new(workspace.CurrentCamera.CFrame.Position); rt.UI.Controls["misc.1"]:Set(false,true); self.Last["misc.1"]=false end
    end)
    self:Once("unsafe.1",function(value)
        if value then
            self.BuildTools={}
            for _,kind in ipairs({Enum.BinType.Clone,Enum.BinType.Hammer,Enum.BinType.Grab}) do
                local ok,tool=pcall(object,"HopperBin",{BinType=kind},Local:FindFirstChildOfClass("Backpack")); if ok then table.insert(self.BuildTools,tool) end
            end
        else for _,tool in ipairs(self.BuildTools or {}) do tool:Destroy() end; self.BuildTools=nil end
    end)
    self:Once("unsafe.4",function(value)
        if self.Shadow then self.Shadow:Destroy(); self.Shadow=nil end
        if value then
            local previous=char.Archivable; char.Archivable=true; local ok,copy=pcall(char.Clone,char); char.Archivable=previous
            if ok and copy then
                for _,v in ipairs(copy:GetDescendants()) do if v:IsA("LuaSourceContainer") then v:Destroy() elseif v:IsA("BasePart") then v.CanCollide=false; v.Anchored=true; v.Transparency=math.max(.5,v.Transparency) end end
                copy.Parent=self.Folder; self.Shadow=copy
            end
        end
    end)
end
function Client:Render(dt)
    local rt=self.Runtime; local camera=workspace.CurrentCamera; if not camera then return end
    if self.Camera~=camera then
        self.Camera=camera; self.CameraBase={Fov=camera.FieldOfView,Type=camera.CameraType,Subject=camera.CameraSubject}
        self.BeforeFreecam=nil
    end
    self:Lease(camera,"CameraType",rt:On("camera.enabled"),Enum.CameraType[rt:Value("camera.type","Fixed")])
    local modify=rt:On("camera.fovEnabled") or rt:On("camera.zoomEnabled")
    local fov=self.CameraBase.Fov
    if rt:On("camera.fovEnabled") then fov=fov*rt:Value("camera.fov",2) end
    if rt:On("camera.zoomEnabled") then fov=fov/math.max(.1,rt:Value("camera.zoom",2)) end
    self:Lease(camera,"FieldOfView",modify,math.clamp(fov,1,120))
    self:Lease(Local,"CameraMaxZoomDistance",rt:On("camera.distanceEnabled") or rt:On("camera.third"),rt:On("camera.distanceEnabled") and rt:Value("camera.distance",40) or math.max(Local.CameraMaxZoomDistance,6))
    self:Lease(Local,"CameraMode",rt:On("camera.third"),Enum.CameraMode.Classic)
    self:Lease(Local,"CameraMinZoomDistance",rt:On("camera.third"),6)
    if rt:On("camera.third") then
        local base=camera.CFrame
        if self.LastThirdCFrame and base==self.LastThirdCFrame then base=base*CFrame.new(0,0,-6) end
        camera.CFrame=base*CFrame.new(0,0,6); self.LastThirdCFrame=camera.CFrame
    elseif self.LastThirdCFrame then
        if camera.CFrame==self.LastThirdCFrame then camera.CFrame=camera.CFrame*CFrame.new(0,0,-6) end
        self.LastThirdCFrame=nil
    end
    local free=rt:On("misc.0")
    if free then
        if not self.BeforeFreecam then self.BeforeFreecam={Type=camera.CameraType,Subject=camera.CameraSubject}; self.FreePosition=camera.CFrame.Position; local p,y=camera.CFrame:ToOrientation(); self.FreePitch=p; self.FreeYaw=y end
        camera.CameraType=Enum.CameraType.Scriptable
        if not rt:InputBlocked() then
            local delta=Input:GetMouseDelta(); self.FreePitch=math.clamp(self.FreePitch-delta.Y*.003,-1.5,1.5); self.FreeYaw=self.FreeYaw-delta.X*.003
            local cf=CFrame.fromOrientation(self.FreePitch,self.FreeYaw,0)
            local function down(key) return Input:IsKeyDown(key) and 1 or 0 end
            local move=Vector3.new(down(Enum.KeyCode.D)-down(Enum.KeyCode.A),down(Enum.KeyCode.E)-down(Enum.KeyCode.Q),down(Enum.KeyCode.S)-down(Enum.KeyCode.W))
            self.FreePosition=self.FreePosition+cf:VectorToWorldSpace(move)*dt*(Input:IsKeyDown(Enum.KeyCode.LeftShift) and 70 or 25)
        end
        camera.CFrame=CFrame.new(self.FreePosition)*CFrame.fromOrientation(self.FreePitch,self.FreeYaw,0)
    elseif self.BeforeFreecam then camera.CameraType=self.BeforeFreecam.Type; camera.CameraSubject=self.BeforeFreecam.Subject; self.BeforeFreecam=nil end
end
function Client:Destroy()
    self:StopUnderground(true)
    if self.Died then self.Died:Disconnect() end
    for obj,props in pairs(self.Leases) do for property,saved in pairs(props) do pcall(function() obj[property]=saved[1] end) end end
    if self.FlightVelocity then self.FlightVelocity:Destroy(); self.FlightAttachment:Destroy() end
    if self.BuildTools then for _,tool in ipairs(self.BuildTools) do tool:Destroy() end end
    if self.BeforeFreecam and self.Camera then pcall(function() self.Camera.CameraType=self.BeforeFreecam.Type; self.Camera.CameraSubject=self.BeforeFreecam.Subject end) end
    if self.OriginalTechnology and type(sethiddenproperty)=="function" then pcall(sethiddenproperty,Lighting,"Technology",self.OriginalTechnology) end
    if self.FpsCap and type(setfpscap)=="function" then pcall(setfpscap,self.FpsCap) end
    self.Folder:Destroy()
end
return Client

end)()
local Http = game:GetService("HttpService")
local teal=Color3.fromRGB(27,185,167)
local white=Color3.fromRGB(225,226,226)
local env=(getgenv and getgenv()) or _G
if env.SerotoninWindow then pcall(function() env.SerotoninWindow:Destroy() end) end
local guiParent
if type(gethui)=="function" then local ok,result=pcall(gethui); if ok then guiParent=result end end
if not guiParent then
    local ok,result=pcall(function()
        local probe=Instance.new("Folder"); probe.Name="SerotoninParentCheck"; probe.Parent=game:GetService("CoreGui"); probe:Destroy()
        return game:GetService("CoreGui")
    end)
    if ok then guiParent=result end
end
local ui=Library.new({Title="Serotonin",Parent=guiParent,ToggleKey=Enum.KeyCode.Insert})
env.SerotoninWindow=ui
local runtime
local folder="SerotoninUI"
local path=folder.."/configs.json"
local canFiles=type(readfile)=="function" and type(writefile)=="function" and type(makefolder)=="function"
if canFiles then pcall(function() if type(isfolder)~="function" or not isfolder(folder) then makefolder(folder) end end) end
local store=ConfigStore.new(Http,canFiles and function() return readfile(path) end or nil,canFiles and function(raw) writefile(path,raw) end or nil)
ui.ConfigStore=store
function ui:SaveNamedConfig(name) return store:Save(name,self:ExportConfig()) end
function ui:LoadNamedConfig(name) local json=store.Data.configs[name]; if not json then return false,"Select a config" end; return self:LoadConfig(json) end
function ui:DeleteNamedConfig(name) return store:Delete(name) end
local function resultNotice(ok,err,success) ui:Notify(ok and success or tostring(err)) end
local function openFolder()
    if type(openfolder)=="function" then local ok=pcall(openfolder,folder); if ok then return end end
    ui:Notify("Folder: your executor workspace / "..folder)
end
local aim=ui:AddTab("Aimbot")
local visuals=ui:AddTab("Visuals")
local lighting=ui:AddTab("Lighting")
local exploits=ui:AddTab("Exploits")
local waypoints=ui:AddTab("Waypoints")
local settings=ui:AddTab("Settings")
local configs=ui:AddTab("Configs")
local function toggle(s,label,flag,default,extra)
    local o={Text=label,Flag=flag,Default=default==true}
    for k,v in pairs(extra or {}) do o[k]=v end
    return s:Toggle(o)
end
local function slider(s,label,flag,min,max,default,step)
    return s:Slider({Text=label,Flag=flag,Min=min,Max=max,Default=default,Step=step or 1})
end
local function dropdown(s,label,flag,options,default,multi)
    return s:Dropdown({Text=label,Flag=flag,Options=options,Default=default,Multi=multi})
end
-- Existing controls feed the attached RIVALS runtime; no extra toggles.
local a=aim:AddSection("Aimbot",1)
toggle(a,"Enabled","aim.enabled",false,{Keybind=Enum.KeyCode.Unknown})
toggle(a,"Silent Aim","aim.silent",false,{Keybind=Enum.KeyCode.Unknown})
slider(a,"Silent Aim FOV","aim.silentFov",0,1000,150,.01)
slider(a,"Silent Aim Hitchance","aim.silentHitchance",0,100,100)
dropdown(a,"Aim Method","aim.method",{"None","Camera","Mouse"},"Camera")
dropdown(a,"Aim Style","aim.style",{"Spring","Linear","Smooth"},"Spring")
dropdown(a,"Targeting Mode","aim.targeting",{"Closest to Crosshair","Closest to Player","Lowest Health"},"Closest to Crosshair")
dropdown(a,"Target Hitboxes","aim.hitboxes",{"Head","Torso","Arms","Legs"},{},true)
dropdown(a,"Checks","aim.checks",{"Team","Alive","Visible","Forcefield"},{},true)
toggle(a,"Sticky Aim","aim.sticky")
slider(a,"Target Switch Delay (ms)","aim.switchDelay",0,1000,0,.01)
slider(a,"Smoothing","aim.smoothing",0,100,75,.01)
slider(a,"Speed Multiplier","aim.speed",0,5,1,.01)
slider(a,"Multipoint Scale","aim.multipoint",0,1,1,.01)
toggle(a,"Offset","aim.offset")
toggle(a,"Prediction","aim.prediction")
slider(a,"Max Distance","aim.distance",0,6000,1000,.01)
toggle(a,"Snaplines","aim.snaplines")
toggle(a,"Show Target Info","aim.targetInfo")
slider(a,"Field of View","aim.fov",0,1000,150,.01)
toggle(a,"Smart FOV","aim.smartFov",true)
toggle(a,"Draw FOV","aim.drawFov",true,{Color=white})
dropdown(a,"FOV Shape","aim.fovShape",{"Circle","Square","Hexagon"},"Circle")
toggle(a,"Fill FOV","aim.fillFov",true,{Color=teal})
dropdown(a,"FOV Type","aim.fovType",{"Static","Dynamic"},"Static")
local t=aim:AddSection("Triggerbot",2)
toggle(t,"Enabled","trigger.enabled",false,{Keybind=Enum.KeyCode.Unknown})
slider(t,"Delay","trigger.delay",0,1000,75)
slider(t,"Click Duration (ms)","trigger.duration",0,1000,50)
slider(t,"Hitchance","trigger.hitchance",0,100,100)
slider(t,"Max Distance","trigger.distance",0,6000,1000,.01)
toggle(t,"Prediction","trigger.prediction")
dropdown(t,"Hitboxes","trigger.hitboxes",{"Head","Torso","Arms","Legs"},{},true)
dropdown(t,"Checks","trigger.checks",{"Team","Alive","Visible","Forcefield"},{},true)

ui:AddPreview()
local p=ui.PreviewParts
local v=visuals:AddSection("Visuals",1)
toggle(v,"Boxes","visual.boxes",true,{Color=teal,Callback=function(x) p.Outline.Enabled=x end,
    ColorCallback=function(x) p.Outline.Color=x; p.Tint.BackgroundColor3=x end})
slider(v,"Box Padding","visual.padding",0,3,.5,.01).Callback=function() ui.FitPreviewCamera() end
dropdown(v,"Box Animation Mode","visual.boxAnimation",{"Static","Pulse","Breathe"},"Static")
toggle(v,"Skeletons","visual.skeletons",true,{Color=white})
dropdown(v,"Skeleton Animation Mode","visual.skeletonAnimation",{"Static","Pulse","Breathe"},"Static")
toggle(v,"Health","visual.health",true,{Color=Color3.fromRGB(50,236,65),Callback=function(x) p.Health.Visible=x end,
    ColorCallback=function(x) p.Health.BackgroundColor3=x end})
dropdown(v,"Health Bar Type","visual.healthType",{"Health Based","Static","Gradient"},"Health Based")
toggle(v,"Name","visual.name",false,{Color=white,Callback=function(x) p.Name.Visible=x end,ColorCallback=function(x) p.Name.TextColor3=x end})
toggle(v,"Tracers","visual.tracers",true,{Color=Color3.fromRGB(68,198,202),Callback=function(x) p.Tracer.Visible=x end,
    ColorCallback=function(x) p.Tracer.BackgroundColor3=x end})
dropdown(v,"Tracer Origin","visual.tracerOrigin",{"Top","Center","Bottom"},"Top")
toggle(v,"Weapon","visual.weapon",false,{Color=white})
toggle(v,"Distance","visual.distance",false,{Color=white,Callback=function(x) p.Distance.Visible=x end,
    ColorCallback=function(x) p.Distance.TextColor3=x end})
toggle(v,"Flags","visual.flags",false,{Color=white})
slider(v,"Max Distance","visual.maxDistance",0,6000,1000)
local vc=visuals:AddSection("Visuals Continued",2)
for _,entry in ipairs({{"Sonar","sonar",teal},{"Sound ESP","sound",Color3.fromRGB(88,199,202)},
    {"Team Flag","team",white},{"Look Tracer","look",Color3.fromRGB(88,199,202)},
    {"Head Dot","head",Color3.fromRGB(255,54,54)},{"OOF Arrows","arrows",teal},
    {"Player Trails","trails",teal},{"Chams","chams",white},{"Dead Chams","deadChams",white}}) do
    toggle(vc,entry[1],"visual."..entry[2],false,{Color=entry[3]})
end

ui:BindVisibility("visual.boxes",{ui.Controls["visual.padding"],ui.Controls["visual.boxAnimation"]})
ui:BindVisibility("visual.skeletons",{ui.Controls["visual.skeletonAnimation"]})
ui:BindVisibility("visual.health",{ui.Controls["visual.healthType"]})
ui:BindVisibility("visual.tracers",{ui.Controls["visual.tracerOrigin"]})
for _,item in ipairs({{"sonar","Sonar Radius",0,500,100},{"sound","Sound Radius",0,500,100},{"head","Head Dot Size",1,20,4},{"arrows","Arrow Size",1,30,10},{"trails","Trail Lifetime",0,10,2},{"chams","Chams Opacity",0,100,50}}) do
    local control=slider(vc,item[2],"visual."..item[1].."Amount",item[3],item[4],item[5])
    ui:BindVisibility("visual."..item[1],{control})
end

local vp=visuals:AddSection("Preview",2)
toggle(vp,"Show ESP Preview","visual.preview",true,{Callback=function(x) ui:SetPreviewEnabled(x) end})
slider(vp,"Preview Opacity","visual.previewOpacity",0,100,18)
ui.Controls["visual.previewOpacity"].Callback=function(x) p.Tint.BackgroundTransparency=1-x/100 end
p.Name.Visible=false; p.Distance.Visible=false

local l=lighting:AddSection("Lighting",1)
for _,entry in ipairs({{"Ambient Light","ambient",true},{"OutdoorAmbient Light","outdoor",true},
    {"Shift Top","shiftTop",true},{"Shift Bottom","shiftBottom",true},{"Lighting Technology","technology"},
    {"Exposure","exposure"},{"Brightness","brightness"},{"ClockTime","clock"},{"Shadow Softness","shadow"},
    {"Fog Start","fogStart"},{"Fog End","fogEnd"},{"Fog Color","fogColor",true},
    {"Diffuse Scale","diffuse"},{"Specular Scale","specular"}}) do
    toggle(l,entry[1],"lighting."..entry[2],false,entry[3] and {Color=white} or nil)
end
local lm=lighting:AddSection("Main",2)
dropdown(lm,"Category","lighting.category",{"Camera","Environment","Atmosphere"},"Camera")
local cam=lighting:AddSection("Camera",2)
toggle(cam,"Camera Type","camera.enabled")
dropdown(cam,"Camera Type Value","camera.type",{"Fixed","Custom","Follow","Scriptable"},"Fixed")
toggle(cam,"Third Person","camera.third",false,{Keybind=Enum.KeyCode.Unknown})
toggle(cam,"Modify Fov","camera.fovEnabled")
slider(cam,"Modify Fov Amount","camera.fov",0,2,2,.01)
toggle(cam,"Zoom","camera.zoomEnabled",false,{Keybind=Enum.KeyCode.Unknown})
slider(cam,"Zoom Amount","camera.zoom",0,2,2,.01)
toggle(cam,"Camera MaxDistance","camera.distanceEnabled")
slider(cam,"Camera MaxDistance Amount","camera.distance",0,350,40,.01)
ui.Controls["lighting.category"].Callback=function(value)
    cam.Body.Parent.Visible=value=="Camera"
end

local e=exploits:AddSection("Main",1)
toggle(e,"Fly","e.0",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Orbit Target","e.1",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Spider","e.2",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Speed","e.3",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Walkspeed","e.4",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Jumppower","e.5",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Hipheight","e.6",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Bunnyhop","e.7",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Infinite Jump","e.8",false,{Keybind=Enum.KeyCode.Unknown})
toggle(e,"Anti Afk","e.9",false,{Keybind=Enum.KeyCode.Unknown})
local unsafe=exploits:AddSection("Unsafe",1)
toggle(unsafe,"Tick Rate","unsafe.0",false,{Keybind=Enum.KeyCode.Unknown})
toggle(unsafe,"Building Tools","unsafe.1",false,{Keybind=Enum.KeyCode.Unknown})
toggle(unsafe,"Freeze Players","unsafe.2",false,{Keybind=Enum.KeyCode.Unknown})
toggle(unsafe,"Desync","unsafe.3",false,{Keybind=Enum.KeyCode.Unknown})
toggle(unsafe,"Shadow-Clone Jutsu","unsafe.4",false,{Keybind=Enum.KeyCode.Unknown})
toggle(unsafe,"No Knockback","unsafe.5",false,{Keybind=Enum.KeyCode.Unknown})
toggle(unsafe,"Ping Spike","unsafe.6",false,{Keybind=Enum.KeyCode.Unknown})
local misc=exploits:AddSection("Misc",2)
toggle(misc,"Freecam","misc.0",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Freecam Teleport","misc.1",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Gravity","misc.2",false,{Keybind=Enum.KeyCode.Unknown})
slider(misc,"Gravity Value","misc.gravity",0,500,196,.01)
toggle(misc,"Rage TP","misc2.0",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"PlatformStand","misc2.1",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Enable Anti-Aim","misc2.2",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Noclip","misc2.3",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"No Jump Cooldown","misc2.4",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Jetpack","misc2.5",false,{Keybind=Enum.KeyCode.Unknown})
slider(misc,"Jetpack Force","misc.jetpack",0,100,10,.01)
toggle(misc,"Underground","misc3.0",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Slow Fall","misc3.1",false,{Keybind=Enum.KeyCode.Unknown})
slider(misc,"Fall Speed","misc.fall",-50,0,-10,.01)
toggle(misc,"Instant Fall","misc4.0",false,{Keybind=Enum.KeyCode.Unknown})
toggle(misc,"Quick Stop","misc4.1",false,{Keybind=Enum.KeyCode.Unknown})

local wp=waypoints:AddSection("Waypoint Sets",1)
local setList
wp:Button({Text="Open folder",Callback=openFolder})
local function refreshSets() setList:SetOptions(store:Names("waypoints")) end
wp:Button({Text="Refresh",Callback=function() store:Refresh(); refreshSets() end})
setList=wp:List({Text="Waypoint Sets List",Flag="waypoints.list",Options={},Height=102}); setList.Transient=true
local setName=wp:Textbox({Text="Set Name",Flag="waypoints.name",Inline=true}); setName.Transient=true
wp:Button({Text="Load",Callback=function()
    local points=store.Data.waypoints[setList:Get()]
    if not points then ui:Notify("Select a waypoint set"); return end
    local ok,err=runtime.Client:SetPoints(points); resultNotice(ok,err,"Waypoint set loaded")
end})
wp:Button({Text="Save",Callback=function()
    local name=setName:Get():match("^%s*(.-)%s*$"); if name=="" then name=setList:Get() end
    local ok,err=store:SaveWaypoints(name,runtime.Client.Points)
    if ok then refreshSets(); setList:Set(name) end
    resultNotice(ok,err,canFiles and "Waypoint set saved to disk" or "Waypoint set saved for this execution")
end})
wp:Button({Text="Delete",Callback=function() local ok,err=store:DeleteWaypoints(setList:Get()); refreshSets(); resultNotice(ok,err,"Waypoint set deleted") end})
refreshSets()
local manager=waypoints:AddSection("Manager",2)
toggle(manager,"Show Waypoints ESP","waypoints.markers",false,{Color=teal})
toggle(manager,"Log Death Waypoints","waypoints.death")
toggle(manager,"Open Manager","waypoints.manager")
toggle(manager,"Open Death Markers","waypoints.deathMarkers")
slider(manager,"Max Distance","waypoints.distance",0,10000,1000)
toggle(manager,"Enable Beams","waypoints.beams")
slider(manager,"Beam Height","waypoints.beamHeight",0,600,50,.01)
slider(manager,"Beam Width","waypoints.beamWidth",0,100,15,.01)
toggle(manager,"Enable Icon","waypoints.icon",false,{Color=teal})
slider(manager,"Icon Size","waypoints.iconSize",0,150,24,.01)
dropdown(manager,"ESP Location","waypoints.location",{"Bottom","Top","Center"},"Bottom")

local st=settings:AddSection("Miscellaneous",1)
st:Keybind({Text="Menu Key",Flag="ui.key",Default=Enum.KeyCode.Insert,Callback=function(x) ui.ToggleKey=x end})
dropdown(st,"GPU Priority","settings.gpu",{"Default","Low","Normal","High"},"Default")
toggle(st,"Show Explorer Selection","settings.explorer")
dropdown(st,"Raycast Origin","settings.raycast",{"Camera","Character"},"Camera")
slider(st,"Explorer Update Rate (seconds)","settings.explorerRate",0,12,5)
toggle(st,"Show Watermark","settings.toggle0")
toggle(st,"Keybind List","settings.toggle1")
toggle(st,"Anti-Capture","settings.toggle2")
toggle(st,"Uncap Overlay","settings.toggle3")
slider(st,"Map Update Rate (seconds)","settings.mapRate",0,21,15)
slider(st,"Cache Update Rate (ms)","settings.cacheRate",0,10,7)
toggle(st,"Show hitmarker","settings.hitmarker")
toggle(st,"Hitmarker sound","settings.hitSound")
st:Button({Text="Unload",Callback=function() ui:Destroy(); env.SerotoninWindow=nil end})
local cross=settings:AddSection("Crosshair",2)
toggle(cross,"Enabled","cross.enabled")
local cs=slider(cross,"Size","cross.size",1,30,8)
local cg=slider(cross,"Gap","cross.gap",0,20,4)
local cc=cross:Colorpicker({Text="Color",Flag="cross.color",Default=white})
ui:BindVisibility("cross.enabled",{cs,cg,cc})

local scripts=configs:AddSection("Scripts",1)
scripts:Button({Text="Open folder",Callback=openFolder})
local scriptList
scripts:Button({Text="Refresh scripts",Callback=function()
    local names={}
    if type(listfiles)=="function" then
        local ok,files=pcall(listfiles,folder)
        if ok then for _,file in ipairs(files) do if file:match("%.lua[u]?$") then table.insert(names,file:match("[^/\\]+$") or file) end end end
    end
    scriptList:SetOptions(names); ui:Notify("Script list refreshed")
end})
scriptList=scripts:List({Text="Scripts list",Flag="scripts.list",Options={},Height=102}); scriptList.Transient=true
local conf=configs:AddSection("Configs",2)
conf:Button({Text="Open folder",Callback=openFolder})
local configList
local function refreshConfigs() configList:SetOptions(store:Names()) end
conf:Button({Text="Refresh",Callback=function()
    local ok,err=store:Refresh(); refreshConfigs(); if not ok then ui:Notify(err) end
end})
configList=conf:List({Text="Config list",Flag="configs.list",Options={},Height=102}); configList.Transient=true
local configName=conf:Textbox({Text="Config name",Flag="configs.name",Placeholder="",Inline=true}); configName.Transient=true
conf:Button({Text="Load",Callback=function() local ok,err=ui:LoadNamedConfig(configList:Get()); resultNotice(ok,err,"Config loaded") end})
conf:Button({Text="Save",Callback=function()
    local name=configName:Get():match("^%s*(.-)%s*$"); if name=="" then name=configList:Get() end
    local ok,err=ui:SaveNamedConfig(name)
    if ok then refreshConfigs(); configList:Set(name) end
    resultNotice(ok,err,canFiles and "Config saved to disk" or "Config saved for this execution")
end})
conf:Button({Text="Delete",Callback=function() local ok,err=ui:DeleteNamedConfig(configList:Get()); refreshConfigs(); resultNotice(ok,err,"Config deleted") end})
conf:Button({Text="Set as Auto-load",Callback=function() local ok,err=store:SetAutoload(configList:Get()); resultNotice(ok,err,canFiles and "Auto-load saved" or "Auto-load needs file APIs to survive re-execution") end})
conf:Button({Text="Remove Auto-load",Callback=function() local ok,err=store:SetAutoload(""); resultNotice(ok,err,"Auto-load removed") end})
conf=configs:AddSection("Import / Export",2)
conf:Button({Text="Export JSON",Callback=function()
    local json=ui:ExportConfig()
    if type(setclipboard)=="function" then local ok=pcall(setclipboard,json); if ok then ui:Notify("Config copied to clipboard"); return end end
    ui:TextDialog("Config JSON · select and copy",json)
end})
conf:Button({Text="Import JSON",Callback=function()
    ui:TextDialog("Paste config JSON","",function(json) local ok,err=ui:LoadConfig(json); ui:Notify(ok and "Config imported" or err) end)
end})
refreshConfigs()
runtime=Runtime.new(ui,Detector,Policy,Visuals,Client)
-- Apply demo callbacks once so the preview matches every initial control value.
for _,control in pairs(ui.Controls) do ui:_callback(control.Callback,control:Get()) end
if store.Data.autoload~="" and store.Data.configs[store.Data.autoload] then
    local ok,err=ui:LoadConfig(store.Data.configs[store.Data.autoload]); ui:Notify(ok and "Auto-loaded: "..store.Data.autoload or err)
end
ui:SelectTab("Aimbot",true)
return ui
