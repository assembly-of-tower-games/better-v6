local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnnouncementsNamespace = require(ReplicatedStorage:WaitForChild("Namespaces"):WaitForChild("Announcements"))

return function (context, text)
	AnnouncementsNamespace.packets.AdminAnnouncement.sendToAll({
		Message = text,
		PlayerName = context.Executor.Name
	})

	return "Created announcement."
end