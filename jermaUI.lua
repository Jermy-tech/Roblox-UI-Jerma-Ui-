local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local AimbotEnabled = false
local Smoothness = 0.2
local AimPart = "Head"
local FOV = 100
local KeybindToggle = Enum.KeyCode.E
local KeybindTurnOff = Enum.KeyCode.F -- Add a keybind to turn off CamLock

local PredictionMultiplier = 0.2

local CurrentTarget = nil

local function calcDist(point1, point2)
    return (point1 - point2).Magnitude
end

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(AimPart) then
            local character = player.Character
            local part = character[AimPart]
            local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)

            if onScreen then
                local dist = calcDist(Vector2.new(screenPos.X, screenPos.Y), Vector2.new(Mouse.X, Mouse.Y))
                if dist < shortestDistance then
                    closestPlayer = player
                    shortestDistance = dist
                end
            end
        end
    end

    return closestPlayer
end

local function getPartVelocity(part)
    local initialPosition = part.Position
    wait(0.1)
    local newPosition = part.Position
    return (newPosition - initialPosition) / 0.1
end

local function predictPosition(part)
    local velocity = getPartVelocity(part)
    return Vector3.new(part.Position.X + (velocity.X * PredictionMultiplier),
                       part.Position.Y,
                       part.Position.Z + (velocity.Z * PredictionMultiplier))
end

local function smoothCameraTo(targetPos)
    local cameraPos = Camera.CFrame.Position
    local direction = (targetPos - cameraPos).Unit
    local newCFrame = CFrame.new(cameraPos, cameraPos + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Smoothness)
end

local function updateTarget()
    if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChild(AimPart) then
        CurrentTarget = getClosestPlayerToCursor()
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        -- Toggle CamLock on/off with KeybindToggle
        if input.KeyCode == KeybindToggle then
            AimbotEnabled = not AimbotEnabled
            if not AimbotEnabled then
                CurrentTarget = nil
            end
        end

        -- Turn off CamLock with KeybindTurnOff
        if input.KeyCode == KeybindTurnOff then
            AimbotEnabled = false
            CurrentTarget = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        updateTarget()
        if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(AimPart) then
            local targetPart = CurrentTarget.Character[AimPart]
            local predictedPos = predictPosition(targetPart)
            smoothCameraTo(predictedPos)
        end
    else
        CurrentTarget = nil
    end
end)

-- Return AimbotEnabled status for toggling in UI
return AimbotEnabled
