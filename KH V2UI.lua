--// Made by philnoob (Claude Opus 5.5)
-- sorry for vibecoding this sadly, i have no experience for UI's and i see retards selling KH ui for money which is not goodz so i recreated it with many new things such as resizable and better such things.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local TITLE = "Kiciahook V2 | Rivals"
local GUI_NAME = "KiciaUI"
local FONT = Enum.Font.Ubuntu
local TEXT_SIZE = 14

local ROW_TOGGLE = 19
local ROW_SLIDER = 30
local ROW_FIELD = 24
local SECTION_HEADER = 23
local SECTION_GAP = 5
local SWATCH_WIDTH = 40
local SWATCH_PITCH = 43.5
local POPUP_ROW = 18
local POPUP_MAX_ROWS = 8
local LABEL_OFFSET = 18
local WINDOW_WIDTH = 500
local WINDOW_HEIGHT = 350
local FIT_MARGIN = 8
local MIN_FIT_SCALE = 0.25
local REFERENCE_WIDTH = 1172
local REFERENCE_HEIGHT = 764
local MIN_SHRINK = 0.6
local MAX_GROWTH = 1.6
local RESIZE_OUTSIDE = 8
local RESIZE_INSIDE = 6
local RESIZE_TOP_INSIDE = 2
local BIND_MENU_ROW = 14
local BIND_MENU_TEXT = 12
local MOBILE_BOX_WIDTH = 64
local MOBILE_BOX_HEIGHT = 26
local TAP_SLOP = 6

local BLACK = Color3.fromRGB(0, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)
local ACCENT = Color3.fromRGB(58, 164, 210)
local ACCENT_DARK = Color3.fromRGB(26, 72, 92)
local MAIN = Color3.fromRGB(31, 31, 31)
local BACKGROUND = Color3.fromRGB(26, 26, 26)
local SECTION = Color3.fromRGB(24, 24, 24)
local OUTLINE = Color3.fromRGB(50, 50, 50)
local CONTROL = Color3.fromRGB(32, 32, 32)
local FIELD = Color3.fromRGB(27, 27, 27)
local SHADE_CONTROL = Color3.fromRGB(196, 196, 196)
local SHADE_ACCENT = Color3.fromRGB(136, 136, 136)

local RED = Color3.fromRGB(255, 0, 0)
local GREEN = Color3.fromRGB(0, 255, 0)
local CYAN = Color3.fromRGB(0, 216, 255)
local GREY = Color3.fromRGB(180, 180, 180)
local PALE_YELLOW = Color3.fromRGB(255, 255, 160)
local GOLD = Color3.fromRGB(220, 200, 10)

local BIND_MODES = { "Hold", "Toggle", "Always" }
local MATERIALS = { "ForceField", "Neon", "Glass", "SmoothPlastic" }

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
	ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
	ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

local function create(className, properties)
	local instance = Instance.new(className)
	for name, value in pairs(properties) do
		if name ~= "Parent" then
			instance[name] = value
		end
	end
	instance.Parent = properties.Parent
	return instance
end

local function box(parent, position, size, color, borderColor, inset)
	return create("Frame", {
		BackgroundColor3 = color,
		BorderColor3 = borderColor or BLACK,
		BorderMode = inset and Enum.BorderMode.Inset or Enum.BorderMode.Outline,
		BorderSizePixel = borderColor and 1 or 0,
		Position = position,
		Size = size,
		Parent = parent,
	})
end

local function panel(parent, position, size)
	return create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		Parent = parent,
	})
end

local function well(parent, position, size, color)
	local outer = box(parent, position, size, color, BLACK)
	local inner = box(outer, UDim2.new(), UDim2.fromScale(1, 1), color, OUTLINE, true)
	return outer, inner
end

local function shade(frame, bottom)
	return create("UIGradient", {
		Color = ColorSequence.new(WHITE, bottom),
		Rotation = 90,
		Parent = frame,
	})
end

local function textObject(className, parent, text, position, size, alignment)
	return create(className, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT,
		Position = position,
		Size = size,
		Text = text,
		TextColor3 = WHITE,
		TextSize = TEXT_SIZE,
		TextXAlignment = alignment or Enum.TextXAlignment.Left,
		Parent = parent,
	})
end

local function textWidth(text, size)
	return TextService:GetTextSize(text, size, FONT, Vector2.new(1000, 20)).X
end

local function hitbox(parent, position, size)
	return create("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		Text = "",
		Parent = parent,
	})
end

local function accentFill(parent, size)
	local fill = box(parent, UDim2.new(), size, ACCENT, ACCENT_DARK, true)
	shade(fill, SHADE_ACCENT)
	return fill
end

local function clippedText(parent, text, position, size)
	local clip = panel(parent, position, size)
	clip.ClipsDescendants = true
	textObject("TextLabel", clip, text, UDim2.new(), UDim2.new(0, 400, 1, 0))
	return clip
end

local function roundTo(value, decimals)
	local factor = 10 ^ decimals
	return math.floor(value * factor + 0.5) / factor
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerPress(input)
	return isPress(input) or input.UserInputType == Enum.UserInputType.MouseButton2
end

local function isSamePress(input, press)
	if press.UserInputType == Enum.UserInputType.Touch then
		return input == press
	end
	return input.UserInputType == press.UserInputType
end

local function isInside(object, position)
	local origin = object.AbsolutePosition
	local size = object.AbsoluteSize
	return position.X >= origin.X
		and position.X <= origin.X + size.X
		and position.Y >= origin.Y
		and position.Y <= origin.Y + size.Y
end

local function inputName(input)
	local kind = input.UserInputType
	if kind == Enum.UserInputType.Keyboard or string.sub(kind.Name, 1, 7) == "Gamepad" then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			return input.KeyCode.Name
		end
		return nil
	end
	if
		kind == Enum.UserInputType.MouseButton1
		or kind == Enum.UserInputType.MouseButton2
		or kind == Enum.UserInputType.MouseButton3
	then
		return kind.Name
	end
	return nil
end

local function trackDrag(press, onMove, onRelease)
	local moved
	local released
	moved = UserInputService.InputChanged:Connect(function(input)
		if input == press or input.UserInputType == Enum.UserInputType.MouseMovement then
			onMove(input.Position)
		end
	end)
	released = UserInputService.InputEnded:Connect(function(input)
		if isSamePress(input, press) then
			moved:Disconnect()
			released:Disconnect()
			if onRelease then
				onRelease()
			end
		end
	end)
end

local function bindDrag(handle, onMove, onPress, onRelease)
	handle.InputBegan:Connect(function(input)
		if isPress(input) then
			if onPress then
				onPress(input)
			end
			onMove(input.Position)
			trackDrag(input, onMove, onRelease)
		end
	end)
end

local function bindHover(handle, target)
	handle.MouseEnter:Connect(function()
		target.BorderColor3 = ACCENT
	end)
	handle.MouseLeave:Connect(function()
		target.BorderColor3 = OUTLINE
	end)
end

local previous = playerGui:FindFirstChild(GUI_NAME)
if previous then
	previous:Destroy()
end

local screen = create("ScreenGui", {
	DisplayOrder = 1000,
	Name = GUI_NAME,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

local topInset = GuiService:GetGuiInset()
local window = box(
	screen,
	UDim2.new(0.5, 0, 0.5, -topInset.Y / 2),
	UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT),
	BLACK
)
window.Active = true
window.AnchorPoint = Vector2.new(0.5, 0.5)
local menuScale = create("UIScale", { Parent = window })
local customScale

local function getScaleLimits()
	local available = screen.AbsoluteSize
	local fullHeight = available.Y + topInset.Y
	local fit = math.max(
		MIN_FIT_SCALE,
		math.min((available.X - FIT_MARGIN * 2) / WINDOW_WIDTH, (fullHeight - FIT_MARGIN * 2) / WINDOW_HEIGHT)
	)
	local proportional = math.min(available.X / REFERENCE_WIDTH, fullHeight / REFERENCE_HEIGHT)
	local default = math.min(fit, math.max(1, proportional))
	return default, default * MIN_SHRINK, math.min(fit, default * MAX_GROWTH)
end

local function keepWindowOnScreen()
	local limit = screen.AbsoluteSize
	if limit.X <= 0 or limit.Y <= 0 then
		return
	end
	local halfWidth = WINDOW_WIDTH * menuScale.Scale / 2
	local halfHeight = WINDOW_HEIGHT * menuScale.Scale / 2
	local position = window.Position
	local minimumY = halfHeight - topInset.Y
	local centerX = math.clamp(limit.X / 2 + position.X.Offset, halfWidth, math.max(halfWidth, limit.X - halfWidth))
	local centerY = math.clamp(limit.Y / 2 + position.Y.Offset, minimumY, math.max(minimumY, limit.Y - halfHeight))
	window.Position = UDim2.new(0.5, centerX - limit.X / 2, 0.5, centerY - limit.Y / 2)
end

local function applyScale()
	local default, lower, upper = getScaleLimits()
	menuScale.Scale = customScale and math.clamp(customScale, lower, upper) or default
	keepWindowOnScreen()
end

applyScale()
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyScale)

local chrome = box(window, UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), MAIN, ACCENT, true)
textObject("TextLabel", chrome, TITLE, UDim2.fromOffset(6, 1), UDim2.new(1, -12, 0, 20))

local bodyOuter = box(chrome, UDim2.fromOffset(5, 19), UDim2.new(1, -10, 1, -24), BACKGROUND, OUTLINE, true)
local body = box(bodyOuter, UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), BACKGROUND, BLACK, true)

local overlay = panel(screen, UDim2.new(), UDim2.fromScale(1, 1))
overlay.ZIndex = 10

local connections = {}
local activePopup
local activeCapture
local menuKey = "RightShift"

local function closePopup()
	if activePopup then
		local popup = activePopup
		activePopup = nil
		popup.Frame:Destroy()
		if popup.OnClose then
			popup.OnClose()
		end
	end
end

local function isPopupAnchor(object)
	return activePopup ~= nil and activePopup.Anchor == object
end

local function createPopup(width, height, color)
	local frame, inner = well(overlay, UDim2.new(), UDim2.fromOffset(width, height), color)
	create("UIScale", { Scale = menuScale.Scale, Parent = frame })
	return frame, inner
end

local function placePopup(frame, anchor, width, height, alignRight)
	local scale = menuScale.Scale
	local scaledWidth = width * scale
	local scaledHeight = height * scale
	local origin = anchor.AbsolutePosition
	local limit = screen.AbsoluteSize
	local left = alignRight and origin.X + anchor.AbsoluteSize.X - scaledWidth or origin.X
	local x = math.clamp(left, 2, math.max(2, limit.X - scaledWidth - 2))
	local y = origin.Y + anchor.AbsoluteSize.Y + 3
	if y + scaledHeight > limit.Y then
		y = math.max(2, origin.Y - scaledHeight - 3)
	end
	frame.Position = UDim2.fromOffset(x, y)
end

local function openList(anchor, options, isSelected, onPick, layout)
	closePopup()
	local rowHeight = layout.RowHeight or POPUP_ROW
	local width = layout.Width
	local height = math.min(#options, POPUP_MAX_ROWS) * rowHeight + 2
	local frame, inner = createPopup(width, height, FIELD)
	local list = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, #options * rowHeight),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Position = UDim2.fromOffset(1, 1),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = UDim2.new(1, -2, 1, -2),
		Parent = inner,
	})

	local buttons = {}

	local function refresh()
		for index, button in ipairs(buttons) do
			button.TextColor3 = isSelected(options[index]) and ACCENT or WHITE
		end
	end

	for index, option in ipairs(options) do
		local button = textObject(
			"TextButton",
			list,
			option,
			UDim2.fromOffset(0, (index - 1) * rowHeight),
			UDim2.new(1, 0, 0, rowHeight)
		)
		button.AutoButtonColor = false
		button.BackgroundColor3 = MAIN
		button.TextSize = layout.TextSize or TEXT_SIZE
		create("UIPadding", { PaddingLeft = UDim.new(0, 5), Parent = button })
		button.MouseEnter:Connect(function()
			button.BackgroundTransparency = 0
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundTransparency = 1
		end)
		button.Activated:Connect(function()
			onPick(option)
			refresh()
		end)
		buttons[index] = button
	end

	refresh()
	placePopup(frame, anchor, width, height, layout.AlignRight)
	activePopup = { Frame = frame, Anchor = anchor, OnClose = layout.OnClose }
end

local function openPicker(anchor, initial, onChange)
	closePopup()
	local hue, saturation, brightness = initial:ToHSV()
	local width = 186
	local height = 172
	local frame, inner = createPopup(width, height, SECTION)
	box(inner, UDim2.fromOffset(1, 1), UDim2.new(1, -2, 0, 2), ACCENT)

	local square = box(inner, UDim2.fromOffset(7, 9), UDim2.fromOffset(150, 130), WHITE, BLACK)
	local saturationLayer = box(square, UDim2.new(), UDim2.fromScale(1, 1), WHITE)
	create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = saturationLayer })
	local brightnessLayer = box(square, UDim2.new(), UDim2.fromScale(1, 1), BLACK)
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = brightnessLayer })
	local squareCursor = box(square, UDim2.new(), UDim2.fromOffset(4, 4), WHITE, BLACK)
	local squareHit = hitbox(square, UDim2.new(), UDim2.fromScale(1, 1))

	local hueBar = box(inner, UDim2.fromOffset(164, 9), UDim2.fromOffset(14, 130), WHITE, BLACK)
	create("UIGradient", { Color = RAINBOW, Rotation = 90, Parent = hueBar })
	local hueCursor = box(hueBar, UDim2.new(), UDim2.new(1, 2, 0, 2), WHITE, BLACK)
	local hueHit = hitbox(hueBar, UDim2.new(), UDim2.fromScale(1, 1))

	local _, hexInner = well(inner, UDim2.fromOffset(7, 147), UDim2.new(1, -14, 0, 18), FIELD)
	local hexBox = textObject("TextBox", hexInner, "", UDim2.fromOffset(5, 0), UDim2.new(1, -10, 1, 0))
	hexBox.ClearTextOnFocus = false

	local function refresh()
		local color = Color3.fromHSV(hue, saturation, brightness)
		square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		squareCursor.Position = UDim2.new(saturation, -2, 1 - brightness, -2)
		hueCursor.Position = UDim2.new(0, -1, hue, -1)
		hexBox.Text = "#" .. string.upper(color:ToHex())
		onChange(color)
	end

	bindDrag(squareHit, function(position)
		saturation = math.clamp((position.X - square.AbsolutePosition.X) / square.AbsoluteSize.X, 0, 1)
		brightness = 1 - math.clamp((position.Y - square.AbsolutePosition.Y) / square.AbsoluteSize.Y, 0, 1)
		refresh()
	end)

	bindDrag(hueHit, function(position)
		hue = math.clamp((position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
		refresh()
	end)

	hexBox.FocusLost:Connect(function()
		local valid, color = pcall(Color3.fromHex, hexBox.Text)
		if valid then
			hue, saturation, brightness = color:ToHSV()
		end
		refresh()
	end)

	refresh()
	placePopup(frame, anchor, width, height)
	activePopup = { Frame = frame, Anchor = anchor }
end

local function addRow(section, height)
	local row = panel(section.Frame, UDim2.fromOffset(7, section.Height), UDim2.new(1, -14, 0, height))
	section.Height = section.Height + height
	return row
end

local function buildBind(row, bind, onResize, isMenuKey)
	local mode = bind[1]
	local key = bind[2]
	local capturing = false
	local longPressed = false
	local outer, inner = well(row, UDim2.fromScale(1, 0), UDim2.fromOffset(0, 13), SECTION)
	outer.AnchorPoint = Vector2.new(1, 0)
	local keyLabel = textObject("TextLabel", inner, "", UDim2.new(), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	local hit = hitbox(outer, UDim2.new(), UDim2.fromScale(1, 1))
	bindHover(hit, inner)

	local function refresh()
		local text = mode .. ": " .. (capturing and "..." or key)
		local width = textWidth(text, TEXT_SIZE) + 6
		keyLabel.Text = text
		outer.Size = UDim2.fromOffset(width, 13)
		onResize(width + 1)
	end

	local function finishCapture(name)
		capturing = false
		activeCapture = nil
		if name == "Backspace" then
			if not isMenuKey then
				key = "None"
			end
		elseif name and name ~= "Escape" and not (isMenuKey and string.sub(name, 1, 5) == "Mouse") then
			key = name
			if isMenuKey then
				menuKey = name
			end
		end
		refresh()
	end

	local function startCapture()
		closePopup()
		capturing = true
		activeCapture = { Anchor = outer, Finish = finishCapture }
		refresh()
	end

	local function toggleModes()
		if isPopupAnchor(outer) then
			closePopup()
			return
		end
		local widest = 0
		for _, option in ipairs(BIND_MODES) do
			widest = math.max(widest, textWidth(option, BIND_MENU_TEXT))
		end
		openList(outer, BIND_MODES, function(option)
			return option == mode
		end, function(option)
			mode = option
			refresh()
			closePopup()
		end, {
			Width = widest + 12,
			RowHeight = BIND_MENU_ROW,
			TextSize = BIND_MENU_TEXT,
			AlignRight = true,
		})
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			longPressed = false
		end
	end)

	hit.Activated:Connect(function(input)
		if longPressed then
			longPressed = false
		elseif capturing then
			finishCapture(input.UserInputType == Enum.UserInputType.MouseButton1 and "MouseButton1" or nil)
		else
			startCapture()
		end
	end)

	hit.MouseButton2Click:Connect(function()
		if capturing then
			finishCapture("MouseButton2")
		elseif not isMenuKey then
			toggleModes()
		end
	end)

	if not isMenuKey then
		hit.TouchLongPress:Connect(function(_, state)
			if state == Enum.UserInputState.Begin and not capturing then
				longPressed = true
				toggleModes()
			end
		end)
	end

	refresh()
end

local function buildSwatches(row, colors)
	local count = #colors
	for index, initial in ipairs(colors) do
		local color = initial
		local offset = (count - index) * SWATCH_PITCH + SWATCH_WIDTH
		local outer, inner = well(row, UDim2.new(1, -offset, 0, 0), UDim2.fromOffset(SWATCH_WIDTH, 13), color)
		local shine = box(inner, UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), WHITE)
		shine.BackgroundTransparency = 0.92
		create("UIGradient", { Color = ColorSequence.new(WHITE, BLACK), Rotation = 90, Parent = shine })
		local hit = hitbox(row, UDim2.new(1, -offset, 0, 0), UDim2.fromOffset(SWATCH_WIDTH, 13))
		bindHover(hit, inner)
		hit.Activated:Connect(function()
			if isPopupAnchor(outer) then
				closePopup()
				return
			end
			openPicker(outer, color, function(value)
				color = value
				outer.BackgroundColor3 = value
				inner.BackgroundColor3 = value
			end)
		end)
	end
	return (count - 1) * SWATCH_PITCH + SWATCH_WIDTH + 1
end

local Builders = {}

function Builders.Toggle(section, spec)
	local row = addRow(section, ROW_TOGGLE)
	local outer, inner = well(row, UDim2.new(), UDim2.fromOffset(13, 13), CONTROL)
	shade(inner, SHADE_CONTROL)
	local fill = accentFill(outer, UDim2.fromScale(1, 1))
	local enabled = spec.Enabled
	fill.Visible = enabled

	local label = clippedText(row, spec.Text, UDim2.fromOffset(LABEL_OFFSET, 0), UDim2.new(1, -LABEL_OFFSET, 0, 14))
	local hit = hitbox(row, UDim2.new(), UDim2.new(1, 0, 0, 13))
	bindHover(hit, inner)

	local function reserve(width)
		label.Size = UDim2.new(1, -LABEL_OFFSET - width, 0, 14)
		hit.Size = UDim2.new(1, -width, 0, 13)
	end

	if spec.Bind then
		buildBind(row, spec.Bind, reserve, false)
	elseif spec.Colors then
		reserve(buildSwatches(row, spec.Colors))
	end

	hit.Activated:Connect(function()
		enabled = not enabled
		fill.Visible = enabled
	end)
end

function Builders.Slider(section, spec)
	local row = addRow(section, ROW_SLIDER)
	local minimum = spec.Min
	local maximum = spec.Max
	local maximumText = tostring(maximum)
	textObject("TextLabel", row, spec.Text, UDim2.new(), UDim2.new(1, 0, 0, 13))
	local valueLabel = textObject("TextLabel", row, "", UDim2.new(), UDim2.new(1, -2, 0, 13), Enum.TextXAlignment.Right)
	local outer, inner = well(row, UDim2.fromOffset(0, 14), UDim2.new(1, 0, 0, 10), CONTROL)
	shade(inner, SHADE_CONTROL)
	local fill = accentFill(outer, UDim2.fromScale(0, 1))
	local hit = hitbox(row, UDim2.fromOffset(0, 11), UDim2.new(1, 0, 0, 16))

	local function setValue(value)
		local current = math.clamp(roundTo(value, spec.Decimals), minimum, maximum)
		local alpha = (current - minimum) / (maximum - minimum)
		fill.Size = UDim2.new(alpha, 2 - 2 * alpha, 1, 0)
		fill.Visible = alpha > 0
		valueLabel.Text = tostring(current) .. "/" .. maximumText
	end

	bindDrag(hit, function(position)
		local alpha = math.clamp((position.X - outer.AbsolutePosition.X) / outer.AbsoluteSize.X, 0, 1)
		setValue(minimum + (maximum - minimum) * alpha)
	end, function()
		closePopup()
		section.Column.ScrollingEnabled = false
	end, function()
		section.Column.ScrollingEnabled = true
	end)

	bindHover(hit, inner)
	setValue(spec.Value)
end

function Builders.Caption(section, spec)
	local row = addRow(section, ROW_TOGGLE)
	textObject("TextLabel", row, spec.Text, UDim2.new(), UDim2.new(1, 0, 0, 14))
end

function Builders.Dropdown(section, spec)
	local row = addRow(section, ROW_FIELD)
	local outer, inner = well(row, UDim2.fromOffset(0, -1), UDim2.new(1, 0, 0, 18), FIELD)
	local valueLabel = textObject("TextLabel", inner, "", UDim2.fromOffset(5, 0), UDim2.new(1, -22, 1, 1))
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	local icon = textObject("TextLabel", inner, "+", UDim2.fromOffset(0, -1), UDim2.new(1, -4, 1, 0), Enum.TextXAlignment.Right)
	local hit = hitbox(row, UDim2.fromOffset(0, -1), UDim2.new(1, 0, 0, 18))
	bindHover(hit, inner)

	local chosen = {}
	for _, option in ipairs(spec.Default) do
		chosen[option] = true
	end

	local function refresh()
		local names = {}
		for _, option in ipairs(spec.Options) do
			if chosen[option] then
				names[#names + 1] = option
			end
		end
		valueLabel.Text = #names > 0 and table.concat(names, ", ") or "None"
	end

	hit.Activated:Connect(function()
		if isPopupAnchor(outer) then
			closePopup()
			return
		end
		openList(outer, spec.Options, function(option)
			return chosen[option] == true
		end, function(option)
			if spec.Multi then
				chosen[option] = not chosen[option] and true or nil
				refresh()
			else
				chosen = { [option] = true }
				refresh()
				closePopup()
			end
		end, {
			Width = outer.AbsoluteSize.X / menuScale.Scale,
			OnClose = function()
				icon.Text = "+"
			end,
		})
		icon.Text = "-"
	end)

	refresh()
end

function Builders.Button(section, spec)
	local row = addRow(section, ROW_FIELD)
	local _, inner = well(row, UDim2.fromOffset(0, -1), UDim2.new(1, 0, 0, 18), FIELD)
	local hit = textObject(
		"TextButton",
		inner,
		spec.Text,
		UDim2.new(),
		UDim2.fromScale(1, 1),
		Enum.TextXAlignment.Center
	)
	hit.AutoButtonColor = false
	bindHover(hit, inner)
	hit.MouseButton1Down:Connect(function()
		inner.BackgroundColor3 = MAIN
	end)
	hit.MouseButton1Up:Connect(function()
		inner.BackgroundColor3 = FIELD
	end)
	hit.MouseLeave:Connect(function()
		inner.BackgroundColor3 = FIELD
	end)
	if spec.Action then
		hit.Activated:Connect(spec.Action)
	end
end

function Builders.Field(section, spec)
	local row = addRow(section, ROW_FIELD)
	local _, inner = well(row, UDim2.fromOffset(0, -1), UDim2.new(1, 0, 0, 18), FIELD)
	local input = textObject("TextBox", inner, "", UDim2.fromOffset(5, 0), UDim2.new(1, -10, 1, 0))
	input.ClearTextOnFocus = false
	input.ClipsDescendants = true
	input.PlaceholderText = spec.Placeholder
	input.PlaceholderColor3 = GREY
end

function Builders.MenuKey(section, spec)
	local row = addRow(section, ROW_TOGGLE)
	local label = clippedText(row, spec.Text, UDim2.new(), UDim2.new(1, 0, 0, 13))
	buildBind(row, { "Toggle", spec.Key }, function(width)
		label.Size = UDim2.new(1, -width, 0, 13)
	end, true)
end

local function buildSection(column, spec)
	local frame = box(column, UDim2.new(), UDim2.new(1, 1, 0, 0), SECTION, OUTLINE, true)
	box(frame, UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), SECTION, BLACK, true)
	box(frame, UDim2.fromOffset(2, 2), UDim2.new(1, -4, 0, 2), ACCENT)
	textObject("TextLabel", frame, spec.Title, UDim2.fromOffset(5, 4), UDim2.new(1, -10, 0, 18))

	local section = { Column = column, Frame = frame, Height = SECTION_HEADER }
	for _, row in ipairs(spec.Rows) do
		Builders[row.Kind](section, row)
	end
	frame.Size = UDim2.new(1, 1, 0, section.Height + 1)
	return section
end

local function buildColumn(host, position, sections)
	local column = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Position = position,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = UDim2.new(0.5, -10, 1, -11),
		Parent = host,
	})

	local offset = 0
	for _, spec in ipairs(sections) do
		local section = buildSection(column, spec)
		section.Frame.Position = UDim2.fromOffset(0, offset)
		offset = offset + section.Height + 1 + SECTION_GAP
	end

	column.CanvasSize = UDim2.fromOffset(0, math.max(offset - SECTION_GAP, 0))
	column:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup)
end

local function buildTabs(host, pages, renderPage)
	local count = #pages
	local strip = panel(host, UDim2.fromOffset(6, 7), UDim2.new(1, -12, 0, 21))
	strip.ZIndex = 2
	local _, container = well(host, UDim2.fromOffset(6, 27), UDim2.new(1, -12, 1, -33), MAIN)
	local tabs = {}

	local function select(selected)
		closePopup()
		for index, tab in ipairs(tabs) do
			local active = index == selected
			tab.Face.BackgroundColor3 = active and MAIN or BACKGROUND
			tab.Blocker.Visible = active
			tab.Content.Visible = active
		end
	end

	for index, page in ipairs(pages) do
		local slot = panel(
			strip,
			UDim2.new((index - 1) / count, index - 1, 0, 0),
			UDim2.new(1 / count, index == count and -3 or -5, 1, 0)
		)
		box(slot, UDim2.fromOffset(-1, -1), UDim2.new(1, 2, 1, 0), BLACK)
		local face = box(slot, UDim2.new(), UDim2.fromScale(1, 1), BACKGROUND, OUTLINE, true)
		local blocker = box(slot, UDim2.new(0, 1, 1, -1), UDim2.new(1, -2, 0, 1), MAIN)
		local button = textObject(
			"TextButton",
			slot,
			page.Name,
			UDim2.fromOffset(0, -1),
			UDim2.new(1, 0, 1, 1),
			Enum.TextXAlignment.Center
		)
		button.AutoButtonColor = false
		button.Activated:Connect(function()
			select(index)
		end)

		local content = panel(container, UDim2.new(), UDim2.fromScale(1, 1))
		tabs[index] = { Face = face, Blocker = blocker, Content = content }
		renderPage(content, page)
	end

	select(1)
end

local function renderPage(host, page)
	if page.Pages then
		buildTabs(host, page.Pages, renderPage)
	else
		buildColumn(host, UDim2.fromOffset(6, 5), page.Left)
		buildColumn(host, UDim2.new(0.5, 3, 0, 5), page.Right)
	end
end

local mobileBox, mobileBoxInner = well(
	screen,
	UDim2.fromOffset(FIT_MARGIN, FIT_MARGIN),
	UDim2.fromOffset(MOBILE_BOX_WIDTH, MOBILE_BOX_HEIGHT),
	MAIN
)
mobileBox.Visible = UserInputService.TouchEnabled
mobileBox.ZIndex = 5
box(mobileBoxInner, UDim2.fromOffset(1, 1), UDim2.new(1, -2, 0, 2), ACCENT)
local mobileButton = textObject(
	"TextButton",
	mobileBoxInner,
	"Close",
	UDim2.new(),
	UDim2.fromScale(1, 1),
	Enum.TextXAlignment.Center
)
mobileButton.AutoButtonColor = false

local function setMenuVisible(visible)
	closePopup()
	window.Visible = visible
	mobileButton.Text = visible and "Close" or "Open"
end

local mobileBoxStart
local mobileBoxOrigin
local mobileBoxDragged = false

bindDrag(mobileButton, function(position)
	local delta = position - mobileBoxOrigin
	if delta.Magnitude > TAP_SLOP then
		mobileBoxDragged = true
	end
	if mobileBoxDragged then
		local limit = screen.AbsoluteSize
		mobileBox.Position = UDim2.fromOffset(
			math.clamp(mobileBoxStart.X.Offset + delta.X, 0, math.max(0, limit.X - MOBILE_BOX_WIDTH)),
			math.clamp(mobileBoxStart.Y.Offset + delta.Y, 0, math.max(0, limit.Y - MOBILE_BOX_HEIGHT))
		)
	end
end, function(input)
	mobileBoxDragged = false
	mobileBoxStart = mobileBox.Position
	mobileBoxOrigin = input.Position
end)

mobileButton.Activated:Connect(function()
	if not mobileBoxDragged then
		setMenuVisible(not window.Visible)
	end
end)

local dragHandle = hitbox(chrome, UDim2.new(), UDim2.new(1, 0, 0, 19))
dragHandle.Modal = true
local dragStart
local dragOrigin
bindDrag(dragHandle, function(position)
	local delta = position - dragOrigin
	window.Position = UDim2.new(
		dragStart.X.Scale,
		dragStart.X.Offset + delta.X,
		dragStart.Y.Scale,
		dragStart.Y.Offset + delta.Y
	)
	keepWindowOnScreen()
end, function(input)
	closePopup()
	dragStart = window.Position
	dragOrigin = input.Position
end)

local resizeStart
local resizeOrigin

local function addResizeHandle(position, size, horizontal, vertical)
	local handle = hitbox(window, position, size)
	handle.ZIndex = 3
	bindDrag(handle, function(pointer)
		local growthX = (pointer.X - resizeOrigin.X) * horizontal * 2 / WINDOW_WIDTH
		local growthY = (pointer.Y - resizeOrigin.Y) * vertical * 2 / WINDOW_HEIGHT
		local growth = growthX
		if horizontal == 0 then
			growth = growthY
		elseif vertical ~= 0 then
			growth = math.max(growthX, growthY)
		end
		customScale = resizeStart + growth
		applyScale()
	end, function(input)
		closePopup()
		resizeStart = menuScale.Scale
		resizeOrigin = input.Position
	end)
end

local edgeThickness = RESIZE_OUTSIDE + RESIZE_INSIDE
local cornerSize = UDim2.fromOffset(edgeThickness, edgeThickness)
local sideLength = -2 * RESIZE_INSIDE

addResizeHandle(
	UDim2.fromOffset(-RESIZE_OUTSIDE, RESIZE_INSIDE),
	UDim2.new(0, edgeThickness, 1, sideLength),
	-1,
	0
)
addResizeHandle(
	UDim2.new(1, -RESIZE_INSIDE, 0, RESIZE_INSIDE),
	UDim2.new(0, edgeThickness, 1, sideLength),
	1,
	0
)
addResizeHandle(
	UDim2.fromOffset(RESIZE_INSIDE, -RESIZE_OUTSIDE),
	UDim2.new(1, sideLength, 0, RESIZE_OUTSIDE + RESIZE_TOP_INSIDE),
	0,
	-1
)
addResizeHandle(
	UDim2.new(0, RESIZE_INSIDE, 1, -RESIZE_INSIDE),
	UDim2.new(1, sideLength, 0, edgeThickness),
	0,
	1
)
addResizeHandle(UDim2.fromOffset(-RESIZE_OUTSIDE, -RESIZE_OUTSIDE), cornerSize, -1, -1)
addResizeHandle(UDim2.new(1, -RESIZE_INSIDE, 0, -RESIZE_OUTSIDE), cornerSize, 1, -1)
addResizeHandle(UDim2.new(0, -RESIZE_OUTSIDE, 1, -RESIZE_INSIDE), cornerSize, -1, 1)
addResizeHandle(UDim2.new(1, -RESIZE_INSIDE, 1, -RESIZE_INSIDE), cornerSize, 1, 1)

local function toggle(text, enabled, options)
	local row = options or {}
	row.Kind = "Toggle"
	row.Text = text
	row.Enabled = enabled
	return row
end

local function slider(text, value, minimum, maximum, decimals)
	return { Kind = "Slider", Text = text, Value = value, Min = minimum, Max = maximum, Decimals = decimals }
end

local function caption(text)
	return { Kind = "Caption", Text = text }
end

local function dropdown(options, default, multi)
	return { Kind = "Dropdown", Options = options, Default = default, Multi = multi }
end

local function button(text, action)
	return { Kind = "Button", Text = text, Action = action }
end

local function field(placeholder)
	return { Kind = "Field", Placeholder = placeholder }
end

local function menuKeyRow(text, key)
	return { Kind = "MenuKey", Text = text, Key = key }
end

local function bindable(mode, key)
	return { Bind = { mode, key } }
end

local function tinted(...)
	return { Colors = { ... } }
end

local function espRows(states)
	return {
		toggle("Enabled", states[1]),
		toggle("Bounding Box", states[2], tinted(WHITE, BLACK)),
		dropdown({ "Full", "Corners", "3D" }, { "Full" }),
		toggle("Name", states[3], tinted(WHITE, BLACK)),
		toggle("Health Bar", states[4], tinted(GREEN, RED, BLACK)),
		toggle("Weapon Text", states[5], tinted(WHITE, BLACK)),
		toggle("Ammo", states[6], tinted(WHITE, BLACK)),
		toggle("Distance", states[7], tinted(WHITE, BLACK)),
		toggle("Katana Status", states[8], tinted(RED, BLACK)),
		toggle("Chams", states[9], tinted(WHITE, GREY)),
		toggle("Chams Behind Walls", states[10], tinted(PALE_YELLOW, GOLD)),
	}
end

local ALL_OFF = { false, false, false, false, false, false, false, false, false, false }
local ENEMY_DEFAULTS = { true, true, true, true, true, false, true, true, false, false }
local HITPARTS = { "Head", "Torso", "Arms", "Legs" }

local Menu = {
	{
		Name = "Combat",
		Pages = {
			{
				Name = "Legitbot",
				Left = {
					{
						Title = "Main Settings",
						Rows = {
							toggle("Enabled", true, bindable("Toggle", "ButtonL3")),
							slider("Speed", 0.84, 0.1, 5, 2),
							slider("Speed (in attack)", 2, 0.1, 5, 2),
							slider("Speed scale - FOV", 100, 0, 100, 0),
							slider("Maximum lock-on time", 3, 0.5, 10, 1),
							slider("Reaction time (ms)", 100, 0, 500, 0),
							toggle("Team Check", true),
							toggle("Visible Check", false),
							caption("Targeting Hitparts"),
							dropdown(HITPARTS, { "Head" }, true),
						},
					},
				},
				Right = {
					{
						Title = "FOV Settings",
						Rows = {
							slider("Maximum FOV", 120, 0, 600, 0),
							toggle("Draw FOV", false, tinted(CYAN)),
							toggle("Dynamic FOV", false),
						},
					},
				},
			},
			{
				Name = "Silent Aim",
				Left = {
					{
						Title = "Main Settings",
						Rows = {
							toggle("Enabled", false, bindable("Always", "None")),
							slider("Hit Chance", 100, 0, 100, 0),
							toggle("Team Check", true),
							toggle("Visible Check", false),
							caption("Targeting Hitparts"),
							dropdown(HITPARTS, { "Head" }, true),
						},
					},
				},
				Right = {
					{
						Title = "FOV Settings",
						Rows = {
							slider("Maximum FOV", 120, 0, 600, 0),
							toggle("Draw FOV", false, tinted(CYAN)),
							toggle("Dynamic FOV", false),
						},
					},
				},
			},
			{
				Name = "Triggerbot",
				Left = {
					{
						Title = "Main",
						Rows = {
							toggle("Enabled", true, bindable("Always", "None")),
							slider("Delay (ms)", 0, 0, 500, 0),
							slider("Grace (ms)", 0, 0, 500, 0),
						},
					},
					{
						Title = "Targeting",
						Rows = {
							toggle("Visible Check", true),
							dropdown({ "Head", "Torso", "Random" }, { "Head" }),
						},
					},
				},
				Right = {
					{
						Title = "Advanced",
						Rows = {
							toggle("Random Delay", false),
							slider("Min Delay", 40, 0, 300, 0),
							slider("Max Delay", 120, 50, 500, 0),
						},
					},
				},
			},
			{
				Name = "Rage",
				Left = {
					{
						Title = "Main",
						Rows = {
							toggle("Enabled", false),
							slider("Field Of View (°)", 181, 0, 360, 0),
							toggle("Orbit Aura", false),
							toggle("Orbit Resolver", true),
							toggle("Orbit Anti Riot", false),
							toggle("Orbit Strike On Melee", false),
							slider("Orbit TP Delay", 1.3, 1, 5, 1),
							slider("Orbit Shot Interval", 0.4, 0, 2, 1),
						},
					},
				},
				Right = {
					{
						Title = "Anti Aim",
						Rows = {
							toggle("Enabled", false),
							caption("Pitch"),
							dropdown({ "Down", "Up", "Zero", "Random" }, { "Down" }),
							caption("Yaw Base"),
							dropdown({ "At Targets", "Camera", "Static" }, { "At Targets" }),
							caption("Yaw"),
							dropdown({ "Stutter Spin", "Spin", "Jitter", "Static" }, { "Stutter Spin" }),
							slider("Yaw Angle (°)", 0, -180, 180, 0),
							caption("Roll"),
							dropdown({ "Random", "None", "Left", "Right" }, { "Random" }),
							toggle("Jitter", false),
						},
					},
				},
			},
		},
	},
	{
		Name = "Visuals",
		Pages = {
			{
				Name = "ESP",
				Left = {
					{
						Title = "Main",
						Rows = {
							toggle("Enabled", true),
							caption("Bounding Box Size"),
							dropdown({ "Static", "Dynamic" }, { "Static" }),
						},
					},
					{ Title = "Team ESP", Rows = espRows(ALL_OFF) },
				},
				Right = {
					{ Title = "Enemy ESP", Rows = espRows(ENEMY_DEFAULTS) },
					{ Title = "Friend ESP", Rows = espRows(ALL_OFF) },
				},
			},
			{
				Name = "Overrides",
				Left = {
					{
						Title = "Viewmodel",
						Rows = {
							toggle("Enabled", false),
							slider("Offset X", 0, -10, 10, 1),
							slider("Offset Y", 0, -10, 10, 1),
							slider("Offset Z", 0, -10, 10, 1),
							slider("Field Of View", 70, 30, 120, 0),
						},
					},
				},
				Right = {
					{
						Title = "Weapon",
						Rows = {
							toggle("Weapon Chams", false, tinted(WHITE, GREY)),
							caption("Weapon Material"),
							dropdown(MATERIALS, { "ForceField" }),
							slider("Transparency", 0, 0, 100, 0),
						},
					},
					{
						Title = "Arms",
						Rows = {
							toggle("Arm Chams", false, tinted(WHITE, GREY)),
							caption("Arm Material"),
							dropdown(MATERIALS, { "ForceField" }),
						},
					},
				},
			},
			{
				Name = "World",
				Left = {
					{
						Title = "Lighting",
						Rows = {
							toggle("Ambient", false, tinted(WHITE)),
							toggle("Color Shift", false, tinted(WHITE, BLACK)),
							slider("Brightness", 2, 0, 10, 1),
							slider("Clock Time", 14, 0, 24, 1),
							toggle("No Shadows", false),
						},
					},
				},
				Right = {
					{
						Title = "Atmosphere",
						Rows = {
							toggle("Fog", false, tinted(GREY)),
							slider("Fog Start", 0, 0, 1000, 0),
							slider("Fog End", 1000, 0, 5000, 0),
							caption("Skybox"),
							dropdown({ "Default", "Night", "Sunset", "Space" }, { "Default" }),
						},
					},
				},
			},
			{
				Name = "Player",
				Left = {
					{
						Title = "Local Player",
						Rows = {
							toggle("Self Chams", false, tinted(CYAN, GREY)),
							caption("Material"),
							dropdown(MATERIALS, { "ForceField" }),
							toggle("Hide Accessories", false),
							toggle("Trail", false, tinted(CYAN)),
						},
					},
				},
				Right = {
					{
						Title = "Camera",
						Rows = {
							slider("Field Of View", 70, 30, 120, 0),
							toggle("Third Person", false, bindable("Toggle", "None")),
							slider("", 12, 2, 40, 0),
							toggle("No Camera Shake", false),
						},
					},
				},
			},
		},
	},
	{
		Name = "Misc",
		Left = {
			{
				Title = "Movement",
				Rows = {
					toggle("Bunny Hop", false, bindable("Always", "None")),
					toggle("Auto Slide Jump", false),
					toggle("Jump Bug", false, bindable("Hold", "X")),
					toggle("Edge Jump", false, bindable("Always", "V")),
					toggle("Auto Strafe", false),
					caption("Auto Strafe Pattern"),
					dropdown({ "Adaptive", "Forward", "Sideways" }, { "Adaptive" }),
					slider("Auto Strafe Intensity", 80, 0, 100, 0),
					toggle("Auto View Angle", false),
				},
			},
			{
				Title = "Character",
				Rows = {
					toggle("Enable Walk Speed", false, bindable("Always", "None")),
					slider("", 45, 0, 150, 0),
					toggle("Enable Slide Boost", false, bindable("Always", "None")),
					slider("", 5, 1, 10, 0),
					toggle("Enable Jump Power", false, bindable("Always", "None")),
					slider("", 100, 0, 150, 0),
					toggle("Enable Fly", false, bindable("Always", "None")),
					slider("", 50, 0, 10000, 0),
				},
			},
		},
		Right = {
			{
				Title = "Weapons",
				Rows = {
					toggle("Unlock All", true),
					toggle("Recoil Modifier (%)", false),
					slider("", 100, 0, 100, 0),
					toggle("No Spread", true),
					toggle("Rapid Fire", false),
					toggle("Automatic Weapon", false),
					toggle("Instant Scope", false),
					toggle("Always Backstab", true),
					toggle("Anti Katana", true),
				},
			},
			{
				Title = "World",
				Rows = {
					toggle("Prevent Out Of Bounds", false),
					toggle("Remove Killers", false),
					toggle("No Fire Damage", false),
				},
			},
		},
	},
	{
		Name = "Settings",
		Left = {
			{
				Title = "Menu",
				Rows = {
					menuKeyRow("Menu Key", "RightShift"),
					button("Hide Menu", function()
						setMenuVisible(false)
					end),
					button("Unload", function()
						screen:Destroy()
					end),
				},
			},
		},
		Right = {
			{
				Title = "Configuration",
				Rows = {
					field("Config name"),
					caption("Config List"),
					dropdown({ "Default" }, { "Default" }),
					button("Create"),
					button("Save"),
					button("Load"),
					button("Delete"),
				},
			},
		},
	},
}

buildTabs(body, Menu, renderPage)

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if activeCapture then
			local capture = activeCapture
			if not (isPointerPress(input) and isInside(capture.Anchor, input.Position)) then
				if isPress(input) then
					capture.Finish(nil)
				else
					local name = inputName(input)
					if name then
						capture.Finish(name)
					end
				end
			end
			return
		end

		if
			activePopup
			and isPointerPress(input)
			and not isInside(activePopup.Frame, input.Position)
			and not isInside(activePopup.Anchor, input.Position)
		then
			closePopup()
		end

		if not processed and inputName(input) == menuKey then
			setMenuVisible(not window.Visible)
		end
	end)
)

screen.Destroying:Connect(function()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
end)
