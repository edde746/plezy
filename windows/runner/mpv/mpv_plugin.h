#ifndef MPV_PLUGIN_H_
#define MPV_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <queue>
#include <string>

#include "display_mode_manager.h"
#include "mpv_player.h"

// C-style registration functions for the video and audio-only plugin
// instances.
void MpvPlayerPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);
void MpvAudioPlayerPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

namespace mpv {

class MpvPlayerPlugin : public flutter::Plugin {
 public:
  // |channel_name| is the method channel name; the event channel is
  // |channel_name| + "/events". |audio_only| runs a windowless music core:
  // no child HWND, no display-mode handling (see MpvPlayer).
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar, const std::string& channel_name = "com.plezy/mpv_player",
      bool audio_only = false);

  MpvPlayerPlugin(
      flutter::PluginRegistrarWindows* registrar, const std::string& channel_name = "com.plezy/mpv_player",
      bool audio_only = false);
  virtual ~MpvPlayerPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SendEvent(const flutter::EncodableValue& event);
  void PostToPlatformThread(std::function<void()> task);
  void DrainPlatformTasks();

  HWND GetWindow();
  HWND GetChildWindow();

  flutter::PluginRegistrarWindows* registrar_;
  DWORD platform_thread_id_;
  const bool audio_only_;
  // Per-instance wakeup message: the first window-proc delegate that handles
  // a message consumes it, so the video and audio instances must not share
  // one message id or one instance's wakeup would strand the other's queue.
  const UINT platform_task_message_;
  HWND flutter_window_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  std::unique_ptr<MpvPlayer> player_;
  DisplayModeManager display_mode_manager_;
  std::optional<int32_t> proc_id_;
  std::mutex platform_tasks_mutex_;
  std::queue<std::function<void()>> platform_tasks_;
  bool wakeup_posted_ = false;  // guarded by platform_tasks_mutex_
};

}  // namespace mpv

#endif  // MPV_PLUGIN_H_
