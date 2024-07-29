package game

SmoothValue :: struct($BufferSize : int) {
	value 	: f32,
	buffer 	: [BufferSize]f32,
	index 	: int,
}

smooth_value_put :: proc(sv : ^SmoothValue($S), value : f32) {
	sv.value 			-= sv.buffer[sv.index] / (f32(len(sv.buffer)))
	sv.buffer[sv.index] = value
	sv.value 			+= sv.buffer[sv.index] / (f32(len(sv.buffer)))

	sv.index = (sv.index + 1) % len(sv.buffer)
}

///////////////////////////////////////////////////////////////////////////////
// Maybe move to debug

DebugValue :: struct {
	label : string,
	value : union { int, f32, bool, vec3 }
}
debug_values : [dynamic] DebugValue

put_debug_value_f32 :: proc(label : string, value : f32) {
	append(&debug_values, DebugValue{label, value})
}

put_debug_value_int :: proc(label : string, value : int) {
	append(&debug_values, DebugValue{label, value})
}

put_debug_value_bool :: proc(label : string, value : bool) {
	append(&debug_values, DebugValue{label, value})
}

put_debug_value_vec3 :: proc(label : string, value : vec3) {
	append(&debug_values, DebugValue{label, value})
}

put_debug_value :: proc {
	put_debug_value_int,
	put_debug_value_f32,
	put_debug_value_bool,
	put_debug_value_vec3,
}

clear_debug_values :: proc() {
	debug_values = make([dynamic]DebugValue, 0, 20, context.temp_allocator)
}

///////////////////////////////////////////////////////////////////////////////