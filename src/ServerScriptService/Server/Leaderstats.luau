type PlayerInfo = {
	Player: Player,
	leaderstats: Folder,

    RealTime: number,
	Time: NumberValue,
}

local Module = {}
local Players: { [string]: PlayerInfo } = {}

function Module.InitPlayer(Player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = Player

	local Time = Instance.new("NumberValue")
	Time.Name = "Time"
	Time.Parent = leaderstats

	local Info: PlayerInfo = {
		Player = Player,
		leaderstats = leaderstats,

        RealTime = 0,
		Time = Time,
	}

	Players[Player.Name] = Info
end

function Module.Step(DeltaTime: number)
    print(DeltaTime)

	for _, Info in pairs(Players) do 
        Info.RealTime += DeltaTime
        Info.Time.Value = math.floor(Info.RealTime)
	end
end

return Module