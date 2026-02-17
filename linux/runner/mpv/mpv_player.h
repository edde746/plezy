#ifndef MPV_PLAYER_H_
#define MPV_PLAYER_H_

#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>
#include <gtk/gtk.h>
#include <epoxy/gl.h>

#include <atomic>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// Forward declaration for Flutter types
struct _FlValue;

namespace mpv {

/// Callback function type for mpv events.
/// Note: FlValue* is passed from the global namespace, not mpv namespace.
using EventCallback = std::function<void(::_FlValue*)>;

/// Callback for requesting a redraw (called from mpv render update thread).
using RedrawCallback = std::function<void()>;

/// Wrapper for libmpv that handles initialization, OpenGL rendering,
/// commands, properties, and event dispatching.
class MpvPlayer {
 public:
  MpvPlayer();
  ~MpvPlayer();

  /// Initializes the mpv instance and configures options.
  /// Does NOT create the render context — call InitRenderContext() later
  /// when an OpenGL context is available.
  /// @return true if initialization succeeded.
  bool Initialize();

  /// Creates the mpv OpenGL render context.
  /// Must be called with a valid GL context current (e.g., from FlTextureGL::populate).
  /// @return true if render context creation succeeded.
  bool InitRenderContext();

  /// Returns true if the render context has been created.
  bool HasRenderContext() const { return mpv_gl_ != nullptr; }

  /// Disposes mpv and releases resources.
  void Dispose();

  /// Returns true if mpv is initialized (has both mpv handle and render context).
  bool IsInitialized() const { return mpv_ != nullptr && mpv_gl_ != nullptr; }

  /// Returns true if mpv handle exists (even without render context).
  bool HasMpvHandle() const { return mpv_ != nullptr; }

  /// Executes an mpv command.
  void Command(const std::vector<std::string>& args);

  /// Callback type for async command completion.
  using CommandCallback = std::function<void(int error)>;

  /// Executes an mpv command asynchronously to prevent UI blocking.
  void CommandAsync(const std::vector<std::string>& args, CommandCallback callback);

  /// Sets an mpv property by name.
  void SetProperty(const std::string& name, const std::string& value);

  /// Gets an mpv property value by name.
  std::string GetProperty(const std::string& name);

  /// Observes an mpv property for changes.
  void ObserveProperty(const std::string& name, const std::string& format,
                       int id);

  /// Renders a frame to the specified FBO.
  void Render(int width, int height, int fbo = 0);

  /// Reports that the mouse has moved.
  void ReportMouseMove(int x, int y);

  /// Sets the event callback for property changes and events.
  void SetEventCallback(EventCallback callback);

  /// Sets the redraw callback (called when mpv has a new frame ready).
  void SetRedrawCallback(RedrawCallback callback);

  /// Returns true if a redraw is needed.
  bool NeedsRedraw() const { return needs_redraw_.load(); }

  /// Clears the redraw flag.
  void ClearRedrawFlag() { needs_redraw_.store(false); }

  /// Sets the MPV log message level (e.g., "warn", "v", "debug").
  void SetLogLevel(const std::string& level);

 private:
  /// MPV event wakeup callback (called from mpv thread).
  static void OnMpvWakeup(void* ctx);

  /// MPV render update callback (called when frame is ready).
  static void OnMpvRenderUpdate(void* ctx);

  /// Processes pending mpv events.
  bool ProcessEvents();

  /// Handles a single mpv event.
  void HandleMpvEvent(mpv_event* event);

  /// Sends a property change notification.
  void SendPropertyChange(const char* name, mpv_node* data);

  /// Sends an event notification.
  void SendEvent(const std::string& name, ::_FlValue* data = nullptr);

  /// Helper to convert mpv_node to FlValue.
  ::_FlValue* NodeToFlValue(mpv_node* node);

  mpv_handle* mpv_ = nullptr;
  mpv_render_context* mpv_gl_ = nullptr;

  std::atomic<bool> needs_redraw_{false};
  std::atomic<bool> disposed_{false};
  EventCallback event_callback_;
  RedrawCallback redraw_callback_;
  std::mutex callback_mutex_;

  uint64_t next_reply_userdata_ = 1;
  std::map<std::string, uint64_t> observed_properties_;
  std::map<std::string, int> name_to_id_;

  // Pending async commands: request_id -> callback
  std::map<uint64_t, CommandCallback> pending_commands_;
  std::mutex pending_commands_mutex_;

  // GSource for processing events on main thread
  guint event_source_id_ = 0;
};

}  // namespace mpv

#endif  // MPV_PLAYER_H_
