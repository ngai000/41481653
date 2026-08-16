-- =================================================================
-- MODULE: VOLCANIC MAGNET CHECK & AUTO BOAT SYSTEM
-- SPEED LOCK: 250
-- =================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local BOAT_SPEED = 250 -- Khóa cố định tốc độ ở 250 toàn hệ thống
local TIKI_BUS_CFRAME = CFrame.new(-16204.081, 9.086, 479.225) -- Vị trí mua thuyền Tiki

-- Gửi thông báo hệ thống
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- =================================================================
-- 1. SYSTEM SCANNER (Quét Volcanic Magnet mỗi 5s)
-- =================================================================
task.spawn(function()
    local lastNotif = 0
    while task.wait(5) do
        local hasMagnet = CheckItemInventory("Volcanic Magnet")
        getgenv().dacoMagnet = hasMagnet

        if not hasMagnet then
            -- Hiển thị thông báo nếu thiếu Magnet
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
