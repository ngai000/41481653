-----------------------------------------------------------
-- DEVIL FRUIT NOTIFIER WEBHOOK (FULL BACKPACK & HAND TRACKER)
-----------------------------------------------------------
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Cấu hình Webhook
local WEBHOOK_URL = "https://discord.com/api/webhooks/1173855957038665840/L85UNpK-G1Hajdvg7Uqj7eQm87pFRxBlazVN0_sw9kTv1pwVghSaKcGkDJCH5T5jAE4O"

-- Chữ ký lưu trạng thái danh sách trái ở lần quét trước
local lastInventorySignature = ""

-- Bảng cấu hình độ hiếm, màu sắc (Decimal) và Tag
local RARITY_CONFIG = {
    MYTHICAL = {
        color = 16711782, -- Đỏ hồng (#FF0066)
        priority = 5,
        tag = "🔥 [MYTHICAL]",
        fruits = {"kitsune", "dragon", "leopard", "dough", "t-rex", "spirit", "venom", "shadow", "gravity", "mammoth"}
    },
    LEGENDARY = {
        color = 16753920, -- Vàng kim (#FFAA00)
        priority = 4,
        tag = "⚡ [LEGENDARY]",
        fruits = {"blizzard", "rumble", "portal", "phoenix", "sound", "spider", "love", "buddha", "quake"}
    },
    RARE = {
        color = 10040319, -- Tím (#9900FF)
        priority = 3,
        tag = "💎 [RARE]",
        fruits = {"magma", "ghost", "barrier", "rubber", "light", "diamond"}
    },
    UNCOMMON = {
        color = 3381759,  -- Xanh dương (#3399FF)
        priority = 2,
        tag = "🔹 [UNCOMMON]",
        fruits = {"dark", "sand", "ice", "falcon", "flame"}
    },
    COMMON = {
        color = 11184810, -- Xám (#AAAAAA)
        priority = 1,
        tag = "⚪ [COMMON]",
        fruits = {"spin", "blade", "spring", "bomb", "smoke", "spike", "rocket"}
    }
}

-- Lấy thông tin độ hiếm của 1 trái
local function getFruitRarityInfo(fruitName)
    local cleanName = fruitName:lower()
    for _, rarityData in pairs(RARITY_CONFIG) do
        for _, keyword in ipairs(rarityData.fruits) do
            if string.find(cleanName, keyword) then
                return rarityData
            end
        end
    end
    return { color = 65280, priority = 6, tag = "🌟 [SPECIAL]" }
end

-- Kiểm tra xem item có phải Trái Ác Quỷ không
local function isDevilFruit(item)
    if not item or not item:IsA("Tool") then return false end
    local name = item.Name:lower()
    return string.find(name, "fruit") or string.find(name, "trái") or string.find(name, "fruit-")
end

-- Quét toàn bộ Backpack và Character để gom tất cả trái ác quỷ hiện có
local function getAllFruits()
    local fruitList = {}

    -- 1. Quét trên tay (Character)
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if isDevilFruit(item) then
                table.insert(fruitList, { name = item.Name, location = "Trang bị trên tay ✋" })
            end
        end
    end

    -- 2. Quét trong Balo (Backpack)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if isDevilFruit(item) then
                table.insert(fruitList, { name = item.Name, location = "Trong Backpack 🎒" })
            end
        end
    end

    return fruitList
end

-- Gửi thông báo danh sách trái về Discord
local function sendFruitListWebhook(fruitList)
    local serverId = game.JobId ~= "" and game.JobId or "Private Server / Studio"
    local playerCount = #Players:GetPlayers()
    local playerDisplayName = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"

    -- Xác định màu Embed dựa theo trái xịn nhất đang có trong người
    local highestPriority = 0
    local embedColor = 65280
    local formattedFruitText = ""

    for i, fruitData in ipairs(fruitList) do
        local rarity = getFruitRarityInfo(fruitData.name)
        if rarity.priority > highestPriority then
            highestPriority = rarity.priority
            embedColor = rarity.color
        end

        formattedFruitText = formattedFruitText .. string.format("%d. **%s** %s - *%s*\n", i, fruitData.name, rarity.tag, fruitData.location)
    end

    local data = {
        username = "Devil Fruit Tracker",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {{
            title = string.format("🎒 Cập Nhật Túi Đồ - Tìm Thấy %d Trái Ác Quỷ!", #fruitList),
            description = string.format("Người chơi **%s** đang sở hữu các trái sau:\n\n%s", playerDisplayName, formattedFruitText),
            color = embedColor,
            fields = {
                {name = "👥 Số người chơi", value = tostring(playerCount), inline = true},
                {name = "🆔 Server JobID", value = "`" .. serverId .. "`", inline = false}
            },
            footer = {
                text = "System Tracker • " .. os.date("%X")
            }
        }}
    }

    local success, response = pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end
    end)

    if not success then
        warn("[Fruit Tracker] Gửi Webhook thất bại:", response)
    end
end

-- Vòng lặp quét liên tục mỗi 0.5s
task.spawn(function()
    while true do
        local currentFruits = getAllFruits()

        if #currentFruits > 0 then
            -- Tạo chuỗi chữ ký đại diện cho danh sách trái hiện tại để so sánh
            local currentNames = {}
            for _, fruit in ipairs(currentFruits) do
                table.insert(currentNames, fruit.name .. "@" .. fruit.location)
            end
            table.sort(currentNames)
            local currentSignature = table.concat(currentNames, "|")

            -- Nếu trạng thái túi đồ thay đổi (nhặt thêm, vứt bớt, hoặc đổi trái lên tay)
            if currentSignature ~= lastInventorySignature then
                lastInventorySignature = currentSignature
                sendFruitListWebhook(currentFruits)
            end
        else
            -- Nếu trong túi và trên tay không còn trái nào
            lastInventorySignature = ""
        end

        task.wait(0.5)
    end
end)
