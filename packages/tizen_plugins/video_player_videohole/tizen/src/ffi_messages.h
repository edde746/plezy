// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FFI_MESSAGES_H_
#define FFI_MESSAGES_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/plugin_registrar.h>
#include <flutter_tizen.h>

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <string>
#include <variant>

#include "video_player_options.h"
#include "video_player_tizen_plugin.h"

#ifdef __cplusplus
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT int ffi_initialize();
FLUTTER_PLUGIN_EXPORT int64_t ffi_create(const char* create_message_json);
FLUTTER_PLUGIN_EXPORT int ffi_prepare(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_dispose(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_play(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_pause(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_seek_to(int64_t player_id, int64_t position_ms);
FLUTTER_PLUGIN_EXPORT int64_t ffi_get_position(int64_t player_id);
FLUTTER_PLUGIN_EXPORT const char* ffi_get_duration(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_set_volume(int64_t player_id, double volume);
FLUTTER_PLUGIN_EXPORT int ffi_set_playback_speed(int64_t player_id,
                                                 double speed);
FLUTTER_PLUGIN_EXPORT int ffi_set_looping(int64_t player_id, bool is_looping);
FLUTTER_PLUGIN_EXPORT const char* ffi_get_track_info(int64_t player_id,
                                                     const char* track_type);
FLUTTER_PLUGIN_EXPORT int ffi_set_track_selection(int64_t player_id,
                                                  int64_t track_id,
                                                  const char* track_type);
FLUTTER_PLUGIN_EXPORT int ffi_set_display_geometry(int64_t player_id, int32_t x,
                                                   int32_t y, int32_t width,
                                                   int32_t height);
FLUTTER_PLUGIN_EXPORT int ffi_set_display_rotate(int64_t player_id,
                                                 int32_t rotation);
FLUTTER_PLUGIN_EXPORT int ffi_suspend(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_restore(int64_t player_id,
                                      const char* create_message_json,
                                      int64_t resume_time);
FLUTTER_PLUGIN_EXPORT int ffi_set_activate(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_set_deactivate(int64_t player_id);
FLUTTER_PLUGIN_EXPORT int ffi_set_mix_with_others(bool mix_with_others);

void ffi_dispose_all_players();

FLUTTER_PLUGIN_EXPORT int ffi_initialize_api_dl(void* data);
FLUTTER_PLUGIN_EXPORT void ffi_register_dart_port(int64_t port);
FLUTTER_PLUGIN_EXPORT void ffi_unregister_dart_port();

FLUTTER_PLUGIN_EXPORT void ffi_free_string(char* ptr);

#ifdef __cplusplus
}  // extern "C"

namespace video_player_videohole_tizen {

class CreateMessage {
 public:
  CreateMessage() = default;

  const std::string* asset() const { return asset_ ? &(*asset_) : nullptr; }
  void set_asset(const std::string& value) { asset_ = value; }

  const std::string* uri() const { return uri_ ? &(*uri_) : nullptr; }
  void set_uri(const std::string& value) { uri_ = value; }

  const std::string* package_name() const {
    return package_name_ ? &(*package_name_) : nullptr;
  }
  void set_package_name(const std::string& value) { package_name_ = value; }

  const std::string* format_hint() const {
    return format_hint_ ? &(*format_hint_) : nullptr;
  }
  void set_format_hint(const std::string& value) { format_hint_ = value; }

  const flutter::EncodableMap* http_headers() const {
    return http_headers_ ? &(*http_headers_) : nullptr;
  }
  void set_http_headers(const flutter::EncodableMap& value) {
    http_headers_ = value;
  }

  const flutter::EncodableMap* drm_configs() const {
    return drm_configs_ ? &(*drm_configs_) : nullptr;
  }
  void set_drm_configs(const flutter::EncodableMap& value) {
    drm_configs_ = value;
  }

  const flutter::EncodableMap* player_options() const {
    return player_options_ ? &(*player_options_) : nullptr;
  }
  void set_player_options(const flutter::EncodableMap& value) {
    player_options_ = value;
  }

  const flutter::EncodableMap* window_geometry() const {
    return window_geometry_ ? &(*window_geometry_) : nullptr;
  }
  void set_window_geometry(const flutter::EncodableMap& value) {
    window_geometry_ = value;
  }

 private:
  std::optional<std::string> asset_;
  std::optional<std::string> uri_;
  std::optional<std::string> package_name_;
  std::optional<std::string> format_hint_;
  std::optional<flutter::EncodableMap> http_headers_;
  std::optional<flutter::EncodableMap> drm_configs_;
  std::optional<flutter::EncodableMap> player_options_;
  std::optional<flutter::EncodableMap> window_geometry_;
};

void ffi_set_plugin_registrar(FlutterDesktopPluginRegistrarRef registrar_ref,
                              flutter::PluginRegistrar* registrar);

}  // namespace video_player_videohole_tizen
#endif  // __cplusplus

#endif  // FFI_MESSAGES_H_
