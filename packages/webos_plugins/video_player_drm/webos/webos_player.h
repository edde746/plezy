// SPDX-FileCopyrightText: Copyright 2023 LG Electronics Inc.
// SPDX-License-Identifier: BSD-3-Clause

#ifndef WEBOS_PLAYER_
#define WEBOS_PLAYER_

#include <atomic>
#include <mutex>
#include <variant>
#include <vector>
#include <string>
#include <glib.h>

class PluginPlayerDelegate;

class WebOSPlayer {
public:
  static const int UNLOADED = 0;
  static const int IN_LOADING = 1;
  static const int LOADED = 2;
  static const int PLAYING = 3;
  static const int PAUSED = 4;
  static const int EOS = 5;
  static const int REMOVED = 6;

  static constexpr int kMaxSlots = 5;

  typedef struct {
    std::string language;
    int trackId;
  } AudioTrackInfoCb;

  typedef struct {
    std::string language;
    int trackId;
  } SubtitleTrackInfoCb;

  // Public so drm_manager (and other future DRM helpers) can carry a
  // platform-neutral challenge payload across plugin boundaries without
  // depending on the underlying platform's DRM encrypted info struct.
  typedef struct {
    std::string systemId;
    std::string service;
    std::string key;
    std::string sessionId;
    std::string drmMsgType;
    std::string drmData;
    int32_t requestId;
  } DrmEncryptedCb;

  WebOSPlayer(PluginPlayerDelegate* delegate, const std::string& window_id);
  ~WebOSPlayer();

  // hint : MPEG-DASH, HLS, SW-AUDIO
  bool load(const std::string& appId,
          const std::string& winId,
          const std::string& uri,
          const std::string& licenseUrl = "",
          const std::string& drmType = "",
          bool use_license_callback = false,
          const std::string& hint = "",
          int64_t start_position = 0);
  bool unload(bool reset = false);
  bool play();
  bool pause();
  bool seek(int64_t position, bool update_position = false);
  bool setVolume(int32_t volume);
  bool setPlayRate(double playRate, bool audioOut);
  bool selectTrack(const std::string& type, int64_t trackIndex);
  bool setSubtitleEnable(bool enable);
  bool setSubtitleSync(int64_t offset);
  bool notifyVisibility(bool visibility);

  bool setDrmOperation(const std::string& systemId,
    const std::string& drmData,
    const std::string& drmMsgType,
    const std::string& service,
    const std::string& sessionId,
    int32_t requestId,
    const std::string& kid = "");

  int getState() { return state_; }
  int64_t getCurrentPosition() { return current_; }
  int64_t getDuration() { return duration_; }
  bool isSeekable() { return seekable_; }
  bool hasVideo() { return has_video_; }
  bool hasAudio() { return has_audio_; }
  int getVideoWidth() { return videoW_; }
  int getVideoHeight() { return videoH_; }
  const std::vector<AudioTrackInfoCb>& getAudioTracks() { return audio_tracks_; }
  const std::vector<SubtitleTrackInfoCb>& getSubtitleTracks() { return subtitle_tracks_; }
  std::string stateToString(int state);

  typedef int (*GMainLoopCallback)(void*);
  static GSource* attachToGMainLoop(GMainLoopCallback cb, void* data, int64_t delayed = 0);

private:
  enum MediaPipelineStatus {
    SMP_PLAYING_ERROR = 100,
    SMP_COMMAND_NOT_SUPPORTED = 101,
    SMP_NEED_TO_RELOAD_A_PIPELINE = 102,
    SMP_TAKE_SNAPSHOT_ERROR = 103,
    SMP_FAILED_TO_LOAD = 104,
    SMP_AUDIO_CODEC_NOT_SUPPORTED = 200,
    SMP_VIDEO_CODEC_NOT_SUPPORTED = 201,
    SMP_MEDIA_NOT_FOUND = 202,
    SMP_AV_TYPE_NOT_FOUNDED = 203,
    SMP_FAILED_TO_DEMULTIPLEX = 204,
    SMP_UNKNOWN_SUBTITLE = 210,
    SMP_NETWORK_ERROR = 300,
    SMP_UNSECURED_WIFI = 301,
    SMP_HLS_SERVER_ERROR_302 = 400,
    SMP_HLS_SERVER_ERROR_404 = 401,
    SMP_HLS_SERVER_ERROR_503 = 402,
    SMP_HLS_SERVER_ERROR_504 = 403,
    SMP_DRM_RELATED_ERROR = 500,
    SMP_DRM_INVALID_DRM_TYPE_ERROR = 506,
    SMP_RM_RELATED_ERROR = 600,
    SMP_RESOURCE_ALLOCATION_ERROR = 601,
    SMP_DVR_RESOURCE_ALLOCATION_ERROR = 602,
    SMP_SEEK_FAILURE = 700,
    SMP_SETPLAYRATE_FAILURE = 701,
    SMP_PIPELINE_DIED_ABNORMALLY = 1000,
    SMP_STREAMING_PROTOCOL_RELATED_ERROR = 40000,
    SMP_MEDIA_API_PLAYING_ERROR = 61440,
    SMP_BUFFER_FULL = 61441,
    SMP_BUFFER_LOW = 61442,
    SMP_RESOURCE_ACQUIRE_ERROR = 61456,
  };

  typedef struct {
    std::string appId;
    std::string winId;
    std::string uri;
    std::string licenseUrl;
    std::string drmType;
    bool use_license_callback;
    std::string hint;
    int64_t start_position;
  } LoadParams;

  enum BasicCbType {
    kTypeLoadCompleted,
    kTypePlaying,
    kTypePaused,
    kTypeSeekDone,
    kTypeBufferingStart,
    kTypeBufferingEnd,
    kTypeEndOfStream
  };

  typedef struct {
    enum BasicCbType type;
  } BasicCb;

  typedef struct {
    int64_t start;
    int64_t end;
  } BufferRangeCb;

  typedef struct {
    int64_t code;
    std::string text;
  } ErrorCb;

  typedef struct {
    bool seekable;
    int64_t duration;
    bool has_video;
    bool has_audio;
    int video_width;
    int video_height;
    std::vector<AudioTrackInfoCb> audio_tracks;
    std::vector<SubtitleTrackInfoCb> subtitle_tracks;
  } SourceInfoCb;

  typedef struct {
    std::string type;
    int index;
  } TrackSelectedCb;

  typedef std::variant<BasicCb,
                       BufferRangeCb,
                       ErrorCb,
                       SourceInfoCb,
                       TrackSelectedCb,
                       DrmEncryptedCb> CallbackVariant;

  // The underlying media API exposes a single callback with no user-data
  // parameter, so we route per-instance events through one static
  // trampoline per slot index, then look up the receiving instance from
  // s_slots_.
  static WebOSPlayer* s_slots_[kMaxSlots];
  static std::mutex s_slots_mutex_;
  static bool s_lib_initialized_;
  // Per-slot platform init is kept alive for the process lifetime so the dtor
  // can skip NDL_MediaQuit; a reused slot just re-subscribes. True once init +
  // NDL_MediaSubscribeEvents have been issued for the slot at least once.
  static bool s_slot_initialized_[kMaxSlots];
  // External windowId bound to each slot at its first NDL init. The platform
  // binds the windowId once per slot (init runs once for the process lifetime),
  // so this records it to detect a windowId mismatch when a slot is reused.
  static std::string s_slot_window_id_[kMaxSlots];

  static int allocateSlot(WebOSPlayer* self);
  static void releaseSlot(int slot);

  static void OnSlotEvent_0(char* event);
  static void OnSlotEvent_1(char* event);
  static void OnSlotEvent_2(char* event);
  static void OnSlotEvent_3(char* event);
  static void OnSlotEvent_4(char* event);

  static void dispatchEvent(int slot, char* event);
  void handleEvent(const std::string& event_json);

  void pushCallback(CallbackVariant cb);
  void popCallbacks();

  void execLoadCompleted();
  void execPlaying();
  void execPaused();
  void execSeekDone();
  void execBufferingStart();
  void execBufferingEnd();
  void execEndOfStream();
  void execBufferRange(int64_t start, int64_t end);
  void execError(int64_t code, const std::string& text);
  void execSourceInfo(const SourceInfoCb& info);
  void execTrackSelected(const std::string& type, int index);
  void execDrmEncrypted(const DrmEncryptedCb& info);

  PluginPlayerDelegate* delegate_;
  int slot_;
  bool visibility_;
  double speed_;
  double volume_;
  bool audio_out_;
  int state_;
  std::atomic<int64_t> current_;
  int64_t duration_;
  bool seekable_;
  bool has_video_;
  bool has_audio_;
  int videoW_;
  int videoH_;
  std::vector<AudioTrackInfoCb> audio_tracks_;
  std::vector<SubtitleTrackInfoCb> subtitle_tracks_;
  bool buffering_;
  int64_t buffering_start_;
  int64_t buffering_end_;
  LoadParams loadParams_;
  static GMainContext* s_main_context_;

  std::vector<CallbackVariant> callbacks_;
  std::recursive_mutex mutex_;
  bool run_ = true;
  GSource* idle_source_ = nullptr;
  GSource* timer_source_ = nullptr;
};
#endif  // WEBOS_PLAYER_
