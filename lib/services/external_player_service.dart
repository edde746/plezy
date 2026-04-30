import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../models/external_player_models.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../i18n/strings.g.dart';
import 'settings_service.dart';

const _externalPlayerChannel = MethodChannel('com.plezy/external_player');

class ExternalPlayerService {
  /// Launch an external player with either a pre-resolved [videoUrl] (e.g.
  /// a local file path for downloaded content) or by asking [client] to
  /// resolve the streaming URL for [metadata]. Each backend implements
  /// `resolveExternalPlaybackUrl` for the right shape (Plex part URL,
  /// Jellyfin `/Videos/{id}/stream?Static=true`).
  static Future<bool> launch({
    required BuildContext context,
    MediaItem? metadata,
    MediaServerClient? client,
    int mediaIndex = 0,
    String? videoUrl,
  }) async {
    try {
      String resolvedUrl;

      if (videoUrl != null) {
        resolvedUrl = videoUrl;
      } else if (client != null && metadata != null) {
        final url = await client.resolveExternalPlaybackUrl(metadata, mediaIndex: mediaIndex);
        if (url == null || url.isEmpty) {
          if (context.mounted) {
            showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
          }
          return false;
        }
        resolvedUrl = url;
      } else {
        appLogger.e('ExternalPlayerService.launch requires either videoUrl or client+metadata');
        return false;
      }

      final settings = await SettingsService.getInstance();
      final player = settings.read(SettingsService.selectedExternalPlayer);

      // On Android, always use native intent to avoid url_launcher opening in browser
      if (Platform.isAndroid && context.mounted) {
        return _launchAndroidNative(resolvedUrl, player, context);
      }

      final launched = await player.launch(resolvedUrl);
      if (!launched && context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.appNotInstalled(name: player.name));
      }
      return launched;
    } catch (e) {
      appLogger.e('Failed to launch external player', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.launchFailed);
      }
      return false;
    }
  }

  /// Launch a video on Android using native ACTION_VIEW intent.
  /// Handles local files (file://, content://, absolute paths) and remote URLs.
  static Future<bool> _launchAndroidNative(String url, ExternalPlayer player, BuildContext context) async {
    try {
      await _externalPlayerChannel.invokeMethod<bool>('openVideo', {
        'filePath': url,
        if (player.id != 'system_default') 'package': _getAndroidPackage(player),
      });
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'APP_NOT_FOUND' && context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.appNotInstalled(name: player.name));
      } else if (context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.launchFailed);
      }
      return false;
    }
  }

  /// Map known player IDs to their Android package names.
  static String? _getAndroidPackage(ExternalPlayer player) {
    const packageMap = {
      'vlc': 'org.videolan.vlc',
      'mpv': 'is.xyz.mpv',
      'mx_player': 'com.mxtech.videoplayer.ad',
      'just_player': 'com.brouken.player',
    };
    // Known players
    if (packageMap.containsKey(player.id)) return packageMap[player.id];
    // Custom command-type players use the value as package name on Android
    if (player.isCustom && player.customType == CustomPlayerType.command) return player.customValue;
    return null;
  }
}
