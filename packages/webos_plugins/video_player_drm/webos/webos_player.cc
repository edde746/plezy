// SPDX-FileCopyrightText: Copyright 2023 LG Electronics Inc.
// SPDX-License-Identifier: BSD-3-Clause

#include <pbnjson.hpp>
#include <NDL/NDL_media.h>

#include "webos_player.h"
#include "plugin_player_delegate.h"
#include "log.h"
#include "video_player.h"
#include <glib.h>
#ifdef TAG
#undef TAG
#endif
#define TAG "WebOSPlayer::"

/******************************************************/
/*                 Simple Json writer                 */
/******************************************************/
class JsonWriter {
public:
  JsonWriter() {}
  ~JsonWriter() {}

  void StartObject() {
    if (!start_) {
      string_buf_ += ",";
    }
    string_buf_ += "{";
    start_ = true;
  }

  void Key(const std::string& key) {
    if (!start_) {
      string_buf_ += ",";
    }
    string_buf_ += "\"" + key + "\":";
    start_ = true;
  }

  void String(const std::string& value) {
    if (!start_) {
      string_buf_ += ",";
    }
    string_buf_ += "\"" + value + "\"";
    start_ = false;
  }

  void Bool(bool set) {
    if (!start_) {
      string_buf_ += ",";
    }
    string_buf_ += set ? "true" : "false";
    start_ = false;
  }

  void Int64(int64_t start_position) {
    if (!start_) {
      string_buf_ += ",";
    }
    string_buf_ += std::to_string(start_position);
    start_ = false;
  }

  void EndObject() {
    string_buf_ += "}";
  }

  std::string GetString() {
    return string_buf_;
  }

private:
  std::string string_buf_;
  bool start_ = true;
};

/******************************************************/
/*                 Static state                       */
/******************************************************/
GMainContext* WebOSPlayer::s_main_context_ = nullptr;
WebOSPlayer* WebOSPlayer::s_slots_[WebOSPlayer::kMaxSlots] = { nullptr };
std::mutex WebOSPlayer::s_slots_mutex_;
bool WebOSPlayer::s_lib_initialized_ = false;
bool WebOSPlayer::s_slot_initialized_[WebOSPlayer::kMaxSlots] = { false };
std::string WebOSPlayer::s_slot_window_id_[WebOSPlayer::kMaxSlots];

int WebOSPlayer::allocateSlot(WebOSPlayer* self) {
  std::lock_guard<std::mutex> lock(s_slots_mutex_);
  for (int i = 0; i < kMaxSlots; ++i) {
    if (s_slots_[i] == nullptr) {
      s_slots_[i] = self;
      return i;
    }
  }
  return -1;
}

void WebOSPlayer::releaseSlot(int slot) {
  std::lock_guard<std::mutex> lock(s_slots_mutex_);
  if (slot >= 0 && slot < kMaxSlots) {
    s_slots_[slot] = nullptr;
  }
}

void WebOSPlayer::OnSlotEvent_0(char* event) { dispatchEvent(0, event); }
void WebOSPlayer::OnSlotEvent_1(char* event) { dispatchEvent(1, event); }
void WebOSPlayer::OnSlotEvent_2(char* event) { dispatchEvent(2, event); }
void WebOSPlayer::OnSlotEvent_3(char* event) { dispatchEvent(3, event); }
void WebOSPlayer::OnSlotEvent_4(char* event) { dispatchEvent(4, event); }

// Holds the slot-table mutex for the duration of the dispatch so the
// instance cannot be torn down underneath us.
void WebOSPlayer::dispatchEvent(int slot, char* event) {
  std::lock_guard<std::mutex> lock(s_slots_mutex_);
  if (slot < 0 || slot >= kMaxSlots) {
    return;
  }
  WebOSPlayer* self = s_slots_[slot];
  if (self == nullptr) {
    return;
  }
  if (event == nullptr) {
    return;
  }
  self->handleEvent(std::string(event));
}

/******************************************************/
/*                 WebOS Player                       */
/******************************************************/
WebOSPlayer::WebOSPlayer(PluginPlayerDelegate* delegate, const std::string& window_id)
    : delegate_(delegate)
    , slot_(-1)
    , visibility_(false)
    , speed_(1.0)
    , volume_(100)
    , audio_out_(true)
    , state_(UNLOADED)
    , current_(0)
    , duration_(0)
    , seekable_(false)
    , has_video_(false)
    , has_audio_(false)
    , videoW_(0)
    , videoH_(0)
    , buffering_(false)
    , buffering_start_(0)
    , buffering_end_(0) {
  if (s_main_context_ == nullptr) {
    s_main_context_ = g_main_context_ref_thread_default();
  }

  slot_ = allocateSlot(this);
  if (slot_ < 0) {
    LogError(TAG) << "no free slot (limit=" << kMaxSlots << ")";
    return;
  }

  if (NDL_MediaSetPlayer(slot_) != 0) {
    LogError(TAG) << "NDL_MediaSetPlayer(" << slot_ << ") failed";
    releaseSlot(slot_);
    slot_ = -1;
    return;
  }

  static void (*trampolines[kMaxSlots])(char*) = {
    OnSlotEvent_0, OnSlotEvent_1, OnSlotEvent_2, OnSlotEvent_3, OnSlotEvent_4
  };

  if (!s_slot_initialized_[slot_]) {
    // Bind the caller's (Flutter) external windowId at init so the platform
    // renders the video plane onto the app's own surface. The windowId is
    // bound once per slot at init; an empty windowId uses the default behavior.
    if (NDL_MediaInitWithWindowId(
            0, window_id.empty() ? nullptr : window_id.c_str()) != 0) {
      LogError(TAG) << "NDL_MediaInitWithWindowId(" << slot_ << ") failed";
      releaseSlot(slot_);
      slot_ = -1;
      return;
    }
    if (NDL_MediaSubscribeEvents(trampolines[slot_]) != 0) {
      LogError(TAG) << "NDL_MediaSubscribeEvents(" << slot_ << ") failed";
    }
    s_slot_initialized_[slot_] = true;
    s_slot_window_id_[slot_] = window_id;
    LogInfo(TAG) << "slot[" << slot_ << "] init complete (windowId=" << window_id << ")";
  } else {
    // The previous instance on this slot dropped its event subscription in its
    // dtor; re-subscribe the trampoline here. Per-slot init is kept alive for
    // the process lifetime on purpose.
    if (NDL_MediaSubscribeEvents(trampolines[slot_]) != 0) {
      LogWarn(TAG) << "NDL_MediaSubscribeEvents(" << slot_
                   << ") re-subscribe failed (likely already subscribed)";
    }
    // The windowId is bound once per slot at init and is not rebound on reuse,
    // so a reused slot keeps its original windowId. This is benign: video
    // position/size is driven by the exported window (webos/exported_windows)
    // and the sink's payload windowId, not by this binding, so playback/display
    // stays correct on reuse. Logged at INFO only as a diagnostic.
    if (s_slot_window_id_[slot_] != window_id) {
      LogInfo(TAG) << "slot[" << slot_ << "] windowId differs on reuse: bound="
                   << s_slot_window_id_[slot_] << " requested=" << window_id
                   << " (platform keeps original; display handled by exported window)";
    }
    // Safety net: drop any leftover pipeline state from the previous user
    // of this slot. Owner-driven dispose normally calls unload() first,
    // but this guards the edge case where it did not.
    NDL_MediaUnload();
  }
}

WebOSPlayer::~WebOSPlayer() {
  if (slot_ >= 0) {
    if (NDL_MediaSetPlayer(slot_) == 0) {
      // Drop the platform event subscription so the callback thread cannot
      // dispatch into a freshly-destroyed instance.
      NDL_MediaUnsubscribeEvents();
      // Unload is skipped: VideoPlayer::Dispose already drove the pipeline to
      // UNLOADED via player_.unload() before releasing this instance.
      // Per-slot platform init is kept alive for the process lifetime and is
      // reused by the next player on this slot, so it is not torn down here.
    }
    releaseSlot(slot_);
  }
  std::lock_guard<std::recursive_mutex> autoLock(mutex_);
  run_ = false;
  if (idle_source_) {
    g_source_destroy(idle_source_);
    idle_source_ = nullptr;
  }
  if (timer_source_) {
    g_source_destroy(timer_source_);
    timer_source_ = nullptr;
  }
  callbacks_.clear();
}

bool WebOSPlayer::load(const std::string& appId,
        const std::string& winId,
        const std::string& uri,
        const std::string& licenseUrl,
        const std::string& drmType,
        const bool use_license_callback,
        const std::string& hint,
        int64_t start_position) {
  loadParams_.appId = appId;
  loadParams_.winId = winId;
  loadParams_.uri = uri;
  loadParams_.licenseUrl = licenseUrl;
  loadParams_.drmType = drmType;
  loadParams_.use_license_callback = use_license_callback;
  loadParams_.hint = hint;
  loadParams_.start_position = start_position;

  if (state_ != UNLOADED) {
    LogWarn(TAG) <<"currentState is" << stateToString(state_) << ", I will unload pipeline";
    unload(true);
  }
  if (start_position != 0) {
    LogInfo(TAG) <<"load(sartPosition:" << start_position << ")";
  }
  current_ = start_position;

  std::string payload;
  bool is_payload = false;

  pbnjson::JValue doc = pbnjson::JDomParser::fromString(hint);
  if (doc.isObject()) {
    pbnjson::JGenerator serializer(nullptr);
    std::string serialized;
    if (serializer.toString(doc, pbnjson::JSchema::AllSchema(), serialized)) {
      std::string option_header = "\"option\":{";
      auto option_start = serialized.find(option_header);
      if (option_start != std::string::npos) {
        is_payload = true;

        JsonWriter writer;
        if (!doc["option"]["appId"].isString()) {
          writer.Key("appId");
          writer.String(appId);
        }
        if (!winId.empty()) {
          writer.Key("windowId");
          writer.String(winId);
        }
        if (start_position > 0 &&
            !doc["option"]["transmission"].isObject()) {
          writer.Key("transmission");
          writer.StartObject();
            writer.Key("playTime");
            writer.StartObject();
              writer.Key("start");
              writer.Int64(start_position);
            writer.EndObject();
          writer.EndObject();
        }
        std::string tmp = writer.GetString();
        if (!tmp.empty()) {
          tmp += ",";
        }
        payload = serialized;
        payload.insert(option_start + option_header.size(), tmp);
      }
    }
  }

  if (!is_payload) {
    JsonWriter writer;
    writer.StartObject();
      std::string media_transport_type;
      if (hint.find("MPEG-DASH") != std::string::npos) {
        media_transport_type = "MPEG-DASH";
      } else if (hint.find("HLS") != std::string::npos) {
        media_transport_type = "HLS";
      } else if (hint.find("MSIIS") != std::string::npos) {
        media_transport_type = "MSIIS";
      } else if (uri.find("m3u8") != std::string::npos) {
        media_transport_type = "HLS";
      } else if (uri.find("udp://") != std::string::npos) {
        media_transport_type = "UDP";
      } else if (uri.find("rtp://") != std::string::npos) {
        media_transport_type = "RTP";
      } else if (uri.find("rtsp://") != std::string::npos) {
        media_transport_type = "RTSP";
      }
      if (!media_transport_type.empty()) {
        writer.Key("mediaTransportType");
        writer.String(media_transport_type);
      }

      writer.Key("option");
      writer.StartObject();
        writer.Key("appId");
        writer.String(appId);
        if (hint.find("lowDelayMode") != std::string::npos) {
          writer.Key("lowDelayMode");
          writer.Bool(true);
        }
        if (!winId.empty()) {
          writer.Key("windowId");
          writer.String(winId);
        }
        if (!drmType.empty()) {
          writer.Key("drm");
          writer.StartObject();
          writer.Key("type");
          writer.String(drmType);
          if (!licenseUrl.empty()) {
            writer.Key("licenseUrl");
            writer.String(licenseUrl);
          }
          writer.Key("useLicenseCallback");
          writer.Bool(use_license_callback);
          writer.EndObject();
        }
        if (start_position > 0) {
          writer.Key("transmission");
          writer.StartObject();
            writer.Key("playTime");
            writer.StartObject();
              writer.Key("start");
              writer.Int64(start_position);
            writer.EndObject();
          writer.EndObject();
        }
      writer.EndObject();
    writer.EndObject();

    payload = writer.GetString();
  }

  // URIs can contain authentication data or an app-local proxy capability.
  LogInfo(TAG) << "Loading network source (URI redacted)";

  if (slot_ < 0) {
    LogError(TAG) << "load(): no slot";
    return false;
  }

  // License-callback DRM is handled inside the media pipeline, which matches
  // the license response to its challenge via sessionId/requestId, so no
  // separate DRM init/load is needed here.
  if (NDL_MediaSetPlayer(slot_) != 0) {
    LogError(TAG) << "NDL_MediaSetPlayer(" << slot_ << ") failed";
    return false;
  }
  if (NDL_MediaLoadWithOption(uri.c_str(), payload.c_str()) != 0) {
    LogError(TAG) << "NDL_MediaLoadWithOption failed: "
                  << NDL_MediaGetError();
    return false;
  }

  state_ = IN_LOADING;
  delegate_->OnStateChanged(state_);
  return true;
}

bool WebOSPlayer::unload(bool reset) {
  bool retv = true;
  if (state_ != UNLOADED) {
    if (slot_ >= 0 && NDL_MediaSetPlayer(slot_) == 0) {
      if (NDL_MediaUnload() != 0) {
        retv = false;
        LogWarn(TAG) << "NDL_MediaUnload(" << slot_ << ") at "
                     << stateToString(state_) << " failed";
      }
    } else {
      retv = false;
      LogWarn(TAG) << "unload() at " << stateToString(state_) << " failed (no slot)";
    }

    // keep visibility_
    if (reset) {
      volume_ = 100;
      current_ = 0;
      duration_ = 0;
      seekable_ = false;
      has_video_ = false;
      has_audio_ = false;
      videoW_ = 0;
      videoH_ = 0;
    }
    speed_ = 1.0;
    audio_out_ = true;
    buffering_ = false;
    buffering_start_ = 0;
    buffering_end_ = 0;

    state_ = UNLOADED;
    delegate_->OnStateChanged(state_);
  }
  return retv;
}

bool WebOSPlayer::play() {
  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return true;
  }

  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0 || NDL_MediaPlay() != 0) {
    LogWarn(TAG) << "NDL_MediaPlay(" << slot_ << ") at "
                 << stateToString(state_) << " failed";
    return false;
  }
  return true;
}

bool WebOSPlayer::setPlayRate(double playRate,bool audioOut) {
  if (playRate == speed_ &&
      audioOut == audio_out_) {
    return true;
  }
  LogInfo(TAG) << "setPlayRate(" << playRate << ", audioOut:" << audioOut << ")";
  speed_ = playRate;
  audio_out_ = audioOut;

  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return true;
  }
  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0
      || NDL_MediaSetPlaybackRate(playRate) != 0) {
    LogWarn(TAG) << "NDL_MediaSetPlaybackRate(" << playRate << ") at "
                 << stateToString(state_) << " failed";
    return false;
  }
  // audio_out_ is preserved on the plugin side; the platform's playback-rate
  // API takes a rate only, so the audio-output toggle has no platform call.
  return true;
}

bool WebOSPlayer::selectTrack(const std::string& type, int64_t trackIndex) {
  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return false;
  }
  LogInfo(TAG) << "selectTrack(" << type << ", " << trackIndex << ") state=" << state_;
  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0) {
    LogWarn(TAG) << "selectTrack: NDL_MediaSetPlayer failed";
    return false;
  }
  bool result = (NDL_MediaSelectTrack(type.c_str(),
                                      static_cast<int>(trackIndex)) == 0);
  LogInfo(TAG) << "selectTrack result=" << result;
  return result;
}

bool WebOSPlayer::setSubtitleEnable(bool enable) {
  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return false;
  }
  LogInfo(TAG) << "setSubtitleEnable(" << enable << ") state=" << state_;
  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0) {
    LogWarn(TAG) << "setSubtitleEnable: NDL_MediaSetPlayer failed";
    return false;
  }
  bool result = (NDL_MediaSetSubtitleEnable(enable) == 0);
  LogInfo(TAG) << "setSubtitleEnable result=" << result;
  return result;
}

bool WebOSPlayer::setSubtitleSync(int64_t offset) {
  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return false;
  }
  LogInfo(TAG) << "setSubtitleSync(" << offset << ") state=" << state_;
  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0) {
    LogWarn(TAG) << "setSubtitleSync: NDL_MediaSetPlayer failed";
    return false;
  }
  bool result = (NDL_MediaSetSubtitleSync(static_cast<int>(offset)) == 0);
  LogInfo(TAG) << "setSubtitleSync result=" << result;
  return result;
}

bool WebOSPlayer::pause() {
  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return true;
  }

  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0 || NDL_MediaPause() != 0) {
    LogWarn(TAG) << "NDL_MediaPause(" << slot_ << ") at "
                 << stateToString(state_) << " failed";
    return false;
  }
  return true;
}

bool WebOSPlayer::seek(int64_t position,bool update_position) {
  if (!seekable_ && position != 0) {
    LogInfo(TAG) << "can't seek, because it's not a seakable contents";
    return false;
  }
  if (state_ == UNLOADED ||
      state_ == IN_LOADING ||
      state_ == REMOVED) {
    return false;
  }
  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0
      || NDL_MediaSeekTo(position) != 0) {
    LogWarn(TAG) << "NDL_MediaSeekTo(" << position << ") at "
                 << stateToString(state_) << " failed";
    return false;
  }
  if (update_position) {
    current_ = position;
  }
  return true;
}

bool WebOSPlayer::setVolume(int32_t volume) {
  // Per-stream volume / mute is not exposed by the platform's C API surface.
  // Record the requested value for state consistency and return success so
  // the Dart-side controller does not see a transport error; the method
  // handler in the plugin layer responds NotImplemented on direct calls.
  if (volume == volume_) {
    return true;
  }
  LogWarn(TAG) << "setVolume(" << volume
               << ") not supported on this platform";
  volume_ = volume;
  return true;
}

bool WebOSPlayer::notifyVisibility(bool visibility) {
  visibility_ = visibility;

  // Video-plane visibility is owned by the exported window
  // (webos/exported_windows) and the compositor, not by this plugin: on
  // background the player is also paused (unless background-run) and the app
  // surface is hidden, so nothing is shown. Keep visibility_ for state only.
  return true;
}

bool WebOSPlayer::setDrmOperation(const std::string& systemId,
                                 const std::string& drmData,
                                 const std::string& drmMsgType,
                                 const std::string& service,
                                 const std::string& sessionId,
                                 int32_t requestId,
                                 const std::string& kid) {

  LogInfo(TAG) << "setDrmOperation called:"
               << " systemId=" << systemId
               << ", msgType=" << drmMsgType
               << ", sessionId=" << sessionId
               << ", requestId=" << requestId;
  if (!kid.empty()) {
    LogInfo(TAG) << "  kid: " << kid;
  }

  // Encode license data to base64 before sending
  gchar* encoded_drm_data = g_base64_encode((const guchar*)drmData.c_str(),
                                            drmData.length());
  std::string base64_drm_data(encoded_drm_data);
  g_free(encoded_drm_data);

  LogInfo(TAG) << "  license data (base64): " << base64_drm_data;

  // Route the license response through this slot's media pipeline so it can be
  // matched to the originating challenge via sessionId/requestId.
  // NDL_MediaSetDrmOperation requires NDL_MediaSetPlayer to select the slot first.
  if (slot_ < 0 || NDL_MediaSetPlayer(slot_) != 0) {
    LogError(TAG) << "setDrmOperation: NDL_MediaSetPlayer(" << slot_
                  << ") failed";
    return false;
  }
  if (NDL_MediaSetDrmOperation(systemId.c_str(), base64_drm_data.c_str(),
                               drmMsgType.c_str(), service.c_str(),
                               kid.c_str(), sessionId.c_str(),
                               requestId) != 0) {
    LogError(TAG) << "NDL_MediaSetDrmOperation failed: "
                  << NDL_MediaGetError();
    return false;
  }
  return true;
}

void WebOSPlayer::handleEvent(const std::string& event_json) {
  LogDebug(TAG) << "event[" << slot_ << "]: " << event_json;
  pbnjson::JValue obj = pbnjson::JDomParser::fromString(event_json);
  if (obj.isNull() || !obj.isObject()) {
    return;
  }

  if (!obj["loadCompleted"].isNull()) {
    pushCallback(BasicCb{ kTypeLoadCompleted });
  } else if (!obj["playing"].isNull()) {
    pushCallback(BasicCb{ kTypePlaying });
  } else if (!obj["paused"].isNull()) {
    pushCallback(BasicCb{ kTypePaused });
  } else if (!obj["seekDone"].isNull()) {
    pushCallback(BasicCb{ kTypeSeekDone });
  } else if (!obj["bufferingStart"].isNull()) {
    pushCallback(BasicCb{ kTypeBufferingStart });
  } else if (!obj["bufferingEnd"].isNull()) {
    pushCallback(BasicCb{ kTypeBufferingEnd });
  } else if (!obj["endOfStream"].isNull()) {
    pushCallback(BasicCb{ kTypeEndOfStream });
  } else if (!obj["currentTime"].isNull()) {
    pbnjson::JValue ct = obj["currentTime"];
    int64_t t = 0;
    if (ct["currentTime"].isNumber()) {
      ct["currentTime"].asNumber(t);
    } else {
      ct.asNumber(t);
    }
    if (current_ != t) {
      current_ = t;
    }
  } else if (!obj["sourceInfo"].isNull()) {
    pbnjson::JValue src = obj["sourceInfo"];
    pbnjson::JValue progs = src["programInfo"];
    if (!progs.isArray() || progs.arraySize() == 0) {
      return;
    }
    pbnjson::JValue p0 = progs[0];
    int64_t dur = 0, num_video = 0, num_audio = 0;
    if (p0["duration"].isNumber())       p0["duration"].asNumber(dur);
    if (p0["numVideoTracks"].isNumber()) p0["numVideoTracks"].asNumber(num_video);
    if (p0["numAudioTracks"].isNumber()) p0["numAudioTracks"].asNumber(num_audio);
    // The platform emits a placeholder sourceInfo whose programInfo[0] has
    // all-zero duration/track counts before the real event arrives with
    // populated data. Dispatching the placeholder would raise a premature
    // OnInitialized(duration:0). isNumber() alone doesn't catch this because
    // 0 is still a valid number — gate on actual content.
    if (dur == 0 && num_video == 0 && num_audio == 0) {
      return;
    }

    SourceInfoCb cb = { true, dur, num_video > 0, num_audio > 0, 0, 0, {}, {} };
    if (src["seekable"].isBoolean()) {
      cb.seekable = src["seekable"].asBool();
    }
    cb.video_width = videoW_;
    cb.video_height = videoH_;
    // audioTrackInfo / subtitleTrackInfo arrive nested in programInfo[0];
    // mirror them onto the callback so the Flutter layer can present
    // track-selection UI.
    pbnjson::JValue audio_tracks = p0["audioTrackInfo"];
    if (audio_tracks.isArray()) {
      for (ssize_t i = 0; i < audio_tracks.arraySize(); ++i) {
        pbnjson::JValue t = audio_tracks[i];
        AudioTrackInfoCb track = { "", 0 };
        if (t["language"].isString()) track.language = t["language"].asString();
        int64_t id = 0;
        if (t["trackId"].isNumber()) {
          t["trackId"].asNumber(id);
          track.trackId = static_cast<int>(id);
        }
        cb.audio_tracks.push_back(track);
      }
    }
    pbnjson::JValue sub_tracks = p0["subtitleTrackInfo"];
    if (sub_tracks.isArray()) {
      for (ssize_t i = 0; i < sub_tracks.arraySize(); ++i) {
        pbnjson::JValue t = sub_tracks[i];
        SubtitleTrackInfoCb track = { "", 0 };
        if (t["language"].isString()) track.language = t["language"].asString();
        int64_t id = 0;
        if (t["trackId"].isNumber()) {
          t["trackId"].asNumber(id);
          track.trackId = static_cast<int>(id);
        }
        cb.subtitle_tracks.push_back(track);
      }
    }
    pushCallback(cb);
  } else if (!obj["videoInfo"].isNull()) {
    pbnjson::JValue vi = obj["videoInfo"];
    int w = 0, h = 0;
    if (vi["width"].isNumber()) {
      vi["width"].asNumber(w);
    }
    if (vi["height"].isNumber()) {
      vi["height"].asNumber(h);
    }
    if (w > 0 && h > 0 && (w != videoW_ || h != videoH_)) {
      videoW_ = w;
      videoH_ = h;
      // Only refresh via SourceInfoCb if real source metadata has already
      // arrived. videoInfo can land before sourceInfo, in which case the
      // cached source state is all-zero and pushing it here would fire a
      // premature OnInitialized(duration:0). The next real sourceInfo
      // will pick up the new dims through cb.video_width = videoW_.
      if (duration_ > 0 || has_video_ || has_audio_) {
        SourceInfoCb cb = { seekable_, duration_, has_video_, has_audio_, w, h,
                            audio_tracks_, subtitle_tracks_ };
        pushCallback(cb);
      }
    }
  } else if (!obj["error"].isNull()) {
    pbnjson::JValue err = obj["error"];
    int64_t code = 0;
    std::string text;
    if (err["errorCode"].isNumber()) {
      err["errorCode"].asNumber(code);
    }
    if (err["errorText"].isString()) {
      text = err["errorText"].asString();
    }
    pushCallback(ErrorCb{ code, text });
  } else if (!obj["drmEncrypted"].isNull()) {
    // DRM-encrypted challenges are forwarded as JSON events on the same
    // subscribe-events channel as playback events.
    pbnjson::JValue d = obj["drmEncrypted"];
    DrmEncryptedCb cb = { "", "", "", "", "", "", 0 };
    if (d["systemId"].isString())   cb.systemId   = d["systemId"].asString();
    if (d["service"].isString())    cb.service    = d["service"].asString();
    if (d["key"].isString())        cb.key        = d["key"].asString();
    if (d["sessionId"].isString())  cb.sessionId  = d["sessionId"].asString();
    if (d["drmMsgType"].isString()) cb.drmMsgType = d["drmMsgType"].asString();
    if (d["drmData"].isString())    cb.drmData    = d["drmData"].asString();
    if (d["requestId"].isNumber()) {
      int64_t r = 0;
      d["requestId"].asNumber(r);
      cb.requestId = static_cast<int32_t>(r);
    }
    pushCallback(cb);
  }
}

void WebOSPlayer::execLoadCompleted() {
  state_ = LOADED;

  notifyVisibility(visibility_);
  // Volume/mute is not restored here: it is not exposed by the platform C API,
  // and setVolume() keeps the plugin-side state record without a platform call.
  if (speed_ != 1.0) {
    if (slot_ >= 0 && NDL_MediaSetPlayer(slot_) == 0) {
      NDL_MediaSetPlaybackRate(speed_);
    }
  }
  delegate_->OnStateChanged(LOADED);
}

void WebOSPlayer::execPlaying() {
  state_ = PLAYING;
  delegate_->OnStateChanged(PLAYING);
}

void WebOSPlayer::execPaused() {
  state_ = PAUSED;
  delegate_->OnStateChanged(PAUSED);
}

void WebOSPlayer::execSeekDone() {
  delegate_->OnSeekCompleted();
}

void WebOSPlayer::execBufferingStart() {
  if (buffering_) {
    return;
  }
  buffering_ = true;
  delegate_->OnBufferingStart();
}

void WebOSPlayer::execBufferingEnd() {
  if (!buffering_) {
    return;
  }
  buffering_ = false;
  delegate_->OnBufferingEnd();
}

void WebOSPlayer::execEndOfStream() {
  state_ = EOS;
  current_ = duration_;
  delegate_->OnStateChanged(EOS);
  delegate_->OnPlayCompleted();
}

void WebOSPlayer::execBufferRange(int64_t begin, int64_t end) {
  if (begin == buffering_start_ &&
      end == buffering_end_) {
    return;
  }

  buffering_start_ = begin;
  buffering_end_ = end;
  delegate_->OnBuffered(buffering_start_, buffering_end_);
}

void WebOSPlayer::execError(int64_t code, const std::string& text) {
  LogInfo(TAG) << "onError("  << code << "," << text << ") at " << stateToString(state_);

  // Ignore Seek error
  if (code == MediaPipelineStatus::SMP_SEEK_FAILURE) {
  }
  // resource was removed by webOS policy.
  else if (code == MediaPipelineStatus::SMP_RM_RELATED_ERROR) {
    state_ = REMOVED;
    delegate_->OnStateChanged(REMOVED);
  }
  // On a pipeline play error, recover so the video is shown: reload if still
  // loading, otherwise seek back to the start.
  else if (code == MediaPipelineStatus::SMP_MEDIA_API_PLAYING_ERROR) {
    if (state_ == IN_LOADING) {
      if (slot_ >= 0 && NDL_MediaSetPlayer(slot_) == 0) {
        NDL_MediaUnload();
      }
      state_ = UNLOADED;

      LoadParams& params = loadParams_;
      load(params.appId,
           params.winId,
           params.uri,
           params.licenseUrl,
           params.drmType,
           params.use_license_callback,
           params.hint,
           params.start_position);
    } else if (slot_ >= 0 && NDL_MediaSetPlayer(slot_) == 0) {
      NDL_MediaSeekTo(0);
    }
  }
  // Notify error
  else {
    delegate_->OnError(code, text);
  }
}

void WebOSPlayer::execTrackSelected(const std::string& type, int index) {
  LogInfo(TAG) << "execTrackSelected(type=" << type << ", index=" << index << ")";
  delegate_->OnTrackSelected(type, index);
}

void WebOSPlayer::execDrmEncrypted(const DrmEncryptedCb& info) {
  LogInfo(TAG) << "execDrmEncrypted: systemId=" << info.systemId
               << ", sessionId=" << info.sessionId
               << ", drmData size=" << info.drmData.size();

  if (info.drmData.empty()) {
    LogWarn(TAG) << "Empty DRM data — skipping challenge processing";
    return;
  }
  VideoPlayer* video_player_instance = static_cast<VideoPlayer*>(delegate_);
  if (!video_player_instance) {
    LogError(TAG) << "Failed to cast delegate to VideoPlayer instance";
    return;
  }
  DrmManager* drm_manager = video_player_instance->GetDrmManager();
  if (!drm_manager) {
    LogError(TAG) << "DrmManager instance is null";
    return;
  }
  drm_manager->processChallenge(info);
}

void WebOSPlayer::execSourceInfo(const SourceInfoCb& info) {
  seekable_ = info.seekable;
  duration_ = info.duration;
  has_video_ = info.has_video;
  has_audio_ = info.has_audio;
  videoW_ =  info.video_width;
  videoH_ = info.video_height;
  audio_tracks_ = info.audio_tracks;
  subtitle_tracks_ = info.subtitle_tracks;

  LogInfo(TAG) << "WH[" << videoW_ << "," << videoH_ << "],duration: "
    << duration_/1000 << ",seekable:" << seekable_
    << ",hasAudio:" << has_audio_ << ",hasVideo:" << has_video_;

  delegate_->OnInitialized();
}

void WebOSPlayer::pushCallback(CallbackVariant cb) {
  std::lock_guard<std::recursive_mutex> autoLock(mutex_);
  callbacks_.push_back(cb);

  if (idle_source_ == nullptr) {
    idle_source_ = attachToGMainLoop([](void* data) -> int {
      WebOSPlayer* self = (WebOSPlayer*)data;
      self->popCallbacks();
      return G_SOURCE_REMOVE;
    }, this);
  }
}

void WebOSPlayer::popCallbacks() {
  std::vector<CallbackVariant> callbacks;
  {
    std::lock_guard<std::recursive_mutex> autoLock(mutex_);
    idle_source_ = nullptr;
    std::swap(callbacks_, callbacks);
  }

  for (auto& cb : callbacks) {
    if (auto basic_cb = std::get_if<BasicCb>(&cb)) {
      switch (basic_cb->type) {
        case kTypeLoadCompleted:  execLoadCompleted(); break;
        case kTypePlaying:        execPlaying(); break;
        case kTypePaused:         execPaused(); break;
        case kTypeSeekDone:       execSeekDone(); break;
        case kTypeBufferingStart: execBufferingStart(); break;
        case kTypeBufferingEnd:   execBufferingEnd(); break;
        case kTypeEndOfStream:
          {
          const int64_t MAX_WAIT = 1000;
          if (timer_source_) {
            g_source_destroy(timer_source_);
          }
          timer_source_ = attachToGMainLoop([](void* data) -> int {
            WebOSPlayer* self = (WebOSPlayer*)data;
            self->timer_source_ = nullptr;
            self->execEndOfStream();
            return G_SOURCE_REMOVE;
          }, this, std::min(duration_ - current_, MAX_WAIT));
          }
          break;
        default: break;
      }
    } else if (auto bufferrange_cb = std::get_if<BufferRangeCb>(&cb)) {
      execBufferRange(bufferrange_cb->start, bufferrange_cb->end);
    } else if (auto error_cb = std::get_if<ErrorCb>(&cb)) {
      execError(error_cb->code, error_cb->text);
    } else if (auto info = std::get_if<SourceInfoCb>(&cb)) {
      execSourceInfo(*info);
    } else if (auto track_cb = std::get_if<TrackSelectedCb>(&cb)) {
      execTrackSelected(track_cb->type, track_cb->index);
    } else if (auto drm_cb = std::get_if<DrmEncryptedCb>(&cb)) {
      execDrmEncrypted(*drm_cb);
    }
  }
}

GSource* WebOSPlayer::attachToGMainLoop(GMainLoopCallback cb, void* data, int64_t msec) {
  GSource* src = (msec > 0) ?  g_timeout_source_new(msec) : g_idle_source_new();
  g_source_set_callback(src,cb,data,NULL);
  g_source_attach(src,s_main_context_);
  g_source_unref(src);
  return src;
}

std::string WebOSPlayer::stateToString(int state) {
  std::string name = "UNKNOWN";

  if (state == UNLOADED) name = "UNLOADED";
  else if (state == IN_LOADING) name = "IN_LOADING";
  else if (state == LOADED) name = "LOADED";
  else if (state == PLAYING) name = "PLAYING";
  else if (state == PAUSED) name = "PAUSED";
  else if (state == EOS) name = "EOF";
  else if (state == REMOVED) name = "REMOVED";

  return name;
}
