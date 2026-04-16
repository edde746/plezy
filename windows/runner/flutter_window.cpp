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
// When true, WM_WINDOWPOSCHANGED should not persist placement. Used while a
// native fullscreen toggle is in flux so we don't record the fullscreen rect
// as the user's last "normal" placement.
static bool g_suppressPlacementSave = false;

// Forward declaration
static void SaveWindowPlacement(HWND hwnd);

// Timer callback for debounced save
static void CALLBACK SaveTimerProc(HWND, UINT, UINT_PTR, DWORD) {
  if (g_mainHwnd) SaveWindowPlacement(g_mainHwnd);
  KillTimer(nullptr, g_saveTimerId);
  g_saveTimerId = 0;
}

// Write a WINDOWPLACEMENT struct directly to the registry.
static void WriteWindowPlacement(const WINDOWPLACEMENT& wp) {
  HKEY hKey;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kWindowPlacementKey, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey,
                      nullptr) == ERROR_SUCCESS) {
    RegSetValueExW(hKey, kWindowPlacementValue, 0, REG_BINARY,
                   reinterpret_cast<const BYTE*>(&wp), sizeof(wp));
    RegCloseKey(hKey);
  }
}

// Save the window's current WINDOWPLACEMENT to registry.
static void SaveWindowPlacement(HWND hwnd) {
  WINDOWPLACEMENT wp{};
  wp.length = sizeof(wp);
  if (!GetWindowPlacement(hwnd, &wp)) return;
  WriteWindowPlacement(wp);
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

  RegisterWindowChannel();

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
  // If still fullscreen at shutdown, persist the pre-fullscreen placement
  // rather than the fullscreen rect so the next launch restores correctly.
  if (is_fullscreen_ && placement_before_fullscreen_.length != 0) {
    WriteWindowPlacement(placement_before_fullscreen_);
  } else {
    SaveWindowPlacement(GetHandle());
  }

  window_channel_ = nullptr;

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
      // Don't persist placement while in fullscreen or mid-toggle — the rect
      // would overwrite the user's real window position.
      if (!is_fullscreen_ && !g_suppressPlacementSave) {
        DebounceSaveWindowPlacement(hwnd);
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

// ---------------------------------------------------------------------------
// Native fullscreen (plezy/window method channel)
//
// Works around window_manager 0.5.1's multi-monitor fullscreen bug where the
// window ends up on the wrong monitor and renders only a fragment of the
// Flutter surface. We:
//   1) Resolve the target monitor by the current window's center point
//      (robust across DPI and restore transitions).
//   2) Save WINDOWPLACEMENT + styles once.
//   3) Strip WS_OVERLAPPEDWINDOW and move+size in a single SetWindowPos so
//      Flutter only relayouts once, at the final DPI/size.
//   4) On exit, restore styles and WINDOWPLACEMENT, re-maximizing if needed.
// ---------------------------------------------------------------------------
void FlutterWindow::RegisterWindowChannel() {
  auto messenger = flutter_controller_->engine()->messenger();
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "plezy/window",
          &flutter::StandardMethodCodec::GetInstance());

  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const std::string& name = call.method_name();
        if (name == "setFullScreen") {
          bool value = false;
          if (const auto* args =
                  std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto it = args->find(flutter::EncodableValue("isFullScreen"));
            if (it != args->end()) {
              if (const bool* b = std::get_if<bool>(&it->second)) value = *b;
            }
          }
          SetNativeFullScreen(value);
          result->Success();
        } else if (name == "isFullScreen") {
          result->Success(flutter::EncodableValue(is_fullscreen_));
        } else {
          result->NotImplemented();
        }
      });
}

void FlutterWindow::NotifyFullScreenChanged() {
  if (!window_channel_) return;
  window_channel_->InvokeMethod(
      "onFullScreenChanged",
      std::make_unique<flutter::EncodableValue>(is_fullscreen_));
}

void FlutterWindow::SetNativeFullScreen(bool fullscreen) {
  HWND hwnd = GetHandle();
  if (!hwnd) return;
  if (fullscreen == is_fullscreen_) return;

  g_suppressPlacementSave = true;
  // Also cancel any pending save so a WM_WINDOWPOSCHANGED just before the
  // toggle doesn't fire SaveTimerProc mid-transition.
  if (g_saveTimerId) {
    KillTimer(nullptr, g_saveTimerId);
    g_saveTimerId = 0;
  }

  if (fullscreen) {
    // Resolve target monitor first — if this fails we bail before mutating
    // any saved state, so a subsequent exit call has nothing stale to act on.
    RECT wr{};
    ::GetWindowRect(hwnd, &wr);
    // Center point is stable across maximize/straddle cases where
    // MonitorFromWindow would resolve to the neighbor monitor.
    POINT center{(wr.left + wr.right) / 2, (wr.top + wr.bottom) / 2};
    MONITORINFO mi{};
    mi.cbSize = sizeof(mi);
    if (!::GetMonitorInfoW(::MonitorFromPoint(center, MONITOR_DEFAULTTONEAREST),
                           &mi)) {
      g_suppressPlacementSave = false;
      return;
    }

    // Save pre-fullscreen state (showCmd inside the placement carries the
    // maximize bit, so no separate flag is needed).
    placement_before_fullscreen_.length = sizeof(WINDOWPLACEMENT);
    ::GetWindowPlacement(hwnd, &placement_before_fullscreen_);
    style_before_fullscreen_ = ::GetWindowLongPtr(hwnd, GWL_STYLE);
    ex_style_before_fullscreen_ = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    // Strip frame/caption. Stripping WS_OVERLAPPEDWINDOW alone is enough to
    // make the following SetWindowPos use the given rect exactly — no need
    // to ShowWindow(SW_SHOWNORMAL) first (would cause a second relayout).
    ::SetWindowLongPtr(
        hwnd, GWL_STYLE, style_before_fullscreen_ & ~WS_OVERLAPPEDWINDOW);
    ::SetWindowLongPtr(
        hwnd, GWL_EXSTYLE,
        ex_style_before_fullscreen_ &
            ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE |
              WS_EX_STATICEDGE));

    const RECT& r = mi.rcMonitor;
    ::SetWindowPos(hwnd, HWND_TOP, r.left, r.top, r.right - r.left,
                   r.bottom - r.top,
                   SWP_FRAMECHANGED | SWP_NOZORDER | SWP_NOACTIVATE);

    is_fullscreen_ = true;
  } else {
    if (style_before_fullscreen_ != 0) {
      ::SetWindowLongPtr(hwnd, GWL_STYLE, style_before_fullscreen_);
      ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, ex_style_before_fullscreen_);
    }

    if (placement_before_fullscreen_.length == sizeof(WINDOWPLACEMENT)) {
      WINDOWPLACEMENT wp = placement_before_fullscreen_;
      if (wp.showCmd == SW_SHOWMINIMIZED) wp.showCmd = SW_SHOWNORMAL;
      ::SetWindowPlacement(hwnd, &wp);
    }

    // Force a frame refresh so restored chrome paints.
    ::SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                       SWP_FRAMECHANGED);

    is_fullscreen_ = false;
    placement_before_fullscreen_ = {};
    style_before_fullscreen_ = 0;
    ex_style_before_fullscreen_ = 0;
  }

  g_suppressPlacementSave = false;
  NotifyFullScreenChanged();
}
