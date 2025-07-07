--!nocheck

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal =
	require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Signal"))
local ProfileStore =
	require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ProfileStore"))

local StorageUtils = {}
local TEMPLATE = {}

local Store
local Profiles

StorageUtils.ProfileLoaded = Signal.new()
StorageUtils.ProfileEnded = Signal.new()

function PlayerAdded(Player: Player)
	if Store then
		local Profile = Store:StartSessionAsync("Player_" .. Player.UserId, {
			Cancel = function()
				return Player.Parent ~= Players
			end,
		})

		if Profile ~= nil then
			Profile:AddUserId(Player.UserId)
			Profile:Reconcile()

			Profile.OnSessionEnd:Connect(function()
				StorageUtils.ProfileEnded:Fire(Player)

				task.delay(1, function()
					Profiles[Player] = nil

					Player:Kick(`Profile session end - Please rejoin`)
				end)
			end)

			if Player.Parent == Players then
				Profiles[Player] = Profile
				print(`Profile loaded for {Player.Name}!`)

				task.delay(1, function()
					StorageUtils.ProfileLoaded:Fire(Player)
				end)
			else
				Profiles[Player] = Profile:EndSession()
			end
		else
			Player:Kick(`Profile load fail - Please rejoin`)
		end
	end
end

function GetProfile(Player: Player)
	assert(Profiles[Player], string.format("Profile does not exist for %s", Player.Name))

	return Profiles[Player]
end

function StorageUtils.init()
	Store = ProfileStore.New("PlayerProfile", TEMPLATE)
	Profiles = {} :: { [Player]: typeof(Store:StartSessionAsync()) }

	for _, Player in pairs(Players:GetPlayers()) do
		task.spawn(PlayerAdded, Player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(function(Player: Player)
		local Profile = Profiles[Player]

		if Profile ~= nil then
			Profile:EndSession()
		end
	end)
end

function StorageUtils:Get(Player: Player, Key: any)
	local Profile = GetProfile(Player)

	assert(Profile, string.format("Profile does not exist for %s", Player.Name))
	assert(Profile.Data[Key], string.format("Data does not exist for key %s", Key))

	return Profile.Data[Key]
end

function StorageUtils:Set(Player: Player, Key: any, Value: any)
	local Profile = GetProfile(Player)

	assert(Profile, string.format("Profile does not exist for %s", Player.Name))
	assert(Profile.Data[Key], string.format("Data does not exist for key %s", Key))

	assert(
		type(Profile.Data[Key]) == type(Value),
		string.format("Type of data (%s) is different from value (%s)", type(Profile.Data[Key]), type(Value))
	)

	Profile.Data[Key] = Value
end

function StorageUtils:Update(Player: Player, Key: any, Callback: (any) -> ())
	local OldData = StorageUtils:Get(Player, Key)
	local NewData = Callback(OldData)

	StorageUtils:Set(Player, Key, NewData)
end

return StorageUtils
