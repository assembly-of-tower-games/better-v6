local tool = script.Parent
local regenConnection

tool.Equipped:Connect(function()
	local character = tool.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		regenConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			humanoid.Health = humanoid.MaxHealth
		end)
	end
end)

tool.Unequipped:Connect(function()
	if regenConnection then
		regenConnection:Disconnect()
	end
end)
