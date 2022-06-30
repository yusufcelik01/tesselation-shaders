#version 460 core

layout( points ) in;
layout(triangle_strip, max_vertices = 6) out;

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    float terrainSpan;
    uint vertexCount;
    float noiseScale;
};

in VS_GS_INTERFACE
{
    vec4 pointWorldCoord;
} gs_in[];

out GS_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
}gs_out;


int coords[4][2] = {
    {0,  0},
    {0,  1},
    {1,  0},
    {1,  1},
};

vec3 gradients[16] = {
    vec3(1, 1, 0),
    vec3(-1, 1, 0),
    vec3(1, -1, 0),
    vec3(-1, -1, 0),
    vec3(1, 0, 1),
    vec3(-1, 0, 1),
    vec3(1, 0, -1),
    vec3(-1, 0, -1),
    vec3(0, 1, 1),
    vec3(0, -1, 1),
    vec3(0, 1, -1),
    vec3(0, -1, -1),
    vec3(1, 1, 0),
    vec3(-1, 1, 0),
    vec3(0, -1, 1),
    vec3(0, -1, -1)
};

int table[16] = {
    14, 8, 9, 7, 5, 13, 4, 0, 12, 2, 3, 11, 6, 15, 10, 1
};

float perlinNoise(vec3);
float perlin3(vec3 texCoords);

void main(void)
{
    float cellSize = terrainSpan * 2 / vertexCount;

    int i, j, k;
    gs_out.fragWorldNor = vec3(0.0f, 1.f, 0.0f);
    for(k = 0; k < 4; k++)
    {
        float noiseVal;
        i = coords[k][0];
        j = coords[k][1];
        gs_out.fragWorldPos = gs_in[0].pointWorldCoord
            + i * vec4(cellSize, 0, 0, 0)
            - j * vec4(0, 0, cellSize, 0);

        noiseVal = perlinNoise(vec3(gs_out.fragWorldPos.x, 0.f, gs_out.fragWorldPos.z));
        //noiseVal = 0.f;
        gs_out.fragWorldPos += vec4(0,1,0,0)* noiseVal * noiseScale;
              

        gl_Position = projectionMatrix * viewingMatrix * gs_out.fragWorldPos;
        EmitVertex();
    }
    EndPrimitive();

}


float fade(float t)
{
    return t * t * t * (t * (t * 6 - 15) + 10);
}

vec3 grad(int i, int j, int k)
{
    if(i < 0) i = -i;
    if(j < 0) j = -j;
    if(k < 0) k = -k;
    int ind;
    ind = table[i % 16];
    ind = table[(j + ind) % 16];
    ind = table[(k + ind) % 16];
    
    return gradients[ind];
}


float perlinNoise(vec3 texCoords)
{
    texCoords = pow(2, -1) * texCoords;
    int i = int(floor(texCoords.x)) & 255,
        j = int(floor(texCoords.y)) & 255,
        k = int(floor(texCoords.z)) & 255;

    float x = texCoords.x - floor(texCoords.x),
          y = texCoords.y - floor(texCoords.y),
          z = texCoords.z - floor(texCoords.z);
    
    float u = fade(x),
          v = fade(y),
          w = fade(z);

    vec3 g000 = grad(i  , j  , k  ),
         g100 = grad(i+1, j  , k  ),
         g110 = grad(i+1, j+1, k  ),
         g010 = grad(i  , j+1, k  ),
         g011 = grad(i  , j+1, k+1),
         g111 = grad(i+1, j+1, k+1),
         g101 = grad(i+1, j  , k+1),
         g001 = grad(i  , j  , k+1);

    vec3 p000 = vec3(x  , y  , z  ),
         p100 = vec3(x-1, y  , z  ), 
         p110 = vec3(x-1, y-1, z  ), 
         p010 = vec3(x  , y-1, z  ),
         p011 = vec3(x  , y-1, z-1), 
         p111 = vec3(x-1, y-1, z-1), 
         p101 = vec3(x-1, y  , z-1),
         p001 = vec3(x  , y  , z-1); 


    float c; 
    c = mix(mix(mix(dot(g000, p000), dot(g100, p100), u),
                mix(dot(g010, p010), dot(g110, p110), u), v),

            mix(mix(dot(g001, p001), dot(g101, p101), u),
                mix(dot(g011, p011), dot(g111, p111), u), v), w);



    return (c+1)/2.0f;
}
