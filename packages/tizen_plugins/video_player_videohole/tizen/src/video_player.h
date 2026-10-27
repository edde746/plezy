// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_PLUGIN_VIDEO_PLAYER_H_
#define FLUTTER_PLUGIN_VIDEO_PLAYER_H_

#include <dart_api_dl.h>
#include <flutter/encodable_value.h>
#include <flutter_tizen.h>
#include <glib.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <queue>
#include <string>
#include <utility>

#include "ffi_messages.h"

namespace video_player_videohole_tizen {

void RegisterDartPort(int64_t dart_port);
void UnregisterDartPort();

void PostEventToDart(int64_t player_id, const std::string &event_json);

class VideoPlayer {
 public:
  using SeekCompletedCallback = std::function<void()>;

  explicit VideoPlayer(flutter::BinaryMessenger *messenger,
                       FlutterDesktopViewRef flutter_view);
  VideoPlayer(const VideoPlayer &) = delete;
  VideoPlayer &operator=(const VideoPlayer &) = delete;
  virtual ~VideoPlayer();

  virtual int64_t Create(const std::string &uri,
                         const CreateMessage &create_message,
                         bool reuse_existing_id = false) = 0;
  virtual int Prepare() = 0;
  virtual void Dispose() = 0;

  virtual void SetDisplayRoi(int32_t x, int32_t y, int32_t width,
                             int32_t height) = 0;
  virtual bool Play() = 0;
  virtual bool Deactivate() { return false; };
  virtual bool Activate() { return false; };
  virtual bool Pause() = 0;
  virtual bool SetLooping(bool is_looping) = 0;
  virtual bool SetVolume(double volume) = 0;
  virtual bool SetPlaybackSpeed(double speed) = 0;
  virtual bool SeekTo(int64_t position, SeekCompletedCallback callback) = 0;
  virtual int64_t GetPosition() = 0;
  virtual std::pair<int64_t, int64_t> GetDuration() = 0;
  virtual bool IsReady() = 0;
  virtual flutter::EncodableList GetTrackInfo(std::string track_type) = 0;
  virtual bool SetTrackSelection(int32_t track_id, std::string track_type) = 0;
  virtual bool Suspend() = 0;
  virtual bool Restore(const CreateMessage *restore_message,
                       int64_t resume_time) = 0;
  virtual bool SetDisplayRotate(int64_t rotation) = 0;

 protected:
  virtual void GetVideoSize(int32_t *width, int32_t *height) = 0;
  void *GetWindowHandle();
  void SendInitialized();
  void SendBufferingStart();
  void SendBufferingUpdate(int32_t value);
  void SendBufferingEnd();
  void SendSeekCompleted();
  void SendSubtitleUpdate(int32_t duration, const std::string &text);
  void SendPlayCompleted();
  void SendIsPlayingState(bool is_playing);
  void SendRestored();
  void SendError(const std::string &error_code,
                 const std::string &error_message);
  void ResetEventDispatchState();
  bool IsDisposed() const;
  void MarkDisposed();

  int64_t player_id_;
  std::mutex queue_mutex_;
  flutter::BinaryMessenger *binary_messenger_;
  bool is_initialized_ = false;
  FlutterDesktopViewRef flutter_view_;
  bool is_restored_ = false;

 private:
  struct GMainContextDeleter {
    void operator()(GMainContext *context) const {
      g_main_context_unref(context);
    }
  };

  struct EventDispatchState {
    std::mutex mutex;
    VideoPlayer *player = nullptr;
    bool disposed = false;
    guint pending_source_id = 0;
  };

  std::shared_ptr<EventDispatchState> event_dispatch_state_;
  std::unique_ptr<GMainContext, GMainContextDeleter> main_context_;

  void ExecuteSinkEvents();
  void ScheduleSendPendingEvents();
  void PushEvent(flutter::EncodableValue encodable_value);

  std::queue<flutter::EncodableValue> encodable_event_queue_;
  std::queue<std::pair<std::string, std::string>> error_event_queue_;
};

}  // namespace video_player_videohole_tizen

namespace flutter_common {

template <typename T>
inline const T GetValue(const flutter::EncodableMap *map,
                        const std::string &key, T &&default_value) {
  if (map == nullptr || map->empty()) {
    return std::move(default_value);
  }

  auto it = map->find(flutter::EncodableValue(key));
  if (it != map->end() && std::holds_alternative<T>(it->second)) {
    return std::get<T>(it->second);
  }
  return std::move(default_value);
}

}  // namespace flutter_common

#endif  // FLUTTER_PLUGIN_VIDEO_PLAYER_H_
