#include "mpv_core.h"

#include <dwmapi.h>

#include "mpv_container.h"
#include "utils.h"

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
  // Get container - composition will be enabled in SetVisible() to batch DwmFlush calls
  container_ = MpvContainer::GetInstance()->Get(flutter_window_);
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

  // Force Windows to recalculate window frame after extended style changes.
  // This ensures the render surface dimensions match the new window state.
  ::SetWindowPos(flutter_window_, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);

  // Sync with DWM to ensure render target is updated
  ::DwmFlush();
}

void MpvCore::SetVisible(bool visible) {
  visible_ = visible;
  if (container_) {
    if (visible) {
      // Batch all window operations, single DwmFlush at end
      ::SetWindowPos(flutter_window_, nullptr, 0, 0, 0, 0,
                     SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
      if (!composition_enabled_) {
        SetWindowComposition(flutter_window_, 2, 0);
        composition_enabled_ = true;
      }
      ::ShowWindow(container_, SW_SHOWNOACTIVATE);
      ::DwmFlush();  // Single sync with DWM after all operations
    } else {
      SetWindowComposition(flutter_window_, 0, 0);
      composition_enabled_ = false;
      ::ShowWindow(container_, SW_HIDE);
      ::DwmFlush();  // Sync with DWM after hiding
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
      // Handle Windows's minimize & maximize animations properly.
      // During these transitions, we hide the container and make Flutter opaque,
      // then restore after the animation completes using a Windows timer.
      if (wparam != SIZE_RESTORED || last_wm_size_wparam_ == SIZE_MINIMIZED ||
          last_wm_size_wparam_ == SIZE_MAXIMIZED ||
          was_window_hidden_due_to_minimize_) {
        was_window_hidden_due_to_minimize_ = false;
        SetWindowComposition(flutter_window_, 0, 0);
        composition_enabled_ = false;
        ::ShowWindow(container_, SW_HIDE);
        ::DwmFlush();  // Single sync after hiding

        // Cancel any pending timer and set a new one.
        ::KillTimer(flutter_window_, kCompositionRestoreTimerId);
        ::SetTimer(flutter_window_, kCompositionRestoreTimerId, kPositionAndShowDelay, nullptr);
      }
      last_wm_size_wparam_ = wparam;
      break;
    }
    case WM_TIMER: {
      if (wparam == kCompositionRestoreTimerId) {
        ::KillTimer(flutter_window_, kCompositionRestoreTimerId);

        // Update container position to match current Flutter window bounds
        RECT window_rect;
        ::GetWindowRect(flutter_window_, &window_rect);
        ::SetWindowPos(container_, flutter_window_, window_rect.left,
                       window_rect.top, window_rect.right - window_rect.left,
                       window_rect.bottom - window_rect.top, SWP_NOACTIVATE);

        // Restore transparency if video is visible
        if (visible_) {
          // Batch all operations, single DwmFlush at end
          ::SetWindowPos(flutter_window_, nullptr, 0, 0, 0, 0,
                         SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
          if (!composition_enabled_) {
            SetWindowComposition(flutter_window_, 2, 0);
            composition_enabled_ = true;
          }
          ::ShowWindow(container_, SW_SHOWNOACTIVATE);
          ::DwmFlush();  // Single sync after all operations

          // Force a redraw to ensure Flutter's render surface is correctly sized
          ::RedrawWindow(flutter_window_, nullptr, nullptr,
                         RDW_INVALIDATE | RDW_UPDATENOW | RDW_ALLCHILDREN);
        }
      }
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
          composition_enabled_ = false;
          ::ShowWindow(container_, SW_HIDE);
          ::DwmFlush();  // Single sync after hiding
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
