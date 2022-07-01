#version 460 core

layout ( quads, equal_spacing, ccw) in;

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
};

uniform sampler2D cobbleStoneBumpMap;

in TESC_TESE_INTERFACE
{
    vec4 pointWorldCoord;
}tese_in[];

out TESE_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
    vec2 fragTex;
} tese_out;

void main(void)
{
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    tese_out.fragTex = vec2(u, v);

    vec4 bl = tese_in[0].pointWorldCoord;
    vec4 br = bl;
    br.x = -br.x;
    vec4 tl = bl;
    tl.z = -tl.z;
    vec4 tr = tl;
    tr.x = -tr.x;

    tese_out.fragWorldPos = mix(mix(bl, br, u),
                                mix(tl, tr, u), v);
    tese_out.fragWorldNor = vec3(0.f, 1.f, 0.f);
    //tese_out.fragWorldNor = texture(cobbleStoneBumpMap, vec2(u,v)).xyz;
    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * tese_out.fragWorldPos;
}
