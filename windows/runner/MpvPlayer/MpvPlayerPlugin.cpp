#include "MpvPlayerPlugin.h"
#include <commctrl.h>
#include <iostream>

// Custom window message for MPV wakeup (must match MpvPlayerCore.cpp)
#define WM_MPV_WAKEUP (WM_USER + 100)

// Subclass ID for window procedure hook
#define SUBCLASS_ID 1

// Static instances to prevent destruction
static std::unique_ptr<MpvPlayerPlugin> g_plugin_instance;
static std::unique_ptr<SimpleBinaryMessenger> g_messenger;
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_method_channel;
static std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> g_event_channel;

void MpvPlayerPlugin::RegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar_ref) {

    auto plugin = std::make_unique<MpvPlayerPlugin>(registrar_ref);
    auto* plugin_ptr = plugin.get();

    // Get messenger from registrar and wrap it
    FlutterDesktopMessengerRef messenger_ref = FlutterDesktopPluginRegistrarGetMessenger(registrar_ref);
    g_messenger = std::make_unique<SimpleBinaryMessenger>(messenger_ref);

    // Set up method channel
    g_method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        g_messenger.get(),
        "com.plezy/mpv_player",
        &flutter::StandardMethodCodec::GetInstance());

    g_method_channel->SetMethodCallHandler(
        [plugin_ptr](const auto& call, auto result) {
            plugin_ptr->HandleMethodCall(call, std::move(result));
        });

    // Set up event channel
    g_event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        g_messenger.get(),
        "com.plezy/mpv_player/events",
        &flutter::StandardMethodCodec::GetInstance());

    auto event_handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [plugin_ptr](const flutter::EncodableValue* arguments,
                    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            plugin_ptr->event_sink_ = std::move(events);
            std::cout << "[MpvPlayerPlugin] Event stream connected" << std::endl;
            return nullptr;
        },
        [plugin_ptr](const flutter::EncodableValue* arguments)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            plugin_ptr->event_sink_.reset();
            std::cout << "[MpvPlayerPlugin] Event stream disconnected" << std::endl;
            return nullptr;
        });

    g_event_channel->SetStreamHandler(std::move(event_handler));

    // Store plugin instance globally to prevent destruction
    g_plugin_instance = std::move(plugin);
    std::cout << "[MpvPlayerPlugin] Registered with Flutter" << std::endl;
}

MpvPlayerPlugin::MpvPlayerPlugin(FlutterDesktopPluginRegistrarRef registrar_ref)
    : registrar_ref_(registrar_ref) {

    // Get the window handle from the view
    FlutterDesktopViewRef view = FlutterDesktopPluginRegistrarGetView(registrar_ref);
    if (view) {
        window_handle_ = FlutterDesktopViewGetHWND(view);

        // Install window procedure hook using subclassing
        if (window_handle_) {
            SetWindowSubclass(window_handle_, WndProcHook, SUBCLASS_ID,
                             reinterpret_cast<DWORD_PTR>(this));
        }
    }
}

MpvPlayerPlugin::~MpvPlayerPlugin() {
    // Remove window subclass
    if (window_handle_) {
        RemoveWindowSubclass(window_handle_, WndProcHook, SUBCLASS_ID);
    }

    if (player_core_) {
        player_core_->Dispose();
    }
}

LRESULT CALLBACK MpvPlayerPlugin::WndProcHook(
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam,
    UINT_PTR subclass_id, DWORD_PTR ref_data) {

    auto* plugin = reinterpret_cast<MpvPlayerPlugin*>(ref_data);

    if (message == WM_MPV_WAKEUP) {
        // Process MPV events on the main thread
        if (plugin && plugin->player_core_) {
            plugin->player_core_->ProcessEvents();
        }
        return 0;
    }

    if (message == WM_SIZE || message == WM_MOVE || message == WM_WINDOWPOSCHANGED) {
        // Update video frame when window is resized or moved
        if (plugin && plugin->player_core_ && plugin->player_core_->IsInitialized()) {
            plugin->player_core_->UpdateFrame();
        }
    }

    return DefSubclassProc(hwnd, message, wparam, lparam);
}

void MpvPlayerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    const auto& method = call.method_name();

    if (method == "initialize") {
        if (!window_handle_) {
            result->Error("NO_WINDOW", "Could not find Flutter window");
            return;
        }

        // Check if already initialized
        if (player_core_ && player_core_->IsInitialized()) {
            std::cout << "[MpvPlayerPlugin] Already initialized" << std::endl;
            result->Success(flutter::EncodableValue(true));
            return;
        }

        player_core_ = std::make_unique<MpvPlayerCore>();
        player_core_->SetDelegate(this);

        if (player_core_->Initialize(window_handle_)) {
            player_core_->SetVisible(false);
            std::cout << "[MpvPlayerPlugin] Initialized successfully" << std::endl;
            result->Success(flutter::EncodableValue(true));
        } else {
            player_core_.reset();
            result->Error("INIT_FAILED", "Failed to initialize MPV");
        }
    }
    else if (method == "dispose") {
        if (player_core_) {
            player_core_->Dispose();
            player_core_.reset();
        }
        std::cout << "[MpvPlayerPlugin] Disposed" << std::endl;
        result->Success();
    }
    else if (method == "setProperty") {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args && player_core_) {
            auto name_it = args->find(flutter::EncodableValue("name"));
            auto value_it = args->find(flutter::EncodableValue("value"));

            if (name_it != args->end() && value_it != args->end()) {
                auto name = std::get<std::string>(name_it->second);
                auto value = std::get<std::string>(value_it->second);
                player_core_->SetProperty(name, value);
            }
        }
        result->Success();
    }
    else if (method == "getProperty") {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args && player_core_) {
            auto name_it = args->find(flutter::EncodableValue("name"));
            if (name_it != args->end()) {
                auto name = std::get<std::string>(name_it->second);
                auto value = player_core_->GetProperty(name);
                if (!value.empty()) {
                    result->Success(flutter::EncodableValue(value));
                    return;
                }
            }
        }
        result->Success();
    }
    else if (method == "observeProperty") {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args && player_core_) {
            auto name_it = args->find(flutter::EncodableValue("name"));
            auto format_it = args->find(flutter::EncodableValue("format"));

            if (name_it != args->end() && format_it != args->end()) {
                auto name = std::get<std::string>(name_it->second);
                auto format = std::get<std::string>(format_it->second);
                player_core_->ObserveProperty(name, format);
            }
        }
        result->Success();
    }
    else if (method == "command") {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args && player_core_) {
            auto args_it = args->find(flutter::EncodableValue("args"));
            if (args_it != args->end()) {
                const auto* cmdArgs = std::get_if<flutter::EncodableList>(&args_it->second);
                if (cmdArgs) {
                    std::vector<std::string> strArgs;
                    for (const auto& arg : *cmdArgs) {
                        strArgs.push_back(std::get<std::string>(arg));
                    }
                    player_core_->Command(strArgs);
                }
            }
        }
        result->Success();
    }
    else if (method == "setVisible") {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args && player_core_) {
            auto visible_it = args->find(flutter::EncodableValue("visible"));
            if (visible_it != args->end()) {
                auto visible = std::get<bool>(visible_it->second);
                player_core_->SetVisible(visible);
                if (visible) {
                    player_core_->UpdateFrame();
                }
            }
        }
        result->Success();
    }
    else if (method == "isInitialized") {
        bool initialized = player_core_ && player_core_->IsInitialized();
        result->Success(flutter::EncodableValue(initialized));
    }
    else {
        result->NotImplemented();
    }
}

flutter::EncodableValue MpvPlayerPlugin::ConvertToEncodable(const MpvValue& value) {
    return std::visit([](auto&& arg) -> flutter::EncodableValue {
        using T = std::decay_t<decltype(arg)>;

        if constexpr (std::is_same_v<T, std::monostate>) {
            return flutter::EncodableValue();
        } else if constexpr (std::is_same_v<T, bool>) {
            return flutter::EncodableValue(arg);
        } else if constexpr (std::is_same_v<T, int64_t>) {
            return flutter::EncodableValue(arg);
        } else if constexpr (std::is_same_v<T, double>) {
            return flutter::EncodableValue(arg);
        } else if constexpr (std::is_same_v<T, std::string>) {
            return flutter::EncodableValue(arg);
        } else if constexpr (std::is_same_v<T, std::vector<std::map<std::string, std::variant<std::monostate, bool, int64_t, double, std::string>>>>) {
            // Handle array of maps (for track-list)
            flutter::EncodableList list;
            for (const auto& item : arg) {
                flutter::EncodableMap map;
                for (const auto& [key, val] : item) {
                    std::visit([&map, &key](auto&& v) {
                        using V = std::decay_t<decltype(v)>;
                        if constexpr (std::is_same_v<V, std::monostate>) {
                            map[flutter::EncodableValue(key)] = flutter::EncodableValue();
                        } else if constexpr (std::is_same_v<V, bool>) {
                            map[flutter::EncodableValue(key)] = flutter::EncodableValue(v);
                        } else if constexpr (std::is_same_v<V, int64_t>) {
                            map[flutter::EncodableValue(key)] = flutter::EncodableValue(v);
                        } else if constexpr (std::is_same_v<V, double>) {
                            map[flutter::EncodableValue(key)] = flutter::EncodableValue(v);
                        } else if constexpr (std::is_same_v<V, std::string>) {
                            map[flutter::EncodableValue(key)] = flutter::EncodableValue(v);
                        }
                    }, val);
                }
                list.push_back(flutter::EncodableValue(map));
            }
            return flutter::EncodableValue(list);
        } else {
            return flutter::EncodableValue();
        }
    }, value);
}

void MpvPlayerPlugin::OnPropertyChange(const std::string& name, const MpvValue& value) {
    if (!event_sink_) return;

    flutter::EncodableMap event;
    event[flutter::EncodableValue("type")] = flutter::EncodableValue("property");
    event[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
    event[flutter::EncodableValue("value")] = ConvertToEncodable(value);

    event_sink_->Success(flutter::EncodableValue(event));
}

void MpvPlayerPlugin::OnEvent(const std::string& name, const std::map<std::string, MpvValue>* data) {
    if (!event_sink_) return;

    flutter::EncodableMap event;
    event[flutter::EncodableValue("type")] = flutter::EncodableValue("event");
    event[flutter::EncodableValue("name")] = flutter::EncodableValue(name);

    if (data) {
        flutter::EncodableMap dataMap;
        for (const auto& [key, val] : *data) {
            dataMap[flutter::EncodableValue(key)] = ConvertToEncodable(val);
        }
        event[flutter::EncodableValue("data")] = flutter::EncodableValue(dataMap);
    }

    event_sink_->Success(flutter::EncodableValue(event));
}
