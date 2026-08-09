local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local SEARCH_RADIUS = 2000
local TWEEN_SPEED = 100 -- Studs/Giây

local isRunning = false
local currentTween = nil
local noclipConnection = nil
local alignBody = {BV = nil, BG = nil}

-- Quản lý Noclip & Giữ nhân vật không rơi
local function setNoclip(enabled)
	if enabled then
		noclipConnection = RunService.Stepped:Connect(function()
			if LocalPlayer.Character then
				for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		if LocalPlayer.Character then
			for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

local function setPhysicsLock(enabled, rootPart)
	if enabled and rootPart then
		local bv = Instance.new("BodyVelocity")
		bv.Name = "AutoFlyVelocity"
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.Parent = rootPart
		
		local bg = Instance.new("BodyGyro")
		bg.Name = "AutoFlyGyro"
		bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		bg.CFrame = rootPart.CFrame
		bg.Parent = rootPart
		
		alignBody.BV = bv
		alignBody.BG = bg
	else
		if alignBody.BV then alignBody.BV:Destroy() end
		if alignBody.BG then alignBody.BG:Destroy() end
		alignBody.BV = nil
		alignBody.BG = nil
	end
end

-- Thuật toán tìm điểm cao nhất trong bán kính
local function findHighestPoint(origin, radius)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = RaycastFilterType.Exclude
	if LocalPlayer.Character then
		raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	end

	local highestPoint = nil
	local highestY = -math.huge
	local step = 40 -- Tăng/giảm để chỉnh độ chính xác & hiệu năng quét

	for x = -radius, radius, step do
		for z = -radius, radius, step do
			if (x^2 + z^2) <= radius^2 then
				local startPos = Vector3.new(origin.X + x, origin.Y + 1000, origin.Z + z)
				local rayResult = workspace:Raycast(startPos, Vector3.new(0, -3000, 0), raycastParams)
				
				if rayResult and rayResult.Position.Y > highestY then
					highestY = rayResult.Position.Y
					highestPoint = rayResult.Position
				end
			end
		end
	end
	
	return highestPoint
end

-- Khởi chạy Tween
local function startAutoTravel(button)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		isRunning = false
		button.Text = "BẬT TÌM ĐIỂM CAO"
		button.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
		return
	end

	button.Text = "ĐANG QUÉT VÙNG ĐẤT..."
	task.wait(0.1)

	local targetPos = findHighestPoint(root.Position, SEARCH_RADIUS)
	if not targetPos then
		isRunning = false
		button.Text = "BẬT TÌM ĐIỂM CAO"
		button.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
		return
	end

	-- Tạo điểm đến an toàn phía trên mặt đất 5 studs
	local finalCFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
	local distance = (finalCFrame.Position - root.Position).Magnitude
	local duration = distance / TWEEN_SPEED

	setNoclip(true)
	setPhysicsLock(true, root)

	button.Text = "ĐANG TWEEN..."
	button.BackgroundColor3 = Color3.fromRGB(220, 60, 60)

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	currentTween = TweenService:Create(root, tweenInfo, {CFrame = finalCFrame})
	
	currentTween:Play()
	currentTween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			stopAutoTravel(button)
		end
	end)
end

function stopAutoTravel(button)
	isRunning = false
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
	
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	
	setPhysicsLock(false, root)
	setNoclip(false)

	button.Text = "BẬT TÌM ĐIỂM CAO"
	button.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
end

-- Tạo Giao diện UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoHighestLandGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainButton = Instance.new("TextButton")
mainButton.Size = UDim2.new(0, 180, 0, 45)
mainButton.Position = UDim2.new(0.8, 0, 0.2, 0)
mainButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
mainButton.Text = "BẬT TÌM ĐIỂM CAO"
mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mainButton.TextSize = 14
mainButton.Font = Enum.Font.SourceSansBold
mainButton.Active = true
mainButton.Draggable = true
mainButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainButton

mainButton.MouseButton1Click:Connect(function()
	isRunning = not isRunning
	if isRunning then
		startAutoTravel(mainButton)
	else
		stopAutoTravel(mainButton)
	end
end)
