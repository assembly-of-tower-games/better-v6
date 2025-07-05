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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local obbyFolder = workspace:FindFirstChild("Obby", true)
local partCount = 0
if obbyFolder then
	for _, part in obbyFolder:GetDescendants() do
		if part:IsA("BasePart") then
			partCount += 1
		end
	end
end

local KitSettingsModule = ReplicatedStorage.KitSettings
local clientObjectPartCount = KitSettingsModule:GetAttribute("COPartCount") or 0
KitSettingsModule:GetAttributeChangedSignal("COPartCount"):Connect(function()
	clientObjectPartCount = KitSettingsModule:GetAttribute("COPartCount")
end)

while true do
	local text = "EToH Kit V6 Debug Stats\n"
	text ..= `Memory: {math.ceil(Stats:GetTotalMemoryUsageMb())} MB\n`
	text ..= `FPS: {math.ceil(1 / Stats.FrameTime)}\n`
	text ..= `Instances: {Stats.InstanceCount} ({partCount} Obby, {clientObjectPartCount} CO)\n`
	text ..= `Moving Primitives: {Stats.MovingPrimitivesCount}\n`
	text ..= `Draw Calls: {Stats.SceneDrawcallCount}\n`
	text ..= `Triangles: {Stats.SceneTriangleCount}\n`
	text ..= `Shadow Triangles: {Stats.ShadowsTriangleCount}\n`

	script.Parent.Text = text
	task.wait(1)
end
