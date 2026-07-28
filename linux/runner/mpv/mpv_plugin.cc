#include "mpv_plugin.h"

#include <cstring>
#include <new>

#include "mpv_texture.h"

enum class VideoBootstrapState { kIdle, kPending, kReady, kFailed };
using PlayerPtr = std::unique_ptr<mpv::MpvPlayer>;

struct _MpvPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;
  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;
  FlTextureRegistrar* texture_registrar;

  PlayerPtr player;
  MpvTexture* texture;  // owned via GObject ref
  gboolean texture_registered;
  gboolean visible;
  gboolean initialized;
  gboolean audio_only;
  VideoBootstrapState bootstrap_state;
  gchar* bootstrap_error;
  FlMethodCall* ready_call;
  guint64 generation;
  guint ready_timeout_source_id;
};

G_DEFINE_TYPE(MpvPlugin, mpv_plugin, G_TYPE_OBJECT)

// Forward declarations
static void mpv_plugin_handle_method_call(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data);

static void send_event(MpvPlugin* self, FlValue* event) {
  if (self->event_channel) {
    g_autoptr(GError) error = nullptr;
    if (!fl_event_channel_send(self->event_channel, event, nullptr, &error) && error != nullptr) {
      g_warning("Failed to send event: %s", error->message);
    }
  }
}

static gboolean handle_ready_timeout(gpointer user_data);

static void complete_ready_call(MpvPlugin* self, gboolean success, const char* message) {
  if (self->ready_timeout_source_id != 0) {
    g_source_remove(self->ready_timeout_source_id);
    self->ready_timeout_source_id = 0;
  }
  if (!self->ready_call) return;
  g_autoptr(FlMethodResponse) response =
      success ? FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr))
              : FL_METHOD_RESPONSE(fl_method_error_response_new(
                    "INIT_FAILED", message ? message : "Video initialization failed", nullptr));
  fl_method_call_respond(self->ready_call, response, nullptr);
  g_object_unref(self->ready_call);
  self->ready_call = nullptr;
}

static void release_video_resources(MpvPlugin* self) {
  ++self->generation;
  if (self->player) {
    // The texture is a raw callback target. Revoke both callback paths before
    // unregistering or unreferencing it; Dispose then drains any callback
    // already holding a native lease.
    self->player->SetRedrawCallback(nullptr);
    self->player->SetEventCallback(nullptr);
  }
  if (self->texture) {
    if (self->texture_registered && self->texture_registrar) {
      fl_texture_registrar_unregister_texture(self->texture_registrar, FL_TEXTURE(self->texture));
      self->texture_registered = FALSE;
    }
    mpv_texture_dispose(self->texture);
    g_object_unref(self->texture);
    self->texture = nullptr;
  }
  if (self->player) {
    self->player->Dispose();
    self->player.reset();
  }
  self->initialized = FALSE;
  self->visible = FALSE;
}

struct TextureReadyContext {
  MpvPlugin* plugin;
  guint64 generation;
};

struct TextureReadyResult {
  MpvPlugin* plugin;
  guint64 generation;
  gboolean success;
  gchar* message;
};

static gboolean handle_texture_ready_result(gpointer data) {
  auto* result = static_cast<TextureReadyResult*>(data);
  MpvPlugin* self = result->plugin;
  if (result->generation != self->generation || self->bootstrap_state != VideoBootstrapState::kPending) {
    return G_SOURCE_REMOVE;
  }

  if (result->success) {
    self->bootstrap_state = VideoBootstrapState::kReady;
    self->initialized = TRUE;
    complete_ready_call(self, TRUE, nullptr);
  } else {
    self->bootstrap_state = VideoBootstrapState::kFailed;
    g_free(self->bootstrap_error);
    self->bootstrap_error = g_strdup(result->message ? result->message : "Video initialization failed");
    complete_ready_call(self, FALSE, self->bootstrap_error);
    release_video_resources(self);
  }
  return G_SOURCE_REMOVE;
}

static void destroy_texture_ready_result(gpointer data) {
  auto* result = static_cast<TextureReadyResult*>(data);
  g_object_unref(result->plugin);
  g_free(result->message);
  delete result;
}

static void on_texture_ready(gboolean success, const gchar* message, gpointer user_data) {
  auto* context = static_cast<TextureReadyContext*>(user_data);
  auto* result = new TextureReadyResult{
      MPV_PLUGIN(g_object_ref(context->plugin)),
      context->generation,
      success,
      g_strdup(message),
  };
  g_main_context_invoke_full(
      nullptr, G_PRIORITY_DEFAULT, handle_texture_ready_result, result, destroy_texture_ready_result);
}

static void destroy_texture_ready_context(gpointer data) {
  auto* context = static_cast<TextureReadyContext*>(data);
  g_object_unref(context->plugin);
  delete context;
}

static gboolean handle_ready_timeout(gpointer user_data) {
  MpvPlugin* self = MPV_PLUGIN(user_data);
  self->ready_timeout_source_id = 0;
  if (self->bootstrap_state != VideoBootstrapState::kPending || !self->ready_call) {
    return G_SOURCE_REMOVE;
  }
  self->bootstrap_state = VideoBootstrapState::kFailed;
  g_free(self->bootstrap_error);
  self->bootstrap_error = g_strdup("Video texture did not become ready before the initialization deadline");
  complete_ready_call(self, FALSE, self->bootstrap_error);
  release_video_resources(self);
  return G_SOURCE_REMOVE;
}

static void mpv_plugin_dispose(GObject* object) {
  MpvPlugin* self = MPV_PLUGIN(object);
  complete_ready_call(self, FALSE, "Video initialization was cancelled");
  release_video_resources(self);
  self->bootstrap_state = VideoBootstrapState::kIdle;
  g_clear_pointer(&self->bootstrap_error, g_free);
  g_clear_object(&self->method_channel);
  g_clear_object(&self->event_channel);
  g_clear_object(&self->registrar);
  G_OBJECT_CLASS(mpv_plugin_parent_class)->dispose(object);
}

static void mpv_plugin_finalize(GObject* object) {
  MpvPlugin* self = MPV_PLUGIN(object);
  self->player.~PlayerPtr();
  G_OBJECT_CLASS(mpv_plugin_parent_class)->finalize(object);
}

static void mpv_plugin_class_init(MpvPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = mpv_plugin_dispose;
  G_OBJECT_CLASS(klass)->finalize = mpv_plugin_finalize;
}

static void mpv_plugin_init(MpvPlugin* self) {
  new (&self->player) PlayerPtr();
  self->visible = FALSE;
  self->initialized = FALSE;
  self->texture = nullptr;
  self->texture_registered = FALSE;
  self->texture_registrar = nullptr;
  self->audio_only = FALSE;
  self->bootstrap_state = VideoBootstrapState::kIdle;
  self->bootstrap_error = nullptr;
  self->ready_call = nullptr;
  self->generation = 0;
  self->ready_timeout_source_id = 0;
}

MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar, const gchar* channel_name, gboolean audio_only) {
  MpvPlugin* self = MPV_PLUGIN(g_object_new(MPV_PLUGIN_TYPE, nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  self->audio_only = audio_only;
  // The audio-only core never renders; leaving the texture registrar unset
  // makes the GL/texture path structurally unreachable for it.
  self->texture_registrar = audio_only ? nullptr : fl_plugin_registrar_get_texture_registrar(registrar);
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
static MpvPlugin* g_mpv_plugin = nullptr;
static MpvPlugin* g_mpv_audio_plugin = nullptr;

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
      // Audio-only music core: no texture, no render context — mpv runs
      // with video disabled entirely (see MpvPlayer). Returns `true`; the
      // Dart side only treats int results as texture IDs.
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
    } else if (
        self->texture && (self->bootstrap_state == VideoBootstrapState::kPending ||
                          self->bootstrap_state == VideoBootstrapState::kReady)) {
      response =
          FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(mpv_texture_get_id(self->texture))));
    } else {
      g_clear_pointer(&self->bootstrap_error, g_free);
      self->bootstrap_state = VideoBootstrapState::kIdle;
      if (!self->player || self->player->IsDisposed()) {
        self->player = std::make_unique<mpv::MpvPlayer>();
      }

      if (!self->player->Initialize()) {
        release_video_resources(self);
        self->bootstrap_state = VideoBootstrapState::kFailed;
        self->bootstrap_error = g_strdup("Failed to initialize MPV player");
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INIT_FAILED", self->bootstrap_error, nullptr));
      } else {
        FlView* view = fl_plugin_registrar_get_view(self->registrar);
        self->texture = mpv_texture_new(self->player.get(), self->texture_registrar, view);
        ++self->generation;
        self->bootstrap_state = VideoBootstrapState::kPending;
        auto* ready_context = new TextureReadyContext{MPV_PLUGIN(g_object_ref(self)), self->generation};
        mpv_texture_set_ready_callback(self->texture, on_texture_ready, ready_context, destroy_texture_ready_context);

        if (!fl_texture_registrar_register_texture(self->texture_registrar, FL_TEXTURE(self->texture))) {
          self->bootstrap_state = VideoBootstrapState::kFailed;
          self->bootstrap_error = g_strdup("Failed to register video texture");
          release_video_resources(self);
          response = FL_METHOD_RESPONSE(fl_method_error_response_new("INIT_FAILED", self->bootstrap_error, nullptr));
        } else {
          self->texture_registered = TRUE;
          MpvTexture* texture = self->texture;
          self->player->SetRedrawCallback([texture]() { mpv_texture_mark_frame_available(texture); });
          self->player->SetEventCallback([self](FlValue* event) { send_event(self, event); });
          mpv_texture_mark_frame_available(self->texture);
          response =
              FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(mpv_texture_get_id(self->texture))));
        }
      }
    }
  } else if (strcmp(method, "waitForVideoReady") == 0) {
    if (self->audio_only) {
      response = FL_METHOD_RESPONSE(
          fl_method_error_response_new("INIT_FAILED", "Audio players have no video readiness state", nullptr));
    } else if (self->bootstrap_state == VideoBootstrapState::kReady && self->initialized) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else if (self->bootstrap_state == VideoBootstrapState::kFailed) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INIT_FAILED", self->bootstrap_error ? self->bootstrap_error : "Video initialization failed", nullptr));
    } else if (self->bootstrap_state != VideoBootstrapState::kPending || !self->texture) {
      response = FL_METHOD_RESPONSE(
          fl_method_error_response_new("INIT_FAILED", "Video initialization is not pending", nullptr));
    } else if (self->ready_call) {
      response = FL_METHOD_RESPONSE(
          fl_method_error_response_new("INIT_IN_PROGRESS", "Video readiness is already being awaited", nullptr));
    } else {
      self->ready_call = FL_METHOD_CALL(g_object_ref(method_call));
      self->ready_timeout_source_id =
          g_timeout_add_seconds_full(G_PRIORITY_DEFAULT, 5, handle_ready_timeout, g_object_ref(self), g_object_unref);
      return;
    }
  } else if (strcmp(method, "dispose") == 0) {
    complete_ready_call(self, FALSE, "Video initialization was cancelled");
    release_video_resources(self);
    self->bootstrap_state = VideoBootstrapState::kIdle;
    g_clear_pointer(&self->bootstrap_error, g_free);
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
      } else {
        g_object_ref(method_call);
        self->player->SetPropertyAsync(
            fl_value_get_string(name_value), fl_value_get_string(value_value), [method_call](int error) {
              g_autoptr(FlMethodResponse) async_response = nullptr;
              if (plezy::mpv_common::SetPropertyStatusSucceeded(error)) {
                async_response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
              } else {
                const char* error_code = plezy::mpv_common::SetPropertyErrorCode(error);
                const std::string description = error == MPV_ERROR_UNINITIALIZED
                                                    ? std::string("Player not initialized")
                                                    : plezy::mpv_common::SetPropertyErrorDescription(error);
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
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(initialized)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}
