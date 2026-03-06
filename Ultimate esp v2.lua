-- Ultimate ESP v2: nearest enemy hard-lock (character faces target continuously)
-- LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local SETTINGS = {
    Enabled = true,
    TeamCheck = true,

    MaxLockDistance = 220,      -- studs
    ReacquireInterval = 0.03,   -- fast target refresh (~33 times/sec)
    RotateOnRenderStepped = true,
    AlsoAimCamera = true,       -- keep camera looking at locked enemy too
}

local currentTargetPlayer = nil
local reacquireClock = 0

local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
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

local function getLocalRoot()
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not isAlive(localCharacter) then
        return nil
    end

    return getRoot(localCharacter)
end

local function getNearestEnemyPlayer(localRoot)
    local nearestPlayer = nil
    local nearestDistance = SETTINGS.MaxLockDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = player.Character
            if character and isAlive(character) then
                local root = getRoot(character)
                if root then
                    local distance = (root.Position - localRoot.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end

    return nearestPlayer
end

local function isTargetStillValid(targetPlayer, localRoot)
    if not targetPlayer or not isEnemy(targetPlayer) then
        return false
    end

    local targetCharacter = targetPlayer.Character
    if not targetCharacter or not isAlive(targetCharacter) then
        return false
    end

    local targetRoot = getRoot(targetCharacter)
    if not targetRoot then
        return false
    end

    return (targetRoot.Position - localRoot.Position).Magnitude <= SETTINGS.MaxLockDistance
end

local function faceTarget(localRoot, targetRoot)
    local fromPosition = localRoot.Position
    local lookAtPosition = Vector3.new(targetRoot.Position.X, fromPosition.Y, targetRoot.Position.Z)
    localRoot.CFrame = CFrame.lookAt(fromPosition, lookAtPosition)

    if SETTINGS.AlsoAimCamera and Camera then
        local camPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.lookAt(camPos, targetRoot.Position)
    end
end

local function stepLock(deltaTime)
    if not SETTINGS.Enabled then
        currentTargetPlayer = nil
        return
    end

    local localRoot = getLocalRoot()
    if not localRoot then
        currentTargetPlayer = nil
        return
    end

    reacquireClock += deltaTime
    if reacquireClock >= SETTINGS.ReacquireInterval or not isTargetStillValid(currentTargetPlayer, localRoot) then
        reacquireClock = 0
        currentTargetPlayer = getNearestEnemyPlayer(localRoot)
    end

    if not currentTargetPlayer then
        return
    end

    local targetCharacter = currentTargetPlayer.Character
    local targetRoot = getRoot(targetCharacter)
    if not targetRoot then
        currentTargetPlayer = nil
        return
    end

    faceTarget(localRoot, targetRoot)
end

if SETTINGS.RotateOnRenderStepped then
    RunService.RenderStepped:Connect(stepLock)
else
    RunService.Heartbeat:Connect(stepLock)
end

print("[Ultimate ESP v2] nearest enemy lock loaded")
