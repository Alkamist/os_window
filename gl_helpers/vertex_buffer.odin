package gl_helpers

import "core:fmt"
import "core:intrinsics"
import "core:reflect"
import "core:runtime"
import gl "vendor:OpenGL"

Vertex_Buffer :: struct($V: typeid) where intrinsics.type_is_struct(V) {
    id: u32,
    length: int,
    capacity: int,
}

vertex_buffer_generate :: proc($V: typeid) -> (buffer: Vertex_Buffer(V)) {
    gl.GenBuffers(1, &buffer.id)

    vertex_buffer_bind(&buffer)

    vertex_size := i32(size_of(V))
    byte_offset := 0

    for attribute_type, i in reflect.struct_field_types(V) {
        gl.EnableVertexAttribArray(u32(i))

        #partial switch reflect.type_kind(attribute_type.id) {
        case .Array:
            gl_type, ok := odin_type_to_vertex_attribute_type(reflect.typeid_elem(attribute_type.id))
            if ok {
                gl.VertexAttribPointer(
                    u32(i), // the 0 based index of the attribute
                    i32(attribute_type.variant.(runtime.Type_Info_Array).count), // the number of values in the attribute
                    gl_type, // the type of value present in the attribute
                    gl.FALSE, // normalize the values from 0 to 1 on the gpu
                    vertex_size, // byte offset of each vertex
                    cast(uintptr)byte_offset, // byte offset of the start of the attribute, cast as a pointer
                )
                byte_offset += size_of(attribute_type.id)
            } else {
                fmt.eprintf("Invalid attribute type for vertex: (Index: %v, Type: %v)\n", i, attribute_type)
            }

        case .Float, .Integer, .Boolean:
            gl_type, ok := odin_type_to_vertex_attribute_type(attribute_type.id)
            if ok {
                gl.VertexAttribPointer(u32(i), 1, gl_type, gl.FALSE, vertex_size, cast(uintptr)byte_offset)
                byte_offset += size_of(attribute_type.id)
            } else {
                fmt.eprintf("Invalid attribute type for vertex: (Index: %v, Type: %v)\n", i, attribute_type)
            }

        case:
            fmt.eprintf("Invalid attribute type for vertex: (Index: %v, Type: %v)\n", i, attribute_type)
        }
    }

    return
}

vertex_buffer_delete :: proc(buffer: ^Vertex_Buffer($V)) {
    gl.DeleteBuffers(1, &buffer.id)
}

vertex_buffer_bind :: proc(buffer: ^Vertex_Buffer($V)) {
    gl.BindBuffer(gl.ARRAY_BUFFER, buffer.id)
}

vertex_buffer_unbind :: proc(buffer: ^Vertex_Buffer($V)) {
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
}

vertex_buffer_upload_data :: proc(buffer: ^Vertex_Buffer($V), data: []V) {
    buffer.length = len(data)
    if buffer.length == 0 {
        return
    }

    vertex_buffer_bind(buffer)

    if buffer.length > buffer.capacity {
        buffer.capacity = buffer.length
        gl.BufferData(gl.ARRAY_BUFFER, buffer.capacity * size_of(V), nil, gl.DYNAMIC_DRAW)
    }
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, buffer.length * size_of(V), &data[0])
}

odin_type_to_vertex_attribute_type :: proc(T: typeid) -> (result: u32, ok: bool) {
    if T == f32 do return gl.FLOAT, true
    if T == f64 do return gl.DOUBLE, true
    if T == i8 do return gl.BYTE, true
    if T == i16 do return gl.SHORT, true
    if T == i32 do return gl.INT, true
    if T == u8 do return gl.UNSIGNED_BYTE, true
    if T == u16 do return gl.UNSIGNED_SHORT, true
    if T == u32 do return gl.UNSIGNED_INT, true
    return
}