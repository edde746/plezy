cmake_minimum_required(VERSION 3.14)
project(plezy LANGUAGES CXX)

set(MPV_VERSION "20260809")
set(MPV_GIT_HASH "dd5d17d328")

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
  # ARM64: use file(DOWNLOAD) + 7z extraction (CMake's built-in libarchive
  # can't handle LZMA2 on ARM64)
  set(MPV_FILENAME "mpv-dev-aarch64-${MPV_VERSION}-git-${MPV_GIT_HASH}.7z")
  set(MPV_URL "https://sourceforge.net/projects/mpv-player-windows/files/libmpv/${MPV_FILENAME}/download")
  set(MPV_DOWNLOAD_DIR "${CMAKE_BINARY_DIR}/mpv-dev-arm64")
  set(MPV_ARCHIVE "${MPV_DOWNLOAD_DIR}/${MPV_FILENAME}")

  if(NOT EXISTS "${MPV_DOWNLOAD_DIR}/libmpv-2.dll")
    message(STATUS "Downloading MPV for ARM64...")
    file(DOWNLOAD "${MPV_URL}" "${MPV_ARCHIVE}" SHOW_PROGRESS STATUS MPV_DL_STATUS)
    list(GET MPV_DL_STATUS 0 MPV_DL_RESULT)
    if(NOT MPV_DL_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to download MPV: ${MPV_DL_STATUS}")
    endif()

    find_program(7Z_EXECUTABLE 7z REQUIRED HINTS "C:/Program Files/7-Zip")
    message(STATUS "Extracting MPV with ${7Z_EXECUTABLE}...")
    execute_process(
      COMMAND "${7Z_EXECUTABLE}" x "${MPV_ARCHIVE}" "-o${MPV_DOWNLOAD_DIR}" -y
      RESULT_VARIABLE MPV_EXTRACT_RESULT
    )
    if(NOT MPV_EXTRACT_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to extract MPV archive")
    endif()
    file(REMOVE "${MPV_ARCHIVE}")
  endif()

  set(MPV_INCLUDE_DIR "${MPV_DOWNLOAD_DIR}/include")
  set(MPV_LIB_DIR "${MPV_DOWNLOAD_DIR}")
else()
  # x64 (AMD64): use FetchContent (existing behavior)
  include(FetchContent)
  FetchContent_Declare(
    mpv_dev
    URL https://sourceforge.net/projects/mpv-player-windows/files/libmpv/mpv-dev-x86_64-${MPV_VERSION}-git-${MPV_GIT_HASH}.7z/download
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  )
  FetchContent_MakeAvailable(mpv_dev)

  set(MPV_INCLUDE_DIR "${mpv_dev_SOURCE_DIR}/include")
  set(MPV_LIB_DIR "${mpv_dev_SOURCE_DIR}")
endif()

# libmpv >= 20260809 dynamically links the Khronos Vulkan loader instead of
# statically linking it, so libmpv-2.dll hard-imports vulkan-1.dll. On x64
# the GPU driver normally installs the loader into System32, but
# Windows-on-ARM Adreno drivers (and driverless x64 machines such as VMs)
# do not ship it, which made the process fail before WinMain (#2110).
# Bundle the LunarG-built loader next to the executable; without a Vulkan
# ICD, gpu-api=auto falls back to D3D11 exactly as the old static loader
# did.
set(VULKAN_RT_VERSION "1.4.357.0")
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
  set(VULKAN_RT_SLUG "warm")
  set(VULKAN_RT_COMPONENTS "VulkanRT-ARM64-${VULKAN_RT_VERSION}-Components")
  set(VULKAN_RT_DLL_SUBPATH "${VULKAN_RT_COMPONENTS}/vulkan-1.dll")
  set(VULKAN_RT_SHA256 "0a51a619525e0c7a156125c4f80c4f591c494cef9ff59dc4481735779a9a280c")
else()
  set(VULKAN_RT_SLUG "windows")
  set(VULKAN_RT_COMPONENTS "VulkanRT-X64-${VULKAN_RT_VERSION}-Components")
  set(VULKAN_RT_DLL_SUBPATH "${VULKAN_RT_COMPONENTS}/x64/vulkan-1.dll")
  set(VULKAN_RT_SHA256 "a14672efed15aafc7f5a16572d35cd3a3416eadf670aeee3cdf50ee32d5fbf83")
endif()
set(VULKAN_RT_DIR "${CMAKE_BINARY_DIR}/vulkan-runtime")
if(NOT EXISTS "${VULKAN_RT_DIR}/vulkan-1.dll" OR NOT EXISTS "${VULKAN_RT_DIR}/VulkanRT-License.txt")
  set(VULKAN_RT_ZIP "${VULKAN_RT_DIR}/vulkan-runtime-components.zip")
  message(STATUS "Downloading Vulkan runtime (${VULKAN_RT_SLUG} ${VULKAN_RT_VERSION})...")
  # sdk.lunarg.com rejects requests without a recognized User-Agent.
  file(DOWNLOAD
    "https://sdk.lunarg.com/sdk/download/${VULKAN_RT_VERSION}/${VULKAN_RT_SLUG}/vulkan-runtime-components.zip"
    "${VULKAN_RT_ZIP}"
    HTTPHEADER "User-Agent: curl/8.4.0"
    EXPECTED_HASH SHA256=${VULKAN_RT_SHA256}
    STATUS VULKAN_RT_DL_STATUS)
  list(GET VULKAN_RT_DL_STATUS 0 VULKAN_RT_DL_RESULT)
  if(NOT VULKAN_RT_DL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to download Vulkan runtime: ${VULKAN_RT_DL_STATUS}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xf "${VULKAN_RT_ZIP}"
    WORKING_DIRECTORY "${VULKAN_RT_DIR}"
    RESULT_VARIABLE VULKAN_RT_EXTRACT_RESULT
  )
  if(NOT VULKAN_RT_EXTRACT_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to extract Vulkan runtime archive")
  endif()
  file(RENAME "${VULKAN_RT_DIR}/${VULKAN_RT_DLL_SUBPATH}" "${VULKAN_RT_DIR}/vulkan-1.dll")
  file(RENAME "${VULKAN_RT_DIR}/${VULKAN_RT_COMPONENTS}/VulkanRT-License.txt"
    "${VULKAN_RT_DIR}/VulkanRT-License.txt")
  file(REMOVE_RECURSE "${VULKAN_RT_DIR}/${VULKAN_RT_COMPONENTS}")
  file(REMOVE "${VULKAN_RT_ZIP}")
endif()

# Fetch simdutf for SIMD-accelerated UTF-8 validation.
# mpv strings are not guaranteed to be valid UTF-8; invalid bytes sent through
# Flutter's StandardMessageCodec cause FormatException crashes.
include(FetchContent)
FetchContent_Declare(
  simdutf
  URL https://github.com/simdutf/simdutf/releases/download/v6.4.2/singleheader.zip
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(simdutf)

set(BINARY_NAME "plezy")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Keep MSVC link by-products out of the runnable bundle directory. CI uploads
# the executable output directory directly, so import and static libraries
# emitted there would otherwise be packaged with the application.
set_target_properties(
  ${BINARY_NAME}
  simdutf
  PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/link-artifacts/$<CONFIG>"
)


# Sentry native crash capture: use the in-process handler instead of
# crashpad. Crashpad uploads minidumps straight to the DSN's /minidump
# endpoint, which our self-hosted tracker does not implement — every native
# Windows crash (e.g. faults inside libmpv threads) was silently dropped.
# The inproc handler stackwalks at crash time and reports through the
# regular envelope endpoint on next launch. sentry-native.cmake gives this
# environment variable highest precedence over the plugin's forced default.
set(ENV{SENTRY_NATIVE_BACKEND} "inproc")

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

if(TARGET os_media_controls_plugin)
  # MSVC 14.51 makes C++/WinRT's experimental coroutine include a hard error.
  target_compile_definitions(
    os_media_controls_plugin
    PRIVATE _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS
  )
endif()


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

# Bundle the MSVC C++ runtime next to the executable. MSVC requires the
# runtime on the target machine to be at least as new as the toolset that
# built the app; a stale system-wide msvcp140.dll (e.g. 14.29 from a 2021
# redist) faults at startup inside the DLL under the VS 2022 17.10+
# constexpr std::mutex layout, so the app never opens. App-local copies
# precede System32 in the DLL search order, removing the dependency on the
# machine-wide redistributable entirely.
set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION "${INSTALL_BUNDLE_LIB_DIR}")
set(CMAKE_INSTALL_SYSTEM_RUNTIME_COMPONENT "Runtime")
include(InstallRequiredSystemLibraries)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

# Install mpv DLL
install(FILES "${MPV_LIB_DIR}/libmpv-2.dll"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

# Install the Vulkan loader (and its license) next to the executable so the
# hard import in libmpv-2.dll resolves on machines whose GPU driver does not
# provide vulkan-1.dll.
install(FILES "${VULKAN_RT_DIR}/vulkan-1.dll" "${VULKAN_RT_DIR}/VulkanRT-License.txt"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)
