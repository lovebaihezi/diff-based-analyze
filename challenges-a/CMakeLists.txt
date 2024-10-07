cmake_minimum_required(VERSION 3.10)
project(LLVM_IR_Generation)

# Find LLVM package
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# Include LLVM headers
include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# Find all .c files recursively
file(GLOB_RECURSE C_SOURCES "${CMAKE_SOURCE_DIR}/src/*/*.c")

# Function to get relative path
function(get_relative_path absolute_path relative_path_var)
    file(RELATIVE_PATH rel_path "${CMAKE_SOURCE_DIR}" "${absolute_path}")
    set(${relative_path_var} "${rel_path}" PARENT_SCOPE)
endfunction()

# Create custom targets for each .c file
foreach(SOURCE_FILE ${C_SOURCES})
    # Get the relative path and filename
    get_relative_path(${SOURCE_FILE} REL_PATH)
    get_filename_component(FILE_NAME ${SOURCE_FILE} NAME_WE)

    # Create output directory if it doesn't exist
    get_filename_component(OUTPUT_DIR "${CMAKE_BINARY_DIR}/${REL_PATH}" DIRECTORY)
    file(MAKE_DIRECTORY ${OUTPUT_DIR})

    # Set the output .ll file path
    set(OUTPUT_FILE "${OUTPUT_DIR}/${FILE_NAME}.ll")

    # Add custom command to generate LLVM IR
    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${LLVM_TOOLS_BINARY_DIR}/clang -O3 -g -S -emit-llvm -o ${OUTPUT_FILE} ${SOURCE_FILE}
        DEPENDS ${SOURCE_FILE}
        COMMENT "Generating LLVM IR for ${REL_PATH}"
    )

    # Add custom target
    add_custom_target(${FILE_NAME}_llvm_ir ALL DEPENDS ${OUTPUT_FILE})
endforeach()
