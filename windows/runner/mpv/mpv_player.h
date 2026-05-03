#ifndef MPV_PLAYER_H_
#define MPV_PLAYER_H_

#include <Windows.h>
#include <flutter/encodable_value.h>
#include <mpv/client.h>

#include <atomic>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace mpv {

// Wrapper for libmpv that handles initialization, commands, properties,
// and event dispatching.
class MpvPlayer {
 public:
  using EventCallback = std::function<void(const flutter::EncodableValue&)>;

  MpvPlayer();
  ~MpvPlayer();

  // Initializes mpv and creates the video window.
  bool Initialize(HWND container, HWND flutter_window);

  // Disposes mpv and the video window.
  void Dispose();

  // Returns true if mpv is initialized.
  bool IsInitialized() const { return mpv_ != nullptr; }

  // Queues an mpv command without waiting for completion.
  void Command(const std::vector<std::string>& args);

  // Callback types for async mpv requests.
  using StatusCallback = std::function<void(int error)>;
  using CommandCallback = StatusCallback;
  using GetPropertyCallback = std::function<void(int error, const std::string& value)>;

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

 private:
  void StartEventLoop();
  void StopEventLoop();
  void EventLoop();
  void HandleMpvEvent(mpv_event* event);
  void SendPropertyChange(const char* name, mpv_node* data);
  void SendEvent(const std::string& name, const flutter::EncodableMap& data = {});
  uint64_t RegisterStatusRequest(StatusCallback callback);
  StatusCallback TakeStatusRequest(uint64_t request_id);
  uint64_t RegisterGetPropertyRequest(GetPropertyCallback callback);
  GetPropertyCallback TakeGetPropertyRequest(uint64_t request_id);

  mpv_handle* mpv_ = nullptr;
  HWND hwnd_ = nullptr;
  HWND container_ = nullptr;
  HWND flutter_window_ = nullptr;
  double device_pixel_ratio_ = 1.0;
  RECT rect_ = {0, 0, 0, 0};

  std::thread event_thread_;
  std::atomic<bool> running_{false};
  EventCallback event_callback_;
  std::mutex callback_mutex_;

  uint64_t next_reply_userdata_ = 1;
  std::map<std::string, uint64_t> observed_properties_;
  std::map<std::string, int> name_to_id_;

  // Pending async requests: request_id -> callback
  std::map<uint64_t, StatusCallback> pending_status_requests_;
  std::map<uint64_t, GetPropertyCallback> pending_get_property_requests_;
  std::mutex pending_requests_mutex_;

  // HDR state
  bool hdr_enabled_ = true;     // User preference
  double last_sig_peak_ = 0.0;  // Last known sig-peak for HDR content detection

  // HDR methods
  void SetHDREnabled(bool enabled, StatusCallback callback = nullptr);
  void UpdateHDRMode(double sigPeak);
};

}  // namespace mpv

#endif  // MPV_PLAYER_H_
