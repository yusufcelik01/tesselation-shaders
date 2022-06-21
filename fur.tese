#version 460 core

uniform mat4 modelingMatrix;
uniform mat4 viewingMatrix;
uniform mat4 projectionMatrix;

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
} tese_out;


vec3 triangleNormal(vec3 t0, vec3 t1, vec3 t2);

void main()
{
    vec4 p0 = tese_in[0].fragWorldPos;
    vec4 p1 = tese_in[1].fragWorldPos;
    vec4 p2 = tese_in[2].fragWorldPos;
    
    vec3 n0 = tese_in[0].fragWorldNor;
    vec3 n1 = tese_in[1].fragWorldNor;
    vec3 n2 = tese_in[2].fragWorldNor;

    float u = gl_TessCoord.x,
          v = gl_TessCoord.y,
          w = gl_TessCoord.z;

    //
    int hairCount = int(gl_TessLevelOuter[0]);
    int numOfSubTriangles = int(ceil(gl_TessLevelOuter[0]/3.0)+0.001);
    int hairID = int(round(v / (1.0f/float(hairCount))));

    vec4 corner = tese_in[hairID % 3].fragWorldPos;

    vec4 midPoint = (p0 + p1 + p2 )/3.0;
 
    midPoint = mix(midPoint, corner, float(hairID/3 + 1)/float(1+ numOfSubTriangles));

    float size = (distance(p0, p1) +
                  distance(p1, p2) +
                  distance(p2, p0) ) /3.0;

    vec3 normal = triangleNormal(vec3(p0), vec3(p1), vec3(p2)); 
         normal = normalize((n0 + n1 + n2) /3.f);
    
    vec4 endPoint = midPoint + vec4(normal * size, 0.0);

    tese_out.fragWorldPos = mix(midPoint, endPoint, u);
    tese_out.fragWorldNor = normal;
    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * tese_out.fragWorldPos;
     
    

    //gl_Position = u * gl_in[0].gl_Position + 
    //              v * gl_in[1].gl_Position +
    //              w * gl_in[2].gl_Position;

    //tese_out.fragWorldPos = u * tese_in[0].fragWorldPos +
    //                        v * tese_in[1].fragWorldPos +
    //                        w * tese_in[2].fragWorldPos;

    //tese_out.fragWorldNor = u * tese_in[0].fragWorldNor +
    //                        v * tese_in[1].fragWorldNor +
    //                        w * tese_in[2].fragWorldNor;

}


vec3 triangleNormal(vec3 t0, vec3 t1, vec3 t2)
{
    return normalize(cross(t1-t0, t2-t1));
}
