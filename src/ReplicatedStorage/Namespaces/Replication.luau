local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("Replication", function()
	return {
		packets = {
			SendServer = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.struct({
					Position = ByteNet.array(ByteNet.float32),
					Rotation = ByteNet.array(ByteNet.uint16),
				}),
			}),
            
			SendClient = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.struct({
					PlayerID = ByteNet.string,
					Position = ByteNet.array(ByteNet.float32),
					Rotation = ByteNet.array(ByteNet.uint16),
				}),
			}),
		},
	}
end)
