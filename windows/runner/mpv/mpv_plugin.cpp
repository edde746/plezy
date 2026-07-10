#include "mpv_plugin.h"

static flutter::EncodableMap DisplayModeToMap(const mpv::DisplayMode& mode) {
  flutter::EncodableMap m;
  m[flutter::EncodableValue("width")] = flutter::EncodableValue(static_cast<int32_t>(mode.width));
  m[flutter::EncodableValue("height")] = flutter::EncodableValue(static_cast<int32_t>(mode.height));
  m[flutter::EncodableValue("refreshRate")] = flutter::EncodableValue(static_cast<int32_t>(mode.refresh_rate));
  return m;
}

void MpvPlayerPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  mpv::MpvPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void MpvAudioPlayerPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  mpv::MpvPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()->GetRegistrar<flutter::PluginRegistrarWindows>(registrar),
      "com.plezy/mpv_audio_player", /*audio_only=*/true);
}

namespace mpv {

namespace {
constexpr UINT kPlatformTaskMessage = WM_APP + 0x4D50;
constexpr UINT kAudioPlatformTaskMessage = WM_APP + 0x4D51;
}  // namespace

void MpvPlayerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar, const std::string& channel_name, bool audio_only) {
  auto plugin = std::make_unique<MpvPlayerPlugin>(registrar, channel_name, audio_only);
  registrar->AddPlugin(std::move(plugin));
}

MpvPlayerPlugin::MpvPlayerPlugin(
    flutter::PluginRegistrarWindows* registrar, const std::string& channel_name, bool audio_only)
    : registrar_(registrar),
      platform_thread_id_(::GetCurrentThreadId()),
      audio_only_(audio_only),
      platform_task_message_(audio_only ? kAudioPlatformTaskMessage : kPlatformTaskMessage) {
  // Create method channel.
  method_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), channel_name, &flutter::StandardMethodCodec::GetInstance());

  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });

  // Create event channel.
  event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), channel_name + "/events", &flutter::StandardMethodCodec::GetInstance());

  auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [this](
          const flutter::EncodableValue* arguments,
          std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        event_sink_ = std::move(events);
        return nullptr;
      },
      [this](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        event_sink_ = nullptr;
        return nullptr;
      });

  event_channel_->SetStreamHandler(std::move(handler));
}

MpvPlayerPlugin::~MpvPlayerPlugin() {
  // Join the mpv event thread before draining: it enqueues platform tasks,
  // and platform_tasks_/platform_tasks_mutex_ are destroyed before player_
  // (reverse declaration order).
  if (player_) {
    player_->Dispose();
    player_.reset();
  }

  DrainPlatformTasks();

  // Unregister window proc delegate.
  if (proc_id_) {
    registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_.value());
    proc_id_ = std::nullopt;
  }
}

HWND MpvPlayerPlugin::GetChildWindow() { return registrar_->GetView()->GetNativeWindow(); }

HWND MpvPlayerPlugin::GetWindow() { return ::GetAncestor(GetChildWindow(), GA_ROOT); }

void MpvPlayerPlugin::PostToPlatformThread(std::function<void()> task) {
  if (::GetCurrentThreadId() == platform_thread_id_) {
    task();
    return;
  }

  bool post_wakeup = false;
  {
    std::lock_guard<std::mutex> lock(platform_tasks_mutex_);
    platform_tasks_.push(std::move(task));
    if (!wakeup_posted_ && flutter_window_) {
      wakeup_posted_ = true;
      post_wakeup = true;
    }
  }

  if (post_wakeup && !::PostMessage(flutter_window_, platform_task_message_, 0, 0)) {
    // Wakeup lost (e.g. message queue full during a log storm); let the next
    // enqueue retry instead of stranding the queue.
    std::lock_guard<std::mutex> lock(platform_tasks_mutex_);
    wakeup_posted_ = false;
  }
}

void MpvPlayerPlugin::DrainPlatformTasks() {
  std::queue<std::function<void()>> tasks;
  {
    std::lock_guard<std::mutex> lock(platform_tasks_mutex_);
    tasks.swap(platform_tasks_);
    wakeup_posted_ = false;
  }

  while (!tasks.empty()) {
    tasks.front()();
    tasks.pop();
  }
}

void MpvPlayerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  if (method == "initialize") {
    if (proc_id_) {
      registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_.value());
      proc_id_ = std::nullopt;
    }

    flutter_window_ = GetWindow();

    // The only top-level message we care about is the platform-task wakeup;
    // mouse-over-video input is forwarded by the mpv inner-window subclass
    // (see MpvPlayer), and compositing/z-order is handled by the engine's
    // topmost DComp visual — there is no separate container window to manage.
    proc_id_ =
        registrar_->RegisterTopLevelWindowProcDelegate([this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          if (message == platform_task_message_) {
            DrainPlatformTasks();
            return std::optional<HRESULT>(0);
          }
          // Both resume variants are handled: which of the two arrives (or
          // both) depends on S3 vs Modern Standby; re-arming is idempotent.
          // player_ create/reset also happens on this thread, so the
          // null-check suffices. Never consume the message.
          if (message == WM_POWERBROADCAST && player_ && player_->IsInitialized()) {
            if (wparam == PBT_APMSUSPEND) {
              player_->NotifyPowerSuspend();
            } else if (wparam == PBT_APMRESUMEAUTOMATIC || wparam == PBT_APMRESUMESUSPEND) {
              player_->NotifyPowerResume();
            }
          }
          return std::optional<HRESULT>(std::nullopt);
        });

    // The video window is a child of the FLUTTER VIEW itself, so DWM's
    // per-window layer model puts it above the view's own (layer 1) content
    // and below the view's topmost DComp visual carrying the UI (layer 4). As
    // a *sibling* of the view, either the view's never-painted white content
    // covers the video or the video covers the UI — the in-subtree placement
    // is the only ordering that yields white < video < UI. The audio-only
    // core is windowless, so it gets no view at all.
    HWND view = audio_only_ ? nullptr : GetChildWindow();

    player_ = std::make_unique<MpvPlayer>(audio_only_);
    bool success = player_->Initialize(view);

    if (success) {
      // Set up event callback.
      player_->SetEventCallback([this](const flutter::EncodableValue& event) { SendEvent(event); });

      if (!audio_only_) {
        // Start hidden.
        player_->SetVisible(false);
      }
      result->Success(flutter::EncodableValue(true));
    } else {
      player_.reset();  // Clear the player so we don't have a half-initialized state
      result->Error("INIT_FAILED", "Failed to initialize MPV player");
    }
  } else if (method == "dispose") {
    if (player_) {
      player_->Dispose();
      player_.reset();
    }
    result->Success();
  } else if (method == "command") {
    if (!player_ || !player_->IsInitialized()) {
      result->Error("NOT_INITIALIZED", "Player not initialized");
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto it = map.find(flutter::EncodableValue("args"));
    if (it == map.end() || !std::holds_alternative<flutter::EncodableList>(it->second)) {
      result->Error("INVALID_ARGS", "Missing 'args' list");
      return;
    }

    const auto& list = std::get<flutter::EncodableList>(it->second);
    std::vector<std::string> command_args;
    for (const auto& item : list) {
      if (std::holds_alternative<std::string>(item)) {
        command_args.push_back(std::get<std::string>(item));
      }
    }

    // Use async command to prevent UI blocking during network operations
    // Move result into shared_ptr for safe capture in callback
    auto result_ptr =
        std::make_shared<std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>>(std::move(result));
    std::string cmd_name = command_args.empty() ? "unknown" : command_args[0];
    player_->CommandAsync(command_args, [this, result_ptr, cmd_name](int error) {
      PostToPlatformThread([result_ptr, cmd_name, error]() {
        if (error < 0) {
          (*result_ptr)
              ->Error("COMMAND_FAILED", "MPV command failed: " + cmd_name + " (error " + std::to_string(error) + ")");
        } else {
          (*result_ptr)->Success();
        }
      });
    });
    return;  // Response will be sent asynchronously
  } else if (method == "setProperty") {
    if (!player_ || !player_->IsInitialized()) {
      result->Error("NOT_INITIALIZED", "Player not initialized");
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto name_it = map.find(flutter::EncodableValue("name"));
    auto value_it = map.find(flutter::EncodableValue("value"));

    if (name_it == map.end() || !std::holds_alternative<std::string>(name_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'name'");
      return;
    }
    if (value_it == map.end() || !std::holds_alternative<std::string>(value_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'value'");
      return;
    }

    auto result_ptr =
        std::make_shared<std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>>(std::move(result));
    player_->SetPropertyAsync(
        std::get<std::string>(name_it->second), std::get<std::string>(value_it->second),
        [this, result_ptr](int error) { PostToPlatformThread([result_ptr]() { (*result_ptr)->Success(); }); });
    return;
  } else if (method == "setLogLevel") {
    if (!player_ || !player_->IsInitialized()) {
      result->Error("NOT_INITIALIZED", "Player not initialized");
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto level_it = map.find(flutter::EncodableValue("level"));

    if (level_it == map.end() || !std::holds_alternative<std::string>(level_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'level'");
      return;
    }

    player_->SetLogLevel(std::get<std::string>(level_it->second));
    result->Success();
  } else if (method == "getProperty") {
    if (!player_ || !player_->IsInitialized()) {
      result->Error("NOT_INITIALIZED", "Player not initialized");
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto name_it = map.find(flutter::EncodableValue("name"));

    if (name_it == map.end() || !std::holds_alternative<std::string>(name_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'name'");
      return;
    }

    auto result_ptr =
        std::make_shared<std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>>(std::move(result));
    player_->GetPropertyAsync(
        std::get<std::string>(name_it->second), [this, result_ptr](int error, const std::string& value) {
          PostToPlatformThread([result_ptr, error, value]() {
            if (error < 0 || value.empty()) {
              (*result_ptr)->Success();
            } else {
              (*result_ptr)->Success(flutter::EncodableValue(value));
            }
          });
        });
    return;
  } else if (method == "observeProperty") {
    if (!player_ || !player_->IsInitialized()) {
      result->Error("NOT_INITIALIZED", "Player not initialized");
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto name_it = map.find(flutter::EncodableValue("name"));
    auto format_it = map.find(flutter::EncodableValue("format"));
    auto id_it = map.find(flutter::EncodableValue("id"));

    if (name_it == map.end() || !std::holds_alternative<std::string>(name_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'name'");
      return;
    }
    if (format_it == map.end() || !std::holds_alternative<std::string>(format_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'format'");
      return;
    }
    if (id_it == map.end() || !std::holds_alternative<int32_t>(id_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'id'");
      return;
    }

    player_->ObserveProperty(
        std::get<std::string>(name_it->second), std::get<std::string>(format_it->second),
        std::get<int32_t>(id_it->second));
    result->Success();
  } else if (method == "setVisible") {
    if (audio_only_) {
      // Windowless core: nothing to show or hide, tolerate as a success no-op.
      result->Success();
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto visible_it = map.find(flutter::EncodableValue("visible"));

    if (visible_it == map.end() || !std::holds_alternative<bool>(visible_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'visible'");
      return;
    }

    bool visible = std::get<bool>(visible_it->second);

    if (player_) {
      player_->SetVisible(visible);
    }

    result->Success();
  } else if (method == "setVideoRect") {
    if (audio_only_) {
      // Windowless core: no rect to position, tolerate as a success no-op.
      result->Success();
      return;
    }

    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);

    auto get_int = [&map](const char* key) -> int {
      auto it = map.find(flutter::EncodableValue(key));
      if (it != map.end()) {
        if (std::holds_alternative<int32_t>(it->second)) {
          return std::get<int32_t>(it->second);
        } else if (std::holds_alternative<int64_t>(it->second)) {
          return static_cast<int>(std::get<int64_t>(it->second));
        }
      }
      return 0;
    };

    auto get_double = [&map](const char* key) -> double {
      auto it = map.find(flutter::EncodableValue(key));
      if (it != map.end() && std::holds_alternative<double>(it->second)) {
        return std::get<double>(it->second);
      }
      return 1.0;
    };

    RECT rect;
    rect.left = get_int("left");
    rect.top = get_int("top");
    rect.right = get_int("right");
    rect.bottom = get_int("bottom");
    double dpr = get_double("devicePixelRatio");

    if (player_) {
      player_->SetRect(rect, dpr);
    }

    result->Success();
  } else if (audio_only_ && method == "updateFrame") {
    // No frames to pump on the windowless core; tolerate as a success no-op.
    result->Success();
  } else if (method == "isInitialized") {
    bool initialized = player_ && player_->IsInitialized();
    result->Success(flutter::EncodableValue(initialized));

    // --- Display mode matching (video instance only) ---
  } else if (!audio_only_ && method == "getDisplayModes") {
    HWND hwnd = GetWindow();
    auto modes = display_mode_manager_.EnumerateDisplayModes(hwnd);
    flutter::EncodableList list;
    for (const auto& mode : modes) {
      list.push_back(flutter::EncodableValue(DisplayModeToMap(mode)));
    }
    result->Success(flutter::EncodableValue(list));
  } else if (!audio_only_ && method == "getCurrentDisplayMode") {
    HWND hwnd = GetWindow();
    auto mode = display_mode_manager_.GetCurrentMode(hwnd);
    result->Success(flutter::EncodableValue(DisplayModeToMap(mode)));
  } else if (!audio_only_ && method == "setDisplayMode") {
    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }
    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto get_int = [&map](const char* key) -> int {
      auto it = map.find(flutter::EncodableValue(key));
      if (it != map.end() && std::holds_alternative<int32_t>(it->second)) return std::get<int32_t>(it->second);
      return 0;
    };
    HWND hwnd = GetWindow();
    bool success =
        display_mode_manager_.SetDisplayMode(hwnd, get_int("width"), get_int("height"), get_int("refreshRate"));
    result->Success(flutter::EncodableValue(success));
  } else if (!audio_only_ && method == "restoreDisplayMode") {
    HWND hwnd = GetWindow();
    bool success = display_mode_manager_.RestoreOriginalMode(hwnd);
    result->Success(flutter::EncodableValue(success));
  } else if (!audio_only_ && method == "isHDRSupported") {
    HWND hwnd = GetWindow();
    result->Success(flutter::EncodableValue(display_mode_manager_.IsHDRSupported(hwnd)));
  } else if (!audio_only_ && method == "isHDREnabled") {
    HWND hwnd = GetWindow();
    result->Success(flutter::EncodableValue(display_mode_manager_.IsHDREnabled(hwnd)));
  } else if (!audio_only_ && method == "setSystemHDR") {
    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }
    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto it = map.find(flutter::EncodableValue("enabled"));
    if (it == map.end() || !std::holds_alternative<bool>(it->second)) {
      result->Error("INVALID_ARGS", "Missing 'enabled'");
      return;
    }
    bool enabled = std::get<bool>(it->second);
    HWND hwnd = GetWindow();
    bool success = display_mode_manager_.SetHDREnabled(hwnd, enabled);
    result->Success(flutter::EncodableValue(success));
  } else if (!audio_only_ && method == "restoreSystemHDR") {
    HWND hwnd = GetWindow();
    bool success = display_mode_manager_.RestoreOriginalHDRState(hwnd);
    result->Success(flutter::EncodableValue(success));
  } else if (!audio_only_ && method == "isModeChanged") {
    result->Success(flutter::EncodableValue(display_mode_manager_.IsModeChanged()));
  } else if (!audio_only_ && method == "isHDRChanged") {
    result->Success(flutter::EncodableValue(display_mode_manager_.IsHDRChanged()));
  } else {
    result->NotImplemented();
  }
}

void MpvPlayerPlugin::SendEvent(const flutter::EncodableValue& event) {
  // mpv events arrive on the mpv event thread; Flutter channel APIs are
  // platform-thread-only, so marshal onto the platform thread (the sink
  // null-check then also runs on the same thread as onListen/onCancel).
  PostToPlatformThread([this, event]() {
    if (event_sink_) {
      event_sink_->Success(event);
    }
  });
}

}  // namespace mpv
