cmake_minimum_required(VERSION 3.16)
project(rapidjson_benchmark LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Force Release build
set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)

add_library(rapidjson INTERFACE)
target_include_directories(rapidjson INTERFACE repo/include)

add_executable(rapidjson_benchmark main.cc)
target_compile_options(rapidjson_benchmark PRIVATE
    -Wall -Wextra -Wno-unused-parameter
)

target_link_libraries(rapidjson_benchmark PRIVATE
	rapidjson
)