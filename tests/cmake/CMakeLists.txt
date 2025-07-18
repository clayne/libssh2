# Copyright (C) Viktor Szakats
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.7...3.16 FATAL_ERROR)
message(STATUS "Using CMake version ${CMAKE_VERSION}")

project(test-consumer C)

option(TEST_INTEGRATION_MODE "Integration mode" "find_package")

message(STATUS "TEST_INTEGRATION_MODE: ${TEST_INTEGRATION_MODE}")

if(TEST_INTEGRATION_MODE STREQUAL "FetchContent" AND CMAKE_VERSION VERSION_LESS 3.14)
  message(FATAL_ERROR "This test requires CMake 3.14 or upper")
endif()

if(TEST_INTEGRATION_MODE STREQUAL "ExternalProject")  # Broken
  include(ExternalProject)
  ExternalProject_Add(libssh2
    URL "${FROM_ARCHIVE}" URL_HASH "SHA256=${FROM_HASH}"
    INSTALL_COMMAND ""
    DOWNLOAD_EXTRACT_TIMESTAMP ON)
endif()

if(TEST_INTEGRATION_MODE STREQUAL "find_package" OR
   TEST_INTEGRATION_MODE STREQUAL "ExternalProject")
  find_package(libssh2 REQUIRED CONFIG)
  find_package(libssh2 REQUIRED CONFIG)  # Double-inclusion test
  foreach(_result_var IN ITEMS
      libssh2_FOUND
      libssh2_VERSION
  )
    if(NOT ${_result_var})
      message(FATAL_ERROR "'${_result_var}' variable expected, but not set by the libssh2 package.")
    endif()
  endforeach()
  # Show variables set by find_package()
  get_cmake_property(_vars VARIABLES)
  foreach(_var IN ITEMS ${_vars})
    string(TOUPPER "${_var}" _var_upper)
    if(_var_upper MATCHES "LIBSSH2")
      get_property(_var_type CACHE ${_var} PROPERTY TYPE)
      if(_var_type)
        set(_var_type ":${_var_type}")
      endif()
      message("find_package() sets: ${_var}${_var_type} = '${${_var}}'")
    endif()
  endforeach()
elseif(TEST_INTEGRATION_MODE STREQUAL "add_subdirectory")
  add_subdirectory(libssh2)
elseif(TEST_INTEGRATION_MODE STREQUAL "FetchContent")
  include(FetchContent)
  option(FROM_GIT_REPO "Git URL" "https://github.com/libssh2/libssh2.git")
  option(FROM_GIT_TAG "Git tag" "master")
  FetchContent_Declare(libssh2
    GIT_REPOSITORY "${FROM_GIT_REPO}"
    GIT_TAG "${FROM_GIT_TAG}"
    GIT_SHALLOW)
  FetchContent_MakeAvailable(libssh2)  # Requires CMake 3.14
endif()

add_executable(test-consumer-static-ns "test.c")
target_link_libraries(test-consumer-static-ns PRIVATE "libssh2::libssh2_static")

add_executable(test-consumer-shared-ns "test.c")
target_link_libraries(test-consumer-shared-ns PRIVATE "libssh2::libssh2_shared")

# Alias for either shared or static library
add_executable(test-consumer-selected-ns "test.c")
target_link_libraries(test-consumer-selected-ns PRIVATE "libssh2::libssh2")

if(TEST_INTEGRATION_MODE STREQUAL "find_package" OR
   TEST_INTEGRATION_MODE STREQUAL "ExternalProject")

  # Compatibility alias
  add_executable(test-consumer-compat "test.c")
  target_link_libraries(test-consumer-compat PRIVATE "Libssh2::libssh2")

elseif(TEST_INTEGRATION_MODE STREQUAL "add_subdirectory" OR
       TEST_INTEGRATION_MODE STREQUAL "FetchContent")

  add_executable(test-consumer-static-bare "test.c")
  target_link_libraries(test-consumer-static-bare PRIVATE "libssh2_static")

  add_executable(test-consumer-shared-bare "test.c")
  target_link_libraries(test-consumer-shared-bare PRIVATE "libssh2_shared")

  add_executable(test-consumer-selected-bare "test.c")
  target_link_libraries(test-consumer-selected-bare PRIVATE "libssh2")
endif()
