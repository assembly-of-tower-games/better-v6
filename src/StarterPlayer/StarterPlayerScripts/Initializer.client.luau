--!nocheck
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

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Framework = ReplicatedStorage.Framework
local Remotes = Framework.Remotes
local Namespace = require(Remotes.Towers)

local Kit = ReplicatedStorage.Framework.Kit
local KitSettings = require(ReplicatedStorage.KitSettings)

--> Disable some stuff
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

--> Wait for character
if not Players.LocalPlayer.Character then
	Players.LocalPlayer.CharacterAdded:Wait()
end

--> Initializing
local _CharacterManager = require(Kit.Managers.CharacterManager):Init()
local _FlipManager = require(Kit.Managers.FlipManager):Init()
local LightingManager = require(Kit.Managers.LightingManager):Init()
local ClientObjectManager = require(Kit.Managers.ClientObjectManager):Init()
local _GuiManager = require(Kit.Managers.GuiManager):Init()

--> Load Client Objects
local ClientParts = Workspace:FindFirstChild("ClientParts")
	or (function()
		local newFolder = Instance.new("Folder")
		newFolder.Name = "ClientParts"
		newFolder.Parent = Workspace
		return newFolder
	end)()

--> Request server for objects
local customRepository = ReplicatedStorage:FindFirstChild("ExternalRepositories")
local towerName = "TowerKit"

local currentlyLoading = false
local objectScope

local function requestObjects()
	if currentlyLoading then
		return
	end
	currentlyLoading = true
	
	local result = {objects = nil, warnings = {}} :: {objects: Folder | nil, warnings: {any}}

	Namespace.packets.RequestCOFolder.send("request")
	Namespace.packets.RespondCOFolder.listen(function(data, _player: Player?)
		result = data
	end)
	
	repeat
		task.wait()
	until result
	
	local receivedObjects, warnings = result.objects, result.warnings
	local objects = receivedObjects:Clone()
	
	receivedObjects:Destroy()
	Namespace.packets.RequestCOFolder.send("cleanup")

	objectScope = ClientObjectManager:LoadClientObjects(
		objects,
		ClientParts,
		towerName,
		customRepository:FindFirstChild(towerName)
	)
	
	currentlyLoading = false
	receivedObjects = nil
	objects = nil

	if warnings then
		for _, warningTable in warnings do
			objectScope:log({
				warningTable.text,
				type = warningTable.type
			})
		end
	end
end

requestObjects()

--> Reset objects on respawn
if KitSettings.ResetOnDeath then
	Players.LocalPlayer.CharacterAdded:Connect(function()
		if objectScope then
			objectScope:cleanup(false, true)
			objectScope = nil :: any
		end

		LightingManager:ResetLighting()
		ClientParts:ClearAllChildren()
		
		task.defer(requestObjects)
	end)
end
