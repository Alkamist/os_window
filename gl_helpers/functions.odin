package gl_helpers

import "core:fmt"
import gl "vendor:OpenGL"

draw_triangles :: proc(
    vertex_buffer: ^Vertex_Buffer($V),
    index_buffer: ^Index_Buffer($I),
    shader: ^Shader,
    texture: ^Texture = nil,
) {
    if texture != nil {
        texture_bind(texture)
    }
    shader_bind(shader)
    vertex_buffer_bind(vertex_buffer)
    index_buffer_bind(index_buffer)
    gl_type, _ := odin_type_to_index_type(I)
    gl.DrawElements(gl.TRIANGLES, i32(index_buffer.length), gl_type, nil)
}