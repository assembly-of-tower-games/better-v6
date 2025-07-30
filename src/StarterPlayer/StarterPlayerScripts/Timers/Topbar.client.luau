--!nocheck

if not game:IsLoaded() then
	game.Loaded:Wait()
end

function convertTime(seconds: number): string
	if seconds == nil then
		return "XX:XX.XX"
	end

	local min = math.floor(seconds / 60)
	local sec = seconds % 60
	local ms = string.format("%.2f", tostring(seconds % 1)):sub(3, 4)

	return string.format("%02i:%02i.%02i", min, sec, ms)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Namespaces = ReplicatedStorage.Namespaces
local TimerNamespace = require(Namespaces.Timer)

local TopbarPlus = require(Packages.TopbarPlus)
local TimerIcon = TopbarPlus.new()

TimerIcon:setName("Timer")
TimerIcon:setLabel("XX:XX.XX")
TimerIcon:setImage(6761866149)
TimerIcon:setEnabled(false)
TimerIcon:align("Center")
TimerIcon:oneClick(true)

TimerNamespace.packets.CorrectTimer.listen(function(seconds: number)
	local convertedTime = convertTime(seconds)
	
	TimerIcon:setLabel(convertedTime)
end)

Players.LocalPlayer:GetAttributeChangedSignal("CurrentTower"):Connect(function()
	TimerIcon:setEnabled(Players.LocalPlayer:GetAttribute("CurrentTower") ~= "")
	TimerIcon:setLabel(Players.LocalPlayer:GetAttribute("CurrentTower") ~= "" and "XX:XX.XX" or "00:00.00")
end)
