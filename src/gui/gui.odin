package gui

import "shrubs:common"
import "shrubs:graphics"
import "shrubs:window"
import "shrubs:input"

import "core:fmt"
import "core:strings"
import "core:math"

import mu   "vendor:microui"

vec2 		:: common.vec2
vec4 		:: common.vec4
Rect_f32 	:: common.Rect_f32

@private
gui_context : struct {
	mu_ctx 				: mu.Context,
	font_atlas_texture 	: graphics.Texture,
}

get_mu_context :: proc() -> ^mu.Context {
	return &gui_context.mu_ctx
}

initialize :: proc() {
	
	ctx := &gui_context.mu_ctx
	mu.init(ctx)
	
	// Set secret mu function pointers to calculate text sizes
	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	gui_context.font_atlas_texture = graphics.create_alpha_only_texture(
		mu.DEFAULT_ATLAS_WIDTH,
		mu.DEFAULT_ATLAS_HEIGHT,
		mu.default_atlas_alpha[:],
		.Linear,
	)

	fmt.println("GUI initialized!\n")
}

begin_frame :: proc() {
	/*
		must be called after input handling
	*/
	ctx := &gui_context.mu_ctx

	// Processs input     
	mouse_x := i32(input.DEBUG_get_mouse_position(0))
	mouse_y := i32(input.DEBUG_get_mouse_position(1))
	mu.input_mouse_move(ctx, mouse_x, mouse_y)
	if input.DEBUG_get_mouse_button_pressed(0) {
		mu.input_mouse_down(ctx, mouse_x, mouse_y, .LEFT)
	}
	if input.DEBUG_get_mouse_button_released(0) {
		mu.input_mouse_up(ctx, mouse_x, mouse_y, .LEFT)
	}

	mu.begin(ctx)
}

render :: proc() {    
	ctx := &gui_context.mu_ctx
	mu.end(ctx)
	
	color_vec4 :: proc(c : mu.Color) -> vec4 {
		return {f32(c.r) / 255, f32(c.g) / 255, f32(c.b) / 255, f32(c.a) / 255 }
	}

	rect_f32 :: proc(r : mu.Rect) -> Rect_f32 {
		return { f32(r.x), f32(r.y), f32(r.w), f32(r.h) }
	}

	normalize_texture_rect :: proc(r : Rect_f32) -> Rect_f32 {
		return { r.x / 128, r.y / 128, r.w / 128, r.h / 128 }
	}

	/*
	This block is microui doing the draw calls for each element 
	of the ui
	*/
	command_backing : ^mu.Command
	for variant in mu.next_command_iterator(&gui_context.mu_ctx, &command_backing) {
		switch cmd in variant {
			case ^mu.Command_Text:

				graphics.set_gui_material(
					color_vec4(cmd.color),
					&gui_context.font_atlas_texture,
					.Text_Or_Icon,
				)

				text_position := vec2{f32(cmd.pos.x), f32(cmd.pos.y)}
				for ch in cmd.str do if ch&0xc0 != 0x80 {
					// check whether it is included in the 128 character bitmap?
					r := min(int(ch), 127)
					
					font_rect := rect_f32(mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r])
					
					screen_rect := Rect_f32{
						text_position.x, 
						text_position.y, 
						font_rect.w, 
						font_rect.h,
					}
					
					graphics.draw_gui_rect(screen_rect, normalize_texture_rect(font_rect))

					// increment the position for the next character
					text_position.x += font_rect.w
				}
			case ^mu.Command_Rect:
				// Todo(Leo): change to explicit extension union/enum
				// Extended Rect: Texture
				if cmd.size == size_of(mu_Command_Rect_Texture) {
					cmd := cast(^mu_Command_Rect_Texture) cmd

					graphics.set_gui_material({}, &cmd.texture, .Image)
					graphics.draw_gui_rect(rect_f32(cmd.rect), {})

				} 

				// Normal Rect
				if cmd.size == size_of(mu.Command_Rect) {
					graphics.set_gui_material(color_vec4(cmd.color), nil, .Solid)
					graphics.draw_gui_rect(rect_f32(cmd.rect), {})
				}
			case ^mu.Command_Icon:
				graphics.set_gui_material(
					color_vec4(cmd.color),	
					&gui_context.font_atlas_texture,
					.Text_Or_Icon,
				)

				icon_rect := rect_f32(mu.default_atlas[cmd.id])
				
				// Icon cmd.rect is given as the entire space it occupies, but the 
				// actual icon texture does not necessarily fill that entire space.
				// Icon is placed in the center of the given space and sized depending
				// on its texture atlas rect size. Microui operates on integers, but here
				// floats are used, so the offset term must be floored to achieve the 
				// intended placement and look.
				screen_rect := Rect_f32{
					f32(cmd.rect.x) + math.floor((f32(cmd.rect.w) - icon_rect.w) * 0.5),
					f32(cmd.rect.y) + math.floor((f32(cmd.rect.h) - icon_rect.h) * 0.5),
					icon_rect.w, 
					icon_rect.h,
				}
				graphics.draw_gui_rect(screen_rect, normalize_texture_rect(icon_rect))

			case ^mu.Command_Clip:
				fmt.println("MU CLIP")
				unreachable()
				/*
				gl.Disable(gl.SCISSOR_TEST)
				gl.Scissor(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
				gl.Enable(gl.SCISSOR_TEST)
				*/
			case ^mu.Command_Jump: 
				fmt.println("MU JUMP")
				unreachable()
		}
	}
}

terminate :: proc() {
	fmt.println("GUI terminated!\n")
}

indent :: proc(ctx : ^mu.Context) {
	mu.get_layout(ctx).indent += ctx.style.indent
}

unindent :: proc(ctx : ^mu.Context) {
	mu.get_layout(ctx).indent -= ctx.style.indent
}

/*
Custom texture button, appropriated from mu normal button. These are now still split
into many procedures, although this is unnecessary. Also, all unneccessary code is just
commented out and not deleted, to easierly know what is/should be going on.
*/


texture_button :: proc(ctx: ^mu.Context, label: string, texture : graphics.Texture, opt: mu.Options = {.ALIGN_CENTER}) -> (res: mu.Result_Set) {
	// id := len(label) > 0 ? mu.get_id(ctx, label) : mu.get_id(ctx, uintptr(icon))
	id := len(label) > 0 ? mu.get_id(ctx, label) : mu.get_id(ctx, uintptr(texture.opengl_name))
	r := mu.layout_next(ctx)
	mu.update_control(ctx, id, r, opt)
	/* handle click */
	if ctx.mouse_pressed_bits == {.LEFT} && ctx.focus_id == id {
		res += {.SUBMIT}
	}
	/* draw */
	mu_draw_texture_control_frame(ctx, id, r, texture, .BUTTON, opt)
	if len(label) > 0 {
		mu.draw_control_text(ctx, label, r, .TEXT, opt)
	}
	// if icon != .NONE {
	//     mu.draw_icon(ctx, icon, r, ctx.style.colors[.TEXT])
	// }
	return
}

///////////////////////////////////////////////////////////////////////////////
// MU EXTENSION ZONE

@private
mu_draw_texture_control_frame :: proc(ctx: ^mu.Context, id: mu.Id, rect: mu.Rect, texture : graphics.Texture, colorid: mu.Color_Type, opt := mu.Options{}) {
	if .NO_FRAME in opt {
		return
	}
	assert(colorid == .BUTTON || colorid == .BASE)
	colorid := colorid
	colorid = mu.Color_Type(int(colorid) + int((ctx.focus_id == id) ? 2 : (ctx.hover_id == id) ? 1 : 0))
	mu_default_draw_texture_frame(ctx, rect, texture, colorid)
	// ctx.draw_frame(ctx, rect, colorid)
}

@private
mu_default_draw_texture_frame :: proc(ctx: ^mu.Context, rect: mu.Rect, texture : graphics.Texture, colorid: mu.Color_Type) {
	// mu.draw_rect(ctx, rect, ctx.style.colors[colorid])
	mu_draw_texture_rect(ctx, rect, texture, ctx.style.colors[colorid])
	
	// Highligh the hovered buttons. The effect is super subtle, but keeps gui just a tiny hint
	// more alive. These compare to normal mu button hover highlights 
	if colorid == .BUTTON_HOVER {
		mu.draw_rect(ctx, rect, {255, 255, 255, 20})
	}
	if colorid == .BUTTON_FOCUS {
		mu.draw_rect(ctx, rect, {255, 255, 255, 40})
	}

	if ctx.style.colors[.BORDER].a != 0 { /* draw border */
		mu.draw_box(ctx, mu.expand_rect(rect, 1), ctx.style.colors[.BORDER])
	}
}

/*
Extension to mu.Command_Rect

Todo(Leo): This is not ultimately totally robust way if we have more extended types, since
it is detected by size_of and that may end up being same size as something else. Make an
extra enum/union thing or smth.
*/
@private
mu_Command_Rect_Texture :: struct {
	using cmd_rect  : mu.Command_Rect,
	texture         : graphics.Texture,
}

@private
mu_draw_texture_rect :: proc(ctx: ^mu.Context, rect: mu.Rect, texture : graphics.Texture, color: mu.Color) {
	rect := rect
	rect = mu.intersect_rects(rect, mu.get_clip_rect(ctx))
	if rect.w > 0 && rect.h > 0 {
		EXTRA_SIZE :: size_of(mu_Command_Rect_Texture) - size_of(mu.Command_Rect)

		cmd := transmute(^mu_Command_Rect_Texture) mu.push_command(ctx, mu.Command_Rect, EXTRA_SIZE)
		cmd.rect = rect
		cmd.color = color
		cmd.texture = texture
	}
}
