import 'dart:async';

import 'package:flutter/material.dart';

import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../models/livetv_channel.dart';
import '../providers/multi_server_provider.dart';
import '../screens/video_player_screen.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';

/// Navigate to the video player for a live TV channel.
///
/// Plex flow: pass [liveClient] + [dvrKey] and the player will run the
/// `/livetv/.../tune` POST + transcode decision inside its loading spinner.
///
/// Jellyfin flow: pass a pre-resolved [liveStreamUrl] (e.g. from
/// [JellyfinClient.buildDirectStreamUrl]) plus [liveClient], and leave
/// [dvrKey] null.
/// The player skips Plex's tune step and points the engine at the URL
/// directly.
///
/// [backend] is the actual backend serving the channel — the placeholder
/// `MediaItem` carries this through so any in-player `metadata.backend`
/// branch (transcoder hints, watch-state surfaces) sees the right kind.
///
/// [channels] is the full channel list for channel up/down navigation.
Future<void> navigateToLiveTv(
  BuildContext context, {
  MediaServerClient? liveClient,
  String? dvrKey,
  String? liveStreamUrl,
  String? liveSessionIdentifier,
  required MediaBackend backend,
  required LiveTvChannel channel,
  List<LiveTvChannel>? channels,
}) async {
  assert(
    liveStreamUrl != null || (liveClient is PlexClient && dvrKey != null),
    'navigateToLiveTv needs either a pre-resolved stream URL or a Plex client + dvrKey to tune',
  );
  final navigator = Navigator.of(context);

  appLogger.d('Navigating to live channel: ${channel.displayName} (${channel.key})');

  final placeholder = MediaItem(
    id: channel.key,
    backend: backend,
    kind: MediaKind.clip,
    title: channel.displayName,
    serverId: channel.serverId,
    serverName: channel.serverName,
    raw: {'key': channel.key},
  );

  final route = PageRouteBuilder<bool>(
    settings: const RouteSettings(name: kVideoPlayerRouteName),
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: placeholder,
      isLive: true,
      liveChannelName: channel.displayName,
      liveStreamUrl: liveStreamUrl,
      liveChannels: channels,
      liveCurrentChannelIndex: channels?.indexWhere(
        (ch) => liveTvChannelScopeKey(ch) == liveTvChannelScopeKey(channel),
      ),
      liveDvrKey: dvrKey,
      liveClient: liveClient,
      liveSessionIdentifier: liveSessionIdentifier,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  unawaited(navigator.push<bool>(route));
}

Future<void> tuneAndNavigateToLiveTv(
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

  final genericClient = multiServer.getClientForServer(serverInfo.serverId);
  if (genericClient == null) {
    showErrorSnackBar(context, 'Live TV server is not connected.');
    return;
  }
  final resolution = await genericClient.liveTv.resolveStreamUrl(channel.key, dvrKey: serverInfo.dvrKey);
  if (!context.mounted) return;
  if (resolution != null) {
    await navigateToLiveTv(
      context,
      liveClient: genericClient,
      liveStreamUrl: resolution.url,
      liveSessionIdentifier: resolution.playSessionId,
      backend: genericClient.backend,
      channel: channel,
      channels: channels,
    );
    return;
  }

  final plexClient = multiServer.getPlexClientForServer(serverInfo.serverId);
  if (plexClient == null) {
    appLogger.w('Failed to resolve live stream URL for ${channel.displayName} on ${genericClient.backend.id}');
    showErrorSnackBar(context, 'Unable to start this live TV channel.');
    return;
  }
  await navigateToLiveTv(
    context,
    liveClient: plexClient,
    dvrKey: serverInfo.dvrKey,
    backend: plexClient.backend,
    channel: channel,
    channels: channels,
  );
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
