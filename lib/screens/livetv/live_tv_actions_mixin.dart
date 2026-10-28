import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:provider/provider.dart';

import '../../i18n/iptv_copy.dart';
import '../../iptv/iptv_source_repository.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/live_tv_matching.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../utils/media_image_helper.dart';
import 'program_details_sheet.dart';

/// Shared live-TV actions: channel lookup, tuning, and program-details sheet.
///
/// Implementers expose their channel list via [liveTvChannels] and invoke
/// [findChannelForProgram], [tuneChannel], and [showProgramDetails] as needed.
mixin LiveTvActionsMixin<T extends StatefulWidget> on State<T> {
  /// Channel list used for lookups and passed into the playback navigator.
  List<LiveTvChannel> get liveTvChannels;

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

  Future<void> tuneProgram(LiveTvChannel channel, LiveTvProgram program) async {
    final multiServer = context.read<MultiServerProvider>();
    await navigateToLiveTv(
      context,
      multiServer: multiServer,
      channel: channel,
      channels: liveTvChannels,
      program: program,
    );
  }

  /// Open the program-details bottom sheet. The poster is resolved from
  /// [posterThumb] on the server identified by [posterServerId].
  Future<void> showProgramDetails({
    BuildContext? sheetContext,
    required LiveTvProgram program,
    required LiveTvChannel? channel,
    required String? posterThumb,
    required String? posterServerId,
    ValueChanged<bool>? onRecordingStateChanged,
  }) async {
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
        pixelRatio: MediaImageHelper.artworkPixelRatio(effectiveContext),
        imageType: ImageType.poster,
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final programStart = program.beginsAt;
    final catchupAge = programStart == null ? null : now - programStart;
    final catchupDays = channel?.iptvCatchupDays;
    final canPlayCatchup = channel?.iptvCatchupAvailable == true &&
        programStart != null &&
        catchupAge != null &&
        catchupAge > 0 &&
        (catchupDays == null || catchupAge <= catchupDays * 86400);

    Future<bool> Function()? onDispatcharrRecordProgram;
    Future<bool> Function()? onLocalIptvRecordProgram;
    final sourceId = channel?.iptvSourceId;
    final profileId = effectiveContext.read<ActiveProfileProvider>().activeId;
    if (sourceId != null && channel?.iptvChannelId != null && profileId != null) {
      final repository = effectiveContext.read<IptvSourceRepository>();
      if (program.beginsAt != null &&
          (program.endsAt ?? 0) > DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        onLocalIptvRecordProgram = () async {
          try {
            await repository.scheduleLocalRecording(profileId, channel!, program);
            if (!effectiveContext.mounted) return true;
            showSnackBar(effectiveContext, t.iptv.localRecordingScheduled);
            return true;
          } on Object catch (error) {
            if (effectiveContext.mounted) {
              showErrorSnackBar(
                effectiveContext,
                error is IptvImportException && error.code == 'recording_schedule_exists'
                    ? t.iptv.localRecordingAlreadyScheduled
                    : t.iptv.recordingActionFailed,
              );
            }
            return false;
          }
        };
      }
      try {
        if (await repository.supportsDispatcharrDvr(profileId, sourceId) && effectiveContext.mounted) {
          onDispatcharrRecordProgram = () async {
            try {
              await repository.scheduleDispatcharrRecording(profileId, channel!, program);
              if (!effectiveContext.mounted) return true;
              showSnackBar(effectiveContext, t.iptv.recordingScheduled);
              return true;
            } on Object catch (error) {
              if (effectiveContext.mounted) {
                showErrorSnackBar(
                  effectiveContext,
                  error is IptvImportException && error.code == 'unsupported'
                      ? t.iptv.recordingActionUnavailable
                      : t.iptv.recordingActionFailed,
                );
              }
              return false;
            }
          };
        }
      } on Object {
        // A missing or locked Dispatcharr configuration should not block the guide.
      }
    }
    if (!effectiveContext.mounted) return;

    showProgramDetailsSheet(
      effectiveContext,
      program: program,
      channel: channel,
      posterUrl: posterUrl,
      onTuneChannel: channel != null ? () => tuneChannel(channel) : null,
      onCatchupProgram: canPlayCatchup ? () => tuneProgram(channel!, program) : null,
      client: client,
      onRecordingStateChanged: onRecordingStateChanged,
      onDispatcharrRecordProgram: onDispatcharrRecordProgram,
      onLocalIptvRecordProgram: onLocalIptvRecordProgram,
    );
  }
}
