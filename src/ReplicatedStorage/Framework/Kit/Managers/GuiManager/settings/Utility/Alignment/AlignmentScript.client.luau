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

local Workspace = game:GetService("Workspace")

local util = script.Parent
util.left.MouseButton1Click:Connect(function()
	Workspace.CurrentCamera:PanUnits(1)
end)

util.right.MouseButton1Click:Connect(function()
	Workspace.CurrentCamera:PanUnits(-1)
end)
