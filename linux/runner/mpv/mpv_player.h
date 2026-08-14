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
#include <deque>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <tuple>
#include <vector>

#include "../../../shared/mpv/mpv_player_common.h"
#include "hdr_metadata.h"
#include "video_params.h"

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
  /// no render context is ever created (InitRenderContextForSurface must not
  /// be called) and no GL/EGL state is touched.
  explicit MpvPlayer(bool audio_only = false);
  ~MpvPlayer();

  /// Initializes the mpv instance and configures options.
  /// Does NOT create the render context — call InitRenderContextForSurface()
  /// once the video plane's EGL surface exists.
  /// @return true if initialization succeeded.
  bool Initialize();

  /// Creates the mpv render context bound to the app-owned EGL window surface
  /// backing the Wayland video plane. This is the only render path: nothing
  /// here is shared with or derived from Flutter's GL state, so the context is
  /// free to be ES 3.x.
  ///
  /// `depth_bits` is the plane's bits per colour channel. mpv takes the
  /// target's precision from MPV_RENDER_PARAM_DEPTH and from nothing else —
  /// the render API's OpenGL backend ignores mpv_opengl_fbo::internal_format —
  /// and assumes 8 when it is absent, which would dither a PQ plane to 8 bits
  /// and band it exactly where the 10-bit config was chosen to avoid that.
  /// @return true if render context creation succeeded.
  bool InitRenderContextForSurface(EGLDisplay display, EGLConfig config, EGLSurface surface, int depth_bits);

  /// Renders one frame into |surface|'s default framebuffer. The caller
  /// presents it (eglSwapBuffers) once this returns.
  /// @return true if the frame was rendered.
  bool RenderToSurface(EGLSurface surface, int width, int height);

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

  /// What became of an HDR output request. The caller has to distinguish these,
  /// because each implies a different truth about the surface description it may
  /// already have committed.
  enum class HdrOutputResult {
    /// mpv is in the requested colour space; the caller's new description is true.
    kApplied,
    /// Refused, and mpv is back in the colour space it had; the previously
    /// committed description is still true and must be left alone.
    kRestored,
    /// Refused, and could not be put back, so it was forced to SDR. Any committed
    /// HDR description is now a lie about the pixels and must be unset.
    kForcedSdr,
    /// Refused, and mpv no longer accepts even `auto`. What it emits is unknowable,
    /// so no description is correct and the plane should not be presented.
    kUnknown,
  };
  using HdrOutputCallback = std::function<void(HdrOutputResult, int)>;

  /// Switches mpv's output colour space between HDR passthrough and its normal
  /// tone-mapped SDR output.
  ///
  /// `target-colorspace-hint` is deliberately not used: it is declared by
  /// vo_gpu_next only, so the render API — which runs the legacy gpu renderer —
  /// ignores it entirely. target-trc/target-prim are what that renderer reads.
  ///
  /// `transfer` is the curve mpv should emit, taken from the source rather than
  /// assumed: HLG content described to the compositor as HLG must also be
  /// *encoded* as HLG. SourceTransfer::kSdr restores the tone-mapped output.
  ///
  /// The output-description properties are applied as a unit, and on failure the
  /// ones that landed are unwound — awaited, not fired and forgotten — so that by
  /// the time the callback runs mpv is in exactly the state the result names.
  ///
  /// `target_peak_nits` decides who tone-maps. Zero (or anything outside mpv's
  /// 10..10000 range) leaves `target-peak` on auto, which under PQ resolves to
  /// the format's nominal 10000 nits so the renderer passes the source through
  /// untouched and the compositor tone-maps. A real display peak makes mpv
  /// tone-map to it instead, and the caller should then declare that peak to the
  /// compositor so it has nothing left to do.
  void SetHdrOutput(SourceTransfer transfer, uint32_t target_peak_nits, HdrOutputCallback callback);

#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
  /// Focused-test boundary for the output-colour-space transaction above.
  ///
  /// The whole ladder — apply, unwind, force SDR — is control flow over one
  /// primitive: "set this property to this string, then call back with an mpv
  /// error code". Substituting that primitive is what lets the sequence, its
  /// ordering and its escalation be observed without libmpv or a compositor,
  /// exactly as NativeRenderTeardownOperations substitutes EGL above.
  ///
  /// Installing a writer also makes the output properties commandable with no
  /// core present: the writer *is* the core as far as the ladder can tell, so
  /// the usual "no handle, nothing to command" short-circuit would otherwise
  /// answer every request before its first step ran.
  using PropertyWriteForTesting =
      std::function<void(const std::string& name, const std::string& value, StatusCallback callback)>;
  void ConfigurePropertyWritesForTesting(PropertyWriteForTesting writer);

  /// The output colour space mpv last accepted in full — the rollback target,
  /// and what a caller's committed surface description is measured against.
  struct AppliedOutputColourSpace {
    std::string target_trc;
    std::string target_prim;
    std::string tone_mapping;
    std::string target_peak;
  };
  AppliedOutputColourSpace AppliedOutputColourSpaceForTesting() const;
#endif

  /// Copies the current source's colour space and HDR10 static metadata out of
  /// the cache `video-params` fills. Returns false only when there is no player
  /// to ask; a source that carries no metadata still fills in the transfer and
  /// primaries names.
  ///
  /// Synchronous and free: nothing here reaches the core, which is the point.
  /// Every caller is on the GTK main thread and one of them runs on every seek.
  bool ReadSourceHdrMetadata(SourceHdrMetadata* out);

  /// Called on the main context whenever `video-params` changes, i.e. whenever
  /// the cache above has just been rewritten.
  ///
  /// This exists because the change is not ordered against playback-restart: a
  /// reconfigure that lands after the restart would otherwise leave the HDR
  /// decision standing on the previous file's colour space. The caller re-runs
  /// its decision from here, so a late parse still converges.
  using SourceMetadataCallback = std::function<void()>;
  void SetSourceMetadataCallback(SourceMetadataCallback callback);

  /// Gets an mpv property value asynchronously.
  void GetPropertyAsync(const std::string& name, GetPropertyCallback callback);

  /// Observes an mpv property for changes.
  void ObserveProperty(const std::string& name, const std::string& format, int id);

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

  /// Whether there is anything to send the output-colour-space properties to.
  /// Named rather than spelled out at both entry points because the focused
  /// test substitutes the write primitive and so answers this differently; see
  /// ConfigurePropertyWritesForTesting. Public because the plugin's kUnknown
  /// handling distinguishes a live core (present undescribed) from one that is
  /// genuinely going away (hide the plane).
  bool CanCommandOutputProperties() const;

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

  /// Reparses the `video-params` payload into source_hdr_metadata_ and tells
  /// the source-metadata callback that it moved. The parse happens under
  /// native_mutex_; the callback runs outside it, because what it goes on to do
  /// reads the cache straight back.
  void UpdateSourceHdrMetadata(const mpv_node* params);

  /// Sends an event notification.
  void SendEvent(const std::string& name, ::_FlValue* data = nullptr);
  void MaybeRunAudioRecovery();
  void TryAudioReload(const char* reason, int attempt, uint64_t request_generation);
  void EnsureAudioRecoveryTimer();
  void LogRecovery(const std::string& text);
  void SetHDREnabled(bool enabled, StatusCallback callback = nullptr);

  /// One step of an all-or-nothing property change: the value to set, and the
  /// value to restore if a *later* step in the same sequence fails.
  struct PropertyChange {
    std::string name;
    std::string value;
    std::string rollback;
  };

  /// Applies `changes` in order, starting at `index`. On the first failure every
  /// earlier change is rolled back, newest first, and the callback reports that
  /// failure; otherwise the callback reports success once all of them landed.
  ///
  /// Shared ownership because each step completes on an mpv thread after this
  /// call has returned.
  void ApplyPropertySequence(
      std::shared_ptr<std::vector<PropertyChange>> changes, size_t index, StatusCallback callback);

  /// Restores the first `undo_count` changes, newest first, awaiting each reply
  /// before the next. `failure` is the error that triggered the unwinding and is
  /// what the callback finally reports — the outcome of the rollback itself is not
  /// what the caller needs to know.
  ///
  /// Awaited rather than fired and forgotten: the caller releases the video
  /// plane's present hold and starts the next request the moment it is told, so a
  /// rollback still in flight would let a frame reach the screen in a colour space
  /// that is neither the old one nor the new.
  void RollbackPropertySequence(
      std::shared_ptr<std::vector<PropertyChange>> changes, size_t undo_count, int failure, StatusCallback callback);

  /// Drives every target property to `auto` — the one state that is always
  /// describable and always accepts its value — after an unwinding step itself
  /// failed. Reports `failure`, the original refusal, once mpv is settled.
  void ForceSdrOutput(size_t index, int failure, StatusCallback callback);

  /// The single writer of the applied-output cache, so every path that moves one
  /// of the four colour properties records it the same way.
  void RecordAppliedOutputProperty(const std::string& name, const std::string& value);

  /// Runs the next queued HDR output request. One sequence at a time; the next
  /// starts only after the previous has finished, rollbacks included.
  void RunPendingHdrOutput();

  /// A desired output colour space, waiting its turn, with the callback that
  /// asked for it. SetHdrOutput explains why each keeps its own callback.
  struct HdrOutputRequest {
    SourceTransfer transfer = SourceTransfer::kSdr;
    uint32_t peak_nits = 0;
    HdrOutputCallback callback;
  };

  /// Helper to convert mpv_node to FlValue, bounded by the shared node budget.
  ::_FlValue* NodeToFlValue(mpv_node* node);
  ::_FlValue* NodeToFlValue(mpv_node* node, plezy::mpv_common::NodeConversionBudget* budget);

  const bool audio_only_;
  mpv_handle* mpv_ = nullptr;
  mpv_render_context* mpv_gl_ = nullptr;

  // Isolated EGL context for mpv rendering (not shared with Flutter)
  EGLDisplay egl_display_ = EGL_NO_DISPLAY;
  EGLContext egl_context_ = EGL_NO_CONTEXT;

  // The output colour space mpv last accepted in full, so a refused change can
  // be unwound to something real instead of a guess. mpv's own defaults.
  std::string applied_target_peak_ = "auto";
  std::string applied_target_prim_ = "auto";
  std::string applied_target_trc_ = "auto";
  // Carried with the output description rather than set once globally: it selects
  // the tone-map operator, but in this mpv it also drives gamut reduction, so a
  // global value would reach wide-gamut SDR content that has no tone mapping to
  // do. It is applied and withdrawn again with the rest of the description,
  // whenever a tone-map pass starts or stops running.
  std::string applied_tone_mapping_ = "auto";
  // Whether the four strings above still describe what mpv holds. False after a
  // forced-SDR reset that was itself refused partway: some of it landed and some
  // did not, so they record what was asked for rather than what is in force, and
  // the no-op short-circuit must not answer from them. A clean apply, or a reset
  // that completes, earns the trust back.
  bool output_state_known_ = true;
  // What the unwinding of a refused sequence achieved. Reset to kRestored before
  // each sequence; the escalation path moves it to kForcedSdr or kUnknown, and
  // RunPendingHdrOutput reports whichever applies.
  HdrOutputResult hdr_unwind_result_ = HdrOutputResult::kRestored;
  // Serialization for SetHdrOutput. Touched only from the GLib main context:
  // requests arrive from the platform channel and from mpv event handling, and
  // ProcessEvents runs on a main-context source, so replies land on that same
  // thread rather than on an mpv worker.
  bool hdr_sequence_in_flight_ = false;
  std::deque<HdrOutputRequest> hdr_queue_;
#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
  // The substituted property-write primitive; empty in every build that has a
  // real core to write to. See ConfigurePropertyWritesForTesting.
  PropertyWriteForTesting test_property_write_;
#endif
  // Bits per colour channel of the video plane, told to mpv on every render so
  // it dithers to the plane's real precision instead of the assumed 8.
  int surface_depth_bits_ = 8;
  // What `video-params` last reported, parsed once on the change event instead
  // of read back from the core on every HDR decision. Guarded by native_mutex_:
  // written from event handling, read by ReadSourceHdrMetadata.
  SourceHdrMetadata source_hdr_metadata_;
  mutable std::mutex native_mutex_;

  std::atomic<bool> needs_redraw_{false};
  std::atomic<bool> disposed_{false};
  EventCallback event_callback_;
  RedrawCallback redraw_callback_;
  SourceMetadataCallback source_metadata_callback_;
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
