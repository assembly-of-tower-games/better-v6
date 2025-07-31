return {
	-- Misc
	-- Controls how many towers can be in a tower rush at once. This cannot go above 2^32 (~4 billion towers) or below 2^8 (256 towers).
	TowerRushMaximum = 2^8,
	
	-- Win Messages
	-- Controls the win message displayed in chat.
	WinMessage = "{DisplayName} <i>(@{Username})</i> beat <b>{TowerName} [{Difficulty}]</b> in {Time}!",

	-- Discord Webhooks
	Webhooks = {
		-- Controls the normal win message for the Discord webhooks.
		Message = "{DisplayName} *(@{Username})* beat **{TowerName} [{DifficultyEmoji}]** in `{Time}` at {Timestamp}!",

		-- Controls the webhook URLs.
		Normal = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",
		SC = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",

		-- Used for Studio testing. If Enabled is false, it will default to the normal message and the Normal/SC webhook urls.
		Testing = {
			Enabled = false,
			Message = "[TESTING] {DisplayName} *(@{Username})* beat **{TowerName} [{DifficultyEmoji}]** in `{Time}` at {Timestamp}!",

			Normal = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",
			SC = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",
		},

		-- List of Difficulty emoji IDs.
		Difficulties = {
			Easy = "1297256622019711056",
			Medium = "1297256645482512465",
			Hard = "1297256668220100638",
			Difficult = "1297256685693571127",
			Challenging = "1297256698494582944",
			Intense = "1297256710150291456",
			Remorseless = "1297256727531622422",
			Insane = "1297256741842587659",
			Extreme = "1297256758263283764",
			Terrifying = "1297256774310690896",
			Catastrophic = "1297256788009291777",
			Horrific = "",
			Unreal = "",
		},

		-- List of Difficulty colour IDs, used for the chat win message.
		DifficultyColours = {
			Easy = Color3.fromRGB(117, 243, 71),
			Medium = Color3.fromRGB(255, 254, 0),
			Hard = Color3.fromRGB(253, 124, 0),
			Difficult = Color3.fromRGB(255, 50, 50),
			Challenging = Color3.fromRGB(160, 0, 0),
			Intense = Color3.fromRGB(25, 35, 45),
			Remorseless = Color3.fromRGB(200, 0, 200),
			Insane = Color3.fromRGB(0, 0, 255),
			Extreme = Color3.fromRGB(3, 137, 255),
			Terrifying = Color3.fromRGB(0, 255, 255),
			Catastrophic = Color3.fromRGB(255, 255, 255),
			Horrific = Color3.fromRGB(150, 149, 255),
			Unreal = Color3.fromRGB(81, 0, 23),
		},
	},
}
