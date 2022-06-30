#version 460 core

// All of the following variables could be defined in the OpenGL
// program and passed to this shader as uniform variables. This
// would be necessary if their values could change during runtim.
// However, we will not change them and therefore we define them 
// here for simplicity.

vec3 I = vec3(1, 1, 1);          // point light intensity
vec3 Iamb = vec3(0.8, 0.8, 0.8); // ambient light intensity
vec3 kd = vec3(0.0, 0.6, 0.0);     // diffuse reflectance coefficient
vec3 ka = vec3(0.3, 0.3, 0.3);   // ambient reflectance coefficient
vec3 ks = vec3(0.8, 0.8, 0.8);   // specular reflectance coefficient
vec3 lightPos = vec3(5, 5, 5);   // light position in world coordinates

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    float terrainSpan;
    uint vertexCount;
    float noiseScale;
};

uniform vec3 eyePos;

in GS_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
}fs_in;

out vec4 fragColor;

vec3 rainbow[256] = {
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

void main(void)
{
	// Compute lighting. We assume lightPos and eyePos are in world
	// coordinates. fragWorldPos and fragWorldNor are the interpolated
	// coordinates by the rasterizer.

	vec3 L = normalize(lightPos - vec3(fs_in.fragWorldPos));
	vec3 V = normalize(eyePos - vec3(fs_in.fragWorldPos));
	vec3 H = normalize(L + V);
	vec3 N = normalize(fs_in.fragWorldNor);

	float NdotL = dot(N, L); // for diffuse component
	float NdotH = dot(N, H); // for specular component

	vec3 diffuseColor = I * kd * max(0, NdotL);
	vec3 specularColor = I * ks * pow(max(0, NdotH), 100);
	vec3 ambientColor = Iamb * ka;

	fragColor = vec4(diffuseColor + specularColor + ambientColor, 1);
    
    if(terrainSpan > 31){
        fragColor = vec4(1,0,0,1);
    }
    if(vertexCount > 1000){
        fragColor = vec4(0,0,1,1);
    }

    //float test = abs(noiseScale)/10;
    //fragColor = vec4(mix(1,0,test), mix(0,1,test), 0, 1);

    float vertexHeight = fs_in.fragWorldPos.y * 155.0f;
    if( vertexHeight > 255) vertexHeight = 255;
    if( vertexHeight < 0) vertexHeight = 0;
    fragColor = vec4(rainbow[int(floor(vertexHeight))], 1.0f) ;
}
