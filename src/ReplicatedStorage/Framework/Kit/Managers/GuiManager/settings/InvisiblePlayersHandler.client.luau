--!strict
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local config = localPlayer:WaitForChild("KitConfiguration")

local ATTRIBUTE_KEY = "InvisPlayers"

local partCache = {} :: { [Player]: Model }
local function updateInvisiblePlayers()
	local isEnabled = config:GetAttribute(ATTRIBUTE_KEY)
	local parent = if isEnabled then nil else workspace
	for player, model in partCache do
		model.Parent = parent
	end
end

local function onCharacterAdded(player: Player, character: Model)
	partCache[player] = character
	updateInvisiblePlayers()
end

local function onPlayerAdded(player: Player)
	if player == localPlayer then
		return
	end

	onCharacterAdded(player, player.Character or player.CharacterAdded:Wait())
	player.CharacterAdded:Connect(function(newCharacter)
		onCharacterAdded(player, newCharacter)
	end)
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player: Player)
	partCache[player] = nil
end)
config:GetAttributeChangedSignal(ATTRIBUTE_KEY):Connect(updateInvisiblePlayers)
