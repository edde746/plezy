#include "experimental_render_api.h"

#include <cstdio>
#include <cstring>

int main() {
  const char* defaults[] = {nullptr, "", "opengl"};
  for (const char* value : defaults) {
    const char* result = mpv::ExperimentalRenderApi(value);
    if (result == nullptr || std::strcmp(result, "opengl") != 0) return 1;
  }

  char request[] = "opengl-next";
  const char* selected = mpv::ExperimentalRenderApi(request);
  request[0] = 'x';
  if (selected == nullptr || std::strcmp(selected, "opengl-next") != 0) return 2;

  // In particular, a VO name or a misspelled experimental API must not cause a
  // legacy-renderer run to be reported as a successful gpu-next experiment.
  const char* invalid[] = {"gpu-next", "vulkan", "OPENGL-NEXT", "opengl-next ", " opengl-next", "yes"};
  for (const char* value : invalid) {
    if (mpv::ExperimentalRenderApi(value) != nullptr) return 3;
  }
  if (std::strcmp(mpv::ExperimentalRenderApi(nullptr, true), "opengl-next") != 0) return 4;
  if (std::strcmp(mpv::ExperimentalRenderApi("opengl", true), "opengl") != 0) return 5;
  if (!mpv::ExperimentalRenderFallbackAllowed(nullptr, true, true)) return 6;
  if (mpv::ExperimentalRenderFallbackAllowed(nullptr, true, false)) return 7;
  if (mpv::ExperimentalRenderFallbackAllowed(nullptr, false, true)) return 8;
  if (mpv::ExperimentalRenderFallbackAllowed("opengl-next", true, true)) return 9;
  if (mpv::ExperimentalRenderFallbackAllowed("typo", true, true)) return 10;
  std::puts("Experimental render API selection and fallback gates passed");
  return 0;
}
