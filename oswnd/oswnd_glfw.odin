package oswnd

import "core:fmt"
import "core:c"
import "vendor:glfw"

window_count := 0

Window :: struct {
    on_close: proc(window: ^Window),
    on_move: proc(window: ^Window, x, y: int),
    on_resize: proc(window: ^Window, width, height: int),
    on_mouse_move: proc(window: ^Window, x, y: int),
    on_mouse_press: proc(window: ^Window, button: Mouse_Button, x, y: int),
    on_mouse_release: proc(window: ^Window, button: Mouse_Button, x, y: int),
    on_mouse_wheel: proc(window: ^Window, x, y: f64),
    on_mouse_enter: proc(window: ^Window, x, y: int),
    on_mouse_exit: proc(window: ^Window, x, y: int),
    on_key_press: proc(window: ^Window, key: Keyboard_Key),
    on_key_release: proc(window: ^Window, key: Keyboard_Key),
    on_rune: proc(window: ^Window, r: rune),
    on_dpi_change: proc(window: ^Window, dpi: f64),
    _glfw_window: glfw.WindowHandle,
    _child_status: Child_Status,
}

create :: proc() -> ^Window {
    window := new(Window)
    if window_count == 0 {
        if glfw.Init() != 1 {
            fmt.eprintln("Failed to initialize GLFW")
            return nil
        }
        window_count += 1
    }
    glfw.WindowHint(glfw.RESIZABLE, 1)
    glfw.WindowHint(glfw.VISIBLE, 0)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    window._glfw_window = glfw.CreateWindow(512, 512, "", nil, nil)
    if window._glfw_window == nil {
        fmt.eprintln("Failed to create window")
    }
    return window
}

destroy :: proc(window: ^Window) {
    glfw.DestroyWindow(window._glfw_window)
    window_count -= 1
    if window_count == 0 {
        glfw.Terminate()
    }
}

poll_events :: proc() {
    glfw.PollEvents()
}

swap_buffers :: proc(window: ^Window) {
    glfw.SwapBuffers(window._glfw_window)
}

make_context_current :: proc(window: ^Window) {
    glfw.MakeContextCurrent(window._glfw_window)
}

// set_cursor_style :: proc(window: ^Window, style: Mouse_Cursor_Style) {}

cursor_position :: proc(window: ^Window) -> (x, y: f64) {
    return glfw.GetCursorPos(window._glfw_window)
}

set_cursor_position :: proc(window: ^Window, x, y: f64) {
    glfw.SetCursorPos(window._glfw_window, x, y)
}

position :: proc(window: ^Window) -> (x, y: int) {
    x_, y_ := glfw.GetWindowPos(window._glfw_window)
    return int(x_), int(y_)
}

set_position :: proc(window: ^Window, x, y: int) {
    glfw.SetWindowPos(window._glfw_window, c.int(x), c.int(y))
}

size :: proc(window: ^Window) -> (width, height: int) {
    width_, height_ := glfw.GetWindowSize(window._glfw_window)
    return int(width_), int(height_)
}

set_size :: proc(window: ^Window, width, height: int) {
    glfw.SetWindowSize(window._glfw_window, c.int(width), c.int(height))
}

set_decorated :: proc(window: ^Window, decorated: bool) {
    glfw.SetWindowAttrib(window._glfw_window, glfw.DECORATED, i32(decorated))
}

show :: proc(window: ^Window) {
    glfw.ShowWindow(window._glfw_window)
}

hide :: proc(window: ^Window) {
    glfw.HideWindow(window._glfw_window)
}

is_open :: proc(window: ^Window) -> bool {
    return glfw.WindowShouldClose(window._glfw_window) != glfw.TRUE
}

// _to_mouse_button :: proc(msg: win32.UINT, wparam: win32.WPARAM) -> Mouse_Button {}
// _to_keyboard_key :: proc(wparam: win32.WPARAM, lparam: win32.LPARAM) -> Keyboard_Key {}

gl_set_proc_address :: glfw.gl_set_proc_address

when ODIN_OS == .Windows {
    import win32 "core:sys/windows"

    foreign import user32 "system:User32.lib"
    @(default_calling_convention="stdcall")
    foreign user32 {
        SetParent :: proc(hWndChild, hWndNewParent: win32.HWND) ---
    }

    embed_inside_window :: proc(window: ^Window, parent: win32.HWND) {
        hwnd := glfw.GetWin32Window(window._glfw_window)
        if window._child_status != .Embedded {
            win32.SetWindowLongPtrW(hwnd, win32.GWL_STYLE, int(win32.WS_CHILDWINDOW | win32.WS_CLIPSIBLINGS))
            window._child_status = .Embedded
            set_decorated(window, false)
            x, y := position(window)
            width, height := size(window)
            win32.SetWindowPos(
                hwnd,
                win32.HWND_TOPMOST,
                i32(x), i32(y),
                i32(width), i32(height),
                win32.SWP_SHOWWINDOW,
            )
        }
        SetParent(hwnd, parent)
    }
}