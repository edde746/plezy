cmake_minimum_required(VERSION 3.19)
project(plezy LANGUAGES CXX)

# libmpv comes from our unified build repository
# (https://github.com/edde746/mpv-build), which publishes per-commit,
# content-addressed dev packages in the classic mpv-dev shape:
# libmpv-2.dll, libmpv.dll.a and include/mpv/*.h at the archive root.
# The asset name and checksum per arch are read from mpv-build.lock.json,
# the single pin shared with Android and Linux (moved by
# scripts/set_native_revision.sh). string(JSON ... GET) fails the configure
# when the windows group is missing, as the lock schema requires.
set(MPV_LOCK_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../mpv-build.lock.json")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${MPV_LOCK_FILE}")
file(READ "${MPV_LOCK_FILE}" MPV_LOCK)
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
  set(MPV_ARCH "aarch64")
else()
  set(MPV_ARCH "x86_64")
endif()
string(JSON MPV_ASSET_BASE GET "${MPV_LOCK}" artifacts windows assetBase)
string(JSON MPV_ASSET GET "${MPV_LOCK}" artifacts windows assets "${MPV_ARCH}" asset)
string(JSON MPV_SHA256 GET "${MPV_LOCK}" artifacts windows assets "${MPV_ARCH}" checksum)
set(MPV_DOWNLOAD_URL "${MPV_ASSET_BASE}/${MPV_ASSET}")

# Explicit development-only FEL engine selection. Never infer an engine from
# a DLL on PATH, and never replace the production pin implicitly.
set(PLEZYNG_DV_ENGINE_ARCHIVE "" CACHE FILEPATH "Experimental FEL engine ZIP")
set(PLEZYNG_DV_ENGINE_SHA256 "" CACHE STRING "Expected SHA256 of the FEL engine ZIP")
if(PLEZYNG_DV_ENGINE_ARCHIVE)
  if(NOT IS_ABSOLUTE "${PLEZYNG_DV_ENGINE_ARCHIVE}" OR
     NOT EXISTS "${PLEZYNG_DV_ENGINE_ARCHIVE}")
    message(FATAL_ERROR "PLEZYNG_DV_ENGINE_ARCHIVE must be an existing absolute local path")
  endif()
  string(LENGTH "${PLEZYNG_DV_ENGINE_SHA256}" DV_HASH_LENGTH)
  if(NOT DV_HASH_LENGTH EQUAL 64 OR NOT PLEZYNG_DV_ENGINE_SHA256 MATCHES "^[0-9a-fA-F]+$")
    message(FATAL_ERROR "An explicit 64-digit PLEZYNG_DV_ENGINE_SHA256 is required")
  endif()
  set(MPV_DOWNLOAD_URL "${PLEZYNG_DV_ENGINE_ARCHIVE}")
  set(MPV_SHA256 "${PLEZYNG_DV_ENGINE_SHA256}")
elseif(PLEZYNG_DV_ENGINE_SHA256)
  message(FATAL_ERROR "PLEZYNG_DV_ENGINE_SHA256 requires PLEZYNG_DV_ENGINE_ARCHIVE")
endif()

# Plain zips extract with CMake's built-in libarchive on every host arch, so
# both arches share the FetchContent path (the old mpv-dev 7z needed a
# 7-Zip binary on ARM64, whose libarchive lacks LZMA2).
include(FetchContent)
FetchContent_Declare(
  mpv_dev
  URL "${MPV_DOWNLOAD_URL}"
  URL_HASH SHA256=${MPV_SHA256}
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(mpv_dev)

set(MPV_INCLUDE_DIR "${mpv_dev_SOURCE_DIR}/include")
set(MPV_LIB_DIR "${mpv_dev_SOURCE_DIR}")
set(MPV_RUNTIME_DLLS "${MPV_LIB_DIR}/libmpv-2.dll")
if(PLEZYNG_DV_ENGINE_ARCHIVE)
  find_package(Python3 3.11 REQUIRED COMPONENTS Interpreter)
  execute_process(
    COMMAND "${Python3_EXECUTABLE}"
      "${CMAKE_CURRENT_SOURCE_DIR}/../tools/dv-engine/engine_bundle.py"
      --root "${MPV_LIB_DIR}" --architecture "${MPV_ARCH}"
      --source-lock "${CMAKE_CURRENT_SOURCE_DIR}/../tools/dv-engine/engine.lock.json"
    RESULT_VARIABLE DV_BUNDLE_RESULT
    OUTPUT_VARIABLE DV_BUNDLE_OUTPUT ERROR_VARIABLE DV_BUNDLE_ERROR)
  if(NOT DV_BUNDLE_RESULT EQUAL 0)
    message(FATAL_ERROR "Experimental FEL engine rejected: ${DV_BUNDLE_ERROR}")
  endif()
  message(WARNING "Using an unqualified experimental FEL engine. ${DV_BUNDLE_OUTPUT}")
  file(GLOB MPV_RUNTIME_DLLS "${MPV_LIB_DIR}/*.dll")
endif()

# The winbuild toolchain dynamically links the Khronos Vulkan loader (since
# 2026-08, and true of our pinned build), so libmpv-2.dll hard-imports
# vulkan-1.dll. On x64
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
  URL_HASH SHA256=9fe4d6f515724a55c8de88fee4463e0890a1abe2267cda13c4b5d245d58039e6
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(simdutf)

set(BINARY_NAME "plezy")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.19...3.25)

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
  # Keep full PDBs in the build tree for local debugging without shipping them
  # in the app bundle. /Z7 keeps compile-time debug info in the objects, so no
  # shared compiler PDB is involved. /DEBUG turns the linker's REF and ICF off
  # by default; restore them so shipped binaries stay the expected size.
  target_compile_options(${TARGET} PRIVATE "$<$<CONFIG:Profile,Release>:/Z7>")
  target_link_options(${TARGET} PRIVATE
    "$<$<CONFIG:Profile,Release>:/DEBUG:FULL>"
    "$<$<CONFIG:Profile,Release>:/OPT:REF>"
    "$<$<CONFIG:Profile,Release>:/OPT:ICF>"
  )
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Keep MSVC link by-products out of the runnable bundle directory. CI uploads
# the executable output directory directly, so import and static libraries
# and the runner's PDB emitted there would otherwise be packaged with the
# application.
set_target_properties(
  ${BINARY_NAME}
  simdutf
  PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/link-artifacts/$<CONFIG>"
)
set_target_properties(
  ${BINARY_NAME}
  PROPERTIES
    PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/link-artifacts/$<CONFIG>"
)


# Sentry native crash capture: use the in-process handler instead of
# crashpad. Crashpad uploads minidumps straight to the DSN's /minidump
# endpoint, which some Sentry-compatible servers do not implement — every native
# Windows crash (e.g. faults inside libmpv threads) was silently dropped.
# The inproc handler stackwalks at crash time and reports through the
# regular envelope endpoint on next launch. sentry-native.cmake gives this
# environment variable highest precedence over the plugin's forced default.
set(ENV{SENTRY_NATIVE_BACKEND} "inproc")

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

if(TARGET flutter_inappwebview_windows_plugin)
  # The webview plugin restores NuGet packages in an unrelated ALL target.
  # Targeted native builds skip that target, and Visual Studio evaluates the
  # packages' .targets imports before build-time restore. Restore at configure
  # time using the plugin's own pinned versions so both paths have the headers
  # and WebView2 loader settings before their projects are generated.
  get_target_property(WEBVIEW_PLUGIN_SOURCE flutter_inappwebview_windows_plugin SOURCE_DIR)
  get_directory_property(WEBVIEW_NUGET DIRECTORY "${WEBVIEW_PLUGIN_SOURCE}" DEFINITION NUGET)
  if(NOT WEBVIEW_NUGET)
    message(FATAL_ERROR "NuGet is required to build the Windows ebook reader")
  endif()
  foreach(WEBVIEW_PACKAGE IN ITEMS
    "Microsoft.Windows.ImplementationLibrary|WIL_VERSION"
    "Microsoft.Windows.CppWinRT|CPP_WINRT_VERSION"
    "Microsoft.Web.WebView2|WEBVIEW_VERSION"
    "nlohmann.json|NLOHMANN_JSON_VERSION"
  )
    string(REPLACE "|" ";" WEBVIEW_PACKAGE_FIELDS "${WEBVIEW_PACKAGE}")
    list(GET WEBVIEW_PACKAGE_FIELDS 0 WEBVIEW_PACKAGE_NAME)
    list(GET WEBVIEW_PACKAGE_FIELDS 1 WEBVIEW_VERSION_VARIABLE)
    get_directory_property(WEBVIEW_PACKAGE_VERSION
      DIRECTORY "${WEBVIEW_PLUGIN_SOURCE}" DEFINITION "${WEBVIEW_VERSION_VARIABLE}")
    if(NOT WEBVIEW_PACKAGE_VERSION)
      message(FATAL_ERROR "The Windows webview plugin must pin ${WEBVIEW_PACKAGE_NAME}")
    endif()
    execute_process(
      COMMAND "${WEBVIEW_NUGET}" install "${WEBVIEW_PACKAGE_NAME}"
        -Version "${WEBVIEW_PACKAGE_VERSION}" -ExcludeVersion -NonInteractive
        -OutputDirectory "${CMAKE_BINARY_DIR}/packages"
      RESULT_VARIABLE WEBVIEW_RESTORE_RESULT
    )
    if(NOT WEBVIEW_RESTORE_RESULT EQUAL 0)
      message(FATAL_ERROR "Could not restore ${WEBVIEW_PACKAGE_NAME} for the Windows ebook reader")
    endif()
  endforeach()
  add_dependencies(flutter_inappwebview_windows_plugin flutter_inappwebview_windows_DEPS)
  # Match the existing C++/WinRT compatibility setting below on MSVC 14.51.
  target_compile_definitions(flutter_inappwebview_windows_plugin
    PRIVATE _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
endif()

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

# Install mpv DLL. Always re-copied: file(INSTALL) skips a destination whose
# size and mtime match the source, and every pin's libmpv-2.dll is the same
# 108,717,056 bytes with the archive's fixed 2019-12-31T23:00:00Z stamp
# (DOWNLOAD_EXTRACT_TIMESTAMP above keeps it), so an incremental build over
# an existing tree fetched the new pin and shipped the previous DLL. Same
# pattern as the flutter_assets re-copy.
foreach(MPV_RUNTIME_DLL IN LISTS MPV_RUNTIME_DLLS)
  get_filename_component(MPV_RUNTIME_NAME "${MPV_RUNTIME_DLL}" NAME)
  install(CODE "file(REMOVE \"${INSTALL_BUNDLE_LIB_DIR}/${MPV_RUNTIME_NAME}\")" COMPONENT Runtime)
endforeach()
install(FILES ${MPV_RUNTIME_DLLS}
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)
if(PLEZYNG_DV_ENGINE_ARCHIVE)
  install(DIRECTORY "${MPV_LIB_DIR}/sources" "${MPV_LIB_DIR}/toolchain-licenses"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/experimental-dv" COMPONENT Runtime)
  install(FILES "${MPV_LIB_DIR}/engine-manifest.json" "${MPV_LIB_DIR}/feature-report.json"
    "${MPV_LIB_DIR}/provenance.json"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/experimental-dv" COMPONENT Runtime)
endif()

# Install the Vulkan loader (and its license) next to the executable so the
# hard import in libmpv-2.dll resolves on machines whose GPU driver does not
# provide vulkan-1.dll.
install(FILES "${VULKAN_RT_DIR}/vulkan-1.dll" "${VULKAN_RT_DIR}/VulkanRT-License.txt"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)


# Optional qualified MilkRust artifacts and their exact corresponding source.
include("${CMAKE_SOURCE_DIR}/../native/visualizer/milkrust.cmake")
plezy_install_milkrust("milkrust_native.dll")
