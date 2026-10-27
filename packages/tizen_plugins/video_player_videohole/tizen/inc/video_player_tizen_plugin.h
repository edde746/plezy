#ifndef FLUTTER_PLUGIN_VIDEO_PLAYER_TIZEN_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_PLAYER_TIZEN_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#include <cstdint>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void VideoPlayerTizenPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_VIDEO_PLAYER_TIZEN_PLUGIN_H_
