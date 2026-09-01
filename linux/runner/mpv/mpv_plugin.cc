#include "mpv_plugin.h"

#include <cstring>
#include <deque>
#include <functional>
#include <limits>
#include <memory>
#include <new>
#include <optional>

#include "plane_render_executor.h"
#include "wayland_video_surface.h"

using PlayerPtr = std::unique_ptr<mpv::MpvPlayer>;
using VideoSurfacePtr = std::unique_ptr<mpv::WaylandVideoSurface>;
using ExecutorPtr = std::unique_ptr<mpv::PlaneRenderExecutor>;

// One queued HDR transaction: what to apply, and who to tell when it settles.
//
// `mode` is engaged only when the request *is* the mode change. Everything else
// leaves it empty and inherits whatever is in force at the moment its turn
// comes: a mode captured at enqueue time could have been refused since, and
// applying it then would put a curve on screen that Dart has already been told
// did not take.
struct PendingHdrRequest {
  bool allow = false;
  std::optional<mpv::HdrToneMapping> mode;
  std::function<void(int)> done;
};

using HdrQueue = std::deque<PendingHdrRequest>;

struct _MpvPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;
  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;

  PlayerPtr player;
  // The native Wayland plane every video instance renders into. Non-null once
  // initialize() has brought it up; there is no second render path, so a null
  // here on a video instance means initialization refused.
  VideoSurfacePtr video_surface;
  // Set when the plane must be redrawn even though mpv has no new frame -
  // after a resize or after becoming visible, where the buffer on screen is
  // stale or absent. Sticky, because the render it asks for may first have to
  // wait out an unacknowledged frame.
  gboolean plane_needs_render;
  // The worker that runs mpv's render + the plane's eglSwapBuffers off the
  // GTK main thread (issue #2057: an expensive per-frame render - a 4K HDR
  // tone-map - on the main thread starves input dispatch and Flutter's
  // raster). Created with the plane; drained and shut down in
  // release_video_resources *before* the player is disposed, which is the
  // ordering RenderToSurface's lock-free render relies on. Null when
  // PLEZY_PLANE_RENDER_MAIN_THREAD selects the inline fallback.
  ExecutorPtr render_executor;
  // A render job is somewhere between PreparePresent() and CompletePresent().
  // Gates render_video_plane - the flight owns the plane's EGL surface - and
  // defers rect application and HDR transaction starts to the completion.
  gboolean render_in_flight;
  // A rect arrived while a job was in flight. Applied at completion, because
  // wl_egl_window_resize must not race the swap.
  gboolean rect_apply_deferred;
  // An HDR transaction was ready to start while a job was in flight. Started
  // at completion; see run_next_hdr_transaction for why it must wait.
  gboolean hdr_start_deferred;
  gboolean visible;
  gboolean initialized;
  gboolean audio_only;
  // What Dart last asked for via hdr-enabled. Remembered because the answer can
  // change without Dart saying anything: moving the window to another monitor
  // changes whether the output is in HDR at all, and the plane has to be
  // re-described when it does.
  gboolean hdr_wanted;
  // The last geometry Dart sent, kept whether or not a plane existed to take
  // it. Dart sends a rect only when its numbers change, so one arriving before
  // start_video_plane is the only one the plane may ever be offered.
  struct PendingRect {
    int32_t x = 0;
    int32_t y = 0;
    int32_t width = 0;
    int32_t height = 0;
    int32_t scale = 1;
  };
  PendingRect pending_rect;
  gboolean has_pending_rect;
  // Bumped on every teardown so an async HDR callback that outlived its plane
  // can tell it is answering for a generation that no longer exists.
  guint64 generation;
  // Who tone-maps when HDR is on. Defaults to the compositor, which is the
  // behaviour that shipped first and needs no knowledge of the display; the
  // player-side path is opted into.
  //
  // Two fields, deliberately. `hdr_tone_mapping` is the mode mpv last *accepted*;
  // `hdr_tone_mapping_desired` is what the app last asked for. Requests are
  // applied strictly in order, so an internal re-apply (playback restart,
  // preferred-description change) queued behind a user's mode change must carry
  // the desired mode - reading the committed one would send the stale mode last
  // and make it final.
  mpv::HdrToneMapping hdr_tone_mapping = mpv::HdrToneMapping::kCompositor;
  mpv::HdrToneMapping hdr_tone_mapping_desired = mpv::HdrToneMapping::kCompositor;
  // Bumped per user mode request, so a failure only reverts `desired` when no
  // newer request has already replaced it.
  uint64_t hdr_mode_request_serial = 0;
  // Same purpose for hdr-enabled: a refused request must only hand hdr_wanted
  // back if no newer one has claimed it since.
  uint64_t hdr_enable_request_serial = 0;
  // Bounds the mpv leg of the in-flight HDR transaction (see apply_hdr_state):
  // zero when no transaction is waiting on a SetHdrOutput reply. A wedged core
  // must cost one transaction, not the whole queue. Zero-initialised like every
  // other scalar here; release_video_resources cancels a live source.
  guint hdr_mpv_leg_timeout_source_ = 0;
  // Exactly one HDR transaction runs at a time, end to end.
  //
  // A transaction spans staging and validating the image description, switching
  // mpv's output colour space, and committing both. Interleaving two cannot be
  // made consistent after the fact: a superseded transaction may already have
  // moved mpv, so refusing its commit leaves mpv on one curve and the surface
  // describing another. Serializing the whole thing is what makes that
  // unreachable, rather than something to detect and unwind.
  bool hdr_transaction_in_flight = false;
  // Waiting user requests, in order. Each keeps its own callback because each has
  // a Dart method call to answer, and answering one with another's outcome is the
  // same divergence one level up.
  HdrQueue hdr_queue;
  // Internal re-applies coalesce into a flag instead of queueing: they have no
  // caller to answer, playback-restart fires on every seek, and each transaction
  // re-reads the source when its turn comes, so collapsing several loses nothing.
  bool hdr_reapply_pending = false;
  // The peak mpv was last told to tone-map to, 0 meaning "do not". Compared
  // against the display's current peak so a move between two HDR outputs is not
  // mistaken for no change at all.
  uint32_t applied_target_peak = 0;
  // Set when a transaction ended in kUnknown: mpv stopped answering partway
  // through being put back, so what the plane emits cannot be named and the
  // surface carries no description. Recorded rather than inferred from the
  // surface being hidden, because Dart's own visibility changes move that bit
  // for entirely unrelated reasons and would otherwise lift the quarantine by
  // accident. Cleared by the next transaction that ends in a nameable state.
  bool hdr_output_unnameable = false;
  // What the source snapshot last logged as, so a seek does not repeat it. Its
  // default state means "no stream", which no real source matches, so the first
  // one always logs. Placement-constructed in init - see the note by finalize.
  mpv::HdrMetadata last_logged_source;
};

// g_type_create_instance zeroes the instance and runs no constructor, so the
// member initialisers above never execute: every scalar starts at zero and
// nothing else assigns these. kCompositor has to *be* zero for that to land on
// the intended default.
static_assert(
    static_cast<int>(mpv::HdrToneMapping::kCompositor) == 0,
    "MpvPlugin's zeroed instance memory must decode as kCompositor");

G_DEFINE_TYPE(MpvPlugin, mpv_plugin, G_TYPE_OBJECT)

// Forward declarations
static void mpv_plugin_handle_method_call(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data);
// The texture bootstrap's failure arms call this; it is defined below.
static void release_video_resources(MpvPlugin* self);

static mpv::HdrMetadata read_source_hdr_metadata(MpvPlugin* self);
static void apply_hdr_state(MpvPlugin* self, bool allow, mpv::HdrToneMapping mode, std::function<void(int)> done);
static void request_hdr_reapply(MpvPlugin* self);
static void run_next_hdr_transaction(MpvPlugin* self);
static void submit_hdr_transaction(
    MpvPlugin* self, bool allow, std::optional<mpv::HdrToneMapping> mode, std::function<void(int)> done);

// Events reach Dart unchanged; this only watches them go past. A playback
// restart is the first moment the source's colour space and HDR metadata are
// knowable, and HDR is normally permitted well before that - typically before
// any file is open - so the decision made back then has to be revisited.
//
// It goes through the full apply path rather than only refreshing the
// description, because a new file can change the *curve*: PQ to HLG, or HDR to
// SDR entirely, each of which mpv has to be reconfigured for and not just
// re-described. Self-cancelling when nothing changed, which matters because this
// also fires on every seek.
static void observe_event_for_hdr(MpvPlugin* self, FlValue* event) {
  if (!self->video_surface) return;
  if (event == nullptr || fl_value_get_type(event) != FL_VALUE_TYPE_MAP) return;
  FlValue* name = fl_value_lookup_string(event, "name");
  if (name == nullptr || fl_value_get_type(name) != FL_VALUE_TYPE_STRING) return;
  if (g_strcmp0(fl_value_get_string(name), "playback-restart") != 0) return;
  // A new source is a fresh chance to name the output. The quarantine from a
  // previous source must not outlive it: one file that broke the colour
  // transaction would otherwise keep the plane hidden (or undescribed-and-
  // quarantined) for every later one. Lifted before the re-apply, so the
  // transaction that follows can restore visibility in the same pass.
  if (self->hdr_output_unnameable) {
    self->hdr_output_unnameable = false;
    if (self->visible != FALSE) self->video_surface->SetVisible(true);
  }
  request_hdr_reapply(self);
}

static void send_event(MpvPlugin* self, FlValue* event) {
  observe_event_for_hdr(self, event);
  if (self->event_channel) {
    g_autoptr(GError) error = nullptr;
    if (!fl_event_channel_send(self->event_channel, event, nullptr, &error) && error != nullptr) {
      g_warning("Failed to send event: %s", error->message);
    }
  }
}

// Every event Dart accepts carries type:"event" - its decoder silently drops a
// map without it. Building the envelope in one place means the next caller
// cannot omit it and quietly get nothing.
static void send_named_event(MpvPlugin* self, const char* name) {
  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, "type", fl_value_new_string("event"));
  fl_value_set_string_take(event, "name", fl_value_new_string(name));
  send_event(self, event);
}

static void release_video_resources(MpvPlugin* self) {
  // Anything still in flight is now answering for a plane that is going away.
  ++self->generation;
  // The timeout closure holds a raw `this`; without this it would fire into
  // the torn-down plugin. The destroy-notify frees its context.
  if (self->hdr_mpv_leg_timeout_source_ != 0) {
    g_source_remove(self->hdr_mpv_leg_timeout_source_);
    self->hdr_mpv_leg_timeout_source_ = 0;
  }
  // Queued transactions will never run, and each may be holding a reference to a
  // Dart method call that has to be answered or it is leaked along with its
  // response.
  auto queued = std::move(self->hdr_queue);
  self->hdr_queue.clear();
  self->hdr_transaction_in_flight = false;
  self->hdr_reapply_pending = false;
  for (auto& request : queued) {
    if (request.done) request.done(MPV_ERROR_UNINITIALIZED);
  }
  // Drain the render thread before anything a job touches is torn down:
  // RenderToSurface's lock-free render is safe only because mpv_gl_, the EGL
  // context and the plane's EGL surface outlive every job, and this is where
  // that ordering is enforced. The final job unbinds the EGL context on the
  // worker - the one thread it is current on - so the teardown queue's worker
  // can bind it (an EGLContext can be current on at most one thread).
  bool render_thread_wedged = false;
  if (self->render_executor) {
    const EGLDisplay unbind_display = self->video_surface ? self->video_surface->egl_display() : EGL_NO_DISPLAY;
    self->render_executor->Post(
        [unbind_display]() -> bool {
          if (unbind_display != EGL_NO_DISPLAY) {
            eglMakeCurrent(unbind_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
          }
          return true;
        },
        nullptr);
    render_thread_wedged = !self->render_executor->ShutdownAndJoin(5000);
    self->render_executor.reset();
  }
  self->render_in_flight = FALSE;
  self->rect_apply_deferred = FALSE;
  self->hdr_start_deferred = FALSE;
  if (render_thread_wedged) {
    // A job is stuck inside a driver call. Disposing the player frees the
    // render context under it and destroying the plane frees the EGL surface
    // it is drawing into - either is a guaranteed crash. Leaking one
    // session's core and plane keeps the process alive; stop is best-effort,
    // because the mpv client API is thread-safe and the wedged job holds only
    // the render API.
    g_warning("MPV video plane: render thread did not drain; leaking this session's player and plane");
    if (self->player) {
      self->player->SetRedrawCallback(nullptr);
      self->player->SetSourceMetadataCallback(nullptr);
      self->player->SetEventCallback(nullptr);
      self->player->Command({"stop"});
      self->player.release();
    }
    if (self->video_surface) self->video_surface.release();
  }
  if (self->player) {
    // The plane is a raw callback target. Revoke every callback path before
    // tearing it down; Dispose then drains any callback already holding a
    // native lease.
    self->player->SetRedrawCallback(nullptr);
    self->player->SetSourceMetadataCallback(nullptr);
    self->player->SetEventCallback(nullptr);
    self->player->Dispose();
    self->player.reset();
  }
  // After the player is gone: disposal hands the render context to the
  // process-lifetime teardown queue, which releases it surfacelessly, so the
  // plane's EGL surface does not have to outlive it.
  if (self->video_surface) {
    self->video_surface->Destroy();
    self->video_surface.reset();
  }
  self->initialized = FALSE;
  self->visible = FALSE;
  self->plane_needs_render = FALSE;
  // All of these describe a plane and an mpv instance that no longer exist, and
  // initialize() builds both fresh: a new MpvPlayer whose applied target
  // properties are back to "auto", and a new surface with no description
  // attached. Left standing, the stale record makes a repeated hdr-tone-mapping
  // write match the old accepted mode and answer success without applying
  // anything, and gives handle_preferred_changed a peak to compare against that
  // nothing is actually using.
  self->hdr_tone_mapping = mpv::HdrToneMapping::kCompositor;
  self->hdr_tone_mapping_desired = mpv::HdrToneMapping::kCompositor;
  self->applied_target_peak = 0;
  // The quarantine belongs to the mpv instance that stopped answering, not to
  // the app. A new plane and a new player have said nothing yet, so nothing
  // about them is unnameable, and leaving this set would hide the next session
  // outright: the flag suppresses exactly the setVisible that would show it.
  self->hdr_output_unnameable = false;
  self->last_logged_source = mpv::HdrMetadata();
  // hdr_wanted included, and this is not obvious. It reads like the user's
  // permission, which outlives any one plane - but this plugin is a
  // process-lifetime singleton, so "outlives the plane" means "outlives every
  // later session too". Dart re-pushes the preference on each initialize and
  // reconciles a refusal by persisting what it believes native holds, and that
  // belief is "off, because the plane is new". Carrying a TRUE over from an
  // earlier session makes that belief false exactly when a refusal happens, and
  // the two then disagree with no way back. A fresh plane starts from no
  // permission and waits to be told.
  self->hdr_wanted = FALSE;
}

// Hands the plane the last geometry Dart sent. Called both when a rect arrives
// and when a plane is created after one already had, which is the case that
// would otherwise leave the plane sizeless: render_video_plane bails while
// has_size() is false, and Dart re-sends only when its numbers change.
static void apply_pending_rect(MpvPlugin* self) {
  if (!self->has_pending_rect || self->video_surface == nullptr) return;
  const auto& rect = self->pending_rect;
  self->video_surface->SetRect(rect.x, rect.y, rect.width, rect.height, rect.scale);
}

// Runs |job| on the plane render thread and |completion| back on the main
// thread with the job's result. The inline fallback (PLEZY_PLANE_RENDER_MAIN_THREAD)
// runs both synchronously, preserving the pre-#2057 single-threaded behaviour.
static bool post_render_job(MpvPlugin* self, std::function<bool()> job, std::function<void(bool)> completion) {
  if (self->render_executor) return self->render_executor->Post(std::move(job), std::move(completion));
  completion(job());
  return true;
}

// Renders and presents one frame on the native video plane. Skipped while the
// plane is hidden or has not been given a rect yet; both of those paths render
// explicitly once the condition clears, because mpv's redraw latch stays set
// until a render consumes it and would otherwise suppress every later frame.
//
// |force| is for the callers who need pixels regardless of whether mpv has
// produced a new frame: a resize, or the plane becoming visible again.
//
// The render and the swap themselves run on the plane render thread (issue
// #2057): a frame render that costs a real fraction of the frame budget - a
// 4K HDR tone-map, say - would otherwise starve input dispatch and Flutter's
// raster, which share the GTK main thread. Everything up to PreparePresent()
// and everything from the completion on stays here on the main thread.
static void render_video_plane(MpvPlugin* self, gboolean force) {
  if (force) self->plane_needs_render = TRUE;
  if (!self->player || !self->video_surface || !self->video_surface->valid()) return;
  // One job at a time. The flight owns the plane's EGL surface, and a second
  // prepare would arm a frame callback over a commit that has not happened.
  // Nothing arriving meanwhile is lost: the completion re-runs this function,
  // and plane_needs_render and mpv's redraw latch both hold their edge.
  if (self->render_in_flight) return;
  if (!self->video_surface->visible() || !self->video_surface->has_size()) return;
  // Presents are held while a colour transition is staged, so a render now would
  // be discarded. The forced render after CommitHdrTransition is what resumes;
  // plane_needs_render stays set meanwhile, so nothing is lost.
  if (self->video_surface->hdr_transition_staged()) return;
  // Never present an empty buffer as the very first frame. The first commit is
  // the one a compositor that skips frame callbacks for occluded surfaces is
  // entitled to ignore forever - the plane's frame-pending latch would then
  // stall every later render, exactly the black-screen report - and it would
  // be empty anyway: the first forced render happens at setVideoRect time,
  // before mpv has decoded anything. Refuse it until mpv actually has a frame
  // (its redraw latch, which is set when a frame is ready and cleared only by
  // a render). The sticky plane_needs_render flag keeps the resize/visibility
  // refresh owed by this call pending, so the first present still happens at
  // the right size the moment content exists.
  if (!self->video_surface->first_frame_presented() && !self->player->NeedsRedraw()) return;
  // Skip entirely while the compositor has not acknowledged the last frame:
  // an occluded plane is never acknowledged, and rendering into it anyway
  // would burn GPU work on frames that can never be shown.
  if (self->video_surface->frame_pending()) return;
  // The frame callback fires once per *display* refresh, so rendering from it
  // unconditionally pins the plane to the monitor's rate - 120 swaps/s for
  // 60fps content on a 120Hz output, half of them redrawing the same picture.
  // mpv's redraw latch is what says a new frame actually exists.
  if (!self->plane_needs_render && !self->player->NeedsRedraw()) return;
  if (!self->video_surface->PreparePresent()) return;

  // Everything the job touches is snapshotted now and stays alive for the
  // flight's duration: release_video_resources drains the render thread
  // before the player or the plane is torn down.
  mpv::MpvPlayer* player = self->player.get();
  EGLDisplay display = self->video_surface->egl_display();
  EGLSurface egl_surface = self->video_surface->egl_surface();
  const int width = self->video_surface->width();
  const int height = self->video_surface->height();
  const guint64 generation = self->generation;
  self->render_in_flight = TRUE;
  const bool posted = post_render_job(
      self,
      [player, display, egl_surface, width, height]() -> bool {
        if (!player->RenderToSurface(egl_surface, width, height)) return false;
        // The swap is the child surface's commit. Non-throttled
        // (eglSwapInterval 0), so it never blocks on the compositor; its cost
        // is the render's, which is exactly what this thread is for.
        if (eglSwapBuffers(display, egl_surface) != EGL_TRUE) {
          g_warning("MPV video plane: eglSwapBuffers failed: 0x%x", eglGetError());
          return false;
        }
        return true;
      },
      [self, generation](bool swapped) {
        // The plane this job rendered for may be gone: release_video_resources
        // bumps the generation, and completions outlive the executor.
        if (self->generation != generation) return;
        self->render_in_flight = FALSE;
        if (self->video_surface == nullptr) return;
        // A swap failure leaves plane_needs_render set, so the retry - and the
        // frame callback CompletePresent just cleared - are both owed to the
        // next event that moves the plane, exactly as before the split.
        if (self->video_surface->CompletePresent(swapped)) self->plane_needs_render = FALSE;
        // Work that had to wait out the flight, in dependency order: geometry
        // first (wl_egl_window_resize must not race a swap), then the HDR
        // transaction pump (a transition staged mid-flight would pair an
        // old-colour buffer with a new description), then the render either
        // may have asked for.
        if (self->rect_apply_deferred) {
          self->rect_apply_deferred = FALSE;
          apply_pending_rect(self);
        }
        if (self->hdr_start_deferred) {
          self->hdr_start_deferred = FALSE;
          run_next_hdr_transaction(self);
        }
        render_video_plane(self, FALSE);
      });
  if (!posted) {
    // Shutdown has begun; the job will never run. Undo the prepare so the
    // frame callback does not wait forever on a commit that is not coming.
    self->render_in_flight = FALSE;
    self->video_surface->CompletePresent(false);
  }
}

// Collects what the source actually is, plus its HDR10 static metadata.
//
// Both halves matter. The colour space decides whether the plane may be
// described as HDR at all — describing it because a setting is on, rather than
// because the stream carries an HDR curve, asks the compositor to undo a
// transform nobody applied. The luminances then decide how hard the compositor
// tone-maps: without them it must assume the worst case PQ permits, 10000 nits,
// and rolls highlights off far harder than the content needs.
//
// The protocol carries luminances as whole nits, and a value that rounds to zero
// would read as "not stated", so anything positive is kept at a minimum of 1.
static mpv::HdrMetadata read_source_hdr_metadata(MpvPlugin* self) {
  mpv::HdrMetadata metadata;
  if (!self->player) return metadata;
  mpv::SourceHdrMetadata source;
  if (!self->player->ReadSourceHdrMetadata(&source)) return metadata;

  // mpv's own trc / primaries names, from video/csputils.c's tables.
  if (source.transfer == "pq") {
    metadata.transfer = mpv::SourceTransfer::kPq;
  } else if (source.transfer == "hlg") {
    metadata.transfer = mpv::SourceTransfer::kHlg;
  }
  if (source.primaries == "bt.2020") {
    metadata.primaries = mpv::SourcePrimaries::kBt2020;
  }

  auto nits = [](double value) -> uint32_t {
    if (!(value > 0.0)) return 0;
    const double rounded = value + 0.5;
    if (rounded >= 4294967295.0) return 4294967295u;
    const uint32_t whole = static_cast<uint32_t>(rounded);
    return whole > 0 ? whole : 1;
  };
  metadata.max_cll = nits(source.max_cll);
  metadata.max_fall = nits(source.max_fall);
  metadata.max_luminance = nits(source.max_luminance);
  metadata.min_luminance = source.min_luminance;
  // Only when it moves. This is the input to the whole HDR decision, so it
  // belongs in an ordinary log - but playback-restart fires on every seek, and
  // an unconditional line would bury the output state it should sit next to.
  if (metadata != self->last_logged_source) {
    self->last_logged_source = metadata;
    g_message(
        "MPV video plane: source is %s / %s, MaxCLL=%u MaxFALL=%u mastering=%.4f-%u nits",
        source.transfer.empty() ? "(no stream)" : source.transfer.c_str(),
        source.primaries.empty() ? "(no stream)" : source.primaries.c_str(), metadata.max_cll, metadata.max_fall,
        metadata.min_luminance, metadata.max_luminance);
  }
  return metadata;
}

// Whether the client and the display could carry HDR at all, before the source
// is considered. Both halves must agree: this client has to be able to describe
// an HDR plane, and the output the surface sits on has to actually be in HDR.
// The second can change under us when the window moves between monitors, which
// is why nothing caches it.
static bool hdr_available(MpvPlugin* self) {
  return self->video_surface != nullptr && self->video_surface->supports_hdr() && self->video_surface->output_is_hdr();
}

// One gate, in hdr_metadata.h, so the four conditions and the peak clamp are
// testable without a compositor. Both the apply path and the preferred-changed
// check go through here, so an eighth HdrInputs field cannot be filled in one
// and forgotten in the other - they would then disagree about what is on screen.
//
// The caller must have established that the surface exists.
static mpv::HdrDecision decide_hdr(
    MpvPlugin* self, bool allow, mpv::HdrToneMapping mode, const mpv::HdrMetadata& source) {
  mpv::HdrInputs inputs;
  inputs.allowed = allow;
  inputs.client_can_describe = self->video_surface->supports_hdr();
  inputs.output_is_hdr = self->video_surface->output_is_hdr();
  inputs.source_describable = self->video_surface->CanDescribeSource(source);
  inputs.requested = mode;
  inputs.display_peak_nits = self->video_surface->preferred().max_luminance;
  inputs.sdr_reference_nits = self->video_surface->preferred().reference_luminance;
  return mpv::DecideHdr(inputs, source);
}

// Applies an HDR state to both halves of the plane, atomically on screen.
//
// The surface's colour state and the buffer it describes land on the *same*
// child-surface commit, and that commit is performed by eglSwapBuffers inside
// Present(). So neither "pixels first" nor "description first" is atomic on its
// own: whichever goes second leaves a window in which presented frames carry one
// colour space while labelled with the other. On enable that window is the
// compositor's validation round-trip, and PQ frames read as sRGB are a visible
// flash.
//
// The three-step transition closes it:
//
//   1. BeginHdrTransition stages and validates the description, holding Present()
//      so nothing can commit mid-change.
//   2. Once it settles, mpv's output colour space is switched.
//   3. CommitHdrTransition attaches the state and releases the hold, and the
//      plane is rendered and presented immediately - so the first buffer in the
//      new colour space is the one that carries it.
//
// Any failure aborts, leaving both halves exactly as they were.
//
// `mode` is the *desired* tone-map owner, passed in rather than read from the
// plugin, so the committed field is updated only when the request carrying that
// mode is the one mpv accepted. Requests are applied in order, so the last
// success is what mpv holds and what gets committed last.
//
// The source is read once and the same snapshot drives every step.
static void apply_hdr_state(MpvPlugin* self, bool allow, mpv::HdrToneMapping mode, std::function<void(int)> done) {
  if (self->video_surface == nullptr || self->player == nullptr) {
    if (done) done(MPV_ERROR_UNINITIALIZED);
    return;
  }
  const mpv::HdrMetadata source = read_source_hdr_metadata(self);

  const mpv::HdrDecision decision = decide_hdr(self, allow, mode, source);

  // What the buffer will actually contain: the source untouched, or the same
  // curve and gamut reduced to the peak we are about to declare. DecideHdr
  // already clamped that peak to the curve's primary colour volume, so mpv aims
  // at exactly what the compositor is told.
  const mpv::HdrMetadata described =
      decision.tone_map_in_player ? mpv::DescribeTonemappedTo(source, decision.target_peak_nits) : source;
  const mpv::SourceTransfer transfer = decision.describe ? described.transfer : mpv::SourceTransfer::kSdr;
  const guint64 generation = self->generation;

  self->video_surface->BeginHdrTransition(
      decision.describe, described, [self, decision, transfer, mode, generation, done](uint64_t token, bool staged) {
        if (self->generation != generation || self->video_surface == nullptr || self->player == nullptr) {
          if (done) done(MPV_ERROR_UNINITIALIZED);
          return;
        }
        if (!staged) {
          self->video_surface->AbortHdrTransition(token);
          // Releasing the hold is not enough to restart the plane. mpv's redraw
          // latch saturated while Present() was held - OnMpvRenderUpdate only
          // schedules on the false->true edge - and no frame callback is
          // outstanding to poke it either, so without a forced render here the
          // plane sits on its last buffer until something unrelated moves.
          render_video_plane(self, TRUE);
          g_warning("MPV video plane: colour transition abandoned; leaving HDR as it was");
          if (done) done(MPV_ERROR_UNSUPPORTED);
          return;
        }
        // The mpv leg is the one wait this file does not bound: the surface
        // watchdog re-arms while it runs, but nothing answers the HDR method
        // call when mpv never replies, so the transaction queue stays in
        // flight behind a ghost forever - every later hdr-enabled or
        // hdr-tone-mapping request queues behind it. A wedged core must cost
        // one transaction, not the session. The shared latch makes whichever
        // of the timeout or the late reply fires first the single caller of
        // `done`; the loser sees a stale token and self-heals through
        // request_hdr_reapply.
        auto leg_finished = std::make_shared<bool>(false);
        auto finish_leg = [done, leg_finished](int error) {
          if (*leg_finished) return;
          *leg_finished = true;
          if (done) done(error);
        };
        self->player->SetHdrOutput(
            transfer, decision.target_peak_nits,
            [self, decision, mode, generation, token, leg_finished, finish_leg](
                mpv::MpvPlayer::HdrOutputResult result, int error) {
              using Result = mpv::MpvPlayer::HdrOutputResult;
              // Whatever this reply says, the timeout (if any) has no more
              // work to do. Both run on the GTK main context, so touching the
              // source id here is single-threaded.
              if (self->hdr_mpv_leg_timeout_source_ != 0) {
                g_source_remove(self->hdr_mpv_leg_timeout_source_);
                self->hdr_mpv_leg_timeout_source_ = 0;
              }
              // The plane may have been torn down while the property was in flight.
              if (self->generation != generation || self->video_surface == nullptr || self->player == nullptr) {
                finish_leg(error);
                return;
              }
              // The timeout already abandoned this transaction. mpv's colour
              // state is unknowable; the timeout withdrew the description and
              // resumed presentation, so the plane shows SDR-claimed pixels
              // and nothing further may be committed against this token.
              if (*leg_finished) {
                self->video_surface->ForceUndescribed();
                self->applied_target_peak = 0;
                return;
              }
              // An earlier kUnknown hid the plane rather than show pixels it could
              // not label. Every outcome below except another kUnknown leaves mpv
              // in a state that *can* be named, so the visibility Dart actually
              // asked for is restored for all of them - restoring it only on
              // kApplied left a clean unwind showing black until some unrelated
              // visibility change arrived. Done before the switch so each arm's
              // own render publishes it.
              //
              // Driven off the recorded quarantine rather than off the surface
              // being hidden: those are different facts. Dart hides the plane
              // whenever the player is off screen, and reading that as "quarantined"
              // would restore visibility the user did not ask for.
              //
              // The commit is resolved first, because "mpv applied it" and "the
              // surface is describing it" are two facts and the quarantine cares
              // about the second. A kApplied whose non-zero token was refused is
              // the case they part company: the watchdog withdrew the description
              // while mpv was still answering, so mpv has moved to PQ and the
              // surface has nothing attached. Lifting on that would publish the
              // mislabelled frame the kUnknown arm below refuses to publish - and
              // the same slow mpv causes both halves, so they arrive together.
              // Short-circuit: only kApplied may commit; the other arms abort or
              // withdraw instead.
              const bool committed = result == Result::kApplied && self->video_surface->CommitHdrTransition(token);
              const bool nameable =
                  result != Result::kUnknown && (result != Result::kApplied || committed || token == 0);
              const bool unquarantined = nameable && self->hdr_output_unnameable;
              if (unquarantined) {
                self->hdr_output_unnameable = false;
                if (self->visible != FALSE) self->video_surface->SetVisible(true);
              }
              switch (result) {
                case Result::kApplied: {
                  // Pixels and state now agree; publish them together.
                  if (committed || unquarantined) render_video_plane(self, TRUE);
                  if (committed && decision.describe) {
                    g_message(
                        "MPV video plane: HDR on, tone mapping by %s",
                        decision.tone_map_in_player ? "the player" : "the compositor");
                  }
                  // A refusal has two very different meanings. Token zero is the
                  // benign one: nothing needed staging because nothing changed, so
                  // the record below is already true. A non-zero token that was
                  // refused means the transition was torn down while this mpv leg
                  // was in flight - the watchdog withdrew the description - and
                  // mpv has now moved to a colour space the surface no longer
                  // claims. Recording that as applied would make it the truth as
                  // far as every later no-change test is concerned, including the
                  // one in handle_preferred_changed that would otherwise repair
                  // it. Leave the record alone and ask for a fresh apply instead.
                  if (!committed && token != 0) {
                    g_warning("MPV video plane: the colour transition was withdrawn mid-flight; re-applying");
                    request_hdr_reapply(self);
                    break;
                  }
                  self->hdr_tone_mapping = mode;
                  self->applied_target_peak = decision.target_peak_nits;
                  break;
                }
                case Result::kRestored:
                  // mpv is back where it was, so the description already committed
                  // is still true of the pixels and must be left exactly alone.
                  // The plane still has to be restarted - see the !staged arm.
                  self->video_surface->AbortHdrTransition(token);
                  render_video_plane(self, TRUE);
                  g_warning(
                      "MPV video plane: mpv refused the %s output colour space and was put back, "
                      "so the surface description is unchanged: %s",
                      decision.describe ? "HDR" : "SDR", mpv_error_string(error));
                  break;
                case Result::kForcedSdr:
                  // mpv could not be put back and is now SDR. Any committed HDR
                  // description describes pixels that no longer exist, so it goes
                  // too - and immediately, paired with a fresh frame. The render is
                  // unconditional because the hold is released either way.
                  self->video_surface->ForceUndescribed();
                  render_video_plane(self, TRUE);
                  self->applied_target_peak = 0;
                  g_warning(
                      "MPV video plane: mpv's colour space could not be restored and was forced to "
                      "SDR; HDR withdrawn: %s",
                      mpv_error_string(error));
                  break;
                case Result::kUnknown:
                  // Nothing can be said truthfully about these pixels, so no
                  // description is attached. Whether anything is shown is a
                  // product decision with two sides: hiding is honest (an
                  // undescribed plane is sRGB by protocol, so PQ pixels read
                  // as sRGB are washed out), showing is useful (visible-wrong
                  // beats invisible — the AV1-transparent report was a plane
                  // hidden this way while sound kept playing). Hiding is now
                  // reserved for a core that is genuinely going away; a live
                  // one presents undescribed instead.
                  //
                  // Recorded either way, so that a setVisible arriving in
                  // between - the app going off screen and back, which has
                  // nothing to do with colour - cannot quietly put the
                  // mislabelled plane back on screen without asking mpv
                  // again; observe_event_for_hdr clears it on the next
                  // playback-restart so one poisoned source cannot hide
                  // every later one.
                  self->hdr_output_unnameable = true;
                  self->video_surface->ForceUndescribed();
                  if (self->player->IsDisposed() || !self->player->CanCommandOutputProperties()) {
                    self->video_surface->SetVisible(false);
                  } else {
                    render_video_plane(self, TRUE);
                  }
                  self->applied_target_peak = 0;
                  g_warning(
                      "MPV video plane: mpv's output colour space is no longer commandable; the "
                      "plane is shown undescribed rather than hidden: %s",
                      mpv_error_string(error));
                  break;
              }
              finish_leg(error);
            });
        // The surface's own watchdog bounds this leg too, but it only unstages
        // the plane - the plugin's transaction state and the queued HDR
        // method calls stay stuck behind the unanswered reply. This timeout
        // answers them, and is armed only while the reply is genuinely
        // outstanding. A synchronous reply - the no-op short-circuit, or a
        // player that cannot command output properties - has already finished
        // the leg by this line, and a timer armed for it would be an orphan
        // nothing removes: the reply callback above ran before the source id
        // existed. That orphan fired five seconds after every no-op re-apply
        // (one per playback restart) and withdrew the plane's live HDR
        // description each time - the HDR/SDR flicker of issue #2016. An
        // asynchronous reply removes the timer in the reply callback.
        if (*leg_finished) return;
        struct MpvLegTimeout {
          MpvPlugin* self;
          guint64 generation;
          uint64_t token;
          std::function<void(int)> finish_leg;
        };
        auto* timeout_ctx = new MpvLegTimeout{self, generation, token, finish_leg};
        self->hdr_mpv_leg_timeout_source_ = g_timeout_add_seconds_full(
            G_PRIORITY_DEFAULT, mpv::WaylandVideoSurface::kTransitionTimeoutSeconds,
            +[](gpointer data) -> gboolean {
              auto* ctx = static_cast<MpvLegTimeout*>(data);
              MpvPlugin* self = ctx->self;
              self->hdr_mpv_leg_timeout_source_ = 0;
              if (self->generation == ctx->generation && self->video_surface != nullptr) {
                g_warning(
                    "MPV video plane: mpv never answered the output colour-space switch within %d "
                    "seconds; abandoning the transaction and resuming presentation",
                    mpv::WaylandVideoSurface::kTransitionTimeoutSeconds);
                // Unstage and drop any description: mpv's state is unknown, so
                // no claim may stand. The plane resumes presenting
                // undescribed (sRGB by protocol) rather than staying held.
                self->video_surface->AbortHdrTransition(ctx->token);
                self->video_surface->ForceUndescribed();
                render_video_plane(self, TRUE);
              }
              // Answers the transaction (and with it the queued HDR method
              // calls) exactly once; a late reply from mpv is swallowed by the
              // shared latch in the callback above. The error code is any
              // non-success - the timeout's log line is what names the reason.
              ctx->finish_leg(MPV_ERROR_UNSUPPORTED);
              return G_SOURCE_REMOVE;
            },
            timeout_ctx, +[](gpointer data) { delete static_cast<MpvLegTimeout*>(data); });
      });
}

// Runs the next queued HDR transaction, or drains the coalesced internal
// re-apply once the queue empties.
static void run_next_hdr_transaction(MpvPlugin* self) {
  if (self->hdr_queue.empty()) {
    self->hdr_transaction_in_flight = false;
    if (self->hdr_reapply_pending) {
      self->hdr_reapply_pending = false;
      request_hdr_reapply(self);
    }
    return;
  }
  // A render job in flight was prepared before this transaction's turn came;
  // let it land first. Staging now would raise the present hold *after* that
  // job's prepare, so the commit its swap performs would pair an old-colour
  // buffer with whatever the transaction stages - the exact mismatch the
  // two-phase dance exists to avoid - and the mpv leg would move the output
  // properties under a frame mid-render. Setting the in-flight flag keeps the
  // pump's invariant (a non-empty queue implies a transaction in flight); the
  // render completion re-enters here.
  if (self->render_in_flight) {
    self->hdr_transaction_in_flight = true;
    self->hdr_start_deferred = TRUE;
    return;
  }
  PendingHdrRequest request = std::move(self->hdr_queue.front());
  self->hdr_queue.pop_front();
  self->hdr_transaction_in_flight = true;
  // Resolved here rather than at enqueue, so a mode that has since been refused
  // is not applied on this request's back.
  const mpv::HdrToneMapping mode = request.mode.value_or(self->hdr_tone_mapping_desired);
  apply_hdr_state(self, request.allow, mode, [self, done = std::move(request.done)](int error) {
    if (done) done(error);
    // Only now, with the surface unstaged and mpv settled, may the next one start.
    run_next_hdr_transaction(self);
  });
}

// Queues an HDR transaction. `mode` is engaged only for the mode change itself;
// everything else passes nullopt and carries whatever mode is in force when its
// turn comes.
static void submit_hdr_transaction(
    MpvPlugin* self, bool allow, std::optional<mpv::HdrToneMapping> mode, std::function<void(int)> done) {
  if (self->video_surface == nullptr || self->player == nullptr) {
    if (done) done(MPV_ERROR_UNINITIALIZED);
    return;
  }
  PendingHdrRequest request;
  request.allow = allow;
  request.mode = mode;
  request.done = std::move(done);
  self->hdr_queue.push_back(std::move(request));
  if (!self->hdr_transaction_in_flight) run_next_hdr_transaction(self);
}

// Whether an HDR transaction is under way. A merely queued request counts as
// under way and needs no separate test: submit_hdr_transaction starts one the
// moment nothing is running, and run_next_hdr_transaction clears the flag only
// on the branch where the queue is already empty - so a non-empty queue always
// implies the flag is set.
static bool hdr_busy(MpvPlugin* self) { return self->hdr_transaction_in_flight; }

// The only entry point for internal re-applies: playback restarts and
// preferred-description changes. Nobody is waiting on these, so instead of
// queueing they collapse into a single pending flag and re-read the mode and the
// source when their turn comes.
static void request_hdr_reapply(MpvPlugin* self) {
  if (self->video_surface == nullptr) return;
  // Folded into the flag rather than queued behind what is already running:
  // starting a re-apply beside waiting user requests would put it ahead of them
  // in effect, and each transaction re-reads the source and the preferred
  // description when its turn comes, so coalescing loses nothing.
  if (hdr_busy(self)) {
    self->hdr_reapply_pending = true;
    return;
  }
  submit_hdr_transaction(self, self->hdr_wanted != FALSE, std::nullopt, nullptr);
}

// Re-applies the current request when the compositor's preferred description
// moves - a monitor change, HDR switched on or off under the app, or the output
// going away entirely.
static void handle_preferred_changed(MpvPlugin* self) {
  if (self->video_surface == nullptr) return;

  // Dart mirrors the HDR controls off isHDRSupported, and that answer depends on
  // which output the surface sits on. This is the only place that learns it
  // moved: dragging a window between monitors raises no Flutter lifecycle event
  // on Wayland, so without this the settings sheet goes on offering a toggle the
  // output can no longer honour, or hiding one it now could. Sent before the
  // busy check below, because a deferred re-apply is still a change Dart needs
  // to hear about.
  send_named_event(self, "hdr-output-changed");

  // A transaction that has not committed yet has not moved hdr_active() or
  // applied_target_peak, so comparing against them here would judge the new
  // preference against the state the in-flight transaction is about to
  // replace. When the two happen to match, the newest word from the compositor
  // would be dropped rather than coalesced - which is reachable just by
  // dragging the window across two monitors, where KWin emits several
  // preferred_changed events and the intermediate one can carry no_output.
  // Defer instead; request_hdr_reapply already coalesces, and apply_hdr_state
  // re-reads the preferred description when its turn comes.
  if (hdr_busy(self)) {
    request_hdr_reapply(self);
    return;
  }

  // Ask the same gate that would run anyway what the answer is now, and only
  // re-apply when it differs from what is in force. The on/off state alone is not
  // enough: in player mode the peak we tone-map to *is* the display's peak, so
  // moving between two HDR outputs of different brightness changes what must be
  // sent while the boolean stays put.
  const mpv::HdrMetadata source = read_source_hdr_metadata(self);
  const mpv::HdrDecision decision = decide_hdr(self, self->hdr_wanted != FALSE, self->hdr_tone_mapping_desired, source);

  if (decision.describe == self->video_surface->hdr_active() &&
      decision.target_peak_nits == self->applied_target_peak) {
    return;
  }
  g_message("MPV video plane: preferred description changed; re-evaluating HDR");
  request_hdr_reapply(self);
}

// Brings up the native Wayland video plane, the only way this runner renders
// video. Returns false with |error| set to the specific reason: there is no
// second path to fall through to, so the reason is what the user is told.
static gboolean start_video_plane(MpvPlugin* self, FlView* view, std::string* error) {
  if (view == nullptr) {
    *error = "The window has no Flutter view to place a video plane under";
    return FALSE;
  }
  GtkWidget* widget = GTK_WIDGET(view);
  if (!mpv::WaylandVideoSurface::IsSupported(gtk_widget_get_display(widget))) {
    *error =
        "Video needs a Wayland session. This looks like an X11 session; log in "
        "under Wayland, or run X11 applications through XWayland instead.";
    return FALSE;
  }

  // my_application.cc gives the toplevel an RGBA visual because the plane is
  // stacked *below* it and only shows through an alpha channel. If that did
  // not take, presenting here would put video behind an opaque surface: the
  // video area would go blank while every other symptom looked healthy. Say so
  // instead, because the symptom on its own points nowhere near here.
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  if (toplevel != nullptr && gtk_widget_is_toplevel(toplevel)) {
    GdkScreen* screen = gtk_widget_get_screen(toplevel);
    GdkVisual* rgba = screen != nullptr ? gdk_screen_get_rgba_visual(screen) : nullptr;
    if (rgba == nullptr || gtk_widget_get_visual(toplevel) != rgba) {
      *error = "The compositor gave the window no alpha channel, so a video plane below it could never be seen";
      return FALSE;
    }
  }

  auto surface = std::make_unique<mpv::WaylandVideoSurface>();
  if (!surface->Create(widget, error)) return FALSE;
  if (!self->player->InitRenderContextForSurface(
          surface->egl_display(), surface->egl_config(), surface->egl_surface(), surface->depth_bits())) {
    surface->Destroy();
    *error = "The GPU driver would not create a render context for the video plane";
    return FALSE;
  }

  self->video_surface = std::move(surface);
  self->video_surface->SetFrameCallback([self]() { render_video_plane(self, FALSE); });
  self->video_surface->SetForcedRenderCallback([self]() { render_video_plane(self, TRUE); });
  self->video_surface->SetPreferredChangedCallback([self]() { handle_preferred_changed(self); });
  self->player->SetRedrawCallback([self]() { render_video_plane(self, FALSE); });
  // playback-restart is not ordered against the video reconfigure that gives the
  // source its colour space, so the re-apply observe_event_for_hdr asks for can
  // land on the previous file's metadata - or on none at all for the first file.
  // The parse's own event therefore re-applies as well; request_hdr_reapply
  // coalesces the two into one transaction when they arrive together, and a late
  // parse converges rather than leaving a wrong description standing.
  self->player->SetSourceMetadataCallback([self]() { request_hdr_reapply(self); });
  // The worker that runs mpv's render + the plane's eglSwapBuffers off the
  // GTK main thread (issue #2057). The env var is a temporary escape hatch
  // for driver surprises: the inline fallback preserves the old
  // single-threaded behaviour through the same code path.
  if (g_getenv("PLEZY_PLANE_RENDER_MAIN_THREAD") != nullptr) {
    g_message("MPV video plane: rendering on the GTK main thread (PLEZY_PLANE_RENDER_MAIN_THREAD)");
  } else {
    self->render_executor = std::make_unique<mpv::PlaneRenderExecutor>();
  }
  // A rect that arrived before this plane existed is the only one Dart may ever
  // offer, since it re-sends solely on change. Hand it over now, before the
  // first frame, so the plane is never left sizeless and blank.
  apply_pending_rect(self);
  return TRUE;
}

static void mpv_plugin_dispose(GObject* object) {
  MpvPlugin* self = MPV_PLUGIN(object);
  release_video_resources(self);
  g_clear_object(&self->method_channel);
  g_clear_object(&self->event_channel);
  g_clear_object(&self->registrar);
  G_OBJECT_CLASS(mpv_plugin_parent_class)->dispose(object);
}

// GObject instances come from g_type_create_instance, which zeroes the memory and
// runs no C++ constructors, and are released without running destructors. Every
// non-trivial member therefore has to be placement-constructed here and destroyed
// in finalize, in reverse.
//
// A zeroed std::unique_ptr happens to behave like an empty one, which is why the
// two smart pointers survived without this; a zeroed std::deque does not - its
// internal map pointers must be initialised before the first push_back, or it
// dereferences null.
static void mpv_plugin_finalize(GObject* object) {
  MpvPlugin* self = MPV_PLUGIN(object);
  self->hdr_queue.~HdrQueue();
  self->render_executor.~ExecutorPtr();
  self->video_surface.~VideoSurfacePtr();
  self->player.~PlayerPtr();
  G_OBJECT_CLASS(mpv_plugin_parent_class)->finalize(object);
}

static void mpv_plugin_class_init(MpvPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = mpv_plugin_dispose;
  G_OBJECT_CLASS(klass)->finalize = mpv_plugin_finalize;
}

static void mpv_plugin_init(MpvPlugin* self) {
  new (&self->player) PlayerPtr();
  new (&self->video_surface) VideoSurfacePtr();
  new (&self->hdr_queue) HdrQueue();
  // Its default member initialisers make it non-trivially-default-constructible,
  // so the zeroed storage is not yet an object even though every field is scalar.
  // Trivially destructible, so finalize has nothing to undo.
  new (&self->last_logged_source) mpv::HdrMetadata();
  self->visible = FALSE;
  self->initialized = FALSE;
  self->audio_only = FALSE;
  self->generation = 0;
}

MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar, const gchar* channel_name, gboolean audio_only) {
  MpvPlugin* self = MPV_PLUGIN(g_object_new(MPV_PLUGIN_TYPE, nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  self->audio_only = audio_only;

  self->player = std::make_unique<mpv::MpvPlayer>(audio_only);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->method_channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), channel_name, FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(self->method_channel, mpv_plugin_handle_method_call, self, nullptr);

  g_autofree gchar* event_channel_name = g_strconcat(channel_name, "/events", nullptr);
  self->event_channel =
      fl_event_channel_new(fl_plugin_registrar_get_messenger(registrar), event_channel_name, FL_METHOD_CODEC(codec));

  return self;
}

// Static references to keep the plugin instances alive.
[[maybe unused]] static MpvPlugin* g_mpv_plugin = nullptr;
[[maybe unused]] static MpvPlugin* g_mpv_audio_plugin = nullptr;

void mpv_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_mpv_plugin = mpv_plugin_new(registrar, "com.plezy/mpv_player", FALSE);
}

void mpv_audio_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_mpv_audio_plugin = mpv_plugin_new(registrar, "com.plezy/mpv_audio_player", TRUE);
}

/// Method call handler.
static void mpv_plugin_handle_method_call(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  (void)channel;
  MpvPlugin* self = MPV_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "initialize") == 0) {
    if (self->audio_only) {
      // Audio-only music core: no plane, no render context - mpv runs with
      // video disabled entirely (see MpvPlayer).
      if (!self->initialized) {
        if (!self->player || self->player->IsDisposed()) {
          self->player = std::make_unique<mpv::MpvPlayer>(/*audio_only=*/true);
        }
        if (self->player->Initialize()) {
          self->player->SetEventCallback([self](FlValue* event) { send_event(self, event); });
          self->initialized = TRUE;
        }
      }
      if (self->initialized) {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
      } else {
        response =
            FL_METHOD_RESPONSE(fl_method_error_response_new("INIT_FAILED", "Failed to initialize MPV player", nullptr));
      }
    } else if (self->video_surface && self->video_surface->valid()) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
    } else {
      if (!self->player || self->player->IsDisposed()) {
        self->player = std::make_unique<mpv::MpvPlayer>();
      }

      std::string error;
      if (!self->player->Initialize()) {
        release_video_resources(self);
        response =
            FL_METHOD_RESPONSE(fl_method_error_response_new("INIT_FAILED", "Failed to initialize MPV player", nullptr));
      } else if (start_video_plane(self, fl_plugin_registrar_get_view(self->registrar), &error)) {
        ++self->generation;
        self->player->SetEventCallback([self](FlValue* event) { send_event(self, event); });
        self->initialized = TRUE;
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
      } else {
        // There is no second render path. Refuse with the reason rather than
        // presenting into something the user cannot see.
        g_warning("MPV: no video plane: %s", error.c_str());
        release_video_resources(self);
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("VIDEO_PLANE_UNSUPPORTED", error.c_str(), nullptr));
      }
    }
  } else if (strcmp(method, "dispose") == 0) {
    release_video_resources(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "command") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* args_value = fl_value_lookup_string(args, "args");
      if (args_value == nullptr || fl_value_get_type(args_value) != FL_VALUE_TYPE_LIST) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'args' list", nullptr));
      } else {
        std::vector<std::string> command_args;
        size_t len = fl_value_get_length(args_value);
        for (size_t i = 0; i < len; i++) {
          FlValue* item = fl_value_get_list_value(args_value, i);
          if (fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
            command_args.push_back(fl_value_get_string(item));
          }
        }
        g_object_ref(method_call);
        self->player->CommandAsync(command_args, [method_call](int error) {
          g_autoptr(FlMethodResponse) async_response = nullptr;
          if (error < 0) {
            async_response =
                FL_METHOD_RESPONSE(fl_method_error_response_new("COMMAND_FAILED", "MPV command failed", nullptr));
          } else {
            async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
          }
          fl_method_call_respond(method_call, async_response, nullptr);
          g_object_unref(method_call);
        });
        return;  // Response sent asynchronously
      }
    }
  } else if (strcmp(method, "setProperty") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          plezy::mpv_common::kSetPropertyNotInitializedCode, "Player not initialized", nullptr));
    } else {
      FlValue* name_value = fl_value_lookup_string(args, "name");
      FlValue* value_value = fl_value_lookup_string(args, "value");

      if (name_value == nullptr || fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'name'", nullptr));
      } else if (value_value == nullptr || fl_value_get_type(value_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'value'", nullptr));
      } else if (self->video_surface && g_strcmp0(fl_value_get_string(name_value), "hdr-tone-mapping") == 0) {
        // Not an mpv property: it selects which side reduces the source's range,
        // which changes both mpv's target-peak and the luminances the compositor
        // is told. Re-applied immediately so the switch is visible without a
        // seek.
        //
        // Unknown values are rejected rather than folded into the default. This
        // knob's whole purpose is A/B comparison, and silently answering a typo
        // with "compositor, success" would mislabel the very measurement it
        // exists to produce.
        const char* mode = fl_value_get_string(value_value);
        const bool is_player = g_strcmp0(mode, "player") == 0;
        const bool is_compositor = g_strcmp0(mode, "compositor") == 0;
        if (!is_player && !is_compositor) {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "INVALID_ARGS", "hdr-tone-mapping must be 'compositor' or 'player'", nullptr));
        } else {
          const mpv::HdrToneMapping requested =
              is_player ? mpv::HdrToneMapping::kPlayer : mpv::HdrToneMapping::kCompositor;
          // A no-op answer is only honest once the mode has actually settled. If a
          // change is queued or running, `desired` holds a value mpv has not yet
          // accepted, and answering a duplicate with immediate success would have
          // Dart persist a mode the original request may still revert. Such a
          // duplicate is queued instead and gets a real outcome; the extra
          // property writes are idempotent.
          if (requested != self->hdr_tone_mapping || hdr_busy(self)) {
            // `desired` moves now, so an internal re-apply that runs later carries
            // the new mode. `hdr_tone_mapping` itself is committed by the
            // transaction only if mpv accepts the change, which is what keeps
            // native and Dart - which does not persist on failure - in agreement.
            self->hdr_tone_mapping_desired = requested;
            const uint64_t serial = ++self->hdr_mode_request_serial;
            // Owned copy: the transaction completes asynchronously, after the
            // handler's FlValue args are gone.
            const std::string mode_string = mode;
            g_object_ref(method_call);
            submit_hdr_transaction(
                self, self->hdr_wanted != FALSE, requested, [self, method_call, serial, mode_string](int error) {
                  g_autoptr(FlMethodResponse) async_response = nullptr;
                  if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
                    async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
                  } else {
                    // Hand the desire back to whatever is actually in force, read
                    // live rather than captured: an intervening request may have
                    // committed since. Skipped if a newer request already claimed
                    // the desire.
                    if (self->hdr_mode_request_serial == serial) {
                      self->hdr_tone_mapping_desired = self->hdr_tone_mapping;
                    }
                    // The refused write is named so a failure lands in the log as
                    // "hdr-tone-mapping=<mode> failed", not as an unattributable
                    // error string. This transaction has no single property: it
                    // moves mpv's whole output colour space. The name is still
                    // worth having - it says which side of the plane refused.
                    async_response = FL_METHOD_RESPONSE(fl_method_error_response_new(
                        plezy::mpv_common::kSetPropertyFailedCode,
                        (std::string("hdr-tone-mapping='") + mode_string + "' failed: " + mpv_error_string(error))
                            .c_str(),
                        nullptr));
                  }
                  fl_method_call_respond(method_call, async_response, nullptr);
                  g_object_unref(method_call);
                });
            return;
          }
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        }
      } else if (self->video_surface && g_strcmp0(fl_value_get_string(name_value), "hdr-enabled") == 0) {
        // HDR spans both halves of the plane: mpv has to emit PQ / BT.2020, and
        // the compositor has to be told that is what the buffer holds. Neither
        // alone produces HDR, so this cannot go through the plain property path.
        const bool enabled = plezy::mpv_common::ParseEnabledFlag(fl_value_get_string(value_value));
        // What every internal re-apply reads. This records the user's
        // permission, which is app policy and not a capability, so it is kept
        // even when the output cannot show HDR right now: decide_hdr gates on
        // output_is_hdr separately, and the whole point of hdr_wanted is that
        // the plane can be re-described when the window reaches an HDR output.
        // Rolling it back on a temporarily-SDR output would strand the session
        // permanently SDR while Dart went on believing HDR was enabled - it
        // swallows this error and keeps the setting persisted.
        //
        // A plane that can never describe HDR is a different matter. That is
        // fixed for the session - an 8-bit config, or a compositor without the
        // colour-management pieces - so refusing is honest and Dart can say so.
        const gboolean previous_wanted = self->hdr_wanted;
        self->hdr_wanted = enabled ? TRUE : FALSE;
        if (enabled && !(self->video_surface->supports_hdr())) {
          self->hdr_wanted = previous_wanted;
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "HDR_UNSUPPORTED", "This compositor or video plane cannot carry HDR", nullptr));
        } else {
          g_object_ref(method_call);
          const uint64_t serial = ++self->hdr_enable_request_serial;
          submit_hdr_transaction(
              self, enabled, std::nullopt, [self, method_call, serial, previous_wanted, enabled](int error) {
                g_autoptr(FlMethodResponse) async_response = nullptr;
                if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
                  async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
                } else {
                  // Only if no newer request has claimed the field since, for the
                  // same reason the tone-mapping path checks its serial.
                  if (self->hdr_enable_request_serial == serial) self->hdr_wanted = previous_wanted;
                  // The requested value is named, not the restored one: the
                  // refusal is about the request that failed.
                  async_response = FL_METHOD_RESPONSE(fl_method_error_response_new(
                      plezy::mpv_common::kSetPropertyFailedCode,
                      (std::string("hdr-enabled='") + (enabled ? "yes" : "no") + "' failed: " + mpv_error_string(error))
                          .c_str(),
                      nullptr));
                }
                fl_method_call_respond(method_call, async_response, nullptr);
                g_object_unref(method_call);
              });
          return;
        }
      } else if (
          !self->audio_only && g_strcmp0(fl_value_get_string(name_value), "vo") == 0 &&
          g_strcmp0(fl_value_get_string(value_value), "libmpv") != 0) {
        // Embedded rendering is authoritative: the render context was created
        // against vo=libmpv, and a runtime vo switch makes mpv re-create its
        // output as a separate window, orphaning the plane. vo=gpu-next is
        // windowed by construction - the libmpv render API is OpenGL-only -
        // so there is no embedded alternative worth accepting. This guard is
        // the native invariant beneath the Dart-side filter: it is the last
        // line, and it names why.
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            plezy::mpv_common::kSetPropertyFailedCode,
            "vo is owned by Plezy: embedded video renders through vo=libmpv and a windowed VO "
            "(gpu-next) cannot be used inside the app",
            nullptr));
      } else {
        // The property name and value travel with the error so a refusal is
        // attributable: mpv's own text ("unsupported format for accessing
        // property", MPV_ERROR_PROPERTY_FORMAT) names the failure mode, not
        // the property, and without this every report of a refused write is
        // a guessing game. The value is truncated the same way
        // SetPropertyErrorDescription truncates the description, so a token
        // or URL that sneaks into a property value is bounded in the log.
        const std::string property_name = fl_value_get_string(name_value);
        const std::string property_value = fl_value_get_string(value_value);
        g_object_ref(method_call);
        self->player->SetPropertyAsync(
            property_name, property_value, [method_call, property_name, property_value](int error) {
              g_autoptr(FlMethodResponse) async_response = nullptr;
              if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
                async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
              } else {
                const char* error_code = plezy::mpv_common::SetPropertyErrorCode(error);
                std::string description;
                if (error == MPV_ERROR_UNINITIALIZED) {
                  description = "Player not initialized";
                } else {
                  description = "setProperty '" + property_name + "'='" + property_value +
                                "' failed: " + plezy::mpv_common::SetPropertyErrorDescription(error);
                  if (description.size() > plezy::mpv_common::kSetPropertyErrorDescriptionLimit) {
                    description.resize(plezy::mpv_common::kSetPropertyErrorDescriptionLimit);
                  }
                }
                async_response =
                    FL_METHOD_RESPONSE(fl_method_error_response_new(error_code, description.c_str(), nullptr));
              }
              fl_method_call_respond(method_call, async_response, nullptr);
              g_object_unref(method_call);
            });
        return;  // Response sent asynchronously
      }
    }
  } else if (strcmp(method, "setLogLevel") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* level_value = fl_value_lookup_string(args, "level");

      if (level_value == nullptr || fl_value_get_type(level_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'level'", nullptr));
      } else {
        self->player->SetLogLevel(fl_value_get_string(level_value));
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "getProperty") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* name_value = fl_value_lookup_string(args, "name");

      if (name_value == nullptr || fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'name'", nullptr));
      } else {
        g_object_ref(method_call);
        self->player->GetPropertyAsync(
            fl_value_get_string(name_value), [method_call](int error, const std::string& value) {
              g_autoptr(FlMethodResponse) async_response = nullptr;
              if (error < 0 || value.empty()) {
                async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
              } else {
                async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(value.c_str())));
              }
              fl_method_call_respond(method_call, async_response, nullptr);
              g_object_unref(method_call);
            });
        return;  // Response sent asynchronously
      }
    }
  } else if (strcmp(method, "observeProperty") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* name_value = fl_value_lookup_string(args, "name");
      FlValue* format_value = fl_value_lookup_string(args, "format");
      FlValue* id_value = fl_value_lookup_string(args, "id");

      if (name_value == nullptr || fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'name'", nullptr));
      } else if (format_value == nullptr || fl_value_get_type(format_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'format'", nullptr));
      } else if (id_value == nullptr || fl_value_get_type(id_value) != FL_VALUE_TYPE_INT) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'id'", nullptr));
      } else {
        self->player->ObserveProperty(
            fl_value_get_string(name_value), fl_value_get_string(format_value),
            static_cast<int>(fl_value_get_int(id_value)));
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "setVisible") == 0) {
    FlValue* visible_value = fl_value_lookup_string(args, "visible");

    if (visible_value == nullptr || fl_value_get_type(visible_value) != FL_VALUE_TYPE_BOOL) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing 'visible'", nullptr));
    } else {
      self->visible = fl_value_get_bool(visible_value);

      if (self->video_surface) {
        // Hiding is always Dart's to do. Showing is not, while the plane is
        // quarantined: the description was withdrawn because what mpv emits
        // could not be named, and showing it now would be the mislabelled
        // picture the kUnknown arm just refused. Dart's wish is still recorded
        // above, so the transaction that lifts the quarantine honours it.
        if (self->visible && self->hdr_output_unnameable) {
          // Actively, rather than waiting for an unrelated event: coming back on
          // screen is exactly when it is worth asking mpv again, and the
          // transaction either names the output and unhides, or lands on
          // kUnknown again and leaves things as they are.
          request_hdr_reapply(self);
        } else {
          self->video_surface->SetVisible(self->visible);
          // Becoming visible has to render explicitly: the redraw latch was
          // consumed (or suppressed) while hidden, so no callback is pending.
          if (self->visible) render_video_plane(self, TRUE);
        }
      }

      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "isHDRSupported") == 0) {
    // The output half of the gate is what stops the app offering an HDR toggle
    // on an SDR panel, where enabling it only invites the compositor to tone-map
    // a plane that never needed to be PQ in the first place.
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(hdr_available(self))));
  } else if (strcmp(method, "setVideoRect") == 0) {
    {
      auto read_int = [args](const char* key, int64_t* out) {
        FlValue* value = fl_value_lookup_string(args, key);
        if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_INT) return false;
        *out = fl_value_get_int(value);
        return true;
      };
      int64_t left = 0, top = 0, right = 0, bottom = 0;
      if (!read_int("left", &left) || !read_int("top", &top) || !read_int("right", &right) ||
          !read_int("bottom", &bottom)) {
        response =
            FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGS", "Missing video rect bounds", nullptr));
      } else {
        FlValue* dpr_value = fl_value_lookup_string(args, "devicePixelRatio");
        double dpr = 1.0;
        if (dpr_value != nullptr && fl_value_get_type(dpr_value) == FL_VALUE_TYPE_FLOAT) {
          dpr = fl_value_get_float(dpr_value);
        }
        // GTK3 only ever reports integer scale factors, and the rect already
        // arrives in physical pixels, so the scale is purely how many buffer
        // pixels make up one surface-local unit.
        //
        // Clamped before the cast, not after: a double->int32 conversion whose
        // truncated value does not fit is undefined, and the two architectures
        // disagree about what falls out - x86-64 gives INT32_MIN, which the
        // lower bound below would catch, while AArch64 saturates to INT32_MAX,
        // which it would not. That value then becomes SetRect's rounding block
        // and would be sent as the buffer scale. NaN fails both comparisons and
        // takes the default.
        if (!(dpr >= 1.0)) dpr = 1.0;
        if (dpr > 16.0) dpr = 16.0;
        const int32_t scale = static_cast<int32_t>(dpr + 0.5);
        // Same reasoning as the scale above, applied to the bounds: these are
        // int64 channel arguments, so `right - left` can overflow before the
        // narrowing, and the narrowing itself is implementation-defined before
        // C++20. Clamp into int32 first and take the width in 64 bits, so a
        // hostile rect becomes a large plane rather than undefined behaviour.
        constexpr int64_t kMin = std::numeric_limits<int32_t>::min();
        constexpr int64_t kMax = std::numeric_limits<int32_t>::max();
        auto clamp32 = [](int64_t value) -> int64_t { return value < kMin ? kMin : (value > kMax ? kMax : value); };
        left = clamp32(left);
        top = clamp32(top);
        const int64_t width = clamp32(clamp32(right) - left);
        const int64_t height = clamp32(clamp32(bottom) - top);
        // Remembered rather than dropped when there is no plane yet. A video
        // session is legitimately asked for geometry between construction and
        // start_video_plane, and Dart only re-sends a rect whose numbers
        // changed - so a rect discarded here is one the plane may never hear
        // again, leaving it sizeless and blank. The audio-only core keeps this
        // too and simply never reads it.
        self->pending_rect.x = static_cast<int32_t>(left);
        self->pending_rect.y = static_cast<int32_t>(top);
        self->pending_rect.width = static_cast<int32_t>(width);
        self->pending_rect.height = static_cast<int32_t>(height);
        self->pending_rect.scale = scale;
        self->has_pending_rect = TRUE;
        if (self->video_surface) {
          if (self->render_in_flight) {
            // wl_egl_window_resize must not race the in-flight swap; the
            // render completion applies the rect. The sticky flag makes it
            // re-render at the new size, exactly like the immediate path.
            self->rect_apply_deferred = TRUE;
            self->plane_needs_render = TRUE;
          } else {
            apply_pending_rect(self);
            // Re-render at the new size straight away; waiting for the next mpv
            // frame would leave a stale buffer stretched across the new rect.
            render_video_plane(self, TRUE);
          }
        }
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "updateFrame") == 0) {
    // The cross-platform "kick the video output" call. On the plane that means
    // forcing a render: mpv may have no new frame, but the caller is asking
    // because what is on screen is stale.
    if (self->visible) render_video_plane(self, TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "isInitialized") == 0) {
    gboolean initialized = self->player && self->initialized;
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(initialized)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}
