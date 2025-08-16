local PhysicsService = game:GetService("PhysicsService")
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local ServerStorage = game:GetService("ServerStorage")

local Types = require(script.Types)
local InternalConfig = require(script.KitConfig)
local COLLISION_MAP = require(script.CollisionGroupMap)
local Leaderstats = require(script.Leaderstats)

local Utility = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Kit"):WaitForChild("Utility")
local WebhookUtils = require(Utility:WaitForChild("Webhooks"))

local Namespaces = ReplicatedStorage.Namespaces
local RealmData = ServerScriptService.RealmData
local TowerCheckpointsFolder = ServerStorage.TowerCheckpointsFolder

local TowerRushes = require(RealmData.TowerRushes) :: Types.Dictionary<Types.TowerRush>
local KitSettings = require(ReplicatedStorage.KitSettings)

local StartTime = tick()

if KitSettings.StartupTime then
	print("BetterV6 Server has started loading.")
end

local TowersNamespace = require(Namespaces.Towers)
local TimerNamespace = require(Namespaces.Timer)
local AnnouncementsNamespace = require(Namespaces.Announcements)

local Towers = workspace:WaitForChild("Towers") :: Folder & { Folder }
local Portals = workspace:WaitForChild("Portals") :: Folder & { BasePart }
local Markers = workspace:WaitForChild("Markers") :: Folder & { BasePart }

local InitiatedTowers = {} :: { Types.TowerInfo }
local Players = {} :: { Types.PlayerInfo }
local Timers = {} :: { [number]: number }

local WinpadParticles: ParticleEmitter = ServerStorage.WinpadParticles
local Winpads: Types.List<BasePart> = {}
local WinpadMaterials: Types.List<Enum.Material> = Enum.Material:GetEnumItems()

--------------------------------------------------------------------------------

function FindValue(Parent: Instance, Name: string): any | nil
	if Parent:GetAttribute(Name) then
		return Parent:GetAttribute(Name) :: any
	elseif Parent:FindFirstChild(Name) then
		local Child = Parent[Name] :: Instance

		if Child:IsA("ValueBase") then
			return Child.Value
		end
	end

	return nil
end

function ConvertTime(Seconds: number): string
	if Seconds == nil then
		return "XX:XX.XX"
	end

	local Minute = math.floor(Seconds / 60)
	local Second = Seconds % 60
	local Millisecond = string.format("%.2f", Seconds % 1):sub(3, 4)

	return string.format("%02i:%02i.%02i", Minute, Second, Millisecond)
end

function ParseColour(colour: Color3)
	local R = (colour.R * 255)
	local G = (colour.G * 255)
	local B = (colour.B * 255)

	return string.format("rgb(%d, %d, %d)", R, G, B)
end

function IsPlayerPart(Hit: BasePart)
	if Hit.Parent and Hit.Parent:FindFirstChild("Humanoid") then
		local Player: Player? = PlayersService:GetPlayerFromCharacter(Hit.Parent)

		if Player then
			return true, Player.Name
		end
	end

	return false, ""
end

function ResetPlayerInfo(Player: Types.PlayerInfo)
	Player.CurrentTowerRush = ""
	Player.CurrentTowerRushIndex = 0

	local SentData = {
		CurrentTower = 0,
		TowerCount = 0,
		PlayerID = tostring(Player.Player.UserId),
	}

	TimerNamespace.packets.UpdateTowerRush.sendToAll(SentData)
end

function Step(Time: number, DeltaTime: number)
	Leaderstats.Step(DeltaTime)

	for ID, Timer in pairs(Timers) do
		local Player = PlayersService:GetPlayerByUserId(ID)

		if Player then
			local NewTimer = Timer + DeltaTime

			Timers[ID] = NewTimer
			TimerNamespace.packets.CorrectTimer.sendTo(NewTimer, Player)
		end
	end

	local PrevInterval: number = math.floor((Time - DeltaTime) / KitSettings.WinpadSettings.Interval)
		* KitSettings.WinpadSettings.Interval
	local CurrentInterval: number = math.floor(Time / KitSettings.WinpadSettings.Interval)
		* KitSettings.WinpadSettings.Interval

	if PrevInterval < CurrentInterval then
		for _, Winpad: BasePart in pairs(Winpads) do
			if KitSettings.WinpadSettings.ChangeColour then
				Winpad.Color = Color3.fromHSV(math.random(0, 100) / 100, 1, 1)
			end

			if KitSettings.WinpadSettings.ChangeMaterial then
				Winpad.Material = WinpadMaterials[math.random(1, #WinpadMaterials)]
			end
		end
	end
end

--------------------------------------------------------------------------------

for GroupName, Map in pairs(COLLISION_MAP) do
	PhysicsService:RegisterCollisionGroup(GroupName)
end

for GroupName, Map in pairs(COLLISION_MAP) do
	for _, DoesNotCollideWith in pairs(Map) do
		PhysicsService:CollisionGroupSetCollidable(GroupName, DoesNotCollideWith, false)
	end
end

--------------------------------------------------------------------------------

local DebounceArray = {} :: { [Player]: boolean? }

function HandleDamage(Player: Player, Type: string | number)
	if DebounceArray[Player] then
		return
	end

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

	if not (Character or Humanoid) then
		return
	end

	local DamageValue = if typeof(Type) == "number" then Type else 5

	if Type == "Heals" then
		DamageValue = -(Humanoid.MaxHealth - Humanoid.Health)
	end

	if DamageValue > 0 then
		DebounceArray[Player] = true

		task.delay(0.1, function()
			DebounceArray[Player] = nil
		end)
	end

	Humanoid:TakeDamage(DamageValue)

	if Humanoid.Health > Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth
	end
end

TowersNamespace.packets.DamageEvent.listen(function(Data: string | number, Player: Player?)
	if not Player then
		return
	end

	HandleDamage(Player, Data)
end)

--------------------------------------------------------------------------------

function GetClientObjects(Player: Player)
	local Tower = Player:GetAttribute("CurrentTower") or ""

	if Tower == "" then
		return nil
	end

	local ClientObjectsFolder = ServerStorage.ClientObjects:FindFirstChild(Tower)

	if not ClientObjectsFolder then
		return nil
	end

	local PointerTemplate = Instance.new("ObjectValue")
	PointerTemplate:AddTag("OBJ_POINTER")

	local PointerContainer = ReplicatedStorage:FindFirstChild("__POINTER_STORAGE") or Instance.new("Folder")
	PointerContainer.Name = "__POINTER_STORAGE"
	PointerContainer.Parent = ReplicatedStorage

	local PointerLinkContainer = ReplicatedStorage:FindFirstChild("__POINTER_LINK_STORAGE") or Instance.new("Folder")
	PointerLinkContainer.Name = "__POINTER_LINK_STORAGE"
	PointerLinkContainer.Parent = ReplicatedStorage

	local DescendantCount = 0
	local PartCount = 0

	for _, Descendant in pairs(ClientObjectsFolder:GetDescendants()) do
		DescendantCount += 1

		if Descendant:IsA("ModuleScript") then
			local PointerLink = PointerTemplate:Clone()
			PointerLink.Value = Descendant.Parent
			PointerLink.Name = Descendant.Parent.Name
			PointerLink.Parent = PointerLinkContainer

			local ThisPointer = PointerTemplate:Clone()
			ThisPointer.Value = Descendant
			ThisPointer.Name = Descendant.Name
			ThisPointer.Parent = Descendant.Parent

			Descendant.Name = PointerLink.Name
		elseif Descendant:IsA("BasePart") then
			PartCount += 1

			if Descendant.CollisionGroup == "Default" and not Descendant:FindFirstAncestor("LightingChangers") then
				Descendant.CollisionGroup = "ClientObjects"
			end

			if
				Descendant.Name == "LightingChanger"
				or Descendant:FindFirstChild("invisible")
				or Descendant:FindFirstChild("Invisible")
			then
				Descendant:AddTag("Invisible")

				if Descendant:FindFirstChild("invisible") then
					Descendant.invisible:Destroy()
				end

				if Descendant:FindFirstChild("Invisible") then
					Descendant.Invisible:Destroy()
				end
			end
		elseif Descendant:IsA("NoCollisionConstraint") and Descendant:FindFirstAncestorOfClass("BasePart") then
			Descendant:FindFirstAncestorOfClass("BasePart").CollisionGroup = "ClientObjects"
			Descendant:FindFirstAncestorOfClass("BasePart").CanCollide = false

			Descendant:Destroy()
		end
	end

	ReplicatedStorage.KitSettings:SetAttribute("COPartCount", PartCount)
	ReplicatedStorage.KitSettings:SetAttribute("COInstanceCount", DescendantCount)

	return ClientObjectsFolder
end

local Clones = {} :: { [Player]: Instance? }

TowersNamespace.packets.RequestCOFolder.listen(function(Request: string, Player: Player?)
	if not Player then
		return
	end

	if Request == "Replicate" then
		local ClientObjectsFolder = GetClientObjects(Player)

		if not ClientObjectsFolder then
			return
		end

		local PlayerGui = Player:WaitForChild("PlayerGui")
		local ClonedFolder = ClientObjectsFolder:Clone()

		ClonedFolder:AddTag("ClientObjects")
		ClonedFolder.Parent = PlayerGui

		Clones[Player] = ClonedFolder
	elseif Request == "Cleanup" then
		local Clone = Clones[Player]

		if Clone then
			Clone:Destroy()
		end

		Clones[Player] = nil
	end
end)

--------------------------------------------------------------------------------

function TeleportToWinroom(Player: Types.PlayerInfo, WinroomMarker: string)
	Player.Player.Team = Teams.Winners
	Player.Player:SetAttribute("CurrentTower", "")

	ResetPlayerInfo(Player)

	local WinroomPart: Instance?

	if WinroomMarker ~= "" then
		WinroomPart = Markers:FindFirstChild(WinroomMarker, true)
	else
		WinroomPart = Markers:FindFirstChild("WinroomSpawn", true)
	end

	if WinroomPart and WinroomPart:IsA("BasePart") then
		local Character = Player.Player.Character or Player.Player.CharacterAdded:Wait()

		Character:PivotTo(WinroomPart.CFrame)
	end
end

function WinAnnouncement(Player: Player, PlayerTime: number, Tower: Folder | nil, TowerRush: Types.TowerRush | nil)
	if Tower then
		local Difficulty = FindValue(Tower, "Difficulty") or "Easy"
		local DifficultyEmojiID = InternalConfig.Webhooks.Difficulties[Difficulty]
		local TowerName = FindValue(Tower, "ProperName") or Tower.Name
		local ConvertedTime = ConvertTime(PlayerTime)

		local Message = RunService:IsStudio() and InternalConfig.Webhooks.Testing.Message
			or InternalConfig.Webhooks.Message
		local URL = RunService:IsStudio() and InternalConfig.Webhooks.Testing.Normal or InternalConfig.Webhooks.Normal
		local Timestamp = WebhookUtils:GetTimestamp("f")

		Message = string.gsub(Message, "{DisplayName}", Player.DisplayName)
		Message = string.gsub(Message, "{Username}", Player.Name)
		Message = string.gsub(Message, "{TowerName}", TowerName)
		Message = string.gsub(Message, "{Difficulty}", Difficulty)
		Message = string.gsub(Message, "{DifficultyEmoji}", string.format("<:%s:%s>", Difficulty, DifficultyEmojiID))
		Message = string.gsub(Message, "{Time}", ConvertedTime)
		Message = string.gsub(Message, "{Timestamp}", Timestamp)

		WebhookUtils:Post({
			Message = Message,
			URL = URL,
		})

		local WinMessage = InternalConfig.WinMessage
		local DifficultyColour = ParseColour(InternalConfig.Webhooks.DifficultyColours[Difficulty])

		WinMessage = string.gsub(WinMessage, "{DisplayName}", Player.DisplayName)
		WinMessage = string.gsub(WinMessage, "{Username}", Player.Name)
		WinMessage = string.gsub(WinMessage, "{TowerName}", TowerName)
		WinMessage = string.gsub(WinMessage, "{Difficulty}", Difficulty)
		WinMessage = string.gsub(WinMessage, "{Time}", ConvertedTime)
		WinMessage = string.format(`<font color="%s">%s</font>`, DifficultyColour, WinMessage)

		AnnouncementsNamespace.packets.WinAnnouncement.sendToAll({
			Text = WinMessage,
			Colour = Color3.fromRGB(255, 255, 255),
		})
	elseif TowerRush then
		local Difficulty = TowerRush.Difficulty or "Easy"
		local DifficultyEmojiID = InternalConfig.Webhooks.Difficulties[Difficulty]
		local TowerName = TowerRush.Title
		local ConvertedTime = ConvertTime(PlayerTime)

		local Message = RunService:IsStudio() and InternalConfig.Webhooks.Testing.Message
			or InternalConfig.Webhooks.Message
		local URL = RunService:IsStudio() and InternalConfig.Webhooks.Testing.Normal or InternalConfig.Webhooks.Normal
		local Timestamp = WebhookUtils:GetTimestamp("f")

		Message = string.gsub(Message, "{DisplayName}", Player.DisplayName)
		Message = string.gsub(Message, "{Username}", Player.Name)
		Message = string.gsub(Message, "{TowerName}", TowerName)
		Message = string.gsub(Message, "{Difficulty}", Difficulty)
		Message = string.gsub(Message, "{DifficultyEmoji}", string.format("<:%s:%s>", Difficulty, DifficultyEmojiID))
		Message = string.gsub(Message, "{Time}", ConvertedTime)
		Message = string.gsub(Message, "{Timestamp}", Timestamp)

		WebhookUtils:Post({
			Message = Message,
			URL = URL,
		})

		local WinMessage = InternalConfig.WinMessage
		local DifficultyColour = ParseColour(InternalConfig.Webhooks.DifficultyColours[Difficulty])

		WinMessage = string.gsub(WinMessage, "{DisplayName}", Player.DisplayName)
		WinMessage = string.gsub(WinMessage, "{Username}", Player.Name)
		WinMessage = string.gsub(WinMessage, "{TowerName}", TowerName)
		WinMessage = string.gsub(WinMessage, "{Difficulty}", Difficulty)
		WinMessage = string.gsub(WinMessage, "{Time}", ConvertedTime)
		WinMessage = string.format(`<font color="%s">%s</font>`, DifficultyColour, WinMessage)

		AnnouncementsNamespace.packets.WinAnnouncement.sendToAll({
			Text = WinMessage,
			Colour = Color3.fromRGB(255, 255, 255),
		})
	end
end

function PlayerLoadTower(Player: Types.PlayerInfo, TowerName: string, ResetTimer: boolean)
	if not Player.Player or Player.Player:GetAttribute("LoadingTower") then
		return
	end

	Player.Player:SetAttribute("CurrentTower", "")
	Player.Player:SetAttribute("CurrentTower", TowerName)

	if ResetTimer then
		Timers[Player.Player.UserId] = 0
	end
end

function OnPlayerWin(
	Player: Types.PlayerInfo,
	PlayerTime: number,
	Tower: Folder | nil,
	TowerRush: Types.TowerRush | nil
)
	WinAnnouncement(Player.Player, PlayerTime, Tower, TowerRush)

	Player.Player:SetAttribute("CurrentTower", "")
	Player.Player:LoadCharacter()
end

function PlayerLoadTowerRush(Player: Types.PlayerInfo, TowerRushName: string)
	if not Player.Player or Player.Player:GetAttribute("LoadingTower") then
		return
	end

	local TowerRush = TowerRushes[TowerRushName]

	if TowerRush then
		Player.CurrentTowerRush = TowerRushName
		Player.CurrentTowerRushIndex = 1

		local FirstTower = TowerRush.Towers[1]
		local TowerCount = #TowerRush.Towers

		local SentData = {
			CurrentTower = 1,
			TowerCount = TowerCount,
			PlayerID = tostring(Player.Player.UserId),
		}

		TimerNamespace.packets.UpdateTowerRush.sendToAll(SentData)
		PlayerLoadTower(Player, FirstTower, true)
	end
end

function AdvanceTowerRush(PlayerName: string)
	local Player: Types.PlayerInfo? = Players[PlayerName]

	if Player then
		local TowerRush: Types.TowerRush? = TowerRushes[Player.CurrentTowerRush]

		if TowerRush then
			local TowerCount: number = #TowerRush.Towers
			local CurrentTowerRushIndex = Player.CurrentTowerRushIndex

			if CurrentTowerRushIndex >= TowerCount then
				local PlayerTime = Timers[Player.Player.UserId] or 0
				Timers[Player.Player.UserId] = nil

				OnPlayerWin(Player, PlayerTime, nil, TowerRush)
				TeleportToWinroom(Player, TowerRush.WinroomMarker)
			else
				Player.CurrentTowerRushIndex += 1

				local TowerName: string = TowerRush.Towers[Player.CurrentTowerRushIndex]
				local SentData = {
					CurrentTower = tostring(Player.CurrentTowerRushIndex),
					TowerCount = tostring(TowerCount),
					PlayerID = tostring(Player.Player.UserId),
				}

				TimerNamespace.packets.UpdateTowerRush.sendToAll(SentData)
				PlayerLoadTower(Player, TowerName, false)
			end
		end
	end
end

--------------------------------------------------------------------------------

local WINPAD_DEBOUNCE = 0.5
local PORTAL_DEBOUNCE = 0.5

function PlayerTouchedWinpad(Winpad: BasePart, Player: Types.PlayerInfo, EndingID: string)
	local TowerName = FindValue(Winpad, "TowerName")
	local Tower = Towers:FindFirstChild(TowerName)

	if Player.Player:GetAttribute("TowersLocked") then
		return
	end

	if Player.Player:GetAttribute("CurrentTower") ~= TowerName or Player.Player:GetAttribute("CurrentTower") == "" then
		return
	end

	if Player.CurrentTowerRush == "" then
		local TowerInfo: Types.TowerInfo = InitiatedTowers[TowerName]
		local Ending: Types.EndingInfo = TowerInfo.Endings[EndingID]

		local PlayerTime = Timers[Player.Player.UserId] or 0
		local EndingWinroom: string = ""

		if EndingID ~= TowerName then
			EndingWinroom = Ending.WinroomMarker
		end

		local SentData = {
			CurrentTower = 0,
			TowerCount = 0,
			PlayerID = tostring(Player.Player.UserId),
		}

		Timers[Player.Player.UserId] = nil
		TimerNamespace.packets.UpdateTowerRush.sendToAll(SentData)

		OnPlayerWin(Player, PlayerTime, Tower)
		TeleportToWinroom(Player, EndingWinroom)
	else
		AdvanceTowerRush(Player.Player.Name)
	end
end

function InitWinpad(TowerName: string, Winpad: BasePart)
	if not Winpad then
		return
	end

	if TowerName == nil or not Towers:FindFirstChild(TowerName) then
		return
	end

	local Particles: ParticleEmitter = WinpadParticles:Clone()
	Particles.Parent = Winpad

	local EndingID: string = FindValue(Winpad, "EndingID") or ""

	if EndingID == "" then
		Winpad:SetAttribute("EndingID", TowerName)
		EndingID = TowerName
	end

	local ParentTower: string = FindValue(Winpad, "ParentTower") or ""

	if ParentTower == "" then
		if TowerName == "" then
			error(
				'Could not setup winpad "'
					.. Winpad:GetFullName()
					.. " because it's parent tower is undefined (and could not be implicitly figured out)"
			)
		end

		Winpad:SetAttribute("ParentTower", TowerName)
	end

	local Tower: Types.TowerInfo? = InitiatedTowers[TowerName]

	if Tower then
		local Ending: Types.EndingInfo = {
			Name = FindValue(Winpad, "EndingName") or Tower.Name,
			Difficulty = FindValue(Winpad, "Difficulty") or Tower.Difficulty,

			BadgeID = FindValue(Winpad, "BadgeID") or 0,
			PreventTowerBadge = FindValue(Winpad, "PreventTowerBadge") or false,

			ParentTower = TowerName,
			WinroomMarker = (FindValue(Winpad, "WinroomMarker") or FindValue(Winpad, "Winroom") or ""),
		}

		Tower.Endings[EndingID] = Ending

		local function Touch(Hit: BasePart)
			local IsPlayer, PlayerName = IsPlayerPart(Hit)
			local Player: Types.PlayerInfo = Players[PlayerName]

			if IsPlayer and not Player.TouchEventBusy then
				if Winpad:GetAttribute("Debounce") then
					return
				end

				Winpad:SetAttribute("Debounce", true)
				PlayerTouchedWinpad(Winpad, Player, EndingID)

				task.delay(WINPAD_DEBOUNCE, function()
					Winpad:SetAttribute("Debounce", false)
				end)
			end
		end

		Winpad.Touched:Connect(Touch)
	else
		error('Could not setup winpad "' .. Winpad:GetFullName() .. " because it's parent tower does not exist")
	end

	table.insert(Winpads, Winpad)
end

function InitPortal(Portal: BasePart)
	if not Portal then
		return
	end

	local TowerName = FindValue(Portal, "TowerName")
	local TowerRush = FindValue(Portal, "TowerRush")

	Portal:SetAttribute("Debounce", false)

	Portal.Touched:Connect(function(Hit)
		if Portal:GetAttribute("Debounce") then
			return
		end

		if not Hit then
			return
		end
		if not Hit.Parent or not Hit.Parent:FindFirstChildOfClass("Humanoid") then
			return
		end

		local Character = Hit.Parent
		local Player = PlayersService:GetPlayerFromCharacter(Hit.Parent)

		if not Character or not Player then
			return
		end

		if Player:GetAttribute("CurrentTower") ~= "" or Player:GetAttribute("TowersLocked") then
			return
		end

		Portal:SetAttribute("Debounce", true)

		if TowerName then
			PlayerLoadTower(Players[Player.Name], TowerName, true)
		elseif TowerRush then
			PlayerLoadTowerRush(Players[Player.Name], TowerRush)
		end

		task.delay(PORTAL_DEBOUNCE, function()
			Portal:SetAttribute("Debounce", false)
		end)
	end)
end

function InitTower(TowerFolder: Folder)
	local ClientSidedObjects = TowerFolder:FindFirstChild("ClientSidedObjects")

	if TowerFolder:FindFirstChild("ClientSidedObjects") then
		local TowerLink = Instance.new("ObjectValue")
		TowerLink.Name = "TowerLink"
		TowerLink.Value = TowerFolder
		TowerLink.Parent = ClientSidedObjects

		ClientSidedObjects.Name = TowerFolder.Name
		ClientSidedObjects.Parent = ServerStorage.ClientObjects
	end

	local Acronym: string = TowerFolder.Name
	local SpawnLocation: Instance? = TowerFolder:FindFirstChild("SpawnLocation")

	if not (SpawnLocation and SpawnLocation:IsA("BasePart")) then
		error(Acronym .. " does not have a SpawnLocation!")
	end

	local ClientObjects: Instance? = (
		TowerFolder:FindFirstChild("ClientSidedObjects") or ServerStorage.ClientObjects:FindFirstChild(Acronym)
	)

	local CheckpointsFolder: Instance? = (
		TowerFolder:FindFirstChild("Checkpoints") or TowerCheckpointsFolder:FindFirstChild(Acronym)
	)

	if CheckpointsFolder and CheckpointsFolder.Parent ~= TowerCheckpointsFolder then
		CheckpointsFolder.Parent = TowerCheckpointsFolder
		CheckpointsFolder.Name = Acronym
	end

	local CheckpointsList = {} :: { BasePart }
	local CheckpointCount = 0

	if CheckpointsFolder then
		for CheckpointName, Checkpoint: Instance? in pairs(CheckpointsFolder:GetChildren()) do
			if Checkpoint then
				if Checkpoint:IsA("BasePart") then
					table.insert(CheckpointsList, Checkpoint)
				else
					error(Acronym .. ": Checkpoint " .. CheckpointName .. " is not a BasePart")
				end
			else
				error(Acronym .. ": Could not find checkpoint " .. CheckpointName)
			end

			CheckpointCount += 1
		end
	end

	local Tower: Types.TowerInfo = {
		Name = FindValue(TowerFolder, "ProperName") or Acronym,
		Difficulty = FindValue(TowerFolder, "Difficulty") or "default",
		BadgeID = FindValue(TowerFolder, "BadgeID") or 0,

		Folder = TowerFolder,
		SpawnLocation = SpawnLocation,
		ClientObjects = ClientObjects,

		Endings = {},

		MinimumTime = FindValue(TowerFolder, "MinimumTime") or 0,
		Checkpoints = CheckpointsList,
		CheckpointCount = CheckpointCount,
	}

	InitiatedTowers[Acronym] = Tower

	for k: number, v: Instance in TowerFolder:GetDescendants() do
		if v.Name == "WinPad" and v:IsA("BasePart") then
			InitWinpad(Acronym, v)
		end
	end

	return Tower
end

function InitMarker(Marker: BasePart)
	if Marker.Name == "LobbyTP" then
		local SpawnLocation: Instance = Markers:WaitForChild("SpawnLocation")

		if not (SpawnLocation and SpawnLocation:IsA("BasePart")) then
			error("Could not initialize LobbyTP because a SpawnLocation couldn't be found")
		end

		local function Touch(Hit: BasePart)
			local IsPlayer, PlayerName = IsPlayerPart(Hit)

			if IsPlayer then
				local Player = Players[PlayerName]

				Player.Player.Team = Teams.Start
				Player.Player.Character:PivotTo(SpawnLocation.CFrame)
			end
		end

		Marker.Touched:Connect(Touch)
	end
end

for _, Tower in pairs(Towers:GetChildren()) do
	if Tower:HasTag("Tower") then
		task.spawn(InitTower, Tower)
	end
end

for _, Portal in pairs(Portals:GetChildren()) do
	if Portal:IsA("BasePart") then
		task.spawn(InitPortal, Portal)
	end
end

for _, Marker in pairs(Markers:GetChildren()) do
	if Marker:IsA("BasePart") then
		task.spawn(InitMarker, Marker)
	end
end

TowersNamespace.packets.FinishedLoading.listen(function(_Data: nil, Player: Player?)
	if not Player then
		return
	end

	Player:SetAttribute("LoadingTower", false)
end)

RunService.Stepped:Connect(Step)

--------------------------------------------------------------------------------

function CharacterAdded(Character: Model)
	local Player = PlayersService:GetPlayerFromCharacter(Character)

	if Player then
		task.defer(function()
			if not KitSettings.ResetOnDeath and not Player:GetAttribute("LoadingTower") then
				ResetPlayerInfo(Players[Player.Name])
				Player:SetAttribute("CurrentTower", "")
			end
		end)
	end
end

function PlayerAdded(Player: Player)
	if Player.Character then
		task.spawn(CharacterAdded, Player.Character)
	end

	Player.CharacterAdded:Connect(CharacterAdded)
	Leaderstats.InitPlayer(Player)

	Player:SetAttribute("ForceRestarting", false)
	Player:SetAttribute("CurrentTower", "")
	Player:SetAttribute("LoadingTower", false)

	Player:GetAttributeChangedSignal("ForceRestarting"):Connect(function()
		if Player:GetAttribute("ForceRestarting") then
			Timers[Player.UserId] = 0
		end
	end)

	Player:GetAttributeChangedSignal("CurrentTower"):Connect(function()
		if
			not Player:GetAttribute("LoadingTower")
			and ServerStorage.ClientObjects:FindFirstChild(Player:GetAttribute("CurrentTower"))
		then
			if Player:GetAttribute("TowersLocked") then
				return
			end

			Player:SetAttribute("LoadingTower", true)
			Player:LoadCharacter()

			if Player.Character then
				if Player:GetAttribute("CurrentTower") ~= "" then
					local Tower = InitiatedTowers[Player:GetAttribute("CurrentTower")]
					local Forcefield = Player.Character:FindFirstChildOfClass("ForceField")

					Player.Character:PivotTo(Tower.SpawnLocation.CFrame)

					if Forcefield then
						Forcefield:Destroy()
					end
				end
			end

			Player.CharacterAdded:Once(function(Character)
				if Player:GetAttribute("CurrentTower") ~= "" then
					local Tower = InitiatedTowers[Player:GetAttribute("CurrentTower")]
					local Forcefield = Character:FindFirstChildOfClass("ForceField")
					
					Character:PivotTo(Tower.SpawnLocation.CFrame)

					if Forcefield then
						Forcefield:Destroy()
					end
				end
			end)
		end
	end)

	local Info: Types.PlayerInfo = {
		Player = Player,
		GameTimer = 0,
		LastRestart = 0,

		CurrentTowerRush = "",
		CurrentTowerRushIndex = 0,

		TouchEventBusy = false,
	}

	Players[Player.Name] = Info
	Player.Team = Teams.Start
end

function PlayerRemoving(Player: Player)
	if Timers[Player.UserId] then
		Timers[Player.UserId] = nil
	end

	Players[Player.Name] = nil
end

for _, Player in pairs(PlayersService:GetPlayers()) do
	task.spawn(PlayerAdded, Player)
end

PlayersService.PlayerAdded:Connect(PlayerAdded)
PlayersService.PlayerRemoving:Connect(PlayerRemoving)

if KitSettings.StartupTime then
	print(`BetterV6 Server has finished loading in {string.format("%1f", tick() - StartTime)} seconds.`)
end
