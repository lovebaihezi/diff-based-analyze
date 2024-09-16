cmake_minimum_required(VERSION 3.10)
project(test VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")

set(SRC_DIRS ${CMAKE_CURRENT_LIST_DIR}/shared_var ${CMAKE_CURRENT_LIST_DIR}/thread_pool ${CMAKE_CURRENT_LIST_DIR}/correct_sync)

foreach(SRC_DIR ${SRC_DIRS})
  execute_process(
    COMMAND find ${SRC_DIR} -name "*.c"
    OUTPUT_VARIABLE C_SOURCES
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(REPLACE "\n" ";" C_SOURCES "${C_SOURCES}")

  foreach(SRC ${C_SOURCES})
    get_filename_component(EXE_NAME ${SRC} NAME_WE)
    add_executable(${EXE_NAME} ${SRC} ${CMAKE_CURRENT_LIST_DIR}/thpool.h ${CMAKE_CURRENT_LIST_DIR}/thpool.c ${CMAKE_CURRENT_LIST_DIR}/types.h)
    target_include_directories(${EXE_NAME} PRIVATE ${CMAKE_CURRENT_LIST_DIR})
  endforeach()

  execute_process(
    COMMAND find ${SRC_DIR} -name "*.cpp"
    OUTPUT_VARIABLE CPP_SOURCES
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(REPLACE "\n" ";" CPP_SOURCES "${CPP_SOURCES}")

  foreach(SRC ${CPP_SOURCES})
    get_filename_component(EXE_NAME ${SRC} NAME_WE)
    add_executable(${EXE_NAME}_cpp ${SRC} ${CMAKE_CURRENT_LIST_DIR}/types.h)
  endforeach()
endforeach()

add_executable(privileges privileges.c ${CMAKE_CURRENT_LIST_DIR}/thpool.h ${CMAKE_CURRENT_LIST_DIR}/thpool.c ${CMAKE_CURRENT_LIST_DIR}/types.h)
