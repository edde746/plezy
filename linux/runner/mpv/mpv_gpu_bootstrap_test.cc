#include "mpv_gpu_bootstrap.h"

#include <iostream>
#include <string>

namespace {

int create_calls = 0;
int destroy_calls = 0;
int failures = 0;

void Expect(bool condition, const char* expression, int line) {
  if (condition) return;
  std::cerr << "line " << line << ": check failed: " << expression << '\n';
  ++failures;
}

#define EXPECT(condition) Expect(static_cast<bool>(condition), #condition, __LINE__)

EGLImageKHR CreateImageKhr(EGLDisplay, EGLContext, EGLenum, EGLClientBuffer, const EGLint*) {
  ++create_calls;
  return reinterpret_cast<EGLImageKHR>(0x1234);
}

EGLBoolean DestroyImageKhr(EGLDisplay, EGLImageKHR image) {
  EXPECT(image == reinterpret_cast<EGLImageKHR>(0x1234));
  ++destroy_calls;
  return EGL_TRUE;
}

void BindImage(GLenum, GLeglImageOES) {}

template <typename Function>
void* Address(Function function) {
  return reinterpret_cast<void*>(function);
}

mpv::GpuBootstrapProbe SupportedKhrProbe() {
  mpv::GpuBootstrapProbe probe;
  probe.egl_major = 1;
  probe.egl_minor = 4;
  probe.egl_extensions = "EGL_KHR_surfaceless_context EGL_KHR_image_base";
  probe.gl_extensions = "GL_EXT_texture GL_OES_EGL_image";
  probe.create_image_khr = Address(CreateImageKhr);
  probe.destroy_image_khr = Address(DestroyImageKhr);
  probe.image_target_texture = Address(BindImage);
  return probe;
}

void TestKhrCapabilitiesFailClosed() {
  std::string error;
  auto probe = SupportedKhrProbe();
  EXPECT(mpv::ValidateGpuBootstrapProbe(probe, &error));
  EXPECT(error.empty());

  probe.egl_extensions = "EGL_KHR_image_base";
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.egl_extensions = "EGL_KHR_surfaceless_context EGL_KHR_image";
  EXPECT(mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.egl_extensions = "EGL_KHR_surfaceless_context EGL_KHR_image_suffix";
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.egl_extensions = "EGL_KHR_surfaceless_context";
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.gl_extensions = "GL_OES_EGL_image_external";
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));

  probe = SupportedKhrProbe();
  probe.create_image_khr = nullptr;
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.destroy_image_khr = nullptr;
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.image_target_texture = nullptr;
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
}

void TestCoreCapabilities() {
  std::string error;
  auto probe = SupportedKhrProbe();
  probe.egl_major = 1;
  probe.egl_minor = 5;
  probe.egl_extensions = "";
  probe.create_image_khr = nullptr;
  probe.destroy_image_khr = nullptr;
  probe.create_image_core = Address(CreateImageKhr);
  probe.destroy_image_core = Address(DestroyImageKhr);
  EXPECT(mpv::ValidateGpuBootstrapProbe(probe, &error));

  probe.create_image_core = nullptr;
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
  probe = SupportedKhrProbe();
  probe.egl_major = 0;
  probe.egl_minor = 0;
  probe.egl_extensions = "";
  EXPECT(!mpv::ValidateGpuBootstrapProbe(probe, &error));
}

void TestDispatchChecksBeforeCalls() {
  mpv::GpuImageDispatch dispatch;
  EXPECT(!dispatch);
  EXPECT(dispatch.Create(EGL_NO_DISPLAY, EGL_NO_CONTEXT, nullptr) == EGL_NO_IMAGE_KHR);
  EXPECT(!dispatch.Destroy(EGL_NO_DISPLAY, reinterpret_cast<EGLImageKHR>(0x1234)));
  EXPECT(create_calls == 0);
  EXPECT(destroy_calls == 0);

  dispatch.create_image_khr = CreateImageKhr;
  dispatch.destroy_image_khr = DestroyImageKhr;
  dispatch.image_target_texture = BindImage;
  EXPECT(dispatch);
  const auto image = dispatch.Create(EGL_NO_DISPLAY, EGL_NO_CONTEXT, nullptr);
  EXPECT(image == reinterpret_cast<EGLImageKHR>(0x1234));
  EXPECT(dispatch.Destroy(EGL_NO_DISPLAY, image));
  EXPECT(create_calls == 1);
  EXPECT(destroy_calls == 1);
}

}  // namespace

int main() {
  TestKhrCapabilitiesFailClosed();
  TestCoreCapabilities();
  TestDispatchChecksBeforeCalls();
  return failures == 0 ? 0 : 1;
}
