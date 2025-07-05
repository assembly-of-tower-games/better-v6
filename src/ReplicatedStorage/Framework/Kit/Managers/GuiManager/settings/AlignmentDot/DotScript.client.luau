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

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local gui = script.Parent
local dot = gui:WaitForChild("dot")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function onCharacterAdded(character: Model)
	task.wait()
	local primaryPart = character.PrimaryPart
	if not primaryPart then
		character:GetPropertyChangedSignal("PrimaryPart"):Wait()
		primaryPart = character.PrimaryPart
	end
	if not primaryPart then -- WE GIVE UP
		return
	end

	primaryPart:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
		dot.Visible = primaryPart.LocalTransparencyModifier > 0.5
	end)
end

onCharacterAdded(localPlayer.Character or localPlayer.CharacterAdded:Wait())
localPlayer.CharacterAdded:Connect(onCharacterAdded)
