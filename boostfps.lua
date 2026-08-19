
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local CaptureInstanceSnapshots = false
local OriginalState = {
    Lighting = {},
    Terrain = {},
    QualityLevel = nil,
    PostProcessing = {}, -- [effect] = wasEnabled
}
local InstanceSnapshots = setmetatable({}, { __mode = "k" })
local Connection_WorldOrigin = nil
local IsBoostActive = false
local function SnapshotInstance(instance)
    if not CaptureInstanceSnapshots then return end
    if InstanceSnapshots[instance] then return end -- đã lưu rồi thì thôi
    local ok, snap = pcall(function()
        if instance:IsA("BasePart") then
            return {
                kind = "BasePart",
                Material = instance.Material,
                Reflectance = instance.Reflectance,
            }
        elseif instance:IsA("Decal") then
            return { kind = "Decal", Transparency = instance.Transparency }
        elseif instance:IsA("ParticleEmitter") then
            return {
                kind = "ParticleEmitter",
                Enabled = instance.Enabled,
                Lifetime = instance.Lifetime,
            }
        elseif instance:IsA("Explosion") then
            return {
                kind = "Explosion",
                Enabled = instance.Enabled,
                BlastPressure = instance.BlastPressure,
                BlastRadius = instance.BlastRadius,
            }
        elseif instance:IsA("Fire") or instance:IsA("Smoke")
            or instance:IsA("Sparkles") or instance:IsA("Light") then
            return { kind = "Toggleable", Enabled = instance.Enabled }
        end
        return nil
    end)

    if ok and snap then
        InstanceSnapshots[instance] = snap
    end
end
local function ApplyFastGraphics(instance)
    pcall(function()
        if instance:IsA("BasePart") then
            SnapshotInstance(instance)
            instance.Material = Enum.Material.Plastic
            instance.Reflectance = 0
            if instance:IsA("MeshPart") then
                instance.TextureID = ""
            end
        elseif instance:IsA("Decal") then
            SnapshotInstance(instance)
            instance.Transparency = 1
        elseif instance:IsA("Texture") then
            if not instance:GetAttribute("Offset") then
                instance:Destroy()
            end
        elseif instance:IsA("ParticleEmitter") then
            if instance.Parent and instance.Parent.Name ~= "RelicFire" then
                SnapshotInstance(instance)
                instance.Enabled = false
                instance.Lifetime = NumberRange.new(0)
            end
        elseif instance:IsA("Explosion") then
            SnapshotInstance(instance)
            instance.Enabled = false
            instance.BlastPressure = 1
            instance.BlastRadius = 1
        elseif instance:IsA("Fire") or instance:IsA("Smoke")
            or instance:IsA("Sparkles") or instance:IsA("Light") then
            SnapshotInstance(instance)
            instance.Enabled = false
        end
    end)
end
local function RestoreInstance(instance, snap)
    pcall(function()
        if not instance or not instance.Parent then return end

        if snap.kind == "BasePart" then
            instance.Material = snap.Material
            instance.Reflectance = snap.Reflectance
        elseif snap.kind == "Decal" then
            instance.Transparency = snap.Transparency
        elseif snap.kind == "ParticleEmitter" then
            instance.Enabled = snap.Enabled
            instance.Lifetime = snap.Lifetime
        elseif snap.kind == "Explosion" then
            instance.Enabled = snap.Enabled
            instance.BlastPressure = snap.BlastPressure
            instance.BlastRadius = snap.BlastRadius
        elseif snap.kind == "Toggleable" then
            instance.Enabled = snap.Enabled
        end
    end)
end
local function DisablePostProcessing()
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect")
        or effect:IsA("SunRaysEffect")
        or effect:IsA("ColorCorrectionEffect")
        or effect:IsA("BloomEffect")
        or effect:IsA("DepthOfFieldEffect") then
            if OriginalState.PostProcessing[effect] == nil then
                OriginalState.PostProcessing[effect] = effect.Enabled
            end
            effect.Enabled = false
        end
    end
end
local function RestorePostProcessing()
    for effect, wasEnabled in pairs(OriginalState.PostProcessing) do
        pcall(function()
            if effect and effect.Parent then
                effect.Enabled = wasEnabled
            end
        end)
    end
    OriginalState.PostProcessing = {}
end
local function ProcessInstancesWithBudget(instanceList, maxBudgetSec)
    local startTime = os.clock()
    for _, inst in next, instanceList do
        pcall(function()
            if inst:IsA("BasePart") then
                SnapshotInstance(inst)
                inst.Material = Enum.Material.SmoothPlastic
            elseif inst:IsA("Texture") then
                if not inst:GetAttribute("Offset") then
                    inst:Destroy()
                end
            end
        end)
        if (os.clock() - startTime) > maxBudgetSec then
            task.wait()
            startTime = os.clock()
        end
    end
end
local function NotifyOptimizerActor(state)
    pcall(function()
        local optimizerActor = LocalPlayer:FindFirstChild("PlayerScripts")
            and LocalPlayer.PlayerScripts:FindFirstChild("OptimizerClientActor")
        if optimizerActor then
            optimizerActor:SendMessage("Optimize", state)
        end
    end)
end
local function EnableBoost()
    if IsBoostActive then return end
    IsBoostActive = true

    pcall(function()
        local terrain = Workspace.Terrain
        OriginalState.Terrain = {
            WaterWaveSize = terrain.WaterWaveSize,
            WaterWaveSpeed = terrain.WaterWaveSpeed,
            WaterReflectance = terrain.WaterReflectance,
            WaterTransparency = terrain.WaterTransparency,
        }
        OriginalState.Lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            Brightness = Lighting.Brightness,
        }
        OriginalState.QualityLevel = settings().Rendering.QualityLevel
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    for _, desc in pairs(Workspace:GetDescendants()) do
        ApplyFastGraphics(desc)
    end
    DisablePostProcessing()
    task.spawn(function()
        task.wait(0.5)
        local mapFolder = Workspace:WaitForChild("Map", 2)
        if mapFolder and IsBoostActive then
            ProcessInstancesWithBudget(mapFolder:GetDescendants(), 0.00833)
        end

        local unloadedFolder = ReplicatedStorage:FindFirstChild("Unloaded")
        if unloadedFolder and IsBoostActive then
            ProcessInstancesWithBudget(unloadedFolder:GetDescendants(), 0.00833)
        end
    end)
    NotifyOptimizerActor(true)
    task.spawn(function()
        local worldOrigin = Workspace:WaitForChild("_WorldOrigin", 5)
        if worldOrigin then
            if Connection_WorldOrigin then Connection_WorldOrigin:Disconnect() end
            Connection_WorldOrigin = worldOrigin.DescendantAdded:Connect(function(child)
                if IsBoostActive then
                    ApplyFastGraphics(child)
                end
            end)
        end
    end)
end

local function DisableBoost()
    if not IsBoostActive then return end
    IsBoostActive = false
    if Connection_WorldOrigin then
        Connection_WorldOrigin:Disconnect()
        Connection_WorldOrigin = nil
    end
    pcall(function()
        local terrain = Workspace.Terrain
        if OriginalState.Terrain.WaterWaveSize ~= nil then
            terrain.WaterWaveSize = OriginalState.Terrain.WaterWaveSize
            terrain.WaterWaveSpeed = OriginalState.Terrain.WaterWaveSpeed
            terrain.WaterReflectance = OriginalState.Terrain.WaterReflectance
            terrain.WaterTransparency = OriginalState.Terrain.WaterTransparency
        end

        if OriginalState.Lighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = OriginalState.Lighting.GlobalShadows
            Lighting.FogEnd = OriginalState.Lighting.FogEnd
            Lighting.Brightness = OriginalState.Lighting.Brightness
        end

        if OriginalState.QualityLevel then
            settings().Rendering.QualityLevel = OriginalState.QualityLevel
        end
    end)
    RestorePostProcessing()
    if CaptureInstanceSnapshots then
        task.spawn(function()
            local count = 0
            local startTime = os.clock()
            for instance, snap in pairs(InstanceSnapshots) do
                RestoreInstance(instance, snap)
                count += 1
                if (os.clock() - startTime) > 0.00833 then
                    task.wait()
                    startTime = os.clock()
                end
            end
            InstanceSnapshots = setmetatable({}, { __mode = "k" })
            print("[BoostFPS] Đã phục hồi " .. count .. " object về trạng thái gốc.")
        end)
    else
        print("[BoostFPS] CaptureInstanceSnapshots = false, chỉ phục hồi Lighting/Terrain/QualityLevel. " ..
              "Các Part đổi Material sẽ tự về gốc khi khu vực đó reload.")
    end
    NotifyOptimizerActor(false)
end
local function SetBoostFPS(enabled)
    Settings["Boost Fps"] = enabled
    SaveSettings("Boost Fps", enabled)

    if enabled then
        EnableBoost()
    else
        DisableBoost()
    end
end
local BoostToggle = {
    Title = "Boost Fps",
    Desc = "Tối ưu hóa tài nguyên, hạ đồ họa để tăng FPS tối đa",
    Default = Settings["Boost Fps"] or false
}
RegisterUIOption(BoostToggle, function(Value)
    SetBoostFPS(Value)
end)
if Settings["Boost Fps"] then
    task.spawn(function()
        SetBoostFPS(true)
    end)
end
