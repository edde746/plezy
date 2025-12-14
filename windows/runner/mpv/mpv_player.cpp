#include "mpv_player.h"

#include <cstring>
#include <fstream>

static void LogToFile(const char* message) {
  std::ofstream log("C:\\Users\\admin\\mpv_debug.log", std::ios::app);
  if (log.is_open()) {
    log << message << std::endl;
    log.close();
  }
  OutputDebugStringA(message);
  OutputDebugStringA("\n");
}

namespace mpv {

MpvPlayer::MpvPlayer() {}

MpvPlayer::~MpvPlayer() { Dispose(); }

bool MpvPlayer::Initialize(HWND container, HWND flutter_window) {
  LogToFile("MpvPlayer::Initialize called");

  if (mpv_) {
    LogToFile("MpvPlayer::Initialize - already initialized");
    return true;  // Already initialized.
  }

  container_ = container;
  flutter_window_ = flutter_window;
  char msg[256];
  snprintf(msg, sizeof(msg), "MpvPlayer::Initialize - container: %p", container);
  LogToFile(msg);

  // Create mpv instance.
  LogToFile("MpvPlayer::Initialize - calling mpv_create()");
  mpv_ = mpv_create();
  if (!mpv_) {
    LogToFile("MPV: mpv_create() failed");
    return false;
  }
  LogToFile("MpvPlayer::Initialize - mpv_create() succeeded");

  // Create a child window for mpv to render into.
  LogToFile("MpvPlayer::Initialize - creating child window");
  hwnd_ = ::CreateWindowW(L"STATIC", L"", WS_CHILD | WS_VISIBLE, 0, 0, 100, 100,
                          container, nullptr, GetModuleHandle(nullptr),
                          nullptr);
  if (!hwnd_) {
    DWORD error = GetLastError();
    snprintf(msg, sizeof(msg), "MPV: CreateWindowW failed with error %lu", error);
    LogToFile(msg);
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }
  snprintf(msg, sizeof(msg), "MpvPlayer::Initialize - child window created: %p", hwnd_);
  LogToFile(msg);

  // Set the wid option to embed mpv in our window.
  int64_t wid = reinterpret_cast<int64_t>(hwnd_);
  int err = mpv_set_option(mpv_, "wid", MPV_FORMAT_INT64, &wid);
  if (err < 0) {
    snprintf(msg, sizeof(msg), "MPV: Failed to set wid option: %d %s", err, mpv_error_string(err));
    LogToFile(msg);
  } else {
    LogToFile("MpvPlayer::Initialize - wid option set successfully");
  }

  // Configure mpv for embedded playback.
  LogToFile("MpvPlayer::Initialize - setting mpv options");
  // hwdec is set from Flutter via setProperty based on user preference
  mpv_set_option_string(mpv_, "keep-open", "yes");
  mpv_set_option_string(mpv_, "idle", "yes");
  mpv_set_option_string(mpv_, "input-default-bindings", "no");
  mpv_set_option_string(mpv_, "input-vo-keyboard", "no");
  mpv_set_option_string(mpv_, "osc", "no");

  // HDR passthrough - let mpv handle color space
  mpv_set_option_string(mpv_, "target-colorspace-hint", "yes");

  // Fallback tone mapping when display doesn't support HDR
  mpv_set_option_string(mpv_, "tone-mapping", "auto");
  mpv_set_option_string(mpv_, "hdr-compute-peak", "auto");

  // Enable logging
  mpv_request_log_messages(mpv_, "v");

  // Initialize mpv.
  LogToFile("MpvPlayer::Initialize - calling mpv_initialize()");
  err = mpv_initialize(mpv_);
  if (err < 0) {
    snprintf(msg, sizeof(msg), "MPV: mpv_initialize() failed with error %d: %s",
             err, mpv_error_string(err));
    LogToFile(msg);
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  LogToFile("MPV: Initialization successful");

  // Observe video-params/sig-peak for HDR detection
  mpv_observe_property(mpv_, 0, "video-params/sig-peak", MPV_FORMAT_DOUBLE);

  // Start event loop.
  StartEventLoop();
  LogToFile("MpvPlayer::Initialize - event loop started");

  return true;
}

void MpvPlayer::Dispose() {
  StopEventLoop();

  if (mpv_) {
    mpv_terminate_destroy(mpv_);
    mpv_ = nullptr;
  }

  if (hwnd_) {
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }

  observed_properties_.clear();
}

void MpvPlayer::Command(const std::vector<std::string>& args) {
  if (!mpv_) return;

  std::vector<const char*> c_args;
  c_args.reserve(args.size() + 1);
  for (const auto& arg : args) {
    c_args.push_back(arg.c_str());
  }
  c_args.push_back(nullptr);

  mpv_command(mpv_, c_args.data());
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  if (!mpv_) return;

  // Handle custom HDR toggle property (same pattern as iOS/macOS)
  if (name == "hdr-enabled") {
    bool enabled = (value == "yes" || value == "true" || value == "1");
    SetHDREnabled(enabled);
    return;
  }

  mpv_set_property_string(mpv_, name.c_str(), value.c_str());
}

std::string MpvPlayer::GetProperty(const std::string& name) {
  if (!mpv_) return "";

  char* value = mpv_get_property_string(mpv_, name.c_str());
  if (!value) return "";

  std::string result(value);
  mpv_free(value);
  return result;
}

void MpvPlayer::ObserveProperty(const std::string& name,
                                const std::string& format) {
  if (!mpv_) return;

  // Check if already observing.
  if (observed_properties_.find(name) != observed_properties_.end()) {
    return;
  }

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
  rect_ = rect;
  device_pixel_ratio_ = device_pixel_ratio;

  if (hwnd_ && container_ && flutter_window_) {
    // The rect from Dart is in Flutter client area coordinates (0,0 is top-left of Flutter content).
    // The container window is positioned to match the Flutter window's full bounds (including title bar).
    // We need to offset the mpv window within the container to align with Flutter's client area.

    // Get the Flutter window's window rect (screen coordinates, includes title bar)
    RECT window_rect;
    ::GetWindowRect(flutter_window_, &window_rect);

    // Get the Flutter window's client rect (client coordinates, 0,0 based)
    RECT client_rect;
    ::GetClientRect(flutter_window_, &client_rect);

    // Convert client area origin to screen coordinates
    POINT client_origin = {0, 0};
    ::ClientToScreen(flutter_window_, &client_origin);

    // Calculate the offset from window origin to client area origin
    int client_offset_x = client_origin.x - window_rect.left;
    int client_offset_y = client_origin.y - window_rect.top;

    // Position the mpv window within the container, offset by the title bar/border size
    int left = rect.left + client_offset_x;
    int top = rect.top + client_offset_y;
    int width = rect.right - rect.left;
    int height = rect.bottom - rect.top;

    ::MoveWindow(hwnd_, left, top, width, height, TRUE);
  }
}

void MpvPlayer::SetVisible(bool visible) {
  if (hwnd_) {
    ::ShowWindow(hwnd_, visible ? SW_SHOW : SW_HIDE);
  }
}

void MpvPlayer::SetEventCallback(EventCallback callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  event_callback_ = std::move(callback);
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
    case MPV_EVENT_LOG_MESSAGE: {
      auto* msg = static_cast<mpv_event_log_message*>(event->data);
      char log_msg[512];
      snprintf(log_msg, sizeof(log_msg), "MPV [%s] %s: %s",
               msg->level, msg->prefix, msg->text);
      OutputDebugStringA(log_msg);

      flutter::EncodableMap data;
      data[flutter::EncodableValue("prefix")] =
          flutter::EncodableValue(msg->prefix ? msg->prefix : "");
      data[flutter::EncodableValue("level")] =
          flutter::EncodableValue(msg->level ? msg->level : "");
      data[flutter::EncodableValue("text")] =
          flutter::EncodableValue(msg->text ? msg->text : "");
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
      if (strcmp(prop->name, "video-params/sig-peak") == 0 &&
          prop->format == MPV_FORMAT_DOUBLE && prop->data) {
        double sigPeak = *static_cast<double*>(prop->data);
        last_sig_peak_ = sigPeak;
        UpdateHDRMode(sigPeak);
      }

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
      auto* end = static_cast<mpv_event_end_file*>(event->data);
      flutter::EncodableMap data;
      data[flutter::EncodableValue("reason")] =
          flutter::EncodableValue(static_cast<int>(end->reason));
      if (end->reason == MPV_END_FILE_REASON_ERROR) {
        data[flutter::EncodableValue("error")] =
            flutter::EncodableValue(static_cast<int>(end->error));
      }
      SendEvent("end-file", data);
      break;
    }
    case MPV_EVENT_FILE_LOADED: {
      SendEvent("file-loaded");
      break;
    }
    case MPV_EVENT_PLAYBACK_RESTART: {
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
  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] =
      flutter::EncodableValue("property");
  event[flutter::EncodableValue("name")] =
      flutter::EncodableValue(name ? name : "");

  flutter::EncodableValue value;
  if (data) {
    switch (data->format) {
      case MPV_FORMAT_STRING:
        value = flutter::EncodableValue(
            data->u.string ? std::string(data->u.string) : std::string());
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
  event[flutter::EncodableValue("value")] = value;

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(event);
  }
}

void MpvPlayer::SendEvent(const std::string& name,
                          const flutter::EncodableMap& data) {
  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] = flutter::EncodableValue("event");
  event[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
  if (!data.empty()) {
    event[flutter::EncodableValue("data")] = flutter::EncodableValue(data);
  }

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(event);
  }
}

void MpvPlayer::SetHDREnabled(bool enabled) {
  hdr_enabled_ = enabled;
  char msg[128];
  snprintf(msg, sizeof(msg), "[MpvPlayer] HDR enabled: %s", enabled ? "true" : "false");
  LogToFile(msg);

  if (mpv_) {
    mpv_set_property_string(mpv_, "target-colorspace-hint", enabled ? "yes" : "no");
  }

  UpdateHDRMode(last_sig_peak_);
}

void MpvPlayer::UpdateHDRMode(double sigPeak) {
  bool isHDRContent = sigPeak > 1.0;

  char msg[256];
  snprintf(msg, sizeof(msg),
           "[MpvPlayer] HDR mode update (hdrEnabled: %s, sigPeak: %.2f, isHDR: %s)",
           hdr_enabled_ ? "true" : "false",
           sigPeak,
           isHDRContent ? "true" : "false");
  LogToFile(msg);

  // On Windows, mpv handles HDR passthrough automatically when:
  // - target-colorspace-hint=yes
  // - Windows HDR is enabled in Display Settings
  // - Display supports HDR
  // No explicit DXGI calls needed - mpv's gpu/d3d11 handles it
}

}  // namespace mpv
