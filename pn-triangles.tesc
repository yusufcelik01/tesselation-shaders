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
bool lineCvvIntersection(vec4 p0, vec4 p1);

void main()
{
    if( !isVisible(gl_in[0].gl_Position) &&
        !isVisible(gl_in[1].gl_Position) &&
        !isVisible(gl_in[2].gl_Position) //&&
        //!lineCvvIntersection(gl_in[0].gl_Position, gl_in[1].gl_Position)  &&
        //!lineCvvIntersection(gl_in[1].gl_Position, gl_in[2].gl_Position)  &&
        //!lineCvvIntersection(gl_in[2].gl_Position, gl_in[0].gl_Position)  
        )
    {//meaning the triangle is not visible
     //discard it by not generating geometry
        gl_TessLevelOuter[0] = 0.f;
        gl_TessLevelOuter[1] = 0.f;
        gl_TessLevelOuter[2] = 0.f;
        gl_TessLevelInner[0] = 0.f;
        return;
    }
    gl_TessLevelOuter[0] = tessOuter * levelOfDetail;
    gl_TessLevelOuter[1] = tessOuter * levelOfDetail;
    gl_TessLevelOuter[2] = tessOuter * levelOfDetail;
    gl_TessLevelInner[0] = tessInner * levelOfDetail;


    tesc_out[gl_InvocationID].fragWorldPos = tesc_in[gl_InvocationID].fragWorldPos;
    tesc_out[gl_InvocationID].fragWorldNor = tesc_in[gl_InvocationID].fragWorldNor;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;

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
