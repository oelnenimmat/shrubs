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


@private
graphics_context : struct {
	view_matrix 		: mat4,
	projection_matrix 	: mat4,

	virtual_frame_index : int,
	virtual_frame_in_use_fences : [VIRTUAL_FRAME_COUNT]gl.sync_t,

	// Pipelines :)
	basic_pipeline 				: BasicPipeline,
	grass_pipeline 				: GrassPipeline,
	terrain_pipeline			: TerrainPipeline,
	grass_placement_pipeline 	: GrassPlacementPipeline,
	sky_pipeline 				: SkyPipeline,
	post_process_pipeline 		: PostProcessPipeline,
	debug_pipeline 				: DebugPipeline,

	pipeline_shared 			: PipelineShared,

	// Per draw uniform locations. These are set whenever a new pipeline
	// is bound/setupped, and used in draw_XXX functions
	// Todo(Leo): instead, just move all draw stuff to pipelines, as they are very
	// intimately coupled anyway
	model_matrix_location : i32,

	// main_render_target : RenderTarget,
}

initialize :: proc() {
	// OpenGL headers contain a set of function pointers, that need to be loaded explicitly
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	{
		print_info :: proc(msg : string, name : u32) {
			value : i32
			gl.GetIntegerv(name, &value)
			fmt.printfln("[GRAPHICS]: {}: {}", msg, value)
		}

		// Todo(Leo): this info needs to be found on the range of hardware that is planned
		// to be supported
		print_info("max uniform locations", gl.MAX_UNIFORM_LOCATIONS)
		print_info("max uniform buffer bindings", gl.MAX_UNIFORM_BUFFER_BINDINGS)
		print_info("max frag texture units", gl.MAX_TEXTURE_IMAGE_UNITS)
		print_info("max vert texture units", gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS)
	}

	// These SHOULD be same for all, if not, move to individual pipelines
	{
		// Always the right hand rule. This is for triangle winding.
		gl.FrontFace(gl.CCW)
		gl.CullFace(gl.BACK)
	
		// Rendering sky needs this, and others don't mind
		gl.DepthFunc(gl.LEQUAL)
	}

	// This is same for all for now, for gui and postprocessing might change
	gl.Enable(gl.MULTISAMPLE)

	window_width, window_height := window.get_window_size()
	gl.Viewport(0, 0, i32(window_width), i32(window_height))

	gc := &graphics_context
	gc^ = {}

	gc.basic_pipeline 			= create_basic_pipeline()
	gc.grass_pipeline 			= create_grass_pipeline()
	gc.terrain_pipeline 		= create_terrain_pipeline()
	gc.grass_placement_pipeline = create_grass_placement_pipeline()
	gc.sky_pipeline 			= create_sky_pipeline()
	gc.post_process_pipeline	= create_post_process_pipeline()

	gc.debug_pipeline 			= create_debug_pipeline()

	gc.pipeline_shared 			= create_pipeline_shared()

	// Todo(Leo): there might be issue here that this could be called before
	// setting up the opengl stuff and then something going haywire, seems to work now
	glfw_resize_framebuffer_proc :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
		// Todo(Leo): re create the manual render target also
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

	// Todo(Leo): learn more if this is necessary or not. Also if it matters
	// if this is before or after fence sync. https://stackoverflow.com/questions/2143240/opengl-glflush-vs-glfinish
	// Moves all sent commands to execution
	gl.Flush()
}

// End of maintenance section
/////////////////////////////////////////////////////

RenderTarget :: struct {
	// Todo(Leo): this is virtual frame stuff
	render_fbo 			: u32,
	color_attachment 	: u32,
	depth_attachemnt 	: u32,

	resolve_fbo 	: u32,
	resolve_image 	: u32,

	width, height : i32,
}

create_render_target :: proc(width, height, multisample_count : i32) -> RenderTarget{	
	rt := RenderTarget{}

	// Generate the framebuffer for post processing
	gl.GenFramebuffers(1, &rt.render_fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, rt.render_fbo)

	rt.width = width
	rt.height = height

	gl.GenRenderbuffers(1, &rt.color_attachment)
	gl.GenRenderbuffers(1, &rt.depth_attachemnt)

	if multisample_count == 1 {
		gl.BindRenderbuffer(gl.RENDERBUFFER, rt.color_attachment)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.RGB32F, width, height)

		gl.BindRenderbuffer(gl.RENDERBUFFER, rt.depth_attachemnt)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, width, height)
	} else {
		gl.BindRenderbuffer(gl.RENDERBUFFER, rt.color_attachment)
		gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, multisample_count, gl.RGB32F, width, height)

		gl.BindRenderbuffer(gl.RENDERBUFFER, rt.depth_attachemnt)
		gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, multisample_count, gl.DEPTH24_STENCIL8, width, height)
	}

	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, rt.color_attachment)
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rt.depth_attachemnt)

	if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE {
		fmt.println("Render Frambuffer GOOD!")
	} else {
		fmt.println("Render Frambuffer BAD!")
	}

	// Resolve image for flattening the multisample image
	gl.GenFramebuffers(1, &rt.resolve_fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, rt.resolve_fbo)

	gl.GenTextures(1, &rt.resolve_image)
	gl.BindTexture(gl.TEXTURE_2D, rt.resolve_image)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB32F, rt.width, rt.height, 0, gl.RGB, gl.FLOAT, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, rt.resolve_image, 0)

	if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE {
		fmt.println("Resolve Frambuffer GOOD!")
	} else {
		fmt.println("Resolve Frambuffer BAD!")
	}

	return rt

	// 	switch status {
	// 		case gl.FRAMEBUFFER_UNDEFINED: fmt.println("GL_FRAMEBUFFER_UNDEFINED")
	// 		case gl.FRAMEBUFFER_INCOMPLETE_ATTACHMENT: fmt.println("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT")
	// 		case gl.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: fmt.println("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT")
	// 		case gl.FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER: fmt.println("GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER")
	// 		case gl.FRAMEBUFFER_INCOMPLETE_READ_BUFFER: fmt.println("GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER")
	// 		case gl.FRAMEBUFFER_UNSUPPORTED: fmt.println("GL_FRAMEBUFFER_UNSUPPORTED")
	// 		case gl.FRAMEBUFFER_INCOMPLETE_MULTISAMPLE: fmt.println("GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE")
	// 		case gl.FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS: fmt.println("GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS") 
	// 		case: fmt.print("something else\n")
	// 	}
}

destroy_render_target :: proc(rt : ^RenderTarget) {
	gl.DeleteFramebuffers(1, &rt.render_fbo)
	gl.DeleteRenderbuffers(1, &rt.color_attachment)
	gl.DeleteRenderbuffers(1, &rt.depth_attachemnt)

	rt^ = {}
}

bind_render_target :: proc(rt : ^RenderTarget) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, rt.render_fbo)
	gl.Viewport(0, 0, rt.width, rt.height)

	// Clear to hostile pink, so we see easily if some pixel is not rendered to.
	gl.ClearColor(1, 0, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

resolve_render_target :: proc(rt : ^RenderTarget) {
	// Todo(Leo): instead, we should look into just sampling the multisample image
	// in the post process shader
	gl.BindFramebuffer(gl.READ_FRAMEBUFFER, rt.render_fbo)
	gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, rt.resolve_fbo)

	w := rt.width
	h := rt.height

	gl.BlitFramebuffer(0, 0, w, h, 0, 0, w, h, gl.COLOR_BUFFER_BIT, gl.LINEAR)
}


bind_screen_framebuffer :: proc() {
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	window_width, window_height := window.get_window_size()
	gl.Viewport(0, 0, i32(window_width), i32(window_height))

	// Clear to hostile pink, so we see easily if some pixel is not rendered to.
	gl.ClearColor(1, 0, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

bind_uniform_buffer :: proc(buffer : ^Buffer, binding : u32) {
	gl.BindBufferBase(gl.UNIFORM_BUFFER, binding, buffer.buffer)
}

read_screen_framebuffer :: proc() -> (width, height : int, pixels_u8_rgba : []u8) {
	// Todo(Leo): make sure that it is screen framebuffer
	// that is actually bound, as this is promised in the function name

	width, height = window.get_window_size()

	pixels_u8_rgba = make([]u8, 4 * width * height)
	gl.ReadPixels(0, 0, i32(width), i32(height), gl.RGBA, gl.UNSIGNED_BYTE, raw_data(pixels_u8_rgba))

	return width, height, pixels_u8_rgba
}

///////////////////////////////////////////////////////////////////////////////
// Platform internal usage

@private
set_texture_2D :: proc(texture : ^Texture, slot : u32) {
	gl.ActiveTexture(gl.TEXTURE0 + slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, texture.opengl_name)
}

@private
resize_framebuffer :: proc "c" (width, height: int) {
	// Note(leo): need context for assert and printf
	// context = runtime.default_context()

	// // Note(Leo): There should never be a reason to set window/framebuffer even close
	// // to max(i32)
	// assert(width < int(max(i32)))
	// assert(height < int(max(i32)))

	// width := i32(width)
	// height := i32(height)

	// fmt.printf("OpenGL framebuffer resized (%i, %i)\n", width, height)

	// gl.Viewport(0, 0, width, height)

	// gc := &graphics_context

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

@private
make_shader :: proc(shader_source: cstring, type: u32) -> u32 {
	shader_source := shader_source
	shader := gl.CreateShader(type)

	gl.ShaderSource(shader, 1, &shader_source, nil)
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

@private
create_shader_program :: proc(vertex_source, fragment_source : cstring) -> u32 {
	program := gl.CreateProgram()

	vertex_shader := make_shader(vertex_source, gl.VERTEX_SHADER)
	fragment_shader := make_shader(fragment_source, gl.FRAGMENT_SHADER)

	gl.AttachShader(program, vertex_shader)
	gl.AttachShader(program, fragment_shader)
	gl.LinkProgram(program)

	success : i32
	gl.GetProgramiv(program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log_buffer := make([]u8, 1024, context.temp_allocator)
		defer delete(info_log_buffer, context.temp_allocator)

		info_log_length : i32 = 0
		gl.GetProgramInfoLog(program, cast(i32) len(info_log_buffer), &info_log_length, raw_data(info_log_buffer))
		fmt.printf("SHADER PROGRAM ERROR: %s\n", transmute(string)info_log_buffer[:info_log_length])	
	} else {
		fmt.println("Shader Program created succesfully")
	}

	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)

	return program
}

@private
create_compute_shader_program :: proc(compute_source : cstring) -> u32 {
	program := gl.CreateProgram()

	compute_shader := make_shader(compute_source, gl.COMPUTE_SHADER)

	gl.AttachShader(program, compute_shader)
	gl.LinkProgram(program)

	success : i32
	gl.GetProgramiv(program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log_buffer := make([]u8, 1024, context.temp_allocator)
		defer delete(info_log_buffer, context.temp_allocator)

		info_log_length : i32 = 0
		gl.GetProgramInfoLog(program, cast(i32) len(info_log_buffer), &info_log_length, raw_data(info_log_buffer))
		fmt.printf("SHADER PROGRAM ERROR: %s\n", transmute(string)info_log_buffer[:info_log_length])	
	} else {
		fmt.println("Shader Program created succesfully")
	}

	gl.DeleteShader(compute_shader)

	return program
}

// create_gradient_texture :: proc(colors : []vec4, positions : []f32) -> Texture {
// 	return Texture {internal_create_gradient_texture(colors, positions) }
// }

// internal_create_gradient_texture :: proc(colors : []vec4, positions : []f32) -> u32 {
// 	color_count := len(colors)

// 	pixel_count := 128
// 	pixel_data := make([]u8, pixel_count * 4)
// 	defer delete(pixel_data)

// 	for i in 0..<pixel_count {
// 		t := f32(i) / f32(pixel_count - 1)
		
// 		a := 0
// 		for positions[a + 1] < t {
// 			a += 1
// 		}
// 		a = linalg.min(a, color_count - 1)
// 		b := linalg.min(a + 1, color_count - 1) 

// 		min := clamp(positions[a], 0, 1)
// 		max := clamp(positions[b], min, 1)
// 		t = (t - min) / (max - min)

// 		color := linalg.lerp(colors[a], colors[b], t)
		
// 		x := i * 4
// 		pixel_data[x + 0] = u8(color.r * 255.999)
// 		pixel_data[x + 1] = u8(color.g * 255.999)
// 		pixel_data[x + 2] = u8(color.b * 255.999)
// 		pixel_data[x + 3] = 255
// 	}

// 	texture : u32
// 	gl.GenTextures(1, &texture)
// 	// todo(Leo): Maybe pick and reserve a slot for all housekeeping texture activites such as this. maybe
// 	gl.BindTexture(gl.TEXTURE_2D, texture)
// 	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
// 	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
// 	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
// 	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	
// 	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(pixel_count), 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(pixel_data))

// 	gl.BindTexture(gl.TEXTURE_2D, 0)

// 	return texture
// }

