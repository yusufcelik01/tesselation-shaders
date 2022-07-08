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


layout (vertices = 16) out;

in VS_TESC_INTERFACE
{
    vec3 fragWorldPos;
} tesc_in[];

out TESC_TESE_INTERFACE
{
    vec3 fragWorldPos;
} tesc_out[];

bool isVisible(vec4 p);
float getLOD(vec4 p0, vec4 p1);

float LOD = 1.0f * levelOfDetail;

void main()
{
    if(viewDependantTesselation == 0)
    {
        gl_TessLevelOuter[0] = tessOuter * LOD;
        gl_TessLevelOuter[1] = tessOuter * LOD;
        gl_TessLevelOuter[2] = tessOuter * LOD;
        gl_TessLevelOuter[3] = tessOuter * LOD;

        gl_TessLevelInner[0] = tessInner * LOD;
        gl_TessLevelInner[1] = tessInner * LOD;
    }
    else
    {
        gl_TessLevelOuter[0] = LOD * getLOD(vec4(tesc_in[0].fragWorldPos, 1.f), 
                                            vec4(tesc_in[3].fragWorldPos, 1.f));
        gl_TessLevelOuter[1] = LOD * getLOD(vec4(tesc_in[0].fragWorldPos, 1.f),
                                            vec4(tesc_in[12].fragWorldPos, 1.f));
        gl_TessLevelOuter[2] = LOD * getLOD(vec4(tesc_in[12].fragWorldPos, 1.f), 
                                            vec4(tesc_in[15].fragWorldPos, 1.f));
        gl_TessLevelOuter[3] = LOD * getLOD(vec4(tesc_in[3].fragWorldPos, 1.f),
                                            vec4(tesc_in[15].fragWorldPos, 1.f));

        gl_TessLevelInner[0] = (gl_TessLevelOuter[1] + gl_TessLevelOuter[3])/2.f;
        gl_TessLevelInner[1] = (gl_TessLevelOuter[0] + gl_TessLevelOuter[2])/2.f;
    }


    tesc_out[gl_InvocationID].fragWorldPos = tesc_in[gl_InvocationID].fragWorldPos;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}

float getLOD(vec4 p0, vec4 p1)
{
    precise float d1 = distance( (p0 + p1)/2.f, vec4(eyePos, 1.f));

    precise float zoomScale =  90.f/cameraFov;

    return ceil(40.f/(d1*d1)) * zoomScale;
}

