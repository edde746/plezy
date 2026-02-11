import 'package:flutter/material.dart';

import '../models/livetv_channel.dart';
import '../screens/video_player_screen.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/plex_url_helper.dart';
import '../utils/video_player_navigation.dart';

/// Tune to a live TV channel and launch the video player.
///
/// 1. Calls `tuneChannel()` to get metadata + stream path
/// 2. Navigates to the VideoPlayerScreen with `isLive: true`
///
/// [channels] is the full channel list for channel up/down navigation.
Future<void> navigateToLiveTv(
  BuildContext context, {
  required PlexClient client,
  required String dvrKey,
  required LiveTvChannel channel,
  List<LiveTvChannel>? channels,
}) async {
  final channelId = channel.identifier ?? channel.key;

  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  appLogger.d('Tuning to channel: ${channel.displayName} ($channelId)');

  final result = await client.tuneChannel(dvrKey, channelId);

  if (result == null) {
    appLogger.e('Failed to tune channel $channelId');
    if (context.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to tune to ${channel.displayName}')),
      );
    }
    return;
  }

  final streamUrl = '${client.config.baseUrl}${result.streamPath}'.withPlexToken(client.config.token);

  if (!context.mounted) return;

  final route = PageRouteBuilder<bool>(
    settings: const RouteSettings(name: kVideoPlayerRouteName),
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: result.metadata,
      isLive: true,
      liveChannelName: channel.displayName,
      liveStreamUrl: streamUrl,
      liveChannels: channels,
      liveCurrentChannelIndex: channels?.indexWhere(
        (ch) => (ch.identifier ?? ch.key) == channelId,
      ),
      liveDvrKey: dvrKey,
      liveClient: client,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  navigator.push<bool>(route);
}
