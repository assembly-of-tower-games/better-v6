export type List<T> = { [number]: T }
export type Dictionary<T> = { [string]: T }

export type EndingInfo = {
	Name: string,
	Difficulty: string,
    
	BadgeID: number,
	PreventTowerBadge: boolean,
    
	ParentTower: string,
	WinroomMarker: string,
}

export type TowerInfo = {
	Name: string,
	Difficulty: string,
	BadgeID: number,
    
	Folder: Instance,
	SpawnLocation: BasePart,
	ClientObjects: Instance?,
    
	Endings: Dictionary<EndingInfo>,
    
	MinimumTime: number,
	Checkpoints: List<BasePart>,
	CheckpointCount: number,
}

export type PlayerInfo = {
	Player: Player,
    GameTimer: number,
	LastRestart: number,
    
	CurrentTowerRush: string,
	CurrentTowerRushIndex: number,
    
	TouchEventBusy: boolean,
}

export type TowerRush = {
	BadgeID: number,
	Title: string,
	Difficulty: string,
	WinroomMarker: string,
	Towers: List<string>,
}

return nil