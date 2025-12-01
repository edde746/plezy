#include "mpv_core.h"

#include <fstream>

#include "mpv_container.h"
#include "utils.h"

static void LogToFile(const char* message) {
  std::ofstream log("C:\\Users\\admin\\mpv_debug.log", std::ios::app);
  if (log.is_open()) {
    log << message << std::endl;
    log.close();
  }
  OutputDebugStringA(message);
  OutputDebugStringA("\n");
}

namespace mpv {

MpvCore* MpvCore::GetInstance() { return instance_.get(); }

void MpvCore::SetInstance(std::unique_ptr<MpvCore> instance) {
  instance_ = std::move(instance);
}

std::optional<int32_t> MpvCore::GetProcId() { return proc_id_; }

void MpvCore::SetProcId(std::optional<int32_t> proc_id) { proc_id_ = proc_id; }

MpvCore::MpvCore(HWND flutter_window, HWND flutter_child_window)
    : flutter_window_(flutter_window),
      flutter_child_window_(flutter_child_window) {}

MpvCore::~MpvCore() {
  // Close all mpv views.
  for (const auto& [mpv_view, rect] : mpv_views_) {
    ::SendMessage(mpv_view, WM_CLOSE, 0, 0);
  }
  mpv_views_.clear();
}

void MpvCore::EnsureInitialized() {
  LogToFile("MpvCore::EnsureInitialized called");
  char msg[256];
  snprintf(msg, sizeof(msg), "MpvCore::EnsureInitialized - flutter_window_: %p", flutter_window_);
  LogToFile(msg);

  // Enable per-pixel transparency on Flutter window.
  LogToFile("MpvCore::EnsureInitialized - calling SetWindowComposition");
  SetWindowComposition(flutter_window_, 6, 0);

  LogToFile("MpvCore::EnsureInitialized - getting container");
  container_ = MpvContainer::GetInstance()->Get(flutter_window_);

  snprintf(msg, sizeof(msg), "MpvCore::EnsureInitialized - container: %p", container_);
  LogToFile(msg);
}

void MpvCore::CreateMpvView(HWND mpv_hwnd, RECT rect,
                            double device_pixel_ratio) {
  ::SetParent(mpv_hwnd, container_);
  ::ShowWindow(mpv_hwnd, SW_SHOW);

  // Remove window decorations.
  auto style = ::GetWindowLongPtr(mpv_hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX |
             WS_EX_APPWINDOW);
  ::SetWindowLongPtr(mpv_hwnd, GWL_STYLE, style);

  device_pixel_ratio_ = device_pixel_ratio;
  mpv_views_[mpv_hwnd] = rect;

  // Position the mpv view behind the Flutter window.
  auto global_rect =
      GetGlobalRect(rect.left, rect.top, rect.right, rect.bottom);
  ::SetWindowPos(mpv_hwnd, flutter_window_, global_rect.left, global_rect.top,
                 global_rect.right - global_rect.left,
                 global_rect.bottom - global_rect.top, SWP_NOACTIVATE);
}

void MpvCore::ResizeMpvView(HWND mpv_hwnd, RECT rect) {
  mpv_views_[mpv_hwnd] = rect;
  auto global_rect =
      GetGlobalRect(rect.left, rect.top, rect.right, rect.bottom);
  // Use MoveWindow to trigger redraw.
  ::MoveWindow(mpv_hwnd, global_rect.left, global_rect.top,
               global_rect.right - global_rect.left,
               global_rect.bottom - global_rect.top, TRUE);
}

void MpvCore::DisposeMpvView(HWND mpv_hwnd) {
  ::SendMessage(mpv_hwnd, WM_CLOSE, 0, 0);
  mpv_views_.erase(mpv_hwnd);
}

void MpvCore::SetHitTestBehavior(int32_t hittest_behavior) {
  LONG ex_style = ::GetWindowLong(flutter_window_, GWL_EXSTYLE);
  if (hittest_behavior) {
    ex_style |= (WS_EX_TRANSPARENT | WS_EX_LAYERED);
  } else {
    ex_style &= ~(WS_EX_TRANSPARENT | WS_EX_LAYERED);
  }
  ::SetWindowLong(flutter_window_, GWL_EXSTYLE, ex_style);
}

void MpvCore::SetVisible(bool visible) {
  char msg[256];
  snprintf(msg, sizeof(msg), "MpvCore::SetVisible - visible: %d, container_: %p", visible, container_);
  LogToFile(msg);

  visible_ = visible;
  if (container_) {
    if (visible) {
      SetWindowComposition(flutter_window_, 6, 0);
      ::ShowWindow(container_, SW_SHOWNOACTIVATE);
      LogToFile("MpvCore::SetVisible - showed container, set composition to 6");
    } else {
      SetWindowComposition(flutter_window_, 0, 0);
      ::ShowWindow(container_, SW_HIDE);
      LogToFile("MpvCore::SetVisible - hid container, set composition to 0");
    }
  }
}

std::optional<HRESULT> MpvCore::WindowProc(HWND hwnd, UINT message,
                                           WPARAM wparam, LPARAM lparam) {
  switch (message) {
    case WM_ACTIVATE: {
      RECT window_rect;
      ::GetWindowRect(flutter_window_, &window_rect);
      // Position container behind Flutter window.
      ::SetWindowPos(container_, flutter_window_, window_rect.left,
                     window_rect.top, window_rect.right - window_rect.left,
                     window_rect.bottom - window_rect.top, SWP_NOACTIVATE);
      break;
    }
    case WM_SIZE: {
      char msg[256];
      snprintf(msg, sizeof(msg), "WM_SIZE - wparam: %llu, last: %llu, visible_: %d, was_hidden: %d",
               (unsigned long long)wparam, (unsigned long long)last_wm_size_wparam_,
               visible_, was_window_hidden_due_to_minimize_);
      LogToFile(msg);

      // Handle Windows's minimize & maximize animations properly.
      // During these transitions, we hide the container and make Flutter opaque,
      // then restore after the animation completes.
      if (wparam != SIZE_RESTORED || last_wm_size_wparam_ == SIZE_MINIMIZED ||
          last_wm_size_wparam_ == SIZE_MAXIMIZED ||
          was_window_hidden_due_to_minimize_) {
        was_window_hidden_due_to_minimize_ = false;
        SetWindowComposition(flutter_window_, 0, 0);
        ::ShowWindow(container_, SW_HIDE);
        LogToFile("WM_SIZE - hiding container, starting delay thread");
        last_thread_time_ =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch())
                .count();
        std::thread(
            [this](uint64_t time) {
              std::this_thread::sleep_for(
                  std::chrono::milliseconds(kPositionAndShowDelay));

              // Check if this thread is still the latest (another WM_SIZE may have come in)
              if (time != last_thread_time_) {
                LogToFile("WM_SIZE thread - superseded by newer thread, skipping");
                return;
              }

              char msg2[256];
              snprintf(msg2, sizeof(msg2), "WM_SIZE thread - after delay, visible_: %d",
                       visible_);
              LogToFile(msg2);

              // Update container position to match current Flutter window bounds
              RECT window_rect;
              ::GetWindowRect(flutter_window_, &window_rect);
              snprintf(msg2, sizeof(msg2), "WM_SIZE thread - flutter rect: %ld,%ld,%ld,%ld",
                       window_rect.left, window_rect.top, window_rect.right, window_rect.bottom);
              LogToFile(msg2);

              ::SetWindowPos(container_, flutter_window_, window_rect.left,
                             window_rect.top, window_rect.right - window_rect.left,
                             window_rect.bottom - window_rect.top, SWP_NOACTIVATE);
              LogToFile("WM_SIZE thread - updated container position");

              // Always restore transparency if video is visible
              if (visible_) {
                SetWindowComposition(flutter_window_, 6, 0);
                LogToFile("WM_SIZE thread - restored composition to 6");
                ::ShowWindow(container_, SW_SHOWNOACTIVATE);
                LogToFile("WM_SIZE thread - showed container");
              }
            },
            last_thread_time_)
            .detach();
      }
      last_wm_size_wparam_ = wparam;
      break;
    }
    case WM_MOVE:
    case WM_MOVING:
    case WM_WINDOWPOSCHANGED: {
      RECT window_rect;
      ::GetWindowRect(flutter_window_, &window_rect);
      if (window_rect.right - window_rect.left > 0 &&
          window_rect.bottom - window_rect.top > 0) {
        ::SetWindowPos(container_, flutter_window_, window_rect.left,
                       window_rect.top, window_rect.right - window_rect.left,
                       window_rect.bottom - window_rect.top, SWP_NOACTIVATE);
        // Window is minimized (negative coordinates).
        if (window_rect.left < 0 && window_rect.top < 0 &&
            window_rect.right < 0 && window_rect.bottom < 0) {
          SetWindowComposition(flutter_window_, 0, 0);
          ::ShowWindow(container_, SW_HIDE);
          was_window_hidden_due_to_minimize_ = true;
        }
      }
      break;
    }
    case WM_CLOSE: {
      ::SendMessage(container_, WM_CLOSE, 0, 0);
      for (const auto& [mpv_view, rect] : mpv_views_) {
        ::SendMessage(mpv_view, WM_CLOSE, 0, 0);
      }
      mpv_views_.clear();
      break;
    }
    default:
      break;
  }
  return std::nullopt;
}

void MpvCore::RedrawMpvViews() {
  ::RedrawWindow(container_, 0, 0, RDW_INVALIDATE | RDW_ALLCHILDREN);
}

RECT MpvCore::GetGlobalRect(int32_t left, int32_t top, int32_t right,
                            int32_t bottom) {
  // Expand client area to prevent transparent gaps.
  left -= static_cast<int32_t>(ceil(device_pixel_ratio_));
  top -= static_cast<int32_t>(ceil(device_pixel_ratio_));
  right += static_cast<int32_t>(ceil(device_pixel_ratio_));
  bottom += static_cast<int32_t>(ceil(device_pixel_ratio_));

  RECT window_rect;
  ::GetClientRect(flutter_window_, &window_rect);
  RECT rect;
  rect.left = window_rect.left + left;
  rect.top = window_rect.top + top;
  rect.right = window_rect.left + right;
  rect.bottom = window_rect.top + bottom;
  return rect;
}

std::unique_ptr<MpvCore> MpvCore::instance_ = nullptr;
std::optional<int32_t> MpvCore::proc_id_ = std::nullopt;

}  // namespace mpv
