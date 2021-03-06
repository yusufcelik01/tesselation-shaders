#include <unistd.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#define _USE_MATH_DEFINES
#include <math.h>
#include <GL/glew.h>
//#include <OpenGL/gl3.h>   // The GL Header File
#include <GLFW/glfw3.h> // The GLFW header
#include <glm/glm.hpp> // GL Math library header
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp> 
#include <glm/gtc/quaternion.hpp>
#include <glm/gtx/quaternion.hpp>


#define BUFFER_OFFSET(i) ((char*)NULL + (i))

using namespace std;


struct ProgramParams
{
    GLuint progObj;
    GLenum primitiveType;//ex. GL_POINTS
    unsigned int patchVertices;//if primitive is GL_PATCHES
};

//program flags
enum program_mode
{
    PN_ONLY,
    BEZIER_ONLY,
    PN_VS_BEZIER,
    PN_ALL
} program_arg;

char* objFileName = NULL;

GLuint gProgram[8];
size_t numberOfPrograms = 0;

int bezierProgramIndex = -1;
int furProgramIndex = -1;
int pnProgramIndex = -1;


size_t numberOfObj = 0;

vector<size_t> pnObjIndices = {};
vector<size_t> bezierObjIndices = {};



int gWidth, gHeight;

GLint modelingMatrixLoc[8];
GLint viewingMatrixLoc[8];
GLint projectionMatrixLoc[8];
GLint eyePosLoc[8];
GLint tessInnerLoc[8];
GLint tessOuterLoc[8];


glm::mat4 projectionMatrix;
glm::mat4 viewingMatrix;
glm::mat4 modelingMatrix;

int activeProgramIndex = 1;
int enableFur = 0;
int wireframeMode = 0;
GLint viewDependantTesselation = 1;
GLint backFaceCulling = 0;

GLfloat tessOuter = 1.0;
GLfloat tessInner = 1.0;
GLfloat levelOfDetail = 1.0;

GLuint hairCount = 30;//per triangle
GLfloat hairLen = 0.1;//length multiplier
GLfloat hairDetail = 5.0;
GLfloat hairCurveAngle = 2.4;
GLint enableFurColor = 0;//0 for gray, 1 for perlin colored furs
GLfloat furColorPerlinParam = 1.f;


#define INITIAL_FOV 90.f
float cameraFov = INITIAL_FOV; //45.0f;
int width = 1200, height = 900;
float lastX = width/2.0f;
float lastY = height/2.0f;
float yaw = -90.0f;
float pitch = 0.0f;



glm::vec3 eyePos(-0.25f, 2.f, 10.0f);
glm::vec3 cameraFront(0.f, 0.f, -1.f);
glm::vec3 cameraUp(0.f, 1.f, 0.f);
float cameraSpeed = 0.f;

float deltaTime = 0.f; 
float currentTime = 0.f;
float lastTime = 0.f;

struct Vertex
{
    Vertex(GLfloat inX, GLfloat inY, GLfloat inZ) : x(inX), y(inY), z(inZ) { }
    GLfloat x, y, z;
};

struct Texture
{
    Texture(GLfloat inU, GLfloat inV) : u(inU), v(inV) { }
    GLfloat u, v;
};

struct Normal
{
    Normal(GLfloat inX, GLfloat inY, GLfloat inZ) : x(inX), y(inY), z(inZ) { }
    GLfloat x, y, z;
};

struct Face
{
	Face(int v[], int t[], int n[]) {
		vIndex[0] = v[0];
		vIndex[1] = v[1];
		vIndex[2] = v[2];
		tIndex[0] = t[0];
		tIndex[1] = t[1];
		tIndex[2] = t[2];
		nIndex[0] = n[0];
		nIndex[1] = n[1];
		nIndex[2] = n[2];
	}
    GLuint vIndex[3], tIndex[3], nIndex[3];
};

struct BezierSurface
{
    GLuint vIndices[16];
};


vector<Vertex> gVertices[8];
vector<Texture> gTextures[8];
vector<Normal> gNormals[8];
vector<Face> gFaces[8];
vector<BezierSurface> gSurfaces[8];

glm::vec4 objCenters[8];

GLuint vao[8];
GLuint ubo[4];
GLsizei uboSizes[4];

//terrain params
int terrainProgramID;
size_t terrainVaoID = -1;
GLuint vertexCount = 1000;
GLfloat terrainSpan = 30;
GLfloat noiseScale = 1.50;

//cobblestone
int cobblestoneProgramID;
size_t cobblestoneVaoID;
unsigned int cobbleStoneTex[4];
char* imagePath = NULL;
unsigned char* rawImage = NULL;

GLuint gVertexAttribBuffer[8], gIndexBuffer[8];
GLint gInVertexLoc[8], gInNormalLoc[8];
int gVertexDataSizeInBytes[8], gNormalDataSizeInBytes[8];


void reshape(GLFWwindow* window, int w, int h);


int ParseObj(const string& fileName)
{
    fstream myfile;

    // Open the input 
    myfile.open(fileName.c_str(), std::ios::in);

    if (myfile.is_open())
    {
        string curLine;

        while (getline(myfile, curLine))
        {
            stringstream str(curLine);
            GLfloat c1, c2, c3;
            GLuint index[9];
            string tmp;

            if (curLine.length() >= 2)
            {
                if (curLine[0] == 'v')
                {
                    if (curLine[1] == 't') // texture
                    {
                        str >> tmp; // consume "vt"
                        str >> c1 >> c2;
                        gTextures[numberOfObj].push_back(Texture(c1, c2));
                    }
                    else if (curLine[1] == 'n') // normal
                    {
                        str >> tmp; // consume "vn"
                        str >> c1 >> c2 >> c3;
                        gNormals[numberOfObj].push_back(Normal(c1, c2, c3));
                    }
                    else // vertex
                    {
                        str >> tmp; // consume "v"
                        str >> c1 >> c2 >> c3;
                        gVertices[numberOfObj].push_back(Vertex(c1, c2, c3));
                    }
                }
                else if (curLine[0] == 'f') // face
                {
                    str >> tmp; // consume "f"
					char c;
					int vIndex[3],  nIndex[3], tIndex[3];
					str >> vIndex[0]; str >> c >> c; // consume "//"
					str >> nIndex[0]; 
					str >> vIndex[1]; str >> c >> c; // consume "//"
					str >> nIndex[1]; 
					str >> vIndex[2]; str >> c >> c; // consume "//"
					str >> nIndex[2]; 

                    if(!(vIndex[0] == nIndex[0] &&
                            vIndex[1] == nIndex[1] &&
                            vIndex[2] == nIndex[2]))
                    {
                        cout << "vIndex[0] = " << vIndex[0] << "\t nIndex[0] = " << nIndex[0] << endl;
                        cout << "vIndex[1] = " << vIndex[1] << "\t nIndex[1] = " << nIndex[1] << endl;
                        cout << "vIndex[2] = " << vIndex[2] << "\t nIndex[2] = " << nIndex[2] << endl;
                    }
					assert(vIndex[0] == nIndex[0] &&
						   vIndex[1] == nIndex[1] &&
						   vIndex[2] == nIndex[2]); // a limitation for now

					// make indices start from 0
					for (int c = 0; c < 3; ++c)
					{
						vIndex[c] -= 1;
						nIndex[c] -= 1;
						tIndex[c] -= 1;
					}

                    gFaces[numberOfObj].push_back(Face(vIndex, tIndex, nIndex));
                }
                else
                {
                    //cout << "Ignoring unidentified line in obj file: " << curLine << endl;
                }
            }

            //data += curLine;
            if (!myfile.eof())
            {
                //data += "\n";
            }
        }

        myfile.close();
    }
    else
    {
        return -1;
    }

    //cout << "gVertices: " << gVertices[numberOfObj].size() << endl;
    //cout << "gNormals: " << gNormals[numberOfObj].size() << endl;
	assert(gVertices[numberOfObj].size() == gNormals[numberOfObj].size());

    size_t temp = numberOfObj;
    numberOfObj++;
    pnObjIndices.push_back(temp);
    return temp;
}

int ParseBezierObj(const string& fileName)
{
    fstream myfile;

    // Open the input 
    myfile.open(fileName.c_str(), std::ios::in);

    if (myfile.is_open())
    {
        string curLine;

        while (getline(myfile, curLine))
        {
            stringstream str(curLine);
            GLfloat c1, c2, c3;
            GLuint index[9];
            string tmp;

            if (curLine.length() >= 2)
            {
                if (curLine[0] == 'v')
                {
                    if (curLine[1] == 't') // texture
                    {
                        str >> tmp; // consume "vt"
                        str >> c1 >> c2;
                        gTextures[numberOfObj].push_back(Texture(c1, c2));
                    }
                    else // vertex
                    {
                        str >> tmp; // consume "v"
                        str >> c1 >> c2 >> c3;
                        gVertices[numberOfObj].push_back(Vertex(c1, c2, c3));
                    }
                }
                else if(curLine.substr(0,4) == string("surf"))
                {
                    str >> tmp; //consume "surf"
                    char c;
                    BezierSurface surf;
                    for(int i = 0; i < 16; i++)
                    {
                        str >> surf.vIndices[i];
                        surf.vIndices[i]--;//make indices start from 0
                    }
                    
                    gSurfaces[numberOfObj].push_back(surf);
                    
                }
                else
                {
                    //cout << "Ignoring unidentified line in obj file: " << curLine << endl;
                }
            }

            //data += curLine;
            if (!myfile.eof())
            {
                //data += "\n";
            }
        }

        myfile.close();
    }
    else
    {
        return -1;
    }

    //cout << "gVertices: " << gVertices[numberOfObj].size() << endl;
    //cout << "gNormals: " << gNormals[numberOfObj].size() << endl;

    size_t temp = numberOfObj;
    numberOfObj++;
    bezierObjIndices.push_back(temp);
    return temp;
}

bool ReadDataFromFile(
    const string& fileName, ///< [in]  Name of the shader file
    string&       data)     ///< [out] The contents of the file
{
    fstream myfile;

    // Open the input 
    myfile.open(fileName.c_str(), std::ios::in);

    if (myfile.is_open())
    {
        string curLine;

        while (getline(myfile, curLine))
        {
            data += curLine;
            if (!myfile.eof())
            {
                data += "\n";
            }
        }

        myfile.close();
    }
    else
    {
        return false;
    }

    return true;
}

GLuint createVS(const char* shaderName)
{
    string shaderSource;

    string filename(shaderName);
    if (!ReadDataFromFile(filename, shaderSource))
    {
        cout << "Cannot find file name: " + filename << endl;
        exit(-1);
    }

    GLint length = shaderSource.length();
    const GLchar* shader = (const GLchar*) shaderSource.c_str();

    GLuint vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, &shader, &length);
    glCompileShader(vs);

    char output[1024] = {0};
    glGetShaderInfoLog(vs, 1024, &length, output);
    printf("VS compile log: %s\n", output);

	return vs;
}

GLuint createFS(const char* shaderName)
{
    string shaderSource;

    string filename(shaderName);
    if (!ReadDataFromFile(filename, shaderSource))
    {
        cout << "Cannot find file name: " + filename << endl;
        exit(-1);
    }

    GLint length = shaderSource.length();
    const GLchar* shader = (const GLchar*) shaderSource.c_str();

    GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, &shader, &length);
    glCompileShader(fs);

    char output[1024] = {0};
    glGetShaderInfoLog(fs, 1024, &length, output);
    printf("FS compile log: %s\n", output);

	return fs;
}

GLuint createGS(const char* shaderName)
{
    string shaderSource;

    string filename(shaderName);
    if (!ReadDataFromFile(filename, shaderSource))
    {
        cout << "Cannot find file name: " + filename << endl;
        exit(-1);
    }

    GLint length = shaderSource.length();
    const GLchar* shader = (const GLchar*) shaderSource.c_str();

    GLuint gs = glCreateShader(GL_GEOMETRY_SHADER);
    glShaderSource(gs, 1, &shader, &length);
    glCompileShader(gs);

    char output[1024] = {0};
    glGetShaderInfoLog(gs, 1024, &length, output);
    printf("GS compile log: %s\n", output);

	return gs;
}

GLuint createTESC(const char* shaderName)
{
    string shaderSource;

    string filename(shaderName);
    if (!ReadDataFromFile(filename, shaderSource))
    {
        cout << "Cannot find file name: " + filename << endl;
        exit(-1);
    }

    GLint length = shaderSource.length();
    const GLchar* shader = (const GLchar*) shaderSource.c_str();

    GLuint fs = glCreateShader(GL_TESS_CONTROL_SHADER);
    glShaderSource(fs, 1, &shader, &length);
    glCompileShader(fs);

    char output[1024] = {0};
    glGetShaderInfoLog(fs, 1024, &length, output);
    printf("TESC compile log: %s\n", output);

	return fs;
}

GLuint createTESE(const char* shaderName)
{
    string shaderSource;

    string filename(shaderName);
    if (!ReadDataFromFile(filename, shaderSource))
    {
        cout << "Cannot find file name: " + filename << endl;
        exit(-1);
    }

    GLint length = shaderSource.length();
    const GLchar* shader = (const GLchar*) shaderSource.c_str();

    GLuint fs = glCreateShader(GL_TESS_EVALUATION_SHADER);
    glShaderSource(fs, 1, &shader, &length);
    glCompileShader(fs);

    char output[1024] = {0};
    glGetShaderInfoLog(fs, 1024, &length, output);
    printf("TESE compile log: %s\n", output);

	return fs;
}

size_t initProgram(const char* vsFile ,
                   const char* tcsFile,
                   const char* tesFile,
                   const char* gsFile ,
                   const char* fsFile  )
{
    size_t progIndex = numberOfPrograms; 

    gProgram[progIndex] = glCreateProgram();
    GLuint vs, tcs, tes, gs, fs;

    cout << "Creating program: " << progIndex << endl;
    if(vsFile == NULL)
    {
        fprintf(stderr, "a vertex shader must be provided\n");
    }
    else
    {
        vs = createVS(vsFile);
        glAttachShader(gProgram[progIndex], vs);
    }
    if( tcsFile != NULL)
    {
        tcs = createTESC(tcsFile);
        glAttachShader(gProgram[progIndex], tcs);
    }
    if( tesFile != NULL)
    {
        tes = createTESE(tesFile);
        glAttachShader(gProgram[progIndex], tes);
    }
    if( gsFile != NULL)
    {
        gs = createGS(gsFile);
        glAttachShader(gProgram[progIndex], gs);
    }
    if(fsFile == NULL)
    {
        fprintf(stderr, "a fragment shader must be provided\n");
    }
    else
    {
        fs = createFS(fsFile);
        glAttachShader(gProgram[progIndex], fs);
    }

    glLinkProgram(gProgram[progIndex]);
	GLint status;
	glGetProgramiv(gProgram[progIndex], GL_LINK_STATUS, &status);

	if (status != GL_TRUE)
	{
		cout << "Program link failed, programIndex: " << progIndex << endl;
        glDeleteShader(vs);
        glDeleteShader(fs);
        if(tcsFile != NULL ) {glDeleteShader(tcs);}
        if(tesFile != NULL ) {glDeleteShader(tes);}
        if(gsFile != NULL ) {glDeleteShader(gs);}

        GLint maxLength = 0;
        glGetProgramiv(gProgram[progIndex], GL_INFO_LOG_LENGTH, &maxLength);
        
        char* log = new char[maxLength];
        glGetProgramInfoLog(gProgram[progIndex], maxLength, &maxLength, log);

        printf("program link log: %s\n", log);

        delete[] log;
        
		exit(-1);
	}
    else//link succesfull
    {
        glDetachShader(gProgram[progIndex], vs);
        glDetachShader(gProgram[progIndex], fs);
        if(tcsFile != NULL ) {glDetachShader(gProgram[progIndex], tcs);}
        if(tesFile != NULL ) {glDetachShader(gProgram[progIndex], tes);}
        if(gsFile != NULL ) {glDetachShader(gProgram[progIndex], gs);}
        glDeleteShader(vs);
        glDeleteShader(fs);
        if(tcsFile != NULL ) {glDeleteShader(tcs);}
        if(tesFile != NULL ) {glDeleteShader(tes);}
        if(gsFile != NULL ) {glDeleteShader(gs);}
    }
		modelingMatrixLoc[progIndex] = glGetUniformLocation(gProgram[progIndex], "modelingMatrix");
		viewingMatrixLoc[progIndex] = glGetUniformLocation(gProgram[progIndex], "viewingMatrix");
		projectionMatrixLoc[progIndex] = glGetUniformLocation(gProgram[progIndex], "projectionMatrix");
		eyePosLoc[progIndex] = glGetUniformLocation(gProgram[progIndex], "eyePos");
		tessInnerLoc[progIndex] = glGetUniformLocation(gProgram[progIndex], "tessInner");
		tessOuterLoc[progIndex] = glGetUniformLocation(gProgram[progIndex], "tessOuter");
    cout << endl;
    numberOfPrograms++;
    return progIndex;
}

void initShaders()
{
	// Create the programs

    gProgram[0] = glCreateProgram();
	gProgram[1] = glCreateProgram();

	// Create the shaders for both programs

    GLuint vs1 = createVS("vert.glsl");
    GLuint fs1 = createFS("frag.glsl");

    cout<< endl;
	GLuint vs2 = createVS("vert2.glsl");
	GLuint tcs2 = createTESC("fur.tesc");
	GLuint tes2 = createTESE("fur.tese");
	GLuint fs2 = createFS("fur.frag");

	// Attach the shaders to the programs

	glAttachShader(gProgram[0], vs1);
	glAttachShader(gProgram[0], fs1);

	glAttachShader(gProgram[1], vs2);
	glAttachShader(gProgram[1], fs2);
	glAttachShader(gProgram[1], tcs2);
	glAttachShader(gProgram[1], tes2);

	// Link the programs

    glLinkProgram(gProgram[0]);
	GLint status;
	glGetProgramiv(gProgram[0], GL_LINK_STATUS, &status);

	if (status != GL_TRUE)
	{
		cout << "Program link failed" << endl;
		exit(-1);
	}

	glLinkProgram(gProgram[1]);
	glGetProgramiv(gProgram[1], GL_LINK_STATUS, &status);

	if (status != GL_TRUE)
	{
		cout << "Program link failed" << endl;
        
        GLint maxLength = 0;
        glGetProgramiv(gProgram[1], GL_INFO_LOG_LENGTH, &maxLength);
        
        char* log = new char[maxLength];
        glGetProgramInfoLog(gProgram[1], maxLength, &maxLength, log);

        printf("program link log: %s\n", log);

        delete[] log;
		exit(-1);
	}
    glPatchParameteri(GL_PATCH_VERTICES, 3);

	// Get the locations of the uniform variables from both programs

	for (int i = 0; i < 1; ++i)
	{
		modelingMatrixLoc[i] = glGetUniformLocation(gProgram[i], "modelingMatrix");
		viewingMatrixLoc[i] = glGetUniformLocation(gProgram[i], "viewingMatrix");
		projectionMatrixLoc[i] = glGetUniformLocation(gProgram[i], "projectionMatrix");
		eyePosLoc[i] = glGetUniformLocation(gProgram[i], "eyePos");
		tessInnerLoc[i] = glGetUniformLocation(gProgram[i], "tessInner");
		tessOuterLoc[i] = glGetUniformLocation(gProgram[i], "tessOuter");
	}
}

//void initFurShaders()
//{
//}

void initVBO(size_t objId)
{
    glGenVertexArrays(1, &vao[objId]);
    assert(vao[objId] > 0);
    glBindVertexArray(vao[objId]);
    cout << "vao = " << vao[objId] << endl;

	glEnableVertexAttribArray(0);
	glEnableVertexAttribArray(1);
	assert(glGetError() == GL_NONE);

	glGenBuffers(1, &gVertexAttribBuffer[objId]);
	glGenBuffers(1, &gIndexBuffer[objId]);

	assert(gVertexAttribBuffer[objId] > 0 && gIndexBuffer[objId] > 0);

	glBindBuffer(GL_ARRAY_BUFFER, gVertexAttribBuffer[objId]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBuffer[objId]);

	gVertexDataSizeInBytes[objId] = gVertices[objId].size() * 3 * sizeof(GLfloat);
	gNormalDataSizeInBytes[objId] = gNormals[objId].size() * 3 * sizeof(GLfloat);
	int indexDataSizeInBytes = gFaces[objId].size() * 3 * sizeof(GLuint);
	GLfloat* vertexData = new GLfloat [gVertices[objId].size() * 3];
	GLfloat* normalData = new GLfloat [gNormals[objId].size() * 3];
	GLuint* indexData = new GLuint [gFaces[objId].size() * 3];

    float minX = 1e6, maxX = -1e6;
    float minY = 1e6, maxY = -1e6;
    float minZ = 1e6, maxZ = -1e6;

	for (int i = 0; i < gVertices[objId].size(); ++i)
	{
		vertexData[3*i] = gVertices[objId][i].x;
		vertexData[3*i+1] = gVertices[objId][i].y;
		vertexData[3*i+2] = gVertices[objId][i].z;

        minX = std::min(minX, gVertices[objId][i].x);
        maxX = std::max(maxX, gVertices[objId][i].x);
        minY = std::min(minY, gVertices[objId][i].y);
        maxY = std::max(maxY, gVertices[objId][i].y);
        minZ = std::min(minZ, gVertices[objId][i].z);
        maxZ = std::max(maxZ, gVertices[objId][i].z);
	}

    std::cout << "minX = " << minX << std::endl;
    std::cout << "maxX = " << maxX << std::endl;
    std::cout << "minY = " << minY << std::endl;
    std::cout << "maxY = " << maxY << std::endl;
    std::cout << "minZ = " << minZ << std::endl;
    std::cout << "maxZ = " << maxZ << std::endl;
    std::cout << "total vertex count = " << gVertices[objId].size() << '\n' << std::endl;
    
    objCenters[objId] = glm::vec4((minX + maxX)/2.f,
                                  (minY + maxY)/2.f,
                                  (minZ + maxZ)/2.f,
                                  1.f);


	for (int i = 0; i < gNormals[objId].size(); ++i)
	{
		normalData[3*i] = gNormals[objId][i].x;
		normalData[3*i+1] = gNormals[objId][i].y;
		normalData[3*i+2] = gNormals[objId][i].z;
	}

	for (int i = 0; i < gFaces[objId].size(); ++i)
	{
		indexData[3*i] = gFaces[objId][i].vIndex[0];
		indexData[3*i+1] = gFaces[objId][i].vIndex[1];
		indexData[3*i+2] = gFaces[objId][i].vIndex[2];
	}


	glBufferData(GL_ARRAY_BUFFER, gVertexDataSizeInBytes[objId] + gNormalDataSizeInBytes[objId], 0, GL_STATIC_DRAW);
	glBufferSubData(GL_ARRAY_BUFFER, 0, gVertexDataSizeInBytes[objId], vertexData);
	glBufferSubData(GL_ARRAY_BUFFER, gVertexDataSizeInBytes[objId], gNormalDataSizeInBytes[objId], normalData);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexDataSizeInBytes, indexData, GL_STATIC_DRAW);

	// done copying; can free now
	delete[] vertexData;
	delete[] normalData;
	delete[] indexData;

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(gVertexDataSizeInBytes[objId]));
}

void initBezierVBO(size_t objId)
{
    glGenVertexArrays(1, &vao[objId]);
    assert(vao[objId] > 0);
    glBindVertexArray(vao[objId]);
    cout << "bezier vao = " << vao[objId] << endl;

	glEnableVertexAttribArray(0);
	//glEnableVertexAttribArray(1);
	assert(glGetError() == GL_NONE);

	glGenBuffers(1, &gVertexAttribBuffer[objId]);
	glGenBuffers(1, &gIndexBuffer[objId]);

	assert(gVertexAttribBuffer[objId] > 0 && gIndexBuffer[objId] > 0);

	glBindBuffer(GL_ARRAY_BUFFER, gVertexAttribBuffer[objId]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBuffer[objId]);

	gVertexDataSizeInBytes[objId] = gVertices[objId].size() * 3 * sizeof(GLfloat);
	//gNormalDataSizeInBytes[objId] = gNormals[objId].size() * 3 * sizeof(GLfloat);
	int indexDataSizeInBytes = gSurfaces[objId].size() * 16 * sizeof(GLuint);
	GLfloat* vertexData = new GLfloat [gVertices[objId].size() * 3];
	//GLfloat* normalData = new GLfloat [gNormals[objId].size() * 3];
	GLuint* indexData = new GLuint [gSurfaces[objId].size() * 16];

    float minX = 1e6, maxX = -1e6;
    float minY = 1e6, maxY = -1e6;
    float minZ = 1e6, maxZ = -1e6;

	for (int i = 0; i < gVertices[objId].size(); ++i)
	{
		vertexData[3*i] = gVertices[objId][i].x;
		vertexData[3*i+1] = gVertices[objId][i].y;
		vertexData[3*i+2] = gVertices[objId][i].z;

        minX = std::min(minX, gVertices[objId][i].x);
        maxX = std::max(maxX, gVertices[objId][i].x);
        minY = std::min(minY, gVertices[objId][i].y);
        maxY = std::max(maxY, gVertices[objId][i].y);
        minZ = std::min(minZ, gVertices[objId][i].z);
        maxZ = std::max(maxZ, gVertices[objId][i].z);
	}

    std::cout << "minX = " << minX << std::endl;
    std::cout << "maxX = " << maxX << std::endl;
    std::cout << "minY = " << minY << std::endl;
    std::cout << "maxY = " << maxY << std::endl;
    std::cout << "minZ = " << minZ << std::endl;
    std::cout << "maxZ = " << maxZ << std::endl;
    std::cout << "total patch count = " << gSurfaces[objId].size() << '\n' << std::endl;

	//for (int i = 0; i < gNormals[objId].size(); ++i)
	//{
	//	normalData[3*i] = gNormals[objId][i].x;
	//	normalData[3*i+1] = gNormals[objId][i].y;
	//	normalData[3*i+2] = gNormals[objId][i].z;
	//}

	for (int i = 0; i < gSurfaces[objId].size(); ++i)
	{
        for(int j = 0; j < 16; ++j)
        {
            indexData[16*i + j] = gSurfaces[objId][i].vIndices[j];
        }
	}


	glBufferData(GL_ARRAY_BUFFER, gVertexDataSizeInBytes[objId] /*+ gNormalDataSizeInBytes[objId]*/, 0, GL_STATIC_DRAW);
	glBufferSubData(GL_ARRAY_BUFFER, 0, gVertexDataSizeInBytes[objId], vertexData);
	//glBufferSubData(GL_ARRAY_BUFFER, gVertexDataSizeInBytes[objId], gNormalDataSizeInBytes[objId], normalData);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexDataSizeInBytes, indexData, GL_STATIC_DRAW);

	// done copying; can free now
	delete[] vertexData;
	//delete[] normalData;
	delete[] indexData;

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	//glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(gVertexDataSizeInBytes[objId]));
}

void initUBO()
{
    glGenBuffers(1, &ubo[0]);
    glBindBuffer(GL_UNIFORM_BUFFER, ubo[0]);

    //vec3 causes alignment problems so we just allocate space for 4 matrices
    uboSizes[0] = sizeof(glm::mat4) * 4 ;//matrices
    //uboSizes[1] = sizeof(GLfloat)*3;//tessLevels
    uboSizes[1] = sizeof(glm::mat4) * 4;//tessLevels
    //uboSizes[2] = sizeof(GLfloat)*8 + sizeof(GLuint)+ sizeof(glm::mat4);//hairParams
    uboSizes[2] = sizeof(glm::mat4)*4;
    uboSizes[3] = sizeof(GLint) + sizeof(GLfloat);

    GLsizei totalBufferSize = 0; 
    for(int i = 0; i < 4; ++i)
    {
        totalBufferSize += uboSizes[i];
    }
    std::cout << "total UBO size = " << totalBufferSize << std::endl;

    glBufferData(GL_UNIFORM_BUFFER, totalBufferSize, 0, GL_DYNAMIC_COPY);

    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    size_t uboOffset = 0;
    //glBindBufferRange(GL_UNIFORM_BUFFER, 0, ubo[0], 0, uboSizes[0]+uboSizes[1]);
    //matrices
    glBindBufferRange(GL_UNIFORM_BUFFER, 0, ubo[0], uboOffset, uboSizes[0]);
    uboOffset += uboSizes[0];
    //tessLevels
    glBindBufferRange(GL_UNIFORM_BUFFER, 1, ubo[0], uboOffset, uboSizes[1]);
    uboOffset += uboSizes[1];
    //hairParams
    glBindBufferRange(GL_UNIFORM_BUFFER, 2, ubo[0], uboOffset, uboSizes[2]);
    uboOffset += uboSizes[2];
    //furColorParams
    glBindBufferRange(GL_UNIFORM_BUFFER, 3, ubo[0], uboOffset, uboSizes[3]);

    //GLuint uniformBlockIndex;
    //GLsizei uniformBlockSize;
    //uniformBlockIndex = glGetUniformBlockIndex(gProgram[1], "matrices");
    //glGetActiveUniformBlockiv(gProgram[1], uniformBlockIndex,
    //                                 GL_UNIFORM_BLOCK_DATA_SIZE,
    //                                 &uniformBlockSize);
    ////cout << "matrices size: " << uniformBlockSize << endl;

    //uniformBlockIndex = glGetUniformBlockIndex(gProgram[1], "tessLevels");
    //glGetActiveUniformBlockiv(gProgram[1], uniformBlockIndex,
    //                                 GL_UNIFORM_BLOCK_DATA_SIZE,
    //                                 &uniformBlockSize);
    //
    //cout << "tessLevelsSize:  " << uniformBlockSize << endl;
    //cout << "float " << sizeof(GLfloat) << endl;
    //cout << "uint " << sizeof(GLuint) << endl;
    //cout << "mat4 " << sizeof(glm::mat4) << endl;
    //cout << "vec3 " << sizeof(glm::vec3) << endl;
    //cout << "ubosizes " << uboSizes[0]  << endl;
    ////// init UBO 2 
    glGenBuffers(1, &ubo[1]);
    glBindBuffer(GL_UNIFORM_BUFFER, ubo[1]);
    size_t posSizes = sizeof(glm::vec4);
    //glBufferData(GL_UNIFORM_BUFFER, posSizes, 0, GL_DYNAMIC_DRAW);
    glBufferData(GL_UNIFORM_BUFFER, posSizes, 0, GL_DYNAMIC_COPY);
    
    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    glBindBufferRange(GL_UNIFORM_BUFFER, 10, ubo[1], 0, posSizes);
}

void updateObjCenterUBO(size_t objIndex)
{
    glBindBuffer(GL_UNIFORM_BUFFER, ubo[1]);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, sizeof(glm::vec4), glm::value_ptr(objCenters[objIndex]));

    glBindBuffer(GL_UNIFORM_BUFFER, 0);
}

void updateUniforms()
{
    //glFinish();
    glBindBuffer(GL_UNIFORM_BUFFER, ubo[0]);

    //matrices block


    size_t uboOffset = 0;
    glBufferSubData(GL_UNIFORM_BUFFER, 0                    , sizeof(glm::mat4), glm::value_ptr(modelingMatrix));
    glBufferSubData(GL_UNIFORM_BUFFER, 1 * sizeof(glm::mat4), sizeof(glm::mat4), glm::value_ptr(viewingMatrix));
    glBufferSubData(GL_UNIFORM_BUFFER, 2 * sizeof(glm::mat4), sizeof(glm::mat4), glm::value_ptr(projectionMatrix));
    glBufferSubData(GL_UNIFORM_BUFFER, 3 * sizeof(glm::mat4), sizeof(glm::vec3), glm::value_ptr(eyePos));

    //upload tesselation levels
    //glBufferSubData(GL_UNIFORM_BUFFER, uboSizes[0]  -1 * sizeof(GLfloat), sizeof(GLfloat), &tessInner);
    uboOffset += uboSizes[0];
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 0 * sizeof(GLfloat), sizeof(GLfloat), &tessInner);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 1 * sizeof(GLfloat), sizeof(GLfloat), &tessOuter);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 2 * sizeof(GLfloat), sizeof(GLfloat), &levelOfDetail);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 3 * sizeof(GLfloat), sizeof(GLint), &viewDependantTesselation);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 4 * sizeof(GLfloat), sizeof(GLint), &cameraFov);

    //upload hair parameters
    uboOffset += uboSizes[1];
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 0 * sizeof(GLfloat), sizeof(GLfloat), &hairLen);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 1 * sizeof(GLfloat), sizeof(GLfloat), &hairDetail);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 2 * sizeof(GLfloat), sizeof(GLfloat), &hairCurveAngle);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 3 * sizeof(GLfloat), sizeof(GLuint), &hairCount);

    //furColorParams
    uboOffset += uboSizes[2];
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 0 * sizeof(GLint), sizeof(GLfloat), &enableFurColor);
    glBufferSubData(GL_UNIFORM_BUFFER, uboOffset + 1 * sizeof(GLint), sizeof(GLfloat), &furColorPerlinParam);

    glBindBuffer(GL_UNIFORM_BUFFER, 0);
}

int initTerrain()
{
    
    gVertices[numberOfObj].push_back(Vertex(0.0f, 0.0f, 0.0f));
    gNormals[numberOfObj].push_back(Normal(0, 1, 0));

    int index[3];
    index[0] = 0;
    index[1] = 0;
    index[2] = 0;
    gFaces[numberOfObj].push_back(Face(index, index, index));

    int temp = numberOfObj;
    numberOfObj++;
    return temp;
}

//void initTexture()
//{
//    char *images[3];
//    images[0] = strdup("brick.jpg");
//    images[1] = strdup("brick_BUMP.png");
//    images[2] = strdup("brick_SPEC.png");
//
//    char * uniformTexNames[3];
//    uniformTexNames[0] = strdup("cobbleStoneTex");
//    uniformTexNames[1] = strdup("cobbleStoneBumpMap");
//    uniformTexNames[2] = strdup("cobbleStoneSpecMap");
//
//    for(int i = 0; i < 3; i++)
//    {
//        imagePath = strdup(images[i]);
//        glGenTextures(1, &cobbleStoneTex[i]);
//        glActiveTexture(GL_TEXTURE0 + i);
//        glBindTexture(GL_TEXTURE_2D, cobbleStoneTex[i]);
//
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
//
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//
//        int width, height, nrChannels;
//        rawImage = load_image(imagePath, &width, &height, &nrChannels);
//        //rawImage = load_image("brick.jpg", &width, &height, &nrChannels);
//        //flagAspecRat = (float)width/height;
//
//        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, rawImage);
//        glGenerateMipmap(GL_TEXTURE_2D);
//
//        glUseProgram(gProgram[cobblestoneProgramID]);
//        glUniform1i(glGetUniformLocation(gProgram[cobblestoneProgramID], uniformTexNames[i]), 0);
//        //std::cout << "get error: " << glGetError() << std::endl;
//
//        free(rawImage);
//        free(images[i]);
//        free(uniformTexNames[i]);
//    }
//}

void init() 
{
    glEnable(GL_DEPTH_TEST);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);
    if(backFaceCulling)
    {
        glEnable(GL_CULL_FACE);
    }

    //init programs
    if(program_arg != BEZIER_ONLY)
    {
        pnProgramIndex =  initProgram("pn-triangles.vert",
                                      "pn-triangles.tesc",
                                      "pn-triangles.tese",
                                      NULL,
                                      "pn-triangles.frag");

        furProgramIndex = initProgram("fur.vert",
                                      "fur.tesc",
                                      "fur.tese",
                                      NULL,
                                      "fur.frag");
    }
    
    if(program_arg == BEZIER_ONLY || program_arg == PN_VS_BEZIER)
    {
        bezierProgramIndex = initProgram("bezier.vert",
                                         "bezier.tesc",
                                         "bezier.tese",
                                         NULL,
                                         "bezier.frag");
        ParseBezierObj("bezier-teapot.obj");
        initBezierVBO(bezierObjIndices[0]);
    }
    switch(program_arg)
    {
        case PN_ONLY:
            ParseObj(string(objFileName));
            break;
        case PN_VS_BEZIER:
            ParseObj("teapot.obj");
            break;
        case PN_ALL:
            ParseObj("teapot.obj");
            ParseObj("bunny.obj");
            ParseObj("suzanne.obj");
            ParseObj("armadillo.obj");
            break;

        case BEZIER_ONLY:
            break;
        default:
            break;
    }
                
    for(int i = 0; i < pnObjIndices.size(); i++)
    {
        initVBO(pnObjIndices[i]);
    }

    initUBO();
    updateUniforms();
}

void drawModel(size_t objId)
{
    glBindVertexArray(vao[objId]);
	glBindBuffer(GL_ARRAY_BUFFER, gVertexAttribBuffer[objId]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBuffer[objId]);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(gVertexDataSizeInBytes[objId]));


    glPatchParameteri(GL_PATCH_VERTICES, 3);
    //glDrawElements(GL_PATCHES,  3 * 350, GL_UNSIGNED_INT, 0);
    glDrawElements(GL_PATCHES, gFaces[objId].size() * 3, GL_UNSIGNED_INT, 0);
}

void drawBezierModel(size_t objId)
{
    glUseProgram(gProgram[bezierProgramIndex]);
    glBindVertexArray(vao[objId]);
	glBindBuffer(GL_ARRAY_BUFFER, gVertexAttribBuffer[objId]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBuffer[objId]);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	//glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(gVertexDataSizeInBytes[objId]));


    glPatchParameteri(GL_PATCH_VERTICES, 16);
    glDrawElements(GL_PATCHES, gSurfaces[objId].size() * 16, GL_UNSIGNED_INT, 0);
}


//void drawCobblestone(size_t terrainId)
//{
//	glUseProgram(gProgram[cobblestoneProgramID]);
//	//glUniformMatrix4fv(projectionMatrixLoc[activeProgramIndex], 1, GL_FALSE, glm::value_ptr(projectionMatrix));
//	//glUniformMatrix4fv(viewingMatrixLoc[activeProgramIndex], 1, GL_FALSE, glm::value_ptr(viewingMatrix));
//	//glUniformMatrix4fv(modelingMatrixLoc[activeProgramIndex], 1, GL_FALSE, glm::value_ptr(modelingMatrix));
//	//glUniform3fv(eyePosLoc[activeProgramIndex], 1, glm::value_ptr(eyePos));
//    /////////
//
//    glBindVertexArray(vao[terrainId]);
//	glBindBuffer(GL_ARRAY_BUFFER, gVertexAttribBuffer[terrainId]);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBuffer[terrainId]);
//
//	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
//	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(gVertexDataSizeInBytes[terrainId]));
//
//	//glDrawElementsInstanced(GL_POINTS, gFaces[terrainId].size(), GL_UNSIGNED_INT, 0, 1000*1000);
//    glPatchParameteri(GL_PATCH_VERTICES, 1);
//	glDrawElements(GL_PATCHES, gFaces[terrainId].size(), GL_UNSIGNED_INT, 0);
//}
//void drawTerrain(size_t terrainId)
//{
//	glUseProgram(gProgram[terrainProgramID]);
//
//    glBindVertexArray(vao[terrainId]);
//	glBindBuffer(GL_ARRAY_BUFFER, gVertexAttribBuffer[terrainId]);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBuffer[terrainId]);
//
//	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
//	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(gVertexDataSizeInBytes[terrainId]));
//
//	//glDrawElementsInstanced(GL_POINTS, gFaces[terrainId].size(), GL_UNSIGNED_INT, 0, 1000*1000);
//	glDrawElementsInstanced(GL_POINTS, gFaces[terrainId].size(), GL_UNSIGNED_INT, 0, vertexCount*vertexCount);
//}

void display(GLFWwindow* window)
{

    reshape(window, width, height);
    glClearColor(0, 0, 0, 1);
    glClearDepth(1.0f);
    glClearStencil(0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    float bezierTeapotAngle = -90.f;
    float bezierAngleInRad = (bezierTeapotAngle/180.f)*M_PI;
    const float dist = 5;
    glm::mat4 matT[4];
    matT[0]= glm::translate(glm::mat4(1.f), glm::vec3(3.5f , -5.f, -4.2f));
    matT[1]= glm::translate(glm::mat4(1.f), glm::vec3(-2.5, -4.f, -2.2f));
    matT[2]= glm::translate(glm::mat4(1.f), glm::vec3(2.75f,  3.5f, 0.0f));
    matT[3]= glm::translate(glm::mat4(1.f), glm::vec3(-2  ,  3.f, 0.f));
    modelingMatrix = glm::mat4(1);

	// Draw the scene
    switch(program_arg)
    {
        case PN_ONLY:
            glUseProgram(gProgram[pnProgramIndex]);
            if(strcmp("armadillo.obj", objFileName) == 0)
            {
                modelingMatrix = glm::rotate(glm::mat4(1.f),
                                         float(M_PI),
                                         glm::vec3(0.f,1.f,0.f));
                updateUniforms();
            }
            updateObjCenterUBO(pnObjIndices[0]);
            drawModel(pnObjIndices[0]);

            if(enableFur)
            {
                glUseProgram(gProgram[furProgramIndex]);
                drawModel(pnObjIndices[0]);
            }
            break;
        case PN_VS_BEZIER:
            glViewport(0, 0, width/2, height);
            glUseProgram(gProgram[pnProgramIndex]);
            drawModel(pnObjIndices[0]);

            if(enableFur)
            {
                glUseProgram(gProgram[furProgramIndex]);
                drawModel(pnObjIndices[0]);
            }

            glViewport(width/2, 0, width/2, height);
            //fall through
        case BEZIER_ONLY:
            modelingMatrix = glm::rotate(glm::mat4(1.f),
                                         bezierAngleInRad,
                                         glm::vec3(1.f,0.f,0.f));
            updateUniforms();
            glUseProgram(gProgram[bezierProgramIndex]);
            drawBezierModel(bezierObjIndices[0]);
            break;
        case PN_ALL:
            for(int i = 0; i < pnObjIndices.size(); ++i)
            {

                modelingMatrix = glm::mat4(1.f);
                if(i == 3)//armadillo
                {
                    modelingMatrix = glm::rotate(glm::mat4(1.f),
                            float(M_PI),
                            glm::vec3(0.f,1.f,0.f));
                }
                modelingMatrix = matT[i] * modelingMatrix;
                updateUniforms();
                glUseProgram(gProgram[pnProgramIndex]);
                drawModel(pnObjIndices[i]);
                if(enableFur)
                {
                    glUseProgram(gProgram[furProgramIndex]);
                    drawModel(pnObjIndices[i]);
                }
            }

            break;
        default:
            break;
    }
    modelingMatrix = glm::mat4(1.f);
}

void reshape(GLFWwindow* window, int w, int h)
{
    w = w < 1 ? 1 : w;
    h = h < 1 ? 1 : h;

    gWidth = w;
    gHeight = h;

    glViewport(0, 0, w, h);
    //glViewport(w/2, 0, w/2, h);
    //glViewport(0, 0, w/2, h);

    //handle euler angles
    eyePos += cameraFront * cameraSpeed;

    float yawInRads = (yaw/180) * M_PI;
    float pitchInRads = (pitch/180) * M_PI;

    glm::vec3 cameraDir;
    cameraDir.x = cos(yawInRads) * cos(pitchInRads);
    cameraDir.y = sin(pitchInRads);
    cameraDir.z = sin(yawInRads) * cos(pitchInRads);

    cameraFront = glm::normalize(cameraDir);

	// Use perspective projection
	float fovyRad = (float) (cameraFov / 180.0) * M_PI;
    float aspectRat = (float) 1.0f;
	projectionMatrix = glm::perspective(fovyRad, aspectRat, 0.1f, 80.0f);

    viewingMatrix = glm::lookAt(eyePos,
                                eyePos + cameraFront,
                                glm::normalize(cameraUp));
}

void keyboard(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
    {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
    else if (key == GLFW_KEY_G && action == GLFW_PRESS)
    {
        enableFur = !enableFur;
    }
    else if (key == GLFW_KEY_3 && action == GLFW_PRESS)
    {
        backFaceCulling = !backFaceCulling;
        if(backFaceCulling)
        {
            glEnable(GL_CULL_FACE);
            cout << "backface culling: ON" << endl;
        }
        else
        {
            glDisable(GL_CULL_FACE);
            cout << "backface culling: OFF" << endl;
        }
    }
    else if (key == GLFW_KEY_1 && action == GLFW_PRESS)
    {
        viewDependantTesselation = !viewDependantTesselation;
        if(viewDependantTesselation)
        {
            cout << "view dependant tesselation: ON" << endl;
        }
        else
        {
            cout << "view dependant tesselation: OFF" << endl;
        }
    }
    else if (key == GLFW_KEY_2 && action == GLFW_PRESS)
    {

        if(wireframeMode)
        {
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        }
        else
        {
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        }
        wireframeMode = !wireframeMode;
    }
    else if (key == GLFW_KEY_0 && action == GLFW_PRESS)//fur colors
    {
        enableFurColor = !enableFurColor;
        std::cout << "colors: " << enableFurColor << std::endl;
    }

    if (glfwGetKey(window, GLFW_KEY_8) == GLFW_PRESS)
    {
        furColorPerlinParam -= 0.08;
    }
    else if (glfwGetKey(window, GLFW_KEY_9) == GLFW_PRESS)
    {
        furColorPerlinParam += 0.08;
    }

    const float cameraSensitivity = 11.65f; // adjust accordingly
    const float cameraAcc = 0.35f;
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
    {
        //eyePos += cameraFront * cameraSensitivity * deltaTime;
        cameraSpeed += cameraAcc * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
    {
        //eyePos -= cameraFront * cameraSensitivity * deltaTime;
        cameraSpeed -= cameraAcc * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_C) == GLFW_PRESS)
    {
        //eyePos -= cameraFront * cameraSensitivity * deltaTime;
        cameraSpeed = 0.f;
    }
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
    {
        eyePos -= glm::normalize(glm::cross(cameraFront, cameraUp)) * cameraSensitivity * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
    {
        eyePos += glm::normalize(glm::cross(cameraFront, cameraUp)) * cameraSensitivity * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_Q) == GLFW_PRESS)
    {
        eyePos -= glm::normalize(cameraUp) * cameraSensitivity * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_E) == GLFW_PRESS)
    {
        eyePos += glm::normalize(cameraUp) * cameraSensitivity * deltaTime;
    }


    //if (glfwGetKey(window, GLFW_KEY_I) == GLFW_PRESS)
    //{
    //    pitch += 1.5f;
    //    if (pitch > 89.0f)
    //        pitch = 89.0f;
    //}
    //if (glfwGetKey(window, GLFW_KEY_K) == GLFW_PRESS)
    //{
    //    pitch -= 1.5f;
    //    if (pitch < -89.0f)
    //        pitch = -89.0f;
    //}

    //if (glfwGetKey(window, GLFW_KEY_L) == GLFW_PRESS)
    //{
    //    yaw += 1.5f;
    //}
    //if (glfwGetKey(window, GLFW_KEY_J) == GLFW_PRESS)
    //{
    //    yaw -= 1.5f;
    //}

    //zoom out 
    if (glfwGetKey(window, GLFW_KEY_Z) == GLFW_PRESS)
    {
        cameraFov += 1.0f;
    }//zoom in
    else if (glfwGetKey(window, GLFW_KEY_X) == GLFW_PRESS)
    {
        cameraFov -= 1.0f;
    }

    if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS)
    {
        if(tessOuter > 1.99)
        {
            tessOuter -= 1.0;
            cout << "tessOuter: " << tessOuter << endl;
        }
    }
    else if (glfwGetKey(window, GLFW_KEY_T) == GLFW_PRESS)
    {
        if((float)64 >= tessOuter + 1.0)
        {
            tessOuter += 1.0;
            cout << "tessOuter: " << tessOuter << endl;
        }
    }
    if (glfwGetKey(window, GLFW_KEY_Y) == GLFW_PRESS)
    {
        if(tessInner > 1.99)
        {
            tessInner -= 1.0f;
            cout << "tessInner: " << tessInner << endl;
        }
    }
    else if (glfwGetKey(window, GLFW_KEY_U) == GLFW_PRESS)
    {
        if((float)64 >= tessInner + 1.0)
        {
            tessInner += 1.0;
            cout << "tessInner: " << tessInner << endl;
        }
    }
    if (glfwGetKey(window, GLFW_KEY_O) == GLFW_PRESS)
    {
        if(levelOfDetail > 1.0)
        {
            levelOfDetail -= 0.3f;
            cout << "levelOfDetail: " << levelOfDetail << endl;
        }
    }
    else if (glfwGetKey(window, GLFW_KEY_P) == GLFW_PRESS)
    {
        if((float)64 >= levelOfDetail + 1.0)
        {
            levelOfDetail += 0.3;
            cout << "levelOfDetail: " << levelOfDetail << endl;
        }
    }

    if (glfwGetKey(window, GLFW_KEY_H) == GLFW_PRESS)
    {
        if(hairCount > 1)
        {
            hairCount--;
            cout << "hairCount: " << hairCount << endl;
        }
    }
    else if (glfwGetKey(window, GLFW_KEY_J) == GLFW_PRESS)
    {
        if(hairCount < 63)
        {
            hairCount++;
            cout << "hairCount: " << hairCount << endl;
        }
    }
    
    if (glfwGetKey(window, GLFW_KEY_V) == GLFW_PRESS)
    {
        if(hairDetail > 1.f)
        {
            hairDetail -= 1.0;
            cout << "hairDetail: " << hairDetail << endl;
        }
    }
    if (glfwGetKey(window, GLFW_KEY_B) == GLFW_PRESS)
    {
        hairDetail += 1.0;
        cout << "hairDetail: " << hairDetail<< endl;
    }
    if (glfwGetKey(window, GLFW_KEY_K) == GLFW_PRESS)
    {
        hairLen -= 0.008;
        cout << "hairLen: " << hairLen << endl;
    }
    else if (glfwGetKey(window, GLFW_KEY_L) == GLFW_PRESS)
    {
        hairLen += 0.008;
        cout << "hairLen: " << hairLen << endl;
    }
    if (glfwGetKey(window, GLFW_KEY_N) == GLFW_PRESS)
    {
        hairCurveAngle -= 0.05;
    }
    else if (glfwGetKey(window, GLFW_KEY_M) == GLFW_PRESS)
    {
        hairCurveAngle += 0.05;
    }
}

void scrollCallBack(GLFWwindow* window, double xOffset, double yOffset)
{
    float sensitivity = 2.1f; 

    cameraFov -= yOffset * sensitivity;
}

void mouseCallBack(GLFWwindow* window, double xposIn, double yposIn)
{

    float xpos = static_cast<float>(xposIn);
    float ypos = static_cast<float>(yposIn);

    static bool mouseInit = true;
    if (mouseInit)
    {
        lastX = xpos;
        lastY = ypos;
        mouseInit = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos; // reversed since y-coordinates go from bottom to top
    lastX = xpos;
    lastY = ypos;


    if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT) != GLFW_PRESS)
    {
        return;
    }

    float sensitivity = 0.1f; // change this value to your liking
    sensitivity *= sqrt(cameraFov / INITIAL_FOV);

    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw += xoffset;
    pitch += yoffset;

    // make sure that when pitch is out of bounds, screen doesn't get flipped
    if (pitch > 89.0f)
        pitch = 89.0f;
    if (pitch < -89.0f)
        pitch = -89.0f;
}

void mainLoop(GLFWwindow* window)
{
    while (!glfwWindowShouldClose(window))
    {
        deltaTime = currentTime - lastTime;
        lastTime = currentTime;
        currentTime = glfwGetTime();

        display(window);
        //drawTerrain(terrainVaoID);
        //drawCobblestone(cobblestoneVaoID);
        glfwSwapBuffers(window);
        glfwPollEvents();
        //cout << "glError: " <<  glGetError() << endl;

        updateUniforms();
    }
}


void APIENTRY messageCallBack(GLenum source,
                 GLenum type,
                 GLuint id,
                 GLenum severity,
                 GLsizei length,
                 const GLchar* message,
                 const void* userParam )
{
  fprintf( stderr, "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
           ( type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : "" ),
            type, severity, message );
}




int main(int argc, char** argv)   // Create Main Function For Bringing It All Together
{
    if(argc > 1) 
    {
        if(strcmp(argv[1], "--pn") == 0)
        {
            program_arg = PN_ONLY;
            if(argc > 2 )//check filename
            {
                if(access(argv[2], R_OK) == 0)
                {
                    objFileName = strdup(argv[2]);
                }
                else
                {
                    cerr << "Failed find the file: " << argv[2] << '\n' << endl;
                }
            }
        }
        else if(strcmp(argv[1], "--bezier") == 0)
        {
            program_arg = BEZIER_ONLY;
        }
        else if(strcmp(argv[1], "--teapot-cmp") == 0)
        {
            program_arg = PN_VS_BEZIER;
        }
        else if(strcmp(argv[1], "--pn-all") == 0)
        {
            program_arg = PN_ALL;
        }
        else
        {
            program_arg = PN_ONLY;
        }
    }
    else
    {
            program_arg = PN_ONLY;
    }
    if(objFileName == NULL)
    {
        objFileName = strdup("bunny.obj");
    }

    GLFWwindow* window;
    if (!glfwInit())
    {
        exit(-1);
    }

    //glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    //glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    //glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_COMPAT_PROFILE);
    //glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    //TODO disable debug 
    //glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);//TODO remove for the final program

    window = glfwCreateWindow(width, height, "Simple Example", NULL, NULL);

    if (!window)
    {
        glfwTerminate();
        exit(-1);
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // Initialize GLEW to setup the OpenGL Function pointers
    if (GLEW_OK != glewInit())
    {
        std::cout << "Failed to initialize GLEW" << std::endl;
        return EXIT_FAILURE;
    }

    char rendererInfo[512] = {0};
    strcpy(rendererInfo, (const char*) glGetString(GL_RENDERER));
    strcat(rendererInfo, " - ");
    strcat(rendererInfo, (const char*) glGetString(GL_VERSION));
    glfwSetWindowTitle(window, rendererInfo);

    init();

    glfwSetKeyCallback(window, keyboard);
    glfwSetCursorPosCallback(window, mouseCallBack);
    glfwSetWindowSizeCallback(window, reshape);
    glfwSetScrollCallback(window, scrollCallBack);

    //glEnable(GL_DEBUG_OUTPUT);
    //glDebugMessageCallbackARB(messageCallBack, 0);

    reshape(window, width, height); // need to call this once ourselves
    mainLoop(window); // this does not return unless the window is closed

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
