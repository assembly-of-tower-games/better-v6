type Context = ModuleScript | StringValue | ObjectValue

local HTTPService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = {}

type Thread = {
	init: () -> (),
	run: () -> (),
	cleanup: () -> (),
}

Loader.Threads = {} :: {Thread}

local ThreadTemplate = script.Parent.Thread
local Repo = script.Parent.ScriptRepo

function Loader:LoadScript(Object: Instance, Context: Context)
	local Body: ModuleScript

	if Context:IsA("StringValue") then
		local RepoScript: Instance? = Repo:FindFirstChild(Context.Value)

		if RepoScript and RepoScript:IsA("ModuleScript") then
			Body = RepoScript:Clone()

			Body.Name = "RepoScriptInstantiation_" .. Body.Name
			Body.Parent = Context.Parent
		end
	elseif Context:IsA("ObjectValue") then
		if Context.Value and Context.Value:IsA("ModuleScript") then 
			Body = Context.Value
		end
	elseif Context:IsA("ModuleScript") then
		Body = Context
	end

	local ClonedThread = ThreadTemplate:Clone()
	local Thread = require(ClonedThread :: ModuleScript) :: Thread

	local PointerLinkContainer = ReplicatedStorage:WaitForChild("__POINTER_LINK_STORAGE")
	local PointerLink = PointerLinkContainer:WaitForChild(Object.Name)

	ClonedThread.Name = HTTPService:GenerateGUID(false)
	ClonedThread.Parent = PointerLink.Value

	Thread.init(Body, Object)
	Thread.run()
	
	table.insert(Loader.Threads, Thread)
end

function Loader:Unload()	
	for _, Thread: Thread in pairs(Loader.Threads) do
		Thread.cleanup()
	end
end

return Loader