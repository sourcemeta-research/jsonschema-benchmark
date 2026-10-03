cmake_minimum_required(VERSION 3.16)
project(corvus_cpp_benchmark CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# The C library's release package (its CMake package), linked statically as Blaze is.
find_package(corvus_json_schema REQUIRED)
add_executable(corvus_cpp_benchmark main.cpp)
target_link_libraries(corvus_cpp_benchmark PRIVATE corvus_json_schema::corvus_json_schema_static)
