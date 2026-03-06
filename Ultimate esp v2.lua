-- ObjectInspector.client.lua
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

-- =========================
-- UI (создаём на лету)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "ObjectInspectorGui"
gui.ResetOnSpawn = false
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
title.Size = UDim2.new(1, -56, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "Object Inspector"
title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.fromOffset(36, 26)
closeBtn.Position = UDim2.new(1, -44, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
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

-- ВАЖНО: TextBox вместо TextLabel, чтобы можно было выделять и Ctrl+C
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

-- read-only, но выделение/копирование работает
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
	title.Text = header or "Object Inspector"
	infoBox.Text = text
	frame.Visible = true
	refreshCanvas()
end

local function closeWindow()
	frame.Visible = false
end

closeBtn.MouseButton1Click:Connect(closeWindow)

-- Закрытие по ESC
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and frame.Visible then
		closeWindow()
	end
end)

-- (необязательно) перетаскивание окна
do
	local dragging = false
	local dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	topBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

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

local function buildInfo(inst: Instance): string
	local lines = {}

	table.insert(lines, ("Name: %s"):format(inst.Name))
	table.insert(lines, ("ClassName: %s"):format(inst.ClassName))
	table.insert(lines, ("FullName: %s"):format(inst:GetFullName()))
	table.insert(lines, ("Parent: %s"):format(inst.Parent and inst.Parent:GetFullName() or "nil"))
	table.insert(lines, ("Archivable: %s"):format(tostring(inst.Archivable)))
	table.insert(lines, "")

	-- BasePart свойства
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

	-- Attributes
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

	-- Tags
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

	-- Children
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

	-- Descendants count
	local descCount = #inst:GetDescendants()
	table.insert(lines, ("[Descendants] count=%d"):format(descCount))

	return table.concat(lines, "\n")
end

-- =========================
-- Клик по объекту в мире
-- =========================
local mouse = player:GetMouse()

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local target = mouse.Target
	if not target then return end

	local header = ("%s (%s)"):format(target.Name, target.ClassName)
	openWindow(buildInfo(target), header)
end)
