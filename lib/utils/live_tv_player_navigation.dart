import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/material.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../models/livetv_channel.dart';
import '../providers/multi_server_provider.dart';
import '../screens/video_player/live_tv_session_args.dart';
import '../screens/video_player_screen.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';

/// Navigate to the video player for a live TV channel — the single live
/// entry for both backends. The player starts the backend-neutral
/// `LiveTvPlaybackSession` itself (Plex tune / Jellyfin stream negotiation
/// run under its loading spinner), so this only validates that the
/// channel's server is reachable and packages the UX arguments.
///
/// [channels] is the full channel list for channel up/down navigation.
Future<void> navigateToLiveTv(
  BuildContext context, {
  required MultiServerProvider multiServer,
  required LiveTvChannel channel,
  required List<LiveTvChannel> channels,
}) async {
  final serverInfo = liveTvServerInfoForChannel(multiServer, channel);
  if (serverInfo == null) {
    showErrorSnackBar(context, 'Live TV server is not available.');
    return;
  }

  final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
  if (client == null) {
    showErrorSnackBar(context, 'Live TV server is not connected.');
    return;
  }

  final navigator = Navigator.of(context);
  appLogger.d('Navigating to live channel: ${channel.displayName} (${channel.key})');

  // The placeholder carries the actual backend through so any in-player
  // `metadata.backend` branch (transcoder hints, watch-state surfaces) sees
  // the right kind.
  final placeholder = MediaItem(
    id: channel.key,
    backend: client.backend,
    kind: MediaKind.clip,
    title: channel.displayName,
    serverId: channel.serverId,
    serverName: channel.serverName,
    raw: {'key': channel.key},
  );

  final normalizedChannels = List<LiveTvChannel>.of(channels);
  var currentChannelIndex = normalizedChannels.indexWhere(
    (ch) => liveTvChannelScopeKey(ch) == liveTvChannelScopeKey(channel),
  );
  if (currentChannelIndex < 0) {
    normalizedChannels.insert(0, channel);
    currentChannelIndex = 0;
    appLogger.w('Live TV launch channel was not present in navigation list; prepending ${channel.key}');
  }

  final route = PageRouteBuilder<bool>(
    settings: const RouteSettings(name: kVideoPlayerRouteName),
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: placeholder,
      live: LiveTvSessionArgs(
        channel: channel,
        channels: normalizedChannels,
        currentChannelIndex: currentChannelIndex,
      ),
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  unawaited(navigator.push<bool>(route));
}

LiveTvServerInfo? liveTvServerInfoForChannel(MultiServerProvider multiServer, LiveTvChannel channel) {
  final serverId = channel.serverId;
  final dvrKey = channel.liveDvrKey;
  if (serverId != null && dvrKey != null) {
    final exact = multiServer.liveTvServers.where((s) => s.serverId == serverId && s.dvrKey == dvrKey).firstOrNull;
    if (exact != null) return exact;
  }
  if (serverId != null) {
    final serverMatch = multiServer.liveTvServers.where((s) => s.serverId == serverId).firstOrNull;
    if (serverMatch != null) return serverMatch;
  }
  return multiServer.liveTvServers.firstOrNull;
}
