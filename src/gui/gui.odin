package gui

import "../common"
import "../graphics"
import "../window"
import "../input"

import "core:fmt"
import "core:strings"
import "core:math"

import gl   "vendor:OpenGL"
import mu   "vendor:microui"

gui_state := struct {
    mu_ctx : mu.Context,
    bg_col : mu.Color,
    mu_mouse : mu.Mouse,
    
    // OpenGL stuff
    vertex_array_object   : u32,
    vertex_buffer_object  : u32,
    element_buffer_object : u32,
    program : u32,

    atlas_texture : u32,
    // font_atlas_texture : graphics.Texture,
}{
    bg_col = {1,1,1,1},
}

initialize :: proc() {
    
    ctx := &gui_state.mu_ctx
    
    // load atlas texture
    
    // create microui context
    // ctx := new(mu.Context) // this line may be superfluous
    mu.init(ctx)
    
    // don't know what this does exactly, but necessary
    ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

    // ====================== //
    // === TEXTURE ACTION === //
    // ====================== //

    // binding the texture objects
	gl.GenTextures(1, &gui_state.atlas_texture)
    gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, gui_state.atlas_texture)
    
    // texture wrapping and filtering options
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    
    // generating the texture
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.ALPHA, mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, 0, gl.ALPHA, gl.UNSIGNED_BYTE, raw_data(&mu.default_atlas_alpha))

    
    // ===================== //
    // === TIME TO SHADE === //
    // ===================== //

    // read shader source code from file at compile time
    vert_shader_source := #load("../shaders/gui.vert", string)
    frag_shader_source := #load("../shaders/gui.frag", string)

    // OpenGL magic to make the shaders usable
    vert_shader := build_shader(vert_shader_source, gl.VERTEX_SHADER)
    frag_shader := build_shader(frag_shader_source, gl.FRAGMENT_SHADER)
    shader_program := build_program(vert_shader, frag_shader)
    gui_state.program = shader_program
    
    // Don't do this
    // What! Why not? But ok!
    // gl.UseProgram(shader_program)

    // clean up
    gl.DeleteShader(vert_shader)
    gl.DeleteShader(frag_shader)

    // ======================================== //
    // === PICASSO THE MOST FANCY RECTANGLE === //
    // ======================================== //
    
    rect := mu.Rect{0.0, 0.0, 0.0, 0.0}
    color := mu.Color{0.0, 0.0, 0.0, 0.0}
    texCoord := mu.Rect{0.0, 0.0, 0.0, 0.0}
    indices := []u32{
        0, 1, 2,
        2, 1, 3,
    }

    // Vertex Array Object
    VAO := &gui_state.vertex_array_object
    gl.GenVertexArrays(1, VAO)
    gl.BindVertexArray(VAO^)

    // Vertex Buffer Object
    VBO := &gui_state.vertex_buffer_object
    gl.GenBuffers(1, VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO^)
    // gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), raw_data(vertices), gl.STATIC_DRAW)
    
    // Element Buffer Object
    EBO := &gui_state.element_buffer_object
    gl.GenBuffers(1, EBO)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO^)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.STATIC_DRAW)

    // define meaning of the vertices
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 9 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 9 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 9 * size_of(f32), 7 * size_of(f32))
    gl.EnableVertexAttribArray(2)    

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    fmt.println("GUI initialized!\n")
}

begin_frame :: proc() {
    /*
        must be called after input handling
    */
    ctx := &gui_state.mu_ctx

    // Processs input     
    mouse_x := i32(input.mouse.position.x)
    mouse_y := i32(input.mouse.position.y)
    mu.input_mouse_move(ctx, mouse_x, mouse_y)
    if input.mouse_button_went_down(0) {
        mu.input_mouse_down(ctx, mouse_x, mouse_y, gui_state.mu_mouse)
    }
    if input.mouse_button_went_up(0) {
        mu.input_mouse_up(ctx, mouse_x, mouse_y, gui_state.mu_mouse)
    }

    mu.begin(ctx)
}

// update :: proc() {
//     get_windows(ctx)
// }


render :: proc() {    
    ctx := &gui_state.mu_ctx
    mu.end(ctx)
    
    // define colors for testing purposes
    text_color := mu.Color{0,0,255,255} // blue
    icon_color := mu.Color{255,0,0,255} // red

    gl.Enable(gl.BLEND)
    gl.Disable(gl.CULL_FACE)
    defer(gl.Disable(gl.BLEND))
    defer(gl.Enable(gl.CULL_FACE))

    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    /*
    This block is microui doing the draw calls for each element 
    of the ui
    */
    command_backing : ^mu.Command
    for variant in mu.next_command_iterator(&gui_state.mu_ctx, &command_backing) {
        switch cmd in variant {
            case ^mu.Command_Text:
                pos := [2]i32{cmd.pos.x, cmd.pos.y}
                for ch in cmd.str do if ch&0xc0 != 0x80 {
                    r := min(int(ch), 127) // check whether it is included in the 128 character bitmap ?
                    rect := cast(common.Rect_i32) mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r] // define the rectangle containing the character ? 
                    
                    draw_rectangle(
                        common.Rect_i32{pos.x, pos.y, rect.w, rect.h},
                        rect,
                        transmute(common.Color_u8_rgba) cmd.color
                    )
                    pos.x += rect.w // increment the position so that characters aren't drawn on top of each other
                }
            case ^mu.Command_Rect:
                // Todo(Leo): change to explicit extension union/enum
                if cmd.size == size_of(Command_Rect_Texture) {
                    cmd := cast(^Command_Rect_Texture) cmd

                    draw_rectangle_texture(
                        cast(common.Rect_i32) cmd.rect,
                        cast(common.Rect_i32) mu.default_atlas[mu.DEFAULT_ATLAS_WHITE],
                        {220, 0, 220, 255},
                        cmd.texture,
                    )
                } 

                if cmd.size == size_of(mu.Command_Rect) {
                    draw_rectangle(
                        cast(common.Rect_i32) cmd.rect,
                        cast(common.Rect_i32) mu.default_atlas[mu.DEFAULT_ATLAS_WHITE],
                        transmute(common.Color_u8_rgba) cmd.color,
                    )
                }
            case ^mu.Command_Icon:
                rect := cast(common.Rect_i32) mu.default_atlas[cmd.id]
                x := cmd.rect.x + (cmd.rect.w - rect.w)/2
                y := cmd.rect.y + (cmd.rect.h - rect.h)/2
                draw_rectangle(
                    common.Rect_i32{x, y, rect.w, rect.h},
                    rect,
                    transmute(common.Color_u8_rgba) cmd.color,
                )
                //draw_texture(rect, {x, y}, cmd.color)
            case ^mu.Command_Clip:
                /*
                gl.Disable(gl.SCISSOR_TEST)
                gl.Scissor(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
                gl.Enable(gl.SCISSOR_TEST)
                */
            case ^mu.Command_Jump: 
                unreachable() // no clue what this is
        }
	}
}

terminate :: proc() {
    fmt.println("GUI terminated!\n")
}

build_shader :: proc(source : string, type : u32) -> u32 {
    // shader building
    success : i32
    shader : u32 
    source := strings.clone_to_cstring(source) 
    defer delete(source)
    shader = gl.CreateShader(type)
    gl.ShaderSource(shader, 1, &source, nil)
    gl.CompileShader(shader)
    
    // error checking
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        logLen : i32
        maxLength : i32 : 1024
        log := make([]u8, maxLength)
        defer delete(log)

        gl.GetShaderInfoLog(shader, maxLength, &logLen, raw_data(log))

        fmt.printfln("GUI SHADER ERROR: %s", transmute(string)log[:logLen])
    }

    return shader
}

build_program :: proc(vert_shader, frag_shader : u32) -> u32 {
    // program building
    success : i32
    program : u32
    program = gl.CreateProgram()
    gl.AttachShader(program, vert_shader)
    gl.AttachShader(program, frag_shader)
    gl.LinkProgram(program)

    // error checking
    gl.GetProgramiv(program, gl.LINK_STATUS, &success)
    if success == 0 {   
        logLen : i32
        maxLength : i32 : 1024
        log := make([]u8, maxLength)
        defer delete(log)

        gl.GetProgramInfoLog(program, maxLength, &logLen, raw_data(log))

        fmt.printfln("GUI PROGRAM ERROR: %s", transmute(string)log[:logLen])
    }

    return program
}

indent :: proc(ctx : ^mu.Context) {
    mu.get_layout(ctx).indent += ctx.style.indent
}

unindent :: proc(ctx : ^mu.Context) {
    mu.get_layout(ctx).indent -= ctx.style.indent
}

draw_rectangle :: proc(
    dst_rect : common.Rect_i32, 
    src_rect : common.Rect_i32, 
    color : common.Color_u8_rgba
) {
    
    /*
        TODO:
        - modify vertices to contain colors and texture coordinates
        - modify shaders to take in those arguments
    */
    createVertices :: proc(
        dst_rect : common.Rect_i32,
        color : common.Color_u8_rgba,
        src_rect : common.Rect_i32
    ) -> [36]f32 {
        vertices := [36]f32{
            // positions                                                        // colors                                                                                  // texture coordinates
            f32(dst_rect.x)             , f32(dst_rect.y)             , 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x) / 128             , f32(src_rect.y) / 128, 
            f32(dst_rect.x + dst_rect.w), f32(dst_rect.y)             , 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x + src_rect.w) / 128, f32(src_rect.y) / 128,
            f32(dst_rect.x)             , f32(dst_rect.y + dst_rect.h), 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x) / 128             , f32(src_rect.y + src_rect.h) / 128, 
            f32(dst_rect.x + dst_rect.w), f32(dst_rect.y + dst_rect.h), 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x + src_rect.w) / 128, f32(src_rect.y + src_rect.h) / 128
        }
        return vertices
    }

    /*texture_coordinates
        Add another argument -> texCoord : mu.Rect
        for handling texture
    */
    window_width, window_height := window.get_window_size()
    windowSizeLocation := gl.GetUniformLocation(gui_state.program, "windowSize")

    use_fill_texture_location := gl.GetUniformLocation(gui_state.program, "use_fill_texture")
    gl.Uniform1f(use_fill_texture_location, 0)

    vertices := createVertices(dst_rect, color, src_rect)

    gl.UseProgram(gui_state.program)
    gl.Uniform2f(windowSizeLocation, f32(window_width), f32(window_height))
    gl.Disable(gl.DEPTH_TEST) // necessary for the ui to draw on top of each other
    gl.BindVertexArray(gui_state.vertex_array_object)
    gl.BindBuffer(gl.ARRAY_BUFFER, gui_state.vertex_buffer_object)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.Enable(gl.TEXTURE_2D)
    gl.BindTexture(gl.TEXTURE_2D, gui_state.atlas_texture)

    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    gl.Enable(gl.DEPTH_TEST)
}


draw_rectangle_texture :: proc(
    dst_rect    : common.Rect_i32, 
    src_rect    : common.Rect_i32, 
    color       : common.Color_u8_rgba,
    texture     : graphics.Texture,
) {
    
    /*
        TODO:
        - modify vertices to contain colors and texture coordinates
        - modify shaders to take in those arguments
    */
    createVertices :: proc(
        dst_rect : common.Rect_i32,
        color : common.Color_u8_rgba,
        src_rect : common.Rect_i32
    ) -> [36]f32 {
        vertices := [36]f32{
            // positions                                                        // colors                                                                                  // texture coordinates
            f32(dst_rect.x)             , f32(dst_rect.y)             , 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x) / 128             , f32(src_rect.y) / 128, 
            f32(dst_rect.x + dst_rect.w), f32(dst_rect.y)             , 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x + src_rect.w) / 128, f32(src_rect.y) / 128,
            f32(dst_rect.x)             , f32(dst_rect.y + dst_rect.h), 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x) / 128             , f32(src_rect.y + src_rect.h) / 128, 
            f32(dst_rect.x + dst_rect.w), f32(dst_rect.y + dst_rect.h), 0.0,    f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0,    f32(src_rect.x + src_rect.w) / 128, f32(src_rect.y + src_rect.h) / 128
        }
        return vertices
    }

    /*texture_coordinates
        Add another argument -> texCoord : mu.Rect
        for handling texture
    */
    window_width, window_height := window.get_window_size()
    windowSizeLocation := gl.GetUniformLocation(gui_state.program, "windowSize")

    use_fill_texture_location := gl.GetUniformLocation(gui_state.program, "use_fill_texture")
    gl.Uniform1f(use_fill_texture_location, 1)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.Enable(gl.TEXTURE_2D)
    gl.BindTexture(gl.TEXTURE_2D, texture.opengl_name)

    fill_texture_location := gl.GetUniformLocation(gui_state.program, "fill_texture")
    gl.Uniform1f(fill_texture_location, 1)

    vertices := createVertices(dst_rect, color, src_rect)

    gl.UseProgram(gui_state.program)
    gl.Uniform2f(windowSizeLocation, f32(window_width), f32(window_height))
    gl.Disable(gl.DEPTH_TEST) // necessary for the ui to draw on top of each other
    gl.BindVertexArray(gui_state.vertex_array_object)
    gl.BindBuffer(gl.ARRAY_BUFFER, gui_state.vertex_buffer_object)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

    // gl.ActiveTexture(FONT_TEXTURE_SLOT)
    // gl.Enable(gl.TEXTURE_2D)
    // gl.BindTexture(gl.TEXTURE_2D, gui_state.atlas_texture)

    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    gl.Enable(gl.DEPTH_TEST)
}









/*
rect2vertices :: proc(rect : mu.Rect, layer : f32 = 0.0) -> [12]f32 {
    vertices := [12]f32{
        f32(rect.x)         , f32(rect.y), layer,
        f32(rect.x + rect.w), f32(rect.y), layer,
        f32(rect.x)         , f32(rect.y + rect.h), layer,
        f32(rect.x + rect.w), f32(rect.y + rect.h), layer,
    }

    return vertices
}
draw_rectangle :: proc(rect : mu.Rect = mu.Rect{-1,-1,1,1}, offset : mu.Rect = {0,0,1,2}, color : mu.Color = mu.Color{0,0,0,1}, layer : f32 = 0.0) {
	window_width, window_height := window.get_window_size()
    vertices := rect2vertices(rect, layer) 
    windowSizeLocation := gl.GetUniformLocation(gui_state.program, "windowSize")
    offsetLocation := gl.GetUniformLocation(gui_state.program, "offset")
    rectColorLocation := gl.GetUniformLocation(gui_state.program, "rectColor")
    gl.UseProgram(gui_state.program)
    gl.Uniform2f(windowSizeLocation, f32(window_width), f32(window_height))
    gl.Uniform2f(offsetLocation, f32(offset.x), f32(offset.y))
    gl.Uniform4f(rectColorLocation, f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0)
    gl.BindVertexArray(gui_state.vertex_array_object)
    gl.BindBuffer(gl.ARRAY_BUFFER, gui_state.vertex_buffer_object)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}
draw_texture :: proc(rect : mu.Rect = mu.Rect{-1,-1,1,1}, pos : [2]i32 = [2]i32{0, 0}, color : mu.Color = mu.Color{0,0,0,1}) {
    tex_rect := mu.Rect{pos[0], pos[1], rect.w, rect.h}
    draw_rectangle(tex_rect)
    gl.UseProgram(gui_state.program)
    //texLocation = gl.GetUniformLocation(gui_state.program, "tex")
    texPosLocation := gl.GetUniformLocation(gui_state.program, "texPos")
    rectColorLocation := gl.GetUniformLocation(gui_state.program, "rectColor")
    gl.Uniform2f(texPosLocation, f32(pos[0]), f32(pos[1])) 
    gl.Uniform4f(rectColorLocation, f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0)
    gl.BindTexture(gl.TEXTURE_2D, gui_state.atlas_texture);
    gl.BindVertexArray(gui_state.atlas_VAO)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}
*/

/*
Custom texture button, appropriated from mu normal button. These are now still split
into many procedures, although this is unnecessary.
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
    draw_texture_control_frame(ctx, id, r, texture, .BUTTON, opt)
    if len(label) > 0 {
        mu.draw_control_text(ctx, label, r, .TEXT, opt)
    }
    // if icon != .NONE {
    //     mu.draw_icon(ctx, icon, r, ctx.style.colors[.TEXT])
    // }
    return
}

draw_texture_control_frame :: proc(ctx: ^mu.Context, id: mu.Id, rect: mu.Rect, texture : graphics.Texture, colorid: mu.Color_Type, opt := mu.Options{}) {
    if .NO_FRAME in opt {
        return
    }
    assert(colorid == .BUTTON || colorid == .BASE)
    colorid := colorid
    colorid = mu.Color_Type(int(colorid) + int((ctx.focus_id == id) ? 2 : (ctx.hover_id == id) ? 1 : 0))
    default_draw_texture_frame(ctx, rect, texture, colorid)
    // ctx.draw_frame(ctx, rect, colorid)
}

default_draw_texture_frame :: proc(ctx: ^mu.Context, rect: mu.Rect, texture : graphics.Texture, colorid: mu.Color_Type) {
    // mu.draw_rect(ctx, rect, ctx.style.colors[colorid])
    draw_texture_rect(ctx, rect, texture, ctx.style.colors[colorid])
    
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
Command_Rect_Texture :: struct {
    using cmd_rect  : mu.Command_Rect,
    texture         : graphics.Texture,
}

draw_texture_rect :: proc(ctx: ^mu.Context, rect: mu.Rect, texture : graphics.Texture, color: mu.Color) {
    rect := rect
    rect = mu.intersect_rects(rect, mu.get_clip_rect(ctx))
    if rect.w > 0 && rect.h > 0 {
        EXTRA_SIZE :: size_of(Command_Rect_Texture) - size_of(mu.Command_Rect)

        cmd := transmute(^Command_Rect_Texture) mu.push_command(ctx, mu.Command_Rect, EXTRA_SIZE)
        cmd.rect = rect
        cmd.color = color
        cmd.texture = texture
    }
}
