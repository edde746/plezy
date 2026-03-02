import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../mpv/mpv.dart';
import '../models/plex_metadata.dart';
import '../models/plex_video_playback_data.dart';
import '../providers/download_provider.dart';
import '../screens/video_player_screen.dart';
import '../services/external_player_service.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import 'app_logger.dart';

const String kVideoPlayerRouteName = '/video_player';

/// Navigates to the VideoPlayerScreen with instant transitions to prevent white flash.
///
/// This utility function provides a consistent way to navigate to the video player
/// across the app, using PageRouteBuilder with zero-duration transitions to eliminate
/// the white flash that occurs with MaterialPageRoute.
///
/// Parameters:
/// - [context]: The build context for navigation
/// - [metadata]: The Plex metadata for the content to play
/// - [preferredAudioTrack]: Optional audio track to select on playback start
/// - [preferredSubtitleTrack]: Optional subtitle track to select on playback start
/// - [selectedMediaIndex]: Optional media version index to use; if not provided,
///   loads the saved preference for the series/movie. Defaults to 0 if no preference exists.
/// - [usePushReplacement]: If true, replaces current route instead of pushing;
///   useful for episode-to-episode navigation. Defaults to false.
/// - [isOffline]: If true, plays from downloaded content without requiring server connection.
///
/// Returns a Future that completes with a boolean indicating whether the content
/// was watched, or null if navigation was cancelled.
Future<bool?> navigateToVideoPlayer(
  BuildContext context, {
  required PlexMetadata metadata,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  int? selectedMediaIndex,
  bool usePushReplacement = false,
  bool isOffline = false,
  PlexVideoPlaybackData? playbackData,
}) async {
  // Extract context-dependent values before any async operations
  final navigator = Navigator.of(context);
  final downloadProvider = context.read<DownloadProvider>();
  final client = isOffline ? null : context.getClientForMetadata(metadata);

  // Load saved media version preference if not explicitly provided
  int mediaIndex = selectedMediaIndex ?? 0;
  var effectivePlaybackData = playbackData;
  if (selectedMediaIndex == null) {
    try {
      final settingsService = await SettingsService.getInstance();
      final seriesKey = metadata.grandparentRatingKey ?? metadata.ratingKey;
      final savedPreference = settingsService.getMediaVersionPreference(seriesKey);
      if (savedPreference != null) {
        mediaIndex = savedPreference;
        // Pre-parsed playbackData was built with mediaIndex=0; invalidate if
        // the resolved index differs so the player re-fetches with the correct one
        if (savedPreference != 0) {
          effectivePlaybackData = null;
        }
      }
    } catch (e) {
      // Ignore errors loading preference, use default
    }
  }

  // Check if external player is enabled
  try {
    final settingsService = await SettingsService.getInstance();
    if (settingsService.getUseExternalPlayer()) {
      bool launched = false;

      if (isOffline) {
        // Offline mode: resolve local file path for the external player
        final globalKey = metadata.globalKey;
        final videoPath = await downloadProvider.getVideoFilePath(globalKey);
        if (videoPath != null && context.mounted) {
          final videoUrl = videoPath.contains('://') ? videoPath : 'file://$videoPath';
          launched = await ExternalPlayerService.launch(context: context, videoUrl: videoUrl);
        }
      } else if (context.mounted) {
        launched = await ExternalPlayerService.launch(
          context: context,
          metadata: metadata,
          client: client!,
          mediaIndex: mediaIndex,
        );
      }

      if (launched) return null;
      // Fall through to built-in player on failure
    }
  } catch (e) {
    appLogger.w('External player launch failed, falling back to built-in player', error: e);
  }

  // Prevent stacking an identical video player when already active
  if (!usePushReplacement &&
      VideoPlayerScreenState.activeRatingKey == metadata.ratingKey &&
      VideoPlayerScreenState.activeMediaIndex == mediaIndex) {
    appLogger.d(
      'Video player already active for ${metadata.ratingKey} (mediaIndex=$mediaIndex), skipping duplicate navigation',
    );
    return null;
  }

  final route = PageRouteBuilder<bool>(
    settings: const RouteSettings(name: kVideoPlayerRouteName),
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: metadata,
      preferredAudioTrack: preferredAudioTrack,
      preferredSubtitleTrack: preferredSubtitleTrack,
      selectedMediaIndex: mediaIndex,
      isOffline: isOffline,
      playbackData: effectivePlaybackData,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  return usePushReplacement ? navigator.pushReplacement<bool, bool>(route) : navigator.push<bool>(route);
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
/// - [metadata]: The Plex metadata for the content to play
/// - [isOffline]: If true, plays from downloaded content
/// - [onRefresh]: Optional callback to refresh data when returning from playback
///   (only called when not offline)
/// - All other parameters are passed through to [navigateToVideoPlayer]
Future<bool?> navigateToVideoPlayerWithRefresh(
  BuildContext context, {
  required PlexMetadata metadata,
  bool isOffline = false,
  VoidCallback? onRefresh,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  int? selectedMediaIndex,
  bool usePushReplacement = false,
  PlexVideoPlaybackData? playbackData,
}) async {
  final result = await navigateToVideoPlayer(
    context,
    metadata: metadata,
    isOffline: isOffline,
    preferredAudioTrack: preferredAudioTrack,
    preferredSubtitleTrack: preferredSubtitleTrack,
    selectedMediaIndex: selectedMediaIndex,
    usePushReplacement: usePushReplacement,
    playbackData: playbackData,
  );

  appLogger.d('Returned from playback, refreshing metadata');

  // Refresh data when returning from video player (skip if offline)
  if (!isOffline && onRefresh != null) {
    onRefresh();
  }

  return result;
}
