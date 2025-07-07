local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("Timer", function()
	return {
		packets = {
			CorrectTimer = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.float32,
			}),
		},
	}
end)
