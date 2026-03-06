-- Enemy ESP + Enemy-only Aim Assist with UI
-- LocalScript

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SETTINGS = {
    ESPEnabled = true,
    TeamCheck = true,
    UseTeamColor = false,
    EnemyColor = Color3.fromRGB(255, 70, 70),
    FillTransparency = 0.75,
    OutlineTransparency = 0,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,

    AssistEnabled = true,
    AssistHoldMouseButton2 = true,
    MinRadius = 30,
    MaxRadius = 350,
    CaptureRadius = 130,
}

local highlights = {}
local trackedConnections = {}

local aimHoldingRMB = false
local draggingSlider = false

local uiRefs = {
    toggleEspButton = nil,
    toggleTeamButton = nil,
    toggleAssistButton = nil,
    radiusLabel = nil,
    sliderBar = nil,
    sliderFill = nil,
    sliderKnob = nil,
    captureCircle = nil,
}

local function getCurrentCamera()
    return Workspace.CurrentCamera
end

local function isEnemy(player)
    if player == LocalPlayer then
        return false
    end

    if not SETTINGS.TeamCheck then
        return true
    end

    if LocalPlayer.Team == nil or player.Team == nil then
        return true
    end

    return player.Team ~= LocalPlayer.Team
end

local function getCharacter(player)
    if not player then
        return nil
    end

    if player.Character then
        return player.Character
    end

    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder then
        return playersFolder:FindFirstChild(player.Name)
    end

    return nil
end

local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getHead(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("Head")
end

local function cleanupHighlight(player)
    local highlight = highlights[player]
    if highlight then
        highlight:Destroy()
        highlights[player] = nil
    end
end

local function applyHighlight(player)
    if not SETTINGS.ESPEnabled or not isEnemy(player) then
        cleanupHighlight(player)
        return
    end

    local character = getCharacter(player)
    if not character or not isAlive(character) then
        cleanupHighlight(player)
        return
    end

    local highlight = highlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "EnemyESP"
        highlights[player] = highlight
    end

    highlight.Parent = character
    highlight.Adornee = character
    highlight.DepthMode = SETTINGS.DepthMode
    highlight.FillTransparency = SETTINGS.FillTransparency
    highlight.OutlineTransparency = SETTINGS.OutlineTransparency

    local color = SETTINGS.EnemyColor
    if SETTINGS.UseTeamColor and player.TeamColor then
        color = player.TeamColor.Color
    end

    highlight.FillColor = color
    highlight.OutlineColor = color
end

local function refreshAllHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyHighlight(player)
        end
    end

    for player in pairs(highlights) do
        if player.Parent == nil then
            cleanupHighlight(player)
        end
    end
end

local function updateToggleButton(button, text, enabled)
    if not button then
        return
    end

    button.Text = string.format("%s: %s", text, enabled and "ВКЛ" or "ВЫКЛ")
    button.BackgroundColor3 = enabled and Color3.fromRGB(30, 150, 65) or Color3.fromRGB(160, 45, 45)
end

local function updateRadiusUI()
    local camera = getCurrentCamera()

    if uiRefs.radiusLabel then
        uiRefs.radiusLabel.Text = string.format("Радиус захвата: %d", SETTINGS.CaptureRadius)
    end

    if uiRefs.sliderFill and uiRefs.sliderKnob then
        local alpha = (SETTINGS.CaptureRadius - SETTINGS.MinRadius) / (SETTINGS.MaxRadius - SETTINGS.MinRadius)
        uiRefs.sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
        uiRefs.sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
    end

    if uiRefs.captureCircle and camera then
        local center = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
        local diameter = SETTINGS.CaptureRadius * 2
        uiRefs.captureCircle.Size = UDim2.fromOffset(diameter, diameter)
        uiRefs.captureCircle.Position = UDim2.fromOffset(center.X, center.Y)
        uiRefs.captureCircle.Visible = SETTINGS.AssistEnabled
    end
end

local function setRadiusFromPixel(pixelX)
    local sliderBar = uiRefs.sliderBar
    if not sliderBar then
        return
    end

    local relative = math.clamp((pixelX - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
    SETTINGS.CaptureRadius = math.floor(SETTINGS.MinRadius + (SETTINGS.MaxRadius - SETTINGS.MinRadius) * relative + 0.5)
    updateRadiusUI()
end

local function getClosestEnemyHeadInCircle()
    local camera = getCurrentCamera()
    local myCharacter = getCharacter(LocalPlayer)

    if not camera or not myCharacter or not isAlive(myCharacter) then
        return nil
    end

    local viewportSize = camera.ViewportSize
    local crosshair = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

    local nearestHead = nil
    local nearestScreenDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = getCharacter(player)
            local head = getHead(character)

            if head and isAlive(character) then
                local headScreenPoint, isOnScreen = camera:WorldToViewportPoint(head.Position)

                if isOnScreen and headScreenPoint.Z > 0 then
                    local headPoint2D = Vector2.new(headScreenPoint.X, headScreenPoint.Y)
                    local screenDistance = (headPoint2D - crosshair).Magnitude

                    if screenDistance <= SETTINGS.CaptureRadius and screenDistance < nearestScreenDistance then
                        nearestScreenDistance = screenDistance
                        nearestHead = head
                    end
                end
            end
        end
    end

    return nearestHead
end

local function updateAssist()
    if not SETTINGS.AssistEnabled or not aimHoldingRMB then
        return
    end

    local camera = getCurrentCamera()
    if not camera then
        return
    end

    local targetHead = getClosestEnemyHeadInCircle()
    if not targetHead then
        return
    end

    local cameraPosition = camera.CFrame.Position
    camera.CFrame = CFrame.new(cameraPosition, targetHead.Position)
end

local function disconnectPlayerConnections(player)
    local playerConnections = trackedConnections[player]
    if playerConnections then
        for _, connection in ipairs(playerConnections) do
            connection:Disconnect()
        end
        trackedConnections[player] = nil
    end
end

local function trackPlayer(player)
    if player == LocalPlayer then
        return
    end

    disconnectPlayerConnections(player)

    trackedConnections[player] = {
        player.CharacterAdded:Connect(function()
            task.wait(0.1)
            applyHighlight(player)
        end),
        player.CharacterRemoving:Connect(function()
            cleanupHighlight(player)
        end),
        player:GetPropertyChangedSignal("Team"):Connect(function()
            refreshAllHighlights()
        end),
    }

    applyHighlight(player)
end

local function cleanupPlayer(player)
    disconnectPlayerConnections(player)
    cleanupHighlight(player)
end

local function createUi()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EnemyEspAssistUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 250, 0, 230)
    panel.Position = UDim2.new(0, 20, 0.5, -115)
    panel.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(235, 235, 235)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Enemy ESP + Assist"
    title.Parent = panel

    local function createToggleButton(name, y)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -20, 0, 28)
        button.Position = UDim2.new(0, 10, 0, y)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 13
        button.Parent = panel

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button

        return button
    end

    uiRefs.toggleEspButton = createToggleButton("ToggleESP", 36)
    uiRefs.toggleTeamButton = createToggleButton("ToggleTeam", 68)
    uiRefs.toggleAssistButton = createToggleButton("ToggleAssist", 100)

    uiRefs.radiusLabel = Instance.new("TextLabel")
    uiRefs.radiusLabel.BackgroundTransparency = 1
    uiRefs.radiusLabel.Size = UDim2.new(1, -20, 0, 20)
    uiRefs.radiusLabel.Position = UDim2.new(0, 10, 0, 136)
    uiRefs.radiusLabel.Font = Enum.Font.Gotham
    uiRefs.radiusLabel.TextSize = 13
    uiRefs.radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    uiRefs.radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
    uiRefs.radiusLabel.Parent = panel

    uiRefs.sliderBar = Instance.new("Frame")
    uiRefs.sliderBar.Size = UDim2.new(1, -20, 0, 10)
    uiRefs.sliderBar.Position = UDim2.new(0, 10, 0, 162)
    uiRefs.sliderBar.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    uiRefs.sliderBar.BorderSizePixel = 0
    uiRefs.sliderBar.Parent = panel

    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(1, 0)
    sliderBarCorner.Parent = uiRefs.sliderBar

    uiRefs.sliderFill = Instance.new("Frame")
    uiRefs.sliderFill.Size = UDim2.new(0, 0, 1, 0)
    uiRefs.sliderFill.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
    uiRefs.sliderFill.BorderSizePixel = 0
    uiRefs.sliderFill.Parent = uiRefs.sliderBar

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = uiRefs.sliderFill

    uiRefs.sliderKnob = Instance.new("Frame")
    uiRefs.sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    uiRefs.sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    uiRefs.sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
    uiRefs.sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    uiRefs.sliderKnob.BorderSizePixel = 0
    uiRefs.sliderKnob.Parent = uiRefs.sliderBar

    local sliderKnobCorner = Instance.new("UICorner")
    sliderKnobCorner.CornerRadius = UDim.new(1, 0)
    sliderKnobCorner.Parent = uiRefs.sliderKnob

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Size = UDim2.new(1, -20, 0, 16)
    hint.Position = UDim2.new(0, 10, 0, 182)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 12
    hint.TextColor3 = Color3.fromRGB(170, 170, 170)
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = "Удерживайте ПКМ для assist"
    hint.Parent = panel

    uiRefs.captureCircle = Instance.new("Frame")
    uiRefs.captureCircle.Name = "CaptureCircle"
    uiRefs.captureCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    uiRefs.captureCircle.BackgroundTransparency = 0.65
    uiRefs.captureCircle.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
    uiRefs.captureCircle.BorderSizePixel = 0
    uiRefs.captureCircle.Parent = screenGui

    local captureCircleCorner = Instance.new("UICorner")
    captureCircleCorner.CornerRadius = UDim.new(1, 0)
    captureCircleCorner.Parent = uiRefs.captureCircle

    local captureCircleStroke = Instance.new("UIStroke")
    captureCircleStroke.Color = Color3.fromRGB(170, 220, 255)
    captureCircleStroke.Thickness = 2
    captureCircleStroke.Transparency = 0.15
    captureCircleStroke.Parent = uiRefs.captureCircle

    uiRefs.sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            setRadiusFromPixel(input.Position.X)
        end
    end)

    uiRefs.toggleEspButton.MouseButton1Click:Connect(function()
        SETTINGS.ESPEnabled = not SETTINGS.ESPEnabled
        updateToggleButton(uiRefs.toggleEspButton, "ESP", SETTINGS.ESPEnabled)
        refreshAllHighlights()
    end)

    uiRefs.toggleTeamButton.MouseButton1Click:Connect(function()
        SETTINGS.TeamCheck = not SETTINGS.TeamCheck
        updateToggleButton(uiRefs.toggleTeamButton, "TeamCheck", SETTINGS.TeamCheck)
        refreshAllHighlights()
    end)

    uiRefs.toggleAssistButton.MouseButton1Click:Connect(function()
        SETTINGS.AssistEnabled = not SETTINGS.AssistEnabled
        updateToggleButton(uiRefs.toggleAssistButton, "Assist", SETTINGS.AssistEnabled)
        updateRadiusUI()
    end)

    updateToggleButton(uiRefs.toggleEspButton, "ESP", SETTINGS.ESPEnabled)
    updateToggleButton(uiRefs.toggleTeamButton, "TeamCheck", SETTINGS.TeamCheck)
    updateToggleButton(uiRefs.toggleAssistButton, "Assist", SETTINGS.AssistEnabled)
    updateRadiusUI()
end

createUi()

for _, player in ipairs(Players:GetPlayers()) do
    trackPlayer(player)
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    refreshAllHighlights()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 and SETTINGS.AssistHoldMouseButton2 then
        aimHoldingRMB = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHoldingRMB = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        setRadiusFromPixel(input.Position.X)
    end
end)

RunService.RenderStepped:Connect(function()
    refreshAllHighlights()
    updateRadiusUI()
    updateAssist()
end)
