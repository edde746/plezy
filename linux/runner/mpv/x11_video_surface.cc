#include "x11_video_surface.h"

#include <epoxy/gl.h>
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <algorithm>
#include <cstring>

#include "plane_geometry.h"

namespace mpv {
namespace {

struct WindowRect {
  int x;
  int y;
  int w;
  int h;
};

bool Fail(std::string* error, const char* message) {
  if (error != nullptr) *error = message;
  return false;
}

// Find the widget that has a window that we can paint into
GtkWidget* FindPaintWidget(GtkWidget* widget) {
  if (widget == nullptr) return nullptr;

  // Recursively find the first widget that has a window
  GtkWidget* nested = nullptr;
  if (GTK_IS_CONTAINER(widget)) {
    GList* children = gtk_container_get_children(GTK_CONTAINER(widget));
    for (GList* it = children; it != nullptr; it = it->next) {
      if (GtkWidget* child = FindPaintWidget(GTK_WIDGET(it->data))) nested = child;
    }
    g_list_free(children);
  }

  // Return the nested widget if we found it
  if (nested != nullptr) return nested;

  // Return the widget if it has a window
  if (gtk_widget_get_has_window(widget) && gtk_widget_get_window(widget) != nullptr) return widget;
  
  // Return nullptr if we didn't find anything
  return nullptr;
}

// The paint window
GdkWindow* PaintWindow(GtkWidget* view) {
  if (GtkWidget* paint = FindPaintWidget(view)) {
    // Return the window if we found it
    if (GdkWindow* window = gtk_widget_get_window(paint)) return window;
  }

  // Return the view's window if we didn't find anything
  return view != nullptr ? gtk_widget_get_window(view) : nullptr;
}

// Write the video rectangle relative to the paint window
// Since they both have the same parent we're just doing a little
// 2d translation to keep everything stacked
// This is "kinda" similar to what was in the original
// x implementation for plezy? idk if this is very fair
// to do. It feels clunky with the layers of compositing plus this but
// if you're stuck using x11 anyway, I think you can handle it.
bool VideoOnPaint(GdkWindow* paint, GdkWindow* video, WindowRect* rect) {
  if (paint == nullptr || video == nullptr || rect == nullptr) return false;
  gint paint_x = 0;
  gint paint_y = 0;
  gint video_x = 0;
  gint video_y = 0;
  gdk_window_get_position(paint, &paint_x, &paint_y);
  gdk_window_get_position(video, &video_x, &video_y);
  rect->x = video_x - paint_x;
  rect->y = video_y - paint_y;
  rect->w = gdk_window_get_width(video);
  rect->h = gdk_window_get_height(video);
  return rect->w > 0 && rect->h > 0;
}

// Get the monitor of the view
GdkMonitor* MonitorOf(GtkWidget* view) {
  if (view == nullptr) return nullptr;
  GtkWidget* toplevel = gtk_widget_get_toplevel(view);
  if (toplevel == nullptr || !gtk_widget_is_toplevel(toplevel)) return nullptr;
  GdkWindow* window = gtk_widget_get_window(toplevel);
  if (window == nullptr) return nullptr;
  return gdk_display_get_monitor_at_window(gdk_window_get_display(window), window);
}

// Destroy the EGL window surface
void DestroyEglWindowSurface(EGLDisplay display, EGLSurface* surface) {
  if (surface == nullptr || *surface == EGL_NO_SURFACE) return;
  if (eglGetCurrentSurface(EGL_DRAW) == *surface || eglGetCurrentSurface(EGL_READ) == *surface) {
    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  }
  eglDestroySurface(display, *surface);
  *surface = EGL_NO_SURFACE;
}

#ifdef GDK_WINDOWING_X11
// Get the visual for the config
GdkVisual* VisualForConfig(EGLDisplay display, EGLConfig config, GdkScreen* screen) {
  EGLint visual_id = 0;
  if (display == EGL_NO_DISPLAY || config == nullptr || screen == nullptr) return nullptr;
  if (!eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &visual_id) || visual_id == 0) return nullptr;
  return gdk_x11_screen_lookup_visual(screen, static_cast<VisualID>(visual_id));
}
#endif

// https://wikis.khronos.org/opengl/Shader_Compilation
GLuint CompileShader(GLenum type, const char* source) {
  const GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &source, nullptr);
  glCompileShader(shader);
  GLint ok = GL_FALSE;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (ok == GL_TRUE) return shader;
  glDeleteShader(shader);
  return 0;
}

// Cairo stores blue, green, red. .bgra puts red and blue back.
// https://wikis.khronos.org/opengl/Shader_Compilation#Example
GLuint LinkOverlayProgram() {
  const char* vertex =
      "#version 100\n"
      "attribute vec2 a_pos;\n"
      "attribute vec2 a_uv;\n"
      "varying vec2 v_uv;\n"
      "void main() {\n"
      "  v_uv = a_uv;\n"
      "  gl_Position = vec4(a_pos, 0.0, 1.0);\n"
      "}\n";
  const char* fragment =
      "#version 100\n"
      "precision mediump float;\n"
      "varying vec2 v_uv;\n"
      "uniform sampler2D u_tex;\n"
      "void main() {\n"
      "  gl_FragColor = texture2D(u_tex, v_uv).bgra;\n"
      "}\n";
  const GLuint vs = CompileShader(GL_VERTEX_SHADER, vertex);
  const GLuint fs = CompileShader(GL_FRAGMENT_SHADER, fragment);
  if (vs == 0 || fs == 0) {
    glDeleteShader(vs);
    glDeleteShader(fs);
    return 0;
  }
  const GLuint program = glCreateProgram();
  glAttachShader(program, vs);
  glAttachShader(program, fs);
  glBindAttribLocation(program, 0, "a_pos");
  glBindAttribLocation(program, 1, "a_uv");
  glLinkProgram(program);
  glDeleteShader(vs);
  glDeleteShader(fs);
  GLint linked = GL_FALSE;
  glGetProgramiv(program, GL_LINK_STATUS, &linked);
  if (linked == GL_TRUE) return program;
  glDeleteProgram(program);
  return 0;
}

}  // namespace

X11VideoSurface::~X11VideoSurface() { Destroy(); }

bool X11VideoSurface::IsX11(GdkDisplay* display) {
#ifdef GDK_WINDOWING_X11
  return display != nullptr && GDK_IS_X11_DISPLAY(display);
#else
  (void)display;
  return false;
#endif
}

bool X11VideoSurface::InitEgl(std::string* error) {
#ifdef GDK_WINDOWING_X11
  if (view_ == nullptr) return Fail(error, "X11 video plane has no view");
  GdkDisplay* display = gtk_widget_get_display(view_);
  Display* xdisplay = gdk_x11_display_get_xdisplay(display);
  if (xdisplay == nullptr) return Fail(error, "X11 display has no native Display");

  // eglGetPlatformDisplay aborts in epoxy when nothing is current. This
  // display is shared with Flutter, so Destroy() does not eglTerminate.
  egl_display_ = eglGetDisplay(reinterpret_cast<EGLNativeDisplayType>(xdisplay));
  if (egl_display_ == EGL_NO_DISPLAY) return Fail(error, "No EGL display for the X11 connection");
  if (!eglInitialize(egl_display_, nullptr, nullptr)) {
    egl_display_ = EGL_NO_DISPLAY;
    return Fail(error, "eglInitialize failed for the X11 video plane");
  }
  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    return Fail(error, "EGL_OPENGL_ES_API is not available for the X11 video plane");
  }

  const EGLint renderables[] = {EGL_OPENGL_ES3_BIT, EGL_OPENGL_ES2_BIT};
  for (EGLint renderable : renderables) {
    const EGLint attributes[] = {
        EGL_SURFACE_TYPE,
        EGL_WINDOW_BIT,
        EGL_RENDERABLE_TYPE,
        renderable,
        EGL_RED_SIZE,
        8,
        EGL_GREEN_SIZE,
        8,
        EGL_BLUE_SIZE,
        8,
        EGL_ALPHA_SIZE,
        0,
        EGL_NONE,
    };
    EGLConfig config = nullptr;
    EGLint count = 0;
    if (eglChooseConfig(egl_display_, attributes, &config, 1, &count) && count == 1) {
      egl_config_ = config;
      return true;
    }
  }
  return Fail(error, "No matching EGL config for the X11 video plane");
#else
  (void)error;
  return Fail(error, "This build has no X11 GDK backend");
#endif
}

bool X11VideoSurface::Create(GtkWidget* view, std::string* error) {
#ifndef GDK_WINDOWING_X11
  (void)view;
  return Fail(error, "This build has no X11 GDK backend");
#else
  if (view == nullptr) return Fail(error, "Video plane requires a view");
  GdkDisplay* display = gtk_widget_get_display(view);
  if (!IsX11(display)) return Fail(error, "Not an X11 display");

  GdkWindow* paint = PaintWindow(view);
  // Sibling of the window Flutter paints into. The view's window is the toplevel.
  GdkWindow* parent = paint != nullptr ? gdk_window_get_parent(paint) : nullptr;
  if (parent == nullptr) parent = gtk_widget_get_parent_window(view);
  if (parent == nullptr || paint == nullptr) {
    return Fail(error, "The window is not realized yet, so there is nowhere to place the video plane");
  }

  view_ = view;
  toplevel_ = gtk_widget_get_toplevel(view);
  if (toplevel_ != nullptr && !gtk_widget_is_toplevel(toplevel_)) toplevel_ = nullptr;

  if (!InitEgl(error)) {
    Destroy();
    return false;
  }

  GdkWindowAttr attributes{};
  attributes.event_mask = 0;
  attributes.x = 0;
  attributes.y = 0;
  attributes.width = 1;
  attributes.height = 1;
  attributes.wclass = GDK_INPUT_OUTPUT;
  attributes.window_type = GDK_WINDOW_CHILD;
  gint mask = GDK_WA_X | GDK_WA_Y;
  GdkScreen* screen = gtk_widget_get_screen(view);
  GdkVisual* visual = VisualForConfig(egl_display_, egl_config_, screen);
  if (visual == nullptr) visual = gdk_window_get_visual(parent);
  if (visual != nullptr) {
    attributes.visual = visual;
    mask |= GDK_WA_VISUAL;
  }
  window_ = gdk_window_new(parent, &attributes, mask);
  if (window_ == nullptr) {
    Destroy();
    return Fail(error, "Failed to create the X11 video window");
  }

  gdk_window_set_pass_through(window_, TRUE);
  Restack();
  gdk_window_hide(window_);

  const Window xid = gdk_x11_window_get_xid(window_);
  egl_surface_ = eglCreateWindowSurface(egl_display_, egl_config_, static_cast<EGLNativeWindowType>(xid), nullptr);
  if (egl_surface_ == EGL_NO_SURFACE) {
    Destroy();
    return Fail(error, "Failed to create the X11 video EGL surface");
  }
  g_message("MPV video plane: X11 child window, 8 bits per channel, HDR off");

  if (toplevel_ != nullptr) {
    configure_id_ = g_signal_connect(toplevel_, "configure-event", G_CALLBACK(OnToplevelConfigure), this);
    g_object_add_weak_pointer(G_OBJECT(toplevel_), reinterpret_cast<gpointer*>(&toplevel_));
  }
  paint_widget_ = FindPaintWidget(view);
  if (paint_widget_ != nullptr) {
    draw_id_ = g_signal_connect(paint_widget_, "draw", G_CALLBACK(OnPaintDraw), this);
    g_object_add_weak_pointer(G_OBJECT(paint_widget_), reinterpret_cast<gpointer*>(&paint_widget_));
  }
  return true;
#endif
}

void X11VideoSurface::Destroy() {
  CancelFrameTimer();
  if (overlay_present_id_ != 0) g_source_remove(overlay_present_id_);
  overlay_present_id_ = 0;
  if (draw_id_ != 0 && paint_widget_ != nullptr) g_signal_handler_disconnect(paint_widget_, draw_id_);
  draw_id_ = 0;
  ClearHole();
  if (paint_widget_ != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(paint_widget_), reinterpret_cast<gpointer*>(&paint_widget_));
    paint_widget_ = nullptr;
  }
  on_frame_ = nullptr;
  on_forced_render_ = nullptr;
  on_monitor_entered_ = nullptr;
  monitor_ = nullptr;

  if (configure_id_ != 0 && toplevel_ != nullptr) {
    g_signal_handler_disconnect(toplevel_, configure_id_);
  }
  configure_id_ = 0;
  if (toplevel_ != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(toplevel_), reinterpret_cast<gpointer*>(&toplevel_));
    toplevel_ = nullptr;
  }

  DestroyEglWindowSurface(egl_display_, &egl_surface_);
  egl_config_ = nullptr;
  surface_w_ = 0;
  surface_h_ = 0;
  // Shared display. Drop the pointer, don't eglTerminate.
  egl_display_ = EGL_NO_DISPLAY;

  if (window_ != nullptr) {
    gdk_window_destroy(window_);
    window_ = nullptr;
  }

  view_ = nullptr;
  origin_x_ = 0;
  origin_y_ = 0;
  extent_w_ = 0;
  extent_h_ = 0;
  scale_ = 1;
  draw_width_ = 0;
  draw_height_ = 0;
  visible_ = false;
  rect_valid_ = false;
  frame_pending_ = false;
  first_frame_presented_ = false;
  present_started_us_ = 0;
}

gboolean X11VideoSurface::OnToplevelConfigure(GtkWidget* widget, GdkEventConfigure* event, gpointer data) {
  (void)widget;
  (void)event;
  static_cast<X11VideoSurface*>(data)->NoteMonitor();
  return FALSE;
}

void X11VideoSurface::NoteMonitor() {
  if (!on_monitor_entered_) return;
  GdkMonitor* monitor = MonitorOf(view_);
  if (monitor == nullptr || monitor == monitor_) return;
  monitor_ = monitor;
  on_monitor_entered_(monitor);
}

void X11VideoSurface::Restack() {
  if (window_ == nullptr || view_ == nullptr) return;
  GdkWindow* paint = PaintWindow(view_);
  if (paint == nullptr || gdk_window_get_parent(paint) != gdk_window_get_parent(window_)) return;
  gdk_window_restack(window_, paint, FALSE);
}

void X11VideoSurface::ShowUnderPaint() {
  if (window_ == nullptr) return;
  gdk_window_show(window_);
  // Map raises the child and can drop the empty input shape.
  gdk_window_set_pass_through(window_, TRUE);
  Restack();
}

void X11VideoSurface::AdoptDrawableSize() {
  if (window_ == nullptr) return;
  // Sync so the size we render is the size the window just became.
  gdk_display_sync(gdk_window_get_display(window_));
  const int factor = std::max(gdk_window_get_scale_factor(window_), 1);
  const int width = std::max(gdk_window_get_width(window_), 1);
  const int height = std::max(gdk_window_get_height(window_), 1);
  draw_width_ = width * factor;
  draw_height_ = height * factor;
}

void X11VideoSurface::EnsureEglSurface() {
#ifndef GDK_WINDOWING_X11
  return;
#else
  if (window_ == nullptr || egl_display_ == EGL_NO_DISPLAY || egl_config_ == nullptr) return;
  if (draw_width_ < 1 || draw_height_ < 1) return;
  if (egl_surface_ != EGL_NO_SURFACE && surface_w_ == draw_width_ && surface_h_ == draw_height_) return;
  DestroyEglWindowSurface(egl_display_, &egl_surface_);
  const Window xid = gdk_x11_window_get_xid(window_);
  egl_surface_ = eglCreateWindowSurface(egl_display_, egl_config_, static_cast<EGLNativeWindowType>(xid), nullptr);
  if (egl_surface_ == EGL_NO_SURFACE) {
    surface_w_ = 0;
    surface_h_ = 0;
    g_warning("MPV video plane: failed to recreate the X11 EGL surface: 0x%x", eglGetError());
    return;
  }
  surface_w_ = draw_width_;
  surface_h_ = draw_height_;
#endif
}

void X11VideoSurface::HideWindow() {
  CancelFrameTimer();
  frame_pending_ = false;
  ClearHole();
  if (window_ != nullptr) gdk_window_hide(window_);
}

void X11VideoSurface::PlaceWindow() {
  if (window_ == nullptr || view_ == nullptr || !rect_valid_) return;
  GdkWindow* view_window = PaintWindow(view_);
  if (view_window == nullptr) return;

  const int32_t scale = NormalizePlaneScale(scale_);
  const int32_t buffer_w = PlaneBufferExtent(origin_x_, extent_w_, scale);
  const int32_t buffer_h = PlaneBufferExtent(origin_y_, extent_h_, scale);
  // Dart sends physical pixels. GDK wants logical ones.
  const int32_t logical_w = std::max<int32_t>(buffer_w / scale, 1);
  const int32_t logical_h = std::max<int32_t>(buffer_h / scale, 1);
  gint view_x = 0;
  gint view_y = 0;
  gdk_window_get_position(view_window, &view_x, &view_y);
  const int32_t x = view_x + PlaneOriginUnits(origin_x_, scale);
  const int32_t y = view_y + PlaneOriginUnits(origin_y_, scale);
  gdk_window_move_resize(window_, x, y, logical_w, logical_h);
  if (visible_) {
    ShowUnderPaint();
    ApplyHole();
  } else {
    Restack();
  }
  AdoptDrawableSize();
  EnsureEglSurface();
}

void X11VideoSurface::SetRect(int32_t x, int32_t y, int32_t width, int32_t height, int32_t scale) {
  scale_ = NormalizePlaneScale(scale);
  const bool was_valid = rect_valid_;
  rect_valid_ = width > 0 && height > 0;
  origin_x_ = x;
  origin_y_ = y;
  extent_w_ = width;
  extent_h_ = height;
  if (!rect_valid_) {
    // Otherwise the last frame stays up over whatever replaced the video.
    if (was_valid) HideWindow();
    draw_width_ = 0;
    draw_height_ = 0;
    return;
  }
  PlaceWindow();
}

void X11VideoSurface::SetVisible(bool visible) {
  if (visible == visible_) return;
  visible_ = visible;
  if (!visible) {
    HideWindow();
    return;
  }
  if (rect_valid_) {
    ShowUnderPaint();
    ApplyHole();
  }
}

bool X11VideoSurface::PreparePresent() {
  if (!visible_ || !rect_valid_ || egl_surface_ == EGL_NO_SURFACE || frame_pending_) return false;
  frame_pending_ = true;
  present_started_us_ = g_get_monotonic_time();
  return true;
}

int X11VideoSurface::FrameIntervalMs() const {
  GdkMonitor* monitor = MonitorOf(view_);
  if (monitor == nullptr) return 16;
  const int refresh_mhz = gdk_monitor_get_refresh_rate(monitor);
  if (refresh_mhz <= 0) return 16;
  const int interval = (1000000 + refresh_mhz / 2) / refresh_mhz;
  return interval < 1 ? 1 : interval;
}

void X11VideoSurface::ArmFrameTimer() {
  CancelFrameTimer();
  const int interval_ms = FrameIntervalMs();
  const gint64 elapsed_ms = present_started_us_ > 0 ? (g_get_monotonic_time() - present_started_us_) / 1000 : 0;
  // Already spent this frame: fire on the next tick.
  const int wait_ms = elapsed_ms >= interval_ms ? 1 : interval_ms - static_cast<int>(elapsed_ms);
  frame_timer_ = g_timeout_add(static_cast<guint>(wait_ms), OnFrameTimer, this);
}

void X11VideoSurface::CancelFrameTimer() {
  if (frame_timer_ == 0) return;
  g_source_remove(frame_timer_);
  frame_timer_ = 0;
}

gboolean X11VideoSurface::OnFrameTimer(gpointer data) {
  auto* self = static_cast<X11VideoSurface*>(data);
  self->frame_timer_ = 0;
  self->frame_pending_ = false;
  // Plugin renders when mpv has a new frame, or a resize is waiting.
  if (self->on_frame_) self->on_frame_();
  return G_SOURCE_REMOVE;
}

bool X11VideoSurface::CompletePresent(bool swapped) {
  if (!swapped || !visible_ || !rect_valid_) {
    frame_pending_ = false;
    CancelFrameTimer();
    if (!visible_ || !rect_valid_) HideWindow();
    return false;
  }
  first_frame_presented_ = true;
  // Hold frame_pending_ until the timer fires. That's the frame callback.
  ArmFrameTimer();
  return true;
}

void X11VideoSurface::ApplyHole() {
  if (!visible_ || !rect_valid_ || view_ == nullptr || window_ == nullptr) return;
  GdkWindow* paint = PaintWindow(view_);
  WindowRect video{};
  if (!VideoOnPaint(paint, window_, &video)) return;
  if (hole_applied_ && hole_x_ == video.x && hole_y_ == video.y && hole_w_ == video.w && hole_h_ == video.h) return;
  const int paint_w = gdk_window_get_width(paint);
  const int paint_h = gdk_window_get_height(paint);
  if (paint_w < 1 || paint_h < 1) return;
  cairo_rectangle_int_t full{0, 0, paint_w, paint_h};
  cairo_region_t* shape = cairo_region_create_rectangle(&full);
  cairo_region_t* input = cairo_region_copy(shape);
  cairo_rectangle_int_t hole{video.x, video.y, video.w, video.h};
  cairo_region_subtract_rectangle(shape, &hole);
  // Output shape is the hole. Input shape stays the whole window.
  gdk_window_shape_combine_region(paint, shape, 0, 0);
  gdk_window_input_shape_combine_region(paint, input, 0, 0);
  cairo_region_destroy(shape);
  cairo_region_destroy(input);
  hole_applied_ = true;
  hole_x_ = video.x;
  hole_y_ = video.y;
  hole_w_ = video.w;
  hole_h_ = video.h;
}

void X11VideoSurface::ClearHole() {
  if (view_ == nullptr) return;
  GdkWindow* paint = PaintWindow(view_);
  if (paint == nullptr) return;
  gdk_window_shape_combine_region(paint, nullptr, 0, 0);
  gdk_window_input_shape_combine_region(paint, nullptr, 0, 0);
  hole_applied_ = false;
}

void X11VideoSurface::CaptureOverlay(cairo_surface_t* group) {
  if (group == nullptr || window_ == nullptr || view_ == nullptr) return;
  if (cairo_surface_get_type(group) != CAIRO_SURFACE_TYPE_IMAGE) return;
  if (cairo_image_surface_get_format(group) != CAIRO_FORMAT_ARGB32) return;
  GdkWindow* paint = PaintWindow(view_);
  WindowRect video{};
  if (!VideoOnPaint(paint, window_, &video)) return;

  double x_off = 0;
  double y_off = 0;
  cairo_surface_get_device_offset(group, &x_off, &y_off);
  double scale_x = 1;
  double scale_y = 1;
  cairo_surface_get_device_scale(group, &scale_x, &scale_y);
  if (scale_x <= 0) scale_x = 1;
  if (scale_y <= 0) scale_y = 1;
  // Image is device pixels. The window rect is logical.
  const int x0 = static_cast<int>(video.x * scale_x + x_off);
  const int y0 = static_cast<int>(video.y * scale_y + y_off);
  const int width = std::max(static_cast<int>(video.w * scale_x), 1);
  const int height = std::max(static_cast<int>(video.h * scale_y), 1);
  const int image_w = cairo_image_surface_get_width(group);
  const int image_h = cairo_image_surface_get_height(group);
  if (x0 < 0 || y0 < 0 || x0 + width > image_w || y0 + height > image_h) {
    static int logged = 0;
    if (logged < 3) {
      g_warning(
          "MPV video plane: Flutter frame %dx%d does not cover the video rect at %d,%d %dx%d", image_w, image_h, x0, y0,
          width, height);
      logged++;
    }
    return;
  }
  const auto* data = cairo_image_surface_get_data(group);
  if (data == nullptr) return;
  const int stride = cairo_image_surface_get_stride(group);

  std::vector<uint8_t> pixels(static_cast<std::size_t>(width) * static_cast<std::size_t>(height) * 4u);
  for (int y = 0; y < height; ++y) {
    const auto* row =
        data + static_cast<std::size_t>(y0 + y) * static_cast<std::size_t>(stride) + static_cast<std::size_t>(x0) * 4u;
    std::memcpy(
        pixels.data() + static_cast<std::size_t>(y) * static_cast<std::size_t>(width) * 4u, row,
        static_cast<std::size_t>(width) * 4u);
  }

  bool changed = false;
  {
    std::lock_guard<std::mutex> lock(overlay_mu_);
    changed = overlay_.size() != pixels.size() || std::memcmp(overlay_.data(), pixels.data(), pixels.size()) != 0;
    if (changed) {
      overlay_.swap(pixels);
      overlay_w_ = width;
      overlay_h_ = height;
    }
  }
  if (changed) ScheduleOverlayPresent();
}

void X11VideoSurface::ScheduleOverlayPresent() {
  if (overlay_present_id_ != 0 || !on_forced_render_) return;
  overlay_present_id_ = g_idle_add(OnOverlayPresent, this);
}

gboolean X11VideoSurface::OnOverlayPresent(gpointer data) {
  auto* self = static_cast<X11VideoSurface*>(data);
  self->overlay_present_id_ = 0;
  if (self->on_forced_render_) self->on_forced_render_();
  return G_SOURCE_REMOVE;
}

gboolean X11VideoSurface::OnPaintDraw(GtkWidget* widget, cairo_t* cr, gpointer data) {
  auto* self = static_cast<X11VideoSurface*>(data);
  if (self->in_paint_draw_ || !self->visible_ || !self->rect_valid_ || self->window_ == nullptr) return FALSE;
  self->in_paint_draw_ = true;
  // Renderer background is opaque black. Clear it for the copy, then put it back.
  const bool is_view = FL_IS_VIEW(self->view_);
  GdkRGBA saved{0.0, 0.0, 0.0, 1.0};
  GdkRGBA clear{0.0, 0.0, 0.0, 0.0};
  if (is_view) fl_view_set_background_color(FL_VIEW(self->view_), &clear);
  // cairo_push_group on X11 is an X pixmap. An image surface we can read.
  GdkWindow* paint = gtk_widget_get_window(widget);
  const int factor = paint != nullptr ? std::max(gdk_window_get_scale_factor(paint), 1) : 1;
  const int logical_w = paint != nullptr ? gdk_window_get_width(paint) : 0;
  const int logical_h = paint != nullptr ? gdk_window_get_height(paint) : 0;
  if (logical_w > 0 && logical_h > 0 && GTK_WIDGET_GET_CLASS(widget)->draw != nullptr) {
    cairo_surface_t* image = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, logical_w * factor, logical_h * factor);
    if (cairo_surface_status(image) == CAIRO_STATUS_SUCCESS) {
      cairo_surface_set_device_scale(image, factor, factor);
      cairo_t* image_cr = cairo_create(image);
      GTK_WIDGET_GET_CLASS(widget)->draw(widget, image_cr);
      cairo_destroy(image_cr);
      cairo_surface_flush(image);
      self->CaptureOverlay(image);
    }
    cairo_surface_destroy(image);
  }
  if (is_view) fl_view_set_background_color(FL_VIEW(self->view_), &saved);
  if (GTK_WIDGET_GET_CLASS(widget)->draw != nullptr) GTK_WIDGET_GET_CLASS(widget)->draw(widget, cr);
  self->ApplyHole();
  g_signal_stop_emission_by_name(widget, "draw");
  self->in_paint_draw_ = false;
  return TRUE;
}

void X11VideoSurface::BlendOverlay() {
  std::vector<uint8_t> pixels;
  int width = 0;
  int height = 0;
  {
    std::lock_guard<std::mutex> lock(overlay_mu_);
    if (overlay_.empty() || overlay_w_ < 1 || overlay_h_ < 1) return;
    pixels = overlay_;
    width = overlay_w_;
    height = overlay_h_;
  }

  if (gl_program_ == 0) {
    static bool shader_failed = false;
    if (shader_failed) return;
    gl_program_ = LinkOverlayProgram();
    if (gl_program_ == 0) {
      shader_failed = true;
      return;
    }
  }

  if (gl_texture_ == 0) glGenTextures(1, &gl_texture_);
  glBindTexture(GL_TEXTURE_2D, gl_texture_);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());

  EGLint drawable_w = 0;
  EGLint drawable_h = 0;
  if (eglQuerySurface(egl_display_, egl_surface_, EGL_WIDTH, &drawable_w) &&
      eglQuerySurface(egl_display_, egl_surface_, EGL_HEIGHT, &drawable_h) && drawable_w > 0 && drawable_h > 0) {
    glViewport(0, 0, drawable_w, drawable_h);
  }
  glDisable(GL_SCISSOR_TEST);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  // Cairo pixels are premultiplied.
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
  glUseProgram(gl_program_);
  glUniform1i(glGetUniformLocation(gl_program_, "u_tex"), 0);

  // First uploaded row is the top of the frame. GL's v=0 is the bottom.
  const float verts[] = {
      -1.f, -1.f, 0.f, 1.f, 1.f, -1.f, 1.f, 1.f, -1.f, 1.f, 0.f, 0.f, 1.f, 1.f, 1.f, 0.f,
  };
  GLuint buffer = 0;
  glGenBuffers(1, &buffer);
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts, GL_STREAM_DRAW);
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), nullptr);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), reinterpret_cast<const void*>(2 * sizeof(float)));
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glDeleteBuffers(1, &buffer);
  glBindTexture(GL_TEXTURE_2D, 0);
  glUseProgram(0);
  glDisable(GL_BLEND);
}

}  // namespace mpv
