package game

SmoothValue :: struct {
	value 	: f32,
	buffer 	: [30]f32,
	index 	: int,
}

smooth_value_put :: proc(sv : ^SmoothValue, value : f32) {
	sv.value 			-= sv.buffer[sv.index] / (f32(len(sv.buffer)))
	sv.buffer[sv.index] = value
	sv.value 			+= sv.buffer[sv.index] / (f32(len(sv.buffer)))

	sv.index = (sv.index + 1) % len(sv.buffer)
}
