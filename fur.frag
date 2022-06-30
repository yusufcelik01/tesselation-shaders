#version 460 core

vec3 I = vec3(1, 1, 1);          // point light intensity
vec3 Iamb = vec3(0.8, 0.8, 0.8); // ambient light intensity
//vec3 kd = vec3(1.0, 0.6, 0.2);     // diffuse reflectance coefficient
vec3 kd = vec3(1.0, 0.2, 0.2);     // diffuse reflectance coefficient
vec3 ka = vec3(0.3, 0.3, 0.3);   // ambient reflectance coefficient
vec3 ks = vec3(0.8, 0.8, 0.8);   // specular reflectance coefficient
vec3 lightPos = vec3(5, 5, 5);   // light position in world coordinates

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
};


in TESE_FS_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} fs_in;

out vec4 fragColor;

void main(void)
{
	// Compute lighting. We assume lightPos and eyePos are in world
	// coordinates. fragWorldPos and fragWorldNor are the interpolated
	// coordinates by the rasterizer.

	vec3 L = normalize(lightPos - vec3(fs_in.fragWorldPos));
	vec3 V = normalize(eyePos - vec3(fs_in.fragWorldPos));
    vec3 T = normalize(fs_in.fragWorldNor);
	vec3 H = normalize(L + V);

	//vec3 N = normalize(fs_in.fragWorldNor);

	float sinTL = length(cross(T, L)); // for diffuse component
	float sinTH = length(cross(T, H)); // for specular component

	vec3 diffuseColor = I * kd * max(0, sinTL);
	vec3 specularColor = I * ks * pow(max(0, sinTH), 700);
	vec3 ambientColor = Iamb * ka;

	fragColor = vec4(diffuseColor + specularColor + ambientColor, 1);
    //fragColor = vec4(0,1,0,1);
    //fragColor = vec4(noise3(fs_in.fragWorldPos.x/3 +fs_in.fragWorldPos.y/3 + fs_in.fragWorldPos.z/3)/2+vec3(0.5,0.5,0.5), 1.0f); 
    //fragColor = vec4(0, 0.8, 0, 1);
}
