cmake_minimum_required(VERSION 3.16)
project(corvus_c_benchmark C)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# The C library's release package (its CMake package), linked statically as Blaze is.
find_package(corvus_json_schema REQUIRED)
add_executable(corvus_c_benchmark main.c)
target_link_libraries(corvus_c_benchmark PRIVATE corvus_json_schema::corvus_json_schema_static)
