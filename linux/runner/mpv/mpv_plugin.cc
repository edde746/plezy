#include "mpv_plugin.h"
#include "mpv_texture.h"

#include <cstring>

struct _MpvPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;
  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;
  FlTextureRegistrar* texture_registrar;

  std::unique_ptr<mpv::MpvPlayer> player;
  MpvTexture* texture;      // owned via GObject ref
  gboolean visible;
  gboolean initialized;
};

G_DEFINE_TYPE(MpvPlugin, mpv_plugin, G_TYPE_OBJECT)

// Forward declarations
static void mpv_plugin_handle_method_call(FlMethodChannel* channel,
                                          FlMethodCall* method_call,
                                          gpointer user_data);

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

static void mpv_plugin_dispose(GObject* object) {
  MpvPlugin* self = MPV_PLUGIN(object);

  // Texture must be disposed BEFORE player — mpv_texture_dispose needs
  // the player's EGL context to clean up GL resources.
  if (self->texture) {
    mpv_texture_dispose(self->texture);
    if (self->texture_registrar) {
      fl_texture_registrar_unregister_texture(self->texture_registrar,
                                              FL_TEXTURE(self->texture));
    }
    g_object_unref(self->texture);
    self->texture = nullptr;
  }

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
  self->texture = nullptr;
  self->texture_registrar = nullptr;
}

MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar) {
  MpvPlugin* self = MPV_PLUGIN(g_object_new(MPV_PLUGIN_TYPE, nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  self->texture_registrar =
      fl_plugin_registrar_get_texture_registrar(registrar);
  self->player = std::make_unique<mpv::MpvPlayer>();

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

  self->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.plezy/mpv_player/events",
      FL_METHOD_CODEC(codec));

  return self;
}

// Static reference to keep the plugin alive.
static MpvPlugin* g_mpv_plugin = nullptr;

void mpv_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_mpv_plugin = mpv_plugin_new(registrar);
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
    if (self->initialized && self->texture) {
      // Already initialized — return existing texture ID
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(
          fl_value_new_int(mpv_texture_get_id(self->texture))));
    } else {
      // Create player if it was disposed or doesn't exist
      if (!self->player || self->player->IsDisposed()) {
        self->player = std::make_unique<mpv::MpvPlayer>();
      }

      if (self->player->Initialize()) {
        // Create the FlTextureGL and register it
        FlView* view = fl_plugin_registrar_get_view(self->registrar);
        self->texture = mpv_texture_new(
            self->player.get(), self->texture_registrar, view);

        fl_texture_registrar_register_texture(
            self->texture_registrar, FL_TEXTURE(self->texture));

        // Create the render context eagerly — mpv needs it BEFORE any
        // file is loaded, otherwise VO init fails with "No render context
        // set" and the video track is dropped entirely.
        self->player->InitRenderContext();

        // Set redraw callback: when mpv has a frame, mark texture available
        MpvTexture* tex = self->texture;
        self->player->SetRedrawCallback([tex]() {
          mpv_texture_mark_frame_available(tex);
        });

        self->initialized = TRUE;

        // Set up event callback
        self->player->SetEventCallback([self](FlValue* event) {
          send_event(self, event);
        });

        // Return the texture ID for the Dart Texture widget
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(
            fl_value_new_int(mpv_texture_get_id(self->texture))));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INIT_FAILED", "Failed to initialize MPV player", nullptr));
      }
    }
  } else if (strcmp(method, "dispose") == 0) {
    // Disconnect and unregister texture FIRST — this stops Flutter from
    // calling populate(), preventing concurrent mpv_render_context_render()
    // during player disposal.
    if (self->texture) {
      mpv_texture_dispose(self->texture);
      fl_texture_registrar_unregister_texture(self->texture_registrar,
                                              FL_TEXTURE(self->texture));
      g_object_unref(self->texture);
      self->texture = nullptr;
    }
    if (self->player) {
      self->player->Dispose();
      // Don't reset player here — stray g_idle callbacks still reference it.
      // It will be replaced on next initialize() call.
    }
    self->initialized = FALSE;
    self->visible = FALSE;
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
        return;  // Response sent asynchronously
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
  } else if (strcmp(method, "setLogLevel") == 0) {
    if (!self->player || !self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Player not initialized", nullptr));
    } else {
      FlValue* level_value = fl_value_lookup_string(args, "level");

      if (level_value == nullptr ||
          fl_value_get_type(level_value) != FL_VALUE_TYPE_STRING) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing 'level'", nullptr));
      } else {
        self->player->SetLogLevel(fl_value_get_string(level_value));
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
      self->visible = fl_value_get_bool(visible_value);

      if (self->visible && self->texture) {
        // Trigger a frame render when becoming visible
        mpv_texture_mark_frame_available(self->texture);
      }

      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "updateFrame") == 0) {
    if (self->visible && self->texture) {
      mpv_texture_mark_frame_available(self->texture);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "isInitialized") == 0) {
    gboolean initialized = self->player && self->initialized;
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(initialized)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}
