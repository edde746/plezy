// Decode a known PPM through libmpv and render it through the experimental
// gpu-next API into an ES FBO. This tests embedding, not FEL pixel fidelity.
#include <stdio.h>
#include <stdlib.h>

#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <mpv/client.h>
#include <mpv/render_gl.h>

static void* get_proc(void* opaque, const char* name) {
  (void)opaque;
  return (void*)eglGetProcAddress(name);
}

static void wakeup(void* opaque) {
  (void)opaque;  // The bounded test loop polls; no app/UI thread is involved.
}

static int option(mpv_handle* mpv, const char* name, const char* value) {
  int err = mpv_set_option_string(mpv, name, value);
  if (err < 0) fprintf(stderr, "%s: %s\n", name, mpv_error_string(err));
  return err >= 0;
}

int main(int argc, char** argv) {
  int result = 1;
  EGLDisplay display = EGL_NO_DISPLAY;
  EGLContext context = EGL_NO_CONTEXT;
  EGLSurface surface = EGL_NO_SURFACE;
  mpv_handle* mpv = NULL;
  mpv_render_context* renderer = NULL;
  GLuint texture = 0, framebuffer = 0;
  if (argc != 2) return 2;
  FILE* file = fopen(argv[1], "wb");
  if (!file) return 2;
  fputs("P6\n32 32\n255\n", file);
  for (int i = 0; i < 32 * 32; ++i) {
    const unsigned char red[] = {255, 0, 0};
    if (fwrite(red, 1, sizeof(red), file) != sizeof(red)) {
      fclose(file);
      return 2;
    }
  }
  if (fclose(file) != 0) return 2;

  display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display == EGL_NO_DISPLAY || !eglInitialize(display, NULL, NULL) ||
      !eglBindAPI(EGL_OPENGL_ES_API)) goto cleanup;
  const EGLint attributes[] = {
      EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
      EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
  EGLConfig config;
  EGLint count = 0;
  if (!eglChooseConfig(display, attributes, &config, 1, &count) || count != 1) goto cleanup;
  const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
  const EGLint surface_attributes[] = {EGL_WIDTH, 32, EGL_HEIGHT, 32, EGL_NONE};
  context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes);
  surface = eglCreatePbufferSurface(display, config, surface_attributes);
  if (context == EGL_NO_CONTEXT || surface == EGL_NO_SURFACE ||
      !eglMakeCurrent(display, surface, surface, context)) goto cleanup;

  printf("GL renderer: %s; %s\n", glGetString(GL_RENDERER), glGetString(GL_VERSION));
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 32, 32, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glGenFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) goto cleanup;

  mpv = mpv_create();
  if (!mpv || !option(mpv, "config", "no") || !option(mpv, "load-scripts", "no") ||
      !option(mpv, "vo", "libmpv") || !option(mpv, "hwdec", "no") ||
      !option(mpv, "audio", "no") || !option(mpv, "keep-open", "yes") ||
      !option(mpv, "terminal", "yes") || mpv_initialize(mpv) < 0) goto cleanup;

  mpv_opengl_init_params init = {.get_proc_address = get_proc};
  mpv_render_param create_params[] = {
      {MPV_RENDER_PARAM_API_TYPE, (void*)MPV_RENDER_API_TYPE_OPENGL_NEXT},
      {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &init}, {0, NULL}};
  int err = mpv_render_context_create(&renderer, mpv, create_params);
  if (err < 0) {
    fprintf(stderr, "opengl-next creation failed: %s\n", mpv_error_string(err));
    goto cleanup;
  }
  mpv_render_context_set_update_callback(renderer, wakeup, NULL);
  const char* command[] = {"loadfile", argv[1], NULL};
  if (mpv_command(mpv, command) < 0) goto cleanup;

  mpv_opengl_fbo fbo = {.fbo = (int)framebuffer, .w = 32, .h = 32, .internal_format = GL_RGBA8};
  int depth = 8;
  mpv_render_param render_params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &fbo}, {MPV_RENDER_PARAM_DEPTH, &depth}, {0, NULL}};
  for (int attempt = 0; attempt < 500; ++attempt) {
    mpv_event* event = mpv_wait_event(mpv, 0.01);
    if (event->event_id == MPV_EVENT_END_FILE &&
        ((mpv_event_end_file*)event->data)->reason == MPV_END_FILE_REASON_ERROR) break;
    if (!(mpv_render_context_update(renderer) & MPV_RENDER_UPDATE_FRAME)) continue;
    if (mpv_render_context_render(renderer, render_params) < 0) break;
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    unsigned char pixel[4] = {0};
    glReadPixels(16, 16, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
    if (glGetError() != GL_NO_ERROR) break;
    if (pixel[0] > 200 && pixel[1] < 80 && pixel[2] < 80) {
      printf("opengl-next ES decode/render/readback passed: %u %u %u\n",
             pixel[0], pixel[1], pixel[2]);
      result = 0;
      break;
    }
  }

cleanup:
  if (result) fprintf(stderr, "Embedded render smoke failed (EGL error 0x%x)\n", eglGetError());
  if (renderer) mpv_render_context_free(renderer);
  if (mpv) mpv_terminate_destroy(mpv);
  if (context != EGL_NO_CONTEXT) {
    if (framebuffer) glDeleteFramebuffers(1, &framebuffer);
    if (texture) glDeleteTextures(1, &texture);
    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(display, context);
  }
  if (surface != EGL_NO_SURFACE) eglDestroySurface(display, surface);
  if (display != EGL_NO_DISPLAY) eglTerminate(display);
  remove(argv[1]);
  return result;
}
