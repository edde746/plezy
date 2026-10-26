// SPDX-FileCopyrightText: Copyright 2023 LG Electronics Inc.
// SPDX-License-Identifier: BSD-3-Clause

#ifndef VIDEO_PLAYER_H_
#define VIDEO_PLAYER_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar.h>
#include "plugin_player_delegate.h"
#include "webos_player.h"
#include "drm_manager.h"

#include <functional>
#include <memory>
#include <mutex>
#include <queue>
#include <string>

class DrmManager;
class VideoPlayerPlugin;

class VideoPlayer : public PluginPlayerDelegate {
public:
  static const int64_t ERROR_PLUGIN = -1;
  static const int64_t ERROR_WINID = -2;
  using DisposedCallback = std::function<void(int64_t)>;
  using ErrorCallback = std::function<void(int64_t)>;

  VideoPlayer(VideoPlayerPlugin* plugin,
        const bool visibility,
        const std::string& window_id,
        const std::string& uri,
        int drm_type,
        const std::string &license_server_url,
        bool use_license_callback,
        const std::string& hint);
  virtual ~VideoPlayer();

  int64_t GetTextureId() { return texture_id_; }
  void Unload();
  void Reload(const std::string& window_id);

  void Play();
  void Pause();
  void SetLooping(bool is_looping);
  void SetVolume(double volume);
  void SetPlaybackSpeed(double speed);
  void Seek(int64_t position);
  int64_t GetPosition();
  void SelectTrack(const std::string& type, int64_t index);
  void SetSubtitleEnable(bool enable);
  void SetSubtitleSync(int64_t offset);
  void Dispose(const DisposedCallback disposed_cb);

  void SetVisibility(bool visibility);
  bool IsPlaying() { return request_play_; }
  bool IsRemovedAtPlaying() { return removed_ && removed_at_playing_; }
  void OnPlayingStateChanged(bool playing);
  DrmManager* GetDrmManager() { return drm_manager_.get(); }
  WebOSPlayer* GetWebOSPlayer() { return &player_; }

// Call at WebOSPlayer.
  virtual void OnStateChanged(int state) override;
  virtual void OnInitialized() override;
  virtual void OnPlayCompleted() override;
  virtual void OnSeekCompleted() override;
  virtual void OnBufferingStart() override;
  virtual void OnBufferingEnd() override;
  virtual void OnBuffered(int64_t start, int64_t end) override;
  virtual void OnError(int64_t errCode,const std::string& errText) override;
  virtual void OnTrackSelected(const std::string& type, int index) override;

private:
  void SetUpEventChannel(flutter::BinaryMessenger *messenger);
  bool IsValidWindowId();
  void SetNetworkBuffering();
  void PushLoaded();
  void PushBufferingEnd();
  void PushDispose(int64_t timeout);
  void PushEvent(const flutter::EncodableValue& value);
  void FlushPendingEvents();
  bool SetDrm(const std::string &app_id, int drm_type,
              const std::string &license_server_url);

  VideoPlayerPlugin* plugin_ = nullptr;
  int64_t texture_id_;
  std::string window_id_;
  std::string app_id_;
  std::string uri_;
  int drm_type_;
  const std::string &license_server_url_;
  bool use_license_callback_ ;
  std::string hint_;

  bool request_play_ = false;
  bool looping_ = false;
  bool removed_ = false;
  bool removed_at_playing_ = false;
  bool reload_ = false;
  bool buffering_ = false;
  int64_t pending_error_code_ = 0;
  std::string pending_error_text_;
  WebOSPlayer player_;

  bool is_initialized_ = false;
  int64_t seek_position_ = 0;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  std::unique_ptr<DrmManager> drm_manager_;

  DisposedCallback disposed_cb_ = nullptr;
  GSource* dispose_timeout_source_ = nullptr;
  GSource* buffering_timeout_source_ = nullptr;
  GSource* load_timeout_source_ = nullptr;
  std::vector<flutter::EncodableValue> pending_events_;
};
#endif  // FLUTTER_PLUGIN_VIDEO_PLAYER_H_
