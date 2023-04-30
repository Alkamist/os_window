package microui_renderer

import "core:fmt"
import "core:mem"
import "core:strings"
import mu "vendor:microui"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

MAX_QUADS :: 8192

atlas_id: u32
shader_id: u32
uniforms: gl.Uniforms

Vertex :: struct {
    position: [2]f32,
    // uv: [2]f32,
    color: [4]f32,
}

Microui_Renderer :: struct {
    width: int,
    height: int,
    write_index: int,
    vao: u32,
    vbo: u32,
    ebo: u32,
    vertices: [MAX_QUADS * 4]Vertex,
    indices: [MAX_QUADS * 6]u16,
}

init :: proc() {
    gl.GenTextures(1, &atlas_id)
    gl.BindTexture(gl.TEXTURE_2D, atlas_id)
    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.ALPHA,
        mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT,
        0,
        gl.ALPHA,
        gl.UNSIGNED_BYTE,
        &mu.default_atlas_alpha[0],
    )
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

    compiled_ok: bool
    shader_id, compiled_ok = gl.load_shaders_source(VERTEX_SOURCE, FRAGMENT_SOURCE)
	if !compiled_ok {
		fmt.eprintln("Failed to compile shader")
		return
	}

    uniforms = gl.get_uniforms_from_program(shader_id)
}

shutdown :: proc() {
    gl.DeleteTextures(1, &atlas_id)
    gl.DeleteProgram(shader_id)
    delete(uniforms)
}

setup_gl_state :: proc() {
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Disable(gl.CULL_FACE)
    gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.SCISSOR_TEST)
    gl.Enable(gl.TEXTURE_2D)
}

make :: proc() -> ^Microui_Renderer {
    renderer := new(Microui_Renderer)

    gl.GenVertexArrays(1, &renderer.vao)
    gl.GenBuffers(1, &renderer.vbo)
    gl.GenBuffers(1, &renderer.ebo)

    gl.BindBuffer(gl.ARRAY_BUFFER, renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(renderer.vertices) * size_of(renderer.vertices[0]), &renderer.vertices[0], gl.DYNAMIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    // gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))
    gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, renderer.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(renderer.indices) * size_of(renderer.indices[0]), &renderer.indices[0], gl.DYNAMIC_DRAW)

    return renderer
}

destroy :: proc(renderer: ^Microui_Renderer) {
    gl.DeleteVertexArrays(1, &renderer.vao)
    gl.DeleteBuffers(1, &renderer.vbo)
    gl.DeleteBuffers(1, &renderer.ebo)
    free(renderer)
}

flush :: proc(renderer: ^Microui_Renderer) {
    if renderer.write_index == 0 {
        return
    }

    gl.Viewport(0, 0, i32(renderer.width), i32(renderer.height))
    gl.UseProgram(shader_id)
    gl.BindTexture(gl.TEXTURE_2D, atlas_id)
    gl.BindBuffer(gl.ARRAY_BUFFER, renderer.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, renderer.ebo)

    // projection_matrix := glm.mat4Ortho3d(0.0, f32(renderer.width), f32(renderer.height), 0.0, -1.0, 1.0)
    // gl.UniformMatrix4fv(uniforms["ProjMtx"].location, 1, false, &projection_matrix[0, 0])

    gl.DrawElements(gl.TRIANGLES, i32(renderer.write_index + 1), gl.UNSIGNED_SHORT, nil)

    renderer.write_index = 0
}

push_quad :: proc(renderer: ^Microui_Renderer, rect, uv_rect: mu.Rect, color: mu.Color) {
    if renderer.write_index == MAX_QUADS {
        flush(renderer)
    }

    pos_left := f32(rect.x)
    pos_right := pos_left + f32(rect.w)
    pos_top := f32(rect.y)
    pos_bottom := pos_top + f32(rect.h)

    tex_left := f32(uv_rect.x) / f32(mu.DEFAULT_ATLAS_WIDTH)
    tex_right := tex_left + f32(uv_rect.w) / f32(mu.DEFAULT_ATLAS_WIDTH)
    tex_top := f32(uv_rect.y) / f32(mu.DEFAULT_ATLAS_WIDTH)
    tex_bottom := tex_top + f32(uv_rect.h) / f32(mu.DEFAULT_ATLAS_WIDTH)

    color := [4]f32{
        f32(color.r) / 255.0,
        f32(color.g) / 255.0,
        f32(color.b) / 255.0,
        f32(color.a) / 255.0,
    }

    v_tl := Vertex{
        position = {pos_left, pos_top},
        // uv = {tex_left, tex_top},
        color = color,
    }
    v_tr := Vertex{
        position = {pos_right, pos_top},
        // uv = {tex_right, tex_top},
        color = color,
    }
    v_bl := Vertex{
        position = {pos_left, pos_bottom},
        // uv = {tex_left, tex_bottom},
        color = color,
    }
    v_br := Vertex{
        position = {pos_right, pos_bottom},
        // uv = {tex_right, tex_bottom},
        color = color,
    }

    vertex_index := renderer.write_index * 4
    index_index := renderer.write_index * 6

    renderer.vertices[vertex_index + 0] = v_tl
    renderer.vertices[vertex_index + 1] = v_tr
    renderer.vertices[vertex_index + 2] = v_bl
    renderer.vertices[vertex_index + 3] = v_br

    renderer.indices[index_index + 0] = u16(vertex_index + 0)
    renderer.indices[index_index + 1] = u16(vertex_index + 1)
    renderer.indices[index_index + 2] = u16(vertex_index + 2)
    renderer.indices[index_index + 3] = u16(vertex_index + 2)
    renderer.indices[index_index + 4] = u16(vertex_index + 3)
    renderer.indices[index_index + 5] = u16(vertex_index + 1)
}

draw_rect :: proc(renderer: ^Microui_Renderer, rect: mu.Rect, color: mu.Color) {
    push_quad(renderer, rect, mu.default_atlas[mu.DEFAULT_ATLAS_WHITE], color)
}

// draw_text :: proc(renderer: ^Microui_Renderer, text: string, pos: mu.Vec2, color: mu.Color) {
//     dst := mu.Rect{ pos.x, pos.y, 0, 0 }
//     for c in text {
//         if (c & 0xc0) == 0x80 {
//             continue
//         }
//         chr := min(int(c), 127)
//         src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + chr]
//         dst.w = src.w
//         dst.h = src.h
//         push_quad(renderer, dst, src, color)
//         dst.x += dst.w
//     }
// }

// draw_icon :: proc(renderer: ^Microui_Renderer, id: int, rect: mu.Rect, color: mu.Color) {
//     src := mu.default_atlas[id]
//     x := rect.x + (rect.w - src.w) / 2
//     y := rect.y + (rect.h - src.h) / 2
//     push_quad(renderer, mu.Rect{x, y, src.w, src.h}, src, color)
// }

// get_text_width :: proc(renderer: ^Microui_Renderer, text: string) -> (result: int) {
//     for c in text {
//         if (c & 0xc0) == 0x80 {
//             continue
//         }
//         chr := min(int(c), 127)
//         result += int(mu.default_atlas[mu.DEFAULT_ATLAS_FONT + chr].w)
//     }
//     return
// }

// get_text_height :: proc(renderer: ^Microui_Renderer) -> int {
//     return 18
// }

// set_clip_rect :: proc(renderer: ^Microui_Renderer, rect: mu.Rect) {
//     flush(renderer)
//     gl.Scissor(rect.x, i32(renderer.height) - (rect.y + rect.h), rect.w, rect.h)
// }

// clear :: proc(renderer: ^Microui_Renderer, color: mu.Color) {
//     flush(renderer)
//     gl.ClearColor(f32(color.r) / 255.0, f32(color.g) / 255.0, f32(color.b) / 255.0, f32(color.a) / 255.0)
//     gl.Clear(gl.COLOR_BUFFER_BIT)
// }

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
// uniform mat4 ProjMtx;
// layout(location=0) in vec2 Position;
// layout(location=1) in vec2 UV;
// layout(location=2) in vec4 Color;
// out vec2 Frag_UV;
// out vec4 Frag_Color;
// void main() {
//     Frag_UV = UV;
//     Frag_Color = Color;
//     gl_Position = ProjMtx * vec4(Position.xy, 0, 1);
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