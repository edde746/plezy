// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "video_player_tizen_plugin.h"

#include <flutter/plugin_registrar.h>
#include <flutter_tizen.h>

#include <memory>

#include "ffi_messages.h"
#include "log.h"

namespace video_player_videohole_tizen {

class VideoPlayerTizenPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      FlutterDesktopPluginRegistrarRef registrar_ref,
      flutter::PluginRegistrar* plugin_registrar) {
    auto plugin = std::make_unique<VideoPlayerTizenPlugin>(registrar_ref);
    plugin_registrar->AddPlugin(std::move(plugin));
  }

  explicit VideoPlayerTizenPlugin(
      FlutterDesktopPluginRegistrarRef registrar_ref)
      : registrar_ref_(registrar_ref) {
    auto* plugin_registrar =
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrar>(registrar_ref);
    ffi_set_plugin_registrar(registrar_ref, plugin_registrar);

    LOG_INFO("[VideoPlayerTizenPlugin] Registered with registrar");
  }

  ~VideoPlayerTizenPlugin() override {
    LOG_INFO(
        "[VideoPlayerTizenPlugin] Destroying plugin, cleaning up resources");
    ffi_dispose_all_players();
  }

  VideoPlayerTizenPlugin(const VideoPlayerTizenPlugin&) = delete;
  VideoPlayerTizenPlugin& operator=(const VideoPlayerTizenPlugin&) = delete;

 private:
  FlutterDesktopPluginRegistrarRef registrar_ref_;
};

extern "C" {

void VideoPlayerTizenPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar_ref) {
  auto* plugin_registrar =
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrar>(registrar_ref);

  VideoPlayerTizenPlugin::RegisterWithRegistrar(registrar_ref,
                                                plugin_registrar);
}

}  // extern "C"

}  // namespace video_player_videohole_tizen
