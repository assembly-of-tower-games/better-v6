local Context: Instance = script.Context.Value

local Types = require(script.Parent.Types)
local Body: ModuleScript

local Thread = {} :: Types.Thread

Thread.link = script

function Thread.init()
	if Context:IsA("ModuleScript") then
		Body = Context
	end
	
	print(Context)
end

function Thread.run()
	local Success, Error = pcall(function()
		task.spawn(require(Body :: ModuleScript) :: any)
	end)
	
	if not Success then
		warn(string.format("[V5 Error] %s", Error))
	end
end

function Thread.cleanup()
	Thread.link:Destroy()
end

return Thread 