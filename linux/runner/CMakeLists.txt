cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "mpv/mpv_player.cc"
  "mpv/mpv_plugin.cc"
  "mpv/wayland_video_surface.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# apply_standard_settings asks for cxx_std_14, which current compilers satisfy
# with a gnu++17 default and so add no -std flag for. mpv_plugin.cc uses
# std::optional, so say 17 rather than inherit it from whatever the host
# compiler happens to default to.
target_compile_features(${BINARY_NAME} PRIVATE cxx_std_17)

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Find mpv library.
pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)

# Find epoxy (OpenGL loader).
pkg_check_modules(EPOXY REQUIRED IMPORTED_TARGET epoxy)

# Wayland client + EGL back the native video plane (a wl_subsurface below the
# Flutter surface). GTK's Wayland backend already links these, but the runner
# calls them directly, so depend on them explicitly.
pkg_check_modules(WAYLAND_CLIENT REQUIRED IMPORTED_TARGET wayland-client)
pkg_check_modules(WAYLAND_EGL REQUIRED IMPORTED_TARGET wayland-egl)
pkg_check_modules(EGL REQUIRED IMPORTED_TARGET egl)

# Vendored wayland-scanner output for color-management-v1 (staging), which backs
# HDR on the native video plane. Built separately because it is C (the runner is
# C++ only) and generated, so it must not be held to -Wall -Werror.
#
# Committed rather than generated at build time: the protocol only appeared in
# wayland-protocols 1.41, newer than the version the distributions this app is
# built for ship, so vendoring keeps the build working regardless of the host and
# adds no build dependency on wayland-scanner. The checked-in files came from
# wayland-protocols 1.49 via wayland-scanner 1.25.0; the interface is at version
# 3 and the client binds min(advertised, 3).
#
# To refresh, from a host with a new enough wayland-protocols - and do not
# hand-edit the results:
#
#   xml=/usr/share/wayland-protocols/staging/color-management/color-management-v1.xml
#   cp "$xml" linux/runner/wayland/
#   wayland-scanner client-header "$xml" linux/runner/wayland/color-management-v1-client-protocol.h
#   wayland-scanner private-code  "$xml" linux/runner/wayland/color-management-v1-protocol.c
enable_language(C)
add_library(wayland_protocols STATIC "wayland/color-management-v1-protocol.c")
target_include_directories(wayland_protocols PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/wayland")
target_link_libraries(wayland_protocols PUBLIC PkgConfig::WAYLAND_CLIENT)
target_compile_options(wayland_protocols PRIVATE -w)

# Build simdutf as a static library from the single-header amalgamation.
add_library(simdutf STATIC "${simdutf_SOURCE_DIR}/simdutf.cpp")
target_include_directories(simdutf PUBLIC "${simdutf_SOURCE_DIR}")
target_compile_features(simdutf PUBLIC cxx_std_14)
# Suppress warnings in third-party code
target_compile_options(simdutf PRIVATE -w)

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::MPV)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::EPOXY)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::WAYLAND_CLIENT)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::WAYLAND_EGL)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::EGL)
target_link_libraries(${BINARY_NAME} PRIVATE wayland_protocols)
target_link_libraries(${BINARY_NAME} PRIVATE simdutf)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/../shared/cpp")

function(check_mpv_sanitizer_support SANITIZER_FLAG RESULT_VARIABLE)
  include(CheckCXXSourceCompiles)
  # Force an executable try-compile: sanitizer availability depends on the
  # runtime being linkable, not just on the compiler accepting the flag.
  set(CMAKE_TRY_COMPILE_TARGET_TYPE EXECUTABLE)
  set(CMAKE_REQUIRED_FLAGS "${SANITIZER_FLAG}")
  set(CMAKE_REQUIRED_LIBRARIES "${SANITIZER_FLAG}")
  check_cxx_source_compiles("int main() { return 0; }" ${RESULT_VARIABLE})
  set(${RESULT_VARIABLE} "${${RESULT_VARIABLE}}" PARENT_SCOPE)
endfunction()

option(PLEZY_BUILD_MPV_PLAYER_LIFECYCLE_TESTS
  "Build the focused Linux mpv callback lifecycle test" OFF)
if(PLEZY_BUILD_MPV_PLAYER_LIFECYCLE_TESTS)
  find_package(Threads REQUIRED)

  add_executable(mpv_player_lifecycle_test
    "mpv/mpv_player.cc"
    "mpv/mpv_player_lifecycle_test.cc"
  )
  apply_standard_settings(mpv_player_lifecycle_test)
  target_compile_definitions(mpv_player_lifecycle_test PRIVATE PLEZY_MPV_PLAYER_LIFECYCLE_TEST=1)
  target_link_libraries(mpv_player_lifecycle_test PRIVATE flutter)
  target_link_libraries(mpv_player_lifecycle_test PRIVATE PkgConfig::GTK)
  target_link_libraries(mpv_player_lifecycle_test PRIVATE PkgConfig::MPV)
  target_link_libraries(mpv_player_lifecycle_test PRIVATE PkgConfig::EPOXY)
  target_link_libraries(mpv_player_lifecycle_test PRIVATE simdutf)
  target_link_libraries(mpv_player_lifecycle_test PRIVATE Threads::Threads)
  target_include_directories(mpv_player_lifecycle_test PRIVATE "${CMAKE_SOURCE_DIR}")
  target_include_directories(mpv_player_lifecycle_test PRIVATE "${CMAKE_SOURCE_DIR}/../shared/cpp")

  option(PLEZY_MPV_LIFECYCLE_SANITIZERS
    "Enable ASan and UBSan for the focused mpv lifecycle test" ON)
  if(PLEZY_MPV_LIFECYCLE_SANITIZERS AND CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    check_mpv_sanitizer_support(
      "-fsanitize=address,undefined" MPV_LIFECYCLE_SANITIZERS_SUPPORTED)
    if(MPV_LIFECYCLE_SANITIZERS_SUPPORTED)
      target_compile_options(mpv_player_lifecycle_test PRIVATE -fno-omit-frame-pointer -fsanitize=address,undefined)
      target_link_options(mpv_player_lifecycle_test PRIVATE -fsanitize=address,undefined)
    endif()
  endif()

  add_test(NAME mpv_player_lifecycle_test COMMAND mpv_player_lifecycle_test)
  set_tests_properties(mpv_player_lifecycle_test PROPERTIES TIMEOUT 30)
endif()

option(PLEZY_BUILD_MPV_PROPERTY_CONTRACT_TESTS
  "Build the focused desktop mpv property-result contract test" OFF)
option(PLEZY_BUILD_MPV_RELIABILITY_TESTS
  "Build focused Linux mpv registry and GPU bootstrap tests" OFF)
set(PLEZY_MPV_RELIABILITY_SANITIZER "none" CACHE STRING
  "Sanitizer for focused mpv reliability tests: none, address, or thread")
set_property(CACHE PLEZY_MPV_RELIABILITY_SANITIZER PROPERTY STRINGS none address thread)

function(apply_mpv_reliability_sanitizer TARGET)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU" OR
     PLEZY_MPV_RELIABILITY_SANITIZER STREQUAL "none")
    return()
  endif()
  if(PLEZY_MPV_RELIABILITY_SANITIZER STREQUAL "address")
    set(SANITIZER_FLAG "-fsanitize=address,undefined")
    set(SANITIZER_SUPPORT_VARIABLE MPV_RELIABILITY_ADDRESS_SANITIZER_SUPPORTED)
  elseif(PLEZY_MPV_RELIABILITY_SANITIZER STREQUAL "thread")
    set(SANITIZER_FLAG "-fsanitize=thread")
    set(SANITIZER_SUPPORT_VARIABLE MPV_RELIABILITY_THREAD_SANITIZER_SUPPORTED)
  else()
    message(FATAL_ERROR "Unknown PLEZY_MPV_RELIABILITY_SANITIZER value")
  endif()
  check_mpv_sanitizer_support("${SANITIZER_FLAG}" ${SANITIZER_SUPPORT_VARIABLE})
  if(NOT ${SANITIZER_SUPPORT_VARIABLE})
    message(WARNING
      "${PLEZY_MPV_RELIABILITY_SANITIZER} sanitizer is unavailable; focused tests will be unsanitized")
    return()
  endif()
  target_compile_options(${TARGET} PRIVATE -fno-omit-frame-pointer ${SANITIZER_FLAG})
  target_link_options(${TARGET} PRIVATE ${SANITIZER_FLAG})
endfunction()

if(PLEZY_BUILD_MPV_PROPERTY_CONTRACT_TESTS OR PLEZY_BUILD_MPV_RELIABILITY_TESTS)
  find_package(Threads REQUIRED)
  add_executable(mpv_property_result_contract_test
    "../../shared/mpv/mpv_player_common_test.cpp"
  )
  apply_standard_settings(mpv_property_result_contract_test)
  target_compile_features(mpv_property_result_contract_test PRIVATE cxx_std_14)
  target_link_libraries(mpv_property_result_contract_test PRIVATE PkgConfig::MPV Threads::Threads)
  target_include_directories(mpv_property_result_contract_test PRIVATE "../../shared/mpv")
  apply_mpv_reliability_sanitizer(mpv_property_result_contract_test)
  add_test(NAME mpv_property_result_contract_test COMMAND mpv_property_result_contract_test)
endif()

if(PLEZY_BUILD_MPV_RELIABILITY_TESTS)
  add_executable(hdr_metadata_test
    "mpv/hdr_metadata_test.cc"
  )
  apply_standard_settings(hdr_metadata_test)
  target_compile_features(hdr_metadata_test PRIVATE cxx_std_14)
  target_include_directories(hdr_metadata_test PRIVATE "mpv")
  apply_mpv_reliability_sanitizer(hdr_metadata_test)
  add_test(NAME hdr_metadata_test COMMAND hdr_metadata_test)
endif()
