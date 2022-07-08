CC=gcc
CXX=g++
GLFLAGS= -g -lglfw -lpthread -lX11 -ldl -lXrandr -lGLEW -lGL -DGL_SILENCE_DEPRECATION -DGLM_ENABLE_EXPERIMENTAL -I. -msse2
CXXFLAGS=$(GLFLAGS)

all: main.cpp helpers.o
	g++ main.cpp -o main -g -lglfw -lpthread -lX11 -ldl -lXrandr -lGLEW -lGL -DGL_SILENCE_DEPRECATION -DGLM_ENABLE_EXPERIMENTAL -I.

%: %.cpp
	$(CXX) $@.cpp -o $@ $(GLFLAGS)
