local Context: ModuleScript

type Thread = {
	init: () -> (),
	run: () -> (),
	cleanup: () -> (),
}

local Thread = {} :: Thread

function Thread.init(NewContext: ModuleScript)
	Context = NewContext
end

function Thread.run()
	if Context then
		task.spawn(function()
			local Success, Error = pcall(function()
				if Context then
					(require(Context) :: () -> ())()
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
	
end

return Thread
