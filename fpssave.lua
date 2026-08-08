local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Locations = Workspace:WaitForChild("_WorldOrigin"):WaitForChild("Locations")

-- Cấu hình mặc định
_G.HighestMirage = true
_G.TPGEAR = true          -- Bật/Tắt tự động tìm & bay đến Gear
_G.AutoInteractGear = true -- Bật/Tắt tự động nhặt/kích hoạt Gear khi lại gần

local TWEEN_SPEED = 300

local MirageHighlight = nil
local MirageBillboard = nil
local DistanceConnection = nil
local MirageDetected = false
local CurrentTween = nil
local IsArrived = false

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- 1. Xóa Sương Mù (Clear Fog)
local function ClearFog()
    pcall(function()
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 0
        if Lighting:FindFirstChildOfClass("Atmosphere") then
            Lighting:FindFirstChildOfClass("Atmosphere"):Destroy()
        end
    end)
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("PostEffect") then
            v:Destroy()
        end
    end
end

Lighting.ChildAdded:Connect(function(child)
    if child:IsA("Atmosphere") or child:IsA("PostEffect") then
        task.defer(function()
            child:Destroy()
        end)
    end
end)

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
    IsArrived = false
end

-- 2. Hàm Tween Di Chuyển
local function TweenTo(targetCFrame)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance <= 10 then
        if CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end
        return true -- Trả về true nếu đã tới nơi
    end

    local time = distance / TWEEN_SPEED
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    if CurrentTween then
        CurrentTween:Cancel()
    end

    CurrentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    CurrentTween:Play()
    return false
end

-- 3. ESP Mirage Island
local function CreateMirageESP()
    CleanupESP()

    local Mirage = Locations:FindFirstChild("Mirage Island")
    if not Mirage then return end

    MirageHighlight = Instance.new("Highlight")
    MirageHighlight.Name = "MirageIslandESP"
    MirageHighlight.Adornee = Mirage
    MirageHighlight.FillTransparency = 0.5
    MirageHighlight.OutlineTransparency = 0
    MirageHighlight.FillColor = Color3.fromRGB(0, 255, 255)
    MirageHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    MirageHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    MirageHighlight.Parent = Mirage

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

-- 4. Tạo UI Nút Bật/Tắt Tự Nhặt Gear (Dành cho Cả Mobile & PC)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GearToggleGui"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleGearBtn"
ToggleBtn.Size = UDim2.new(0, 140, 0, 40)
ToggleBtn.Position = UDim2.new(0, 20, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "Auto Gear: ON"
ToggleBtn.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    _G.TPGEAR = not _G.TPGEAR
    _G.AutoInteractGear = _G.TPGEAR
    if _G.TPGEAR then
        ToggleBtn.Text = "Auto Gear: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
        Notify("⚙️ Auto Gear", "Đã BẬT tự động bay & nhặt Gear")
    else
        ToggleBtn.Text = "Auto Gear: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        Notify("⚙️ Auto Gear", "Đã TẮT tự động bay & nhặt Gear")
    end
end)

-- 5. Task Tự Động Bay & Nhặt Gear / Bay Đỉnh Đảo
task.spawn(function()
    while task.wait(0.2) do
        if Locations:FindFirstChild("Mirage Island") then
            local gearFound = false

            -- Ưu tiên 1: Tự tìm & Bay đến Gear
            if _G.TPGEAR then
                pcall(function()
                    local mysticIsland = Workspace.Map:FindFirstChild("MysticIsland")
                    if mysticIsland then
                        for _, part in pairs(mysticIsland:GetChildren()) do
                            if part.Name == "Part" and part:IsA("MeshPart") then
                                gearFound = true
                                local arrived = TweenTo(part.CFrame * CFrame.new(0, 2, 0))
                                
                                -- Tự động nhặt / Tương tác ProximityPrompt khi đến gần
                                if arrived or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - part.Position).Magnitude <= 15) then
                                    if _G.AutoInteractGear then
                                        for _, prompt in pairs(part:GetDescendants()) do
                                            if prompt:IsA("ProximityPrompt") then
                                                fireproximityprompt(prompt)
                                            end
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end
                end)
            end

            -- Ưu tiên 2: Bay lên đỉnh đảo Mirage nếu không thấy Gear
            if not gearFound and _G.HighestMirage and not IsArrived then
                pcall(function()
                    local mapMystic = Workspace.Map:FindFirstChild("MysticIsland")
                    if mapMystic and mapMystic:FindFirstChild("Center") then
                        local targetPos = mapMystic.Center.CFrame * CFrame.new(0, 400, 0)
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - targetPos.Position).Magnitude <= 15 then
                            IsArrived = true
                            if CurrentTween then CurrentTween:Cancel() end
                        else
                            TweenTo(targetPos)
                        end
                    end
                end)
            end
        end
    end
end)

-- Khởi chạy No Fog
ClearFog()

-- Khởi chạy kiểm tra Mirage
CheckMirage()

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

-- Loop duy trì Clear Fog & Check
task.spawn(function()
    while task.wait(1) do
        CheckMirage()
        ClearFog()
    end
end)
