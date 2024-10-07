cmake_minimum_required(VERSION 3.20)
project(diff-analysis LANGUAGES CXX VERSION 0.1.0)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Use FetchContent to download and include libgit2 and Catch2
include(FetchContent)
FetchContent_Declare(
  libgit2
  GIT_REPOSITORY https://github.com/libgit2/libgit2.git
  GIT_TAG        v1.5.0  # Use the desired version
)
FetchContent_MakeAvailable(libgit2)

FetchContent_Declare(
  Catch2
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG        v3.3.2  # Use the desired version
)
FetchContent_MakeAvailable(Catch2)

# Find LLVM and libclang
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")

# Include directories for LLVM and libclang
include_directories(${LLVM_INCLUDE_DIRS})

# Link with LLVM and libclang libraries
link_libraries(${LLVM_LIBRARIES})

# Add your source files
add_executable(analysis main.cpp)

# Link with libgit2
target_link_libraries(analysis git2)

add_executable(FileVarA tests/challenges-a/FileVarA.cpp)
target_link_libraries(FileVarA PRIVATE Catch2::Catch2)
