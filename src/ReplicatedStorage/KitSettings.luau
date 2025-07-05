return {
	-- Kit behavior
	ResetOnDeath = false,
	DisplaySettingsGui = true,

	-- Debug Config
	DisplayDebugGuis = false,
	DisplayMemoryDebug = false,

	-- Discord Webhooks
	Webhooks = {
		Message = "{DisplayName} *(@{Username})* beat **{TowerName}** [{DifficultyEmoji}] in `{Time}`!",

		Normal = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",
		SC = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",

		Testing = {
			Message = "[TESTING] {DisplayName} *(@{Username})* beat **{TowerName}** [{DifficultyEmoji}] in `{Time}`!",

			Normal = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",
			SC = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l"
		},

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
			Unreal = ""
		}
	}
}
