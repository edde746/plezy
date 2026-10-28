cmake_minimum_required(VERSION 3.16)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "mpv/display_mode_manager.cpp"
  "mpv/mpv_player.cpp"
  "mpv/mpv_plugin.cpp"
  "visualizer/visualizer_session.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

add_subdirectory("${CMAKE_SOURCE_DIR}/../shared/cpp/plezy_motion_engine" plezy_motion_engine)

apply_standard_settings(${BINARY_NAME})

target_precompile_headers(${BINARY_NAME} PRIVATE "pch.h")

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

add_library(simdutf STATIC "${simdutf_SOURCE_DIR}/simdutf.cpp")
target_include_directories(simdutf PUBLIC "${simdutf_SOURCE_DIR}")
target_compile_features(simdutf PUBLIC cxx_std_17)
target_compile_options(simdutf PRIVATE /W0)

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app flutter_wrapper_plugin)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib" "comctl32.lib" "dxgi.lib" "advapi32.lib")
target_link_libraries(${BINARY_NAME} PRIVATE "${MPV_LIB_DIR}/libmpv.dll.a")
target_link_libraries(${BINARY_NAME} PRIVATE simdutf opengl32 windowscodecs ole32 plezy_motion_engine)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "${MPV_INCLUDE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/../shared/cpp")

# The Flutter desktop loader resolves PME beside the executable. Bundle the
# matching Windows ML runtime and manifest there as well; provider EPs remain
# device-specific and are acquired through Windows ML when Neural is enabled.
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "$<TARGET_FILE:plezy_motion_engine>" "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${WINML_BINARY_DIR}/onnxruntime.dll" "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${WINML_BINARY_DIR}/Microsoft.Windows.AI.MachineLearning.dll" "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${WINML_DIRECTML_DLL}" "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${PLEZY_WINML_PACKAGE_ROOT}/license.txt"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>/WindowsML-License.txt"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${PLEZY_WINML_PACKAGE_ROOT}/ThirdPartyNotices.txt"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>/WindowsML-ThirdPartyNotices.txt"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/../shared/cpp/plezy_motion_engine/providers.windows.tsv"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  VERBATIM
)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

option(PLEZY_STEAM_RECEIVER "Include the Windows Steam receiver" ON)
if(PLEZY_STEAM_RECEIVER)
  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  execute_process(COMMAND "${Python3_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/../scripts/games/prepare_steam.py"
    RESULT_VARIABLE STEAM_PREPARE_RESULT)
  if(NOT STEAM_PREPARE_RESULT EQUAL 0)
    message(FATAL_ERROR "Could not prepare the pinned Steam runtime")
  endif()
  set(PLEZY_STEAM_PYROWAVE OFF CACHE BOOL "" FORCE)
  add_subdirectory("${CMAKE_SOURCE_DIR}/../native/games/steam" "${CMAKE_CURRENT_BINARY_DIR}/steam")
  target_sources(${BINARY_NAME} PRIVATE "games/steam_plugin.cpp")
  # Winsock2 must precede windows.h; this adapter owns that include ordering.
  set_source_files_properties("games/steam_plugin.cpp" PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
  target_compile_definitions(${BINARY_NAME} PRIVATE PLEZY_STEAM_RECEIVER=1 _WIN32_WINNT=0x0602)
  target_link_libraries(${BINARY_NAME} PRIVATE plezy_steam_windows bcrypt)
endif()

option(PLEZY_BUILD_MPV_PROPERTY_CONTRACT_TESTS
  "Build the focused Windows mpv property-result contract tests" OFF)
if(PLEZY_BUILD_MPV_PROPERTY_CONTRACT_TESTS)
  enable_testing()

  add_executable(mpv_property_result_contract_test
    "../../shared/mpv/mpv_player_common_test.cpp"
  )
  apply_standard_settings(mpv_property_result_contract_test)
  target_link_libraries(mpv_property_result_contract_test PRIVATE "${MPV_LIB_DIR}/libmpv.dll.a")
  target_include_directories(mpv_property_result_contract_test PRIVATE "${MPV_INCLUDE_DIR}")

  add_executable(mpv_player_property_contract_test
    "mpv/mpv_player.cpp"
    "mpv/mpv_player_property_contract_test.cpp"
  )
  apply_standard_settings(mpv_player_property_contract_test)
  target_compile_definitions(mpv_player_property_contract_test PRIVATE "NOMINMAX")
  target_link_libraries(
    mpv_player_property_contract_test
    PRIVATE flutter_wrapper_plugin "${MPV_LIB_DIR}/libmpv.dll.a" simdutf "comctl32.lib" "user32.lib" "dxgi.lib"
  )
  target_include_directories(
    mpv_player_property_contract_test
    PRIVATE
      "${CMAKE_SOURCE_DIR}"
      "${CMAKE_CURRENT_SOURCE_DIR}"
      "${MPV_INCLUDE_DIR}"
      "${CMAKE_SOURCE_DIR}/../shared/cpp"
  )

  foreach(test_target IN ITEMS mpv_property_result_contract_test mpv_player_property_contract_test)
    add_custom_command(
      TARGET ${test_target}
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${MPV_RUNTIME_DLLS}
        "$<TARGET_FILE_DIR:${test_target}>"
    )
  endforeach()

  add_test(NAME mpv_property_result_contract_test COMMAND mpv_property_result_contract_test)
  add_test(NAME mpv_player_property_contract_test COMMAND mpv_player_property_contract_test)
endif()

option(PLEZY_BUILD_DISPLAY_RECOVERY_TESTS
  "Build the focused Windows display recovery transaction tests" OFF)
if(PLEZY_BUILD_DISPLAY_RECOVERY_TESTS)
  enable_testing()

  add_executable(display_mode_manager_test
    "mpv/display_mode_manager.cpp"
    "mpv/display_mode_manager_test.cpp"
  )
  apply_standard_settings(display_mode_manager_test)
  target_compile_definitions(
    display_mode_manager_test PRIVATE "NOMINMAX" "PLEZY_DISPLAY_MODE_MANAGER_TESTING"
  )
  target_link_libraries(display_mode_manager_test PRIVATE "advapi32.lib" "user32.lib")

  add_test(NAME display_mode_manager_test COMMAND display_mode_manager_test)
endif()

