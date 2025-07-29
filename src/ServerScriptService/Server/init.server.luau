--!nocheck
-- By @synnwave (29/11/24 DD/MM/YY)
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

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local COLLISION_MAP = require(script.CollisionGroupMap)
local KitSettings = require(ReplicatedStorage.KitSettings)
local InternalConfig = require(script.KitConfig)

local Utility = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Kit"):WaitForChild("Utility")
local WebhookUtils = require(Utility:WaitForChild("Webhooks"))

local Framework = ReplicatedStorage.Framework
local Namespaces = Framework.Namespaces

local TowersNamespace = require(Namespaces.Towers)
local TimerNamespace = require(Namespaces.Timer)
local AnnouncementNamespace = require(Namespaces.Announcement)

local VERSION_NUMBER = "6.0.0"
local timers = {}

--------------------------------------------------------------------------------

function findValue(parent: BasePart, name: string): string | nil
	if parent:GetAttribute(name) then
		return parent:GetAttribute(name) :: string
	elseif parent:FindFirstChild(name) then
		if parent:FindFirstChild(name):IsA("StringValue") then
			return (parent:FindFirstChild(name) :: StringValue).Value
		end
	end

	return nil
end

function convertTime(seconds: number): string
	if seconds == nil then
		return "XX:XX.XX"
	end

	local min = math.floor(seconds / 60)
	local sec = seconds % 60
	local ms = string.format("%.2f", tostring(seconds % 1)):sub(3, 4)

	return string.format("%02i:%02i.%02i", min, sec, ms)
end

function step(deltaTime: number)
	for id, timer in pairs(timers) do
		local plr = Players:GetPlayerByUserId(id)

		if plr then
			timers[id] = timer + deltaTime

			TimerNamespace.packets.CorrectTimer.sendTo(timers[id], plr)
		end
	end
end

--------------------------------------------------------------------------------

do --> Collision Groups
	-- first iteration: register collision groups from the map
	for groupName in COLLISION_MAP do
		PhysicsService:RegisterCollisionGroup(groupName)
	end

	-- second iteration: set groups collidable
	for groupName, map in COLLISION_MAP do
		for _, doesNotCollideWith in map do
			PhysicsService:CollisionGroupSetCollidable(groupName, doesNotCollideWith, false)
		end
	end
end

--------------------------------------------------------------------------------

do --> Damage Event
	local debounceArray = {} :: { [Player]: boolean? }

	function handleDamage(player: Player, type: string | number)
		if debounceArray[player] then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local damageValue = if typeof(type) == "number" then type else 5
		if type == "Heals" then
			damageValue = -(humanoid.MaxHealth - humanoid.Health)
		end

		if damageValue > 0 then -- no debounce for healing
			debounceArray[player] = true
			task.delay(0.1, function()
				debounceArray[player] = nil
			end)
		end

		humanoid:TakeDamage(damageValue)
		if humanoid.Health > humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth
		end
	end

	TowersNamespace.packets.DamageEvent.listen(function(data: number, player: Player?)
		handleDamage(player :: Player, data)
	end)
	TowersNamespace.packets.DamageEventS.listen(function(data: string, player: Player?)
		handleDamage(player :: Player, data)
	end)
end

--------------------------------------------------------------------------------

do --> Create Player Configuration Folder
	local function onPlayerAdded(player: Player)
		local configurationFolder = Instance.new("Configuration")
		configurationFolder.Name = "KitConfiguration"
		configurationFolder.Parent = player
	end

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

--------------------------------------------------------------------------------

do --> Handle Tower Client Objects
	--> Move client objects folder to where they need to go
	function getPlayerCOs(player: Player)
		local tower = player:GetAttribute("CurrentTower") or ""

		if tower == "" then
			return nil
		end

		local clientObjectsFolder = ServerStorage.ClientObjects:FindFirstChild(tower)

		if not clientObjectsFolder then
			return nil
		end

		--> Make ModuleScript pointers
		-- this is to help reduce memory usage when requiring modules !
		-- i'm still keeping repository scripts the way they are though because
		-- this is meant for much smaller modules like lighting configurations
		local pointerTemplate = Instance.new("ObjectValue")
		pointerTemplate:AddTag("OBJ_POINTER")

		local pointerContainer = ReplicatedStorage:FindFirstChild("__POINTER_STORAGE") or Instance.new("Folder")
		pointerContainer.Name = "__POINTER_STORAGE"
		pointerContainer.Parent = ReplicatedStorage

		local pointerLinkContainer = ReplicatedStorage:FindFirstChild("__POINTER_LINK_STORAGE")
			or Instance.new("Folder")
		pointerLinkContainer.Name = "__POINTER_LINK_STORAGE"
		pointerLinkContainer.Parent = ReplicatedStorage

		local warnings = {}
		local version = clientObjectsFolder:GetAttribute("KitVersion")
		if version ~= VERSION_NUMBER then
			table.insert(warnings, {
				"ClientObjects folder is missing its KitVersion Attribute or is outdated",
				`Current version is: {VERSION_NUMBER}`,
			})
		end

		local descendantCount = 0
		local partCount = 0

		for _, instance in clientObjectsFolder:GetDescendants() do
			descendantCount += 1

			if instance:IsA("ModuleScript") then
				local pointerLink = pointerTemplate:Clone()
				pointerLink.Value = instance.Parent
				pointerLink.Name = instance.Parent.Name
				pointerLink.Parent = pointerLinkContainer

				local thisPointer = pointerTemplate:Clone()
				thisPointer.Value = instance
				thisPointer.Name = instance.Name
				thisPointer.Parent = instance.Parent

				instance.Name = pointerLink.Name
				--instance.Parent = pointerContainer
			elseif instance:IsA("BasePart") then
				partCount += 1

				if instance.CollisionGroup == "Default" and not instance:FindFirstAncestor("LightingChangers") then
					instance.CollisionGroup = "ClientObjects"
				end

				if
					instance.Name == "LightingChanger"
					or instance:FindFirstChild("invisible")
					or instance:FindFirstChild("Invisible")
				then
					instance:AddTag("Invisible")

					if instance:FindFirstChild("invisible") then
						instance.invisible:Destroy()
					end
					if instance:FindFirstChild("Invisible") then
						instance.Invisible:Destroy()
					end
				end
			elseif instance:IsA("NoCollisionConstraint") and instance:FindFirstAncestorOfClass("BasePart") then
				instance:FindFirstAncestorOfClass("BasePart").CollisionGroup = "ClientObjects"
				instance:FindFirstAncestorOfClass("BasePart").CanCollide = false

				instance:Destroy()
			end
		end

		ReplicatedStorage.KitSettings:SetAttribute("COPartCount", partCount)
		ReplicatedStorage.KitSettings:SetAttribute("COInstanceCount", descendantCount)

		return clientObjectsFolder
	end

	--> Listen to client requests
	local clones = {} :: { [Player]: Instance? }

	TowersNamespace.packets.RequestCOFolder.listen(function(request: string, player: Player?)
		if request == "request" then
			local clientObjectsFolder = getPlayerCOs(player)

			if not clientObjectsFolder then
				return
			end

			local playerGui = player:WaitForChild("PlayerGui")
			local clonedFolder = clientObjectsFolder:Clone()

			clonedFolder:AddTag("ClientObjects")
			clonedFolder.Parent = playerGui

			clones[player] = clonedFolder
		elseif request == "cleanup" then
			local clone = clones[player]

			if clone then
				clone:Destroy()
			end

			clones[player] = nil
		end
	end)
end

--------------------------------------------------------------------------------

do --> Init Player Attributes
	function CharacterAdded(character: Model)
		local player = Players:GetPlayerFromCharacter(character)

		if player then
			task.defer(function()
				if not KitSettings.ResetOnDeath and not player:GetAttribute("LoadingTower") then
					player:SetAttribute("CurrentTower", "")
				end
			end)
		end
	end

	function PlayerAdded(player: Player)
		if player.Character then
			task.spawn(CharacterAdded, player.Character)
		end
		player.CharacterAdded:Connect(CharacterAdded)

		player:SetAttribute("CurrentTower", "")
		player:SetAttribute("LoadingTower", false)

		player:GetAttributeChangedSignal("CurrentTower"):Connect(function()
			if
				not player:GetAttribute("LoadingTower")
				and ServerStorage.ClientObjects:FindFirstChild(player:GetAttribute("CurrentTower"))
			then
				player:SetAttribute("LoadingTower", true)
				player:LoadCharacter()
			end
		end)
	end
	function PlayerRemoving(player: Player)
		if timers[player.UserId] then
			timers[player.UserId] = nil
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(PlayerAdded, player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

--------------------------------------------------------------------------------

do --> Init Towers
	local WINPAD_DEBOUNCE = 0.5

	function parseColour(colour: Color3)
		local R = (colour.R * 255)
		local G = (colour.G * 255)
		local B = (colour.B * 255)

		return string.format("rgb(%d, %d, %d)", R, G, B)
	end

	function onPlayerWin(player: Player, plrTime: number, tower: Folder)
		local difficulty = findValue(tower, "Difficulty") or "Easy"
		local difficultyEmojiID = InternalConfig.Webhooks.Difficulties[difficulty]
		local name = findValue(tower, "ProperName") or tower.Name
		local convertedTime = convertTime(plrTime)

		local message = RunService:IsStudio() and InternalConfig.Webhooks.Testing.Message
			or InternalConfig.Webhooks.Message
		local url = RunService:IsStudio() and InternalConfig.Webhooks.Testing.Normal or InternalConfig.Webhooks.Normal
		local timestamp = WebhookUtils:GetTimestamp("f")

		message = string.gsub(message, "{DisplayName}", player.DisplayName)
		message = string.gsub(message, "{Username}", player.Name)
		message = string.gsub(message, "{TowerName}", name)
		message = string.gsub(message, "{Difficulty}", difficulty)
		message = string.gsub(message, "{DifficultyEmoji}", string.format("<:%s:%s>", difficulty, difficultyEmojiID))
		message = string.gsub(message, "{Time}", convertedTime)
		message = string.gsub(message, "{Timestamp}", timestamp)

		WebhookUtils:Post({
			Message = message,
			URL = url,
		})

		local winMessage = InternalConfig.WinMessage
		local difficultyColour = parseColour(InternalConfig.Webhooks.DifficultyColours[difficulty])

		winMessage = string.gsub(winMessage, "{DisplayName}", player.DisplayName)
		winMessage = string.gsub(winMessage, "{Username}", player.Name)
		winMessage = string.gsub(winMessage, "{TowerName}", name)
		winMessage = string.gsub(winMessage, "{Difficulty}", difficulty)
		winMessage = string.gsub(winMessage, "{Time}", convertedTime)
		winMessage = string.format(`<font color="%s">%s</font>`, difficultyColour, winMessage)

		AnnouncementNamespace.packets.WinAnnouncement.sendToAll({
			Text = winMessage,
			Colour = Color3.fromRGB(255, 255, 255),
		})

		player:SetAttribute("CurrentTower", "")
		player:LoadCharacter()
	end

	function initWinpad(winpad: BasePart)
		if not winpad then
			return
		end

		local towerName = findValue(winpad, "TowerName")

		if towerName == nil then
			return
		end
		if not workspace.Towers:FindFirstChild(towerName) then
			return
		end

		winpad:SetAttribute("Debounce", false)
		winpad.Touched:Connect(function(Hit)
			if winpad:GetAttribute("Debounce") then
				return
			end

			if not Hit then
				return
			end
			if not Hit.Parent or not Hit.Parent:IsA("Model") or not Hit.Parent:FindFirstChildOfClass("Humanoid") then
				return
			end

			local character = Hit.Parent
			local player = Players:GetPlayerFromCharacter(Hit.Parent)

			if not character or not player then
				return
			end
			if player:GetAttribute("CurrentTower") ~= towerName then
				return
			end

			winpad:SetAttribute("Debounce", true)
			local plrTime = timers[player.UserId] or 0

			timers[player.UserId] = nil
			onPlayerWin(player, plrTime, workspace.Towers:FindFirstChild(towerName))

			task.delay(WINPAD_DEBOUNCE, function()
				winpad:SetAttribute("Debounce", false)
			end)
		end)
	end

	function initTower(tower: Folder)
		do --> Init ClientSidedObjects
			local clientSidedObjects = tower:FindFirstChild("ClientSidedObjects")

			if tower:FindFirstChild("ClientSidedObjects") then
				local towerLink = Instance.new("ObjectValue")
				towerLink.Name = "TowerLink"
				towerLink.Value = tower
				towerLink.Parent = clientSidedObjects

				clientSidedObjects.Name = tower.Name
				clientSidedObjects.Parent = ServerStorage.ClientObjects
			end
		end

		do --> Init Winpad
			local winpad = tower:FindFirstChild("WinPad", true)

			if winpad then
				initWinpad(winpad)
			end
		end
	end

	for _, tower in pairs(workspace.Towers:GetChildren()) do
		if tower:HasTag("Tower") then
			initTower(tower)
		end
	end
end

do --> Init Tower Loading
	TowersNamespace.packets.FinishedLoading.listen(function(_data, player: Player?)
		player:SetAttribute("LoadingTower", false)
	end)
end

--------------------------------------------------------------------------------

do --> Init Portals
	local PORTAL_DEBOUNCE = 0.5

	function initPortal(portal: BasePart)
		if not portal then
			return
		end

		local towerName = findValue(portal, "TowerName")

		if towerName == nil then
			return
		end
		if not workspace.Towers:FindFirstChild(towerName) then
			return
		end

		portal:SetAttribute("Debounce", false)
		portal.Touched:Connect(function(Hit)
			if portal:GetAttribute("Debounce") then
				return
			end

			if not Hit then
				return
			end
			if not Hit.Parent or not Hit.Parent:IsA("Model") or not Hit.Parent:FindFirstChildOfClass("Humanoid") then
				return
			end

			local character = Hit.Parent
			local player = Players:GetPlayerFromCharacter(Hit.Parent)

			if not character or not player then
				return
			end
			if player:GetAttribute("CurrentTower") == towerName then
				return
			end

			portal:SetAttribute("Debounce", true)

			player:SetAttribute("CurrentTower", towerName)
			timers[player.UserId] = 0

			task.delay(PORTAL_DEBOUNCE, function()
				portal:SetAttribute("Debounce", false)
			end)
		end)
	end

	for _, portal in pairs(workspace.Portals:GetChildren()) do
		if portal:IsA("BasePart") and portal:HasTag("TowerPortal") then
			initPortal(portal)
		end
	end
end

--------------------------------------------------------------------------------

do --> Step Function
	RunService.Stepped:Connect(function(time, deltaTime)
		step(deltaTime)
	end)
end
