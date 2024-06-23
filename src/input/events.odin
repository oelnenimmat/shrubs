package input

events : struct {
	application : struct {
		exit : bool,
	},
}

reset_events :: proc() {
	events = {}
}