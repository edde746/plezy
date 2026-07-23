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
  "mpv/mpv_texture.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Find mpv library.
pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)

# Find epoxy (OpenGL loader).
pkg_check_modules(EPOXY REQUIRED IMPORTED_TARGET epoxy)

# Build simdutf as a static library from the single-header amalgamation.
add_library(simdutf STATIC "${simdutf_SOURCE_DIR}/simdutf.cpp")
target_include_directories(simdutf PUBLIC "${simdutf_SOURCE_DIR}")
target_compile_features(simdutf PUBLIC cxx_std_17)
# Suppress warnings in third-party code
target_compile_options(simdutf PRIVATE -w)

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::MPV)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::EPOXY)
target_link_libraries(${BINARY_NAME} PRIVATE simdutf)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/../shared/cpp")

option(PLEZY_BUILD_MPV_PLAYER_LIFECYCLE_TESTS
  "Build the focused Linux mpv callback lifecycle test" OFF)
if(PLEZY_BUILD_MPV_PLAYER_LIFECYCLE_TESTS)
  enable_testing()
  find_package(Threads REQUIRED)

  add_executable(mpv_player_lifecycle_test
    "mpv/mpv_player.cc"
    "mpv/mpv_player_lifecycle_test.cc"
  )
  apply_standard_settings(mpv_player_lifecycle_test)
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
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-fsanitize=address,undefined" MPV_LIFECYCLE_SANITIZERS_SUPPORTED)
    if(MPV_LIFECYCLE_SANITIZERS_SUPPORTED)
      target_compile_options(mpv_player_lifecycle_test PRIVATE -fno-omit-frame-pointer -fsanitize=address,undefined)
      target_link_options(mpv_player_lifecycle_test PRIVATE -fsanitize=address,undefined)
    endif()
  endif()

  add_test(NAME mpv_player_lifecycle_test COMMAND mpv_player_lifecycle_test)
endif()

option(PLEZY_BUILD_MPV_PROPERTY_CONTRACT_TESTS
  "Build the focused desktop mpv property-result contract test" OFF)
if(PLEZY_BUILD_MPV_PROPERTY_CONTRACT_TESTS)
  enable_testing()
  find_package(Threads REQUIRED)

  add_executable(mpv_property_result_contract_test
    "../../shared/mpv/mpv_player_common_test.cpp"
  )
  apply_standard_settings(mpv_property_result_contract_test)
  target_link_libraries(mpv_property_result_contract_test PRIVATE PkgConfig::MPV Threads::Threads)
  target_include_directories(mpv_property_result_contract_test PRIVATE "../../shared/mpv")

  add_test(NAME mpv_property_result_contract_test COMMAND mpv_property_result_contract_test)
endif()
