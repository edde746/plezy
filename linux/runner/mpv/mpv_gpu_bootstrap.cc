#include "mpv_gpu_bootstrap.h"

#include <cstdlib>
#include <cstring>

namespace mpv {
namespace {

bool HasExtension(const char* extensions, const char* requested) {
  if (!extensions || !requested || requested[0] == '\0' || std::strchr(requested, ' ')) return false;
  const size_t requested_length = std::strlen(requested);
  const char* current = extensions;
  while ((current = std::strstr(current, requested)) != nullptr) {
    const bool starts_token = current == extensions || current[-1] == ' ';
    const char following = current[requested_length];
    if (starts_token && (following == '\0' || following == ' ')) return true;
    current += requested_length;
  }
  return false;
}

bool ParseEglVersion(const char* version, int* major, int* minor) {
  if (!version || !major || !minor) return false;
  char* end = nullptr;
  const long parsed_major = std::strtol(version, &end, 10);
  if (end == version || *end != '.') return false;
  const char* minor_start = end + 1;
  const long parsed_minor = std::strtol(minor_start, &end, 10);
  if (end == minor_start || parsed_major < 0 || parsed_minor < 0) return false;
  *major = static_cast<int>(parsed_major);
  *minor = static_cast<int>(parsed_minor);
  return true;
}

bool AtLeastEgl15(const GpuBootstrapProbe& probe) {
  return probe.egl_major > 1 || (probe.egl_major == 1 && probe.egl_minor >= 5);
}

bool Fail(std::string* error, const char* message) {
  if (error) *error = message;
  return false;
}

}  // namespace

EGLImageKHR GpuImageDispatch::Create(EGLDisplay display, EGLContext context, EGLClientBuffer buffer) const {
  if (uses_core) {
    if (!create_image_core) return EGL_NO_IMAGE_KHR;
    const EGLAttrib attributes[] = {EGL_NONE};
    return reinterpret_cast<EGLImageKHR>(
        create_image_core(display, context, EGL_GL_TEXTURE_2D_KHR, buffer, attributes));
  }
  if (!create_image_khr) return EGL_NO_IMAGE_KHR;
  const EGLint attributes[] = {EGL_NONE};
  return create_image_khr(display, context, EGL_GL_TEXTURE_2D_KHR, buffer, attributes);
}

bool GpuImageDispatch::Destroy(EGLDisplay display, EGLImageKHR image) const {
  if (image == EGL_NO_IMAGE_KHR) return true;
  if (uses_core) {
    return destroy_image_core && destroy_image_core(display, reinterpret_cast<EGLImage>(image)) == EGL_TRUE;
  }
  return destroy_image_khr && destroy_image_khr(display, image) == EGL_TRUE;
}

GpuImageDispatch::operator bool() const {
  const bool image_functions =
      uses_core ? create_image_core && destroy_image_core : create_image_khr && destroy_image_khr;
  return image_functions && image_target_texture;
}

bool ValidateGpuBootstrapProbe(const GpuBootstrapProbe& probe, std::string* error) {
  const bool egl15 = AtLeastEgl15(probe);
  if (!egl15 && !HasExtension(probe.egl_extensions, "EGL_KHR_surfaceless_context")) {
    return Fail(error, "EGL surfaceless contexts are unavailable");
  }

  const bool core_images = egl15 && probe.create_image_core && probe.destroy_image_core;
  const bool has_khr_image_extension =
      HasExtension(probe.egl_extensions, "EGL_KHR_image") || HasExtension(probe.egl_extensions, "EGL_KHR_image_base");
  const bool khr_images = has_khr_image_extension && probe.create_image_khr && probe.destroy_image_khr;
  if (!core_images && !khr_images) {
    return Fail(error, "EGL image creation is unavailable");
  }
  if (!HasExtension(probe.gl_extensions, "GL_OES_EGL_image")) {
    return Fail(error, "OpenGL EGL image binding is unavailable");
  }
  if (!probe.image_target_texture) {
    return Fail(error, "OpenGL EGL image entry point is unavailable");
  }
  if (error) error->clear();
  return true;
}

bool ResolveGpuImageDispatch(EGLDisplay display, GpuImageDispatch* dispatch, std::string* error) {
  if (!dispatch || display == EGL_NO_DISPLAY || eglGetCurrentContext() == EGL_NO_CONTEXT) {
    return Fail(error, "No current EGL context is available");
  }

  GpuBootstrapProbe probe;
  if (!ParseEglVersion(eglQueryString(display, EGL_VERSION), &probe.egl_major, &probe.egl_minor)) {
    return Fail(error, "EGL version is unavailable");
  }
  probe.egl_extensions = eglQueryString(display, EGL_EXTENSIONS);
  probe.gl_extensions = reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
  probe.create_image_core = reinterpret_cast<void*>(eglGetProcAddress("eglCreateImage"));
  probe.destroy_image_core = reinterpret_cast<void*>(eglGetProcAddress("eglDestroyImage"));
  probe.create_image_khr = reinterpret_cast<void*>(eglGetProcAddress("eglCreateImageKHR"));
  probe.destroy_image_khr = reinterpret_cast<void*>(eglGetProcAddress("eglDestroyImageKHR"));
  probe.image_target_texture = reinterpret_cast<void*>(eglGetProcAddress("glEGLImageTargetTexture2DOES"));
  if (!ValidateGpuBootstrapProbe(probe, error)) return false;

  GpuImageDispatch resolved;
  const bool egl15 = AtLeastEgl15(probe);
  if (egl15 && probe.create_image_core && probe.destroy_image_core) {
    resolved.uses_core = true;
    resolved.create_image_core = reinterpret_cast<EglCreateImageCoreProc>(probe.create_image_core);
    resolved.destroy_image_core = reinterpret_cast<EglDestroyImageCoreProc>(probe.destroy_image_core);
  } else {
    resolved.create_image_khr = reinterpret_cast<EglCreateImageKhrProc>(probe.create_image_khr);
    resolved.destroy_image_khr = reinterpret_cast<EglDestroyImageKhrProc>(probe.destroy_image_khr);
  }
  resolved.image_target_texture = reinterpret_cast<GlImageTargetTextureProc>(probe.image_target_texture);
  if (!resolved) return Fail(error, "GPU image dispatch is incomplete");
  *dispatch = resolved;
  return true;
}

}  // namespace mpv
