package gl_helpers

import "core:fmt"
import gl "vendor:OpenGL"

Minify_Filter :: enum {
    Nearest,
    Linear,
    Nearest_Mipmap_Nearest,
    Linear_Mipmap_Nearest,
    Nearest_Mipmap_Linear,
    Linear_Mipmap_Linear,
}

Magnify_Filter :: enum {
    Nearest,
    Linear,
}

Wrap_Mode :: enum {
    Repeat,
    Clamp_To_Border,
    Clamp_To_Edge,
    Mirrored_Repeat,
    Mirror_Clamp_To_Edge,
}

Texture_Format :: enum {
    Rgba,
    Alpha,
}

Texture :: struct {
    id: u32,
    width: int,
    height: int,
}

texture_generate :: proc() -> (texture: Texture) {
    gl.GenTextures(1, &texture.id)
    texture_bind(&texture)
    texture_set_minify_filter(&texture, .Nearest)
    texture_set_magnify_filter(&texture, .Nearest)
    texture_set_wrap_s(&texture, .Repeat)
    texture_set_wrap_t(&texture, .Repeat)
    return
}

texture_delete :: proc(texture: ^Texture) {
    gl.DeleteTextures(1, &texture.id)
}

texture_bind :: proc(texture: ^Texture) {
    gl.BindTexture(gl.TEXTURE_2D, texture.id)
}

texture_set_minify_filter :: proc(texture: ^Texture, filter: Minify_Filter) {
    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, i32(filter))
}

texture_set_magnify_filter :: proc(texture: ^Texture, filter: Magnify_Filter) {
    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, i32(filter))
}

texture_set_wrap_s :: proc(texture: ^Texture, mode: Wrap_Mode) {
    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, i32(mode))
}

texture_set_wrap_t :: proc(texture: ^Texture, mode: Wrap_Mode) {
    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, i32(mode))
}

texture_set_wrap_r :: proc(texture: ^Texture, mode: Wrap_Mode) {
    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_R, i32(mode))
}

texture_generate_mipmap :: proc(texture: ^Texture) {
    texture_bind(texture)
    gl.GenerateMipmap(gl.TEXTURE_2D)
}

texture_upload_data :: proc(texture: ^Texture, format: Texture_Format, width, height: int, data: []u8) {
    texture.width = width
    texture.height = height
    texture_bind(texture)
    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        i32(_texture_format_to_gl_enum(format)),
        i32(width),
        i32(height),
        0,
        _texture_format_to_gl_enum(format),
        gl.UNSIGNED_BYTE,
        &data[0],
    )
}

texture_upload_sub_data :: proc(texture: ^Texture, format: Texture_Format, x, y, width, height: int, data: []u8) {
    texture_bind(texture)
    gl.TexSubImage2D(
        gl.TEXTURE_2D,
        0,
        i32(x),
        i32(y),
        i32(width),
        i32(height),
        _texture_format_to_gl_enum(format),
        gl.UNSIGNED_BYTE,
        &data[0],
    )
}

_minify_filter_to_gl_enum :: proc(minify_filter: Minify_Filter) -> (result: u32) {
    switch minify_filter {
    case .Nearest: result = gl.NEAREST
    case .Linear: result = gl.LINEAR
    case .Nearest_Mipmap_Nearest: result = gl.NEAREST_MIPMAP_NEAREST
    case .Linear_Mipmap_Nearest: result = gl.LINEAR_MIPMAP_NEAREST
    case .Nearest_Mipmap_Linear: result = gl.NEAREST_MIPMAP_LINEAR
    case .Linear_Mipmap_Linear: result = gl.LINEAR_MIPMAP_LINEAR
    }
    return
}

_magnify_filter_to_gl_enum :: proc(magnify_filter: Magnify_Filter) -> (result: u32) {
    switch magnify_filter {
    case .Nearest: result = gl.NEAREST
    case .Linear: result = gl.LINEAR
    }
    return
}

_wrap_mode_to_gl_enum :: proc(wrap_mode: Wrap_Mode) -> (result: u32) {
    switch wrap_mode {
    case .Repeat: result = gl.REPEAT
    case .Clamp_To_Border: result = gl.CLAMP_TO_BORDER
    case .Clamp_To_Edge: result = gl.CLAMP_TO_EDGE
    case .Mirrored_Repeat: result = gl.MIRRORED_REPEAT
    case .Mirror_Clamp_To_Edge: result = gl.MIRROR_CLAMP_TO_EDGE
    }
    return
}

_texture_format_to_gl_enum :: proc(texture_format: Texture_Format) -> (result: u32) {
    switch texture_format {
    case .Rgba: result = gl.RGBA
    case .Alpha: result = gl.ALPHA
    }
    return
}