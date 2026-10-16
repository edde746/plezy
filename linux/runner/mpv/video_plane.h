#ifndef PLEZY_LINUX_MPV_VIDEO_PLANE_H_
#define PLEZY_LINUX_MPV_VIDEO_PLANE_H_

#include <epoxy/egl.h>
#include <gtk/gtk.h>

#include <cstdint>
#include <functional>
#include <string>

#include "hdr_metadata.h"

namespace mpv {

struct PreferredColorDescription;

// The window mpv's EGL surface is attached to.
class VideoPlane {
 public:
  VideoPlane() = default;
  virtual ~VideoPlane() = default;

  VideoPlane(const VideoPlane&) = delete;
  VideoPlane& operator=(const VideoPlane&) = delete;

  virtual bool Create(GtkWidget* view, std::string* error) = 0;
  virtual void Destroy() = 0;

  virtual bool valid() const = 0;
  virtual EGLDisplay egl_display() const = 0;
  virtual EGLConfig egl_config() const = 0;
  virtual EGLSurface egl_surface() const = 0;

  // Drawable size
  virtual int32_t width() const = 0;
  virtual int32_t height() const = 0;
  virtual bool has_size() const = 0;

  // Physical-pixel rect in the Flutter view, plus the view's scale, as Dart
  // sends them via setVideoRect.
  virtual void SetRect(int32_t x, int32_t y, int32_t width, int32_t height, int32_t scale) = 0;
  virtual void SetVisible(bool visible) = 0;
  virtual bool visible() const = 0;
  virtual bool frame_pending() const = 0;
  virtual bool first_frame_presented() const = 0;

  virtual void SetFrameCallback(std::function<void()> callback) = 0;
  virtual void SetForcedRenderCallback(std::function<void()> callback) { (void)callback; }
  virtual bool PreparePresent() = 0;
  virtual bool CompletePresent(bool swapped) = 0;

  // X11 only. Called on the render thread with the plane's EGL context current,
  // after mpv has drawn and before the swap. Blends the latest Flutter frame
  // over the picture.
  virtual void BlendOverlay() {}

  virtual bool supports_hdr() const { return false; }
  // Defined in wayland_video_surface.cc.
  // x11 dosn't have HDR (empty)
  virtual const PreferredColorDescription& preferred() const;
  virtual bool output_is_hdr() const { return false; }
  virtual void SetPreferredChangedCallback(std::function<void()> callback) { (void)callback; }
  virtual void SetMonitorEnteredCallback(std::function<void(GdkMonitor*)> callback) { (void)callback; }
  virtual int depth_bits() const { return 8; }

  virtual void BeginHdrTransition(
      bool describe, const HdrMetadata& metadata, std::function<void(uint64_t, bool)> on_settled) {
    (void)metadata;
    if (on_settled) on_settled(0, !describe);
  }
  virtual bool CommitHdrTransition(uint64_t token) {
    (void)token;
    return false;
  }
  virtual void AbortHdrTransition(uint64_t token) { (void)token; }
  virtual bool hdr_transition_staged() const { return false; }
  virtual bool ForceUndescribed() { return false; }
  virtual bool CanDescribeSource(const HdrMetadata& metadata) const {
    (void)metadata;
    return false;
  }
  virtual bool hdr_active() const { return false; }
};

}  // namespace mpv

#endif  // PLEZY_LINUX_MPV_VIDEO_PLANE_H_
