#include "mpv_player.h"

#include <windowsx.h>

#include "sanitize_utf8.h"

namespace mpv {

namespace {

flutter::EncodableValue NodeToEncodableValue(const mpv_node* node) {
  if (!node) return flutter::EncodableValue();

  switch (node->format) {
    case MPV_FORMAT_STRING:
      return flutter::EncodableValue(SanitizeUtf8(node->u.string));
    case MPV_FORMAT_FLAG:
      return flutter::EncodableValue(node->u.flag != 0);
    case MPV_FORMAT_INT64:
      return flutter::EncodableValue(node->u.int64);
    case MPV_FORMAT_DOUBLE:
      return flutter::EncodableValue(node->u.double_);
    case MPV_FORMAT_NODE_ARRAY: {
      const mpv_node_list* node_list = node->u.list;
      if (!node_list || node_list->num < 0 || (node_list->num > 0 && !node_list->values)) {
        return flutter::EncodableValue();
      }
      flutter::EncodableList list;
      list.reserve(static_cast<size_t>(node_list->num));
      for (int i = 0; i < node_list->num; ++i) {
        list.push_back(NodeToEncodableValue(&node_list->values[i]));
      }
      return flutter::EncodableValue(list);
    }
    case MPV_FORMAT_NODE_MAP: {
      const mpv_node_list* node_list = node->u.list;
      if (!node_list || node_list->num < 0 || (node_list->num > 0 && (!node_list->values || !node_list->keys))) {
        return flutter::EncodableValue();
      }
      flutter::EncodableMap map;
      for (int i = 0; i < node_list->num; ++i) {
        map[flutter::EncodableValue(SanitizeUtf8(node_list->keys[i]))] = NodeToEncodableValue(&node_list->values[i]);
      }
      return flutter::EncodableValue(map);
    }
    default:
      return flutter::EncodableValue();
  }
}

// DComp-mode input forwarding. mpv's inner window lives on mpv's own thread
// and consumes input over the video (WS_EX_TRANSPARENT hit-test skipping is
// same-thread-only, and disabling the subtree makes the system drop the input
// entirely instead of routing it to a sibling). Subclass the inner window
// (legal within one process, even across threads) and forward mouse and pointer
// input to the Flutter view. Pointer messages must be sent synchronously:
// Flutter calls GetPointerInfo while handling them, and Windows only retains
// that data for the current or forwarded message.
constexpr bool IsFlutterPointerMessage(UINT message) {
  switch (message) {
    case WM_POINTERDOWN:
    case WM_POINTERUPDATE:
    case WM_POINTERUP:
    case WM_POINTERLEAVE:
      return true;
    default:
      return false;
  }
}

static_assert(IsFlutterPointerMessage(WM_POINTERDOWN));
static_assert(IsFlutterPointerMessage(WM_POINTERUPDATE));
static_assert(IsFlutterPointerMessage(WM_POINTERUP));
static_assert(IsFlutterPointerMessage(WM_POINTERLEAVE));
static_assert(!IsFlutterPointerMessage(WM_MOUSEMOVE));

WNDPROC g_mpv_inner_original_proc = nullptr;
HWND g_mpv_inner_hwnd = nullptr;
HWND g_forward_target_view = nullptr;

LRESULT CALLBACK MpvInnerSubclassProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (IsFlutterPointerMessage(message)) {
    HWND view = g_forward_target_view;
    if (view) {
      // WM_POINTER coordinates are already in screen space. SendMessage also
      // preserves the message association required by GetPointerInfo in the
      // Flutter view's window procedure.
      ::SendMessageW(view, message, wparam, lparam);
    }
    return 0;
  }

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

MpvPlayer::MpvPlayer(bool audio_only) : audio_only_(audio_only) {}

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

  if (audio_only_) {
    // Windowless music core: no HWND, no VO, no video decode. vid=no keeps
    // embedded cover art from ever becoming a video track, and
    // force-window/audio-display make sure mpv never opens a video output
    // for it either.
    mpv_set_option_string(mpv_, "vid", "no");
    mpv_set_option_string(mpv_, "force-window", "no");
    mpv_set_option_string(mpv_, "audio-display", "no");
    mpv_set_option_string(mpv_, "gapless-audio", "weak");
  } else {
    // Create a child window for mpv to render into, parented to the Flutter
    // |view|. The video child then sits in the view's own per-window layer
    // stack, above the view's (never-painted) layer-1 content and below the
    // engine's topmost DComp visual carrying the UI. WS_CLIPSIBLINGS keeps it
    // from painting over neighboring view children. Mouse, touch, and stylus
    // input over the video is delivered to mpv's own inner window (on mpv's
    // thread); the subclass installed in EnsureMpvInnerSubclassed forwards it
    // back to the Flutter view.
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

    mpv_set_option_string(mpv_, "vo", "gpu-next");
    mpv_set_option_string(mpv_, "gpu-api", "auto");
    // hwdec is set from Flutter via setProperty based on user preference
  }

  // Configure mpv for embedded playback.
  mpv_set_option_string(mpv_, "keep-open", "yes");
  mpv_set_option_string(mpv_, "idle", "yes");
  mpv_set_option_string(mpv_, "input-default-bindings", "no");
  mpv_set_option_string(mpv_, "input-vo-keyboard", "no");
  // Hardware media keys are owned by the SMTC integration (os_media_controls);
  // mpv's default handling would double-handle Play/Pause.
  mpv_set_option_string(mpv_, "input-media-keys", "no");
  mpv_set_option_string(mpv_, "osc", "no");

  if (!audio_only_) {
    // Let mpv use display/context detection instead of forcing HDR signaling.
    mpv_set_option_string(mpv_, "target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(hdr_enabled_));

    // Fallback tone mapping when display doesn't support HDR
    mpv_set_option_string(mpv_, "tone-mapping", "auto");
    mpv_set_option_string(mpv_, "hdr-compute-peak", "auto");
  }

  // When WASAPI becomes unavailable (sleep, device unplug), fall back to null
  // audio output instead of permanently dropping the audio track. Recovery is
  // handled by MaybeRunAudioRecovery in the event loop.
  mpv_set_option_string(mpv_, "audio-fallback-to-null", "yes");

  // Default to warn-level logging; Dart side can raise to "v" if debug logging is enabled.
  mpv_request_log_messages(mpv_, "warn");

  // Initialize mpv.
  int err = mpv_initialize(mpv_);
  if (err < 0) {
    if (hwnd_) {
      ::DestroyWindow(hwnd_);
      hwnd_ = nullptr;
    }
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  mpv_observe_property(mpv_, 0, "current-ao", MPV_FORMAT_STRING);
  // Native observation so audio recovery doesn't depend on the Dart side
  // choosing to observe the device list.
  mpv_observe_property(mpv_, 0, "audio-device-list", MPV_FORMAT_NONE);

  // Start event loop.
  StartEventLoop();

  return true;
}

void MpvPlayer::Dispose() {
  StopEventLoop();

  auto cancelled = pending_requests_.CancelAll();
  for (auto& callback : cancelled.status) {
    callback(-1);
  }
  for (auto& callback : cancelled.properties) {
    callback(-1, "");
  }

  // Detach the native handle before releasing platform-owned state. mpv can
  // block in demuxer/network teardown, so only the detached handle crosses to
  // the worker; it must not retain this player, callbacks, or HWNDs.
  auto* handle = mpv_;
  mpv_ = nullptr;

  if (hwnd_) {
    ::ShowWindow(hwnd_, SW_HIDE);
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;

    // The subclassed inner window died with hwnd_; clear the forwarding
    // state. Only the owner of the window may do this: the audio-only core
    // (which never has an hwnd_) must not wipe the video instance's state.
    g_mpv_inner_hwnd = nullptr;
    g_mpv_inner_original_proc = nullptr;
    g_forward_target_view = nullptr;
  }

  if (handle) {
    std::thread([handle]() { mpv_terminate_destroy(handle); }).detach();
  }

  observed_properties_.Clear();
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

  uint64_t request_id = callback ? pending_requests_.RegisterStatus(std::move(callback)) : 0;

  // mpv_command_async returns immediately
  int result = mpv_command_async(mpv_, request_id, c_args.data());
  if (result < 0) {
    auto cb = pending_requests_.TakeStatus(request_id);
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
    SetHDREnabled(plezy::mpv_common::ParseEnabledFlag(value), std::move(callback));
    return;
  }

  uint64_t request_id = callback ? pending_requests_.RegisterStatus(std::move(callback)) : 0;

  char* property_value = const_cast<char*>(value.c_str());
  int result = mpv_set_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING, &property_value);
  if (result < 0) {
    auto cb = pending_requests_.TakeStatus(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::GetPropertyAsync(const std::string& name, GetPropertyCallback callback) {
  if (!mpv_) {
    if (callback) callback(-1, "");
    return;
  }

  uint64_t request_id = pending_requests_.RegisterProperty(std::move(callback));

  int result = mpv_get_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING);
  if (result < 0) {
    auto cb = pending_requests_.TakeProperty(request_id);
    if (cb) cb(result, "");
  }
}

void MpvPlayer::ObserveProperty(const std::string& name, const std::string& format, int id) {
  if (!mpv_) return;

  const auto request = observed_properties_.Register(name, format, id);
  if (!request.added) return;
  mpv_observe_property(mpv_, request.userdata, name.c_str(), request.format);
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
  // re-subclass if mpv ever recreates it) so mouse and pointer input over the
  // video is forwarded to the Flutter view.
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

void MpvPlayer::NotifyPowerSuspend() { LogRecovery("system suspending"); }

void MpvPlayer::NotifyPowerResume() { audio_recovery_.RequestResume(); }

void MpvPlayer::LogRecovery(const std::string& text) {
  char log_msg[512];
  snprintf(log_msg, sizeof(log_msg), "MPV [warn] audio-recovery: %s", text.c_str());
  OutputDebugStringA(log_msg);

  // Emitted as a synthetic log-message event so it reaches the app logs
  // regardless of the mpv log level.
  flutter::EncodableMap data;
  data[flutter::EncodableValue("prefix")] = flutter::EncodableValue("audio-recovery");
  data[flutter::EncodableValue("level")] = flutter::EncodableValue("warn");
  data[flutter::EncodableValue("text")] = flutter::EncodableValue(text);
  SendEvent("log-message", data);
}

void MpvPlayer::TryAudioReload(const char* reason, int attempt) {
  LogRecovery("issuing ao-reload (reason=" + std::string(reason) + ", attempt " + std::to_string(attempt) + ")");
  const std::string reason_copy = reason;
  CommandAsync({"ao-reload"}, [this, reason_copy, attempt](int error) {
    audio_recovery_.CompleteReload();
    LogRecovery(
        "ao-reload completed (reason=" + reason_copy + ", attempt " + std::to_string(attempt) +
        ", error=" + std::to_string(error) + ")");
  });
}

void MpvPlayer::MaybeRunAudioRecovery() {
  const auto action = audio_recovery_.NextReload(plezy::mpv_common::AudioRecoveryState::Clock::now());
  if (action.reason == plezy::mpv_common::AudioReloadReason::kNone) {
    return;
  }
  const char* reason = action.reason == plezy::mpv_common::AudioReloadReason::kResume ? "resume" : "null-fallback";
  TryAudioReload(reason, action.attempt);
  if (action.exhausted) {
    LogRecovery("audio recovery budget exhausted; waiting for device list change");
  }
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
    if (event->event_id == MPV_EVENT_SHUTDOWN) {
      break;
    }
    if (event->event_id != MPV_EVENT_NONE) {
      HandleMpvEvent(event);
    }
    // Runs on every iteration including wait timeouts: this ~100ms tick is
    // the clock that drives scheduled audio reload attempts.
    MaybeRunAudioRecovery();
  }
}

void MpvPlayer::HandleMpvEvent(mpv_event* event) {
  switch (event->event_id) {
    case MPV_EVENT_COMMAND_REPLY:
    case MPV_EVENT_SET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      StatusCallback callback = pending_requests_.TakeStatus(request_id);
      if (callback) {
        callback(event->error);
      }
      break;
    }
    case MPV_EVENT_GET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      GetPropertyCallback callback = pending_requests_.TakeProperty(request_id);
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
      mpv_node node{};
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

      if (strcmp(prop->name, "current-ao") == 0) {
        const char* current_ao = nullptr;
        if (prop->format == MPV_FORMAT_STRING && prop->data) {
          current_ao = *static_cast<char**>(prop->data);
        }
        const bool is_null = current_ao && strcmp(current_ao, "null") == 0;
        const auto transition =
            audio_recovery_.SetCurrentAudioOutputNull(is_null, plezy::mpv_common::AudioRecoveryState::Clock::now());
        if (transition == plezy::mpv_common::AudioOutputTransition::kFellBackToNull) {
          LogRecovery("current-ao fell back to null; starting recovery");
        } else if (transition == plezy::mpv_common::AudioOutputTransition::kRecovered) {
          LogRecovery("audio recovered (current-ao no longer null)");
        }
      }
      if (strcmp(prop->name, "audio-device-list") == 0 && event->reply_userdata == 0 &&
          audio_recovery_.OnAudioDeviceListChanged(plezy::mpv_common::AudioRecoveryState::Clock::now())) {
        LogRecovery("audio-device-list changed while ao=null; rescheduling ao-reload");
      }

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
      audio_recovery_.SetFileLoaded(false);
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
      audio_recovery_.SetFileLoaded(true);
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
    default:
      break;
  }
}

void MpvPlayer::SendPropertyChange(const char* name, mpv_node* data) {
  if (!name) return;

  int id = 0;
  if (!observed_properties_.LookupId(name, &id)) return;

  // mpv owns event node storage; copy the full tree before the callback can
  // queue it beyond the current mpv_wait_event result's lifetime.
  flutter::EncodableList list;
  list.push_back(flutter::EncodableValue(id));
  list.push_back(NodeToEncodableValue(data));

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
  if (!mpv_) {
    if (callback) callback(0);
    return;
  }
  SetPropertyAsync("target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(enabled), std::move(callback));
}

}  // namespace mpv
