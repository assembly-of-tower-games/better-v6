local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("Announcements", function()
	return {
		packets = {
			WinAnnouncement = ByteNet.definePacket({
                value = ByteNet.struct({
                    Text = ByteNet.string,
                    Colour = ByteNet.color3
                })
            }),

            AdminAnnouncement = ByteNet.definePacket({
                value = ByteNet.struct({
                    Message = ByteNet.string,
                    PlayerName = ByteNet.playerName
                })
            })
		}
	}
end)