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
