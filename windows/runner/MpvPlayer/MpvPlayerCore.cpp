#include "MpvPlayerCore.h"
#include <iostream>

// Custom window message for MPV wakeup
#define WM_MPV_WAKEUP (WM_USER + 100)

// Window class name for video window
static const wchar_t* kVideoWindowClass = L"MpvVideoWindow";
static bool window_class_registered = false;

MpvPlayerCore::MpvPlayerCore() {}

MpvPlayerCore::~MpvPlayerCore() {
    Dispose();
}

bool MpvPlayerCore::Initialize(HWND parentHwnd) {
    if (initialized_) {
        std::cout << "[MpvPlayerCore] Already initialized" << std::endl;
        return true;
    }

    // parentHwnd is the Flutter view - get its parent (the top-level Win32Window)
    flutter_view_hwnd_ = parentHwnd;
    parent_hwnd_ = GetParent(parentHwnd);

    if (!parent_hwnd_) {
        // If no parent, use the Flutter view itself
        parent_hwnd_ = parentHwnd;
        flutter_view_hwnd_ = nullptr;
    }

    std::cout << "[MpvPlayerCore] Flutter view HWND: " << flutter_view_hwnd_
              << ", Parent HWND: " << parent_hwnd_ << std::endl;

    // Register window class if not already done
    if (!window_class_registered) {
        WNDCLASSW wc = {};
        wc.lpfnWndProc = DefWindowProcW;
        wc.hInstance = GetModuleHandle(nullptr);
        wc.lpszClassName = kVideoWindowClass;
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);

        if (!RegisterClassW(&wc)) {
            DWORD error = GetLastError();
            if (error != ERROR_CLASS_ALREADY_EXISTS) {
                std::cerr << "[MpvPlayerCore] Failed to register window class: " << error << std::endl;
                return false;
            }
        }
        window_class_registered = true;
    }

    // Get the client area of the parent window
    RECT clientRect;
    GetClientRect(parent_hwnd_, &clientRect);

    // Create video window as a CHILD of the top-level window (sibling to Flutter view)
    // This allows proper z-ordering between siblings
    video_hwnd_ = CreateWindowExW(
        0,                              // No extended styles needed for child
        kVideoWindowClass,              // Window class
        L"",                            // Window title
        WS_CHILD | WS_CLIPSIBLINGS,     // Child window, clip siblings for proper rendering
        0, 0,                           // Position (relative to parent client area)
        clientRect.right - clientRect.left,
        clientRect.bottom - clientRect.top,
        parent_hwnd_,                   // Parent is the top-level window
        nullptr,                        // Menu
        GetModuleHandle(nullptr),       // Instance
        nullptr                         // Additional data
    );

    if (!video_hwnd_) {
        std::cerr << "[MpvPlayerCore] Failed to create video window: " << GetLastError() << std::endl;
        return false;
    }

    // Position video window BEHIND the Flutter view in z-order
    // The Flutter view should be on top
    if (flutter_view_hwnd_) {
        SetWindowPos(video_hwnd_, HWND_BOTTOM, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }

    std::cout << "[MpvPlayerCore] Video window created as sibling to Flutter view" << std::endl;

    // Create MPV context
    mpv_ = mpv_create();
    if (!mpv_) {
        std::cerr << "[MpvPlayerCore] Failed to create MPV context" << std::endl;
        DestroyWindow(video_hwnd_);
        video_hwnd_ = nullptr;
        return false;
    }

    // Set the window handle for rendering
    int64_t wid = reinterpret_cast<int64_t>(video_hwnd_);
    if (mpv_set_option(mpv_, "wid", MPV_FORMAT_INT64, &wid) < 0) {
        std::cerr << "[MpvPlayerCore] Failed to set wid option" << std::endl;
    }

    // Video output configuration for D3D11
    mpv_set_option_string(mpv_, "vo", "gpu");
    mpv_set_option_string(mpv_, "gpu-api", "d3d11");
    mpv_set_option_string(mpv_, "hwdec", "auto");
    mpv_set_option_string(mpv_, "target-colorspace-hint", "yes");

    // Logging
#ifdef _DEBUG
    mpv_request_log_messages(mpv_, "info");
#else
    mpv_request_log_messages(mpv_, "warn");
#endif

    // Initialize MPV
    int initResult = mpv_initialize(mpv_);
    if (initResult < 0) {
        std::cerr << "[MpvPlayerCore] mpv_initialize failed: " << mpv_error_string(initResult) << std::endl;
        mpv_terminate_destroy(mpv_);
        mpv_ = nullptr;
        DestroyWindow(video_hwnd_);
        video_hwnd_ = nullptr;
        return false;
    }

    // Set up wakeup callback for event handling
    mpv_set_wakeup_callback(mpv_, WakeupCallback, this);

    initialized_ = true;
    std::cout << "[MpvPlayerCore] Initialized successfully" << std::endl;
    return true;
}

void MpvPlayerCore::WakeupCallback(void* ctx) {
    auto* core = static_cast<MpvPlayerCore*>(ctx);
    // Post to flutter_view_hwnd_ if available (where message hook is installed)
    HWND targetHwnd = core->flutter_view_hwnd_ ? core->flutter_view_hwnd_ : core->parent_hwnd_;
    if (core && targetHwnd) {
        // Post message to main thread for event processing
        PostMessage(targetHwnd, WM_MPV_WAKEUP, 0, reinterpret_cast<LPARAM>(core));
    }
}

void MpvPlayerCore::ProcessEvents() {
    std::lock_guard<std::mutex> lock(event_mutex_);

    if (!mpv_) return;

    while (true) {
        mpv_event* event = mpv_wait_event(mpv_, 0);
        if (!event || event->event_id == MPV_EVENT_NONE) {
            break;
        }
        HandleEvent(event);
    }
}

void MpvPlayerCore::HandleEvent(mpv_event* event) {
    switch (event->event_id) {
        case MPV_EVENT_PROPERTY_CHANGE: {
            auto* prop = static_cast<mpv_event_property*>(event->data);
            if (prop) {
                HandlePropertyChange(prop);
            }
            break;
        }

        case MPV_EVENT_FILE_LOADED:
            if (delegate_) {
                delegate_->OnEvent("file-loaded", nullptr);
            }
            break;

        case MPV_EVENT_END_FILE:
            if (delegate_) {
                delegate_->OnEvent("end-file", nullptr);
            }
            break;

        case MPV_EVENT_SHUTDOWN:
            std::cout << "[MpvPlayerCore] MPV shutdown event" << std::endl;
            break;

        case MPV_EVENT_LOG_MESSAGE: {
            auto* msg = static_cast<mpv_event_log_message*>(event->data);
            if (msg && msg->text) {
                std::cout << "[MPV:" << (msg->prefix ? msg->prefix : "")
                         << "] " << (msg->level ? msg->level : "") << ": " << msg->text;
            }
            break;
        }

        default:
            break;
    }
}

void MpvPlayerCore::HandlePropertyChange(mpv_event_property* prop) {
    if (!delegate_ || !prop->name) return;

    std::string name(prop->name);
    MpvValue value;

    switch (prop->format) {
        case MPV_FORMAT_DOUBLE:
            if (prop->data) {
                value = *static_cast<double*>(prop->data);
            }
            break;

        case MPV_FORMAT_FLAG:
            if (prop->data) {
                value = (*static_cast<int*>(prop->data)) != 0;
            }
            break;

        case MPV_FORMAT_STRING:
            if (prop->data) {
                const char* str = *static_cast<const char**>(prop->data);
                if (str) {
                    value = std::string(str);
                }
            }
            break;

        case MPV_FORMAT_NODE:
            if (prop->data) {
                auto* node = static_cast<mpv_node*>(prop->data);
                value = ConvertMpvNode(node);
            }
            break;

        default:
            break;
    }

    delegate_->OnPropertyChange(name, value);
}

MpvValue MpvPlayerCore::ConvertMpvNode(mpv_node* node) {
    if (!node) return std::monostate{};

    switch (node->format) {
        case MPV_FORMAT_STRING:
            return node->u.string ? std::string(node->u.string) : std::string();

        case MPV_FORMAT_FLAG:
            return node->u.flag != 0;

        case MPV_FORMAT_INT64:
            return node->u.int64;

        case MPV_FORMAT_DOUBLE:
            return node->u.double_;

        case MPV_FORMAT_NODE_ARRAY: {
            if (!node->u.list) return std::monostate{};

            std::vector<std::map<std::string, std::variant<std::monostate, bool, int64_t, double, std::string>>> array;
            for (int i = 0; i < node->u.list->num; i++) {
                auto itemValue = ConvertMpvNode(&node->u.list->values[i]);
                // For track-list, each item is a map
                if (node->u.list->values[i].format == MPV_FORMAT_NODE_MAP) {
                    std::map<std::string, std::variant<std::monostate, bool, int64_t, double, std::string>> map;
                    auto* list = node->u.list->values[i].u.list;
                    if (list && list->keys) {
                        for (int j = 0; j < list->num; j++) {
                            if (list->keys[j]) {
                                std::string key(list->keys[j]);
                                auto val = ConvertMpvNode(&list->values[j]);
                                // Convert MpvValue to the simpler variant for the map
                                std::visit([&map, &key](auto&& arg) {
                                    using T = std::decay_t<decltype(arg)>;
                                    if constexpr (std::is_same_v<T, bool>) {
                                        map[key] = arg;
                                    } else if constexpr (std::is_same_v<T, int64_t>) {
                                        map[key] = arg;
                                    } else if constexpr (std::is_same_v<T, double>) {
                                        map[key] = arg;
                                    } else if constexpr (std::is_same_v<T, std::string>) {
                                        map[key] = arg;
                                    } else {
                                        map[key] = std::monostate{};
                                    }
                                }, val);
                            }
                        }
                    }
                    array.push_back(map);
                }
            }
            return array;
        }

        case MPV_FORMAT_NODE_MAP: {
            // For top-level maps, we don't have a good way to return them
            // in the current MpvValue type, so return monostate
            return std::monostate{};
        }

        default:
            return std::monostate{};
    }
}

void MpvPlayerCore::SetProperty(const std::string& name, const std::string& value) {
    if (!mpv_) return;
    mpv_set_property_string(mpv_, name.c_str(), value.c_str());
}

std::string MpvPlayerCore::GetProperty(const std::string& name) {
    if (!mpv_) return "";

    char* result = mpv_get_property_string(mpv_, name.c_str());
    if (!result) return "";

    std::string value(result);
    mpv_free(result);
    return value;
}

void MpvPlayerCore::ObserveProperty(const std::string& name, const std::string& format) {
    if (!mpv_) return;

    mpv_format mpvFormat;
    if (format == "double") {
        mpvFormat = MPV_FORMAT_DOUBLE;
    } else if (format == "flag") {
        mpvFormat = MPV_FORMAT_FLAG;
    } else if (format == "node") {
        mpvFormat = MPV_FORMAT_NODE;
    } else if (format == "string") {
        mpvFormat = MPV_FORMAT_STRING;
    } else {
        return;
    }

    mpv_observe_property(mpv_, 0, name.c_str(), mpvFormat);
}

void MpvPlayerCore::Command(const std::vector<std::string>& args) {
    if (!mpv_ || args.empty()) return;

    // Build array of C strings
    std::vector<const char*> cargs;
    for (const auto& arg : args) {
        cargs.push_back(arg.c_str());
    }
    cargs.push_back(nullptr);  // null-terminate

    mpv_command(mpv_, cargs.data());
}

void MpvPlayerCore::SetVisible(bool visible) {
    visible_ = visible;

    if (video_hwnd_) {
        if (visible) {
            // Update position first, then show
            UpdateFrame();
            ShowWindow(video_hwnd_, SW_SHOWNOACTIVATE);
        } else {
            ShowWindow(video_hwnd_, SW_HIDE);
        }
    }

    std::cout << "[MpvPlayerCore] setVisible(" << (visible ? "true" : "false") << ")" << std::endl;
}

void MpvPlayerCore::UpdateFrame() {
    if (!video_hwnd_ || !parent_hwnd_) return;

    // Get the client area of the parent window (in client coordinates)
    RECT clientRect;
    GetClientRect(parent_hwnd_, &clientRect);

    // Resize video window to match parent's client area
    // Keep it at HWND_BOTTOM to stay behind the Flutter view
    SetWindowPos(video_hwnd_, HWND_BOTTOM,
                0, 0,
                clientRect.right - clientRect.left,
                clientRect.bottom - clientRect.top,
                SWP_NOACTIVATE);

    std::cout << "[MpvPlayerCore] updateFrame: " << (clientRect.right - clientRect.left) << "x" << (clientRect.bottom - clientRect.top) << std::endl;
}

void MpvPlayerCore::Dispose() {
    std::lock_guard<std::mutex> lock(event_mutex_);

    if (mpv_) {
        mpv_terminate_destroy(mpv_);
        mpv_ = nullptr;
    }

    if (video_hwnd_) {
        DestroyWindow(video_hwnd_);
        video_hwnd_ = nullptr;
    }

    initialized_ = false;
    std::cout << "[MpvPlayerCore] Disposed" << std::endl;
}
