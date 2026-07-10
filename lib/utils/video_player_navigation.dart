import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_version.dart';
import '../media/media_version_preference.dart';
import '../mpv/mpv.dart';
import '../models/transcode_quality_preset.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/watch_state_store.dart';
import '../watch_together/providers/watch_together_provider.dart';
import '../screens/video_player_screen.dart';
import '../services/external_player_service.dart';
import '../services/local_playback_history.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import 'app_logger.dart';
import 'global_key_utils.dart';
import 'platform_detector.dart';

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
/// [SettingsService.mediaVersionPreferences], scoped by server — raw Plex
/// rating keys are small integers that can collide across servers.
String _mediaVersionPreferenceKey(MediaItem metadata) {
  final serverId = serverIdOrNull(metadata.serverId);
  final id = metadata.grandparentId ?? metadata.id;
  return serverId != null ? buildGlobalKey(serverId, id) : id;
}

/// Key entries were stored under before server scoping. Reads fall back to
/// it; writes migrate it to the scoped key.
String _legacyMediaVersionPreferenceKey(MediaItem metadata) => metadata.grandparentId ?? metadata.id;

/// Entry cap for [SettingsService.mediaVersionPreferences]; oldest entries
/// (by write time, legacy entries first) are evicted past it.
const _maxMediaVersionPreferences = 500;

/// Saved media-version preference for [metadata]'s series/movie, or null when
/// none is stored. Shared by launch navigation and in-player version
/// switching so reads and writes can't drift onto different keys.
Future<MediaVersionPreference?> savedMediaVersionPreferenceFor(MediaItem metadata) async {
  try {
    final settingsService = await SettingsService.getInstance();
    final prefs = settingsService.read(SettingsService.mediaVersionPreferences);
    return prefs[_mediaVersionPreferenceKey(metadata)] ?? prefs[_legacyMediaVersionPreferenceKey(metadata)];
  } catch (_) {
    return null;
  }
}

/// Persist the version at [index] in [versions] as the preferred media
/// version for [metadata]'s series/movie. Callers are explicit-selection
/// sites only — plain plays and backend fallbacks must not write, so a
/// server-side clamp can't silently overwrite the user's choice.
Future<void> saveMediaVersionPreferenceFor(
  MediaItem metadata, {
  required int index,
  required List<MediaVersion> versions,
}) async {
  final settingsService = await SettingsService.getInstance();
  final pref = index >= 0 && index < versions.length
      ? MediaVersionPreference.forVersion(versions[index], index)
      : MediaVersionPreference(index: index, updatedAt: DateTime.now().millisecondsSinceEpoch);
  final updated = {...settingsService.read(SettingsService.mediaVersionPreferences)}
    ..remove(_legacyMediaVersionPreferenceKey(metadata))
    ..[_mediaVersionPreferenceKey(metadata)] = pref;
  await settingsService.write(SettingsService.mediaVersionPreferences, _pruneMediaVersionPreferences(updated));
}

Map<String, MediaVersionPreference> _pruneMediaVersionPreferences(Map<String, MediaVersionPreference> prefs) {
  if (prefs.length <= _maxMediaVersionPreferences) return prefs;
  final entries = prefs.entries.toList()..sort((a, b) => (b.value.updatedAt ?? 0).compareTo(a.value.updatedAt ?? 0));
  return Map.fromEntries(entries.take(_maxMediaVersionPreferences));
}

/// A saved preference resolved for launch: the index to request plus the
/// id/signature evidence for re-resolving it against the authoritative
/// version list during playback initialization.
typedef ResolvedMediaVersionPreference = ({int index, String? sourceId, String? signature});

/// Resolve the saved preference for [metadata] against its version list.
///
/// When [MediaItem.mediaVersions] is populated (Plex hub/detail fetches) the
/// index is verified and the matched version's real id is returned. When it
/// isn't (Jellyfin resume rows omit `MediaSources`), the stored index and
/// signature pass through with a null sourceId — an unverified id from a
/// sibling episode would be meaningless downstream, while a signature is
/// safely re-matched there.
Future<ResolvedMediaVersionPreference?> resolveSavedMediaVersionFor(MediaItem metadata) async {
  final pref = await savedMediaVersionPreferenceFor(metadata);
  if (pref == null) return null;
  final versions = metadata.mediaVersions ?? const <MediaVersion>[];
  if (versions.isEmpty) return (index: pref.index, sourceId: null, signature: pref.signature);
  final index = pref.resolveIndex(versions);
  if (index == null) return null;
  final version = versions[index];
  return (index: index, sourceId: version.id.isEmpty ? null : version.id, signature: version.signature);
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
/// - [resolveWatchState]: Resolve [metadata] through [WatchStateStore] so the
///   resume offset/watched flag are session-fresh even when the caller holds a
///   stale list snapshot. Pass false for explicit intents like play-from-start.
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
  bool resolveWatchState = true,
}) async {
  if (resolveWatchState) {
    metadata = context.readFreshWatchState(metadata);
  }
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

  // Plain Play on a downloaded item must target the version actually on
  // disk. Only one version can be downloaded per item, and saved version
  // preferences describe online intent — they may point at a version that
  // was never downloaded (issue #1440). Explicit caller selections still win.
  int? downloadedMediaIndex;
  String? downloadedMediaSourceId;
  if (isOffline && selectedMediaIndex == null && selectedMediaSourceId == null) {
    final downloaded = await downloadProvider.getCompletedDownload(metadata.globalKey);
    if (downloaded != null) {
      downloadedMediaIndex = downloaded.mediaIndex;
      downloadedMediaSourceId = downloaded.mediaSourceId;
    }
  }

  // Saved preferences only apply when nothing explicit is in play — an
  // explicit caller selection or a downloaded version must never be
  // second-guessed by a remembered choice.
  ResolvedMediaVersionPreference? savedVersion;
  if (selectedMediaIndex == null &&
      selectedMediaSourceId == null &&
      downloadedMediaIndex == null &&
      downloadedMediaSourceId == null) {
    savedVersion = await resolveSavedMediaVersionFor(metadata);
  }
  final mediaIndex = selectedMediaIndex ?? downloadedMediaIndex ?? savedVersion?.index ?? 0;
  final mediaSourceId = selectedMediaSourceId ?? downloadedMediaSourceId ?? savedVersion?.sourceId;

  var markedInFlight = false;
  if (!usePushReplacement) {
    markedInFlight = _videoPlayerNavigationInFlightGuard.tryStart(
      metadata,
      mediaIndex: mediaIndex,
      selectedMediaSourceId: mediaSourceId,
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
      if (PlatformDetector.supportsExternalPlayers() && settingsService.read(SettingsService.useExternalPlayer)) {
        bool launched = false;

        if (isOffline) {
          final globalKey = metadata.globalKey;
          final videoPath = await downloadProvider.getVideoFilePath(
            globalKey,
            mediaIndex: mediaIndex,
            mediaSourceId: mediaSourceId,
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
              mediaSourceId: mediaSourceId,
            );
          }
        } else if (context.mounted) {
          launched = await ExternalPlayerService.launch(
            context: context,
            metadata: metadata,
            client: mediaClient,
            offlineWatchService: offlineWatchService,
            mediaIndex: mediaIndex,
            mediaSourceId: mediaSourceId,
          );
        }

        if (launched) {
          // External playback never reaches the in-player session commit, so
          // record the local last-played history here.
          if (!isOffline) unawaited(LocalPlaybackHistory.recordPlayback(metadata));
          return null;
        }
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
        selectedMediaSourceId: mediaSourceId,
        preferredVersionSignature: savedVersion?.signature,
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
        selectedMediaSourceId: mediaSourceId,
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
///
/// Returns whether navigation was initiated. The fetch can outlive the
/// dispatch that requested it (slow server, host switching again, dispatcher
/// timeout); navigating then would stack a stale player route on top of the
/// live one, so the key is re-validated against the session's current
/// playback snapshot before the push.
Future<bool> navigateToWatchTogetherPlayback(
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

  if (!context.mounted) return false;

  final watchTogether = context.read<WatchTogetherProvider>();
  if (watchTogether.currentMediaRatingKey != ratingKey || watchTogether.currentMediaServerId != serverId) {
    appLogger.d('WatchTogether: Skipping stale navigation to $ratingKey');
    return false;
  }

  onBeforeNavigate?.call();
  unawaited(navigateToVideoPlayer(context, metadata: metadata));
  return true;
}
