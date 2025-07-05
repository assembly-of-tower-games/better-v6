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

local Stats = game:GetService("Stats")
local enums = Enum.DeveloperMemoryTag:GetEnumItems()
while true do
	local text = ""
	for _, tag in enums do
		local mb = Stats:GetMemoryUsageMbForTag(tag)
		text ..= `{tag.Name}: {math.ceil(mb)} MB\n`
	end

	script.Parent.Text = text
	task.wait(1)
end
