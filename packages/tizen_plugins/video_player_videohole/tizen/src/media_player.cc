// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "media_player.h"

#include <system_info.h>
#include <unistd.h>

#include <cstdio>
#include <cstdlib>
#include <sstream>

#include "log.h"

namespace video_player_videohole_tizen {

static std::string RotationToString(player_display_rotation_e rotation) {
  switch (rotation) {
    case PLAYER_DISPLAY_ROTATION_NONE:
      return "PLAYER_DISPLAY_ROTATION_NONE";
    case PLAYER_DISPLAY_ROTATION_90:
      return "PLAYER_DISPLAY_ROTATION_90";
    case PLAYER_DISPLAY_ROTATION_180:
      return "PLAYER_DISPLAY_ROTATION_180";
    case PLAYER_DISPLAY_ROTATION_270:
      return "PLAYER_DISPLAY_ROTATION_270";
  }
  return std::string();
}

static player_stream_type_e ConvertTrackType(std::string track_type) {
  if (track_type == "video") {
    return PLAYER_STREAM_TYPE_VIDEO;
  }
  if (track_type == "audio") {
    return PLAYER_STREAM_TYPE_AUDIO;
  }
  if (track_type == "text") {
    return PLAYER_STREAM_TYPE_TEXT;
  }
  return PLAYER_STREAM_TYPE_DEFAULT;
}

static bool IsTizenCorePlatform() {
  static const bool is_tizen_core = [] {
    int major = 0;
    char *value = nullptr;
    int ret = system_info_get_platform_string(
        "http://tizen.org/feature/platform.version", &value);
    if (ret == SYSTEM_INFO_ERROR_NONE && value) {
      std::sscanf(value, "%d", &major);
    }
    free(value);
    return major >= 11;
  }();
  return is_tizen_core;
}

MediaPlayer::MediaPlayer(flutter::BinaryMessenger *messenger,
                         FlutterDesktopViewRef flutter_view)
    : VideoPlayer(messenger, flutter_view) {}

MediaPlayer::~MediaPlayer() { Dispose(); }

static int64_t player_id_counter = 1;

int64_t MediaPlayer::Create(const std::string &uri,
                            const CreateMessage &create_message,
                            bool reuse_existing_id) {
  LOG_INFO("[MediaPlayer] Create: reuse_existing_id=%d", reuse_existing_id ? 1 : 0);

  if (uri.empty()) {
    LOG_ERROR("[MediaPlayer] The uri must not be empty.");
    return -1;
  }

  if (!reuse_existing_id || player_id_ <= 0) {
    player_id_ = player_id_counter++;
    LOG_INFO("[MediaPlayer] Allocated new player_id=%lld",
             static_cast<long long>(player_id_));
  } else {
    LOG_INFO("[MediaPlayer] Reusing existing player_id=%lld",
             static_cast<long long>(player_id_));
  }

  url_ = uri;
  create_message_ = create_message;

  int ret = player_create(&player_);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_create failed: %s.",
              get_error_message(ret));
    return -1;
  }

  std::string cookie = flutter_common::GetValue(create_message.http_headers(),
                                                "Cookie", std::string());
  if (!cookie.empty()) {
    int ret =
        player_set_streaming_cookie(player_, cookie.c_str(), cookie.size());
    if (ret != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] player_set_streaming_cookie failed: %s.",
                get_error_message(ret));
    }
  }
  std::string user_agent = flutter_common::GetValue(
      create_message.http_headers(), "User-Agent", std::string());
  if (!user_agent.empty()) {
    int ret = player_set_streaming_user_agent(player_, user_agent.c_str(),
                                              user_agent.size());
    if (ret != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] player_set_streaming_user_agent failed: %s.",
                get_error_message(ret));
    }
  }

  int64_t drm_type = flutter_common::GetValue(create_message.drm_configs(),
                                              "drmType", (int64_t)0);
  std::string license_server_url = flutter_common::GetValue(
      create_message.drm_configs(), "licenseServerUrl", std::string());
  if (drm_type != 0) {
    if (!SetDrm(uri, drm_type, license_server_url)) {
      LOG_ERROR("[MediaPlayer] Failed to set drm.");
      return -1;
    }
  }

  if (!SetDisplay()) {
    LOG_ERROR("[MediaPlayer] Failed to set display.");
    return -1;
  }

  SetDisplayRoi(pre_display_roi_x_, pre_display_roi_y_, pre_display_roi_width_,
                pre_display_roi_height_);

  ret = player_set_uri(player_, uri.c_str());
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_uri failed : %s.",
              get_error_message(ret));
    return -1;
  }

  ret = player_set_display_visible(player_, true);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_display_visible failed : %s.",
              get_error_message(ret));
    return -1;
  }

  ret = player_set_buffering_cb(player_, OnBuffering, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_buffering_cb failed : %s.",
              get_error_message(ret));
    return -1;
  }

  ret = player_set_completed_cb(player_, OnPlayCompleted, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_completed_cb failed : %s.",
              get_error_message(ret));
    return -1;
  }

  ret = player_set_interrupted_cb(player_, OnInterrupted, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_interrupted_cb failed : %s.",
              get_error_message(ret));
    return -1;
  }

  ret = player_set_error_cb(player_, OnError, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_error_cb failed : %s.",
              get_error_message(ret));
    return -1;
  }

  ret = player_set_subtitle_updated_cb(player_, OnSubtitleUpdated, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_subtitle_updated_cb failed : %s.",
              get_error_message(ret));
    return -1;
  }

  return player_id_;
}

int MediaPlayer::Prepare() {
  LOG_INFO("[MediaPlayer] Prepare() called for player_id=%lld",
           static_cast<long long>(player_id_));

  if (!player_) {
    LOG_ERROR("[MediaPlayer] Player not created.");
    return -1;
  }

  int ret = player_prepare_async(player_, OnPrepared, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_prepare_async failed : %s.",
              get_error_message(ret));
    return -1;
  }

  return 0;
}

void MediaPlayer::Dispose() {
  MarkDisposed();

  if (!player_) {
    return;
  }
  LOG_INFO("[MediaPlayer] Player disposing.");

  player_unset_buffering_cb(player_);
  player_unset_completed_cb(player_);
  player_unset_interrupted_cb(player_);
  player_unset_error_cb(player_);
  player_unset_subtitle_updated_cb(player_);

  StopAndDestroy();
}

void MediaPlayer::SetDisplayRoi(int32_t x, int32_t y, int32_t width,
                                int32_t height) {
  int ret = player_set_display_roi_area(player_, x, y, width, height);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_display_roi_area failed: %s.",
              get_error_message(ret));
  }
  pre_display_roi_x_ = x;
  pre_display_roi_y_ = y;
  pre_display_roi_width_ = width;
  pre_display_roi_height_ = height;
}

bool MediaPlayer::Play() {
  LOG_INFO("[MediaPlayer] Player starting.");

  player_state_e state = PLAYER_STATE_NONE;
  int ret = player_get_state(player_, &state);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] Unable to get player state: %s.",
              get_error_message(ret));
    return false;
  }
  if (state == PLAYER_STATE_NONE || state == PLAYER_STATE_IDLE) {
    LOG_ERROR("[MediaPlayer] Player not ready.");
    return false;
  }
  if (state == PLAYER_STATE_PLAYING) {
    LOG_INFO("[MediaPlayer] Player already playing.");
    return true;
  }

  ret = player_start(player_);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_start failed: %s.", get_error_message(ret));
    return false;
  }

  SendIsPlayingState(true);
  return true;
}

bool MediaPlayer::Pause() {
  LOG_INFO("[MediaPlayer] Player pausing.");

  player_state_e state = PLAYER_STATE_NONE;
  int ret = player_get_state(player_, &state);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] Unable to get player state.");
  }
  if (state == PLAYER_STATE_NONE || state == PLAYER_STATE_IDLE) {
    LOG_ERROR("[MediaPlayer] Player not ready.");
    return false;
  }
  if (state != PLAYER_STATE_PLAYING) {
    LOG_INFO("[MediaPlayer] Player already not playing (state=%d).", state);
    return true;
  }
  ret = player_pause(player_);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_pause failed: %s.", get_error_message(ret));
    return false;
  }
  SendIsPlayingState(false);
  return true;
}

bool MediaPlayer::SetLooping(bool is_looping) {
  LOG_INFO("[MediaPlayer] is_looping: %d.", is_looping);

  int ret = player_set_looping(player_, is_looping);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_looping failed: %s.",
              get_error_message(ret));
    return false;
  }
  return true;
}

bool MediaPlayer::SetVolume(double volume) {
  LOG_INFO("[MediaPlayer] volume: %f.", volume);

  int ret = player_set_volume(player_, volume, volume);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_volume failed: %s.",
              get_error_message(ret));
    return false;
  }
  return true;
}

bool MediaPlayer::SetPlaybackSpeed(double speed) {
  LOG_INFO("[MediaPlayer] speed: %f.", speed);

  int ret = player_set_playback_rate(player_, speed);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_playback_rate failed: %s.",
              get_error_message(ret));
    return false;
  }
  return true;
}

bool MediaPlayer::SeekTo(int64_t position, SeekCompletedCallback callback) {
  LOG_INFO("[MediaPlayer] position: %lld.", position);

  if (is_seeking_) {
    LOG_ERROR("[MediaPlayer] Seek is already in progress.");
    return false;
  }

  on_seek_completed_ = std::move(callback);
  is_seeking_ = true;

  int ret =
      player_set_play_position(player_, position, true, OnSeekCompleted, this);
  if (ret != PLAYER_ERROR_NONE) {
    on_seek_completed_ = nullptr;
    is_seeking_ = false;
    LOG_ERROR("[MediaPlayer] player_set_play_position failed: %s.",
              get_error_message(ret));
    return false;
  }
  return true;
}

int64_t MediaPlayer::GetPosition() {
  if (!player_) {
    LOG_ERROR("[MediaPlayer] player_ is null, cannot get position.");
    return -1;
  }

  int position = 0;
  int ret = player_get_play_position(player_, &position);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_DEBUG("[MediaPlayer] player_get_play_position failed: %s.",
              get_error_message(ret));
  }
  LOG_DEBUG("[MediaPlayer] Video current position : %d.", position);
  return position;
}

std::pair<int64_t, int64_t> MediaPlayer::GetDuration() {
  if (IsLive()) {
    return GetLiveDuration();
  } else {
    int duration = 0;
    int ret = player_get_duration(player_, &duration);
    if (ret != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] player_get_duration failed: %s.",
                get_error_message(ret));
    }
    LOG_INFO("[MediaPlayer] Video duration: %d.", duration);
    return std::make_pair(0, duration);
  }
}

void MediaPlayer::GetVideoSize(int32_t *width, int32_t *height) {
  int w = 0, h = 0;
  int ret = player_get_video_size(player_, &w, &h);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_video_size failed: %s.",
              get_error_message(ret));
  }
  LOG_INFO("[MediaPlayer] Video width: %d, height: %d.", w, h);

  player_display_rotation_e rotation = PLAYER_DISPLAY_ROTATION_NONE;
  ret = player_get_display_rotation(player_, &rotation);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_display_rotation failed: %s.",
              get_error_message(ret));
  }
  LOG_DEBUG("[MediaPlayer] Video rotation: %s.",
            RotationToString(rotation).c_str());
  if (rotation == PLAYER_DISPLAY_ROTATION_90 ||
      rotation == PLAYER_DISPLAY_ROTATION_270) {
    std::swap(w, h);
  }

  *width = w;
  *height = h;
}

bool MediaPlayer::IsReady() {
  player_state_e state = PLAYER_STATE_NONE;
  int ret = player_get_state(player_, &state);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_state failed: %s.",
              get_error_message(ret));
    return false;
  }

  LOG_INFO("[MediaPlayer] Player state : %d.", state);
  return PLAYER_STATE_READY == state;
}

bool MediaPlayer::SetDisplay() {
  void *native_window = GetWindowHandle();
  if (!native_window) {
    LOG_ERROR("[MediaPlayer] Could not get a native window handle.");
    return false;
  }

  int ret = PLAYER_ERROR_NONE;
  if (IsTizenCorePlatform()) {
    ret = ftpw_video_player_videohole_player_set_tcore_display(
        player_, PLAYER_DISPLAY_TYPE_TCORE_OVERLAY, native_window);
    if (ret != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] player_set_tcore_display failed: %s.",
                get_error_message(ret));
      return false;
    }
  } else {
    const flutter::EncodableMap *window_geometry =
        create_message_.window_geometry();
    if (!window_geometry) {
      LOG_ERROR("[MediaPlayer] Window geometry is missing.");
      return false;
    }
    int64_t x = flutter_common::GetValue(window_geometry, "x", (int64_t)0);
    int64_t y = flutter_common::GetValue(window_geometry, "y", (int64_t)0);
    int64_t width =
        flutter_common::GetValue(window_geometry, "width", (int64_t)0);
    int64_t height =
        flutter_common::GetValue(window_geometry, "height", (int64_t)0);
    if (width <= 0 || height <= 0) {
      LOG_ERROR(
          "[MediaPlayer] Invalid window geometry size: width[%d], height[%d].",
          width, height);
      return false;
    }
    LOG_INFO(
        "[MediaPlayer] Window geometry: x[%d], y[%d], width[%d], height[%d].",
        x, y, width, height);

    ret = ftpw_video_player_videohole_player_set_ecore_wl_display(
        player_, PLAYER_DISPLAY_TYPE_OVERLAY, native_window, x, y, width,
        height);
    if (ret != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] player_set_ecore_wl_display failed: %s.",
                get_error_message(ret));
      return false;
    }
  }

  ret = player_set_display_mode(player_, PLAYER_DISPLAY_MODE_DST_ROI);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_display_mode failed: %s.",
              get_error_message(ret));
    return false;
  }
  return true;
}

bool MediaPlayer::IsLive() {
  int is_live = 0;
  int ret = ftpw_video_player_videohole_player_get_adaptive_streaming_info(
      player_, &is_live, PLAYER_ADAPTIVE_INFO_IS_LIVE);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_adaptive_streaming_info failed: %s",
              get_error_message(ret));
    return false;
  }
  return is_live != 0;
}

static std::vector<std::string> split(const std::string &s, char delim) {
  std::stringstream ss(s);
  std::string item;
  std::vector<std::string> tokens;
  while (getline(ss, item, delim)) {
    tokens.push_back(item);
  }
  return tokens;
}

std::pair<int64_t, int64_t> MediaPlayer::GetLiveDuration() {
  std::string live_duration_str = "";
  char *live_duration_buff = static_cast<char *>(malloc(sizeof(char) * 64));
  memset(live_duration_buff, 0, sizeof(char) * 64);

  int ret = ftpw_video_player_videohole_player_get_adaptive_streaming_info(
      player_, (void *)&live_duration_buff, PLAYER_ADAPTIVE_INFO_LIVE_DURATION);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_adaptive_streaming_info failed: %s",
              get_error_message(ret));
    free(live_duration_buff);
    return std::make_pair(0, 0);
  }
  if (*live_duration_buff) {
    live_duration_str = std::string(live_duration_buff);
  }
  free(live_duration_buff);
  if (live_duration_str.empty()) {
    return std::make_pair(0, 0);
  }
  std::vector<std::string> time_vec = split(live_duration_str, '|');
  return std::make_pair(std::stoll(time_vec[0]), std::stoll(time_vec[1]));
}

flutter::EncodableList MediaPlayer::GetTrackInfo(std::string track_type) {
  player_state_e state = PLAYER_STATE_NONE;
  int ret = player_get_state(player_, &state);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_state failed: %s",
              get_error_message(ret));
    return {};
  }
  if (state == PLAYER_STATE_NONE || state == PLAYER_STATE_IDLE) {
    LOG_ERROR("[MediaPlayer] Player not ready.");
    return {};
  }

  player_stream_type_e type = ConvertTrackType(track_type);
  int track_count = 0;
  ret = ftpw_video_player_videohole_player_get_track_count_v2(player_, type,
                                                              &track_count);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_track_count_v2 failed: %s",
              get_error_message(ret));
    return {};
  }

  if (track_count <= 0) {
    LOG_INFO("[MediaPlayer] No tracks found for type=%d", type);
    return {};
  }

  flutter::EncodableList trackSelections = {};
  flutter::EncodableMap trackSelection = {};
  trackSelection.insert(
      {flutter::EncodableValue("trackType"), flutter::EncodableValue(type)});
  if (type == PLAYER_STREAM_TYPE_VIDEO) {
    LOG_INFO("[MediaPlayer] video_count: %d", track_count);

    for (int video_index = 0; video_index < track_count; video_index++) {
      player_video_track_info_v2 *video_track_info = nullptr;

      ret = ftpw_video_player_videohole_player_get_video_track_info_v2(
          player_, video_index, &video_track_info);
      if (ret != PLAYER_ERROR_NONE) {
        LOG_ERROR("[MediaPlayer] player_get_video_track_info_v2 failed: %s",
                  get_error_message(ret));
        return {};
      }
      LOG_INFO(
          "[MediaPlayer] video track info: width[%d], height[%d], "
          "bitrate[%d]",
          video_track_info->width, video_track_info->height,
          video_track_info->bit_rate);

      trackSelection.insert_or_assign(flutter::EncodableValue("trackId"),
                                      flutter::EncodableValue(video_index));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("width"),
          flutter::EncodableValue(video_track_info->width));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("height"),
          flutter::EncodableValue(video_track_info->height));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("bitrate"),
          flutter::EncodableValue(video_track_info->bit_rate));

      trackSelections.push_back(flutter::EncodableValue(trackSelection));
    }

  } else if (type == PLAYER_STREAM_TYPE_AUDIO) {
    LOG_INFO("[MediaPlayer] audio_count: %d", track_count);

    for (int audio_index = 0; audio_index < track_count; audio_index++) {
      player_audio_track_info_v2 *audio_track_info = nullptr;

      ret = ftpw_video_player_videohole_player_get_audio_track_info_v2(
          player_, audio_index, &audio_track_info);
      if (ret != PLAYER_ERROR_NONE) {
        LOG_ERROR("[MediaPlayer] player_get_audio_track_info_v2 failed: %s",
                  get_error_message(ret));
        return {};
      }
      LOG_INFO(
          "[MediaPlayer] audio track info: language[%s], channel[%d], "
          "sample_rate[%d], bitrate[%d]",
          audio_track_info->language, audio_track_info->channel,
          audio_track_info->sample_rate, audio_track_info->bit_rate);

      trackSelection.insert_or_assign(flutter::EncodableValue("trackId"),
                                      flutter::EncodableValue(audio_index));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("language"),
          flutter::EncodableValue(std::string(audio_track_info->language)));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("channel"),
          flutter::EncodableValue(audio_track_info->channel));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("bitrate"),
          flutter::EncodableValue(audio_track_info->bit_rate));

      trackSelections.push_back(flutter::EncodableValue(trackSelection));
    }

  } else if (type == PLAYER_STREAM_TYPE_TEXT) {
    LOG_INFO("[MediaPlayer] subtitle_count: %d", track_count);

    for (int sub_index = 0; sub_index < track_count; sub_index++) {
      player_subtitle_track_info_v2 *sub_track_info = nullptr;

      ret = ftpw_video_player_videohole_player_get_subtitle_track_info_v2(
          player_, sub_index, &sub_track_info);
      if (ret != PLAYER_ERROR_NONE) {
        LOG_ERROR("[MediaPlayer] player_get_subtitle_track_info_v2 failed: %s",
                  get_error_message(ret));
        return {};
      }
      LOG_INFO("[MediaPlayer] subtitle track info: language[%s]",
               sub_track_info->language);

      trackSelection.insert_or_assign(flutter::EncodableValue("trackId"),
                                      flutter::EncodableValue(sub_index));
      trackSelection.insert_or_assign(
          flutter::EncodableValue("language"),
          flutter::EncodableValue(std::string(sub_track_info->language)));

      trackSelections.push_back(flutter::EncodableValue(trackSelection));
    }
  }

  return trackSelections;
}

bool MediaPlayer::SetTrackSelection(int32_t track_id, std::string track_type) {
  LOG_INFO("[MediaPlayer] track_id: %d,track_type: %s", track_id,
           track_type.c_str());

  player_state_e state = PLAYER_STATE_NONE;
  int ret = player_get_state(player_, &state);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_state failed: %s",
              get_error_message(ret));
    return false;
  }
  if (state == PLAYER_STATE_NONE || state == PLAYER_STATE_IDLE) {
    LOG_ERROR("[MediaPlayer] Player not ready.");
    return false;
  }

  ret = player_select_track(player_, ConvertTrackType(track_type), track_id);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_select_track failed: %s",
              get_error_message(ret));
    return false;
  }

  return true;
}

bool MediaPlayer::SetDrm(const std::string &uri, int drm_type,
                         const std::string &license_server_url) {
  drm_manager_ = std::make_unique<DrmManager>();
  if (!drm_manager_->CreateDrmSession(drm_type, false)) {
    LOG_ERROR("[MediaPlayer] Failed to create drm session.");
    return false;
  }

  int drm_handle = 0;
  if (!drm_manager_->GetDrmHandle(&drm_handle)) {
    LOG_ERROR("[MediaPlayer] Failed to get drm handle.");
    return false;
  }

  int ret = ftpw_video_player_videohole_player_set_drm_handle(
      player_, PLAYER_DRM_TYPE_EME, drm_handle);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_drm_handle failed : %s.",
              get_error_message(ret));
    return false;
  }

  ret = ftpw_video_player_videohole_player_set_drm_init_complete_cb(
      player_, OnDrmSecurityInitComplete, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_drm_init_complete_cb failed : %s.",
              get_error_message(ret));
    return false;
  }

  ret = ftpw_video_player_videohole_player_set_drm_init_data_cb(
      player_, OnDrmUpdatePsshData, this);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_drm_init_data_cb failed : %s.",
              get_error_message(ret));
    return false;
  }

  if (license_server_url.empty()) {
    bool success = drm_manager_->SetChallenge(uri, binary_messenger_);
    if (!success) {
      LOG_ERROR("[MediaPlayer] Failed to set challenge.");
      return false;
    }
  } else {
    if (!drm_manager_->SetChallenge(uri, license_server_url)) {
      LOG_ERROR("[MediaPlayer] Failed to set challenge.");
      return false;
    }
  }
  return true;
}

bool MediaPlayer::StopAndDestroy() {
  LOG_INFO("[MediaPlayer] StopAndDestroy is called.");
  if (!player_) {
    LOG_ERROR("[MediaPlayer] Player not created.");
    return false;
  }

  bool success = true;
  is_buffering_ = false;
  on_seek_completed_ = nullptr;
  is_seeking_ = false;

  player_state_e player_state = PLAYER_STATE_NONE;
  int ret = player_get_state(player_, &player_state);
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_get_state failed: %s.",
              get_error_message(ret));
    success = false;
  }

  if (drm_manager_) {
    drm_manager_->StopDrmSession();
  }

  if (player_state == PLAYER_STATE_PLAYING ||
      player_state == PLAYER_STATE_PAUSED) {
    if (player_stop(player_) != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] Player fail to stop.");
      success = false;
    }
  }

  if (player_state != PLAYER_STATE_NONE && player_state != PLAYER_STATE_IDLE) {
    if (player_unprepare(player_) != PLAYER_ERROR_NONE) {
      LOG_ERROR("[MediaPlayer] Player fail to unprepare.");
      success = false;
    }
  }

  if (drm_manager_) {
    drm_manager_->ReleaseDrmSession();
    drm_manager_.reset();
  }

  if (player_destroy(player_) != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] Player fail to destroy.");
    success = false;
  }
  player_ = nullptr;

  return success;
}

bool MediaPlayer::Suspend() {
  LOG_INFO("[MediaPlayer] Suspend is called.");
  if (!player_) {
    LOG_ERROR("[MediaPlayer] Player not created.");
    return false;
  }

  player_state_e player_state = PLAYER_STATE_NONE;
  int res = player_get_state(player_, &player_state);
  if (res != PLAYER_ERROR_NONE || player_state == PLAYER_STATE_NONE) {
    LOG_ERROR("[MediaPlayer] Player get state failed or in invalid state[%d].",
              player_state);
    return false;
  }

  pre_state_ = player_state;
  pre_playing_time_ = GetPosition();
  if (pre_playing_time_ < 0) {
    LOG_ERROR("[MediaPlayer] Get position failed.");
    return false;
  }
  LOG_INFO(
      "[MediaPlayer] Saved current player state: %d, playing time: %llu ms",
      pre_state_, pre_playing_time_);

  if (IsLive()) {
    pre_playing_time_ = 0;
    if (!StopAndDestroy()) {
      LOG_ERROR("[MediaPlayer] Player is live, StopAndDestroy fail.");
      return false;
    }
    LOG_INFO("[MediaPlayer] Player is live: close done successfully.");
    return true;
  }

  if (ftpw_video_player_videohole_device_power_is_standby()) {
    LOG_INFO("[MediaPlayer] Power state is standby.");
    if (!StopAndDestroy()) {
      LOG_ERROR("[MediaPlayer] Player StopAndDestroy fail.");
      return false;
    }
    LOG_INFO("[MediaPlayer] Standby state: close done successfully.");
    return true;
  } else {
    LOG_INFO("[MediaPlayer] Power state is not standby.");
  }

  if (player_state == PLAYER_STATE_IDLE || player_state == PLAYER_STATE_READY) {
    if (!StopAndDestroy()) {
      LOG_ERROR("[MediaPlayer] Player StopAndDestroy fail.");
      return false;
    }
    LOG_INFO("[MediaPlayer] Player called in IDLE state, so stop the player.");
  } else if (player_state == PLAYER_STATE_PLAYING) {
    LOG_INFO("[MediaPlayer] Player calling pause from suspend.");
    if (!Pause()) {
      LOG_ERROR(
          "[MediaPlayer] Suspend fail, in restore player instance would be "
          "created newly.");
      if (!StopAndDestroy()) {
        LOG_ERROR("[MediaPlayer] Player StopAndDestroy fail.");
        return false;
      }
    }
  }

  return true;
}

bool MediaPlayer::Restore(const CreateMessage *restore_message,
                          int64_t resume_time) {
  LOG_INFO("[MediaPlayer] Restore is called.");
  return RestorePlayer(restore_message, resume_time);
}

bool MediaPlayer::RestorePlayer(const CreateMessage *restore_message,
                                int64_t resume_time) {
  LOG_INFO("[MediaPlayer] RestorePlayer is called.");

  if (player_ && !StopAndDestroy()) {
    LOG_ERROR("[MediaPlayer] RestorePlayer: StopAndDestroy failed.");
    return false;
  }
  LOG_INFO("[MediaPlayer] RestorePlayer: old player cleaned up.");

  if (restore_message->uri()) {
    LOG_INFO("[MediaPlayer] Updating source");
    url_ = *restore_message->uri();
    create_message_ = *restore_message;
  } else {
    if (restore_message->window_geometry()) {
      create_message_.set_window_geometry(*restore_message->window_geometry());
    }
  }

  LOG_INFO("[MediaPlayer] Player previous playing time: %llu ms",
           pre_playing_time_);
  LOG_INFO("[MediaPlayer] Player new resume time: %lld ms", resume_time);
  // resume_time < 0  ==> use previous playing time
  // resume_time == 0 ==> play from beginning
  // resume_time > 0  ==> play from resume_time(Third-party settings)
  if (resume_time >= 0) pre_playing_time_ = static_cast<uint64_t>(resume_time);

  is_restored_ = true;

  if (Create(url_, create_message_, true) < 0) {
    LOG_ERROR("[MediaPlayer] Fail to create player.");
    is_restored_ = false;
    return false;
  }

  LOG_INFO("[MediaPlayer] RestorePlayer: calling Prepare() after Create().");
  if (Prepare() < 0) {
    LOG_ERROR("[MediaPlayer] RestorePlayer: Prepare() failed.");
    is_restored_ = false;
    return false;
  }

  return true;
}

bool MediaPlayer::SetDisplayRotate(int64_t rotation) {
  LOG_INFO("[MediaPlayer] rotation: %lld", rotation);
  int ret = player_set_display_rotation(
      player_, static_cast<player_display_rotation_e>(rotation));
  if (ret != PLAYER_ERROR_NONE) {
    LOG_ERROR("[MediaPlayer] player_set_display_rotation failed: %s",
              get_error_message(ret));
    return false;
  }
  return true;
}

void MediaPlayer::OnRestoreCompleted() {
  if (pre_playing_time_ <= 0 || !SeekTo(pre_playing_time_, [this]() {
        if (pre_state_ == PLAYER_STATE_PLAYING) {
          LOG_INFO("[MediaPlayer] Restoring to PLAYING state after seek.");
          Play();
        }
        SendRestored();
      })) {
    if (pre_state_ == PLAYER_STATE_PLAYING) Play();
    SendRestored();
  }
}

void MediaPlayer::OnPrepared(void *user_data) {
  LOG_INFO("[MediaPlayer] Player prepared.");

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    LOG_DEBUG("[MediaPlayer] OnPrepared: player disposed, dropping callback");
    return;
  }

  if (self->is_restored_) {
    self->ResetEventDispatchState();
    LOG_INFO("[MediaPlayer] Event dispatch state reset for restored player.");
    self->OnRestoreCompleted();
  }

  if (!self->is_initialized_) {
    self->SendInitialized();
  }
}

void MediaPlayer::OnBuffering(int percent, void *user_data) {
  LOG_INFO("[MediaPlayer] Buffering percent: %d.", percent);

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    return;
  }

  if (percent == 100) {
    self->SendBufferingEnd();
    self->is_buffering_ = false;
  } else if (!self->is_buffering_ && percent <= 5) {
    self->SendBufferingStart();
    self->is_buffering_ = true;
  } else {
    self->SendBufferingUpdate(percent);
  }
}

void MediaPlayer::OnSeekCompleted(void *user_data) {
  LOG_INFO("[MediaPlayer] Seek completed.");

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    LOG_DEBUG(
        "[MediaPlayer] OnSeekCompleted: player disposed, dropping callback");
    return;
  }

  auto on_seek_completed = std::move(self->on_seek_completed_);
  self->on_seek_completed_ = nullptr;
  self->is_seeking_ = false;

  if (on_seek_completed) {
    on_seek_completed();
  }

  self->SendSeekCompleted();
}

void MediaPlayer::OnPlayCompleted(void *user_data) {
  LOG_INFO("[MediaPlayer] Play completed.");

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    LOG_DEBUG(
        "[MediaPlayer] OnPlayCompleted: player disposed, dropping callback");
    return;
  }

  self->SendPlayCompleted();
  self->Pause();
}

void MediaPlayer::OnInterrupted(player_interrupted_code_e code,
                                void *user_data) {
  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    LOG_DEBUG(
        "[MediaPlayer] OnInterrupted: player disposed, dropping callback");
    return;
  }

  self->SendIsPlayingState(false);
  LOG_ERROR("[MediaPlayer] Interrupt code: %d.", code);
}

void MediaPlayer::OnError(int error_code, void *user_data) {
  LOG_ERROR("An error occurred for media player, error: %d (%s).", error_code,
            get_error_message(error_code));

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    LOG_DEBUG("[MediaPlayer] OnError: player disposed, dropping callback");
    return;
  }

  self->SendError("Media Player error", get_error_message(error_code));
}

void MediaPlayer::OnSubtitleUpdated(unsigned long duration, char *text,
                                    void *user_data) {
  LOG_INFO("[MediaPlayer] Subtitle updated, duration: %ld, text: %s.", duration,
           text);

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);

  if (self->IsDisposed()) {
    LOG_DEBUG(
        "[MediaPlayer] OnSubtitleUpdated: player disposed, dropping callback");
    return;
  }

  self->SendSubtitleUpdate(duration, std::string(text));
}

bool MediaPlayer::OnDrmSecurityInitComplete(int *drm_handle,
                                            unsigned int length,
                                            unsigned char *pssh_data,
                                            void *user_data) {
  LOG_INFO("[MediaPlayer] Drm init completed.");

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);
  if (self->drm_manager_) {
    return self->drm_manager_->SecurityInitCompleteCB(drm_handle, length,
                                                      pssh_data, self->player_);
  }
  return false;
}

int MediaPlayer::OnDrmUpdatePsshData(drm_init_data_type init_type, void *data,
                                     int data_length, void *user_data) {
  LOG_INFO("[MediaPlayer] Drm update pssh data.");

  MediaPlayer *self = static_cast<MediaPlayer *>(user_data);
  if (self->drm_manager_) {
    return self->drm_manager_->UpdatePsshData(data, data_length);
  }
  return 0;
}

}  // namespace video_player_videohole_tizen
