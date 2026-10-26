#pragma once

#include <cstring>

namespace mpv {

// The opt-in API is from mpv PR #18607, not a released libmpv contract.
// Return literals so environment storage is never retained by the renderer.
// nullptr means invalid input; callers must not silently run another backend.
inline const char* ExperimentalRenderApi(const char* requested, bool opted_in = false) {
  if (requested == nullptr || requested[0] == '\0') return opted_in ? "opengl-next" : "opengl";
  if (std::strcmp(requested, "opengl") == 0) return "opengl";
  if (std::strcmp(requested, "opengl-next") == 0) return "opengl-next";
  return nullptr;
}

// An explicit environment override remains strict. Only the settings-driven
// request may fall back, and only when the separate compatibility switch is on.
inline bool ExperimentalRenderFallbackAllowed(const char* requested, bool opted_in, bool allow_fallback) {
  return (requested == nullptr || requested[0] == '\0') && opted_in && allow_fallback;
}

}  // namespace mpv
