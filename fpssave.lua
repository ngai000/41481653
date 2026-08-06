-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer.UserId
local ConfigFileName = "FPS_Ping_Pos_" .. tostring(UserId) .. ".json"

-- Default Position
local defaultPos = {XScale = 0.85, XOffset = 0, YScale = 0.05, YOffset = 0}

-- Read / Save File Config
local function loadSavedPosition()
    if isfile and readfile and isfile(ConfigFileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end)
        if success and type(result) == "table" then
            return UDim2.new(result.XScale or 0, result.XOffset or 0, result.YScale or 0, result.YOffset or 0)
        end
    end
    return UDim2.new(defaultPos.XScale, defaultPos.XOffset, defaultPos.YScale, defaultPos.YOffset)
end

local function savePosition(udim2)
    if writefile then
        local data = {
            XScale = udim2.XScale.Scale,
            XOffset = udim2.XScale.Offset,
            YScale = udim2.YScale.Scale,
            YOffset = udim2.YScale.Offset
        }
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(data))
        end)
    end
end

-- UI Parent Protection
local ParentTarget
if gethui then
    ParentTarget = gethui()
elseif syn and syn.protect_gui then
    ParentTarget = game:GetService("CoreGui")
    pcall(syn.protect_gui, ParentTarget)
else
    ParentTarget = LocalPlayer:WaitForChild("PlayerGui")
end

-- Clean old UI if re-executed
if ParentTarget:FindFirstChild("FPS_Ping_Tracker_" .. tostring(UserId)) then
    ParentTarget["FPS_Ping_Tracker_" .. tostring(UserId)]:Destroy()
end

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPS_Ping_Tracker_" .. tostring(UserId)
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentTarget

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 160, 0, 40)
MainFrame.Position = loadSavedPosition()
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Selectable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim2.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(70, 70, 70)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 1, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.Font = Enum.Font.GothamBold
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 13
TextLabel.Text = "FPS: ... | Ping: ..."
TextLabel.Active = false -- FIX: Bỏ active để không chặn raycast input kéo thả của MainFrame
TextLabel.Parent = MainFrame

---------------------------------------------------------
-- FIX LỖI KÉO THẢ (Drag Engine mới)
---------------------------------------------------------
local dragging = false
local dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                connection:Disconnect()
                savePosition(MainFrame.Position)
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

---------------------------------------------------------
-- FIX LỖI FPS & PING (Thay đổi cơ chế đo)
---------------------------------------------------------
local fpsCalculated = 0
local timeAcc = 0

-- Tính FPS theo DeltaTime thực tế của frame
RunService.RenderStepped:Connect(function(deltaTime)
    fpsCalculated = math.floor(1 / deltaTime)
end)

-- Loop riêng cập nhật UI định kỳ 0.5s (hoạt động tốt cả khi tab ẩn/chạy ẩn)
task.spawn(function()
    while task.wait(0.5) do
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        TextLabel.Text = string.format("FPS: %d  |  Ping: %dms", fpsCalculated, ping)

        -- Đổi màu chỉ báo
        if fpsCalculated < 30 or ping > 200 then
            TextLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        elseif fpsCalculated < 50 or ping > 100 then
            TextLabel.TextColor3 = Color3.fromRGB(255, 220, 85)
        else
            TextLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        end
    end
end)
