--[[
    eclipse.wtf | KiciaRebuild Ragebot & Flickbot UI — FIXED
    修复内容:
      1. GetStore() 正确通过 K._store 获取 ReactiveStore 实例
      2. SetData() 改用 store:Set(path, value) — 触发 KiciaRebuild 内部监听器
      3. ReadData() 改用 store:Get(path)
      4. DepthForward / DepthUp 滑块每次创建新 table，确保 store 检测到变更
      5. Flickbot / Ragebot Enable 同时设置 Keybind.Kind="Always" + Keybind.State
      6. 保留全部触屏兼容、拖拽、滑块、移动端按钮

    ⚠ 前置要求：在 KiciaRebuild 主脚本末尾、tbl17.j1()(boot) 这行之前
       插入一行：  K._store = tbl17.bG()
       这样本 UI 才能拿到 ReactiveStore。
]]

-- ============================================================
-- 基础服务
-- ============================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local Player = Players.LocalPlayer

-- ============================================================
-- 安全获取 ReactiveStore
-- 需要 KiciaRebuild 主脚本末尾有:  K._store = tbl17.bG()
-- ============================================================
local function GetStore()
    local K = getgenv and getgenv().KiciaRebuild
    if K and K._store then return K._store end
    return nil
end

-- store:Set(path, value) — 写入并触发全部内部监听器
local function SetData(path, value)
    local store = GetStore()
    if not store then return end
    store:Set(path, value)
end

-- store:Get(path) — 读取当前值
local function ReadData(path)
    local store = GetStore()
    if not store then return nil end
    return store:Get(path)
end

-- DepthForward / DepthUp 专用写入：每次返回新 table
-- store:Set 通过引用比较判断是否变更，必须传新表才能触发监听器
local function SetDepth(path, key, value)
    local store = GetStore()
    if not store then return end
    local cur = store:Get(path) or {}
    store:Set(path, { Min = cur.Min or 0, Max = cur.Max or 0, [key] = value })
end

-- ============================================================
-- UI 配置
-- ============================================================
local CFG = {
    MainColor      = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor    = Color3.fromRGB(189, 172, 255),
    TextColor      = Color3.fromRGB(200, 200, 200),
    TextDark       = Color3.fromRGB(120, 120, 120),
    StrokeColor    = Color3.fromRGB(40, 40, 40),
    Font           = Enum.Font.Code,
    BaseSize       = Vector2.new(600, 450)
}

local Library = {
    Flags       = {},
    Connections = {},
    Unloaded    = false
}

-- ============================================================
-- 工具函数
-- ============================================================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do inst[i] = v end
    for _, child in pairs(children or {}) do child.Parent = inst end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

-- ============================================================
-- ScreenGui
-- ============================================================
local ScreenGui = Create("ScreenGui", {
    Name           = "EclipseUI",
    Parent         = game:GetService("CoreGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true
})

local UIScale = Create("UIScale", { Parent = ScreenGui })

local function UpdateScale()
    local vp         = workspace.CurrentCamera.ViewportSize
    local widthRatio  = (vp.X - 40) / CFG.BaseSize.X
    local heightRatio = (vp.Y - 40) / CFG.BaseSize.Y
    UIScale.Scale    = math.max(math.min(widthRatio, heightRatio, 1), 0.6)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

-- ============================================================
-- 通知系统
-- ============================================================
local NotificationContainer = Create("Frame", {
    Parent              = ScreenGui,
    Position            = UDim2.new(1, -20, 0, 20),
    AnchorPoint         = Vector2.new(1, 0),
    Size                = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex              = 100
})
Create("UIListLayout", {
    Parent              = NotificationContainer,
    Padding             = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment   = Enum.VerticalAlignment.Top
})

function Library:Notify(msg, ntype)
    local color = (ntype == "success" and Color3.fromRGB(100, 255, 100))
               or (ntype == "warning" and Color3.fromRGB(255, 100, 100))
               or CFG.AccentColor

    local Frame = Create("Frame", {
        Parent           = NotificationContainer,
        Size             = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel  = 0,
        ClipsDescendants = true
    }, {
        Create("UIStroke",  { Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5 }),
        Create("Frame",     { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = color }),
        Create("TextLabel", {
            Text               = msg,
            TextColor3         = CFG.TextColor,
            Font               = CFG.Font,
            TextSize           = 12,
            Size               = UDim2.new(1, -10, 1, 0),
            Position           = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment     = Enum.TextXAlignment.Left
        })
    })

    Tween(Frame, { Size = UDim2.new(0, 250, 0, 35) }, 0.5, Enum.EasingStyle.Back)
    task.delay(3, function()
        Tween(Frame, { Size = UDim2.new(0, 250, 0, 0), BackgroundTransparency = 1 }, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

-- ============================================================
-- 主窗口
-- ============================================================
local MainFrame = Create("Frame", {
    Name             = "MainFrame",
    Parent           = ScreenGui,
    Size             = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position         = UDim2.new(0.5, -300, 0.5, -225),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0
}, {
    Create("UIStroke", { Color = CFG.StrokeColor }),
    Create("UICorner", { CornerRadius = UDim.new(0, 3) })
})

-- 触屏拖拽
local Dragging, DragStart, StartPos, DragInput = false, nil, nil, nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Dragging  = true
        DragStart = input.Position
        StartPos  = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        Tween(MainFrame, {
            Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + delta.Y
            )
        }, 0.05)
    end
end)

-- ============================================================
-- 顶栏 + 标题动画
-- ============================================================
local TopBar = Create("Frame", {
    Parent           = MainFrame,
    Size             = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0
}, {
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor
    })
})

local TitleLabel = Create("TextLabel", {
    Parent             = TopBar,
    Text               = "eclipse.wtf | rivals",
    TextColor3         = CFG.TextDark,
    TextSize           = 13,
    Font               = CFG.Font,
    BackgroundTransparency = 1,
    Size               = UDim2.new(0, 200, 1, 0),
    Position           = UDim2.new(0, 10, 0, 0),
    TextXAlignment     = Enum.TextXAlignment.Left,
    RichText           = true
})

task.spawn(function()
    local textList = {
        '', 'e', 'ec', 'ecl', 'ecli', 'eclip', 'eclipse', 'eclipse.', 'eclipse.w',
        'eclipse.wt', 'eclipse.wtf', 'eclipse.wtf |', 'eclipse.wtf | r',
        'eclipse.wtf | ri', 'eclipse.wtf | riv', 'eclipse.wtf | riva',
        'eclipse.wtf | rival', 'eclipse.wtf | rivals',
        'eclipse.wtf | rival', 'eclipse.wtf | riva', 'eclipse.wtf | riv',
        'eclipse.wtf | ri', 'eclipse.wtf | r', 'eclipse.wtf |',
        'eclipse.wtf', 'eclipse.wt', 'eclipse.w', 'eclipse.',
        'eclipse', 'eclips', 'eclip', 'ecli', 'ecl', 'ec', 'e'
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "rivals") then
                display = string.gsub(text, "rivals", '<font color="#bdacff">rivals</font>')
            elseif string.find(text, "wtf") then
                display = string.gsub(text, "wtf", '<font color="#bdacff">wtf</font>')
            end
            TitleLabel.Text = display
            task.wait(0.18)
        end
    end
end)

-- ============================================================
-- 内容容器 + 侧边栏 + 页面容器
-- ============================================================
local ContentContainer = Create("Frame", {
    Parent             = MainFrame,
    Size               = UDim2.new(1, 0, 1, -30),
    Position           = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1
})

local Sidebar = Create("Frame", {
    Parent           = ContentContainer,
    Size             = UDim2.new(0, 60, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel  = 0
}, {
    Create("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = CFG.StrokeColor
    }),
    Create("UIListLayout", {
        Padding             = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment   = Enum.VerticalAlignment.Top
    }),
    Create("UIPadding", { PaddingTop = UDim.new(0, 15) })
})

local PagesContainer = Create("Frame", {
    Parent             = ContentContainer,
    Size               = UDim2.new(1, -60, 1, 0),
    Position           = UDim2.new(0, 60, 0, 0),
    BackgroundTransparency = 1
})

local Tabs = {}

-- ============================================================
-- Tab / Group / 控件构建器
-- ============================================================
function Library:Tab(name, icon)
    local TabButton = Create("TextButton", {
        Parent           = Sidebar,
        Size             = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = CFG.MainColor,
        Text             = "",
        AutoButtonColor  = false
    }, {
        Create("ImageLabel", {
            Name               = "Icon",
            Size               = UDim2.new(0.6, 0, 0.6, 0),
            Position           = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image              = "rbxassetid://" .. tostring(icon),
            ImageColor3        = CFG.TextDark
        }),
        Create("UICorner", { CornerRadius = UDim.new(0, 6) })
    })

    local PageFrame = Create("ScrollingFrame", {
        Parent               = PagesContainer,
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible              = false,
        ScrollBarThickness   = 2,
        ScrollBarImageColor3 = CFG.AccentColor,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y
    })
    Create("UIPadding", {
        Parent        = PageFrame,
        PaddingTop    = UDim.new(0, 15),
        PaddingLeft   = UDim.new(0, 15),
        PaddingRight  = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15)
    })

    local LeftCol = Create("Frame", {
        Parent             = PageFrame,
        Size               = UDim2.new(0.48, 0, 1, 0),
        BackgroundTransparency = 1
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    })
    local RightCol = Create("Frame", {
        Parent             = PageFrame,
        Size               = UDim2.new(0.48, 0, 1, 0),
        Position           = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
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
    end)
    table.insert(Tabs, { Btn = TabButton, Page = PageFrame })
    if #Tabs == 1 then
        Tween(TabButton, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        TabButton.Icon.ImageColor3 = CFG.AccentColor
        PageFrame.Visible = true
    end

    local GroupFunctions = {}
    local LeftSide = true

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol
        LeftSide = not LeftSide

        local GroupFrame = Create("Frame", {
            Parent           = ParentCol,
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel  = 0
        }, {
            Create("UIStroke", { Color = CFG.StrokeColor }),
            Create("UICorner", { CornerRadius = UDim.new(0, 2) })
        })

        Create("Frame", {
            Parent           = GroupFrame,
            Size             = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel  = 0
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 5),
                Position         = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0
            }),
            Create("TextLabel", {
                Text               = title,
                Size               = UDim2.new(1, -20, 1, 0),
                Position           = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3         = CFG.TextColor,
                Font               = Enum.Font.GothamBold,
                TextSize           = 11,
                TextXAlignment     = Enum.TextXAlignment.Left
            }),
            Create("Frame", {
                Size             = UDim2.new(0, 4, 0, 4),
                Position         = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel  = 0
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        })

        local Content = Create("Frame", {
            Parent             = GroupFrame,
            Size               = UDim2.new(1, 0, 0, 0),
            Position           = UDim2.new(0, 0, 0, 25),
            AutomaticSize      = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding", {
                PaddingTop    = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft   = UDim.new(0, 8),
                PaddingRight  = UDim.new(0, 8)
            })
        })

        local ItemFuncs = {}

        -- --------------------------------------------------------
        -- Toggle
        -- --------------------------------------------------------
        function ItemFuncs:Toggle(cfg)
            local Enabled = false
            local Frame = Create("TextButton", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text               = ""
            })
            local Box = Create("Frame", {
                Parent           = Frame,
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0
            }, { Create("UIStroke", { Color = CFG.StrokeColor }) })
            local Check = Create("Frame", {
                Parent             = Box,
                Size               = UDim2.new(1, -4, 1, -4),
                Position           = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint        = Vector2.new(0.5, 0.5),
                BackgroundColor3   = CFG.AccentColor,
                BackgroundTransparency = 1
            })
            local Label = Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Position           = UDim2.new(0, 18, 0, 0),
                Size               = UDim2.new(1, -18, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left
            })
            if cfg.Risky then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end

            local function Update()
                Enabled = not Enabled
                Tween(Check, { BackgroundTransparency = Enabled and 0 or 1 }, 0.1)
                Tween(Label, {
                    TextColor3 = Enabled and CFG.TextColor
                        or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)
                }, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end
            Frame.MouseButton1Click:Connect(Update)
            return { Set = function(v) if v ~= Enabled then Update() end end }
        end

        -- --------------------------------------------------------
        -- Slider
        -- --------------------------------------------------------
        function ItemFuncs:Slider(cfg)
            local Step   = cfg.Step or 1
            local Value  = cfg.Default or cfg.Min
            local DraggingSlider = false

            local Frame = Create("Frame", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1
            })
            Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 15),
                TextXAlignment     = Enum.TextXAlignment.Left
            })
            local ValueLabel = Create("TextLabel", {
                Parent             = Frame,
                Text               = tostring(Value) .. (cfg.Unit or ""),
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 15),
                TextXAlignment     = Enum.TextXAlignment.Right
            })
            local SliderBG = Create("Frame", {
                Parent           = Frame,
                Size             = UDim2.new(1, 0, 0, 6),
                Position         = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
            local Fill = Create("Frame", {
                Parent           = SliderBG,
                Size             = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local function UpdateSlider(input)
                local SizeX   = SliderBG.AbsoluteSize.X
                local PosX    = SliderBG.AbsolutePosition.X
                local Percent = math.clamp((input.Position.X - PosX) / SizeX, 0, 1)
                local raw     = cfg.Min + (cfg.Max - cfg.Min) * Percent
                if Step >= 1 then
                    Value = math.floor(raw + 0.5)
                else
                    local factor = 1 / Step
                    Value = math.floor(raw * factor + 0.5) / factor
                end
                Fill.Size       = UDim2.new(Percent, 0, 1, 0)
                ValueLabel.Text = tostring(Value) .. (cfg.Unit or "")
                if cfg.Callback then cfg.Callback(Value) end
            end

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if DraggingSlider and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then UpdateSlider(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)

            local pct = (Value - cfg.Min) / (cfg.Max - cfg.Min)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
        end

        -- --------------------------------------------------------
        -- Dropdown
        -- --------------------------------------------------------
        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current  = cfg.Default or cfg.Options[1]

            local Frame = Create("Frame", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex             = 20
            })
            Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 15),
                TextXAlignment     = Enum.TextXAlignment.Left
            })
            local MainBox = Create("TextButton", {
                Parent           = Frame,
                Size             = UDim2.new(1, 0, 0, 20),
                Position         = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
                Text             = "",
                AutoButtonColor  = false
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("TextLabel", {
                    Name               = "Val",
                    Text               = Current,
                    Size               = UDim2.new(1, -20, 1, 0),
                    Position           = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3         = CFG.TextColor,
                    TextSize           = 11,
                    Font               = CFG.Font,
                    TextXAlignment     = Enum.TextXAlignment.Left
                }),
                Create("TextLabel", {
                    Text               = "▼",
                    Size               = UDim2.new(0, 20, 1, 0),
                    Position           = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3         = CFG.TextDark,
                    TextSize           = 10
                })
            })
            local ListFrame = Create("ScrollingFrame", {
                Parent               = MainBox,
                Size                 = UDim2.new(1, 0, 0, 0),
                Position             = UDim2.new(0, 0, 1, 2),
                BackgroundColor3     = CFG.SecondaryColor,
                BorderSizePixel      = 0,
                Visible              = false,
                ZIndex               = 50,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                ScrollBarThickness   = 2
            }, {
                Create("UIStroke",     { Color = CFG.StrokeColor }),
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
                Create("UICorner",     { CornerRadius = UDim.new(0, 3) })
            })

            for _, opt in pairs(cfg.Options) do
                local Btn = Create("TextButton", {
                    Parent             = ListFrame,
                    Size               = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text               = opt,
                    TextColor3         = (opt == Current) and CFG.AccentColor or CFG.TextDark,
                    TextSize           = 11,
                    Font               = CFG.Font
                })
                Btn.MouseButton1Click:Connect(function()
                    Current = opt
                    MainBox.Val.Text = opt
                    if cfg.Callback then cfg.Callback(opt) end
                    Expanded = false
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end)
            end

            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, math.min(#cfg.Options * 20, 100)) }, 0.1)
                else
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end
            end)
        end

        -- --------------------------------------------------------
        -- Button
        -- --------------------------------------------------------
        function ItemFuncs:Button(cfg)
            local Btn = Create("TextButton", {
                Parent           = Content,
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                Text             = cfg.Name,
                TextColor3       = CFG.TextDark,
                Font             = Enum.Font.GothamBold,
                TextSize         = 10
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) })
            })
            if cfg.Variant == "Primary" then
                Btn.BackgroundColor3 = CFG.AccentColor
                Btn.TextColor3       = Color3.new(0, 0, 0)
            elseif cfg.Variant == "Danger" then
                Btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                Btn.TextColor3       = Color3.new(0, 0, 0)
            end
            Btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
            end)
        end

        return ItemFuncs
    end

    return GroupFunctions
end

-- ============================================================
-- 隐藏/显示按钮 (移动端)
-- ============================================================
local Visible = true
local MobileToggle = Create("ImageButton", {
    Parent           = ScreenGui,
    Size             = UDim2.new(0, 40, 0, 40),
    Position         = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint      = Vector2.new(0.5, 0),
    BackgroundColor3 = CFG.MainColor,
    Image            = "rbxassetid://3926305904",
    ImageColor3      = CFG.AccentColor,
    AutoButtonColor  = false
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    Create("UIStroke", { Color = CFG.AccentColor, Thickness = 2 })
})
MobileToggle.MouseButton1Click:Connect(function()
    Visible = not Visible
    MainFrame.Visible = Visible
end)

-- ============================================================
-- 标签页
-- ============================================================
local RageTab  = Library:Tab("Rage",  10455604811)
local FlickTab = Library:Tab("Flick", 98159911363596)
local MiscTab  = Library:Tab("Misc",  11888734334)

-- ============================================================
-- RAGEBOT
-- ============================================================
local RageActivation = RageTab:Group("Activation")

RageActivation:Toggle({
    Name = "Enable Ragebot",
    Callback = function(v)
        -- ✅ 用 store:Set() 触发 KiciaRebuild 内部监听器
        SetData({"Ragebot", "Enabled"}, v)
        SetData({"Ragebot", "Keybind", "Kind"}, "Always")
        SetData({"Ragebot", "Keybind", "State"}, v)
    end
})

RageActivation:Toggle({
    Name = "Prioritize Hackers",
    Callback = function(v)
        SetData({"Ragebot", "PrioritizeHackers"}, v)
    end
})

RageActivation:Toggle({
    Name = "Utilize Health Lead",
    Callback = function(v)
        SetData({"Ragebot", "UtilizeHealthLead"}, v)
    end
})

local RageShooting = RageTab:Group("Shooting")

RageShooting:Slider({
    Name     = "Stability",
    Min      = 0,
    Max      = 150,
    Default  = 15,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        -- 原始单位是 0.00–1.50，UI 用整数 0–150 映射
        SetData({"Ragebot", "Stability"}, v / 100)
    end
})

RageShooting:Slider({
    Name     = "Shoot Frames",
    Min      = 1,
    Max      = 5,
    Default  = 1,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot", "ShootFrames"}, v)
    end
})

-- ============================================================
-- RAGEBOT — Weapons
-- ============================================================
local RageWeapons = RageTab:Group("Weapons")

RageWeapons:Toggle({
    Name = "Primary",
    Callback = function(v)
        SetData({"Ragebot", "Weapons", "Enabled", "Primary"}, v)
    end
})
RageWeapons:Toggle({
    Name = "Secondary",
    Callback = function(v)
        SetData({"Ragebot", "Weapons", "Enabled", "Secondary"}, v)
    end
})
RageWeapons:Toggle({
    Name = "Melee",
    Callback = function(v)
        SetData({"Ragebot", "Weapons", "Enabled", "Melee"}, v)
    end
})
RageWeapons:Dropdown({
    Name     = "On Empty",
    Options  = {"Reload", "Swap", "SwapOrReload"},
    Default  = "SwapOrReload",
    Callback = function(v)
        SetData({"Ragebot", "Weapons", "OnEmpty"}, v)
    end
})

-- ============================================================
-- RAGEBOT — Evasion
-- ============================================================
local RageEvasion = RageTab:Group("Evasion")

RageEvasion:Dropdown({
    Name     = "Mode",
    Options  = {"Off", "Random", "Translocate", "ProjectileBreaker"},
    Default  = "Random",
    Callback = function(v)
        SetData({"Ragebot", "Evasion", "Mode"}, v)
    end
})
RageEvasion:Toggle({
    Name = "Char Origin (Random)",
    Callback = function(v)
        SetData({"Ragebot", "Evasion", "Random", "AnchorFromCharacter"}, v)
    end
})
RageEvasion:Slider({
    Name     = "Base Radius",
    Min      = 5,
    Max      = 5000,
    Default  = 100,
    Step     = 5,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot", "Evasion", "Random", "BaseRadius"}, v)
    end
})
RageEvasion:Slider({
    Name     = "Radius Random Factor",
    Min      = 0,
    Max      = 10,
    Default  = 5,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot", "Evasion", "Random", "RadiusRandomFactor"}, v / 10)
    end
})
RageEvasion:Slider({
    Name     = "Translocate Offset",
    Min      = -50,
    Max      = 50,
    Default  = -50,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot", "Evasion", "Translocate", "Offset"}, v / 10)
    end
})

-- ============================================================
-- RAGEBOT — ProjectileBreaker
-- ✅ 使用 SetDepth() 每次传新 table，确保 store 检测到变更并触发监听
-- ============================================================
local RagePB = RageTab:Group("ProjectileBreaker")

RagePB:Slider({
    Name     = "Forward Depth Min",
    Min      = 0,
    Max      = 100,
    Default  = 0,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetDepth({"Ragebot","Evasion","ProjectileBreaker","DepthForward"}, "Min", v / 10)
    end
})
RagePB:Slider({
    Name     = "Forward Depth Max",
    Min      = 0,
    Max      = 100,
    Default  = 40,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetDepth({"Ragebot","Evasion","ProjectileBreaker","DepthForward"}, "Max", v / 10)
    end
})
RagePB:Slider({
    Name     = "Forward Frequency",
    Min      = 0,
    Max      = 200,
    Default  = 50,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot","Evasion","ProjectileBreaker","DepthForwardFrequency"}, v / 10)
    end
})
RagePB:Slider({
    Name     = "Upward Depth Min",
    Min      = 0,
    Max      = 100,
    Default  = 0,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetDepth({"Ragebot","Evasion","ProjectileBreaker","DepthUp"}, "Min", v / 10)
    end
})
RagePB:Slider({
    Name     = "Upward Depth Max",
    Min      = 0,
    Max      = 100,
    Default  = 55,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetDepth({"Ragebot","Evasion","ProjectileBreaker","DepthUp"}, "Max", v / 10)
    end
})
RagePB:Slider({
    Name     = "Upward Frequency",
    Min      = 0,
    Max      = 200,
    Default  = 50,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot","Evasion","ProjectileBreaker","DepthUpFrequency"}, v / 10)
    end
})
RagePB:Slider({
    Name     = "Reposition Interval",
    Min      = 5,
    Max      = 200,
    Default  = 30,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot","Evasion","ProjectileBreaker","RepositionInterval"}, v / 100)
    end
})
RagePB:Toggle({
    Name = "Fallback Char Origin",
    Callback = function(v)
        SetData({"Ragebot","Evasion","ProjectileBreaker","FallbackAnchorFromCharacter"}, v)
    end
})
RagePB:Slider({
    Name     = "Fallback Base Radius",
    Min      = 5,
    Max      = 5000,
    Default  = 100,
    Step     = 5,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot","Evasion","ProjectileBreaker","FallbackBaseRadius"}, v)
    end
})
RagePB:Slider({
    Name     = "Fallback Random Factor",
    Min      = 0,
    Max      = 10,
    Default  = 5,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Ragebot","Evasion","ProjectileBreaker","FallbackRadiusRandomFactor"}, v / 10)
    end
})

-- ============================================================
-- FLICKBOT
-- ============================================================
local FlickActivation = FlickTab:Group("Activation")

FlickActivation:Toggle({
    Name = "Enable Flickbot",
    Callback = function(v)
        -- ✅ Flickbot 默认 Kind="Hold"；改成 Always 让 State 生效
        SetData({"Flickbot", "Enabled"}, v)
        SetData({"Flickbot", "Keybind", "Kind"}, "Always")
        SetData({"Flickbot", "Keybind", "State"}, v)
    end
})
FlickActivation:Toggle({
    Name = "Shoot After Flick",
    Callback = function(v)
        SetData({"Flickbot", "Shoot"}, v)
    end
})

local FlickTiming = FlickTab:Group("Timing")

FlickTiming:Slider({
    Name     = "Shot Delay (ms)",
    Min      = 0,
    Max      = 250,
    Default  = 0,
    Step     = 1,
    Unit     = "ms",
    Callback = function(v)
        SetData({"Flickbot", "ShotDelay"}, v)
    end
})
FlickTiming:Slider({
    Name     = "Cooldown (ms)",
    Min      = 0,
    Max      = 2000,
    Default  = 250,
    Step     = 10,
    Unit     = "ms",
    Callback = function(v)
        SetData({"Flickbot", "Cooldown"}, v)
    end
})
FlickTiming:Slider({
    Name     = "Flick Duration (ms)",
    Min      = 30,
    Max      = 400,
    Default  = 110,
    Step     = 5,
    Unit     = "ms",
    Callback = function(v)
        SetData({"Flickbot", "FlickDuration"}, v)
    end
})

local FlickCurve = FlickTab:Group("Curve")

FlickCurve:Slider({
    Name     = "Curvature",
    Min      = 0,
    Max      = 50,
    Default  = 12,
    Step     = 1,
    Unit     = "",
    Callback = function(v)
        SetData({"Flickbot", "Curvature"}, v)
    end
})
FlickCurve:Slider({
    Name     = "Humanness",
    Min      = 0,
    Max      = 100,
    Default  = 30,
    Step     = 1,
    Unit     = "%",
    Callback = function(v)
        SetData({"Flickbot", "Humanness"}, v)
    end
})

-- ============================================================
-- MISC
-- ============================================================
local MiscUtil = MiscTab:Group("Utilities")

MiscUtil:Button({
    Name    = "Print Data Status",
    Variant = "Primary",
    Callback = function()
        local store = GetStore()
        if store then
            local rb = store:Get({"Ragebot"})
            local fb = store:Get({"Flickbot"})
            print("[EclipseUI] KiciaRebuild Store OK")
            print("  Ragebot.Enabled       =", rb and rb.Enabled)
            print("  Ragebot.Keybind.State =", rb and rb.Keybind and rb.Keybind.State)
            print("  Flickbot.Enabled      =", fb and fb.Enabled)
            print("  Evasion.Mode          =", rb and rb.Evasion and rb.Evasion.Mode)
        else
            warn("[EclipseUI] 无法获取 Store — 请确认：")
            warn("  1. KiciaRebuild 已先行加载")
            warn("  2. KiciaRebuild 末尾已插入:  K._store = tbl17.bG()")
        end
    end
})

MiscUtil:Button({
    Name    = "Unload UI",
    Variant = "Danger",
    Callback = function()
        Library.Unloaded = true
        ScreenGui:Destroy()
    end
})

-- ============================================================
-- 启动通知
-- ============================================================
task.wait(0.5)
local storeOk = GetStore() ~= nil
Library:Notify(
    storeOk and "KiciaRebuild Store 已连接" or "⚠ 未检测到 Store — 见 Misc > Print Data Status",
    storeOk and "success" or "warning"
)
Library:Notify("eclipse.wtf | rivals UI 已加载", "success")
