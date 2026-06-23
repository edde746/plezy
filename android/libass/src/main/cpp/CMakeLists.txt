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

if(NOT EXISTS "${LIBASS_ROOT}/lib/${ANDROID_ABI}/libass.a")
    set(_libass_zip "${LIBASS_CACHE_DIR}/libass-android-${LIBASS_VERSION}.zip")
    message(STATUS "Fetching fork libass ${LIBASS_VERSION} from ${LIBASS_ZIP_URL}")
    file(DOWNLOAD "${LIBASS_ZIP_URL}" "${_libass_zip}"
        EXPECTED_HASH "SHA256=${LIBASS_SHA256}"
        TLS_VERIFY ON
        STATUS _libass_dl)
    list(GET _libass_dl 0 _libass_dl_code)
    if(NOT _libass_dl_code EQUAL 0)
        file(REMOVE "${_libass_zip}")
        message(FATAL_ERROR "Failed to download libass: ${_libass_dl}")
    endif()
    file(ARCHIVE_EXTRACT INPUT "${_libass_zip}" DESTINATION "${LIBASS_CACHE_DIR}")
endif()

add_library(ass STATIC IMPORTED)
set_target_properties(ass PROPERTIES
    IMPORTED_LOCATION "${LIBASS_ROOT}/lib/${ANDROID_ABI}/libass.a")
target_include_directories(ass INTERFACE "${LIBASS_ROOT}/include")

add_library(${CMAKE_PROJECT_NAME} SHARED AssKt.c SurfaceTxProbe.c)
# HarfBuzz brings C++; link the shared STL that the app already packages.
# (SurfaceTxProbe resolves its libandroid/libsync entry points via dlsym, so no extra link.)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        ass
        log
        EGL
        c++_shared)
