--[[ luxxs v5.1
     LocalScript -> StarterPlayer > StarterPlayerScripts
     RightShift или иконка Lx открывает меню ]]

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

-- ===================== helpers =====================
local conns, dead = {}, false
local function on(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end
local EZ, ED = Enum.EasingStyle, Enum.EasingDirection
local function tw(o, t, p, st, dr)
	local x = TS:Create(o, TweenInfo.new(t, st or EZ.Quint, dr or ED.Out), p)
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
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = o }) end
local function stroke(o, col, th, tr)
	return new("UIStroke", { Color = col, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end
local function setLine(f, x1, y1, x2, y2, th, col)
	local dx, dy = x2 - x1, y2 - y1
	f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), th)
	f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
	f.Rotation = math.deg(math.atan2(dy, dx))
	if col then f.BackgroundColor3 = col end
	f.Visible = true
end

local C = {
	bg = Color3.fromRGB(10, 12, 11), panel = Color3.fromRGB(15, 18, 16), row = Color3.fromRGB(24, 29, 26),
	line = Color3.fromRGB(38, 46, 41), off = Color3.fromRGB(56, 64, 60), text = Color3.fromRGB(232, 238, 233),
	dim = Color3.fromRGB(120, 134, 126), red = Color3.fromRGB(255, 84, 84),
}
local WHITE, GRAY = Color3.new(1, 1, 1), Color3.fromRGB(190, 192, 200)
local F_HEAD, F_BODY, F_MONO, F_SEC = Enum.Font.Michroma, Enum.Font.SourceSansSemibold, Enum.Font.RobotoMono, Enum.Font.Oswald

local PAL = {
	Color3.fromRGB(86, 255, 126), Color3.fromRGB(0, 220, 255), Color3.fromRGB(80, 120, 255), Color3.fromRGB(170, 95, 255),
	Color3.fromRGB(255, 95, 200), Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 232, 70),
	Color3.fromRGB(255, 255, 255),
}
local function pal(i, off)
	if i == 10 then return Color3.fromHSV((os.clock() * 0.22 + (off or 0)) % 1, 0.85, 1) end
	return PAL[i] or PAL[1]
end

-- ===================== state =====================
local F, SET, DEF = {}, {}, {}
local function reg(k, d, fn)
	F[k], DEF[k], SET[k] = d, d, fn
end

local accent = PAL[1]
local accReg, bgReg, hooks = {}, {}, {}
local function A(o, p)
	accReg[#accReg + 1] = { o, p }
	o[p] = accent
	return o
end
local function BG(o, base)
	bgReg[#bgReg + 1] = { o, base }
	o.BackgroundTransparency = math.clamp(base + (F.alpha or 0), 0, 1)
	return o
end
local function setAccent(c)
	accent = c
	for _, r in ipairs(accReg) do
		if r[1].Parent then r[1][r[2]] = c end
	end
	for _, h in ipairs(hooks) do h() end
end
local function applyAlpha()
	for _, r in ipairs(bgReg) do
		if r[1].Parent then r[1].BackgroundTransparency = math.clamp(r[2] + (F.alpha or 0), 0, 1) end
	end
end
local function ticks(p, w, h, len, z)
	for _, c in ipairs({ { 0, 0, 1, 1 }, { w, 0, -1, 1 }, { 0, h, 1, -1 }, { w, h, -1, -1 } }) do
		local x, y, dx, dy = c[1], c[2], c[3], c[4]
		A(new("Frame", { Size = UDim2.fromOffset(len, 1), Position = UDim2.fromOffset(dx > 0 and x or x - len, dy > 0 and y or y - 1), BorderSizePixel = 0, ZIndex = z or 6, Parent = p }), "BackgroundColor3")
		A(new("Frame", { Size = UDim2.fromOffset(1, len), Position = UDim2.fromOffset(dx > 0 and x or x - 1, dy > 0 and y or y - len), BorderSizePixel = 0, ZIndex = z or 6, Parent = p }), "BackgroundColor3")
	end
end

-- ===================== roots =====================
local guiParent = pgui
do
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and typeof(h) == "Instance" then guiParent = h end
end
for _, par in ipairs({ guiParent, pgui }) do
	for _, n in ipairs({ "Luxxs", "LuxxsESP" }) do
		local o = par:FindFirstChild(n)
		if o then o:Destroy() end
	end
end
local function mkGui(name, order)
	return new("ScreenGui", { Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent })
end
local gui, espGui = mkGui("Luxxs", 50), mkGui("LuxxsESP", 8)

-- toasts
local toastHost = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(260, 320), BackgroundTransparency = 1, ZIndex = 100, Parent = gui })
new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), Parent = toastHost })
local function notify(txt)
	if F.notif == false then return end
	local slot = new("Frame", { Size = UDim2.fromOffset(240, 32), BackgroundTransparency = 1, Parent = toastHost })
	local card = new("Frame", { Position = UDim2.fromOffset(270, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = slot })
	stroke(card, C.line, 1)
	A(new("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card }), "BackgroundColor3")
	new("TextLabel", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -18, 1, 0), BackgroundTransparency = 1, Text = txt, Font = F_MONO, TextSize = 12,
		TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	tw(card, .4, { Position = UDim2.fromOffset(0, 0) })
	task.delay(2.4, function()
		if not card.Parent then return end
		tw(card, .3, { Position = UDim2.fromOffset(270, 0) }, EZ.Quint, ED.In)
		task.delay(.35, function() slot:Destroy() end)
	end)
end

local function drag(handle, target, onClick)
	local dn, moved, start, orig = false, false, nil, nil
	on(handle.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dn, moved, start, orig = true, false, i.Position, target.Position
			local c
			c = i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dn = false
					c:Disconnect()
					if not moved and onClick then onClick() end
				end
			end)
		end
	end)
	on(UIS.InputChanged, function(i)
		if dn and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			if d.Magnitude > 5 then moved = true end
			if moved then target.Position = UDim2.new(orig.X.Scale, orig.X.Offset + d.X, orig.Y.Scale, orig.Y.Offset + d.Y) end
		end
	end)
end

-- ===================== UI components =====================
local activeDrag, activeScroll
on(UIS.InputChanged, function(i)
	if activeDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then activeDrag(i.Position.X) end
end)
on(UIS.InputEnded, function(i)
	if activeDrag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
		activeDrag = nil
		if activeScroll then activeScroll.ScrollingEnabled = true; activeScroll = nil end
	end
end)

local function hair(p, y) return new("Frame", { Position = UDim2.new(0, 0, 1, y or -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0, Parent = p }) end
local function rowLabel(r, txt, w)
	return new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(w or 1, w and 0 or -60, 0, 34), Font = F_BODY, TextSize = 16,
		TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Text = txt, Parent = r })
end

local function makeTabApi(sc)
	local T = {}
	function T:Section(txt)
		local f = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = sc })
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 18), Font = F_SEC, TextSize = 13,
			TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(txt), Parent = f })
		hair(f, -3)
		A(new("Frame", { Position = UDim2.new(0, 0, 1, -3), Size = UDim2.fromOffset(28, 1), BorderSizePixel = 0, Parent = f }), "BackgroundColor3")
	end
	function T:Note(txt, h)
		new("TextLabel", { Size = UDim2.new(1, -8, 0, h or 18), BackgroundTransparency = 1, Font = F_MONO, TextSize = 10, TextColor3 = C.dim, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = txt, Parent = sc })
	end
	function T:Toggle(txt, key, cb)
		local r = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.row, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = sc })
		hair(r)
		rowLabel(r, txt)
		local box = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = r })
		local bs = stroke(box, C.off, 1)
		local inner = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(0, 0), BorderSizePixel = 0, Parent = box })
		A(inner, "BackgroundColor3")
		local function paint(anim)
			local v = F[key]
			tw(inner, anim and .16 or 0, { Size = v and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0) }, v and EZ.Back or EZ.Quad)
			tw(bs, anim and .16 or 0, { Color = v and accent or C.off })
		end
		reg(key, false, function(v)
			F[key] = v and true or false
			paint(true)
			if cb then task.spawn(cb, F[key]) end
		end)
		paint(false)
		hooks[#hooks + 1] = function() if F[key] then bs.Color = accent end end
		on(r.MouseButton1Click, function()
			SET[key](not F[key])
			notify(txt .. (F[key] and "  ON" or "  OFF"))
		end)
		on(r.MouseEnter, function() tw(r, .12, { BackgroundTransparency = .55 }) end)
		on(r.MouseLeave, function() tw(r, .12, { BackgroundTransparency = 1 }) end)
	end
	function T:Slider(txt, key, mn, mx, def, fmt, cb, step)
		step = step or 1
		local r = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = sc })
		hair(r)
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 4), Size = UDim2.new(.6, 0, 0, 20), Font = F_BODY, TextSize = 16, TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left, Text = txt, Parent = r })
		local val = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 4), Size = UDim2.fromOffset(110, 20), Font = F_MONO,
			TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = r })
		A(val, "TextColor3")
		local bar = new("Frame", { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -20, 0, 2), BackgroundColor3 = C.off, BorderSizePixel = 0, Parent = r })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
		A(fill, "BackgroundColor3")
		local knob = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.fromOffset(6, 14), BackgroundColor3 = C.text, BorderSizePixel = 0, ZIndex = 3, Parent = bar })
		reg(key, def, function(v)
			v = math.clamp(math.floor((tonumber(v) or mn) / step + .5) * step, mn, mx)
			F[key] = v
			local fr = (v - mn) / (mx - mn)
			val.Text = fmt and fmt(v) or tostring(v)
			tw(fill, .08, { Size = UDim2.fromScale(fr, 1) }, EZ.Linear)
			tw(knob, .08, { Position = UDim2.fromScale(fr, .5) }, EZ.Linear)
			if cb then task.spawn(cb, v) end
		end)
		SET[key](def)
		local hit = new("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 24), Parent = r })
		local function upd(x) SET[key](mn + (mx - mn) * math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)) end
		on(hit.InputBegan, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				activeDrag, activeScroll = upd, sc
				sc.ScrollingEnabled = false
				upd(i.Position.X)
			end
		end)
	end
	function T:Choice(txt, key, opts, def, cb)
		local idx = table.find(opts, def) or 1
		local r = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.row, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = sc })
		hair(r)
		rowLabel(r, txt, .5)
		local val = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(.5, -10, 1, 0), Font = F_MONO, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right, Text = "< " .. opts[idx] .. " >", Parent = r })
		A(val, "TextColor3")
		reg(key, opts[idx], function(v)
			local i = table.find(opts, v)
			if not i then return end
			idx, F[key] = i, opts[i]
			val.Text = "< " .. opts[i] .. " >"
			if cb then task.spawn(cb, opts[i]) end
		end)
		on(r.MouseButton1Click, function() SET[key](opts[idx % #opts + 1]) end)
		on(r.MouseButton2Click, function() SET[key](opts[(idx - 2) % #opts + 1]) end)
		on(r.MouseEnter, function() tw(r, .12, { BackgroundTransparency = .55 }) end)
		on(r.MouseLeave, function() tw(r, .12, { BackgroundTransparency = 1 }) end)
	end
	function T:Colors(txt, key, def, rainbow, cb)
		local r = new("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Parent = sc })
		hair(r)
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 0, 32), Font = F_BODY, TextSize = 16, TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left, Text = txt, Parent = r })
		local f = new("Frame", { Position = UDim2.fromOffset(10, 33), Size = UDim2.new(1, -20, 0, 22), BackgroundTransparency = 1, Parent = r })
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = f })
		local sw = {}
		local function paint() for i, b in ipairs(sw) do tw(b.s, .15, { Transparency = F[key] == i and 0 or 1 }) end end
		for i = 1, rainbow and 10 or 9 do
			local b = new("TextButton", { Size = UDim2.fromOffset(22, 22), BorderSizePixel = 0, Text = "", AutoButtonColor = false, BackgroundColor3 = i == 10 and WHITE or PAL[i], Parent = f })
			corner(b, 11)
			if i == 10 then
				new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)), ColorSequenceKeypoint.new(.25, Color3.fromRGB(255, 232, 70)),
					ColorSequenceKeypoint.new(.5, Color3.fromRGB(86, 255, 126)), ColorSequenceKeypoint.new(.75, Color3.fromRGB(80, 120, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 95, 200)) }),
					Rotation = 45, Parent = b })
			end
			local s = stroke(b, WHITE, 2, 1)
			sw[i] = { s = s }
			on(b.MouseButton1Click, function() SET[key](i) end)
		end
		reg(key, def, function(v)
			F[key] = v
			paint()
			if cb then task.spawn(cb, v) end
		end)
		paint()
	end
	function T:Button(txt, cb)
		local w = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = sc })
		local b = new("TextButton", { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 30), BackgroundColor3 = C.bg, BackgroundTransparency = 1, BorderSizePixel = 0,
			AutoButtonColor = false, Font = F_MONO, TextSize = 12, Text = string.upper(txt), Parent = w })
		A(b, "TextColor3")
		A(stroke(b, accent, 1, .4), "Color")
		on(b.MouseEnter, function() b.BackgroundColor3 = accent; tw(b, .12, { BackgroundTransparency = 0 }); b.TextColor3 = C.bg end)
		on(b.MouseLeave, function() tw(b, .12, { BackgroundTransparency = 1 }); b.TextColor3 = accent end)
		on(b.MouseButton1Click, function() if cb then task.spawn(cb) end end)
	end
	function T:Input(txt, key, def, cb)
		local r = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = sc })
		hair(r)
		rowLabel(r, txt, .42)
		local bf = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.new(.58, -14, 0, 26), BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = r })
		A(stroke(bf, accent, 1, .4), "Color")
		local tb = new("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0), Font = F_MONO, TextSize = 12, TextColor3 = C.text,
			PlaceholderColor3 = C.dim, PlaceholderText = "value", Text = tostring(def or ""), ClearTextOnFocus = false, Parent = bf })
		reg(key, tostring(def or ""), function(v)
			F[key] = tostring(v)
			tb.Text = F[key]
			if cb then task.spawn(cb, F[key], tb) end
		end)
		on(tb.FocusLost, function() SET[key](tb.Text) end)
	end
	return T
end

-- ===================== window =====================
local W, H = 900, 470
local holder = new("Frame", { Name = "Holder", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Parent = gui })
local userScale = new("UIScale", { Parent = holder })
local animF = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder })
local animScale = new("UIScale", { Scale = .9, Parent = animF })
local main = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = animF })
BG(main, 0)
corner(main, 10)
local mainStroke = stroke(main, accent, 1.8)
A(mainStroke, "Color")
local mainGrad = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(.5, Color3.fromRGB(55, 55, 55)), ColorSequenceKeypoint.new(1, WHITE) }), Parent = mainStroke })

local function fit()
	local vp = gui.AbsoluteSize
	userScale.Scale = math.clamp(math.min(vp.X / (W + 30), vp.Y / (H + 30)), .3, 1.6) * (F.size or 1)
end
on(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)

-- top bar
local top = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = main })
BG(top, .05)
drag(top, holder)
hair(top)
local mark = new("Frame", { Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(8, 8), Rotation = 45, BorderSizePixel = 0, Parent = top })
A(mark, "BackgroundColor3")
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.fromOffset(90, 44), Font = F_HEAD, TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Text = "LUXXS", Parent = top })
local crumb = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(130, 2), Size = UDim2.fromOffset(240, 44), Font = F_MONO, TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "// 01", Parent = top })
new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -52, 0, 0), Size = UDim2.fromOffset(160, 44), Font = F_MONO, TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, Text = "v5.1", Parent = top })
local closeBtn = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = C.row, BorderSizePixel = 0, Text = "X", Font = F_MONO, TextSize = 13, TextColor3 = C.dim, AutoButtonColor = false, Parent = top })

-- sidebar
local sideH = H - 44 - 24
local side = new("Frame", { Position = UDim2.fromOffset(0, 44), Size = UDim2.fromOffset(150, sideH), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = main })
BG(side, .05)
new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.line, BorderSizePixel = 0, Parent = side })
local sideList = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, -1, 1, -70), Parent = side })
local indicator = new("Frame", { Size = UDim2.fromOffset(2, 22), Position = UDim2.fromOffset(0, 18), BorderSizePixel = 0, ZIndex = 3, Parent = side })
A(indicator, "BackgroundColor3")
local brand = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -12), Size = UDim2.fromOffset(120, 22), Font = F_HEAD, TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left, Text = "luxxs", Parent = side })
A(brand, "TextColor3")
local brandStroke = new("UIStroke", { Thickness = 1, Transparency = .7, Parent = brand })
A(brandStroke, "Color")
new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -38), Size = UDim2.fromOffset(24, 1), BorderSizePixel = 0, Parent = side })
local brandLine = side:GetChildren()[#side:GetChildren()]
A(brandLine, "BackgroundColor3")

-- footer
local foot = new("Frame", { Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = main })
BG(foot, .05)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0, Parent = foot })
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(166, 0), Size = UDim2.new(.5, 0, 1, 0), Font = F_MONO, TextSize = 10, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "RIGHTSHIFT = TOGGLE   //   DRAG TOP BAR OR Lx ICON", Parent = foot })
local footR = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(.4, 0, 1, 0), Font = F_MONO, TextSize = 10, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, Text = "", Parent = foot })

local pages = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(162, 54), Size = UDim2.fromOffset(468, H - 54 - 34), ClipsDescendants = true, Parent = main })

local tabs, curTab, switching = {}, nil, false
local function paintTabs()
	for _, t in ipairs(tabs) do
		local sel = t == curTab
		t.nm.TextColor3 = sel and C.text or C.dim
		t.num.TextColor3 = sel and accent or C.dim
		t.btn.BackgroundTransparency = sel and .55 or 1
	end
end
hooks[#hooks + 1] = paintTabs
local function selectTab(tab)
	if curTab == tab or switching then return end
	switching = true
	local old = curTab
	curTab = tab
	tw(indicator, .3, { Position = UDim2.fromOffset(0, 18 + tab.index * 38) })
	paintTabs()
	crumb.Text = string.format("// %02d  %s", tab.index + 1, string.upper(tab.name))
	if old then
		tw(old.page, .15, { BackgroundTransparency = 1 })
		task.delay(.15, function() old.page.Visible = false end)
	end
	task.delay(old and .12 or 0, function()
		tab.page.BackgroundTransparency = 1
		tab.page.Visible = true
		tw(tab.page, .25, { BackgroundTransparency = 0 })
		task.delay(.25, function() switching = false end)
	end)
end
local function createTab(name)
	local index = #tabs
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, index * 38 + 6), BackgroundColor3 = C.row, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = sideList })
	local num = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(24, 34), Font = F_MONO, TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Text = string.format("%02d", index + 1), Parent = btn })
	local nm = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -50, 1, 0), Font = F_SEC, TextSize = 16, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(name), Parent = btn })
	local page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = pages })
	local sc = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = page })
	A(sc, "ScrollBarImageColor3")
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sc })
	new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12), Parent = sc })
	local tab = makeTabApi(sc)
	tab.btn, tab.num, tab.nm, tab.page, tab.index, tab.name = btn, num, nm, page, index, name
	tabs[#tabs + 1] = tab
	on(btn.MouseButton1Click, function() selectTab(tab) end)
	on(btn.MouseEnter, function() if curTab ~= tab then tw(nm, .15, { TextColor3 = C.text }) end end)
	on(btn.MouseLeave, function() if curTab ~= tab then tw(nm, .15, { TextColor3 = C.dim }) end end)
	return tab
end

-- ===================== open / close / icon =====================
local opened, busy = false, false
local function openMenu()
	if busy or opened then return end
	busy, opened = true, true
	holder.Visible = true
	animScale.Scale = .9
	main.BackgroundTransparency = 1
	tw(animScale, .4, { Scale = 1 }, EZ.Back)
	tw(main, .3, { BackgroundTransparency = 0 })
	task.delay(.4, function() busy = false end)
end
local function closeMenu()
	if busy or not opened then return end
	busy, opened = true, false
	tw(animScale, .25, { Scale = .92 }, EZ.Quint, ED.In)
	tw(main, .25, { BackgroundTransparency = 1 }, EZ.Quint, ED.In)
	task.delay(.27, function() holder.Visible = false; busy = false end)
end
local function toggleMenu() if opened then closeMenu() else openMenu() end end
on(closeBtn.MouseButton1Click, closeMenu)
on(closeBtn.MouseEnter, function() tw(closeBtn, .12, { BackgroundColor3 = Color3.fromRGB(190, 56, 56) }); closeBtn.TextColor3 = WHITE end)
on(closeBtn.MouseLeave, function() tw(closeBtn, .12, { BackgroundColor3 = C.row }); closeBtn.TextColor3 = C.dim end)
on(UIS.InputBegan, function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end)

local icon = new("TextButton", { Name = "Icon", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(56, 170), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = C.bg,
	Text = "Lx", Font = F_HEAD, TextSize = 17, AutoButtonColor = false, Visible = true, ZIndex = 5, Parent = gui })
A(icon, "TextColor3")
corner(icon, 40)
local iconStroke = stroke(icon, accent, 2.5)
A(iconStroke, "Color")
local iconGrad = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(.5, Color3.fromRGB(40, 40, 40)), ColorSequenceKeypoint.new(1, WHITE) }), Parent = iconStroke })
local iconGlow = new("UIStroke", { Thickness = 7, Transparency = .82, Parent = icon })
A(iconGlow, "Color")
drag(icon, icon, toggleMenu)
on(icon.MouseEnter, function() tw(icon, .2, { Size = UDim2.fromOffset(62, 62) }, EZ.Back) end)
on(icon.MouseLeave, function() tw(icon, .2, { Size = UDim2.fromOffset(54, 54) }) end)

-- ===================== tabs =====================
local tCombat = createTab("Combat")
local tVis = createTab("Visuals")
local tChar = createTab("Character")
local tSkin = createTab("Skins")
local tWorld = createTab("World")
local tSet = createTab("Settings")

local AIM_NAMES = { "Head", "Chest", "Stomach", "Arms", "Legs" }
local wingDirty, auraDirty, skinVer = true, true, 0

-- Combat
tCombat:Section("Aimbot")
tCombat:Toggle("Enable aimbot", "aim")
tCombat:Choice("Activation", "aimAct", { "Hold RMB", "Always" }, "Hold RMB")
tCombat:Choice("Mode", "aimMode", { "Smooth", "Snap" }, "Smooth")
tCombat:Slider("Smoothness", "smooth", 1, 100, 40, function(v) return v .. "%" end)
tCombat:Choice("Aim point", "aimPart", AIM_NAMES, "Head")
tCombat:Toggle("Wall check (no aim through walls)", "wall")
tCombat:Toggle("Team check", "team")
tCombat:Section("FOV")
tCombat:Toggle("Show FOV circle", "fovShow")
tCombat:Slider("FOV radius", "fov", 30, 500, 140, function(v) return v .. "px" end)
tCombat:Note("Tip: click a point on the mannequin in the preview to choose the aim point.", 28)
SET.wall(true)

-- Visuals
tVis:Section("ESP")
tVis:Toggle("Boxes", "box")
tVis:Choice("Box type", "boxType", { "2D", "3D" }, "2D")
tVis:Colors("Box color", "boxCol", 1, true)
tVis:Toggle("Names", "name")
tVis:Toggle("Distance", "dist")
tVis:Toggle("Health bar", "hp")
tVis:Toggle("Tracers", "tracer")
tVis:Toggle("Skeleton", "skel")
tVis:Colors("Skeleton color", "skelCol", 9, true)
tVis:Toggle("Head dot", "headDot")
tVis:Colors("Head dot color", "headCol", 6, true)
tVis:Toggle("Weapon name", "tool")
tVis:Toggle("Off-screen arrows", "arrows")
tVis:Colors("Arrow color", "arrowCol", 1, true)
tVis:Slider("Max distance", "espDist", 100, 3000, 1500, function(v) return v .. "m" end, nil, 50)
tVis:Section("Chams / Glow")
tVis:Toggle("Chams", "chams")
tVis:Colors("Chams color", "chamCol", 1, true)
tVis:Toggle("Glow", "glow")
tVis:Colors("Glow color", "glowCol", 2, true)
tVis:Section("Screen")
tVis:Toggle("Crosshair", "cross")

-- Character
tChar:Section("Movement")
tChar:Toggle("Fly", "fly")
tChar:Slider("Fly speed", "flySpeed", 10, 300, 70)
tChar:Toggle("Noclip", "noclip")
tChar:Toggle("Spin", "spin")
tChar:Slider("Spin speed", "spinSpeed", 1, 1000, 500)
tChar:Toggle("Walk speed", "speedOn")
tChar:Slider("Speed value", "speed", 16, 150, 32)
tChar:Toggle("Jump power", "jumpOn")
tChar:Slider("Jump value", "jump", 50, 300, 100)
tChar:Toggle("Infinite jump", "infJump")
tChar:Toggle("Gravity", "gravOn")
tChar:Slider("Gravity value", "grav", 0, 300, 196)
tChar:Note("Fly: WASD + Space/E up, Ctrl/Q down. On mobile use joystick + UP/DN buttons.", 40)
tChar:Section("Wings")
tChar:Toggle("Wings", "wings", function() wingDirty = true end)
tChar:Choice("Wing type", "wingType", { "Angel", "Demon" }, "Angel", function() wingDirty = true end)
tChar:Colors("Wing color", "wingCol", 9, true)
tChar:Slider("Wing size", "wingSize", 60, 160, 100, function(v) return v .. "%" end, function() wingDirty = true end, 5)
tChar:Slider("Flap speed", "wingSpeed", 1, 12, 3)
tChar:Section("Aura")
tChar:Toggle("Aura", "aura", function() auraDirty = true end)
tChar:Choice("Aura type", "auraType", { "Sparkles", "Flames", "Vortex", "Halo" }, "Sparkles", function() auraDirty = true end)
tChar:Colors("Aura color", "auraCol", 4, true)
tChar:Section("Trail")
tChar:Toggle("Trail", "trail")
tChar:Colors("Trail color", "trailCol", 10, true)
tChar:Slider("Trail length", "trailLen", 3, 30, 10, function(v) return string.format("%.1fs", v / 10) end)
tChar:Slider("Trail width", "trailW", 1, 10, 4)
tChar:Section("Body")
tChar:Choice("Body material", "bodyMat", { "Off", "ForceField", "Neon", "Glass", "Metal", "Ice" }, "Off")
tChar:Colors("Body color", "bodyCol", 2, true)
tChar:Toggle("Self glow outline", "selfGlow")
tChar:Colors("Outline color", "selfGlowCol", 1, true)

-- Skins
tSkin:Section("Knife skin")
tSkin:Choice("Knife skin", "knifeSkin", { "Off", "Gold", "Ice", "Lava", "Void", "Toxic", "Galaxy", "Candy", "Obsidian", "Chroma" }, "Off", function() skinVer = skinVer + 1 end)
tSkin:Input("Knife texture ID", "knifeTex", "", function() skinVer = skinVer + 1 end)
tSkin:Section("Gun skin")
tSkin:Choice("Gun skin", "gunSkin", { "Off", "Gold", "Ice", "Lava", "Void", "Toxic", "Galaxy", "Candy", "Obsidian", "Chroma" }, "Off", function() skinVer = skinVer + 1 end)
tSkin:Input("Gun texture ID", "gunTex", "", function() skinVer = skinVer + 1 end)
tSkin:Section("Options")
tSkin:Toggle("Skin particles", "skinFx", function() skinVer = skinVer + 1 end)
tSkin:Toggle("Knife trail", "skinTrail", function() skinVer = skinVer + 1 end)
tSkin:Toggle("Strip original textures", "skinStrip", function() skinVer = skinVer + 1 end)
tSkin:Input("Knife name keywords", "knifeKeys", "knife,blade,sword,dagger", function() skinVer = skinVer + 1 end)
tSkin:Input("Gun name keywords", "gunKeys", "gun,pistol,revolver,rifle,shotgun,blaster", function() skinVer = skinVer + 1 end)
tSkin:Note("Skins are client-side only (only you see them).", 28)

-- World
tWorld:Section("Lighting")
tWorld:Toggle("Fullbright", "fullbright")
tWorld:Toggle("Time of day", "timeOn")
tWorld:Slider("Time", "timeVal", 0, 24, 14, function(v) return string.format("%02d:%02d", math.floor(v), (v % 1) * 60) end, nil, .5)
tWorld:Toggle("No fog", "noFog")
tWorld:Choice("Color grade", "grade", { "Off", "Cinematic", "Neon", "Warm", "Noir", "Vivid" }, "Off")
tWorld:Section("Camera")
tWorld:Toggle("Custom FOV", "camFov")
tWorld:Slider("Field of view", "fovVal", 30, 120, 90)

-- Settings
tSet:Section("Menu")
tSet:Colors("Menu color", "menuCol", 1, false, function(i) setAccent(PAL[i]) end)
tSet:Slider("Hue", "hue", 0, 1, .39, function(v) return math.floor(v * 360) .. "deg" end, function(v) setAccent(Color3.fromHSV(v, .7, 1)) end, .01)
tSet:Slider("Transparency", "alpha", 0, .6, .05, function(v) return math.floor(v * 100) .. "%" end, applyAlpha, .01)
tSet:Slider("Size", "size", .6, 1.4, 1, function(v) return math.floor(v * 100) .. "%" end, fit, .05)
tSet:Toggle("Notifications", "notif")
SET.notif(true)
tSet:Section("Performance")
tSet:Toggle("FPS counter", "fpsShow")
tSet:Toggle("Custom FPS", "fpsCustom")
tSet:Slider("FPS cap", "fps", 30, 999, 240)
tSet:Input("Type FPS", "fpsType", "999", function(txt)
	local n = tonumber(txt)
	if n then SET.fps(math.clamp(math.floor(n), 30, 999)) end
end)
local capfn
do
	local ok, f = pcall(function() return setfpscap end)
	if ok and type(f) == "function" then capfn = f end
end
if not capfn then tSet:Note("setfpscap is not available here.", 40) end
tSet:Section("Config")
tSet:Choice("Slot", "slot", { "1", "2", "3" }, "1")
local hasFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local function cfgPath() return "luxxs_cfg_" .. F.slot .. ".json" end
tSet:Button("Save config", function()
	if not hasFS then notify("No file system") return end
	local d = {}
	for k, v in pairs(F) do
		local ty = type(v)
		if ty == "boolean" or ty == "number" or ty == "string" then d[k] = v end
	end
	notify(pcall(writefile, cfgPath(), HttpService:JSONEncode(d)) and "Saved slot " .. F.slot or "Save failed")
end)
tSet:Button("Load config", function()
	if not hasFS or not isfile(cfgPath()) then notify("Slot empty") return end
	local ok, d = pcall(function() return HttpService:JSONDecode(readfile(cfgPath())) end)
	if not ok then notify("Read failed") return end
	for k, v in pairs(d) do if SET[k] and k ~= "slot" then SET[k](v) end end
	notify("Loaded slot " .. F.slot)
end)
tSet:Button("Reset all", function()
	for k, d in pairs(DEF) do if SET[k] and k ~= "slot" then SET[k](d) end end
	SET.wall(true); SET.notif(true)
	notify("Reset")
end)
local unload
tSet:Section("Menu control")
tSet:Button("Close menu", closeMenu)
tSet:Button("Unload luxxs", function() unload() end)

-- ===================== ESP =====================
local plist = Players:GetPlayers()
local esp = {}
local R15 = { { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" }, { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" }, { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" } }
local R6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }
local UP_T, UP_B = Vector3.new(0, 2.7, 0), Vector3.new(0, -3.1, 0)
local CORN = {}
for xi, x in ipairs({ -1.9, 1.9 }) do
	for yi, y in ipairs({ -3.1, 2.7 }) do
		for zi, z in ipairs({ -1.1, 1.1 }) do CORN[(xi - 1) * 4 + (yi - 1) * 2 + zi] = Vector3.new(x, y, z) end
	end
end
local EDGES = { { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 }, { 1, 3 }, { 2, 4 }, { 5, 7 }, { 6, 8 }, { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 } }

local function eLine() return new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false, Parent = espGui }) end
local function eText(sz, ay)
	return new("TextLabel", { AnchorPoint = Vector2.new(.5, ay), Size = UDim2.fromOffset(160, 14), BackgroundTransparency = 1, Font = F_MONO, TextSize = sz, TextColor3 = WHITE,
		TextStrokeTransparency = .35, Visible = false, Parent = espGui })
end
local function mkEsp()
	local d = { shown = false, e3 = {}, sk = {} }
	d.box = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = espGui })
	d.bs = stroke(d.box, WHITE, 1.5)
	for i = 1, 12 do d.e3[i] = eLine() end
	for i = 1, 14 do d.sk[i] = eLine() end
	d.name, d.dist, d.tool = eText(13, 1), eText(11, 0), eText(11, 0)
	d.tool.TextColor3 = Color3.fromRGB(255, 220, 120)
	d.hpBg = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .4, BorderSizePixel = 0, Visible = false, Parent = espGui })
	d.hp = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = d.hpBg })
	d.tr = eLine()
	d.dot = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false, Parent = espGui })
	corner(d.dot, 9)
	stroke(d.dot, Color3.new(0, 0, 0), 1)
	d.arrow = new("TextLabel", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "▲", Font = Enum.Font.GothamBold, TextSize = 22, Visible = false, Parent = espGui })
	new("UIStroke", { Thickness = 1, Transparency = .4, Parent = d.arrow })
	return d
end
local function hideEsp(d)
	if not d.shown then return end
	d.shown = false
	d.box.Visible, d.name.Visible, d.dist.Visible, d.tool.Visible, d.hpBg.Visible, d.tr.Visible, d.dot.Visible, d.arrow.Visible = false, false, false, false, false, false, false, false
	for _, l in ipairs(d.e3) do l.Visible = false end
	for _, l in ipairs(d.sk) do l.Visible = false end
end
local hls = {}
local function killEsp(p)
	local d = esp[p]
	if d then
		for _, v in pairs(d) do if typeof(v) == "Instance" then v:Destroy() end end
		for _, l in ipairs(d.e3) do l:Destroy() end
		for _, l in ipairs(d.sk) do l:Destroy() end
		esp[p] = nil
	end
	if hls[p] then hls[p]:Destroy(); hls[p] = nil end
end
on(Players.PlayerAdded, function() plist = Players:GetPlayers() end)
on(Players.PlayerRemoving, function(p) killEsp(p); task.defer(function() plist = Players:GetPlayers() end) end)

local function isEnemy(p) return not (F.team and p.Team and p.Team == lp.Team) end
local espWasOn = false

local function bindChar(d, ch)
	if d.char == ch then
		if ch and (not d.hrp or not d.hum) then d.hrp, d.hum, d.head = ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid"), ch:FindFirstChild("Head") end
		return
	end
	d.char, d.hrp, d.hum, d.head, d.pairs = ch, nil, nil, nil, nil
	if ch then
		d.hrp, d.hum, d.head = ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid"), ch:FindFirstChild("Head")
		local prs = {}
		for _, pr in ipairs(ch:FindFirstChild("UpperTorso") and R15 or R6) do
			local a, b = ch:FindFirstChild(pr[1]), ch:FindFirstChild(pr[2])
			if a and b then prs[#prs + 1] = { a, b } end
		end
		d.pairs = prs
	end
end

local function espStep(cam, t)
	local any = F.box or F.name or F.dist or F.hp or F.skel or F.tracer or F.headDot or F.tool or F.arrows
	local hlOn = F.chams or F.glow
	if not any and not hlOn and not espWasOn then return end
	espWasOn = any or hlOn
	local vp = cam.ViewportSize
	local camPos = cam.CFrame.Position
	local bc, sc, cc, gc, hc, ac = pal(F.boxCol), pal(F.skelCol), pal(F.chamCol), pal(F.glowCol), pal(F.headCol), pal(F.arrowCol)
	local maxD = F.espDist or 1500
	for _, p in ipairs(plist) do
		if p ~= lp then
			local ch = p.Character
			local d = esp[p]
			local alive = false
			if ch and (any or hlOn) and isEnemy(p) then
				if not d then d = mkEsp(); esp[p] = d end
				bindChar(d, ch)
				alive = d.hrp and d.hum and d.hum.Health > 0 and (d.hrp.Position - camPos).Magnitude <= maxD
			elseif d then
				bindChar(d, nil)
			end

			local hl = hls[p]
			if alive and hlOn then
				if not hl or hl.Parent ~= ch then
					if hl then hl:Destroy() end
					hl = new("Highlight", { Adornee = ch, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = ch })
					hls[p] = hl
				end
				hl.Enabled = true
				hl.FillColor, hl.OutlineColor = cc, F.glow and gc or cc
				hl.FillTransparency = F.chams and .45 or 1
				hl.OutlineTransparency = F.glow and (.05 + .3 * (.5 + .5 * math.sin(t * 3))) or (F.chams and .2 or 1)
				local pl = d.hrp:FindFirstChild("LxGlow")
				if F.glow then
					if not pl then pl = new("PointLight", { Name = "LxGlow", Range = 14, Brightness = 1.5, Parent = d.hrp }) end
					pl.Color = gc
				elseif pl then
					pl:Destroy()
				end
			elseif hl then
				hl.Enabled = false
				local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
				local pl = hrp and hrp:FindFirstChild("LxGlow")
				if pl then pl:Destroy() end
			end

			if d then
				if alive and any then
					local hrp, hum = d.hrp, d.hum
					local pos = hrp.Position
					local top, bot = cam:WorldToViewportPoint(pos + UP_T), cam:WorldToViewportPoint(pos + UP_B)
					local headP = d.head and cam:WorldToViewportPoint(d.head.Position)
					if top.Z > 0 and bot.Z > 0 then
						d.shown = true
						local h = bot.Y - top.Y
						local w = h * .55
						local mx = (top.X + bot.X) / 2
						d.arrow.Visible = false
						if F.box and F.boxType == "2D" then
							d.box.Visible = true
							d.box.Position = UDim2.fromOffset(mx - w / 2, top.Y)
							d.box.Size = UDim2.fromOffset(w, h)
							d.bs.Color = bc
						else
							d.box.Visible = false
						end
						local ok3 = false
						if F.box and F.boxType == "3D" then
							local _, yaw = hrp.CFrame:ToOrientation()
							local base = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
							local pts, okp = {}, true
							for i = 1, 8 do
								local v = cam:WorldToViewportPoint(base * CORN[i])
								if v.Z <= 0 then okp = false break end
								pts[i] = v
							end
							if okp then
								ok3 = true
								for i, e in ipairs(EDGES) do
									local a, b = pts[e[1]], pts[e[2]]
									setLine(d.e3[i], a.X, a.Y, b.X, b.Y, 1.5, bc)
								end
							end
						end
						if not ok3 then for _, l in ipairs(d.e3) do l.Visible = false end end
						if F.name then
							d.name.Visible = true; d.name.Text = p.DisplayName; d.name.Position = UDim2.fromOffset(mx, top.Y - 3)
						else d.name.Visible = false end
						if F.dist then
							d.dist.Visible = true; d.dist.Text = math.floor((camPos - pos).Magnitude) .. "m"; d.dist.Position = UDim2.fromOffset(mx, bot.Y + 2)
						else d.dist.Visible = false end
						local tl = F.tool and ch:FindFirstChildOfClass("Tool")
						if tl then
							d.tool.Visible = true; d.tool.Text = tl.Name; d.tool.Position = UDim2.fromOffset(mx, bot.Y + (F.dist and 15 or 3))
						else d.tool.Visible = false end
						if F.hp then
							local fr = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
							d.hpBg.Visible = true
							d.hpBg.Position = UDim2.fromOffset(mx - w / 2 - 7, top.Y)
							d.hpBg.Size = UDim2.fromOffset(3, h)
							d.hp.Size = UDim2.fromScale(1, fr)
							d.hp.BackgroundColor3 = Color3.fromHSV(.33 * fr, .9, 1)
						else d.hpBg.Visible = false end
						if F.tracer then setLine(d.tr, vp.X / 2, vp.Y, mx, bot.Y, 1.2, bc) else d.tr.Visible = false end
						if F.headDot and headP and headP.Z > 0 then
							local sz = math.clamp(h * .11, 4, 18)
							d.dot.Visible = true; d.dot.Size = UDim2.fromOffset(sz, sz); d.dot.Position = UDim2.fromOffset(headP.X, headP.Y); d.dot.BackgroundColor3 = hc
						else d.dot.Visible = false end
						if F.skel and d.pairs then
							for i = 1, 14 do
								local pr, l = d.pairs[i], d.sk[i]
								if pr then
									local s1, s2 = cam:WorldToViewportPoint(pr[1].Position), cam:WorldToViewportPoint(pr[2].Position)
									if s1.Z > 0 and s2.Z > 0 then setLine(l, s1.X, s1.Y, s2.X, s2.Y, 1.5, sc) else l.Visible = false end
								else l.Visible = false end
							end
						else
							for _, l in ipairs(d.sk) do l.Visible = false end
						end
					else
						hideEsp(d)
						d.shown = true
						if F.arrows then
							local rel = cam.CFrame:PointToObjectSpace(pos)
							local dir = Vector2.new(rel.X, -rel.Y)
							if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
							dir = dir.Unit
							local r = math.min(vp.X, vp.Y) * .38
							d.arrow.Visible = true
							d.arrow.Position = UDim2.fromOffset(vp.X / 2 + dir.X * r, vp.Y / 2 + dir.Y * r)
							d.arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
							d.arrow.TextColor3 = ac
							d.arrow.TextTransparency = .1 + .3 * (.5 + .5 * math.sin(t * 5))
						else
							d.arrow.Visible = false
						end
					end
				else
					hideEsp(d)
				end
			end
		end
	end
end

-- crosshair + fov circle
local fovC = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), BackgroundTransparency = 1, Visible = false, Parent = espGui })
corner(fovC, 500)
A(stroke(fovC, accent, 1.5, .3), "Color")
local cross = {}
for i = 1, 5 do
	cross[i] = A(new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false, Parent = espGui }), "BackgroundColor3")
end
local XO = { { 0, -9, 2, 8 }, { 0, 9, 2, 8 }, { -9, 0, 8, 2 }, { 9, 0, 8, 2 }, { 0, 0, 2, 2 } }
local function screenStep(cam)
	local c = cam.ViewportSize / 2
	for i, f in ipairs(cross) do
		f.Visible = F.cross == true
		if F.cross then
			local o = XO[i]
			f.Position = UDim2.fromOffset(c.X + o[1], c.Y + o[2])
			f.Size = UDim2.fromOffset(o[3], o[4])
		end
	end
	local show = F.aim and F.fovShow
	fovC.Visible = show == true
	if show then
		fovC.Size = UDim2.fromOffset(F.fov * 2, F.fov * 2)
		fovC.Position = UDim2.fromOffset(c.X, c.Y)
	end
end

-- ===================== aimbot =====================
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local function aimPartOf(ch, n)
	local p
	if n == "Head" then p = ch:FindFirstChild("Head")
	elseif n == "Chest" then p = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	elseif n == "Stomach" then p = ch:FindFirstChild("LowerTorso") or ch:FindFirstChild("Torso")
	elseif n == "Arms" then p = ch:FindFirstChild("RightUpperArm") or ch:FindFirstChild("Right Arm")
	else p = ch:FindFirstChild("LeftUpperLeg") or ch:FindFirstChild("Left Leg") end
	return p or ch:FindFirstChild("HumanoidRootPart")
end
local function aimStep(cam, dt)
	if not F.aim then return end
	if F.aimAct == "Hold RMB" and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
	local filt = { cam }
	if lp.Character then filt[2] = lp.Character end
	rp.FilterDescendantsInstances = filt
	local c = cam.ViewportSize / 2
	local origin = cam.CFrame.Position
	local bestPos, bestD = nil, F.fov
	for _, p in ipairs(plist) do
		if p ~= lp and p.Character and isEnemy(p) then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local part = aimPartOf(p.Character, F.aimPart)
			if hum and hum.Health > 0 and part then
				local sp = cam:WorldToViewportPoint(part.Position)
				if sp.Z > 0 then
					local d = (Vector2.new(sp.X, sp.Y) - c).Magnitude
					if d < bestD then
						local clear = true
						if F.wall then
							local hit = Workspace:Raycast(origin, part.Position - origin, rp)
							clear = hit == nil or hit.Instance:IsDescendantOf(p.Character)
						end
						if clear then bestPos, bestD = part.Position, d end
					end
				end
			end
		end
	end
	if bestPos then
		local goal = CFrame.lookAt(origin, bestPos)
		local a = 1
		if F.aimMode == "Smooth" then a = 1 - math.exp(-(1.5 + 26 * (1 - F.smooth / 100)) * dt) end
		cam.CFrame = cam.CFrame:Lerp(goal, a)
	end
end
pcall(function() RS:UnbindFromRenderStep("LuxxsAim") end)
RS:BindToRenderStep("LuxxsAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local cam = Workspace.CurrentCamera
	if cam then pcall(aimStep, cam, dt) end
end)

-- ===================== character =====================
local fly = { on = false, vel = Vector3.zero, up = false, dn = false }
local function flyStop(hum)
	for _, k in ipairs({ "lv", "ao", "att" }) do
		if fly[k] then pcall(function() fly[k]:Destroy() end); fly[k] = nil end
	end
	fly.vel = Vector3.zero
	if fly.on and hum and hum.Parent then
		hum.PlatformStand = false
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
	fly.on = false
end
local function flyStart(hrp, hum)
	flyStop(nil)
	fly.att = new("Attachment", { Name = "LxFlyA", Parent = hrp })
	fly.lv = new("LinearVelocity", { Attachment0 = fly.att, MaxForce = math.huge, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
		VectorVelocity = Vector3.zero, RelativeTo = Enum.ActuatorRelativeTo.World, Parent = hrp })
	fly.ao = new("AlignOrientation", { Mode = Enum.OrientationAlignmentMode.OneAttachment, Attachment0 = fly.att, MaxTorque = math.huge, Responsiveness = 60,
		RigidityEnabled = false, CFrame = hrp.CFrame - hrp.CFrame.Position, Parent = hrp })
	hum.PlatformStand = true
	fly.on = true
end
local function mkFlyBtn(txt, y)
	local b = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -24, .5, y), Size = UDim2.fromOffset(56, 46), BackgroundColor3 = C.bg, BackgroundTransparency = .1,
		BorderSizePixel = 0, Text = txt, Font = F_MONO, TextSize = 14, TextColor3 = C.text, AutoButtonColor = false, Visible = false, ZIndex = 5, Parent = gui })
	A(stroke(b, accent, 1.5), "Color")
	return b
end
local flyUp, flyDn = mkFlyBtn("UP", -30), mkFlyBtn("DN", 30)
local function hold(b, key)
	on(b.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fly[key] = true end end)
	on(b.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fly[key] = false end end)
end
hold(flyUp, "up"); hold(flyDn, "dn")

local spinObj = {}
local function spinClear(hum)
	for _, k in ipairs({ "av", "att" }) do
		if spinObj[k] then pcall(function() spinObj[k]:Destroy() end); spinObj[k] = nil end
	end
	if hum and spinObj.was then hum.AutoRotate = true end
	spinObj.was = false
end

local lastSafe, savedGrav, speedWas, jumpWas = nil, nil, false, false
local function moveStep(dt, t, ch, hrp, hum)
	if F.speedOn then hum.WalkSpeed = F.speed; speedWas = true
	elseif speedWas then hum.WalkSpeed = 16; speedWas = false end
	if F.jumpOn then hum.UseJumpPower = true; hum.JumpPower = F.jump; jumpWas = true
	elseif jumpWas then hum.JumpPower = 50; jumpWas = false end
	if F.gravOn then
		savedGrav = savedGrav or Workspace.Gravity
		Workspace.Gravity = F.grav
	elseif savedGrav then
		Workspace.Gravity = savedGrav
		savedGrav = nil
	end

	if not F.fly and hum.FloorMaterial ~= Enum.Material.Air then lastSafe = hrp.CFrame end
	if (F.fly or F.noclip) and lastSafe and hrp.Position.Y < Workspace.FallenPartsDestroyHeight + 80 then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = lastSafe + Vector3.new(0, 4, 0)
	end

	local cam = Workspace.CurrentCamera
	if F.fly then
		if not fly.on or not fly.lv or fly.lv.Parent ~= hrp then flyStart(hrp, hum) end
		local cf = cam.CFrame
		local d = Vector3.zero
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then d = d + Vector3.yAxis end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then d = d - Vector3.yAxis end
		end
		local md = hum.MoveDirection
		if d.Magnitude == 0 and md.Magnitude > .05 then d = d + md end
		if fly.up then d = d + Vector3.yAxis end
		if fly.dn then d = d - Vector3.yAxis end
		local target = d.Magnitude > 0 and d.Unit * F.flySpeed or Vector3.zero
		fly.vel = fly.vel:Lerp(target, 1 - math.exp(-10 * dt))
		fly.lv.VectorVelocity = fly.vel
		fly.ao.Enabled = not F.spin
		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if look.Magnitude > .01 then fly.ao.CFrame = CFrame.lookAt(Vector3.zero, look) end
		local show = UIS.TouchEnabled
		flyUp.Visible, flyDn.Visible = show, show
	elseif fly.on or fly.lv then
		flyStop(hum)
		flyUp.Visible, flyDn.Visible = false, false
	end

	if F.spin then
		if not spinObj.av or spinObj.av.Parent ~= hrp then
			spinClear(nil)
			spinObj.att = new("Attachment", { Name = "LxSpinA", Parent = hrp })
			spinObj.av = new("AngularVelocity", { Attachment0 = spinObj.att, MaxTorque = math.huge, RelativeTo = Enum.ActuatorRelativeTo.World, Parent = hrp })
		end
		hum.AutoRotate = false
		spinObj.was = true
		spinObj.av.AngularVelocity = Vector3.new(0, F.spinSpeed * .08, 0)
	elseif spinObj.av then
		spinClear(hum)
	end
end

local ncTouched = {}
on(RS.Stepped, function()
	local ch = lp.Character
	if F.noclip and ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then ncTouched[p] = true; p.CanCollide = false end
		end
	elseif next(ncTouched) then
		for p in pairs(ncTouched) do
			if p.Parent and (p.Name == "HumanoidRootPart" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso" or p.Name == "Head") then p.CanCollide = true end
		end
		ncTouched = {}
	end
end)
on(UIS.JumpRequest, function()
	if F.infJump then
		local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- ===================== cosmetics =====================
local fx = { char = nil, wings = nil, aura = nil, trail = nil, trailOwner = nil, selfHl = nil }

local function triDesc(a, b, c, th)
	if (b - a):Cross(c - a).Magnitude < 1e-3 then return nil end
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then c, a = a, c
	elseif acd > bcd and acd > abd then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.max(.05, math.abs(ab:Dot(up)))
	return {
		{ Vector3.new(th, height, math.max(.05, math.abs(ab:Dot(back)))), CFrame.fromMatrix((a + b) / 2, right, up, back) },
		{ Vector3.new(th, height, math.max(.05, math.abs(ac:Dot(back)))), CFrame.fromMatrix((a + c) / 2, -right, up, -back) },
	}
end

local function wpart(model, pivot, cls, size, cf, col, mat, list, mix)
	local p = Instance.new(cls)
	p.Size, p.Color, p.Material = size, col, mat
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = pivot, p, cf
	w.Parent = p
	p.Parent = model
	if list then list[#list + 1] = { p, mix, col } end
	return p
end
local function mkPivot(model, torso, c0)
	local pv = Instance.new("Part")
	pv.Size, pv.Transparency = Vector3.new(.2, .2, .2), 1
	pv.CanCollide, pv.CanQuery, pv.CanTouch, pv.Massless = false, false, false, true
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = torso, pv, c0
	w.Parent = pv
	pv.Parent = model
	return pv, w
end

local function destroyWings()
	if fx.wings then pcall(function() fx.wings.model:Destroy() end); fx.wings = nil end
end
local function buildWings(ch)
	destroyWings()
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	if not torso then return end
	local model = Instance.new("Model")
	model.Name = "LxWings"
	local sc = (F.wingSize or 100) / 100
	local demon = F.wingType == "Demon"
	local W = { model = model, pivots = {}, parts = {}, demon = demon }

	for _, side in ipairs({ -1, 1 }) do
		if not demon then
			local rows = {
				{ n = 7, a0 = 4, a1 = 78, lens = { 5.6, 5.9, 5.6, 5.1, 4.5, 3.9, 3.3 }, wid = .62, mix = .7, z = 0 },
				{ n = 7, a0 = 14, a1 = 104, lens = { 4.2, 4.4, 4.1, 3.7, 3.2, 2.8, 2.4 }, wid = .7, mix = .45, z = .045 },
				{ n = 6, a0 = 26, a1 = 116, lens = { 2.8, 2.7, 2.4, 2.1, 1.8, 1.5 }, wid = .78, mix = .2, z = .09 },
			}
			for ri, row in ipairs(rows) do
				local pv, w = mkPivot(model, torso, CFrame.new(side * .35, .5, .5))
				W.pivots[#W.pivots + 1] = { w = w, side = side, lag = (ri - 1) * .22 }
				for i = 1, row.n do
					local th = math.rad(row.a0 + (row.a1 - row.a0) * (i - 1) / (row.n - 1))
					local d = Vector3.new(side * math.cos(th), math.sin(th), 0)
					local nrm = Vector3.new(-d.Y, d.X, 0)
					local len, wid = row.lens[i] * sc, row.wid * sc
					local b = len * .62
					local z = Vector3.new(0, 0, row.z)
					wpart(model, pv, "Part", Vector3.new(b, wid, .04), CFrame.fromMatrix(d * (b / 2) + z, d, nrm), WHITE, Enum.Material.SmoothPlastic, W.parts, row.mix * .5)
					local tri = triDesc(d * b + nrm * (wid / 2) + z, d * b - nrm * (wid / 2) + z, d * len + z, .04)
					if tri then
						for _, td in ipairs(tri) do wpart(model, pv, "WedgePart", td[1], td[2], WHITE, Enum.Material.Neon, W.parts, row.mix) end
					end
				end
			end
		else
			local pv, w = mkPivot(model, torso, CFrame.new(side * .35, .5, .5))
			W.pivots[#W.pivots + 1] = { w = w, side = side, lag = 0 }
			local function P(x, y) return Vector3.new(side * x * sc, y * sc, 0) end
			local E, Wr = P(1.5, 1.9), P(3.3, 3.0)
			local tips = { P(4.6, 5.8), P(6.4, 4.4), P(6.8, 2.1), P(5.5, .1), P(3.4, -1.5) }
			local B, O = P(.4, -1.8), P(0, 0)
			local dark, edge = Color3.fromRGB(34, 5, 10), WHITE
			local function bone(a, b, th)
				local len = (b - a).Magnitude
				wpart(model, pv, "Part", Vector3.new(th, th, len), CFrame.lookAt((a + b) / 2, b), dark, Enum.Material.SmoothPlastic, W.parts, .5)
			end
			local function memb(a, b, c)
				local tri = triDesc(a, b, c, .05)
				if tri then for _, td in ipairs(tri) do wpart(model, pv, "WedgePart", td[1], td[2], dark, Enum.Material.SmoothPlastic, W.parts, .28) end end
			end
			bone(O, E, .24); bone(E, Wr, .2)
			for i, tp in ipairs(tips) do
				bone(Wr, tp, .14 - i * .008)
				wpart(model, pv, "Part", Vector3.new(.2, .2, .2), CFrame.new(tp), edge, Enum.Material.Neon, W.parts, 1)
			end
			for i = 1, #tips - 1 do memb(Wr, tips[i], tips[i + 1]) end
			memb(Wr, tips[#tips], B); memb(O, Wr, B)
		end
	end
	model.Parent = ch
	fx.wings = W
end

local function destroyAura()
	if fx.aura then
		for _, o in ipairs(fx.aura.objs) do pcall(function() o:Destroy() end) end
		fx.aura = nil
	end
end
local function buildAura(ch)
	destroyAura()
	local hrp, head = ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChild("Head")
	if not hrp then return end
	local a = { objs = {}, ty = F.auraType, beads = {} }
	local function add(o) a.objs[#a.objs + 1] = o; return o end
	add(new("PointLight", { Name = "LxAuraL", Range = 12, Brightness = 1.2, Parent = hrp }))
	a.light = a.objs[1]
	if a.ty == "Sparkles" then
		a.em = add(new("ParticleEmitter", { Rate = 60, Lifetime = NumberRange.new(.9, 1.6), Speed = NumberRange.new(.5, 2.5), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Acceleration = Vector3.new(0, 2, 0), RotSpeed = NumberRange.new(-120, 120),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .6), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .15), NumberSequenceKeypoint.new(1, 1) }), Parent = hrp }))
	elseif a.ty == "Flames" then
		a.fire = add(new("Fire", { Size = 8, Heat = 12, Parent = hrp }))
	else
		local halo = a.ty == "Halo"
		local parent = halo and head or hrp
		if not parent then return end
		local pv = Instance.new("Part")
		pv.Size, pv.Transparency = Vector3.new(.2, .2, .2), 1
		pv.CanCollide, pv.CanQuery, pv.CanTouch, pv.Massless = false, false, false, true
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = parent, pv
		w.Parent = pv
		pv.Parent = ch
		add(pv)
		a.pv, a.w = pv, w
		local n = halo and 24 or 12
		for i = 1, n do
			local ang = i / n * math.pi * 2
			local r = halo and 1.05 or 3.4
			local pos = halo and Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r) or Vector3.new(math.cos(ang) * r, math.sin(ang * 2) * 1.1, math.sin(ang) * r)
			local b = Instance.new("Part")
			b.Size = halo and Vector3.new(.13, .09, .32) or Vector3.new(.42, .42, .42)
			if not halo then b.Shape = Enum.PartType.Ball end
			b.Material, b.Color = Enum.Material.Neon, WHITE
			b.CanCollide, b.CanQuery, b.CanTouch, b.Massless, b.CastShadow = false, false, false, true, false
			local bw = Instance.new("Weld")
			bw.Part0, bw.Part1 = pv, b
			bw.C0 = halo and (CFrame.new(pos) * CFrame.Angles(0, -ang, 0)) or CFrame.new(pos)
			bw.Parent = b
			b.Parent = pv
			a.beads[#a.beads + 1] = b
		end
	end
	fx.aura = a
end

local function trailStep(t, ch, hrp)
	if F.trail then
		if not fx.trail or not fx.trail.Parent or fx.trailOwner ~= ch then
			if fx.trail then
				local a0, a1 = fx.trail.Attachment0, fx.trail.Attachment1
				if a0 then a0:Destroy() end
				if a1 then a1:Destroy() end
				fx.trail:Destroy()
			end
			local a0 = new("Attachment", { Name = "LxT0", Parent = hrp })
			local a1 = new("Attachment", { Name = "LxT1", Parent = hrp })
			fx.trail = new("Trail", { Attachment0 = a0, Attachment1 = a1, LightEmission = 1, FaceCamera = true, MinLength = .05,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .05), NumberSequenceKeypoint.new(1, 1) }),
				WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, .1) }), Parent = hrp })
			fx.trailOwner = ch
		end
		local tr = fx.trail
		tr.Enabled = true
		tr.Lifetime = F.trailLen / 10
		local w = F.trailW * .4
		tr.Attachment0.Position, tr.Attachment1.Position = Vector3.new(0, w / 2, 0), Vector3.new(0, -w / 2, 0)
		if F.trailCol == 10 then
			local k = {}
			for i = 0, 6 do k[#k + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((t * .3 + i * .12) % 1, .85, 1)) end
			tr.Color = ColorSequence.new(k)
		else
			tr.Color = ColorSequence.new(PAL[F.trailCol])
		end
	elseif fx.trail and fx.trail.Parent then
		fx.trail.Enabled = false
	end
end

local bodyStore, colAcc = {}, 0
local MATS = { ForceField = Enum.Material.ForceField, Neon = Enum.Material.Neon, Glass = Enum.Material.Glass, Metal = Enum.Material.Metal, Ice = Enum.Material.Ice }
local function cosStep(dt, t, ch, hrp, hum)
	if wingDirty or (F.wings and (not fx.wings or fx.wings.model.Parent ~= ch)) then
		wingDirty = false
		if F.wings then buildWings(ch) else destroyWings() end
	end
	if not F.wings and fx.wings then destroyWings() end
	if auraDirty or (F.aura and (not fx.aura or fx.aura.objs[1].Parent ~= hrp)) then
		auraDirty = false
		if F.aura then buildAura(ch) else destroyAura() end
	end
	if not F.aura and fx.aura then destroyAura() end

	local W = fx.wings
	if W then
		local sp = F.wingSpeed
		for _, pvt in ipairs(W.pivots) do
			local open = 24 + math.sin(t * sp - pvt.lag * 3) * 16
			pvt.w.C0 = CFrame.new(pvt.side * .35, .5, .5) * CFrame.Angles(0, -pvt.side * math.rad(open), 0)
		end
	end

	colAcc += dt
	local recolor = colAcc > .08
	if recolor then colAcc = 0 end
	if recolor and W then
		local tint = pal(F.wingCol)
		local base = W.demon and Color3.fromRGB(34, 5, 10) or WHITE
		for i, e in ipairs(W.parts) do
			if e[1].Parent then
				local b = (W.demon or e[2] >= 1) and e[3] or base
				e[1].Color = b:Lerp(tint, e[2])
			end
		end
	end
	local A_ = fx.aura
	if A_ then
		local col = pal(F.auraCol)
		if A_.light then A_.light.Color = col end
		if A_.em then A_.em.Color = ColorSequence.new(col) end
		if A_.fire then A_.fire.Color = col; A_.fire.SecondaryColor = col:Lerp(Color3.new(0, 0, 0), .5) end
		if A_.w then
			if A_.ty == "Halo" then
				A_.w.C0 = CFrame.new(0, 1.35 + math.sin(t * 2) * .05, 0) * CFrame.Angles(0, t * 1.4, 0)
			else
				A_.w.C0 = CFrame.Angles(0, t * 2.4, 0) * CFrame.Angles(math.rad(10), 0, 0)
			end
		end
		if recolor then for _, b in ipairs(A_.beads) do b.Color = col end end
	end

	trailStep(t, ch, hrp)

	if F.bodyMat ~= "Off" then
		if recolor then
			local col, mat = pal(F.bodyCol), MATS[F.bodyMat]
			for _, p in ipairs(ch:GetChildren()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and not p.Massless then
					if not bodyStore[p] then bodyStore[p] = { p.Material, p.Color } end
					p.Material, p.Color = mat, col
				end
			end
		end
	elseif next(bodyStore) then
		for p, o in pairs(bodyStore) do if p.Parent then p.Material, p.Color = o[1], o[2] end end
		bodyStore = {}
	end

	if F.selfGlow then
		if not fx.selfHl or fx.selfHl.Parent ~= ch then
			if fx.selfHl then fx.selfHl:Destroy() end
			fx.selfHl = new("Highlight", { Adornee = ch, FillTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded, Parent = ch })
		end
		fx.selfHl.Enabled = true
		fx.selfHl.OutlineColor = pal(F.selfGlowCol)
		fx.selfHl.OutlineTransparency = .1 + .25 * (.5 + .5 * math.sin(t * 3))
	elseif fx.selfHl then
		fx.selfHl.Enabled = false
	end
end

-- ===================== skins =====================
local SKINS = {
	Gold = { c = Color3.fromRGB(255, 196, 70), m = Enum.Material.Metal, r = .35 },
	Ice = { c = Color3.fromRGB(150, 225, 255), m = Enum.Material.Ice, r = .2 },
	Lava = { c = Color3.fromRGB(255, 90, 20), m = Enum.Material.Neon, r = 0 },
	Void = { c = Color3.fromRGB(70, 20, 130), m = Enum.Material.Glass, r = .1 },
	Toxic = { c = Color3.fromRGB(90, 255, 90), m = Enum.Material.Neon, r = 0 },
	Galaxy = { c = Color3.fromRGB(120, 80, 255), m = Enum.Material.Neon, r = 0 },
	Candy = { c = Color3.fromRGB(255, 120, 200), m = Enum.Material.SmoothPlastic, r = .1 },
	Obsidian = { c = Color3.fromRGB(18, 18, 24), m = Enum.Material.Glass, r = .25 },
	Chroma = { rainbow = true, m = Enum.Material.Neon, r = 0 },
}
local function skinColor(name, t)
	local s = SKINS[name]
	if not s then return WHITE end
	return s.rainbow and Color3.fromHSV((t * .25) % 1, .85, 1) or s.c
end
local function splitKeys(str)
	local out = {}
	for k in string.gmatch(string.lower(str or ""), "[^,%s]+") do out[#out + 1] = k end
	return out
end
local function kindOf(name, kk, gk)
	local n = string.lower(name)
	for _, k in ipairs(kk) do if n:find(k, 1, true) then return "knife" end end
	for _, k in ipairs(gk) do if n:find(k, 1, true) then return "gun" end end
end
local skinStore = setmetatable({}, { __mode = "k" })
local skinTick, skinSeen = 0, 0
local function texId(s)
	if not s or s == "" then return nil end
	local n = tonumber(s)
	return n and ("rbxassetid://" .. n) or s
end
local function skinPart(part, name, tex, t)
	local o = skinStore[part]
	if not o then
		local sm = part:FindFirstChildOfClass("SpecialMesh")
		o = { part.Color, part.Material, part.Reflectance, part:IsA("MeshPart") and part.TextureID or nil, sm, sm and sm.TextureId }
		skinStore[part] = o
	end
	local s = SKINS[name]
	local custom = texId(tex)
	if not s and not custom then
		part.Color, part.Material, part.Reflectance = o[1], o[2], o[3]
		if o[4] ~= nil then part.TextureID = o[4] end
		if o[5] then o[5].TextureId = o[6] end
		return
	end
	if s then
		part.Color, part.Material, part.Reflectance = skinColor(name, t), s.m, s.r
	end
	if F.skinStrip and not custom then
		if part:IsA("MeshPart") then part.TextureID = "" end
		if o[5] then o[5].TextureId = "" end
	end
	if custom then
		if part:IsA("MeshPart") then part.TextureID = custom end
		if o[5] then o[5].TextureId = custom end
	end
end
local function skinFxFor(handle, name, kind, t)
	local fxP, tr = handle:FindFirstChild("LxSkinFx"), handle:FindFirstChild("LxSkinTrail")
	local on_ = SKINS[name] ~= nil
	if on_ and F.skinFx then
		if not fxP then
			fxP = new("ParticleEmitter", { Name = "LxSkinFx", Rate = 22, Lifetime = NumberRange.new(.4, .8), Speed = NumberRange.new(.3, 1.2), SpreadAngle = Vector2.new(180, 180),
				LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .25), NumberSequenceKeypoint.new(1, 0) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(1, 1) }), Parent = handle })
		end
		fxP.Color = ColorSequence.new(skinColor(name, t))
	elseif fxP then
		fxP:Destroy()
	end
	if on_ and F.skinTrail and kind == "knife" then
		if not tr then
			local sz = handle.Size
			local ax = (sz.X >= sz.Y and sz.X >= sz.Z) and Vector3.xAxis or ((sz.Y >= sz.Z) and Vector3.yAxis or Vector3.zAxis)
			local half = math.max(sz.X, sz.Y, sz.Z) / 2
			local a0 = new("Attachment", { Name = "LxSA0", Position = ax * half, Parent = handle })
			local a1 = new("Attachment", { Name = "LxSA1", Position = -ax * half, Parent = handle })
			tr = new("Trail", { Name = "LxSkinTrail", Attachment0 = a0, Attachment1 = a1, LightEmission = 1, Lifetime = .25, FaceCamera = true,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .1), NumberSequenceKeypoint.new(1, 1) }), Parent = handle })
		end
		tr.Color = ColorSequence.new(skinColor(name, t))
	elseif tr then
		local a0, a1 = tr.Attachment0, tr.Attachment1
		tr:Destroy()
		if a0 then a0:Destroy() end
		if a1 then a1:Destroy() end
	end
end
local function skinStep(dt, t)
	skinTick += dt
	local rainbow = F.knifeSkin == "Chroma" or F.gunSkin == "Chroma"
	if skinTick < (rainbow and .1 or .5) and skinSeen == skinVer then return end
	skinTick = 0
	skinSeen = skinVer
	local kk, gk = splitKeys(F.knifeKeys), splitKeys(F.gunKeys)
	local targets = {}
	local function scan(parent, rec)
		if not parent then return end
		for _, o in ipairs(parent:GetChildren()) do
			if o:IsA("Tool") or o:IsA("Model") then
				local k = kindOf(o.Name, kk, gk)
				if k then targets[#targets + 1] = { o, k }
				elseif rec and o:IsA("Model") then scan(o, false) end
			end
		end
	end
	scan(lp.Character, false)
	scan(lp:FindFirstChildOfClass("Backpack"), false)
	scan(Workspace.CurrentCamera, true)
	for _, tg in ipairs(targets) do
		local name = tg[2] == "knife" and F.knifeSkin or F.gunSkin
		local tex = tg[2] == "knife" and F.knifeTex or F.gunTex
		local handle
		for _, d in ipairs(tg[1]:GetDescendants()) do
			if d:IsA("BasePart") then
				skinPart(d, name, tex, t)
				if not handle or d.Name == "Handle" then handle = d end
			end
		end
		if handle then skinFxFor(handle, name, tg[2], t) end
	end
end

-- ===================== world / fps =====================
local worldOrig, gradeCC, gradeBloom
local GRADES = {
	Cinematic = { b = .02, c = .22, s = -.08, tint = Color3.fromRGB(255, 238, 220), bloom = .5 },
	Neon = { b = -.02, c = .3, s = .5, tint = Color3.fromRGB(215, 190, 255), bloom = 1.2 },
	Warm = { b = .03, c = .12, s = .25, tint = Color3.fromRGB(255, 215, 170), bloom = .5 },
	Noir = { b = -.02, c = .4, s = -1, tint = Color3.fromRGB(235, 235, 245), bloom = .25 },
	Vivid = { b = .02, c = .2, s = .7, tint = WHITE, bloom = .4 },
}
local lastGrade, lastFull, lastTime, lastFog = "Off", false, false, false
local function worldStep()
	if F.fullbright ~= lastFull then
		lastFull = F.fullbright
		if F.fullbright then
			worldOrig = worldOrig or {}
			worldOrig.fb = { Lighting.Brightness, Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient }
			Lighting.Brightness, Lighting.GlobalShadows = 2, false
			Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170), Color3.fromRGB(170, 170, 170)
		elseif worldOrig and worldOrig.fb then
			Lighting.Brightness, Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient = table.unpack(worldOrig.fb)
		end
	end
	if F.timeOn then
		worldOrig = worldOrig or {}
		worldOrig.time = worldOrig.time or Lighting.ClockTime
		Lighting.ClockTime = F.timeVal
		lastTime = true
	elseif lastTime then
		lastTime = false
		if worldOrig and worldOrig.time then Lighting.ClockTime = worldOrig.time; worldOrig.time = nil end
	end
	if F.noFog ~= lastFog then
		lastFog = F.noFog
		if F.noFog then
			worldOrig = worldOrig or {}
			worldOrig.fog = Lighting.FogEnd
			Lighting.FogEnd = 1e6
		elseif worldOrig and worldOrig.fog then
			Lighting.FogEnd = worldOrig.fog
		end
	end
	if F.grade ~= lastGrade then
		lastGrade = F.grade
		local g = GRADES[F.grade]
		if g then
			if not gradeCC then
				gradeCC = new("ColorCorrectionEffect", { Name = "luxxs_cc", Parent = Lighting })
				gradeBloom = new("BloomEffect", { Name = "luxxs_bloom", Size = 28, Threshold = .9, Parent = Lighting })
			end
			gradeCC.Enabled, gradeBloom.Enabled = true, true
			tw(gradeCC, .9, { Brightness = g.b, Contrast = g.c, Saturation = g.s, TintColor = g.tint })
			tw(gradeBloom, .9, { Intensity = g.bloom })
		elseif gradeCC then
			gradeCC.Enabled, gradeBloom.Enabled = false, false
		end
	end
end

local fpsF = new("Frame", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(190, 26), BackgroundColor3 = C.bg, BackgroundTransparency = .1, BorderSizePixel = 0, Visible = false, ZIndex = 5, Parent = gui })
stroke(fpsF, C.line, 1)
A(new("Frame", { Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0, ZIndex = 6, Parent = fpsF }), "BackgroundColor3")
local fpsT = new("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -12, 1, 0), BackgroundTransparency = 1, Font = F_MONO, TextSize = 12, TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left, Text = "FPS", ZIndex = 6, Parent = fpsF })
drag(fpsF, fpsF)
local fAcc, fCnt, lastCap = 0, 0, nil
local function fpsStep(dt)
	fAcc += dt
	fCnt += 1
	if fAcc >= .25 then
		local fps = math.floor(fCnt / fAcc + .5)
		fAcc, fCnt = 0, 0
		local txt = fps .. " FPS"
		if F.fpsCustom then txt = txt .. "  |  cap " .. F.fps .. (capfn and "" or "*") end
		fpsT.Text = txt
		fpsT.TextColor3 = fps >= 60 and C.text or (fps >= 30 and Color3.fromRGB(255, 190, 70) or C.red)
	end
	fpsF.Visible = F.fpsShow == true
	if capfn then
		local want = F.fpsCustom and F.fps or nil
		if want ~= lastCap then
			lastCap = want
			pcall(capfn, want or 60)
		end
	end
end

-- ===================== preview panel =====================
local PW, PH = 252, H - 54 - 34
local pvp = new("Frame", { Position = UDim2.fromOffset(640, 54), Size = UDim2.fromOffset(PW, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, Parent = main })
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(20, 27, 23), Color3.fromRGB(8, 10, 9)), Rotation = 90, Parent = pvp })
stroke(pvp, C.line, 1)
ticks(pvp, PW, PH, 10, 9)
local function pf(props, z)
	props.BorderSizePixel = 0
	props.ZIndex = z or 1
	return new("Frame", props)
end
local CX, CY = 126, 200
for i, y in ipairs({ 292, 302, 316, 334, 358 }) do
	local f = pf({ Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = .9 - i * .02, Parent = pvp })
	A(f, "BackgroundColor3")
end
for i = -5, 5 do
	local l = pf({ AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = .9, Parent = pvp })
	setLine(l, CX + i * 6, 288, CX + i * 46, PH, 1)
	A(l, "BackgroundColor3")
end
local scanBand = pf({ Size = UDim2.new(1, 0, 0, 40), Parent = pvp }, 2)
A(scanBand, "BackgroundColor3")
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, .8) }), Parent = scanBand })
local scanLine = pf({ Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = .3, Parent = pvp }, 2)
A(scanLine, "BackgroundColor3")
local liveDot = pf({ Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(5, 5), Parent = pvp }, 9)
A(liveDot, "BackgroundColor3")
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 3), Size = UDim2.fromOffset(90, 18), Font = F_MONO, TextSize = 10, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "PREVIEW // LIVE", ZIndex = 9, Parent = pvp })
local aimCap = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 3), Size = UDim2.fromOffset(120, 18), Font = F_MONO, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 9, Parent = pvp })
A(aimCap, "TextColor3")
pf({ Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, Parent = pvp }, 3)
pf({ Position = UDim2.new(0, 0, 1, -26), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Color3.fromRGB(10, 12, 11), BackgroundTransparency = .05, Parent = pvp }, 8)
pf({ Position = UDim2.new(0, 0, 1, -26), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, Parent = pvp }, 9)
local tagsL = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 1, -26), Size = UDim2.new(1, -20, 0, 26), Font = F_MONO, TextSize = 10, TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "NO MODULES", ZIndex = 10, Parent = pvp })

local glows = {}
for i = 1, 4 do
	local s = 240 - i * 40
	local g = pf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX, CY), Size = UDim2.fromOffset(s, s), BackgroundTransparency = .95, Parent = pvp }, 1)
	corner(g, 200)
	glows[i] = g
end
local shadow = pf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX, 312), Size = UDim2.fromOffset(120, 22), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .35, Parent = pvp }, 1)
corner(shadow, 20)
local ring1 = pf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX, 312), Size = UDim2.fromOffset(110, 20), BackgroundTransparency = 1, Parent = pvp }, 1)
corner(ring1, 20)
local ring1S = stroke(ring1, accent, 1.5, .2)
A(ring1S, "Color")
local ring2 = pf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX, 312), Size = UDim2.fromOffset(110, 20), BackgroundTransparency = 1, Parent = pvp }, 1)
corner(ring2, 40)
local ring2S = stroke(ring2, accent, 1, .6)
A(ring2S, "Color")

local particles = {}
do
	local rn = Random.new(5)
	for i = 1, 14 do
		local f = pf({ Size = UDim2.fromOffset(2, 2), Parent = pvp }, 2)
		A(f, "BackgroundColor3")
		particles[i] = { f = f, x = rn:NextInteger(12, 238), y = rn:NextInteger(40, 330), sp = rn:NextInteger(8, 24), ph = rn:NextNumber() * 6 }
	end
end
local fovRing = pf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX, CY), Size = UDim2.fromOffset(100, 100), BackgroundTransparency = 1, Visible = false, Parent = pvp }, 2)
corner(fovRing, 300)
A(stroke(fovRing, accent, 1, .45), "Color")
local tracerP = pf({ AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = 0, Visible = false, Parent = pvp }, 2)

local fig = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX, CY), Size = UDim2.fromOffset(90, 170), BackgroundTransparency = 1, Parent = pvp })
new("UIScale", { Scale = 1.2, Parent = fig })
local body = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = fig })
local function bf(props, z)
	props.BorderSizePixel = 0
	props.ZIndex = z or 3
	props.Parent = body
	return new("Frame", props)
end

local trailF = {}
for k = 1, 14 do
	local f = bf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(12, 10), Visible = false }, 1)
	corner(f, 3)
	trailF[k] = f
end
local angelRows = { { n = 6, a0 = 6, a1 = 74, len = 66, wd = 9 }, { n = 5, a0 = 18, a1 = 100, len = 48, wd = 8 }, { n = 5, a0 = 28, a1 = 114, len = 32, wd = 8 } }
local wingA, wingD = {}, {}
for side = 1, 2 do
	wingA[side], wingD[side] = {}, {}
	for ri, row in ipairs(angelRows) do
		for i = 1, row.n do
			local f = bf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(row.len, row.wd), Visible = false }, 2)
			corner(f, 4)
			new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .05), NumberSequenceKeypoint.new(1, .55) }), Parent = f })
			wingA[side][#wingA[side] + 1] = { f = f, row = ri, i = i, n = row.n, a0 = row.a0, a1 = row.a1, len = row.len }
		end
	end
	for i = 1, 26 do wingD[side][i] = bf({ AnchorPoint = Vector2.new(.5, .5), Visible = false }, 2) end
end
local ZONES = {
	{ n = "Head", x = 33, y = 10, w = 24, h = 24, r = 12, dx = 45, dy = 22 },
	{ n = "Chest", x = 27, y = 40, w = 36, h = 32, r = 4, dx = 45, dy = 56 },
	{ n = "Stomach", x = 30, y = 72, w = 30, h = 20, r = 3, dx = 45, dy = 82 },
	{ n = "Arms", x = 65, y = 42, w = 13, h = 62, r = 5, dx = 72, dy = 75 },
	{ n = "Legs", x = 26, y = 103, w = 17, h = 62, r = 5, dx = 35, dy = 135 },
}
local overlays = {}
for _, z in ipairs(ZONES) do
	local ov = bf({ Position = UDim2.fromOffset(z.x, z.y), Size = UDim2.fromOffset(z.w, z.h), BackgroundTransparency = 1 }, 5)
	A(ov, "BackgroundColor3")
	corner(ov, z.r)
	overlays[z.n] = ov
end
local segs = {}
local function seg(x, y, w, h, r)
	local f = bf({ Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = GRAY }, 3)
	corner(f, r)
	new("UIGradient", { Color = ColorSequence.new(WHITE, Color3.fromRGB(120, 122, 132)), Rotation = 90, Parent = f })
	local s = new("UIStroke", { Thickness = 1, Color = WHITE, Transparency = .78, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
	segs[#segs + 1] = { f = f, s = s }
end
seg(41, 33, 8, 8, 2); seg(33, 10, 24, 24, 12); seg(27, 40, 36, 32, 4); seg(30, 72, 30, 20, 3); seg(28, 91, 34, 12, 3)
seg(13, 42, 12, 32, 5); seg(12, 75, 10, 29, 4); seg(10, 105, 9, 9, 4)
seg(65, 42, 12, 32, 5); seg(68, 75, 10, 29, 4); seg(71, 105, 9, 9, 4)
seg(26, 103, 17, 36, 5); seg(28, 140, 13, 25, 4); seg(24, 165, 19, 5, 2)
seg(47, 103, 17, 36, 5); seg(49, 140, 13, 25, 4); seg(47, 165, 19, 5, 2)
local visor = bf({ Position = UDim2.fromOffset(37, 19), Size = UDim2.fromOffset(16, 5), BackgroundColor3 = Color3.fromRGB(24, 28, 26) }, 4)
corner(visor, 2)
local emblem = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(27, 51), Size = UDim2.fromOffset(36, 14), Font = F_HEAD, TextSize = 8, Text = "LX", ZIndex = 4, Parent = body })
A(emblem, "TextColor3")

local skelF = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Visible = false, Parent = body })
local J = { head = { 45, 22 }, neck = { 45, 38 }, pel = { 45, 98 }, shL = { 27, 46 }, shR = { 63, 46 }, elL = { 18, 76 }, elR = { 72, 76 }, haL = { 14, 108 }, haR = { 76, 108 },
	hipL = { 35, 104 }, hipR = { 55, 104 }, knL = { 34, 140 }, knR = { 56, 140 }, ftL = { 34, 166 }, ftR = { 56, 166 } }
local BP = { { "head", "neck" }, { "neck", "pel" }, { "neck", "shL" }, { "neck", "shR" }, { "shL", "elL" }, { "elL", "haL" }, { "shR", "elR" }, { "elR", "haR" },
	{ "pel", "hipL" }, { "pel", "hipR" }, { "hipL", "knL" }, { "knL", "ftL" }, { "hipR", "knR" }, { "knR", "ftR" } }
local skelParts = {}
for _, b in ipairs(BP) do
	local l = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, ZIndex = 6, Parent = skelF })
	setLine(l, J[b[1]][1], J[b[1]][2], J[b[2]][1], J[b[2]][2], 2)
	skelParts[#skelParts + 1] = l
end
for _, p in pairs(J) do
	local d = new("Frame", { Position = UDim2.fromOffset(p[1] - 2.5, p[2] - 2.5), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = 7, Parent = skelF })
	corner(d, 3)
	skelParts[#skelParts + 1] = d
end

local knifeB = bf({ AnchorPoint = Vector2.new(.5, 1), Position = UDim2.fromOffset(83, 108), Size = UDim2.fromOffset(4, 30), Rotation = 18 }, 7)
corner(knifeB, 2)
local knifeH = bf({ AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromOffset(83, 108), Size = UDim2.fromOffset(5, 9), Rotation = 18, BackgroundColor3 = Color3.fromRGB(70, 70, 76) }, 7)
local knifeS = new("UIStroke", { Thickness = 2, Transparency = 1, Parent = knifeB })
local gunB = bf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(6, 106), Size = UDim2.fromOffset(24, 7), Rotation = -12 }, 7)
corner(gunB, 2)
local gunG = bf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(0, 112), Size = UDim2.fromOffset(6, 11), Rotation = -12 }, 7)
corner(gunG, 2)
local gunS = new("UIStroke", { Thickness = 2, Transparency = 1, Parent = gunB })

local boxF = bf({ Position = UDim2.fromOffset(2, 4), Size = UDim2.fromOffset(86, 166), BackgroundTransparency = 1, Visible = false }, 8)
local boxFS = stroke(boxF, WHITE, 1.5)
local box3F = bf({ Position = UDim2.fromOffset(2, 14), Size = UDim2.fromOffset(76, 156), BackgroundTransparency = 1, Visible = false }, 8)
local box3FS = stroke(box3F, WHITE, 1.5)
local box3B = bf({ Position = UDim2.fromOffset(14, 4), Size = UDim2.fromOffset(76, 156), BackgroundTransparency = 1, Visible = false }, 8)
local box3BS = stroke(box3B, WHITE, 1.5)
local box3L = {}
for i = 1, 4 do box3L[i] = bf({ AnchorPoint = Vector2.new(.5, .5), Visible = false }, 8) end
local function pLabel(sz, font, txt)
	return new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(130, 13), Font = font, TextSize = sz, Text = txt, TextStrokeTransparency = .5, ZIndex = 9, Visible = false, Parent = fig })
end
local pName, pDist, pTool = pLabel(10, F_MONO, "PLAYER"), pLabel(8, F_MONO, "[42m]"), pLabel(8, F_MONO, "Knife")
pTool.TextColor3 = Color3.fromRGB(255, 220, 120)
local hpBg = bf({ Position = UDim2.fromOffset(-5, 4), Size = UDim2.fromOffset(3, 166), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .3, Visible = false }, 8)
local hpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, .7), BackgroundColor3 = Color3.fromRGB(90, 230, 110), BorderSizePixel = 0, Parent = hpBg })
local pHead = bf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(45, 22), Size = UDim2.fromOffset(7, 7), Visible = false }, 10)
corner(pHead, 4)
local pArrow = new("TextLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(26, 56), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Text = "▲", Font = Enum.Font.GothamBold,
	TextSize = 20, Rotation = -40, Visible = false, ZIndex = 9, Parent = pvp })
local spinL = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(CX + 62, 70), Size = UDim2.fromOffset(30, 30), Text = "↻", Font = Enum.Font.GothamBold, TextSize = 24, Visible = false, ZIndex = 9, Parent = pvp })
A(spinL, "TextColor3")

local sparks = {}
for i = 1, 12 do
	local f = bf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(4, 4), Visible = false }, 6)
	corner(f, 3)
	sparks[i] = f
end
local haloP = bf({ AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(45, -4), Size = UDim2.fromOffset(34, 8), BackgroundTransparency = 1, Visible = false }, 9)
corner(haloP, 10)
local haloS = stroke(haloP, WHITE, 2)

local aimUI = {}
for _, z in ipairs(ZONES) do
	local b = new("TextButton", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(z.dx, z.dy), Size = UDim2.fromOffset(11, 11), BackgroundColor3 = Color3.fromRGB(230, 235, 232),
		BackgroundTransparency = .45, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 12, Parent = body })
	corner(b, 6)
	local ds = stroke(b, WHITE, 1, .55)
	local u = { z = z, b = b, s = ds, hover = false }
	on(b.MouseEnter, function() u.hover = true end)
	on(b.MouseLeave, function() u.hover = false end)
	on(b.MouseButton1Click, function() SET.aimPart(z.n) end)
	aimUI[#aimUI + 1] = u
end
local aimAura = bf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = .8 }, 12)
A(aimAura, "BackgroundColor3")
corner(aimAura, 14)
local aimDot = bf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(7, 7) }, 14)
A(aimDot, "BackgroundColor3")
corner(aimDot, 4)
local ret = {}
for i = 1, 4 do
	ret[i] = bf({ AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(i <= 2 and 6 or 1, i <= 2 and 1 or 6) }, 14)
	A(ret[i], "BackgroundColor3")
end

local aimX, aimY, boxTop = 45, 22, 4
local tagAcc, flyOff, spinRot = 0, 0, 0
local SKIN_PREV_BASE = Color3.fromRGB(150, 152, 160)

local function previewStep(dt, t)
	local pulse = (math.sin(t * 1.4) + 1) / 2
	local bc, sc, cc, gc, hc, ac = pal(F.boxCol), pal(F.skelCol), pal(F.chamCol), pal(F.glowCol), pal(F.headCol), pal(F.arrowCol)

	for i, g in ipairs(glows) do g.BackgroundColor3 = accent; g.BackgroundTransparency = .955 - i * .006 - pulse * .01 end
	liveDot.BackgroundTransparency = pulse * .7
	local ys = 30 + ((t * .33) % 1) * 300
	scanLine.Position = UDim2.fromOffset(0, ys)
	scanBand.Position = UDim2.fromOffset(0, ys - 40)
	local rp_ = (t * .55) % 1
	ring2.Size = UDim2.fromOffset(90 + rp_ * 100, 16 + rp_ * 26)
	ring2S.Transparency = .3 + rp_ * .7
	for _, p in ipairs(particles) do
		p.y -= p.sp * dt
		if p.y < 30 then p.y = 340; p.x = math.random(12, 238) end
		p.f.Position = UDim2.fromOffset(p.x + math.sin(t * .8 + p.ph) * 6, p.y)
		p.f.BackgroundTransparency = 1 - ((p.y - 30) / 310) * .55
	end

	flyOff += ((F.fly and -16 or 0) - flyOff) * math.clamp(dt * 8, 0, 1)
	body.Position = UDim2.fromOffset(0, math.sin(t * 2) * 1.5 + flyOff)
	shadow.Size = UDim2.fromOffset(120 + flyOff * 2, 22 + flyOff * .4)
	shadow.BackgroundTransparency = .35 - flyOff * .01
	spinL.Visible = F.spin == true
	if F.spin then spinRot += dt * (60 + F.spinSpeed * .9); spinL.Rotation = spinRot % 360 end

	local ecol = bc
	local b2, b3 = F.box and F.boxType == "2D", F.box and F.boxType == "3D"
	boxF.Visible = b2; boxFS.Color = ecol
	box3F.Visible, box3B.Visible = b3, b3
	box3FS.Color, box3BS.Color = ecol, ecol
	for i = 1, 4 do
		if b3 then
			local fx_, fy_ = 2 + (i % 2) * 76, 14 + (i > 2 and 156 or 0)
			setLine(box3L[i], fx_ + 6, fy_ - 5, fx_ + 6, fy_ - 5, 1.5, ecol)
			setLine(box3L[i], fx_, fy_, fx_ + 12, fy_ - 10, 1.5, ecol)
		else box3L[i].Visible = false end
	end
	pName.Visible = F.name == true; pName.TextColor3 = ecol; pName.Position = UDim2.fromOffset(-20, boxTop - 15)
	pDist.Visible = F.dist == true; pDist.TextColor3 = WHITE; pDist.Position = UDim2.fromOffset(-20, 172)
	pTool.Visible = F.tool == true; pTool.Position = UDim2.fromOffset(-20, F.dist and 183 or 172)
	hpBg.Visible = F.hp == true
	hpFill.Size = UDim2.fromScale(1, .7 + math.sin(t) * .2)
	if F.tracer then setLine(tracerP, CX + 90, PH - 34, CX, 306, 1.2, ecol) else tracerP.Visible = false end
	pHead.Visible = F.headDot == true; pHead.BackgroundColor3 = hc
	pArrow.Visible = F.arrows == true; pArrow.TextColor3 = ac; pArrow.TextTransparency = .1 + .4 * pulse
	skelF.Visible = F.skel == true
	if F.skel then for _, s in ipairs(skelParts) do s.BackgroundColor3 = sc end end

	local chams, glowOn = F.chams, F.glow
	for _, s in ipairs(segs) do
		if chams then s.f.BackgroundColor3, s.f.BackgroundTransparency = cc, .25
		elseif F.bodyMat ~= "Off" then s.f.BackgroundColor3, s.f.BackgroundTransparency = pal(F.bodyCol), .12
		else s.f.BackgroundColor3, s.f.BackgroundTransparency = GRAY, 0 end
		if glowOn then s.s.Color, s.s.Transparency, s.s.Thickness = gc, .05, 2
		elseif F.selfGlow then s.s.Color, s.s.Transparency, s.s.Thickness = pal(F.selfGlowCol), .15 + .3 * pulse, 2
		else s.s.Color, s.s.Transparency, s.s.Thickness = WHITE, .78, 1 end
	end
	visor.BackgroundColor3 = chams and Color3.fromRGB(16, 20, 18) or Color3.fromRGB(24, 28, 26)

	local kS, gS = SKINS[F.knifeSkin], SKINS[F.gunSkin]
	local kc = kS and skinColor(F.knifeSkin, t) or SKIN_PREV_BASE
	local gcl = gS and skinColor(F.gunSkin, t) or SKIN_PREV_BASE
	knifeB.BackgroundColor3, gunB.BackgroundColor3, gunG.BackgroundColor3 = kc, gcl, gcl:Lerp(Color3.new(0, 0, 0), .35)
	knifeS.Color, gunS.Color = kc, gcl
	knifeS.Transparency = (kS and kS.m == Enum.Material.Neon) and .35 or 1
	gunS.Transparency = (gS and gS.m == Enum.Material.Neon) and .35 or 1

	local wingsOn = F.wings
	local demon = F.wingType == "Demon"
	local flap = math.sin(t * F.wingSpeed) * 9
	local tint = pal(F.wingCol)
	local ws = (F.wingSize or 100) / 100
	for side = 1, 2 do
		local sg = side == 1 and -1 or 1
		local bx, by = 45 + sg * 8, 50
		for _, w in ipairs(wingA[side]) do
			if wingsOn and not demon then
				local a = math.rad(w.a0 + (w.a1 - w.a0) * (w.i - 1) / (w.n - 1) + flap * (.4 + w.row * .25))
				local L = w.len * ws
				local dx, dy = sg * math.cos(a), -math.sin(a)
				w.f.Visible = true
				w.f.Size = UDim2.fromOffset(L, w.f.Size.Y.Offset)
				w.f.Position = UDim2.fromOffset(bx + dx * L / 2, by + dy * L / 2)
				w.f.Rotation = math.deg(math.atan2(dy, dx))
				w.f.BackgroundColor3 = WHITE:Lerp(tint, ({ .65, .4, .18 })[w.row])
			else w.f.Visible = false end
		end
		local ln = wingD[side]
		if wingsOn and demon then
			local function P(x, y) return bx + sg * x * 9 * ws, by - (y + flap * .05 * x) * 9 * ws end
			local ox, oy = P(0, 0)
			local ex, ey = P(1.5, 1.9)
			local wx, wy = P(3.3, 3.0)
			local tips = { { P(4.6, 5.8) }, { P(6.4, 4.4) }, { P(6.8, 2.1) }, { P(5.5, .1) }, { P(3.4, -1.5) } }
			local idx = 1
			local function L(x1, y1, x2, y2, th, col, tr)
				local f = ln[idx]
				idx += 1
				if f then setLine(f, x1, y1, x2, y2, th, col); f.BackgroundTransparency = tr end
			end
			local dark = Color3.fromRGB(34, 5, 10)
			for g = 1, #tips - 1 do
				for k = 0, 3 do
					local tx = tips[g][1] + (tips[g + 1][1] - tips[g][1]) * k / 3
					local ty = tips[g][2] + (tips[g + 1][2] - tips[g][2]) * k / 3
					if idx <= 16 then L(wx, wy, tx, ty, 6, dark:Lerp(tint, .28), .1) end
				end
			end
			idx = 17
			L(ox, oy, ex, ey, 3, dark:Lerp(tint, .5), 0); L(ex, ey, wx, wy, 2.5, dark:Lerp(tint, .5), 0)
			for _, tp in ipairs(tips) do if idx <= 26 then L(wx, wy, tp[1], tp[2], 1.8, tint, 0) end end
			for i = idx, 26 do ln[i].Visible = false end
		else
			for _, f in ipairs(ln) do f.Visible = false end
		end
	end

	local aOn, aT, aCol = F.aura, F.auraType, pal(F.auraCol)
	haloP.Visible = aOn and aT == "Halo"
	if haloP.Visible then haloP.BackgroundTransparency = 1; haloS.Color = aCol; haloP.Position = UDim2.fromOffset(45, -2 + math.sin(t * 2) * 2) end
	for i, f in ipairs(sparks) do
		if aOn and aT ~= "Halo" then
			local ph = i * .53
			f.Visible = true
			f.BackgroundColor3 = aCol
			if aT == "Vortex" then
				local a = t * 2.4 + i / #sparks * math.pi * 2
				f.Position = UDim2.fromOffset(45 + math.cos(a) * 52, 98 + math.sin(a) * 14 + math.sin(a * 2) * 10)
				f.Size = UDim2.fromOffset(6, 6)
				f.BackgroundTransparency = .1 + (math.sin(a) + 1) * .15
			elseif aT == "Flames" then
				local k = (t * .9 + ph) % 1
				f.Position = UDim2.fromOffset(45 + math.sin(t * 3 + ph * 4) * (28 - k * 18), 168 - k * 130)
				f.Size = UDim2.fromOffset(9 - k * 7, 9 - k * 7)
				f.BackgroundColor3 = aCol:Lerp(Color3.fromRGB(255, 255, 255), k * .5)
				f.BackgroundTransparency = .1 + k * .9
			else
				local k = (t * .35 + ph) % 1
				f.Position = UDim2.fromOffset(45 + math.sin(t * 1.3 + ph * 5) * (30 + i * 3), 170 - k * 175)
				f.Size = UDim2.fromOffset(4, 4)
				f.BackgroundTransparency = .1 + .9 * k
			end
		else f.Visible = false end
	end

	local n = F.trail and math.clamp(math.floor(F.trailLen / 30 * 14) + 3, 3, 14) or 0
	for k, f in ipairs(trailF) do
		local show = k <= n
		f.Visible = show
		if show then
			local fall = k / n
			f.Position = UDim2.fromOffset(18 - k * 8, 100 + math.sin(t * 4 + k * .6) * 4 * fall)
			f.Size = UDim2.fromOffset(12, math.max(2, F.trailW * 2.4 * (1 - fall * .85)))
			f.BackgroundTransparency = .1 + fall * .85
			f.BackgroundColor3 = F.trailCol == 10 and Color3.fromHSV((t * .3 - k * .04) % 1, .85, 1) or PAL[F.trailCol]
		end
	end

	fovRing.Visible = (F.aim and F.fovShow) == true
	if fovRing.Visible then
		local r = 26 + (F.fov - 30) / 470 * 90
		fovRing.Size = UDim2.fromOffset(r * 2, r * 2)
	end
	local sel
	for _, z in ipairs(ZONES) do if z.n == F.aimPart then sel = z end end
	for nme, ov in pairs(overlays) do ov.BackgroundTransparency = (nme == F.aimPart) and (.7 - .15 * pulse) or 1 end
	if sel then
		local k = math.clamp(dt * 9, 0, 1)
		aimX += (sel.dx - aimX) * k
		aimY += (sel.dy - aimY) * k
	end
	aimDot.Position = UDim2.fromOffset(aimX, aimY)
	aimAura.Position = UDim2.fromOffset(aimX, aimY)
	aimAura.Size = UDim2.fromOffset(22 + pulse * 8, 22 + pulse * 8)
	local g = 7 + pulse * 3
	ret[1].Position = UDim2.fromOffset(aimX - g - 3, aimY); ret[2].Position = UDim2.fromOffset(aimX + g + 3, aimY)
	ret[3].Position = UDim2.fromOffset(aimX, aimY - g - 3); ret[4].Position = UDim2.fromOffset(aimX, aimY + g + 3)
	for _, u in ipairs(aimUI) do
		if u.z.n == F.aimPart then u.b.BackgroundTransparency = 1; u.s.Transparency = 1
		elseif u.hover then u.b.BackgroundColor3 = accent; u.b.BackgroundTransparency = .25; u.b.Size = UDim2.fromOffset(13, 13); u.s.Transparency = .2
		else u.b.BackgroundColor3 = Color3.fromRGB(230, 235, 232); u.b.BackgroundTransparency = .45; u.b.Size = UDim2.fromOffset(11, 11); u.s.Transparency = .55 end
	end
	aimCap.Text = F.aim and ("AIM / " .. string.upper(tostring(F.aimPart))) or "AIM OFF"

	tagAcc += dt
	if tagAcc >= .3 then
		tagAcc = 0
		local tg = {}
		local function add(k, nme) if F[k] then tg[#tg + 1] = nme end end
		add("box", "BOX"); add("name", "NAME"); add("hp", "HP"); add("dist", "DIST"); add("tracer", "TRC"); add("skel", "SKEL"); add("chams", "CHAMS"); add("glow", "GLOW")
		add("headDot", "HEAD"); add("tool", "WPN"); add("arrows", "ARR"); add("wings", "WINGS"); add("aura", "AURA"); add("trail", "TRAIL"); add("fly", "FLY"); add("spin", "SPIN"); add("noclip", "NC")
		if F.aim then tg[#tg + 1] = "AIM" end
		if F.knifeSkin ~= "Off" or F.gunSkin ~= "Off" then tg[#tg + 1] = "SKIN" end
		tagsL.Text = #tg > 0 and table.concat(tg, " / ") or "NO MODULES"
	end
end

-- ===================== master loops =====================
local dotsM = {}
do
	local rn = Random.new(21)
	for i = 1, 14 do
		local f = new("Frame", { Size = UDim2.fromOffset(rn:NextInteger(2, 4), rn:NextInteger(2, 4)), BorderSizePixel = 0, ZIndex = 0, Parent = pages })
		A(f, "BackgroundColor3")
		corner(f, 2)
		f.BackgroundTransparency = .6 + rn:NextNumber() * .3
		dotsM[i] = { f, rn:NextNumber(), rn:NextNumber(), .008 + rn:NextNumber() * .02, (rn:NextNumber() - .5) * .02 }
	end
end

on(RS.RenderStepped, function(dt)
	if dead then return end
	local cam = Workspace.CurrentCamera
	local t = os.clock()
	if cam then
		pcall(espStep, cam, t)
		pcall(screenStep, cam)
		if F.camFov then cam.FieldOfView = F.fovVal end
	end
	pcall(fpsStep, dt)
	pcall(worldStep)
	iconGrad.Rotation = (t * 120) % 360
	iconGlow.Transparency = .75 + .15 * math.sin(t * 2.5)
	brandStroke.Transparency = .6 + .25 * math.sin(t * 2)
	if opened then
		mainGrad.Rotation = (t * 45) % 360
		for _, d in ipairs(dotsM) do d[1].Position = UDim2.fromScale((d[2] + t * d[5]) % 1, (d[3] - t * d[4]) % 1) end
		pcall(previewStep, dt, t)
	end
end)

on(RS.Heartbeat, function(dt)
	if dead then return end
	local t = os.clock()
	local ch = lp.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if ch ~= fx.char then
		fx.char = ch
		wingDirty, auraDirty = true, true
		fly.on = false
		bodyStore = {}
	end
	if hrp and hum and hum.Health > 0 then
		pcall(moveStep, dt, t, ch, hrp, hum)
		pcall(cosStep, dt, t, ch, hrp, hum)
	end
	pcall(skinStep, dt, t)
end)

-- ===================== unload =====================
unload = function()
	if dead then return end
	dead = true
	pcall(function() RS:UnbindFromRenderStep("LuxxsAim") end)
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	local ch = lp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	flyStop(hum)
	spinClear(hum)
	destroyWings(); destroyAura()
	if fx.trail then
		local a0, a1 = fx.trail.Attachment0, fx.trail.Attachment1
		fx.trail:Destroy()
		if a0 then a0:Destroy() end
		if a1 then a1:Destroy() end
	end
	if fx.selfHl then fx.selfHl:Destroy() end
	for p, o in pairs(bodyStore) do if p.Parent then p.Material, p.Color = o[1], o[2] end end
	for part, o in pairs(skinStore) do
		if part.Parent then
			part.Color, part.Material, part.Reflectance = o[1], o[2], o[3]
			if o[4] ~= nil then part.TextureID = o[4] end
			if o[5] then o[5].TextureId = o[6] end
			for _, n in ipairs({ "LxSkinFx", "LxSkinTrail", "LxSA0", "LxSA1" }) do
				local x = part:FindFirstChild(n)
				if x then x:Destroy() end
			end
		end
	end
	for p in pairs(esp) do killEsp(p) end
	for _, h in pairs(hls) do pcall(function() h:Destroy() end) end
	for _, p in ipairs(plist) do
		local hr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local pl = hr and hr:FindFirstChild("LxGlow")
		if pl then pl:Destroy() end
	end
	if hum then hum.WalkSpeed = 16; hum.PlatformStand = false; hum.AutoRotate = true end
	if savedGrav then Workspace.Gravity = savedGrav end
	if worldOrig then
		if worldOrig.fb then Lighting.Brightness, Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient = table.unpack(worldOrig.fb) end
		if worldOrig.time then Lighting.ClockTime = worldOrig.time end
		if worldOrig.fog then Lighting.FogEnd = worldOrig.fog end
	end
	if gradeCC then gradeCC:Destroy(); gradeBloom:Destroy() end
	if capfn then pcall(capfn, 60) end
	gui:Destroy(); espGui:Destroy()
end

-- ===================== start =====================
fit()
selectTab(tabs[1])
applyAlpha()
task.wait(.3)
openMenu()
notify("luxxs v5.1 loaded")
