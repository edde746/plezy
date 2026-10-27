// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ffi_messages.h"

#include <app_common.h>
#include <dart_api_dl.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/plugin_registrar.h>
#include <flutter_tizen.h>
#include <stdlib.h>
#include <string.h>

#include <cinttypes>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <shared_mutex>
#include <sstream>
#include <string>
#include <variant>

#include "../third_party/nlohmann_json/json.hpp"
#include "log.h"
#include "media_player.h"
#include "video_player.h"
#include "video_player_options.h"

using nlohmann::json;

namespace video_player_videohole_tizen {

static std::map<int64_t, std::shared_ptr<VideoPlayer>> g_players;
static std::shared_mutex g_players_mutex;
static FlutterDesktopPluginRegistrarRef g_registrar_ref = nullptr;
static flutter::PluginRegistrar* g_plugin_registrar = nullptr;
static VideoPlayerOptions g_options;
static bool g_dart_api_dl_initialized = false;

static std::shared_ptr<VideoPlayer> GetPlayer(int64_t player_id) {
  std::shared_lock<std::shared_mutex> lock(g_players_mutex);
  auto iter = g_players.find(player_id);
  if (iter != g_players.end()) {
    return iter->second;
  }
  return nullptr;
}

static flutter::EncodableValue EncodableValueFromJson(const json& j) {
  if (j.is_null()) {
    return flutter::EncodableValue();
  } else if (j.is_boolean()) {
    return flutter::EncodableValue(j.get<bool>());
  } else if (j.is_number_integer()) {
    return flutter::EncodableValue(static_cast<int64_t>(j.get<int64_t>()));
  } else if (j.is_number_float()) {
    return flutter::EncodableValue(j.get<double>());
  } else if (j.is_string()) {
    return flutter::EncodableValue(j.get<std::string>());
  } else if (j.is_array()) {
    flutter::EncodableList list;
    for (const auto& item : j) {
      list.push_back(EncodableValueFromJson(item));
    }
    return flutter::EncodableValue(list);
  } else if (j.is_object()) {
    flutter::EncodableMap map;
    for (auto& [key, value] : j.items()) {
      map[flutter::EncodableValue(key)] = EncodableValueFromJson(value);
    }
    return flutter::EncodableValue(map);
  }
  return flutter::EncodableValue();
}

static flutter::EncodableMap ParseJsonMap(const std::string& json_str) {
  flutter::EncodableMap result;
  if (json_str.empty() || json_str == "{}") {
    return result;
  }
  try {
    json j = json::parse(json_str);
    if (j.is_object()) {
      for (auto& [key, value] : j.items()) {
        result[flutter::EncodableValue(key)] = EncodableValueFromJson(value);
      }
    }
  } catch (const json::parse_error& e) {
    LOG_ERROR("[ParseJsonMap] JSON parse error: %s", e.what());
  }
  return result;
}

CreateMessage ParseCreateMessage(const std::string& json_str) {
  CreateMessage msg;
  if (json_str.empty() || json_str == "{}") {
    return msg;
  }
  try {
    json j = json::parse(json_str);
    if (j.contains("uri") && !j["uri"].is_null()) {
      msg.set_uri(j["uri"].get<std::string>());
    }
    if (j.contains("asset") && !j["asset"].is_null()) {
      msg.set_asset(j["asset"].get<std::string>());
    }
    if (j.contains("packageName") && !j["packageName"].is_null()) {
      msg.set_package_name(j["packageName"].get<std::string>());
    }
    if (j.contains("formatHint") && !j["formatHint"].is_null()) {
      msg.set_format_hint(j["formatHint"].get<std::string>());
    }
    if (j.contains("httpHeaders") && j["httpHeaders"].is_object()) {
      msg.set_http_headers(ParseJsonMap(j["httpHeaders"].dump()));
    }
    if (j.contains("playerOptions") && j["playerOptions"].is_object()) {
      msg.set_player_options(ParseJsonMap(j["playerOptions"].dump()));
    }
    if (j.contains("drmConfigs") && j["drmConfigs"].is_object()) {
      msg.set_drm_configs(ParseJsonMap(j["drmConfigs"].dump()));
    }
    if (j.contains("windowGeometry") && j["windowGeometry"].is_object()) {
      msg.set_window_geometry(ParseJsonMap(j["windowGeometry"].dump()));
    }
  } catch (const json::parse_error& e) {
    LOG_ERROR("[ParseCreateMessage] JSON parse error: %s", e.what());
  }
  return msg;
}

void ffi_set_plugin_registrar(FlutterDesktopPluginRegistrarRef registrar_ref,
                              flutter::PluginRegistrar* registrar) {
  g_registrar_ref = registrar_ref;
  g_plugin_registrar = registrar;
}

}  // namespace video_player_videohole_tizen

using video_player_videohole_tizen::CreateMessage;
using video_player_videohole_tizen::VideoPlayer;

extern "C" {

int ffi_initialize() {
  std::unique_lock<std::shared_mutex> lock(
      video_player_videohole_tizen::g_players_mutex);
  video_player_videohole_tizen::g_players.clear();
  return 0;
}

void ffi_dispose_all_players() {
  using namespace video_player_videohole_tizen;

  std::vector<std::shared_ptr<VideoPlayer>> players_to_dispose;
  {
    std::unique_lock<std::shared_mutex> lock(g_players_mutex);
    for (auto& [id, player] : g_players) {
      players_to_dispose.push_back(player);
    }
    g_players.clear();
  }

  for (auto& player : players_to_dispose) {
    player->Dispose();
  }

  UnregisterDartPort();

  g_registrar_ref = nullptr;
  g_plugin_registrar = nullptr;

  LOG_INFO(
      "[FFI] All players disposed, Dart port unregistered, registrar refs "
      "cleared");
}

int64_t ffi_create(const char* create_message_json) {
  using namespace video_player_videohole_tizen;
  if (g_registrar_ref == nullptr || g_plugin_registrar == nullptr) {
    return -1;
  }
  FlutterDesktopViewRef view =
      FlutterDesktopPluginRegistrarGetView(g_registrar_ref);
  if (!view) {
    return -1;
  }
  CreateMessage msg;
  if (create_message_json != nullptr && strlen(create_message_json) > 0) {
    msg = ParseCreateMessage(std::string(create_message_json));
  }
  std::string uri;
  if (msg.asset() && !msg.asset()->empty()) {
    char* res_path = app_get_resource_path();
    if (res_path) {
      uri = uri + res_path + "flutter_assets/" + *msg.asset();
      free(res_path);
    } else {
      return -1;
    }
  } else if (msg.uri() && !msg.uri()->empty()) {
    uri = *msg.uri();
  } else {
    return -1;
  }
  auto player = std::make_unique<video_player_videohole_tizen::MediaPlayer>(
      g_plugin_registrar->messenger(), view);
  int64_t player_id = player->Create(uri, msg);
  if (player_id == -1) {
    return -1;
  }
  std::unique_lock<std::shared_mutex> lock(g_players_mutex);
  g_players[player_id] = std::move(player);
  return player_id;
}

int ffi_prepare(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->Prepare();
}

int ffi_dispose(int64_t player_id) {
  using namespace video_player_videohole_tizen;
  std::shared_ptr<VideoPlayer> player;

  {
    std::unique_lock<std::shared_mutex> lock(g_players_mutex);
    auto iter = g_players.find(player_id);
    if (iter != g_players.end()) {
      player = iter->second;
      g_players.erase(iter);
    }
  }

  if (player) {
    player->Dispose();
  }

  return 0;
}

int ffi_play(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->Play() ? 0 : -1;
}

int ffi_pause(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->Pause() ? 0 : -1;
}

int ffi_seek_to(int64_t player_id, int64_t position_ms) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->SeekTo(
             position_ms,
             video_player_videohole_tizen::VideoPlayer::SeekCompletedCallback())
             ? 0
             : -1;
}

int64_t ffi_get_position(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->GetPosition();
}

const char* ffi_get_duration(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return strdup("-1");
  }
  auto duration_pair = player->GetDuration();
  std::string duration_json = "{\"playerId\":" + std::to_string(player_id) +
                              ",\"durationRange\":[" +
                              std::to_string(duration_pair.first) + "," +
                              std::to_string(duration_pair.second) + "]}";
  return strdup(duration_json.c_str());
}

int ffi_set_volume(int64_t player_id, double volume) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->SetVolume(volume) ? 0 : -1;
}

int ffi_set_playback_speed(int64_t player_id, double speed) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->SetPlaybackSpeed(speed) ? 0 : -1;
}

int ffi_set_looping(int64_t player_id, bool is_looping) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->SetLooping(is_looping) ? 0 : -1;
}

const char* ffi_get_track_info(int64_t player_id, const char* track_type) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player || track_type == nullptr) {
    return nullptr;
  }
  auto tracks = player->GetTrackInfo(std::string(track_type));
  json j;
  j["playerId"] = player_id;
  j["tracks"] = json::array();
  for (const auto& track_value : tracks) {
    const auto& track_map = std::get<flutter::EncodableMap>(track_value);
    json track_j = json::object();
    for (const auto& [key, value] : track_map) {
      const std::string* key_str = std::get_if<std::string>(&key);
      if (!key_str) continue;
      if (std::holds_alternative<int32_t>(value)) {
        track_j[*key_str] = std::get<int32_t>(value);
      } else if (std::holds_alternative<int64_t>(value)) {
        track_j[*key_str] = std::get<int64_t>(value);
      } else if (std::holds_alternative<double>(value)) {
        track_j[*key_str] = std::get<double>(value);
      } else if (std::holds_alternative<std::string>(value)) {
        track_j[*key_str] = std::get<std::string>(value);
      } else if (std::holds_alternative<bool>(value)) {
        track_j[*key_str] = std::get<bool>(value);
      }
    }
    j["tracks"].push_back(track_j);
  }
  return strdup(j.dump().c_str());
}

int ffi_set_track_selection(int64_t player_id, int64_t track_id,
                            const char* track_type) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player || track_type == nullptr) {
    return -1;
  }
  return player->SetTrackSelection(track_id, std::string(track_type)) ? 0 : -1;
}

int ffi_set_display_geometry(int64_t player_id, int32_t x, int32_t y,
                             int32_t width, int32_t height) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  player->SetDisplayRoi(x, y, width, height);
  return 0;
}

int ffi_set_display_rotate(int64_t player_id, int32_t rotation) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->SetDisplayRotate(rotation) ? 0 : -1;
}

int ffi_suspend(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->Suspend() ? 0 : -1;
}

int ffi_restore(int64_t player_id, const char* create_message_json,
                int64_t resume_time) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  CreateMessage msg;
  if (create_message_json != nullptr && strlen(create_message_json) > 0) {
    msg = video_player_videohole_tizen::ParseCreateMessage(
        std::string(create_message_json));
  }
  return player->Restore(&msg, resume_time) ? 0 : -1;
}

int ffi_set_activate(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->Activate() ? 0 : -1;
}

int ffi_set_deactivate(int64_t player_id) {
  auto player = video_player_videohole_tizen::GetPlayer(player_id);
  if (!player) {
    return -1;
  }
  return player->Deactivate() ? 0 : -1;
}

int ffi_set_mix_with_others(bool mix_with_others) {
  video_player_videohole_tizen::g_options.SetMixWithOthers(mix_with_others);
  return 0;
}

int ffi_initialize_api_dl(void* data) {
  if (!video_player_videohole_tizen::g_dart_api_dl_initialized) {
    if (Dart_InitializeApiDL(data) == 0) {
      video_player_videohole_tizen::g_dart_api_dl_initialized = true;
      return 0;
    }
    return -1;
  }
  return 0;
}

void ffi_free_string(char* ptr) {
  if (ptr != nullptr) {
    free(ptr);
  }
}

void ffi_register_dart_port(int64_t port) {
  video_player_videohole_tizen::RegisterDartPort(port);
}

void ffi_unregister_dart_port() {
  video_player_videohole_tizen::UnregisterDartPort();
}

}  // extern "C"
