-- ==================================================
-- Lấy dịch vụ cần thiết
-- ==================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================================================
-- 🔥 XÓA TOÀN BỘ GUI CŨ (FIX TRIỆT ĐỂ)
-- ==================================================
for _, gui in ipairs(playerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "NoteGui" then
        gui:Destroy()
    end
end
task.wait()

-- ==================================================
-- Cấu hình giao diện (Gọn gàng hơn)
-- ==================================================
local PADDING = 8
local HEADER_HEIGHT = 40
local CORNER_RADIUS = 6
local FRAME_SIZE = Vector2.new(300, 240)
local INPUT_HEIGHT = 32
local LABEL_WIDTH = 90

-- ==================================================
-- Hàm bảo mật username
-- ==================================================
local function maskUsername(username)
    if #username <= 4 then
        return string.rep("*", #username)
    else
        return string.sub(username, 1, 4) .. string.rep("*", #username - 4)
    end
end

-- ==================================================
-- Tạo ScreenGui (NAME TRƯỚC - PARENT SAU)
-- ==================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoteGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ==================================================
-- Main Frame
-- ==================================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(FRAME_SIZE.X, FRAME_SIZE.Y)
mainFrame.Position = UDim2.new(0.5, -FRAME_SIZE.X/2, 0.5, -FRAME_SIZE.Y/2)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, CORNER_RADIUS)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(68, 71, 90)
stroke.Thickness = 1
stroke.Parent = mainFrame

-- ==================================================
-- Header
-- ==================================================
local headerContainer = Instance.new("Frame")
headerContainer.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
headerContainer.BackgroundColor3 = Color3.fromRGB(30, 31, 40)
headerContainer.BorderSizePixel = 0
headerContainer.Parent = mainFrame

Instance.new("UICorner", headerContainer).CornerRadius = UDim.new(0, CORNER_RADIUS)

local headerLayout = Instance.new("UIListLayout")
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
headerLayout.Padding = UDim.new(0, 2)
headerLayout.Parent = headerContainer

local logoHeader = Instance.new("TextLabel")
logoHeader.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT * 0.55)
logoHeader.BackgroundTransparency = 1
logoHeader.Text = "Trùm Cày Thuê: Ngài "
logoHeader.TextColor3 = Color3.fromRGB(241, 250, 140)
logoHeader.Font = Enum.Font.SourceSansBold
logoHeader.TextSize = 20
logoHeader.Parent = headerContainer

local userHeader = Instance.new("TextLabel")
userHeader.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT * 0.45)
userHeader.BackgroundTransparency = 1
userHeader.Text = "Username: " .. maskUsername(player.Name)
userHeader.TextColor3 = Color3.fromRGB(189, 147, 249)
userHeader.Font = Enum.Font.SourceSans
userHeader.TextSize = 14
userHeader.Parent = headerContainer

-- ==================================================
-- Input Container
-- ==================================================
local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.fromOffset(FRAME_SIZE.X - PADDING*2, FRAME_SIZE.Y)
inputContainer.Position = UDim2.new(0, PADDING, 0, HEADER_HEIGHT + PADDING)
inputContainer.BackgroundTransparency = 1
inputContainer.Parent = mainFrame

local inputLayout = Instance.new("UIListLayout")
inputLayout.Padding = UDim.new(0, PADDING)
inputLayout.Parent = inputContainer

-- ==================================================
-- Hàm tạo input
-- ==================================================
local function createInputRow(labelText, placeholder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, INPUT_HEIGHT)
    row.BackgroundTransparency = 1
    row.Parent = inputContainer

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, PADDING/2)
    layout.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, LABEL_WIDTH, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -LABEL_WIDTH, 1, 0)
    box.BackgroundColor3 = Color3.fromRGB(68, 71, 90)
    box.TextColor3 = Color3.fromRGB(248, 248, 242)
    box.PlaceholderText = placeholder
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = row

    Instance.new("UICorner", box).CornerRadius = UDim.new(0, CORNER_RADIUS/2)

    return box
end

local orderBox = createInputRow("📝 Đơn hàng:", "Nhập đơn hàng...")
local noteBox = createInputRow("✏️ Ghi chú:", "Nhập ghi chú...")
local customerBox = createInputRow("👤 Người đặt:", "Nhập tên người đặt...")

-- ==================================================
-- Buttons
-- ==================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage.Remotes.CommF_

local buttonRow = Instance.new("Frame")
buttonRow.Size = UDim2.new(1, 0, 0, 40)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = inputContainer

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.Padding = UDim.new(0, PADDING)
buttonLayout.Parent = buttonRow

local function createButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -PADDING, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, CORNER_RADIUS)
    return btn
end

local resetBtn = createButton("♻ Reset Stats", Color3.fromRGB(255, 85, 85))
resetBtn.Parent = buttonRow
resetBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Refund", "1")
    CommF:InvokeServer("BlackbeardReward", "Refund", "2")
end)

local rerollBtn = createButton("🔄 Reroll Race", Color3.fromRGB(80, 250, 123))
rerollBtn.Parent = buttonRow
rerollBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Reroll", "2")
end)headerContainer.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
headerContainer.BackgroundColor3 = Color3.fromRGB(30, 31, 40)
headerContainer.BorderSizePixel = 0
headerContainer.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
headerCorner.Parent = headerContainer

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = headerContainer

local logoHeader = Instance.new("TextLabel")
logoHeader.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT * 0.55)
logoHeader.BackgroundTransparency = 1
logoHeader.Text = "Trùm Cày Thuê: Ngài "
logoHeader.TextColor3 = Color3.fromRGB(241, 250, 140)
logoHeader.Font = Enum.Font.SourceSansBold
logoHeader.TextSize = 20
logoHeader.Parent = headerContainer

local userHeader = Instance.new("TextLabel")
userHeader.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT * 0.45)
userHeader.BackgroundTransparency = 1
userHeader.Text = "Username: " .. maskUsername(player.Name)
userHeader.TextColor3 = Color3.fromRGB(189, 147, 249)
userHeader.Font = Enum.Font.SourceSans
userHeader.TextSize = 14
userHeader.Parent = headerContainer

-- Input Container
local inputContainer = Instance.new("Frame")
local inputHeight = FRAME_SIZE.Y - HEADER_HEIGHT - PADDING * 2
inputContainer.Size = UDim2.fromOffset(FRAME_SIZE.X - PADDING * 2, inputHeight)
inputContainer.Position = UDim2.new(0, PADDING, 0, HEADER_HEIGHT + PADDING)
inputContainer.BackgroundTransparency = 1
inputContainer.Parent = mainFrame

local inputLayout = Instance.new("UIListLayout")
inputLayout.FillDirection = Enum.FillDirection.Vertical
inputLayout.Padding = UDim.new(0, PADDING)
inputLayout.VerticalAlignment = Enum.VerticalAlignment.Top
inputLayout.SortOrder = Enum.SortOrder.LayoutOrder
inputContainer.AutomaticSize = Enum.AutomaticSize.Y
inputLayout.Parent = inputContainer

-- Hàm tạo một dòng nhập liệu
local function createInputRow(name, labelText, placeholderText)
    local rowFrame = Instance.new("Frame")
    rowFrame.Name = name .. "Row"
    rowFrame.Size = UDim2.new(1, 0, 0, INPUT_HEIGHT)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = inputContainer
    
    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.Padding = UDim.new(0, PADDING/2)
    rowLayout.Parent = rowFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, LABEL_WIDTH, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = labelText
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = rowFrame

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(1, -LABEL_WIDTH - PADDING/2, 1, 0)
    textbox.BackgroundColor3 = Color3.fromRGB(68, 71, 90)
    textbox.TextColor3 = Color3.fromRGB(248, 248, 242)
    textbox.PlaceholderText = placeholderText
    textbox.PlaceholderColor3 = Color3.fromRGB(140, 142, 163)
    textbox.TextWrapped = true
    textbox.ClearTextOnFocus = false
    textbox.Font = Enum.Font.SourceSans
    textbox.TextSize = 14
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.TextYAlignment = Enum.TextYAlignment.Center
    textbox.BorderSizePixel = 0
    textbox.Parent = rowFrame

    local textboxCorner = Instance.new("UICorner")
    textboxCorner.CornerRadius = UDim.new(0, CORNER_RADIUS/2)
    textboxCorner.Parent = textbox
    
    return textbox
end

-- Các dòng nhập liệu
local orderBox = createInputRow("OrderBox", "📝 Đơn hàng:", "Nhập đơn hàng...")
local noteBox = createInputRow("NoteBox", "✏️ Ghi chú:", "Nhập ghi chú...")
local customerBox = createInputRow("CustomerBox", "👤 Người đặt:", "Nhập tên người đặt...")

-- In ra console (giữ nguyên tên thật)
local function onFocusLost(enterPressed)
    if enterPressed then
        print("--- Đơn Hàng Mới ---")
        print("Người dùng Roblox: " .. player.Name)
        print("Đơn hàng: " .. orderBox.Text)
        print("Ghi chú: " .. noteBox.Text)
        print("Người đặt: " .. customerBox.Text)
        print("--------------------")
    end
end

orderBox.FocusLost:Connect(onFocusLost)
noteBox.FocusLost:Connect(onFocusLost)
customerBox.FocusLost:Connect(onFocusLost)
-- Buttons Container
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage.Remotes.CommF_

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, 0, 0, 40)
buttonContainer.BackgroundTransparency = 1
buttonContainer.LayoutOrder = 99
buttonContainer.Parent = inputContainer

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.Padding = UDim.new(0, PADDING)
buttonLayout.Parent = buttonContainer

-- Hàm tạo nút
local function createButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -PADDING, 1, 0)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    corner.Parent = btn

    return btn
end

-- Nút Reset Stats
local resetBtn = createButton("♻ Reset Stats", Color3.fromRGB(255, 85, 85))
resetBtn.Parent = buttonContainer
resetBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Refund", "1")
    CommF:InvokeServer("BlackbeardReward", "Refund", "2")
end)

-- Nút Reroll Race
local rerollBtn = createButton("🔄 Reroll Race", Color3.fromRGB(80, 250, 123))
rerollBtn.Parent = buttonContainer
rerollBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Reroll", "2")
end)
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = headerContainer

local logoHeader = Instance.new("TextLabel")
logoHeader.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT * 0.55)
logoHeader.BackgroundTransparency = 1
logoHeader.Text = "Trùm Cày Thuê: Ngài "
logoHeader.TextColor3 = Color3.fromRGB(241, 250, 140)
logoHeader.Font = Enum.Font.SourceSansBold
logoHeader.TextSize = 20
logoHeader.Parent = headerContainer

local userHeader = Instance.new("TextLabel")
userHeader.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT * 0.45)
userHeader.BackgroundTransparency = 1
userHeader.Text = "Username: " .. maskUsername(player.Name)
userHeader.TextColor3 = Color3.fromRGB(189, 147, 249)
userHeader.Font = Enum.Font.SourceSans
userHeader.TextSize = 14
userHeader.Parent = headerContainer

-- Input Container
local inputContainer = Instance.new("Frame")
local inputHeight = FRAME_SIZE.Y - HEADER_HEIGHT - PADDING * 2
inputContainer.Size = UDim2.fromOffset(FRAME_SIZE.X - PADDING * 2, inputHeight)
inputContainer.Position = UDim2.new(0, PADDING, 0, HEADER_HEIGHT + PADDING)
inputContainer.BackgroundTransparency = 1
inputContainer.Parent = mainFrame

local inputLayout = Instance.new("UIListLayout")
inputLayout.FillDirection = Enum.FillDirection.Vertical
inputLayout.Padding = UDim.new(0, PADDING)
inputLayout.VerticalAlignment = Enum.VerticalAlignment.Top
inputLayout.SortOrder = Enum.SortOrder.LayoutOrder
inputContainer.AutomaticSize = Enum.AutomaticSize.Y
inputLayout.Parent = inputContainer

-- Hàm tạo một dòng nhập liệu
local function createInputRow(name, labelText, placeholderText)
    local rowFrame = Instance.new("Frame")
    rowFrame.Name = name .. "Row"
    rowFrame.Size = UDim2.new(1, 0, 0, INPUT_HEIGHT)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = inputContainer
    
    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.Padding = UDim.new(0, PADDING/2)
    rowLayout.Parent = rowFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, LABEL_WIDTH, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = labelText
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = rowFrame

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(1, -LABEL_WIDTH - PADDING/2, 1, 0)
    textbox.BackgroundColor3 = Color3.fromRGB(68, 71, 90)
    textbox.TextColor3 = Color3.fromRGB(248, 248, 242)
    textbox.PlaceholderText = placeholderText
    textbox.PlaceholderColor3 = Color3.fromRGB(140, 142, 163)
    textbox.TextWrapped = true
    textbox.ClearTextOnFocus = false
    textbox.Font = Enum.Font.SourceSans
    textbox.TextSize = 14
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.TextYAlignment = Enum.TextYAlignment.Center
    textbox.BorderSizePixel = 0
    textbox.Parent = rowFrame

    local textboxCorner = Instance.new("UICorner")
    textboxCorner.CornerRadius = UDim.new(0, CORNER_RADIUS/2)
    textboxCorner.Parent = textbox
    
    return textbox
end

-- Các dòng nhập liệu
local orderBox = createInputRow("OrderBox", "📝 Đơn hàng:", "Nhập đơn hàng...")
local noteBox = createInputRow("NoteBox", "✏️ Ghi chú:", "Nhập ghi chú...")
local customerBox = createInputRow("CustomerBox", "👤 Người đặt:", "Nhập tên người đặt...")

-- In ra console (giữ nguyên tên thật)
local function onFocusLost(enterPressed)
    if enterPressed then
        print("--- Đơn Hàng Mới ---")
        print("Người dùng Roblox: " .. player.Name)
        print("Đơn hàng: " .. orderBox.Text)
        print("Ghi chú: " .. noteBox.Text)
        print("Người đặt: " .. customerBox.Text)
        print("--------------------")
    end
end

orderBox.FocusLost:Connect(onFocusLost)
noteBox.FocusLost:Connect(onFocusLost)
customerBox.FocusLost:Connect(onFocusLost)
-- Buttons Container
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage.Remotes.CommF_

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, 0, 0, 40)
buttonContainer.BackgroundTransparency = 1
buttonContainer.LayoutOrder = 99
buttonContainer.Parent = inputContainer

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.Padding = UDim.new(0, PADDING)
buttonLayout.Parent = buttonContainer

-- Hàm tạo nút
local function createButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -PADDING, 1, 0)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    corner.Parent = btn

    return btn
end

-- Nút Reset Stats
local resetBtn = createButton("♻ Reset Stats", Color3.fromRGB(255, 85, 85))
resetBtn.Parent = buttonContainer
resetBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Refund", "1")
    CommF:InvokeServer("BlackbeardReward", "Refund", "2")
end)

-- Nút Reroll Race
local rerollBtn = createButton("🔄 Reroll Race", Color3.fromRGB(80, 250, 123))
rerollBtn.Parent = buttonContainer
rerollBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Reroll", "2")
end)
