cmake_minimum_required(VERSION 3.29)
project(diff-analysis LANGUAGES CXX VERSION 0.1.0)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_LINKER_TYPE LLD)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fno-omit-frame-pointer")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")

set(BUILD_SHARED_LIBS OFF)
set(BUILD_TESTS OFF)
set(BUILD_CLAR OFF)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)

# Find LLVM and libclang
find_package(LLVM REQUIRED CONFIG HINTS)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")

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
  GIT_TAG        v3.4.0  # Use the desired version
)
FetchContent_MakeAvailable(Catch2)

# Include directories for LLVM and libclang
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB_RECURSE SOURCES
  App.hpp
  argparse.hpp
  expected.hpp
  GitApp.hpp
  GitAppImpl.cpp
  logger.hpp
  rust.hpp
  types.hpp
  VariableApp.hpp
  VariableAppImpl.cpp
  uuidv4.hpp
  uuidv4Impl.cpp
)

# Add your source files
add_executable(
  diff_analysis
  main.cpp
  ${SOURCES}
)

llvm_map_components_to_libnames(llvm_libs support core irreader analysis debuginfod)

# Link with libgit2, quill, LLVM
target_link_libraries(diff_analysis git2 ${llvm_libs})

enable_testing()

file(GLOB_RECURSE TEST_SOURCES "${CMAKE_SOURCE_DIR}/*Test.cpp")
add_executable(
  tests
  ${SOURCES}
  ${TEST_SOURCES}
)
target_link_libraries(tests PRIVATE Catch2::Catch2WithMain git2 ${llvm_libs})

include(Catch)
catch_discover_tests(tests)
