local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cmdr = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Cmdr"))

return function()
	Cmdr:RegisterCommandsIn(ReplicatedStorage:WaitForChild("MTKCommands"):WaitForChild("Commands"))
	Cmdr:RegisterHooksIn(ReplicatedStorage:WaitForChild("MTKCommands"):WaitForChild("Hooks"))
	Cmdr:RegisterTypesIn(ReplicatedStorage:WaitForChild("MTKCommands"):WaitForChild("Types"))
end
