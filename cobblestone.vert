#version 460 core

layout(location=0) in vec3 inPoint;
layout(location=1) in vec3 inNormal;//actually not gonna use this


layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
};

float terrainSpan = 30;
uint vertexCount = 1000;
float noiseScale = 1.5;

out VS_TESC_INTERFACE
{
    vec4 pointWorldCoord;
} vs_out;

void main(void)
{

    vs_out.pointWorldCoord = vec4(-15.f, -1.f, 15.f, 1.f);

    gl_Position = projectionMatrix * viewingMatrix * vs_out.pointWorldCoord;
}

