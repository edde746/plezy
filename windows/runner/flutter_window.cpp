#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "mpv/mpv_plugin.h"

// Registry key for window placement persistence
static constexpr wchar_t kWindowPlacementKey[] = L"Software\\Plezy";
static constexpr wchar_t kWindowPlacementValue[] = L"WindowPlacement";

// Debounce timer for saving window placement
static UINT_PTR g_saveTimerId = 0;
static HWND g_mainHwnd = nullptr;

// Forward declaration
static void SaveWindowPlacement(HWND hwnd);

// Timer callback for debounced save
static void CALLBACK SaveTimerProc(HWND, UINT, UINT_PTR, DWORD) {
  if (g_mainHwnd) SaveWindowPlacement(g_mainHwnd);
  KillTimer(nullptr, g_saveTimerId);
  g_saveTimerId = 0;
}

// Save WINDOWPLACEMENT to registry
static void SaveWindowPlacement(HWND hwnd) {
  WINDOWPLACEMENT wp{};
  wp.length = sizeof(wp);
  if (!GetWindowPlacement(hwnd, &wp)) return;

  HKEY hKey;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kWindowPlacementKey, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey,
                      nullptr) == ERROR_SUCCESS) {
    RegSetValueExW(hKey, kWindowPlacementValue, 0, REG_BINARY,
                   reinterpret_cast<const BYTE*>(&wp), sizeof(wp));
    RegCloseKey(hKey);
  }
}

// Load and apply WINDOWPLACEMENT from registry
// Returns whether the window should be maximized
static bool LoadWindowPlacement(HWND hwnd) {
  HKEY hKey;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kWindowPlacementKey, 0, KEY_READ,
                    &hKey) != ERROR_SUCCESS)
    return false;

  WINDOWPLACEMENT wp{};
  wp.length = sizeof(wp);
  DWORD size = sizeof(wp);
  bool wasMaximized = false;

  if (RegQueryValueExW(hKey, kWindowPlacementValue, nullptr, nullptr,
                       reinterpret_cast<BYTE*>(&wp), &size) == ERROR_SUCCESS &&
      size == sizeof(wp)) {
    // Prevent restoring as minimized
    if (wp.showCmd == SW_SHOWMINIMIZED) wp.showCmd = SW_SHOWNORMAL;
    SetWindowPlacement(hwnd, &wp);
    wasMaximized = (wp.showCmd == SW_SHOWMAXIMIZED);
  }

  RegCloseKey(hKey);
  return wasMaximized;
}

// Debounce save to avoid excessive registry writes during resize/move
static void DebounceSaveWindowPlacement(HWND hwnd) {
  g_mainHwnd = hwnd;
  if (g_saveTimerId) KillTimer(nullptr, g_saveTimerId);
  g_saveTimerId = SetTimer(nullptr, 0, 500, SaveTimerProc);  // 500ms debounce
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Register mpv player plugin.
  OutputDebugStringA("FlutterWindow: About to register MpvPlayerPlugin\n");
  MpvPlayerPluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("MpvPlayerPlugin"));
  OutputDebugStringA("FlutterWindow: MpvPlayerPlugin registered\n");

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Load saved window placement before showing
  HWND hwnd = GetHandle();
  bool maximized = LoadWindowPlacement(hwnd);

  flutter_controller_->engine()->SetNextFrameCallback([this, maximized]() {
    ::ShowWindow(this->GetHandle(), maximized ? SW_SHOWMAXIMIZED : SW_SHOWNORMAL);
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  // Cancel any pending save timer and save immediately
  if (g_saveTimerId) {
    KillTimer(nullptr, g_saveTimerId);
    g_saveTimerId = 0;
  }
  SaveWindowPlacement(GetHandle());

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_WINDOWPOSCHANGED:
      DebounceSaveWindowPlacement(hwnd);
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
