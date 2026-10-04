import 'package:flutter/widgets.dart';

import '../media/ids.dart';
import '../models/livetv_channel.dart';
import '../providers/multi_server_provider.dart';
import '../screens/video_player/live_tv_session_args.dart';
import 'app_logger.dart';
import 'live_tv_player_navigation.dart';

/// A `plezy://live` deep link that tunes a live TV channel.
///
/// Format: `plezy://live?channel=<channel>[&server=<machineIdentifier>][&start=beginning|live]`
///
/// * `channel` (required) is matched against the channel key, identifier,
///   number and call sign, in that order. The first rule that matches exactly
///   one channel wins.
/// * `server` (optional) restricts the lookup to one server. Without it every
///   Live TV server is searched.
/// * `start` (optional) answers the "watch from start" prompt shown when the
///   channel is already being recorded: `beginning` starts at the beginning of
///   the current program, `live` joins at the live edge. When omitted the
///   prompt is shown as usual.
///
/// Intended for automation (e.g. a home automation system launching
/// `am start -a android.intent.action.VIEW -d "plezy://live?channel=4.1&start=beginning"`).
class LiveTvDeepLink {
  const LiveTvDeepLink({required this.channel, this.serverId, this.startPosition = LiveTvStartPosition.ask});

  static const scheme = 'plezy';
  static const host = 'live';

  final String channel;
  final String? serverId;
  final LiveTvStartPosition startPosition;

  /// Parses [link], returning null when it is not a well-formed live link.
  static LiveTvDeepLink? tryParse(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != scheme || uri.host != host) return null;
    final channel = uri.queryParameters['channel']?.trim();
    if (channel == null || channel.isEmpty) return null;
    final server = uri.queryParameters['server']?.trim();
    final start = switch (uri.queryParameters['start']?.trim().toLowerCase()) {
      null || '' => LiveTvStartPosition.ask,
      'beginning' || 'start' => LiveTvStartPosition.beginning,
      'live' || 'now' => LiveTvStartPosition.live,
      _ => null,
    };
    if (start == null) return null;
    return LiveTvDeepLink(
      channel: channel,
      serverId: server == null || server.isEmpty ? null : server,
      startPosition: start,
    );
  }

  /// Selects the channel this link refers to from [channels], or null when no
  /// channel (or more than one channel) matches.
  LiveTvChannel? selectChannel(List<LiveTvChannel> channels) {
    final wanted = channel.toLowerCase();
    final rules = <bool Function(LiveTvChannel)>[
      (c) => c.key == channel,
      (c) => c.identifier == channel,
      (c) => c.number == channel,
      (c) => c.callSign?.toLowerCase() == wanted,
    ];
    for (final rule in rules) {
      final matches = channels.where(rule).toList(growable: false);
      if (matches.length == 1) return matches.single;
      if (matches.length > 1) {
        appLogger.w('Live TV deep link: channel "$channel" is ambiguous (${matches.length} matches)');
        return null;
      }
    }
    return null;
  }

  /// How many times [launch] re-checks Live TV availability before giving up.
  static const coldStartAttempts = 5;
  static const coldStartRetryDelay = Duration(seconds: 2);

  List<LiveTvServerInfo> _sources(MultiServerProvider multiServer) => multiServer.liveTvServers
      .where((source) => serverId == null || source.serverId == serverId)
      .toList(growable: false);

  /// Resolves the channel on the connected Live TV servers and opens the
  /// player. Returns whether playback was launched.
  Future<bool> launch(BuildContext context, MultiServerProvider multiServer) async {
    // On a cold start the servers may still be connecting; give them a moment.
    var sources = _sources(multiServer);
    for (var attempt = 0; sources.isEmpty && attempt < coldStartAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(coldStartRetryDelay);
      if (!context.mounted) return false;
      await multiServer.checkLiveTvAvailability();
      sources = _sources(multiServer);
    }
    if (sources.isEmpty) {
      appLogger.w('Live TV deep link: no Live TV server available${serverId == null ? '' : ' for $serverId'}');
      return false;
    }

    final channels = <LiveTvChannel>[];
    for (final source in sources) {
      final client = multiServer.getClientForServer(ServerId(source.serverId));
      if (client == null) continue;
      try {
        final rows = await client.liveTv.fetchChannels(lineup: source.lineup);
        channels.addAll(rows.map((c) => c.copyWith(serverId: source.serverId, liveDvrKey: source.dvrKey)));
      } catch (e) {
        appLogger.w('Live TV deep link: failed to fetch channels from ${source.serverId}', error: e);
      }
    }

    final match = selectChannel(channels);
    if (match == null) {
      appLogger.w('Live TV deep link: channel "$channel" not found');
      return false;
    }
    if (!context.mounted) return false;
    await navigateToLiveTv(
      context,
      multiServer: multiServer,
      channel: match,
      channels: channels,
      startPosition: startPosition,
    );
    return true;
  }
}
