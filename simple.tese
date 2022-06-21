#version 460 core

uniform mat4 modelingMatrix;
uniform mat4 viewingMatrix;
uniform mat4 projectionMatrix;

layout ( triangles, equal_spacing, ccw) in;


in TESC_TESE_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tese_in[];

out TESE_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tese_out;

void main()
{
    vec4 p0 = tese_in[0].fragWorldPos;
    vec4 p1 = tese_in[1].fragWorldPos;
    vec4 p2 = tese_in[2].fragWorldPos;
    
    vec3 n0 = tese_in[0].fragWorldNor;
    vec3 n1 = tese_in[1].fragWorldNor;
    vec3 n2 = tese_in[2].fragWorldNor;

    float u = gl_TessCoord.x,
          v = gl_TessCoord.y,
          w = gl_TessCoord.z;


    gl_Position = u * gl_in[0].gl_Position + 
                  v * gl_in[1].gl_Position +
                  w * gl_in[2].gl_Position;

    tese_out.fragWorldPos = u * tese_in[0].fragWorldPos +
                            v * tese_in[1].fragWorldPos +
                            w * tese_in[2].fragWorldPos;

    tese_out.fragWorldNor = u * tese_in[0].fragWorldNor +
                            v * tese_in[1].fragWorldNor +
                            w * tese_in[2].fragWorldNor;

}
