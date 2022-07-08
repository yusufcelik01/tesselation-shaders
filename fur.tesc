#version 460 core

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
    int viewDependantTesselation;
    float cameraFov;
};

layout (std140, binding = 2) uniform hairParams
{
    float hairLen;
    float hairDetail;
    float hairCurveAngle;
    uint hairCount;
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
    {//meaning the triangle vertices are not visible
     //but its edges may be
        gl_TessLevelOuter[0] = 1.f;
        gl_TessLevelOuter[1] = 1.f;
    }
    if(viewDependantTesselation == 1)
    {
        precise float zoomScale =  90.f/cameraFov;
        
        vec4 avg = vec4(0, 0, 0, 0);
        avg += tesc_in[0].fragWorldPos;
        avg += tesc_in[1].fragWorldPos;
        avg += tesc_in[2].fragWorldPos;
        avg = avg/3.f;
        precise float d = distance(avg, vec4(eyePos, 1.f));
        precise float viewLOD = 40/(d*d) * zoomScale;
        gl_TessLevelOuter[0] = float(hairCount);
        gl_TessLevelOuter[1] = hairDetail * levelOfDetail * viewLOD;

    }
    else
    {
        gl_TessLevelOuter[0] = float(hairCount);
        gl_TessLevelOuter[1] = hairDetail * levelOfDetail;
    }


    tesc_out[gl_InvocationID].fragWorldPos = tesc_in[gl_InvocationID].fragWorldPos;
    tesc_out[gl_InvocationID].fragWorldNor = tesc_in[gl_InvocationID].fragWorldNor;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
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
