cmake_minimum_required(VERSION 3.22.1)
project(plezy_native)

option(DOVI_ENABLE_LIBDOVI "Link real libdovi" ON)
set(DOVI_LIBDOVI_PREBUILT_ROOT "" CACHE PATH "Path to prebuilt libdovi")
set(MPV_FFMPEG_ROOT "" CACHE PATH "Path to libmpv's FFmpeg headers and shared libraries")

add_library(dovi_bridge SHARED dovi_bridge.cpp)

if(DOVI_ENABLE_LIBDOVI)
    add_library(dovi_static STATIC IMPORTED)
    set_target_properties(dovi_static PROPERTIES
        IMPORTED_LOCATION "${DOVI_LIBDOVI_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libdovi.a")
    target_compile_definitions(dovi_bridge PRIVATE DOVI_REAL_LINKED=1)
    target_include_directories(dovi_bridge PRIVATE ${CMAKE_SOURCE_DIR}/include)
    target_link_libraries(dovi_bridge dovi_static log)
else()
    target_compile_definitions(dovi_bridge PRIVATE DOVI_REAL_LINKED=0)
    target_link_libraries(dovi_bridge log)
endif()

foreach(ffmpeg_library avcodec avutil swresample)
    add_library(${ffmpeg_library} SHARED IMPORTED)
    set_target_properties(${ffmpeg_library} PROPERTIES
        IMPORTED_LOCATION "${MPV_FFMPEG_ROOT}/native/${ANDROID_ABI}/lib${ffmpeg_library}.so")
endforeach()

add_library(ffmpegJNI SHARED
    media3_ffmpeg_decoder/ffmpeg_jni.cc)
target_compile_features(ffmpegJNI PRIVATE cxx_std_17)
target_include_directories(ffmpegJNI PRIVATE
    "${MPV_FFMPEG_ROOT}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/media3_ffmpeg_decoder")
target_link_libraries(ffmpegJNI
    avcodec
    avutil
    swresample
    android
    log)
