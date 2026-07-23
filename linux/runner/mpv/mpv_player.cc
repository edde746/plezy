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
#include <clocale>

#include "sanitize_utf8.h"

// Flutter on Linux uses EGL (OpenGL ES) for both X11 and Wayland.
static void* get_opengl_proc_address(void* ctx, const char* name) {
  (void)ctx;
  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

namespace mpv {

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

void MpvPlayer::CallbackContext::DetachAndWait() {
  std::unique_lock<std::mutex> lock(mutex_);
  player_ = nullptr;
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

bool MpvPlayer::Initialize() {
  if (mpv_) {
    return true;  // Already initialized.
  }

  // MPV requires C locale for numeric formatting
  std::setlocale(LC_NUMERIC, "C");

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

bool MpvPlayer::InitRenderContext() {
  if (audio_only_) {
    g_warning("MPV: InitRenderContext called on an audio-only player");
    return false;
  }

  if (mpv_gl_) {
    return true;  // Already created.
  }

  if (!mpv_) {
    g_warning("MPV: Cannot create render context - mpv not initialized");
    return false;
  }

  // Capture Flutter's EGL display and create an isolated EGL context.
  // Flutter on Linux uses EGL for both X11 and Wayland.  Running mpv in
  // an isolated context prevents OpenGL state pollution between mpv and
  // Flutter, which caused corrupted/blank video on some drivers.
  EGLDisplay flutter_display = eglGetCurrentDisplay();
  EGLContext flutter_context = eglGetCurrentContext();

  if (flutter_display == EGL_NO_DISPLAY || flutter_context == EGL_NO_CONTEXT) {
    g_warning("MPV: No EGL context available");
    return false;
  }

  egl_display_ = flutter_display;

  // Query Flutter's EGL config and reuse it for compatibility
  EGLConfig config = nullptr;
  EGLint config_id = 0;

  if (!eglQueryContext(egl_display_, flutter_context, EGL_CONFIG_ID, &config_id)) {
    g_warning("MPV: Failed to query Flutter's EGL config ID");
    return false;
  }

  EGLint num_configs = 0;
  EGLint config_attribs[] = {EGL_CONFIG_ID, config_id, EGL_NONE};
  if (!eglChooseConfig(egl_display_, config_attribs, &config, 1, &num_configs) || num_configs == 0) {
    g_warning("MPV: Failed to get Flutter's EGL config");
    return false;
  }

  // Create isolated EGL context (NOT shared with Flutter) to prevent
  // GL state pollution
  eglBindAPI(EGL_OPENGL_ES_API);
  EGLint context_attribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      2,
      EGL_NONE,
  };
  egl_context_ = eglCreateContext(egl_display_, config, EGL_NO_CONTEXT, context_attribs);
  if (egl_context_ == EGL_NO_CONTEXT) {
    g_warning("MPV: Failed to create isolated EGL context: 0x%x", eglGetError());
    return false;
  }

  // Make the isolated context current for mpv render context creation
  EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
  eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context_);

  // Set up OpenGL parameters for mpv.
  mpv_opengl_init_params gl_init_params{
      .get_proc_address = get_opengl_proc_address,
      .get_proc_address_ctx = nullptr,
  };

  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_API_TYPE, const_cast<char*>(MPV_RENDER_API_TYPE_OPENGL)},
      {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
      {MPV_RENDER_PARAM_INVALID, nullptr},  // slot for X11/Wayland display
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  // Pass X11/Wayland display for VAAPI hardware acceleration
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

  int err = mpv_render_context_create(&mpv_gl_, mpv_, params);

  // Restore Flutter's context
  eglMakeCurrent(egl_display_, flutter_draw, flutter_read, flutter_context);

  if (err < 0) {
    g_warning("MPV: mpv_render_context_create() failed: %s", mpv_error_string(err));
    eglDestroyContext(egl_display_, egl_context_);
    egl_context_ = EGL_NO_CONTEXT;
    return false;
  }

  // Set up render update callback.
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
  if (mpv_gl_) {
    mpv_render_context_set_update_callback(mpv_gl_, nullptr, nullptr);
  }
  if (mpv_) {
    mpv_set_wakeup_callback(mpv_, nullptr, nullptr);
  }
  callback_context_->DetachAndWait();

  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    redraw_callback_ = nullptr;
    event_callback_ = nullptr;
  }

  auto cancelled = pending_requests_.CancelAll();
  for (auto& callback : cancelled.status) {
    callback(-1);
  }
  for (auto& callback : cancelled.properties) {
    callback(-1, "");
  }

  RemoveTrackedSources();

  // Native destruction remains off the main thread. Keeping the detached
  // callback context alive until both mpv objects are gone makes even a late
  // invocation through mpv's old context pointer harmless.
  auto* gl = mpv_gl_;
  auto* handle = mpv_;
  auto egl_display = egl_display_;
  auto egl_context = egl_context_;
  auto callback_context = callback_context_;
  mpv_gl_ = nullptr;
  mpv_ = nullptr;
  egl_display_ = EGL_NO_DISPLAY;
  egl_context_ = EGL_NO_CONTEXT;

  if (gl || handle || egl_context != EGL_NO_CONTEXT) {
    std::thread([gl, handle, egl_display, egl_context, callback_context]() {
      (void)callback_context;
      if (gl) {
        if (egl_context != EGL_NO_CONTEXT) {
          eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
        }
        mpv_render_context_free(gl);
      }
      if (handle) {
        mpv_terminate_destroy(handle);
      }
      if (egl_context != EGL_NO_CONTEXT) {
        eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(egl_display, egl_context);
      }
    }).detach();
  }

  observed_properties_.Clear();
}

void MpvPlayer::Render(int width, int height, int fbo) {
  if (disposed_ || !mpv_gl_) return;

  mpv_opengl_fbo mpv_fbo{
      .fbo = fbo,
      .w = width,
      .h = height,
      .internal_format = 0,
  };

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
    if (callback) callback(0);
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
    if (callback) callback(-1, "");
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

void MpvPlayer::TryAudioReload(const char* reason, int attempt) {
  LogRecovery("issuing ao-reload (reason=" + std::string(reason) + ", attempt " + std::to_string(attempt) + ")");
  const std::string reason_copy = reason;
  CommandAsync({"ao-reload"}, [this, reason_copy, attempt](int error) {
    audio_recovery_.CompleteReload();
    LogRecovery(
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
  TryAudioReload(reason, action.attempt);
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
        int error = event->error;
        g_idle_add(
            [](gpointer data) -> gboolean {
              auto* pair = static_cast<std::pair<CommandCallback, int>*>(data);
              if (pair->first) pair->first(pair->second);
              delete pair;
              return G_SOURCE_REMOVE;
            },
            new std::pair<CommandCallback, int>(std::move(callback), error));
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
        g_idle_add(
            [](gpointer data) -> gboolean {
              auto* tuple = static_cast<std::tuple<GetPropertyCallback, int, std::string>*>(data);
              const auto& callback = std::get<0>(*tuple);
              if (callback) callback(std::get<1>(*tuple), std::get<2>(*tuple));
              delete tuple;
              return G_SOURCE_REMOVE;
            },
            new std::tuple<GetPropertyCallback, int, std::string>(std::move(callback), error, std::move(value)));
      }
      break;
    }
    case MPV_EVENT_LOG_MESSAGE: {
      auto* msg = static_cast<mpv_event_log_message*>(event->data);
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
  if (!node) return fl_value_new_null();

  switch (node->format) {
    case MPV_FORMAT_STRING:
      return fl_value_new_string(SanitizeUtf8(node->u.string).c_str());
    case MPV_FORMAT_FLAG:
      return fl_value_new_bool(node->u.flag != 0);
    case MPV_FORMAT_INT64:
      return fl_value_new_int(node->u.int64);
    case MPV_FORMAT_DOUBLE:
      return fl_value_new_float(node->u.double_);
    case MPV_FORMAT_NODE_ARRAY: {
      FlValue* list = fl_value_new_list();
      for (int i = 0; i < node->u.list->num; i++) {
        fl_value_append_take(list, NodeToFlValue(&node->u.list->values[i]));
      }
      return list;
    }
    case MPV_FORMAT_NODE_MAP: {
      FlValue* map = fl_value_new_map();
      for (int i = 0; i < node->u.list->num; i++) {
        fl_value_set_string_take(map, node->u.list->keys[i], NodeToFlValue(&node->u.list->values[i]));
      }
      return map;
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

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(list);
  }
  fl_value_unref(list);
}

void MpvPlayer::SendEvent(const std::string& name, FlValue* data) {
  FlValue* event_map = fl_value_new_map();
  fl_value_set_string_take(event_map, "type", fl_value_new_string("event"));
  fl_value_set_string_take(event_map, "name", fl_value_new_string(name.c_str()));
  if (data) {
    fl_value_set_string_take(event_map, "data", fl_value_ref(data));
  }

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(event_map);
  }
  fl_value_unref(event_map);
}

void MpvPlayer::SetHDREnabled(bool enabled, StatusCallback callback) {
  hdr_enabled_ = enabled;
  if (!mpv_) {
    if (callback) callback(0);
    return;
  }
  SetPropertyAsync("target-colorspace-hint", plezy::mpv_common::TargetColorspaceHint(enabled), std::move(callback));
}
}  // namespace mpv
