cmake_minimum_required(VERSION 3.22)
project(plezy_torrent LANGUAGES C CXX)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/engine")
set(plezy_torrent_bundled_libraries $<TARGET_FILE:plezy_torrent> PARENT_SCOPE)
