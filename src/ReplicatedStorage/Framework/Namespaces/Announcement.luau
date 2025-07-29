local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("Announcement", function()
	return {
		packets = {
			WinAnnouncement = ByteNet.definePacket({
                value = ByteNet.struct({
                    Text = ByteNet.string,
                    Colour = ByteNet.color3
                })
            })
		}
	}
end)