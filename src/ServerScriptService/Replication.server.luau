local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicationNamespace = require(ReplicatedStorage.Namespaces.Replication)

ReplicationNamespace.packets.SendServer.listen(
	function(Data: { Position: { number }, Rotation: { number } }, Player: Player?)
        if not Player then 
            return
        end

		ReplicationNamespace.packets.SendClient.sendToAll({
			PlayerID = tostring(Player.UserId),
			Position = Data.Position,
			Rotation = Data.Rotation,
		})
	end
)