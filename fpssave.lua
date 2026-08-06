-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer.UserId
local ConfigFileName = "FPS_Ping_Pos_" .. tostring(UserId) .. ".json"

-- Default Position (Bottom-Right / Top-Right tùy chỉnh)
local defaultPos = {XScale = 0.85, XOffset = 0, YScale = 0.05, YOffset = 0}

-- Hàm load vị trí đã lưu của acc này
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

-- Hàm lưu vị trí mới cho acc này
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

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPS_Ping_Tracker_" .. tostring(UserId)
ScreenGui.ResetOnSpawn = false

-- Bảo vệ UI khỏi bị game detect cơ bản (nếu executor hỗ trợ)
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 160, 0, 50)
MainFrame.Position = loadSavedPosition()
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim2.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 60)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 1, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.Font = Enum.Font.GothamBold
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 13
TextLabel.Text = "FPS: -- | Ping: --ms"
TextLabel.Parent = MainFrame

-- Logic Kéo Thả (Drag & Drop) + Lưu Tọa Độ
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + delta.X, 
        startPos.Y.Scale, 
        startPos.Y.Offset + delta.Y
    )
    MainFrame.Position = newPos
    return newPos
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                savePosition(MainFrame.Position) -- Lưu vị trí ngay khi buông chuột/tay
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
        updateDrag(input)
    end
end)

-- Logic Cập Nhật FPS & Ping
local frameCount = 0
local lastUpdate = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    
    if currentTime - lastUpdate >= 0.5 then -- Cập nhật mỗi 0.5s để tránh giật lag UI
        local fps = math.floor(frameCount / (currentTime - lastUpdate))
        frameCount = 0
        lastUpdate = currentTime
        
        -- Lấy Ping chuẩn từ PerformanceStats
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        
        TextLabel.Text = string.format("FPS: %d  |  Ping: %dms", fps, ping)
        
        -- Đổi màu chữ theo chất lượng mạng/FPS
        if fps < 30 or ping > 200 then
            TextLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        elseif fps < 50 or ping > 100 then
            TextLabel.TextColor3 = Color3.fromRGB(255, 220, 85)
        else
            TextLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        end
    end
end)
