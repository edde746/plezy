#ifndef PLEZY_SHARED_MPV_PLAYER_COMMON_H_
#define PLEZY_SHARED_MPV_PLAYER_COMMON_H_

#include <mpv/client.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <map>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

namespace plezy {
namespace mpv_common {

using StatusCallback = std::function<void(int error)>;
using GetPropertyCallback = std::function<void(int error, const std::string& value)>;

struct CancelledRequests {
  std::vector<StatusCallback> status;
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
    cancelled.properties.reserve(properties_.size());
    for (auto& request : properties_) {
      if (request.second) {
        cancelled.properties.push_back(std::move(request.second));
      }
    }
    status_.clear();
    properties_.clear();
    return cancelled;
  }

 private:
  uint64_t next_id_ = 1;
  std::map<uint64_t, StatusCallback> status_;
  std::map<uint64_t, GetPropertyCallback> properties_;
  std::mutex mutex_;
};

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
    if (userdata_by_name_.find(name) != userdata_by_name_.end()) {
      return {false, 0, MPV_FORMAT_NONE};
    }
    const uint64_t userdata = next_userdata_++;
    userdata_by_name_[name] = userdata;
    id_by_name_[name] = id;
    return {true, userdata, ParsePropertyFormat(format)};
  }

  bool LookupId(const std::string& name, int* id) const {
    const auto it = id_by_name_.find(name);
    if (it == id_by_name_.end()) return false;
    *id = it->second;
    return true;
  }

  void Clear() {
    userdata_by_name_.clear();
    id_by_name_.clear();
  }

 private:
  uint64_t next_userdata_ = 1;
  std::map<std::string, uint64_t> userdata_by_name_;
  std::map<std::string, int> id_by_name_;
};

inline bool ParseEnabledFlag(const std::string& value) { return value == "yes" || value == "true" || value == "1"; }

inline const char* TargetColorspaceHint(bool hdr_enabled) { return hdr_enabled ? "auto" : "no"; }

enum class AudioReloadReason { kNone, kResume, kNullFallback };

struct AudioReloadAction {
  AudioReloadReason reason = AudioReloadReason::kNone;
  int attempt = 0;
  bool exhausted = false;
};

enum class AudioOutputTransition { kNone, kFellBackToNull, kRecovered };

class AudioRecoveryState {
 public:
  using Clock = std::chrono::steady_clock;

  void SetFileLoaded(bool loaded) {
    file_loaded_ = loaded;
    if (!loaded) {
      resume_attempts_left_ = 0;
      null_attempts_left_ = 0;
    }
  }

  void RequestResume() { resume_requested_.store(true); }

  AudioOutputTransition SetCurrentAudioOutputNull(bool is_null, Clock::time_point now) {
    if (is_null == current_ao_is_null_) return AudioOutputTransition::kNone;
    current_ao_is_null_ = is_null;
    if (is_null) {
      null_attempts_left_ = kNullRetryBudget;
      null_backoff_ = NullFirstDelay();
      null_next_attempt_ = now + NullFirstDelay();
      return AudioOutputTransition::kFellBackToNull;
    }
    null_attempts_left_ = 0;
    return AudioOutputTransition::kRecovered;
  }

  bool OnAudioDeviceListChanged(Clock::time_point now) {
    if (!current_ao_is_null_) return false;
    const auto candidate = now + DeviceListDebounce();
    if (null_attempts_left_ <= 0 || candidate < null_next_attempt_) {
      null_next_attempt_ = candidate;
    }
    null_attempts_left_ = kNullRetryBudget;
    null_backoff_ = NullFirstDelay();
    return true;
  }

  AudioReloadAction NextReload(Clock::time_point now) {
    if (resume_requested_.exchange(false) && file_loaded_) {
      resume_attempts_left_ = kResumeReloadAttempts;
      resume_next_attempt_ = now + ResumeFirstDelay();
    }
    if (reload_pending_) return {};

    if (resume_attempts_left_ > 0 && now >= resume_next_attempt_) {
      const int attempt = kResumeReloadAttempts - resume_attempts_left_ + 1;
      --resume_attempts_left_;
      resume_next_attempt_ = now + ResumeRetryDelay();
      reload_pending_ = true;
      return {AudioReloadReason::kResume, attempt, false};
    }

    if (null_attempts_left_ > 0 && now >= null_next_attempt_) {
      if (!current_ao_is_null_) {
        null_attempts_left_ = 0;
        return {};
      }
      const int attempt = kNullRetryBudget - null_attempts_left_ + 1;
      --null_attempts_left_;
      null_next_attempt_ = now + null_backoff_;
      null_backoff_ = std::min(null_backoff_ * 2, NullBackoffCap());
      reload_pending_ = true;
      return {AudioReloadReason::kNullFallback, attempt, null_attempts_left_ == 0};
    }
    return {};
  }

  void CompleteReload() { reload_pending_ = false; }

  bool HasPendingWork() const {
    return resume_requested_.load() || resume_attempts_left_ > 0 || null_attempts_left_ > 0 || reload_pending_;
  }

  bool current_audio_output_is_null() const { return current_ao_is_null_; }

  static int NullRetryBudget() { return kNullRetryBudget; }

 private:
  static constexpr int kResumeReloadAttempts = 2;
  static constexpr int kNullRetryBudget = 5;

  static std::chrono::milliseconds ResumeFirstDelay() { return std::chrono::milliseconds(1500); }
  static std::chrono::milliseconds ResumeRetryDelay() { return std::chrono::milliseconds(4500); }
  static std::chrono::milliseconds NullFirstDelay() { return std::chrono::milliseconds(500); }
  static std::chrono::milliseconds NullBackoffCap() { return std::chrono::milliseconds(8000); }
  static std::chrono::milliseconds DeviceListDebounce() { return std::chrono::milliseconds(250); }

  std::atomic<bool> resume_requested_{false};
  bool file_loaded_ = false;
  bool current_ao_is_null_ = false;
  bool reload_pending_ = false;
  int resume_attempts_left_ = 0;
  Clock::time_point resume_next_attempt_{};
  int null_attempts_left_ = 0;
  Clock::time_point null_next_attempt_{};
  std::chrono::milliseconds null_backoff_{0};
};

}  // namespace mpv_common
}  // namespace plezy

#endif  // PLEZY_SHARED_MPV_PLAYER_COMMON_H_
