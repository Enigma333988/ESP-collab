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

    ShowInfo = true,
    InfoTextColor = Color3.fromRGB(255, 255, 255),
    InfoTextSize = 13,
    MaxInfoDistance = 5000,

    AssistEnabled = true,
    AssistHoldMouseButton2 = true,
    AimBotEnabled = false,
    AimBotFollowDistance = 2,
    MinRadius = 30,
    MaxRadius = 350,
    CaptureRadius = 130,

    RefreshInterval = 0.12,
}

local highlights = {}
local infoBillboards = {}
local trackedConnections = {}
local globalConnections = {}

local aimHoldingRMB = false
local draggingSlider = false
local refreshAccumulator = 0
local scriptActive = true

local draggingWindow = false
local dragStartMouse = nil
local dragStartPos = nil
local aimBotLockedPlayer = nil

local uiRefs = {
    toggleEspButton = nil,
    toggleTeamButton = nil,
    toggleAssistButton = nil,
    toggleAimBotButton = nil,
    toggleInfoButton = nil,
    radiusLabel = nil,
    sliderBar = nil,
    sliderFill = nil,
    sliderKnob = nil,
    captureCircle = nil,
    screenGui = nil,
    panel = nil,
    titleBar = nil,
    closeButton = nil,
}

local function addConnection(connection)
    table.insert(globalConnections, connection)
    return connection
end

local function getCurrentCamera()
    return Workspace.CurrentCamera
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

local function getHead(character)
    return character and character:FindFirstChild("Head")
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getDistanceToCharacter(character)
    local localCharacter = getCharacter(LocalPlayer)
    local localRoot = getRoot(localCharacter)
    local targetRoot = getRoot(character)

    if not localRoot or not targetRoot then
        return nil
    end

    return (targetRoot.Position - localRoot.Position).Magnitude
end

local function cleanupHighlight(player)
    local highlight = highlights[player]
    if highlight then
        highlight:Destroy()
        highlights[player] = nil
    end
end

local function cleanupInfo(player)
    local billboard = infoBillboards[player]
    if billboard then
        billboard:Destroy()
        infoBillboards[player] = nil
    end
end

local function cleanupVisuals(player)
    cleanupHighlight(player)
    cleanupInfo(player)
end

local function ensureInfoBillboard(player, character)
    if not SETTINGS.ShowInfo then
        cleanupInfo(player)
        return
    end

    local head = getHead(character)
    if not head then
        cleanupInfo(player)
        return
    end

    local billboard = infoBillboards[player]
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "EnemyInfo"
        billboard.Size = UDim2.fromOffset(160, 34)
        billboard.StudsOffset = Vector3.new(0, -3.2, 0) -- under silhouette / character center
        billboard.AlwaysOnTop = true

        local text = Instance.new("TextLabel")
        text.Name = "InfoLabel"
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextScaled = false
        text.TextWrapped = true
        text.Parent = billboard

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.4
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Transparency = 0.2
        stroke.Parent = text

        infoBillboards[player] = billboard
    end

    billboard.Parent = character
    billboard.Adornee = head

    local label = billboard:FindFirstChild("InfoLabel")
    if label then
        local distance = getDistanceToCharacter(character)
        if distance and distance <= SETTINGS.MaxInfoDistance then
            label.Visible = true
            label.TextColor3 = SETTINGS.InfoTextColor
            label.TextSize = SETTINGS.InfoTextSize
            label.Text = string.format("%s\n%dm", player.Name, math.floor(distance + 0.5))
        else
            label.Visible = false
        end
    end
end

local function applyVisuals(player)
    if not SETTINGS.ESPEnabled or not isEnemy(player) then
        cleanupVisuals(player)
        return
    end

    local character = getCharacter(player)
    if not character or not isAlive(character) then
        cleanupVisuals(player)
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

    ensureInfoBillboard(player, character)
end

local function refreshAllVisuals()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyVisuals(player)
        end
    end

    for player in pairs(highlights) do
        if player.Parent == nil then
            cleanupVisuals(player)
        end
    end

    for player in pairs(infoBillboards) do
        if player.Parent == nil then
            cleanupVisuals(player)
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

local function getClosestEnemyToCrosshair()
    local camera = getCurrentCamera()
    local myCharacter = getCharacter(LocalPlayer)

    if not camera or not myCharacter or not isAlive(myCharacter) then
        return nil, nil
    end

    local viewportSize = camera.ViewportSize
    local crosshair = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

    local nearestPlayer = nil
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

                    if screenDistance < nearestScreenDistance then
                        nearestScreenDistance = screenDistance
                        nearestPlayer = player
                        nearestHead = head
                    end
                end
            end
        end
    end

    return nearestPlayer, nearestHead
end

local function clearAimBotLock()
    aimBotLockedPlayer = nil
end

local function followTargetBehind(targetPlayer)
    if not targetPlayer then
        return nil
    end

    local targetCharacter = getCharacter(targetPlayer)
    if not targetCharacter or not isAlive(targetCharacter) then
        return nil
    end

    local targetHead = getHead(targetCharacter)
    local targetRoot = getRoot(targetCharacter)
    if not targetHead or not targetRoot then
        return nil
    end

    local myCharacter = getCharacter(LocalPlayer)
    local myRoot = getRoot(myCharacter)
    if not myRoot then
        return nil
    end

    local behindPosition = targetRoot.Position - (targetRoot.CFrame.LookVector * SETTINGS.AimBotFollowDistance)
    myRoot.CFrame = CFrame.new(behindPosition, targetHead.Position)

    return targetHead
end

local function updateAssist()
    if not SETTINGS.AssistEnabled then
        clearAimBotLock()
        return
    end

    local camera = getCurrentCamera()
    if not camera then
        return
    end

    if SETTINGS.AimBotEnabled then
        if not aimHoldingRMB then
            clearAimBotLock()
            return
        end

        if not aimBotLockedPlayer then
            local nearestPlayer = getClosestEnemyToCrosshair()
            aimBotLockedPlayer = nearestPlayer
        end

        local targetHead = followTargetBehind(aimBotLockedPlayer)
        if not targetHead then
            clearAimBotLock()
            return
        end

        camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
        return
    end

    clearAimBotLock()

    if not aimHoldingRMB then
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
            applyVisuals(player)
        end),
        player.CharacterRemoving:Connect(function()
            cleanupVisuals(player)
        end),
        player:GetPropertyChangedSignal("Team"):Connect(function()
            refreshAllVisuals()
        end),
    }

    applyVisuals(player)
end

local function cleanupPlayer(player)
    disconnectPlayerConnections(player)
    cleanupVisuals(player)
end

local function shutdownScript()
    if not scriptActive then
        return
    end

    scriptActive = false
    aimHoldingRMB = false
    draggingSlider = false
    draggingWindow = false
    SETTINGS.ESPEnabled = false
    SETTINGS.AssistEnabled = false
    clearAimBotLock()

    for _, player in ipairs(Players:GetPlayers()) do
        cleanupPlayer(player)
    end

    for _, connection in ipairs(globalConnections) do
        connection:Disconnect()
    end
    table.clear(globalConnections)

    if uiRefs.screenGui then
        uiRefs.screenGui:Destroy()
        uiRefs.screenGui = nil
    end
end

local function createUi()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EnemyEspAssistUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui
    uiRefs.screenGui = screenGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 250, 0, 294)
    panel.Position = UDim2.new(0, 20, 0.5, -147)
    panel.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    panel.BorderSizePixel = 0
    panel.Parent = screenGui
    uiRefs.panel = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundTransparency = 1
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.Parent = panel
    uiRefs.titleBar = titleBar

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -54, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(235, 235, 235)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Enemy ESP + Assist"
    title.Parent = titleBar

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Size = UDim2.fromOffset(26, 26)
    closeButton.Position = UDim2.new(1, -6, 0.5, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(170, 55, 55)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 15
    closeButton.Parent = titleBar
    uiRefs.closeButton = closeButton

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton

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
    uiRefs.toggleAimBotButton = createToggleButton("ToggleAimBot", 132)
    uiRefs.toggleInfoButton = createToggleButton("ToggleInfo", 164)

    uiRefs.radiusLabel = Instance.new("TextLabel")
    uiRefs.radiusLabel.BackgroundTransparency = 1
    uiRefs.radiusLabel.Size = UDim2.new(1, -20, 0, 20)
    uiRefs.radiusLabel.Position = UDim2.new(0, 10, 0, 202)
    uiRefs.radiusLabel.Font = Enum.Font.Gotham
    uiRefs.radiusLabel.TextSize = 13
    uiRefs.radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    uiRefs.radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
    uiRefs.radiusLabel.Parent = panel

    uiRefs.sliderBar = Instance.new("Frame")
    uiRefs.sliderBar.Size = UDim2.new(1, -20, 0, 10)
    uiRefs.sliderBar.Position = UDim2.new(0, 10, 0, 228)
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
    hint.Position = UDim2.new(0, 10, 0, 248)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 12
    hint.TextColor3 = Color3.fromRGB(170, 170, 170)
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = "ПКМ: фикс цели и следование за спиной (2м)"
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

    addConnection(uiRefs.sliderBar.InputBegan:Connect(function(input)
        if not scriptActive then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            setRadiusFromPixel(input.Position.X)
        end
    end))

    addConnection(titleBar.InputBegan:Connect(function(input)
        if not scriptActive then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingWindow = true
            dragStartMouse = input.Position
            dragStartPos = panel.Position
        end
    end))

    addConnection(titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingWindow = false
        end
    end))

    addConnection(closeButton.MouseButton1Click:Connect(function()
        shutdownScript()
    end))

    addConnection(uiRefs.toggleEspButton.MouseButton1Click:Connect(function()
        if not scriptActive then
            return
        end

        SETTINGS.ESPEnabled = not SETTINGS.ESPEnabled
        updateToggleButton(uiRefs.toggleEspButton, "ESP", SETTINGS.ESPEnabled)
        refreshAllVisuals()
    end))

    addConnection(uiRefs.toggleTeamButton.MouseButton1Click:Connect(function()
        if not scriptActive then
            return
        end

        SETTINGS.TeamCheck = not SETTINGS.TeamCheck
        updateToggleButton(uiRefs.toggleTeamButton, "TeamCheck", SETTINGS.TeamCheck)
        refreshAllVisuals()
    end))

    addConnection(uiRefs.toggleAssistButton.MouseButton1Click:Connect(function()
        if not scriptActive then
            return
        end

        SETTINGS.AssistEnabled = not SETTINGS.AssistEnabled
        updateToggleButton(uiRefs.toggleAssistButton, "Assist", SETTINGS.AssistEnabled)
        updateRadiusUI()
    end))

    addConnection(uiRefs.toggleAimBotButton.MouseButton1Click:Connect(function()
        if not scriptActive then
            return
        end

        SETTINGS.AimBotEnabled = not SETTINGS.AimBotEnabled
        if not SETTINGS.AimBotEnabled then
            clearAimBotLock()
        end
        updateToggleButton(uiRefs.toggleAimBotButton, "AimBot", SETTINGS.AimBotEnabled)
    end))

    addConnection(uiRefs.toggleInfoButton.MouseButton1Click:Connect(function()
        if not scriptActive then
            return
        end

        SETTINGS.ShowInfo = not SETTINGS.ShowInfo
        updateToggleButton(uiRefs.toggleInfoButton, "Info", SETTINGS.ShowInfo)
        refreshAllVisuals()
    end))

    updateToggleButton(uiRefs.toggleEspButton, "ESP", SETTINGS.ESPEnabled)
    updateToggleButton(uiRefs.toggleTeamButton, "TeamCheck", SETTINGS.TeamCheck)
    updateToggleButton(uiRefs.toggleAssistButton, "Assist", SETTINGS.AssistEnabled)
    updateToggleButton(uiRefs.toggleAimBotButton, "AimBot", SETTINGS.AimBotEnabled)
    updateToggleButton(uiRefs.toggleInfoButton, "Info", SETTINGS.ShowInfo)
    updateRadiusUI()
end

createUi()

for _, player in ipairs(Players:GetPlayers()) do
    trackPlayer(player)
end

addConnection(Players.PlayerAdded:Connect(trackPlayer))
addConnection(Players.PlayerRemoving:Connect(cleanupPlayer))

addConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    if not scriptActive then
        return
    end

    refreshAllVisuals()
end))

addConnection(UserInputService.InputBegan:Connect(function(input)
    if not scriptActive then
        return
    end

    -- Do not block by gameProcessedEvent: many weapons consume RMB for ADS,
    -- and we still want assist while RMB is physically held.
    if input.UserInputType == Enum.UserInputType.MouseButton2 and SETTINGS.AssistHoldMouseButton2 then
        aimHoldingRMB = true
    end
end))

addConnection(UserInputService.InputEnded:Connect(function(input)
    if not scriptActive then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
        draggingWindow = false
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHoldingRMB = false
        clearAimBotLock()
    end
end))

addConnection(UserInputService.InputChanged:Connect(function(input)
    if not scriptActive then
        return
    end

    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        setRadiusFromPixel(input.Position.X)
    end

    if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement and dragStartMouse and dragStartPos then
        local delta = input.Position - dragStartMouse
        uiRefs.panel.Position = UDim2.new(
            dragStartPos.X.Scale,
            dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + delta.Y
        )
    end
end))

addConnection(RunService.RenderStepped:Connect(function(deltaTime)
    if not scriptActive then
        return
    end

    refreshAccumulator += deltaTime
    if refreshAccumulator >= SETTINGS.RefreshInterval then
        refreshAccumulator = 0
        refreshAllVisuals()
    end

    -- Fallback: keep RMB state synced even if input events are swallowed by weapon ADS logic.
    if SETTINGS.AssistHoldMouseButton2 then
        aimHoldingRMB = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end


    updateRadiusUI()
    updateAssist()
end))
