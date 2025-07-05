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

local root = script:FindFirstAncestor("settings")
local newScrollableList = require(root.SettingsHandler.ScrollableList)

local util = script.Parent
local list = newScrollableList({
	"dance2",
	"point",
	"cheer",
	"wave",
})

util.left.MouseButton1Click:Connect(function()
	util.emote.Text = list:Scroll(-1)
end)
util.right.MouseButton1Click:Connect(function()
	util.emote.Text = list:Scroll(1)
end)
util.emote.MouseButton1Click:Connect(function()
	local character = localPlayer.Character
	local animateScript = character and character:FindFirstChild("Animate")
	if not character or not animateScript then
		return
	end

	local playEmote = animateScript:FindFirstChild("PlayEmote")
	if not playEmote then
		return
	end

	playEmote:Invoke(list:Current())
end)
