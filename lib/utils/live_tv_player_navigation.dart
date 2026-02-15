import 'package:flutter/material.dart';

import '../models/livetv_channel.dart';
import '../models/plex_metadata.dart';
import '../screens/video_player_screen.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/video_player_navigation.dart';

/// Navigate to the video player for a live TV channel.
///
/// Pushes the player screen immediately with a placeholder metadata.
/// The actual tuning (tune POST + decision GET) happens inside the player,
/// which shows a loading spinner while it works.
///
/// [channels] is the full channel list for channel up/down navigation.
Future<void> navigateToLiveTv(
  BuildContext context, {
  required PlexClient client,
  required String dvrKey,
  required LiveTvChannel channel,
  List<LiveTvChannel>? channels,
}) async {
  final navigator = Navigator.of(context);

  appLogger.d('Navigating to live channel: ${channel.displayName} (${channel.key})');

  final placeholder = PlexMetadata(ratingKey: channel.key, key: channel.key, type: 'clip', title: channel.displayName);

  final route = PageRouteBuilder<bool>(
    settings: const RouteSettings(name: kVideoPlayerRouteName),
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: placeholder,
      isLive: true,
      liveChannelName: channel.displayName,
      liveStreamUrl: null,
      liveChannels: channels,
      liveCurrentChannelIndex: channels?.indexWhere((ch) => ch.key == channel.key),
      liveDvrKey: dvrKey,
      liveClient: client,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  navigator.push<bool>(route);
}
