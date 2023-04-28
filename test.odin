package main

// import gl "vendor:OpenGL"
import "core:fmt"
import "oswnd"

main :: proc() {
    window := oswnd.create()

    window.on_frame = proc(window: ^oswnd.Window) {
        // gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        // gl.Clear(gl.COLOR_BUFFER_BIT)

        // if oswnd.mouse_just_entered(window) {
        //     fmt.println("Mouse just entered")
        // }
        // if oswnd.mouse_just_exited(window) {
        //     fmt.println("Mouse just exited")
        // }
        // if oswnd.mouse_just_moved(window) {
        //     fmt.printf("Mouse just moved: %v, %v\n", oswnd.mouse_x(window), oswnd.mouse_y(window))
        // }

        oswnd.swap_buffers(window)
    }

    for oswnd.is_open(window) {
        oswnd.poll(window)
    }
}