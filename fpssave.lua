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
local guiName = "FPS_Ping_Tracker_" .. tostring(UserId)
if ParentTarget:FindFirstChild(guiName) then
    ParentTarget[guiName]:Destroy()
end

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- tránh lệch vị trí do status bar / notch trên mobile
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
TextLabel.Active = false -- không chặn raycast input kéo thả của MainFrame
TextLabel.Parent = MainFrame

---------------------------------------------------------
-- FIX KÉO THẢ (hỗ trợ cả chuột lẫn cảm ứng - mobile)
---------------------------------------------------------
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
        if dragging then
            updateDrag(input)
        end
    end
end)

-- Chuột: theo dõi qua UserInputService (vì chuột có thể ra khỏi frame khi kéo)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDrag(input)
    end
end)

-- Cảm ứng (mobile): dùng TouchMoved riêng vì Touch trên mobile
-- không luôn báo cập nhật ổn định qua InputChanged như chuột.
UserInputService.TouchMoved:Connect(function(touch, gameProcessedEvent)
    if dragging then
        updateDrag(touch)
    end
end)

---------------------------------------------------------
-- FIX FPS & PING (cập nhật ổn định, không phụ thuộc "task" lib)
---------------------------------------------------------
local frameCount = 0
local fpsCalculated = 0
local fpsTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    frameCount = frameCount + 1
    fpsTimer = fpsTimer + deltaTime
    if fpsTimer >= 1 then
        fpsCalculated = frameCount
        frameCount = 0
        fpsTimer = 0
    end
end)

-- Dùng spawn thường thay vì task.spawn để tương thích rộng hơn
-- (một số executor cũ không có "task" library -> task.spawn = nil -> lỗi im lặng,
-- khiến vòng lặp cập nhật UI không bao giờ chạy, đây là nguyên nhân chính khiến
-- FPS/Ping không hiển thị gì cả).
local spawnFn = (task and task.spawn) or spawn
local waitFn = (task and task.wait) or wait

spawnFn(function()
    while true do
        waitFn(0.5)

        local ping = 0
        local ok = pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if not ok then
            ping = -1 -- báo hiệu không lấy được ping, thay vì im lặng để 0
        end

        local pingText = ping >= 0 and (tostring(ping) .. "ms") or "N/A"
        TextLabel.Text = string.format("FPS: %d  |  Ping: %s", fpsCalculated, pingText)

        if fpsCalculated < 30 or (ping > 200) then
            TextLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        elseif fpsCalculated < 50 or (ping > 100) then
            TextLabel.TextColor3 = Color3.fromRGB(255, 220, 85)
        else
            TextLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        end
    end
end)
