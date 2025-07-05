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
local Namespaces = Framework.Namespaces
local TowersNamespace = require(Namespaces.Towers)

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
local towerName = ""

local currentlyLoading = false
local objectScope

local function requestObjects()
	if currentlyLoading then
		return
	end

	currentlyLoading = true

	local receivedObjects = nil
	local connection = nil

	TowersNamespace.packets.RequestCOFolder.send("request")

	connection = Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(Child)
		if Child:IsA("Folder") and Child:HasTag("ClientObjects") then
			receivedObjects = Child
			towerName = Child.TowerLink.Value.Name

			connection:Disconnect()
		end
	end)

	repeat
		task.wait()
	until receivedObjects and towerName

	local objects = receivedObjects:Clone()

	receivedObjects:Destroy()
	TowersNamespace.packets.RequestCOFolder.send("cleanup")

	objectScope = ClientObjectManager:LoadClientObjects(
		objects,
		ClientParts,
		towerName,
		customRepository:FindFirstChild(towerName)
	)

	currentlyLoading = false
	receivedObjects = nil

	TowersNamespace.packets.FinishedLoading.send()
end

if Players.LocalPlayer:GetAttribute("CurrentTower") ~= "" then
	requestObjects()
end

--> Reset objects on respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
	print(KitSettings.ResetOnDeath and towerName == Players.LocalPlayer:GetAttribute("CurrentTower"))
	print(Players.LocalPlayer:GetAttribute("LoadingTower"))

	if objectScope then
		objectScope:cleanup(false, true)
		objectScope = nil :: any
	end

	LightingManager:ResetLighting()
	ClientParts:ClearAllChildren()

	if
		(KitSettings.ResetOnDeath and towerName == Players.LocalPlayer:GetAttribute("CurrentTower"))
		or (Players.LocalPlayer:GetAttribute("LoadingTower"))
	then
		if Players.LocalPlayer:GetAttribute("CurrentTower") ~= "" then
			task.defer(requestObjects)
		end
	end
end)
