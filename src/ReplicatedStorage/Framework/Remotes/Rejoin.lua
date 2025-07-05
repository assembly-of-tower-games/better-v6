local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Libs"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("Rejoin", function()
	return {
		packets = {
			Rejoin = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.nothing
			})
		}
	}
end)