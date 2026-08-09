local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local SEARCH_RADIUS = 2000
local TWEEN_SPEED = 500 -- Tăng tốc độ bay (Studs/giây) - Chỉnh tăng giảm tùy ý

local isRunning = false
local currentTween = nil
local noclipConnection = nil
local alignBody = {BV = nil, BG = nil}

-- Quản lý Noclip
local function setNoclip(enabled)
	if enabled then
		noclipConnection = RunService.Stepped:Connect(function()
			if LocalPlayer.Character then
				for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
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
			for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

-- Khóa trọng lực & hướng xoay
local function setPhysicsLock(enabled, rootPart)
	if enabled and rootPart then
		local bv = Instance.new("BodyVelocity")
		bv.Name = "FastFlyVelocity"
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.Velocity = Vector3.zero
		bv.Parent = rootPart
		
		local bg = Instance.new("BodyGyro")
		bg.Name = "FastFlyGyro"
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

-- Thuật toán Raycast xoắn ốc (Siêu nhanh - không trễ UI)
local function findHighestPointFast(origin, radius)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = RaycastFilterType.Exclude
	if LocalPlayer.Character then
		raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	end

	local highestPoint = nil
	local highestY = -math.huge
	
	-- Quét theo bán kính nhảy bước lớn (Step 50m) để đạt tốc độ tối đa
	local stepSize = 50 
	local numRings = math.floor(radius / stepSize)

	for r = 1, numRings do
		local currentRadius = r * stepSize
		local pointsOnRing = math.floor(2 * math.pi * currentRadius / stepSize)
		
		for i = 1, pointsOnRing do
			local angle = (i / pointsOnRing) * math.pi * 2
			local x = math.cos(angle) * currentRadius
			local z = math.sin(angle) * currentRadius
			
			local startPos = Vector3.new(origin.X + x, origin.Y + 1500, origin.Z + z)
			local rayResult = workspace:Raycast(startPos, Vector3.new(0, -4000, 0), raycastParams)
			
			if rayResult and rayResult.Position.Y > highestY then
				highestY = rayResult.Position.Y
				highestPoint = rayResult.Position
			end
		end
	end
	
	return highestPoint
end

local function stopAutoTravel(button)
	isRunning = false
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
	
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	
	setPhysicsLock(false, root)
	setNoclip(false)

	if button then
		button.Text = "BẬT TÌM ĐIỂM CAO"
		button.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
	end
end

-- Khởi chạy di chuyển
local function startAutoTravel(button)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		stopAutoTravel(button)
		return
	end

	button.Text = "ĐANG QUÉT..."
	
	-- Chạy quét bất đồng bộ để tránh khựng màn hình
	task.spawn(function()
		local targetPos = findHighestPointFast(root.Position, SEARCH_RADIUS)
		
		if not targetPos or not isRunning then
			stopAutoTravel(button)
			return
		end

		local finalCFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
		local distance = (finalCFrame.Position - root.Position).Magnitude
		local duration = distance / TWEEN_SPEED

		setNoclip(true)
		setPhysicsLock(true, root)

		button.Text = "ĐANG TWEEN FAST..."
		button.BackgroundColor3 = Color3.fromRGB(220, 60, 60)

		-- Sử dụng EasingStyle.Linear cho chuyển động đều và mượt ở tốc độ cao
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		currentTween = TweenService:Create(root, tweenInfo, {CFrame = finalCFrame})
		
		currentTween:Play()
		currentTween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				stopAutoTravel(button)
			end
		end)
	end)
end

-- UI
local screenGui = CoreGui:FindFirstChild("AutoHighestLandGUI") or Instance.new("ScreenGui")
screenGui.Name = "AutoHighestLandGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainButton = screenGui:FindFirstChild("MainButton") or Instance.new("TextButton")
mainButton.Name = "MainButton"
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

if not mainButton:FindFirstChildOfClass("UICorner") then
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainButton
end

mainButton.MouseButton1Click:Connect(function()
	isRunning = not isRunning
	if isRunning then
		startAutoTravel(mainButton)
	else
		stopAutoTravel(mainButton)
	end
end)
