#pragma once

#include <cstring>

namespace mpv {

// The opt-in API is from mpv PR #18607, not a released libmpv contract.
// Return literals so environment storage is never retained by the renderer.
// nullptr means invalid input; callers must not silently run another backend.
inline const char* ExperimentalRenderApi(const char* requested) {
  if (requested == nullptr || requested[0] == '\0' || std::strcmp(requested, "opengl") == 0) return "opengl";
  if (std::strcmp(requested, "opengl-next") == 0) return "opengl-next";
  return nullptr;
}

}  // namespace mpv
