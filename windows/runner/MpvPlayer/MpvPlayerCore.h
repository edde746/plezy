#ifndef MPV_PLAYER_CORE_H_
#define MPV_PLAYER_CORE_H_

#include <windows.h>
#include <mpv/client.h>
#include <functional>
#include <string>
#include <vector>
#include <variant>
#include <map>
#include <mutex>

// Value type that can hold different property types
using MpvValue = std::variant<std::monostate, bool, int64_t, double, std::string,
                              std::vector<std::map<std::string, std::variant<std::monostate, bool, int64_t, double, std::string>>>>;

/// Delegate interface for receiving player events
class MpvPlayerDelegate {
public:
    virtual void OnPropertyChange(const std::string& name, const MpvValue& value) = 0;
    virtual void OnEvent(const std::string& name, const std::map<std::string, MpvValue>* data) = 0;
    virtual ~MpvPlayerDelegate() = default;
};

/// Core MPV player using D3D11 rendering via child HWND
class MpvPlayerCore {
public:
    MpvPlayerCore();
    ~MpvPlayerCore();

    /// Initialize the player with a parent window
    bool Initialize(HWND parentHwnd);

    /// Dispose of the player and release resources
    void Dispose();

    /// Set an MPV property
    void SetProperty(const std::string& name, const std::string& value);

    /// Get an MPV property value
    std::string GetProperty(const std::string& name);

    /// Observe property changes
    void ObserveProperty(const std::string& name, const std::string& format);

    /// Execute an MPV command
    void Command(const std::vector<std::string>& args);

    /// Show or hide the video layer
    void SetVisible(bool visible);

    /// Update the video layer frame to match parent window
    void UpdateFrame();

    /// Process pending MPV events (call from main thread)
    void ProcessEvents();

    /// Set the delegate for receiving events
    void SetDelegate(MpvPlayerDelegate* delegate) { delegate_ = delegate; }

    /// Check if initialized
    bool IsInitialized() const { return initialized_; }

    /// Get the Flutter view HWND for message handling
    HWND GetFlutterViewHwnd() const { return flutter_view_hwnd_ ? flutter_view_hwnd_ : parent_hwnd_; }

private:
    static void WakeupCallback(void* ctx);
    void HandleEvent(mpv_event* event);
    void HandlePropertyChange(mpv_event_property* prop);
    MpvValue ConvertMpvNode(mpv_node* node);

    HWND video_hwnd_ = nullptr;
    HWND parent_hwnd_ = nullptr;      // Top-level window
    HWND flutter_view_hwnd_ = nullptr; // Flutter view (sibling to video)
    mpv_handle* mpv_ = nullptr;
    MpvPlayerDelegate* delegate_ = nullptr;
    bool initialized_ = false;
    bool visible_ = false;
    std::mutex event_mutex_;
};

#endif  // MPV_PLAYER_CORE_H_
