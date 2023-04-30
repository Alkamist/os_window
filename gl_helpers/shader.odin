package gl_helpers

import "core:fmt"
import gl "vendor:OpenGL"

Shader :: struct {
    id: u32,
}

shader_generate :: proc(vertex_src, fragment_src: string) -> (shader: Shader) {
    shader_id, compiled_ok := gl.load_shaders_source(vertex_src, fragment_src)
	if !compiled_ok {
		fmt.eprintln("Failed to compile shader")
		return
	}
    shader.id = shader_id
    return
}

shader_delete :: proc(shader: ^Shader) {
    gl.DeleteProgram(shader.id)
}

shader_bind :: proc(shader: ^Shader) {
    gl.UseProgram(shader.id)
}