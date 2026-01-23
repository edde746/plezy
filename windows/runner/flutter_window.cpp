#include "flutter_window.h"
#include "native_window_state_plugin.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "mpv/mpv_plugin.h"

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

  // Register our native window state plugin
  auto registrar_raw = flutter_controller_->engine()->GetRegistrarForPlugin("NativeWindowStatePlugin");
  NativeWindowStatePlugin::RegisterWithRegistrar(
      new flutter::PluginRegistrarWindows(registrar_raw));

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Load window state before showing the window
  HWND hwnd = this->GetHandle();
  bool should_start_maximized = false;
  
  if (hwnd) {
    NativeWindowStatePlugin::LoadWindowStateStatic(hwnd, &should_start_maximized);
  }

  flutter_controller_->engine()->SetNextFrameCallback([this, hwnd, should_start_maximized]() {
    // Show maximized or normal based on saved state
    if (should_start_maximized && hwnd) {
      ::ShowWindow(hwnd, SW_SHOWMAXIMIZED);
    } else {
      this->Show();
    }
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
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
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
