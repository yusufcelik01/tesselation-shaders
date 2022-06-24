#version 460 core

layout (std140, binding = 0) uniform matrices
{
    mat4 modelingMatrix;
    mat4 viewingMatrix;
    mat4 projectionMatrix;
    vec3 eyePos;
    float tessInner;
    float tessOuter;
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
struct Vertex hairVertex(int hairID, struct Triangle triangle);

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

    float u = gl_TessCoord.x,
          v = gl_TessCoord.y,
          w = gl_TessCoord.z;

    //
    int hairCount = int(gl_TessLevelOuter[0]);
    //int numOfSubTriangles = int(ceil(gl_TessLevelOuter[0]/3.0)+0.001);
    int hairID = int(round(v / (1.0f/gl_TessLevelOuter[0])) + 0.1);

    struct Vertex hairRoot = hairVertex(hairID, triangle);

    float hairLength = (distance(p0, p1) +
                        distance(p1, p2) +
                        distance(p2, p0) ) /3.0;
    vec4 hairTip = hairRoot.coord + vec4(normalize(hairRoot.normal) * hairLength * 1, 0.f);



    tese_out.fragWorldPos = mix(hairRoot.coord, hairTip, u);
    tese_out.fragWorldNor = hairRoot.normal; 
    gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * tese_out.fragWorldPos;

    //vec4 corner = tese_in[hairID % 3].fragWorldPos;

    //vec4 midPoint = (p0 + p1 + p2 )/3.0;
 
    //midPoint = mix(midPoint, corner, float(hairID/3 + 1)/float(1+ numOfSubTriangles));

    //float size = (distance(p0, p1) +
    //              distance(p1, p2) +
    //              distance(p2, p0) ) /3.0;

    //vec3 normal = triangleNormal(vec3(p0), vec3(p1), vec3(p2)); 
    //     normal = normalize((n0 + n1 + n2) /3.f);
    //
    //vec4 endPoint = midPoint + vec4(normal * size, 0.0);

    //tese_out.fragWorldPos = mix(midPoint, endPoint, u);
    //tese_out.fragWorldNor = normal;
    //gl_Position = projectionMatrix * viewingMatrix * modelingMatrix * tese_out.fragWorldPos;
     
    

    //dummy shader
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




struct Vertex getHairRootCoord(int hairID, int numberOfHairs, struct Triangle triangle)
{
    if(hairID == 0)
    {
        struct Vertex vertex;
        vertex.coord = (triangle.vert[0].coord + triangle.vert[1].coord + triangle.vert[2].coord  ) / 3.0;
        vertex.normal = (triangle.vert[0].normal + triangle.vert[1].normal + triangle.vert[2].normal  ) / 3.0;
        return  vertex;
    }
    int numberOfTriangles = 1;
    int numberOfRoots = 4; //fur roots
    int currTriangleRoots = 6;
    int hairTriangle = -1;
    int hairPosOnTriangle = -1;
    while( numberOfRoots < numberOfHairs )
    {
        if(numberOfRoots > hairID && hairTriangle == -1)
        {
            hairTriangle = numberOfTriangles;
        }
        numberOfRoots += currTriangleRoots;
        numberOfTriangles++;
        currTriangleRoots += 3;
    }

    //int corner = 
    struct Vertex vertex;
    vertex.coord = (triangle.vert[0].coord + triangle.vert[1].coord + triangle.vert[2].coord  ) / 3.0;
    vertex.normal = (triangle.vert[0].normal + triangle.vert[1].normal + triangle.vert[2].normal  ) / 3.0;
    return  vertex;
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
            case 0:
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

