cmake_minimum_required(VERSION 3.12...3.21)

project(
  reproc
  VERSION 14.2.7
  DESCRIPTION "Cross-platform C99/C++11 process library"
  HOMEPAGE_URL "https://github.com/DaanDeMeyer/reproc"
  LANGUAGES C
)

# Common options and functions separated for easier reuse in other projects.
include(cmake/reproc.cmake)

option(REPROC++ "Build reproc++" ${REPROC_DEVELOP})
option(
  REPROC_MULTITHREADED
  "Use `pthread_sigmask` and link against the system's thread library"
  ON
)

if(REPROC_MULTITHREADED)
  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  set(REPROC_THREAD_LIBRARY ${CMAKE_THREAD_LIBS_INIT})
endif()

add_subdirectory(reproc)

if(REPROC++)
  enable_language(CXX)
  add_subdirectory(reproc++)
endif()

if(REPROC_TEST AND REPROC_INSTALL AND REPROC_INSTALL_PKGCONFIG)
  add_test(
    NAME reproc-test-pkg-config
    COMMAND ${CMAKE_COMMAND}
      -DREPROC_SOURCE_DIR=${PROJECT_SOURCE_DIR}
      -DREPROC_BINARY_DIR=${PROJECT_BINARY_DIR}/pkg-config-test
      -DREPROC_CXX=${REPROC++}
      -DCMAKE_GENERATOR=${CMAKE_GENERATOR}
      -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DCMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
      -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
      -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
      -P ${PROJECT_SOURCE_DIR}/cmake/test-pkg-config.cmake
  )
endif()
