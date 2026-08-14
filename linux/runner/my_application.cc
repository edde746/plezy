#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gdk/gdk.h>
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "mpv/mpv_plugin.h"

// On Wayland the mpv video plane is a wl_subsurface stacked *below* this
// window's surface, so the window needs an alpha channel for it to show
// through. Harmless when the plane is unavailable: the Flutter UI paints
// opaque anyway, and sessions that cannot host the plane (X11/XWayland)
// fall back to the Flutter-texture path, which composites through Flutter
// and needs no alpha channel.
static void enable_video_plane_transparency(GtkWindow* window, FlView* view) {
#ifdef GDK_WINDOWING_WAYLAND
  GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
  if (!GDK_IS_WAYLAND_DISPLAY(display)) return;

  GdkScreen* screen = gtk_widget_get_screen(GTK_WIDGET(window));
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual == nullptr) {
    // The plane is stacked *below* the toplevel, so without an alpha channel it
    // is occluded by an opaque Flutter surface and the video area goes blank
    // with everything else working. GDK's Wayland backend always offers an ARGB
    // visual, so this is not expected - say so rather than fail silently, since
    // the symptom on its own points nowhere near here.
    g_warning("MPV video plane: no RGBA visual; the video plane would be hidden behind an opaque window");
    return;
  }

  gtk_widget_set_visual(GTK_WIDGET(window), visual);
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);

  // The RGBA visual only reaches the compositor if Flutter stops filling the frame too: fl_view clears to this
  // colour every frame, so any opaque value would paint over the subsurface whatever the visual says.
  GdkRGBA transparent = {0.0, 0.0, 0.0, 0.0};
  fl_view_set_background_color(view, &transparent);
#else
  (void)window;
  (void)view;
#endif
}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlView* flutter_view;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Default to traditional titlebar. Set GTK_CSD=1 to use a header bar.
  gboolean use_header_bar = FALSE;
  const gchar* gtk_csd = g_getenv("GTK_CSD");
  if (gtk_csd != nullptr && g_strcmp0(gtk_csd, "1") == 0) {
    use_header_bar = TRUE;
  }
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Plezy");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Plezy");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  self->flutter_view = fl_view_new(project);
  enable_video_plane_transparency(window, self->flutter_view);
  gtk_widget_show(GTK_WIDGET(self->flutter_view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(self->flutter_view));

  // Register Flutter plugins.
  fl_register_plugins(FL_PLUGIN_REGISTRY(self->flutter_view));

  // Register the MPV plugin. Video prefers the native Wayland plane; sessions
  // that cannot host one (X11/XWayland, or a failed plane bootstrap) fall back
  // to the Flutter-texture path in SDR.
  FlPluginRegistrar* registrar =
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(self->flutter_view), "MpvPlugin");
  mpv_plugin_register_with_registrar(registrar);

  // Register the dedicated audio-only MPV core for music playback (no
  // video or GL work at all).
  FlPluginRegistrar* audio_registrar =
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(self->flutter_view), "MpvAudioPlugin");
  mpv_audio_plugin_register_with_registrar(audio_registrar);

  gtk_widget_show(GTK_WIDGET(window));
  gtk_widget_grab_focus(GTK_WIDGET(self->flutter_view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) { self->flutter_view = nullptr; }

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(
      my_application_get_type(), "application-id", APPLICATION_ID, "flags", G_APPLICATION_NON_UNIQUE, nullptr));
}
