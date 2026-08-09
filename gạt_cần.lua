local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Locations = Workspace:WaitForChild("_WorldOrigin"):WaitForChild("Locations")

-- Config
_G.HighestMirage = true -- Mặc định TẮT tự động bay lên đỉnh đảo
_G.AutoInteractGear = true 

local TWEEN_SPEED = 300

local MirageHighlight = nil
local MirageBillboard = nil
local DistanceConnection = nil
local NoclipConnection = nil
local MirageDetected = false
local CurrentTween = nil
local IsArrived = false
local FloatBV = nil
local IsTPingGear = false

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- 1. Quản lý Noclip & Float
local function EnableNoclipAndFloat()
    if not NoclipConnection then
        NoclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end

    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not FloatBV or FloatBV.Parent ~= hrp then
                if FloatBV then FloatBV:Destroy() end
                FloatBV = Instance.new("BodyVelocity")
                FloatBV.Name = "MirageFloatVelocity"
                FloatBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                FloatBV.Velocity = Vector3.zero
                FloatBV.Parent = hrp
            end
        end
    end
end

local function DisableNoclipAndFloat()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    if FloatBV then
        FloatBV:Destroy()
        FloatBV = nil
    end
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- 2. Clear Fog
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
    DisableNoclipAndFloat()
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
    IsTPingGear = false
end

-- 3. Hàm Tween Di Chuyển
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
        return true
    end

    EnableNoclipAndFloat()

    local time = distance / TWEEN_SPEED
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    if CurrentTween then
        CurrentTween:Cancel()
    end

    CurrentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    CurrentTween:Play()
    return false
end

-- 4. ESP Mirage Island
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

-- 5. UI Khởi tạo
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GearToggleGui"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

-- 5.1 Nút Bấm TP Gear
local ActionBtn = Instance.new("TextButton")
ActionBtn.Name = "TPGearBtn"
ActionBtn.Size = UDim2.new(0, 140, 0, 40)
ActionBtn.Position = UDim2.new(0, 20, 0.4, 0)
ActionBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionBtn.TextSize = 14
ActionBtn.Font = Enum.Font.SourceSansBold
ActionBtn.Text = "TP To Gear"
ActionBtn.Parent = ScreenGui

local Corner1 = Instance.new("UICorner")
Corner1.CornerRadius = UDim.new(0, 8)
Corner1.Parent = ActionBtn

-- 5.2 Nút Công tắc Auto Mirage
local MirageToggleBtn = Instance.new("TextButton")
MirageToggleBtn.Name = "MirageToggleBtn"
MirageToggleBtn.Size = UDim2.new(0, 140, 0, 40)
MirageToggleBtn.Position = UDim2.new(0, 20, 0.4, 48) -- Nằm ngay bên dưới nút TP Gear
MirageToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
MirageToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MirageToggleBtn.TextSize = 14
MirageToggleBtn.Font = Enum.Font.SourceSansBold
MirageToggleBtn.Text = "Auto Mirage: on"
MirageToggleBtn.Parent = ScreenGui

local Corner2 = Instance.new("UICorner")
Corner2.CornerRadius = UDim.new(0, 8)
Corner2.Parent = MirageToggleBtn

-- Sự kiện Click Nút TP Gear
ActionBtn.MouseButton1Click:Connect(function()
    if IsTPingGear then return end

    if not Locations:FindFirstChild("Mirage Island") then
        Notify("⚙️ TP Gear", "Chưa xuất hiện Mirage Island!")
        return
    end

    IsTPingGear = true
    ActionBtn.Text = "Teleporting..."
    ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)

    task.spawn(function()
        local gearPart = nil
        local mysticIsland = Workspace.Map:FindFirstChild("MysticIsland")
        
        if mysticIsland then
            for _, part in pairs(mysticIsland:GetChildren()) do
                if part.Name == "Part" and part:IsA("MeshPart") then
                    gearPart = part
                    break
                end
            end
        end

        if gearPart then
            Notify("⚙️ TP Gear", "Đã tìm thấy Gear! Đang di chuyển...")
            
            while gearPart and gearPart.Parent and IsTPingGear do
                local arrived = TweenTo(gearPart.CFrame * CFrame.new(0, 2, 0))
                
                if arrived or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - gearPart.Position).Magnitude <= 15) then
                    if _G.AutoInteractGear then
                        for _, prompt in pairs(gearPart:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                    Notify("⚙️ TP Gear", "Đã tới vị trí Gear!")
                    DisableNoclipAndFloat()
                    break
                end
                task.wait(0.1)
            end
        else
            Notify("⚙️ TP Gear", "Chưa tìm thấy Gear trên đảo!")
        end

        IsTPingGear = false
        ActionBtn.Text = "TP To Gear"
        ActionBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
    end)
end)

-- Sự kiện Click Nút Auto Mirage
MirageToggleBtn.MouseButton1Click:Connect(function()
    _G.HighestMirage = not _G.HighestMirage
    
    if _G.HighestMirage then
        MirageToggleBtn.Text = "Auto Mirage: ON"
        MirageToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
        Notify("🌴 Auto Mirage", "Đã BẬT tự động đến đỉnh Mirage Island")
    else
        MirageToggleBtn.Text = "Auto Mirage: OFF"
        MirageToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        
        -- Reset trạng thái ngay lập tức khi tắt
        IsArrived = false
        if CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end
        DisableNoclipAndFloat()
        Notify("🌴 Auto Mirage", "Đã TẮT - Khôi phục di chuyển bình thường")
    end
end)

-- 6. Task Logic Vận Hành
task.spawn(function()
    while task.wait(0.1) do
        if Locations:FindFirstChild("Mirage Island") then
            -- Chỉ chạy nếu BẬT Auto Mirage và KHÔNG trong quá trình TP Gear
            if _G.HighestMirage and not IsTPingGear then
                pcall(function()
                    local mapMystic = Workspace.Map:FindFirstChild("MysticIsland")
                    if mapMystic and mapMystic:FindFirstChild("Center") then
                        local targetPos = mapMystic.Center.CFrame * CFrame.new(0, 400, 0)
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local distance = (hrp.Position - targetPos.Position).Magnitude
                            if distance <= 10 then
                                IsArrived = true
                                if CurrentTween then 
                                    CurrentTween:Cancel() 
                                    CurrentTween = nil
                                end
                                -- Giữ lơ lửng tại chỗ khi đã tới đỉnh, không rơi
                                EnableNoclipAndFloat() 
                            else
                                IsArrived = false
                                TweenTo(targetPos)
                            end
                        end
                    end
                end)
            end
        else
            if not IsTPingGear and not _G.HighestMirage then
                DisableNoclipAndFloat()
            end
        end
    end
end)

-- Khởi chạy ban đầu
ClearFog()
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

task.spawn(function()
    while task.wait(1) do
        CheckMirage()
        ClearFog()
    end
end)
