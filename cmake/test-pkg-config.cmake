# The absolute installation paths must be outside the source and build trees.
# No installation is performed, so these paths need not exist or be writable.
get_filename_component(ROOT "${REPROC_BINARY_DIR}" ABSOLUTE)
set(PARENT "")
while(NOT PARENT STREQUAL ROOT)
  set(PARENT "${ROOT}")
  get_filename_component(ROOT "${ROOT}" DIRECTORY)
endwhile()

set(MODULES reproc)
if(REPROC_CXX)
  list(APPEND MODULES reproc++)
endif()

foreach(LAYOUT relative absolute absolute-include absolute-lib)
  set(BUILD_DIR "${REPROC_BINARY_DIR}/${LAYOUT}/build")
  set(INCLUDEDIR include)
  set(LIBDIR lib)
  set(EXPECTED_INCLUDEDIR "\${prefix}/include")
  set(EXPECTED_LIBDIR "\${exec_prefix}/lib")

  if(LAYOUT STREQUAL absolute OR LAYOUT STREQUAL absolute-include)
    set(INCLUDEDIR "${ROOT}reproc-pkg-config-test/${LAYOUT}/headers")
    set(EXPECTED_INCLUDEDIR "${INCLUDEDIR}")
  endif()
  if(LAYOUT STREQUAL absolute OR LAYOUT STREQUAL absolute-lib)
    set(LIBDIR "${ROOT}reproc-pkg-config-test/${LAYOUT}/libraries")
    set(EXPECTED_LIBDIR "${LIBDIR}")
  endif()

  file(MAKE_DIRECTORY "${BUILD_DIR}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" "${REPROC_SOURCE_DIR}"
      -G "${CMAKE_GENERATOR}"
      "-DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}"
      "-DCMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}"
      "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
      "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_INSTALL_PREFIX=${BUILD_DIR}/prefix"
      "-DCMAKE_INSTALL_INCLUDEDIR=${INCLUDEDIR}"
      "-DCMAKE_INSTALL_LIBDIR=${LIBDIR}"
      "-DREPROC++=${REPROC_CXX}"
      -DREPROC_DEVELOP=OFF
      -DREPROC_TEST=OFF
      -DREPROC_INSTALL=ON
      -DREPROC_INSTALL_PKGCONFIG=ON
    WORKING_DIRECTORY "${BUILD_DIR}"
    RESULT_VARIABLE RESULT
  )
  if(NOT RESULT EQUAL 0)
    message(FATAL_ERROR "Could not configure ${LAYOUT} installation")
  endif()

  foreach(MODULE IN LISTS MODULES)
    file(READ "${BUILD_DIR}/${MODULE}/${MODULE}.pc" CONFIG)
    foreach(DIR INCLUDEDIR LIBDIR)
      string(TOLOWER "${DIR}" VARIABLE)
      string(FIND "${CONFIG}" "${VARIABLE}=${EXPECTED_${DIR}}\n" MATCH)
      if(MATCH EQUAL -1)
        message(FATAL_ERROR "Incorrect ${VARIABLE} in ${LAYOUT} ${MODULE}.pc")
      endif()
    endforeach()
  endforeach()
endforeach()
