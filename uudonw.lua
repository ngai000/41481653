-- Lấy dịch vụ cần thiết
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==================================================
-- Cấu hình giao diện (Gọn gàng hơn)
-- ==================================================
local PADDING = 8 -- Khoảng cách đệm nhỏ hơn
local HEADER_HEIGHT = 40 -- Giảm chiều cao header
local CORNER_RADIUS = 6 -- Viền bo gọn hơn
local FRAME_SIZE = Vector2.new(300, 240) -- Khung chính nhỏ gọn
local INPUT_HEIGHT = 32 -- Giảm chiều cao ô nhập liệu
local LABEL_WIDTH = 90 -- Giữ nhãn đủ rộng

-- ==================================================
-- Hàm bảo mật username (ẩn bớt ký tự khi hiển thị GUI)
-- ==================================================
local function maskUsername(username)
    if #username <= 4 then
        return string.rep("*", #username)
    else
        return string.sub(username, 1, 4) .. string.rep("*", #username - 4)
    end
end

-- ==================================================
-- Bắt đầu tạo giao diện
-- ==================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoteGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(FRAME_SIZE.X, FRAME_SIZE.Y)
mainFrame.Position = UDim2.new(0.5, -FRAME_SIZE.X/2, 0.5, -FRAME_SIZE.Y/2)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
mainFrameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = Color3.fromRGB(68, 71, 90)
mainFrameStroke.Thickness = 1
mainFrameStroke.Parent = mainFrame

-- Header
local headerContainer = Instance.new("Frame")
headerContainer.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
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
