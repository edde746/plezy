import 'package:flutter/material.dart';

import '../models/external_player_models.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../i18n/strings.g.dart';
import 'plex_client.dart';
import 'settings_service.dart';

class ExternalPlayerService {
  static Future<bool> launch({
    required BuildContext context,
    required PlexMetadata metadata,
    required PlexClient client,
    int mediaIndex = 0,
  }) async {
    try {
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

      final videoUrl = playbackData.videoUrl!;
      final settings = await SettingsService.getInstance();
      final player = settings.getSelectedExternalPlayer();

      appLogger.d('Launching external player: ${player.name} with URL: $videoUrl');

      final launched = await player.launch(videoUrl);
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
}
