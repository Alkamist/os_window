package gl_helpers

import gl "vendor:OpenGL"

Index_Buffer :: struct($I: typeid)
    where I == u8 || I == u16 || I == u32  {
    id: u32,
    length: int,
    capacity: int,
}

index_buffer_generate :: proc($I: typeid) -> (buffer: Index_Buffer(I)) {
    gl.GenBuffers(1, &buffer.id)
    return
}

index_buffer_delete :: proc(buffer: ^Index_Buffer($I)) {
    gl.DeleteBuffers(1, &buffer.id)
}

index_buffer_bind :: proc(buffer: ^Index_Buffer($I)) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer.id)
}

index_buffer_unbind :: proc(buffer: ^Index_Buffer($I)) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
}

index_buffer_upload_data :: proc(buffer: ^Index_Buffer($I), data: []I) {
    buffer.length = len(data)
    if buffer.length == 0 {
        return
    }

    index_buffer_bind(buffer)

    if buffer.length > buffer.capacity {
        buffer.capacity = buffer.length
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, buffer.capacity * size_of(I), nil, gl.DYNAMIC_DRAW)
    }
    gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, buffer.length * size_of(I), &data[0])
}

odin_type_to_index_type :: proc(T: typeid) -> (result: u32, ok: bool) {
    if T == u8 do return gl.UNSIGNED_BYTE, true
    if T == u16 do return gl.UNSIGNED_SHORT, true
    if T == u32 do return gl.UNSIGNED_INT, true
    return
}