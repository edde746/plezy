cmake_minimum_required(VERSION 3.15)
project(runner LANGUAGES CXX)

include(${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral/webos_build.cmake)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../packages/plezy_torrent/src" "${CMAKE_CURRENT_BINARY_DIR}/torrent")
install(TARGETS plezy_torrent LIBRARY DESTINATION lib)
