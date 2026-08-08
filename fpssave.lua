local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Locations = Workspace:WaitForChild("_WorldOrigin"):WaitForChild("Locations")

-- Config
_G.HighestMirage = true
local TWEEN_SPEED = 300

local MirageHighlight = nil
local MirageBillboard = nil
local DistanceConnection = nil
local MirageDetected = false
local CurrentTween = nil

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

local function CleanupESP()
    if DistanceConnection then
        DistanceConnection:Disconnect()
        DistanceConnection = nil
    end
    if MirageHighlight then
        MirageHighlight:Destroy()
        MirageHighlight = nil
    end
    if MirageBillboard then
        MirageBillboard:Destroy()
        MirageBillboard = nil
    end
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
end

local function TweenTo(targetCFrame)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance <= 15 then return end

    local time = distance / TWEEN_SPEED
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    if CurrentTween then
        CurrentTween:Cancel()
    end

    CurrentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    CurrentTween:Play()
end

local function CreateMirageESP()
    CleanupESP()

    local Mirage = Locations:FindFirstChild("Mirage Island")
    if not Mirage then return end

    -- 1. Highlight
    MirageHighlight = Instance.new("Highlight")
    MirageHighlight.Name = "MirageIslandESP"
    MirageHighlight.Adornee = Mirage
    MirageHighlight.FillTransparency = 0.5
    MirageHighlight.OutlineTransparency = 0
    MirageHighlight.FillColor = Color3.fromRGB(0, 255, 255)
    MirageHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    MirageHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    MirageHighlight.Parent = Mirage

    -- 2. BillboardGui (Màn hình & Khoảng cách)
    MirageBillboard = Instance.new("BillboardGui")
    MirageBillboard.Name = "MirageIslandUI"
    MirageBillboard.Adornee = Mirage
    MirageBillboard.Size = UDim2.new(0, 200, 0, 50)
    MirageBillboard.StudsOffset = Vector3.new(0, 50, 0)
    MirageBillboard.AlwaysOnTop = true
    MirageBillboard.Parent = Mirage

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextSize = 16
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.Text = "🌴 Mirage Island\n[ Tính toán... ]"
    TextLabel.Parent = MirageBillboard

    -- 3. Cập nhật khoảng cách Real-time
    DistanceConnection = RunService.RenderStepped:Connect(function()
        if Mirage and Mirage.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local charPos = LocalPlayer.Character.HumanoidRootPart.Position
            local miragePos = Mirage:GetPivot().Position
            local distance = math.floor((charPos - miragePos).Magnitude)
            
            TextLabel.Text = string.format("🌴 Mirage Island\n[%dm]", distance)
        end
    end)

    Notify("🌴 Mirage Island", "🟢 Mirage Island đã xuất hiện!")
end

local function RemoveMirageESP()
    CleanupESP()
    Notify("🌴 Mirage Island", "🔴 Mirage Island đã biến mất!")
end

local function CheckMirage()
    local exists = Locations:FindFirstChild("Mirage Island") ~= nil

    if exists and not MirageDetected then
        MirageDetected = true
        CreateMirageESP()
    elseif not exists and MirageDetected then
        MirageDetected = false
        RemoveMirageESP()
    end
end

-- Task Auto Tween bay đến điểm cao nhất
task.spawn(function()
    while task.wait(1) do
        if _G.HighestMirage then
            pcall(function()
                if Locations:FindFirstChild("Mirage Island") then
                    local mapMystic = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("MysticIsland")
                    if mapMystic and mapMystic:FindFirstChild("Center") then
                        local targetPos = mapMystic.Center.CFrame * CFrame.new(0, 400, 0)
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if hrp and (hrp.Position - targetPos.Position).Magnitude > 15 then
                            TweenTo(targetPos)
                        end
                    end
                end
            end)
        end
    end
end)

-- Khởi chạy ban đầu
CheckMirage()

-- Theo dõi sự kiện
Locations.ChildAdded:Connect(function(child)
    if child.Name == "Mirage Island" then
        task.wait(0.2)
        CheckMirage()
    end
end)

Locations.ChildRemoved:Connect(function(child)
    if child.Name == "Mirage Island" then
        CheckMirage()
    end
end)

-- Backup Loop
task.spawn(function()
    while task.wait(1) do
        CheckMirage()
    end
end)
