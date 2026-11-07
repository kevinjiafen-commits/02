-- Arch script beta
-- RCLC Premium logic merged into custom Eclipse-style UI
-- UI originally by eclipse.wtf/fallen; logic from RCLC Premium Lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- ============================================================
-- ECLIPSE UI LIBRARY
-- ============================================================
local CFG = {
    MainColor       = Color3.fromRGB(14, 14, 14),
    SecondaryColor  = Color3.fromRGB(26, 26, 26),
    AccentColor     = Color3.fromRGB(189, 172, 255),
    TextColor       = Color3.fromRGB(200, 200, 200),
    TextDark        = Color3.fromRGB(120, 120, 120),
    StrokeColor     = Color3.fromRGB(40, 40, 40),
    Font            = Enum.Font.Code,
    BaseSize        = Vector2.new(700, 500),
}

local Library = { Flags = {}, Connections = {}, Unloaded = false }

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do inst[i] = v end
    for _, child in pairs(children or {}) do child.Parent = inst end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

local ScreenGui = Create("ScreenGui", {
    Name            = "ArchScriptBeta",
    Parent          = CoreGui,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn    = false,
    IgnoreGuiInset  = true,
})

local UIScale = Create("UIScale", { Parent = ScreenGui })

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local widthRatio  = (vp.X - 40) / CFG.BaseSize.X
    local heightRatio = (vp.Y - 40) / CFG.BaseSize.Y
    local scale = math.min(widthRatio, heightRatio, 1)
    UIScale.Scale = math.max(scale, 0.6)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

-- Notification container
local NotificationContainer = Create("Frame", {
    Parent              = ScreenGui,
    Position            = UDim2.new(1, -20, 0, 20),
    AnchorPoint         = Vector2.new(1, 0),
    Size                = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex              = 100,
})
Create("UIListLayout", {
    Parent              = NotificationContainer,
    Padding             = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment   = Enum.VerticalAlignment.Top,
})

local function Notify(title, message, kind, duration)
    local color = (kind == "success" and Color3.fromRGB(100, 255, 100))
               or (kind == "warning" and Color3.fromRGB(255, 100, 100))
               or CFG.AccentColor
    local msg = tostring(title) .. " | " .. tostring(message)
    local Frame = Create("Frame", {
        Parent              = NotificationContainer,
        Size                = UDim2.new(0, 0, 0, 30),
        BackgroundColor3    = CFG.MainColor,
        BorderSizePixel     = 0,
        ClipsDescendants    = true,
    }, {
        Create("UIStroke", { Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5 }),
        Create("Frame",    { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = color }),
        Create("TextLabel", {
            Text                = msg,
            TextColor3          = CFG.TextColor,
            Font                = CFG.Font,
            TextSize            = 12,
            Size                = UDim2.new(1, -10, 1, 0),
            Position            = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment      = Enum.TextXAlignment.Left,
        }),
    })
    Tween(Frame, { Size = UDim2.new(0, 280, 0, 35) }, 0.5, Enum.EasingStyle.Back)
    task.delay(duration or 3, function()
        Tween(Frame, { Size = UDim2.new(0, 280, 0, 0), BackgroundTransparency = 1 }, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

-- Tooltip
local TooltipLabel = Create("TextLabel", {
    Parent          = ScreenGui,
    Size            = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3      = CFG.TextColor,
    TextSize        = 11,
    Font            = CFG.Font,
    BorderSizePixel = 0,
    Visible         = false,
    ZIndex          = 200,
}, {
    Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
    Create("UIStroke",  { Color = CFG.StrokeColor }),
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        TooltipLabel.Size = UDim2.fromOffset(GetTextSize(text, 11, CFG.Font).X + 12, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function() TooltipLabel.Visible = false end)
end

RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
    end
end)

-- Main frame
local MainFrame = Create("Frame", {
    Name            = "MainFrame",
    Parent          = ScreenGui,
    Size            = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position        = UDim2.new(0.5, -350, 0.5, -250),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0,
}, {
    Create("UIStroke", { Color = CFG.StrokeColor }),
    Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
})

-- Drag
local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging  = true
        DragStart = input.Position
        StartPos  = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
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
        Tween(MainFrame, { Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y) }, 0.05)
    end
end)

-- Top bar
local TopBar = Create("Frame", {
    Parent          = MainFrame,
    Size            = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0,
}, {
    Create("Frame", {
        Size            = UDim2.new(1, 0, 0, 1),
        Position        = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor,
    }),
})

local TitleLabel = Create("TextLabel", {
    Parent          = TopBar,
    Text            = "Arch script beta",
    TextColor3      = CFG.AccentColor,
    TextSize        = 13,
    Font            = CFG.Font,
    BackgroundTransparency = 1,
    Size            = UDim2.new(0, 300, 1, 0),
    Position        = UDim2.new(0, 10, 0, 0),
    TextXAlignment  = Enum.TextXAlignment.Left,
    RichText        = true,
})

-- Animated title
task.spawn(function()
    local base = "Arch script beta"
    while not Library.Unloaded do
        for i = 1, #base do
            if Library.Unloaded then break end
            TitleLabel.Text = string.sub(base, 1, i)
            task.wait(0.08)
        end
        task.wait(1.5)
        for i = #base, 0, -1 do
            if Library.Unloaded then break end
            TitleLabel.Text = string.sub(base, 1, i)
            task.wait(0.05)
        end
        task.wait(0.4)
    end
end)

local ContentContainer = Create("Frame", {
    Parent          = MainFrame,
    Size            = UDim2.new(1, 0, 1, -30),
    Position        = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1,
})

local Sidebar = Create("Frame", {
    Parent          = ContentContainer,
    Size            = UDim2.new(0, 70, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel = 0,
    Position        = UDim2.new(0, 0, 0, 0),
}, {
    Create("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder }),
    Create("UIPadding",    { PaddingTop = UDim.new(0, 15) }),
})
-- Separator parented after creation so UIListLayout never treats it as a list item
Create("Frame", { Parent = Sidebar, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = CFG.StrokeColor })

local PagesContainer = Create("Frame", {
    Parent          = ContentContainer,
    Size            = UDim2.new(1, -70, 1, 0),
    Position        = UDim2.new(0, 70, 0, 0),
    BackgroundTransparency = 1,
})

local Tabs       = {}
local CurrentTab = nil

-- ============================================================
-- TAB / GROUP / ITEM BUILDER
-- ============================================================
local function NewTab(name, iconId)
    local TabButton = Create("TextButton", {
        Parent          = Sidebar,
        Size            = UDim2.new(0, 46, 0, 46),
        BackgroundColor3 = CFG.MainColor,
        Text            = "",
        AutoButtonColor = false,
    }, {
        Create("ImageLabel", {
            Name            = "Icon",
            Size            = UDim2.new(0.6, 0, 0.6, 0),
            Position        = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image           = "rbxassetid://" .. tostring(iconId),
            ImageColor3     = CFG.TextDark,
        }),
        Create("UICorner",   { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke",   { Color = CFG.StrokeColor, Thickness = 1 }),
    })

    local PageFrame = Create("ScrollingFrame", {
        Parent              = PagesContainer,
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible             = false,
        ScrollBarThickness  = 2,
        ScrollBarImageColor3 = CFG.AccentColor,
        CanvasSize          = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })

    local Padding = Create("UIPadding", {
        Parent         = PageFrame,
        PaddingTop     = UDim.new(0, 15),
        PaddingLeft    = UDim.new(0, 10),
        PaddingRight   = UDim.new(0, 10),
        PaddingBottom  = UDim.new(0, 15),
    })

    local LeftCol = Create("Frame", {
        Parent          = PageFrame,
        Size            = UDim2.new(0.48, 0, 1, 0),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local RightCol = Create("Frame", {
        Parent          = PageFrame,
        Size            = UDim2.new(0.48, 0, 1, 0),
        Position        = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn, { BackgroundColor3 = CFG.MainColor }, 0.2)
            t.Btn.Icon.ImageColor3 = CFG.TextDark
            t.Page.Visible = false
        end
        Tween(TabButton, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        TabButton.Icon.ImageColor3 = CFG.AccentColor
        PageFrame.Visible = true
        CurrentTab = PageFrame
    end)

    table.insert(Tabs, { Btn = TabButton, Page = PageFrame })

    if #Tabs == 1 then
        Tween(TabButton, { BackgroundColor3 = CFG.SecondaryColor }, 0.001)
        TabButton.Icon.ImageColor3 = CFG.AccentColor
        PageFrame.Visible = true
    end

    local GroupFunctions = {}
    local LeftSide = true

    function GroupFunctions:Section(sectionName)
        -- Section header spanning both columns
        local header = Create("TextLabel", {
            Parent          = PageFrame,
            Size            = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text            = "── " .. sectionName .. " ──",
            TextColor3      = CFG.AccentColor,
            Font            = Enum.Font.GothamBold,
            TextSize        = 10,
            TextXAlignment  = Enum.TextXAlignment.Center,
        })
        LeftSide = true  -- reset column alternation after a section
        return self
    end

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol
        LeftSide = not LeftSide

        local GroupFrame = Create("Frame", {
            Parent          = ParentCol,
            Size            = UDim2.new(1, 0, 0, 0),
            AutomaticSize   = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel = 0,
        }, {
            Create("UIStroke", { Color = CFG.StrokeColor }),
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
        })

        Create("Frame", {
            Parent          = GroupFrame,
            Size            = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel = 0,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("Frame", {
                Size            = UDim2.new(1, 0, 0, 5),
                Position        = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
            }),
            Create("TextLabel", {
                Text            = title,
                Size            = UDim2.new(1, -20, 1, 0),
                Position        = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3      = CFG.TextColor,
                Font            = Enum.Font.GothamBold,
                TextSize        = 11,
                TextXAlignment  = Enum.TextXAlignment.Left,
            }),
            Create("Frame", {
                Size            = UDim2.new(0, 4, 0, 4),
                Position        = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel = 0,
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
        })

        local Content = Create("Frame", {
            Parent          = GroupFrame,
            Size            = UDim2.new(1, 0, 0, 0),
            Position        = UDim2.new(0, 0, 0, 25),
            AutomaticSize   = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding",    { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
        })

        local ItemFuncs = {}

        function ItemFuncs:Toggle(cfg)
            local Enabled = cfg.Default or false
            local Frame = Create("TextButton", {
                Parent          = Content,
                Size            = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text            = "",
            })
            local Box = Create("Frame", {
                Parent          = Frame,
                Size            = UDim2.new(0, 12, 0, 12),
                Position        = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
            }, { Create("UIStroke", { Color = CFG.StrokeColor }) })
            local Check = Create("Frame", {
                Parent          = Box,
                Size            = UDim2.new(1, -4, 1, -4),
                Position        = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint     = Vector2.new(0.5, 0.5),
                BackgroundColor3 = CFG.AccentColor,
                BackgroundTransparency = Enabled and 0 or 1,
            })
            local Label = Create("TextLabel", {
                Parent          = Frame,
                Text            = cfg.Name,
                TextColor3      = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark),
                TextSize        = 11,
                Font            = CFG.Font,
                BackgroundTransparency = 1,
                Position        = UDim2.new(0, 18, 0, 0),
                Size            = UDim2.new(1, -18, 1, 0),
                TextXAlignment  = Enum.TextXAlignment.Left,
            })
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
            local function Update()
                Enabled = not Enabled
                Tween(Check, { BackgroundTransparency = Enabled and 0 or 1 }, 0.1)
                Tween(Label, { TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark) }, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end
            Frame.MouseButton1Click:Connect(Update)
            return { Set = function(v) if v ~= Enabled then Update() end end }
        end

        function ItemFuncs:Slider(cfg)
            local Value = cfg.Default or cfg.Min
            local DraggingSlider = false
            local Frame = Create("Frame", { Parent = Content, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 })
            local Label      = Create("TextLabel", { Parent = Frame, Text = cfg.Name,          TextColor3 = CFG.TextDark, TextSize = 11, Font = CFG.Font, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Left  })
            local ValueLabel = Create("TextLabel", { Parent = Frame, Text = tostring(Value) .. (cfg.Unit or ""), TextColor3 = CFG.TextDark, TextSize = 11, Font = CFG.Font, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Right })
            local SliderBG   = Create("Frame", { Parent = Frame, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = CFG.SecondaryColor, BorderSizePixel = 0 }, { Create("UIStroke", { Color = CFG.StrokeColor }), Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            local Fill       = Create("Frame", { Parent = SliderBG, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = CFG.AccentColor }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            local function UpdateSlider(input)
                local SizeX = SliderBG.AbsoluteSize.X
                local PosX  = SliderBG.AbsolutePosition.X
                local Pct   = math.clamp((input.Position.X - PosX) / SizeX, 0, 1)
                local step  = cfg.Increment or 1
                Value = math.floor((cfg.Min + (cfg.Max - cfg.Min) * Pct) / step + 0.5) * step
                Value = math.clamp(Value, cfg.Min, cfg.Max)
                Fill.Size = UDim2.new(Pct, 0, 1, 0)
                ValueLabel.Text = tostring(Value) .. (cfg.Unit or "")
                if cfg.Callback then cfg.Callback(Value) end
            end
            Frame.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true; UpdateSlider(inp)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if DraggingSlider and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(inp)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)
            local pct = (Value - cfg.Min) / (cfg.Max - cfg.Min)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current  = cfg.Default or cfg.Options[1]
            local Frame = Create("Frame", { Parent = Content, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 20 })
            Create("TextLabel", { Parent = Frame, Text = cfg.Name, TextColor3 = CFG.TextDark, TextSize = 11, Font = CFG.Font, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Left })
            local MainBox = Create("TextButton", { Parent = Frame, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 16), BackgroundColor3 = CFG.SecondaryColor, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("TextLabel", { Name = "Val", Text = Current, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, TextColor3 = CFG.TextColor, TextSize = 11, Font = CFG.Font, TextXAlignment = Enum.TextXAlignment.Left }),
                Create("TextLabel", { Text = "▼", Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, TextColor3 = CFG.TextDark, TextSize = 10 }),
            })
            local ListFrame = Create("ScrollingFrame", { Parent = MainBox, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 2), BackgroundColor3 = CFG.SecondaryColor, BorderSizePixel = 0, Visible = false, ZIndex = 50, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2 }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })
            for _, opt in pairs(cfg.Options) do
                local Btn = Create("TextButton", { Parent = ListFrame, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = opt, TextColor3 = (opt == Current) and CFG.AccentColor or CFG.TextDark, TextSize = 11, Font = CFG.Font })
                Btn.MouseButton1Click:Connect(function()
                    Current = opt
                    MainBox.Val.Text = opt
                    if cfg.Callback then cfg.Callback(opt) end
                    Expanded = false
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1); ListFrame.Visible = false
                end)
            end
            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, math.min(#cfg.Options * 20, 100)) }, 0.1)
                else
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1); ListFrame.Visible = false
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Button(cfg)
            local Btn = Create("TextButton", { Parent = Content, Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = CFG.SecondaryColor, Text = cfg.Name, TextColor3 = CFG.TextDark, Font = Enum.Font.GothamBold, TextSize = 10 }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })
            if cfg.Style == "Danger"  then Btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60);  Btn.TextColor3 = Color3.new(0,0,0) end
            if cfg.Style == "Primary" then Btn.BackgroundColor3 = CFG.AccentColor;              Btn.TextColor3 = Color3.new(0,0,0) end
            Btn.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback() end end)
            if cfg.Tooltip then AddTooltip(Btn, cfg.Tooltip) end
        end

        function ItemFuncs:Label(cfg)
            Create("TextLabel", { Parent = Content, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Text or "", TextColor3 = CFG.TextDark, Font = CFG.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left })
        end

        return ItemFuncs
    end

    return GroupFunctions
end

-- ============================================================
-- RCLC LOGIC (verbatim, unchanged)
-- ============================================================
local character, rootPart, humanoid
local connections = {}
local frameStamp  = -1
local frameCount  = 0

local function disconnectConn(connName)
    if connections[connName] then
        connections[connName]:Disconnect()
        connections[connName] = nil
    end
end

local function getRoot() return rootPart end

local function frameBudgetOk()
    local currentFrame = math.floor(tick() * 60 + 0.5)
    if currentFrame ~= frameStamp then frameStamp = currentFrame; frameCount = 0 end
    if frameCount >= 3 then return false end
    frameCount = frameCount + 1
    return true
end

-- Config tables
local voidCfg = { VOID_ENABLED = false, VOID_METHOD = "Quantum", VOID_ATTACKER_INTERVAL = 4, VOID_ATTACKER_DURATION = 0.4, VOID_BAIT_INTERVAL = 3, VOID_BAIT_DURATION = 0.4, SPEED = 1000000000, CHAOS = 0.98, BASE_X = 0, BASE_Y = 0, BASE_Z = 0, RADIUS = 10000000, VOID_Y_MIN = -10000000, VOID_Y_MAX = 10000000, VOID_WRITES_PER_FRAME = 1, VOID_INTERP = true, VOID_INTERP_ALPHA = 0.35, VOID_HOLD = 0, VOID_JITTER = 0, VOID_ANTIFLING = true, VOID_ANTIVOID = false, VOID_SAFE_RADIUS = 0, VOID_LOG = false, VOID_CURVE_FREQ = 0.7, VOID_CURVE_AMP = 0.5, VOID_DRIFT_SPEED = 1, VOID_GRID_SIZE = 8, VOID_SCREEN_DEPTH_MIN = 50, VOID_SCREEN_DEPTH_MAX = 50000, VOID_CHASE_MAX = 200, VOID_MIRROR_AXIS = "X", VOID_PREDICT_LEAD = 0.2, VOID_DURATION_ENABLED = false, VOID_DURATION = 10, WIREFRAME_ENABLED = false }
local orbitCfg      = { orbitEnabled = false, orbitSpeed = 90, orbitDist = 8, orbitHeight = 0, orbitMode = "Clockwise", orbitLockDist = 10000000 }
local predictCfg    = { predEnabled = false, predRadius = 150, predDodgeDist = 80, predCooldown = 0.05, predReactionTime = 0.12, predBulletSpeed = 1000, predAimThreshold = 0.7, predKinematic = true, predPredictive = true, predLookahead = 0.5, predInfiniteRange = false }
local translocCfg   = { enabled = false, frequency = 1000000, jitterX = 10000000, jitterY = 10000000, fixedZ = 1, fakeVel = true, fakeVelMag = 10000000000, burstMode = false, burstCount = 10 }
local fakePosCfg    = { enabled = false, radius = 1000000, height = 999999999, yDist = 999999999, speed = 100000, pattern = "Scatter", distribution = "Random", axisLock = "None", randomizeEveryFrame = false, scatterAngle = 360, pulseRadius = false, pulseRadiusMin = 100, pulseRadiusMax = 999999, pulseSpeed = 2, layeredFake = false, layerCount = 3, chaosMode = false, chaosMult = 5 }
local velDesyncCfg  = { enabled = false, intensity = 50, angle = 90, jitter = 20, flip = false, speed = 10, randomizeAngle = false, angleMin = 0, angleMax = 360, multiVector = false, vectorCount = 3, spikeMode = false, spikeInterval = 0.05, spikeMag = 1000000, invertOnTimer = false, invertInterval = 0.2, oscillate = false, oscillateFreq = 5, oscillateAmp = 30, noiseVel = false, noiseScale = 1, burstDesync = false, burstEvery = 0.1, burstMag = 500000, counterVel = false, rotateVel = false, rotateVelSpeed = 180 }
local antiAimCfg    = { enabled = false, speed = 5000, chaosLevel = 100, pitch = 360, yaw = 360 }
local undergroundCfg = { enabled = false, depth = 1.5, orbitRadius = 3, orbitSpeed = 200, spinSpeed = 720 }
local fastMeleeCfg  = { enabled = false, cached = {}, cooldown = 0, animSpeed = 100, remoteCount = 5 }
local fastGunState  = { primaryOn = false, primaryHits = 0, lastPatch = 0 }
local excludedGuns  = { Sniper = true, Crossbow = true, Bow = true, RPG = true }
local killAuraCfg   = { enabled = false, fireRate = 0.02, weaponSlot = "Primary", radius = 5000, headshotOffset = 1, jitter = 0.02, autoEquip = true }
local weaponSlots   = { Primary = 1, Secondary = 2, Melee = 3 }

local undergroundAngle = 0
local undergroundConn  = nil
local savedRootJointC0 = nil

local Utility, EnumLibrary, FighterController
local lastShotTime  = 0
local killAuraConn  = nil
local autoEquipThread = nil

pcall(function()
    Utility       = require(ReplicatedStorage.Modules.Utility)
    EnumLibrary   = require(ReplicatedStorage.Modules.EnumLibrary)
    local ps = localPlayer:FindFirstChild("PlayerScripts")
    if ps then
        local ct = ps:FindFirstChild("Controllers")
        if ct and ct:FindFirstChild("FighterController") then
            FighterController = require(ct.FighterController)
        end
    end
end)

-- Fast gun
local function patchGun(gs)
    if type(gs) ~= "table" then return false end
    local d = false
    if gs.ShootSpread       then gs.ShootSpread       = 0;     d = true end
    if gs.ShootAccuracy     then gs.ShootAccuracy     = 0;     d = true end
    if gs.ShootRecoil       then gs.ShootRecoil       = 0;     d = true end
    if gs.ShootCooldown     then gs.ShootCooldown     = 0.001; d = true end
    if gs.ShootBurstCooldown then gs.ShootBurstCooldown = 0.001; d = true end
    return d
end

local function patchEquippedGuns()
    local ok, items = pcall(function() return require(ReplicatedStorage.Modules.ItemLibrary).Items end)
    if not ok or type(items) ~= "table" then Notify("Fast Gun", "ItemLibrary unavailable", "warning", 3); return false end
    local n = 0
    for k, v in pairs(items) do
        if not excludedGuns[k] and type(v) == "table" and patchGun(v) then n = n + 1 end
    end
    fastGunState.primaryHits = n; fastGunState.lastPatch = tick()
    Notify("Fast Gun", ("patched %d guns"):format(n), "success", 3)
    return n > 0
end

local function fastGunTick() if fastGunState.primaryOn then pcall(patchEquippedGuns) end end

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
            if FighterController and FighterController.LocalFighter and FighterController.LocalFighter.EquippedItem == nil then
                pcall(function() FighterController.LocalFighter:EquipItem(weaponSlotIndex()) end)
            end
        end
    end)
end

local function getNpcTargets()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local targets = {}
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= myChar then
            local nr  = model:FindFirstChild("HumanoidRootPart")
            local nh  = model:FindFirstChild("Head")
            local nhm = model:FindFirstChildWhichIsA("Humanoid")
            if nr and nh and nhm and nhm.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                local dist = (myRoot.Position - nr.Position).Magnitude
                if dist <= killAuraCfg.radius then
                    table.insert(targets, { model = model, root = nr, head = nh, dist = dist })
                end
            end
        end
    end
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    return targets
end

local function killAuraStep()
    if not killAuraCfg.enabled or not Utility or not EnumLibrary or not FighterController then return end
    if tick() - lastShotTime < killAuraCfg.fireRate then return end
    local npcList = getNpcTargets()
    if #npcList == 0 then return end
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local fighter = FighterController.LocalFighter
    if not fighter or not fighter.EquippedItem then return end
    local th = npcList[1].head
    local hp = th.Position
    local aimCFrame  = CFrame.lookAt(hp + Vector3.new(0, killAuraCfg.headshotOffset, 0), hp)
    local headCFrame = th.CFrame
    local j = killAuraCfg.jitter
    local jv = Vector3.new((math.random()-0.5)*j, (math.random()-0.5)*j, (math.random()-0.5)*j)
    local hitOffset = th.CFrame:ToObjectSpace(CFrame.new(hp + jv))
    local sp = {}
    sp[utf8.char(1)] = {
        [utf8.char(0)] = Utility:EncodeCFrame(aimCFrame),
        [utf8.char(1)] = Utility:EncodeCFrame(headCFrame),
        [utf8.char(2)] = th,
        [utf8.char(3)] = Utility:EncodeCFrame(hitOffset),
    }
    pcall(function()
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            fighter.EquippedItem:Get("ObjectID"), EnumLibrary:ToEnum("StartShooting"), sp, nil)
    end)
    lastShotTime = tick()
end

local function disableKillAura()
    if killAuraConn then killAuraConn:Disconnect(); killAuraConn = nil end
    stopAutoEquip()
    Notify("Kill Aura", "Ka deactivated", "warning", 3)
end

local function enableKillAura()
    if killAuraConn then killAuraConn:Disconnect() end
    if killAuraCfg.autoEquip then startAutoEquip() end
    killAuraConn = RunService.Heartbeat:Connect(killAuraStep)
    Notify("Kill Aura", "Ka activated", "success", 3)
end

-- Helpers
local function getHead(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("CameraBone", true) or player.Character:FindFirstChild("HumanoidRootPart")
end

local velTrackers = {}
local function getTracker(player)
    if not velTrackers[player] then velTrackers[player] = { vel = Vector3.zero, accel = Vector3.zero, lastPos = nil, lastVel = Vector3.zero, lastT = tick() } end
    return velTrackers[player]
end

local function updateTracker(player, targetRoot)
    local tr = getTracker(player)
    local now = tick(); local dt = now - tr.lastT
    if dt > 0.01 then
        local vel = targetRoot.AssemblyLinearVelocity
        if tr.lastPos and tr.lastVel then tr.accel = tr.accel:Lerp((vel - tr.lastVel) / dt, 0.2) end
        tr.vel = vel; tr.lastPos = targetRoot.Position; tr.lastVel = vel; tr.lastT = now
    end
    return tr
end

local function nearestPlayerRoot()
    if not rootPart then return nil end
    local np, nd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (rootPart.Position - r.Position).Magnitude
                if d < nd then nd = d; np = p end
            end
        end
    end
    return np
end

local function sidestepDirection(aPos, myPos)
    local off = Vector3.new(aPos.X - myPos.X, 0, aPos.Z - myPos.Z)
    if off.Magnitude < 0.01 then off = Vector3.new(1,0,0) end
    local d = off.Unit
    local pl = Vector3.new(-d.Z, 0, d.X); local pr = Vector3.new(d.Z, 0, -d.X)
    return (math.random(0,1)==0 and pl or pr) + Vector3.new(0,(math.random()-0.5)*0.4,0)
end

local function scorePlayers(myPos)
    local scores = {}
    if not myPos then return scores end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local ht = p.Character:FindFirstChildOfClass("Tool")
                local op = getHead(p) or r
                local lv = op.CFrame.LookVector
                local tm = myPos - (op.Position + lv * 0.5)
                local dm = tm.Magnitude
                if dm >= 0.01 then
                    local tr  = updateTracker(p, r)
                    local dot = lv:Dot(tm.Unit)
                    local af  = math.max(0, dot)
                    local pf  = math.max(0, 1 - dm / 250)
                    scores[p] = { hrp = r, dist = dm, aimDot = dot, score = af*45 + (ht and 25 or 0) + pf*30, hasTool = ht ~= nil, origin = op, trk = tr }
                end
            end
        end
    end
    return scores
end

-- Void
local voidState     = { t = 0, pos = Vector3.zero, vel = Vector3.zero, phase = 0, seed = os.clock(), anchor = Vector3.zero }
local voidPhaseTime = 0
local voidBaitPhase = false

local function randomRange(mn, mx) return mn + math.random()*(mx-mn) end

local function sanitizeVector(v)
    if not v or typeof(v) ~= "Vector3" then return v end
    local x, y, z = v.X, v.Y, v.Z
    if x ~= x or x == math.huge or x == -math.huge then x = voidCfg.BASE_X end
    if y ~= y or y == math.huge or y == -math.huge then y = 0 end
    if z ~= z or z == math.huge or z == -math.huge then z = voidCfg.BASE_Z end
    y = math.clamp(y, voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX)
    local mr = math.abs(voidCfg.RADIUS)
    if mr > 0 then
        local dx, dz = x-voidCfg.BASE_X, z-voidCfg.BASE_Z
        local d = math.sqrt(dx*dx + dz*dz)
        if d > mr and d > 0 then local s = mr/d; x = voidCfg.BASE_X + dx*s; z = voidCfg.BASE_Z + dz*s end
    end
    return Vector3.new(x, y, z)
end

local function voidTarget(dt)
    local r = voidCfg.RADIUS
    if voidCfg.VOID_METHOD == "Freeze Bait" then
        voidPhaseTime = voidPhaseTime + dt
        if voidBaitPhase then
            if voidPhaseTime >= voidCfg.VOID_BAIT_DURATION then voidBaitPhase = false; voidPhaseTime = 0
            else local sr = getRoot(); return sr and sr.Position or Vector3.zero end
        elseif voidPhaseTime >= voidCfg.VOID_BAIT_INTERVAL then
            voidBaitPhase = true; voidPhaseTime = 0
            local sr = getRoot(); return sr and sr.Position or Vector3.zero
        end
        return sanitizeVector(Vector3.new(voidCfg.BASE_X + randomRange(-r, r), randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX), voidCfg.BASE_Z + randomRange(-r, r)))
    elseif voidCfg.VOID_METHOD == "Attacker" then
        voidPhaseTime = voidPhaseTime + dt
        if voidBaitPhase then
            if voidPhaseTime >= voidCfg.VOID_ATTACKER_DURATION then voidBaitPhase = false; voidPhaseTime = 0
            else
                local np = nearestPlayerRoot()
                if np and np.Character then local nr = np.Character:FindFirstChild("HumanoidRootPart"); if nr then return nr.Position end end
            end
        elseif voidPhaseTime >= voidCfg.VOID_ATTACKER_INTERVAL then
            voidBaitPhase = true; voidPhaseTime = 0
            local np = nearestPlayerRoot()
            if np and np.Character then local nr = np.Character:FindFirstChild("HumanoidRootPart"); if nr then return nr.Position end end
        end
        return sanitizeVector(Vector3.new(voidCfg.BASE_X + randomRange(-r, r), randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX), voidCfg.BASE_Z + randomRange(-r, r)))
    elseif voidCfg.VOID_METHOD == "Chaos" then
        local cm = r * voidCfg.CHAOS
        return Vector3.new(voidCfg.BASE_X + randomRange(-cm, cm), randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX), voidCfg.BASE_Z + randomRange(-cm, cm))
    else
        return Vector3.new(voidCfg.BASE_X + randomRange(-r, r), randomRange(voidCfg.VOID_Y_MIN, voidCfg.VOID_Y_MAX), voidCfg.BASE_Z + randomRange(-r, r))
    end
end

local function voidStep(dt)
    voidState.t = voidState.t + dt
    local root = getRoot(); if not root then return end
    local tp = voidTarget(dt); if not tp then return end
    pcall(function()
        root.CFrame = CFrame.new(tp)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function enableVoid()
    disconnectConn("void")
    voidState.t = 0; voidState.phase = 0; voidState.vel = Vector3.zero
    voidPhaseTime = 0; voidBaitPhase = false
    local root = getRoot()
    if root then
        voidState.pos = root.Position; voidState.anchor = root.Position
        pcall(function() root:SetNetworkOwner(localPlayer) end)
    end
    connections.void = (RunService.PreSimulation or RunService.Heartbeat):Connect(function(dt)
        if not voidCfg.VOID_ENABLED then disconnectConn("void"); return end
        if voidCfg.VOID_DURATION_ENABLED and tick()-voidState.t > voidCfg.VOID_DURATION then
            voidCfg.VOID_ENABLED = false; Notify("Void", "duration reached", "warning", 2); return
        end
        voidStep(dt)
    end)
end

local function disableVoid()
    disconnectConn("void"); voidCfg.VOID_ENABLED = false; voidBaitPhase = false; voidPhaseTime = 0
end

-- Wireframe
local wireframeFolder = nil
local wireframeBoxes  = {}

local function enableWireframes()
    if not wireframeFolder then
        wireframeFolder = Instance.new("Folder"); wireframeFolder.Name = "ArchWireframes"; wireframeFolder.Parent = CoreGui
    end
    local function add(part)
        if wireframeBoxes[part] then return end
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ArchBox"; box.Adornee = part; box.AlwaysOnTop = true; box.ZIndex = 10
        box.Size = Vector3.new(4,6,4); box.Transparency = 0.5; box.Color3 = CFG.AccentColor; box.Parent = wireframeFolder
        wireframeBoxes[part] = box
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart"); if r then add(r) end
        end
    end
    connections.wireframe = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            if voidCfg.WIREFRAME_ENABLED then local r = c:FindFirstChild("HumanoidRootPart"); if r then add(r) end end
        end)
    end)
end

local function disableWireframes()
    if wireframeFolder then wireframeFolder:Destroy(); wireframeFolder = nil end
    wireframeBoxes = {}
    if connections.wireframe then connections.wireframe:Disconnect(); connections.wireframe = nil end
end

local function setWireframes(state)
    voidCfg.WIREFRAME_ENABLED = state
    if state then enableWireframes() else disableWireframes() end
end

-- Orbit
local orbitAngle = 0

local function disableOrbit()
    disconnectConn("orbit"); orbitCfg.orbitEnabled = false
    if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
end

local function enableOrbit()
    disconnectConn("orbit"); orbitAngle = 0
    if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end) end
    connections.orbit = RunService.Heartbeat:Connect(function(dt)
        if not orbitCfg.orbitEnabled then disconnectConn("orbit"); return end
        if not rootPart then return end
        if humanoid then pcall(function() if humanoid:GetState() ~= Enum.HumanoidStateType.Physics then humanoid:ChangeState(Enum.HumanoidStateType.Physics) end end) end
        local np = nearestPlayerRoot()
        local center = rootPart.Position
        if np and np.Character then
            local nr = np.Character:FindFirstChild("HumanoidRootPart")
            if nr and (rootPart.Position - nr.Position).Magnitude <= orbitCfg.orbitLockDist then center = nr.Position end
        end
        orbitAngle = (orbitAngle + math.rad(orbitCfg.orbitSpeed) * (orbitCfg.orbitMode == "Counter-Clockwise" and -1 or 1) * dt) % (2*math.pi)
        local op = center + Vector3.new(math.cos(orbitAngle)*orbitCfg.orbitDist, orbitCfg.orbitHeight, math.sin(orbitAngle)*orbitCfg.orbitDist)
        pcall(function()
            rootPart.CFrame = CFrame.new(op, Vector3.new(center.X, op.Y, center.Z))
            rootPart.AssemblyLinearVelocity = Vector3.zero; rootPart.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end

-- Prediction
local lastPredFire  = 0
local lastToolUse   = {}
local hookedTools   = {}
local hookedToolCount = 0

local function disablePrediction() disconnectConn("pred"); predictCfg.predEnabled = false end

local hookToolActivate
local function hookAllPlayerTools()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local t = p.Character:FindFirstChildOfClass("Tool"); if t then hookToolActivate(t) end
            p.Character.ChildAdded:Connect(function(c) if c:IsA("Tool") then hookToolActivate(c) end end)
        end
    end
end

hookToolActivate = function(tool)
    if not tool or hookedTools[tool] or hookedToolCount >= 64 then return end
    hookedTools[tool] = true; hookedToolCount = hookedToolCount + 1
    pcall(function()
        hookfunction(tool.Activate, function(s, ...)
            if not checkcaller() and s == tool then
                local owner = tool.Parent and tool.Parent.Parent
                if owner and owner ~= localPlayer and owner.Character then lastToolUse[owner] = tick() end
            end
            -- BUG (from original): old/v346 undefined
        end)
    end)
end

local function enablePrediction()
    disconnectConn("pred"); hookAllPlayerTools()
    connections.pred = RunService.Heartbeat:Connect(function(dt)
        if not predictCfg.predEnabled then disconnectConn("pred"); return end
        if not rootPart or (humanoid and humanoid.Health <= 0) then return end
        local myPos = rootPart.Position; local myVel = rootPart.AssemblyLinearVelocity
        local now = tick(); local bt, bs = nil, 0
        for p, info in pairs(scorePlayers(myPos)) do
            if info.score > bs then bs = info.score; bt = { p = p, d = info } end
        end
        if not bt then return end
        local maxRange = predictCfg.predInfiniteRange and 5e12 or predictCfg.predRadius
        if bt.d.dist > maxRange then return end
        if now - lastPredFire < predictCfg.predCooldown then return end
        local threatened = (lastToolUse[bt.p] and now - lastToolUse[bt.p] < predictCfg.predReactionTime) or bt.d.aimDot > predictCfg.predAimThreshold
        if threatened then
            if predictCfg.predPredictive and bt.d.trk and bt.d.trk.vel then
                local tr = bt.d.trk; local dv = Vector3.zero; local fd = false
                for s = 1, 10 do
                    local t = predictCfg.predLookahead/10*s
                    local mfp = myPos + myVel*t
                    local efp = tr.lastPos + tr.vel*t + 0.5*tr.accel*t^2
                    if math.abs((mfp-efp).Magnitude/predictCfg.predBulletSpeed - t) < 0.15 then
                        fd = true
                        local dtm = (mfp-efp).Unit
                        local pa = Vector3.new(-dtm.Z,0,dtm.X); local pb = Vector3.new(dtm.Z,0,-dtm.X)
                        dv = ((math.random(0,1)==0 and 1 or -1)==1 and pa or pb).Unit * predictCfg.predDodgeDist
                        break
                    end
                end
                if fd and dv.Magnitude > 0 then
                    local dp = myPos + dv + Vector3.new(0,(math.random()-0.5)*15,0)
                    if frameBudgetOk() then pcall(function() rootPart.CFrame = CFrame.new(dp); rootPart.AssemblyLinearVelocity = dv.Unit*150 end) end
                    lastPredFire = now; return
                end
            end
        end
        if threatened and predictCfg.predKinematic then
            lastPredFire = now
            local sd = sidestepDirection(bt.d.hrp.Position, myPos)
            local sp = myPos + sd*predictCfg.predDodgeDist
            if frameBudgetOk() then
                pcall(function()
                    rootPart.CFrame = CFrame.new(sp + Vector3.new((math.random()-0.5)*4, 0, (math.random()-0.5)*4))
                    rootPart.AssemblyLinearVelocity = sd*150
                end)
            end
        end
    end)
end

-- Anti-aim
local function enableAntiAim()
    disconnectConn("antiAim")
    connections.antiAim = RunService.Heartbeat:Connect(function(dt)
        if not antiAimCfg.enabled then disconnectConn("antiAim"); return end
        if not rootPart then return end
        local ch = antiAimCfg.chaosLevel*0.01
        local ss = antiAimCfg.speed/5000
        rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(
            (math.random()-0.5)*2*math.rad(antiAimCfg.pitch)*ch*ss,
            (math.random()-0.5)*2*math.rad(antiAimCfg.yaw)*ch*ss,
            (math.random()-0.5)*math.rad(360)*ch*ss)
    end)
end

local function disableAntiAim() disconnectConn("antiAim"); antiAimCfg.enabled = false end

local function enableUndergroundAA()
    if undergroundConn then undergroundConn:Disconnect() end
    undergroundAngle = 0
    if rootPart and character then
        local head = character:FindFirstChild("Head")
        if head then
            local neck = head:FindFirstChild("Neck") or character:FindFirstChild("Neck")
            if neck and neck:IsA("Motor6D") then
                savedRootJointC0 = neck.C0; neck.C0 = CFrame.new(0,0,0)*CFrame.Angles(math.rad(-90),0,0)
            end
        end
    end
    undergroundConn = RunService.Heartbeat:Connect(function(dt)
        if not undergroundCfg.enabled then return end
        local root = getRoot(); if not root then return end
        undergroundAngle = (undergroundAngle + math.rad(undergroundCfg.orbitSpeed)*dt) % (2*math.pi)
        local up = root.Position + Vector3.new(math.cos(undergroundAngle)*undergroundCfg.orbitRadius, -undergroundCfg.depth, math.sin(undergroundAngle)*undergroundCfg.orbitRadius)
        if root.Position.Y - up.Y > undergroundCfg.depth + 1 then up = Vector3.new(up.X, root.Position.Y - undergroundCfg.depth, up.Z) end
        local spin = tick()*undergroundCfg.spinSpeed % 360
        pcall(function() root.CFrame = CFrame.new(up)*CFrame.Angles(0,math.rad(spin),0); root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end)
    end)
    Notify("Underground AA", "Activated", "success", 3)
end

local function disableUndergroundAA()
    if undergroundConn then undergroundConn:Disconnect(); undergroundConn = nil end
    if rootPart and character and savedRootJointC0 then
        local head = character:FindFirstChild("Head")
        if head then
            local neck = head:FindFirstChild("Neck") or character:FindFirstChild("Neck")
            if neck and neck:IsA("Motor6D") then neck.C0 = savedRootJointC0 end
        end
    end
    Notify("Underground AA", "Deactivated", "warning", 3)
end

-- Translocation
local translocConn  = nil
local translocTimer = 0

local function disableTransloc()
    if translocConn then translocConn:Disconnect(); translocConn = nil end
    translocCfg.enabled = false
end

local function enableTransloc()
    if translocConn then translocConn:Disconnect() end
    translocTimer = 0
    translocConn = RunService.Heartbeat:Connect(function(dt)
        if not translocCfg.enabled then disableTransloc(); return end
        if not rootPart then return end
        translocTimer = translocTimer + dt
        local interval = 1 / math.max(translocCfg.frequency, 1)
        local iters = math.clamp(math.floor(dt/interval), 1, 50)
        if translocTimer >= interval then
            translocTimer = translocTimer % interval
            local origin = rootPart.Position
            local meta = getrawmetatable and getrawmetatable(rootPart)
            local rni  = meta and rawget(meta, "__newindex")
            for _ = 1, iters do
                local fc = CFrame.new(origin.X + (math.random()*2-1)*translocCfg.jitterX, origin.Y + (math.random()*2-1)*translocCfg.jitterY, translocCfg.fixedZ)
                local fv = Vector3.zero
                if translocCfg.fakeVel then local m = translocCfg.fakeVelMag; fv = Vector3.new((math.random()-0.5)*m*2, (math.random()-0.5)*m*2, (math.random()-0.5)*m*2) end
                if rni then pcall(rni, rootPart, "CFrame", fc); pcall(rni, rootPart, "AssemblyLinearVelocity", fv)
                else pcall(function() rootPart.CFrame = fc; rootPart.AssemblyLinearVelocity = fv end) end
            end
        end
    end)
end

-- Fake position
local fakePosHeartbeat = nil; local fakePosRender = nil
local fakePosAnchor = nil; local fakePosAngle = 0; local fakePosHue = 0
local fakePosLastWrite = 0; local fakePosTime = 0

local function disableFakePos()
    if fakePosHeartbeat then fakePosHeartbeat:Disconnect(); fakePosHeartbeat = nil end
    if fakePosRender    then fakePosRender:Disconnect();    fakePosRender = nil    end
    fakePosAnchor = nil; fakePosCfg.enabled = false
end

local function enableFakePos()
    if fakePosHeartbeat then fakePosHeartbeat:Disconnect() end
    if fakePosRender    then fakePosRender:Disconnect()    end
    fakePosAnchor = nil; fakePosAngle = 0; fakePosHue = 0; fakePosLastWrite = 0; fakePosTime = 0
    fakePosHeartbeat = RunService.Heartbeat:Connect(function(dt)
        if not fakePosCfg.enabled or not rootPart then return end
        fakePosAnchor = rootPart.CFrame; fakePosTime = fakePosTime + dt
        local now = tick()
        local wr = fakePosCfg.randomizeEveryFrame and 99999 or math.max(fakePosCfg.speed, 1)
        if now - fakePosLastWrite < 1/wr then return end
        fakePosLastWrite = now
        local meta = getrawmetatable and getrawmetatable(rootPart)
        local rni  = meta and rawget(meta, "__newindex")
        local radius = math.max(fakePosCfg.radius, 1)
        if fakePosCfg.pulseRadius then radius = fakePosCfg.pulseRadiusMin + (math.sin(fakePosTime*fakePosCfg.pulseSpeed*2*math.pi)*0.5+0.5)*(fakePosCfg.pulseRadiusMax-fakePosCfg.pulseRadiusMin) end
        local layers = fakePosCfg.layeredFake and fakePosCfg.layerCount or 1
        for layer = 1, layers do
            local lr = radius*(layer/layers)
            if fakePosCfg.chaosMode then lr = lr*(1+(math.random()-0.5)*fakePosCfg.chaosMult) end
            local ox, oy, oz = 0, 0, 0
            local pat = fakePosCfg.pattern
            if pat == "Scatter" then
                local ang = (math.random()-0.5)*math.rad(fakePosCfg.scatterAngle)
                ox = math.cos(ang)*(math.random()*lr); oy = fakePosCfg.height+math.random()*fakePosCfg.yDist; oz = math.sin(ang)*(math.random()*lr)
            elseif pat == "Linear" then
                fakePosHue = fakePosHue + 0.05; local t = fakePosHue%1
                ox = (t-0.5)*2*lr; oy = fakePosCfg.height+math.random()*fakePosCfg.yDist; oz = (t-0.5)*2*lr
            elseif pat == "Circle" then
                fakePosAngle = (fakePosAngle+math.rad(fakePosCfg.speed*dt*60))%(2*math.pi)
                ox = math.cos(fakePosAngle)*lr; oy = fakePosCfg.height+math.random()*fakePosCfg.yDist; oz = math.sin(fakePosAngle)*lr
            elseif pat == "Random" then
                ox = (math.random()*2-1)*lr; oy = fakePosCfg.height+math.random()*fakePosCfg.yDist; oz = (math.random()*2-1)*lr
            elseif pat == "Spiral" then
                fakePosAngle = (fakePosAngle+math.rad(fakePosCfg.speed*dt*60))%(2*math.pi)
                local sr = lr*(0.3+0.7*(fakePosAngle/(2*math.pi)%1))
                ox = math.cos(fakePosAngle)*sr; oy = fakePosCfg.height+math.random()*fakePosCfg.yDist; oz = math.sin(fakePosAngle)*sr
            end
            local dist = fakePosCfg.distribution
            if dist == "Uniform" then local l = math.sqrt(ox*ox+oz*oz); if l>0 then local s=lr/l; ox=ox*s; oz=oz*s end
            elseif dist == "Weighted" then ox=ox*0.6; oz=oz*0.6
            elseif dist == "Radial" then local a=math.atan2(oz,ox); ox=math.cos(a)*lr; oz=math.sin(a)*lr
            elseif dist == "Clustered" then local o=math.floor(math.random()*8)*(math.pi*0.25); ox=math.cos(o)*lr; oz=math.sin(o)*lr end
            local al = fakePosCfg.axisLock
            if al=="X" then oz=0; oy=fakePosCfg.height elseif al=="Y" then ox=0; oz=0 elseif al=="Z" then ox=0; oy=fakePosCfg.height elseif al=="XZ" then oy=fakePosCfg.height end
            local fp = fakePosAnchor + Vector3.new(ox, oy, oz)
            if rni then pcall(rni, rootPart, "AssemblyLinearVelocity", Vector3.zero); pcall(rni, rootPart, "CFrame", fp); pcall(rni, rootPart, "AssemblyLinearVelocity", Vector3.zero)
            else pcall(function() rootPart.AssemblyLinearVelocity=Vector3.zero; rootPart.CFrame=fp; rootPart.AssemblyLinearVelocity=Vector3.zero end) end
        end
    end)
    fakePosRender = RunService.RenderStepped:Connect(function()
        if fakePosCfg.enabled and rootPart and fakePosAnchor then
            rootPart.CFrame = fakePosAnchor; rootPart.AssemblyLinearVelocity = Vector3.zero; rootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- Velocity desync
local velDesyncConn = nil; local velDesyncConn2 = nil
local desyncSavedVel = nil; local desyncAngle = 0; local desyncFlipTimer = 0
local desyncOscTime = 0; local desyncBurstTimer = 0; local desyncFlipState = false

local function disableVelDesync()
    if velDesyncConn  then velDesyncConn:Disconnect();  velDesyncConn = nil  end
    if velDesyncConn2 then velDesyncConn2:Disconnect(); velDesyncConn2 = nil end
    desyncSavedVel = nil; desyncAngle = 0; velDesyncCfg.enabled = false
end

local function enableVelDesync()
    if velDesyncConn  then velDesyncConn:Disconnect()  end
    if velDesyncConn2 then velDesyncConn2:Disconnect() end
    desyncSavedVel = nil; desyncAngle = 0; desyncFlipTimer = 0; desyncOscTime = 0; desyncBurstTimer = 0; desyncFlipState = false
    velDesyncConn = RunService.Heartbeat:Connect(function(dt)
        local root = getRoot()
        if not velDesyncCfg.enabled or not root then return end
        desyncSavedVel = root.AssemblyLinearVelocity
        desyncFlipTimer = desyncFlipTimer+dt; desyncBurstTimer = desyncBurstTimer+dt; desyncOscTime = desyncOscTime+dt
        if velDesyncCfg.invertOnTimer and desyncFlipTimer >= velDesyncCfg.invertInterval then desyncFlipTimer=0; desyncFlipState=not desyncFlipState end
        local sign = (velDesyncCfg.flip or desyncFlipState) and -1 or 1
        desyncAngle = (desyncAngle+math.rad(math.clamp(velDesyncCfg.speed,1,100)*dt*360))%(2*math.pi)
        local ba = velDesyncCfg.randomizeAngle and math.rad(velDesyncCfg.angleMin+math.random()*(velDesyncCfg.angleMax-velDesyncCfg.angleMin)) or math.rad(velDesyncCfg.angle)
        local ang = ba + math.rad((math.random()-0.5)*math.clamp(velDesyncCfg.jitter,0,180)*2) + desyncAngle
        if velDesyncCfg.oscillate then ang = ang + math.rad(math.sin(desyncOscTime*velDesyncCfg.oscillateFreq*2*math.pi)*velDesyncCfg.oscillateAmp) end
        if velDesyncCfg.rotateVel  then ang = ang + math.rad(velDesyncCfg.rotateVelSpeed)*dt end
        local mag = math.clamp(velDesyncCfg.intensity,1,100)/100*50000
        if velDesyncCfg.spikeMode  and desyncBurstTimer >= velDesyncCfg.spikeInterval then desyncBurstTimer=0; mag=mag+velDesyncCfg.spikeMag end
        if velDesyncCfg.burstDesync and desyncBurstTimer >= velDesyncCfg.burstEvery   then mag=mag+velDesyncCfg.burstMag end
        local nx, nz = 0, 0
        if velDesyncCfg.noiseVel then local nt=tick()*velDesyncCfg.noiseScale; nx=math.noise(nt,0,0)*mag*0.5; nz=math.noise(0,nt,0)*mag*0.5 end
        local vels = {}
        local vc = velDesyncCfg.multiVector and velDesyncCfg.vectorCount or 1
        for i = 1, vc do
            local va = ang + (i-1)*(2*math.pi/vc)
            table.insert(vels, Vector3.new(math.cos(va)*mag*sign+nx, (math.random()-0.5)*mag*0.5, math.sin(va)*mag*sign+nz))
        end
        if velDesyncCfg.counterVel and desyncSavedVel then table.insert(vels, -desyncSavedVel*2) end
        local meta = getrawmetatable and getrawmetatable(root)
        local rni  = meta and rawget(meta, "__newindex")
        for _, vel in ipairs(vels) do
            if rni then pcall(rni, root, "AssemblyLinearVelocity", vel) else pcall(function() root.AssemblyLinearVelocity=vel end) end
            if sethiddenproperty then pcall(sethiddenproperty, root, "AssemblyLinearVelocity", vel) end
        end
    end)
    velDesyncConn2 = RunService.RenderStepped:Connect(function()
        local root = getRoot()
        if velDesyncCfg.enabled and root and desyncSavedVel then root.AssemblyLinearVelocity = desyncSavedVel end
    end)
end

-- Fast melee
local fastMeleeConn = nil

local function cacheMeleeTables()
    if #fastMeleeCfg.cached > 0 or type(getgc) ~= "function" then return end
    pcall(function()
        for _, t in pairs(getgc(true)) do
            if type(t)=="table" and (rawget(t,"MeleeCooldown") or rawget(t,"AttackCooldown")) then
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
            if rawget(t,"MeleeCooldown")  then t.MeleeCooldown  = fastMeleeCfg.cooldown end
            if rawget(t,"AttackCooldown") then t.AttackCooldown = fastMeleeCfg.cooldown end
        end
    end)
end

-- Character lifecycle
local function onCharacterAdded(newChar)
    character = newChar
    rootPart  = newChar:WaitForChild("HumanoidRootPart", 5)
    humanoid  = newChar:WaitForChild("Humanoid", 5)
    if voidCfg.VOID_ENABLED      then enableVoid()         end
    if orbitCfg.orbitEnabled     then enableOrbit()        end
    if predictCfg.predEnabled    then enablePrediction()   end
    if antiAimCfg.enabled        then enableAntiAim()      end
    if undergroundCfg.enabled    then enableUndergroundAA() end
    if translocCfg.enabled       then enableTransloc()     end
    if fakePosCfg.enabled        then enableFakePos()      end
    if velDesyncCfg.enabled      then enableVelDesync()    end
    if fastGunState.primaryOn    then fastGunTick()        end
end

if localPlayer.Character then onCharacterAdded(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(function(c) task.wait(0.3); onCharacterAdded(c) end)
localPlayer.CharacterRemoving:Connect(function()
    for n in pairs(connections) do disconnectConn(n) end
    if translocConn    then translocConn:Disconnect();    translocConn = nil    end
    if fakePosHeartbeat then fakePosHeartbeat:Disconnect(); fakePosHeartbeat = nil end
    if fakePosRender   then fakePosRender:Disconnect();   fakePosRender = nil   end
    if velDesyncConn   then velDesyncConn:Disconnect();   velDesyncConn = nil   end
    if velDesyncConn2  then velDesyncConn2:Disconnect();  velDesyncConn2 = nil  end
    if undergroundConn then undergroundConn:Disconnect(); undergroundConn = nil end
    rootPart = nil; humanoid = nil; character = nil
end)

-- ============================================================
-- BUILD TABS
-- ============================================================
-- TAB: Void  (icon: activity)
local voidTab = NewTab("Void", 10244689938)
local vgEngine = voidTab:Group("Engine")
vgEngine:Toggle({ Name = "Enable Void", Default = false, Callback = function(v) voidCfg.VOID_ENABLED = v; if v then enableVoid() else disableVoid() end end })
vgEngine:Dropdown({ Name = "Method", Options = {"Attacker","Chaos","Quantum","Freeze Bait"}, Default = "Quantum", Callback = function(v) voidCfg.VOID_METHOD = v; voidPhaseTime = 0; voidBaitPhase = false end })
vgEngine:Toggle({ Name = "Wireframe ESP", Default = false, Callback = function(v) setWireframes(v) end })

local vgMotion = voidTab:Group("Motion")
vgMotion:Slider({ Name = "Writes/Frame", Min = 1, Max = 8, Default = 1, Increment = 1, Callback = function(v) voidCfg.VOID_WRITES_PER_FRAME = v end })
vgMotion:Toggle({ Name = "Interpolate", Default = true, Callback = function(v) voidCfg.VOID_INTERP = v end })
vgMotion:Slider({ Name = "Interp Alpha", Min = 1, Max = 100, Default = 35, Unit = "%", Callback = function(v) voidCfg.VOID_INTERP_ALPHA = v/100 end })

local vgSpace = voidTab:Group("Space")
vgSpace:Slider({ Name = "Radius", Min = 1, Max = 10000000, Default = 10000000, Increment = 10000, Callback = function(v) voidCfg.RADIUS = v end })
vgSpace:Slider({ Name = "Y Min", Min = -10000000, Max = 0, Default = -10000000, Increment = 10000, Callback = function(v) voidCfg.VOID_Y_MIN = v end })
vgSpace:Slider({ Name = "Y Max", Min = 0, Max = 10000000, Default = 10000000, Increment = 10000, Callback = function(v) voidCfg.VOID_Y_MAX = v end })

local vgBait = voidTab:Group("Bait/Attacker")
vgBait:Slider({ Name = "Att Interval (s)", Min = 1, Max = 10, Default = 4, Increment = 1, Callback = function(v) voidCfg.VOID_ATTACKER_INTERVAL = v end })
vgBait:Slider({ Name = "Att Freeze (s)",   Min = 1, Max = 20, Default = 4, Increment = 1, Callback = function(v) voidCfg.VOID_ATTACKER_DURATION = v/10 end })
vgBait:Slider({ Name = "Bait Interval (s)", Min = 1, Max = 10, Default = 3, Increment = 1, Callback = function(v) voidCfg.VOID_BAIT_INTERVAL = v end })
vgBait:Slider({ Name = "Bait Freeze (s)",   Min = 1, Max = 20, Default = 4, Increment = 1, Callback = function(v) voidCfg.VOID_BAIT_DURATION = v/10 end })

-- TAB: Orbit
local orbitTab = NewTab("Orbit", 10244689938)
local ogMain = orbitTab:Group("Orbit")
ogMain:Toggle({ Name = "Enable Orbit", Default = false, Callback = function(v) orbitCfg.orbitEnabled = v; if v then enableOrbit() else disableOrbit() end end })
ogMain:Dropdown({ Name = "Direction", Options = {"Clockwise","Counter-Clockwise"}, Default = "Clockwise", Callback = function(v) orbitCfg.orbitMode = v end })
ogMain:Slider({ Name = "Speed",  Min = 5,    Max = 1000, Default = 90, Increment = 5,  Callback = function(v) orbitCfg.orbitSpeed  = v end })
ogMain:Slider({ Name = "Radius", Min = 1,    Max = 50,   Default = 8,  Increment = 1,  Callback = function(v) orbitCfg.orbitDist   = v end })
ogMain:Slider({ Name = "Height", Min = -100, Max = 100,  Default = 0,  Increment = 1,  Callback = function(v) orbitCfg.orbitHeight = v end })

-- TAB: Defense
local defTab = NewTab("Defense", 10244689938)
local dgAA = defTab:Group("Anti-Aim")
dgAA:Toggle({ Name = "Enable Anti-Aim", Default = false, Callback = function(v) antiAimCfg.enabled = v; if v then enableAntiAim() else disableAntiAim() end end })
dgAA:Slider({ Name = "Pitch Max", Min = 1, Max = 360, Default = 360, Unit = "°", Callback = function(v) antiAimCfg.pitch = v end })
dgAA:Slider({ Name = "Yaw Max",   Min = 1, Max = 360, Default = 360, Unit = "°", Callback = function(v) antiAimCfg.yaw   = v end })

local dgUG = defTab:Group("Underground AA")
dgUG:Toggle({ Name = "Enable UG AA", Default = false, Callback = function(v) undergroundCfg.enabled = v; if v then enableUndergroundAA() else disableUndergroundAA() end end })
dgUG:Slider({ Name = "Depth",        Min = 10, Max = 50,   Default = 15, Increment = 1, Callback = function(v) undergroundCfg.depth       = v/10 end })
dgUG:Slider({ Name = "Orbit Radius", Min = 0,  Max = 100,  Default = 30, Increment = 1, Callback = function(v) undergroundCfg.orbitRadius  = v/10 end })
dgUG:Slider({ Name = "Orbit Speed",  Min = 50, Max = 1000, Default = 200,Increment = 10,Callback = function(v) undergroundCfg.orbitSpeed   = v end })
dgUG:Slider({ Name = "Spin Speed",   Min = 100,Max = 2000, Default = 720,Increment = 10,Callback = function(v) undergroundCfg.spinSpeed    = v end })

local dgPred = defTab:Group("Prediction")
dgPred:Toggle({ Name = "Enable Prediction",    Default = false, Callback = function(v) predictCfg.predEnabled   = v; if v then enablePrediction() else disablePrediction() end end })
dgPred:Toggle({ Name = "Track Enemy Velocity", Default = true,  Callback = function(v) predictCfg.predKinematic  = v end })
dgPred:Toggle({ Name = "Predict Shot Path",    Default = true,  Callback = function(v) predictCfg.predPredictive = v end })
dgPred:Slider({ Name = "Danger Radius", Min = 5,   Max = 5000, Default = 150, Increment = 5, Callback = function(v) predictCfg.predRadius = v end })
dgPred:Slider({ Name = "Dodge Dist",    Min = 5,   Max = 500,  Default = 80,  Increment = 5, Callback = function(v) predictCfg.predDodgeDist = v end })

local dgVD = defTab:Group("Vel Desync")
dgVD:Toggle({ Name = "Enable VD",    Default = false, Callback = function(v) velDesyncCfg.enabled = v; if v then enableVelDesync() else disableVelDesync() end end })
dgVD:Slider({ Name = "Intensity %",  Min = 1, Max = 100, Default = 50, Unit = "%", Callback = function(v) velDesyncCfg.intensity = v end })
dgVD:Slider({ Name = "Base Angle",   Min = 0, Max = 360, Default = 90, Unit = "°", Callback = function(v) velDesyncCfg.angle     = v end })
dgVD:Slider({ Name = "Jitter",       Min = 0, Max = 180, Default = 20, Unit = "°", Callback = function(v) velDesyncCfg.jitter    = v end })
dgVD:Toggle({ Name = "Flip Dir",     Default = false, Callback = function(v) velDesyncCfg.flip      = v end })
dgVD:Toggle({ Name = "Oscillate",    Default = false, Callback = function(v) velDesyncCfg.oscillate = v end })
dgVD:Toggle({ Name = "Spike Mode",   Default = false, Callback = function(v) velDesyncCfg.spikeMode = v end })
dgVD:Toggle({ Name = "Multi Vector", Default = false, Callback = function(v) velDesyncCfg.multiVector = v end })
dgVD:Toggle({ Name = "Burst Desync", Default = false, Callback = function(v) velDesyncCfg.burstDesync = v end })

local dgFP = defTab:Group("Fake Position")
dgFP:Toggle({ Name = "Enable Fake Pos", Default = false, Callback = function(v) fakePosCfg.enabled = v; if v then enableFakePos() else disableFakePos() end end })
dgFP:Dropdown({ Name = "Pattern",      Options = {"Scatter","Linear","Circle","Random","Spiral"}, Default = "Scatter", Callback = function(v) fakePosCfg.pattern = v end })
dgFP:Dropdown({ Name = "Distribution", Options = {"Random","Uniform","Weighted","Radial","Clustered"}, Default = "Random", Callback = function(v) fakePosCfg.distribution = v end })
dgFP:Dropdown({ Name = "Axis Lock",    Options = {"None","X","Y","Z","XZ"}, Default = "None", Callback = function(v) fakePosCfg.axisLock = v end })
dgFP:Toggle({ Name = "Randomize/Frame", Default = false, Callback = function(v) fakePosCfg.randomizeEveryFrame = v end })
dgFP:Toggle({ Name = "Layered Fake",    Default = false, Callback = function(v) fakePosCfg.layeredFake = v end })
dgFP:Toggle({ Name = "Chaos Mode",      Default = false, Callback = function(v) fakePosCfg.chaosMode = v end })
dgFP:Toggle({ Name = "Pulse Radius",    Default = false, Callback = function(v) fakePosCfg.pulseRadius = v end })

-- TAB: Transloc
local transTab = NewTab("Transloc", 10244689938)
local tgMain = transTab:Group("Translocation")
tgMain:Toggle({ Name = "Enable Transloc", Default = false, Callback = function(v) translocCfg.enabled = v; if v then enableTransloc() else disableTransloc() end end })
tgMain:Slider({ Name = "Jitter X", Min = 1, Max = 10000000, Default = 10000000, Increment = 100000, Callback = function(v) translocCfg.jitterX = v end })
tgMain:Slider({ Name = "Jitter Y", Min = 1, Max = 10000000, Default = 10000000, Increment = 100000, Callback = function(v) translocCfg.jitterY = v end })
tgMain:Toggle({ Name = "Fake Velocity", Default = true, Callback = function(v) translocCfg.fakeVel = v end })
tgMain:Toggle({ Name = "Burst Mode",    Default = false, Callback = function(v) translocCfg.burstMode = v end })
tgMain:Slider({ Name = "Burst Count", Min = 2, Max = 50, Default = 10, Increment = 1, Callback = function(v) translocCfg.burstCount = v end })

-- TAB: Extras
local extTab = NewTab("Extras", 10244689938)
local egKA = extTab:Group("Kill Aura")
egKA:Toggle({ Name = "Enable Kill Aura", Default = false, Callback = function(v) killAuraCfg.enabled = v; if v then enableKillAura() else disableKillAura() end end })
egKA:Slider({ Name = "Fire Rate ms", Min = 1, Max = 500, Default = 20, Increment = 1, Callback = function(v) killAuraCfg.fireRate = v/1000 end })
egKA:Slider({ Name = "Radius",       Min = 10, Max = 10000, Default = 5000, Increment = 50, Callback = function(v) killAuraCfg.radius = v end })
egKA:Toggle({ Name = "Auto Equip",   Default = true, Callback = function(v) killAuraCfg.autoEquip = v end })

local egFM = extTab:Group("Fast Melee")
egFM:Toggle({ Name = "Enable Fast Melee", Default = false, Callback = function(v) fastMeleeCfg.enabled = v; if v then enableFastMelee() else disableFastMelee() end end })
egFM:Slider({ Name = "Cooldown", Min = 0, Max = 50, Default = 0, Increment = 1, Callback = function(v) fastMeleeCfg.cooldown = v/10 end })

local egFG = extTab:Group("Fast Gun")
egFG:Toggle({ Name = "Enable Fast Gun", Default = false, Callback = function(v) fastGunState.primaryOn = v; if v then patchEquippedGuns() end end })
egFG:Button({ Name = "Rescan & Repatch", Style = "Primary", Callback = function() fastGunState.primaryOn = true; patchEquippedGuns() end })

-- TAB: Settings
local cfgTab = NewTab("Settings", 10244689938)
local sgPresets = cfgTab:Group("Presets")
sgPresets:Button({ Name = "Kill All Systems", Style = "Danger", Callback = function()
    voidCfg.VOID_ENABLED = false;      disableVoid()
    orbitCfg.orbitEnabled = false;     disableOrbit()
    predictCfg.predEnabled = false;    disablePrediction()
    antiAimCfg.enabled = false;        disableAntiAim()
    undergroundCfg.enabled = false;    disableUndergroundAA()
    translocCfg.enabled = false;       disableTransloc()
    fakePosCfg.enabled = false;        disableFakePos()
    velDesyncCfg.enabled = false;      disableVelDesync()
    fastMeleeCfg.enabled = false;      disableFastMelee()
    killAuraCfg.enabled = false;       disableKillAura()
    disableWireframes()
    fastGunState.primaryOn = false
    Notify("Presets", "All systems off", "warning", 3)
end})

local sgChar = cfgTab:Group("Character")
sgChar:Button({ Name = "Reload Character", Callback = function() if localPlayer.Character then localPlayer.Character:BreakJoints() end end })
sgChar:Button({ Name = "Rejoin Server", Callback = function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer) end) end })

-- ============================================================
-- POSITION HUD (from RCLC)
-- ============================================================
local function createPositionHud()
    local old = CoreGui:FindFirstChild("ArchPositionHUD"); if old then old:Destroy() end
    local hg = Instance.new("ScreenGui"); hg.Name="ArchPositionHUD"; hg.ResetOnSpawn=false; hg.DisplayOrder=9998; hg.IgnoreGuiInset=true; hg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    if not pcall(function() hg.Parent=CoreGui end) or not hg.Parent then hg.Parent=localPlayer:WaitForChild("PlayerGui") end
    local accent=CFG.AccentColor; local bg=CFG.MainColor; local bg2=CFG.SecondaryColor; local stroke=CFG.StrokeColor
    local panel = Create("Frame", { Parent=hg, Name="PositionHUD", Size=UDim2.fromOffset(190,120), Position=UDim2.new(0,16,0.5,-60), BackgroundColor3=bg, BackgroundTransparency=0.05, BorderSizePixel=0 }, { Create("UICorner",{CornerRadius=UDim.new(0,10)}), Create("UIStroke",{Color=stroke, Thickness=1}) })
    Create("TextLabel", { Parent=panel, Text="POSITION  ·  Arch", TextColor3=accent, Font=Enum.Font.GothamBold, TextSize=11, BackgroundTransparency=1, Size=UDim2.new(1,-12,0,18), Position=UDim2.fromOffset(10,8), TextXAlignment=Enum.TextXAlignment.Left })
    Create("Frame", { Parent=panel, Size=UDim2.new(1,-20,0,1), Position=UDim2.fromOffset(10,28), BackgroundColor3=stroke, BorderSizePixel=0 })
    local vl = {}
    for i, axis in ipairs({"X","Y","Z"}) do
        local row = Create("Frame", { Parent=panel, Size=UDim2.new(1,-20,0,22), Position=UDim2.fromOffset(10,32+(i-1)*26), BackgroundColor3=bg2, BackgroundTransparency=0.3, BorderSizePixel=0 }, { Create("UICorner",{CornerRadius=UDim.new(0,5)}) })
        Create("TextLabel", { Parent=row, Text=axis, TextColor3=accent, Font=Enum.Font.GothamBold, TextSize=11, BackgroundTransparency=1, Size=UDim2.fromOffset(16,22), Position=UDim2.fromOffset(6,0), TextXAlignment=Enum.TextXAlignment.Left })
        vl[axis] = Create("TextLabel", { Parent=row, Text="0.00", TextColor3=CFG.TextColor, Font=CFG.Font, TextSize=12, BackgroundTransparency=1, Size=UDim2.new(1,-30,1,0), Position=UDim2.fromOffset(28,0), TextXAlignment=Enum.TextXAlignment.Right })
    end
    local lx, ly, lz = "","",""
    RunService.Heartbeat:Connect(function()
        if not hg.Parent then return end
        local c = localPlayer and localPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then
            local tx = ("%.2f"):format(r.Position.X); if tx~=lx then vl.X.Text=tx; lx=tx end
            local ty = ("%.2f"):format(r.Position.Y); if ty~=ly then vl.Y.Text=ty; ly=ty end
            local tz = ("%.2f"):format(r.Position.Z); if tz~=lz then vl.Z.Text=tz; lz=tz end
        elseif lx~="0.00" then vl.X.Text="0.00"; vl.Y.Text="0.00"; vl.Z.Text="0.00"; lx="0.00"; ly="0.00"; lz="0.00" end
    end)
    return hg
end
createPositionHud()

-- ============================================================
-- MENU TOGGLE  (Insert key)
-- ============================================================
Library.MenuKey = Enum.KeyCode.Insert
local Visible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Library.MenuKey then
        Visible = not Visible
        MainFrame.Visible = Visible
    end
end)

local MobileToggle = Create("ImageButton", {
    Parent          = ScreenGui,
    Size            = UDim2.new(0, 40, 0, 40),
    Position        = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint     = Vector2.new(0.5, 0),
    BackgroundColor3 = CFG.MainColor,
    Image           = "rbxassetid://3926305904",
    ImageColor3     = CFG.AccentColor,
    AutoButtonColor = false,
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    Create("UIStroke", { Color = CFG.AccentColor, Thickness = 2 }),
})
MobileToggle.MouseButton1Click:Connect(function()
    Visible = not Visible; MainFrame.Visible = Visible
end)

-- ============================================================
-- BOOT NOTIFY
-- ============================================================
Notify("Arch script beta", "Loaded — Insert to toggle", "success", 4)
