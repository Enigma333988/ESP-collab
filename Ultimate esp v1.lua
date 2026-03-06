-- Enemy-only ESP with team check (allies are ignored)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local SETTINGS = {
    Enabled = true,
    TeamCheck = true,
    UseTeamColor = false,
    EnemyColor = Color3.fromRGB(255, 70, 70),
    FillTransparency = 0.75,
    OutlineTransparency = 0,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
}

local highlights = {}

local function isEnemy(player)
    if player == LocalPlayer then
        return false
    end

    if not SETTINGS.TeamCheck then
        return true
    end

    -- If either side has no team, treat as enemy to avoid missing targets
    if LocalPlayer.Team == nil or player.Team == nil then
        return true
    end

    return player.Team ~= LocalPlayer.Team
end

local function cleanupHighlight(player)
    local highlight = highlights[player]
    if highlight then
        highlight:Destroy()
        highlights[player] = nil
    end
end

local function applyHighlight(player)
    if not SETTINGS.Enabled then
        cleanupHighlight(player)
        return
    end

    if not isEnemy(player) then
        cleanupHighlight(player)
        return
    end

    local character = player.Character
    if not character then
        cleanupHighlight(player)
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        cleanupHighlight(player)
        return
    end

    local highlight = highlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "EnemyESP"
        highlight.Parent = character
        highlights[player] = highlight
    else
        highlight.Parent = character
    end

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

local function trackPlayer(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        applyHighlight(player)
    end)

    player.CharacterRemoving:Connect(function()
        cleanupHighlight(player)
    end)

    applyHighlight(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    trackPlayer(player)
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(cleanupHighlight)

-- Re-evaluate continuously so team swaps and respawns are reflected
RunService.RenderStepped:Connect(function()
    if not SETTINGS.Enabled then
        for player in pairs(highlights) do
            cleanupHighlight(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyHighlight(player)
        end
    end
end)
