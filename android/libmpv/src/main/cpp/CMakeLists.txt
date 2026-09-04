cmake_minimum_required(VERSION 3.22.1)

project("libmpv")

# The JNI glue this module compiles; MpvPlayer loads it with
# System.loadLibrary("player") after libmpv.so itself.
add_library(
        player
        SHARED
        main.cpp render.cpp log.cpp jni_utils.cpp property.cpp event.cpp
)

# Prebuilt libraries extracted from the pinned mpv-build per-ABI tarballs by the
# extractLibmpvNative Gradle task; MPV_PREBUILT_ROOT points at its output.
add_library(
        mpv
        SHARED
        IMPORTED
)

set_target_properties(
        mpv
        PROPERTIES IMPORTED_LOCATION
        ${MPV_PREBUILT_ROOT}/jni/${ANDROID_ABI}/libmpv.so
)

# av_jni_set_java_vm / av_jni_set_android_app_ctx (main.cpp) live in FFmpeg's
# libavcodec, which the same tarballs package.
add_library(
        avcodec
        SHARED
        IMPORTED
)

set_target_properties(
        avcodec
        PROPERTIES IMPORTED_LOCATION
        ${MPV_PREBUILT_ROOT}/jni/${ANDROID_ABI}/libavcodec.so
)

# mpv public headers ride in the extracted tarballs next to libmpv.so; the
# vendored tree only carries FFmpeg's libavcodec/jni.h (see include/README.md).
include_directories( ${MPV_PREBUILT_ROOT}/include ${CMAKE_CURRENT_SOURCE_DIR}/include )

target_link_libraries( player mpv avcodec log )
