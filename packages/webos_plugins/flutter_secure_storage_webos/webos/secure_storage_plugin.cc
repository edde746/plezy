// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter_secure_storage_webos/flutter_secure_storage_webos_plugin.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "secure_storage.h"

namespace {

constexpr const char* kChannelName = "webos/secure_storage";

class SecureStoragePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

  SecureStoragePlugin();
  ~SecureStoragePlugin() override;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void OnLoad(flutter::MethodResult<flutter::EncodableValue>* result);
  void OnStore(const flutter::EncodableMap* args,
               flutter::MethodResult<flutter::EncodableValue>* result,
               bool compare);

  SecureStorage storage_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

void SecureStoragePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<SecureStoragePlugin>();
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  plugin->channel_ = std::move(channel);
  registrar->AddPlugin(std::move(plugin));
}

SecureStoragePlugin::SecureStoragePlugin() = default;
SecureStoragePlugin::~SecureStoragePlugin() = default;

void SecureStoragePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method_name = method_call.method_name();
  if (method_name == "load") {
    OnLoad(result.get());
  } else if (method_name == "store" || method_name == "compareAndStore") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    OnStore(args, result.get(), method_name == "compareAndStore");
  } else {
    result->NotImplemented();
  }
}

void SecureStoragePlugin::OnLoad(
    flutter::MethodResult<flutter::EncodableValue>* result) {
  SecureStorage::Row row;
  if (!storage_.Load(&row)) {
    result->Error("io", "sqlite load failed");
    return;
  }
  flutter::EncodableMap out;
  out[flutter::EncodableValue("keys")] =
      row.keys ? flutter::EncodableValue(*row.keys)
               : flutter::EncodableValue();
  out[flutter::EncodableValue("datas")] =
      row.datas ? flutter::EncodableValue(*row.datas)
                : flutter::EncodableValue();
  result->Success(flutter::EncodableValue(out));
}

void SecureStoragePlugin::OnStore(
    const flutter::EncodableMap* args,
    flutter::MethodResult<flutter::EncodableValue>* result,
    bool compare) {
  if (!args) {
    result->Error("invalid_args", "store requires {keys, datas}");
    return;
  }
  std::string keys;
  std::string datas;
  bool has_keys = false;
  bool has_datas = false;
  for (const auto& [k, v] : *args) {
    if (!std::holds_alternative<std::string>(k)) continue;
    const auto& name = std::get<std::string>(k);
    if (!std::holds_alternative<std::string>(v)) continue;
    if (name == "keys") {
      keys = std::get<std::string>(v);
      has_keys = true;
    } else if (name == "datas") {
      datas = std::get<std::string>(v);
      has_datas = true;
    }
  }
  if (!has_keys || !has_datas) {
    result->Error("invalid_args",
                  "store requires {keys: String, datas: String}");
    return;
  }
  if (compare) {
    SecureStorage::Row expected;
    const auto read_expected = [&](const char* name, std::optional<std::string>* out) {
      const auto it = args->find(flutter::EncodableValue(name));
      if (it == args->end()) return false;
      if (std::holds_alternative<std::monostate>(it->second)) return true;
      if (const auto* value = std::get_if<std::string>(&it->second)) {
        *out = *value;
        return true;
      }
      return false;
    };
    if (!read_expected("expectedKeys", &expected.keys) ||
        !read_expected("expectedDatas", &expected.datas) ||
        expected.keys.has_value() != expected.datas.has_value()) {
      result->Error("invalid_args", "compareAndStore requires the expected row");
      return;
    }
    const auto stored = storage_.CompareAndStore(expected, keys, datas);
    if (!stored.has_value()) {
      result->Error("io", "sqlite compare-and-store failed");
      return;
    }
    result->Success(flutter::EncodableValue(*stored));
    return;
  }
  if (!storage_.Store(keys, datas)) {
    result->Error("io", "sqlite store failed");
    return;
  }
  result->Success();
}

}  // namespace

void FlutterSecureStorageWebosPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  SecureStoragePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrar>(registrar));
}
