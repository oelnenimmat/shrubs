package graphics

Buffer :: struct {}
create_buffer :: proc(data_size : int, needs_to_be_writeable := false) -> Buffer {	
	return {}
}
destroy_buffer :: proc(b : ^Buffer) {}
buffer_write_data :: proc(b : ^Buffer, data : []$DataType) {}
