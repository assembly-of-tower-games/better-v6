return {
	-- Kit behavior
	ResetOnDeath = false,
	DisplaySettingsGui = true,

	-- Debug Config
	DisplayDebugGuis = false,
	DisplayMemoryDebug = false,

	-- Discord Webhooks
	Webhooks = {
		Message = "{DisplayName} *(@{Username})* beat {TowerName} ({Difficulty} in {Time}!",

		Normal = "https://webhook.lewisakura.moe/api/webhooks/1244358093467553975/iw8FAEZYqU0Ps90lhHGcEIcAt0F3kJPl4I59uF-LbSbidVkkinBqIU-cHRU1q7MKZHHE",
		SC = "https://webhook.lewisakura.moe/api/webhooks/1246041571556593676/2Q0SPJLMvkHC_shZ5ALM6g1YfV1E8Yhl4U8_Glt68LrmS09pBve0LYy5qqNJPjiGm6a5",

		Testing = {
			Message = "[TESTING] {DisplayName} *(@{Username})* beat {TowerName} ({Difficulty}) in {Time}!",

			Normal = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l",
			SC = "https://webhook.lewisakura.moe/api/webhooks/1373715043581034616/XP-Jdk7uIX5S9e0eKoZspF0El4UZS8bo-h1fLJ-gOMsq7VO6YKnQpcAgda3d4xmRqQ-l"
		}
	}
}
