#include "utils.h"

namespace mpv {

typedef enum _WINDOWCOMPOSITIONATTRIB {
  WCA_UNDEFINED = 0,
  WCA_NCRENDERING_ENABLED = 1,
  WCA_NCRENDERING_POLICY = 2,
  WCA_TRANSITIONS_FORCEDISABLED = 3,
  WCA_ALLOW_NCPAINT = 4,
  WCA_CAPTION_BUTTON_BOUNDS = 5,
  WCA_NONCLIENT_RTL_LAYOUT = 6,
  WCA_FORCE_ICONIC_REPRESENTATION = 7,
  WCA_EXTENDED_FRAME_BOUNDS = 8,
  WCA_HAS_ICONIC_BITMAP = 9,
  WCA_THEME_ATTRIBUTES = 10,
  WCA_NCRENDERING_EXILED = 11,
  WCA_NCADORNMENTINFO = 12,
  WCA_EXCLUDED_FROM_LIVEPREVIEW = 13,
  WCA_VIDEO_OVERLAY_ACTIVE = 14,
  WCA_FORCE_ACTIVEWINDOW_APPEARANCE = 15,
  WCA_DISALLOW_PEEK = 16,
  WCA_CLOAK = 17,
  WCA_CLOAKED = 18,
  WCA_ACCENT_POLICY = 19,
  WCA_FREEZE_REPRESENTATION = 20,
  WCA_EVER_UNCLOAKED = 21,
  WCA_VISUAL_OWNER = 22,
  WCA_HOLOGRAPHIC = 23,
  WCA_EXCLUDED_FROM_DDA = 24,
  WCA_PASSIVEUPDATEMODE = 25,
  WCA_USEDARKMODECOLORS = 26,
  WCA_LAST = 27
} WINDOWCOMPOSITIONATTRIB;

typedef struct _WINDOWCOMPOSITIONATTRIBDATA {
  WINDOWCOMPOSITIONATTRIB Attrib;
  PVOID pvData;
  SIZE_T cbData;
} WINDOWCOMPOSITIONATTRIBDATA;

typedef enum _ACCENT_STATE {
  ACCENT_DISABLED = 0,
  ACCENT_ENABLE_GRADIENT = 1,
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
  ACCENT_ENABLE_BLURBEHIND = 3,
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
  ACCENT_ENABLE_HOSTBACKDROP = 5,
  ACCENT_INVALID_STATE = 6
} ACCENT_STATE;

typedef struct _ACCENT_POLICY {
  ACCENT_STATE AccentState;
  DWORD AccentFlags;
  DWORD GradientColor;
  DWORD AnimationId;
} ACCENT_POLICY;

typedef BOOL(WINAPI* _SetWindowCompositionAttribute)(
    HWND, WINDOWCOMPOSITIONATTRIBDATA*);

static _SetWindowCompositionAttribute g_set_window_composition_attribute = NULL;
static bool g_set_window_composition_attribute_initialized = false;

typedef LONG NTSTATUS, *PNTSTATUS;
#define STATUS_SUCCESS (0x00000000)

typedef NTSTATUS(WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);

static RTL_OSVERSIONINFOW GetWindowsVersion() {
  HMODULE hmodule = ::GetModuleHandleW(L"ntdll.dll");
  if (hmodule) {
    RtlGetVersionPtr rtl_get_version_ptr =
        (RtlGetVersionPtr)::GetProcAddress(hmodule, "RtlGetVersion");
    if (rtl_get_version_ptr != nullptr) {
      RTL_OSVERSIONINFOW rovi = {0};
      rovi.dwOSVersionInfoSize = sizeof(rovi);
      if (STATUS_SUCCESS == rtl_get_version_ptr(&rovi)) {
        return rovi;
      }
    }
  }
  RTL_OSVERSIONINFOW rovi = {0};
  return rovi;
}

void SetWindowComposition(HWND window, int32_t accent_state,
                          int32_t gradient_color) {
  if (GetWindowsVersion().dwBuildNumber >= 18362) {
    if (!g_set_window_composition_attribute_initialized) {
      auto user32 = ::GetModuleHandleA("user32.dll");
      if (user32) {
        g_set_window_composition_attribute =
            reinterpret_cast<_SetWindowCompositionAttribute>(
                ::GetProcAddress(user32, "SetWindowCompositionAttribute"));
        if (g_set_window_composition_attribute) {
          g_set_window_composition_attribute_initialized = true;
        }
      }
    }
    if (g_set_window_composition_attribute) {
      ACCENT_POLICY accent = {static_cast<ACCENT_STATE>(accent_state), 2,
                              static_cast<DWORD>(gradient_color), 0};
      WINDOWCOMPOSITIONATTRIBDATA data;
      data.Attrib = WCA_ACCENT_POLICY;
      data.pvData = &accent;
      data.cbData = sizeof(accent);
      g_set_window_composition_attribute(window, &data);
    }
  }
}

}  // namespace mpv
