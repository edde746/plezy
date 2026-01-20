#ifndef MPV_PLAYER_H_
#define MPV_PLAYER_H_

#include <Windows.h>
#include <mpv/client.h>

#include <atomic>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <flutter/encodable_value.h>

namespace mpv {

// Wrapper for libmpv that handles initialization, commands, properties,
// and event dispatching.
class MpvPlayer {
 public:
  using EventCallback =
      std::function<void(const flutter::EncodableMap&)>;

  MpvPlayer();
  ~MpvPlayer();

  // Initializes mpv and creates the video window.
  bool Initialize(HWND container, HWND flutter_window);

  // Disposes mpv and the video window.
  void Dispose();

  // Returns true if mpv is initialized.
  bool IsInitialized() const { return mpv_ != nullptr; }

  // Executes an mpv command.
  void Command(const std::vector<std::string>& args);

  // Callback type for async command completion.
  using CommandCallback = std::function<void(int error)>;

  // Executes an mpv command asynchronously to prevent UI blocking.
  // The callback is called on the main thread when the command completes.
  void CommandAsync(const std::vector<std::string>& args, CommandCallback callback);

  // Sets an mpv property.
  void SetProperty(const std::string& name, const std::string& value);

  // Gets an mpv property.
  std::string GetProperty(const std::string& name);

  // Observes an mpv property for changes.
  void ObserveProperty(const std::string& name, const std::string& format);

  // Returns the mpv video window handle.
  HWND GetHwnd() const { return hwnd_; }

  // Updates the video window position.
  void SetRect(RECT rect, double device_pixel_ratio);

  // Shows or hides the video window.
  void SetVisible(bool visible);

  // Sets the event callback for property changes and events.
  void SetEventCallback(EventCallback callback);

 private:
  void StartEventLoop();
  void StopEventLoop();
  void EventLoop();
  void HandleMpvEvent(mpv_event* event);
  void SendPropertyChange(const char* name, mpv_node* data);
  void SendEvent(const std::string& name,
                 const flutter::EncodableMap& data = {});

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

  // Pending async commands: request_id -> callback
  std::map<uint64_t, CommandCallback> pending_commands_;
  std::mutex pending_commands_mutex_;

  // HDR state
  bool hdr_enabled_ = true;      // User preference
  double last_sig_peak_ = 0.0;   // Last known sig-peak for HDR content detection

  // HDR methods
  void SetHDREnabled(bool enabled);
  void UpdateHDRMode(double sigPeak);
};

}  // namespace mpv

#endif  // MPV_PLAYER_H_
