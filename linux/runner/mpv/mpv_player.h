#ifndef MPV_PLAYER_H_
#define MPV_PLAYER_H_

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <gtk/gtk.h>
#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

#include <atomic>
#include <condition_variable>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <tuple>
#include <vector>

#include "../../../shared/mpv/mpv_player_common.h"

// Forward declaration for Flutter types
struct _FlValue;

namespace mpv {

/// Callback function type for mpv events.
/// Note: FlValue* is passed from the global namespace, not mpv namespace.
using EventCallback = std::function<void(::_FlValue*)>;

/// Callback for requesting a redraw (called from mpv render update thread).
using RedrawCallback = std::function<void()>;

// Linux-runner-internal teardown boundary. A render context may only be
// released while its EGL context is current; the batch retains the shared mpv
// handle until every render/context pair has been safely released.
struct NativeRenderTeardownResource {
  mpv_render_context* render = nullptr;
  EGLDisplay display = EGL_NO_DISPLAY;
  EGLContext context = EGL_NO_CONTEXT;
};

struct NativeRenderTeardownBatch {
  std::vector<NativeRenderTeardownResource> resources;
  mpv_handle* handle = nullptr;
  std::shared_ptr<void> callback_keep_alive;
};

struct NativeRenderTeardownOperations {
  std::function<bool(EGLDisplay, EGLContext)> make_current;
  std::function<bool(EGLDisplay)> release_current;
  std::function<bool(EGLDisplay, EGLContext)> destroy_context;
  std::function<void(mpv_render_context*)> free_render;
  std::function<void(mpv_handle*)> terminate_handle;
};

// Attempts one teardown pass. Failed resources remain owned by |batch| for a
// later retry, and |handle| is never terminated while any resource remains.
bool TryReleaseNativeRenderTeardown(NativeRenderTeardownBatch& batch, const NativeRenderTeardownOperations& operations);

// Releases render contexts retained by a failed initialization attempt. A
// false result must block another render-context creation on the same core.
bool TryReleaseRetainedNativeRenderContexts(
    std::vector<NativeRenderTeardownResource>& resources, const NativeRenderTeardownOperations& operations);

#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
// Focused-test boundary for exercising the process-lifetime teardown queue
// without invoking real EGL or libmpv resources.
void ConfigureNativeRenderTeardownQueueForTesting(NativeRenderTeardownOperations operations);
void EnqueueNativeRenderTeardownForTesting(NativeRenderTeardownBatch batch);
#endif

/// Wrapper for libmpv that handles initialization, OpenGL rendering,
/// commands, properties, and event dispatching.
class MpvPlayer {
 public:
  /// |audio_only| runs mpv as a music core with video disabled entirely:
  /// no render context is ever created (InitRenderContext must not be
  /// called) and no GL/EGL state is touched.
  explicit MpvPlayer(bool audio_only = false);
  ~MpvPlayer();

  /// Initializes the mpv instance and configures options.
  /// Does NOT create the render context — call InitRenderContext() later
  /// when an OpenGL context is available.
  /// @return true if initialization succeeded.
  bool Initialize();

  /// Creates the mpv OpenGL render context.
  /// Must be called with a valid GL context current (e.g., from FlTextureGL::populate).
  /// Fails on audio-only players.
  /// @return true if render context creation succeeded.
  bool InitRenderContext();

  /// Returns true if the render context has been created.
  bool HasRenderContext() const;

  /// Returns the isolated EGL display used for mpv rendering.
  EGLDisplay GetEglDisplay() const;

  /// Returns the isolated EGL context used for mpv rendering.
  EGLContext GetEglContext() const;

  /// Disposes mpv and releases resources.
  void Dispose();

  /// Returns true if mpv is initialized (has both mpv handle and render
  /// context; audio-only players never have a render context).
  bool IsInitialized() const;

  /// Returns true if this player has been disposed.
  bool IsDisposed() const { return disposed_.load(); }

  /// Returns true if mpv handle exists (even without render context).
  bool HasMpvHandle() const;

  /// Queues an mpv command without waiting for completion.
  void Command(const std::vector<std::string>& args);

  /// Callback types for async mpv requests.
  using StatusCallback = plezy::mpv_common::StatusCallback;
  using CommandCallback = StatusCallback;
  using GetPropertyCallback = plezy::mpv_common::GetPropertyCallback;

  /// Executes an mpv command asynchronously to prevent UI blocking.
  void CommandAsync(const std::vector<std::string>& args, CommandCallback callback);

  /// Sets an mpv property by name.
  void SetProperty(const std::string& name, const std::string& value);

  /// Sets an mpv property asynchronously.
  void SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback);

  /// Gets an mpv property value asynchronously.
  void GetPropertyAsync(const std::string& name, GetPropertyCallback callback);

  /// Observes an mpv property for changes.
  void ObserveProperty(const std::string& name, const std::string& format, int id);

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

  /// Retries process-owned native teardown work on the managed EGL teardown
  /// thread. Primarily useful before creating another render context.
  static void RetryPendingNativeTeardown();

 private:
  class CallbackContext {
   public:
    class Lease {
     public:
      Lease() = default;
      Lease(const Lease&) = delete;
      Lease& operator=(const Lease&) = delete;
      Lease(Lease&& other) noexcept;
      Lease& operator=(Lease&& other) noexcept;
      ~Lease();

      explicit operator bool() const { return player_ != nullptr; }
      MpvPlayer* player() const { return player_; }

     private:
      friend class CallbackContext;
      Lease(CallbackContext* context, MpvPlayer* player);
      void Release();

      CallbackContext* context_ = nullptr;
      MpvPlayer* player_ = nullptr;
    };

    explicit CallbackContext(MpvPlayer* player);
    ~CallbackContext();

    Lease Acquire();
    void DetachAndWait();
    void WaitUntilDetached();
    GMainContext* main_context() const { return main_context_; }

   private:
    void ReleaseLease();

    std::mutex mutex_;
    std::condition_variable quiescent_;
    MpvPlayer* player_;
    size_t in_flight_ = 0;
    GMainContext* main_context_;
  };

  struct SourceCallbackData;

  friend class MpvPlayerLifecycleTestPeer;

  /// MPV event wakeup callback (called from mpv thread).
  static void OnMpvWakeup(void* ctx);

  /// MPV render update callback (called when frame is ready).
  static void OnMpvRenderUpdate(void* ctx);

  static gboolean DispatchWakeupSource(gpointer data);
  static gboolean DispatchRedrawSource(gpointer data);
  static gboolean DispatchRecoverySource(gpointer data);
  static void DestroySourceCallbackData(gpointer data);

  void ScheduleWakeupSource();
  void ScheduleRedrawSource();
  void ScheduleRecoverySource();
  void RemoveTrackedSources();

  /// Processes pending mpv events.
  bool ProcessEvents();

  /// Handles a single mpv event.
  void HandleMpvEvent(mpv_event* event);

  /// Sends a property change notification.
  void SendPropertyChange(const char* name, mpv_node* data);

  /// Sends an event notification.
  void SendEvent(const std::string& name, ::_FlValue* data = nullptr);
  void MaybeRunAudioRecovery();
  void TryAudioReload(const char* reason, int attempt, uint64_t request_generation);
  void EnsureAudioRecoveryTimer();
  void LogRecovery(const std::string& text);
  void SetHDREnabled(bool enabled, StatusCallback callback = nullptr);

  struct NodeConversionBudget {
    size_t remaining_entries;
    size_t remaining_bytes;
  };

  /// Helper to convert mpv_node to FlValue.
  ::_FlValue* NodeToFlValue(mpv_node* node);
  ::_FlValue* NodeToFlValue(mpv_node* node, size_t depth, NodeConversionBudget* budget);
  bool ConvertNodeString(const char* input, NodeConversionBudget* budget, std::string* result);

  const bool audio_only_;
  mpv_handle* mpv_ = nullptr;
  mpv_render_context* mpv_gl_ = nullptr;

  // Isolated EGL context for mpv rendering (not shared with Flutter)
  EGLDisplay egl_display_ = EGL_NO_DISPLAY;
  EGLContext egl_context_ = EGL_NO_CONTEXT;
  std::vector<NativeRenderTeardownResource> retained_render_contexts_;
  mutable std::mutex native_mutex_;

  std::atomic<bool> needs_redraw_{false};
  std::atomic<bool> disposed_{false};
  EventCallback event_callback_;
  RedrawCallback redraw_callback_;
  std::mutex callback_mutex_;
  plezy::mpv_common::AudioRecoveryState audio_recovery_;
  plezy::mpv_common::AsyncRequestRegistry pending_requests_;
  plezy::mpv_common::PropertyObservationRegistry observed_properties_;
  bool hdr_enabled_ = true;

  // All player-carrying sources are attached to CallbackContext::main_context()
  // and protected by source_mutex_.
  std::shared_ptr<CallbackContext> callback_context_;
  std::mutex source_mutex_;
  guint wakeup_source_id_ = 0;
  guint redraw_source_id_ = 0;
  guint recovery_source_id_ = 0;
};

}  // namespace mpv

#endif  // MPV_PLAYER_H_
