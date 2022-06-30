#version 460 core

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
    float tessInner;
    float tessOuter;
    float levelOfDetail;
};

layout(location=0) in vec3 inVertex;
layout(location=1) in vec3 inNormal;

out VS_TESC_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} vs_out;

void main(void)
{
	// Compute the world coordinates of the vertex and its normal.
	// These coordinates will be interpolated during the rasterization
	// stage and the fragment shader will receive the interpolated
	// coordinates.

	vs_out.fragWorldPos = modelingMatrix * vec4(inVertex, 1);
	vs_out.fragWorldNor = inverse(transpose(mat3x3(modelingMatrix))) * inNormal;

    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * vec4(inVertex, 1);
}

