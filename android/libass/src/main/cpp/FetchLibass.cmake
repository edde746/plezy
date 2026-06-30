cmake_minimum_required(VERSION 3.22.1)

foreach(_var IN ITEMS
        LIBASS_VERSION
        LIBASS_SHA256
        LIBASS_ZIP_URL
        LIBASS_CACHE_DIR
        LIBASS_ROOT
        LIBASS_ARCHIVE
        LIBASS_HEADER
        ANDROID_ABI)
    if(NOT DEFINED ${_var} OR "${${_var}}" STREQUAL "")
        message(FATAL_ERROR "${_var} is required")
    endif()
endforeach()

get_filename_component(_cache_parent "${LIBASS_CACHE_DIR}" DIRECTORY)
file(MAKE_DIRECTORY "${_cache_parent}")

# Android Gradle can build ABI variants in parallel; serialize the shared cache.
file(LOCK "${LIBASS_CACHE_DIR}.lock" GUARD PROCESS TIMEOUT 300)

if(NOT EXISTS "${LIBASS_ARCHIVE}" OR NOT EXISTS "${LIBASS_HEADER}")
    file(MAKE_DIRECTORY "${LIBASS_CACHE_DIR}")
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

    file(REMOVE_RECURSE "${LIBASS_ROOT}")
    file(ARCHIVE_EXTRACT INPUT "${_libass_zip}" DESTINATION "${LIBASS_CACHE_DIR}")
endif()

if(NOT EXISTS "${LIBASS_ARCHIVE}")
    message(FATAL_ERROR "libass archive for ${ANDROID_ABI} was not extracted: ${LIBASS_ARCHIVE}")
endif()
if(NOT EXISTS "${LIBASS_HEADER}")
    message(FATAL_ERROR "libass headers were not extracted: ${LIBASS_HEADER}")
endif()
