#include "mpv_player.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <flutter_linux/flutter_linux.h>
#include <gdk/gdk.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif
#include <locale.h>

#include <chrono>
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

bool TryReleaseRetainedNativeRenderContexts(
    std::vector<NativeRenderTeardownResource>& resources, const NativeRenderTeardownOperations& operations) {
  NativeRenderTeardownBatch batch;
  batch.resources = std::move(resources);
  const bool complete = TryReleaseNativeRenderTeardown(batch, operations);
  resources = std::move(batch.resources);
  return complete;
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

bool MpvPlayer::HasRenderContext() const {
  std::lock_guard<std::mutex> lock(native_mutex_);
  return mpv_gl_ != nullptr;
}

EGLDisplay MpvPlayer::GetEglDisplay() const {
  std::lock_guard<std::mutex> lock(native_mutex_);
  return egl_display_;
}

EGLContext MpvPlayer::GetEglContext() const {
  std::lock_guard<std::mutex> lock(native_mutex_);
  return egl_context_;
}

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

  if (audio_only_) {
    // Music core: no VO, no video decode. vid=no keeps embedded cover art
    // from ever becoming a video track, and force-window/audio-display make
    // sure mpv never opens a video output for it either.
    mpv_set_option_string(mpv_, "vid", "no");
    mpv_set_option_string(mpv_, "force-window", "no");
    mpv_set_option_string(mpv_, "audio-display", "no");
    mpv_set_option_string(mpv_, "gapless-audio", "weak");
  } else {
    // Configure mpv for embedded playback.
    mpv_set_option_string(mpv_, "vo", "libmpv");
    mpv_set_option_string(mpv_, "hwdec", "auto");
  }
  mpv_set_option_string(mpv_, "keep-open", "yes");
  mpv_set_option_string(mpv_, "audio-fallback-to-null", "yes");

  if (!audio_only_) {
    // HDR tone mapping
    mpv_set_option_string(mpv_, "tone-mapping", "auto");
    mpv_set_option_string(mpv_, "target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(hdr_enabled_));
    mpv_set_option_string(mpv_, "hdr-compute-peak", "auto");
  }
  mpv_set_option_string(mpv_, "idle", "yes");
  mpv_set_option_string(mpv_, "input-default-bindings", "no");
  mpv_set_option_string(mpv_, "input-vo-keyboard", "no");
  mpv_set_option_string(mpv_, "osc", "no");
  mpv_set_option_string(mpv_, "terminal", "no");

  // Default to warn-level logging
  mpv_request_log_messages(mpv_, "warn");

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

  g_message("MPV: Initialization successful (%s)", audio_only_ ? "audio-only" : "render context deferred");
  return true;
}

void MpvPlayer::RetryPendingNativeTeardown() { NativeRenderTeardownQueue::Instance().Retry(); }

bool MpvPlayer::InitRenderContext() {
  RetryPendingNativeTeardown();

  std::lock_guard<std::mutex> lock(native_mutex_);
  if (audio_only_ || disposed_) {
    g_warning("MPV: Render context requested for an unavailable player");
    return false;
  }
  if (mpv_gl_) return true;
  if (!mpv_) {
    g_warning("MPV: Cannot create render context - mpv not initialized");
    return false;
  }

  const EGLDisplay flutter_display = eglGetCurrentDisplay();
  const EGLContext flutter_context = eglGetCurrentContext();
  const EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  const EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
  const EGLenum previous_api = eglQueryAPI();
  if (flutter_display == EGL_NO_DISPLAY || flutter_context == EGL_NO_CONTEXT || previous_api == EGL_NONE) {
    g_warning("MPV: No EGL context available");
    return false;
  }

  auto restore_flutter = [&]() {
    const EGLBoolean api_restored = previous_api == EGL_NONE ? EGL_TRUE : eglBindAPI(previous_api);
    const EGLBoolean restored = api_restored == EGL_TRUE
                                    ? eglMakeCurrent(flutter_display, flutter_draw, flutter_read, flutter_context)
                                    : EGL_FALSE;
    return restored == EGL_TRUE && api_restored == EGL_TRUE;
  };
  if (!retained_render_contexts_.empty()) {
    const bool released =
        TryReleaseRetainedNativeRenderContexts(retained_render_contexts_, ProductionTeardownOperations());
    const bool flutter_restored = restore_flutter();
    if (!released) {
      g_warning("MPV: Retained render context still requires a later EGL teardown retry");
    }
    if (!flutter_restored) {
      g_warning("MPV: Failed to restore Flutter EGL state after retained teardown: 0x%x", eglGetError());
    }
    if (!released || !flutter_restored) return false;
  }

  EGLint config_id = 0;
  if (!eglQueryContext(flutter_display, flutter_context, EGL_CONFIG_ID, &config_id)) {
    g_warning("MPV: Failed to query Flutter EGL config: 0x%x", eglGetError());
    return false;
  }
  EGLConfig config = nullptr;
  EGLint num_configs = 0;
  const EGLint config_attribs[] = {EGL_CONFIG_ID, config_id, EGL_NONE};
  if (!eglChooseConfig(flutter_display, config_attribs, &config, 1, &num_configs) || num_configs != 1) {
    g_warning("MPV: Failed to select Flutter EGL config: 0x%x", eglGetError());
    return false;
  }
  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    g_warning("MPV: Failed to bind OpenGL ES API: 0x%x", eglGetError());
    return false;
  }

  const EGLint context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  EGLContext candidate_context = eglCreateContext(flutter_display, config, EGL_NO_CONTEXT, context_attribs);
  if (candidate_context == EGL_NO_CONTEXT) {
    g_warning("MPV: Failed to create isolated EGL context: 0x%x", eglGetError());
    if (previous_api != EGL_NONE && !eglBindAPI(previous_api)) {
      g_warning("MPV: Failed to restore EGL client API: 0x%x", eglGetError());
    }
    return false;
  }

  auto destroy_candidate_context = [&]() {
    const EGLenum api_before_cleanup = eglQueryAPI();
    if (eglGetCurrentContext() == candidate_context) {
      if (!eglBindAPI(EGL_OPENGL_ES_API) ||
          !eglMakeCurrent(flutter_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
        g_warning("MPV: Failed to release rejected EGL context: 0x%x", eglGetError());
        return;
      }
    }
    if (!eglDestroyContext(flutter_display, candidate_context)) {
      g_warning("MPV: Failed to destroy rejected EGL context: 0x%x", eglGetError());
    }
    if (api_before_cleanup != EGL_NONE && !eglBindAPI(api_before_cleanup)) {
      g_warning("MPV: Failed to restore EGL API after context cleanup: 0x%x", eglGetError());
    }
  };

  if (!eglMakeCurrent(flutter_display, EGL_NO_SURFACE, EGL_NO_SURFACE, candidate_context)) {
    g_warning("MPV: Failed to activate isolated EGL context: 0x%x", eglGetError());
    destroy_candidate_context();
    if (previous_api != EGL_NONE && !eglBindAPI(previous_api)) {
      g_warning("MPV: Failed to restore EGL client API: 0x%x", eglGetError());
    }
    return false;
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

  GdkDisplay* gdk_display = gdk_display_get_default();
#ifdef GDK_WINDOWING_WAYLAND
  if (GDK_IS_WAYLAND_DISPLAY(gdk_display)) {
    params[2].type = MPV_RENDER_PARAM_WL_DISPLAY;
    params[2].data = gdk_wayland_display_get_wl_display(gdk_display);
  }
#endif
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_DISPLAY(gdk_display)) {
    params[2].type = MPV_RENDER_PARAM_X11_DISPLAY;
    params[2].data = gdk_x11_display_get_xdisplay(gdk_display);
  }
#endif

  mpv_render_context* candidate_gl = nullptr;
  const int error = mpv_render_context_create(&candidate_gl, mpv_, params);
  const bool restored = restore_flutter();
  if (error < 0 || candidate_gl == nullptr || !restored) {
    if (error < 0) {
      g_warning("MPV: mpv_render_context_create() failed: %s", mpv_error_string(error));
    } else if (!restored) {
      g_warning("MPV: Failed to restore Flutter EGL state: 0x%x", eglGetError());
    } else {
      g_warning("MPV: mpv returned a null render context");
    }
    bool retained_candidate = false;
    if (candidate_gl) {
      if (eglMakeCurrent(flutter_display, EGL_NO_SURFACE, EGL_NO_SURFACE, candidate_context)) {
        mpv_render_context_free(candidate_gl);
      } else {
        g_warning("MPV: Failed to reactivate rejected EGL context: 0x%x; retaining it for teardown", eglGetError());
        retained_render_contexts_.push_back({candidate_gl, flutter_display, candidate_context});
        retained_candidate = true;
      }
      if (!restore_flutter()) {
        g_warning("MPV: Failed final Flutter EGL restoration: 0x%x", eglGetError());
      }
    }
    if (!retained_candidate) destroy_candidate_context();
    return false;
  }

  egl_display_ = flutter_display;
  egl_context_ = candidate_context;
  mpv_gl_ = candidate_gl;
  mpv_render_context_set_update_callback(mpv_gl_, OnMpvRenderUpdate, callback_context_.get());
  g_message("MPV: Render context created with isolated EGL context");
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
  }

  auto cancelled = pending_requests_.CancelAll();
  for (auto& callback : cancelled.status) {
    callback(MPV_ERROR_UNINITIALIZED);
  }
  for (auto& callback : cancelled.properties) {
    callback(-1, "");
  }

  RemoveTrackedSources();

  // Transfer every render/context pair and the shared mpv handle to the
  // managed teardown thread. A failed EGL bind leaves the complete pair in
  // the queue; the handle cannot be terminated until every pair is gone.
  NativeRenderTeardownBatch teardown;
  {
    std::lock_guard<std::mutex> lock(native_mutex_);
    teardown.resources = std::move(retained_render_contexts_);
    if (mpv_gl_ || egl_context_ != EGL_NO_CONTEXT) {
      teardown.resources.push_back({mpv_gl_, egl_display_, egl_context_});
    }
    teardown.handle = mpv_;
    teardown.callback_keep_alive = callback_context_;
    mpv_gl_ = nullptr;
    mpv_ = nullptr;
    egl_display_ = EGL_NO_DISPLAY;
    egl_context_ = EGL_NO_CONTEXT;
  }
  NativeRenderTeardownQueue::Instance().Enqueue(std::move(teardown));

  observed_properties_.Clear();
}

void MpvPlayer::Render(int width, int height, int fbo) {
  std::lock_guard<std::mutex> lock(native_mutex_);
  if (disposed_ || !mpv_gl_) return;

  mpv_opengl_fbo mpv_fbo{};
  mpv_fbo.fbo = fbo;
  mpv_fbo.w = width;
  mpv_fbo.h = height;
  mpv_fbo.internal_format = 0;

  int flip_y = 0;
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &mpv_fbo},
      {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };
  mpv_render_context_render(mpv_gl_, params);
}

void MpvPlayer::Command(const std::vector<std::string>& args) { CommandAsync(args, nullptr); }

void MpvPlayer::CommandAsync(const std::vector<std::string>& args, CommandCallback callback) {
  if (disposed_ || !mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED);
    return;
  }

  std::vector<const char*> c_args;
  c_args.reserve(args.size() + 1);
  for (const auto& arg : args) {
    c_args.push_back(arg.c_str());
  }
  c_args.push_back(nullptr);

  uint64_t request_id = callback ? pending_requests_.RegisterStatus(std::move(callback)) : 0;

  int result = mpv_command_async(mpv_, request_id, c_args.data());
  if (result < 0) {
    auto cb = pending_requests_.TakeStatus(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  SetPropertyAsync(name, value, nullptr);
}

void MpvPlayer::SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback) {
  if (disposed_ || !mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED);
    return;
  }

  if (name == "hdr-enabled") {
    SetHDREnabled(plezy::mpv_common::ParseEnabledFlag(value), std::move(callback));
    return;
  }

  if (name == "pause" && !plezy::mpv_common::ParseEnabledFlag(value)) {
    auto completion = std::move(callback);
    callback = [this, completion = std::move(completion)](int error) {
      if (error >= 0 && !disposed_) {
        audio_recovery_.RequestResume();
        EnsureAudioRecoveryTimer();
      }
      if (completion) completion(error);
    };
  }
  uint64_t request_id = callback ? pending_requests_.RegisterStatus(std::move(callback)) : 0;

  char* property_value = const_cast<char*>(value.c_str());
  int result = mpv_set_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING, &property_value);
  if (result < 0) {
    auto cb = pending_requests_.TakeStatus(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::GetPropertyAsync(const std::string& name, GetPropertyCallback callback) {
  if (disposed_ || !mpv_) {
    if (callback) callback(MPV_ERROR_UNINITIALIZED, "");
    return;
  }

  uint64_t request_id = pending_requests_.RegisterProperty(std::move(callback));

  int result = mpv_get_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING);
  if (result < 0) {
    auto cb = pending_requests_.TakeProperty(request_id);
    if (cb) cb(result, "");
  }
}

void MpvPlayer::ObserveProperty(const std::string& name, const std::string& format, int id) {
  if (disposed_ || !mpv_) return;

  const auto request = observed_properties_.Register(name, format, id);
  if (!request.added) return;
  mpv_observe_property(mpv_, request.userdata, name.c_str(), request.format);
}

void MpvPlayer::ReportMouseMove(int x, int y) {
  if (disposed_ || !mpv_) return;
  std::string x_str = std::to_string(x);
  std::string y_str = std::to_string(y);
  const char* args[] = {"mouse", x_str.c_str(), y_str.c_str(), nullptr};
  mpv_command_async(mpv_, 0, args);
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

  // Flutter texture notification must run on the player's owning GLib
  // context, never on mpv's render/VO thread.
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
  CommandAsync({"ao-reload"}, [callback_context, reason_copy, attempt, request_generation](int error) {
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
  switch (event->event_id) {
    case MPV_EVENT_COMMAND_REPLY:
    case MPV_EVENT_SET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      StatusCallback callback = pending_requests_.TakeStatus(request_id);
      if (callback) {
        callback(event->error);
      }
      break;
    }
    case MPV_EVENT_GET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      GetPropertyCallback callback = pending_requests_.TakeProperty(request_id);
      if (callback) {
        int error = event->error;
        std::string value;
        if (error >= 0) {
          auto* prop = static_cast<mpv_event_property*>(event->data);
          if (prop && prop->format == MPV_FORMAT_STRING && prop->data) {
            auto c_value = *static_cast<char**>(prop->data);
            if (c_value) value = SanitizeUtf8(c_value);
          }
        }
        callback(error, value);
      }
      break;
    }
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
      mpv_node node;
      node.format = prop->format;

      switch (prop->format) {
        case MPV_FORMAT_STRING:
          node.u.string = prop->data ? *static_cast<char**>(prop->data) : nullptr;
          break;
        case MPV_FORMAT_FLAG:
          node.u.flag = prop->data ? *static_cast<int*>(prop->data) : 0;
          break;
        case MPV_FORMAT_INT64:
          node.u.int64 = prop->data ? *static_cast<int64_t*>(prop->data) : 0;
          break;
        case MPV_FORMAT_DOUBLE:
          node.u.double_ = prop->data ? *static_cast<double*>(prop->data) : 0.0;
          break;
        case MPV_FORMAT_NODE:
          if (prop->data) {
            node = *static_cast<mpv_node*>(prop->data);
          } else {
            node.format = MPV_FORMAT_NONE;
          }
          break;
        default:
          node.format = MPV_FORMAT_NONE;
          break;
      }

      if (strcmp(prop->name, "current-ao") == 0) {
        const char* current_ao = nullptr;
        if (prop->format == MPV_FORMAT_STRING && prop->data) {
          current_ao = *static_cast<char**>(prop->data);
        }
        const bool is_null = current_ao && strcmp(current_ao, "null") == 0;
        const auto transition =
            audio_recovery_.SetCurrentAudioOutputNull(is_null, plezy::mpv_common::AudioRecoveryState::Clock::now());
        if (transition == plezy::mpv_common::AudioOutputTransition::kFellBackToNull) {
          LogRecovery("current-ao fell back to null; starting recovery");
          EnsureAudioRecoveryTimer();
        } else if (transition == plezy::mpv_common::AudioOutputTransition::kRecovered) {
          LogRecovery("audio recovered (current-ao no longer null)");
        }
      }
      if (strcmp(prop->name, "audio-device-list") == 0 && event->reply_userdata == 0 &&
          audio_recovery_.OnAudioDeviceListChanged(plezy::mpv_common::AudioRecoveryState::Clock::now())) {
        LogRecovery("audio-device-list changed while ao=null; rescheduling ao-reload");
        EnsureAudioRecoveryTimer();
      }

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
      audio_recovery_.SetFileLoaded(false);
      auto* end = static_cast<mpv_event_end_file*>(event->data);
      if (!end) break;
      FlValue* data = fl_value_new_map();
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
      SendEvent("start-file");
      break;
    }
    case MPV_EVENT_FILE_LOADED: {
      audio_recovery_.SetFileLoaded(true);
      EnsureAudioRecoveryTimer();
      SendEvent("file-loaded");
      break;
    }
    case MPV_EVENT_PLAYBACK_RESTART: {
      SendEvent("playback-restart");
      break;
    }
    default:
      break;
  }
}
FlValue* MpvPlayer::NodeToFlValue(mpv_node* node) {
  NodeConversionBudget budget{
      /*remaining_entries=*/16384,
      /*remaining_bytes=*/16 * 1024 * 1024,
  };
  return NodeToFlValue(node, 0, &budget);
}

bool MpvPlayer::ConvertNodeString(const char* input, NodeConversionBudget* budget, std::string* result) {
  if (!input || !budget || !result) return false;
  const size_t length = strnlen(input, budget->remaining_bytes + 1);
  if (length > budget->remaining_bytes) return false;
  budget->remaining_bytes -= length;
  *result = SanitizeUtf8(input, length);
  return true;
}

FlValue* MpvPlayer::NodeToFlValue(mpv_node* node, size_t depth, NodeConversionBudget* budget) {
  constexpr size_t kMaxNodeDepth = 32;
  constexpr int kMaxNodeEntries = 16384;
  if (!node || !budget || depth >= kMaxNodeDepth || budget->remaining_entries == 0) {
    return fl_value_new_null();
  }
  --budget->remaining_entries;

  switch (node->format) {
    case MPV_FORMAT_STRING: {
      std::string value;
      if (!ConvertNodeString(node->u.string, budget, &value)) return fl_value_new_null();
      return fl_value_new_string(value.c_str());
    }
    case MPV_FORMAT_FLAG:
      return fl_value_new_bool(node->u.flag != 0);
    case MPV_FORMAT_INT64:
      return fl_value_new_int(node->u.int64);
    case MPV_FORMAT_DOUBLE:
      return fl_value_new_float(node->u.double_);
    case MPV_FORMAT_NODE_ARRAY: {
      const mpv_node_list* list = node->u.list;
      if (!list || list->num < 0 || list->num > kMaxNodeEntries || (list->num > 0 && !list->values)) {
        return fl_value_new_null();
      }
      FlValue* result = fl_value_new_list();
      for (int i = 0; i < list->num; i++) {
        fl_value_append_take(result, NodeToFlValue(&list->values[i], depth + 1, budget));
      }
      return result;
    }
    case MPV_FORMAT_NODE_MAP: {
      const mpv_node_list* map = node->u.list;
      if (!map || map->num < 0 || map->num > kMaxNodeEntries || (map->num > 0 && (!map->keys || !map->values))) {
        return fl_value_new_null();
      }
      FlValue* result = fl_value_new_map();
      for (int i = 0; i < map->num; i++) {
        if (!map->keys[i]) {
          fl_value_unref(result);
          return fl_value_new_null();
        }
        std::string key;
        if (!ConvertNodeString(map->keys[i], budget, &key)) {
          fl_value_unref(result);
          return fl_value_new_null();
        }
        fl_value_set_string_take(result, key.c_str(), NodeToFlValue(&map->values[i], depth + 1, budget));
      }
      return result;
    }
    default:
      return fl_value_new_null();
  }
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

  EventCallback callback;
  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    callback = event_callback_;
  }
  if (callback) callback(list);
  fl_value_unref(list);
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
