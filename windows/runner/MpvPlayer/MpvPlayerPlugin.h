#ifndef MPV_PLAYER_PLUGIN_H_
#define MPV_PLAYER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/binary_messenger.h>
#include <flutter_windows.h>
#include <map>
#include <memory>
#include <optional>

#include "MpvPlayerCore.h"

/// Simple BinaryMessenger implementation wrapping the C API
class SimpleBinaryMessenger : public flutter::BinaryMessenger {
public:
    explicit SimpleBinaryMessenger(FlutterDesktopMessengerRef messenger)
        : messenger_(messenger) {}

    void Send(const std::string& channel,
              const uint8_t* message,
              size_t message_size,
              flutter::BinaryReply reply) const override {
        FlutterDesktopMessengerSend(messenger_, channel.c_str(), message, message_size);
        if (reply) {
            reply(nullptr, 0);
        }
    }

    void SetMessageHandler(const std::string& channel,
                          flutter::BinaryMessageHandler handler) override {
        if (handler) {
            auto* handler_ptr = new flutter::BinaryMessageHandler(std::move(handler));
            FlutterDesktopMessengerSetCallback(
                messenger_, channel.c_str(),
                [](FlutterDesktopMessengerRef messenger,
                   const FlutterDesktopMessage* message,
                   void* user_data) {
                    auto* handler = static_cast<flutter::BinaryMessageHandler*>(user_data);
                    (*handler)(
                        message->message, message->message_size,
                        [messenger, response_handle = message->response_handle](
                            const uint8_t* response, size_t response_size) {
                            FlutterDesktopMessengerSendResponse(
                                messenger, response_handle, response, response_size);
                        });
                },
                handler_ptr);
        } else {
            FlutterDesktopMessengerSetCallback(messenger_, channel.c_str(), nullptr, nullptr);
        }
    }

private:
    FlutterDesktopMessengerRef messenger_;
};

/// Flutter plugin that bridges MPV player to Dart via method and event channels
class MpvPlayerPlugin : public MpvPlayerDelegate {
public:
    static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar_ref);

    explicit MpvPlayerPlugin(FlutterDesktopPluginRegistrarRef registrar_ref);
    virtual ~MpvPlayerPlugin();

    // Prevent copying
    MpvPlayerPlugin(const MpvPlayerPlugin&) = delete;
    MpvPlayerPlugin& operator=(const MpvPlayerPlugin&) = delete;

    // MpvPlayerDelegate implementation
    void OnPropertyChange(const std::string& name, const MpvValue& value) override;
    void OnEvent(const std::string& name, const std::map<std::string, MpvValue>* data) override;

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    static LRESULT CALLBACK WndProcHook(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam,
                                        UINT_PTR subclass_id, DWORD_PTR ref_data);

    // Convert MpvValue to Flutter EncodableValue
    flutter::EncodableValue ConvertToEncodable(const MpvValue& value);

    FlutterDesktopPluginRegistrarRef registrar_ref_;
    HWND window_handle_ = nullptr;
    std::unique_ptr<MpvPlayerCore> player_core_;
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

#endif  // MPV_PLAYER_PLUGIN_H_
