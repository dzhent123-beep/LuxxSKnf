--[[ luxxs :: LocalScript -> StarterPlayer > StarterPlayerScripts
     ключ: best | открыть/закрыть: иконка Lx или RightShift ]]

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")
for _, n in ipairs({ "Luxxs", "LuxxsESP" }) do
	local o = pgui:FindFirstChild(n)
	if o then o:Destroy() end
end

local KEY = "best"
local conns, dead = {}, false
local function on(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

-- ===== helpers =====
local EZ = Enum.EasingStyle
local ED = Enum.EasingDirection
local function tw(o, t, props, st, dr)
	local x = TS:Create(o, TweenInfo.new(t, st or EZ.Quad, dr or ED.Out), props)
	x:Play()
	return x
end
local function new(cls, props)
	local o = Instance.new(cls)
	for k, v in pairs(props) do
		if k ~= "Parent" then o[k] = v end
	end
	o.Parent = props.Parent
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = r or UDim.new(0, 8), Parent = o }) end
local PILL = UDim.new(1, 0)
local function stroke(o, col, th)
	return new("UIStroke", { Color = col, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end
local function setLine(f, x1, y1, x2, y2, th, col)
	local dx, dy = x2 - x1, y2 - y1
	f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), th)
	f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
	f.Rotation = math.deg(math.atan2(dy, dx))
	f.BackgroundColor3 = col
	f.Visible = true
end

local C = {
	bg = Color3.fromRGB(12, 15, 13), panel = Color3.fromRGB(17, 21, 19), row = Color3.fromRGB(25, 30, 27),
	text = Color3.fromRGB(228, 236, 230), dim = Color3.fromRGB(122, 138, 128), off = Color3.fromRGB(50, 57, 53),
	red = Color3.fromRGB(255, 85, 85), white = Color3.new(1, 1, 1),
}
local PAL = {
	Color3.fromRGB(70, 255, 120), Color3.fromRGB(0, 220, 255), Color3.fromRGB(70, 120, 255),
	Color3.fromRGB(170, 90, 255), Color3.fromRGB(255, 90, 200), Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 235, 70), Color3.fromRGB(255, 255, 255),
}
local function pal(i)
	if i == 10 then return Color3.fromHSV(os.clock() * 0.25 % 1, 0.85, 1) end
	return PAL[i]
end

-- ===== state (все выключено) =====
local S = {
	aim = false, aimAct = "Hold RMB", aimMode = "Smooth", smooth = 40, fov = 120, fovShow = false,
	wall = true, team = false, aimPart = "Head",
	box = false, boxType = "2D", boxCol = 1, name = false, dist = false, hp = false,
	skel = false, skelCol = 9, chams = false, chamCol = 1, glow = false, glowCol = 2, tracer = false,
	trail = false, trailCol = 10, trailLen = 1, wings = false, wingType = "Angel",
	cross = false, fullbright = false,
	fly = false, flySpeed = 60, noclip = false, speedOn = false, speed = 32,
	fpsCustom = false, fps = 144, fpsShow = false,
	alpha = 0.05, size = 1, menuCol = 1, hue = .39, notif = true,
	headDot = false, headCol = 6, tool = false, arrows = false, arrowCol = 1,
	aura = false, auraCol = 4, selfFF = false, ffCol = 2, timeOn = false, timeVal = 14,
}

-- ===== theme =====
local accent = PAL[1]
local accReg, bgReg, hooks = {}, {}, {}
local function A(o, prop)
	accReg[#accReg + 1] = { o, prop }
	o[prop] = accent
	return o
end
local function BG(o, base)
	bgReg[#bgReg + 1] = { o, base }
	o.BackgroundTransparency = math.clamp(base + S.alpha, 0, 1)
	return o
end
local function setAccent(c)
	accent = c
	for _, r in ipairs(accReg) do
		if r[1].Parent then r[1][r[2]] = c end
	end
	for _, h in ipairs(hooks) do h() end
end
local function setAlpha()
	for _, r in ipairs(bgReg) do
		if r[1].Parent then r[1].BackgroundTransparency = math.clamp(r[2] + S.alpha, 0, 1) end
	end
end

local pv = function() end -- preview refresh (ниже)

-- ===== roots =====
local guiParent = pgui
do
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and typeof(h) == "Instance" then guiParent = h end
end
for _, n in ipairs({ "Luxxs", "LuxxsESP" }) do
	local o = guiParent:FindFirstChild(n)
	if o then o:Destroy() end
end
local gui = new("ScreenGui", { Name = "Luxxs", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
local espGui = new("ScreenGui", { Name = "LuxxsESP", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 8,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })

-- тосты справа снизу
local toastHost = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(250, 320),
	BackgroundTransparency = 1, ZIndex = 100, Parent = gui })
new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 6), Parent = toastHost })
local function notify(txt)
	if not S.notif then return end
	local slot = new("Frame", { Size = UDim2.fromOffset(230, 34), BackgroundTransparency = 1, Parent = toastHost })
	local card = new("Frame", { Position = UDim2.fromOffset(260, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg,
		BackgroundTransparency = .08, BorderSizePixel = 0, Parent = slot })
	corner(card, UDim.new(0, 8))
	A(stroke(card, accent, 1), "Color")
	local bar = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 8, .5, 0), Size = UDim2.new(0, 3, .55, 0), BorderSizePixel = 0, Parent = card })
	A(bar, "BackgroundColor3"); corner(bar, PILL)
	new("TextLabel", { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -26, 1, 0), BackgroundTransparency = 1, Text = txt,
		Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	tw(card, .35, { Position = UDim2.fromOffset(0, 0) }, EZ.Back)
	task.delay(2, function()
		if not card.Parent then return end
		tw(card, .3, { Position = UDim2.fromOffset(260, 0) }, EZ.Quad, ED.In)
		task.delay(.35, function() slot:Destroy() end)
	end)
end

local function drag(handle, target, onClick)
	local dragging, moved, start, orig = false, false, nil, nil
	on(handle.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, moved, start, orig = true, false, i.Position, target.Position
			local c
			c = i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
					if not moved and onClick then onClick() end
				end
			end)
		end
	end)
	on(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			if d.Magnitude > 5 then moved = true end
			if moved then
				target.Position = UDim2.new(orig.X.Scale, orig.X.Offset + d.X, orig.Y.Scale, orig.Y.Offset + d.Y)
			end
		end
	end)
end

-- ===== окно =====
local W, H = 780, 440
local holder = new("Frame", { Name = "Holder", Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5), BackgroundTransparency = 1, Visible = false, Parent = gui })
local userScale = new("UIScale", { Parent = holder })
local animF = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1, Parent = holder })
local win = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, GroupTransparency = 1, Parent = animF })
BG(win, 0)
corner(win, UDim.new(0, 12))
local winStroke = stroke(win, accent, 1.6)
A(winStroke, "Color")
local winGrad = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.white),
	ColorSequenceKeypoint.new(.5, Color3.fromRGB(60, 60, 60)), ColorSequenceKeypoint.new(1, C.white) }), Parent = winStroke })
local animScale = new("UIScale", { Scale = .88, Parent = animF })

local function fit()
	local vp = gui.AbsoluteSize
	userScale.Scale = math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), .35, 1.6) * S.size
end
on(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)

-- шапка
local header = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = win })
drag(header, holder)
local logo = new("Frame", { Position = UDim2.fromOffset(12, 7), Size = UDim2.fromOffset(28, 26), BorderSizePixel = 0, Parent = header })
A(logo, "BackgroundColor3"); corner(logo, UDim.new(0, 7))
new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Lx", Font = Enum.Font.GothamBlack,
	TextSize = 14, TextColor3 = C.bg, Parent = logo })
local title = new("TextLabel", { Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
	Text = "luxxs  /  Combat", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = header })
local closeBtn = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(24, 24),
	BackgroundColor3 = C.row, Text = "×", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.dim, AutoButtonColor = false, Parent = header })
corner(closeBtn, UDim.new(0, 6))
new("Frame", { Position = UDim2.fromOffset(0, 39), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.off, BackgroundTransparency = .5, BorderSizePixel = 0, Parent = win })

-- сайдбар
local side = new("Frame", { Position = UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(130, H - 40), BorderSizePixel = 0, BackgroundColor3 = C.panel, Parent = win })
BG(side, .1)
local tabList = new("Frame", { Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, Parent = side })
new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = tabList })
local brand = new("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.fromOffset(100, 28),
	BackgroundTransparency = 1, Text = "luxxs", Font = Enum.Font.GothamBlack, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Parent = side })
A(brand, "TextColor3")
local brandStroke = new("UIStroke", { Thickness = 1, Transparency = .75, Parent = brand })
A(brandStroke, "Color")

-- контент
local content = new("Frame", { Position = UDim2.fromOffset(130, 40), Size = UDim2.fromOffset(390, H - 40), BackgroundTransparency = 1, Parent = win })
local pages, tabBtns, curTab = {}, {}, nil

local function page(name)
	local p = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, Parent = content })
	A(p, "ScrollBarImageColor3")
	new("UIListLayout", { Padding = UDim.new(0, 6), Parent = p })
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), Parent = p })
	pages[name] = p
	return p
end

local function paintTabs()
	for n, t in pairs(tabBtns) do
		local sel = n == curTab
		tw(t.ind, .2, { BackgroundTransparency = sel and 0 or 1 })
		tw(t.lbl, .2, { TextColor3 = sel and accent or C.dim })
	end
end
hooks[#hooks + 1] = function() if curTab then paintTabs() end end

local function selectTab(n)
	if curTab == n then return end
	curTab = n
	for k, p in pairs(pages) do p.Visible = k == n end
	title.Text = "luxxs  /  " .. n
	paintTabs()
end
local function addTab(n)
	local b = new("TextButton", { Size = UDim2.new(1, -16, 0, 34), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = tabList })
	local ind = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.fromOffset(3, 16), BorderSizePixel = 0, Parent = b })
	A(ind, "BackgroundColor3"); ind.BackgroundTransparency = 1; corner(ind, PILL)
	local lbl = new("TextLabel", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0), BackgroundTransparency = 1, Text = n,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = b })
	tabBtns[n] = { ind = ind, lbl = lbl }
	on(b.MouseButton1Click, function() selectTab(n) end)
end

-- ===== компоненты =====
local function row(pg, h)
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, h), BorderSizePixel = 0, BackgroundColor3 = C.row, Parent = pg })
	BG(r, .3); corner(r, UDim.new(0, 7))
	return r
end
local function rlabel(r, txt, w)
	return new("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, w or -70, 0, 34), BackgroundTransparency = 1, Text = txt,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
end
local function section(pg, txt)
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = pg })
	local l = new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = string.upper(txt), Font = Enum.Font.GothamBold,
		TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
	A(l, "TextColor3")
end

local function toggle(pg, txt, key, cb)
	local r = row(pg, 34)
	rlabel(r, txt)
	local sw = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(36, 18),
		BackgroundColor3 = C.off, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = r })
	corner(sw, PILL)
	local kn = new("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C.white, BorderSizePixel = 0, Parent = sw })
	corner(kn, PILL)
	local function paint(t)
		local v = S[key]
		tw(sw, t, { BackgroundColor3 = v and accent or C.off })
		tw(kn, t, { Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) }, EZ.Back)
	end
	paint(0)
	hooks[#hooks + 1] = function() if S[key] then sw.BackgroundColor3 = accent end end
	on(sw.MouseButton1Click, function()
		S[key] = not S[key]
		paint(.2)
		notify(txt .. (S[key] and "  ON" or "  OFF"))
		if cb then cb(S[key]) end
		pv()
	end)
end

local function slider(pg, txt, key, mn, mx, fmt, cb, step)
	step = step or 1
	local r = row(pg, 46)
	rlabel(r, txt, -80)
	local val = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.fromOffset(70, 30),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, Parent = r })
	local track = new("TextButton", { Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 12), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = r })
	local bar = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.off, BorderSizePixel = 0, Parent = track })
	corner(bar, PILL)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
	A(fill, "BackgroundColor3"); corner(fill, PILL)
	local kn = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(1, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C.white, BorderSizePixel = 0, Parent = fill })
	corner(kn, PILL)
	local function set(v, silent)
		v = math.clamp(math.floor(v / step + .5) * step, mn, mx)
		S[key] = v
		fill.Size = UDim2.fromScale((v - mn) / (mx - mn), 1)
		val.Text = fmt(v)
		if not silent then
			if cb then cb(v) end
			pv()
		end
	end
	set(S[key], true)
	local dn = false
	local function upd(x) set(mn + (mx - mn) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end
	on(track.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dn = true
			upd(i.Position.X)
		end
	end)
	on(UIS.InputChanged, function(i)
		if dn and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end
	end)
	on(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dn = false end
	end)
end

local function seg(pg, txt, key, opts, cb)
	local r = row(pg, 58)
	rlabel(r, txt)
	local holderF = new("Frame", { Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 22), BackgroundTransparency = 1, Parent = r })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = holderF })
	local btns = {}
	local n = #opts
	local function paint()
		for _, b in ipairs(btns) do
			local sel = S[key] == b.Text
			tw(b, .15, { BackgroundColor3 = sel and accent or C.off, TextColor3 = sel and C.bg or C.dim })
		end
	end
	for _, o in ipairs(opts) do
		local b = new("TextButton", { Size = UDim2.new(1 / n, -4 * (n - 1) / n, 1, 0), BackgroundColor3 = C.off, BorderSizePixel = 0, Text = o,
			Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.dim, AutoButtonColor = false, Parent = holderF })
		corner(b, UDim.new(0, 5))
		btns[#btns + 1] = b
		on(b.MouseButton1Click, function()
			S[key] = o
			paint()
			if cb then cb(o) end
			pv()
		end)
	end
	paint()
	hooks[#hooks + 1] = paint
end

local function colors(pg, txt, key, rainbow, cb)
	local r = row(pg, 62)
	rlabel(r, txt)
	local f = new("Frame", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 22), BackgroundTransparency = 1, Parent = r })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = f })
	local sw = {}
	local function paint()
		for i, b in ipairs(sw) do
			local s = b:FindFirstChildOfClass("UIStroke")
			tw(s, .15, { Transparency = S[key] == i and 0 or 1 })
		end
	end
	for i = 1, rainbow and 10 or 9 do
		local b = new("TextButton", { Size = UDim2.fromOffset(22, 22), BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = f })
		corner(b, PILL)
		if i == 10 then
			b.BackgroundColor3 = C.white
			new("UIGradient", { Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)), ColorSequenceKeypoint.new(.25, Color3.fromRGB(255, 235, 70)),
				ColorSequenceKeypoint.new(.5, Color3.fromRGB(70, 255, 120)), ColorSequenceKeypoint.new(.75, Color3.fromRGB(70, 120, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)) }), Rotation = 45, Parent = b })
		else
			b.BackgroundColor3 = PAL[i]
		end
		local s = stroke(b, C.white, 2)
		s.Transparency = 1
		sw[i] = b
		on(b.MouseButton1Click, function()
			S[key] = i
			paint()
			if cb then cb(i) end
			pv()
		end)
	end
	paint()
end

local function button(pg, txt, cb)
	local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0, Text = txt, Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = C.bg, AutoButtonColor = false, Parent = pg })
	A(b, "BackgroundColor3"); corner(b, UDim.new(0, 7))
	on(b.MouseButton1Click, cb)
end
local function note(pg, txt, h)
	new("TextLabel", { Size = UDim2.new(1, 0, 0, h or 30), BackgroundTransparency = 1, Text = txt, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = pg })
end

-- ===== capabilities =====
local capfn
do
	local ok, f = pcall(function() return setfpscap end)
	if ok and type(f) == "function" then capfn = f end
end
local function applyFps()
	if capfn then pcall(capfn, S.fpsCustom and S.fps or 60) end
end

local fullbrightOrig
local function applyFullbright(v)
	if v then
		fullbrightOrig = fullbrightOrig or { Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows, Lighting.Ambient, Lighting.FogEnd }
		Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows = 2, 14, false
		Lighting.Ambient, Lighting.FogEnd = Color3.fromRGB(170, 170, 170), 1e6
	elseif fullbrightOrig then
		Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows, Lighting.Ambient, Lighting.FogEnd = table.unpack(fullbrightOrig)
		fullbrightOrig = nil
	end
end

local timeOrig
local function applyTime(v)
	if v then
		timeOrig = timeOrig or Lighting.ClockTime
		Lighting.ClockTime = S.timeVal
	elseif timeOrig then
		Lighting.ClockTime = timeOrig
		timeOrig = nil
	end
end

-- ===== страницы =====
local pc, pvis, pp, pset = page("Combat"), page("Visuals"), page("Player"), page("Settings")
for _, n in ipairs({ "Combat", "Visuals", "Player", "Settings" }) do addTab(n) end

section(pc, "Aimbot")
toggle(pc, "Enable aimbot", "aim")
seg(pc, "Activation", "aimAct", { "Hold RMB", "Always" })
seg(pc, "Mode", "aimMode", { "Smooth", "Snap" })
slider(pc, "Smoothness", "smooth", 1, 100, function(v) return v .. "%" end)
toggle(pc, "Show FOV circle", "fovShow")
slider(pc, "FOV radius", "fov", 30, 400, function(v) return v .. "px" end)
toggle(pc, "Visible check (no walls)", "wall")
toggle(pc, "Team check", "team")
note(pc, "Aim point is picked on the mannequin in the preview panel (click head / torso / legs).")

section(pvis, "ESP")
toggle(pvis, "Boxes", "box")
seg(pvis, "Box type", "boxType", { "2D", "3D" })
colors(pvis, "Box color", "boxCol", true)
toggle(pvis, "Names", "name")
toggle(pvis, "Distance", "dist")
toggle(pvis, "Health bar", "hp")
toggle(pvis, "Tracers", "tracer")
toggle(pvis, "Skeleton", "skel")
colors(pvis, "Skeleton color", "skelCol", true)
toggle(pvis, "Head dot", "headDot")
colors(pvis, "Head dot color", "headCol", true)
toggle(pvis, "Weapon name", "tool")
toggle(pvis, "Off-screen arrows", "arrows")
colors(pvis, "Arrow color", "arrowCol", true)
section(pvis, "Chams / Glow")
toggle(pvis, "Chams", "chams")
colors(pvis, "Chams color", "chamCol", true)
toggle(pvis, "Glow", "glow")
colors(pvis, "Glow color", "glowCol", true)
section(pvis, "Self")
toggle(pvis, "Trail", "trail")
colors(pvis, "Trail color", "trailCol", true)
slider(pvis, "Trail length", "trailLen", .3, 2, function(v) return string.format("%.1fs", v) end, nil, .1)
toggle(pvis, "Wings", "wings")
seg(pvis, "Wing type", "wingType", { "Angel", "Demon" })
toggle(pvis, "Aura particles", "aura")
colors(pvis, "Aura color", "auraCol", true)
toggle(pvis, "Self forcefield", "selfFF")
colors(pvis, "Forcefield color", "ffCol", true)
section(pvis, "World")
toggle(pvis, "Crosshair", "cross")
toggle(pvis, "Fullbright", "fullbright", applyFullbright)
toggle(pvis, "Time of day", "timeOn", applyTime)
slider(pvis, "Time", "timeVal", 0, 24, function(v) return string.format("%02d:%02d", math.floor(v), (v % 1) * 60) end,
	function() if S.timeOn then Lighting.ClockTime = S.timeVal end end, .5)

section(pp, "Movement")
toggle(pp, "Fly", "fly")
slider(pp, "Fly speed", "flySpeed", 10, 200, function(v) return v end)
toggle(pp, "Noclip", "noclip")
toggle(pp, "Walk speed", "speedOn")
slider(pp, "Speed value", "speed", 16, 120, function(v) return v end)
section(pp, "Performance")
toggle(pp, "FPS counter", "fpsShow")
toggle(pp, "Custom FPS", "fpsCustom", applyFps)
slider(pp, "FPS cap", "fps", 30, 999, function(v) return v end, applyFps)
if not capfn then note(pp, "setfpscap not found in this environment: the cap is shown on the counter but the engine limit can't be changed from a normal LocalScript.", 48) end

section(pset, "Menu")
colors(pset, "Menu color", "menuCol", false, function(i) setAccent(PAL[i]) end)
slider(pset, "Hue", "hue", 0, 1, function(v) return math.floor(v * 360) .. "°" end, function(v) setAccent(Color3.fromHSV(v, .72, 1)) end, .01)
slider(pset, "Transparency", "alpha", 0, .6, function(v) return math.floor(v * 100) .. "%" end, setAlpha, .01)
slider(pset, "Size", "size", .7, 1.3, function(v) return math.floor(v * 100) .. "%" end, fit, .05)
toggle(pset, "Notifications", "notif")
section(pset, "Misc")
local unload
button(pset, "Unload luxxs", function() unload() end)

-- ===== PREVIEW =====
local pvPanel = new("Frame", { Position = UDim2.fromOffset(520, 40), Size = UDim2.fromOffset(260, H - 40), BorderSizePixel = 0, BackgroundColor3 = C.panel, Parent = win })
BG(pvPanel, .1)
new("Frame", { Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.off, BackgroundTransparency = .5, BorderSizePixel = 0, Parent = pvPanel })
new("TextLabel", { Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(120, 18), BackgroundTransparency = 1, Text = "PREVIEW", Font = Enum.Font.GothamBold,
	TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = pvPanel })
local stage = new("Frame", { Position = UDim2.fromOffset(0, 32), Size = UDim2.fromOffset(260, 300), BackgroundTransparency = 1, ClipsDescendants = true, Parent = pvPanel })

local cx = 130
local function sf(props, z)
	props.BorderSizePixel = 0
	props.ZIndex = z or 1
	props.Parent = stage
	return new("Frame", props)
end
local function pLine(z) return sf({ AnchorPoint = Vector2.new(.5, .5), Visible = false, BackgroundColor3 = C.white }, z) end
local function ptxt(txt, z, size)
	return new("TextLabel", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(120, 14), BackgroundTransparency = 1, Text = txt, Font = Enum.Font.GothamBold,
		TextSize = size or 12, TextColor3 = C.white, TextStrokeTransparency = .5, Visible = false, ZIndex = z, Parent = stage })
end

local GRAY = Color3.fromRGB(150, 153, 160)
local trailSeg, wingF, glows, body, skelL, edge3 = {}, { {}, {} }, {}, {}, {}, {}
for i = 1, 18 do
	local f = sf({ AnchorPoint = Vector2.new(.5, .5), Visible = false, BackgroundColor3 = C.white }, 1)
	trailSeg[i] = f
end
for i = 1, 3 do
	local g = sf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(cx, 148), Size = UDim2.fromOffset(96 + i * 24, 214 + i * 24), Visible = false }, 2)
	corner(g, UDim.new(.5, 0))
	glows[i] = g
end
for side = 1, 2 do
	for i = 1, 5 do
		local f = sf({ AnchorPoint = Vector2.new(.5, .5), Visible = false }, 3)
		corner(f, UDim.new(.5, 0))
		wingF[side][i] = f
	end
end
local shadow = sf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(cx, 254), Size = UDim2.fromOffset(100, 10), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .6 }, 3)
corner(shadow, PILL)
local function part(x, y, w, h, r)
	local f = sf({ Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = GRAY }, 4)
	corner(f, UDim.new(0, r))
	local s = stroke(f, C.white, 2)
	s.Transparency = 1
	body[#body + 1] = { f, s }
end
part(cx - 16, 46, 32, 32, 16)
part(cx - 26, 84, 52, 76, 8)
part(cx - 43, 86, 13, 70, 6); part(cx + 30, 86, 13, 70, 6)
part(cx - 24, 164, 22, 86, 8); part(cx + 2, 164, 22, 86, 8)

for i = 1, 12 do skelL[i] = pLine(6) end
for i = 1, 4 do edge3[i] = pLine(7) end
local box2 = sf({ Position = UDim2.fromOffset(cx - 58, 40), Size = UDim2.fromOffset(116, 216), BackgroundTransparency = 1, Visible = false }, 7)
local box2s = stroke(box2, C.white, 1.5)
local boxFr = sf({ Position = UDim2.fromOffset(cx - 56, 50), Size = UDim2.fromOffset(100, 206), BackgroundTransparency = 1, Visible = false }, 7)
local boxFrS = stroke(boxFr, C.white, 1.5)
local boxBk = sf({ Position = UDim2.fromOffset(cx - 42, 40), Size = UDim2.fromOffset(100, 206), BackgroundTransparency = 1, Visible = false }, 7)
local boxBkS = stroke(boxBk, C.white, 1.5)
local tracerL = pLine(5)
local hpBg = sf({ Position = UDim2.fromOffset(cx - 66, 40), Size = UDim2.fromOffset(3, 216), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .4, Visible = false }, 7)
local hpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, .7), BorderSizePixel = 0, Parent = hpBg })
local nameL, distL = ptxt("Opponent", 8), ptxt("23m", 8, 11)
nameL.Position = UDim2.fromOffset(cx, 30)
distL.Position = UDim2.fromOffset(cx, 268)

-- aim zones
local ZONES = { Head = Vector2.new(cx, 62), Torso = Vector2.new(cx, 118), Legs = Vector2.new(cx, 208) }
local aimLbl = new("TextLabel", { Position = UDim2.fromOffset(0, 340), Size = UDim2.fromOffset(260, 18), BackgroundTransparency = 1, Text = "Aim point: Head",
	Font = Enum.Font.GothamBold, TextSize = 13, Parent = pvPanel })
A(aimLbl, "TextColor3")
new("TextLabel", { Position = UDim2.fromOffset(0, 360), Size = UDim2.fromOffset(260, 16), BackgroundTransparency = 1, Text = "click the mannequin to change",
	Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim, Parent = pvPanel })

local aura = sf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(ZONES.Head.X, ZONES.Head.Y), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = .8 }, 11)
A(aura, "BackgroundColor3"); corner(aura, PILL)
local ring = sf({ AnchorPoint = Vector2.new(.5, .5), Position = aura.Position, Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1 }, 12)
corner(ring, PILL)
local ringS = stroke(ring, accent, 1.5)
A(ringS, "Color")
local dot = sf({ AnchorPoint = Vector2.new(.5, .5), Position = aura.Position, Size = UDim2.fromOffset(10, 10) }, 13)
A(dot, "BackgroundColor3"); corner(dot, PILL)

local function setAim(n, silent)
	S.aimPart = n
	aimLbl.Text = "Aim point: " .. n
	local p = UDim2.fromOffset(ZONES[n].X, ZONES[n].Y)
	local t = silent and 0 or .55
	tw(dot, t, { Position = p }, EZ.Quint)
	tw(ring, t * 1.25, { Position = p }, EZ.Quint)
	tw(aura, t * 1.5, { Position = p }, EZ.Quint)
end
local function zone(n, x, y, w, h)
	local z = new("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 14, Parent = stage })
	corner(z, UDim.new(0, 8))
	local s = stroke(z, accent, 1)
	A(s, "Color")
	s.Transparency = 1
	on(z.MouseEnter, function() tw(s, .15, { Transparency = .55 }) end)
	on(z.MouseLeave, function() tw(s, .15, { Transparency = 1 }) end)
	on(z.MouseButton1Click, function() setAim(n) end)
end
zone("Head", cx - 22, 42, 44, 40)
zone("Torso", cx - 46, 84, 92, 78)
zone("Legs", cx - 26, 164, 52, 90)

local pvHead = sf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(cx, 62), Size = UDim2.fromOffset(7, 7), Visible = false }, 9)
corner(pvHead, PILL)
local toolL = ptxt("Knife", 8, 11)
toolL.Position = UDim2.fromOffset(cx, 282)
toolL.TextColor3 = Color3.fromRGB(255, 220, 120)
local arrowL = new("TextLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(34, 52), Size = UDim2.fromOffset(22, 22),
	BackgroundTransparency = 1, Text = "▲", Font = Enum.Font.GothamBold, TextSize = 20, Rotation = -40, Visible = false, ZIndex = 9, Parent = stage })
local sparks = {}
for i = 1, 10 do
	sparks[i] = sf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(4, 4), Visible = false }, 5)
	corner(sparks[i], PILL)
end

-- перья крыльев
local WA = { ang = { 16, 38, 60, 82, 104 }, len = { 92, 104, 96, 80, 60 } }
local WD = { ang = { 8, 34, 62, 92, 118 }, len = { 108, 118, 104, 84, 60 } }

local function renderPV()
	local t = os.clock()
	local bc, sc, cc, gc, tc = pal(S.boxCol), pal(S.skelCol), pal(S.chamCol), pal(S.glowCol), pal(S.trailCol)
	local pulse = .5 + .5 * math.sin(t * 3)

	-- тело
	for _, b in ipairs(body) do
		if S.chams then
			b[1].BackgroundColor3, b[1].BackgroundTransparency = cc, .25
		else
			b[1].BackgroundColor3, b[1].BackgroundTransparency = GRAY, 0
		end
		if S.glow then
			b[2].Color, b[2].Transparency = gc, .1 + .3 * pulse
		elseif S.selfFF then
			b[2].Color, b[2].Transparency = pal(S.ffCol), .3 + .3 * pulse
		else
			b[2].Transparency = 1
		end
	end
	for i, g in ipairs(glows) do
		g.Visible = S.glow
		g.BackgroundColor3 = gc
		g.BackgroundTransparency = .72 + i * .08 + .06 * pulse
	end

	-- box
	local b2, b3 = S.box and S.boxType == "2D", S.box and S.boxType == "3D"
	box2.Visible = b2; box2s.Color = bc
	boxFr.Visible, boxBk.Visible = b3, b3
	boxFrS.Color, boxBkS.Color = bc, bc
	for i = 1, 4 do
		if b3 then
			local fx, fy = cx - 56 + (i % 2) * 100, 50 + (i > 2 and 206 or 0)
			setLine(edge3[i], fx, fy, fx + 14, fy - 10, 1.5, bc)
		else
			edge3[i].Visible = false
		end
	end

	-- skeleton
	local J = {
		head = { cx, 62 }, neck = { cx, 84 }, pel = { cx, 160 }, sl = { cx - 30, 90 }, sr = { cx + 30, 90 },
		el = { cx - 36, 124 }, er = { cx + 36, 124 }, hl = { cx - 36, 154 }, hr = { cx + 36, 154 },
		pl = { cx - 12, 164 }, pr = { cx + 12, 164 }, kl = { cx - 12, 208 }, kr = { cx + 12, 208 }, fl = { cx - 12, 248 }, fr = { cx + 12, 248 },
	}
	local SK = { { "head", "neck" }, { "neck", "pel" }, { "neck", "sl" }, { "neck", "sr" }, { "sl", "hl" }, { "sr", "hr" },
		{ "pel", "pl" }, { "pel", "pr" }, { "pl", "kl" }, { "pr", "kr" }, { "kl", "fl" }, { "kr", "fr" } }
	for i, p in ipairs(SK) do
		if S.skel then
			local a, b = J[p[1]], J[p[2]]
			setLine(skelL[i], a[1], a[2], b[1], b[2], 1.5, sc)
		else
			skelL[i].Visible = false
		end
	end

	nameL.Visible, nameL.TextColor3 = S.name, C.white
	distL.Visible = S.dist
	hpBg.Visible = S.hp
	hpFill.BackgroundColor3 = Color3.fromHSV(.33 * .7, .9, 1)
	if S.tracer then setLine(tracerL, cx + 92, 300, cx, 254, 1.2, bc) else tracerL.Visible = false end

	-- trail
	local n = S.trail and math.clamp(math.floor(S.trailLen * 8) + 2, 3, 18) or 0
	for i, f in ipairs(trailSeg) do
		if i <= n then
			local k = (i - 1) / n
			f.Visible = true
			f.Size = UDim2.fromOffset(9, 96 * (1 - k * .85))
			f.Position = UDim2.fromOffset(cx - 34 - (i - 1) * 6.5, 150 + math.sin(t * 2 + i * .35) * 3)
			f.BackgroundTransparency = .15 + .85 * k
			f.BackgroundColor3 = S.trailCol == 10 and Color3.fromHSV((t * .3 + i * .045) % 1, .85, 1) or tc
		else
			f.Visible = false
		end
	end

	-- wings
	local demon = S.wingType == "Demon"
	local cfg = demon and WD or WA
	local flap = math.sin(t * 2.4) * 9
	for side = 1, 2 do
		local sg = side == 1 and -1 or 1
		for i, f in ipairs(wingF[side]) do
			if S.wings then
				local phi = math.rad(cfg.ang[i] + flap * (i / 5) - (demon and 0 or 0))
				local L = cfg.len[i]
				local bx, by = cx + sg * 10, 98
				f.Visible = true
				f.Size = UDim2.fromOffset(demon and (9 - i) or (15 - i * 1.5), L)
				f.Position = UDim2.fromOffset(bx + sg * math.sin(phi) * L / 2, by - math.cos(phi) * L / 2)
				f.Rotation = sg * math.deg(phi)
				f.BackgroundColor3 = demon and Color3.fromRGB(150 - i * 8, 14, 28) or Color3.fromRGB(255, 255, 255 - i * 6)
				f.BackgroundTransparency = demon and .05 or .12 + i * .03
			else
				f.Visible = false
			end
		end
	end

	pvHead.Visible = S.headDot
	pvHead.BackgroundColor3 = pal(S.headCol)
	toolL.Visible = S.tool
	arrowL.Visible = S.arrows
	arrowL.TextColor3 = pal(S.arrowCol)
	arrowL.TextTransparency = .1 + .4 * pulse
	for i, f in ipairs(sparks) do
		if S.aura then
			local ph = i * .63
			local k = (t * .35 + ph) % 1
			f.Visible = true
			f.Position = UDim2.fromOffset(cx + math.sin(t * 1.3 + ph * 5) * (40 + i * 3), 256 - k * 210)
			f.BackgroundColor3 = pal(S.auraCol)
			f.BackgroundTransparency = .1 + .9 * k
		else
			f.Visible = false
		end
	end

	ringS.Transparency = .1 + .5 * pulse
	ring.Size = UDim2.fromOffset(20 + 5 * pulse, 20 + 5 * pulse)
end
local pvAcc = 0
pv = renderPV

-- ===== открыть/закрыть =====
local opened, unlocked = false, false
local function setOpen(v)
	if v == opened then return end
	opened = v
	if v then
		holder.Visible = true
		animScale.Scale = .88
		win.GroupTransparency = 1
		tw(animScale, .4, { Scale = 1 }, EZ.Back)
		tw(win, .28, { GroupTransparency = 0 })
		renderPV()
	else
		tw(animScale, .25, { Scale = .9 }, EZ.Quad, ED.In)
		tw(win, .22, { GroupTransparency = 1 })
		task.delay(.26, function() if not opened then holder.Visible = false end end)
	end
end
on(closeBtn.MouseButton1Click, function() setOpen(false) end)
on(closeBtn.MouseEnter, function() tw(closeBtn, .15, { TextColor3 = C.red }) end)
on(closeBtn.MouseLeave, function() tw(closeBtn, .15, { TextColor3 = C.dim }) end)
on(UIS.InputBegan, function(i, gp)
	if not gp and unlocked and i.KeyCode == Enum.KeyCode.RightShift then setOpen(not opened) end
end)

-- иконка
local icon = new("TextButton", { Name = "Icon", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(54, 166), Size = UDim2.fromOffset(0, 0),
	BackgroundColor3 = C.bg, Text = "Lx", Font = Enum.Font.GothamBlack, TextSize = 20, AutoButtonColor = false, Visible = false, Parent = gui })
A(icon, "TextColor3"); corner(icon, PILL)
local iconStroke = stroke(icon, accent, 2.5)
A(iconStroke, "Color")
local iconGrad = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.white),
	ColorSequenceKeypoint.new(.5, Color3.fromRGB(40, 40, 40)), ColorSequenceKeypoint.new(1, C.white) }), Parent = iconStroke })
local iconGlow = new("UIStroke", { Thickness = 6, Transparency = .8, Parent = icon })
A(iconGlow, "Color")
drag(icon, icon, function() setOpen(not opened) end)
on(icon.MouseEnter, function() tw(icon, .2, { Size = UDim2.fromOffset(58, 58) }, EZ.Back) end)
on(icon.MouseLeave, function() tw(icon, .2, { Size = UDim2.fromOffset(52, 52) }) end)

-- ===== окно ключа =====
local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui })
tw(dim, .5, { BackgroundTransparency = .4 })
local kcard = new("CanvasGroup", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(340, 226),
	BackgroundColor3 = C.bg, GroupTransparency = 1, Parent = gui })
corner(kcard, UDim.new(0, 14))
local kStroke = stroke(kcard, accent, 2)
A(kStroke, "Color")
local kGrad = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.white),
	ColorSequenceKeypoint.new(.5, Color3.fromRGB(50, 50, 50)), ColorSequenceKeypoint.new(1, C.white) }), Parent = kStroke })
local kscale = new("UIScale", { Scale = .9, Parent = kcard })
tw(kcard, .4, { GroupTransparency = 0 }); tw(kscale, .5, { Scale = 1 }, EZ.Back)
new("TextLabel", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = 'lux<font color="rgb(70,255,120)">xs</font>',
	RichText = true, Font = Enum.Font.GothamBlack, TextSize = 38, TextColor3 = C.text, Parent = kcard })
new("TextLabel", { Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "enter your key to continue",
	Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.dim, Parent = kcard })
local kbox = new("TextBox", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 96), Size = UDim2.fromOffset(280, 38), BackgroundColor3 = C.row,
	Text = "", PlaceholderText = "key", PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 14, ClearTextOnFocus = false, Parent = kcard })
corner(kbox, UDim.new(0, 8))
local kstroke = stroke(kbox, C.off, 1)
on(kbox.Focused, function() tw(kstroke, .2, { Color = accent }) end)
on(kbox.FocusLost, function() tw(kstroke, .2, { Color = C.off }) end)
local kbtn = new("TextButton", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 144), Size = UDim2.fromOffset(280, 38), BorderSizePixel = 0,
	Text = "Verify", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.bg, AutoButtonColor = false, Parent = kcard })
A(kbtn, "BackgroundColor3"); corner(kbtn, UDim.new(0, 8))
local kbar = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(0, 0, 0, 3), BorderSizePixel = 0, Parent = kcard })
A(kbar, "BackgroundColor3")
local kmsg = new("TextLabel", { Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamMedium,
	TextSize = 12, TextColor3 = C.red, Parent = kcard })

local function ripple(delay, size)
	task.delay(delay, function()
		local r = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Parent = gui })
		corner(r, PILL)
		local s = stroke(r, accent, 3)
		tw(r, 1, { Size = UDim2.fromOffset(size, size) }, EZ.Quint)
		tw(s, 1, { Transparency = 1, Thickness = 1 })
		task.delay(1.1, function() r:Destroy() end)
	end)
end

local function burst()
	for i = 1, 30 do
		local a = math.rad(i / 30 * 360 + math.random(-8, 8))
		local d = math.random(140, 380)
		local f = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), BorderSizePixel = 0,
			Size = UDim2.fromOffset(math.random(3, 7), math.random(3, 7)), BackgroundColor3 = accent, Parent = gui })
		corner(f, PILL)
		tw(f, math.random(70, 110) / 100, { Position = UDim2.new(.5, math.cos(a) * d, .5, math.sin(a) * d),
			BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1) }, EZ.Quint)
		task.delay(1.2, function() f:Destroy() end)
	end
end

local function success()
	kbtn.Text = "Access granted"
	tw(kbar, .7, { Size = UDim2.new(1, 0, 0, 3) }, EZ.Quart)
	task.wait(.8)
	tw(kcard, .4, { GroupTransparency = 1 })
	tw(kscale, .4, { Scale = .8 }, EZ.Back, ED.In)
	ripple(0, 900); ripple(.18, 1300); burst()
	task.wait(.35)
	kcard.Visible = false

	local word, widths = { "l", "u", "x", "x", "s" }, { 22, 44, 40, 40, 38 }
	local total = -6
	for _, w in ipairs(widths) do total += w + 6 end
	local wrap = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(total, 80), BackgroundTransparency = 1, Parent = gui })
	local x, letters = 0, {}
	for i, ch in ipairs(word) do
		local l = new("TextLabel", { Position = UDim2.fromOffset(x, 34), Size = UDim2.fromOffset(widths[i], 70), BackgroundTransparency = 1, Text = ch,
			Font = Enum.Font.GothamBlack, TextSize = 66, TextColor3 = i > 2 and accent or C.text, TextTransparency = 1, Parent = wrap })
		local st = new("UIStroke", { Color = accent, Thickness = 1.5, Transparency = 1, Parent = l })
		letters[i] = { l, st, x }
		x += widths[i] + 6
	end
	local line = new("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 1, 18), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0, Parent = wrap })
	A(line, "BackgroundColor3"); corner(line, PILL)
	for i, d in ipairs(letters) do
		task.delay((i - 1) * .08, function()
			tw(d[1], .5, { Position = UDim2.fromOffset(d[3], 0), TextTransparency = 0 }, EZ.Back)
			tw(d[2], .6, { Transparency = .55 })
		end)
	end
	tw(line, .7, { Size = UDim2.fromOffset(total, 2) }, EZ.Quart)
	task.wait(1.5)
	for i, d in ipairs(letters) do
		task.delay((i - 1) * .05, function()
			tw(d[1], .4, { Position = UDim2.fromOffset(d[3], -26), TextTransparency = 1 }, EZ.Quad, ED.In)
			tw(d[2], .3, { Transparency = 1 })
		end)
	end
	tw(line, .4, { Size = UDim2.fromOffset(0, 2) })
	tw(dim, .6, { BackgroundTransparency = 1 })
	task.wait(.7)
	wrap:Destroy(); dim:Destroy(); kcard:Destroy()

	unlocked = true
	local home = icon.Position
	icon.Position = UDim2.fromScale(.5, .5)
	icon.Visible = true
	tw(icon, .5, { Size = UDim2.fromOffset(64, 64) }, EZ.Back)
	task.wait(.45)
	tw(icon, .8, { Position = home, Size = UDim2.fromOffset(52, 52) }, EZ.Quint)
	task.wait(.35)
	setOpen(true)
end

local busy = false
local function verify()
	if busy then return end
	local k = (kbox.Text:lower():gsub("%s", ""))
	if k == KEY then
		busy = true
		kmsg.Text = ""
		task.spawn(success)
	else
		kmsg.Text = "invalid key"
		tw(kstroke, .1, { Color = C.red })
		task.delay(.6, function() if kbox.Parent then tw(kstroke, .3, { Color = C.off }) end end)
		task.spawn(function()
			local base = kcard.Position
			for _, dx in ipairs({ 10, -10, 7, -7, 3, 0 }) do
				tw(kcard, .04, { Position = base + UDim2.fromOffset(dx, 0) })
				task.wait(.045)
			end
		end)
	end
end
on(kbtn.MouseButton1Click, verify)
on(kbox.FocusLost, function(enter) if enter then verify() end end)

-- ===== FPS / crosshair / fov-circle =====
local fpsF = new("Frame", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(150, 26), BackgroundColor3 = C.bg, BackgroundTransparency = .25, Visible = false, Parent = gui })
corner(fpsF, UDim.new(0, 7)); A(stroke(fpsF, accent, 1), "Color")
local fpsT = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "FPS", Font = Enum.Font.GothamBold, TextSize = 12, Parent = fpsF })
A(fpsT, "TextColor3")
drag(fpsF, fpsF)

local fovC = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), BackgroundTransparency = 1, Visible = false, Parent = espGui })
corner(fovC, PILL); A(stroke(fovC, accent, 1.5), "Color")

local cross = {}
for i = 1, 5 do
	local f = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false, Parent = espGui })
	A(f, "BackgroundColor3")
	cross[i] = f
end
local XO = { { 0, -9, 2, 8 }, { 0, 9, 2, 8 }, { -9, 0, 8, 2 }, { 9, 0, 8, 2 }, { 0, 0, 2, 2 } }
local function crossStep(cam)
	local c = cam.ViewportSize / 2
	for i, f in ipairs(cross) do
		f.Visible = S.cross
		if S.cross then
			local d = XO[i]
			f.Position = UDim2.fromOffset(c.X + d[1], c.Y + d[2])
			f.Size = UDim2.fromOffset(d[3], d[4])
		end
	end
end

-- ===== ESP =====
local objs, hls = {}, {}
local UP_T, UP_B = Vector3.new(0, 2.7, 0), Vector3.new(0, -3.1, 0)
local CORN = {}
for xi, x in ipairs({ -1.9, 1.9 }) do
	for yi, y in ipairs({ -3.1, 2.7 }) do
		for zi, z in ipairs({ -1.1, 1.1 }) do
			CORN[(xi - 1) * 4 + (yi - 1) * 2 + zi] = Vector3.new(x, y, z)
		end
	end
end
local EDGES = { { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 }, { 1, 3 }, { 2, 4 }, { 5, 7 }, { 6, 8 }, { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 } }
local R15 = { { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" }, { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" }, { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" } }
local R6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }

local function eline()
	return new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false, Parent = espGui })
end
local function etext(sz, anchorY)
	return new("TextLabel", { AnchorPoint = Vector2.new(.5, anchorY), Size = UDim2.fromOffset(160, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
		TextSize = sz, TextColor3 = C.white, TextStrokeTransparency = .35, Visible = false, Parent = espGui })
end
local function mkObj()
	local o = { on = false, e3 = {}, sk = {} }
	o.box = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = espGui })
	o.bs = stroke(o.box, C.white, 1.5)
	for i = 1, 12 do o.e3[i] = eline() end
	for i = 1, 14 do o.sk[i] = eline() end
	o.name, o.dist = etext(13, 1), etext(11, 0)
	o.hpBg = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .4, BorderSizePixel = 0, Visible = false, Parent = espGui })
	o.hp = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = o.hpBg })
	o.tr = eline()
	return o
end
local function hideObj(o)
	if not o.on then return end
	o.on = false
	o.box.Visible, o.name.Visible, o.dist.Visible, o.hpBg.Visible, o.tr.Visible = false, false, false, false, false
	for _, l in ipairs(o.e3) do l.Visible = false end
	for _, l in ipairs(o.sk) do l.Visible = false end
end
local function killObj(p)
	local o = objs[p]
	if o then
		for _, v in pairs(o) do
			if typeof(v) == "Instance" then v:Destroy() end
		end
		for _, l in ipairs(o.e3) do l:Destroy() end
		for _, l in ipairs(o.sk) do l:Destroy() end
		objs[p] = nil
	end
	if hls[p] then hls[p]:Destroy(); hls[p] = nil end
end
on(Players.PlayerRemoving, killObj)

local function enemy(p)
	if p == lp then return false end
	if S.team and p.Team and p.Team == lp.Team then return false end
	return true
end

local function drawObj(o, p, ch, hrp, hum, cam, bc, sc, vp)
	local pos = hrp.Position
	local top, bot = cam:WorldToViewportPoint(pos + UP_T), cam:WorldToViewportPoint(pos + UP_B)
	if top.Z <= 0 or bot.Z <= 0 then hideObj(o) return end
	o.on = true
	local h = bot.Y - top.Y
	local w = h * .55
	local mx = (top.X + bot.X) / 2

	if S.box and S.boxType == "2D" then
		o.box.Visible = true
		o.box.Position = UDim2.fromOffset(mx - w / 2, top.Y)
		o.box.Size = UDim2.fromOffset(w, h)
		o.bs.Color = bc
	else
		o.box.Visible = false
	end

	local show3 = false
	if S.box and S.boxType == "3D" then
		local _, yaw = hrp.CFrame:ToOrientation()
		local base = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
		local pts, okp = {}, true
		for i = 1, 8 do
			local v = cam:WorldToViewportPoint(base * CORN[i])
			if v.Z <= 0 then okp = false break end
			pts[i] = v
		end
		if okp then
			show3 = true
			for i, e in ipairs(EDGES) do
				local a, b = pts[e[1]], pts[e[2]]
				setLine(o.e3[i], a.X, a.Y, b.X, b.Y, 1.5, bc)
			end
		end
	end
	if not show3 then for _, l in ipairs(o.e3) do l.Visible = false end end

	if S.name then
		o.name.Visible = true
		o.name.Text = p.DisplayName
		o.name.Position = UDim2.fromOffset(mx, top.Y - 3)
	else
		o.name.Visible = false
	end
	if S.dist then
		o.dist.Visible = true
		o.dist.Text = math.floor((cam.CFrame.Position - pos).Magnitude) .. "m"
		o.dist.Position = UDim2.fromOffset(mx, bot.Y + 2)
	else
		o.dist.Visible = false
	end
	if S.hp then
		local f = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		o.hpBg.Visible = true
		o.hpBg.Position = UDim2.fromOffset(mx - w / 2 - 7, top.Y)
		o.hpBg.Size = UDim2.fromOffset(3, h)
		o.hp.Size = UDim2.fromScale(1, f)
		o.hp.BackgroundColor3 = Color3.fromHSV(.33 * f, .9, 1)
	else
		o.hpBg.Visible = false
	end
	if S.tracer then
		setLine(o.tr, vp.X / 2, vp.Y, mx, bot.Y, 1.2, bc)
	else
		o.tr.Visible = false
	end
	if S.skel then
		local list = ch:FindFirstChild("UpperTorso") and R15 or R6
		for i = 1, 14 do
			local pr, l = list[i], o.sk[i]
			if pr then
				local a, b = ch:FindFirstChild(pr[1]), ch:FindFirstChild(pr[2])
				if a and b then
					local pa, pb = cam:WorldToViewportPoint(a.Position), cam:WorldToViewportPoint(b.Position)
					if pa.Z > 0 and pb.Z > 0 then
						setLine(l, pa.X, pa.Y, pb.X, pb.Y, 1.5, sc)
					else
						l.Visible = false
					end
				else
					l.Visible = false
				end
			else
				l.Visible = false
			end
		end
	else
		for _, l in ipairs(o.sk) do l.Visible = false end
	end
end

local function espStep(cam)
	local t = os.clock()
	local anyDraw = S.box or S.name or S.dist or S.hp or S.skel or S.tracer
	local bc, sc, cc, gc = pal(S.boxCol), pal(S.skelCol), pal(S.chamCol), pal(S.glowCol)
	local vp = cam.ViewportSize
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local ch = p.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local alive = hrp and hum and hum.Health > 0 and enemy(p)

			-- chams + glow
			local hl = hls[p]
			if alive and (S.chams or S.glow) then
				if not hl or hl.Parent ~= ch then
					if hl then hl:Destroy() end
					hl = new("Highlight", { Adornee = ch, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = ch })
					hls[p] = hl
				end
				hl.Enabled = true
				hl.FillColor = cc
				hl.FillTransparency = S.chams and .45 or 1
				hl.OutlineColor = S.glow and gc or cc
				hl.OutlineTransparency = S.glow and (.05 + .3 * (.5 + .5 * math.sin(t * 3))) or (S.chams and .2 or 1)
				local pl = hrp:FindFirstChild("LxGlow")
				if S.glow then
					if not pl then pl = new("PointLight", { Name = "LxGlow", Range = 14, Brightness = 1.6, Parent = hrp }) end
					pl.Color = gc
				elseif pl then
					pl:Destroy()
				end
			elseif hl then
				hl.Enabled = false
				local pl = hrp and hrp:FindFirstChild("LxGlow")
				if pl then pl:Destroy() end
			end

			-- 2D overlay
			local o = objs[p]
			if alive and anyDraw then
				if not o then o = mkObj(); objs[p] = o end
				drawObj(o, p, ch, hrp, hum, cam, bc, sc, vp)
			elseif o then
				hideObj(o)
			end
		end
	end
end

-- ===== aimbot =====
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local function aimPartOf(ch)
	local m = S.aimPart
	local p
	if m == "Head" then
		p = ch:FindFirstChild("Head")
	elseif m == "Torso" then
		p = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	else
		p = ch:FindFirstChild("LeftLowerLeg") or ch:FindFirstChild("Left Leg")
	end
	return p or ch:FindFirstChild("HumanoidRootPart")
end
local function aimStep(cam, dt)
	local c = cam.ViewportSize / 2
	fovC.Visible = S.aim and S.fovShow
	if fovC.Visible then
		fovC.Size = UDim2.fromOffset(S.fov * 2, S.fov * 2)
		fovC.Position = UDim2.fromOffset(c.X, c.Y)
	end
	if not S.aim then return end
	if S.aimAct == "Hold RMB" and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
	local filt = { cam }
	if lp.Character then filt[2] = lp.Character end
	rp.FilterDescendantsInstances = filt
	local best, bestD, bestPos = nil, S.fov, nil
	for _, p in ipairs(Players:GetPlayers()) do
		if enemy(p) and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local part = aimPartOf(p.Character)
			if hum and hum.Health > 0 and part then
				local sp = cam:WorldToViewportPoint(part.Position)
				if sp.Z > 0 then
					local d = (Vector2.new(sp.X, sp.Y) - c).Magnitude
					if d < bestD then
						local clear = true
						if S.wall then
							local origin = cam.CFrame.Position
							local hit = workspace:Raycast(origin, part.Position - origin, rp)
							clear = hit == nil or hit.Instance:IsDescendantOf(p.Character)
						end
						if clear then best, bestD, bestPos = p, d, part.Position end
					end
				end
			end
		end
	end
	if bestPos then
		local goal = CFrame.lookAt(cam.CFrame.Position, bestPos)
		local a = 1
		if S.aimMode == "Smooth" then
			a = 1 - math.exp(-(1.5 + 26 * (1 - S.smooth / 100)) * dt)
		end
		cam.CFrame = cam.CFrame:Lerp(goal, a)
	end
end

-- ===== extras: head dot / weapon / off-screen arrows =====
local ex = {}
local function mkEx()
	local e = {}
	e.dot = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false, Parent = espGui })
	corner(e.dot, PILL)
	stroke(e.dot, Color3.new(0, 0, 0), 1)
	e.tool = etext(11, 0)
	e.tool.TextColor3 = Color3.fromRGB(255, 220, 120)
	e.arrow = new("TextLabel", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "▲",
		Font = Enum.Font.GothamBold, TextSize = 22, Visible = false, Parent = espGui })
	new("UIStroke", { Thickness = 1, Transparency = .4, Parent = e.arrow })
	return e
end
local function hideEx(e) e.dot.Visible, e.tool.Visible, e.arrow.Visible = false, false, false end
on(Players.PlayerRemoving, function(p)
	local e = ex[p]
	if e then
		e.dot:Destroy(); e.tool:Destroy(); e.arrow:Destroy()
		ex[p] = nil
	end
end)

local function extraStep(cam)
	local any = S.headDot or S.tool or S.arrows
	local vp = cam.ViewportSize
	local hc, ac = pal(S.headCol), pal(S.arrowCol)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local ch = p.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local head = ch and ch:FindFirstChild("Head")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local e = ex[p]
			if any and hrp and head and hum and hum.Health > 0 and enemy(p) then
				if not e then e = mkEx(); ex[p] = e end
				local hp = cam:WorldToViewportPoint(head.Position)
				local bot = cam:WorldToViewportPoint(hrp.Position + UP_B)
				local onscr = hp.Z > 0 and hp.X > 0 and hp.X < vp.X and hp.Y > 0 and hp.Y < vp.Y

				if S.headDot and hp.Z > 0 and bot.Z > 0 then
					local sz = math.clamp(math.abs(bot.Y - hp.Y) * .11, 4, 18)
					e.dot.Visible = true
					e.dot.Size = UDim2.fromOffset(sz, sz)
					e.dot.Position = UDim2.fromOffset(hp.X, hp.Y)
					e.dot.BackgroundColor3 = hc
				else
					e.dot.Visible = false
				end

				local tl = S.tool and bot.Z > 0 and ch:FindFirstChildOfClass("Tool")
				if tl then
					e.tool.Visible = true
					e.tool.Text = tl.Name
					e.tool.Position = UDim2.fromOffset(hp.X, bot.Y + (S.dist and 15 or 3))
				else
					e.tool.Visible = false
				end

				if S.arrows and not onscr then
					local rel = cam.CFrame:PointToObjectSpace(hrp.Position)
					local dir = Vector2.new(rel.X, -rel.Y)
					if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
					dir = dir.Unit
					local r = math.min(vp.X, vp.Y) * .38
					e.arrow.Visible = true
					e.arrow.Position = UDim2.fromOffset(vp.X / 2 + dir.X * r, vp.Y / 2 + dir.Y * r)
					e.arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
					e.arrow.TextColor3 = ac
				else
					e.arrow.Visible = false
				end
			elseif e then
				hideEx(e)
			end
		end
	end
end

-- ===== анимации интерфейса =====
local dots, rnd = {}, Random.new(7)
for i = 1, 16 do
	local f = new("Frame", { Size = UDim2.fromOffset(rnd:NextInteger(2, 4), rnd:NextInteger(2, 4)), BorderSizePixel = 0, ZIndex = 0, Parent = content })
	A(f, "BackgroundColor3")
	corner(f, PILL)
	f.BackgroundTransparency = .55 + rnd:NextNumber() * .35
	dots[i] = { f, rnd:NextNumber(), rnd:NextNumber(), .01 + rnd:NextNumber() * .02, (rnd:NextNumber() - .5) * .02 }
end
local function animStep(t)
	if opened then
		winGrad.Rotation = (t * 45) % 360
		for _, d in ipairs(dots) do
			d[1].Position = UDim2.fromScale((d[2] + t * d[5]) % 1, (d[3] - t * d[4]) % 1)
		end
	end
	iconGrad.Rotation = (t * 120) % 360
	iconGlow.Transparency = .75 + .15 * math.sin(t * 2.5)
	if kcard.Parent then kGrad.Rotation = (t * 90) % 360 end
end

-- ===== игрок: fly / noclip / speed / trail / wings =====
local flying, speedWas, touched = false, false, {}
local trail, trailOwner, wingWelds, wingKey, wingType = nil, nil, {}, nil, nil

local function clearWings()
	for _, w in ipairs(wingWelds) do
		if w.f then w.f:Destroy() end
	end
	wingWelds, wingKey = {}, nil
end
local function buildWings(ch)
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	if not torso then return end
	clearWings()
	local demon = S.wingType == "Demon"
	local lens = demon and { 4.6, 4.2, 3.6, 2.9, 2.1 } or { 3.6, 4, 3.6, 3, 2.2 }
	local angs = demon and { 8, 34, 62, 92, 118 } or { 14, 34, 54, 76, 98 }
	for side = -1, 1, 2 do
		for i = 1, 5 do
			local L = lens[i]
			local f = new("Part", { Size = Vector3.new(demon and .22 or .5 - i * .04, L, .07), CanCollide = false, CanQuery = false, CanTouch = false,
				Massless = true, Material = demon and Enum.Material.SmoothPlastic or Enum.Material.Neon,
				Color = demon and Color3.fromRGB(135 - i * 10, 10, 24) or Color3.fromRGB(255, 255, 250 - i * 6), Parent = ch })
			local wd = new("Weld", { Part0 = torso, Part1 = f, C1 = CFrame.new(0, -L / 2, 0), Parent = f })
			wingWelds[#wingWelds + 1] = { f = f, w = wd, side = side, ang = angs[i], i = i }
		end
	end
	wingKey = ch
end

local function wingStep(t)
	local ch = lp.Character
	if S.wings and ch then
		if wingKey ~= ch or wingType ~= S.wingType or #wingWelds == 0 or wingWelds[1].f.Parent == nil then
			buildWings(ch)
			wingType = S.wingType
		end
		local flap = math.sin(t * 2.4) * 16
		for _, d in ipairs(wingWelds) do
			local sg = d.side
			d.w.C0 = CFrame.new(sg * .35, .45, .55) * CFrame.Angles(0, sg * math.rad(flap * (.5 + d.i * .1)), 0)
				* CFrame.Angles(math.rad(22), 0, -sg * math.rad(d.ang))
		end
	elseif #wingWelds > 0 then
		clearWings()
	end
end

local auraEm, ffStore = nil, {}
local function selfFx(t, ch)
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if S.aura and hrp then
		if not auraEm or auraEm.Parent ~= hrp then
			if auraEm then auraEm:Destroy() end
			auraEm = new("ParticleEmitter", { Rate = 45, Lifetime = NumberRange.new(.8, 1.4), Speed = NumberRange.new(.5, 2),
				SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Acceleration = Vector3.new(0, 2, 0), RotSpeed = NumberRange.new(-90, 90),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .55), NumberSequenceKeypoint.new(1, 0) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(1, 1) }), Parent = hrp })
		end
		auraEm.Enabled = true
		auraEm.Color = ColorSequence.new(pal(S.auraCol))
	elseif auraEm then
		auraEm.Enabled = false
	end

	if S.selfFF and ch then
		local c = pal(S.ffCol)
		for _, p in ipairs(ch:GetChildren()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and not p.Massless then
				if not ffStore[p] then ffStore[p] = { p.Material, p.Color } end
				p.Material = Enum.Material.ForceField
				p.Color = c
			end
		end
	elseif next(ffStore) then
		for p, o in pairs(ffStore) do
			if p.Parent then p.Material, p.Color = o[1], o[2] end
		end
		ffStore = {}
	end

	if S.timeOn then Lighting.ClockTime = S.timeVal end
end
local function trailStep(t, ch)
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if S.trail and hrp then
		if not trail or trail.Parent == nil or trailOwner ~= ch then
			if trail then
				local a0, a1 = trail.Attachment0, trail.Attachment1
				if a0 then a0:Destroy() end
				if a1 then a1:Destroy() end
				trail:Destroy()
			end
			local a0 = new("Attachment", { Position = Vector3.new(0, .9, 0), Parent = hrp })
			local a1 = new("Attachment", { Position = Vector3.new(0, -.9, 0), Parent = hrp })
			trail = new("Trail", { Attachment0 = a0, Attachment1 = a1, LightEmission = 1, FaceCamera = true, MinLength = .05,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .05), NumberSequenceKeypoint.new(1, 1) }),
				WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, .1) }), Parent = hrp })
			trailOwner = ch
		end
		trail.Enabled = true
		trail.Lifetime = S.trailLen
		if S.trailCol == 10 then
			local k = {}
			for i = 0, 5 do k[#k + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV((t * .3 + i * .12) % 1, .85, 1)) end
			trail.Color = ColorSequence.new(k)
		else
			trail.Color = ColorSequence.new(PAL[S.trailCol])
		end
	elseif trail and trail.Parent then
		trail.Enabled = false
	end
end

on(RS.Stepped, function()
	local ch = lp.Character
	if S.noclip and ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide and p.Name ~= "LxWing" and not p.Massless then
				touched[p] = true
				p.CanCollide = false
			end
		end
	elseif next(touched) then
		for p in pairs(touched) do
			if p.Parent and (p.Name == "HumanoidRootPart" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso") then p.CanCollide = true end
		end
		touched = {}
	end
end)

on(RS.Heartbeat, function()
	local t = os.clock()
	local ch = lp.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	trailStep(t, ch)
	selfFx(t, ch)
	wingStep(t)
	if not (hrp and hum) then return end
	local cam = workspace.CurrentCamera
	if S.fly then
		flying = true
		hum.PlatformStand = true
		local cf, d = cam.CFrame, Vector3.zero
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.W) then d += cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then d += cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.yAxis end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d -= Vector3.yAxis end
		end
		hrp.AssemblyLinearVelocity = d.Magnitude > 0 and d.Unit * S.flySpeed or Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if look.Magnitude > .01 then hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look) end
	elseif flying then
		flying = false
		hum.PlatformStand = false
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
	if S.speedOn then
		hum.WalkSpeed = S.speed
		speedWas = true
	elseif speedWas then
		speedWas = false
		hum.WalkSpeed = 16
	end
end)

-- ===== главный цикл =====
local fAcc, fCnt, fps = 0, 0, 60
BG(fpsF, .25)
on(RS.RenderStepped, function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	fAcc += dt; fCnt += 1
	if fAcc >= .25 then
		fps = math.floor(fCnt / fAcc + .5)
		fAcc, fCnt = 0, 0
		local txt = "FPS " .. fps
		if S.fpsCustom then txt ..= "  |  cap " .. S.fps .. (capfn and "" or "*") end
		fpsT.Text = txt
	end
	fpsF.Visible = S.fpsShow and unlocked
	espStep(cam)
	extraStep(cam)
	crossStep(cam)
	animStep(os.clock())
	if opened then
		pvAcc += dt
		if pvAcc > 1 / 30 then pvAcc = 0; renderPV() end
	end
end)
pcall(function()
	RS:UnbindFromRenderStep("LuxxsAim")
end)
RS:BindToRenderStep("LuxxsAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local cam = workspace.CurrentCamera
	if cam then aimStep(cam, dt) end
end)

-- ===== unload =====
unload = function()
	if dead then return end
	dead = true
	S.fly, S.noclip, S.speedOn, S.wings, S.trail = false, false, false, false, false
	applyFullbright(false)
	pcall(function() RS:UnbindFromRenderStep("LuxxsAim") end)
	for _, c in ipairs(conns) do c:Disconnect() end
	clearWings()
	if auraEm then auraEm:Destroy() end
	for p, o in pairs(ffStore) do
		if p.Parent then p.Material, p.Color = o[1], o[2] end
	end
	applyTime(false)
	for _, e in pairs(ex) do
		e.dot:Destroy(); e.tool:Destroy(); e.arrow:Destroy()
	end
	if trail then
		if trail.Attachment0 then trail.Attachment0:Destroy() end
		if trail.Attachment1 then trail.Attachment1:Destroy() end
		trail:Destroy()
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if hls[p] then hls[p]:Destroy() end
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local pl = hrp and hrp:FindFirstChild("LxGlow")
		if pl then pl:Destroy() end
	end
	local ch = lp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false; hum.WalkSpeed = 16 end
	gui:Destroy(); espGui:Destroy()
end

-- старт
fit()
selectTab("Combat")
setAim("Head", true)
renderPV()
