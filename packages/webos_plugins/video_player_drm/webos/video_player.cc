// SPDX-FileCopyrightText: Copyright 2023 LG Electronics Inc.
// SPDX-License-Identifier: BSD-3-Clause

#include "video_player_plugin.h"
#include "video_player.h"
#include "log.h"
#include "drm_manager.h"
#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>

#ifdef TAG
#undef TAG
#endif
#define TAG "VideoPlayer::"

VideoPlayer::VideoPlayer(VideoPlayerPlugin* plugin,
        const bool visibility,
        const std::string& window_id,
        const std::string& uri,
        int drm_type,
        const std::string &license_server_url,
        bool use_license_callback,
        const std::string& hint)
    : plugin_(plugin)
    , window_id_(window_id)
    , uri_(uri)
    , drm_type_(drm_type)
    , license_server_url_(license_server_url)
    , use_license_callback_(use_license_callback)
    , hint_(hint)
    , player_(this, window_id) {
  SetVisibility(visibility);
  app_id_ = ::getenv("FLUTTER_APP_ID");

  static int64_t s_texture_id = 0;
  ++s_texture_id;
  if (s_texture_id < 0) {
    s_texture_id = 1;
  }
  texture_id_ = s_texture_id;
  SetUpEventChannel(plugin_->PluginRegistrar()->messenger());

  if (IsValidWindowId()) {
    if (!SetDrm(app_id_, drm_type_, license_server_url_))
    {
      LogInfo(TAG) << "no drm info";
    }
    SetNetworkBuffering();
    player_.load(app_id_, window_id_, uri_,
                 drm_type_ != 0 ? drm_manager_->getLicenseUrl() : "",
                 drm_type_ != 0 ? drm_manager_->getDrmType() : "",
                 use_license_callback_,
                 hint_);
  } else {
    OnError(ERROR_WINID, "invalid windowId");
  }
  // The media URI may contain a local proxy capability or server credentials.
  // Never write it to the device log.
  LogInfo(TAG) << "Created(" << texture_id_ << ", network source redacted)";
}

VideoPlayer::~VideoPlayer() {
  LogInfo(TAG) << "Destroyed(" << texture_id_ << ")";
  if (buffering_timeout_source_) {
    g_source_destroy(buffering_timeout_source_);
    buffering_timeout_source_ = nullptr;
  }
  if (dispose_timeout_source_) {
    g_source_destroy(dispose_timeout_source_);
    dispose_timeout_source_ = nullptr;
  }
  if (load_timeout_source_) {
    g_source_destroy(load_timeout_source_);
    load_timeout_source_ = nullptr;
  }
  Unload();
}

void VideoPlayer::Unload() {
  LogInfo(TAG) << "Unload(" << texture_id_ << ", " << window_id_ << ")";
  removed_ = true;
  removed_at_playing_ = false;
  reload_ = false;
  buffering_ = false;
  seek_position_ = player_.getCurrentPosition();
  window_id_.clear();

  player_.unload();
}

void VideoPlayer::Reload(const std::string& window_id) {
  LogInfo(TAG) << "Reload(" << texture_id_ << ", " << window_id << ")";
  if (removed_at_playing_) {
    OnPlayingStateChanged(request_play_);
  }
  removed_ = false;
  removed_at_playing_ = false;
  reload_ = true;
  window_id_ = window_id;

  if (IsValidWindowId()) {
    if (!SetDrm(app_id_, drm_type_, license_server_url_))
    {
      LogInfo(TAG) << "no drm info";
    }
    SetNetworkBuffering();
    player_.load(app_id_, window_id_, uri_,
                 drm_type_ != 0 ? drm_manager_->getLicenseUrl() : "",
                 drm_type_ != 0 ? drm_manager_->getDrmType() : "",
                 use_license_callback_,
                 hint_, seek_position_);
  } else {
    OnError(ERROR_WINID, "invalid windowId");
  }
}

void VideoPlayer::Play() {
  request_play_ = true;
  if (uri_.empty()) {
    return;
  }
  if (reload_ || !IsValidWindowId()) {
    return;
  }
  if (removed_) {
    Reload(window_id_);
  } else {
    player_.play();
  }
}

void VideoPlayer::Pause() {
  request_play_ = false;
  if (uri_.empty()) {
    return;
  }
  if (removed_ || reload_ || !IsValidWindowId()) {
    return;
  }

  player_.pause();
}

void VideoPlayer::SetLooping(bool is_looping) {
  looping_ = is_looping;
}

void VideoPlayer::SetVolume(double volume) {
  player_.setVolume(volume*100);
}

void VideoPlayer::SetPlaybackSpeed(double speed) {
  player_.setPlayRate(speed,true);
}

void VideoPlayer::SelectTrack(const std::string& type, int64_t index) {
  player_.selectTrack(type, index);
}

void VideoPlayer::SetSubtitleEnable(bool enable) {
  player_.setSubtitleEnable(enable);
}

void VideoPlayer::SetSubtitleSync(int64_t offset) {
  player_.setSubtitleSync(offset);
}

void VideoPlayer::Seek(int64_t position) {
  if (!player_.isSeekable()) {
    return;
  }

  if (reload_ || removed_ || position == player_.getCurrentPosition()) {
    seek_position_ = position;
  } else if (player_.seek(position, true)) {
    seek_position_ = position;
  }
}

int64_t VideoPlayer::GetPosition() {
  int64_t position = player_.getCurrentPosition();
  return std::max(seek_position_, position);
}

void VideoPlayer::Dispose(const DisposedCallback disposed_cb) {
  disposed_cb_ = disposed_cb;
  is_initialized_ = false;
  event_sink_ = nullptr;
  event_channel_->SetStreamHandler(nullptr);

  int64_t timeout = (player_.getState() ==
                     WebOSPlayer::UNLOADED) ? 0 : 500;
  PushDispose(timeout);
  Unload();
}

void VideoPlayer::SetUpEventChannel(flutter::BinaryMessenger *messenger) {
  std::string name =
      "flutter.io/videoPlayer/videoEvents" + std::to_string(texture_id_);
  auto channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, name, &flutter::StandardMethodCodec::GetInstance());
  // SetStreamHandler be called after player_prepare,
  // because initialized event will be send in listen function of event channel
  auto handler = std::make_unique<
      flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [&](const flutter::EncodableValue *arguments,
          std::unique_ptr<flutter::EventSink<>> &&events)
          -> std::unique_ptr<flutter::StreamHandlerError<>> {
        event_sink_ = std::move(events);
        FlushPendingEvents();
        return nullptr;
      },
      [&](const flutter::EncodableValue *arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<>> {
        event_sink_ = nullptr;
        return nullptr;
      });
  channel->SetStreamHandler(std::move(handler));

  event_channel_ = std::move(channel);
}

bool VideoPlayer::IsValidWindowId() {
  if (window_id_.empty()) {
    return false;
  }
  if (window_id_ == "invalid") {
    return false;
  }
  return true;
}

void VideoPlayer::SetNetworkBuffering() {
  if (uri_.find("file:///") != 0) {
    OnBufferingStart();
  }
}

void VideoPlayer::SetVisibility(bool visibility) {
  player_.notifyVisibility(visibility);
}

void VideoPlayer::OnPlayingStateChanged(bool playing) {
  LogDebug(TAG) << "OnPlayingStateChanged(" << texture_id_
                << ", " << playing
                << ")";

  flutter::EncodableMap result = {{flutter::EncodableValue("event"),
                                   flutter::EncodableValue("isPlayingStateUpdate")},
                                   {flutter::EncodableValue("isPlaying"),
                                   flutter::EncodableValue(playing)}};
  PushEvent(flutter::EncodableValue(result));
}

void VideoPlayer::OnStateChanged(int state) {
  if (disposed_cb_) {
    if (state == WebOSPlayer::UNLOADED) {
      LogInfo(TAG) << "media pipeline unloaded("
                   << texture_id_ << ") !!!";
      if (dispose_timeout_source_) {
        g_source_destroy(dispose_timeout_source_);
        dispose_timeout_source_ = nullptr;
      }
      disposed_cb_(texture_id_);
    }
    return;
  }

  LogInfo(TAG) << "OnStateChanged("
                   << texture_id_
                   << "," << player_.stateToString(state) << ")";
  switch (state) {
    case WebOSPlayer::LOADED:
      reload_ = false;
      if (request_play_) {
        player_.play();
      }
      if (!buffering_) {
        PushLoaded();
      }
      break;

    case WebOSPlayer::REMOVED:
      removed_ = true;
      removed_at_playing_ = request_play_;
      reload_ = false;
      buffering_ = false;
      seek_position_ = player_.getCurrentPosition();

      if (request_play_) {
        request_play_ = false;
        OnPlayingStateChanged(false);
      }
      player_.unload();

      if (plugin_->IsTopAndResumed(texture_id_) &&
          removed_at_playing_) {
        Play();
      }
      break;

    case WebOSPlayer::UNLOADED:
      {
      flutter::EncodableMap result = {
        {flutter::EncodableValue("event"),
         flutter::EncodableValue("onUnloaded")}};
      PushEvent(flutter::EncodableValue(result));
      }
      break;

    default:
      break;
  }
}

void VideoPlayer::OnInitialized() {
  if (buffering_) {
    buffering_ = false;
    PushBufferingEnd();
  }

  if (!is_initialized_) {
    is_initialized_ = true;

    int64_t duration = player_.getDuration();
    int width = player_.getVideoWidth();
    int height = player_.getVideoHeight();
    LogInfo(TAG) << "OnInitialized(" << texture_id_
        << ",duration:" << duration
        << ",video width:" << width
        << ",height:" << height << ")";

    flutter::EncodableList audio_tracks;
    for (const auto& track : player_.getAudioTracks()) {
      flutter::EncodableMap t = {
        {flutter::EncodableValue("language"), flutter::EncodableValue(track.language)},
        {flutter::EncodableValue("trackId"),  flutter::EncodableValue(track.trackId)},
      };
      audio_tracks.push_back(flutter::EncodableValue(t));
    }

    flutter::EncodableList subtitle_tracks;
    for (const auto& track : player_.getSubtitleTracks()) {
      flutter::EncodableMap t = {
        {flutter::EncodableValue("language"), flutter::EncodableValue(track.language)},
        {flutter::EncodableValue("trackId"),  flutter::EncodableValue(track.trackId)},
      };
      subtitle_tracks.push_back(flutter::EncodableValue(t));
    }

    flutter::EncodableMap result = {
        {flutter::EncodableValue("event"),
         flutter::EncodableValue("initialized")},
        {flutter::EncodableValue("duration"),
         flutter::EncodableValue(duration)},
        {flutter::EncodableValue("width"), flutter::EncodableValue(width)},
        {flutter::EncodableValue("height"), flutter::EncodableValue(height)},
        {flutter::EncodableValue("audioTracks"),
         flutter::EncodableValue(audio_tracks)},
        {flutter::EncodableValue("subtitleTracks"),
         flutter::EncodableValue(subtitle_tracks)}};
    PushEvent(flutter::EncodableValue(result));
  }
}

void VideoPlayer::OnPlayCompleted() {
  if (looping_) {
    if (!removed_ && !reload_ && looping_) {
      player_.seek(0,true);
      if (request_play_) {
        Play();
      }
    }
    return;
  }

  LogInfo(TAG) << "OnPlayeCompleted(" << texture_id_ << ")";
  request_play_ = false;
  flutter::EncodableMap result = {{flutter::EncodableValue("event"),
                                   flutter::EncodableValue("completed")}};
  PushEvent(flutter::EncodableValue(result));
}

void VideoPlayer::OnSeekCompleted() {
}

void VideoPlayer::OnBufferingStart() {
  LogInfo(TAG) << "OnBufferingStart(" << texture_id_ << ")";
  buffering_ = true;
  flutter::EncodableMap result = {{flutter::EncodableValue("event"),
                                   flutter::EncodableValue("bufferingStart")}};
  PushEvent(flutter::EncodableValue(result));
}

void VideoPlayer::OnBufferingEnd() {
  LogInfo(TAG) << "OnBufferingEnd(" << texture_id_ << ")";
  buffering_ = false;
  flutter::EncodableMap result = {{flutter::EncodableValue("event"),
                                   flutter::EncodableValue("bufferingEnd")}};
  PushEvent(flutter::EncodableValue(result));

  PushLoaded();
}

void VideoPlayer::OnBuffered(int64_t start, int64_t end) {
  LogDebug(TAG) << "OnBuffered(" << texture_id_
                << ", [" << start
                << ", " << end
                << "])";

  std::vector<int64_t> lst;
  lst.push_back(start);
  lst.push_back(end);
  flutter::EncodableList emit_list;
  emit_list.push_back(flutter::EncodableValue(lst));
  flutter::EncodableMap result = {{flutter::EncodableValue("event"),
                                   flutter::EncodableValue("bufferingUpdate")},
                                  {flutter::EncodableValue("values"),
                                   flutter::EncodableValue(emit_list)}};
  PushEvent(flutter::EncodableValue(result));
}

void VideoPlayer::OnTrackSelected(const std::string& type, int index) {
  LogInfo(TAG) << "OnTrackSelected(" << texture_id_
      << ", type=" << type
      << ", index=" << index << ")";

  flutter::EncodableMap result = {
    {flutter::EncodableValue("event"),
     flutter::EncodableValue("trackSelected")},
    {flutter::EncodableValue("trackType"),
     flutter::EncodableValue(type)},
    {flutter::EncodableValue("trackIndex"),
     flutter::EncodableValue(index)}};
  PushEvent(flutter::EncodableValue(result));
}

void VideoPlayer::OnError(int64_t errorCode,const std::string& errorText) {
  LogError(TAG) << "OnError(" << texture_id_
      << "," << errorCode
      << "," << errorText << ")";

  // To release this
  plugin_->OnVideoPlayerError(texture_id_);

  if (event_sink_ == nullptr) {
    pending_error_code_ = errorCode;
    pending_error_text_ = errorText;
    return;
  }
  pending_error_code_ = 0;
  pending_error_text_.clear();

  // for Dart videoController.Dispose()
  if (!is_initialized_) {
    is_initialized_ = true;
    flutter::EncodableMap result = {
        {flutter::EncodableValue("event"),
         flutter::EncodableValue("initialized")},
        {flutter::EncodableValue("duration"),
         flutter::EncodableValue(0)},
        {flutter::EncodableValue("width"), flutter::EncodableValue(0)},
        {flutter::EncodableValue("height"), flutter::EncodableValue(0)}};
    event_sink_->Success(flutter::EncodableValue(result));
  }

  // To release resouces.
  flutter::EncodableMap result = {
      {flutter::EncodableValue("event"), flutter::EncodableValue("onError")}
  };
  event_sink_->Success(flutter::EncodableValue(result));

  // errText pass to _controller.value.errorDescription for a application
  std::string errCode = std::to_string(errorCode);
  std::string errText = errCode + " " + errorText;
  event_sink_->Error(errCode, errText, flutter::EncodableValue(errText));
}

void VideoPlayer::PushLoaded() {
  if (load_timeout_source_) {
    g_source_destroy(load_timeout_source_);
  }

  load_timeout_source_ = player_.attachToGMainLoop([](void* data) -> int {
    VideoPlayer* self = (VideoPlayer*)data;
    self->load_timeout_source_ = nullptr;
    if (!self->removed_ && !self->reload_) {
      flutter::EncodableMap result = {
        {flutter::EncodableValue("event"),
         flutter::EncodableValue("onLoaded")}};
      self->PushEvent(flutter::EncodableValue(result));
    }
    return G_SOURCE_REMOVE;
  }, this, 50);
}

void VideoPlayer::PushBufferingEnd() {
  if (buffering_timeout_source_) {
    g_source_destroy(buffering_timeout_source_);
  }

  buffering_timeout_source_ = player_.attachToGMainLoop([](void* data) -> int {
    VideoPlayer* self = (VideoPlayer*)data;
    self->buffering_timeout_source_ = nullptr;
    if (!self->buffering_) {
      self->OnBufferingEnd();
    }
    return G_SOURCE_REMOVE;
  }, this, 10);
}

void VideoPlayer::PushDispose(int64_t timeout) {
  if (dispose_timeout_source_) {
    g_source_destroy(dispose_timeout_source_);
  }

  dispose_timeout_source_ = player_.attachToGMainLoop([](void* data) -> int {
    LogError(TAG) << "Dispose timeout.. forced_dispose..";
    VideoPlayer* self = (VideoPlayer*)data;
    self->dispose_timeout_source_ = nullptr;
    self->disposed_cb_(self->texture_id_);
    return G_SOURCE_REMOVE;
  }, this, timeout);
}

void VideoPlayer::PushEvent(const flutter::EncodableValue& value) {
  if (event_sink_) {
    event_sink_->Success(value);
  } else {
    pending_events_.push_back(value);
  }
}

void VideoPlayer::FlushPendingEvents() {
  if (event_sink_) {
    for (auto& value : pending_events_) {
      event_sink_->Success(value);
    }
    pending_events_.clear();

    if (pending_error_code_) {
      OnError(pending_error_code_, std::string(pending_error_text_));
    }
  }
}

bool VideoPlayer::SetDrm(const std::string &app_id, int drm_type,
                         const std::string &license_server_url)
{
  if (drm_type == 0) return false;

  drm_manager_ = std::make_unique<DrmManager>(app_id, license_server_url, drm_type, plugin_->PluginRegistrar()->messenger(), &player_);
  return true;
}
