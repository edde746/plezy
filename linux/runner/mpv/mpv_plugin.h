#ifndef MPV_PLUGIN_H_
#define MPV_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

#include <memory>

#include "mpv_player.h"

G_BEGIN_DECLS

/// Plugin for MPV playback on Linux.
///
/// The video instance renders into a native Wayland plane: a wl_subsurface
/// below the Flutter surface, which is what can carry HDR. It is the only
/// video path - where it cannot be brought up, initialize() fails with
/// VIDEO_PLANE_UNSUPPORTED naming the reason rather than degrading to
/// something the user cannot see. See start_video_plane() for the conditions.
/// The audio-only instance (music playback) skips all video work and runs mpv
/// with video disabled.

#define MPV_PLUGIN_TYPE (mpv_plugin_get_type())

G_DECLARE_FINAL_TYPE(MpvPlugin, mpv_plugin, MPV, PLUGIN, GObject)

/// Creates a new MpvPlugin instance on the given method channel name (the
/// event channel is |channel_name| + "/events").
MpvPlugin* mpv_plugin_new(FlPluginRegistrar* registrar, const gchar* channel_name, gboolean audio_only);

/// Registers the video plugin with Flutter.
void mpv_plugin_register_with_registrar(FlPluginRegistrar* registrar);

/// Registers the audio-only (music) plugin with Flutter.
void mpv_audio_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // MPV_PLUGIN_H_
