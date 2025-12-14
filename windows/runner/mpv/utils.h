#ifndef MPV_UTILS_H_
#define MPV_UTILS_H_

#include <Windows.h>
#include <dwmapi.h>

#include <cstdint>

namespace mpv {

// Sets window composition attribute for transparency.
// accent_state = 6 enables per-pixel transparency.
// accent_state = 0 makes window opaque.
void SetWindowComposition(HWND window, int32_t accent_state,
                          int32_t gradient_color);

}  // namespace mpv

#endif  // MPV_UTILS_H_
