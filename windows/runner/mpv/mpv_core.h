#ifndef MPV_CORE_H_
#define MPV_CORE_H_

#include <Windows.h>

#include <cmath>
#include <map>
#include <memory>
#include <optional>

namespace mpv {

// Core class for managing z-order and window positioning for mpv video window.
// Handles transparency, minimize/maximize animations, and position syncing.
class MpvCore {
 public:
  static constexpr auto kPositionAndShowDelay = 300;
  static constexpr UINT_PTR kCompositionRestoreTimerId = 1001;

  static MpvCore* GetInstance();
  static void SetInstance(std::unique_ptr<MpvCore> instance);
  static std::optional<int32_t> GetProcId();
  static void SetProcId(std::optional<int32_t> proc_id);

  MpvCore(HWND flutter_window, HWND flutter_child_window);
  ~MpvCore();

  // Initializes transparency on the Flutter window.
  void EnsureInitialized();

  // Creates and positions the mpv video view.
  void CreateMpvView(HWND mpv_hwnd, RECT rect, double device_pixel_ratio);

  // Updates the mpv view position.
  void ResizeMpvView(HWND mpv_hwnd, RECT rect);

  // Disposes the mpv view.
  void DisposeMpvView(HWND mpv_hwnd);

  // Sets hit test behavior for mouse passthrough.
  void SetHitTestBehavior(int32_t hittest_behavior);

  // Shows or hides the mpv view.
  void SetVisible(bool visible);

  // Window procedure handler for Flutter window messages.
  std::optional<HRESULT> WindowProc(HWND hwnd, UINT message, WPARAM wparam,
                                    LPARAM lparam);

 private:
  void RedrawMpvViews();
  RECT GetGlobalRect(int32_t left, int32_t top, int32_t right, int32_t bottom);

  HWND flutter_window_ = nullptr;
  HWND flutter_child_window_ = nullptr;
  HWND container_ = nullptr;
  double device_pixel_ratio_ = 1.0;
  std::map<HWND, RECT> mpv_views_;
  WPARAM last_wm_size_wparam_ = SIZE_RESTORED;
  bool was_window_hidden_due_to_minimize_ = false;
  bool visible_ = true;
  bool composition_enabled_ = false;

  static std::unique_ptr<MpvCore> instance_;
  static std::optional<int32_t> proc_id_;
};

}  // namespace mpv

#endif  // MPV_CORE_H_
