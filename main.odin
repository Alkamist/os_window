package main

import "core:unicode/utf8"
import "core:fmt"
import gl "vendor:OpenGL"
import mu "vendor:microui"
import wnd "os_window"
import r "microui_renderer"

main :: proc() {
    window := wnd.create()
    defer wnd.destroy(window)

    wnd.show(window)
    wnd.make_context_current(window)

    gl.load_up_to(3, 3, wnd.gl_set_proc_address)

	ctx: mu.Context
    mu.init(&ctx)
    ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	bind_window_input_to_mu_input(window, &ctx)

	r.init()
    defer r.shutdown()

	renderer := r.create()
    defer r.destroy(renderer)

    for wnd.is_open(window) {
        wnd.poll_events(window)

		r.setup_gl_state()

        width, height := wnd.size(window)
		renderer.width = width
        renderer.height = height

        gl.Viewport(0, 0, i32(width), i32(height))
		gl.Scissor(0, 0, i32(width), i32(height))
        gl.ClearColor(0.2, 0.2, 0.2, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

		mu.begin(&ctx)
        all_windows(&ctx)
        mu.end(&ctx)

		r.process_microui_commands(renderer, &ctx)
		r.flush(renderer)

        wnd.swap_buffers(window)
    }
}

to_mu_mouse_button :: proc(button: wnd.Mouse_Button) -> (res: mu.Mouse, ok: bool) {
	#partial switch button {
	case .Left: return .LEFT, true
	case .Right: return .RIGHT, true
	case .Middle: return .MIDDLE, true
	}
	return
}

to_mu_key :: proc(button: wnd.Keyboard_Key) -> (res: mu.Key, ok: bool) {
	#partial switch button {
	case .Left_Shift, .Right_Shift: return .SHIFT, true
	case .Left_Control, .Right_Control: return .CTRL, true
	case .Left_Alt, .Right_Alt: return .ALT, true
	case .Backspace: return .BACKSPACE, true
	case .Enter: return .RETURN, true
	}
	return
}

bind_window_input_to_mu_input :: proc(window: ^wnd.Window, ctx: ^mu.Context) {
	window.user_ptr = ctx
    window.on_mouse_move = proc(window: ^wnd.Window, x, y: int) {
		ctx := (^mu.Context)(window.user_ptr)
        mu.input_mouse_move(ctx, i32(x), i32(y))
    }
    window.on_mouse_press = proc(window: ^wnd.Window, button: wnd.Mouse_Button, x, y: int) {
        ctx := (^mu.Context)(window.user_ptr)
		if mu_button, ok := to_mu_mouse_button(button); ok {
			mu.input_mouse_down(ctx, i32(x), i32(y), mu_button)
		}
    }
	window.on_mouse_release = proc(window: ^wnd.Window, button: wnd.Mouse_Button, x, y: int) {
        ctx := (^mu.Context)(window.user_ptr)
		if mu_button, ok := to_mu_mouse_button(button); ok {
			mu.input_mouse_up(ctx, i32(x), i32(y), mu_button)
		}
    }
	window.on_mouse_wheel = proc(window: ^wnd.Window, x, y: f64) {
		ctx := (^mu.Context)(window.user_ptr)
		mu.input_scroll(ctx, i32(x), i32(y))
	}
	window.on_key_press = proc(window: ^wnd.Window, key: wnd.Keyboard_Key) {
		ctx := (^mu.Context)(window.user_ptr)
		if mu_key, ok := to_mu_key(key); ok {
			mu.input_key_down(ctx, mu_key)
		}
	}
	window.on_key_release = proc(window: ^wnd.Window, key: wnd.Keyboard_Key) {
		ctx := (^mu.Context)(window.user_ptr)
		if mu_key, ok := to_mu_key(key); ok {
			mu.input_key_up(ctx, mu_key)
		}
	}
	window.on_rune = proc(window: ^wnd.Window, r: rune) {
		ctx := (^mu.Context)(window.user_ptr)
		bytes, count := utf8.encode_rune(r)
		mu.input_text(ctx, string(bytes[:count]))
	}
}

u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) {
	mu.push_id(ctx, uintptr(val))

	@static tmp: mu.Real
	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	mu.pop_id(ctx)
	return
}

all_windows :: proc(ctx: ^mu.Context) {
	@static opts := mu.Options{.NO_CLOSE}

	if mu.window(ctx, "Demo Window", {40, 40, 300, 450}, opts) {
		if .ACTIVE in mu.header(ctx, "Window Info") {
			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}

		if .ACTIVE in mu.header(ctx, "Window Options") {
			mu.layout_row(ctx, {120, 120, 120}, 0)
			for opt in mu.Opt {
				state := opt in opts
				if .CHANGE in mu.checkbox(ctx, fmt.tprintf("%v", opt), &state)  {
					if state {
						opts += {opt}
					} else {
						opts -= {opt}
					}
				}
			}
		}

		if .ACTIVE in mu.header(ctx, "Test Buttons", {.EXPANDED}) {
			mu.layout_row(ctx, {86, -110, -1})
			mu.label(ctx, "Test buttons 1:")
			if .SUBMIT in mu.button(ctx, "Button 1") { }
			if .SUBMIT in mu.button(ctx, "Button 2") { }
			mu.label(ctx, "Test buttons 2:")
			if .SUBMIT in mu.button(ctx, "Button 3") { }
			if .SUBMIT in mu.button(ctx, "Button 4") { }
		}

		if .ACTIVE in mu.header(ctx, "Tree and Text", {.EXPANDED}) {
			mu.layout_row(ctx, {140, -1})
			mu.layout_begin_column(ctx)
			if .ACTIVE in mu.treenode(ctx, "Test 1") {
				if .ACTIVE in mu.treenode(ctx, "Test 1a") {
					mu.label(ctx, "Hello")
					mu.label(ctx, "world")
				}
				if .ACTIVE in mu.treenode(ctx, "Test 1b") {
					if .SUBMIT in mu.button(ctx, "Button 1") { }
					if .SUBMIT in mu.button(ctx, "Button 2") { }
				}
			}
			if .ACTIVE in mu.treenode(ctx, "Test 2") {
				mu.layout_row(ctx, {53, 53})
				if .SUBMIT in mu.button(ctx, "Button 3") { }
				if .SUBMIT in mu.button(ctx, "Button 4") { }
				if .SUBMIT in mu.button(ctx, "Button 5") { }
				if .SUBMIT in mu.button(ctx, "Button 6") { }
			}
			if .ACTIVE in mu.treenode(ctx, "Test 3") {
				@static checks := [3]bool{true, false, true}
				mu.checkbox(ctx, "Checkbox 1", &checks[0])
				mu.checkbox(ctx, "Checkbox 2", &checks[1])
				mu.checkbox(ctx, "Checkbox 3", &checks[2])

			}
			mu.layout_end_column(ctx)

			mu.layout_begin_column(ctx)
			mu.layout_row(ctx, {-1})
			mu.text(ctx,
				"Lorem ipsum dolor sit amet, consectetur adipiscing "+
				"elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus "+
				"ipsum, eu varius magna felis a nulla.",
		        )
			mu.layout_end_column(ctx)
		}
	}

	if mu.window(ctx, "Style Window", {350, 250, 300, 240}) {
		@static colors := [mu.Color_Type]string{
			.TEXT         = "text",
			.BORDER       = "border",
			.WINDOW_BG    = "window bg",
			.TITLE_BG     = "title bg",
			.TITLE_TEXT   = "title text",
			.PANEL_BG     = "panel bg",
			.BUTTON       = "button",
			.BUTTON_HOVER = "button hover",
			.BUTTON_FOCUS = "button focus",
			.BASE         = "base",
			.BASE_HOVER   = "base hover",
			.BASE_FOCUS   = "base focus",
			.SCROLL_BASE  = "scroll base",
			.SCROLL_THUMB = "scroll thumb",
		}

		sw := i32(f32(mu.get_current_container(ctx).body.w) * 0.14)
		mu.layout_row(ctx, {80, sw, sw, sw, sw, -1})
		for label, col in colors {
			mu.label(ctx, label)
			u8_slider(ctx, &ctx.style.colors[col].r, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].g, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].b, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].a, 0, 255)
			mu.draw_rect(ctx, mu.layout_next(ctx), ctx.style.colors[col])
		}
	}
}