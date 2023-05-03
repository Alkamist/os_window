package main

import mu "vendor:microui"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "core:fmt"
import "oswnd"
import r "microui_renderer"

main :: proc() {
    window := oswnd.create()
    defer oswnd.destroy(window)

    oswnd.show(window)
    oswnd.make_context_current(window)

    gl.load_up_to(3, 3, oswnd.gl_set_proc_address)

    r.init()
    defer r.shutdown()

    renderer := r.renderer_make()
    defer r.renderer_destroy(renderer)

    for oswnd.is_open(window) {
        oswnd.poll_events(window)

        r.setup_gl_state()

        width, height := oswnd.size(window)
        renderer.width = width
        renderer.height = height

        gl.Viewport(0, 0, i32(width), i32(height))
		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

        // r.draw_rect(renderer, mu.Rect{50, 50, 100, 100}, mu.Color{255, 0, 255, 255})
        // r.draw_rect(renderer, mu.Rect{200, 200, 100, 100}, mu.Color{0, 255, 255, 255})

        r.draw_text(renderer, "Ayy lmao", mu.Vec2{300, 300}, mu.Color{255, 255, 255, 255})

        r.draw_icon(renderer, 1, mu.Rect{50, 50, 100, 100}, mu.Color{255, 255, 255, 255})

        r.flush(renderer)

        oswnd.swap_buffers(window)
    }
}

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