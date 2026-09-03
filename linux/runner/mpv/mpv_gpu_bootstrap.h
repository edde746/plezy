#ifndef MPV_GPU_BOOTSTRAP_H_
#define MPV_GPU_BOOTSTRAP_H_

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include <string>

namespace mpv {

using EglCreateImageCoreProc = EGLImage (*)(EGLDisplay, EGLContext, EGLenum, EGLClientBuffer, const EGLAttrib*);
using EglDestroyImageCoreProc = EGLBoolean (*)(EGLDisplay, EGLImage);
using EglCreateImageKhrProc = EGLImageKHR (*)(EGLDisplay, EGLContext, EGLenum, EGLClientBuffer, const EGLint*);
using EglDestroyImageKhrProc = EGLBoolean (*)(EGLDisplay, EGLImageKHR);
using GlImageTargetTextureProc = void (*)(GLenum, GLeglImageOES);

struct GpuBootstrapProbe {
  int egl_major = 0;
  int egl_minor = 0;
  const char* egl_extensions = nullptr;
  const char* gl_extensions = nullptr;
  void* create_image_core = nullptr;
  void* destroy_image_core = nullptr;
  void* create_image_khr = nullptr;
  void* destroy_image_khr = nullptr;
  void* image_target_texture = nullptr;
};

struct GpuImageDispatch {
  bool uses_core = false;
  EglCreateImageCoreProc create_image_core = nullptr;
  EglDestroyImageCoreProc destroy_image_core = nullptr;
  EglCreateImageKhrProc create_image_khr = nullptr;
  EglDestroyImageKhrProc destroy_image_khr = nullptr;
  GlImageTargetTextureProc image_target_texture = nullptr;

  EGLImageKHR Create(EGLDisplay display, EGLContext context, EGLClientBuffer buffer) const;
  bool Destroy(EGLDisplay display, EGLImageKHR image) const;
  explicit operator bool() const;
};

bool ValidateGpuBootstrapProbe(const GpuBootstrapProbe& probe, std::string* error);
bool ResolveGpuImageDispatch(EGLDisplay display, GpuImageDispatch* dispatch, std::string* error);

}  // namespace mpv

#endif  // MPV_GPU_BOOTSTRAP_H_
