#include "mpv_texture.h"

#include <epoxy/gl.h>
#include <epoxy/egl.h>

// EGLImage extension function pointers
typedef EGLImageKHR (*PFNEGLCREATEIMAGEKHRPROC)(EGLDisplay, EGLContext, EGLenum, EGLClientBuffer, const EGLint*);
typedef EGLBoolean (*PFNEGLDESTROYIMAGEKHRPROC)(EGLDisplay, EGLImageKHR);
typedef void (*PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)(GLenum, GLeglImageOES);

static PFNEGLCREATEIMAGEKHRPROC _eglCreateImageKHR = nullptr;
static PFNEGLDESTROYIMAGEKHRPROC _eglDestroyImageKHR = nullptr;
static PFNGLEGLIMAGETARGETTEXTURE2DOESPROC _glEGLImageTargetTexture2DOES = nullptr;

static void init_egl_image_extensions() {
  static bool initialized = false;
  if (!initialized) {
    _eglCreateImageKHR = (PFNEGLCREATEIMAGEKHRPROC)eglGetProcAddress("eglCreateImageKHR");
    _eglDestroyImageKHR = (PFNEGLDESTROYIMAGEKHRPROC)eglGetProcAddress("eglDestroyImageKHR");
    _glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
    initialized = true;
  }
}

struct _MpvTexture {
  FlTextureGL parent_instance;

  mpv::MpvPlayer* player;          // not owned
  FlTextureRegistrar* registrar;   // not owned
  FlView* view;                    // not owned, for querying allocation size

  // mpv's FBO and texture (owned by mpv's isolated EGL context)
  GLuint mpv_fbo;
  GLuint mpv_texture;

  // Flutter's texture (owned by Flutter's EGL context)
  GLuint flutter_texture;

  // EGLImage bridging the two contexts
  EGLImageKHR egl_image;

  int32_t width;
  int32_t height;
};

G_DEFINE_TYPE(MpvTexture, mpv_texture, fl_texture_gl_get_type())

// Create/resize the FBO in mpv's context and the shared EGLImage + Flutter texture.
static void ensure_textures(MpvTexture* self, int32_t w, int32_t h) {
  if (self->mpv_fbo != 0 && self->width == w && self->height == h) {
    return;
  }

  EGLDisplay egl_display = self->player->GetEglDisplay();
  EGLContext egl_context = self->player->GetEglContext();

  // Save Flutter's current EGL state
  EGLDisplay flutter_display = eglGetCurrentDisplay();
  EGLContext flutter_context = eglGetCurrentContext();
  EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);

  // --- Switch to mpv's isolated context ---
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);

  // Clean up previous mpv resources
  if (self->mpv_texture != 0) {
    glDeleteTextures(1, &self->mpv_texture);
  }
  if (self->mpv_fbo != 0) {
    glDeleteFramebuffers(1, &self->mpv_fbo);
  }
  if (self->egl_image != EGL_NO_IMAGE_KHR) {
    _eglDestroyImageKHR(egl_display, self->egl_image);
  }

  self->width = w;
  self->height = h;

  // Create mpv's texture and FBO
  glGenTextures(1, &self->mpv_texture);
  glBindTexture(GL_TEXTURE_2D, self->mpv_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, nullptr);

  glGenFramebuffers(1, &self->mpv_fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, self->mpv_fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D, self->mpv_texture, 0);

  // Create EGLImage from mpv's texture for cross-context sharing
  EGLint image_attribs[] = { EGL_NONE };
  self->egl_image = _eglCreateImageKHR(
      egl_display, egl_context, EGL_GL_TEXTURE_2D_KHR,
      (EGLClientBuffer)(uintptr_t)self->mpv_texture, image_attribs);

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glBindTexture(GL_TEXTURE_2D, 0);
  glFlush();

  // --- Switch back to Flutter's context ---
  eglMakeCurrent(flutter_display, flutter_draw, flutter_read, flutter_context);

  // Clean up previous Flutter texture
  if (self->flutter_texture != 0) {
    glDeleteTextures(1, &self->flutter_texture);
  }

  // Create Flutter's texture backed by the EGLImage
  glGenTextures(1, &self->flutter_texture);
  glBindTexture(GL_TEXTURE_2D, self->flutter_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  _glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, self->egl_image);
  glBindTexture(GL_TEXTURE_2D, 0);
}

static gboolean mpv_texture_populate(FlTextureGL* gl_texture,
                                     uint32_t* target,
                                     uint32_t* name,
                                     uint32_t* width,
                                     uint32_t* height,
                                     GError** error) {
  MpvTexture* self = MPV_TEXTURE(gl_texture);

  if (!self->player) {
    return FALSE;
  }

  // Lazily create the mpv render context on first populate() call,
  // since Flutter's GL context is current here.
  if (!self->player->HasRenderContext()) {
    if (!self->player->InitRenderContext()) {
      g_set_error(error, g_quark_from_static_string("mpv"), 0,
                  "Failed to create mpv render context");
      return FALSE;
    }
  }

  // Determine target size from the FlView widget allocation.
  GtkAllocation alloc;
  gtk_widget_get_allocation(GTK_WIDGET(self->view), &alloc);
  int scale = gtk_widget_get_scale_factor(GTK_WIDGET(self->view));
  int32_t w = alloc.width * scale;
  int32_t h = alloc.height * scale;

  if (w <= 0 || h <= 0) {
    return FALSE;
  }

  ensure_textures(self, w, h);

  // Save Flutter's current EGL state
  EGLDisplay flutter_display = eglGetCurrentDisplay();
  EGLContext flutter_context = eglGetCurrentContext();
  EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);

  // Switch to mpv's isolated context for rendering
  EGLDisplay egl_display = self->player->GetEglDisplay();
  EGLContext egl_context = self->player->GetEglContext();
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);

  // Render mpv into its FBO
  glBindFramebuffer(GL_FRAMEBUFFER, self->mpv_fbo);
  self->player->ClearRedrawFlag();
  self->player->Render(w, h, static_cast<int>(self->mpv_fbo));
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glFlush();

  // Restore Flutter's context
  eglMakeCurrent(flutter_display, flutter_draw, flutter_read, flutter_context);

  *target = GL_TEXTURE_2D;
  *name = self->flutter_texture;
  *width = static_cast<uint32_t>(w);
  *height = static_cast<uint32_t>(h);

  return TRUE;
}

static void mpv_texture_class_init(MpvTextureClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate = mpv_texture_populate;
}

static void mpv_texture_init(MpvTexture* self) {
  self->player = nullptr;
  self->registrar = nullptr;
  self->view = nullptr;
  self->mpv_fbo = 0;
  self->mpv_texture = 0;
  self->flutter_texture = 0;
  self->egl_image = EGL_NO_IMAGE_KHR;
  self->width = 0;
  self->height = 0;
}

MpvTexture* mpv_texture_new(mpv::MpvPlayer* player,
                            FlTextureRegistrar* registrar,
                            FlView* view) {
  init_egl_image_extensions();
  MpvTexture* self = MPV_TEXTURE(g_object_new(MPV_TEXTURE_TYPE, nullptr));
  self->player = player;
  self->registrar = registrar;
  self->view = view;
  return self;
}

void mpv_texture_mark_frame_available(MpvTexture* self) {
  if (self && self->registrar) {
    fl_texture_registrar_mark_texture_frame_available(
        self->registrar, FL_TEXTURE(self));
  }
}

void mpv_texture_dispose(MpvTexture* self) {
  if (!self) return;

  EGLDisplay egl_display = EGL_NO_DISPLAY;
  EGLContext egl_context = EGL_NO_CONTEXT;

  if (self->player) {
    egl_display = self->player->GetEglDisplay();
    egl_context = self->player->GetEglContext();
  }

  // Clean up Flutter's texture (in Flutter's current context)
  if (self->flutter_texture != 0) {
    glDeleteTextures(1, &self->flutter_texture);
    self->flutter_texture = 0;
  }

  // Clean up EGLImage
  if (self->egl_image != EGL_NO_IMAGE_KHR && egl_display != EGL_NO_DISPLAY) {
    _eglDestroyImageKHR(egl_display, self->egl_image);
    self->egl_image = EGL_NO_IMAGE_KHR;
  }

  // Clean up mpv's GL resources in mpv's context
  if (egl_context != EGL_NO_CONTEXT) {
    EGLDisplay cur_display = eglGetCurrentDisplay();
    EGLContext cur_context = eglGetCurrentContext();
    EGLSurface cur_draw = eglGetCurrentSurface(EGL_DRAW);
    EGLSurface cur_read = eglGetCurrentSurface(EGL_READ);

    eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);

    if (self->mpv_texture != 0) {
      glDeleteTextures(1, &self->mpv_texture);
      self->mpv_texture = 0;
    }
    if (self->mpv_fbo != 0) {
      glDeleteFramebuffers(1, &self->mpv_fbo);
      self->mpv_fbo = 0;
    }

    eglMakeCurrent(cur_display, cur_draw, cur_read, cur_context);
  }

  self->player = nullptr;
  self->registrar = nullptr;
  self->view = nullptr;
}

int64_t mpv_texture_get_id(MpvTexture* self) {
  return fl_texture_get_id(FL_TEXTURE(self));
}
