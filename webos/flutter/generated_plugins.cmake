#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  shared_preferences_webos
  flutter_secure_storage_webos
  video_player_drm
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
)

set(PLUGIN_BUNDLED_LIBRARIES)
add_definitions(-D_FLUTTER_RUN_MODE=\"${FLUTTER_RUN_MODE}\")
add_definitions(-D_FLUTTER_FRAMEWORK_VERSION=\"${FLUTTER_FRAMEWORK_VERSION}\")

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/webos plugins/${plugin})
  target_link_libraries(${WEBOS_PLUGIN_INTERFACE_LIBRARY} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/webos plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
