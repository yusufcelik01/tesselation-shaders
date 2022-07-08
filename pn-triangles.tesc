#version 460 core

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


layout (std140, binding = 10) uniform objData
{
    vec4 objCenter;
};

layout (vertices = 3) out;

in VS_TESC_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tesc_in[];

out TESC_TESE_INTERFACE
{
    vec4 fragWorldPos;
    vec3 fragWorldNor;
} tesc_out[];

bool isVisible(vec4 p);
bool isBackFace(vec3 t0, vec3 t1, vec3 t2);
bool lineCvvIntersection(vec4 p0, vec4 p1);

precise gl_TessLevelOuter;
precise tesc_out;

void main()
{
    precise float zoomScale = 90.f/cameraFov;
    if( !isVisible(gl_in[0].gl_Position) &&
        !isVisible(gl_in[1].gl_Position) &&
        !isVisible(gl_in[2].gl_Position) //&&
        //!lineCvvIntersection(gl_in[0].gl_Position, gl_in[1].gl_Position)  &&
        //!lineCvvIntersection(gl_in[1].gl_Position, gl_in[2].gl_Position)  &&
        //!lineCvvIntersection(gl_in[2].gl_Position, gl_in[0].gl_Position)  
        )
    {//meaning the triangle is not visible
     //discard it by not generating geometry
        gl_TessLevelOuter[0] = 1.f;
        gl_TessLevelOuter[1] = 1.f;
        gl_TessLevelOuter[2] = 1.f;
        gl_TessLevelInner[0] = 1.f;
    }
    if(viewDependantTesselation == 0)
    {
        gl_TessLevelOuter[0] = tessOuter * levelOfDetail;
        gl_TessLevelOuter[1] = tessOuter * levelOfDetail;
        gl_TessLevelOuter[2] = tessOuter * levelOfDetail;
        gl_TessLevelInner[0] = tessInner * levelOfDetail;
    }
    else if( false )
    {

        precise vec4 edge[3];
        precise float dist[3];
        precise float tessOut[3];
        precise float tessLodAvg = 0.f;
        for(int i = 0; i < 3; i++)
        {
            //edge[i] = (tesc_in[i].fragWorldPos +
            //           tesc_in[(i-1)+3%3].fragWorldPos  )/2.f;
            //edge[i] = (p0 + p1 )/2.f;
    //float tessInner;
    //float tessOuter;
    //float levelOfDetail;
            //dist[i] = distance(edge[i], vec4(eyePos,1.f));

            precise float d1 = distance(tesc_in[i].fragWorldPos, vec4(eyePos, 1.f));
            precise float d2 = distance(tesc_in[(i-1)+3%3].fragWorldPos, vec4(eyePos, 1.f));

            if( d1 > d2 )
            {
                dist[i] = d2;
            }
            else
            {
                dist[i] = d1;
            }

            //vec4 p0 = gl_in[i].gl_Position;
            //vec4 p1 = gl_in[(i-1)+3%3].gl_Position;

            //if( (p0.z/ p0.w) > (p1.z / p1.w))
            //{
            //    dist[i] = p0.z /p0.w;
            //}
            //else 
            //{
            //    dist[i] = p1.z /p1.w ;
            //}
            //dist[i] = 1.f/abs(dist[i]);

            precise float tessLOD = 30.f/(dist[i]*dist[i]) *levelOfDetail * zoomScale;

            //gl_TessLevelOuter[i] = tessLOD;
            tessOut[i] = tessLOD;
            tessLodAvg += tessLOD;
        }
        tessLodAvg /= 3.f;
        gl_TessLevelInner[0] = tessLodAvg;
        //gl_TessLevelInner[0] = 1.f;

        gl_TessLevelOuter[0] = ceil(tessOut[0]);
        gl_TessLevelOuter[1] = ceil(tessOut[1]);
        gl_TessLevelOuter[2] = ceil(tessOut[2]);

        //gl_TessLevelOuter[0] = tessOut[0];
        //gl_TessLevelOuter[1] = tessOut[2];
        //gl_TessLevelOuter[2] = tessOut[1];

        //gl_TessLevelOuter[0] = tessOut[1];
        //gl_TessLevelOuter[1] = tessOut[0];
        //gl_TessLevelOuter[2] = tessOut[2];

        //gl_TessLevelOuter[0] = tessOut[1];
        //gl_TessLevelOuter[1] = tessOut[2];
        //gl_TessLevelOuter[2] = tessOut[0];

        //gl_TessLevelOuter[0] = tessOut[2];
        //gl_TessLevelOuter[1] = tessOut[1];
        //gl_TessLevelOuter[2] = tessOut[0];

        //gl_TessLevelOuter[0] = tessOut[2];
        //gl_TessLevelOuter[1] = tessOut[0];
        //gl_TessLevelOuter[2] = tessOut[1];

    }
    else 
    {
        precise float d = distance(vec4(eyePos, 1.f), objCenter);

        precise float LOD = 30.f/(d*d) * levelOfDetail * zoomScale;

        gl_TessLevelOuter[0] = LOD;
        gl_TessLevelOuter[1] = LOD;
        gl_TessLevelOuter[2] = LOD;
        gl_TessLevelInner[0] = LOD ;
    }





    tesc_out[gl_InvocationID].fragWorldPos = tesc_in[gl_InvocationID].fragWorldPos;
    tesc_out[gl_InvocationID].fragWorldNor = tesc_in[gl_InvocationID].fragWorldNor;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;

}

vec3 triangleNormal(vec3 t0, vec3 t1, vec3 t2)
{
    return normalize(cross(t1-t0, t2-t1));
}
/*
   this function takes a point in the canonical viewing volume 
   and returns true if this point is visible by the eye
   return false if it is not visible
*/
bool isVisible(vec4 p)
{//check if the point
    if( p.x > p.w || p.x < -p.w ||
        p.y > p.w || p.y < -p.w ||
        p.z > p.w || p.z < -p.w   )
    {
        return false;
    }
    else
    {
        return true;
    }
}

bool isBackFace(vec3 t0, vec3 t1, vec3 t2)
{
    vec3 norm = normalize(triangleNormal(t0, t1, t2));
    vec3 v = normalize(((t0 + t1 + t2)/3.0f) - eyePos);

    return dot(norm, v) >= 0.f;
}

bool lineCvvIntersection(vec4 p0, vec4 p1)//these points are outside the box
{
    vec3 o = p0.xyz / p0.w;//ray origin
    vec3 d = (p1.xyz / p1.w) - o;//ray direction
    
    float t1 = (1.0f - o.z )/d.z; // where z = 1.0
    if(true|| 0.f <= t1 && t1 <= 1.f)// line does intersect at z=1
    {
        vec3 p = o + d * t1;// intersection point at z=1 
        if( -1.f <= p.x && p.x <= 1.0 &&
            -1.f <= p.y && p.y <= 1.0 )
        {
            return true;
        }
    }
    // line does not intersect with the box at z = 1.0
    float t2 = (-1.f - o.z)/d.z;
    if(true|| 0.f <= t2 && t2 <= 1.f)// line does intersect at z = -1
    {
        vec3 p = o + d * t2;// intersection point at z = -1 
        if( -1.f <= p.x && p.x <= 1.0 &&
            -1.f <= p.y && p.y <= 1.0 )
        {
            return true;
        }
    }

    return false;
}

//
        //precise float dist0 = distance((tesc_in[0].fragWorldPos.xyz + 
        //            tesc_in[1].fragWorldPos.xyz )/2.f,
        //        eyePos);
        //precise float dist1 = distance((tesc_in[1].fragWorldPos.xyz + 
        //            tesc_in[2].fragWorldPos.xyz )/2.f,
        //        eyePos);
        //precise float dist2 = distance((tesc_in[2].fragWorldPos.xyz + 
        //            tesc_in[0].fragWorldPos.xyz )/2.f,
        //        eyePos);
        //float threshold = 10;
        //int tessOut0 = 1;
        //int tessOut1 = 1;
        //int tessOut2 = 1;
        //while(dist0 < threshold )
        //{
        //    tessOut0++;
        //    threshold /= 2.f;
        //}
        //threshold = 5;
        //while(dist1 < threshold )
        //{
        //    tessOut1++;
        //    threshold /= 2.f;
        //}
        //threshold = 10;
        //while(dist2 < threshold )
        //{
        //    tessOut2++;
        //    threshold /= 2.f;
        //}

        //dist0 = 1.0 /dist0;
        //dist1 = 1.0 /dist1;
        //dist2 = 1.0 /dist2;

        //float avgDist = (dist0 + dist1 + dist2)/3.f;
        //precise float tessIn = (tessOut0 + tessOut1 + tessOut2)/3.0f;

        ////gl_TessLevelOuter[1] = tessOut0 * levelOfDetail * 0.4;
        ////gl_TessLevelOuter[2] = tessOut1 * levelOfDetail * 0.4;
        ////gl_TessLevelOuter[0] = tessOut2 * levelOfDetail * 0.4;

        //gl_TessLevelOuter[1] = tessOut0 * levelOfDetail * 0.4;
        //gl_TessLevelOuter[2] = tessOut1 * levelOfDetail * 0.4;
        //gl_TessLevelOuter[0] = tessOut2 * levelOfDetail * 0.4;
        //gl_TessLevelInner[0] = tessIn   * levelOfDetail * 0.4;

