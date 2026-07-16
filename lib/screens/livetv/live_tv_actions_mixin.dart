import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:provider/provider.dart';

import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/live_tv_matching.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../utils/media_image_helper.dart';
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

  LiveTvChannel? findChannelForProgram(LiveTvProgram program) {
    return liveTvChannels.where((channel) => liveTvProgramMatchesChannel(program, channel)).firstOrNull;
  }

  /// Start live playback for [channel] on its owning server.
  ///
  /// Both backends route through the live-TV navigator so the player
  /// inherits the live-only branches (no Trakt scrobble, no progress
  /// scrobble, channel up/down nav, no resume bookmark). The player starts
  /// the backend-neutral session itself (Plex tune / Jellyfin stream
  /// negotiation under its loading spinner).
  Future<void> tuneChannel(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();
    await navigateToLiveTv(context, multiServer: multiServer, channel: channel, channels: liveTvChannels);
  }

  /// Open the program-details bottom sheet. The poster is resolved from
  /// [posterThumb] on the server identified by [posterServerId].
  void showProgramDetails({
    BuildContext? sheetContext,
    required LiveTvProgram program,
    required LiveTvChannel? channel,
    required String? posterThumb,
    required String? posterServerId,
  }) {
    final effectiveContext = sheetContext ?? context;
    final multiServer = effectiveContext.read<MultiServerProvider>();
    final serverId = serverIdOrNull(posterServerId);
    final client = serverId == null ? null : multiServer.getClientForServer(serverId);
    String? posterUrl;
    if (posterThumb != null && client != null) {
      posterUrl = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: posterThumb,
        maxWidth: 80,
        maxHeight: 120,
        devicePixelRatio: MediaImageHelper.effectiveDevicePixelRatio(effectiveContext),
        imageType: ImageType.poster,
      );
    }

    showProgramDetailsSheet(
      effectiveContext,
      program: program,
      channel: channel,
      posterUrl: posterUrl,
      onTuneChannel: channel != null ? () => tuneChannel(channel) : null,
      client: client,
    );
  }
}
