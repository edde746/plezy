#include "mpv_player.h"

#include <flutter_linux/flutter_linux.h>
#include <epoxy/gl.h>
#include <epoxy/egl.h>
#include <epoxy/glx.h>
#include <gdk/gdk.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif
#include <clocale>
#include <cstring>
#include <string>

// Static helper to get proc address - must be defined outside the namespace
// to have the correct function signature.
static void* get_opengl_proc_address(void* ctx, const char* name) {
  (void)ctx;
#ifdef GDK_WINDOWING_WAYLAND
  // On Wayland, use EGL
  if (epoxy_has_egl()) {
    return reinterpret_cast<void*>(eglGetProcAddress(name));
  }
#endif
#ifdef GDK_WINDOWING_X11
  // On X11, use GLX
  return reinterpret_cast<void*>(glXGetProcAddressARB(
      reinterpret_cast<const GLubyte*>(name)));
#else
  // Fallback: try EGL
  return reinterpret_cast<void*>(eglGetProcAddress(name));
#endif
}

namespace mpv {

MpvPlayer::MpvPlayer() {}

MpvPlayer::~MpvPlayer() {
  Dispose();
}

bool MpvPlayer::Initialize(GtkGLArea* gl_area) {
  if (mpv_) {
    return true;  // Already initialized.
  }

  gl_area_ = gl_area;

  // Check if GL area is realized
  if (!gtk_widget_get_realized(GTK_WIDGET(gl_area))) {
    g_warning("MPV: GL area not realized yet");
    return false;
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
  mpv_set_option_string(mpv_, "vo", "libmpv");  // Render via mpv_render_context_render()
  mpv_set_option_string(mpv_, "hwdec", "auto");
  mpv_set_option_string(mpv_, "keep-open", "yes");
  mpv_set_option_string(mpv_, "idle", "yes");
  mpv_set_option_string(mpv_, "input-default-bindings", "no");
  mpv_set_option_string(mpv_, "input-vo-keyboard", "no");
  mpv_set_option_string(mpv_, "osc", "no");
  mpv_set_option_string(mpv_, "terminal", "no");

  // Enable verbose logging for debugging.
  mpv_request_log_messages(mpv_, "v");

  // Initialize mpv.
  int err = mpv_initialize(mpv_);
  if (err < 0) {
    g_warning("MPV: mpv_initialize() failed: %s", mpv_error_string(err));
    mpv_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // Make the GL context current.
  gtk_gl_area_make_current(gl_area_);
  if (gtk_gl_area_get_error(gl_area_) != nullptr) {
    g_warning("MPV: Failed to make GL context current");
    mpv_terminate_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // Set up OpenGL parameters for mpv.
  mpv_opengl_init_params gl_init_params{
      .get_proc_address = get_opengl_proc_address,
      .get_proc_address_ctx = nullptr,
  };

  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_API_TYPE,
       const_cast<char*>(MPV_RENDER_API_TYPE_OPENGL)},
      {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  err = mpv_render_context_create(&mpv_gl_, mpv_, params);
  if (err < 0) {
    g_warning("MPV: mpv_render_context_create() failed: %s",
              mpv_error_string(err));
    mpv_terminate_destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // Set up event wakeup callback.
  mpv_set_wakeup_callback(mpv_, OnMpvWakeup, this);

  // Set up render update callback.
  mpv_render_context_set_update_callback(mpv_gl_, OnMpvRenderUpdate, this);

  g_message("MPV: Initialization successful");
  return true;
}

void MpvPlayer::Dispose() {
  // Guard against multiple dispose calls (double-free protection)
  if (disposed_.exchange(true)) {
    return;  // Already disposed
  }

  // Clear mpv callbacks BEFORE freeing to prevent new callbacks being scheduled
  if (mpv_gl_) {
    mpv_render_context_set_update_callback(mpv_gl_, nullptr, nullptr);
  }
  if (mpv_) {
    mpv_set_wakeup_callback(mpv_, nullptr, nullptr);
  }

  // Remove pending idle callbacks
  if (event_source_id_ != 0) {
    g_source_remove(event_source_id_);
    event_source_id_ = 0;
  }

  // Now safe to free render context
  if (mpv_gl_) {
    mpv_render_context_free(mpv_gl_);
    mpv_gl_ = nullptr;
  }

  // And terminate mpv
  if (mpv_) {
    mpv_terminate_destroy(mpv_);
    mpv_ = nullptr;
  }

  observed_properties_.clear();
  gl_area_ = nullptr;
}

void MpvPlayer::Command(const std::vector<std::string>& args) {
  if (disposed_ || !mpv_) return;

  std::vector<const char*> c_args;
  c_args.reserve(args.size() + 1);
  for (const auto& arg : args) {
    c_args.push_back(arg.c_str());
  }
  c_args.push_back(nullptr);

  mpv_command(mpv_, c_args.data());
}

void MpvPlayer::SetProperty(const std::string& name, const std::string& value) {
  if (disposed_ || !mpv_) return;
  mpv_set_property_string(mpv_, name.c_str(), value.c_str());
}

std::string MpvPlayer::GetProperty(const std::string& name) {
  if (disposed_ || !mpv_) return "";

  char* value = mpv_get_property_string(mpv_, name.c_str());
  if (!value) return "";

  std::string result(value);
  mpv_free(value);
  return result;
}

void MpvPlayer::ObserveProperty(const std::string& name,
                                const std::string& format) {
  if (disposed_ || !mpv_) return;

  // Check if already observing.
  if (observed_properties_.find(name) != observed_properties_.end()) {
    return;
  }

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

void MpvPlayer::Render(int width, int height, int fbo) {
  if (disposed_ || !mpv_gl_) return;

  mpv_opengl_fbo mpv_fbo{
      .fbo = fbo,
      .w = width,
      .h = height,
      .internal_format = 0,
  };

  int flip_y = 1;

  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &mpv_fbo},
      {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  mpv_render_context_render(mpv_gl_, params);
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

void MpvPlayer::RequestRedraw() {
  if (disposed_) return;

  needs_redraw_.store(true);
  if (gl_area_) {
    // Queue redraw on main thread
    GtkGLArea* area = gl_area_;
    g_idle_add(
        [](gpointer data) -> gboolean {
          GtkGLArea* area = static_cast<GtkGLArea*>(data);
          if (GTK_IS_GL_AREA(area)) {
            gtk_gl_area_queue_render(area);
          }
          return G_SOURCE_REMOVE;
        },
        area);
  }
}

void MpvPlayer::OnMpvWakeup(void* ctx) {
  auto* player = static_cast<MpvPlayer*>(ctx);

  // Don't schedule if already disposed
  if (player->disposed_) return;

  // Schedule event processing on the main thread.
  g_idle_add(
      [](gpointer data) -> gboolean {
        auto* player = static_cast<MpvPlayer*>(data);
        // Check disposed again when callback runs
        if (!player->disposed_) {
          player->ProcessEvents();
        }
        return G_SOURCE_REMOVE;
      },
      player);
}

void MpvPlayer::OnMpvRenderUpdate(void* ctx) {
  auto* player = static_cast<MpvPlayer*>(ctx);
  // RequestRedraw already checks disposed_
  player->RequestRedraw();
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
    case MPV_EVENT_LOG_MESSAGE: {
      auto* msg = static_cast<mpv_event_log_message*>(event->data);
      g_message("MPV [%s] %s: %s", msg->level, msg->prefix, msg->text);

      FlValue* data = fl_value_new_map();
      fl_value_set_string_take(data, "prefix",
                               fl_value_new_string(msg->prefix ? msg->prefix : ""));
      fl_value_set_string_take(data, "level",
                               fl_value_new_string(msg->level ? msg->level : ""));
      fl_value_set_string_take(data, "text",
                               fl_value_new_string(msg->text ? msg->text : ""));
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
          node.u.string =
              prop->data ? *static_cast<char**>(prop->data) : nullptr;
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
      fl_value_set_string_take(data, "reason",
                               fl_value_new_int(static_cast<int>(end->reason)));
      if (end->reason == MPV_END_FILE_REASON_ERROR) {
        fl_value_set_string_take(data, "error",
                                 fl_value_new_int(static_cast<int>(end->error)));
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
      return fl_value_new_string(node->u.string ? node->u.string : "");
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
        fl_value_set_string_take(
            map, node->u.list->keys[i],
            NodeToFlValue(&node->u.list->values[i]));
      }
      return map;
    }
    default:
      return fl_value_new_null();
  }
}

void MpvPlayer::SendPropertyChange(const char* name, mpv_node* data) {
  FlValue* event_map = fl_value_new_map();
  fl_value_set_string_take(event_map, "type", fl_value_new_string("property"));
  fl_value_set_string_take(event_map, "name",
                           fl_value_new_string(name ? name : ""));

  if (data) {
    fl_value_set_string_take(event_map, "value", NodeToFlValue(data));
  } else {
    fl_value_set_string_take(event_map, "value", fl_value_new_null());
  }

  std::lock_guard<std::mutex> lock(callback_mutex_);
  if (event_callback_) {
    event_callback_(event_map);
  }
  fl_value_unref(event_map);
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
