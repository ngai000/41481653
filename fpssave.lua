local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------
-- UI Setup (giảm còn ~60% kích thước gốc: 300x50 -> 180x30)
---------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui
screenGui.DisplayOrder = 100
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 180, 0, 30)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Selectable = true

local textLabel = Instance.new("TextLabel")
textLabel.Parent = mainFrame
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.Font = Enum.Font.FredokaOne
textLabel.TextScaled = true
textLabel.BackgroundTransparency = 1
textLabel.TextStrokeTransparency = 0
textLabel.Active = false -- không chặn input kéo thả của mainFrame

---------------------------------------------------------
-- Kéo thả (hỗ trợ chuột + cảm ứng mobile)
---------------------------------------------------------
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                connection:Disconnect()
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        updateDrag(input)
    end
end)

UserInputService.TouchMoved:Connect(function(touch)
    if dragging then
        updateDrag(touch)
    end
end)

---------------------------------------------------------
-- Hiệu ứng cầu vồng cho chữ FPS (giữ như bản gốc)
---------------------------------------------------------
local hue = 0
spawn(function()
    while true do
        hue = hue + 0.01
        if hue > 1 then hue = 0 end
        textLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
        RunService.RenderStepped:Wait()
    end
end)

---------------------------------------------------------
-- FPS + Ping + RAM
---------------------------------------------------------
local frameCount = 0
local lastUpdate = tick()
local currentFps = 0
local currentPing = 0
local currentRam = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()

    if now - lastUpdate >= 1 then
        currentFps = math.floor(frameCount / (now - lastUpdate))
        frameCount = 0
        lastUpdate = now

        local okPing = pcall(function()
            currentPing = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if not okPing then currentPing = -1 end

        local okRam = pcall(function()
            currentRam = math.floor(Stats:GetTotalMemoryUsageMb())
        end)
        if not okRam then currentRam = -1 end

        local pingText = currentPing >= 0 and (currentPing .. "ms") or "N/A"
        local ramText = currentRam >= 0 and (currentRam .. "MB") or "N/A"

        textLabel.Text = string.format("FPS: %d | Ping: %s | RAM: %s", currentFps, pingText, ramText)
    end
end)
