import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../services/settings_service.dart';
import 'app_locale_utils.dart';

/// Keeps Android 13's app-language picker and PlezyNG's picker in agreement.
/// The checkpoint distinguishes an external OS change from our previous write,
/// including choosing “System default” while the app was not running.
class PlatformLocaleSync {
  static const channel = MethodChannel('com.edde746.plezy/app_locale');
  static const _checkpointKey = 'native_app_locale_checkpoint';

  static Future<void> synchronize(SettingsService settings) async {
    if (!Platform.isAndroid) return;
    await synchronizeChannel(settings);
  }

  static Future<void> synchronizeChannel(SettingsService settings) async {
    String? platformTag;
    try {
      platformTag = await channel.invokeMethod<String>('getApplicationLocale');
    } on MissingPluginException {
      return; // Desktop, older Android, and engines without the host bridge.
    } on PlatformException {
      return; // A platform failure must not prevent the Dart language choice.
    }
    if (platformTag == null) return;
    final checkpoint = settings.readNullableString(_checkpointKey);
    final changedExternally = checkpoint == null ? platformTag.isNotEmpty : checkpoint != platformTag;
    if (changedExternally) {
      if (platformTag.isEmpty) {
        await settings.reset(SettingsService.appLocale);
      } else {
        final pieces = platformTag.split(',').first.split('-');
        final locale = Locale.fromSubtags(languageCode: pieces.first,
          scriptCode: pieces.skip(1).where((p) => p.length == 4).firstOrNull,
          countryCode: pieces.skip(1).where((p) => p.length == 2 || p.length == 3).firstOrNull);
        await settings.write(SettingsService.appLocale, resolvePreferredAppLocale([locale]));
      }
      await settings.writeString(_checkpointKey, platformTag);
      return;
    }
    final explicit = settings.readNullableString(SettingsService.appLocale.key)?.isNotEmpty == true;
    final desired = explicit ? settings.read(SettingsService.appLocale).languageTag : '';
    if (desired != platformTag) {
      try {
        await channel.invokeMethod<void>('setApplicationLocale', desired);
      } on PlatformException {
        return;
      }
    }
    await settings.writeString(_checkpointKey, desired);
  }
}
