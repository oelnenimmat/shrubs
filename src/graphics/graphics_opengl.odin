////+private
package graphics

/*
Graphics interface implementation using OpenGL
*/

import "../window"

import "core:fmt"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:strings"

import gl "vendor:OpenGL"
import "vendor:glfw"
import mu "vendor:microui"

import "core:math/linalg"


/*
Some resources are used by both gpu and cpu each frame, and for these
we use a concept of virtual frame. All these frequently updated shared
resources are created multiple times, one per virtual frame and then
reused one after another, always returning to end of the queue. This is
implemented so that there is [VIRTUAL_FRAME_COUNT] sized array of each
reusable resource and one global index that is updated once per frame.
Failing to update SHOULD not lead to crash, but manifestation of some
artifacts in the resource.
*/
VIRTUAL_FRAME_COUNT :: 3

set_lighting :: proc(direction : vec3, color : vec3) {
	direction := direction
	color := color

	gc := &graphics_context

	// todo(Leo): use uniform buffer objects, or just go vulkan :)
	direction_location 	:= gl.GetUniformLocation(gc.shader_program, "light_direction")
	color_location 		:= gl.GetUniformLocation(gc.shader_program, "light_color")

	gl.UseProgram(gc.shader_program)
	gl.Uniform3fv(direction_location, 1, auto_cast &direction)
	gl.Uniform3fv(color_location, 1, auto_cast &color)
}

set_surface :: proc(color : vec3) {
	color := color 

	gc := &graphics_context

	color_location := gl.GetUniformLocation(gc.shader_program, "surface_color")

	gl.UseProgram(gc.shader_program)
	gl.Uniform3fv(color_location, 1, auto_cast &color)
}

//@private
graphics_context : struct {
	particle_vertex_buffer_object 	: u32,
	particle_index_buffer_object 	: u32,
	particle_index_count 			: i32,

	shader_program 	: u32,
	
	// instance_buffer : InstanceBuffer,

	view_matrix 		: mat4,
	projection_matrix 	: mat4,

	view_matrix_location 		: i32,
	projection_matrix_location 	: i32,
	model_matrix_location 		: i32,

	
	virtual_frame_index : int,
	virtual_frame_in_use_fences : [VIRTUAL_FRAME_COUNT]gl.sync_t,
}

// WHAT IS THIS ---------------------------------------------------------------

initialize :: proc() {

	window_width, window_height := window.get_window_size()

	// OpenGL headers contain a set of function pointers, that need to be loaded explicitly
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Enable(gl.DEPTH_TEST)

	// Note(Leo): my laptop cannot really handle this right now
	// gl.Enable(gl.MULTISAMPLE)

	gl.CullFace(gl.BACK)
	gl.Enable(gl.CULL_FACE)
	gl.FrontFace(gl.CCW)

	gl.Viewport(0, 0, i32(window_width), i32(window_height))

	test_shader_program := gl.CreateProgram()
	{
		// Compile time generated slices to program memory, no need to delete after.
		// Now we don't need to worry about shader files being present runtime.
		vertex_shader_source := #load("../shaders/basic.vert", string)
		frag_shader_source := #load("../shaders/basic.frag", string)

		vertex_shader := make_shader(vertex_shader_source, gl.VERTEX_SHADER)
		fragment_shader := make_shader(frag_shader_source, gl.FRAGMENT_SHADER)

		gl.AttachShader(test_shader_program, vertex_shader)
		gl.AttachShader(test_shader_program, fragment_shader)
		gl.LinkProgram(test_shader_program)

		success : i32
		gl.GetProgramiv(test_shader_program, gl.LINK_STATUS, &success)
		if success == 0 {
			info_log_buffer := make([]u8, 1024, context.temp_allocator)
			defer delete(info_log_buffer, context.temp_allocator)

			info_log_length : i32 = 0
			gl.GetProgramInfoLog(test_shader_program, cast(i32) len(info_log_buffer), &info_log_length, raw_data(info_log_buffer))
			fmt.printf("SHADER PROGRAM ERROR: %s\n", transmute(string)info_log_buffer[:info_log_length])	
		} else {
			fmt.println("Shader Program created succesfully")
		}
	
		gl.DeleteShader(vertex_shader)
		gl.DeleteShader(fragment_shader)
	}
	gl.UseProgram(test_shader_program)

	VERTICES :: PARTICLE_CUBE_VERTICES
	INDICES :: PARTICLE_CUBE_INDICES

	particle_vertex_buffer_object : u32
	particle_index_buffer_object : u32
	particle_index_count := i32(len(INDICES))

	// CREATE PARTICLE MESH
	{
		// VERTEX POSITIONS
		gl.GenBuffers(1, &particle_vertex_buffer_object)
		gl.BindBuffer(gl.ARRAY_BUFFER, particle_vertex_buffer_object)
		vertex_data_size := size_of(f32) * len(VERTICES)
		vertex_data := raw_data(VERTICES)
		gl.BufferData(gl.ARRAY_BUFFER, vertex_data_size, vertex_data, gl.STATIC_DRAW)

		// INDICES
		gl.GenBuffers(1, &particle_index_buffer_object)
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, particle_index_buffer_object)
		index_data_size := size_of(u16) * int(particle_index_count)
		index_data := raw_data(INDICES)
		gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, index_data_size, index_data, gl.STATIC_DRAW)
	}

	gc := &graphics_context
	gc^ = {}

	gc.particle_vertex_buffer_object 	= particle_vertex_buffer_object
	gc.particle_index_buffer_object 	= particle_index_buffer_object
	gc.shader_program 					= test_shader_program
	gc.particle_index_count 			= particle_index_count

	gc.view_matrix_location 		= gl.GetUniformLocation(test_shader_program, "view")
	gc.projection_matrix_location 	= gl.GetUniformLocation(test_shader_program, "projection")
	gc.model_matrix_location 		= gl.GetUniformLocation(test_shader_program, "model")

	// Todo(Leo): there might be issue here that this could be called before
	// setting up the opengl stuff and then something going haywire, seems to work now
	glfw_resize_framebuffer_proc :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
		resize_framebuffer(int(width), int(height))
	}
	glfw.SetFramebufferSizeCallback(window.get_glfw_window_handle(), glfw_resize_framebuffer_proc)
}

terminate :: proc() {
	// Any resources deallocation that NEED to be done on ending the program,
	// can be done here.

	// So far no need to do anything, many things are claimed automatically
	// by os on termination
	fmt.println("OpenGL terminated (no work done)")
}

draw_instance_buffer :: proc(ib : ^InstanceBuffer) {
	using graphics_context
	gl.UseProgram(shader_program)

	gl.UniformMatrix4fv(view_matrix_location, 1, false, transmute([^]f32)&view_matrix)
	gl.UniformMatrix4fv(projection_matrix_location, 1, false, transmute([^]f32)&projection_matrix)

	gl.BindVertexArray(ib.vertex_arrays[virtual_frame_index])

	gl.DrawElementsInstanced(
		gl.TRIANGLES, 
		particle_index_count, 
		gl.UNSIGNED_SHORT, 
		nil, 
		ib.count,
	)

	//gui.draw_rectangle()
}

render :: proc() {
	gc := &graphics_context


	// Todo(Leo): learn more if this is necessary or not. Also if it matters
	// if this is before or after fence sync. https://stackoverflow.com/questions/2143240/opengl-glflush-vs-glfinish
	// Moves all sent commands to execution
	gl.Flush()

	// After all draw commands, get a fence at this point
	fence := gl.FenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0)
	gc.virtual_frame_in_use_fences[gc.virtual_frame_index] = fence
}

begin_frame :: proc() {
	gc := &graphics_context

	// Pick up new virtual frame, the one that was used least recently
	gc.virtual_frame_index += 1
	gc.virtual_frame_index %= VIRTUAL_FRAME_COUNT

	// start by waiting to make sure that that frame's resources are no
	// longer in use by GPU
	fence := gc.virtual_frame_in_use_fences[gc.virtual_frame_index]
	gl.ClientWaitSync(fence, 0, max(u64))

	// gl.ClearColor(0.1, 0.15, 0.2, 1.0)
	// gl.ClearColor(0.43, 0.49, 0.58, 1.0)
	// gl.ClearColor(0.37, 0.41, 0.47, 1.0)
	// gl.ClearColor(0.27, 0.31, 0.37, 1.0)
	// gl.ClearColor(0.17, 0.20, 0.23, 1.0)
	gl.ClearColor(0.07, 0.10, 0.13, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	// Todo(Leo): learn more if this is necessary or not. Also if it matters
	// if this is before or after fence sync. https://stackoverflow.com/questions/2143240/opengl-glflush-vs-glfinish
	// Moves all sent commands to execution
	gl.Flush()
}

// PLATFORM INTERNAL USAGE ----------------------------------------------------

@private
resize_framebuffer :: proc "c" (width, height: int) {
	// Note(leo): need context for assert and printf
	context = runtime.default_context()

	// Note(Leo): There should never be a reason to set window/framebuffer even close
	// to max(i32)
	assert(width < int(max(i32)))
	assert(height < int(max(i32)))

	width := i32(width)
	height := i32(height)

	fmt.printf("OpenGL framebuffer resized (%i, %i)\n", width, height)

	gl.Viewport(0, 0, width, height)
}

// OPENGL IMPLEMENTATION FOR THE GRAPHICS API ---------------------------------

set_view_projection :: proc(view_matrix: mat4, projection_matrix: mat4) {
	gc := &graphics_context
	gc.view_matrix 			= view_matrix
	gc.projection_matrix 	= projection_matrix
}

create_instance_buffer :: proc(instance_count: int) -> InstanceBuffer{
	// gc := &graphics_context

	ib := create_instance_buffer_internal(instance_count)
	// gc.instance_buffer = ib 
	return ib
}

get_instance_buffer_writeable_memory :: proc(ib : ^InstanceBuffer) -> rawptr {
	// ib_internal := &graphics_context.instance_buffer
	return ib.mapped_memories[graphics_context.virtual_frame_index]
}

// INTERNAL THINGS ------------------------------------------------------------

PARTICLE_CUBE_VERTICES :: []f32 {
	-0.5, -0.5, -0.5,
	0.5, -0.5, -0.5,
	-0.5, 0.5, -0.5,
	0.5, 0.5, -0.5,

	-0.5, -0.5, 0.5,
	0.5, -0.5, 0.5,
	-0.5, 0.5, 0.5,
	0.5, 0.5, 0.5,
}

PARTICLE_CUBE_INDICES :: []u16 {
	0, 2, 1,  1, 2, 3,
	5, 7, 4,  4, 7, 6, 

	4, 6, 0,  0, 6, 2,
	1, 3, 5,  5, 3, 7,

	0, 1, 4,  4, 1, 5,
	2, 6, 3,  3, 6, 7,
}

@(private="file")
make_shader :: proc(shader_source: string, type: u32) -> u32 {
	// opengl expects a null terminated cstring, let her have it her way
	shader_cstring := strings.clone_to_cstring(shader_source)
	defer delete(shader_cstring)

	shader := gl.CreateShader(type)

	gl.ShaderSource(shader, 1, &shader_cstring, nil)
	gl.CompileShader(shader)

	success : i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)

	// fmt.printf("Compile shader '%s', status: %i\n", filename, success)

	if success == 0 {
		info_log_buffer := make([]u8, 1024, context.temp_allocator)
		defer delete(info_log_buffer, context.temp_allocator)

		info_log_length : i32 = 0
		gl.GetShaderInfoLog(shader, cast(i32) len(info_log_buffer), &info_log_length, raw_data(info_log_buffer))
		fmt.printf("SHADER ERROR: %s\n", transmute(string)info_log_buffer[:info_log_length])
	}

	return shader
}

@(private="file")
create_instance_buffer_internal :: proc (instance_count: int) -> InstanceBuffer {		
	gc := &graphics_context

	ib := InstanceBuffer {}

	instance_size := size_of(InstanceData)
	instance_data_size := instance_size * instance_count

	gl.GenBuffers(VIRTUAL_FRAME_COUNT, raw_data(&ib.buffer_objects))
	for i in 0..<VIRTUAL_FRAME_COUNT {
		gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer_objects[i])
		
		/*
		To use this same memory from both CPU and GPU we need to specify
			- GL_MAP_COHERENT_BIT -> memory is visible on GPU 'immediately' after write
			- GL_MAP_PERSISTENT_BIT -> memory wont change, so same mapping can be used for long times
			- GL_MAP_WRITE_BIT -> OpenGL promises that we can write to memory correctly (we do not need to read)
		Note(Leo): using same memory on GPU and CPU is convenient, but may prevent
		GPU from using optimal memory layout which may cause performance loss. When
		optimizing, check if we can/need to do something different.
		*/
		flags : u32 = gl.MAP_COHERENT_BIT | gl.MAP_PERSISTENT_BIT | gl.MAP_WRITE_BIT
		gl.BufferStorage(gl.ARRAY_BUFFER, instance_data_size, nil, flags)
		ib.mapped_memories[i] = gl.MapBufferRange(gl.ARRAY_BUFFER, 0, instance_data_size, flags)
	}


	// In this application we basically only render batches of instances, and since instance
	// buffer is same as vertex buffer and needs to bound to and vertex array object so we create
	// one for each instance
	// instance_vertex_array_object : u32
	{
		// CREATE VERTEX ARRAY OBJECT
		gl.GenVertexArrays(VIRTUAL_FRAME_COUNT, raw_data(&ib.vertex_arrays))

		for i in 0..<VIRTUAL_FRAME_COUNT {
			gl.BindVertexArray(ib.vertex_arrays[i])

			// SETUP PARTICLE MESH VERTEX BUFFER
			gl.BindBuffer(gl.ARRAY_BUFFER, gc.particle_vertex_buffer_object)
			gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
			gl.EnableVertexAttribArray(0)

			// SETUP PARTICLE MESH INDEX BUFFER
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, gc.particle_index_buffer_object)

			// SETUP INSTANCE DATA BUFFER
			gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer_objects[i])
			gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
			gl.EnableVertexAttribArray(1)
			gl.VertexAttribDivisor(1, 1)
		}
	}

	ib.count 					= i32(instance_count)

	return ib
}

create_gradient_texture :: proc(colors : []vec4, positions : []f32) -> Texture {
	return Texture {internal_create_gradient_texture(colors, positions) }
}

destroy_texture :: proc(texture : Texture) {
	name := texture.opengl_name
	gl.DeleteTextures(1, &name)
}

internal_create_gradient_texture :: proc(colors : []vec4, positions : []f32) -> u32 {
	color_count := len(colors)

	pixel_count := 128
	pixel_data := make([]u8, pixel_count * 4)
	defer delete(pixel_data)

	for i in 0..<pixel_count {
		t := f32(i) / f32(pixel_count - 1)
		
		a := 0
		for positions[a + 1] < t {
			a += 1
		}
		a = linalg.min(a, color_count - 1)
		b := linalg.min(a + 1, color_count - 1) 

		min := clamp(positions[a], 0, 1)
		max := clamp(positions[b], min, 1)
		t = (t - min) / (max - min)

		color := linalg.lerp(colors[a], colors[b], t)
		
		x := i * 4
		pixel_data[x + 0] = u8(color.r * 255.999)
		pixel_data[x + 1] = u8(color.g * 255.999)
		pixel_data[x + 2] = u8(color.b * 255.999)
		pixel_data[x + 3] = 255
	}

	texture : u32
	gl.GenTextures(1, &texture)
	// todo(Leo): Maybe pick and reserve a slot for all housekeeping texture activites such as this. maybe
	gl.BindTexture(gl.TEXTURE_2D, texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(pixel_count), 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(pixel_data))

	gl.BindTexture(gl.TEXTURE_2D, 0)

	return texture
}

