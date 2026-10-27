// Copyright 2024 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "wakelock_plus_tizen_plugin.h"

#include <Ecore.h>
#include <dlfcn.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <tizen.h>

#include <memory>
#include <string>
#include <variant>

#include "log.h"

namespace {

typedef int (*FuncScreensaverResetTimeout)(void);
typedef int (*FuncScreensaverOverrideReset)(bool onoff);

class WakelockPlusTizenPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "tizen/wakelock_plus_plugin",
            &flutter::StandardMethodCodec::GetInstance());
    auto plugin = std::make_unique<WakelockPlusTizenPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  WakelockPlusTizenPlugin() {}

  virtual ~WakelockPlusTizenPlugin() {
    if (timer_) ecore_timer_del(timer_);
    if (screensaver_api_handle_) dlclose(screensaver_api_handle_);
  }

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto &method_name = method_call.method_name();
    if (!is_initialized_screensaver_api_) {
      InitScreensaverApi();
      is_initialized_screensaver_api_ = true;
    }

    if (method_name == "toggle") {
      const auto &arguments = *method_call.arguments();
      if (std::holds_alternative<bool>(arguments)) {
        bool enable = std::get<bool>(arguments);
        if (enable) {
          if (!screensaver_reset_timeout_) {
            result->Error("unavailable", "Screensaver API is unavailable on this device.");
            return;
          }
          int ret = screensaver_reset_timeout_();
          if (ret != 0) {
            result->Error(std::to_string(ret), get_error_message(ret));
            return;
          }
          if (timer_) {
            ecore_timer_del(timer_);
          }
          timer_ = ecore_timer_add(30, OnResetScreensaverTimeout, this);
          is_enabled_ = true;
        } else {
          if (timer_) {
            ecore_timer_del(timer_);
            timer_ = nullptr;
          }
          is_enabled_ = false;
        }
        result->Success();
      } else {
        result->Error("Invalid argument",
                      "The argument must be a boolean value.");
      }
    } else if (method_name == "isEnabled") {
      result->Success(flutter::EncodableValue(is_enabled_));
    } else {
      result->NotImplemented();
    }
  }

  void InitScreensaverApi() {
    screensaver_api_handle_ = dlopen("libcapi-screensaver.so", RTLD_LAZY);
    if (!screensaver_api_handle_) {
      LOG_ERROR("dlopen failed: %s", dlerror());
      return;
    }
    screensaver_reset_timeout_ = reinterpret_cast<FuncScreensaverResetTimeout>(
        dlsym(screensaver_api_handle_, "screensaver_reset_timeout"));
    if (!screensaver_reset_timeout_) {
      LOG_ERROR("Symbol not found: %s", dlerror());
      return;
    }
    FuncScreensaverOverrideReset screensaver_override_reset =
        reinterpret_cast<FuncScreensaverOverrideReset>(
            dlsym(screensaver_api_handle_, "screensaver_override_reset"));
    if (!screensaver_override_reset) {
      LOG_ERROR("Symbol not found: %s", dlerror());
      return;
    }
    int ret = screensaver_override_reset(false);
    if (ret != 0) {
      LOG_ERROR("screensaver_override_reset failed: %s",
                get_error_message(ret));
      return;
    }
  }

  static Eina_Bool OnResetScreensaverTimeout(void *data) {
    auto *plugin = static_cast<WakelockPlusTizenPlugin *>(data);
    if (!plugin->screensaver_reset_timeout_) {
      plugin->timer_ = nullptr;
      plugin->is_enabled_ = false;
      return ECORE_CALLBACK_CANCEL;
    }
    int ret = plugin->screensaver_reset_timeout_();
    if (ret != 0) {
      LOG_ERROR("screensaver_reset_timeout failed: %s", get_error_message(ret));
      plugin->timer_ = nullptr;
      plugin->is_enabled_ = false;
      return ECORE_CALLBACK_CANCEL;
    }

    return ECORE_CALLBACK_RENEW;
  }

  bool is_initialized_screensaver_api_ = false;
  void *screensaver_api_handle_ = nullptr;
  Ecore_Timer *timer_ = nullptr;
  FuncScreensaverResetTimeout screensaver_reset_timeout_ = nullptr;
  bool is_enabled_ = false;
};

}  // namespace

void WakelockPlusTizenPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  WakelockPlusTizenPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrar>(registrar));
}
