#version 460 core

layout (vertices = 1) out;

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
};

layout (std140, binding = 1) uniform tessLevels
{
    float tessInner;
    float tessOuter;
    float levelOfDetail;
};


in VS_TESC_INTERFACE
{
    vec4 pointWorldCoord;
} tesc_in[];

out TESC_TESE_INTERFACE
{
    vec4 pointWorldCoord;
}tesc_out[];

void main(void)
{
    gl_TessLevelOuter[0] = tessOuter * levelOfDetail;
    gl_TessLevelOuter[1] = tessOuter * levelOfDetail;
    gl_TessLevelOuter[2] = tessOuter * levelOfDetail;
    gl_TessLevelOuter[3] = tessOuter * levelOfDetail;
    gl_TessLevelInner[0] = tessInner * levelOfDetail;
    gl_TessLevelInner[1] = tessInner * levelOfDetail;


    tesc_out[gl_InvocationID].pointWorldCoord = tesc_in[gl_InvocationID].pointWorldCoord;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}
