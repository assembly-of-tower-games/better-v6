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
			RespondCOFolder = ByteNet.definePacket({
				value = ByteNet.struct({
					objects = ByteNet.optional(ByteNet.inst),

					warnings = ByteNet.array(ByteNet.struct({
						text = ByteNet.string,
						type = ByteNet.string
					}))
				})
			})
		},
	}
end)