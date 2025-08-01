local Context: ModuleScript

type Thread = {
	init: () -> (),
	run: () -> (),
	cleanup: () -> (),

	thread: Instance,
	name: string,
}

local Thread = {} :: Thread
local Task = nil :: thread | nil

function Thread.init(NewContext: ModuleScript)
	Context = NewContext
end

function Thread.run()
	if Context then
		task.spawn(function()
			local Success, Error = pcall(function()
				if Context then
					Task = task.spawn(require(Context) :: () -> ())
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
	if Task then
		task.cancel(Task)
		Task = nil
	end

	if Thread.thread then
		Thread.thread:Destroy()
	end

	script:Destroy()
end

return Thread
