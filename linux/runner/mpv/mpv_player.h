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

/// Wrapper for libmpv that handles initialization, OpenGL rendering,
/// commands, properties, and event dispatching.
class MpvPlayer {
 public:
  MpvPlayer();
  ~MpvPlayer();

  /// Initializes mpv with OpenGL rendering context.
  /// Must be called from the GTK main thread after GL context is available.
  /// @param gl_area The GtkGLArea widget for rendering.
  /// @return true if initialization succeeded.
  bool Initialize(GtkGLArea* gl_area);

  /// Disposes mpv and releases resources.
  void Dispose();

  /// Returns true if mpv is initialized.
  bool IsInitialized() const { return mpv_ != nullptr && mpv_gl_ != nullptr; }

  /// Executes an mpv command.
  /// @param args Command arguments (e.g., ["loadfile", "url", "replace"]).
  void Command(const std::vector<std::string>& args);

  /// Callback type for async command completion.
  using CommandCallback = std::function<void(int error)>;

  /// Executes an mpv command asynchronously to prevent UI blocking.
  /// The callback is called on the main thread when the command completes.
  /// @param args Command arguments.
  /// @param callback Callback called with error code (0 = success).
  void CommandAsync(const std::vector<std::string>& args, CommandCallback callback);

  /// Sets an mpv property by name.
  /// @param name Property name.
  /// @param value Property value as string.
  void SetProperty(const std::string& name, const std::string& value);

  /// Gets an mpv property value by name.
  /// @param name Property name.
  /// @return Property value as string, or empty if not found.
  std::string GetProperty(const std::string& name);

  /// Observes an mpv property for changes.
  /// Changes will be reported via the event callback.
  /// @param name Property name to observe.
  /// @param format Format type ("string", "flag", "int64", "double", "node").
  /// @param id Property ID assigned by Dart for compact event encoding.
  void ObserveProperty(const std::string& name, const std::string& format,
                       int id);

  /// Renders a frame to the current OpenGL context.
  /// Must be called from the GTK render callback.
  /// @param width Viewport width.
  /// @param height Viewport height.
  /// @param fbo Framebuffer object to render into (0 for default).
  void Render(int width, int height, int fbo = 0);

  /// Reports that the mouse has moved.
  /// This is used to show/hide the cursor.
  void ReportMouseMove(int x, int y);

  /// Sets the event callback for property changes and events.
  void SetEventCallback(EventCallback callback);

  /// Returns the GtkGLArea widget.
  GtkGLArea* GetGLArea() const { return gl_area_; }

  /// Returns true if a redraw is needed.
  bool NeedsRedraw() const { return needs_redraw_.load(); }

  /// Clears the redraw flag.
  void ClearRedrawFlag() { needs_redraw_.store(false); }

  /// Request a redraw.
  void RequestRedraw();

  /// Sets the MPV log message level (e.g., "warn", "v", "debug").
  void SetLogLevel(const std::string& level);

 private:
  /// MPV event wakeup callback (called from mpv thread).
  static void OnMpvWakeup(void* ctx);

  /// MPV render update callback (called when frame is ready).
  static void OnMpvRenderUpdate(void* ctx);

  /// Processes pending mpv events.
  /// @return true to keep processing, false if shutdown.
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
  GtkGLArea* gl_area_ = nullptr;

  std::atomic<bool> needs_redraw_{false};
  std::atomic<bool> disposed_{false};
  EventCallback event_callback_;
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
