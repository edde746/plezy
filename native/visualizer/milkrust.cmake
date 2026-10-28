# Optional, produced-on-private-JIT artifacts. No download or guessed pin.
set(PLEZY_VISUALIZER_MILKRUST_LIBRARY "" CACHE FILEPATH "Qualified native MilkRust shared library")
set(PLEZY_VISUALIZER_MILKRUST_SHA256 "" CACHE STRING "Reviewed MilkRust library SHA-256")
set(PLEZY_VISUALIZER_MILKRUST_SOURCE_ARCHIVE "" CACHE FILEPATH "Exact corresponding-source archive")
set(PLEZY_VISUALIZER_MILKRUST_SOURCE_SHA256 "" CACHE STRING "Reviewed corresponding-source SHA-256")

function(plezy_install_milkrust runtime_name)
  if(NOT PLEZY_VISUALIZER_MILKRUST_LIBRARY)
    return()
  endif()
  foreach(artifact IN ITEMS LIBRARY SOURCE_ARCHIVE)
    set(path "${PLEZY_VISUALIZER_MILKRUST_${artifact}}")
    if(artifact STREQUAL "LIBRARY")
      set(expected "${PLEZY_VISUALIZER_MILKRUST_SHA256}")
    else()
      set(expected "${PLEZY_VISUALIZER_MILKRUST_SOURCE_SHA256}")
    endif()
    string(LENGTH "${expected}" digest_length)
    if(NOT EXISTS "${path}" OR IS_DIRECTORY "${path}" OR NOT digest_length EQUAL 64 OR
       NOT expected MATCHES "^[a-fA-F0-9]+$")
      message(FATAL_ERROR "MilkRust ${artifact} requires an existing artifact and a reviewed SHA-256")
    endif()
    file(SHA256 "${path}" actual)
    string(TOLOWER "${expected}" expected)
    if(NOT actual STREQUAL expected)
      message(FATAL_ERROR "MilkRust ${artifact} digest differs from the configured pin")
    endif()
  endforeach()
  # Remove first: native artifacts can have identical timestamp and file size.
  install(CODE "file(REMOVE \"${INSTALL_BUNDLE_LIB_DIR}/${runtime_name}\")" COMPONENT Runtime)
  install(FILES "${PLEZY_VISUALIZER_MILKRUST_LIBRARY}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" RENAME "${runtime_name}" COMPONENT Runtime)
  install(FILES "${PLEZY_VISUALIZER_MILKRUST_SOURCE_ARCHIVE}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/visualizer-notices/source" COMPONENT Runtime)
  install(DIRECTORY "${CMAKE_SOURCE_DIR}/../native/visualizer/notices/"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/visualizer-notices" COMPONENT Runtime)
  install(FILES "${CMAKE_SOURCE_DIR}/../native/visualizer/sources.lock.json"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/visualizer-notices" COMPONENT Runtime)
endfunction()
