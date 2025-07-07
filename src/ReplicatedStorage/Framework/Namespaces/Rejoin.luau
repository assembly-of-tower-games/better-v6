local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ByteNet"))

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