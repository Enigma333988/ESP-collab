-- ObjectInspector.client.lua
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local running = true
local connections = {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-- =========================
-- UI (создаём на лету)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "ObjectInspectorGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Window"
frame.Size = UDim2.fromOffset(560, 380)
frame.Position = UDim2.new(0.5, -280, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
topBar.BorderSizePixel = 0
topBar.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -152, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "Object Inspector"
title.Parent = topBar

local cameraBtn = Instance.new("TextButton")
cameraBtn.Name = "Camera"
cameraBtn.Size = UDim2.fromOffset(72, 26)
cameraBtn.Position = UDim2.new(1, -124, 0.5, -13)
cameraBtn.BackgroundColor3 = Color3.fromRGB(55, 110, 180)
cameraBtn.BorderSizePixel = 0
cameraBtn.Font = Enum.Font.GothamSemibold
cameraBtn.TextSize = 13
cameraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cameraBtn.Text = "Камера"
cameraBtn.Parent = topBar

local cameraCorner = Instance.new("UICorner")
cameraCorner.CornerRadius = UDim.new(0, 8)
cameraCorner.Parent = cameraBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.fromOffset(36, 26)
closeBtn.Position = UDim2.new(1, -44, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Size = UDim2.new(1, -24, 1, -56)
scroll.Position = UDim2.fromOffset(12, 46)
scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 8
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Parent = frame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 10)
scrollCorner.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = scroll

-- TextBox вместо TextLabel, чтобы можно было выделять и Ctrl+C
local infoBox = Instance.new("TextBox")
infoBox.Name = "Info"
infoBox.BackgroundTransparency = 1
infoBox.Size = UDim2.new(1, -10, 0, 0)
infoBox.AutomaticSize = Enum.AutomaticSize.Y
infoBox.Font = Enum.Font.Code
infoBox.TextSize = 14
infoBox.TextXAlignment = Enum.TextXAlignment.Left
infoBox.TextYAlignment = Enum.TextYAlignment.Top
infoBox.TextWrapped = true
infoBox.TextColor3 = Color3.fromRGB(230, 230, 230)
infoBox.Text = ""
infoBox.ClearTextOnFocus = false
infoBox.TextEditable = false
infoBox.MultiLine = true
infoBox.Active = true
infoBox.Parent = scroll

local function refreshCanvas()
	task.wait()
	scroll.CanvasSize = UDim2.new(0, 0, 0, infoBox.AbsoluteSize.Y + 20)
end

local function openWindow(text, header)
	if not running then return end
	title.Text = header or "Object Inspector"
	infoBox.Text = text
	frame.Visible = true
	refreshCanvas()
end

-- =========================
-- Режим камеры
-- =========================
local cameraMode = false
local rotateActive = false
local yaw = 0
local pitch = 0
local cameraMove = {
	W = false,
	A = false,
	S = false,
	D = false,
}
local hiddenGuiStates = {}
local savedCameraType = camera.CameraType
local savedCameraCF = camera.CFrame

local function setServerUiVisible(visible)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	if not visible then
		hiddenGuiStates = {}
		for _, child in ipairs(playerGui:GetChildren()) do
			if child:IsA("ScreenGui") and child ~= gui then
				hiddenGuiStates[child] = child.Enabled
				child.Enabled = false
			end
		end
	else
		for g, state in pairs(hiddenGuiStates) do
			if g and g.Parent then
				g.Enabled = state
			end
		end
		hiddenGuiStates = {}
	end
end

local function stopCameraMode()
	if not cameraMode then return end
	cameraMode = false
	rotateActive = false
	cameraBtn.Text = "Камера"
	cameraBtn.BackgroundColor3 = Color3.fromRGB(55, 110, 180)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true
	camera.CameraType = savedCameraType
	camera.CFrame = savedCameraCF
	setServerUiVisible(true)
	frame.Visible = true
end

local function startCameraMode()
	if cameraMode or not running then return end
	cameraMode = true
	cameraBtn.Text = "Камера: ON"
	cameraBtn.BackgroundColor3 = Color3.fromRGB(60, 150, 95)
	savedCameraType = camera.CameraType
	savedCameraCF = camera.CFrame
	local look = camera.CFrame.LookVector
	yaw = math.atan2(-look.X, -look.Z)
	pitch = math.asin(math.clamp(look.Y, -0.99, 0.99))
	camera.CameraType = Enum.CameraType.Scriptable
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true
	setServerUiVisible(false)
	frame.Visible = false
end

local function shutdownScript()
	if not running then return end
	running = false
	stopCameraMode()
	for _, c in ipairs(connections) do
		if c and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(connections)
	if gui then
		gui:Destroy()
	end
end

closeBtn.MouseButton1Click:Connect(shutdownScript)

-- Закрытие по ESC
connect(UIS.InputBegan, function(input, gp)
	if gp or not running then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		shutdownScript()
	end
end)

-- Кнопка камеры
connect(cameraBtn.MouseButton1Click, function()
	if not running then return end
	if cameraMode then
		stopCameraMode()
	else
		startCameraMode()
	end
end)

-- Перетаскивание окна
local dragging = false
local dragStart, startPos
connect(topBar.InputBegan, function(input)
	if not running or cameraMode then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
connect(topBar.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
connect(UIS.InputChanged, function(input)
	if not running then return end
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- =========================
-- Сбор полной инфы
-- =========================
local function toStr(v)
	local t = typeof(v)
	if t == "Vector3" then
		return string.format("Vector3(%.3f, %.3f, %.3f)", v.X, v.Y, v.Z)
	elseif t == "Color3" then
		return string.format("Color3(%.3f, %.3f, %.3f)", v.R, v.G, v.B)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CFrame(pos=%.3f, %.3f, %.3f)", p.X, p.Y, p.Z)
	elseif t == "Instance" then
		return v:GetFullName()
	end
	return tostring(v)
end

local function buildInfo(inst)
	local lines = {}

	table.insert(lines, ("Name: %s"):format(inst.Name))
	table.insert(lines, ("ClassName: %s"):format(inst.ClassName))
	table.insert(lines, ("FullName: %s"):format(inst:GetFullName()))
	table.insert(lines, ("Parent: %s"):format(inst.Parent and inst.Parent:GetFullName() or "nil"))
	table.insert(lines, ("Archivable: %s"):format(tostring(inst.Archivable)))
	table.insert(lines, "")

	if inst:IsA("BasePart") then
		table.insert(lines, "[BasePart]")
		table.insert(lines, ("Position: %s"):format(toStr(inst.Position)))
		table.insert(lines, ("Size: %s"):format(toStr(inst.Size)))
		table.insert(lines, ("Anchored: %s"):format(tostring(inst.Anchored)))
		table.insert(lines, ("CanCollide: %s"):format(tostring(inst.CanCollide)))
		table.insert(lines, ("Transparency: %s"):format(toStr(inst.Transparency)))
		table.insert(lines, ("Material: %s"):format(tostring(inst.Material)))
		table.insert(lines, ("Color: %s"):format(toStr(inst.Color)))
		table.insert(lines, ("Locked: %s"):format(tostring(inst.Locked)))
		table.insert(lines, "")
	end

	local attrs = inst:GetAttributes()
	table.insert(lines, "[Attributes]")
	local anyAttr = false
	for k, v in pairs(attrs) do
		anyAttr = true
		table.insert(lines, ("- %s = %s (%s)"):format(k, toStr(v), typeof(v)))
	end
	if not anyAttr then
		table.insert(lines, "- (none)")
	end
	table.insert(lines, "")

	table.insert(lines, "[Tags]")
	local tags = CollectionService:GetTags(inst)
	if #tags == 0 then
		table.insert(lines, "- (none)")
	else
		for _, t in ipairs(tags) do
			table.insert(lines, ("- %s"):format(t))
		end
	end
	table.insert(lines, "")

	local children = inst:GetChildren()
	table.insert(lines, ("[Children] count=%d"):format(#children))
	local maxShow = math.min(#children, 30)
	for i = 1, maxShow do
		local c = children[i]
		table.insert(lines, ("- %s (%s)"):format(c.Name, c.ClassName))
	end
	if #children > maxShow then
		table.insert(lines, ("- ... +%d more"):format(#children - maxShow))
	end
	table.insert(lines, "")

	local descCount = #inst:GetDescendants()
	table.insert(lines, ("[Descendants] count=%d"):format(descCount))

	return table.concat(lines, "\n")
end

-- =========================
-- Клик по объекту в мире
-- =========================
local mouse = player:GetMouse()

connect(UIS.InputBegan, function(input, gameProcessed)
	if not running or gameProcessed or cameraMode then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local target = mouse.Target
	if not target then return end

	local header = ("%s (%s)"):format(target.Name, target.ClassName)
	openWindow(buildInfo(target), header)
end)

connect(UIS.InputBegan, function(input, gameProcessed)
	if not running or gameProcessed or not cameraMode then return end

	if input.KeyCode == Enum.KeyCode.W then cameraMove.W = true end
	if input.KeyCode == Enum.KeyCode.A then cameraMove.A = true end
	if input.KeyCode == Enum.KeyCode.S then cameraMove.S = true end
	if input.KeyCode == Enum.KeyCode.D then cameraMove.D = true end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotateActive = true
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UIS.MouseIconEnabled = false
	end
end)

connect(UIS.InputEnded, function(input)
	if not running or not cameraMode then return end

	if input.KeyCode == Enum.KeyCode.W then cameraMove.W = false end
	if input.KeyCode == Enum.KeyCode.A then cameraMove.A = false end
	if input.KeyCode == Enum.KeyCode.S then cameraMove.S = false end
	if input.KeyCode == Enum.KeyCode.D then cameraMove.D = false end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotateActive = false
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
end)

connect(UIS.InputChanged, function(input)
	if not running or not cameraMode or not rotateActive then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

	local sensitivity = 0.0025
	yaw = yaw - input.Delta.X * sensitivity
	pitch = math.clamp(pitch - input.Delta.Y * sensitivity, math.rad(-89), math.rad(89))
end)

connect(RunService.RenderStepped, function(dt)
	if not running or not cameraMode then return end

	local move = Vector3.zero
	if cameraMove.W then move += Vector3.new(0, 0, -1) end
	if cameraMove.S then move += Vector3.new(0, 0, 1) end
	if cameraMove.A then move += Vector3.new(-1, 0, 0) end
	if cameraMove.D then move += Vector3.new(1, 0, 0) end

	local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local speed = 32
	local pos = camera.CFrame.Position
	if move.Magnitude > 0 then
		move = move.Unit * speed * dt
		pos = pos + rotation:VectorToWorldSpace(move)
	end
	camera.CFrame = CFrame.new(pos) * rotation
end)
