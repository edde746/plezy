cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "flutter_secure_storage")
project(${PROJECT_NAME} LANGUAGES C CXX)

find_package(PkgConfig)
pkg_check_modules(PMLOG REQUIRED PmLogLib)
pkg_check_modules(SQLITE3 REQUIRED sqlite3)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_secure_storage_webos_plugin")

add_library(${PLUGIN_NAME} SHARED
  "secure_storage_plugin.cc"
  "secure_storage.cc"
  "log.cc"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_include_directories(${PLUGIN_NAME} PRIVATE
   ${CMAKE_CURRENT_SOURCE_DIR}
   ${PMLOG_INCLUDE_DIRS}
   ${SQLITE3_INCLUDE_DIRS}
)

target_link_libraries(
  ${PLUGIN_NAME} PRIVATE flutter
  ${PMLOG_LIBRARIES}
  ${SQLITE3_LIBRARIES}
)
target_link_directories(${PLUGIN_NAME} PRIVATE ${SQLITE3_LIBRARY_DIRS})

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_secure_storage_handled_libraries
  ""
  PARENT_SCOPE
)
