#include "mpv_plugin.h"

#include <fstream>

#include "mpv_container.h"
#include "mpv_core.h"

static void LogToFile(const char* message) {
  std::ofstream log("C:\\Users\\admin\\mpv_debug.log", std::ios::app);
  if (log.is_open()) {
    log << message << std::endl;
    log.close();
  }
  OutputDebugStringA(message);
  OutputDebugStringA("\n");
}

void MpvPlayerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  LogToFile("MpvPlayerPlugin: RegisterWithRegistrar called");
  mpv::MpvPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
  LogToFile("MpvPlayerPlugin: RegisterWithRegistrar completed");
}

namespace mpv {

void MpvPlayerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<MpvPlayerPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

MpvPlayerPlugin::MpvPlayerPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  LogToFile("MpvPlayerPlugin: Constructor called");

  // Create method channel.
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.plezy/mpv_player",
          &flutter::StandardMethodCodec::GetInstance());

  LogToFile("MpvPlayerPlugin: Method channel created");

  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        char msg[256];
        snprintf(msg, sizeof(msg), "MpvPlayerPlugin: Method call received: %s",
                 call.method_name().c_str());
        LogToFile(msg);
        HandleMethodCall(call, std::move(result));
      });

  // Create event channel.
  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.plezy/mpv_player/events",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler = std::make_unique<
      flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* arguments,
             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                 events) -> std::unique_ptr<flutter::StreamHandlerError<
                              flutter::EncodableValue>> {
        event_sink_ = std::move(events);
        return nullptr;
      },
      [this](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<
              flutter::StreamHandlerError<flutter::EncodableValue>> {
        event_sink_ = nullptr;
        return nullptr;
      });

  event_channel_->SetStreamHandler(std::move(handler));
}

MpvPlayerPlugin::~MpvPlayerPlugin() {
  // Unregister window proc delegate.
  if (proc_id_) {
    registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_.value());
    proc_id_ = std::nullopt;
  }
}

HWND MpvPlayerPlugin::GetChildWindow() {
  return registrar_->GetView()->GetNativeWindow();
}

HWND MpvPlayerPlugin::GetWindow() {
  return ::GetAncestor(GetChildWindow(), GA_ROOT);
}

void MpvPlayerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  if (method == "initialize") {
    LogToFile("MPV Plugin: initialize called");

    // Set up MpvCore for z-order management.
    if (proc_id_) {
      registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_.value());
      proc_id_ = std::nullopt;
    }

    HWND flutter_window = GetWindow();
    HWND child_window = GetChildWindow();

    char msg[256];
    snprintf(msg, sizeof(msg), "MPV Plugin: Flutter window: %p, Child window: %p",
             flutter_window, child_window);
    LogToFile(msg);

    MpvCore::SetInstance(
        std::make_unique<MpvCore>(flutter_window, child_window));

    proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
        [](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
          auto* core = MpvCore::GetInstance();
          if (core) {
            return core->WindowProc(hwnd, message, wparam, lparam);
          }
          return std::optional<HRESULT>(std::nullopt);
        });

    LogToFile("MPV Plugin: Calling EnsureInitialized");
    MpvCore::GetInstance()->EnsureInitialized();

    // Create player - use the container from MpvCore which was set up by EnsureInitialized
    player_ = std::make_unique<MpvPlayer>();
    HWND container = MpvContainer::GetInstance()->handle();

    snprintf(msg, sizeof(msg), "MPV Plugin: Container handle: %p", container);
    LogToFile(msg);

    if (!container) {
      LogToFile("MPV Plugin: ERROR - container is null");
      result->Error("INIT_FAILED", "Failed to create container window");
      return;
    }

    LogToFile("MPV Plugin: Initializing player");
    bool success = player_->Initialize(container, flutter_window);

    if (success) {
      LogToFile("MPV Plugin: Player initialized successfully");
      // Set up event callback.
      player_->SetEventCallback([this](const flutter::EncodableValue& event) {
        SendEvent(event);
      });

      // Register the mpv window with core for z-order management.
      RECT rect = {0, 0, 100, 100};
      MpvCore::GetInstance()->CreateMpvView(player_->GetHwnd(), rect, 1.0);

      // Start hidden.
      MpvCore::GetInstance()->SetVisible(false);
      result->Success(flutter::EncodableValue(true));
    } else {
      OutputDebugStringA("MPV Plugin: Player initialization FAILED\n");
      player_.reset();  // Clear the player so we don't have a half-initialized state
      result->Error("INIT_FAILED", "Failed to initialize MPV player");
    }
  } else if (method == "dispose") {
    if (player_) {
      auto hwnd = player_->GetHwnd();
      player_->Dispose();
      player_.reset();

      if (MpvCore::GetInstance() && hwnd) {
        MpvCore::GetInstance()->DisposeMpvView(hwnd);
      }
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
    if (it == map.end() ||
        !std::holds_alternative<flutter::EncodableList>(it->second)) {
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
    auto result_ptr = std::make_shared<std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>>(std::move(result));
    std::string cmd_name = command_args.empty() ? "unknown" : command_args[0];
    player_->CommandAsync(command_args, [result_ptr, cmd_name](int error) {
      if (error < 0) {
        (*result_ptr)->Error("COMMAND_FAILED",
          "MPV command failed: " + cmd_name + " (error " + std::to_string(error) + ")");
      } else {
        (*result_ptr)->Success();
      }
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

    if (name_it == map.end() ||
        !std::holds_alternative<std::string>(name_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'name'");
      return;
    }
    if (value_it == map.end() ||
        !std::holds_alternative<std::string>(value_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'value'");
      return;
    }

    player_->SetProperty(std::get<std::string>(name_it->second),
                         std::get<std::string>(value_it->second));
    result->Success();
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

    if (level_it == map.end() ||
        !std::holds_alternative<std::string>(level_it->second)) {
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

    if (name_it == map.end() ||
        !std::holds_alternative<std::string>(name_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'name'");
      return;
    }

    std::string value =
        player_->GetProperty(std::get<std::string>(name_it->second));
    if (value.empty()) {
      result->Success();
    } else {
      result->Success(flutter::EncodableValue(value));
    }
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

    if (name_it == map.end() ||
        !std::holds_alternative<std::string>(name_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'name'");
      return;
    }
    if (format_it == map.end() ||
        !std::holds_alternative<std::string>(format_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'format'");
      return;
    }
    if (id_it == map.end() ||
        !std::holds_alternative<int32_t>(id_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'id'");
      return;
    }

    player_->ObserveProperty(std::get<std::string>(name_it->second),
                             std::get<std::string>(format_it->second),
                             std::get<int32_t>(id_it->second));
    result->Success();
  } else if (method == "setVisible") {
    const auto* args = method_call.arguments();
    if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
      result->Error("INVALID_ARGS", "Expected map argument");
      return;
    }

    const auto& map = std::get<flutter::EncodableMap>(*args);
    auto visible_it = map.find(flutter::EncodableValue("visible"));

    if (visible_it == map.end() ||
        !std::holds_alternative<bool>(visible_it->second)) {
      result->Error("INVALID_ARGS", "Missing 'visible'");
      return;
    }

    bool visible = std::get<bool>(visible_it->second);

    if (player_) {
      player_->SetVisible(visible);
    }
    if (MpvCore::GetInstance()) {
      MpvCore::GetInstance()->SetVisible(visible);
    }

    result->Success();
  } else if (method == "setVideoRect") {
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

    if (player_ && MpvCore::GetInstance()) {
      MpvCore::GetInstance()->ResizeMpvView(player_->GetHwnd(), rect);
      player_->SetRect(rect, dpr);
    }

    result->Success();
  } else if (method == "isInitialized") {
    bool initialized = player_ && player_->IsInitialized();
    result->Success(flutter::EncodableValue(initialized));
  } else {
    result->NotImplemented();
  }
}

void MpvPlayerPlugin::SendEvent(const flutter::EncodableValue& event) {
  if (event_sink_) {
    event_sink_->Success(event);
  }
}

}  // namespace mpv
