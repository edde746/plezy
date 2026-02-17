#include "mpv_texture.h"

#include <epoxy/gl.h>

struct _MpvTexture {
  FlTextureGL parent_instance;

  mpv::MpvPlayer* player;          // not owned
  FlTextureRegistrar* registrar;   // not owned
  FlView* view;                    // not owned, for querying allocation size

  GLuint fbo;
  GLuint texture;
  int32_t width;
  int32_t height;
};

G_DEFINE_TYPE(MpvTexture, mpv_texture, fl_texture_gl_get_type())

static void ensure_fbo(MpvTexture* self, int32_t w, int32_t h) {
  if (self->fbo != 0 && self->width == w && self->height == h) {
    return;
  }

  // Delete old resources.
  if (self->fbo != 0) {
    glDeleteFramebuffers(1, &self->fbo);
    self->fbo = 0;
  }
  if (self->texture != 0) {
    glDeleteTextures(1, &self->texture);
    self->texture = 0;
  }

  self->width = w;
  self->height = h;

  glGenTextures(1, &self->texture);
  glBindTexture(GL_TEXTURE_2D, self->texture);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, nullptr);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  glGenFramebuffers(1, &self->fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, self->fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         self->texture, 0);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
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

  ensure_fbo(self, w, h);

  // Save GL state that mpv may clobber.
  GLint prev_viewport[4];
  GLint prev_scissor_box[4];
  GLboolean prev_blend, prev_scissor_test;
  GLint prev_blend_src, prev_blend_dst;
  GLint prev_fbo;

  glGetIntegerv(GL_VIEWPORT, prev_viewport);
  glGetIntegerv(GL_SCISSOR_BOX, prev_scissor_box);
  glGetBooleanv(GL_BLEND, &prev_blend);
  glGetBooleanv(GL_SCISSOR_TEST, &prev_scissor_test);
  glGetIntegerv(GL_BLEND_SRC_ALPHA, &prev_blend_src);
  glGetIntegerv(GL_BLEND_DST_ALPHA, &prev_blend_dst);
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prev_fbo);

  // Render mpv into our FBO.
  glBindFramebuffer(GL_FRAMEBUFFER, self->fbo);
  glViewport(0, 0, w, h);
  self->player->ClearRedrawFlag();
  self->player->Render(w, h, static_cast<int>(self->fbo));

  // Restore GL state.
  glViewport(prev_viewport[0], prev_viewport[1], prev_viewport[2],
             prev_viewport[3]);
  glScissor(prev_scissor_box[0], prev_scissor_box[1], prev_scissor_box[2],
            prev_scissor_box[3]);
  if (prev_blend)
    glEnable(GL_BLEND);
  else
    glDisable(GL_BLEND);
  if (prev_scissor_test)
    glEnable(GL_SCISSOR_TEST);
  else
    glDisable(GL_SCISSOR_TEST);
  glBlendFunc(prev_blend_src, prev_blend_dst);
  glBindFramebuffer(GL_FRAMEBUFFER, prev_fbo);

  *target = GL_TEXTURE_2D;
  *name = self->texture;
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
  self->fbo = 0;
  self->texture = 0;
  self->width = 0;
  self->height = 0;
}

MpvTexture* mpv_texture_new(mpv::MpvPlayer* player,
                            FlTextureRegistrar* registrar,
                            FlView* view) {
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

  if (self->fbo != 0) {
    glDeleteFramebuffers(1, &self->fbo);
    self->fbo = 0;
  }
  if (self->texture != 0) {
    glDeleteTextures(1, &self->texture);
    self->texture = 0;
  }

  self->player = nullptr;
  self->registrar = nullptr;
  self->view = nullptr;
}

int64_t mpv_texture_get_id(MpvTexture* self) {
  return fl_texture_get_id(FL_TEXTURE(self));
}
