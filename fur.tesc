#version 460 core

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
    float tessInner;
    float tessOuter;
};


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

bool isVisible(vec4 p);

void main()
{
    if( !isVisible(gl_in[0].gl_Position) &&
        !isVisible(gl_in[1].gl_Position) &&
        !isVisible(gl_in[2].gl_Position)   )
    {//meaning the triangle is not visible
        gl_TessLevelOuter[0] = 0.f;
        gl_TessLevelOuter[1] = 0.f;
        gl_TessLevelOuter[2] = 0.f;
        gl_TessLevelInner[0] = 0.f;
        return;
    }
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

/*
   this function takes a point in the canonical viewing volume 
   and returns true if this point is visible by the eye
   return false if it is not visible
*/
bool isVisible(vec4 p)
{//check if the point
    if( p.x > p.w || p.x < -p.w ||
        p.y > p.w || p.y < -p.w ||
        p.z > p.w || p.z < -p.w   )
    {
        return false;
    }
    else
    {
        return true;
    }
}
