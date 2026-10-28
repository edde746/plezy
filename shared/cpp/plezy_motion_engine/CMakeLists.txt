cmake_minimum_required(VERSION 3.16)
project(plezy_motion_engine LANGUAGES CXX)

set(ONNXRUNTIME_ROOT "" CACHE PATH "ONNX Runtime SDK root with C API v27 or newer")
set(PME_ORT_RUNTIME_LIBRARY "" CACHE FILEPATH "ONNX Runtime shared library to bundle")
set(PME_PROVIDER_LIBRARIES "" CACHE STRING "ONNX Runtime provider shared libraries to bundle")
set(PME_PROVIDER_DEPENDENCY_LIBRARIES "" CACHE STRING "Non-ORT shared libraries required by execution providers")
option(PME_BUILD_RUNTIME_PROBE "Build the standalone PME provider/inference diagnostic" OFF)
set(PLEZY_ORT_LINUX_VARIANT "cpu" CACHE STRING "Linux ONNX Runtime bundle: cpu or amd-migraphx")
set_property(CACHE PLEZY_ORT_LINUX_VARIANT PROPERTY STRINGS cpu amd-migraphx)

if(UNIX AND NOT APPLE)
  if(NOT PLEZY_ORT_LINUX_VARIANT STREQUAL "cpu" AND NOT PLEZY_ORT_LINUX_VARIANT STREQUAL "amd-migraphx")
    message(FATAL_ERROR "PLEZY_ORT_LINUX_VARIANT must be 'cpu' or 'amd-migraphx'")
  endif()
endif()

set(PME_ORT_RUNTIME_USER_SUPPLIED FALSE)

find_package(Threads REQUIRED)
if(WIN32)
  if(NOT TARGET WindowsML::Api)
    if(NOT PLEZY_WINML_PACKAGE_ROOT OR NOT EXISTS "${PLEZY_WINML_PACKAGE_ROOT}/build/cmake")
      message(FATAL_ERROR "PLEZY_WINML_PACKAGE_ROOT must point to the extracted Windows ML NuGet package")
    endif()
    find_package(microsoft.windows.ai.machinelearning CONFIG REQUIRED
      PATHS "${PLEZY_WINML_PACKAGE_ROOT}/build/cmake"
      NO_DEFAULT_PATH
    )
  endif()
  if(NOT WINML_INCLUDE_DIR OR NOT WINML_BINARY_DIR OR NOT WINML_DIRECTML_DLL)
    message(FATAL_ERROR "PLEZY_WINML_PACKAGE_ROOT must point to the extracted Windows ML NuGet package")
  endif()
  set(ONNXRUNTIME_ROOT "${PLEZY_WINML_PACKAGE_ROOT}")
  set(ONNXRUNTIME_INCLUDE_DIR "${WINML_INCLUDE_DIR}/winml")
  set(PME_ORT_RUNTIME_LIBRARY "${WINML_BINARY_DIR}/onnxruntime.dll")
endif()

if(NOT WIN32 AND NOT ONNXRUNTIME_ROOT AND DEFINED ENV{ONNXRUNTIME_ROOT})
  set(ONNXRUNTIME_ROOT "$ENV{ONNXRUNTIME_ROOT}")
endif()
if(NOT PME_ORT_RUNTIME_LIBRARY AND DEFINED ENV{PME_ORT_RUNTIME_LIBRARY})
  set(PME_ORT_RUNTIME_LIBRARY "$ENV{PME_ORT_RUNTIME_LIBRARY}")
  set(PME_ORT_RUNTIME_USER_SUPPLIED TRUE)
elseif(PME_ORT_RUNTIME_LIBRARY)
  set(PME_ORT_RUNTIME_USER_SUPPLIED TRUE)
endif()

# Linux app builds get a reproducible SDK/runtime by default. AMD's MIGraphX
# mode keeps the official API-v27 SDK for compilation but stages AMD's pinned
# ORT 1.23 runtime and built-in provider from the matching ROCm wheel.
if(UNIX AND NOT APPLE)
  if(FLUTTER_TARGET_PLATFORM STREQUAL "linux-arm64")
    set(PLEZY_ORT_PLATFORM "linux-aarch64")
    set(PLEZY_ORT_SHA256 "33c67e33d1e25b816878366ea276589a024f71f000e7ff955c4b33224d639edd")
  elseif(FLUTTER_TARGET_PLATFORM STREQUAL "linux-x64")
    set(PLEZY_ORT_PLATFORM "linux-x64")
    set(PLEZY_ORT_SHA256 "25b1ef1fea1acd210d63f8f24dc870ad6e077795ce1f54876252c6d3803c15af")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    set(PLEZY_ORT_PLATFORM "linux-aarch64")
    set(PLEZY_ORT_SHA256 "33c67e33d1e25b816878366ea276589a024f71f000e7ff955c4b33224d639edd")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64)$")
    set(PLEZY_ORT_PLATFORM "linux-x64")
    set(PLEZY_ORT_SHA256 "25b1ef1fea1acd210d63f8f24dc870ad6e077795ce1f54876252c6d3803c15af")
  else()
    message(FATAL_ERROR "No pinned ONNX Runtime package for Linux target '${FLUTTER_TARGET_PLATFORM}' (${CMAKE_SYSTEM_PROCESSOR})")
  endif()
endif()

if(UNIX AND NOT APPLE AND NOT ONNXRUNTIME_ROOT)
  set(PLEZY_ORT_VERSION "1.27.1")
  set(PLEZY_ORT_ARCHIVE_NAME "onnxruntime-${PLEZY_ORT_PLATFORM}-${PLEZY_ORT_VERSION}.tgz")
  set(PLEZY_ORT_CACHE_DIR "${CMAKE_BINARY_DIR}/onnxruntime/${PLEZY_ORT_VERSION}")
  set(PLEZY_ORT_DOWNLOAD_DIR "${PLEZY_ORT_CACHE_DIR}/downloads")
  set(PLEZY_ORT_EXTRACT_DIR "${PLEZY_ORT_CACHE_DIR}/sdk")
  set(PLEZY_ORT_ROOT "${PLEZY_ORT_EXTRACT_DIR}/onnxruntime-${PLEZY_ORT_PLATFORM}-${PLEZY_ORT_VERSION}")
  set(PLEZY_ORT_ARCHIVE "${PLEZY_ORT_DOWNLOAD_DIR}/${PLEZY_ORT_ARCHIVE_NAME}")
  file(MAKE_DIRECTORY "${PLEZY_ORT_DOWNLOAD_DIR}" "${PLEZY_ORT_EXTRACT_DIR}")

  if(EXISTS "${PLEZY_ORT_ARCHIVE}")
    file(SHA256 "${PLEZY_ORT_ARCHIVE}" PLEZY_ORT_CACHED_SHA256)
    if(NOT PLEZY_ORT_CACHED_SHA256 STREQUAL PLEZY_ORT_SHA256)
      file(REMOVE "${PLEZY_ORT_ARCHIVE}")
    endif()
  endif()
  if(NOT EXISTS "${PLEZY_ORT_ARCHIVE}")
    message(STATUS "Downloading pinned ONNX Runtime ${PLEZY_ORT_VERSION} for ${PLEZY_ORT_PLATFORM}")
    file(DOWNLOAD
      "https://github.com/microsoft/onnxruntime/releases/download/v${PLEZY_ORT_VERSION}/${PLEZY_ORT_ARCHIVE_NAME}"
      "${PLEZY_ORT_ARCHIVE}"
      EXPECTED_HASH "SHA256=${PLEZY_ORT_SHA256}"
      STATUS PLEZY_ORT_DOWNLOAD_STATUS
    )
    list(GET PLEZY_ORT_DOWNLOAD_STATUS 0 PLEZY_ORT_DOWNLOAD_RESULT)
    if(NOT PLEZY_ORT_DOWNLOAD_RESULT EQUAL 0)
      file(REMOVE "${PLEZY_ORT_ARCHIVE}")
      message(FATAL_ERROR "Could not download the verified ONNX Runtime package: ${PLEZY_ORT_DOWNLOAD_STATUS}")
    endif()
  endif()
  if(NOT EXISTS "${PLEZY_ORT_ROOT}/include/onnxruntime_c_api.h")
    execute_process(
      COMMAND "${CMAKE_COMMAND}" -E tar xzf "${PLEZY_ORT_ARCHIVE}"
      WORKING_DIRECTORY "${PLEZY_ORT_EXTRACT_DIR}"
      RESULT_VARIABLE PLEZY_ORT_EXTRACT_RESULT
    )
    if(NOT PLEZY_ORT_EXTRACT_RESULT EQUAL 0 OR NOT EXISTS "${PLEZY_ORT_ROOT}/include/onnxruntime_c_api.h")
      message(FATAL_ERROR "Could not extract the pinned ONNX Runtime SDK")
    endif()
  endif()
  set(ONNXRUNTIME_ROOT "${PLEZY_ORT_ROOT}")
  if(NOT PME_ORT_RUNTIME_LIBRARY_USER_SUPPLIED AND NOT PLEZY_ORT_LINUX_VARIANT STREQUAL "amd-migraphx")
    set(PME_ORT_RUNTIME_LIBRARY "${PLEZY_ORT_ROOT}/lib/libonnxruntime.so")
  endif()
endif()

set(PME_ORT_LICENSE_FILE "${ONNXRUNTIME_ROOT}/LICENSE")
set(PME_ORT_THIRD_PARTY_NOTICES_FILE "${ONNXRUNTIME_ROOT}/ThirdPartyNotices.txt")
set(PME_LINUX_PROVIDER_MANIFEST "${CMAKE_CURRENT_LIST_DIR}/providers.linux.tsv")

if(UNIX AND NOT APPLE AND PLEZY_ORT_LINUX_VARIANT STREQUAL "amd-migraphx")
  if(NOT PLEZY_ORT_PLATFORM STREQUAL "linux-x64")
    message(FATAL_ERROR "The pinned AMD ROCm 7.2.1 MIGraphX package requires the linux-x64 target")
  endif()
  if(PME_ORT_RUNTIME_USER_SUPPLIED)
    message(FATAL_ERROR "PLEZY_ORT_LINUX_VARIANT=amd-migraphx pins its own ORT runtime; unset PME_ORT_RUNTIME_LIBRARY")
  endif()

  set(PLEZY_AMD_ORT_VERSION "1.23.2")
  set(PLEZY_AMD_ROCM_VERSION "7.2.1")
  set(PLEZY_AMD_ORT_WHEEL_NAME "onnxruntime_migraphx-${PLEZY_AMD_ORT_VERSION}-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
  set(PLEZY_AMD_ORT_WHEEL_SHA256 "663bff4dc3f72582d69f12ad073eb5695dfb526d574376cc8e5b161c7d2f0f08")
  set(PLEZY_AMD_ORT_CACHE_DIR "${CMAKE_BINARY_DIR}/onnxruntime/rocm-${PLEZY_AMD_ROCM_VERSION}")
  set(PLEZY_AMD_ORT_DOWNLOAD_DIR "${PLEZY_AMD_ORT_CACHE_DIR}/downloads")
  set(PLEZY_AMD_ORT_EXTRACT_DIR "${PLEZY_AMD_ORT_CACHE_DIR}/runtime")
  set(PLEZY_AMD_ORT_WHEEL "${PLEZY_AMD_ORT_DOWNLOAD_DIR}/${PLEZY_AMD_ORT_WHEEL_NAME}")
  file(MAKE_DIRECTORY "${PLEZY_AMD_ORT_DOWNLOAD_DIR}" "${PLEZY_AMD_ORT_EXTRACT_DIR}")

  if(EXISTS "${PLEZY_AMD_ORT_WHEEL}")
    file(SHA256 "${PLEZY_AMD_ORT_WHEEL}" PLEZY_AMD_ORT_CACHED_SHA256)
    if(NOT PLEZY_AMD_ORT_CACHED_SHA256 STREQUAL PLEZY_AMD_ORT_WHEEL_SHA256)
      file(REMOVE "${PLEZY_AMD_ORT_WHEEL}")
    endif()
  endif()
  if(NOT EXISTS "${PLEZY_AMD_ORT_WHEEL}")
    message(STATUS "Downloading pinned AMD ROCm ${PLEZY_AMD_ROCM_VERSION} ONNX Runtime ${PLEZY_AMD_ORT_VERSION} MIGraphX package")
    file(DOWNLOAD
      "https://repo.radeon.com/rocm/manylinux/rocm-rel-${PLEZY_AMD_ROCM_VERSION}/${PLEZY_AMD_ORT_WHEEL_NAME}"
      "${PLEZY_AMD_ORT_WHEEL}"
      EXPECTED_HASH "SHA256=${PLEZY_AMD_ORT_WHEEL_SHA256}"
      STATUS PLEZY_AMD_ORT_DOWNLOAD_STATUS
    )
    list(GET PLEZY_AMD_ORT_DOWNLOAD_STATUS 0 PLEZY_AMD_ORT_DOWNLOAD_RESULT)
    if(NOT PLEZY_AMD_ORT_DOWNLOAD_RESULT EQUAL 0)
      file(REMOVE "${PLEZY_AMD_ORT_WHEEL}")
      message(FATAL_ERROR "Could not download the verified AMD ONNX Runtime package: ${PLEZY_AMD_ORT_DOWNLOAD_STATUS}")
    endif()
  endif()

  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  execute_process(
    COMMAND "${Python3_EXECUTABLE}"
      "${CMAKE_CURRENT_LIST_DIR}/../../../scripts/motion/extract_amd_ort_wheel.py"
      "${PLEZY_AMD_ORT_WHEEL}"
      "${PLEZY_AMD_ORT_EXTRACT_DIR}"
      "${PLEZY_AMD_ORT_WHEEL_SHA256}"
    RESULT_VARIABLE PLEZY_AMD_ORT_EXTRACT_RESULT
    OUTPUT_VARIABLE PLEZY_AMD_ORT_EXTRACT_OUTPUT
    ERROR_VARIABLE PLEZY_AMD_ORT_EXTRACT_ERROR
  )
  if(NOT PLEZY_AMD_ORT_EXTRACT_RESULT EQUAL 0)
    message(FATAL_ERROR "Could not extract the pinned AMD ONNX Runtime package: ${PLEZY_AMD_ORT_EXTRACT_ERROR}")
  endif()

  set(PLEZY_AMD_ORT_RUNTIME "${PLEZY_AMD_ORT_EXTRACT_DIR}/libonnxruntime.so.1.23.2")
  set(PME_ORT_RUNTIME_LIBRARY "${PLEZY_AMD_ORT_RUNTIME}")
  list(APPEND PME_PROVIDER_LIBRARIES
    "${PLEZY_AMD_ORT_EXTRACT_DIR}/libonnxruntime_providers_migraphx.so"
    "${PLEZY_AMD_ORT_EXTRACT_DIR}/libonnxruntime_providers_shared.so"
  )
  set(PME_ORT_LICENSE_FILE "${PLEZY_AMD_ORT_EXTRACT_DIR}/ONNXRuntime-License.txt")
  set(PME_ORT_THIRD_PARTY_NOTICES_FILE "${PLEZY_AMD_ORT_EXTRACT_DIR}/ONNXRuntime-ThirdPartyNotices.txt")
  set(PME_LINUX_PROVIDER_MANIFEST "${CMAKE_CURRENT_LIST_DIR}/providers.linux.migraphx.tsv")
endif()

find_path(ONNXRUNTIME_INCLUDE_DIR
  NAMES onnxruntime_c_api.h
  HINTS
    "${ONNXRUNTIME_ROOT}/include"
    "${ONNXRUNTIME_ROOT}/include/winml"
    "$ENV{ONNXRUNTIME_ROOT}/include"
    "$ENV{ONNXRUNTIME_ROOT}/include/winml"
)
if(NOT ONNXRUNTIME_INCLUDE_DIR)
  message(FATAL_ERROR "ONNXRUNTIME_ROOT must point to an ONNX Runtime distribution with onnxruntime_c_api.h")
endif()

if(NOT PME_ORT_RUNTIME_LIBRARY)
  unset(PME_ORT_RUNTIME_LIBRARY CACHE)
  find_file(PME_ORT_RUNTIME_LIBRARY
    NAMES onnxruntime.dll libonnxruntime.so libonnxruntime.dylib
    HINTS
      "${ONNXRUNTIME_ROOT}/lib"
      "${ONNXRUNTIME_ROOT}/bin"
      "$ENV{ONNXRUNTIME_ROOT}/lib"
      "$ENV{ONNXRUNTIME_ROOT}/bin"
  )
endif()
if(NOT PME_ORT_RUNTIME_LIBRARY OR NOT EXISTS "${PME_ORT_RUNTIME_LIBRARY}")
  message(FATAL_ERROR "Set PME_ORT_RUNTIME_LIBRARY to the ONNX Runtime shared library")
endif()

foreach(provider_library IN LISTS PME_PROVIDER_LIBRARIES PME_PROVIDER_DEPENDENCY_LIBRARIES)
  if(NOT EXISTS "${provider_library}")
    message(FATAL_ERROR "ONNX Runtime provider runtime file does not exist: ${provider_library}")
  endif()
endforeach()

add_library(plezy_motion_engine SHARED pme_runtime.cpp)
if(WIN32)
  target_compile_features(plezy_motion_engine PRIVATE cxx_std_20)
else()
  target_compile_features(plezy_motion_engine PRIVATE cxx_std_17)
endif()
target_compile_definitions(plezy_motion_engine PRIVATE PME_RUNTIME_BUILD)
if(WIN32)
  target_compile_definitions(plezy_motion_engine PRIVATE PME_HAVE_WINML=1)
endif()
target_include_directories(plezy_motion_engine
  PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}"
  PRIVATE "${ONNXRUNTIME_INCLUDE_DIR}"
)
if(WIN32)
  target_include_directories(plezy_motion_engine PRIVATE "${WINML_INCLUDE_DIR}")
endif()
set_target_properties(plezy_motion_engine PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN YES
)
if(UNIX AND NOT APPLE)
  set_target_properties(plezy_motion_engine PROPERTIES INSTALL_RPATH "$ORIGIN")
endif()

if(CMAKE_DL_LIBS)
  target_link_libraries(plezy_motion_engine PRIVATE "${CMAKE_DL_LIBS}")
endif()
target_link_libraries(plezy_motion_engine PRIVATE Threads::Threads)
if(WIN32)
  target_link_libraries(plezy_motion_engine PRIVATE WindowsML::Api)
endif()

if(WIN32)
  set(PME_INSTALL_LIBDIR ".")
  set(PME_ORT_INSTALL_NAME "onnxruntime.dll")
elseif(APPLE)
  set(PME_INSTALL_LIBDIR "lib")
  set(PME_ORT_INSTALL_NAME "libonnxruntime.dylib")
else()
  set(PME_INSTALL_LIBDIR "lib")
  set(PME_ORT_INSTALL_NAME "libonnxruntime.so")
endif()

install(TARGETS plezy_motion_engine
  RUNTIME DESTINATION "${PME_INSTALL_LIBDIR}" COMPONENT Runtime
  LIBRARY DESTINATION "${PME_INSTALL_LIBDIR}" COMPONENT Runtime
  ARCHIVE DESTINATION lib COMPONENT Runtime
)
install(FILES pme_runtime.h DESTINATION include/plezy_motion_engine COMPONENT Runtime)
install(FILES "${PME_ORT_RUNTIME_LIBRARY}"
  DESTINATION "${PME_INSTALL_LIBDIR}"
  RENAME "${PME_ORT_INSTALL_NAME}"
  COMPONENT Runtime
)
if(UNIX AND NOT APPLE)
  # ONNX Runtime ships libonnxruntime.so as a symlink chain. Installing only
  # that entry leaves the bundle pointing at a missing .so.1 target, and the
  # shared provider interface library is needed when execution providers load.
  get_filename_component(PME_ORT_RUNTIME_DIRECTORY "${PME_ORT_RUNTIME_LIBRARY}" DIRECTORY)
  install(DIRECTORY "${PME_ORT_RUNTIME_DIRECTORY}/"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    COMPONENT Runtime
    FILES_MATCHING
      PATTERN "libonnxruntime.so.*"
      PATTERN "libonnxruntime_providers_shared.so*"
  )
  install(FILES "${PME_ORT_LICENSE_FILE}"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    RENAME "ONNXRuntime-License.txt"
    COMPONENT Runtime
    OPTIONAL
  )
  install(FILES "${PME_ORT_THIRD_PARTY_NOTICES_FILE}"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    RENAME "ONNXRuntime-ThirdPartyNotices.txt"
    COMPONENT Runtime
    OPTIONAL
  )
endif()
if(WIN32)
  install(FILES
    "${WINML_BINARY_DIR}/Microsoft.Windows.AI.MachineLearning.dll"
    "${WINML_DIRECTML_DLL}"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    COMPONENT Runtime
  )
  install(FILES "${PLEZY_WINML_PACKAGE_ROOT}/license.txt"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    RENAME "WindowsML-License.txt"
    COMPONENT Runtime
  )
  install(FILES "${PLEZY_WINML_PACKAGE_ROOT}/ThirdPartyNotices.txt"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    RENAME "WindowsML-ThirdPartyNotices.txt"
    COMPONENT Runtime
  )
endif()
if(PME_PROVIDER_LIBRARIES)
  install(FILES ${PME_PROVIDER_LIBRARIES}
    DESTINATION "${PME_INSTALL_LIBDIR}"
    COMPONENT Runtime
  )
endif()
if(PME_PROVIDER_DEPENDENCY_LIBRARIES)
  install(FILES ${PME_PROVIDER_DEPENDENCY_LIBRARIES}
    DESTINATION "${PME_INSTALL_LIBDIR}"
    COMPONENT Runtime
  )
endif()

if(WIN32)
  install(FILES providers.windows.tsv DESTINATION "${PME_INSTALL_LIBDIR}" COMPONENT Runtime)
elseif(UNIX AND NOT APPLE)
  install(FILES "${PME_LINUX_PROVIDER_MANIFEST}"
    DESTINATION "${PME_INSTALL_LIBDIR}"
    RENAME providers.linux.tsv
    COMPONENT Runtime
  )
endif()

if(PME_BUILD_RUNTIME_PROBE)
  add_executable(plezy_motion_runtime_probe
    "${CMAKE_CURRENT_LIST_DIR}/../../../scripts/motion/pme_runtime_probe.cpp"
  )
  target_compile_features(plezy_motion_runtime_probe PRIVATE cxx_std_17)
  target_include_directories(plezy_motion_runtime_probe PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  target_link_libraries(plezy_motion_runtime_probe PRIVATE plezy_motion_engine)
  if(UNIX AND NOT APPLE)
    set_target_properties(plezy_motion_runtime_probe PROPERTIES INSTALL_RPATH "$ORIGIN/../lib")
    set(PME_PROBE_INSTALL_BINDIR bin)
  else()
    set(PME_PROBE_INSTALL_BINDIR "${PME_INSTALL_LIBDIR}")
  endif()
  install(TARGETS plezy_motion_runtime_probe
    RUNTIME DESTINATION "${PME_PROBE_INSTALL_BINDIR}"
    COMPONENT DevTools
  )
endif()
