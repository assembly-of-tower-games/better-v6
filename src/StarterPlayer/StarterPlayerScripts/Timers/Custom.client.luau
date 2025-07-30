if not game:IsLoaded() then
	game.Loaded:Wait()
end

function convertTime(seconds: number): string
	if seconds == nil then
		return "XX:XX.XX"
	end

	local min = math.floor(seconds / 60)
	local sec = seconds % 60
	local ms = string.format("%.2f", seconds % 1):sub(3, 4)

	return string.format("%02i:%02i.%02i", min, sec, ms)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Namespaces = ReplicatedStorage.Namespaces
local TimerNamespace = require(Namespaces.Timer)

local PlayerGui = Players.LocalPlayer.PlayerGui
local Timer = PlayerGui:WaitForChild("Timer") --REPLACE THIS

TimerNamespace.packets.CorrectTimer.listen(function(seconds: number)
	local convertedTime = convertTime(seconds)
	
	Timer.TimerPanel.Text.Text = convertedTime
end)

Players.LocalPlayer:GetAttributeChangedSignal("CurrentTower"):Connect(function()
	Timer.Enabled = Players.LocalPlayer:GetAttribute("CurrentTower") ~= ""
    Timer.TimerPanel.Text.Text = Players.LocalPlayer:GetAttribute("CurrentTower") ~= "" and "XX:XX.XX" or "00:00.00"
end)