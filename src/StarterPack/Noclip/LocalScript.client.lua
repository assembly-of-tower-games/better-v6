-- Noclip tool made by funwolf7, modified by bLockerman666

local tool = script.Parent

local upButton = "Space"
local downButton = "LeftControl"
local speedUpButton = "E"
local speedDownButton = "Q"
local speedResetButton = "R"

local keys = {
	UpButton = Enum.KeyCode.Space,
	DownButton = Enum.KeyCode.LeftControl,
	SpeedUpButton = Enum.KeyCode.E,
	SpeedDownButton = Enum.KeyCode.Q,
	SpeedResetButton = Enum.KeyCode.R,
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
local controlModule = playerModule:GetControls()

local equipped = false
local connection = nil

local defaultSpeed = tool:FindFirstChild("Speed") and tool.Speed.Value or 60
local speed = 0

UserInputService.InputBegan:Connect(function(key, typing)
	if not equipped or typing then
		return
	end
	
	for name, keyCode in keys do
		if key.KeyCode == keyCode then
			speed = name == "SpeedUpButton" and speed + 1
				or name == "SpeedDownButton" and speed - 1
				or name == "SpeedResetButton" and 0
				or speed
		end
	end
end)

tool.ToolTip ..= ` Press {upButton} to move upwards.`
tool.ToolTip ..= ` Press {downButton} to move downwards.`
tool.ToolTip ..= ` Press {speedUpButton} to speed up.`
tool.ToolTip ..= ` Press {speedDownButton} to slow down.`
tool.ToolTip ..= ` Press {speedResetButton} to reset speed.`

tool.Equipped:Connect(function()
	equipped = true
	
	connection = RunService.Heartbeat:Connect(function(step)
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		
		if humanoid then
			humanoid.PlatformStand = true
		end
		
		if humanoidRootPart and camera then
			humanoidRootPart.Anchored = true
			humanoidRootPart.Velocity = Vector3.zero

			local moveAmount = controlModule:GetMoveVector() or Vector3.zero

			if not UserInputService:GetFocusedTextBox() then
				if UserInputService:IsKeyDown(keys.UpButton) then
					moveAmount = Vector3.new(moveAmount.X, 1, moveAmount.Z)
				end

				if UserInputService:IsKeyDown(keys.DownButton) then
					moveAmount = Vector3.new(moveAmount.X, moveAmount.Y - 1, moveAmount.Z)
				end
			end

			moveAmount = moveAmount.Magnitude > 1 and moveAmount.Unit or moveAmount
			moveAmount *= step * defaultSpeed * 1.25 ^ speed

			humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + camera.CFrame.LookVector) * CFrame.new(moveAmount)
		end
	end)
end)

tool.Unequipped:Connect(function()
	equipped = false
	
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	
	if humanoid then
		humanoid.PlatformStand = false
	end

	if humanoidRootPart then
		humanoidRootPart.Anchored = false
	end
	
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)