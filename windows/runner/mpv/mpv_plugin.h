#ifndef MPV_PLUGIN_H_
#define MPV_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>

#include "mpv_core.h"
#include "mpv_player.h"

// C-style registration function for the plugin.
void MpvPlayerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

namespace mpv {

class MpvPlayerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  MpvPlayerPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~MpvPlayerPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SendEvent(const flutter::EncodableValue& event);

  HWND GetWindow();
  HWND GetChildWindow();

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  std::unique_ptr<MpvPlayer> player_;
  std::optional<int32_t> proc_id_;
};

}  // namespace mpv

#endif  // MPV_PLUGIN_H_
