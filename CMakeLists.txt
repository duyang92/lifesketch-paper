cmake_minimum_required(VERSION 3.10)
project(${TARGET_NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_VERBOSE_MAKEFILE ON)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

add_executable(${TARGET_NAME}
        ${MAIN_FILE}
        Sources/HLL.cpp
        Sources/MurmurHash3.cpp
        Sources/HLLTC.cpp
        Sources/LifeSketchRE.cpp       
        Sources/LifeSketch.cpp
        Sources/SHE_BM.cpp)