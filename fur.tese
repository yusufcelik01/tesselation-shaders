#version 460 core

#define M_PI 3.1415926535897932384626433832795


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

layout (std140, binding = 3) uniform furColorParams
{
    int enableFurColor;
    float  furColorPerlinParam;
};

layout ( isolines, equal_spacing, ccw) in;


in TESC_TESE_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tese_in[];

out TESE_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
    vec3 furColor;
} tese_out;

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
mat4 rotateX(float angle);
mat4 rotateAroundAxis(float angle, vec3 u);
struct Vertex hairVertex(int hairID, struct Triangle triangle);

float fade(float);
float perlinNoise(vec3);
vec3 sampleRainbow(float u);

void main()
{
    struct Triangle triangle;
    vec4 p0 = tese_in[0].fragWorldPos;
    vec4 p1 = tese_in[1].fragWorldPos;
    vec4 p2 = tese_in[2].fragWorldPos;
    
    vec3 n0 = tese_in[0].fragWorldNor;
    vec3 n1 = tese_in[1].fragWorldNor;
    vec3 n2 = tese_in[2].fragWorldNor;

    triangle.vert[0].coord = tese_in[0].fragWorldPos;
    triangle.vert[1].coord = tese_in[1].fragWorldPos;
    triangle.vert[2].coord = tese_in[2].fragWorldPos;

    triangle.vert[0].normal = tese_in[0].fragWorldNor;
    triangle.vert[1].normal = tese_in[1].fragWorldNor;
    triangle.vert[2].normal = tese_in[2].fragWorldNor;

    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    //float w = gl_TessCoord.z;

    //
    //int hairCount = int(gl_TessLevelOuter[0]);
    //int numOfSubTriangles = int(ceil(gl_TessLevelOuter[0]/3.0)+0.001);
    int hairID = int(round(v / (1.0f/gl_TessLevelOuter[0]))+0.001);

    struct Vertex hairRoot = hairVertex(hairID, triangle);

    float hairLength = (distance(p0, p1) +
                        distance(p1, p2) +
                        distance(p2, p0) ) /3.0;

    hairLength = hairLen;
    //line furs
    vec4 hairTip = hairRoot.coord + vec4(normalize(hairRoot.normal) * hairLength * 1, 0.f);

    tese_out.fragWorldPos = mix(hairRoot.coord, hairTip, u);
    tese_out.fragWorldNor = hairRoot.normal; 
    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * tese_out.fragWorldPos;

    //bezier curve furs
    
    vec3 surfNorm = triangleNormal(p0.xyz, p1.xyz, p2.xyz);//actual surfnormal not vertex
    float alpha = acos(dot(surfNorm, hairRoot.normal)); //fur angle
    float theta = alpha * 0.5 * hairCurveAngle;
    vec3 hairRotAxis = cross(surfNorm, hairRoot.normal);

    vec3 hairRootNorm = normalize(hairRoot.normal);
    vec3 hairRootToTip = normalize((rotateAroundAxis(theta, hairRotAxis) 
                                * vec4(hairRootNorm,0.f)).xyz);
    vec3 hairTipNorm = normalize((rotateAroundAxis( theta*2, hairRotAxis) * vec4(hairRootNorm, 0.f)).xyz);

    vec3 B1 = hairRoot.coord.xyz;
    vec3 B2 = hairRootNorm*hairLength/3.0f  + B1;
    vec3 B4 = B1 +  hairRootToTip * hairLength;
    vec3 B3 = hairTipNorm*hairLength/ -3.f + B4;

    tese_out.fragWorldPos = vec4(pow(1-u, 3)*B1 +
                                 3*u*pow(1-u, 2)*B2 +
                                 3*u*u*(1-u)*B3 +
                                 u*u*u*B4
                                 , 1.f);
    //tese_out.fragWorldPos = vec4(mix(B1, B4, u), 1.f);
    theta = mix(0, theta*2, u);
    tese_out.fragWorldNor = normalize((rotateAroundAxis( theta, hairRotAxis) * vec4(hairRootNorm, 0.f)).xyz);
    gl_Position = projectionMatrix * viewingMatrix * tese_out.fragWorldPos;


    //set fur color
    vec3 noiseSampler = pow(2, furColorPerlinParam) * tese_out.fragWorldPos.xyz;
    tese_out.furColor = sampleRainbow(perlinNoise(noiseSampler));
    float t = hairLength * u;
    //tese_out.furColor = sampleRainbow(perlinNoise(vec3(u,u,u)));
    //tese_out.furColor = sampleRainbow(perlinNoise(vec3(v,v,v)));
    //tese_out.furColor = sampleRainbow(perlinNoise(vec3(t,t,t)));
    vec3 enbyColors[4] = 
    {
        vec3(0, 0, 0),
        vec3(154, 86, 207)/255.f,
        vec3(1, 1, 1),
        vec3(254, 221, 0)/255.f
    };
    float perlinValue = perlinNoise(noiseSampler);
    perlinValue = fade(perlinValue);
    tese_out.furColor = enbyColors[int(4* perlinValue)];
    tese_out.furColor = sampleRainbow(perlinNoise(noiseSampler));
}


vec3 triangleNormal(vec3 t0, vec3 t1, vec3 t2)
{
    return normalize(cross(t1-t0, t2-t1));
}

mat4 rotateX(float angle)
{
    return mat4(1.f,         0.f,        0.f, 0.f, //col0
                0.f,  cos(angle), sin(angle), 0.f, 
                0.f, -sin(angle), cos(angle), 0.f,
                0.f, 0.f, 0.f, 1.f);


}

mat4 rotateAroundAxis(float angle, vec3 u)
{
    vec3 v;
    v.x = -u.y;
    v.y = u.x;
    v.z = 0.f;
    
    vec3 w = cross(u, v);
    u =  normalize(u);
    v =  normalize(v);
    w =  normalize(w);

    mat4 M = mat4(1.f);

    M[0] = vec4(u.x, v.x, w.x, 0.f);
    M[1] = vec4(u.y, v.y, w.y, 0.f);
    M[2] = vec4(u.z, v.z, w.z, 0.f);

    return inverse(M) * rotateX(angle) * M;
}





struct Vertex hairVertex(int hairID, struct Triangle triangle)
{
    while(hairID != 0)
    {
        int rem = hairID % 6;
        struct Vertex center;
        center.coord = (triangle.vert[0].coord + triangle.vert[1].coord + triangle.vert[2].coord  ) / 3.0;
        center.normal = (triangle.vert[0].normal + triangle.vert[1].normal + triangle.vert[2].normal  ) / 3.0;
        struct Vertex edgeMid;
        switch(rem)
        {
            case 1:
                edgeMid.coord = (triangle.vert[0].coord  + triangle.vert[1].coord  ) / 2.0;
                edgeMid.normal = (triangle.vert[0].normal + triangle.vert[1].normal  ) / 2.0;

                triangle.vert[1] = triangle.vert[0];
                triangle.vert[0] = center;
                triangle.vert[2] = edgeMid;
                break;

            case 2:
                edgeMid.coord = (triangle.vert[0].coord  + triangle.vert[1].coord  ) / 2.0;
                edgeMid.normal = (triangle.vert[0].normal + triangle.vert[1].normal  ) / 2.0;

                triangle.vert[2] = triangle.vert[1];
                triangle.vert[1] = edgeMid;
                triangle.vert[0] = center;
                break;

            case 3:
                edgeMid.coord = (triangle.vert[2].coord  + triangle.vert[1].coord  ) / 2.0;
                edgeMid.normal = (triangle.vert[2].normal + triangle.vert[1].normal  ) / 2.0;

                triangle.vert[2] = edgeMid; 
                //triangle.vert[1];//vertex 1 stays the same
                triangle.vert[0] = center;
                break;
            case 4:
                edgeMid.coord = (triangle.vert[2].coord  + triangle.vert[1].coord  ) / 2.0;
                edgeMid.normal = (triangle.vert[2].normal + triangle.vert[1].normal  ) / 2.0;

                triangle.vert[1] = edgeMid;
                //triangle.vert[2];//stays the same
                triangle.vert[0] = center;
                break;
            case 5:
                edgeMid.coord = (triangle.vert[2].coord  + triangle.vert[0].coord  ) / 2.0;
                edgeMid.normal = (triangle.vert[2].normal + triangle.vert[0].normal  ) / 2.0;

                triangle.vert[1] = triangle.vert[2];
                triangle.vert[2] = edgeMid;
                triangle.vert[0] = center;
                break;
            default://case 0
                edgeMid.coord = (triangle.vert[2].coord  + triangle.vert[0].coord  ) / 2.0;
                edgeMid.normal = (triangle.vert[2].normal + triangle.vert[0].normal  ) / 2.0;
                
                triangle.vert[2] = triangle.vert[0];
                triangle.vert[1] = edgeMid;
                triangle.vert[0] = center;
                break;


        }
        hairID /= 6;
    }

    struct Vertex vertex;
    vertex.coord = (triangle.vert[0].coord + triangle.vert[1].coord + triangle.vert[2].coord  ) / 3.0;
    vertex.normal = (triangle.vert[0].normal + triangle.vert[1].normal + triangle.vert[2].normal  ) / 3.0;
    return vertex;
}

//perlin noise 
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


vec3 sampleRainbow(float u)
{

const vec3 rainbow[256] = {
	vec3(0.984314, 0, 1),
	vec3(0.964706, 0, 1),
	vec3(0.945098, 0, 1),
	vec3(0.92549, 0, 1),
	vec3(0.905882, 0, 1),
	vec3(0.886275, 0, 1),
	vec3(0.866667, 0, 1),
	vec3(0.847059, 0, 1),
	vec3(0.827451, 0, 1),
	vec3(0.807843, 0, 1),
	vec3(0.788235, 0, 1),
	vec3(0.768627, 0, 1),
	vec3(0.74902, 0, 1),
	vec3(0.729412, 0, 1),
	vec3(0.709804, 0, 1),
	vec3(0.690196, 0, 1),
	vec3(0.670588, 0, 1),
	vec3(0.65098, 0, 1),
	vec3(0.631373, 0, 1),
	vec3(0.611765, 0, 1),
	vec3(0.592157, 0, 1),
	vec3(0.572549, 0, 1),
	vec3(0.552941, 0, 1),
	vec3(0.533333, 0, 1),
	vec3(0.513726, 0, 1),
	vec3(0.494118, 0, 1),
	vec3(0.47451, 0, 1),
	vec3(0.454902, 0, 1),
	vec3(0.435294, 0, 1),
	vec3(0.415686, 0, 1),
	vec3(0.396078, 0, 1),
	vec3(0.376471, 0, 1),
	vec3(0.356863, 0, 1),
	vec3(0.337255, 0, 1),
	vec3(0.317647, 0, 1),
	vec3(0.298039, 0, 1),
	vec3(0.278431, 0, 1),
	vec3(0.258824, 0, 1),
	vec3(0.239216, 0, 1),
	vec3(0.219608, 0, 1),
	vec3(0.2, 0, 1),
	vec3(0.184314, 0, 1),
	vec3(0.164706, 0, 1),
	vec3(0.145098, 0, 1),
	vec3(0.12549, 0, 1),
	vec3(0.105882, 0, 1),
	vec3(0.0862745, 0, 1),
	vec3(0.0666667, 0, 1),
	vec3(0.0470588, 0, 1),
	vec3(0.027451, 0, 1),
	vec3(0.00784314, 0, 1),
	vec3(0, 0.0117647, 1),
	vec3(0, 0.0313726, 1),
	vec3(0, 0.0509804, 1),
	vec3(0, 0.0705882, 1),
	vec3(0, 0.0901961, 1),
	vec3(0, 0.109804, 1),
	vec3(0, 0.129412, 1),
	vec3(0, 0.14902, 1),
	vec3(0, 0.168627, 1),
	vec3(0, 0.188235, 1),
	vec3(0, 0.207843, 1),
	vec3(0, 0.227451, 1),
	vec3(0, 0.247059, 1),
	vec3(0, 0.266667, 1),
	vec3(0, 0.286275, 1),
	vec3(0, 0.305882, 1),
	vec3(0, 0.32549, 1),
	vec3(0, 0.345098, 1),
	vec3(0, 0.364706, 1),
	vec3(0, 0.384314, 1),
	vec3(0, 0.403922, 1),
	vec3(0, 0.423529, 1),
	vec3(0, 0.443137, 1),
	vec3(0, 0.462745, 1),
	vec3(0, 0.482353, 1),
	vec3(0, 0.501961, 1),
	vec3(0, 0.521569, 1),
	vec3(0, 0.541176, 1),
	vec3(0, 0.560784, 1),
	vec3(0, 0.580392, 1),
	vec3(0, 0.6, 1),
	vec3(0, 0.619608, 1),
	vec3(0, 0.639216, 1),
	vec3(0, 0.658824, 1),
	vec3(0, 0.678431, 1),
	vec3(0, 0.698039, 1),
	vec3(0, 0.717647, 1),
	vec3(0, 0.737255, 1),
	vec3(0, 0.756863, 1),
	vec3(0, 0.776471, 1),
	vec3(0, 0.796078, 1),
	vec3(0, 0.815686, 1),
	vec3(0, 0.835294, 1),
	vec3(0, 0.854902, 1),
	vec3(0, 0.87451, 1),
	vec3(0, 0.894118, 1),
	vec3(0, 0.913725, 1),
	vec3(0, 0.933333, 1),
	vec3(0, 0.952941, 1),
	vec3(0, 0.972549, 1),
	vec3(0, 0.992157, 1),
	vec3(0, 1, 0.992157),
	vec3(0, 1, 0.972549),
	vec3(0, 1, 0.952941),
	vec3(0, 1, 0.933333),
	vec3(0, 1, 0.913725),
	vec3(0, 1, 0.894118),
	vec3(0, 1, 0.87451),
	vec3(0, 1, 0.854902),
	vec3(0, 1, 0.835294),
	vec3(0, 1, 0.815686),
	vec3(0, 1, 0.796078),
	vec3(0, 1, 0.776471),
	vec3(0, 1, 0.756863),
	vec3(0, 1, 0.737255),
	vec3(0, 1, 0.717647),
	vec3(0, 1, 0.698039),
	vec3(0, 1, 0.678431),
	vec3(0, 1, 0.658824),
	vec3(0, 1, 0.639216),
	vec3(0, 1, 0.619608),
	vec3(0, 1, 0.6),
	vec3(0, 1, 0.580392),
	vec3(0, 1, 0.560784),
	vec3(0, 1, 0.541176),
	vec3(0, 1, 0.521569),
	vec3(0, 1, 0.501961),
	vec3(0, 1, 0.482353),
	vec3(0, 1, 0.462745),
	vec3(0, 1, 0.443137),
	vec3(0, 1, 0.423529),
	vec3(0, 1, 0.403922),
	vec3(0, 1, 0.384314),
	vec3(0, 1, 0.364706),
	vec3(0, 1, 0.345098),
	vec3(0, 1, 0.32549),
	vec3(0, 1, 0.305882),
	vec3(0, 1, 0.286275),
	vec3(0, 1, 0.266667),
	vec3(0, 1, 0.247059),
	vec3(0, 1, 0.227451),
	vec3(0, 1, 0.207843),
	vec3(0, 1, 0.188235),
	vec3(0, 1, 0.168627),
	vec3(0, 1, 0.14902),
	vec3(0, 1, 0.129412),
	vec3(0, 1, 0.109804),
	vec3(0, 1, 0.0901961),
	vec3(0, 1, 0.0705882),
	vec3(0, 1, 0.0509804),
	vec3(0, 1, 0.0313726),
	vec3(0, 1, 0.0117647),
	vec3(0.00784314, 1, 0),
	vec3(0.027451, 1, 0),
	vec3(0.0470588, 1, 0),
	vec3(0.0666667, 1, 0),
	vec3(0.0862745, 1, 0),
	vec3(0.105882, 1, 0),
	vec3(0.12549, 1, 0),
	vec3(0.145098, 1, 0),
	vec3(0.164706, 1, 0),
	vec3(0.184314, 1, 0),
	vec3(0.2, 1, 0),
	vec3(0.219608, 1, 0),
	vec3(0.239216, 1, 0),
	vec3(0.258824, 1, 0),
	vec3(0.278431, 1, 0),
	vec3(0.298039, 1, 0),
	vec3(0.317647, 1, 0),
	vec3(0.337255, 1, 0),
	vec3(0.356863, 1, 0),
	vec3(0.376471, 1, 0),
	vec3(0.396078, 1, 0),
	vec3(0.415686, 1, 0),
	vec3(0.435294, 1, 0),
	vec3(0.454902, 1, 0),
	vec3(0.47451, 1, 0),
	vec3(0.494118, 1, 0),
	vec3(0.513726, 1, 0),
	vec3(0.533333, 1, 0),
	vec3(0.552941, 1, 0),
	vec3(0.572549, 1, 0),
	vec3(0.592157, 1, 0),
	vec3(0.611765, 1, 0),
	vec3(0.631373, 1, 0),
	vec3(0.65098, 1, 0),
	vec3(0.670588, 1, 0),
	vec3(0.690196, 1, 0),
	vec3(0.709804, 1, 0),
	vec3(0.729412, 1, 0),
	vec3(0.74902, 1, 0),
	vec3(0.768627, 1, 0),
	vec3(0.788235, 1, 0),
	vec3(0.807843, 1, 0),
	vec3(0.827451, 1, 0),
	vec3(0.847059, 1, 0),
	vec3(0.866667, 1, 0),
	vec3(0.886275, 1, 0),
	vec3(0.905882, 1, 0),
	vec3(0.92549, 1, 0),
	vec3(0.945098, 1, 0),
	vec3(0.964706, 1, 0),
	vec3(0.984314, 1, 0),
	vec3(1, 0.996078, 0),
	vec3(1, 0.976471, 0),
	vec3(1, 0.956863, 0),
	vec3(1, 0.937255, 0),
	vec3(1, 0.917647, 0),
	vec3(1, 0.898039, 0),
	vec3(1, 0.878431, 0),
	vec3(1, 0.858824, 0),
	vec3(1, 0.839216, 0),
	vec3(1, 0.819608, 0),
	vec3(1, 0.8, 0),
	vec3(1, 0.780392, 0),
	vec3(1, 0.760784, 0),
	vec3(1, 0.741176, 0),
	vec3(1, 0.721569, 0),
	vec3(1, 0.701961, 0),
	vec3(1, 0.682353, 0),
	vec3(1, 0.662745, 0),
	vec3(1, 0.643137, 0),
	vec3(1, 0.623529, 0),
	vec3(1, 0.603922, 0),
	vec3(1, 0.588235, 0),
	vec3(1, 0.568627, 0),
	vec3(1, 0.54902, 0),
	vec3(1, 0.529412, 0),
	vec3(1, 0.509804, 0),
	vec3(1, 0.490196, 0),
	vec3(1, 0.470588, 0),
	vec3(1, 0.45098, 0),
	vec3(1, 0.431373, 0),
	vec3(1, 0.411765, 0),
	vec3(1, 0.392157, 0),
	vec3(1, 0.372549, 0),
	vec3(1, 0.352941, 0),
	vec3(1, 0.333333, 0),
	vec3(1, 0.313726, 0),
	vec3(1, 0.294118, 0),
	vec3(1, 0.27451, 0),
	vec3(1, 0.254902, 0),
	vec3(1, 0.235294, 0),
	vec3(1, 0.215686, 0),
	vec3(1, 0.196078, 0),
	vec3(1, 0.176471, 0),
	vec3(1, 0.156863, 0),
	vec3(1, 0.137255, 0),
	vec3(1, 0.117647, 0),
	vec3(1, 0.0980392, 0),
	vec3(1, 0.0784314, 0),
	vec3(1, 0.0588235, 0),
	vec3(1, 0.0392157, 0),
	vec3(1, 0.0196078, 0),
	vec3(1, 0, 0)
};


    return rainbow[int(u*255)];
    //return rainbow[int(max(0, u*145 )) ];
}
