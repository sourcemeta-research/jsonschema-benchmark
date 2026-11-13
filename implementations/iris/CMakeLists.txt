cmake_minimum_required(VERSION 3.20)
project(iris_benchmark LANGUAGES CXX)

# The validator library only (the options Bowtie's harness sets), without the JIT.
set(IRIS_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(IRIS_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(IRIS_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(IRIS_BUILD_SIMDJSON OFF CACHE BOOL "" FORCE)
set(IRIS_BUILD_GATEWAY OFF CACHE BOOL "" FORCE)
set(IRIS_BUILD_DB OFF CACHE BOOL "" FORCE)
set(IRIS_BUILD_BOWTIE OFF CACHE BOOL "" FORCE)
set(IRIS_ENABLE_JIT OFF CACHE BOOL "" FORCE)
set(IRIS_ENABLE_LTO OFF CACHE BOOL "" FORCE)
add_subdirectory(iris iris-build)

add_executable(iris_benchmark main.cpp)
target_link_libraries(iris_benchmark PRIVATE iris)
target_compile_features(iris_benchmark PRIVATE cxx_std_20)
