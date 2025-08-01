type Context = ModuleScript | StringValue | ObjectValue

local HTTPService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = {}

type Thread = {
	init: () -> (),
	run: () -> (),
	cleanup: () -> (),

	thread: Instance,
	name: string
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

	if not Body then 
		return
	end

	local ClonedThread = ThreadTemplate:Clone()
	local Thread = require(ClonedThread :: ModuleScript) :: Thread

	local PointerLinkContainer = ReplicatedStorage:WaitForChild("__POINTER_LINK_STORAGE")

	if PointerLinkContainer:FindFirstChild(Object.Name) then 
		if PointerLinkContainer[Object.Name].Value then 
			PointerLinkContainer[Object.Name].Value:Destroy()
		end
	end

	local PointerLink = PointerLinkContainer:WaitForChild(Object.Name)

	ClonedThread.Name = HTTPService:GenerateGUID(false)
	ClonedThread.Parent = PointerLink.Value

	Thread.name = Object:GetFullName()
	Thread.thread = ClonedThread

	local Success, Error = pcall(function()
		Thread.init(Body, Object)
		Thread.run()
	end)

	if not Success then 
		warn(Error)
	end
	
	table.insert(Loader.Threads, Thread)
end

function Loader:Unload()	
	for _, Thread: Thread in pairs(Loader.Threads) do
		print("Unloading thread ", Thread.name)
		Thread.cleanup()
	end
end

return Loader