if not game:IsLoaded() then
	game.Loaded:Wait()
end

function ConvertTime(Seconds: number): string
	if Seconds == nil then
		return "XX:XX.XX"
	end

	local Minute = math.floor(Seconds / 60)
	local Second = Seconds % 60
	local Millisecond = string.format("%.2f", Seconds % 1):sub(3, 4)

	return string.format("%02i:%02i.%02i", Minute, Second, Millisecond)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Namespaces = ReplicatedStorage.Namespaces
local TimerNamespace = require(Namespaces.Timer)

local TopbarPlus = require(Packages.TopbarPlus)
local TimerIcon = TopbarPlus.new()
local TowerRushIcon = TopbarPlus.new()

TimerIcon:setName("Timer")
TimerIcon:setLabel("XX:XX.XX")
TimerIcon:setImage(6761866149)
TimerIcon:setEnabled(false)
TimerIcon:align("Center")
TimerIcon:oneClick(true)

TowerRushIcon:setName("TowerRush")
TowerRushIcon:setLabel("0/0")
TowerRushIcon:setEnabled(false)
TowerRushIcon:align("Center")
TowerRushIcon:oneClick(true)

TimerNamespace.packets.CorrectTimer.listen(function(Seconds: number)
	TimerIcon:setLabel(ConvertTime(Seconds))
end)

TimerNamespace.packets.UpdateTowerRush.listen(function(Data:{ CurrentTower: number, TowerCount: number })
	TowerRushIcon:setLabel(string.format("%s/%s", tostring(Data.CurrentTower), tostring(Data.TowerCount)))
	TowerRushIcon:setEnabled(Data.CurrentTower >= 1)
end)

Players.LocalPlayer:GetAttributeChangedSignal("CurrentTower"):Connect(function()
	TimerIcon:setEnabled(Players.LocalPlayer:GetAttribute("CurrentTower") ~= "")
	TimerIcon:setLabel(Players.LocalPlayer:GetAttribute("CurrentTower") ~= "" and "XX:XX.XX" or "00:00.00")
end)
