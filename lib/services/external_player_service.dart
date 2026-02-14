import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/external_player_models.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../i18n/strings.g.dart';
import 'plex_client.dart';
import 'settings_service.dart';

const _externalPlayerChannel = MethodChannel('app.plezy/external_player');

class ExternalPlayerService {
  /// Launch an external player with either a pre-resolved [videoUrl] (e.g. local
  /// file path for downloaded content) or by fetching the streaming URL from [client].
  static Future<bool> launch({
    required BuildContext context,
    PlexMetadata? metadata,
    PlexClient? client,
    int mediaIndex = 0,
    String? videoUrl,
  }) async {
    try {
      String resolvedUrl;

      if (videoUrl != null) {
        resolvedUrl = videoUrl;
      } else if (client != null && metadata != null) {
        final playbackData = await client.getVideoPlaybackData(
          metadata.ratingKey,
          mediaIndex: mediaIndex,
        );

        if (!playbackData.hasValidVideoUrl) {
          if (context.mounted) {
            showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
          }
          return false;
        }
        resolvedUrl = playbackData.videoUrl!;
      } else {
        appLogger.e('ExternalPlayerService.launch requires either videoUrl or client+metadata');
        return false;
      }

      final settings = await SettingsService.getInstance();
      final player = settings.getSelectedExternalPlayer();

      appLogger.d('Launching external player: ${player.name} with URL: $resolvedUrl');

      // On Android, use native intent for local files (file:// and content://)
      if (Platform.isAndroid && _isLocalUrl(resolvedUrl)) {
        return _launchAndroidLocalFile(resolvedUrl, player, context);
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

  static bool _isLocalUrl(String url) {
    return url.startsWith('file://') || url.startsWith('content://') || url.startsWith('/');
  }

  /// Launch a local video file on Android using native ACTION_VIEW intent
  /// with FileProvider content:// URI and FLAG_GRANT_READ_URI_PERMISSION.
  static Future<bool> _launchAndroidLocalFile(String url, ExternalPlayer player, BuildContext context) async {
    try {
      final filePath = url.startsWith('file://') ? url.substring(7) : url;
      final result = await _externalPlayerChannel.invokeMethod<bool>('openVideo', {
        'filePath': filePath,
        if (player.id != 'system_default') 'package': _getAndroidPackage(player),
      });
      final launched = result ?? false;
      if (!launched && context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.appNotInstalled(name: player.name));
      }
      return launched;
    } catch (e) {
      appLogger.w('Android native intent failed, falling back to player.launch', error: e);
      return player.launch(url);
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
