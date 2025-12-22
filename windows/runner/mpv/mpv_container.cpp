#include "mpv_container.h"

#include <dwmapi.h>

#include "mpv_core.h"
#include "utils.h"

namespace mpv {

MpvContainer* MpvContainer::GetInstance() { return instance_.get(); }

MpvContainer::~MpvContainer() {
  if (taskbar_) {
    taskbar_->Release();
    taskbar_ = nullptr;
  }
}

HWND MpvContainer::Create() {
  auto window_class = WNDCLASSEX{};
  ::SecureZeroMemory(&window_class, sizeof(window_class));
  window_class.cbSize = sizeof(window_class);
  window_class.style = 0;
  window_class.lpfnWndProc = WindowProc;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.lpszClassName = kClassName;
  window_class.hCursor = ::LoadCursorW(nullptr, IDC_ARROW);
  window_class.hbrBackground = ::CreateSolidBrush(RGB(0, 0, 0));

  ::RegisterClassExW(&window_class);

  // Use WS_POPUP for a borderless window without title bar.
  // Use WS_EX_TOOLWINDOW | WS_EX_NOREDIRECTIONBITMAP to prevent shadow and DWM effects.
  handle_ = ::CreateWindowExW(
      WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_NOREDIRECTIONBITMAP,
      kClassName, kWindowName, WS_POPUP,
      0, 0, 100, 100, nullptr, nullptr,
      GetModuleHandle(nullptr), nullptr);

  // Disable DWM animations on the container.
  auto disable_window_transitions = TRUE;
  DwmSetWindowAttribute(handle_, DWMWA_TRANSITIONS_FORCEDISABLED,
                        &disable_window_transitions,
                        sizeof(disable_window_transitions));

  return handle_;
}

HWND MpvContainer::Get(HWND flutter_window) {
  if (!handle_) {
    Create();
  }

  RECT window_rect;
  ::GetWindowRect(flutter_window, &window_rect);
  ::SetWindowPos(handle_, flutter_window, window_rect.left, window_rect.top,
                 window_rect.right - window_rect.left,
                 window_rect.bottom - window_rect.top, SWP_NOACTIVATE);
  ::SetWindowLongPtr(handle_, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(flutter_window));

  // Remove taskbar entry using cached ITaskbarList3.
  if (!taskbar_) {
    ::CoCreateInstance(CLSID_TaskbarList, 0, CLSCTX_INPROC_SERVER,
                       IID_PPV_ARGS(&taskbar_));
  }
  if (taskbar_) {
    taskbar_->DeleteTab(handle_);
  }

  ::ShowWindow(handle_, SW_SHOWNOACTIVATE);
  ::SetFocus(flutter_window);

  return handle_;
}

LRESULT CALLBACK MpvContainer::WindowProc(HWND const window,
                                          UINT const message,
                                          WPARAM const wparam,
                                          LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY: {
      ::PostQuitMessage(0);
      return 0;
    }
    case WM_MOUSEMOVE: {
      // Redirect focus to Flutter window.
      auto* core = MpvCore::GetInstance();
      if (core) {
        core->SetHitTestBehavior(0);
      }
      auto user_data = ::GetWindowLongPtr(window, GWLP_USERDATA);
      if (user_data) {
        ::SetForegroundWindow(reinterpret_cast<HWND>(user_data));
      }
      break;
    }
    case WM_ERASEBKGND: {
      // Prevent erasing to avoid flicker.
      return 1;
    }
    case WM_SIZE:
    case WM_MOVE:
    case WM_MOVING:
    case WM_ACTIVATE:
    case WM_WINDOWPOSCHANGED: {
      auto* core = MpvCore::GetInstance();
      if (core) {
        core->SetHitTestBehavior(0);
      }
      auto user_data = ::GetWindowLongPtr(window, GWLP_USERDATA);
      if (user_data) {
        ::SetForegroundWindow(reinterpret_cast<HWND>(user_data));
      }
      break;
    }
    default:
      break;
  }
  return ::DefWindowProc(window, message, wparam, lparam);
}

std::unique_ptr<MpvContainer> MpvContainer::instance_ =
    std::make_unique<MpvContainer>();

}  // namespace mpv
