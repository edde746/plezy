#include "mpv_plugin.h"

#include <cstring>

/// Plugin structure definition.
struct _MpvPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;
  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;
  FlBasicMessageChannel* event_message_channel;

  GtkOverlay* overlay;
  GtkGLArea* gl_area;
  GtkWidget* flutter_view;

  std::unique_ptr<mpv::MpvPlayer> player;
  gboolean visible;
  gboolean initialized;
};

G_DEFINE_TYPE(MpvPlugin, mpv_plugin, G_TYPE_OBJECT)

// Forward declarations
static void mpv_plugin_handle_method_call(FlMethodChannel* channel,
                                          FlMethodCall* method_call,
                                          gpointer user_data);
static gboolean on_gl_render(GtkGLArea* area,
                             GdkGLContext* context,
                             gpointer user_data);
static void on_gl_realize(GtkGLArea* area, gpointer user_data);
static void on_gl_unrealize(GtkGLArea* area, gpointer user_data);

static void mpv_plugin_dispose(GObject* object) {
  MpvPlugin* self = MPV_PLUGIN(object);

  if (self->player) {
    self->player->Dispose();
    self->player.reset();
  }

  g_clear_object(&self->method_channel);
  g_clear_object(&self->event_channel);
  g_clear_object(&self->registrar);

  G_OBJECT_CLASS(mpv_plugin_parent_class)->dispose(object);
}

static void mpv_plugin_class_init(MpvPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = mpv_plugin_dispose;
}

static void mpv_plugin_init(MpvPlugin* self) {
  self->visible = FALSE;
  self->initialized = FALSE;
}

/// Send an event through the event channel.
static void send_event(MpvPlugin* self, FlValue* event) {
  if (self->event_channel) {
    g_autoptr(GError) error = nullptr;
    if (!fl_event_channel_send(self->event_channel, event, nullptr, &error)) {
      if (error != nullptr) {
        g_warning("Failed to send event: %s", error->message);
      }
    }
  }
}

MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar,
                          GtkOverlay* overlay,
                          GtkGLArea* gl_area,
                          GtkWidget* flutter_view) {
  MpvPlugin* self = MPV_PLUGIN(g_object_new(MPV_PLUGIN_TYPE, nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  self->overlay = overlay;
  self->gl_area = gl_area;
  self->flutter_view = flutter_view;
  self->player = std::make_unique<mpv::MpvPlayer>();

  // Create method channel.
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.plezy/mpv_player",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      self->method_channel,
      mpv_plugin_handle_method_call,
      self,
      nullptr);

  // Create event channel.
  self->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.plezy/mpv_player/events",
      FL_METHOD_CODEC(codec));

  // Connect GtkGLArea signals.
  g_signal_connect(gl_area, "render", G_CALLBACK(on_gl_render), self);
  g_signal_connect(gl_area, "realize", G_CALLBACK(on_gl_realize), self);
  g_signal_connect(gl_area, "unrealize", G_CALLBACK(on_gl_unrealize), self);

  // Set up auto-render to false - we control when to render.
  gtk_gl_area_set_auto_render(gl_area, FALSE);

  // Use OpenGL 3.3 core profile.
  gtk_gl_area_set_required_version(gl_area, 3, 3);

  return self;
}

// Static reference to keep the plugin alive for the lifetime of the app.
// The plugin will be disposed when the GL area is unrealized.
static MpvPlugin* g_mpv_plugin = nullptr;

void mpv_plugin_register_with_registrar(FlPluginRegistrar* registrar,
                                        GtkOverlay* overlay,
                                        GtkGLArea* gl_area,
                                        GtkWidget* flutter_view) {
  g_mpv_plugin = mpv_plugin_new(registrar, overlay, gl_area, flutter_view);
  // Keep a reference - the plugin will be cleaned up when the app exits
}

/// GtkGLArea render callback.
static gboolean on_gl_render(GtkGLArea* area,
                             GdkGLContext* context,
                             gpointer user_data) {
  (void)context;
  MpvPlugin* self = MPV_PLUGIN(user_data);

  if (!self->player || !self->player->IsInitialized() || !self->visible) {
    // Clear to transparent when not showing video.
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    return TRUE;
  }

  int width = gtk_widget_get_allocated_width(GTK_WIDGET(area));
  int height = gtk_widget_get_allocated_height(GTK_WIDGET(area));

  // Get the scale factor for HiDPI support.
  int scale = gtk_widget_get_scale_factor(GTK_WIDGET(area));
  width *= scale;
  height *= scale;

  // Get the FBO that GtkGLArea is rendering to.
  // GtkGLArea uses its own FBO, not the default framebuffer (0).
  GLint fbo = 0;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fbo);

  // Render the video frame.
  self->player->Render(width, height, fbo);
  self->player->ClearRedrawFlag();

  return TRUE;
}

/// GtkGLArea realize callback.
static void on_gl_realize(GtkGLArea* area, gpointer user_data) {
  (void)user_data;
  gtk_gl_area_make_current(area);

  // Check for GL errors.
  GError* error = gtk_gl_area_get_error(area);
  if (error != nullptr) {
    g_warning("MPV Plugin: GL area error: %s", error->message);
    return;
  }

  // Enable blending for transparency support.
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  g_message("MPV Plugin: GL area realized");
}

/// GtkGLArea unrealize callback.
static void on_gl_unrealize(GtkGLArea* area, gpointer user_data) {
  MpvPlugin* self = MPV_PLUGIN(user_data);

  gtk_gl_area_make_current(area);

  if (self->player) {
    self->player->Dispose();
  }

  g_message("MPV Plugin: GL area unrealized");
}

/// Method call handler.
static void mpv_plugin_handle_method_call(FlMethodChannel* channel,
                                          FlMethodCall* method_call,
                                          gpointer user_data) {
  (void)channel;
  MpvPlugin* self = MPV_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "initialize") == 0) {
    if (self->initialized) {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(TRUE)));
    } else {
      // Create player if it was disposed
      if (!self->player) {
        self->player = std::make_unique<mpv::MpvPlayer>();
      }

      // Check if GL area is realized before trying to use it
      if (!gtk_widget_get_realized(GTK_WIDGET(self->gl_area))) {
        // Force realization of the GL area
        gtk_widget_realize(GTK_WIDGET(self->gl_area));
      }

      // Initialize the player with the GL area.
      gtk_gl_area_make_current(self->gl_area);

      GError* error = gtk_gl_area_get_error(self->gl_area);
      if (error != nullptr) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "GL_ERROR", error->message, nullptr));
      } else if (self->player->Initialize(self->gl_area)) {
        self->initialized = TRUE;

        // Set up event callback.
        self->player->SetEventCallback([self](FlValue* event) {
          // Send event - must be called from main thread
          // The event is already created on the main thread via g_idle_add in mpv_player.cc
          send_event(self, event);
        });

        response = FL_METHOD_RESPONSE(
            fl_method_success_response_new(fl_value_new_bool(TRUE)));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INIT_FAILED", "Failed to initialize MPV player", nullptr));
      }
    }
  } else if (strcmp(method, "dispose") == 0) {
    if (self->player) {
      // Make GL context current before disposing mpv GL resources
      gtk_gl_area_make_current(self->gl_area);
      self->player->Dispose();
      self->player.reset();
    }
    self->initialized = FALSE;
    self->visible = FALSE;
    gtk_widget_set_visible(GTK_WIDGET(self->gl_area), FALSE);
    // Restore Flutter view opacity to 1.0 (may have been set to 0 by setControlsVisible)
    if (self->flutter_view != nullptr) {
      gtk_widget_set_opacity(self->flutter_view, 1.0);
      // Force Flutter view to redraw
      gtk_widget_queue_draw(self->flutter_view);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "command") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* args_value = fl_value_lookup_string(args, "args");
      if (args_value == nullptr ||
          fl_value_get_type(args_value) != FL_VALUE_TYPE_LIST) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'args' list", nullptr));
      } else {
        std::vector<std::string> command_args;
        size_t len = fl_value_get_length(args_value);
        for (size_t i = 0; i < len; i++) {
          FlValue* item = fl_value_get_list_value(args_value, i);
          if (fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
            command_args.push_back(fl_value_get_string(item));
          }
        }
        self->player->Command(command_args);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "setProperty") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* name_value = fl_value_lookup_string(args, "name");
      FlValue* value_value = fl_value_lookup_string(args, "value");

      if (name_value == nullptr ||
          fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'name'", nullptr));
      } else if (value_value == nullptr ||
                 fl_value_get_type(value_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'value'", nullptr));
      } else {
        self->player->SetProperty(fl_value_get_string(name_value),
                                  fl_value_get_string(value_value));
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "getProperty") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* name_value = fl_value_lookup_string(args, "name");

      if (name_value == nullptr ||
          fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'name'", nullptr));
      } else {
        std::string value =
            self->player->GetProperty(fl_value_get_string(name_value));
        if (value.empty()) {
          response =
              FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        } else {
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(
              fl_value_new_string(value.c_str())));
        }
      }
    }
  } else if (strcmp(method, "observeProperty") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* name_value = fl_value_lookup_string(args, "name");
      FlValue* format_value = fl_value_lookup_string(args, "format");

      if (name_value == nullptr ||
          fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'name'", nullptr));
      } else if (format_value == nullptr ||
                 fl_value_get_type(format_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'format'", nullptr));
      } else {
        self->player->ObserveProperty(fl_value_get_string(name_value),
                                      fl_value_get_string(format_value));
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "setVisible") == 0) {
    FlValue* visible_value = fl_value_lookup_string(args, "visible");

    if (visible_value == nullptr ||
        fl_value_get_type(visible_value) != FL_VALUE_TYPE_BOOL) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGS", "Missing 'visible'", nullptr));
    } else {
      gboolean visible = fl_value_get_bool(visible_value);
      self->visible = visible;

      // Show/hide the GL area.
      gtk_widget_set_visible(GTK_WIDGET(self->gl_area), visible);

      if (visible) {
        gtk_gl_area_queue_render(self->gl_area);
      }

      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "setVideoRect") == 0) {
    // On Linux, the GtkGLArea fills the entire overlay area,
    // and mpv handles its own aspect ratio. So we just trigger a redraw.
    if (self->player && self->initialized && self->visible) {
      gtk_gl_area_queue_render(self->gl_area);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "setControlsVisible") == 0) {
    // Set Flutter view opacity when controls are hidden/shown.
    // This is a workaround for Flutter's lack of transparency support on Linux.
    // When controls are hidden, setting opacity to 0 shows only the video
    // while keeping the widget interactive for mouse events.
    FlValue* controls_visible_value = fl_value_lookup_string(args, "visible");

    if (controls_visible_value == nullptr ||
        fl_value_get_type(controls_visible_value) != FL_VALUE_TYPE_BOOL) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGS", "Missing 'visible'", nullptr));
    } else {
      gboolean controls_visible = fl_value_get_bool(controls_visible_value);

      // When controls are hidden, set Flutter view opacity to 0.
      // When controls are visible, set opacity to 1.
      // Using opacity keeps the widget interactive for mouse events.
      if (self->flutter_view != nullptr) {
        gtk_widget_set_opacity(self->flutter_view, controls_visible ? 1.0 : 0.0);
      }

      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "isInitialized") == 0) {
    gboolean initialized = self->player && self->initialized;
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(initialized)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}
