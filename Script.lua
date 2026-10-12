-- MALLHI HUB | STAGED LOADER (Optimized & Redesigned)
local PHASE = 4
local START_DELAY = 1
local STAGE_PAUSE = 1

task.spawn(function()
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local G = (getgenv and getgenv()) or _G

pcall(function() if G.MALLHI_KILL then G.MALLHI_KILL() end end)

local alive = true
local conns = {}
local function bind(signal, fn)
local c = signal:Connect(fn)
conns[#conns + 1] = c
return c
end

G.MALLHI_KILL = function()
alive = false
for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
pcall(function() RunService:UnbindFromRenderStep("MallhiAim") end)
pcall(function() RunService:UnbindFromRenderStep("MallhiFollow") end)
local s = G.MALLHI_SILENT
if s then s.on = false; s.pos = nil; s.target = nil end
end

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(START_DELAY)

do
local t0 = os.clock()
repeat
task.wait(0.5)
until (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) or os.clock() - t0 > 20
task.wait(1)
end

pcall(function()
local roots = {}
pcall(function() if gethui then roots[#roots + 1] = gethui() end end)
pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
local pg = lp:FindFirstChild("PlayerGui")
if pg then roots[#roots + 1] = pg end
for _, p in ipairs(roots) do
for _, n in ipairs({"MallhiHub", "MallhiFly", "MallhiESP"}) do
local o = p:FindFirstChild(n)
if o then o:Destroy() end
end
end
end)

local state = {airJump=false, airJumpPower=50, lastAirJump=0, infJump=false, speedOn=false, speedMult=1.4, speedMode="Velocity", fly=false, flySpeed=60, noclip=false}
local aim = {on=false, alwaysOn=false, smooth=35, maxDist=500, part="Head", teamCheck=true, wallCheck=true, prediction=0, rotateBody=true, lockedUntil=0, camGame=nil, dir=nil}

local silent = G.MALLHI_SILENT or {}
G.MALLHI_SILENT = silent
silent.on = false
silent.fov = 150
silent.range = 1000
silent.hitChance = 100
silent.part = "Head"
silent.showFov = true
silent.target = nil
silent.pos = nil
silent.legacyMouse = false
silent.redirects = silent.redirects or 0
silent.hookState = silent.hookState or "off"

local esp = {on=false, chams=true, names=true, distance=true, health=true, teammates=false, visCheck=true, maxDist=1000, fill=0.8, enemyColor=Color3.fromRGB(240,240,240), visibleColor=Color3.fromRGB(255,255,255), teamColor=Color3.fromRGB(120,120,120)}
local baseSpeed = 16
local gunPosState = {on=false, x=0, y=0, z=0}
local gunMode = "Stable"

local flyGui, upBtn, downBtn
local installSilentHooks, installMouseHook

local function getH() local c = lp.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function getR() local c = lp.Character return c and c:FindFirstChild("HumanoidRootPart") end

local markedChars = {}
local TEAM_ATTRS = {"Team", "TeamId", "TeamName", "TeamColor", "GroupId", "Faction"}

task.spawn(function()
while alive do
task.wait(2)
if not (aim.on or esp.on or silent.on) then continue end
local found = {}
for _, p in ipairs(Players:GetPlayers()) do
local c = p.Character
if p ~= lp and c then
local head = c:FindFirstChild("Head")
for _, group in ipairs({c, head or c}) do
for _, d in ipairs(group:GetChildren()) do
if d:IsA("BillboardGui") and d.Enabled then
found[c] = true
break
end
end
if found[c] then break end
end
end
end
markedChars = found
end
end)

local function sameTeam(p)
if p.Character and markedChars[p.Character] then return true end
for _, attr in ipairs(TEAM_ATTRS) do
local pa, ta = lp:GetAttribute(attr), p:GetAttribute(attr)
if pa ~= nil and pa == ta then return true end
local ca = lp.Character and lp.Character:GetAttribute(attr)
local cb = p.Character and p.Character:GetAttribute(attr)
if ca ~= nil and ca == cb then return true end
end
if lp.Team and p.Team and lp.Team == p.Team then return true end
return false
end

local function getParent()
local p
pcall(function() p = gethui and gethui() end)
if not p then pcall(function() p = game:GetService("CoreGui") end) end
if not p then p = lp:WaitForChild("PlayerGui") end
return p
end

local function parentGui(g)
local ok = pcall(function() g.Parent = getParent() end)
if not ok or not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
end

-- PURE BLACK & WHITE MINIMALIST THEME
local BW = {
bg = Color3.fromRGB(8, 8, 8),
card = Color3.fromRGB(16, 16, 16),
row = Color3.fromRGB(24, 24, 24),
accent = Color3.fromRGB(255, 255, 255),
text = Color3.fromRGB(240, 240, 240),
dim = Color3.fromRGB(130, 130, 130),
off = Color3.fromRGB(45, 45, 45),
}

local function round(inst, r)
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, r)
c.Parent = inst
return c
end

local function isPtr(i)
return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end

local function newLabel(parent, text, size, pos, color, font, align)
local l = Instance.new("TextLabel")
l.Size = size
l.Position = pos
l.BackgroundTransparency = 1
l.Text = text
l.TextColor3 = color or BW.text
l.TextSize = 12
l.Font = font or Enum.Font.GothamMedium
l.TextXAlignment = align or Enum.TextXAlignment.Left
l.Parent = parent
return l
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MallhiHub"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
parentGui(screenGui)

-- SLEEK PILL TOGGLE BUTTON
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(130, 42)
toggleBtn.Position = UDim2.fromOffset(16, 16)
toggleBtn.BackgroundColor3 = BW.card
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "MALLHI HUB"
toggleBtn.TextColor3 = BW.accent
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 100
toggleBtn.Parent = screenGui
round(toggleBtn, 21)

local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color = BW.accent
btnStroke.Thickness = 1.2
btnStroke.Transparency = 0.3

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(420, 300)
mainFrame.Position = UDim2.fromOffset(160, 20)
mainFrame.BackgroundColor3 = BW.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui
round(mainFrame, 12)

local winStroke = Instance.new("UIStroke", mainFrame)
winStroke.Thickness = 1.2
winStroke.Color = BW.accent
winStroke.Transparency = 0.25

local HEAD_H = 42
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEAD_H)
header.BackgroundColor3 = BW.card
header.BorderSizePixel = 0
header.Parent = mainFrame

newLabel(header, "MALLHI HUB", UDim2.fromOffset(150, 20), UDim2.fromOffset(16, 6), BW.accent, Enum.Font.GothamBold)
newLabel(header, "v2.0 // stable core", UDim2.fromOffset(180, 14), UDim2.fromOffset(16, 23), BW.dim, Enum.Font.Gotham, Enum.TextXAlignment.Left)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 7)
closeBtn.BackgroundColor3 = BW.row
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = BW.accent
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
round(closeBtn, 8)

local CONTENT_H = 300 - HEAD_H - 12
local CONTENT_W = 420 - 108

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.fromOffset(92, CONTENT_H)
sidebar.Position = UDim2.fromOffset(6, HEAD_H + 6)
sidebar.BackgroundColor3 = BW.card
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
round(sidebar, 8)

local tabs, tabCount, firstTab = {}, 0, nil
local pageY = {}

local function selectTab(name)
for n, t in pairs(tabs) do
local on = (n == name)
if on and not t.built then
t.built = true
local ok, err = pcall(t.builder, t.page)
if not ok then warn("[MALLHIHUB] page build failed: " .. tostring(err)) end
end
t.page.Visible = on
t.btn.BackgroundColor3 = on and BW.accent or BW.row
t.btn.TextColor3 = on and BW.bg or BW.dim
end
end

local function createCategory(title, builder)
tabCount += 1
local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(84, 32)
btn.Position = UDim2.fromOffset(4, 4 + (tabCount - 1) * 36)
btn.BackgroundColor3 = BW.row
btn.BorderSizePixel = 0
btn.Text = title
btn.TextColor3 = BW.dim
btn.TextSize = 11
btn.Font = Enum.Font.GothamBold
btn.AutoButtonColor = false
btn.Parent = sidebar
round(btn, 6)

local page = Instance.new("ScrollingFrame")
page.Size = UDim2.fromOffset(CONTENT_W, CONTENT_H)
page.Position = UDim2.fromOffset(102, HEAD_H + 6)
page.BackgroundTransparency = 1
page.BorderSizePixel = 0
page.ScrollBarThickness = 2
page.ScrollBarImageColor3 = BW.accent
page.CanvasSize = UDim2.fromOffset(0, 0)
page.ScrollingDirection = Enum.ScrollingDirection.Y
page.Visible = false
page.Parent = mainFrame
pageY[page] = 0

tabs[title] = {btn = btn, page = page, builder = builder, built = false}
btn.MouseButton1Click:Connect(function() selectTab(title) end)
if not firstTab then firstTab = title end
end

local function place(page, h)
local y = pageY[page] or 0
pageY[page] = y + h + 6
page.CanvasSize = UDim2.fromOffset(0, y + h + 6)
return y
end

local function newRow(page, h)
local y = place(page, h)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, -8, 0, h)
row.Position = UDim2.fromOffset(0, y)
row.BackgroundColor3 = BW.row
row.BorderSizePixel = 0
row.Parent = page
round(row, 6)
return row
end

local function addToggle(page, text, default, cb)
local row = newRow(page, 36)
newLabel(row, text, UDim2.new(1, -60, 1, 0), UDim2.fromOffset(12, 0))

local track = Instance.new("Frame")
track.Size = UDim2.fromOffset(38, 20)
track.Position = UDim2.new(1, -48, 0.5, -10)
track.BorderSizePixel = 0
track.Parent = row
round(track, 10)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(16, 16)
knob.BorderSizePixel = 0
knob.Parent = track
round(knob, 8)

local val = default
local function render(v)
track.BackgroundColor3 = v and BW.accent or BW.off
knob.BackgroundColor3 = v and BW.bg or BW.accent
knob.Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
end
render(val)

local b = Instance.new("TextButton")
b.Size = UDim2.new(1, 0, 1, 0)
b.BackgroundTransparency = 1
b.Text = ""
b.Parent = row
b.MouseButton1Click:Connect(function()
val = not val
render(val)
cb(val)
end)
return {Set = function(_, v) val = v; render(v); cb(v) end}
end

local function addSlider(page, text, min, max, default, suffix, cb)
local row = newRow(page, 50)
newLabel(row, text, UDim2.new(0.6, 0, 0, 20), UDim2.fromOffset(12, 6))
local vl = newLabel(row, tostring(default) .. (suffix or ""), UDim2.new(0.4, -12, 0, 20), UDim2.new(0.6, 0, 0, 6), BW.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)

local sb = Instance.new("Frame")
sb.Size = UDim2.new(1, -24, 0, 5)
sb.Position = UDim2.fromOffset(12, 36)
sb.BackgroundColor3 = BW.off
sb.BorderSizePixel = 0
sb.Parent = row
round(sb, 2)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
fill.BackgroundColor3 = BW.accent
fill.BorderSizePixel = 0
fill.Parent = sb
round(fill, 2)

local dragging = false
local function upd(input)
local w = sb.AbsoluteSize.X
if w == 0 then return end
local ratio = math.clamp((input.Position.X - sb.AbsolutePosition.X) / w, 0, 1)
local v = math.floor(min + (max - min) * ratio + 0.5)
fill.Size = UDim2.fromScale(ratio, 1)
vl.Text = tostring(v) .. (suffix or "")
cb(v)
end

local b = Instance.new("TextButton")
b.Size = UDim2.new(1, 0, 0, 28)
b.Position = UDim2.fromOffset(0, 22)
b.BackgroundTransparency = 1
b.Text = ""
b.Parent = row
b.InputBegan:Connect(function(i)
if isPtr(i) then
dragging = true
page.ScrollingEnabled = false
upd(i)
end
end)
b.InputEnded:Connect(function(i)
if isPtr(i) then
dragging = false
page.ScrollingEnabled = true
end
end)
bind(UIS.InputChanged, function(i)
if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then upd(i) end
end)

return {Set = function(_, v)
fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
vl.Text = tostring(v) .. (suffix or "")
cb(v)
end}
end

local function addDropdown(page, text, options, default, cb)
local row = newRow(page, 36)
newLabel(row, text, UDim2.new(0.5, 0, 1, 0), UDim2.fromOffset(12, 0))
local sl = newLabel(row, tostring(default) .. " ▾", UDim2.new(0.5, -12, 1, 0), UDim2.new(0.5, 0, 0, 0), BW.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)

local idx = table.find(options, default) or 1
local b = Instance.new("TextButton")
b.Size = UDim2.new(1, 0, 1, 0)
b.BackgroundTransparency = 1
b.Text = ""
b.Parent = row
b.MouseButton1Click:Connect(function()
idx = idx % #options + 1
sl.Text = tostring(options[idx]) .. " ▾"
cb(options[idx])
end)
return {Set = function(_, v) sl.Text = tostring(v) .. " ▾"; cb(v) end}
end

local function addButton(page, text, cb)
local y = place(page, 34)
local b = Instance.new("TextButton")
b.Size = UDim2.new(1, -8, 0, 34)
b.Position = UDim2.fromOffset(0, y)
b.BackgroundColor3 = BW.accent
b.BorderSizePixel = 0
b.Text = text
b.TextColor3 = BW.bg
b.TextSize = 12
b.Font = Enum.Font.GothamBold
b.AutoButtonColor = false
b.Parent = page
round(b, 6)
b.MouseButton1Click:Connect(cb)
end

createCategory("Aimbot", function(page)
addToggle(page, "Enabled", false, function(v) aim.on = v end)
addToggle(page, "Always On", false, function(v) aim.alwaysOn = v end)
addToggle(page, "Wall Check", true, function(v) aim.wallCheck = v end)
addToggle(page, "Team Check", true, function(v) aim.teamCheck = v end)
addToggle(page, "Rotate Body", true, function(v) aim.rotateBody = v end)
addSlider(page, "Smoothness", 1, 100, 35, "%", function(v) aim.smooth = v end)
addSlider(page, "Max Distance", 50, 1000, 500, "", function(v) aim.maxDist = v end)
end)

createCategory("Silent", function(page)
addToggle(page, "Silent Aim", false, function(v)
silent.on = v
if v and installSilentHooks then installSilentHooks() end
end)
addToggle(page, "Show FOV Circle", true, function(v) silent.showFov = v end)
addDropdown(page, "Hit Part", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(o) silent.part = o end)
addSlider(page, "Silent FOV", 30, 500, 150, "", function(v) silent.fov = v end)
addSlider(page, "Silent Range", 50, 2000, 1000, "m", function(v) silent.range = v end)
addSlider(page, "Hit Chance", 1, 100, 100, "%", function(v) silent.hitChance = v end)
addToggle(page, "Legacy Mouse Hook", false, function(v)
silent.legacyMouse = v
if v and installMouseHook then installMouseHook() end
end)
end)

createCategory("Movement", function(page)
addToggle(page, "Infinite Jump", false, function(v) state.infJump = v end)
addToggle(page, "No CD Double Jump", false, function(v) state.airJump = v end)
addSlider(page, "Air Jump Power", 20, 120, 50, "", function(v) state.airJumpPower = v end)
addToggle(page, "Speed Boost", false, function(v)
local h = getH()
if v and h and h.WalkSpeed > 0 then baseSpeed = h.WalkSpeed end
state.speedOn = v
if not v and h and state.speedMode == "WalkSpeed" then h.WalkSpeed = baseSpeed end
end)
addDropdown(page, "Speed Mode", {"Velocity", "WalkSpeed"}, "Velocity", function(o)
local h = getH()
if state.speedMode == "WalkSpeed" and h then h.WalkSpeed = baseSpeed end
state.speedMode = o
end)
addSlider(page, "Multiplier", 10, 30, 14, "x", function(v) state.speedMult = v / 10 end)
addToggle(page, "Touch Fly", false, function(v)
state.fly = v
local h = getH()
if h then h.PlatformStand = v end
if flyGui then flyGui.Enabled = v end
if upBtn then upBtn.Visible = v end
if downBtn then downBtn.Visible = v end
end)
addSlider(page, "Fly Speed", 10, 300, 60, "", function(v) state.flySpeed = v end)
addToggle(page, "Noclip", false, function(v) state.noclip = v end)
end)

createCategory("Weapon", function(page)
local gpT = addToggle(page, "Custom Position", false, function(v) gunPosState.on = v end)
local gxS = addSlider(page, "Left / Right", -50, 50, 0, "", function(v) gunPosState.x = v / 10 end)
local gyS = addSlider(page, "Down / Up", -50, 50, 0, "", function(v) gunPosState.y = v / 10 end)
local gzS = addSlider(page, "Back / Forward", -50, 50, 0, "", function(v) gunPosState.z = v / 10 end)
addButton(page, "Reset Gun Pos", function()
gunPosState.on = false
gunPosState.x, gunPosState.y, gunPosState.z = 0, 0, 0
gpT:Set(false); gxS:Set(0); gyS:Set(0); gzS:Set(0)
end)
addDropdown(page, "Gun Mode", {"Stable", "Off"}, "Stable", function(o) gunMode = o end)
end)

createCategory("Visuals", function(page)
addToggle(page, "ESP Enabled", false, function(v) esp.on = v end)
addToggle(page, "Glow Outline", true, function(v) esp.chams = v end)
addToggle(page, "Name Tags", true, function(v) esp.names = v end)
addToggle(page, "Distance", true, function(v) esp.distance = v end)
addToggle(page, "Health Bars", true, function(v) esp.health = v end)
addToggle(page, "Visible Check", true, function(v) esp.visCheck = v end)
addToggle(page, "Show Teammates", false, function(v) esp.teammates = v end)
addSlider(page, "Fill Transparency", 0, 100, 80, "%", function(v) esp.fill = v / 100 end)
addSlider(page, "Max Distance", 50, 2000, 1000, "", function(v) esp.maxDist = v end)
end)

selectTab(firstTab)

-- DRAGGABLE WINDOW
local draggingMain, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
if isPtr(input) then
draggingMain = true
dragStart = input.Position
startPos = mainFrame.Position
end
end)
bind(UIS.InputChanged, function(input)
if not draggingMain then return end
if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
local delta = input.Position - dragStart
mainFrame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
end
end)
bind(UIS.InputEnded, function(input)
if draggingMain and isPtr(input) then draggingMain = false end
end)

toggleBtn.MouseButton1Click:Connect(function()
mainFrame.Visible = not mainFrame.Visible
btnStroke.Transparency = mainFrame.Visible and 0.1 or 0.3
end)
closeBtn.MouseButton1Click:Connect(function()
mainFrame.Visible = false
btnStroke.Transparency = 0.3
end)

-- FLY CONTROLS
flyGui = Instance.new("ScreenGui")
flyGui.Name = "MallhiFly"
flyGui.ResetOnSpawn = false
flyGui.IgnoreGuiInset = true
flyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
flyGui.DisplayOrder = 999998
flyGui.Enabled = false
parentGui(flyGui)

local function makeFlyBtn(text, pos)
local b = Instance.new("TextButton")
b.Size = UDim2.fromOffset(56, 56)
b.Position = pos
b.BackgroundColor3 = BW.card
b.BackgroundTransparency = 0.2
b.BorderSizePixel = 0
b.Text = text
b.TextColor3 = BW.accent
b.TextSize = 22
b.Font = Enum.Font.GothamBold
b.AutoButtonColor = false
b.Visible = false
b.Parent = flyGui
round(b, 28)
local s = Instance.new("UIStroke", b)
s.Color = BW.accent
s.Thickness = 1.2
s.Transparency = 0.4
return b
end

upBtn = makeFlyBtn("▲", UDim2.new(1, -76, 0.5, -90))
downBtn = makeFlyBtn("▼", UDim2.new(1, -76, 0.5, 20))

local flyUp, flyDown = false, false
upBtn.InputBegan:Connect(function(i) if isPtr(i) then flyUp = true end end)
upBtn.InputEnded:Connect(function(i) if isPtr(i) then flyUp = false end end)
downBtn.InputBegan:Connect(function(i) if isPtr(i) then flyDown = true end end)
downBtn.InputEnded:Connect(function(i) if isPtr(i) then flyDown = false end end)

-- MOVEMENT LOGIC
bind(UIS.JumpRequest, function()
if not state.infJump then return end
local h = getH()
if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

bind(UIS.JumpRequest, function()
if not state.airJump then return end
local h, root = getH(), getR()
if not (h and root) then return end
local st = h:GetState()
if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then return end
if os.clock() - state.lastAirJump < 0.18 then return end
state.lastAirJump = os.clock()
local v = root.AssemblyLinearVelocity
root.AssemblyLinearVelocity = Vector3.new(v.X, state.airJumpPower, v.Z)
h:ChangeState(Enum.HumanoidStateType.Jumping)
end)

bind(RunService.Heartbeat, function()
if not state.speedOn or state.fly then return end
local h, root = getH(), getR()
if not (h and root) then return end
if state.speedMode == "WalkSpeed" then
local t = baseSpeed * state.speedMult
if h.WalkSpeed ~= t then h.WalkSpeed = t end
else
local md = h.MoveDirection
if md.Magnitude > 0 and h.WalkSpeed > 0 then
local s = h.WalkSpeed * state.speedMult
local v = root.AssemblyLinearVelocity
root.AssemblyLinearVelocity = Vector3.new(md.X * s, v.Y, md.Z * s)
end
end
end)

bind(RunService.Heartbeat, function()
if not state.fly then return end
local root, h, cam = getR(), getH(), workspace.CurrentCamera
if not (root and h and cam) then return end
local dir = Vector3.new(h.MoveDirection.X, 0, h.MoveDirection.Z)
if flyUp then dir += Vector3.yAxis end
if flyDown then dir -= Vector3.yAxis end
root.AssemblyLinearVelocity = dir.Magnitude > 0 and dir.Unit * state.flySpeed or Vector3.zero
end)

local noclipParts, noclipTime = {}, 0
bind(RunService.Stepped, function()
if not state.noclip then return end
local c = lp.Character
if not c then return end
if os.clock() - noclipTime > 1.5 then
noclipTime = os.clock()
table.clear(noclipParts)
for _, p in ipairs(c:GetDescendants()) do
if p:IsA("BasePart") then noclipParts[#noclipParts + 1] = p end
end
end
for _, p in ipairs(noclipParts) do
if p.Parent and p.CanCollide then p.CanCollide = false end
end
end)

-- RAYCAST & VISIBILITY
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.RespectCanCollide = true

local function refreshFilter()
local list = {workspace.CurrentCamera}
for _, p in ipairs(Players:GetPlayers()) do
if p.Character then list[#list + 1] = p.Character end
end
rayParams.FilterDescendantsInstances = list
end

local visCache, visTime = {}, 0
local function isVisible(part)
local now = os.clock()
if now - visTime > 0.4 then table.clear(visCache); visTime = now end
if visCache[part] ~= nil then return visCache[part] end
local cam = workspace.CurrentCamera
local o = cam.CFrame.Position
local d = part.Position - o
local hit = workspace:Raycast(o, d, rayParams)
local res = not hit or hit.Instance.Transparency >= 0.8
visCache[part] = res
return res
end

-- CAMERA AIMBOT
local holding = false
bind(UIS.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then holding = true end end)
bind(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then holding = false end end)

local function computeTarget()
local myRoot = getR()
if not myRoot then return nil end
local cands, myPos = {}, myRoot.Position
for _, p in ipairs(Players:GetPlayers()) do
if p ~= lp then
local c = p.Character
local h = c and c:FindFirstChildOfClass("Humanoid")
local r = c and c:FindFirstChild("HumanoidRootPart")
local part = c and (c:FindFirstChild(aim.part) or r)
if h and r and part and h.Health > 0 and not c:FindFirstChildOfClass("ForceField") and not (aim.teamCheck and sameTeam(p)) then
local d = (r.Position - myPos).Magnitude
if d <= aim.maxDist then cands[#cands + 1] = {part = part, root = r, d = d} end
end
end
end
table.sort(cands, function(a, b) return a.d < b.d end)
refreshFilter()
for _, c in ipairs(cands) do
if not aim.wallCheck or isVisible(c.part) then return c end
end
end

local aimCache, aimCacheTime = nil, 0
local function getTarget()
local now = os.clock()
if now - aimCacheTime < 0.08 then return aimCache end
aimCacheTime = now
aimCache = computeTarget()
return aimCache
end

RunService:BindToRenderStep("MallhiAim", Enum.RenderPriority.Camera.Value + 1, function()
if not (aim.on and (aim.alwaysOn or holding)) then aim.dir = nil; aim.camGame = nil; return end
local cam = workspace.CurrentCamera
local t = cam and getTarget()
if not t then aim.dir = nil; aim.camGame = nil; return end

local o = cam.CFrame.Position
local pos = t.part.Position + t.root.AssemblyLinearVelocity * aim.prediction
local want = (pos - o).Unit
local alpha = math.clamp(aim.smooth / 100, 0.01, 1)

aim.camGame = cam.CFrame
if not aim.dir then aim.dir = cam.CFrame.LookVector end
local nd = aim.dir:Lerp(want, alpha)
aim.dir = nd.Magnitude < 0.001 and want or nd.Unit

cam.CFrame = CFrame.lookAt(o, o + aim.dir)
aim.lockedUntil = os.clock() + 0.08
end)

-- SILENT AIM
local mouse = lp:GetMouse()
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = screenGui
round(fovCircle, 999)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = BW.accent
fovStroke.Thickness = 1.2

local function getAimOrigin(cam)
if UIS.TouchEnabled and not UIS.MouseEnabled then return cam.ViewportSize / 2 end
return UIS:GetMouseLocation()
end

local function getSilentTarget()
local cam = workspace.CurrentCamera
if not cam then return nil end
local origin = getAimOrigin(cam)
local myRoot = getR()
local myPos = myRoot and myRoot.Position or cam.CFrame.Position
local cands = {}

for _, p in ipairs(Players:GetPlayers()) do
if p == lp then continue end
local c = p.Character
local h = c and c:FindFirstChildOfClass("Humanoid")
local r = c and c:FindFirstChild("HumanoidRootPart")
local part = c and (c:FindFirstChild(silent.part) or c:FindFirstChild("HumanoidRootPart"))
if not (h and r and part and h.Health > 0) then continue end
if c:FindFirstChildOfClass("ForceField") then continue end
if aim.teamCheck and sameTeam(p) then continue end

local worldDist = (r.Position - myPos).Magnitude
if worldDist > silent.range then continue end

local sp, onScreen = cam:WorldToViewportPoint(part.Position)
if not onScreen then continue end

local screenDist = (Vector2.new(sp.X, sp.Y) - origin).Magnitude
if screenDist <= silent.fov then
cands[#cands + 1] = {part = part, dist = screenDist, worldDist = worldDist, name = p.DisplayName}
end
end

if #cands == 0 then return nil end
table.sort(cands, function(x, y) return x.worldDist < y.worldDist end)
if not aim.wallCheck then return cands[1] end

refreshFilter()
for _, c in ipairs(cands) do
if isVisible(c.part) then return c end
end
end

local statusLabel = Instance.new("TextLabel")
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
local vp0 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 400)
statusLabel.Position = UDim2.fromOffset(vp0.X / 2, 8)
statusLabel.Size = UDim2.fromOffset(130, 16)
statusLabel.BackgroundTransparency = 0.3
statusLabel.BackgroundColor3 = BW.card
statusLabel.TextColor3 = BW.accent
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Visible = false
statusLabel.Parent = screenGui
round(statusLabel, 6)

bind(RunService.RenderStepped, function()
local cam = workspace.CurrentCamera
if not (silent.on and cam) then
silent.target = nil
silent.pos = nil
if fovCircle.Visible then fovCircle.Visible = false end
if statusLabel.Visible then statusLabel.Visible = false end
return
end

local origin = getAimOrigin(cam)
fovCircle.Size = UDim2.fromOffset(silent.fov * 2, silent.fov * 2)
fovCircle.Position = UDim2.fromOffset(origin.X, origin.Y)
fovCircle.Visible = silent.showFov

local t = getSilentTarget()
silent.target = t and t.part or nil
local tgt = silent.target
silent.pos = (tgt and tgt.Parent) and tgt.Position or nil

if t then
statusLabel.Text = t.name .. " | " .. silent.redirects
statusLabel.Visible = true
else
statusLabel.Visible = false
end
end)

local function shouldRedirect()
return math.random() * 100 <= silent.hitChance
end

installSilentHooks = function()
if G.MALLHI_NAMECALL_HOOKED then return end
task.defer(function()
pcall(function()
local ws = workspace
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
local pos = silent.pos
if pos and self == ws and not checkcaller() then
local method = getnamecallmethod()
if method == "Raycast" then
local o, d = ...
if typeof(o) == "Vector3" and typeof(d) == "Vector3" then
if shouldRedirect() then
silent.redirects += 1
return old(self, o, (pos - o).Unit * d.Magnitude, select(3, ...))
end
end
end
end
return old(self, ...)
end))
G.MALLHI_NAMECALL_HOOKED = true
silent.hookState = "ok"
end)
end)
end

-- ESP SYSTEM
local espRoot = Instance.new("Folder")
espRoot.Name = "MallhiESP"
parentGui(espRoot)
local espObjs = {}

local function makeEsp(p)
local hl = Instance.new("Highlight")
hl.Name = "MallhiHL"
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.FillTransparency = esp.fill
hl.OutlineTransparency = 0.1
hl.Enabled = false
hl.Parent = espRoot

local bb = Instance.new("BillboardGui")
bb.Name = "MallhiBB"
bb.Size = UDim2.fromOffset(140, 40)
bb.StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0)
bb.AlwaysOnTop = true
bb.ResetOnSpawn = false
bb.Enabled = false
bb.Parent = espRoot

local nl = Instance.new("TextLabel")
nl.BackgroundTransparency = 1
nl.Size = UDim2.new(1, 0, 0, 18)
nl.Font = Enum.Font.GothamBold
nl.TextSize = 12
nl.TextColor3 = Color3.new(1, 1, 1)
nl.TextStrokeTransparency = 0.4
nl.Parent = bb

local bg = Instance.new("Frame")
bg.Position = UDim2.new(0.1, 0, 0, 20)
bg.Size = UDim2.new(0.8, 0, 0, 5)
bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bg.BorderSizePixel = 0
bg.Parent = bb
round(bg, 999)

local bf = Instance.new("Frame")
bf.Size = UDim2.fromScale(1, 1)
bf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bf.BorderSizePixel = 0
bf.Parent = bg
round(bf, 999)

espObjs[p] = {hl = hl, bb = bb, name = nl, barBg = bg, fill = bf, visible = false}
end

local function remEsp(p)
local o = espObjs[p]
if o then
pcall(function() o.hl:Destroy(); o.bb:Destroy() end)
espObjs[p] = nil
end
end
bind(Players.PlayerRemoving, remEsp)

task.spawn(function()
while alive do
task.wait(0.2)
if not esp.on then
for _, o in pairs(espObjs) do
if o.visible then o.hl.Enabled = false; o.bb.Enabled = false; o.visible = false end
end
continue
end

local myRoot = getR()
if not myRoot then continue end
local myPos = myRoot.Position

for _, p in ipairs(Players:GetPlayers()) do
if p == lp then continue end
local c = p.Character
local h = c and c:FindFirstChildOfClass("Humanoid")
local r = c and c:FindFirstChild("HumanoidRootPart")
local head = c and (c:FindFirstChild("Head") or r)
local isT = sameTeam(p)

local show = h and r and head and h.Health > 0 and (not isT or esp.teammates)
local dist = 0
if show then
dist = (r.Position - myPos).Magnitude
show = dist <= esp.maxDist
end

local o = espObjs[p]
if show then
if not o then makeEsp(p); o = espObjs[p] end
local col = isT and esp.teamColor or esp.enemyColor
if not isT and esp.visCheck and isVisible(head) then col = esp.visibleColor end

o.hl.Adornee = c
o.hl.Enabled = esp.chams
o.hl.FillColor = col
o.hl.OutlineColor = col
o.hl.FillTransparency = esp.fill
o.bb.Adornee = head
o.bb.Enabled = esp.names or esp.health or esp.distance

if esp.names then
o.name.Text = esp.distance and (p.DisplayName .. " [" .. math.floor(dist) .. "m]") or p.DisplayName
o.name.Visible = true
else
o.name.Visible = false
end

if esp.health then
local rat = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
o.barBg.Visible = true
o.fill.Size = UDim2.fromScale(rat, 1)
else
o.barBg.Visible = false
end
o.visible = true
elseif o and o.visible then
o.hl.Enabled = false
o.bb.Enabled = false
o.visible = false
end
end
end
end)

print("[MALLHIHUB] Loaded successfully without freezing.")
end)

