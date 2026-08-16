-- =================================================================
-- PREHISTORIC AUTO FIND & BOAT SYSTEM (REFACTORED FROM USER CODE)
-- LOCK SPEED: 250 | MAGNET SCANNER: 5 SECONDS
-- =================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local BOAT_SPEED = 250 -- Chuẩn hóa tốc độ thuyền toàn bộ hệ thống

-- Hàm gửi thông báo hệ thống
local function SendNotify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-- 1. QUÉT VOLCANIC MAGNET TRONG TÚI (MỖI 5 GIÂY)
task.spawn(function()
    while task.wait(5) do
        local hasMagnet = CheckItemInventory("Volcanic Magnet")
        getgenv().dacoMagnet = hasMagnet

        if not hasMagnet then
            SendNotify("SYSTEM WARNING", "Chưa có Volcanic Magnet trong túi!")
            
            -- Hủy các tween thuyền đang chạy nếu mất Magnet
            if getgenv().TweenBoat then pcall(function() getgenv().TweenBoat:Cancel() end) end
            if getgenv().TweenBoatBack then pcall(function() getgenv().TweenBoatBack:Cancel() end) end
        end
    end
end)

-- 2. HÀM TÌM ĐẢO & MUA THUYỀN (GIỮ NGUYÊN LOGIC GỐC CỦA CÂU)
local function AutoFindPrehistoric()
    local mainGui = localPlayer:FindFirstChild("PlayerGui") and localPlayer.PlayerGui:FindFirstChild("Main")
    if not mainGui then return end

    local topHUD = mainGui:FindFirstChild("TopHUDList")
    local isPrehistoricTimer = topHUD and topHUD:FindFirstChild("PrehistoricRaidTimer") and topHUD.PrehistoricRaidTimer.Visible
    local isRaidTimer = topHUD and topHUD:FindFirstChild("RaidTimer") and topHUD.RaidTimer.Visible

    -- Nếu đang trong Raid/Timer thì bỏ qua
    if isPrehistoricTimer or isRaidTimer then
        return
    end

    -- Yêu cầu bắt buộc phải có Volcanic Magnet mới chạy tiếp
    if not CheckItemInventory("Volcanic Magnet") then
        return
    end

    getgenv().RespawnVolcano = true
    local currentBoat = checkboat()

    if currentBoat then
        local distToBoat = localPlayer:DistanceFromCharacter(currentBoat.VehicleSeat.Position)
        
        -- Nếu thuyền ở xa (>= 4000 studs) -> Tiến hành đi mua thuyền mới
        if distToBoat >= 4000 then
            local boatVendorCF = CFrame.new(-16204.0810546875, 9.0863618850708, 479.2259521484375)
            local distToVendor = (boatVendorCF.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude

            if distToVendor <= 8 then
                -- Đã sát NPC -> Mua thuyền PirateBrigade
                ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "PirateBrigade")
                task.wait(3)
            elseif distToVendor <= 1000 then
                -- Trong khoảng 8 - 1000 studs -> Bay tới NPC
                toTarget(boatVendorCF)
            else
                -- Rất xa (> 1000 studs) -> Kiểm tra điểm Spawn để Reset nhanh
                local lastSpawn = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("LastSpawnPoint") and localPlayer.Data.LastSpawnPoint.Value
                if lastSpawn == "Tiki" or lastSpawn == "Tiki2" then
                    localPlayer.Character.Humanoid.Health = 0
                    return
                end
            end
        else
            -- Thuyền ở gần -> Kiểm tra trạng thái ngồi
            if localPlayer.Character.Humanoid.Sit then
                local farCF = CFrame.new(-118834.515625, 160, -78.9505844116211) * CFrame.new(0, 0, 99999999)
                local backCF = CFrame.new(-32975.9921875, 160, 25963.7109375)

                while true do
                    task.wait(0.5)
                    NoclipBoat(currentBoat)

                    -- Logic kiểm tra khoảng cách Leviathan & quay đầu (Nếu bật Setting)
                    if Settings["Will Back When over 10km"] then
                        local leviDist = DistanceFindLeviathan()
                        if leviDist >= 10000 then
                            manageTween(currentBoat.VehicleSeat, backCF, BOAT_SPEED, "TweenBoatBack")
                        end
                    end

                    -- Tween thuyền ra khơi với tốc độ khóa 250
                    manageTween(currentBoat.VehicleSeat, farCF, BOAT_SPEED, "TweenBoat")

                    -- Kiểm tra phát hiện Đảo Tiền Sử
                    if Settings["Auto Find Prehistoric Island"] then
                        if localPlayer.Character.Humanoid.Sit then
                            local prehistoricMap = Workspace.Map:FindFirstChild("PrehistoricIsland")
                            if not prehistoricMap then
                                continue
                            end
                        end
                    end
                    break
                end

                -- Tắt Tween khi đã tìm thấy đảo hoặc ngắt vòng lặp
                if getgenv().TweenBoat then
                    getgenv().TweenBoat:Pause()
                    getgenv().TweenBoat:Cancel()
                end
                if getgenv().TweenBoatBack then
                    getgenv().TweenBoatBack:Pause()
                    getgenv().TweenBoatBack:Cancel()
                end
            else
                -- Chưa ngồi -> Dừng Tween và bay tới ghế
                if getgenv().TweenBoat then
                    getgenv().TweenBoat:Pause()
                    getgenv().TweenBoat:Cancel()
                end
                if getgenv().TweenBoatBack then
                    getgenv().TweenBoatBack:Pause()
                    getgenv().TweenBoatBack:Cancel()
                end
                toTarget(currentBoat.VehicleSeat.CFrame)
            end
        end
    end
end

-- Gán hàm vào Toggle UI (Giữ nguyên cấu trúc UI gốc)
AutoFindPrehistoric = AutoFindPrehistoric

local ToggleFindIsland = FarmingVolcanoSection:CreateToggle({
    Title = "Auto Find Prehistoric Island",
    Desc = "",
    Default = Settings["Auto Find Prehistoric Island"] or false
}, function(Value)
    if Value then
        spawn(function()
            while Settings["Auto Find Prehistoric Island"] do
                task.wait(0.1)
                pcall(function()
                    AutoFindPrehistoric()
                end)
            end
        end)
    end
    SaveSettings("Auto Find Prehistoric Island", Value)
end)
            Notify("SYSTEM WARNING", "Chưa có Volcanic Magnet! Vui lòng craft hoặc farm thêm.", 4)
            
            -- Hủy các Tween thuyền đang chạy nếu mất Magnet đột ngột
            if getgenv().TweenBoat then pcall(function() getgenv().TweenBoat:Cancel() end) end
            if getgenv().TweenBoatBack then pcall(function() getgenv().TweenBoatBack:Cancel() end) end
        end
    end
end)

-- =================================================================
-- 2. AUTO BUY BOAT & NAVIGATE SYSTEM
-- =================================================================
local function AutoBuyAndDriveBoat()
    -- Kiểm tra Magnet trước khi thực thi di chuyển
    if not CheckItemInventory("Volcanic Magnet") then
        return
    end

    local currentBoat = checkboat()

    -- TRƯỜNG HỢP 1: Chưa có thuyền hoặc thuyền quá xa (>= 4000 studs)
    if not currentBoat or (LocalPlayer:DistanceFromCharacter(currentBoat.VehicleSeat.Position) >= 4000) then
        local distToVendor = (TIKI_BUS_CFRAME.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

        if distToVendor > 8 then
            if distToVendor > 1000 then
                -- Nếu xa quá và chưa ở Tiki Outpost -> Reset nhanh về điểm Spawn
                local spawnPoint = LocalPlayer:FindFirstChild("Data") 
                    and LocalPlayer.Data:FindFirstChild("LastSpawnPoint") 
                    and LocalPlayer.Data.LastSpawnPoint.Value

                if spawnPoint == "Tiki" or spawnPoint == "Tiki2" then
                    LocalPlayer.Character.Humanoid.Health = 0
                    task.wait(3)
                    return
                end
            end
            
            -- Bay tới vị trí NPC mua thuyền
            toTarget(TIKI_BUS_CFRAME)
        else
            -- Đã đứng sát NPC -> Gửi remote mua thuyền PirateBrigade
            ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "PirateBrigade")
            task.wait(2)
        end
        return
    end

    -- TRƯỜNG HỢP 2: Đã có thuyền gần
    local vehicleSeat = currentBoat.VehicleSeat

    if not LocalPlayer.Character.Humanoid.Sit then
        -- Chưa ngồi vào ghế -> Bay tới ghế lái
        toTarget(vehicleSeat.CFrame)
    else
        -- Đã ngồi ghế lái -> Kích hoạt Noclip & Lái thuyền
        task.spawn(function()
            NoclipBoat(currentBoat)
        end)

        -- Tọa độ hướng thẳng ra khơi
        local targetFarCF = CFrame.new(-118834.515, vehicleSeat.Position.Y, -78.950) * CFrame.new(0, 0, 99999999)
        local targetReturnCF = CFrame.new(-32975.992, vehicleSeat.Position.Y, 25963.710)

        -- Vòng lặp di chuyển chính (Tốc độ 250)
        while task.wait(0.5) do
            -- Kiểm tra ngắt nếu mất ngồi hoặc đảo đã xuất hiện
            if not LocalPlayer.Character.Humanoid.Sit then break end
            if Workspace.Map:FindFirstChild("PrehistoricIsland") then break end

            -- Xử lý quay đầu nếu vượt quá bán kính quy định (dùng BOAT_SPEED = 250)
            if Settings["Will Back When over 10km"] then
                local distLevi = DistanceFindLeviathan()
                if distLevi >= 10000 then
                    manageTween(vehicleSeat, targetReturnCF, BOAT_SPEED, "TweenBoatBack")
                elseif distLevi <= 4800 then
                    manageTween(vehicleSeat, targetFarCF, BOAT_SPEED, "TweenBoat")
                end
            else
                manageTween(vehicleSeat, targetFarCF, BOAT_SPEED, "TweenBoat")
            end
        end

        -- Dừng thuyền ngay lập tức khi phát hiện đảo hoặc dời ghế
        if getgenv().TweenBoat then pcall(function() getgenv().TweenBoat:Pause() getgenv().TweenBoat:Cancel() end) end
        if getgenv().TweenBoatBack then pcall(function() getgenv().TweenBoatBack:Pause() getgenv().TweenBoatBack:Cancel() end) end
    end
end

return AutoBuyAndDriveBoat
