cmake_minimum_required(VERSION 3.22.1)
project(dovi_bridge_test LANGUAGES CXX)

enable_testing()

add_executable(dovi_bridge_test dovi_bridge_test.cpp)
target_compile_features(dovi_bridge_test PRIVATE cxx_std_17)
target_include_directories(dovi_bridge_test PRIVATE fakes)

add_test(NAME dovi_bridge_test COMMAND dovi_bridge_test)

add_executable(ffmpeg_audio_buffer_test ffmpeg_audio_buffer_test.cpp)
target_compile_features(ffmpeg_audio_buffer_test PRIVATE cxx_std_17)

add_test(NAME ffmpeg_audio_buffer_test COMMAND ffmpeg_audio_buffer_test)

add_executable(mpv_utf8_convert_test mpv_utf8_convert_test.cpp)
target_compile_features(mpv_utf8_convert_test PRIVATE cxx_std_17)

add_test(NAME mpv_utf8_convert_test COMMAND mpv_utf8_convert_test)

find_package(Threads REQUIRED)
add_executable(mpv_lifecycle_test mpv_lifecycle_test.cpp)
target_compile_features(mpv_lifecycle_test PRIVATE cxx_std_17)
target_include_directories(mpv_lifecycle_test PRIVATE fakes ../../../../libmpv/src/main/cpp/include)
target_link_libraries(mpv_lifecycle_test PRIVATE Threads::Threads)

add_test(NAME mpv_lifecycle_test COMMAND mpv_lifecycle_test)
set_tests_properties(mpv_lifecycle_test PROPERTIES TIMEOUT 30)
