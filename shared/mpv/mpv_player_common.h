#ifndef PLEZY_SHARED_MPV_PLAYER_COMMON_H_
#define PLEZY_SHARED_MPV_PLAYER_COMMON_H_

#include <mpv/client.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <functional>
#include <map>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

namespace plezy {
namespace mpv_common {

using StatusCallback = std::function<void(int error)>;
// `result` is the command's return node (owned by the reply event, valid only
// for the duration of the callback) or nullptr when the command failed or
// returned nothing.
using CommandCallback = std::function<void(int error, const mpv_node* result)>;
using GetPropertyCallback = std::function<void(int error, const std::string& value)>;

static constexpr char kSetPropertyFailedCode[] = "SET_PROPERTY_FAILED";
static constexpr char kSetPropertyNotInitializedCode[] = "NOT_INITIALIZED";
static constexpr size_t kSetPropertyErrorDescriptionLimit = 160;
// end-file `cause` for an audio device the recovery below gave up on. Dart
// (PlayerError.audioOutputFailed) and Android
// (MpvEndFileDiagnostics.CAUSE_AUDIO_OUTPUT_FAILED) carry the same tag.
static constexpr char kAudioOutputFailedCause[] = "audio-output-failed";

inline bool SetPropertyStatusSucceeded(int status) { return status >= 0; }

inline const char* SetPropertyErrorCode(int status) {
  return status == MPV_ERROR_UNINITIALIZED ? kSetPropertyNotInitializedCode : kSetPropertyFailedCode;
}

inline std::string SetPropertyErrorDescription(int status) {
  const char* description = mpv_error_string(status);
  if (!description || description[0] == '\0') {
    return "MPV property write failed";
  }

  size_t length = 0;
  while (length < kSetPropertyErrorDescriptionLimit && description[length] != '\0') {
    ++length;
  }
  return std::string(description, length);
}

struct CancelledRequests {
  std::vector<StatusCallback> status;
  std::vector<CommandCallback> commands;
  std::vector<GetPropertyCallback> properties;
};

class AsyncRequestRegistry {
 public:
  uint64_t RegisterStatus(StatusCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    const uint64_t request_id = next_id_++;
    status_[request_id] = std::move(callback);
    return request_id;
  }

  StatusCallback TakeStatus(uint64_t request_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = status_.find(request_id);
    if (it == status_.end()) return nullptr;
    auto callback = std::move(it->second);
    status_.erase(it);
    return callback;
  }

  uint64_t RegisterCommand(CommandCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    const uint64_t request_id = next_id_++;
    commands_[request_id] = std::move(callback);
    return request_id;
  }

  CommandCallback TakeCommand(uint64_t request_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = commands_.find(request_id);
    if (it == commands_.end()) return nullptr;
    auto callback = std::move(it->second);
    commands_.erase(it);
    return callback;
  }

  uint64_t RegisterProperty(GetPropertyCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    const uint64_t request_id = next_id_++;
    properties_[request_id] = std::move(callback);
    return request_id;
  }

  GetPropertyCallback TakeProperty(uint64_t request_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = properties_.find(request_id);
    if (it == properties_.end()) return nullptr;
    auto callback = std::move(it->second);
    properties_.erase(it);
    return callback;
  }

  CancelledRequests CancelAll() {
    CancelledRequests cancelled;
    std::lock_guard<std::mutex> lock(mutex_);
    cancelled.status.reserve(status_.size());
    for (auto& request : status_) {
      if (request.second) {
        cancelled.status.push_back(std::move(request.second));
      }
    }
    cancelled.commands.reserve(commands_.size());
    for (auto& request : commands_) {
      if (request.second) {
        cancelled.commands.push_back(std::move(request.second));
      }
    }
    cancelled.properties.reserve(properties_.size());
    for (auto& request : properties_) {
      if (request.second) {
        cancelled.properties.push_back(std::move(request.second));
      }
    }
    status_.clear();
    commands_.clear();
    properties_.clear();
    return cancelled;
  }

 private:
  uint64_t next_id_ = 1;
  std::map<uint64_t, StatusCallback> status_;
  std::map<uint64_t, CommandCallback> commands_;
  std::map<uint64_t, GetPropertyCallback> properties_;
  std::mutex mutex_;
};

// Every libmpv async submission follows the same shape: register the callback,
// hand the request to mpv, and roll back when the submission fails. A negative
// result means the request never reached mpv, so nothing will ever complete it
// and the callback has to be taken back and failed inline. The uninitialized
// handle guard stays with the callers: they own the lifecycle flags and the
// error code they report when the handle is gone.
inline void SubmitCommandAsync(
    mpv_handle* mpv, AsyncRequestRegistry& requests, const std::vector<std::string>& args, CommandCallback callback) {
  std::vector<const char*> c_args;
  c_args.reserve(args.size() + 1);
  for (const auto& arg : args) {
    c_args.push_back(arg.c_str());
  }
  c_args.push_back(nullptr);

  const uint64_t request_id = callback ? requests.RegisterCommand(std::move(callback)) : 0;
  // mpv_command_async returns immediately.
  const int result = mpv_command_async(mpv, request_id, c_args.data());
  if (result < 0) {
    auto pending = requests.TakeCommand(request_id);
    if (pending) pending(result, nullptr);
  }
}

// The playlist entry a `loadfile` created, read from the command's result map.
// mpv reports it as `playlist_entry_id`; other commands return no map, so a
// caller gets false for them and answers with no id.
inline bool PlaylistEntryIdFromCommandResult(const mpv_node* result, int64_t* playlist_entry_id) {
  if (!result || !playlist_entry_id || result->format != MPV_FORMAT_NODE_MAP) return false;
  const mpv_node_list* map = result->u.list;
  if (!map || map->num <= 0 || !map->keys || !map->values) return false;
  for (int i = 0; i < map->num; i++) {
    if (!map->keys[i] || strcmp(map->keys[i], "playlist_entry_id") != 0) continue;
    if (map->values[i].format != MPV_FORMAT_INT64) return false;
    *playlist_entry_id = map->values[i].u.int64;
    return true;
  }
  return false;
}

inline void SubmitSetPropertyAsync(
    mpv_handle* mpv, AsyncRequestRegistry& requests, const std::string& name, const std::string& value,
    StatusCallback callback) {
  const uint64_t request_id = callback ? requests.RegisterStatus(std::move(callback)) : 0;
  char* property_value = const_cast<char*>(value.c_str());
  const int result = mpv_set_property_async(mpv, request_id, name.c_str(), MPV_FORMAT_STRING, &property_value);
  if (result < 0) {
    auto pending = requests.TakeStatus(request_id);
    if (pending) pending(result);
  }
}

// Typed rather than formatted: a double rendered to text goes through the
// C locale's decimal separator, which a GTK process has usually replaced.
inline void SubmitSetPropertyAsync(
    mpv_handle* mpv, AsyncRequestRegistry& requests, const std::string& name, double value, StatusCallback callback) {
  const uint64_t request_id = callback ? requests.RegisterStatus(std::move(callback)) : 0;
  const int result = mpv_set_property_async(mpv, request_id, name.c_str(), MPV_FORMAT_DOUBLE, &value);
  if (result < 0) {
    auto pending = requests.TakeStatus(request_id);
    if (pending) pending(result);
  }
}

inline void SubmitGetPropertyAsync(
    mpv_handle* mpv, AsyncRequestRegistry& requests, const std::string& name, GetPropertyCallback callback) {
  const uint64_t request_id = requests.RegisterProperty(std::move(callback));
  const int result = mpv_get_property_async(mpv, request_id, name.c_str(), MPV_FORMAT_STRING);
  if (result < 0) {
    auto pending = requests.TakeProperty(request_id);
    if (pending) pending(result, "");
  }
}

// Completes a COMMAND_REPLY / SET_PROPERTY_REPLY / GET_PROPERTY_REPLY against
// the pending-request registry. `sanitize` converts mpv's payload (not
// guaranteed to be valid UTF-8) into the string handed to the callback.
// Returns true when the event was a reply event and has been fully handled.
template <typename Sanitizer>
inline bool DispatchReplyEvent(AsyncRequestRegistry& requests, const mpv_event* event, const Sanitizer& sanitize) {
  switch (event->event_id) {
    case MPV_EVENT_COMMAND_REPLY: {
      CommandCallback callback = requests.TakeCommand(event->reply_userdata);
      if (callback) {
        const mpv_node* result = nullptr;
        if (event->error >= 0 && event->data) {
          result = &static_cast<const mpv_event_command*>(event->data)->result;
        }
        callback(event->error, result);
      }
      return true;
    }
    case MPV_EVENT_SET_PROPERTY_REPLY: {
      StatusCallback callback = requests.TakeStatus(event->reply_userdata);
      if (callback) {
        callback(event->error);
      }
      return true;
    }
    case MPV_EVENT_GET_PROPERTY_REPLY: {
      GetPropertyCallback callback = requests.TakeProperty(event->reply_userdata);
      if (callback) {
        std::string value;
        if (event->error >= 0) {
          auto* prop = static_cast<mpv_event_property*>(event->data);
          if (prop && prop->format == MPV_FORMAT_STRING && prop->data) {
            auto c_value = *static_cast<char**>(prop->data);
            if (c_value) value = sanitize(c_value);
          }
        }
        callback(event->error, value);
      }
      return true;
    }
    default:
      return false;
  }
}

// Copies a PROPERTY_CHANGE payload into a node the platform marshallers can
// convert. mpv owns the storage, so the node only borrows it for the lifetime
// of the event.
inline mpv_node ExtractPropertyNode(const mpv_event_property* prop) {
  mpv_node node{};
  node.format = prop ? prop->format : MPV_FORMAT_NONE;
  if (!prop) return node;

  switch (prop->format) {
    case MPV_FORMAT_STRING:
      node.u.string = prop->data ? *static_cast<char**>(prop->data) : nullptr;
      break;
    case MPV_FORMAT_FLAG:
      node.u.flag = prop->data ? *static_cast<int*>(prop->data) : 0;
      break;
    case MPV_FORMAT_INT64:
      node.u.int64 = prop->data ? *static_cast<int64_t*>(prop->data) : 0;
      break;
    case MPV_FORMAT_DOUBLE:
      node.u.double_ = prop->data ? *static_cast<double*>(prop->data) : 0.0;
      break;
    case MPV_FORMAT_NODE:
      if (prop->data) {
        node = *static_cast<mpv_node*>(prop->data);
      } else {
        node.format = MPV_FORMAT_NONE;
      }
      break;
    default:
      node.format = MPV_FORMAT_NONE;
      break;
  }
  return node;
}

// mpv node payloads are untrusted input: a property can nest arbitrarily
// deeply, carry a list as long as mpv claims, and hold strings that are
// neither length-bounded nor valid UTF-8. Every runner walks the same trees
// into its own Flutter value type, so the walk and its bounds live here once.
static constexpr size_t kMaxNodeDepth = 32;
static constexpr int kMaxNodeEntries = 16384;

struct NodeConversionBudget {
  size_t remaining_entries = static_cast<size_t>(kMaxNodeEntries);
  size_t remaining_bytes = 16 * 1024 * 1024;
};

// Measures an mpv string without ever reading past the remaining byte budget,
// and charges it to that budget. Returns false for a missing string or one
// that would exceed what is left, which is how the walk rejects a payload.
inline bool ClaimNodeString(const char* input, NodeConversionBudget* budget, size_t* length) {
  if (!input || !budget || !length) return false;
  const size_t measured = strnlen(input, budget->remaining_bytes + 1);
  if (measured > budget->remaining_bytes) return false;
  budget->remaining_bytes -= measured;
  *length = measured;
  return true;
}

// `Builder` adapts the walk to a platform value type and keeps that platform's
// UTF-8 sanitizer out of this header. It supplies the types `Value`,
// `ListBuilder` and `MapBuilder`, the leaves `Null`, `Boolean`, `Int`,
// `Double` and `String(data, length)`, and the containers `NewList`/`Append`/
// `FinishList` plus `NewMap`/`Insert`/`FinishMap`. A value passed to
// `Append`/`Insert` belongs to the builder from then on, and `AbandonMap`
// releases a partially built map whose key was rejected. The boolean leaf is
// deliberately not named `Bool`: X11's `Xlib.h`, reached through `epoxy/egl.h`
// on Linux, defines `Bool` as a macro and would rewrite the declaration.
template <typename Builder>
typename Builder::Value ConvertNode(const mpv_node* node, size_t depth, NodeConversionBudget* budget) {
  if (!node || !budget || depth >= kMaxNodeDepth || budget->remaining_entries == 0) {
    return Builder::Null();
  }
  --budget->remaining_entries;

  switch (node->format) {
    case MPV_FORMAT_STRING: {
      size_t length = 0;
      if (!ClaimNodeString(node->u.string, budget, &length)) return Builder::Null();
      return Builder::String(node->u.string, length);
    }
    case MPV_FORMAT_FLAG:
      return Builder::Boolean(node->u.flag != 0);
    case MPV_FORMAT_INT64:
      return Builder::Int(node->u.int64);
    case MPV_FORMAT_DOUBLE:
      return Builder::Double(node->u.double_);
    case MPV_FORMAT_NODE_ARRAY: {
      const mpv_node_list* list = node->u.list;
      if (!list || list->num < 0 || list->num > kMaxNodeEntries || (list->num > 0 && !list->values)) {
        return Builder::Null();
      }
      typename Builder::ListBuilder result = Builder::NewList();
      for (int i = 0; i < list->num; i++) {
        Builder::Append(result, ConvertNode<Builder>(&list->values[i], depth + 1, budget));
      }
      return Builder::FinishList(std::move(result));
    }
    case MPV_FORMAT_NODE_MAP: {
      const mpv_node_list* map = node->u.list;
      if (!map || map->num < 0 || map->num > kMaxNodeEntries || (map->num > 0 && (!map->keys || !map->values))) {
        return Builder::Null();
      }
      typename Builder::MapBuilder result = Builder::NewMap();
      for (int i = 0; i < map->num; i++) {
        size_t key_length = 0;
        if (!ClaimNodeString(map->keys[i], budget, &key_length)) {
          Builder::AbandonMap(result);
          return Builder::Null();
        }
        Builder::Insert(result, map->keys[i], key_length, ConvertNode<Builder>(&map->values[i], depth + 1, budget));
      }
      return Builder::FinishMap(std::move(result));
    }
    default:
      return Builder::Null();
  }
}

template <typename Builder>
typename Builder::Value ConvertNode(const mpv_node* node) {
  NodeConversionBudget budget;
  return ConvertNode<Builder>(node, 0, &budget);
}

inline mpv_format ParsePropertyFormat(const std::string& format) {
  if (format == "string") return MPV_FORMAT_STRING;
  if (format == "flag" || format == "bool") return MPV_FORMAT_FLAG;
  if (format == "int64") return MPV_FORMAT_INT64;
  if (format == "double") return MPV_FORMAT_DOUBLE;
  if (format == "node") return MPV_FORMAT_NODE;
  return MPV_FORMAT_NONE;
}

struct ObservationRequest {
  bool added;
  uint64_t userdata;
  mpv_format format;
};

class PropertyObservationRegistry {
 public:
  ObservationRequest Register(const std::string& name, const std::string& format, int id) {
    const mpv_format parsed_format = ParsePropertyFormat(format);
    std::lock_guard<std::mutex> lock(mutex_);
    if (id_by_name_.find(name) != id_by_name_.end()) {
      return {false, 0, MPV_FORMAT_NONE};
    }
    const uint64_t userdata = next_userdata_++;
    id_by_name_[name] = id;
    return {true, userdata, parsed_format};
  }

  bool LookupId(const std::string& name, int* id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = id_by_name_.find(name);
    if (it == id_by_name_.end()) return false;
    *id = it->second;
    return true;
  }

  void Clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    id_by_name_.clear();
  }

 private:
  uint64_t next_userdata_ = 1;
  std::map<std::string, int> id_by_name_;
  mutable std::mutex mutex_;
};

inline bool ParseEnabledFlag(const std::string& value) { return value == "yes" || value == "true" || value == "1"; }

inline const char* TargetColorspaceHint(bool hdr_enabled) { return hdr_enabled ? "auto" : "no"; }

// Startup options shared by every desktop mpv core. Must run between
// mpv_create() and mpv_initialize(); platform-specific options (vo, hwdec,
// wid, HDR/tone-mapping, log level) stay with the caller.
inline void ApplyCommonStartupOptions(mpv_handle* mpv, bool audio_only) {
  if (audio_only) {
    // Music core: no VO, no video decode. vid=no keeps embedded cover art
    // from ever becoming a video track, and force-window/audio-display make
    // sure mpv never opens a video output for it either.
    mpv_set_option_string(mpv, "vid", "no");
    mpv_set_option_string(mpv, "force-window", "no");
    mpv_set_option_string(mpv, "audio-display", "no");
    mpv_set_option_string(mpv, "gapless-audio", "weak");
  }
  mpv_set_option_string(mpv, "keep-open", "yes");
  // When the audio device becomes unavailable (sleep, device unplug), fall
  // back to the null audio output instead of permanently dropping the audio
  // track. Recovery is handled by the platform event loop.
  mpv_set_option_string(mpv, "audio-fallback-to-null", "yes");
  mpv_set_option_string(mpv, "idle", "yes");
  mpv_set_option_string(mpv, "input-default-bindings", "no");
  mpv_set_option_string(mpv, "input-vo-keyboard", "no");
  mpv_set_option_string(mpv, "osc", "no");
  // Every URL Plezy opens is a media-server stream or a local file, never a
  // site mpv's bundled ytdl_hook could resolve. Loading it costs an on_load
  // hook per open and, on a failed open, spawns yt-dlp with the full stream
  // URL — access token included — in its argv, where other processes can read
  // it. mpv gates loading the builtin script on this option at mpv_initialize
  // time, so it has to be set here rather than from Dart.
  mpv_set_option_string(mpv, "ytdl", "no");
}

// kGiveUp is not a reload: the null-fallback budget is spent, the AO is still
// null and nothing is in flight, so the runner is to end playback. Returned
// once per outage episode; `attempt` then carries the number of reloads made.
enum class AudioReloadReason { kNone, kResume, kNullFallback, kGiveUp };

struct AudioReloadAction {
  AudioReloadReason reason = AudioReloadReason::kNone;
  int attempt = 0;
  bool exhausted = false;
  uint64_t request_generation = 0;
};

enum class AudioOutputTransition { kNone, kFellBackToNull, kRecovered };

// The null-fallback budget is per outage *episode*, not per null transition.
// Every ao-reload takes current-ao through unavailable and, when the device is
// still gone, straight back to "null", and a device that is flapping shows a
// real AO for a moment in between; neither is the outage ending. An episode
// starts when the AO falls back to null and ends either with the give-up or
// once audio has been back for a whole stable window, so a flap inside it
// continues the same budget and backoff instead of refilling them.
class AudioRecoveryState {
 public:
  using Clock = std::chrono::steady_clock;

  void SetFileLoaded(bool loaded, Clock::time_point now = Clock::now()) {
    std::lock_guard<std::mutex> lock(mutex_);
    const bool was_loaded = file_loaded_;
    file_loaded_ = loaded;
    if (!loaded) {
      resume_requested_ = false;
      resume_attempts_left_ = 0;
      reload_pending_ = false;
      pending_request_generation_ = 0;
      // The give-up ended this file; the next one gets its own episode.
      gave_up_ = false;
      return;
    }
    // The budget itself survives the file boundary: a skip mid-outage is the
    // same outage, so it resumes rather than refills.
    if (!was_loaded && current_ao_is_null_) ArmNullRecoveryLocked(now);
  }

  void RequestResume() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!file_loaded_) {
      resume_requested_ = false;
      resume_attempts_left_ = 0;
      return;
    }
    resume_requested_ = true;
  }

  AudioOutputTransition SetCurrentAudioOutputNull(bool is_null, Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (is_null == current_ao_is_null_) return AudioOutputTransition::kNone;
    current_ao_is_null_ = is_null;
    if (is_null) {
      if (file_loaded_) ArmNullRecoveryLocked(now);
      return AudioOutputTransition::kFellBackToNull;
    }
    // Only the time is recorded; whether this was the outage ending is decided
    // by how long it lasts, at the next fall back to null.
    last_recovered_at_ = now;
    recovered_in_episode_ = true;
    return AudioOutputTransition::kRecovered;
  }

  bool OnAudioDeviceListChanged(Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!file_loaded_ || !current_ao_is_null_) return false;
    const auto candidate = now + DeviceListDebounce();
    if (null_attempts_left_ <= 0 || candidate < null_next_attempt_) {
      null_next_attempt_ = candidate;
    }
    null_attempts_left_ = kNullRetryBudget;
    null_backoff_ = NullFirstDelay();
    // A new device is a new episode, whatever became of the last one.
    episode_active_ = true;
    recovered_in_episode_ = false;
    gave_up_ = false;
    return true;
  }

  AudioReloadAction NextReload(Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (resume_requested_ && file_loaded_) {
      resume_requested_ = false;
      resume_attempts_left_ = kResumeReloadAttempts;
      resume_next_attempt_ = now + ResumeFirstDelay();
    }
    if (reload_pending_) return {};

    if (resume_attempts_left_ > 0 && now >= resume_next_attempt_) {
      const int attempt = kResumeReloadAttempts - resume_attempts_left_ + 1;
      --resume_attempts_left_;
      resume_next_attempt_ = now + ResumeRetryDelay();
      reload_pending_ = true;
      pending_request_generation_ = ++next_request_generation_;
      return {AudioReloadReason::kResume, attempt, false, pending_request_generation_};
    }

    if (!NullWorkOwedLocked()) return {};
    if (null_attempts_left_ > 0) {
      if (now < null_next_attempt_) return {};
      const int attempt = kNullRetryBudget - null_attempts_left_ + 1;
      --null_attempts_left_;
      null_next_attempt_ = now + null_backoff_;
      null_backoff_ = std::min(null_backoff_ * 2, NullBackoffCap());
      reload_pending_ = true;
      pending_request_generation_ = ++next_request_generation_;
      return {AudioReloadReason::kNullFallback, attempt, null_attempts_left_ == 0, pending_request_generation_};
    }
    // The last reload has completed and the AO is still null. Its reply only
    // says the old AO was torn down; the replacement comes up afterwards and
    // current-ao reports it later still. So the last reload gets the same
    // backoff every earlier one had to show a real AO before the episode's
    // outcome is handed over, exactly once.
    if (now < null_next_attempt_) return {};
    gave_up_ = true;
    episode_active_ = false;
    return {AudioReloadReason::kGiveUp, kNullRetryBudget, true, 0};
  }

  bool CompleteReload(uint64_t request_generation) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!reload_pending_ || pending_request_generation_ != request_generation) {
      return false;
    }
    reload_pending_ = false;
    pending_request_generation_ = 0;
    return true;
  }

  bool HasPendingWork() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return file_loaded_ && (resume_requested_ || resume_attempts_left_ > 0 || reload_pending_ || NullWorkOwedLocked());
  }

 private:
  static constexpr int kResumeReloadAttempts = 2;
  static constexpr int kNullRetryBudget = 5;

  static std::chrono::milliseconds ResumeFirstDelay() { return std::chrono::milliseconds(1500); }
  static std::chrono::milliseconds ResumeRetryDelay() { return std::chrono::milliseconds(4500); }
  static std::chrono::milliseconds NullFirstDelay() { return std::chrono::milliseconds(500); }
  static std::chrono::milliseconds NullBackoffCap() { return std::chrono::milliseconds(8000); }
  static std::chrono::milliseconds DeviceListDebounce() { return std::chrono::milliseconds(250); }
  // How long audio has to stay on a real AO before a later fall back to null
  // counts as a new outage rather than the same one flapping.
  static std::chrono::seconds StableAudioWindow() { return std::chrono::seconds(10); }

  // A reload is owed while the budget lasts, and the give-up once it is spent;
  // both only while the AO is actually null, so a reload that has just brought
  // a real AO back is not followed by another, nor by the give-up.
  bool NullWorkOwedLocked() const { return file_loaded_ && current_ao_is_null_ && episode_active_ && !gave_up_; }

  // The AO is null and the file is loaded: continue the episode in progress
  // with what is left of its budget, or start one.
  void ArmNullRecoveryLocked(Clock::time_point now) {
    const bool same_outage =
        episode_active_ && (!recovered_in_episode_ || now - last_recovered_at_ < StableAudioWindow());
    if (same_outage) {
      null_next_attempt_ = now + null_backoff_;
      return;
    }
    null_attempts_left_ = kNullRetryBudget;
    null_backoff_ = NullFirstDelay();
    null_next_attempt_ = now + NullFirstDelay();
    episode_active_ = true;
    recovered_in_episode_ = false;
  }

  bool resume_requested_ = false;
  bool file_loaded_ = false;
  bool current_ao_is_null_ = false;
  bool reload_pending_ = false;
  uint64_t next_request_generation_ = 0;
  uint64_t pending_request_generation_ = 0;
  int resume_attempts_left_ = 0;
  Clock::time_point resume_next_attempt_{};
  int null_attempts_left_ = 0;
  Clock::time_point null_next_attempt_{};
  std::chrono::milliseconds null_backoff_{0};
  // An outage episode has a budget granted and has not yet given up. Retired
  // lazily: a fall back to null after a whole stable window on a real AO
  // starts a new one in its place.
  bool episode_active_ = false;
  bool recovered_in_episode_ = false;
  Clock::time_point last_recovered_at_{};
  // The give-up has been handed to the runner; cleared when the file it ended
  // is gone or a new device shows up.
  bool gave_up_ = false;
  mutable std::mutex mutex_;
};

struct AudioRecoveryNotice {
  // What to log, or nullptr when the property changed nothing of interest.
  const char* message = nullptr;
  // True when the state machine now has a reload queued, which platforms that
  // drive recovery from a timer rather than an event-loop tick must wake for.
  bool scheduled_work = false;
};

// Feeds the audio-related properties of a PROPERTY_CHANGE event into the
// recovery state machine, leaving the caller only the platform reporting.
// `now` is injectable for the same reason SetFileLoaded's is: the schedule
// the state machine derives from it is what the contract test asserts.
inline AudioRecoveryNotice ObserveAudioRecoveryProperty(
    AudioRecoveryState& state, const mpv_event* event, const mpv_event_property* prop,
    AudioRecoveryState::Clock::time_point now = AudioRecoveryState::Clock::now()) {
  if (!event || !prop || !prop->name || event->reply_userdata != 0) return {};

  if (std::strcmp(prop->name, "current-ao") == 0) {
    // Unavailable (MPV_FORMAT_NONE) is not an AO: the core has no AO at all
    // for the duration of an ao-reload - uninit, then re-init - and reports
    // exactly this in between. It says nothing about the outage either way,
    // and reading it as a recovery is what refilled the budget on every
    // reload and kept the watchdog going forever.
    if (prop->format != MPV_FORMAT_STRING || !prop->data) return {};
    const char* current_ao = *static_cast<char**>(prop->data);
    const bool is_null = current_ao && std::strcmp(current_ao, "null") == 0;
    const auto transition = state.SetCurrentAudioOutputNull(is_null, now);
    if (transition == AudioOutputTransition::kFellBackToNull) {
      return {"current-ao fell back to null; starting recovery", true};
    }
    if (transition == AudioOutputTransition::kRecovered) {
      return {"audio recovered (current-ao no longer null)", false};
    }
    return {};
  }
  if (std::strcmp(prop->name, "audio-device-list") == 0 && state.OnAudioDeviceListChanged(now)) {
    return {"audio-device-list changed while ao=null; rescheduling ao-reload", true};
  }
  return {};
}

}  // namespace mpv_common
}  // namespace plezy

#endif  // PLEZY_SHARED_MPV_PLAYER_COMMON_H_
