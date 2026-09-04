#ifndef MPV_PLAYER_H_
#define MPV_PLAYER_H_

#include <Windows.h>
#include <flutter/encodable_value.h>
#include <mpv/client.h>

#include <atomic>
#include <chrono>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "../../../shared/mpv/mpv_player_common.h"
#include "hdr_probe.h"

namespace mpv {
struct InnerWindowSubclassState;

// Style of the window mpv renders into. WS_DISABLED takes the host, and every
// window mpv creates inside it, out of input targeting so mouse, touch, and pen
// over the video reach the parent Flutter view instead of mpv's thread.
inline constexpr DWORD kVideoHostWindowStyle = WS_CHILD | WS_CLIPSIBLINGS | WS_DISABLED;

// Wrapper for libmpv that handles initialization, commands, properties,
// and event dispatching.
class MpvPlayer {
 public:
  using EventCallback = std::function<void(const flutter::EncodableValue&)>;

  // |audio_only| runs mpv as a windowless music core: no child HWND, no VO,
  // video decode disabled entirely (vid=no).
  explicit MpvPlayer(bool audio_only = false);
  ~MpvPlayer();

  // Initializes mpv and creates the video window as a child of the Flutter
  // |view| window. The flutter-plezy engine presents the UI on a topmost
  // DirectComposition visual, so the video child composites beneath it in the
  // same HWND. In audio-only mode |view| is ignored (pass nullptr) and no
  // window is created.
  bool Initialize(HWND view);

  // Disposes mpv and the video window.
  void Dispose();

  // Returns true if mpv is initialized.
  bool IsInitialized() const { return mpv_ != nullptr; }

  // Queues an mpv command without waiting for completion.
  void Command(const std::vector<std::string>& args);

  // Callback types for async mpv requests.
  using StatusCallback = plezy::mpv_common::StatusCallback;
  using CommandCallback = StatusCallback;
  using GetPropertyCallback = plezy::mpv_common::GetPropertyCallback;

  // Executes an mpv command asynchronously to prevent UI blocking.
  void CommandAsync(const std::vector<std::string>& args, CommandCallback callback);

  // Queues an mpv property update without waiting for completion.
  void SetProperty(const std::string& name, const std::string& value);

  // Sets an mpv property asynchronously.
  void SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback);

  // Gets an mpv property asynchronously.
  void GetPropertyAsync(const std::string& name, GetPropertyCallback callback);

  // Observes an mpv property for changes.
  void ObserveProperty(const std::string& name, const std::string& format, int id);

  // Returns the mpv video window handle.
  HWND GetHwnd() const { return hwnd_; }

  // Updates the video window position.
  void SetRect(RECT rect, double device_pixel_ratio);

  // Shows or hides the video window.
  void SetVisible(bool visible);

  // Sets the MPV log message level (e.g., "warn", "v", "debug").
  void SetLogLevel(const std::string& level);

  // Sets the event callback for property changes and events.
  void SetEventCallback(EventCallback callback);

  // Power notifications, called from the platform thread (window proc).
  // NotifyPowerResume only sets an atomic flag consumed by the event thread —
  // no mpv calls, no timers — so it cannot race Dispose and needs no cleanup.
  void NotifyPowerSuspend();
  void NotifyPowerResume();

 private:
  friend class MpvPlayerPropertyContractTestPeer;

  void StartEventLoop();
  void StopEventLoop();
  void EventLoop();
  void HandleMpvEvent(mpv_event* event);
  void SendPropertyChange(const char* name, mpv_node* data);
  void SendEvent(const std::string& name, const flutter::EncodableMap& data = {});
  void MaybeRunAudioRecovery();
  void TryAudioReload(const char* reason, int attempt, uint64_t request_generation);
  void LogRecovery(const std::string& text);
  // Reports the applied HDR pipeline options once per player, as a synthetic
  // log-message on the first file load (when the Dart callback is wired).
  void LogHdrPipelineOnce();
  void EnsureMpvInnerSubclassed();
  void DetachMpvInnerSubclass();

  const bool audio_only_;
  mpv_handle* mpv_ = nullptr;
  HWND hwnd_ = nullptr;
  HWND forward_target_view_ = nullptr;
  std::mutex inner_subclass_mutex_;
  std::shared_ptr<InnerWindowSubclassState> inner_subclass_;

  std::thread event_thread_;
  std::atomic<bool> running_{false};
  EventCallback event_callback_;
  std::mutex callback_mutex_;
  plezy::mpv_common::AudioRecoveryState audio_recovery_;

  plezy::mpv_common::AsyncRequestRegistry pending_requests_;
  plezy::mpv_common::PropertyObservationRegistry observed_properties_;

  // HDR state
  bool hdr_enabled_ = true;
  // Set during Initialize when a Qualcomm Adreno GPU is present; names the
  // tone-map LUT workaround so the first file load can log it.
  bool adreno_tone_map_workaround_ = false;
  bool hdr_config_logged_ = false;
  // #2191 diagnostics: reports tone-map input churn (see hdr_probe.h). Owned
  // by the player; ticked from the event thread, torn down before mpv.
  std::unique_ptr<HdrProbe> hdr_probe_;
  void LogHdrProbe(const std::string& text);

  void SetHDREnabled(bool enabled, StatusCallback callback = nullptr);
};

}  // namespace mpv

#endif  // MPV_PLAYER_H_
