cmake_minimum_required(VERSION 3.22.1)

project("asskt")

# Fetching the fork release at configure time keeps per-ABI static archives out
# of git; the pinned hash makes that network step reproducible.
set(LIBASS_VERSION "0.18.1")
set(LIBASS_SHA256 "56088619d3907fabbede978d053eca842c1acdda2fea8f11a1e4e1c5722f0624")
set(LIBASS_ZIP_URL "https://github.com/edde746/libass/releases/download/${LIBASS_VERSION}/libass-android-${LIBASS_VERSION}.zip")

# Gradle passes one cache root so per-ABI CMake builds share the download.
if(NOT DEFINED LIBASS_CACHE_DIR)
    set(LIBASS_CACHE_DIR "${CMAKE_BINARY_DIR}/libass-prebuilt")
endif()
set(LIBASS_ROOT "${LIBASS_CACHE_DIR}/libass-android-${LIBASS_VERSION}")
set(LIBASS_ARCHIVE "${LIBASS_ROOT}/lib/${ANDROID_ABI}/libass.a")
set(LIBASS_HEADER "${LIBASS_ROOT}/include/ass/ass.h")

# The downloaded archive lives under Flutter's root build/ directory, which can
# be deleted without invalidating android/libass/.cxx. Model it as a Ninja output
# so stale CMake configure caches can regenerate it during the build step.
file(MAKE_DIRECTORY "${LIBASS_ROOT}/include")
add_custom_command(
    OUTPUT "${LIBASS_ARCHIVE}" "${LIBASS_HEADER}"
    COMMAND "${CMAKE_COMMAND}"
        "-DLIBASS_VERSION=${LIBASS_VERSION}"
        "-DLIBASS_SHA256=${LIBASS_SHA256}"
        "-DLIBASS_ZIP_URL=${LIBASS_ZIP_URL}"
        "-DLIBASS_CACHE_DIR=${LIBASS_CACHE_DIR}"
        "-DLIBASS_ROOT=${LIBASS_ROOT}"
        "-DLIBASS_ARCHIVE=${LIBASS_ARCHIVE}"
        "-DLIBASS_HEADER=${LIBASS_HEADER}"
        "-DANDROID_ABI=${ANDROID_ABI}"
        -P "${CMAKE_CURRENT_LIST_DIR}/FetchLibass.cmake"
    COMMENT "Preparing fork libass ${LIBASS_VERSION} for ${ANDROID_ABI}"
    VERBATIM)

string(REPLACE "-" "_" LIBASS_ABI_TARGET "${ANDROID_ABI}")
add_custom_target(libass_prebuilt_${LIBASS_ABI_TARGET}
    DEPENDS "${LIBASS_ARCHIVE}" "${LIBASS_HEADER}")

add_library(ass STATIC IMPORTED)
set_target_properties(ass PROPERTIES
    IMPORTED_LOCATION "${LIBASS_ARCHIVE}")
target_include_directories(ass INTERFACE "${LIBASS_ROOT}/include")

add_library(${CMAKE_PROJECT_NAME} SHARED AssKt.c SurfaceTxProbe.c)
add_dependencies(${CMAKE_PROJECT_NAME} libass_prebuilt_${LIBASS_ABI_TARGET})
# HarfBuzz brings C++; link the shared STL that the app already packages.
# (SurfaceTxProbe resolves its libandroid/libsync entry points via dlsym, so no extra link.)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        ass
        log
        EGL
        c++_shared)
