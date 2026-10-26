cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "flutter_secure_storage_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_secure_storage_linux_plugin")

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

add_library(${PLUGIN_NAME} SHARED
  "flutter_secure_storage_linux_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1>=0.18.4)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)


target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
"${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories(${LIBSECRET_INCLUDE_DIRS})

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::LIBSECRET)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_secure_storage_bundled_libraries
  ""
  PARENT_SCOPE
)

# === Tests ===
if(${include_flutter_secure_storage_linux_tests})
if(${CMAKE_VERSION} VERSION_LESS "3.11.0")
  message("Unit tests require CMake 3.11.0 or later")
else()
  set(TEST_RUNNER "${PROJECT_NAME}_test")
  enable_testing()

  include(FetchContent)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/b514bdc898e2951020cbdca1304b75f5950d1f59.zip
  )
  set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)
  FetchContent_MakeAvailable(googletest)

  add_executable(${TEST_RUNNER}
    test/flutter_secure_storage_linux_plugin_test.cc
  )
  apply_standard_settings(${TEST_RUNNER})
  target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main PkgConfig::LIBSECRET)

  include(GoogleTest)
  gtest_discover_tests(${TEST_RUNNER})
endif()
endif()
