#include "mpv_texture.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

#include "mpv_gpu_bootstrap.h"

namespace {

GQuark TextureErrorDomain() { return g_quark_from_static_string("plezy-mpv-texture"); }

struct TextureResources {
  GLuint mpv_fbo = 0;
  GLuint mpv_texture = 0;
  GLuint flutter_texture = 0;
  EGLImageKHR egl_image = EGL_NO_IMAGE_KHR;
  int32_t width = 0;
  int32_t height = 0;

  bool complete() const {
    return mpv_fbo != 0 && mpv_texture != 0 && flutter_texture != 0 && egl_image != EGL_NO_IMAGE_KHR;
  }
};

bool SetError(GError** error, const char* message) {
  g_set_error_literal(error, TextureErrorDomain(), 1, message);
  return false;
}

void ClearGlErrors() {
  while (glGetError() != GL_NO_ERROR) {
  }
}

}  // namespace

struct _MpvTexture {
  FlTextureGL parent_instance;

  mpv::MpvPlayer* player;
  FlTextureRegistrar* registrar;
  FlView* view;

  GMutex mutex;
  bool disposed;
  TextureResources* active;
  std::vector<TextureResources>* retired;
  mpv::GpuImageDispatch* image_dispatch;
  EGLDisplay flutter_display;
  EGLContext flutter_share_context;
  EGLContext flutter_cleanup_context;

  GMutex bootstrap_mutex;
  gint bootstrap_state;
  gchar* bootstrap_error;
  MpvTextureReadyCallback ready_callback;
  gpointer ready_user_data;
  GDestroyNotify ready_destroy_notify;
};

G_DEFINE_TYPE(MpvTexture, mpv_texture, fl_texture_gl_get_type())

namespace {

void SignalBootstrap(MpvTexture* self, gboolean success, const char* message) {
  MpvTextureReadyCallback callback = nullptr;
  gpointer user_data = nullptr;
  g_mutex_lock(&self->bootstrap_mutex);
  if (self->bootstrap_state == 0) {
    self->bootstrap_state = success ? 1 : 2;
    if (!success) self->bootstrap_error = g_strdup(message ? message : "Video initialization failed");
    callback = self->ready_callback;
    user_data = self->ready_user_data;
  }
  g_mutex_unlock(&self->bootstrap_mutex);
  if (callback) callback(success, message, user_data);
}

bool RestoreContext(
    EGLDisplay display, EGLSurface draw, EGLSurface read, EGLContext context, EGLenum api, GError** error) {
  if (api != EGL_NONE && !eglBindAPI(api)) {
    g_warning("MPV texture: failed to restore Flutter EGL API: 0x%x", eglGetError());
    return SetError(error, "Failed to restore Flutter EGL API");
  }
  if (eglMakeCurrent(display, draw, read, context)) return true;
  g_warning("MPV texture: failed to restore EGL context: 0x%x", eglGetError());
  return SetError(error, "Failed to restore Flutter EGL context");
}

void RestoreOrReleaseContext(
    EGLDisplay flutter_display, EGLSurface flutter_draw, EGLSurface flutter_read, EGLContext flutter_context,
    EGLenum flutter_api, EGLDisplay mpv_display) {
  if (flutter_display != EGL_NO_DISPLAY && flutter_context != EGL_NO_CONTEXT) {
    const bool api_restored = flutter_api == EGL_NONE || eglBindAPI(flutter_api);
    if (api_restored && eglMakeCurrent(flutter_display, flutter_draw, flutter_read, flutter_context)) return;
    g_warning("MPV texture: failed to restore EGL state during cleanup: 0x%x", eglGetError());
  }

  if (mpv_display != EGL_NO_DISPLAY) {
    if (!eglBindAPI(EGL_OPENGL_ES_API)) {
      g_warning("MPV texture: failed to bind OpenGL while releasing cleanup context: 0x%x", eglGetError());
    } else if (!eglMakeCurrent(mpv_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
      g_warning("MPV texture: failed to release EGL context during cleanup: 0x%x", eglGetError());
    }
  }
  if (flutter_api != EGL_NONE && !eglBindAPI(flutter_api)) {
    g_warning("MPV texture: failed to restore Flutter EGL API after cleanup: 0x%x", eglGetError());
  }
}

bool ResourceSetEmpty(const TextureResources& resources) {
  return resources.mpv_fbo == 0 && resources.mpv_texture == 0 && resources.flutter_texture == 0 &&
         resources.egl_image == EGL_NO_IMAGE_KHR;
}

bool EnsureFlutterCleanupContext(
    MpvTexture* self, EGLDisplay flutter_display, EGLContext flutter_context, EGLenum flutter_api, GError** error) {
  if (self->flutter_cleanup_context != EGL_NO_CONTEXT) {
    if (self->flutter_display == flutter_display && self->flutter_share_context == flutter_context) return true;
    return SetError(error, "Flutter EGL context changed while video textures were active");
  }
  if (flutter_api != EGL_OPENGL_ES_API) {
    return SetError(error, "Flutter is not using an OpenGL ES context");
  }

  EGLint config_id = 0;
  EGLint client_version = 0;
  if (!eglQueryContext(flutter_display, flutter_context, EGL_CONFIG_ID, &config_id) ||
      !eglQueryContext(flutter_display, flutter_context, EGL_CONTEXT_CLIENT_VERSION, &client_version)) {
    g_warning("MPV texture: failed to query Flutter EGL context: 0x%x", eglGetError());
    return SetError(error, "Failed to query Flutter EGL context");
  }
  EGLConfig config = nullptr;
  EGLint num_configs = 0;
  const EGLint config_attribs[] = {EGL_CONFIG_ID, config_id, EGL_NONE};
  if (!eglChooseConfig(flutter_display, config_attribs, &config, 1, &num_configs) || num_configs != 1) {
    g_warning("MPV texture: failed to select Flutter EGL config: 0x%x", eglGetError());
    return SetError(error, "Failed to select Flutter EGL config");
  }

  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    g_warning("MPV texture: failed to bind OpenGL ES for cleanup context creation: 0x%x", eglGetError());
    return SetError(error, "Failed to bind OpenGL ES for video cleanup");
  }
  const EGLint context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, client_version, EGL_NONE};
  const EGLContext cleanup_context = eglCreateContext(flutter_display, config, flutter_context, context_attribs);
  const bool api_restored = eglBindAPI(flutter_api) == EGL_TRUE;
  if (cleanup_context == EGL_NO_CONTEXT || !api_restored) {
    if (cleanup_context != EGL_NO_CONTEXT && !eglDestroyContext(flutter_display, cleanup_context)) {
      g_warning("MPV texture: failed to destroy rejected cleanup context: 0x%x", eglGetError());
    }
    if (!api_restored) {
      g_warning("MPV texture: failed to restore Flutter EGL API after cleanup context creation: 0x%x", eglGetError());
    }
    return SetError(error, "Failed to create video cleanup context");
  }

  self->flutter_display = flutter_display;
  self->flutter_share_context = flutter_context;
  self->flutter_cleanup_context = cleanup_context;
  return true;
}

void DestroyFlutterCleanupContext(MpvTexture* self) {
  if (self->flutter_cleanup_context == EGL_NO_CONTEXT || self->flutter_display == EGL_NO_DISPLAY) return;

  const EGLenum previous_api = eglQueryAPI();
  if (eglGetCurrentContext() == self->flutter_cleanup_context) {
    if (!eglBindAPI(EGL_OPENGL_ES_API) ||
        !eglMakeCurrent(self->flutter_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
      g_warning("MPV texture: failed to release Flutter cleanup context: 0x%x", eglGetError());
    }
  }
  if (!eglDestroyContext(self->flutter_display, self->flutter_cleanup_context)) {
    g_warning("MPV texture: failed to destroy Flutter cleanup context: 0x%x", eglGetError());
  }
  if (previous_api != EGL_NONE && !eglBindAPI(previous_api)) {
    g_warning("MPV texture: failed to restore EGL API after cleanup context destruction: 0x%x", eglGetError());
  }
  self->flutter_cleanup_context = EGL_NO_CONTEXT;
  self->flutter_share_context = EGL_NO_CONTEXT;
  self->flutter_display = EGL_NO_DISPLAY;
}

void RetireIncompleteCandidate(MpvTexture* self, const TextureResources& candidate) {
  if (!ResourceSetEmpty(candidate)) self->retired->push_back(candidate);
}

void CleanupResourceSet(
    MpvTexture* self, TextureResources* resources, EGLDisplay flutter_display, EGLSurface flutter_draw,
    EGLSurface flutter_read, EGLContext flutter_context, EGLenum flutter_api) {
  const EGLDisplay mpv_display = self->player ? self->player->GetEglDisplay() : EGL_NO_DISPLAY;
  const EGLContext mpv_context = self->player ? self->player->GetEglContext() : EGL_NO_CONTEXT;

  if (resources->egl_image != EGL_NO_IMAGE_KHR && mpv_display != EGL_NO_DISPLAY && self->image_dispatch &&
      *self->image_dispatch) {
    if (self->image_dispatch->Destroy(mpv_display, resources->egl_image)) {
      resources->egl_image = EGL_NO_IMAGE_KHR;
    } else {
      g_warning("MPV texture: failed to destroy EGL image: 0x%x", eglGetError());
    }
  }

  if (resources->flutter_texture) {
    const bool flutter_current = flutter_display == self->flutter_display &&
                                 flutter_context == self->flutter_share_context && flutter_context != EGL_NO_CONTEXT &&
                                 eglGetCurrentContext() == self->flutter_share_context;
    const bool cleanup_current =
        !flutter_current && self->flutter_display != EGL_NO_DISPLAY &&
        self->flutter_cleanup_context != EGL_NO_CONTEXT && eglBindAPI(EGL_OPENGL_ES_API) &&
        eglMakeCurrent(self->flutter_display, EGL_NO_SURFACE, EGL_NO_SURFACE, self->flutter_cleanup_context);
    if (flutter_current || cleanup_current) {
      glDeleteTextures(1, &resources->flutter_texture);
      resources->flutter_texture = 0;
    } else {
      g_warning("MPV texture: failed to activate Flutter cleanup context: 0x%x", eglGetError());
    }
    if (cleanup_current) {
      RestoreOrReleaseContext(
          flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, self->flutter_display);
    }
  }

  if (resources->mpv_fbo || resources->mpv_texture) {
    const bool mpv_current = mpv_display != EGL_NO_DISPLAY && mpv_context != EGL_NO_CONTEXT &&
                             eglBindAPI(EGL_OPENGL_ES_API) &&
                             eglMakeCurrent(mpv_display, EGL_NO_SURFACE, EGL_NO_SURFACE, mpv_context);
    if (mpv_current) {
      if (resources->mpv_fbo) glDeleteFramebuffers(1, &resources->mpv_fbo);
      if (resources->mpv_texture) glDeleteTextures(1, &resources->mpv_texture);
      resources->mpv_fbo = 0;
      resources->mpv_texture = 0;
    } else {
      g_warning("MPV texture: failed to activate EGL context during cleanup: 0x%x", eglGetError());
    }
    RestoreOrReleaseContext(flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, mpv_display);
  }
}

void CleanupRetired(MpvTexture* self) {
  if (!self->retired || self->retired->empty() || !self->player) return;
  const EGLDisplay flutter_display = eglGetCurrentDisplay();
  const EGLContext flutter_context = eglGetCurrentContext();
  const EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  const EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
  const EGLenum flutter_api = eglQueryAPI();
  for (auto& resources : *self->retired) {
    CleanupResourceSet(self, &resources, flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api);
  }
  auto& retired = *self->retired;
  retired.erase(
      std::remove_if(
          retired.begin(), retired.end(),
          [](const TextureResources& resources) { return ResourceSetEmpty(resources); }),
      retired.end());
}

bool EnsureTextures(MpvTexture* self, int32_t width, int32_t height, GError** error) {
  if (self->active->complete() && self->active->width == width && self->active->height == height) return true;

  const EGLDisplay flutter_display = eglGetCurrentDisplay();
  const EGLContext flutter_context = eglGetCurrentContext();
  const EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  const EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
  const EGLenum flutter_api = eglQueryAPI();
  const EGLDisplay mpv_display = self->player->GetEglDisplay();
  const EGLContext mpv_context = self->player->GetEglContext();
  if (flutter_display == EGL_NO_DISPLAY || flutter_context == EGL_NO_CONTEXT || mpv_display == EGL_NO_DISPLAY ||
      mpv_context == EGL_NO_CONTEXT) {
    return SetError(error, "Video EGL contexts are unavailable");
  }

  if (!EnsureFlutterCleanupContext(self, flutter_display, flutter_context, flutter_api, error)) return false;

  if (!*self->image_dispatch) {
    std::string dispatch_error;
    if (!mpv::ResolveGpuImageDispatch(flutter_display, self->image_dispatch, &dispatch_error)) {
      g_warning("MPV texture: GPU bootstrap rejected: %s", dispatch_error.c_str());
      return SetError(error, dispatch_error.c_str());
    }
  }

  TextureResources candidate;
  candidate.width = width;
  candidate.height = height;
  if (!eglBindAPI(EGL_OPENGL_ES_API) || !eglMakeCurrent(mpv_display, EGL_NO_SURFACE, EGL_NO_SURFACE, mpv_context)) {
    RestoreOrReleaseContext(flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, mpv_display);
    return SetError(error, "Failed to activate video EGL context");
  }

  ClearGlErrors();
  glGenTextures(1, &candidate.mpv_texture);
  glBindTexture(GL_TEXTURE_2D, candidate.mpv_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
  glGenFramebuffers(1, &candidate.mpv_fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, candidate.mpv_fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, candidate.mpv_texture, 0);
  bool framebuffer_complete = candidate.mpv_texture != 0 && candidate.mpv_fbo != 0 &&
                              glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE &&
                              glGetError() == GL_NO_ERROR;
  if (framebuffer_complete) {
    candidate.egl_image = self->image_dispatch->Create(
        mpv_display, mpv_context, reinterpret_cast<EGLClientBuffer>(static_cast<uintptr_t>(candidate.mpv_texture)));
  }
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glBindTexture(GL_TEXTURE_2D, 0);
  glFlush();
  framebuffer_complete = framebuffer_complete && glGetError() == GL_NO_ERROR;

  if (!RestoreContext(flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, error)) {
    CleanupResourceSet(self, &candidate, flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api);
    RetireIncompleteCandidate(self, candidate);
    return false;
  }
  if (!framebuffer_complete || candidate.egl_image == EGL_NO_IMAGE_KHR) {
    CleanupResourceSet(self, &candidate, flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api);
    RetireIncompleteCandidate(self, candidate);
    return SetError(error, "Failed to create a complete video framebuffer");
  }

  ClearGlErrors();
  glGenTextures(1, &candidate.flutter_texture);
  glBindTexture(GL_TEXTURE_2D, candidate.flutter_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  self->image_dispatch->image_target_texture(GL_TEXTURE_2D, reinterpret_cast<GLeglImageOES>(candidate.egl_image));
  const bool flutter_texture_complete = candidate.flutter_texture != 0 && glGetError() == GL_NO_ERROR;
  glBindTexture(GL_TEXTURE_2D, 0);
  if (!flutter_texture_complete) {
    CleanupResourceSet(self, &candidate, flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api);
    RetireIncompleteCandidate(self, candidate);
    return SetError(error, "Failed to bind the shared video image");
  }

  if (self->active->complete()) self->retired->push_back(*self->active);
  *self->active = candidate;
  CleanupRetired(self);
  return true;
}

static gboolean MpvTexturePopulate(
    FlTextureGL* texture, uint32_t* target, uint32_t* name, uint32_t* width, uint32_t* height, GError** error) {
  MpvTexture* self = MPV_TEXTURE(texture);
  g_mutex_lock(&self->mutex);
  if (self->disposed || !self->player) {
    g_object_ref(self);
    g_mutex_unlock(&self->mutex);
    SignalBootstrap(self, FALSE, "Video texture was disposed");
    g_object_unref(self);
    return SetError(error, "Video texture was disposed");
  }
  if (!self->player->HasRenderContext() && !self->player->InitRenderContext()) {
    g_mutex_unlock(&self->mutex);
    return SetError(error, "Failed to create video render context");
  }

  GtkAllocation allocation;
  gtk_widget_get_allocation(GTK_WIDGET(self->view), &allocation);
  const int scale = gtk_widget_get_scale_factor(GTK_WIDGET(self->view));
  const int32_t requested_width = allocation.width * scale;
  const int32_t requested_height = allocation.height * scale;
  if (requested_width <= 0 || requested_height <= 0) {
    g_mutex_unlock(&self->mutex);
    return SetError(error, "Video surface has no drawable size");
  }
  // GL/EGL failures during the first populate are not terminal. Flutter may
  // call populate again while waitForVideoReady owns the bounded deadline.
  if (!EnsureTextures(self, requested_width, requested_height, error)) {
    g_mutex_unlock(&self->mutex);
    return FALSE;
  }

  const EGLDisplay flutter_display = eglGetCurrentDisplay();
  const EGLContext flutter_context = eglGetCurrentContext();
  const EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  const EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
  const EGLenum flutter_api = eglQueryAPI();
  const EGLDisplay mpv_display = self->player->GetEglDisplay();
  const EGLContext mpv_context = self->player->GetEglContext();
  if (!eglBindAPI(EGL_OPENGL_ES_API) || !eglMakeCurrent(mpv_display, EGL_NO_SURFACE, EGL_NO_SURFACE, mpv_context)) {
    RestoreOrReleaseContext(flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, mpv_display);
    g_mutex_unlock(&self->mutex);
    return SetError(error, "Failed to activate video EGL context");
  }

  ClearGlErrors();
  glBindFramebuffer(GL_FRAMEBUFFER, self->active->mpv_fbo);
  self->player->ClearRedrawFlag();
  self->player->Render(requested_width, requested_height, static_cast<int>(self->active->mpv_fbo));
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glFlush();
  const bool render_succeeded = glGetError() == GL_NO_ERROR;
  if (!RestoreContext(flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, error)) {
    RestoreOrReleaseContext(flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api, mpv_display);
    g_mutex_unlock(&self->mutex);
    return FALSE;
  }
  if (!render_succeeded) {
    g_mutex_unlock(&self->mutex);
    return SetError(error, "Video render operation failed");
  }

  *target = GL_TEXTURE_2D;
  *name = self->active->flutter_texture;
  *width = static_cast<uint32_t>(requested_width);
  *height = static_cast<uint32_t>(requested_height);
  g_object_ref(self);
  g_mutex_unlock(&self->mutex);
  SignalBootstrap(self, TRUE, nullptr);
  g_object_unref(self);
  return TRUE;
}

static void MpvTextureFinalize(GObject* object) {
  MpvTexture* self = MPV_TEXTURE(object);
  if (self->ready_destroy_notify && self->ready_user_data) {
    self->ready_destroy_notify(self->ready_user_data);
  }
  g_free(self->bootstrap_error);
  delete self->active;
  delete self->retired;
  delete self->image_dispatch;
  g_mutex_clear(&self->bootstrap_mutex);
  g_mutex_clear(&self->mutex);
  G_OBJECT_CLASS(mpv_texture_parent_class)->finalize(object);
}

}  // namespace

static void mpv_texture_class_init(MpvTextureClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate = MpvTexturePopulate;
  G_OBJECT_CLASS(klass)->finalize = MpvTextureFinalize;
}

static void mpv_texture_init(MpvTexture* self) {
  self->player = nullptr;
  self->registrar = nullptr;
  self->view = nullptr;
  g_mutex_init(&self->mutex);
  self->disposed = false;
  self->active = new TextureResources();
  self->retired = new std::vector<TextureResources>();
  self->image_dispatch = new mpv::GpuImageDispatch();
  self->flutter_display = EGL_NO_DISPLAY;
  self->flutter_share_context = EGL_NO_CONTEXT;
  self->flutter_cleanup_context = EGL_NO_CONTEXT;
  g_mutex_init(&self->bootstrap_mutex);
  self->bootstrap_state = 0;
  self->bootstrap_error = nullptr;
  self->ready_callback = nullptr;
  self->ready_user_data = nullptr;
  self->ready_destroy_notify = nullptr;
}

MpvTexture* mpv_texture_new(mpv::MpvPlayer* player, FlTextureRegistrar* registrar, FlView* view) {
  MpvTexture* self = MPV_TEXTURE(g_object_new(MPV_TEXTURE_TYPE, nullptr));
  self->player = player;
  self->registrar = registrar;
  self->view = view;
  return self;
}

void mpv_texture_set_ready_callback(
    MpvTexture* self, MpvTextureReadyCallback callback, gpointer user_data, GDestroyNotify destroy_notify) {
  gboolean success = FALSE;
  const gchar* message = nullptr;
  bool complete = false;
  g_mutex_lock(&self->bootstrap_mutex);
  self->ready_callback = callback;
  self->ready_user_data = user_data;
  self->ready_destroy_notify = destroy_notify;
  if (self->bootstrap_state != 0) {
    complete = true;
    success = self->bootstrap_state == 1;
    message = self->bootstrap_error;
  }
  g_mutex_unlock(&self->bootstrap_mutex);
  if (complete && callback) callback(success, message, user_data);
}

void mpv_texture_mark_frame_available(MpvTexture* self) {
  if (!self) return;
  g_mutex_lock(&self->mutex);
  FlTextureRegistrar* registrar = self->disposed ? nullptr : self->registrar;
  g_mutex_unlock(&self->mutex);
  if (registrar) {
    fl_texture_registrar_mark_texture_frame_available(registrar, FL_TEXTURE(self));
  }
}

void mpv_texture_dispose(MpvTexture* self) {
  if (!self) return;
  g_mutex_lock(&self->mutex);
  if (self->disposed) {
    g_mutex_unlock(&self->mutex);
    return;
  }
  self->disposed = true;
  SignalBootstrap(self, FALSE, "Video initialization was cancelled");

  if (self->player) {
    const EGLDisplay flutter_display = eglGetCurrentDisplay();
    const EGLContext flutter_context = eglGetCurrentContext();
    const EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
    const EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
    const EGLenum flutter_api = eglQueryAPI();
    CleanupResourceSet(self, self->active, flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api);
    for (auto& resources : *self->retired) {
      CleanupResourceSet(self, &resources, flutter_display, flutter_draw, flutter_read, flutter_context, flutter_api);
    }
    DestroyFlutterCleanupContext(self);
    const auto leaked_sets =
        static_cast<size_t>(!ResourceSetEmpty(*self->active)) +
        static_cast<size_t>(std::count_if(self->retired->begin(), self->retired->end(), [](const auto& resources) {
          return !ResourceSetEmpty(resources);
        }));
    if (leaked_sets != 0) {
      g_warning("MPV texture: %zu resource set(s) could not be released before disposal", leaked_sets);
    }
  }
  *self->active = TextureResources{};
  self->retired->clear();
  self->player = nullptr;
  self->registrar = nullptr;
  self->view = nullptr;
  g_mutex_unlock(&self->mutex);
}

int64_t mpv_texture_get_id(MpvTexture* self) { return fl_texture_get_id(FL_TEXTURE(self)); }
