-- Win11UIModule (ModuleScript) – Full Mobile + PC Support
-- Supports: Space, Logs, BoolValue, Slider, TextBox, TextBoxAndButton,
--           Button, ColorUI, ColorPicker, InstancePicker, SaveLoad, Keybind
-- ✦ เพิ่ม: Window slide-up open animation + Tab slide-from-left animation

local Win11UIModule = {}
Win11UIModule.__index = Win11UIModule

-- ─── Services ────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local UIS              = UserInputService
local LogService       = game:GetService("LogService")
local Debris           = game:GetService("Debris")

local neon
if game:GetService("RunService"):IsStudio() then
	neon = require(game.ReplicatedStorage.neon) 
else
	neon = loadstring(game:HttpGet("https://raw.githubusercontent.com/chaiya333222-oss/test123/refs/heads/main/test3.lua", true))()
end
-- ─── Mobile Detection ────────────────────────
local isMobile = false

-- ─── Global State ────────────────────────────
local globalConnections = {}
local activePickerCloser = nil

local function trackGlobalConnection(conn)
	table.insert(globalConnections, conn)
	return conn
end

local function cleanupGlobalConnections()
	for _, conn in ipairs(globalConnections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	globalConnections = {}
	
	pcall(function()
		local cg = game:GetService("CoreGui")
		local fab = cg:FindFirstChild("BenTen_Mobile") or Players.LocalPlayer.PlayerGui:FindFirstChild("BenTen_Mobile")
		if fab then fab:Destroy() end
	end)
end

-- ─── Helpers ─────────────────────────────────
local function new(class, parent, props)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function tw(obj, tweenInfo, props)
	if typeof(tweenInfo) == "number" then
		local tween = TweenService:Create(
			obj,
			TweenInfo.new(tweenInfo or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			props
		)
		tween:Play()
		return tween
	else
		local tween = TweenService:Create(obj, tweenInfo, props)
		tween:Play()
		return tween
	end
end

local function ripple(btn)
	if not btn or not btn.Parent then return end
	local r = new("Frame", btn, {
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.fromOffset(0, 0),
		BackgroundColor3       = rgb(255, 255, 255),
		BackgroundTransparency = 0.7,
		BorderSizePixel        = 0,
		ZIndex                 = (btn.ZIndex or 1) + 5,
	})
	new("UICorner", r, { CornerRadius = UDim.new(1, 0) })
	local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2
	local ti = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(r, ti, { Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1 }):Play()
	Debris:AddItem(r, 0.45)
end

local function colorToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local function hexToColor3(hex)
	hex = hex:gsub("#", "")
	if #hex == 6 then
		local r = tonumber(hex:sub(1, 2), 16)
		local g = tonumber(hex:sub(3, 4), 16)
		local b = tonumber(hex:sub(5, 6), 16)
		if r and g and b then return Color3.fromRGB(r, g, b) end
	end
	return nil
end

local function getContrastColor(c)
	local brightness = (c.R * 0.299) + (c.G * 0.587) + (c.B * 0.114)
	return brightness > 0.5 and rgb(0, 0, 0) or rgb(255, 255, 255)
end

-- ─── Touch/Mouse unified input ───────────────
local function isTouchOrMouse(inp)
	return inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch
end

local function isMove(inp)
	return inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch
end

-- ─── Color Palette ────────────────────────────
local C = {
	BASE      = rgb(18, 18, 20),
	SURFACE   = rgb(24, 24, 27),
	SURFACE2  = rgb(30, 30, 34),
	SIDEBAR   = rgb(14, 14, 16),
	BORDER    = rgb(35, 35, 42),
	BORDER2   = rgb(44, 44, 52),
	ACCENT    = rgb(30, 30, 30),
	TEXT      = rgb(200, 200, 208),
	TEXT2     = rgb(255,255,255),
	ICON      = rgb(105, 105, 118),
	HOVER     = rgb(255, 255, 255),
	SEL_BAR   = rgb(130, 130, 148),
	DIVIDER   = rgb(30, 30, 30),
	CLOSEHOV  = rgb(58, 58, 58),
	MINHOV    = rgb(32, 32, 38),
}

-- ─── Item Design Tokens ──────────────────────
local D = {
	pillBg      = rgb(20, 20, 24),
	pillBorder  = rgb(36, 36, 44),
	pillText    = rgb(190, 190, 200),
	pillMuted   = rgb(75, 75, 88),
	accent      = rgb(130, 130, 148),
	accentDim   = rgb(32, 32, 40),
	sliderFill  = rgb(120, 120, 140),
	sliderTrack = rgb(30, 30, 36),
	knob        = rgb(160, 160, 172),
	rad         = UDim.new(0.05, 0),
	radRound    = UDim.new(1, 0),
	fontMain    = isMobile and 15 or 14,
	fontSub     = isMobile and 12 or 16,
	fontValue   = isMobile and 15 or 14,
	fontSmall   = isMobile and 13 or 12,
	fontIcon    = isMobile and 20 or 18,
	inputW      = isMobile and 150 or 140,
	keybindW    = isMobile and 70 or 60,
	sliderW     = isMobile and 160 or 200,
	btnW        = 90,
	toggleW     = isMobile and 50 or 45,
	pillH       = isMobile and 38 or 32,
	marginR     = 20,
	iconSize    = isMobile and 32 or 28,
	iconPad     = 8,
}








function Win11UIModule.Key(config)
	local player    = Players.LocalPlayer
	local playerGui = game:GetService("CoreGui") or player:WaitForChild("PlayerGui")
	local camera    = workspace.CurrentCamera

	-- ── Window state ─────────────────────────
	local BASE_W = isMobile and 540  or 1280
	local BASE_H = isMobile and 960  or 720

	local vp0 = camera.ViewportSize
	local WIN_W = config.width  or (isMobile and math.floor(vp0.X * 0.95) or 420)
	local WIN_H = config.height or (isMobile and math.floor(vp0.Y * 0.45) or 320)
	local WIN   = { dx = 0, dy = 0, w = WIN_W, h = WIN_H }

	-- ── ScreenGui + UIScale ───────────────────
	local sg = new("ScreenGui", playerGui, {
		Name           = "BenTen__" .. tostring(math.random(1e6)),
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder   = 100,
		IgnoreGuiInset = true,
	})
	local uiScale = new("UIScale", sg, {})




	local window = new("Frame", sg, {
		AnchorPoint      = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.BASE,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
	})
	new("UICorner", window, { CornerRadius = UDim.new(0, 12) })
	new("UIStroke", window, { Color = C.BORDER, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })

	local function applyWin()
		window.Position = UDim2.new(0.5, WIN.dx, 0.5, WIN.dy)
		window.Size     = UDim2.fromOffset(WIN.w, WIN.h)
	end
	applyWin()

	local function updateScale()
		local vp = camera.ViewportSize
		if isMobile then
			uiScale.Scale = 1
			WIN.w  = math.floor(vp.X * 0.95)
			WIN.h  = math.floor(vp.Y * 0.45)
			WIN.dx = 0
			WIN.dy = 0
			applyWin()
		else
			uiScale.Scale = math.min(vp.X / BASE_W, vp.Y / BASE_H)
		end
	end
	updateScale()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

	local function getRefSize()
		local vp = camera.ViewportSize
		local sc = uiScale.Scale
		return vp.X / sc, vp.Y / sc
	end

	local function getOffScreenBottom()
		local _, rh = getRefSize()
		return math.floor(rh / 2 + WIN.h / 2 + 50)
	end

	-- ── Title Bar ────────────────────────────
	local TITLE_H = isMobile and 38 or 32
	local titleBar = new("Frame", window, {
		Size             = UDim2.new(1, 0, 0, TITLE_H),
		BackgroundColor3 = rgb(28, 28, 28),
		BorderSizePixel  = 0,
		ZIndex           = 10,
		
		Transparency = 0,
	})
	
	new("Frame", titleBar, {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = C.BORDER,
		BorderSizePixel  = 0,
	})
	new("UICorner", titleBar, { CornerRadius = UDim.new(0, 12) })

	new("TextLabel", titleBar, {
		Size               = UDim2.new(0, 200, 1, 0),
		Position           = UDim2.fromOffset(30, 0),
		BackgroundTransparency = 1,
		Text               = config.title or "Key System",
		TextColor3         = C.TEXT2,
		Font               = Enum.Font.GothamBold,
		TextSize           = isMobile and 13 or 12,
		TextXAlignment     = Enum.TextXAlignment.Left,
		ZIndex             = 11,
	})

	local ctrlW = isMobile and 36 or 46
	local closeBtn = new("TextButton", titleBar, {
		Size                = UDim2.fromOffset(ctrlW, TITLE_H),
		Position            = UDim2.new(1, -ctrlW, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel     = 0,
		Text                = "X",
		TextColor3          = C.TEXT2,
		Font                = Enum.Font.Gotham,
		TextSize            = isMobile and 13 or 12,
		AutoButtonColor     = false,
		ZIndex              = 11,
	})
	new("UICorner", closeBtn, { CornerRadius = UDim.new(0, 12) })
	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = C.CLOSEHOV
		tw(closeBtn, 0.1, { BackgroundTransparency = 0 })
	end)
	closeBtn.MouseLeave:Connect(function()
		tw(closeBtn, 0.1, { BackgroundTransparency = 1 })
	end)
	closeBtn.MouseButton1Click:Connect(function()
		local targetY = getOffScreenBottom()
		TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, WIN.dx, 0.5, targetY),
		}):Play()
		task.delay(0.32, function()
			cleanupGlobalConnections()
			sg:Destroy()
		end)
	end)

	-- ── Body Content ─────────────────────────
	local body = new("Frame", window, {
		Size                = UDim2.new(1, 0, 1, -TITLE_H),
		Position            = UDim2.fromOffset(0, TITLE_H),
		BackgroundTransparency = 1,
		BorderSizePixel     = 0,
		ClipsDescendants    = false,
	})

	new("TextLabel", body, {
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.15, 0),
		Size                   = UDim2.fromOffset(50, 50),
		BackgroundTransparency = 1,
		Text                   = "🔑",
		TextSize               = isMobile and 32 or 28,
		ZIndex                 = 5,
	})

	new("TextLabel", body, {
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.32, 0),
		Size                   = UDim2.new(0.85, 0, 0, 22),
		BackgroundTransparency = 1,
		Text                   = config.lockTitle or "กรุณาใส่ Key เพื่อใช้งาน",
		TextColor3             = C.TEXT,
		Font                   = Enum.Font.GothamBold,
		TextSize               = isMobile and 15 or 14,
		ZIndex                 = 5,
	})

	-- ── ช่องใส่ Key ──────────────────────────
	local INPUT_W = isMobile and 260 or 300
	local INPUT_H = isMobile and 42 or 38
	local inputFrame = new("Frame", body, {
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0.5, 0, 0.52, 0),
		Size             = UDim2.fromOffset(INPUT_W, INPUT_H),
		BackgroundColor3 = rgb(30, 30, 36),
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Name             = "InputFrame",
		Transparency = .6,
	})
	new("UICorner", inputFrame, { CornerRadius = UDim.new(0, 8) })
	local inputStroke = new("UIStroke", inputFrame, { Color = D.pillBorder, Thickness = 1 })

	local keyInput = new("TextBox", inputFrame, {
		AnchorPoint        = Vector2.new(0.5, 0.5),
		Position           = UDim2.new(0.5, 0, 0.5, 0),
		Size               = UDim2.new(0.9, 0, 0.7, 0),
		BackgroundTransparency = 1,
		Font               = Enum.Font.Code,
		Text               = "",
		PlaceholderText    = "ใส่ Key ที่นี่...",
		PlaceholderColor3  = Color3.new(0.647059, 0.647059, 0.647059),
		TextColor3         = Color3.new(1, 1, 1),
		TextSize           = isMobile and 15 or 14,
		ClearTextOnFocus   = false,
		TextXAlignment     = Enum.TextXAlignment.Center,
		ZIndex             = 6,
	})


	keyInput.Focused:Connect(function() tw(inputStroke, 0.15, { Color = rgb(1, 1, 1) }) end)
	keyInput.FocusLost:Connect(function() tw(inputStroke, 0.15, { Color = D.pillBorder }) end)

	local errorLabel = new("TextLabel", body, {
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.64, 0),
		Size                   = UDim2.new(0.85, 0, 0, 18),
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = rgb(255, 80, 80),
		Font                   = Enum.Font.Gotham,
		TextSize               = isMobile and 12 or 11,
		TextTransparency       = 1,
		ZIndex                 = 5,
	})

	local function showError(msg)
		errorLabel.Text = msg
		tw(errorLabel, 0.15, { TextTransparency = 0 })
		tw(inputStroke, 0.15, { Color = rgb(200, 50, 50) })
		task.delay(2.5, function()
			if errorLabel and errorLabel.Parent then tw(errorLabel, 0.3, { TextTransparency = 1 }) end
			if inputStroke and inputStroke.Parent then tw(inputStroke, 0.3, { Color = D.pillBorder }) end
		end)
	end

	-- ── ปุ่ม CopyKey + ตกลง ──────────────────
	local BTN_H   = isMobile and 38 or 34
	local BTN_GAP = isMobile and 10 or 12
	local COPY_W  = isMobile and 130 or 140
	local OK_W    = isMobile and 130 or 140
	local totalW  = COPY_W + BTN_GAP + OK_W
	local startX  = -totalW / 2

	local copyBtnFrame = new("Frame", body, {
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0.5, startX, 0.78, 0),
		Size             = UDim2.fromOffset(COPY_W, BTN_H),
		BackgroundColor3 = rgb(45, 50, 70),
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Transparency = .6
	})
	new("UICorner", copyBtnFrame, { CornerRadius = UDim.new(0, 8) })
	new("UIStroke", copyBtnFrame, { Color = rgb(65, 70, 95), Thickness = 1 })

	new("TextLabel", copyBtnFrame, {
		AnchorPoint            = Vector2.new(0.5, 0.5), Position = UDim2.new(0.45, 0, 0.5, 0),
		Size                   = UDim2.new(0.7, 0, 0.65, 0), BackgroundTransparency = 1,
		Text                   = "📋 CopyKey", TextColor3 = rgb(180, 185, 210),
		Font                   = Enum.Font.GothamMedium, TextSize = isMobile and 13 or 12, ZIndex = 6,
	})
	new("TextLabel", copyBtnFrame, {
		AnchorPoint            = Vector2.new(1, 0.5), Position = UDim2.new(0.95, 0, 0.5, 0),
		Size                   = UDim2.new(0.2, 0, 0.5, 0), BackgroundTransparency = 1,
		Text                   = "∨", TextColor3 = D.pillMuted, TextSize = isMobile and 12 or 10, ZIndex = 6,
	})

	local okBtnFrame = new("Frame", body, {
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0.5, startX + COPY_W + BTN_GAP, 0.78, 0),
		Size             = UDim2.fromOffset(OK_W, BTN_H),
		BackgroundColor3 = rgb(50, 75, 55),
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Transparency = .6
	})
	new("UICorner", okBtnFrame, { CornerRadius = UDim.new(0, 8) })
	new("UIStroke", okBtnFrame, { Color = rgb(60, 100, 65), Thickness = 1 })

	new("TextLabel", okBtnFrame, {
		AnchorPoint            = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size                   = UDim2.new(0.8, 0, 0.65, 0), BackgroundTransparency = 1,
		Text                   = "✓ ตกลง", TextColor3 = rgb(180, 220, 185),
		Font                   = Enum.Font.GothamBold, TextSize = isMobile and 13 or 12, ZIndex = 6,
	})
	local copyBtn = new("TextButton", copyBtnFrame, { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 7 })
	local okBtn = new("TextButton", okBtnFrame, { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 7 })

	copyBtn.MouseEnter:Connect(function() tw(copyBtnFrame, 0.12, { BackgroundColor3 = rgb(55, 60, 85) }) end)
	copyBtn.MouseLeave:Connect(function() tw(copyBtnFrame, 0.12, { BackgroundColor3 = rgb(45, 50, 70) }) end)
	okBtn.MouseEnter:Connect(function() tw(okBtnFrame, 0.12, { BackgroundColor3 = rgb(55, 90, 65) }) end)
	okBtn.MouseLeave:Connect(function() tw(okBtnFrame, 0.12, { BackgroundColor3 = rgb(50, 75, 55) }) end)

	-- ══════════════════════════════════════════
	-- Dropdown (ปรับซ้าย + กรอบพอดิ้งเนื้อหา)
	-- ══════════════════════════════════════════
	local dropdownOpen = false
	local dropdown = nil
	local dropdownConn = nil
	local currentDropdownH = 100 -- ตัวแปรเก็บความสูงจริง

	local copyCategories = config.copyLinks or {}
	local linkMap = config.linkMap or {}

	local ITEM_H = isMobile and 38 or 34
	local POP_WIDTH = isMobile and (WIN_W - 40) or 250

	local function closeDropdown(instant)
		dropdownOpen = false
		if dropdownConn then dropdownConn:Disconnect(); dropdownConn = nil end
		if not dropdown then return end

		if instant then
			if dropdown.Parent then dropdown:Destroy() end
			dropdown = nil
		else
			local curW = dropdown.Size.X.Offset
			dropdown.ClipsDescendants = true
			TweenService:Create(dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.fromOffset(curW, 0),
			}):Play()
			task.delay(0.22, function()
				if dropdown and dropdown.Parent then dropdown:Destroy(); dropdown = nil end
			end)
		end
	end
	local function buildDropdown()
		if dropdown then dropdown:Destroy() end
		dropdown = new("Frame", window, {
			BackgroundColor3 = rgb(22, 22, 26),
			BorderSizePixel  = 0,
			ClipsDescendants = true,
			Visible          = false,
			ZIndex           = 50,
			Transparency = .3
		})
	
		new("UICorner", dropdown, { CornerRadius = UDim.new(0, 8) })
		new("UIStroke", dropdown, { Color = rgb(55, 55, 65), Thickness = 1 })



		local listFrame = new("ScrollingFrame", dropdown, {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = isMobile and 3 or 4, ScrollBarImageColor3 = rgb(60, 60, 70),
		})
		new("UIListLayout", listFrame, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })
		new("UIPadding", listFrame, { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
	
		local order = 0
		local calcH = 12 

		for _, cat in ipairs(copyCategories) do
			order = order + 1
			calcH = calcH + 26 
			local headerFrame = new("Frame", listFrame, { BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 26)  })
			new("TextLabel", headerFrame, {
				AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Position = UDim2.new(0, 4, 1, 0), Size = UDim2.new(1, 0, 0, 22),
				Font = Enum.Font.GothamBold, Text = cat.name, TextColor3 = rgb(255,255,255), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
			})

			for _, itemName in ipairs(cat.items or {}) do
				order = order + 1
				calcH = calcH + ITEM_H + 2 -- Item height + padding
				local itemFrame = new("Frame", listFrame, { BackgroundColor3 = rgb(30, 30, 38), BorderSizePixel = 0, LayoutOrder = order, Size = UDim2.new(1, 0, 0, ITEM_H) , Transparency = .5})
				new("UICorner", itemFrame, { CornerRadius = UDim.new(0, 6) })

				local iconText = "🔗"
				if itemName:find("Discord") then iconText = "💬"
				elseif itemName:find("YouTube") then iconText = "▶️"
				elseif itemName:find("Facebook") then iconText = "📘"
				elseif itemName:find("Website") then iconText = "🌐" end

				new("TextLabel", itemFrame, { AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.08, 0, 1, 0), Text = iconText, TextSize = isMobile and 14 or 12 })
				new("TextLabel", itemFrame, { AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Position = UDim2.new(0, 32, 0.5, 0), Size = UDim2.new(1, -45, 0, ITEM_H - 4), Font = Enum.Font.Gotham, Text = itemName, TextColor3 = rgb(180, 180, 195), TextSize = isMobile and 13 or 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
				new("TextLabel", itemFrame, { AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 1, Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.15, 0, 0.5, 0), Text = "↗", TextColor3 = D.pillMuted, TextSize = isMobile and 14 or 12 })

				local itemBtn = new("TextButton", itemFrame, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", ZIndex = 2 })
				itemBtn.MouseEnter:Connect(function() tw(itemFrame, 0.1, { BackgroundColor3 = rgb(40, 40, 50) }) end)
				itemBtn.MouseLeave:Connect(function() tw(itemFrame, 0.1, { BackgroundColor3 = rgb(30, 30, 38) }) end)
				itemBtn.MouseButton1Click:Connect(function()
					local link = linkMap[itemName] or itemName
					if setclipboard then pcall(function() setclipboard(link) end) end
					if config.onCopy then config.onCopy(itemName, link) end
					closeDropdown()
					ripple(itemBtn)
				end)
			end
		end

		currentDropdownH = math.clamp(calcH, 50, 300)
		dropdown.Size = UDim2.fromOffset(POP_WIDTH, currentDropdownH)
	end

	local function calcDropdownPos()
		local sc = uiScale.Scale
		local winAbs = window.AbsolutePosition
		local btnAbs = copyBtnFrame.AbsolutePosition
		local btnSz  = copyBtnFrame.AbsoluteSize

		local relX = btnAbs.X - winAbs.X
		local relY = btnAbs.Y + btnSz.Y - winAbs.Y

		local x = relX / sc - 58
		local y = relY / sc +  10

		if x + POP_WIDTH > WIN.w - 10 then
			x = WIN.w - POP_WIDTH - 10
		end

		local _, rh = getRefSize()
		if y + currentDropdownH > rh - 10 then
			local relBtnTop = btnAbs.Y - winAbs.Y
			y = relBtnTop / sc - currentDropdownH - 4
		end

		return x, y
	end

	local function openDropdown()
		if dropdownOpen then closeDropdown(); return end
		buildDropdown()
		local x, y = calcDropdownPos()

		dropdown.Position        = UDim2.fromOffset(x, y)
		dropdown.Size            = UDim2.fromOffset(POP_WIDTH, 0)
		dropdown.ClipsDescendants = true
		dropdown.Visible         = true
		dropdownOpen             = true

		TweenService:Create(dropdown, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(POP_WIDTH, currentDropdownH),
		}):Play()

		dropdownConn = UIS.InputBegan:Connect(function(inp)
			if not dropdownOpen or not dropdown or not dropdown.Parent then return end
			if not isTouchOrMouse(inp) then return end
			local pos = inp.Position
			local bPos = copyBtnFrame.AbsolutePosition
			local bSz  = copyBtnFrame.AbsoluteSize
			if pos.X >= bPos.X and pos.X <= bPos.X + bSz.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSz.Y then return end
			local dPos = dropdown.AbsolutePosition
			local dSz  = dropdown.AbsoluteSize
			if pos.X >= dPos.X and pos.X <= dPos.X + dSz.X and pos.Y >= dPos.Y and pos.Y <= dPos.Y + dSz.Y then return end
			closeDropdown()
		end)
	end

	copyBtn.MouseButton1Click:Connect(function()
		if dropdownOpen then closeDropdown() else openDropdown() end
		ripple(copyBtn)
	end)

	local function trySubmit()
		local inputKey = keyInput.Text
		if inputKey == "" then showError("⚠️ กรุณาใส่ Key") return end

		local isValid = false
		if config.validateKey then isValid = config.validateKey(inputKey)
		elseif config.correctKey then isValid = (inputKey == config.correctKey) end

		if isValid then
			if config.onSuccess then config.onSuccess(inputKey) end
			local targetY = getOffScreenBottom()
			tw(window, 0.25, { BackgroundTransparency = 1 })
			TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, WIN.dx, 0.5, targetY),
			}):Play()
			task.delay(0.35, function()
				if config.onComplete then config.onComplete(inputKey) else sg:Destroy() end
			end)
		else
			showError("❌ Key ผิด!")
			if config.onFail then config.onFail(inputKey) end
			local origX = inputFrame.Position.X.Offset
			task.spawn(function()
				for i = 1, 6 do
					local shakeX = (i % 2 == 0) and 6 or -6
					tw(inputFrame, 0.04, { Position = UDim2.new(0.5, origX + shakeX, 0.52, 0) })
					task.wait(0.01)
				end
				tw(inputFrame, 0.1, { Position = UDim2.new(0.5, origX, 0.52, 0) })
			end)
		end
	end

	okBtn.MouseButton1Click:Connect(function() trySubmit(); ripple(okBtn) end)
	keyInput.FocusLost:Connect(function(enter) if enter then trySubmit() end end)

	-- ── Window Open Animation ────────────────
	local offScreenBottom = getOffScreenBottom()
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, WIN.dx, 0.5, offScreenBottom)
	
	neon:BindFrame(window, {
		Transparency = 0.98,
		BrickColor = BrickColor.new("Institutional white")
	})
	tw(window, 0.25, { BackgroundTransparency = .3 })
	TweenService:Create(window, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, WIN.dx, 0.5, WIN.dy)
	}):Play()

	task.delay(0.5, function()
		if keyInput and keyInput.Parent then keyInput:CaptureFocus() end
	end)
	sg.AncestryChanged:Connect(function()
		if not sg.Parent then
			pcall(function() neon:UnbindFrame(window) end)
		end
	end)
	return sg
end



return Win11UIModule
