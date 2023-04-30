package main

// import mu "vendor:microui"
import gl "vendor:OpenGL"
import "core:fmt"
import "oswnd"
// import r "microui_renderer"
import glh "gl_helpers"

Vertex :: struct {
    position: [2]f32,
    color: [4]f32,
}

// atlas_as_rgba :: proc() -> (result: [len(mu.default_atlas_alpha) * 4]u8) {
//     for i in 0 ..< len(mu.default_atlas_alpha) {
//         result[i * 4 + 0] = 255
//         result[i * 4 + 1] = 255
//         result[i * 4 + 2] = 255
//         result[i * 4 + 3] = mu.default_atlas_alpha[i]
//     }
//     return
// }

// atlas := atlas_as_rgba()
// atlas := [16]u8{
//     255, 255, 255, 255,
//     255, 255, 0, 255,
//     255, 0, 255, 255,
//     255, 255, 255, 255,
// }

main :: proc() {
    window := oswnd.create()
    oswnd.show(window)
    oswnd.make_context_current(window)

    gl.load_up_to(3, 3, oswnd.gl_set_proc_address)

    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Disable(gl.CULL_FACE)
    gl.Disable(gl.DEPTH_TEST)

    width, height := oswnd.size(window)
    gl.Viewport(0, 0, i32(width), i32(height))

    // gl.Enable(gl.SCISSOR_TEST)
    // gl.Enable(gl.TEXTURE_2D)

    // texture := glh.texture_generate()
    // defer glh.texture_delete(&texture)
    // glh.texture_upload_data(&texture, .Rgba, 1, 1, atlas[:])
    // glh.texture_upload_data(&texture, .Rgba, mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, atlas[:])

    shader := glh.shader_generate(VERTEX_SOURCE, FRAGMENT_SOURCE)
    defer glh.shader_delete(&shader)

    vertex_buffer := glh.vertex_buffer_generate(Vertex)
    defer glh.vertex_buffer_delete(&vertex_buffer)
    glh.vertex_buffer_upload_data(&vertex_buffer, []Vertex{
		{{-0.5, +0.5}, {1, 1, 1, 1}},
		{{-0.5, -0.5}, {1, 1, 1, 1}},
		{{+0.5, -0.5}, {1, 1, 1, 1}},
		{{+0.5, +0.5}, {1, 1, 1, 1}},
	})

    index_buffer := glh.index_buffer_generate(u16)
    defer glh.index_buffer_delete(&index_buffer)
    glh.index_buffer_upload_data(&index_buffer, []u16{
        0, 1, 2,
        2, 3, 0,
    })

    for oswnd.is_open(window) {
        oswnd.poll_events()

        gl.ClearColor(0.1, 0.1, 0.1, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        // glh.draw_triangles(&vertex_buffer, &index_buffer, &shader, &texture)
        // glh.draw_triangles(&vertex_buffer, &index_buffer, &shader)

        oswnd.swap_buffers(window)
    }
}

VERTEX_SOURCE :: `#version 330 core
layout(location=0) in vec2 Position;
layout(location=1) in vec4 Color;
out vec4 Frag_Color;
void main() {
    Frag_Color = Color;
    gl_Position = vec4(Position.xy, 0, 1);
}
`

FRAGMENT_SOURCE :: `#version 330 core
in vec4 Frag_Color;
out vec4 Out_Color;
void main() {
    Out_Color = Frag_Color;
}
`

// VERTEX_SOURCE :: `#version 330 core
// layout(location=0) in vec2 Position;
// layout(location=1) in vec2 UV;
// layout(location=2) in vec4 Color;
// out vec2 Frag_UV;
// out vec4 Frag_Color;
// void main() {
//     Frag_UV = UV;
//     Frag_Color = Color;
//     gl_Position = vec4(Position.xy, 0, 1);
// }
// `

// FRAGMENT_SOURCE :: `#version 330 core
// uniform sampler2D Texture;
// in vec2 Frag_UV;
// in vec4 Frag_Color;
// out vec4 Out_Color;
// void main() {
//     Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
// }
// `

// window.on_close = proc(window: ^oswnd.Window) {
//     fmt.println("Window closed\n")
// }
// window.on_move = proc(window: ^oswnd.Window, x, y: int) {
//     fmt.printf("Window moved: %i, %i\n", x, y)
// }
// window.on_resize = proc(window: ^oswnd.Window, width, height: int) {
//     fmt.printf("Window resized: %i, %i\n", width, height)
// }
// window.on_mouse_move = proc(window: ^oswnd.Window, x, y: int) {
//     fmt.printf("Mouse moved: %i, %i\n", x, y)
// }
// window.on_mouse_press = proc(window: ^oswnd.Window, button: oswnd.Mouse_Button, x, y: int) {
//     fmt.printf("Mouse pressed: %v, %i, %i\n", button, x, y)
// }
// window.on_mouse_release = proc(window: ^oswnd.Window, button: oswnd.Mouse_Button, x, y: int) {
//     fmt.printf("Mouse released: %v, %i, %i\n", button, x, y)
// }
// window.on_mouse_wheel = proc(window: ^oswnd.Window, x, y: f64) {
//     fmt.printf("Mouse wheel: %f, %f\n", x, y)
// }
// window.on_mouse_enter = proc(window: ^oswnd.Window, x, y: int) {
//     fmt.printf("Mouse entered: %i, %i\n", x, y)
// }
// window.on_mouse_exit = proc(window: ^oswnd.Window, x, y: int) {
//     fmt.printf("Mouse exited: %i, %i\n", x, y)
// }
// window.on_key_press = proc(window: ^oswnd.Window, key: oswnd.Keyboard_Key) {
//     fmt.printf("Key pressed: %v\n", key)
// }
// window.on_key_release = proc(window: ^oswnd.Window, key: oswnd.Keyboard_Key) {
//     fmt.printf("Key released: %v\n", key)
// }
// window.on_rune = proc(window: ^oswnd.Window, r: rune) {
//     fmt.printf("Rune typed: %v\n", r)
// }
// window.on_dpi_change = proc(window: ^oswnd.Window, dpi: f64) {
//     fmt.printf("Dpi changed: %f\n", dpi)
// }