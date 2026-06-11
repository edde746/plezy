cmake_minimum_required(VERSION 3.22.1)

project("asskt")

# libass headers + libass.so come from the io.github.peerless2012:ass AAR via prefab.
add_library(${CMAKE_PROJECT_NAME} SHARED AssKt.c)
find_package(lib_ass REQUIRED CONFIG)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        lib_ass::ass
        log)
