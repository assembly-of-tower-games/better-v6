type Context = ModuleScript | StringValue

local HTTPService = game:GetService("HttpService")
local Loader = {}

Loader.Threads = {}

local ThreadTemplate = script.Parent.Thread
local Repo = script.Parent.ScriptRepo
local Types = require(script.Parent.Types)

function Loader:LoadScript(Context: Context)
	local Body: ModuleScript

	if Context:IsA("StringValue") then
		local RepoScript: Instance? = Repo:FindFirstChild(Context.Value)

		if RepoScript and RepoScript:IsA("ModuleScript") then
			Body = RepoScript:Clone()

			Body.Name = "RepoScriptInstantiation_" .. Body.Name
			Body.Parent = Context.Parent
		end
	elseif Context:IsA("ModuleScript") then
		Body = Context
	end

	local ClonedThread = ThreadTemplate:Clone()
	local Thread = require(ClonedThread :: ModuleScript) :: Types.Thread

	ClonedThread.Name = HTTPService:GenerateGUID(false)

	local ThreadContext = ClonedThread:WaitForChild("Context") :: ObjectValue
	ThreadContext.Value = Body

	Thread.init()
	Thread.run()

	table.insert(Loader.Threads, Thread)
end

function Loader:Unload()	
	for _, Thread: Types.Thread in pairs(Loader.Threads) do
		Thread.cleanup()
	end
end

return Loader