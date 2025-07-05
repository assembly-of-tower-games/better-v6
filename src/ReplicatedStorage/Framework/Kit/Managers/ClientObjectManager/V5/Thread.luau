local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage:WaitForChild("Libs"):WaitForChild("Janitor")) :: any

local Context: ModuleScript
local ThreadJanitor = nil

type Thread = {
	init: () -> (),
	run: () -> (),
	cleanup: () -> (),
}

local Thread = {} :: Thread

function Thread.init(NewContext: ModuleScript)
	Context = NewContext
	ThreadJanitor = Janitor.new()
end

function Thread.run()
	if Context and ThreadJanitor then
		task.spawn(function()
			local Success, Error = pcall(function()
				if Context then
					(require(Context) :: any)()
				else
					error("No Context found")
				end
			end)

			if not Success then
				warn(string.format("[V5 Error] %s", Error))
			end
		end)
	end
end

function Thread.cleanup()
	if ThreadJanitor then
		ThreadJanitor:Destroy()
		ThreadJanitor = nil
	end
end

return Thread
