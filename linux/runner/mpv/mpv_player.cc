#include "mpv_player.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <flutter_linux/flutter_linux.h>
#include <gdk/gdk.h>

#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif
#include <locale.h>

// EGL 1.5 names; EGL_KHR_create_context introduced the same values earlier.
// Declared here so the build does not depend on which EGL headers the distro
// ships - the runtime check is eglCreateContext refusing the attribute, which
// the caller already falls back from.
#ifndef EGL_CONTEXT_MAJOR_VERSION
#define EGL_CONTEXT_MAJOR_VERSION EGL_CONTEXT_CLIENT_VERSION
#endif
#ifndef EGL_CONTEXT_MINOR_VERSION
#define EGL_CONTEXT_MINOR_VERSION 0x30FB
#endif

#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <cstring>

#include "sanitize_utf8.h"

namespace {

bool EnsureProcessNumericLocale() {
  // libmpv parses numeric options on worker threads, so a thread-local locale
  // is insufficient. This process-wide setting intentionally remains in force
  // for the rest of the process after the first player starts.
  static const bool configured = setlocale(LC_NUMERIC, "C") != nullptr;
  return configured;
}

// Reply userdata for the runner's own `video-params` observation.
//
// Every Dart-facing observation takes its userdata from
// PropertyObservationRegistry, which hands out 1, 2, 3, … one per distinct
// property name and never resets the counter; the two audio observations below
// pass 0, which the registry also never hands out. UINT64_MAX is the one value
// the counter cannot reach without first wrapping — and a wrap would collide
// with those two just as surely, so the scheme already depends on it not
// happening.
constexpr uint64_t kVideoParamsUserdata = UINT64_MAX;

// Runner-internal observation of the decode path mpv actually took. The
// "silent software fallback" is the one hwdec failure mode with no visible
// symptom, so every transition is logged with a timestamp from the native
// side rather than inferred from an overlay readout.
constexpr uint64_t kHwdecCurrentUserdata = UINT64_MAX - 1;

// Parses the string reply of a `time-pos` read: the whole string must be one
// finite number. Anything else — an empty reply, "inf"/"nan", trailing text —
// is "no position" rather than a manufactured one. LC_NUMERIC is the C locale
// process-wide (EnsureProcessNumericLocale), which is also what mpv printed in.
bool ParseSeconds(const std::string& value, double* seconds) {
  if (value.empty()) return false;
  char* end = nullptr;
  const double parsed = std::strtod(value.c_str(), &end);
  if (end != value.c_str() + value.size() || !std::isfinite(parsed)) return false;
  *seconds = parsed;
  return true;
}

}  // namespace

// Flutter on Linux uses EGL (OpenGL ES) for both X11 and Wayland.
static void* get_opengl_proc_address(void* ctx, const char* name) {
  (void)ctx;
  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

namespace mpv {
namespace {

NativeRenderTeardownOperations ProductionTeardownOperations() {
  return {
      [](EGLDisplay display, EGLContext context) {
        if (!eglBindAPI(EGL_OPENGL_ES_API) || !eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context)) {
          g_warning("MPV: Failed to activate EGL context for teardown: 0x%x", eglGetError());
          return false;
        }
        return true;
      },
      [](EGLDisplay display) {
        if (!eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
          g_warning("MPV: Failed to release EGL context during teardown: 0x%x", eglGetError());
          return false;
        }
        return true;
      },
      [](EGLDisplay display, EGLContext context) {
        if (!eglDestroyContext(display, context)) {
          g_warning("MPV: Failed to destroy EGL context during teardown: 0x%x", eglGetError());
          return false;
        }
        return true;
      },
      [](mpv_render_context* render) { mpv_render_context_free(render); },
      [](mpv_handle* handle) { mpv_terminate_destroy(handle); },
  };
}

#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
NativeRenderTeardownOperations*& TestTeardownOperationsOverride() {
  static NativeRenderTeardownOperations* operations = nullptr;
  return operations;
}
#endif

class NativeRenderTeardownQueue {
 public:
  static NativeRenderTeardownQueue& Instance() {
    // Native driver/libmpv teardown can block indefinitely. Keep both the
    // queue and its worker state alive until the OS ends the process so static
    // destruction never joins the worker or invalidates state it may access.
    static NativeRenderTeardownQueue* const queue = new NativeRenderTeardownQueue();
    return *queue;
  }

  void Enqueue(NativeRenderTeardownBatch batch) {
    if (batch.resources.empty() && !batch.handle) return;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      batches_.push_back(std::move(batch));
      ++generation_;
    }
    condition_.notify_one();
  }

  void Retry() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      ++generation_;
    }
    condition_.notify_one();
  }

 private:
  NativeRenderTeardownQueue() : worker_([this]() { Run(); }) {}

  void Run() {
#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
    const NativeRenderTeardownOperations operations =
        TestTeardownOperationsOverride() ? *TestTeardownOperationsOverride() : ProductionTeardownOperations();
#else
    const NativeRenderTeardownOperations operations = ProductionTeardownOperations();
#endif
    std::unique_lock<std::mutex> lock(mutex_);
    for (;;) {
      condition_.wait(lock, [this]() { return !batches_.empty(); });
      const uint64_t observed_generation = generation_;
      std::vector<NativeRenderTeardownBatch> work = std::move(batches_);
      batches_.clear();

      // EGL activation and mpv shutdown can block in a driver. Keep queue
      // admission independent so replacement initialization and disposal only
      // pay the short ownership-transfer critical section.
      lock.unlock();
      std::vector<NativeRenderTeardownBatch> retry;
      for (auto& batch : work) {
        if (!TryReleaseNativeRenderTeardown(batch, operations)) retry.push_back(std::move(batch));
      }
      lock.lock();
      for (auto& batch : retry) batches_.push_back(std::move(batch));

      if (batches_.empty()) continue;

      condition_.wait_for(lock, std::chrono::milliseconds(100), [this, observed_generation]() {
        return generation_ != observed_generation;
      });
    }
  }

  std::mutex mutex_;
  std::condition_variable condition_;
  std::vector<NativeRenderTeardownBatch> batches_;
  uint64_t generation_ = 0;
  std::thread worker_;
};

// Mesa's software rasterizers, as named in GL_RENDERER. The video plane lands
// on one when the compositor hands clients no GPU device (Muffin 6.6.3 does
// exactly that), and that session is the one where handing mpv the Wayland
// display is not merely futile but fatal — see the MPV_RENDER_PARAM_WL_DISPLAY
// comment in InitRenderContextForSurface.
bool IsSoftwareGlRenderer(const char* renderer) {
  if (renderer == nullptr) return false;
  return strstr(renderer, "llvmpipe") != nullptr || strstr(renderer, "softpipe") != nullptr ||
         strstr(renderer, "swrast") != nullptr || strstr(renderer, "Software Rasterizer") != nullptr;
}

}  // namespace

#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
void ConfigureNativeRenderTeardownQueueForTesting(NativeRenderTeardownOperations operations) {
  auto*& configured = TestTeardownOperationsOverride();
  if (configured) {
    *configured = std::move(operations);
  } else {
    configured = new NativeRenderTeardownOperations(std::move(operations));
  }
}

void EnqueueNativeRenderTeardownForTesting(NativeRenderTeardownBatch batch) {
  NativeRenderTeardownQueue::Instance().Enqueue(std::move(batch));
}
#endif

bool TryReleaseNativeRenderTeardown(
    NativeRenderTeardownBatch& batch, const NativeRenderTeardownOperations& operations) {
  for (auto it = batch.resources.begin(); it != batch.resources.end();) {
    if (it->context == EGL_NO_CONTEXT || !operations.make_current(it->display, it->context)) {
      ++it;
      continue;
    }

    if (it->render) {
      operations.free_render(it->render);
      it->render = nullptr;
    }
    if (!operations.release_current(it->display)) {
      ++it;
      continue;
    }
    if (!operations.destroy_context(it->display, it->context)) {
      ++it;
      continue;
    }
    it = batch.resources.erase(it);
  }

  if (!batch.resources.empty()) return false;
  if (batch.handle) {
    operations.terminate_handle(batch.handle);
    batch.handle = nullptr;
  }
  batch.callback_keep_alive.reset();
  return true;
}

MpvPlayer::CallbackContext::Lease::Lease(CallbackContext* context, MpvPlayer* player)
    : context_(context), player_(player) {}

MpvPlayer::CallbackContext::Lease::Lease(Lease&& other) noexcept : context_(other.context_), player_(other.player_) {
  other.context_ = nullptr;
  other.player_ = nullptr;
}

MpvPlayer::CallbackContext::Lease& MpvPlayer::CallbackContext::Lease::operator=(Lease&& other) noexcept {
  if (this != &other) {
    Release();
    context_ = other.context_;
    player_ = other.player_;
    other.context_ = nullptr;
    other.player_ = nullptr;
  }
  return *this;
}

MpvPlayer::CallbackContext::Lease::~Lease() { Release(); }

void MpvPlayer::CallbackContext::Lease::Release() {
  if (!context_) return;
  context_->ReleaseLease();
  context_ = nullptr;
  player_ = nullptr;
}

MpvPlayer::CallbackContext::CallbackContext(MpvPlayer* player)
    : player_(player), main_context_(g_main_context_ref_thread_default()) {}

MpvPlayer::CallbackContext::~CallbackContext() { g_main_context_unref(main_context_); }

MpvPlayer::CallbackContext::Lease MpvPlayer::CallbackContext::Acquire() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!player_) return Lease();
  ++in_flight_;
  return Lease(this, player_);
}

void MpvPlayer::CallbackContext::WaitUntilDetached() {
  std::unique_lock<std::mutex> lock(mutex_);
  quiescent_.wait(lock, [this]() { return player_ == nullptr; });
}
void MpvPlayer::CallbackContext::DetachAndWait() {
  std::unique_lock<std::mutex> lock(mutex_);
  player_ = nullptr;
  quiescent_.notify_all();
  quiescent_.wait(lock, [this]() { return in_flight_ == 0; });
}

void MpvPlayer::CallbackContext::ReleaseLease() {
  std::lock_guard<std::mutex> lock(mutex_);
  --in_flight_;
  if (in_flight_ == 0) quiescent_.notify_all();
}

struct MpvPlayer::SourceCallbackData {
  explicit SourceCallbackData(std::shared_ptr<CallbackContext> callback_context)
      : context(std::move(callback_context)) {}

  std::shared_ptr<CallbackContext> context;
  guint source_id = 0;
};

MpvPlayer::MpvPlayer(bool audio_only)
    : audio_only_(audio_only), callback_context_(std::make_shared<CallbackContext>(this)) {}

MpvPlayer::~MpvPlayer() { Dispose(); }

bool MpvPlayer::IsInitialized() const {
  std::lock_guard<std::mutex> lock(native_mutex_);
  return mpv_ != nullptr && (audio_only_ || mpv_gl_ != nullptr);
}

bool MpvPlayer::HasMpvHandle() const {
  std::lock_guard<std::mutex> lock(native_mutex_);
  return mpv_ != nullptr;
}

bool MpvPlayer::Initialize() {
  std::lock_guard<std::mutex> lock(native_mutex_);
  if (disposed_) {
    g_warning("MPV: initialization requested after disposal");
    return false;
  }
  if (mpv_) {
    return true;  // Already initialized.
  }

  if (!EnsureProcessNumericLocale()) {
    g_warning("MPV: Failed to establish the process-wide C numeric locale");
    return false;
  }

  // Create mpv instance.
  mpv_ = mpv_create();
  if (!mpv_) {
    g_warning("MPV: mpv_create() failed");
    return false;
  }

  plezy::mpv_common::ApplyCommonStartupOptions(mpv_, audio_only_);
  mpv_set_option_string(mpv_, "terminal", "no");

  if (!audio_only_) {
    // Configure mpv for embedded playback.
    mpv_set_option_string(mpv_, "vo", "libmpv");
    mpv_set_option_string(mpv_, "hwdec", "auto");

    // hdr-compute-peak is nested under the same predicate as the tone-map pass -
    // it runs exactly when the source's declared peak exceeds target-peak - so it
    // costs nothing while the compositor owns tone mapping and gives
    // content-adaptive peak detection once we own it.
    //
    // `tone-mapping` is deliberately *not* set here: it travels with the output
    // description and is applied and withdrawn in RunPendingHdrOutput instead.
    // See applied_tone_mapping_ in mpv_player.h for why it cannot be global.
    mpv_set_option_string(mpv_, "hdr-compute-peak", "auto");
    // Declared by vo_gpu_next only, so inert for the render API this player
    // runs. Set anyway so the startup value agrees with what a later
    // `hdr-enabled` write puts here through SetHDREnabled.
    mpv_set_option_string(mpv_, "target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(hdr_enabled_));
  }

  // Default to info-level logging. The vaapi hwdec probe and the "Using
  // software decoding" fallback are MSGL_INFO messages, and both are the only
  // evidence a silently software-decoding session leaves behind; at "warn"
  // neither ever reaches the app log (mpv_request_log_messages takes a single
  // global level - there is no per-module syntax here), so a hwdec regression
  // is indistinguishable from a working one. Debug logging raises this
  // further via setLogLevel.
  mpv_request_log_messages(mpv_, "info");

  // Initialize mpv.
  int err = mpv_initialize(mpv_);
  if (err < 0) {
    g_warning("MPV: mpv_initialize() failed: %s", mpv_error_string(err));
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // Set up event wakeup callback.
  mpv_set_wakeup_callback(mpv_, OnMpvWakeup, callback_context_.get());
  mpv_observe_property(mpv_, 0, "current-ao", MPV_FORMAT_STRING);
  mpv_observe_property(mpv_, 0, "audio-device-list", MPV_FORMAT_NONE);
  if (!audio_only_) {
    // One node observation stands in for six blocking sub-property reads. The
    // HDR decision runs on the GTK main thread and one of its callers fires on
    // every seek, while libmpv's synchronous read hands the request to the core
    // and waits for the playloop; every other property access here is async for
    // exactly that reason.
    //
    // An audio-only core has no video-params to report, so it is not asked.
    source_hdr_metadata_ = SourceHdrMetadata();
    mpv_observe_property(mpv_, kVideoParamsUserdata, "video-params", MPV_FORMAT_NODE);
    // Which decode path is in use. mpv only emits on change, so each event is
    // a real transition worth a log line.
    mpv_observe_property(mpv_, kHwdecCurrentUserdata, "hwdec-current", MPV_FORMAT_STRING);
  }

  g_message("MPV: Initialization successful (%s)", audio_only_ ? "audio-only" : "render context deferred");
  return true;
}

void MpvPlayer::RetryPendingNativeTeardown() { NativeRenderTeardownQueue::Instance().Retry(); }

bool MpvPlayer::InitRenderContextForSurface(EGLDisplay display, EGLConfig config, EGLSurface surface, int depth_bits) {
  RetryPendingNativeTeardown();

  std::lock_guard<std::mutex> lock(native_mutex_);
  if (audio_only_ || disposed_) {
    g_warning("MPV: Video-plane render context requested for an unavailable player");
    return false;
  }
  if (mpv_gl_) return true;
  if (!mpv_) {
    g_warning("MPV: Cannot create render context - mpv not initialized");
    return false;
  }
  if (display == EGL_NO_DISPLAY || surface == EGL_NO_SURFACE) {
    g_warning("MPV: Video plane provided no usable EGL display or surface");
    return false;
  }
  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    g_warning("MPV: Failed to bind OpenGL ES API: 0x%x", eglGetError());
    return false;
  }

  // Nothing is shared with Flutter here, so take the highest ES version the
  // driver will give. EGL_CONTEXT_CLIENT_VERSION=3 asks for exactly 3.0, which
  // reads as "ES 3" while being the oldest of them; 3.2 brings float render
  // targets (mpv picks an rgba16f FBO on this path) and ES 3.1 semantics for
  // the rest.
  //
  // It does **not** buy compute shaders. mpv refuses them on any GLES context at
  // any version, by construction (`video/out/opengl/ra_gl.c:136-139` in v0.40.0):
  //
  //   // While we can handle compute shaders on GLES the spec (intentionally)
  //   // does not support binding textures for writing, which all uses inside
  //   // mpv would require. So disable it unconditionally anyway.
  //   if (ra->glsl_es) ra->caps &= ~RA_CAP_COMPUTE;
  //
  // So `hdr-compute-peak` is unreachable through the render API here however
  // new the context is - confirmed on hardware with an ES 3.2 context whose
  // glDispatchCompute and glBindImageTexture both resolve, where mpv still
  // logs "Disabling HDR peak computation (compute shaders=0)". The player-side
  // tone map therefore aims at the peak the source declares rather than one
  // measured from the frames. Reaching it needs a desktop-GL context on the
  // plane, which is the same architectural door as libplacebo and belongs with
  // it rather than in a version bump.
  //
  // EGL_CONTEXT_MINOR_VERSION needs EGL 1.5 or EGL_KHR_create_context. Where
  // neither is present eglCreateContext rejects the attribute outright, so the
  // legacy CLIENT_VERSION-only request stays as the floor rather than letting
  // a missing extension fail context creation altogether.
  struct EsVersion {
    EGLint major;
    EGLint minor;
  };
  static constexpr EsVersion kPreferredEsVersions[] = {{3, 2}, {3, 1}, {3, 0}, {2, 0}};
  EGLContext candidate_context = EGL_NO_CONTEXT;
  EGLint chosen_major = 0;
  EGLint chosen_minor = 0;
  for (const EsVersion& version : kPreferredEsVersions) {
    const EGLint context_attribs[] = {
        EGL_CONTEXT_MAJOR_VERSION, version.major, EGL_CONTEXT_MINOR_VERSION, version.minor, EGL_NONE};
    candidate_context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attribs);
    if (candidate_context != EGL_NO_CONTEXT) {
      chosen_major = version.major;
      chosen_minor = version.minor;
      break;
    }
  }
  if (candidate_context == EGL_NO_CONTEXT) {
    for (const EGLint client_version : {3, 2}) {
      const EGLint context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, client_version, EGL_NONE};
      candidate_context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attribs);
      if (candidate_context != EGL_NO_CONTEXT) {
        chosen_major = client_version;
        chosen_minor = 0;
        break;
      }
    }
  }
  if (candidate_context == EGL_NO_CONTEXT) {
    g_warning("MPV: Failed to create the video-plane EGL context: 0x%x", eglGetError());
    return false;
  }
  // Report the requested version, not the delivered one - those are different
  // claims, and the delivered one is logged below once a context is current.
  g_message("MPV video plane: requested OpenGL ES %d.%d", chosen_major, chosen_minor);

  auto destroy_candidate_context = [&]() {
    if (eglGetCurrentContext() == candidate_context) {
      eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    }
    if (!eglDestroyContext(display, candidate_context)) {
      g_warning("MPV: Failed to destroy rejected video-plane EGL context: 0x%x", eglGetError());
    }
  };

  if (!eglMakeCurrent(display, surface, surface, candidate_context)) {
    g_warning("MPV: Failed to activate the video-plane EGL context: 0x%x", eglGetError());
    destroy_candidate_context();
    return false;
  }

  // What the driver actually gave, and whether mpv will find the entry points
  // its compute path needs. Asking for a version is not the same as getting
  // it, and mpv's own report of "compute shaders=0" says nothing about which
  // half is missing. All of these are cheap and all were needed to diagnose
  // this. The renderer name additionally decides the hwdec display handoff
  // below.
  const GLubyte* gl_version = glGetString(GL_VERSION);
  const GLubyte* gl_renderer = glGetString(GL_RENDERER);
  const bool software_renderer = IsSoftwareGlRenderer(reinterpret_cast<const char*>(gl_renderer));
  g_message(
      "MPV video plane: GL_VERSION='%s' GL_RENDERER='%s' dispatch_compute=%s image_load_store=%s",
      gl_version ? reinterpret_cast<const char*>(gl_version) : "(null)",
      gl_renderer ? reinterpret_cast<const char*>(gl_renderer) : "(null)",
      eglGetProcAddress("glDispatchCompute") ? "yes" : "no", eglGetProcAddress("glBindImageTexture") ? "yes" : "no");

  // Pre-flight the VAAPI dmabuf interop prerequisites. mpv's GL-side probe
  // (dmabuf_interop_gl_init) is lazy — first hardware decode attempt — and its
  // failure never fails mpv_render_context_create, so a driver that lacks the
  // pieces quietly decodes everything in software. Naming which prerequisite
  // is missing on this display/context turns that into a diagnosable
  // one-liner. The three extensions are the ones the probe requires;
  // EGL_EXT_image_dma_buf_import is the display-level one, GL_OES_EGL_image is
  // context-level. (The VAAPI *device* init is a different story: given a
  // Wayland display below, mpv opens it eagerly inside
  // mpv_render_context_create.)
  const char* egl_exts = eglQueryString(display, EGL_EXTENSIONS);
  const GLubyte* gl_exts = glGetString(GL_EXTENSIONS);
  const bool has_dma_buf = egl_exts != nullptr && strstr(egl_exts, "EGL_EXT_image_dma_buf_import") != nullptr;
  const bool has_image_base = egl_exts != nullptr && strstr(egl_exts, "EGL_KHR_image_base") != nullptr;
  const bool has_oes_egl_image =
      gl_exts != nullptr && strstr(reinterpret_cast<const char*>(gl_exts), "GL_OES_EGL_image") != nullptr;
  if (!has_dma_buf || !has_image_base || !has_oes_egl_image) {
    g_warning(
        "MPV video plane: VAAPI dmabuf interop prerequisites missing "
        "(EGL_EXT_image_dma_buf_import=%d EGL_KHR_image_base=%d GL_OES_EGL_image=%d); "
        "hardware decoding may silently fall back to software",
        has_dma_buf, has_image_base, has_oes_egl_image);
  }

  // Now that a context is current, the surface's swap interval can be set.
  // eglSwapBuffers runs on the GTK main thread and must never block: at the
  // default interval Mesa throttles it on the compositor's frame callback,
  // which an occluded surface never receives. The plane paces itself with its
  // own frame callback instead.
  if (!eglSwapInterval(display, 0)) {
    g_warning("MPV: could not disable EGL swap throttling on the video plane: 0x%x", eglGetError());
  }

  mpv_opengl_init_params gl_init_params{};
  gl_init_params.get_proc_address = get_opengl_proc_address;
  gl_init_params.get_proc_address_ctx = nullptr;
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_API_TYPE, const_cast<char*>(MPV_RENDER_API_TYPE_OPENGL)},
      {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
      {MPV_RENDER_PARAM_INVALID, nullptr},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  // The plane only exists on Wayland, and hwdec interop wants the display
  // handle: without it VAAPI has to find a device by other means and can
  // quietly end up on software decoding, on the path that exists for
  // performance.
  //
  // Never on a software renderer, though. Zero-copy interop into llvmpipe does
  // not exist, so the handle buys nothing — and the one session that produces
  // a software renderer on the plane (a compositor that hands clients no GPU
  // device; Muffin 6.6.3, issue #1963) is also the one where libva-wayland's
  // vaInitialize segfaults on that handle, inside mpv_render_context_create,
  // taking the app down before playback starts. Left without a display handle,
  // mpv's hwdec=auto probes the DRM render nodes instead, which still works on
  // such a session (the kernel driver is fine; only the compositor's device
  // handoff is broken).
#ifdef GDK_WINDOWING_WAYLAND
  GdkDisplay* gdk_display = gdk_display_get_default();
  if (GDK_IS_WAYLAND_DISPLAY(gdk_display) && !software_renderer) {
    params[2].type = MPV_RENDER_PARAM_WL_DISPLAY;
    params[2].data = gdk_wayland_display_get_wl_display(gdk_display);
  } else if (software_renderer) {
    g_message("MPV video plane: software GL renderer; not handing mpv the Wayland display for VAAPI interop");
  }
#endif

  mpv_render_context* candidate_gl = nullptr;
  const int error = mpv_render_context_create(&candidate_gl, mpv_, params);
  if (error < 0 || candidate_gl == nullptr) {
    g_warning("MPV: mpv_render_context_create() failed for the video plane: %s", mpv_error_string(error));
    if (candidate_gl) mpv_render_context_free(candidate_gl);
    destroy_candidate_context();
    return false;
  }

  egl_display_ = display;
  egl_context_ = candidate_context;
  surface_depth_bits_ = depth_bits > 0 ? depth_bits : 8;
  mpv_gl_ = candidate_gl;
  mpv_render_context_set_update_callback(mpv_gl_, OnMpvRenderUpdate, callback_context_.get());
  // Hand the context over unbound: from here on only the plane render thread
  // makes it current (RenderToSurface), and an EGLContext can be current on at
  // most one thread. Creation itself had to happen with it current here - mpv
  // probes GL inside mpv_render_context_create.
  if (!eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
    g_warning("MPV: could not unbind the video-plane EGL context after creation: 0x%x", eglGetError());
  }
  g_message("MPV: Render context created on the Wayland video plane");
  return true;
}

bool MpvPlayer::RenderToSurface(EGLSurface surface, int width, int height) {
  // Runs on the plane render thread. Deliberately not holding native_mutex_
  // across the render: a 4K HDR tone-map takes tens of milliseconds, and the
  // mutex has main-thread callers on every seek (ReadSourceHdrMetadata,
  // UpdateSourceHdrMetadata) - holding it here would rebuild the very stall
  // this thread exists to remove, behind a lock instead of a thread. The
  // snapshot below is safe without it because of ordering, not locking: the
  // plugin drains the render thread (release_video_resources) before
  // Dispose() hands mpv_gl_ and the EGL context to the teardown queue, so
  // neither can be freed while a job is running.
  mpv_render_context* render_context = nullptr;
  EGLDisplay display = EGL_NO_DISPLAY;
  EGLContext context = EGL_NO_CONTEXT;
  int depth_bits = 8;
  {
    std::lock_guard<std::mutex> lock(native_mutex_);
    if (disposed_ || !mpv_gl_ || egl_context_ == EGL_NO_CONTEXT || surface == EGL_NO_SURFACE) return false;
    if (width < 1 || height < 1) return false;
    render_context = mpv_gl_;
    display = egl_display_;
    context = egl_context_;
    depth_bits = surface_depth_bits_;
  }

  if (!eglBindAPI(EGL_OPENGL_ES_API) || !eglMakeCurrent(display, surface, surface, context)) {
    g_warning("MPV: Failed to activate the video-plane EGL context for render: 0x%x", eglGetError());
    return false;
  }

  // Consume the redraw latch before rendering: OnMpvRenderUpdate drops further
  // notifications until it is cleared.
  needs_redraw_.store(false);

  mpv_opengl_fbo mpv_fbo{};
  mpv_fbo.fbo = 0;  // the window surface's default framebuffer
  mpv_fbo.w = width;
  mpv_fbo.h = height;
  // Ignored by the render API's OpenGL backend, which reads the depth param
  // instead, but it is what mpv#16818's gpu-next backend will read, so state
  // it truthfully rather than leave a lie in place for that day.
  mpv_fbo.internal_format = depth_bits >= 16 ? GL_RGBA16F : depth_bits >= 10 ? GL_RGB10_A2 : GL_RGBA8;

  // The default framebuffer is bottom-up relative to mpv's image orientation,
  // so this flips.
  int flip_y = 1;
  // Without this mpv assumes 8 bits and dithers a 10-bit PQ plane down to 8,
  // which bands precisely in the dark ramp PQ spends most of its code space on.
  int depth = depth_bits;
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &mpv_fbo},
      {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
      {MPV_RENDER_PARAM_DEPTH, &depth},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };
  mpv_render_context_render(render_context, params);
  return true;
}

void MpvPlayer::Dispose() {
  if (disposed_.exchange(true)) {
    return;
  }

  // Stop native producers before revoking access to the player. A callback
  // already entered on an mpv thread owns a lease and is allowed to finish.
  {
    std::lock_guard<std::mutex> lock(native_mutex_);
    if (mpv_) {
      const char* stop_command[] = {"stop", nullptr};
      const int stop_result = mpv_command_async(mpv_, 0, stop_command);
      if (stop_result < 0) {
        g_warning("MPV: Failed to enqueue stop during disposal: %s", mpv_error_string(stop_result));
      }
    }
    if (mpv_gl_) {
      mpv_render_context_set_update_callback(mpv_gl_, nullptr, nullptr);
    }
    if (mpv_) {
      mpv_set_wakeup_callback(mpv_, nullptr, nullptr);
    }
  }
  callback_context_->DetachAndWait();

  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    redraw_callback_ = nullptr;
    event_callback_ = nullptr;
    source_metadata_callback_ = nullptr;
  }

  auto cancelled = pending_requests_.CancelAll();
  for (auto& callback : cancelled.status) {
    callback(MPV_ERROR_UNINITIALIZED);
  }
  for (auto& callback : cancelled.commands) {
    callback(MPV_ERROR_UNINITIALIZED, nullptr);
  }
  for (auto& callback : cancelled.properties) {
    callback(-1, "");
  }

  RemoveTrackedSources();

  // The plane's context is normally already unbound by the time this runs: the
  // plane render thread makes it current (RenderToSurface) and the plugin's
  // teardown posts an unbind there before draining the thread ahead of this
  // call. This main-thread release covers the two paths that still bind it
  // here - the PLEZY_PLANE_RENDER_MAIN_THREAD inline fallback, and a context
  // created but never rendered with, where InitRenderContextForSurface's own
  // unbind failed. An EGLContext can be current to at most one thread, so
  // handing it to the teardown worker while it is still bound here makes the
  // worker's eglMakeCurrent fail with EGL_BAD_ACCESS; the pair is then
  // retained, and by the note below the mpv handle cannot be terminated until
  // every pair drains. Repeated open/close would carry a whole stale mpv core
  // across each gap. Only our own context is released: Flutter's must be left
  // exactly where it is.
  if (egl_context_ != EGL_NO_CONTEXT && eglGetCurrentContext() == egl_context_) {
    if (!eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
      g_warning("MPV: Failed to release the video-plane EGL context before teardown: 0x%x", eglGetError());
    }
  }

  // Transfer the render context, the EGL context and the shared mpv handle to
  // the managed teardown thread. A failed EGL bind leaves the complete pair in
  // the queue; the handle cannot be terminated until every pair is gone.
  NativeRenderTeardownBatch teardown;
  {
    std::lock_guard<std::mutex> lock(native_mutex_);
    if (mpv_gl_ || egl_context_ != EGL_NO_CONTEXT) {
      teardown.resources.push_back({mpv_gl_, egl_display_, egl_context_});
    }
    teardown.handle = mpv_;
    teardown.callback_keep_alive = callback_context_;
    mpv_gl_ = nullptr;
    mpv_ = nullptr;
    egl_display_ = EGL_NO_DISPLAY;
    egl_context_ = EGL_NO_CONTEXT;
    // The next player must not decide against this one's colour space.
    source_hdr_metadata_ = SourceHdrMetadata();
  }
  NativeRenderTeardownQueue::Instance().Enqueue(std::move(teardown));

  observed_properties_.Clear();
}

void MpvPlayer::Command(const std::vector<std::string>& args) { CommandAsync(args, nullptr); }

void MpvPlayer::CommandAsync(const std::vector<std::string>& args, CommandCallback callback) {
  if (disposed_ || !mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED, nullptr);
    return;
  }

  plezy::mpv_common::SubmitCommandAsync(mpv_, pending_requests_, args, std::move(callback));
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  SetPropertyAsync(name, value, nullptr);
}

void MpvPlayer::SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback) {
#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
  // Ahead of the handle check: a substituted writer stands in for the core, so
  // the absence of a real one is not a reason to refuse the write.
  if (test_property_write_) {
    test_property_write_(name, value, std::move(callback));
    return;
  }
#endif
  if (disposed_ || !mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED);
    return;
  }

  if (name == "hdr-enabled") {
    SetHDREnabled(plezy::mpv_common::ParseEnabledFlag(value), std::move(callback));
    return;
  }
  plezy::mpv_common::SubmitSetPropertyAsync(
      mpv_, pending_requests_, name, value, [this, name, value, cb = std::move(callback)](int error) mutable {
        // Native-side attribution for the same failure the platform channel
        // reports: the HDR transaction's property writes never reach the
        // channel handler, so without this a refused target-* write leaves
        // only mpv's error string in the log. Values are truncated the same
        // way the channel error description is, so a token or URL that lands
        // in a property value stays bounded.
        if (error < 0 && !disposed_) {
          std::string logged = value;
          if (logged.size() > plezy::mpv_common::kSetPropertyErrorDescriptionLimit) {
            logged.resize(plezy::mpv_common::kSetPropertyErrorDescriptionLimit);
          }
          g_warning("MPV: setProperty '%s'='%s' failed: %s", name.c_str(), logged.c_str(), mpv_error_string(error));
        }
        if (cb) cb(error);
      });
}

bool MpvPlayer::ReadSourceHdrMetadata(SourceHdrMetadata* out) {
  if (out == nullptr) return false;
  std::lock_guard<std::mutex> lock(native_mutex_);
  if (disposed_ || !mpv_) return false;
  *out = source_hdr_metadata_;
  return true;
}

void MpvPlayer::UpdateSourceHdrMetadata(const mpv_node* params) {
  {
    std::lock_guard<std::mutex> lock(native_mutex_);
    source_hdr_metadata_ = ParseSourceHdrMetadata(params);
  }

  // Outside the lock on purpose: the callback's whole job is to re-run the HDR
  // decision, which reads the cache straight back through ReadSourceHdrMetadata.
  SourceMetadataCallback callback;
  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    callback = source_metadata_callback_;
  }
  if (callback) callback();
}

void MpvPlayer::SetSourceMetadataCallback(SourceMetadataCallback callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  source_metadata_callback_ = std::move(callback);
}

void MpvPlayer::GetPropertyAsync(const std::string& name, GetPropertyCallback callback) {
#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
  if (test_property_read_) {
    test_property_read_(name, std::move(callback));
    return;
  }
#endif
  if (disposed_ || !mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED, "");
    return;
  }

  plezy::mpv_common::SubmitGetPropertyAsync(mpv_, pending_requests_, name, std::move(callback));
}

void MpvPlayer::ObserveProperty(const std::string& name, const std::string& format, int id) {
  if (disposed_ || !mpv_) return;

  const auto request = observed_properties_.Register(name, format, id);
  if (!request.added) return;
  mpv_observe_property(mpv_, request.userdata, name.c_str(), request.format);
}

void MpvPlayer::SetEventCallback(EventCallback callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  event_callback_ = std::move(callback);
}

void MpvPlayer::SetRedrawCallback(RedrawCallback callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  redraw_callback_ = std::move(callback);
}

void MpvPlayer::SetLogLevel(const std::string& level) {
  if (disposed_ || !mpv_) return;
  mpv_request_log_messages(mpv_, level.c_str());
}

void MpvPlayer::OnMpvWakeup(void* ctx) {
  auto* context = static_cast<CallbackContext*>(ctx);
  auto lease = context->Acquire();
  if (!lease) return;

  MpvPlayer* player = lease.player();
  if (!player->disposed_) {
    player->ScheduleWakeupSource();
  }
}

void MpvPlayer::OnMpvRenderUpdate(void* ctx) {
  auto* context = static_cast<CallbackContext*>(ctx);
  auto lease = context->Acquire();
  if (!lease) return;

  MpvPlayer* player = lease.player();
  if (player->disposed_) return;

  bool expected = false;
  if (!player->needs_redraw_.compare_exchange_strong(expected, true)) {
    return;
  }

  // The redraw must run on the player's owning GLib context, never on mpv's
  // render/VO thread.
  player->ScheduleRedrawSource();
}

void MpvPlayer::DestroySourceCallbackData(gpointer data) { delete static_cast<SourceCallbackData*>(data); }

void MpvPlayer::ScheduleWakeupSource() {
  std::lock_guard<std::mutex> lock(source_mutex_);
  if (disposed_ || wakeup_source_id_ != 0) return;

  GSource* source = g_idle_source_new();
  g_source_set_priority(source, G_PRIORITY_HIGH_IDLE);
  auto* data = new SourceCallbackData(callback_context_);
  g_source_set_callback(source, DispatchWakeupSource, data, DestroySourceCallbackData);
  data->source_id = g_source_attach(source, callback_context_->main_context());
  wakeup_source_id_ = data->source_id;
  g_source_unref(source);
}

void MpvPlayer::ScheduleRedrawSource() {
  std::lock_guard<std::mutex> lock(source_mutex_);
  if (disposed_ || redraw_source_id_ != 0) return;

  GSource* source = g_idle_source_new();
  auto* data = new SourceCallbackData(callback_context_);
  g_source_set_callback(source, DispatchRedrawSource, data, DestroySourceCallbackData);
  data->source_id = g_source_attach(source, callback_context_->main_context());
  redraw_source_id_ = data->source_id;
  g_source_unref(source);

  if (redraw_source_id_ == 0) {
    needs_redraw_ = false;
  }
}

void MpvPlayer::ScheduleRecoverySource() {
  std::lock_guard<std::mutex> lock(source_mutex_);
  if (disposed_ || recovery_source_id_ != 0) return;

  GSource* source = g_timeout_source_new(100);
  auto* data = new SourceCallbackData(callback_context_);
  g_source_set_callback(source, DispatchRecoverySource, data, DestroySourceCallbackData);
  data->source_id = g_source_attach(source, callback_context_->main_context());
  recovery_source_id_ = data->source_id;
  g_source_unref(source);
}

gboolean MpvPlayer::DispatchWakeupSource(gpointer data) {
  auto* source_data = static_cast<SourceCallbackData*>(data);
  auto lease = source_data->context->Acquire();
  if (!lease) return G_SOURCE_REMOVE;

  MpvPlayer* player = lease.player();
  {
    std::lock_guard<std::mutex> lock(player->source_mutex_);
    if (player->wakeup_source_id_ == source_data->source_id) {
      player->wakeup_source_id_ = 0;
    }
  }
  if (!player->disposed_ && player->mpv_) {
    player->ProcessEvents();
  }
  return G_SOURCE_REMOVE;
}

gboolean MpvPlayer::DispatchRedrawSource(gpointer data) {
  auto* source_data = static_cast<SourceCallbackData*>(data);
  auto lease = source_data->context->Acquire();
  if (!lease) return G_SOURCE_REMOVE;

  MpvPlayer* player = lease.player();
  {
    std::lock_guard<std::mutex> lock(player->source_mutex_);
    if (player->redraw_source_id_ == source_data->source_id) {
      player->redraw_source_id_ = 0;
    }
  }
  if (player->disposed_) return G_SOURCE_REMOVE;

  RedrawCallback callback;
  {
    std::lock_guard<std::mutex> lock(player->callback_mutex_);
    callback = player->redraw_callback_;
  }
  if (callback) callback();
  return G_SOURCE_REMOVE;
}

gboolean MpvPlayer::DispatchRecoverySource(gpointer data) {
  auto* source_data = static_cast<SourceCallbackData*>(data);
  auto lease = source_data->context->Acquire();
  if (!lease) return G_SOURCE_REMOVE;

  MpvPlayer* player = lease.player();
  if (player->disposed_) return G_SOURCE_REMOVE;

  player->MaybeRunAudioRecovery();
  if (player->audio_recovery_.HasPendingWork()) {
    return G_SOURCE_CONTINUE;
  }

  std::lock_guard<std::mutex> lock(player->source_mutex_);
  if (player->recovery_source_id_ == source_data->source_id) {
    player->recovery_source_id_ = 0;
  }
  return G_SOURCE_REMOVE;
}

void MpvPlayer::RemoveTrackedSources() {
  std::lock_guard<std::mutex> lock(source_mutex_);
  GMainContext* context = callback_context_->main_context();
  auto remove = [context](guint& source_id) {
    if (source_id == 0) return;
    GSource* source = g_main_context_find_source_by_id(context, source_id);
    if (source) g_source_destroy(source);
    source_id = 0;
  };
  remove(wakeup_source_id_);
  remove(redraw_source_id_);
  remove(recovery_source_id_);
}

bool MpvPlayer::ProcessEvents() {
  if (disposed_ || !mpv_) return false;

  while (true) {
    mpv_event* event = mpv_wait_event(mpv_, 0);
    if (event->event_id == MPV_EVENT_NONE) {
      break;
    }
    if (event->event_id == MPV_EVENT_SHUTDOWN) {
      return false;
    }
    HandleMpvEvent(event);
  }
  return true;
}

void MpvPlayer::LogRecovery(const std::string& text) {
  g_warning("MPV audio-recovery: %s", text.c_str());
  FlValue* data = fl_value_new_map();
  fl_value_set_string_take(data, "prefix", fl_value_new_string("audio-recovery"));
  fl_value_set_string_take(data, "level", fl_value_new_string("warn"));
  fl_value_set_string_take(data, "text", fl_value_new_string(text.c_str()));
  SendEvent("log-message", data);
  fl_value_unref(data);
}

void MpvPlayer::TryAudioReload(const char* reason, int attempt, uint64_t request_generation) {
  LogRecovery("issuing ao-reload (reason=" + std::string(reason) + ", attempt " + std::to_string(attempt) + ")");
  const std::string reason_copy = reason;
  auto callback_context = callback_context_;
  CommandAsync({"ao-reload"}, [callback_context, reason_copy, attempt, request_generation](int error, const mpv_node*) {
    auto lease = callback_context->Acquire();
    if (!lease) return;
    MpvPlayer* player = lease.player();
    player->audio_recovery_.CompleteReload(request_generation);
    player->LogRecovery(
        "ao-reload completed (reason=" + reason_copy + ", attempt " + std::to_string(attempt) +
        ", error=" + std::to_string(error) + ")");
  });
}

void MpvPlayer::MaybeRunAudioRecovery() {
  const auto action = audio_recovery_.NextReload(plezy::mpv_common::AudioRecoveryState::Clock::now());
  if (action.reason == plezy::mpv_common::AudioReloadReason::kNone) {
    return;
  }
  const char* reason = action.reason == plezy::mpv_common::AudioReloadReason::kResume ? "resume" : "null-fallback";
  TryAudioReload(reason, action.attempt, action.request_generation);
  if (action.exhausted) {
    LogRecovery("audio recovery budget exhausted; waiting for device list change");
  }
}

void MpvPlayer::EnsureAudioRecoveryTimer() {
  if (!audio_recovery_.HasPendingWork()) return;
  ScheduleRecoverySource();
}

void MpvPlayer::HandleMpvEvent(mpv_event* event) {
  if (plezy::mpv_common::DispatchReplyEvent(
          pending_requests_, event, [](const char* value) { return SanitizeUtf8(value); })) {
    return;
  }

  switch (event->event_id) {
    case MPV_EVENT_LOG_MESSAGE: {
      auto* msg = static_cast<mpv_event_log_message*>(event->data);
      if (!msg) break;
      g_message("MPV [%s] %s: %s", msg->level, msg->prefix, msg->text);

      FlValue* data = fl_value_new_map();
      fl_value_set_string_take(data, "prefix", fl_value_new_string(SanitizeUtf8(msg->prefix).c_str()));
      fl_value_set_string_take(data, "level", fl_value_new_string(SanitizeUtf8(msg->level).c_str()));
      fl_value_set_string_take(data, "text", fl_value_new_string(SanitizeUtf8(msg->text).c_str()));
      SendEvent("log-message", data);
      fl_value_unref(data);
      break;
    }
    case MPV_EVENT_PROPERTY_CHANGE: {
      auto* prop = static_cast<mpv_event_property*>(event->data);
      if (!prop || !prop->name) break;
      mpv_node node = plezy::mpv_common::ExtractPropertyNode(prop);

      // This runner's own observation, which nothing on the Dart side asked
      // for and nothing there is waiting on. mpv delivers one event per
      // observation, so a Dart-side observer of the same property still gets
      // its own under its own userdata.
      if (event->reply_userdata == kVideoParamsUserdata) {
        UpdateSourceHdrMetadata(&node);
        break;
      }
      if (event->reply_userdata == kHwdecCurrentUserdata) {
        const char* value = node.format == MPV_FORMAT_STRING ? node.u.string : nullptr;
        g_message("MPV: hwdec-current=%s", value && value[0] != '\0' ? value : "(none)");
        break;
      }

      const auto notice = plezy::mpv_common::ObserveAudioRecoveryProperty(audio_recovery_, event, prop);
      if (notice.message) LogRecovery(notice.message);
      // Recovery runs off a GLib timer here, so newly queued work has to arm it.
      if (notice.scheduled_work) EnsureAudioRecoveryTimer();

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
      audio_recovery_.SetFileLoaded(false);
      // Whatever comes next is a different source until video-params says
      // otherwise, and describing it against this one's colour space is the
      // one failure worth a transient wrong answer to avoid. No re-apply is
      // requested: the plane keeps the description it has until the next
      // playback-restart or video-params change, exactly as before.
      {
        std::lock_guard<std::mutex> lock(native_mutex_);
        source_hdr_metadata_ = SourceHdrMetadata();
      }
      FlushPendingRestartPositions();
      auto* end = static_cast<mpv_event_end_file*>(event->data);
      if (!end) break;
      FlValue* data = fl_value_new_map();
      fl_value_set_string_take(data, "sourceId", fl_value_new_int(end->playlist_entry_id));
      fl_value_set_string_take(data, "reason", fl_value_new_int(static_cast<int>(end->reason)));
      if (end->reason == MPV_END_FILE_REASON_ERROR) {
        fl_value_set_string_take(data, "error", fl_value_new_int(static_cast<int>(end->error)));
        fl_value_set_string_take(
            data, "message", fl_value_new_string(SanitizeUtf8(mpv_error_string(end->error)).c_str()));
      }
      SendEvent("end-file", data);
      fl_value_unref(data);
      break;
    }
    case MPV_EVENT_START_FILE: {
      auto* start = static_cast<mpv_event_start_file*>(event->data);
      if (!start) break;
      FlushPendingRestartPositions();
      active_source_id_ = start->playlist_entry_id;
      has_active_source_id_ = true;
      SendActiveSourceEvent("start-file");
      break;
    }
    case MPV_EVENT_FILE_LOADED: {
      audio_recovery_.SetFileLoaded(true);
      EnsureAudioRecoveryTimer();
      SendActiveSourceEvent("file-loaded");
      break;
    }
    case MPV_EVENT_PLAYBACK_RESTART: {
      // The position is asked for, not read: a synchronous read hands the
      // request to the core and parks the GTK main thread on the playloop — the
      // thread the core's render path is itself waiting on (see the video-params
      // note in Initialize) — so the envelope follows the reply instead. The
      // source is captured now so a boundary crossed in the meantime cannot
      // relabel it; the epoch lets that boundary retire the reply after
      // delivering the restart itself position-less.
      const bool has_source_id = has_active_source_id_;
      const int64_t source_id = active_source_id_;
      const uint64_t epoch = restart_epoch_;
      auto on_position = [this, has_source_id, source_id, epoch](int error, const std::string& value) {
        if (disposed_ || epoch != restart_epoch_) return;
        --pending_restart_positions_;
        double seconds = 0.0;
        const bool has_position = error >= 0 && ParseSeconds(value, &seconds);
        SendPlaybackRestartEvent(has_source_id, source_id, has_position ? &seconds : nullptr);
      };
#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
      if (test_property_read_) {
        ++pending_restart_positions_;
        test_property_read_("time-pos", std::move(on_position));
        break;
      }
#endif
      if (!mpv_) {
        SendPlaybackRestartEvent(has_source_id, source_id, nullptr);
        break;
      }
      ++pending_restart_positions_;
      plezy::mpv_common::SubmitGetPropertyAsync(mpv_, pending_requests_, "time-pos", std::move(on_position));
      break;
    }
    default:
      break;
  }
}

namespace {

// Adapts the shared, bounded mpv_node walk onto GLib-owned FlValues.
struct FlValueNodeBuilder {
  using Value = FlValue*;
  using ListBuilder = FlValue*;
  using MapBuilder = FlValue*;

  static Value Null() { return fl_value_new_null(); }
  static Value Boolean(bool value) { return fl_value_new_bool(value); }
  static Value Int(int64_t value) { return fl_value_new_int(value); }
  static Value Double(double value) { return fl_value_new_float(value); }
  static Value String(const char* value, size_t length) {
    return fl_value_new_string(SanitizeUtf8(value, length).c_str());
  }

  static ListBuilder NewList() { return fl_value_new_list(); }
  static void Append(ListBuilder& list, Value value) { fl_value_append_take(list, value); }
  static Value FinishList(ListBuilder list) { return list; }

  static MapBuilder NewMap() { return fl_value_new_map(); }
  static void Insert(MapBuilder& map, const char* key, size_t key_length, Value value) {
    fl_value_set_string_take(map, SanitizeUtf8(key, key_length).c_str(), value);
  }
  static Value FinishMap(MapBuilder map) { return map; }
  static void AbandonMap(MapBuilder& map) { fl_value_unref(map); }
};

}  // namespace

FlValue* MpvPlayer::NodeToFlValue(mpv_node* node) { return plezy::mpv_common::ConvertNode<FlValueNodeBuilder>(node); }

FlValue* MpvPlayer::NodeToFlValue(mpv_node* node, plezy::mpv_common::NodeConversionBudget* budget) {
  return plezy::mpv_common::ConvertNode<FlValueNodeBuilder>(node, 0, budget);
}

void MpvPlayer::SendPropertyChange(const char* name, mpv_node* data) {
  if (!name) return;

  int id = 0;
  if (!observed_properties_.LookupId(name, &id)) return;

  FlValue* list = fl_value_new_list();
  fl_value_append_take(list, fl_value_new_int(id));
  if (data) {
    fl_value_append_take(list, NodeToFlValue(data));
  } else {
    fl_value_append_take(list, fl_value_new_null());
  }
  if (has_active_source_id_) {
    fl_value_append_take(list, fl_value_new_int(active_source_id_));
  } else {
    fl_value_append_take(list, fl_value_new_null());
  }

  EventCallback callback;
  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    callback = event_callback_;
  }
  if (callback) callback(list);
  fl_value_unref(list);
}

void MpvPlayer::SendActiveSourceEvent(const std::string& name) {
  FlValue* data = nullptr;
  if (has_active_source_id_) {
    data = fl_value_new_map();
    fl_value_set_string_take(data, "sourceId", fl_value_new_int(active_source_id_));
  }
  SendEvent(name, data);
  if (data) fl_value_unref(data);
}

void MpvPlayer::SendPlaybackRestartEvent(bool has_source_id, int64_t source_id, const double* position_seconds) {
  const bool has_position = position_seconds && std::isfinite(*position_seconds);
  FlValue* data = nullptr;
  if (has_source_id || has_position) {
    data = fl_value_new_map();
    if (has_source_id) {
      fl_value_set_string_take(data, "sourceId", fl_value_new_int(source_id));
    }
    if (has_position) {
      fl_value_set_string_take(data, "positionSeconds", fl_value_new_float(*position_seconds));
    }
  }
  SendEvent("playback-restart", data);
  if (data) fl_value_unref(data);
}

void MpvPlayer::FlushPendingRestartPositions() {
  // Every pending restart was dequeued under the source that is now ending, so
  // the active source is the one each of them captured.
  for (; pending_restart_positions_ > 0; --pending_restart_positions_) {
    SendPlaybackRestartEvent(has_active_source_id_, active_source_id_, nullptr);
  }
  ++restart_epoch_;
}

void MpvPlayer::SendEvent(const std::string& name, FlValue* data) {
  FlValue* event_map = fl_value_new_map();
  fl_value_set_string_take(event_map, "type", fl_value_new_string("event"));
  fl_value_set_string_take(event_map, "name", fl_value_new_string(name.c_str()));
  if (data) {
    fl_value_set_string_take(event_map, "data", fl_value_ref(data));
  }

  EventCallback callback;
  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    callback = event_callback_;
  }
  if (callback) callback(event_map);
  fl_value_unref(event_map);
}

void MpvPlayer::ApplyPropertySequence(
    std::shared_ptr<std::vector<PropertyChange>> changes, size_t index, StatusCallback callback) {
  if (changes == nullptr || index >= changes->size()) {
    if (callback) callback(MPV_ERROR_SUCCESS);
    return;
  }
  const PropertyChange& change = (*changes)[index];
  SetPropertyAsync(change.name, change.value, [this, changes, index, cb = std::move(callback)](int error) mutable {
    if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
      ApplyPropertySequence(changes, index + 1, std::move(cb));
      return;
    }
    // `index` entries already landed and must come back, newest
    // first, so a refused change leaves the previous state intact
    // rather than a half-applied mixture of the two.
    RollbackPropertySequence(changes, index, error, std::move(cb));
  });
}

void MpvPlayer::RollbackPropertySequence(
    std::shared_ptr<std::vector<PropertyChange>> changes, size_t undo_count, int failure, StatusCallback callback) {
  if (changes == nullptr || undo_count == 0) {
    // Only now is mpv genuinely back where it started, so only now may the caller
    // hear about it. The original failure is what it needs, not the outcome of the
    // unwinding.
    if (callback) callback(failure);
    return;
  }
  const size_t index = undo_count - 1;
  const PropertyChange& change = (*changes)[index];
  SetPropertyAsync(
      change.name, change.rollback, [this, changes, index, failure, cb = std::move(callback)](int error) mutable {
        if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
          RollbackPropertySequence(changes, index, failure, std::move(cb));
          return;
        }
        // Carrying on would leave mpv in a state that is neither the
        // old one nor the new, and *no* surface description is correct
        // for a signal nobody can name. Escalate to the one state that
        // is always describable and always accepts its value: SDR.
        g_warning(
            "MPV: could not restore %s while unwinding a refused output colour space; "
            "forcing SDR",
            (*changes)[index].name.c_str());
        ForceSdrOutput(0, failure, std::move(cb));
      });
}

// The one place the applied-output cache is written, so every path that moves a
// property records it the same way. Matched by name, not position: the order the
// sequences use is load-bearing and has to stay free to change without silently
// reassigning the wrong field.
void MpvPlayer::RecordAppliedOutputProperty(const std::string& name, const std::string& value) {
  if (name == "target-peak") {
    applied_target_peak_ = value;
  } else if (name == "target-prim") {
    applied_target_prim_ = value;
  } else if (name == "target-trc") {
    applied_target_trc_ = value;
  } else if (name == "tone-mapping") {
    applied_tone_mapping_ = value;
  }
}

void MpvPlayer::ForceSdrOutput(size_t index, int failure, StatusCallback callback) {
  // Same order the apply path uses: the transfer function stops asking for HDR
  // before the primaries, operator and peak follow it back.
  static const char* const kResetOrder[] = {"target-trc", "target-prim", "tone-mapping", "target-peak"};
  constexpr size_t kResetCount = sizeof(kResetOrder) / sizeof(kResetOrder[0]);
  if (index >= kResetCount) {
    // mpv is SDR now, not back where it started, so any HDR description the
    // caller has already committed is a lie about these pixels.
    hdr_unwind_result_ = HdrOutputResult::kForcedSdr;
    output_state_known_ = true;
    if (callback) callback(failure);
    return;
  }
  SetPropertyAsync(kResetOrder[index], "auto", [this, index, failure, cb = std::move(callback)](int error) mutable {
    if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
      // Recorded as it lands, not once the whole reset is through. Recording
      // only at the end would leave the cache naming the pre-reset curve for
      // every property that did move if a later one is refused, and the no-op
      // short-circuit would then answer a repeat request from it - committing an
      // HDR description over pixels mpv had already reset to SDR.
      RecordAppliedOutputProperty(kResetOrder[index], "auto");
      ForceSdrOutput(index + 1, failure, std::move(cb));
      return;
    }
    // `auto` is valid for every one of them, so this failing means mpv is
    // no longer taking orders at all - usually because it is being
    // disposed. Either way what it emits is now unknowable, and the
    // caller must stop presenting the plane rather than guess.
    hdr_unwind_result_ = HdrOutputResult::kUnknown;
    // And the cache is now a record of what we *asked* for, not what mpv holds:
    // some of the reset landed and some did not. Marking it untrusted is what
    // stops the short-circuit skipping a later write on the strength of it. The
    // strings are left alone deliberately - they are still the best rollback
    // targets available if a later sequence gets that far.
    output_state_known_ = false;
    g_warning(
        "MPV: output colour space is no longer commandable; what the plane emits "
        "is unknown");
    if (cb) cb(failure);
  });
}

bool MpvPlayer::CanCommandOutputProperties() const {
#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
  // The substituted writer is the core here; see SetPropertyAsync, which routes
  // to it ahead of the same handle check.
  if (test_property_write_) return true;
#endif
  return !disposed_ && mpv_ != nullptr;
}

#ifdef PLEZY_MPV_PLAYER_LIFECYCLE_TEST
void MpvPlayer::ConfigurePropertyWritesForTesting(PropertyWriteForTesting writer) {
  test_property_write_ = std::move(writer);
}

void MpvPlayer::ConfigurePropertyReadsForTesting(PropertyReadForTesting reader) {
  test_property_read_ = std::move(reader);
}

MpvPlayer::AppliedOutputColourSpace MpvPlayer::AppliedOutputColourSpaceForTesting() const {
  return {applied_target_trc_, applied_target_prim_, applied_tone_mapping_, applied_target_peak_};
}
#endif

void MpvPlayer::SetHdrOutput(SourceTransfer transfer, uint32_t target_peak_nits, HdrOutputCallback callback) {
  if (!CanCommandOutputProperties()) {
    // The third place a result is named, and it owes the same honesty as the
    // other two: nothing was touched, so the previous state stands - which is
    // only worth saying when that state is nameable. Otherwise a request that
    // was already queued when the core went away is answered kUnknown by the
    // drain while an identical one arriving a moment later hears kRestored.
    if (callback) {
      callback(output_state_known_ ? HdrOutputResult::kRestored : HdrOutputResult::kUnknown, MPV_ERROR_UNINITIALIZED);
    }
    return;
  }
  // Requests are serialized, and queued rather than coalesced.
  //
  // Playback restarts, preferred-description changes and the two settings can
  // each ask for a new output colour space, and every step of a sequence
  // completes asynchronously. Two overlapping sequences would interleave: a
  // failure in the older one would issue rollbacks that overwrite properties the
  // newer one had already set, while the newer one still reported success and
  // recorded values mpv no longer holds. That is the divergence the sequencing
  // exists to prevent.
  //
  // Each request keeps its own callback instead of being folded into the newest
  // one, because callers commit their own state on success: telling a caller its
  // change landed when a *different* request is what actually landed reintroduces
  // the same divergence one level up. Strict ordering then makes the bookkeeping
  // trivial — the last request to succeed is exactly what mpv holds, so nobody
  // needs an epoch to work out whether their commit is still current.
  hdr_queue_.push_back(HdrOutputRequest{transfer, target_peak_nits, std::move(callback)});
  if (hdr_sequence_in_flight_) return;
  RunPendingHdrOutput();
}

void MpvPlayer::RunPendingHdrOutput() {
  if (!CanCommandOutputProperties()) {
    hdr_sequence_in_flight_ = false;
    auto orphaned = std::move(hdr_queue_);
    hdr_queue_.clear();
    for (auto& request : orphaned) {
      // Nothing was touched, so the previous state - whatever it was - still
      // stands as far as this request is concerned. Which is only worth telling
      // the caller when that state is nameable; if the last unwind gave up
      // halfway, "unchanged" describes a colour space nobody knows.
      if (request.callback) {
        request.callback(
            output_state_known_ ? HdrOutputResult::kRestored : HdrOutputResult::kUnknown, MPV_ERROR_UNINITIALIZED);
      }
    }
    return;
  }
  if (hdr_queue_.empty()) {
    hdr_sequence_in_flight_ = false;
    return;
  }
  HdrOutputRequest request = std::move(hdr_queue_.front());
  hdr_queue_.pop_front();
  hdr_sequence_in_flight_ = true;
  // Assume a clean unwind; the escalation path in RollbackPropertySequence and
  // ForceSdrOutput moves this on if it cannot manage one.
  hdr_unwind_result_ = HdrOutputResult::kRestored;

  // Four properties describe one output colour space, so they are applied as a
  // unit. A plane whose primaries moved to BT.2020 while its transfer function
  // stayed on gamma is neither SDR nor HDR, and the caller describes the surface
  // to the compositor on success — a silently half-applied set would have the
  // compositor told one thing and shown another.
  //
  // target-peak is what mpv maps to. Under PQ, left on auto it resolves to the
  // format's nominal 10000 nits, so the renderer never tone-maps and the
  // compositor owns the decision. Set to the display's real peak, mpv tone-maps
  // to it and the caller declares that same peak, leaving the compositor nothing
  // to do.
  //
  // On the SDR fallback the peak and curve are named for accuracy, not to make
  // tone mapping happen: mpv 0.40 already resolves target-peak=auto to 203 nits
  // and target-trc=auto to gamma 2.2 for an SDR curve, and measurement confirmed
  // naming them changed the shadows but not the highlights. What they buy is the
  // surface's real terms instead of assumed ones - the compositor's own reference
  // white, and sRGB, which is what an undescribed Wayland surface is and what
  // this compositor's preferred description for the output says. Hence no
  // `enabled` in the peak condition below: an SDR peak is a real instruction, not
  // a leftover from an HDR request.
  const bool enabled = request.transfer != SourceTransfer::kSdr;
  const char* primaries = enabled ? "bt.2020" : "auto";
  // The option is an integer in [10, 10000]; anything outside means "auto".
  const bool tone_map_here = request.peak_nits >= 10 && request.peak_nits <= kPqMaxLuminanceNits;
  const std::string peak = tone_map_here ? std::to_string(request.peak_nits) : std::string("auto");
  const char* curve = request.transfer == SourceTransfer::kHlg
                          ? "hlg"
                          : (request.transfer == SourceTransfer::kPq ? "pq" : (tone_map_here ? "srgb" : "auto"));

  // The operator only matters while a tone-map pass runs, and it must go back to
  // auto when one does not; see applied_tone_mapping_ in mpv_player.h.
  //
  // Restricted to the undescribed SDR target, which is where it was measured.
  // Player-side mapping onto an HDR output aims at a PQ target instead, and
  // nothing has been measured there yet - that needs the external display - so
  // it keeps mpv's own choice until it can be judged the same way.
  //
  // mobius's shape is governed by tone-mapping-param, its transition point: below
  // it the curve is 1:1, above it rolls off. Left at mpv's default 0.3 because
  // that measured best, not by omission. Raising it trades highlight shoulder for
  // in-range luminance, and against libplacebo's rendering of the same chart
  // (400/700/1000 -> 238.5/253.8/254.8, 100 nits -> 134.0) the default is closest
  // on both counts, with higher values moving away on each:
  //
  //   param   100 nits   400->1000 span
  //   0.30     179.0      17.1
  //   0.45     184.4      12.1
  //   0.60     185.0       7.2
  //
  // It also does not touch the cost this operator carries. On real 1000-nit
  // footage mobius sits 0.027 dxy and ~12% darker than BT.2390 whatever the
  // transition point is (0.30/0.38/0.45 measured identical), because that
  // difference is gamut handling rather than the tone curve, and a dark scene's
  // pixels fall below the transition point in every case.
  //
  // Not pinned explicitly: the option has no accepted "unset" token - `default`
  // is rejected - so writing it would leave a mobius-specific value applied to
  // whatever operator runs next, including BT.2390 on the unmeasured HDR-output
  // path. Recorded here instead so an upstream default change is diagnosable.
  const char* operator_name = (tone_map_here && !enabled) ? "mobius" : "auto";

  // playback-restart drives a re-apply and fires on every seek, so most calls
  // here ask for the state mpv already holds. The plane's own half already
  // short-circuits an identical request; this is the other half. Without it a
  // seek costs four property round-trips and a log line saying nothing changed,
  // and holds the sequence long enough to defer a real request behind it.
  //
  // kApplied, because that is the truth the caller acts on: these four values
  // *are* in force, so a surface description committed against them stays
  // honest. The queue has to keep draining from here exactly as it does on the
  // applied path, or a coalesced request behind this one never runs. Unlike that
  // path the call is a real recursion rather than a fresh stack, which is fine
  // because the plugin coalesces reapplies into a single pending flag: the queue
  // holds the one in flight plus at most one waiting.
  // output_state_known_ first: the comparison is only meaningful while the cache
  // is a record of what mpv holds. A forced-SDR reset that was itself refused
  // partway leaves it a record of what was *asked* for, and skipping on that
  // would report kApplied for a colour space mpv is not in - which the caller
  // then commits an image description against.
  if (output_state_known_ && applied_target_trc_ == curve && applied_target_prim_ == primaries &&
      applied_tone_mapping_ == operator_name && applied_target_peak_ == peak) {
    if (request.callback) request.callback(HdrOutputResult::kApplied, 0);
    RunPendingHdrOutput();
    return;
  }

  // The values that decide who tone-maps and against what, none of which is
  // visible on screen: two very different curves both look like working video.
  // Logged next to the plane's own decisions so a capture can be matched to the
  // state that produced it.
  g_message(
      "MPV: output colour target peak=%s prim=%s trc=%s tone-mapping=%s", peak.c_str(), primaries, curve,
      operator_name);

  // Dependencies first, peak last, matching the order kResetOrder uses. The peak
  // is what decides whether a tone-map pass runs at all, so everything that pass
  // depends on is in place before it is named.
  auto changes = std::make_shared<std::vector<PropertyChange>>();
  changes->push_back({"target-trc", curve, applied_target_trc_});
  changes->push_back({"target-prim", primaries, applied_target_prim_});
  changes->push_back({"tone-mapping", operator_name, applied_tone_mapping_});
  changes->push_back({"target-peak", peak, applied_target_peak_});
  ApplyPropertySequence(changes, 0, [this, changes, callback = std::move(request.callback)](int error) {
    const bool ok = plezy::mpv_common::SetPropertyStatusSucceeded(error);
    // Only a fully applied set becomes the new rollback target; a failed one was
    // already unwound, and the unwinding updated these itself if it had to force
    // SDR.
    if (ok && !disposed_) {
      for (const PropertyChange& change : *changes) {
        RecordAppliedOutputProperty(change.name, change.value);
      }
      // A clean apply is the one outcome that leaves mpv exactly where the cache
      // says, so it is what re-earns the short-circuit's trust after an unwind
      // gave up halfway.
      output_state_known_ = true;
    }
    // This request's own outcome, to this request's own caller. The result names
    // what mpv is actually in now, which is what decides whether the caller's
    // committed surface description is still true.
    //
    // kRestored says "mpv is where it was", which only reassures the caller while
    // where it was is known. After an unwind that gave up halfway it is not: a
    // sequence refused on its very first write unwinds nothing, so it reports the
    // untouched kRestored while mpv sits in the half-reset state nobody can name.
    // The caller would read that as "your description still holds" and put an
    // undescribed plane back on screen. Downgrading to kUnknown is the honest
    // answer, and a clean apply - the one thing that re-earns the trust - is
    // reported as kApplied above regardless.
    const HdrOutputResult result =
        ok ? HdrOutputResult::kApplied : (output_state_known_ ? hdr_unwind_result_ : HdrOutputResult::kUnknown);
    if (callback) callback(result, error);
    // Whatever arrived while this ran runs now — never alongside.
    RunPendingHdrOutput();
  });
}

void MpvPlayer::SetHDREnabled(bool enabled, StatusCallback callback) {
  SetPropertyAsync(
      "target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(enabled),
      [this, enabled, callback = std::move(callback)](int error) mutable {
        if (plezy::mpv_common::SetPropertyStatusSucceeded(error) && !disposed_) {
          hdr_enabled_ = enabled;
        }
        if (callback) callback(error);
      });
}
}  // namespace mpv
