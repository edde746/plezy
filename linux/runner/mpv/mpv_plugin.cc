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
static void on_gl_resize(GtkGLArea* area, gint width, gint height, gpointer user_data);

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
  g_signal_connect(gl_area, "resize", G_CALLBACK(on_gl_resize), self);

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

  // Ensure GL context is current before any GL operations.
  // Critical during fullscreen transitions and workspace switches (issue #202).
  gtk_gl_area_make_current(area);

  // Check for GL context errors (can happen during window state changes)
  GError* error = gtk_gl_area_get_error(area);
  if (error != nullptr) {
    g_warning("MPV Plugin: GL context error in render: %s", error->message);
    return FALSE;  // Signal failure to GTK
  }

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

  // Save GL state before MPV render (MPV modifies these and doesn't restore them)
  // This prevents GL state pollution that corrupts Flutter's rendering.
  GLint prev_viewport[4];
  GLint prev_scissor_box[4];
  GLboolean prev_blend, prev_scissor_test;
  GLint prev_blend_src, prev_blend_dst;

  glGetIntegerv(GL_VIEWPORT, prev_viewport);
  glGetIntegerv(GL_SCISSOR_BOX, prev_scissor_box);
  glGetBooleanv(GL_BLEND, &prev_blend);
  glGetBooleanv(GL_SCISSOR_TEST, &prev_scissor_test);
  glGetIntegerv(GL_BLEND_SRC_ALPHA, &prev_blend_src);
  glGetIntegerv(GL_BLEND_DST_ALPHA, &prev_blend_dst);

  // Set viewport and render the video frame.
  glViewport(0, 0, width, height);
  self->player->Render(width, height, fbo);
  self->player->ClearRedrawFlag();

  // Restore GL state after MPV render to prevent Flutter corruption.
  glViewport(prev_viewport[0], prev_viewport[1], prev_viewport[2], prev_viewport[3]);
  glScissor(prev_scissor_box[0], prev_scissor_box[1], prev_scissor_box[2], prev_scissor_box[3]);
  if (prev_blend) {
    glEnable(GL_BLEND);
  } else {
    glDisable(GL_BLEND);
  }
  if (prev_scissor_test) {
    glEnable(GL_SCISSOR_TEST);
  } else {
    glDisable(GL_SCISSOR_TEST);
  }
  glBlendFunc(prev_blend_src, prev_blend_dst);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);

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

  // Check if context is valid before disposing GL resources (issue #202)
  GError* error = gtk_gl_area_get_error(area);
  if (error != nullptr) {
    g_warning("MPV Plugin: GL context error in unrealize: %s", error->message);
  }

  // Always try to dispose - Dispose() handles its own safety checks
  if (self->player) {
    self->player->Dispose();
  }

  g_message("MPV Plugin: GL area unrealized");
}

/// GtkGLArea resize callback.
static void on_gl_resize(GtkGLArea* area,
                         gint width,
                         gint height,
                         gpointer user_data) {
  MpvPlugin* self = MPV_PLUGIN(user_data);
  (void)width;
  (void)height;

  // Force a redraw when size changes to prevent lag during resize.
  if (self->visible && self->player && self->player->IsInitialized()) {
    gtk_gl_area_queue_render(area);
  }
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
    if (self->flutter_view != nullptr) {
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
        // Use async command to prevent UI blocking during network operations
        // Take ownership of method_call to respond asynchronously
        g_object_ref(method_call);
        self->player->CommandAsync(command_args, [method_call](int error) {
          g_autoptr(FlMethodResponse) async_response = nullptr;
          if (error < 0) {
            async_response = FL_METHOD_RESPONSE(fl_method_error_response_new(
                "COMMAND_FAILED", "MPV command failed", nullptr));
          } else {
            async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
          }
          fl_method_call_respond(method_call, async_response, nullptr);
          g_object_unref(method_call);
        });
        return;  // Response will be sent asynchronously
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
      FlValue* id_value = fl_value_lookup_string(args, "id");

      if (name_value == nullptr ||
          fl_value_get_type(name_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'name'", nullptr));
      } else if (format_value == nullptr ||
                 fl_value_get_type(format_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'format'", nullptr));
      } else if (id_value == nullptr ||
                 fl_value_get_type(id_value) != FL_VALUE_TYPE_INT) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'id'", nullptr));
      } else {
        self->player->ObserveProperty(fl_value_get_string(name_value),
                                      fl_value_get_string(format_value),
                                      static_cast<int>(fl_value_get_int(id_value)));
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
  } else if (strcmp(method, "isInitialized") == 0) {
    gboolean initialized = self->player && self->initialized;
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(initialized)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}
