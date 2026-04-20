import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../utils/plex_image_helper.dart';
import 'program_details_sheet.dart';

/// Shared live-TV actions: channel lookup, tuning, and program-details sheet.
///
/// Implementers expose their channel list via [liveTvChannels] and invoke
/// [findChannel], [tuneChannel], and [showProgramDetails] as needed.
mixin LiveTvActionsMixin<T extends StatefulWidget> on State<T> {
  /// Channel list used for lookups and passed into the playback navigator.
  List<LiveTvChannel> get liveTvChannels;

  /// Look up a channel by identifier or key. Returns null if no match.
  LiveTvChannel? findChannel(String? channelIdentifier) {
    if (channelIdentifier == null) return null;
    return liveTvChannels.where((ch) {
      return ch.identifier == channelIdentifier || ch.key == channelIdentifier;
    }).firstOrNull;
  }

  /// Start live playback for [channel] on its owning server.
  Future<void> tuneChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();
    final serverInfo =
        multiServer.liveTvServers.where((s) => s.serverId == channel.serverId).firstOrNull ??
        multiServer.liveTvServers.firstOrNull;
    if (serverInfo == null) return;

    final client = multiServer.getClientForServer(serverInfo.serverId);
    if (client == null) return;

    await navigateToLiveTv(
      context,
      client: client,
      dvrKey: serverInfo.dvrKey,
      channel: channel,
      channels: liveTvChannels,
    );
  }

  /// Open the program-details bottom sheet. The poster is resolved from
  /// [posterThumb] on the server identified by [posterServerId].
  void showProgramDetails({
    required LiveTvProgram program,
    required LiveTvChannel? channel,
    required String? posterThumb,
    required String posterServerId,
  }) {
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(posterServerId);
    String? posterUrl;
    if (posterThumb != null && client != null) {
      posterUrl = PlexImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: posterThumb,
        maxWidth: 80,
        maxHeight: 120,
        devicePixelRatio: PlexImageHelper.effectiveDevicePixelRatio(context),
        imageType: ImageType.poster,
      );
    }

    showProgramDetailsSheet(
      context,
      program: program,
      channel: channel,
      posterUrl: posterUrl,
      onTuneChannel: channel != null ? () => tuneChannel(channel) : null,
    );
  }
}
