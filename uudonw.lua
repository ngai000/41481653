-- ==================================================
-- Lấy dịch vụ cần thiết
-- ==================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Xóa GUI cũ
for _, gui in ipairs(playerGui:GetChildren()) do
    if gui.Name == "NoteGui" then
        gui:Destroy()
    end
end

-- ==================================================
-- Cấu hình màu sắc & kích thước
-- ==================================================
local COLORS = {
    BG = Color3.fromRGB(33, 34, 44),
    HEADER = Color3.fromRGB(40, 42, 54),
    INPUT = Color3.fromRGB(68, 71, 90),
    TEXT = Color3.fromRGB(248, 248, 242),
    ACCENT = Color3.fromRGB(189, 147, 249),
    RED = Color3.fromRGB(255, 85, 85),
    GREEN = Color3.fromRGB(80, 250, 123)
}

-- ==================================================
-- GUI Chính
-- ==================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoteGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(320, 280) -- Tăng nhẹ chiều cao để thoải mái
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
mainFrame.BackgroundColor3 = COLORS.BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.INPUT
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Layout chính cho Main Frame
local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 10)
mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainFrame

-- ==================================================
-- Header Section
-- ==================================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = COLORS.HEADER
header.LayoutOrder = 1
header.Parent = mainFrame

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.6, 0)
title.BackgroundTransparency = 1
title.Text = "TRÙM CÀY THUÊ"
title.TextColor3 = Color3.fromRGB(241, 250, 140)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = header

local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(1, 0, 0.4, 0)
subTitle.Position = UDim2.new(0, 0, 0.55, 0)
subTitle.BackgroundTransparency = 1
subTitle.Text = "User: " .. player.Name:sub(1, 4) .. "****"
subTitle.TextColor3 = COLORS.ACCENT
subTitle.Font = Enum.Font.SourceSansItalic
subTitle.TextSize = 14
subTitle.Parent = header

-- ==================================================
-- Body Section (Chứa Input & Buttons)
-- ==================================================
local body = Instance.new("Frame")
body.Size = UDim2.new(0.9, 0, 0, 200)
body.BackgroundTransparency = 1
body.LayoutOrder = 2
body.Parent = mainFrame

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 8)
bodyLayout.Parent = body

-- Hàm tạo hàng nhập liệu
local function createInput(labelName, placeholder)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = body

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.35, 0, 1, 0)
    lbl.Text = labelName
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = frame

    local txt = Instance.new("TextBox")
    txt.Size = UDim2.new(0.65, 0, 1, 0)
    txt.Position = UDim2.new(0.35, 0, 0, 0)
    txt.BackgroundColor3 = COLORS.INPUT
    txt.TextColor3 = COLORS.TEXT
    txt.PlaceholderText = placeholder
    txt.Text = ""
    txt.Font = Enum.Font.SourceSans
    txt.TextSize = 14
    txt.Parent = frame
    Instance.new("UICorner", txt).CornerRadius = UDim.new(0, 4)
    
    return txt
end

local orderBox = createInput("📝 Đơn hàng:", "Tên dịch vụ...")
local noteBox = createInput("✏️ Ghi chú:", "Lưu ý...")
local customerBox = createInput("👤 Khách:", "Tên khách hàng...")

-- ==================================================
-- Buttons Section
-- ==================================================
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, 0, 0, 40)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = body

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 10)
btnLayout.Parent = btnFrame

local function makeBtn(text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -5, 1, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    b.Parent = btnFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local resetBtn = makeBtn("♻ Reset Stats", COLORS.RED)
local rerollBtn = makeBtn("🔄 Reroll Race", COLORS.GREEN)

-- Logic Buttons
local CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")

resetBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Refund", "1")
    CommF:InvokeServer("BlackbeardReward", "Refund", "2")
end)

rerollBtn.MouseButton1Click:Connect(function()
    CommF:InvokeServer("BlackbeardReward", "Reroll", "2")
end)
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
