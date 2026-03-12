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
frame.Visible = true
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
title.Size = UDim2.new(1, -586, 1, 0)
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

local xyzBtn = Instance.new("TextButton")
xyzBtn.Name = "XYZ"
xyzBtn.Size = UDim2.fromOffset(50, 26)
xyzBtn.Position = UDim2.new(1, -180, 0.5, -13)
xyzBtn.BackgroundColor3 = Color3.fromRGB(85, 85, 150)
xyzBtn.BorderSizePixel = 0
xyzBtn.Font = Enum.Font.GothamSemibold
xyzBtn.TextSize = 13
xyzBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
xyzBtn.Text = "XYZ"
xyzBtn.Parent = topBar

local xyzCorner = Instance.new("UICorner")
xyzCorner.CornerRadius = UDim.new(0, 8)
xyzCorner.Parent = xyzBtn

local teleportBtn = Instance.new("TextButton")
teleportBtn.Name = "Teleport"
teleportBtn.Size = UDim2.fromOffset(86, 26)
teleportBtn.Position = UDim2.new(1, -272, 0.5, -13)
teleportBtn.BackgroundColor3 = Color3.fromRGB(135, 95, 45)
teleportBtn.BorderSizePixel = 0
teleportBtn.Font = Enum.Font.GothamSemibold
teleportBtn.TextSize = 13
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Text = "Телепорт"
teleportBtn.Parent = topBar

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 8)
teleportCorner.Parent = teleportBtn

local wingsBtn = Instance.new("TextButton")
wingsBtn.Name = "Wings"
wingsBtn.Size = UDim2.fromOffset(64, 26)
wingsBtn.Position = UDim2.new(1, -342, 0.5, -13)
wingsBtn.BackgroundColor3 = Color3.fromRGB(95, 55, 145)
wingsBtn.BorderSizePixel = 0
wingsBtn.Font = Enum.Font.GothamSemibold
wingsBtn.TextSize = 13
wingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
wingsBtn.Text = "Крылья"
wingsBtn.Parent = topBar

local wingsCorner = Instance.new("UICorner")
wingsCorner.CornerRadius = UDim.new(0, 8)
wingsCorner.Parent = wingsBtn

local cursorBtn = Instance.new("TextButton")
cursorBtn.Name = "Cursor"
cursorBtn.Size = UDim2.fromOffset(64, 26)
cursorBtn.Position = UDim2.new(1, -412, 0.5, -13)
cursorBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
cursorBtn.BorderSizePixel = 0
cursorBtn.Font = Enum.Font.GothamSemibold
cursorBtn.TextSize = 13
cursorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cursorBtn.Text = "Курсор"
cursorBtn.Parent = topBar

local cursorCorner = Instance.new("UICorner")
cursorCorner.CornerRadius = UDim.new(0, 8)
cursorCorner.Parent = cursorBtn

local pickupBtn = Instance.new("TextButton")
pickupBtn.Name = "Pickup"
pickupBtn.Size = UDim2.fromOffset(64, 26)
pickupBtn.Position = UDim2.new(1, -482, 0.5, -13)
pickupBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 35)
pickupBtn.BorderSizePixel = 0
pickupBtn.Font = Enum.Font.GothamSemibold
pickupBtn.TextSize = 13
pickupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pickupBtn.Text = "Лут"
pickupBtn.Parent = topBar

local pickupCorner = Instance.new("UICorner")
pickupCorner.CornerRadius = UDim.new(0, 8)
pickupCorner.Parent = pickupBtn

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
	Shift = false,
}
local hiddenGuiStates = {}
local savedCameraType = camera.CameraType
local savedCameraCF = camera.CFrame
local forceCursorMode = false
local cursorHotkey = "Ctrl+M"
local lastCollectedInfo = nil
local lastClickedTarget = nil
local lootTrackingEnabled = false

local flyMode = false
local flyMove = {
	W = false,
	A = false,
	S = false,
	D = false,
	Up = false,
	Down = false,
	Shift = false,
}
local flyVelocity
local flyGyro
local flyTargetPart
local flyTargetHumanoid

local function formatCameraCFrame(cf)
	local p = cf.Position
	local lv = cf.LookVector
	return string.format(
		"CFrame.new(%.3f, %.3f, %.3f) * CFrame.fromMatrix(Vector3.zero, Vector3.new(%.6f, %.6f, %.6f), Vector3.new(%.6f, %.6f, %.6f), Vector3.new(%.6f, %.6f, %.6f))",
		p.X, p.Y, p.Z,
		cf.XVector.X, cf.XVector.Y, cf.XVector.Z,
		cf.YVector.X, cf.YVector.Y, cf.YVector.Z,
		cf.ZVector.X, cf.ZVector.Y, cf.ZVector.Z
	), string.format("LookVector: Vector3.new(%.4f, %.4f, %.4f)", lv.X, lv.Y, lv.Z)
end

local function copyText(text)
	if typeof(setclipboard) == "function" then
		setclipboard(text)
		return true
	end
	if typeof(toclipboard) == "function" then
		toclipboard(text)
		return true
	end
	if typeof(clipboard_set) == "function" then
		clipboard_set(text)
		return true
	end
	return false
end

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function resolveFlyTarget()
	local character = player.Character
	if not character then
		return nil, nil, "Персонаж не загружен."
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return nil, nil, "Не найден Humanoid/HumanoidRootPart."
	end

	local seat = humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		local vehicleRoot = seat.AssemblyRootPart or seat
		return vehicleRoot, humanoid, "vehicle"
	end

	return root, humanoid, "character"
end

local function setPickupButtonState()
	if lootTrackingEnabled then
		pickupBtn.Text = "Лут: ON"
		pickupBtn.BackgroundColor3 = Color3.fromRGB(160, 120, 45)
	else
		pickupBtn.Text = "Лут: OFF"
		pickupBtn.BackgroundColor3 = Color3.fromRGB(85, 70, 45)
	end
end

local function rememberCollected(source, inst, extra)
	if not lootTrackingEnabled then return end

	local objectName = inst and inst.Name or "Unknown"
	local className = inst and inst.ClassName or "Unknown"
	local fullName = inst and inst:GetFullName() or "Unknown"
	lastCollectedInfo = {
		time = os.time(),
		source = source,
		name = objectName,
		className = className,
		fullName = fullName,
		extra = extra,
	}
end
local function stopFlyMode()
	if not flyMode then return end
	flyMode = false
	flyMove.W = false
	flyMove.A = false
	flyMove.S = false
	flyMove.D = false
	flyMove.Up = false
	flyMove.Down = false
	flyMove.Shift = false
	wingsBtn.Text = "Крылья"
	wingsBtn.BackgroundColor3 = Color3.fromRGB(95, 55, 145)
	if flyVelocity and flyVelocity.Parent then
		flyVelocity:Destroy()
	end
	if flyGyro and flyGyro.Parent then
		flyGyro:Destroy()
	end
	flyVelocity = nil
	flyGyro = nil
	if flyTargetHumanoid then
		flyTargetHumanoid.PlatformStand = false
	end
	flyTargetPart = nil
	flyTargetHumanoid = nil
end

local function startFlyMode()
	if flyMode or not running then return end
	local targetPart, humanoid, targetKind = resolveFlyTarget()
	if not targetPart then
		openWindow("Не удалось включить полёт: цель не найдена.", "Крылья")
		return
	end
	flyMode = true
	flyTargetPart = targetPart
	flyTargetHumanoid = humanoid
	wingsBtn.Text = targetKind == "vehicle" and "Крылья: АВТО" or "Крылья: ON"
	wingsBtn.BackgroundColor3 = Color3.fromRGB(140, 75, 210)

	if flyTargetHumanoid then
		flyTargetHumanoid.PlatformStand = true
	end

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	flyVelocity.P = 1e4
	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = flyTargetPart

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyGyro.P = 2e4
	flyGyro.CFrame = flyTargetPart.CFrame
	flyGyro.Parent = flyTargetPart
end

local function setCursorButtonState()
	if forceCursorMode then
		cursorBtn.Text = "Курсор: ON"
		cursorBtn.BackgroundColor3 = Color3.fromRGB(55, 150, 95)
	else
		cursorBtn.Text = "Курсор"
		cursorBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end
end

local function applyCursorState()
	if forceCursorMode then
		rotateActive = false
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
		return
	end

	if cameraMode and rotateActive then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UIS.MouseIconEnabled = false
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
end

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
	applyCursorState()
	camera.CameraType = savedCameraType
	camera.CFrame = savedCameraCF
	setServerUiVisible(true)
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
	applyCursorState()
	setServerUiVisible(false)
end

local function shutdownScript()
	if not running then return end
	running = false
	stopCameraMode()
	stopFlyMode()
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

setCursorButtonState()
setPickupButtonState()
closeBtn.MouseButton1Click:Connect(shutdownScript)

-- Закрытие по ESC
connect(UIS.InputBegan, function(input, gp)
	if gp or not running then return end

	local isCtrlDown = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
	if input.KeyCode == Enum.KeyCode.M and isCtrlDown then
		forceCursorMode = not forceCursorMode
		setCursorButtonState()
		applyCursorState()
		local state = forceCursorMode and "включен" or "выключен"
		openWindow(("Режим свободного курсора %s. Горячая клавиша: %s"):format(state, cursorHotkey), "Курсор")
		return
	end

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

connect(cursorBtn.MouseButton1Click, function()
	if not running then return end
	forceCursorMode = not forceCursorMode
	setCursorButtonState()
	applyCursorState()
	local state = forceCursorMode and "включен" or "выключен"
	openWindow(("Режим свободного курсора %s. Горячая клавиша: %s"):format(state, cursorHotkey), "Курсор")
end)

connect(pickupBtn.MouseButton1Click, function()
	if not running then return end
	lootTrackingEnabled = not lootTrackingEnabled
	setPickupButtonState()

	if lootTrackingEnabled then
		openWindow("Трекинг лута включён. Теперь события подбора будут записываться.", "Лут")
	else
		openWindow("Трекинг лута выключен. События больше не читаются в реальном времени.", "Лут")
	end
end)

connect(xyzBtn.MouseButton1Click, function()
	if not running then return end
	local cframeText, lookText = formatCameraCFrame(camera.CFrame)
	local copied = copyText(cframeText)
	local status = copied and "Скопировано в буфер." or "Буфер недоступен, скопируй вручную."
	openWindow(cframeText .. "\n" .. lookText .. "\n" .. status, "Camera XYZ")
end)

connect(teleportBtn.MouseButton1Click, function()
	if not running then return end
	local root = getRootPart()
	if not root then
		openWindow("Не найден HumanoidRootPart. Персонаж не загружен.", "Телепорт")
		return
	end
	root.CFrame = camera.CFrame
	if cameraMode then
		stopCameraMode()
	end
	openWindow("Телепорт выполнен в позицию камеры.", "Телепорт")
end)

connect(wingsBtn.MouseButton1Click, function()
	if not running then return end
	if flyMode then
		stopFlyMode()
	else
		startFlyMode()
	end
end)

local function hookCharacterTracking(character)
	if not character then return end

	connect(character.ChildAdded, function(child)
		if not running then return end
		if child:IsA("Accessory") or child:IsA("Tool") then
			rememberCollected("Character.ChildAdded", child, "Новый предмет применён к персонажу")
		end
	end)
end

local function hookCharacterTouchTracking(character)
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("BasePart") then
			connect(desc.Touched, function(hit)
				if not running or not hit then return end
				if hit:IsDescendantOf(character) then return end
				rememberCollected("Character.Touched", hit, "Касание персонажа")
			end)
		end
	end

	connect(character.DescendantAdded, function(desc)
		if not running then return end
		if desc:IsA("BasePart") then
			connect(desc.Touched, function(hit)
				if not running or not hit then return end
				if hit:IsDescendantOf(character) then return end
				rememberCollected("Character.Touched", hit, "Касание персонажа")
			end)
		end
	end)
end

if player.Character then
	hookCharacterTracking(player.Character)
	hookCharacterTouchTracking(player.Character)
end

connect(player.CharacterAdded, function(character)
	if not running then return end
	hookCharacterTracking(character)
	hookCharacterTouchTracking(character)
end)

local function hookBackpackTracking(backpackInst)
	if not backpackInst then return end
	connect(backpackInst.ChildAdded, function(child)
		if not running then return end
		if child:IsA("Tool") then
			rememberCollected("Backpack.ChildAdded", child, "Предмет попал в рюкзак")
		end
	end)
end

local backpack = player:FindFirstChildOfClass("Backpack")
if backpack then
	hookBackpackTracking(backpack)
end

connect(player.ChildAdded, function(child)
	if not running then return end
	if child:IsA("Backpack") then
		hookBackpackTracking(child)
	end
end)

connect(workspace.DescendantRemoving, function(inst)
	if not running then return end
	if not inst:IsA("BasePart") and not inst:IsA("Model") and not inst:IsA("Tool") then
		return
	end

	local root = getRootPart()
	if not root then return end

	local part = inst:IsA("BasePart") and inst or inst:IsA("Model") and inst.PrimaryPart
	if not part and (inst:IsA("Model") or inst:IsA("Tool")) then
		part = inst:FindFirstChildWhichIsA("BasePart", true)
	end
	if not part then return end

	local distance = (part.Position - root.Position).Magnitude
	if distance <= 60 then
		local extra = ("Удалён рядом с игроком (dist=%.1f)"):format(distance)
		if lastClickedTarget and (inst == lastClickedTarget or inst:IsDescendantOf(lastClickedTarget) or lastClickedTarget:IsDescendantOf(inst)) then
			extra = extra .. ", совпал с последним кликом"
		end
		rememberCollected("Workspace.DescendantRemoving", inst, extra)
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
	if t == "number" then
		return string.format("%.6f", v)
	elseif t == "boolean" then
		return v and "true" or "false"
	elseif t == "Vector3" then
		return string.format("Vector3(%.3f, %.3f, %.3f)", v.X, v.Y, v.Z)
	elseif t == "Color3" then
		return string.format("Color3(%.3f, %.3f, %.3f)", v.R, v.G, v.B)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CFrame(pos=%.3f, %.3f, %.3f)", p.X, p.Y, p.Z)
	elseif t == "Vector2" then
		return string.format("Vector2(%.3f, %.3f)", v.X, v.Y)
	elseif t == "UDim2" then
		return string.format("UDim2(%.3f, %d, %.3f, %d)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
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
		table.insert(lines, ("Orientation: %s"):format(toStr(inst.Orientation)))
		table.insert(lines, ("CFrame: %s"):format(toStr(inst.CFrame)))
		table.insert(lines, ("Size: %s"):format(toStr(inst.Size)))
		table.insert(lines, ("Mass: %s"):format(toStr(inst.AssemblyMass)))
		table.insert(lines, ("Velocity: %s"):format(toStr(inst.AssemblyLinearVelocity)))
		table.insert(lines, ("Anchored: %s"):format(tostring(inst.Anchored)))
		table.insert(lines, ("CanCollide: %s"):format(tostring(inst.CanCollide)))
		table.insert(lines, ("CanTouch: %s"):format(tostring(inst.CanTouch)))
		table.insert(lines, ("CanQuery: %s"):format(tostring(inst.CanQuery)))
		table.insert(lines, ("Transparency: %s"):format(toStr(inst.Transparency)))
		table.insert(lines, ("Material: %s"):format(tostring(inst.Material)))
		table.insert(lines, ("Color: %s"):format(toStr(inst.Color)))
		table.insert(lines, ("Locked: %s"):format(tostring(inst.Locked)))
		table.insert(lines, "")
	end

	local attrs = inst:GetAttributes()
	table.insert(lines, "[Attributes]")
	local anyAttr = false
	local attrKeys = {}
	for k in pairs(attrs) do
		table.insert(attrKeys, k)
	end
	table.sort(attrKeys)
	for _, k in ipairs(attrKeys) do
		local v = attrs[k]
		anyAttr = true
		table.insert(lines, ("- %s = %s (%s)"):format(k, toStr(v), typeof(v)))
	end
	if not anyAttr then
		table.insert(lines, "- (none)")
	end
	table.insert(lines, "")

	table.insert(lines, "[Tags]")
	local tags = CollectionService:GetTags(inst)
	table.sort(tags)
	if #tags == 0 then
		table.insert(lines, "- (none)")
	else
		for _, t in ipairs(tags) do
			table.insert(lines, ("- %s"):format(t))
		end
	end
	table.insert(lines, "")

	local children = inst:GetChildren()
	table.sort(children, function(a, b)
		if a.Name == b.Name then
			return a.ClassName < b.ClassName
		end
		return a.Name < b.Name
	end)
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
local function getTargetUnderCursor()
	local mousePos = UIS:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.RespectCanCollide = false
	params.IgnoreWater = false

	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	params.FilterDescendantsInstances = ignore

	local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
	if result then
		return result.Instance
	end

	local mouse = player:GetMouse()
	return mouse.Target
end

connect(UIS.InputBegan, function(input, gameProcessed)
	if not running or gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local target = getTargetUnderCursor()
	if not target then return end

	lastClickedTarget = target
	local header = ("%s (%s)"):format(target.Name, target.ClassName)
	openWindow(buildInfo(target), header)
end)

connect(UIS.InputBegan, function(input, gameProcessed)
	if not running or gameProcessed or (not cameraMode and not flyMode) then return end

	if input.KeyCode == Enum.KeyCode.W then cameraMove.W = true end
	if input.KeyCode == Enum.KeyCode.A then cameraMove.A = true end
	if input.KeyCode == Enum.KeyCode.S then cameraMove.S = true end
	if input.KeyCode == Enum.KeyCode.D then cameraMove.D = true end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		cameraMove.Shift = true
		if flyMode then
			flyMove.Shift = true
		end
	end
	if flyMode then
		if input.KeyCode == Enum.KeyCode.W then flyMove.W = true end
		if input.KeyCode == Enum.KeyCode.A then flyMove.A = true end
		if input.KeyCode == Enum.KeyCode.S then flyMove.S = true end
		if input.KeyCode == Enum.KeyCode.D then flyMove.D = true end
		if input.KeyCode == Enum.KeyCode.Space then flyMove.Up = true end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			flyMove.Down = true
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotateActive = true
		applyCursorState()
	end
end)

connect(UIS.InputEnded, function(input)
	if not running or (not cameraMode and not flyMode) then return end

	if input.KeyCode == Enum.KeyCode.W then cameraMove.W = false end
	if input.KeyCode == Enum.KeyCode.A then cameraMove.A = false end
	if input.KeyCode == Enum.KeyCode.S then cameraMove.S = false end
	if input.KeyCode == Enum.KeyCode.D then cameraMove.D = false end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		cameraMove.Shift = false
		flyMove.Shift = false
	end
	if flyMode then
		if input.KeyCode == Enum.KeyCode.W then flyMove.W = false end
		if input.KeyCode == Enum.KeyCode.A then flyMove.A = false end
		if input.KeyCode == Enum.KeyCode.S then flyMove.S = false end
		if input.KeyCode == Enum.KeyCode.D then flyMove.D = false end
		if input.KeyCode == Enum.KeyCode.Space then flyMove.Up = false end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			flyMove.Down = false
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotateActive = false
		applyCursorState()
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
	if not running then return end

	if cameraMode then
		local move = Vector3.zero
		if cameraMove.W then move += Vector3.new(0, 0, -1) end
		if cameraMove.S then move += Vector3.new(0, 0, 1) end
		if cameraMove.A then move += Vector3.new(-1, 0, 0) end
		if cameraMove.D then move += Vector3.new(1, 0, 0) end

		local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local speed = cameraMove.Shift and 96 or 32
		local pos = camera.CFrame.Position
		if move.Magnitude > 0 then
			move = move.Unit * speed * dt
			pos = pos + rotation:VectorToWorldSpace(move)
		end
		camera.CFrame = CFrame.new(pos) * rotation
	end

	if flyMode then
		if not flyTargetPart or not flyTargetPart.Parent or not flyVelocity or not flyGyro then
			stopFlyMode()
			return
		end
		local dir = Vector3.zero
		if flyMove.W then dir += Vector3.new(0, 0, -1) end
		if flyMove.S then dir += Vector3.new(0, 0, 1) end
		if flyMove.A then dir += Vector3.new(-1, 0, 0) end
		if flyMove.D then dir += Vector3.new(1, 0, 0) end
		if flyMove.Up then dir += Vector3.new(0, 1, 0) end
		if flyMove.Down then dir += Vector3.new(0, -1, 0) end

		local speed = flyMove.Shift and 120 or 40
		if dir.Magnitude > 0 then
			dir = dir.Unit
		end
		flyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(dir) * speed
		flyGyro.CFrame = CFrame.new(flyTargetPart.Position, flyTargetPart.Position + camera.CFrame.LookVector)
	end
end)
