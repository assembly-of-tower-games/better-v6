export type Thread = {
	link: ModuleScript,
	
	init: () -> (),
	run: () -> (),
	cleanup: () -> ()
}

return {}