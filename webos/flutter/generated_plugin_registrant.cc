//
// Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <shared_preferences_webos/shared_preferences_webos_plugin.h>
#include <flutter_secure_storage_webos/flutter_secure_storage_webos_plugin.h>
#include <video_player_drm/video_player_web_os_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  SharedPreferencesWebosPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SharedPreferencesWebosPlugin"));
  FlutterSecureStorageWebosPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWebosPlugin"));
  VideoPlayerWebOsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("VideoPlayerWebOsPlugin"));
}
