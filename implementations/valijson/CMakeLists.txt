cmake_minimum_required(VERSION 3.16)
project(valijson_benchmark)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -mtune=native")

include(FetchContent)
FetchContent_Declare(
  valijson
  GIT_REPOSITORY https://github.com/tristanpenman/valijson.git
  GIT_TAG v1.1.3
  GIT_SHALLOW TRUE
  GIT_SUBMODULES ""
)
set(valijson_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(valijson_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(valijson)

find_package(nlohmann_json CONFIG REQUIRED)
add_executable(valijson_benchmark main.cc)
target_link_libraries(valijson_benchmark PRIVATE ValiJSON::valijson nlohmann_json::nlohmann_json)
