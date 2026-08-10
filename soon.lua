-- ========================================================
-- AUTO UPGRADE RACE V1 -> V2 -> V3 (Auto-Detect Race + GUI Monitor)
-- BẢN SỬA LỖI: GUI không còn làm crash toàn bộ script nếu fail.
-- Tự động nhận diện tộc hiện tại (plr.Data.Race.Value)
-- tích hợp GUI hiển thị Trạng thái Tộc, Tiến độ Action & Debug Log.
-- ========================================================

v8:AddSection({"Auto Upgrade Race (Detect Tộc Tự Động)"})

v8:AddToggle({
    Name = "Auto Upgrade Race (All-in-1)",
    Default = GetSetting("Auto_UpgradeRace_Save", false),
    Callback = function(Value)
        _G.Auto_UpgradeRace = Value
        _G.SaveData["Auto_UpgradeRace_Save"] = Value
        SaveSettings()
        if _G.RaceMonitorUI and _G.RaceMonitorUI.MainFrame then
            _G.RaceMonitorUI.MainFrame.Visible = Value
        end
    end
})

-- ========================================================
-- HÀM TÌM NƠI PARENT GUI AN TOÀN (fix lỗi Delta Executor / mobile)
-- Ưu tiên: gethui() (hidden UI của executor) -> CoreGui -> PlayerGui
-- ========================================================

local function GetSafeGuiParent()
    -- 1) Executor hỗ trợ gethui() (Delta, Synapse, v.v.)
    if typeof(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and container then
            return container
        end
    end

    -- 2) Thử CoreGui trực tiếp (có thể bị chặn trên 1 số executor mobile)
    local ok2, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok2 and coreGui then
        -- test thử có index/ghi được không
        local okTest = pcall(function()
            return coreGui:FindFirstChild("__test__")
        end)
        if okTest then
            return coreGui
        end
    end

    -- 3) Fallback cuối: PlayerGui (luôn hoạt động, dù kém ẩn hơn)
    local ok3, playerGui = pcall(function()
        return plr:WaitForChild("PlayerGui")
    end)
    if ok3 and playerGui then
        return playerGui
    end

    return nil
end

-- ========================================================
-- KHOI TAO GUI MONITOR / LOG / DEBUG
-- (toàn bộ được bọc pcall bên ngoài khi gọi - xem cuối file)
-- ========================================================

local function CreateRaceMonitorGUI()
    local parentContainer = GetSafeGuiParent()
    if not parentContainer then
        warn("[Auto Upgrade Race] Không tìm được nơi parent GUI (gethui/CoreGui/PlayerGui đều fail)")
        return nil
    end

    local existing = parentContainer:FindFirstChild("RaceMonitorGUI")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "RaceMonitorGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 320, 0, 220)
    main.Position = UDim2.new(0.01, 0, 0.4, 0)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Visible = _G.Auto_UpgradeRace or false
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1.5
    stroke.Parent = main

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 25)
    title.Position = UDim2.new(0, 8, 0, 2)
    title.Text = "RACE UPGRADE MONITOR"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextSize = 12
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = main

    -- Status Labels
    local raceStatus = Instance.new("TextLabel")
    raceStatus.Name = "RaceStatus"
    raceStatus.Size = UDim2.new(1, -16, 0, 20)
    raceStatus.Position = UDim2.new(0, 8, 0, 28)
    raceStatus.Text = "Tộc: [ N/A ] | Tier: Unknown"
    raceStatus.TextColor3 = Color3.fromRGB(220, 220, 220)
    raceStatus.TextSize = 12
    raceStatus.Font = Enum.Font.SourceSansSemibold
    raceStatus.TextXAlignment = Enum.TextXAlignment.Left
    raceStatus.BackgroundTransparency = 1
    raceStatus.Parent = main

    local actionStatus = Instance.new("TextLabel")
    actionStatus.Name = "ActionStatus"
    actionStatus.Size = UDim2.new(1, -16, 0, 20)
    actionStatus.Position = UDim2.new(0, 8, 0, 48)
    actionStatus.Text = "Hành động: [ Đang chờ... ]"
    actionStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
    actionStatus.TextSize = 12
    actionStatus.Font = Enum.Font.SourceSans
    actionStatus.TextXAlignment = Enum.TextXAlignment.Left
    actionStatus.BackgroundTransparency = 1
    actionStatus.Parent = main

    -- Log Box Area
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, -16, 0, 135)
    logFrame.Position = UDim2.new(0, 8, 0, 75)
    logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    logFrame.BorderSizePixel = 0
    logFrame.ScrollBarThickness = 3
    logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    logFrame.Parent = main

    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 2)
    logLayout.Parent = logFrame

    logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        logFrame.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y)
        logFrame.CanvasPosition = Vector2.new(0, logLayout.AbsoluteContentSize.Y)
    end)

    local okParent, errParent = pcall(function()
        gui.Parent = parentContainer
    end)
    if not okParent then
        warn("[Auto Upgrade Race] Không thể parent GUI: " .. tostring(errParent))
        return nil
    end

    return {
        MainFrame = main,
        RaceStatus = raceStatus,
        ActionStatus = actionStatus,
        LogFrame = logFrame
    }
end

-- GUI được tạo có bảo vệ: nếu fail, chỉ mất phần hiển thị,
-- KHÔNG được phép làm chết phần logic auto upgrade race bên dưới.
local guiOk, guiResult = pcall(CreateRaceMonitorGUI)
if guiOk and guiResult then
    _G.RaceMonitorUI = guiResult
else
    _G.RaceMonitorUI = nil
    warn("[Auto Upgrade Race] GUI Monitor không khởi tạo được, script vẫn chạy farm bình thường (không có GUI). Lỗi: " .. tostring(guiResult))
end

-- Update UI Helper Functions (an toàn khi _G.RaceMonitorUI = nil)
local function UpdateMonitorUI(raceText, actionText)
    if not _G.RaceMonitorUI then return end
    local ok = pcall(function()
        if raceText then _G.RaceMonitorUI.RaceStatus.Text = "Tộc: " .. raceText end
        if actionText then _G.RaceMonitorUI.ActionStatus.Text = "Hành động: " .. actionText end
    end)
end

local function AddLog(msg, logType)
    if not _G.RaceMonitorUI then
        -- Không có GUI -> vẫn in ra console để debug được
        if logType == "error" or logType == "warn" then
            warn("[Auto Upgrade Race] " .. tostring(msg))
        end
        return
    end

    pcall(function()
        local timeStr = os.date("%H:%M:%S")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -5, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        if logType == "error" or logType == "warn" then
            lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            lbl.Text = "[" .. timeStr .. "] [ERR] " .. msg
        elseif logType == "success" then
            lbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            lbl.Text = "[" .. timeStr .. "] [OK] " .. msg
        else
            lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
            lbl.Text = "[" .. timeStr .. "] [INFO] " .. msg
        end

        lbl.Parent = _G.RaceMonitorUI.LogFrame
    end)
end

-- ========================================================
-- DỮ LIỆU DÙNG CHUNG
-- ========================================================

local HumanBosses = {"Fajita", "Jeremy", "Diamond"}
local BossPositions = {
    Fajita  = CFrame.new(-2172.7399902344, 103.32216644287, -4015.025390625),
    Jeremy  = CFrame.new(2006.9261474609, 448.95666503906, 853.98284912109),
    Diamond = CFrame.new(-1576.7166748047, 198.59265136719, 13.724286079407)
}

local FLOWER_WAIT_POS = CFrame.new(980.09851074219, 121.33129882812, 1287.2093505859)

local RaceAliasMap = {
    ["mink"]     = "Mink",
    ["human"]    = "Human",
    ["skypiea"]  = "Skypiea",
    ["angel"]    = "Skypiea",
    ["fishman"]  = "Fishman",
}

-- ========================================================
-- HÀM HỖ TRỢ
-- ========================================================

local function GetCurrentRace()
    local ok, raceVal = pcall(function()
        return plr.Data.Race.Value
    end)
    if not ok or raceVal == nil then return nil end
    local key = tostring(raceVal):lower()
    return RaceAliasMap[key]
end

local function DoFlowerStep(raceFlag)
    if not GetBP("Flower 1") then
        UpdateMonitorUI(nil, "Đang đi lấy Flower 1")
        _tp(workspace.Flower1.CFrame)
    elseif not GetBP("Flower 2") then
        UpdateMonitorUI(nil, "Đang đi lấy Flower 2")
        _tp(workspace.Flower2.CFrame)
    elseif not GetBP("Flower 3") then
        local mob = GetConnectionEnemies("Swan Pirate")
        if mob then
            UpdateMonitorUI(nil, "Đang farm Swan Pirate lấy Flower 3")
            repeat
                wait()
                G.Kill(mob, raceFlag)
            until GetBP("Flower 3") or not mob.Parent or mob.Humanoid.Health <= 0 or raceFlag == false
        else
            UpdateMonitorUI(nil, "Đang chờ Swan Pirate spawn...")
            _tp(FLOWER_WAIT_POS)
        end
    end
end

-- ========================================================
-- LOGIC RIÊNG TỪNG TỘC
-- ========================================================

local function UpgradeMink()
    local alchemist = replicated.Remotes.CommF_:InvokeServer("Alchemist", "1")

    if alchemist ~= 2 then
        if alchemist == 0 then
            UpdateMonitorUI(nil, "Nhận Quest Alchemist V2")
            replicated.Remotes.CommF_:InvokeServer("Alchemist", "2")
            AddLog("Đã nhận Quest Alchemist V2", "info")
        elseif alchemist == 1 then
            DoFlowerStep(_G.Auto_UpgradeRace)
        end
    elseif replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
        UpdateMonitorUI(nil, "Nhận Quest Wenlocktoad V3 (Mink)")
        replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
        AddLog("Đã nhận Quest Wenlocktoad V3", "info")
    elseif replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
        UpdateMonitorUI(nil, "Đang Auto Farm Chest (Quest V3)")
        _G.AutoFarmChest = true
    else
        _G.AutoFarmChest = false
        UpdateMonitorUI(nil, "Mink V3 đã hoàn thành!")
    end
end

local function UpgradeHuman()
    local alchemist = replicated.Remotes.CommF_:InvokeServer("Alchemist", "1")

    if alchemist ~= -2 then
        if alchemist == 0 then
            UpdateMonitorUI(nil, "Nhận Quest Alchemist V2")
            replicated.Remotes.CommF_:InvokeServer("Alchemist", "2")
            AddLog("Đã nhận Quest Alchemist V2", "info")
        elseif alchemist == 1 then
            DoFlowerStep(_G.Auto_UpgradeRace)
        elseif alchemist == 2 then
            UpdateMonitorUI(nil, "Trả Quest Alchemist V2")
            replicated.Remotes.CommF_:InvokeServer("Alchemist", "3")
            AddLog("Nâng cấp Alchemist V2 thành công!", "success")
        end
    elseif replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
        UpdateMonitorUI(nil, "Nhận Quest Wenlocktoad V3 (Human)")
        replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
        AddLog("Đã nhận Quest Wenlocktoad V3", "info")
    elseif replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
        for _, bossName in ipairs(HumanBosses) do
            local boss = GetConnectionEnemies(bossName)
            if boss then
                UpdateMonitorUI(nil, "Đang hạ Boss: " .. bossName)
                repeat
                    wait()
                    G.Kill(boss, _G.Auto_UpgradeRace)
                until boss.Humanoid.Health <= 0 or not boss.Parent or not _G.Auto_UpgradeRace
            else
                UpdateMonitorUI(nil, "Đến vị trí Boss: " .. bossName)
                _tp(BossPositions[bossName])
            end
        end
    else
        UpdateMonitorUI(nil, "Human V3 đã hoàn thành!")
    end
end

local function UpgradeSkypiea()
    local alchemist = replicated.Remotes.CommF_:InvokeServer("Alchemist", "1")

    if alchemist ~= -2 then
        if alchemist == 0 then
            UpdateMonitorUI(nil, "Nhận Quest Alchemist V2")
            replicated.Remotes.CommF_:InvokeServer("Alchemist", "2")
            AddLog("Đã nhận Quest Alchemist V2", "info")
        elseif alchemist == 1 then
            DoFlowerStep(_G.Auto_UpgradeRace)
        elseif alchemist == 2 then
            UpdateMonitorUI(nil, "Trả Quest Alchemist V2")
            replicated.Remotes.CommF_:InvokeServer("Alchemist", "3")
            AddLog("Nâng cấp Alchemist V2 thành công!", "success")
        end
    elseif replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
        UpdateMonitorUI(nil, "Nhận Quest Wenlocktoad V3 (Skypiea)")
        replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
        AddLog("Đã nhận Quest Wenlocktoad V3", "info")
    elseif replicated.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
        local targetFound = false
        for _, player in pairs(game.Players:GetChildren()) do
            local ok = pcall(function()
                if player ~= plr
                    and player.Character
                    and player.Character:FindFirstChild("HumanoidRootPart")
                    and player.Character:FindFirstChild("Humanoid")
                    and player:FindFirstChild("Data")
                    and player.Data:FindFirstChild("Race")
                    and tostring(player.Data.Race.Value) == "Skypiea" then

                    targetFound = true
                    UpdateMonitorUI(nil, "Đang theo vết mục tiêu Skypiea: " .. player.Name)
                    repeat
                        task.wait()
                        _tp(player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(-45), 0, 0))
                    until (not player.Character) or player.Character.Humanoid.Health <= 0 or _G.Auto_UpgradeRace == false
                end
            end)
            if not ok then
                AddLog("Lỗi kiểm tra dữ liệu người chơi khác", "error")
            end
        end
        if not targetFound then
            UpdateMonitorUI(nil, "Tìm kiếm người chơi tộc Skypiea trên server...")
        end
    else
        UpdateMonitorUI(nil, "Skypiea V3 đã hoàn thành!")
    end
end

local function UpgradeFishman()
    UpdateMonitorUI(nil, "Fishman: Sea Beast (Coming Soon)")
    AddLog("Tộc Fishman chưa hỗ trợ farm Sea Beast tự động.", "warn")
end

-- ========================================================
-- DISPATCH THEO TỘC ĐÃ DETECT
-- ========================================================

local RaceHandlers = {
    Mink     = UpgradeMink,
    Human    = UpgradeHuman,
    Skypiea  = UpgradeSkypiea,
    Fishman  = UpgradeFishman,
}

spawn(function()
    local lastRaceDetected = ""

    while wait(Sec) do
        if not _G.Auto_UpgradeRace then
            UpdateMonitorUI(nil, "Đã tắt Auto")
        else
            local errStatus, errMessage = pcall(function()
                local currentRace = GetCurrentRace()

                if not currentRace then
                    UpdateMonitorUI("[ KHÔNG XÁC ĐỊNH ]", "Lỗi đọc dữ liệu tộc")
                    AddLog("Không tìm thấy plr.Data.Race.Value", "error")
                    return
                end

                if currentRace ~= lastRaceDetected then
                    lastRaceDetected = currentRace
                    AddLog("Phát hiện Tộc mới: " .. currentRace, "success")
                end

                UpdateMonitorUI(currentRace, nil)

                local handler = RaceHandlers[currentRace]
                if handler then
                    handler()
                else
                    UpdateMonitorUI(currentRace, "Chưa hỗ trợ Tộc này")
                    AddLog("Tộc chưa được cấu hình: " .. tostring(currentRace), "warn")
                end
            end)

            if not errStatus then
                UpdateMonitorUI(nil, "Bị lỗi vòng lặp (Xem Log)")
                AddLog("Lỗi Runtime: " .. tostring(errMessage), "error")
            end
        end
    end
end)
