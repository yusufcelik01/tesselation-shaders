#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include "helpers.hpp"


unsigned char* load_image(char* img, int* width, int* height, int* nrChannels)
{
    //return stbi_load("metu_flag.jpg", width, height, nrChannels, 0);
    return stbi_load(img, width, height, nrChannels, 0);
}

glm::vec3 mirrorPoint(glm::vec3 mirror, glm::vec3 p)
{
    return mirror + (mirror - p);
}
