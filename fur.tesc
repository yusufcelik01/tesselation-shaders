#version 460 core

uniform mat4 modelingMatrix;
uniform mat4 viewingMatrix;
uniform mat4 projectionMatrix;

uniform float tessInner;
uniform float tessOuter;

layout (vertices = 3) out;

in VS_TESC_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tesc_in[];

out TESC_TESE_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tesc_out[];


void main()
{
    gl_TessLevelOuter[0] = tessOuter;
    gl_TessLevelOuter[1] = tessOuter;
    gl_TessLevelOuter[2] = tessOuter;
    gl_TessLevelInner[0] = tessInner;
    //gl_TessLevelOuter[0] = 6;
    //gl_TessLevelOuter[1] = 6;

    //shrink triangles
    vec4 mid = ( tesc_in[0].fragWorldPos +
                 tesc_in[1].fragWorldPos +
                 tesc_in[2].fragWorldPos ) / 3.f;
    


    tesc_out[gl_InvocationID].fragWorldPos = tesc_in[gl_InvocationID].fragWorldPos;
    tesc_out[gl_InvocationID].fragWorldNor = tesc_in[gl_InvocationID].fragWorldNor;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;

    //tesc_out[gl_InvocationID].fragWorldPos= mix(tesc_in[gl_InvocationID].fragWorldPos, mid, 0.25);
    //mid = ( gl_in[0].gl_Position +
    //        gl_in[1].gl_Position +
    //        gl_in[2].gl_Position ) / 3.f;
    //gl_out[gl_InvocationID].gl_Position = mix(gl_in[gl_InvocationID].gl_Position, mid, 0.25);
    
}
