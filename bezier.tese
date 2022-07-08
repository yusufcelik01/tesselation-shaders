#version 460 core

#define M_PI 3.1415926535897932384626433832795
#define EPSILON 1e-2


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

layout ( quads, equal_spacing, cw) in;


in TESC_TESE_INTERFACE
{
    vec3 fragWorldPos;
} tese_in[];

out TESE_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
    vec2 texCoord;
} tese_out;


float bern(int i, float u);

void main()
{
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;

    tese_out.texCoord = vec2(u,v);
        
    vec3 vert = vec3(0.f, 0.f, 0.f);

    for(int i = 0; i <= 3; ++i)
    {
        for(int j = 0; j <= 3; ++j)
        {
            vert += bern(i, u) * bern(j, v) * tese_in[i*4 + j].fragWorldPos;
        }
    }

    vec3 du = vec3(0.f, 0.f, 0.f);
    vec3 dv = vec3(0.f, 0.f, 0.f);
    int dir = 1;

    float e1 = EPSILON;
    float e2 = EPSILON;
    if(u > 0.5){ e1 = -e1; dir = -dir;}
    if(v > 0.5){ e2 = -e2; dir = -dir;}


    for(int i = 0; i <= 3; ++i)
    {
        for(int j = 0; j <= 3; ++j)
        {
            du += bern(i, u+ e1/2.0) * bern(j, v+e2/3.0) * tese_in[i*4 + j].fragWorldPos;
            dv += bern(i, u+ e1/3.0) * bern(j, v+e2/2.0) * tese_in[i*4 + j].fragWorldPos;
        }
    }
    
    //vert = mix(mix(tese_in[0 ].fragWorldPos, tese_in[3 ].fragWorldPos, u),
    //           mix(tese_in[12].fragWorldPos, tese_in[15].fragWorldPos, u), v);

    //
    //vert = mix(mix(tese_in[0 ].fragWorldPos, tese_in[3 ].fragWorldPos, u),
    //           mix(tese_in[8 ].fragWorldPos, tese_in[11].fragWorldPos, u), v);
    tese_out.fragWorldPos = vec4(vert,1);
    tese_out.fragWorldNor = cross(dv-vert, du-vert) *dir;

    gl_Position = projectionMatrix * viewingMatrix * tese_out.fragWorldPos;
}


int factorial(int x)
{
    if(x < 2)
    {
        return 1;
    }
    int acc = 1;
    while(x > 1)
    {
        acc *= x;
        x--;
    }
    return acc;
}


int combination(int n, int m)
{
    return factorial(n)/(factorial(m)*factorial(n-m));
}


float bern(int i, float u)
{
// Binomial lookup table
    const float bc[4] = {1.f, 3.f, 3.f, 1.f};
    return bc[i] * pow(u, i) * pow(1-u, 3-i);
}
