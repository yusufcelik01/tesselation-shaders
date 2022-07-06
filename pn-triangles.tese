#version 460 core

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
    //float tessInner;
    //float tessOuter;
    //float levelOfDetail;
};

layout (std140, binding = 1) uniform tessLevels
{
    float tessInner;
    float tessOuter;
    float levelOfDetail;
    int viewDependantTesselation;
};

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

precise tese_out;

struct Vertex 
{
    vec4 coord;
    vec3 normal;
};
struct Triangle 
{
    struct Vertex vert[3];
};


vec3 triangleNormal(vec3 t0, vec3 t1, vec3 t2);
struct Vertex hairVertex(int hairID, struct Triangle triangle);

void main()
{
    float u = gl_TessCoord.x,
          v = gl_TessCoord.y,
          w = gl_TessCoord.z;

    vec3 p0 = tese_in[0].fragWorldPos.xyz,
         p1 = tese_in[1].fragWorldPos.xyz, 
         p2 = tese_in[2].fragWorldPos.xyz; 

    vec3 n0 = normalize(tese_in[0].fragWorldNor),
         n1 = normalize(tese_in[1].fragWorldNor), 
         n2 = normalize(tese_in[2].fragWorldNor); 

    vec3 b300 = p0,
         b030 = p1,
         b003 = p2;

    float wNorms[3][3];

    for(int i=0; i < 3; i++)
    {
        for(int j=0; j < 3; j++)
        {
            wNorms[i][j] = dot(tese_in[j].fragWorldPos.xyz - tese_in[i].fragWorldPos.xyz, tese_in[i].fragWorldNor);
        }
    }

    vec3 b210 = (2*p0 + p1 - wNorms[0][1] * n0)/3.0,
         b120 = (2*p1 + p0 - wNorms[1][0] * n1)/3.0,
         b021 = (2*p1 + p2 - wNorms[1][2] * n1)/3.0,
         b012 = (2*p2 + p1 - wNorms[2][1] * n2)/3.0,
         b102 = (2*p2 + p0 - wNorms[2][0] * n2)/3.0,
         b201 = (2*p0 + p2 - wNorms[0][2] * n0)/3.0;

    vec3 E = (b210 + b120 + b021 + b012 + b102 + b201)/ 6.0;
    vec3 V = (p0 + p1 + p2)/3.0;

    vec3 b111 = E + (E - V) / 2.0;
    
    //calculate normal coefficients
    vec3 n200 = n0,
         n020 = n1,
         n002 = n2;
    
    float v01 = 2 * dot(p1 - p0, n0 + n1) / dot(p1 - p0, p1 - p0),
          v12 = 2 * dot(p2 - p1, n1 + n2) / dot(p2 - p1, p2 - p1), 
          v20 = 2 * dot(p0 - p2, n2 + n0) / dot(p0 - p2, p0 - p2); 

    vec3 n110 = normalize(n0 + n1 - v01 * (p1 - p0)),
         n011 = normalize(n1 + n2 - v12 * (p2 - p1)),
         n101 = normalize(n2 + n0 - v20 * (p0 - p2));

   
    tese_out.fragWorldPos = vec4( b300*w*w*w   + b030*u*u*u   + b003*v*v*v   +
                                  b210*3*w*w*u + b120*3*w*u*u + b201*3*w*w*v +
                                  b021*3*u*u*v + b102*3*w*v*v + b012*3*u*v*v +
                                  b111*6*w*u*v
                                  ,1.0);

    tese_out.fragWorldNor = n200*w*w + n020*u*u + n002*v*v + 
                            n110*w*u + n011*u*v + n101*w*v;

    //TODO set fragWorldPos
    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix *
                        tese_out.fragWorldPos;
}


vec3 triangleNormal(vec3 t0, vec3 t1, vec3 t2)
{
    return normalize(cross(t1-t0, t2-t1));
}

