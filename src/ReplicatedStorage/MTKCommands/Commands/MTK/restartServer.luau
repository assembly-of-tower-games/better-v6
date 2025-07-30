return function(_Context, Players)
	for _, Player in pairs(Players) do
		local CurrentTower = Player:GetAttribute("CurrentTower")

		if CurrentTower ~= "" then
			Player:SetAttribute("ForceRestarting", true)

			Player:SetAttribute("CurrentTower", "")
			Player:SetAttribute("CurrentTower", CurrentTower)

			Player.CharacterAdded:Once(function()
				Player:SetAttribute("ForceRestarting", false)
			end)
		end
	end

	return "Restarted tower for players."
end
