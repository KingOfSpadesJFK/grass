#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer GrassDataBuffer {
    vec2 size;
}
grass_data_buffer;

layout(set = 1, binding = 0, std430) restrict buffer GrassOutBuffer {
    vec4 positions[];
}
grass_out_buffer;

// Initialize the positions of the grass blades
void main() {
    vec4 pos = vec4(float(gl_GlobalInvocationID.x), 0.0, float(gl_GlobalInvocationID.y), 0.0);
    vec4 density = vec4(float(gl_NumWorkGroups.x), 1.0, float(gl_NumWorkGroups.y), 1.0);
    vec4 size = vec4(grass_data_buffer.size.x, 1.0, grass_data_buffer.size.y, 0.0);
    uint index = gl_GlobalInvocationID.x * gl_NumWorkGroups.y + gl_GlobalInvocationID.y;
    
    grass_out_buffer.positions[index] = size * (pos / density - 0.5);
}