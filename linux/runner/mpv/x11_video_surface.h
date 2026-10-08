#ifndef PLEZY_LINUX_MPV_X11_VIDEO_SURFACE_H_
#define PLEZY_LINUX_MPV_X11_VIDEO_SURFACE_H_

#include <gtk/gtk.h>

#include <cstdint>
#include <functional>
#include <mutex>
#include <vector>

#include "video_plane.h"

namespace mpv {

// SDR video plane for an X11 session: a child GdkWindow with its own EGL
// window surface, stacked below the Flutter view. 
// The X compositor wont draw Flutter's transparent pixels over a sibling, 
// so each Flutter frame is read back and blended ontop, then you see that
// through the rect hole.
class X11VideoSurface : public VideoPlane {
 public:
  X11VideoSurface() = default;
  ~X11VideoSurface() override;

  X11VideoSurface(const X11VideoSurface&) = delete;
  X11VideoSurface& operator=(const X11VideoSurface&) = delete;

  static bool IsX11(GdkDisplay* display);

  bool Create(GtkWidget* view, std::string* error) override;
  void Destroy() override;

  bool valid() const override { return egl_surface_ != EGL_NO_SURFACE; }
  EGLDisplay egl_display() const override { return egl_display_; }
  EGLConfig egl_config() const override { return egl_config_; }
  EGLSurface egl_surface() const override { return egl_surface_; }

  int32_t width() const override { return draw_width_; }
  int32_t height() const override { return draw_height_; }
  bool has_size() const override { return rect_valid_; }

  void SetRect(int32_t x, int32_t y, int32_t width, int32_t height, int32_t scale) override;
  void SetVisible(bool visible) override;
  bool visible() const override { return visible_; }
  bool frame_pending() const override { return frame_pending_; }
  bool first_frame_presented() const override { return first_frame_presented_; }

  void SetFrameCallback(std::function<void()> callback) override { on_frame_ = std::move(callback); }
  void SetForcedRenderCallback(std::function<void()> callback) override { on_forced_render_ = std::move(callback); }
  void BlendOverlay() override;
  void SetMonitorEnteredCallback(std::function<void(GdkMonitor*)> callback) override {
    on_monitor_entered_ = std::move(callback);
  }

  bool PreparePresent() override;
  bool CompletePresent(bool swapped) override;

 private:
  bool InitEgl(std::string* error);
  void PlaceWindow();
  void Restack();

  void ShowUnderPaint();
  void ApplyHole();
  void ClearHole();
  
  void CaptureOverlay(cairo_surface_t* group);
  void ScheduleOverlayPresent();

  void AdoptDrawableSize();
  void EnsureEglSurface();
  void HideWindow();
  void NoteMonitor();
  void ArmFrameTimer();
  void CancelFrameTimer();
  int FrameIntervalMs() const;

  static gboolean OnToplevelConfigure(GtkWidget* widget, GdkEventConfigure* event, gpointer data);
  static gboolean OnFrameTimer(gpointer data);
  static gboolean OnPaintDraw(GtkWidget* widget, cairo_t* cr, gpointer data);
  static gboolean OnOverlayPresent(gpointer data);

  GtkWidget* view_ = nullptr;
  GtkWidget* toplevel_ = nullptr;
  GtkWidget* paint_widget_ = nullptr;
  GdkWindow* window_ = nullptr;
  gulong configure_id_ = 0;
  gulong draw_id_ = 0;
  guint frame_timer_ = 0;
  guint overlay_present_id_ = 0;
  bool in_paint_draw_ = false;

  EGLDisplay egl_display_ = EGL_NO_DISPLAY;
  EGLConfig egl_config_ = nullptr;
  EGLSurface egl_surface_ = EGL_NO_SURFACE;
  // Size the current EGL surface was created at
  int32_t surface_w_ = 0;
  int32_t surface_h_ = 0;

  // The rect Dart last sent, in physical pixels of the Flutter view
  int32_t origin_x_ = 0;
  int32_t origin_y_ = 0;
  int32_t extent_w_ = 0;
  int32_t extent_h_ = 0;
  int32_t scale_ = 1;

  // Device pixels of the child window
  int32_t draw_width_ = 0;
  int32_t draw_height_ = 0;

  // Flutter's video rect
  std::mutex overlay_mu_;
  std::vector<uint8_t> overlay_;
  int overlay_w_ = 0;
  int overlay_h_ = 0;

  // Last shape punched into the view
  // Reapplying the same region every draw makes the server recompute the shape and its glitchy
  bool hole_applied_ = false;
  int hole_x_ = 0;
  int hole_y_ = 0;
  int hole_w_ = 0;
  int hole_h_ = 0;
  unsigned int gl_program_ = 0;
  unsigned int gl_texture_ = 0;

  bool visible_ = false;
  bool rect_valid_ = false;
  bool frame_pending_ = false;
  bool first_frame_presented_ = false;
  gint64 present_started_us_ = 0;

  std::function<void()> on_frame_;
  std::function<void()> on_forced_render_;
  std::function<void(GdkMonitor*)> on_monitor_entered_;
  GdkMonitor* monitor_ = nullptr;
};

}  // namespace mpv

#endif  // PLEZY_LINUX_MPV_X11_VIDEO_SURFACE_H_
