local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Libs"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("Towers", function()
	return {
		packets = {
			DamageEvent = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.int8
			}),
			DamageEventS = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.string
			}),
			
			RequestCOFolder = ByteNet.definePacket({
				value = ByteNet.string
			}),

			FinishedLoading = ByteNet.definePacket({
				value = ByteNet.nothing
			})
		},
	}
end)