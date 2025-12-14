#ifndef MPV_PLUGIN_H_
#define MPV_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <memory>

#include "mpv_player.h"

G_BEGIN_DECLS

/// Plugin for MPV video playback on Linux.
///
/// This plugin uses OpenGL rendering via GtkGLArea,
/// positioned behind the Flutter view using a GtkOverlay.

#define MPV_PLUGIN_TYPE (mpv_plugin_get_type())

G_DECLARE_FINAL_TYPE(MpvPlugin, mpv_plugin, MPV, PLUGIN, GObject)

/// Creates a new MpvPlugin instance.
/// @param registrar The Flutter plugin registrar.
/// @param overlay The GtkOverlay containing the GtkGLArea and FlView.
/// @param gl_area The GtkGLArea widget for video rendering.
/// @param flutter_view The Flutter view widget (for visibility control).
MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar,
                          GtkOverlay* overlay,
                          GtkGLArea* gl_area,
                          GtkWidget* flutter_view);

/// Registers the plugin with Flutter.
void mpv_plugin_register_with_registrar(FlPluginRegistrar* registrar,
                                        GtkOverlay* overlay,
                                        GtkGLArea* gl_area,
                                        GtkWidget* flutter_view);

G_END_DECLS

#endif  // MPV_PLUGIN_H_
