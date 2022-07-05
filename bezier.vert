#version 460 core

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
};


layout(location=0) in vec3 inVertex;

out VS_TESC_INTERFACE
{
    vec3 fragWorldPos;
} vs_out;

void main(void)
{
	// Compute the world coordinates of the vertex and its normal.
	// These coordinates will be interpolated during the rasterization
	// stage and the fragment shader will receive the interpolated
	// coordinates.

	vs_out.fragWorldPos = (modelingMatrix * vec4(inVertex, 1)).xyz;

    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * vec4(inVertex, 1);
}

