#ifndef MPV_PLUGIN_H_
#define MPV_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

#include <memory>

#include "mpv_player.h"

G_BEGIN_DECLS

/// Plugin for MPV video playback on Linux.
///
/// This plugin renders mpv video through Flutter's GPU-accelerated
/// texture pipeline via FlTextureGL.

#define MPV_PLUGIN_TYPE (mpv_plugin_get_type())

G_DECLARE_FINAL_TYPE(MpvPlugin, mpv_plugin, MPV, PLUGIN, GObject)

/// Creates a new MpvPlugin instance.
MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar);

/// Registers the plugin with Flutter.
void mpv_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // MPV_PLUGIN_H_
