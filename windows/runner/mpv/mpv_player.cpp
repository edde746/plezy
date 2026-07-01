#include "mpv_player.h"

#include <windowsx.h>

#include "sanitize_utf8.h"

namespace mpv {

namespace {

// DComp-mode input forwarding. mpv's inner window lives on mpv's own thread
// and consumes the mouse input over the video (WS_EX_TRANSPARENT hit-test
// skipping is same-thread-only, and disabling the subtree makes the system
// drop the input entirely instead of routing it to a sibling). Subclass the
// inner window (legal within one process, even across threads) and forward
// mouse input to the Flutter view with coordinates translated into view
// space. The subclass proc runs on mpv's thread and only uses thread-safe
// calls (PostMessage / MapWindowPoints / CallWindowProc).
WNDPROC g_mpv_inner_original_proc = nullptr;
HWND g_mpv_inner_hwnd = nullptr;
HWND g_forward_target_view = nullptr;

LRESULT CALLBACK MpvInnerSubclassProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message >= WM_MOUSEFIRST && message <= WM_MOUSELAST) {
    HWND view = g_forward_target_view;
    if (view) {
      LPARAM forwarded = lparam;
      if (message != WM_MOUSEWHEEL && message != WM_MOUSEHWHEEL) {
        // Client coordinates: translate inner-window-space -> view-space.
        // (Wheel messages carry screen coordinates; pass through unchanged.)
        POINT pt = {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
        ::MapWindowPoints(hwnd, view, &pt, 1);
        forwarded = MAKELPARAM(pt.x, pt.y);
      }
      ::PostMessage(view, message, wparam, forwarded);
    }
    return 0;
  }
  return ::CallWindowProc(g_mpv_inner_original_proc, hwnd, message, wparam, lparam);
}

// Subclass mpv's lazily-created inner window if it exists and isn't yet
// subclassed (or was recreated). Idempotent; callable from any thread in
// this process.
void EnsureMpvInnerSubclassed(HWND host) {
  if (!host) {
    return;
  }
  HWND inner = ::FindWindowExW(host, nullptr, nullptr, nullptr);
  if (inner && inner != g_mpv_inner_hwnd) {
    g_mpv_inner_hwnd = inner;
    g_mpv_inner_original_proc = reinterpret_cast<WNDPROC>(
        ::SetWindowLongPtrW(inner, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(MpvInnerSubclassProc)));
  }
}

}  // namespace

MpvPlayer::MpvPlayer() {}

MpvPlayer::~MpvPlayer() { Dispose(); }

bool MpvPlayer::Initialize(HWND view) {
  if (mpv_) {
    return true;  // Already initialized.
  }

  // Create mpv instance.
  mpv_ = mpv_create();
  if (!mpv_) {
    return false;
  }

  // Create a child window for mpv to render into, parented to the Flutter
  // |view|. The video child then sits in the view's own per-window layer
  // stack, above the view's (never-painted) layer-1 content and below the
  // engine's topmost DComp visual carrying the UI. WS_CLIPSIBLINGS keeps it
  // from painting over neighboring view children. Mouse input over the video
  // is delivered to mpv's own inner window (on mpv's thread); the subclass
  // installed in EnsureMpvInnerSubclassed forwards it back to the view.
  hwnd_ = ::CreateWindowExW(
      WS_EX_NOPARENTNOTIFY, L"STATIC", L"", WS_CHILD | WS_CLIPSIBLINGS, 0, 0, 100, 100, view, nullptr,
      GetModuleHandle(nullptr), nullptr);
  if (!hwnd_) {
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }
  g_forward_target_view = view;

  // Set the wid option to embed mpv in our window.
  int64_t wid = reinterpret_cast<int64_t>(hwnd_);
  mpv_set_option(mpv_, "wid", MPV_FORMAT_INT64, &wid);

  // Configure mpv for embedded playback.
  mpv_set_option_string(mpv_, "vo", "gpu-next");
  mpv_set_option_string(mpv_, "gpu-api", "auto");
  // hwdec is set from Flutter via setProperty based on user preference
  mpv_set_option_string(mpv_, "keep-open", "yes");
  mpv_set_option_string(mpv_, "idle", "yes");
  mpv_set_option_string(mpv_, "input-default-bindings", "no");
  mpv_set_option_string(mpv_, "input-vo-keyboard", "no");
  mpv_set_option_string(mpv_, "osc", "no");

  // Let mpv use display/context detection instead of forcing HDR signaling.
  mpv_set_option_string(mpv_, "target-colorspace-hint", "auto");

  // Fallback tone mapping when display doesn't support HDR
  mpv_set_option_string(mpv_, "tone-mapping", "auto");
  mpv_set_option_string(mpv_, "hdr-compute-peak", "auto");

  // When WASAPI becomes unavailable (sleep, device unplug), fall back to null
  // audio output instead of permanently dropping the audio track. Recovery is
  // handled in the event loop when audio-device-list changes.
  mpv_set_option_string(mpv_, "audio-fallback-to-null", "yes");

  // Default to warn-level logging; Dart side can raise to "v" if debug logging is enabled.
  mpv_request_log_messages(mpv_, "warn");

  // Initialize mpv.
  int err = mpv_initialize(mpv_);
  if (err < 0) {
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // Observe video-params/sig-peak for HDR detection
  mpv_observe_property(mpv_, 0, "video-params/sig-peak", MPV_FORMAT_DOUBLE);
  mpv_observe_property(mpv_, 0, "current-ao", MPV_FORMAT_STRING);

  // Start event loop.
  StartEventLoop();

  return true;
}

void MpvPlayer::Dispose() {
  StopEventLoop();

  // Cancel pending async requests
  std::vector<StatusCallback> status_callbacks;
  std::vector<GetPropertyCallback> get_callbacks;
  {
    std::lock_guard<std::mutex> lock(pending_requests_mutex_);
    for (auto& pair : pending_status_requests_) {
      if (pair.second) status_callbacks.push_back(std::move(pair.second));
    }
    for (auto& pair : pending_get_property_requests_) {
      if (pair.second) get_callbacks.push_back(std::move(pair.second));
    }
    pending_status_requests_.clear();
    pending_get_property_requests_.clear();
  }
  for (auto& callback : status_callbacks) {
    callback(-1);
  }
  for (auto& callback : get_callbacks) {
    callback(-1, "");
  }

  if (mpv_) {
    mpv_terminate_destroy(mpv_);
    mpv_ = nullptr;
  }

  if (hwnd_) {
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }

  // The subclassed inner window died with hwnd_; clear the forwarding state.
  g_mpv_inner_hwnd = nullptr;
  g_mpv_inner_original_proc = nullptr;

  observed_properties_.clear();
}

void MpvPlayer::Command(const std::vector<std::string>& args) { CommandAsync(args, nullptr); }

void MpvPlayer::CommandAsync(const std::vector<std::string>& args, CommandCallback callback) {
  if (!mpv_) {
    if (callback) callback(0);
    return;
  }

  std::vector<const char*> c_args;
  c_args.reserve(args.size() + 1);
  for (const auto& arg : args) {
    c_args.push_back(arg.c_str());
  }
  c_args.push_back(nullptr);

  uint64_t request_id = callback ? RegisterStatusRequest(std::move(callback)) : 0;

  // mpv_command_async returns immediately
  int result = mpv_command_async(mpv_, request_id, c_args.data());
  if (result < 0) {
    auto cb = TakeStatusRequest(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  SetPropertyAsync(name, value, nullptr);
}

void MpvPlayer::SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback) {
  if (!mpv_) {
    if (callback) callback(0);
    return;
  }

  // Handle custom HDR toggle property (same pattern as iOS/macOS)
  if (name == "hdr-enabled") {
    bool enabled = (value == "yes" || value == "true" || value == "1");
    SetHDREnabled(enabled, std::move(callback));
    return;
  }

  uint64_t request_id = callback ? RegisterStatusRequest(std::move(callback)) : 0;

  char* property_value = const_cast<char*>(value.c_str());
  int result = mpv_set_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING, &property_value);
  if (result < 0) {
    auto cb = TakeStatusRequest(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::GetPropertyAsync(const std::string& name, GetPropertyCallback callback) {
  if (!mpv_) {
    if (callback) callback(-1, "");
    return;
  }

  uint64_t request_id = RegisterGetPropertyRequest(std::move(callback));

  int result = mpv_get_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING);
  if (result < 0) {
    auto cb = TakeGetPropertyRequest(request_id);
    if (cb) cb(result, "");
  }
}

uint64_t MpvPlayer::RegisterStatusRequest(StatusCallback callback) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  uint64_t request_id = next_reply_userdata_++;
  pending_status_requests_[request_id] = std::move(callback);
  return request_id;
}

MpvPlayer::StatusCallback MpvPlayer::TakeStatusRequest(uint64_t request_id) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  auto it = pending_status_requests_.find(request_id);
  if (it == pending_status_requests_.end()) return nullptr;
  auto callback = std::move(it->second);
  pending_status_requests_.erase(it);
  return callback;
}

uint64_t MpvPlayer::RegisterGetPropertyRequest(GetPropertyCallback callback) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  uint64_t request_id = next_reply_userdata_++;
  pending_get_property_requests_[request_id] = std::move(callback);
  return request_id;
}

MpvPlayer::GetPropertyCallback MpvPlayer::TakeGetPropertyRequest(uint64_t request_id) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  auto it = pending_get_property_requests_.find(request_id);
  if (it == pending_get_property_requests_.end()) return nullptr;
  auto callback = std::move(it->second);
  pending_get_property_requests_.erase(it);
  return callback;
}

void MpvPlayer::ObserveProperty(const std::string& name, const std::string& format, int id) {
  if (!mpv_) return;

  // Check if already observing.
  if (observed_properties_.find(name) != observed_properties_.end()) {
    return;
  }

  name_to_id_[name] = id;

  mpv_format mpv_fmt = MPV_FORMAT_NONE;
  if (format == "string") {
    mpv_fmt = MPV_FORMAT_STRING;
  } else if (format == "flag" || format == "bool") {
    mpv_fmt = MPV_FORMAT_FLAG;
  } else if (format == "int64") {
    mpv_fmt = MPV_FORMAT_INT64;
  } else if (format == "double") {
    mpv_fmt = MPV_FORMAT_DOUBLE;
  } else if (format == "node") {
    mpv_fmt = MPV_FORMAT_NODE;
  }

  uint64_t userdata = next_reply_userdata_++;
  observed_properties_[name] = userdata;
  mpv_observe_property(mpv_, userdata, name.c_str(), mpv_fmt);
}

void MpvPlayer::SetRect(RECT rect, double device_pixel_ratio) {
  if (!hwnd_) {
    return;
  }

  // The video window is a child of the Flutter view; the Dart rect is already
  // in view physical pixels, which is exactly the child coordinate space. No
  // screen mapping, no padding.
  ::SetWindowPos(hwnd_, HWND_TOP, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, SWP_NOACTIVATE);

  // mpv creates its inner window lazily on its own thread; subclass it (and
  // re-subclass if mpv ever recreates it) so mouse input over the video is
  // forwarded to the Flutter view.
  EnsureMpvInnerSubclassed(hwnd_);
}

void MpvPlayer::SetVisible(bool visible) {
  if (hwnd_) {
    ::ShowWindow(hwnd_, visible ? SW_SHOW : SW_HIDE);
  }
}

void MpvPlayer::SetLogLevel(const std::string& level) {
  if (!mpv_) return;
  mpv_request_log_messages(mpv_, level.c_str());
}

void MpvPlayer::SetEventCallback(EventCallback callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  event_callback_ = std::move(callback);
}

void MpvPlayer::ReloadAudioOutput() {
  if (audio_reload_pending_) return;
  audio_reload_pending_ = true;
  CommandAsync({"ao-reload"}, [this](int) { audio_reload_pending_ = false; });
}

void MpvPlayer::StartEventLoop() {
  running_ = true;
  event_thread_ = std::thread(&MpvPlayer::EventLoop, this);
}

void MpvPlayer::StopEventLoop() {
  running_ = false;
  if (event_thread_.joinable()) {
    // Wake up the event loop.
    if (mpv_) {
      mpv_wakeup(mpv_);
    }
    event_thread_.join();
  }
}

void MpvPlayer::EventLoop() {
  while (running_) {
    mpv_event* event = mpv_wait_event(mpv_, 0.1);
    if (event->event_id == MPV_EVENT_NONE) {
      continue;
    }
    if (event->event_id == MPV_EVENT_SHUTDOWN) {
      break;
    }
    HandleMpvEvent(event);
  }
}

void MpvPlayer::HandleMpvEvent(mpv_event* event) {
  switch (event->event_id) {
    case MPV_EVENT_COMMAND_REPLY:
    case MPV_EVENT_SET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      StatusCallback callback = TakeStatusRequest(request_id);
      if (callback) {
        callback(event->error);
      }
      break;
    }
    case MPV_EVENT_GET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      GetPropertyCallback callback = TakeGetPropertyRequest(request_id);
      if (callback) {
        std::string value;
        if (event->error >= 0) {
          auto* prop = static_cast<mpv_event_property*>(event->data);
          if (prop && prop->format == MPV_FORMAT_STRING && prop->data) {
            auto c_value = *static_cast<char**>(prop->data);
            if (c_value) value = SanitizeUtf8(c_value);
          }
        }
        callback(event->error, value);
      }
      break;
    }
    case MPV_EVENT_LOG_MESSAGE: {
      auto* msg = static_cast<mpv_event_log_message*>(event->data);
      char log_msg[512];
      snprintf(log_msg, sizeof(log_msg), "MPV [%s] %s: %s", msg->level, msg->prefix, msg->text);
      OutputDebugStringA(log_msg);

      flutter::EncodableMap data;
      data[flutter::EncodableValue("prefix")] = flutter::EncodableValue(SanitizeUtf8(msg->prefix));
      data[flutter::EncodableValue("level")] = flutter::EncodableValue(SanitizeUtf8(msg->level));
      data[flutter::EncodableValue("text")] = flutter::EncodableValue(SanitizeUtf8(msg->text));
      SendEvent("log-message", data);
      break;
    }
    case MPV_EVENT_PROPERTY_CHANGE: {
      auto* prop = static_cast<mpv_event_property*>(event->data);
      mpv_node node;
      node.format = prop->format;

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
          }
          break;
        default:
          node.format = MPV_FORMAT_NONE;
          break;
      }

      // Handle sig-peak for HDR detection
      if (strcmp(prop->name, "video-params/sig-peak") == 0 && prop->format == MPV_FORMAT_DOUBLE && prop->data) {
        double sigPeak = *static_cast<double*>(prop->data);
        last_sig_peak_ = sigPeak;
        UpdateHDRMode(sigPeak);
      }

      if (strcmp(prop->name, "current-ao") == 0) {
        const char* current_ao = nullptr;
        if (prop->format == MPV_FORMAT_STRING && prop->data) {
          current_ao = *static_cast<char**>(prop->data);
        }
        current_ao_is_null_ = current_ao && strcmp(current_ao, "null") == 0;
      }

      // Audio recovery for sleep/wake or unplugged devices.
      // Mirrors mpv's TOOLS/lua/ao-null-reload.lua for embedded libmpv.
      if (strcmp(prop->name, "audio-device-list") == 0 && current_ao_is_null_) {
        ReloadAudioOutput();
      }

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
      auto* end = static_cast<mpv_event_end_file*>(event->data);
      flutter::EncodableMap data;
      data[flutter::EncodableValue("reason")] = flutter::EncodableValue(static_cast<int>(end->reason));
      if (end->reason == MPV_END_FILE_REASON_ERROR) {
        data[flutter::EncodableValue("error")] = flutter::EncodableValue(static_cast<int>(end->error));
        data[flutter::EncodableValue("message")] = flutter::EncodableValue(SanitizeUtf8(mpv_error_string(end->error)));
      }
      SendEvent("end-file", data);
      break;
    }
    case MPV_EVENT_FILE_LOADED: {
      SendEvent("file-loaded");
      break;
    }
    case MPV_EVENT_PLAYBACK_RESTART: {
      // mpv's inner window exists by now (vo is configured); make sure the
      // DComp-mode input forwarding subclass is installed. SetRect alone can
      // miss it: the rect often settles before mpv creates the window.
      EnsureMpvInnerSubclassed(hwnd_);
      SendEvent("playback-restart");
      break;
    }
    case MPV_EVENT_SEEK: {
      SendEvent("seek");
      break;
    }
    default:
      break;
  }
}

void MpvPlayer::SendPropertyChange(const char* name, mpv_node* data) {
  if (!name) return;

  auto it = name_to_id_.find(name);
  if (it == name_to_id_.end()) return;

  flutter::EncodableValue value;
  if (data) {
    switch (data->format) {
      case MPV_FORMAT_STRING:
        value = flutter::EncodableValue(SanitizeUtf8(data->u.string));
        break;
      case MPV_FORMAT_FLAG:
        value = flutter::EncodableValue(data->u.flag != 0);
        break;
      case MPV_FORMAT_INT64:
        value = flutter::EncodableValue(data->u.int64);
        break;
      case MPV_FORMAT_DOUBLE:
        value = flutter::EncodableValue(data->u.double_);
        break;
      default:
        value = flutter::EncodableValue();
        break;
    }
  }

  flutter::EncodableList list;
  list.push_back(flutter::EncodableValue(it->second));
  list.push_back(value);

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(flutter::EncodableValue(list));
  }
}

void MpvPlayer::SendEvent(const std::string& name, const flutter::EncodableMap& data) {
  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] = flutter::EncodableValue("event");
  event[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
  if (!data.empty()) {
    event[flutter::EncodableValue("data")] = flutter::EncodableValue(data);
  }

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(flutter::EncodableValue(event));
  }
}

void MpvPlayer::SetHDREnabled(bool enabled, StatusCallback callback) {
  hdr_enabled_ = enabled;

  if (mpv_) {
    SetPropertyAsync("target-colorspace-hint", enabled ? "auto" : "no", std::move(callback));
  } else if (callback) {
    callback(0);
  }

  UpdateHDRMode(last_sig_peak_);
}

void MpvPlayer::UpdateHDRMode(double sigPeak) {
  // On Windows, mpv handles HDR passthrough automatically when:
  // - target-colorspace-hint=auto
  // - Windows HDR is enabled in Display Settings
  // - Display supports HDR
  // No explicit DXGI calls needed - mpv's gpu-next/vulkan handles it
}

}  // namespace mpv
