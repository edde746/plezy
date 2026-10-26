#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <mpv/client.h>
#include <mpv/render_gl.h>

#define WIDTH 1280
#define HEIGHT 720

static void *get_proc(void *opaque, const char *name) {
  (void)opaque;
  return (void *)eglGetProcAddress(name);
}

static void wakeup(void *opaque) {
  (void)opaque;
}

static int option(mpv_handle *mpv, const char *name, const char *value) {
  int err = mpv_set_option_string(mpv, name, value);
  if (err < 0) fprintf(stderr, "%s: %s\n", name, mpv_error_string(err));
  return err >= 0;
}

static int write_ppm(const char *path, const unsigned char *rgba) {
  FILE *file = fopen(path, "wb");
  if (!file) return 0;
  if (fprintf(file, "P6\n%d %d\n255\n", WIDTH, HEIGHT) < 0) {
    fclose(file);
    return 0;
  }
  for (int y = HEIGHT - 1; y >= 0; --y) {
    for (int x = 0; x < WIDTH; ++x) {
      const unsigned char *pixel = rgba + ((size_t)y * WIDTH + x) * 4;
      if (fwrite(pixel, 1, 3, file) != 3) {
        fclose(file);
        return 0;
      }
    }
  }
  return fclose(file) == 0;
}

int main(int argc, char **argv) {
  if (argc < 4 || argc > 6) {
    fprintf(stderr,
            "usage: %s input-video output.ppm log-file [capture-seconds=20.5] [hwdec=no]\n",
            argv[0]);
    return 2;
  }
  char *end = NULL;
  double capture_at = argc >= 5 ? strtod(argv[4], &end) : 20.5;
  if (!isfinite(capture_at) || capture_at < 0.5 ||
      (argc >= 5 && (!end || *end != '\0'))) {
    fprintf(stderr, "capture-seconds must be a finite number of at least 0.5\n");
    return 2;
  }
  char start_at[32];
  snprintf(start_at, sizeof(start_at), "%.6f", capture_at - 0.5);
  const char *hwdec = argc >= 6 ? argv[5] : "no";
  int result = 1;
  EGLDisplay display = EGL_NO_DISPLAY;
  EGLContext context = EGL_NO_CONTEXT;
  EGLSurface surface = EGL_NO_SURFACE;
  mpv_handle *mpv = NULL;
  mpv_render_context *renderer = NULL;
  GLuint texture = 0, framebuffer = 0;
  unsigned char *pixels = NULL;

  display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display == EGL_NO_DISPLAY || !eglInitialize(display, NULL, NULL) ||
      !eglBindAPI(EGL_OPENGL_ES_API)) goto cleanup;
  const EGLint config_attrs[] = {
      EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
      EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8,
      EGL_ALPHA_SIZE, 8, EGL_NONE};
  EGLConfig config;
  EGLint count = 0;
  if (!eglChooseConfig(display, config_attrs, &config, 1, &count) || count != 1) goto cleanup;
  const EGLint context_attrs[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
  const EGLint surface_attrs[] = {EGL_WIDTH, WIDTH, EGL_HEIGHT, HEIGHT, EGL_NONE};
  context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attrs);
  surface = eglCreatePbufferSurface(display, config, surface_attrs);
  if (context == EGL_NO_CONTEXT || surface == EGL_NO_SURFACE ||
      !eglMakeCurrent(display, surface, surface, context)) goto cleanup;
  printf("GL renderer: %s; %s\n", glGetString(GL_RENDERER), glGetString(GL_VERSION));

  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, WIDTH, HEIGHT, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, NULL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glGenFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         texture, 0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) goto cleanup;

  mpv = mpv_create();
  if (!mpv || !option(mpv, "config", "no") ||
      !option(mpv, "load-scripts", "no") || !option(mpv, "vo", "libmpv") ||
      !option(mpv, "hwdec", hwdec) || !option(mpv, "audio", "no") ||
      !option(mpv, "keep-open", "yes") || !option(mpv, "terminal", "yes") ||
      !option(mpv, "start", start_at) || !option(mpv, "msg-level",
          "all=info,demux=debug,vd=debug") ||
      !option(mpv, "log-file", argv[3]) || mpv_initialize(mpv) < 0) goto cleanup;

  mpv_opengl_init_params init = {.get_proc_address = get_proc};
  mpv_render_param create_params[] = {
      {MPV_RENDER_PARAM_API_TYPE, (void *)MPV_RENDER_API_TYPE_OPENGL_NEXT},
      {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &init}, {0, NULL}};
  int err = mpv_render_context_create(&renderer, mpv, create_params);
  if (err < 0) {
    fprintf(stderr, "opengl-next context creation failed: %s\n", mpv_error_string(err));
    goto cleanup;
  }
  mpv_render_context_set_update_callback(renderer, wakeup, NULL);
  const char *load[] = {"loadfile", argv[1], NULL};
  if (mpv_command(mpv, load) < 0) goto cleanup;

  mpv_opengl_fbo fbo = {
      .fbo = (int)framebuffer, .w = WIDTH, .h = HEIGHT,
      .internal_format = GL_RGBA8};
  int depth = 8;
  int flip_y = 1;
  mpv_render_param render_params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
      {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
      {MPV_RENDER_PARAM_DEPTH, &depth}, {0, NULL}};
  pixels = calloc((size_t)WIDTH * HEIGHT, 4);
  if (!pixels) goto cleanup;

  double position = -1.0;
  int captured = 0;
  int stopping = 0;
  for (int attempt = 0; attempt < 4200; ++attempt) {
    mpv_event *event = mpv_wait_event(mpv, 0.01);
    if (event->event_id == MPV_EVENT_END_FILE) {
      mpv_event_end_file *end = event->data;
      if (end && end->reason == MPV_END_FILE_REASON_ERROR) {
        fprintf(stderr, "mpv ended with error: %s\n", mpv_error_string(end->error));
        break;
      }
      if (stopping) break;
    }
    if (stopping) continue;
    if (!(mpv_render_context_update(renderer) & MPV_RENDER_UPDATE_FRAME)) continue;
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    if (mpv_render_context_render(renderer, render_params) < 0) break;
    if (mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &position) < 0) continue;
    // mpv can leave another framebuffer bound; restore the capture target.
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    if (!captured && position >= capture_at) {
      glFinish();
      glPixelStorei(GL_PACK_ALIGNMENT, 1);
      glReadPixels(0, 0, WIDTH, HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
      if (glGetError() != GL_NO_ERROR || !write_ppm(argv[2], pixels)) break;
      printf("Embedded opengl-next rendered and read back at %.6f s with hwdec=%s: %s\n",
             position, hwdec, argv[2]);
      captured = 1;
      result = 0;
    }
    mpv_render_context_report_swap(renderer);
    if (captured) {
      const char *stop[] = {"stop", NULL};
      if (mpv_command(mpv, stop) < 0) {
        result = 1;
        break;
      }
      stopping = 1;
    }
  }

cleanup:
  if (result) fprintf(stderr, "Embedded P7 render failed (EGL error 0x%x)\n", eglGetError());
  free(pixels);
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
  return result;
}
