import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../mpv/mpv.dart';
import '../models/transcode_quality_preset.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../screens/video_player_screen.dart';
import '../services/external_player_service.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import 'app_logger.dart';

const String kVideoPlayerRouteName = '/video_player';

class VideoPlayerNavigationInFlightGuard {
  final Set<String> _keys = <String>{};

  bool tryStart(
    MediaItem metadata, {
    required int mediaIndex,
    required String? selectedMediaSourceId,
    required TranscodeQualityPreset? selectedQualityPreset,
    required bool isOffline,
  }) {
    return _keys.add(
      _keyFor(
        metadata,
        mediaIndex: mediaIndex,
        selectedMediaSourceId: selectedMediaSourceId,
        selectedQualityPreset: selectedQualityPreset,
        isOffline: isOffline,
      ),
    );
  }

  void finish(
    MediaItem metadata, {
    required int mediaIndex,
    required String? selectedMediaSourceId,
    required TranscodeQualityPreset? selectedQualityPreset,
    required bool isOffline,
  }) {
    _keys.remove(
      _keyFor(
        metadata,
        mediaIndex: mediaIndex,
        selectedMediaSourceId: selectedMediaSourceId,
        selectedQualityPreset: selectedQualityPreset,
        isOffline: isOffline,
      ),
    );
  }

  String _keyFor(
    MediaItem metadata, {
    required int mediaIndex,
    required String? selectedMediaSourceId,
    required TranscodeQualityPreset? selectedQualityPreset,
    required bool isOffline,
  }) {
    return [
      metadata.globalKey,
      mediaIndex,
      selectedMediaSourceId ?? '',
      selectedQualityPreset?.name ?? 'auto',
      isOffline,
    ].join('|');
  }
}

final _videoPlayerNavigationInFlightGuard = VideoPlayerNavigationInFlightGuard();

class WatchTogetherPlaybackNavigationException implements Exception {
  final String message;

  const WatchTogetherPlaybackNavigationException(this.message);

  @override
  String toString() => message;
}

/// Series (keyed by grandparent) or standalone-item key under
/// [SettingsService.mediaVersionPreferences].
String _mediaVersionPreferenceKey(MediaItem metadata) => metadata.grandparentId ?? metadata.id;

/// Saved media-version preference for [metadata], or null when none is
/// stored. Shared by launch navigation and in-player version switching so
/// reads and writes can't drift onto different keys.
Future<int?> savedMediaVersionIndexFor(MediaItem metadata) async {
  try {
    final settingsService = await SettingsService.getInstance();
    return settingsService.read(SettingsService.mediaVersionPreferences)[_mediaVersionPreferenceKey(metadata)];
  } catch (_) {
    return null;
  }
}

/// Persist [index] as the preferred media version for [metadata]'s series/movie.
Future<void> saveMediaVersionIndexFor(MediaItem metadata, int index) async {
  final settingsService = await SettingsService.getInstance();
  await settingsService.write(SettingsService.mediaVersionPreferences, {
    ...settingsService.read(SettingsService.mediaVersionPreferences),
    _mediaVersionPreferenceKey(metadata): index,
  });
}

/// Navigates to the VideoPlayerScreen with instant transitions to prevent white flash.
///
/// This utility function provides a consistent way to navigate to the video player
/// across the app, using PageRouteBuilder with zero-duration transitions to eliminate
/// the white flash that occurs with MaterialPageRoute.
///
/// Parameters:
/// - [context]: The build context for navigation
/// - [metadata]: The neutral [MediaItem] for the content to play
/// - [preferredAudioTrack]: Optional audio track to select on playback start
/// - [preferredSubtitleTrack]: Optional subtitle track to select on playback start
/// - [selectedMediaIndex]: Optional media version index to use; if not provided,
///   loads the saved preference for the series/movie. Defaults to 0 if no preference exists.
/// - [selectedMediaSourceId]: Optional stable backend source id for the chosen version.
/// - [usePushReplacement]: If true, replaces current route instead of pushing;
///   useful for episode-to-episode navigation. Defaults to false.
/// - [isOffline]: If true, plays from downloaded content without requiring server connection.
///
/// Returns a Future that completes with a boolean indicating whether the content
/// was watched, or null if navigation was cancelled.
Future<bool?> navigateToVideoPlayer(
  BuildContext context, {
  required MediaItem metadata,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  SubtitleTrack? preferredSecondarySubtitleTrack,
  int? selectedMediaIndex,
  String? selectedMediaSourceId,
  TranscodeQualityPreset? selectedQualityPreset,
  bool usePushReplacement = false,
  bool isOffline = false,
}) async {
  final navigator = Navigator.of(context);
  final downloadProvider = context.read<DownloadProvider>();
  // Use the manager-routed lookup so Jellyfin items don't trip the
  // Plex-only client. The player branches on the returned type internally.
  final manager = context.read<MultiServerProvider>().serverManager;
  final offlineWatchService = context.read<OfflineWatchSyncService>();
  final serverId = serverIdOrNull(metadata.serverId);
  final mediaClient = serverId != null && (!isOffline || manager.isClientOnline(serverId))
      ? manager.getClient(serverId)
      : null;

  final mediaIndex = selectedMediaIndex ?? await savedMediaVersionIndexFor(metadata) ?? 0;

  var markedInFlight = false;
  if (!usePushReplacement) {
    markedInFlight = _videoPlayerNavigationInFlightGuard.tryStart(
      metadata,
      mediaIndex: mediaIndex,
      selectedMediaSourceId: selectedMediaSourceId,
      selectedQualityPreset: selectedQualityPreset,
      isOffline: isOffline,
    );
    if (!markedInFlight) {
      appLogger.d(
        'Video player navigation already in flight for ${metadata.id} (mediaIndex=$mediaIndex), '
        'skipping duplicate navigation',
      );
      return null;
    }
  }

  try {
    // Check if external player is enabled
    try {
      final settingsService = await SettingsService.getInstance();
      if (settingsService.read(SettingsService.useExternalPlayer)) {
        bool launched = false;

        if (isOffline) {
          final globalKey = metadata.globalKey;
          final videoPath = await downloadProvider.getVideoFilePath(
            globalKey,
            mediaIndex: mediaIndex,
            mediaSourceId: selectedMediaSourceId,
          );
          if (videoPath != null && context.mounted) {
            final videoUrl = videoPath.contains('://') ? videoPath : 'file://$videoPath';
            launched = await ExternalPlayerService.launch(
              context: context,
              videoUrl: videoUrl,
              metadata: metadata,
              client: mediaClient,
              offlineWatchService: offlineWatchService,
              mediaIndex: mediaIndex,
              mediaSourceId: selectedMediaSourceId,
            );
          }
        } else if (context.mounted) {
          launched = await ExternalPlayerService.launch(
            context: context,
            metadata: metadata,
            client: mediaClient,
            offlineWatchService: offlineWatchService,
            mediaIndex: mediaIndex,
            mediaSourceId: selectedMediaSourceId,
          );
        }

        if (launched) return null;
      }
    } catch (e) {
      appLogger.w('External player launch failed, falling back to built-in player', error: e);
    }

    // Prevent stacking an identical video player when already active
    if (!usePushReplacement &&
        VideoPlayerScreenState.activeId == metadata.id &&
        VideoPlayerScreenState.activeMediaIndex == mediaIndex) {
      appLogger.d(
        'Video player already active for ${metadata.id} (mediaIndex=$mediaIndex), skipping duplicate navigation',
      );
      return null;
    }

    final route = PageRouteBuilder<bool>(
      settings: const RouteSettings(name: kVideoPlayerRouteName),
      pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
        metadata: metadata,
        preferredAudioTrack: preferredAudioTrack,
        preferredSubtitleTrack: preferredSubtitleTrack,
        preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
        selectedMediaIndex: mediaIndex,
        selectedMediaSourceId: selectedMediaSourceId,
        selectedQualityPreset: selectedQualityPreset,
        isOffline: isOffline,
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );

    return usePushReplacement ? navigator.pushReplacement<bool, bool>(route) : navigator.push<bool>(route);
  } finally {
    if (markedInFlight) {
      _videoPlayerNavigationInFlightGuard.finish(
        metadata,
        mediaIndex: mediaIndex,
        selectedMediaSourceId: selectedMediaSourceId,
        selectedQualityPreset: selectedQualityPreset,
        isOffline: isOffline,
      );
    }
  }
}

/// Navigates to the video player and optionally refreshes content when returning.
///
/// This helper consolidates the common pattern of:
/// 1. Navigating to the video player
/// 2. Logging the return
/// 3. Calling a refresh callback if not offline
///
/// Parameters:
/// - [context]: The build context for navigation
/// - [metadata]: The neutral [MediaItem] for the content to play
/// - [isOffline]: If true, plays from downloaded content
/// - [onRefresh]: Optional callback to refresh data when returning from playback
///   (only called when not offline)
/// - All other parameters are passed through to [navigateToVideoPlayer]
Future<bool?> navigateToVideoPlayerWithRefresh(
  BuildContext context, {
  required MediaItem metadata,
  bool isOffline = false,
  VoidCallback? onRefresh,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  SubtitleTrack? preferredSecondarySubtitleTrack,
  int? selectedMediaIndex,
  String? selectedMediaSourceId,
  bool usePushReplacement = false,
}) async {
  final result = await navigateToVideoPlayer(
    context,
    metadata: metadata,
    isOffline: isOffline,
    preferredAudioTrack: preferredAudioTrack,
    preferredSubtitleTrack: preferredSubtitleTrack,
    preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
    selectedMediaIndex: selectedMediaIndex,
    selectedMediaSourceId: selectedMediaSourceId,
    usePushReplacement: usePushReplacement,
  );

  appLogger.d('Returned from playback, refreshing metadata');

  if (!isOffline && onRefresh != null && context.mounted) {
    onRefresh();
  }

  return result;
}

/// Resolves the current Watch Together media and opens the video player.
Future<void> navigateToWatchTogetherPlayback(
  BuildContext context, {
  required String ratingKey,
  required ServerId serverId,
  VoidCallback? onBeforeNavigate,
}) async {
  final multiServer = context.read<MultiServerProvider>();
  final client = multiServer.getClientForServer(serverId);

  if (client == null) {
    throw const WatchTogetherPlaybackNavigationException('Watch Together server is unavailable');
  }

  final metadata = await client.fetchItem(ratingKey);
  if (metadata == null) {
    throw const WatchTogetherPlaybackNavigationException('Current Watch Together media is unavailable');
  }

  if (!context.mounted) return;

  onBeforeNavigate?.call();
  unawaited(navigateToVideoPlayer(context, metadata: metadata));
}
