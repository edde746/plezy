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

MpvPlayer::MpvPlayer() {}

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

  // Configure mpv for embedded playback.
  mpv_set_option_string(mpv_, "vo", "libmpv");
  mpv_set_option_string(mpv_, "hwdec", "auto");
  mpv_set_option_string(mpv_, "keep-open", "yes");

  // HDR tone mapping
  mpv_set_option_string(mpv_, "tone-mapping", "auto");
  mpv_set_option_string(mpv_, "target-colorspace-hint", "no");
  mpv_set_option_string(mpv_, "hdr-compute-peak", "auto");
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
  mpv_set_wakeup_callback(mpv_, OnMpvWakeup, this);

  g_message("MPV: Initialization successful (render context deferred)");
  return true;
}

bool MpvPlayer::InitRenderContext() {
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
  mpv_render_context_set_update_callback(mpv_gl_, OnMpvRenderUpdate, this);

  g_message("MPV: Render context created with isolated EGL context");
  return true;
}

void MpvPlayer::Dispose() {
  // 1. Set disposed flag atomically FIRST — all callback paths check this
  if (disposed_.exchange(true)) {
    return;
  }

  // 2. Clear mpv's native callbacks to prevent new ones from firing
  if (mpv_gl_) {
    mpv_render_context_set_update_callback(mpv_gl_, nullptr, nullptr);
  }
  if (mpv_) {
    mpv_set_wakeup_callback(mpv_, nullptr, nullptr);
  }

  // 3. Briefly hold mutex to null our callbacks
  {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    redraw_callback_ = nullptr;
    event_callback_ = nullptr;
  }

  // 4. Cancel pending async requests
  std::vector<StatusCallback> status_callbacks;
  std::vector<GetPropertyCallback> get_callbacks;
  {
    std::lock_guard<std::mutex> request_lock(pending_requests_mutex_);
    for (auto& pair : pending_status_requests_) {
      if (pair.second) status_callbacks.push_back(std::move(pair.second));
    }
    for (auto& pair : pending_get_property_requests_) {
      if (pair.second) get_callbacks.push_back(std::move(pair.second));
    }
    pending_status_requests_.clear();
    pending_get_property_requests_.clear();
  }
  for (auto& callback : status_callbacks) {
    callback(-1);
  }
  for (auto& callback : get_callbacks) {
    callback(-1, "");
  }

  // 5. Remove pending idle callbacks
  if (event_source_id_ != 0) {
    g_source_remove(event_source_id_);
    event_source_id_ = 0;
  }

  // 6. Free render context and mpv handle in a background thread.
  //    mpv_render_context_free() can block waiting for mpv's render/VO thread,
  //    and mpv_terminate_destroy() can block on demuxer/network I/O.
  //    Running these off the main thread prevents stalling the GLib main loop.
  auto* gl = mpv_gl_;
  auto* handle = mpv_;
  auto egl_display = egl_display_;
  auto egl_context = egl_context_;
  mpv_gl_ = nullptr;
  mpv_ = nullptr;
  egl_display_ = EGL_NO_DISPLAY;
  egl_context_ = EGL_NO_CONTEXT;

  std::thread([gl, handle, egl_display, egl_context]() {
    if (gl) {
      // mpv render context must be freed with its EGL context current
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

  observed_properties_.clear();
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

  uint64_t request_id = callback ? RegisterStatusRequest(std::move(callback)) : 0;

  int result = mpv_command_async(mpv_, request_id, c_args.data());
  if (result < 0) {
    auto cb = TakeStatusRequest(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  SetPropertyAsync(name, value, nullptr);
}

void MpvPlayer::SetPropertyAsync(const std::string& name, const std::string& value, StatusCallback callback) {
  if (disposed_ || !mpv_) {
    if (callback) callback(0);
    return;
  }

  uint64_t request_id = callback ? RegisterStatusRequest(std::move(callback)) : 0;

  char* property_value = const_cast<char*>(value.c_str());
  int result = mpv_set_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING, &property_value);
  if (result < 0) {
    auto cb = TakeStatusRequest(request_id);
    if (cb) cb(result);
  }
}

void MpvPlayer::GetPropertyAsync(const std::string& name, GetPropertyCallback callback) {
  if (disposed_ || !mpv_) {
    if (callback) callback(-1, "");
    return;
  }

  uint64_t request_id = RegisterGetPropertyRequest(std::move(callback));

  int result = mpv_get_property_async(mpv_, request_id, name.c_str(), MPV_FORMAT_STRING);
  if (result < 0) {
    auto cb = TakeGetPropertyRequest(request_id);
    if (cb) cb(result, "");
  }
}

uint64_t MpvPlayer::RegisterStatusRequest(StatusCallback callback) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  uint64_t request_id = next_reply_userdata_++;
  pending_status_requests_[request_id] = std::move(callback);
  return request_id;
}

MpvPlayer::StatusCallback MpvPlayer::TakeStatusRequest(uint64_t request_id) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  auto it = pending_status_requests_.find(request_id);
  if (it == pending_status_requests_.end()) return nullptr;
  auto callback = std::move(it->second);
  pending_status_requests_.erase(it);
  return callback;
}

uint64_t MpvPlayer::RegisterGetPropertyRequest(GetPropertyCallback callback) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  uint64_t request_id = next_reply_userdata_++;
  pending_get_property_requests_[request_id] = std::move(callback);
  return request_id;
}

MpvPlayer::GetPropertyCallback MpvPlayer::TakeGetPropertyRequest(uint64_t request_id) {
  std::lock_guard<std::mutex> lock(pending_requests_mutex_);
  auto it = pending_get_property_requests_.find(request_id);
  if (it == pending_get_property_requests_.end()) return nullptr;
  auto callback = std::move(it->second);
  pending_get_property_requests_.erase(it);
  return callback;
}

void MpvPlayer::ObserveProperty(const std::string& name, const std::string& format, int id) {
  if (disposed_ || !mpv_) return;

  if (observed_properties_.find(name) != observed_properties_.end()) {
    return;
  }

  name_to_id_[name] = id;

  mpv_format mpv_fmt = MPV_FORMAT_NONE;
  if (format == "string") {
    mpv_fmt = MPV_FORMAT_STRING;
  } else if (format == "flag" || format == "bool") {
    mpv_fmt = MPV_FORMAT_FLAG;
  } else if (format == "int64") {
    mpv_fmt = MPV_FORMAT_INT64;
  } else if (format == "double") {
    mpv_fmt = MPV_FORMAT_DOUBLE;
  } else if (format == "node") {
    mpv_fmt = MPV_FORMAT_NODE;
  }

  uint64_t userdata = next_reply_userdata_++;
  observed_properties_[name] = userdata;
  mpv_observe_property(mpv_, userdata, name.c_str(), mpv_fmt);
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
  auto* player = static_cast<MpvPlayer*>(ctx);

  if (player->disposed_) return;

  g_idle_add_full(
      G_PRIORITY_HIGH_IDLE,
      [](gpointer data) -> gboolean {
        auto* player = static_cast<MpvPlayer*>(data);

        if (!player->disposed_ && player->mpv_) {
          player->ProcessEvents();
        }
        return G_SOURCE_REMOVE;
      },
      player, nullptr);
}

void MpvPlayer::OnMpvRenderUpdate(void* ctx) {
  auto* player = static_cast<MpvPlayer*>(ctx);
  if (player->disposed_) return;

  bool expected = false;
  if (!player->needs_redraw_.compare_exchange_strong(expected, true)) {
    return;
  }

  // Schedule redraw on main thread. Calling Flutter's
  // fl_texture_registrar_mark_texture_frame_available directly from mpv's
  // render/VO thread can deadlock during disposal on Wayland: the main thread
  // blocks in mpv_render_context_free() waiting for the VO thread, while the
  // VO thread blocks in the Flutter registrar waiting for the main thread.
  g_idle_add(
      [](gpointer data) -> gboolean {
        auto* player = static_cast<MpvPlayer*>(data);
        if (player->disposed_) return G_SOURCE_REMOVE;

        std::lock_guard<std::mutex> lock(player->callback_mutex_);
        if (player->redraw_callback_) {
          player->redraw_callback_();
        }
        return G_SOURCE_REMOVE;
      },
      player);
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

void MpvPlayer::HandleMpvEvent(mpv_event* event) {
  switch (event->event_id) {
    case MPV_EVENT_COMMAND_REPLY:
    case MPV_EVENT_SET_PROPERTY_REPLY: {
      uint64_t request_id = event->reply_userdata;
      StatusCallback callback = TakeStatusRequest(request_id);
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
      GetPropertyCallback callback = TakeGetPropertyRequest(request_id);
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

      SendPropertyChange(prop->name, &node);
      break;
    }
    case MPV_EVENT_END_FILE: {
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
    case MPV_EVENT_FILE_LOADED: {
      SendEvent("file-loaded");
      break;
    }
    case MPV_EVENT_PLAYBACK_RESTART: {
      SendEvent("playback-restart");
      break;
    }
    case MPV_EVENT_SEEK: {
      SendEvent("seek");
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

  auto it = name_to_id_.find(name);
  if (it == name_to_id_.end()) return;

  FlValue* list = fl_value_new_list();
  fl_value_append_take(list, fl_value_new_int(it->second));
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

}  // namespace mpv
