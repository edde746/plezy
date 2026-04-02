#ifndef MPV_CORE_H_
#define MPV_CORE_H_

#include <Windows.h>

#include <cmath>
#include <functional>
#include <map>
#include <memory>
#include <optional>

namespace mpv {

// Core class for managing z-order and window positioning for mpv video window.
// Handles transparency, minimize/maximize animations, and position syncing.
class MpvCore {
 public:
  static constexpr auto kPositionAndShowDelay = 300;
  static constexpr auto kPowerResumeAudioDelay = 500;
  static constexpr UINT_PTR kCompositionRestoreTimerId = 1001;
  static constexpr UINT_PTR kPowerResumeTimerId = 1002;

  static MpvCore* GetInstance();
  static void SetInstance(std::unique_ptr<MpvCore> instance);

  explicit MpvCore(HWND flutter_window);
  ~MpvCore();

  // Initializes transparency on the Flutter window.
  void EnsureInitialized();

  // Creates and positions the mpv video view.
  void CreateMpvView(HWND mpv_hwnd, RECT rect, double device_pixel_ratio);

  // Updates the mpv view position.
  void ResizeMpvView(HWND mpv_hwnd, RECT rect);

  // Disposes the mpv view.
  void DisposeMpvView(HWND mpv_hwnd);

  // Shows or hides the mpv view.
  void SetVisible(bool visible);

  // Window procedure handler for Flutter window messages.
  std::optional<HRESULT> WindowProc(HWND hwnd, UINT message, WPARAM wparam,
                                    LPARAM lparam);

  // Callback invoked when Windows resumes from sleep/hibernate.
  using PowerResumeCallback = std::function<void()>;
  void SetPowerResumeCallback(PowerResumeCallback callback);

 private:
  RECT GetGlobalRect(int32_t left, int32_t top, int32_t right, int32_t bottom);
  void EnableComposition();
  void DisableComposition();

  HWND flutter_window_ = nullptr;
  HWND container_ = nullptr;
  double device_pixel_ratio_ = 1.0;
  std::map<HWND, RECT> mpv_views_;
  WPARAM last_wm_size_wparam_ = SIZE_RESTORED;
  bool was_window_hidden_due_to_minimize_ = false;
  bool visible_ = true;
  bool composition_enabled_ = false;
  PowerResumeCallback power_resume_cb_;

  static std::unique_ptr<MpvCore> instance_;
};

}  // namespace mpv

#endif  // MPV_CORE_H_
