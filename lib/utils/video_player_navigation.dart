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
import '../watch_together/services/watch_together_controller.dart';
import '../screens/video_player_screen.dart';
import '../services/external_player_service.dart';
import '../services/local_playback_history.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import 'app_logger.dart';
import 'global_key_utils.dart';
import 'platform_detector.dart';
import 'download_version_utils.dart';
import 'media_version_resolver.dart';
import 'provider_extensions.dart';
import 'quality_preset_labels.dart';
import '../i18n/strings.g.dart';

const String kVideoPlayerRouteName = '/video_player';

/// The route contract shared by VOD and Live TV playback.
///
/// The stable route name drives player lifecycle observation, while the
/// opaque zero-duration route prevents the underlying detail screen flashing
/// during player startup and teardown.
PageRouteBuilder<bool> buildVideoPlayerRoute({required WidgetBuilder builder}) {
  return PageRouteBuilder<bool>(
    settings: const RouteSettings(name: kVideoPlayerRouteName),
    pageBuilder: (context, _, _) => builder(context),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

enum VideoPlayerRouteKind { vod, liveTv }

@immutable
final class VideoPlayerLaunchIdentity {
  VideoPlayerLaunchIdentity({
    required MediaItem metadata,
    required this.mediaIndex,
    required String? selectedMediaSourceId,
    required this.selectedQualityPreset,
    required this.isOffline,
    required this.routeKind,
  }) : globalKey = metadata.globalKey,
       mediaSourceId = _normalizeMediaSourceId(selectedMediaSourceId);

  final String globalKey;
  final int mediaIndex;
  final String? mediaSourceId;
  final TranscodeQualityPreset? selectedQualityPreset;
  final bool isOffline;
  final VideoPlayerRouteKind routeKind;

  static String? _normalizeMediaSourceId(String? mediaSourceId) {
    if (mediaSourceId == null || mediaSourceId.trim().isEmpty) return null;
    return mediaSourceId;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VideoPlayerLaunchIdentity &&
            other.globalKey == globalKey &&
            other.mediaIndex == mediaIndex &&
            other.mediaSourceId == mediaSourceId &&
            other.selectedQualityPreset == selectedQualityPreset &&
            other.isOffline == isOffline &&
            other.routeKind == routeKind;
  }

  @override
  int get hashCode => Object.hash(globalKey, mediaIndex, mediaSourceId, selectedQualityPreset, isOffline, routeKind);
}

class VideoPlayerNavigationInFlightGuard {
  final Set<VideoPlayerLaunchIdentity> _identities = <VideoPlayerLaunchIdentity>{};

  bool tryStart(VideoPlayerLaunchIdentity identity) => _identities.add(identity);

  void finish(VideoPlayerLaunchIdentity identity) => _identities.remove(identity);
}

class VideoPlayerActiveRouteGuard {
  Object? _owner;
  VideoPlayerLaunchIdentity? _identity;

  String? get activeGlobalKey => _identity?.globalKey;

  /// The State that currently owns the active player route, if any.
  Object? get owner => _owner;

  VideoPlayerLaunchIdentity? identityFor(Object owner) => identical(_owner, owner) ? _identity : null;

  bool blocks(VideoPlayerLaunchIdentity identity) => _identity == identity;

  void activate(Object owner, VideoPlayerLaunchIdentity identity) {
    _owner = owner;
    _identity = identity;
  }

  bool update(Object owner, VideoPlayerLaunchIdentity identity) {
    if (!identical(_owner, owner)) return false;
    _identity = identity;
    return true;
  }

  bool clear(Object owner) {
    if (!identical(_owner, owner)) return false;
    _owner = null;
    _identity = null;
    return true;
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
  WatchPlaybackLease? watchTogetherLease,
  bool Function()? isLaunchCurrent,
}) async {
  if (!isOffline && watchTogetherLease == null) {
    final watchTogether = context.read<WatchTogetherProvider?>();
    watchTogetherLease = watchTogether?.capturePlaybackLease(selection: watchTogether.isHost);
  }
  final playbackLease = watchTogetherLease;
  bool launchCurrent() => (isLaunchCurrent?.call() ?? true) && (playbackLease?.isCurrent ?? true);
  if (!launchCurrent()) return null;
  if (resolveWatchState) {
    metadata = context.readFreshWatchState(metadata);
  }
  final navigator = Navigator.of(context);
  final sourceRoute = ModalRoute.of(context);
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
  if (!launchCurrent()) return null;
  final mediaIndex = selectedMediaIndex ?? downloadedMediaIndex ?? savedVersion?.index ?? 0;
  final mediaSourceId = selectedMediaSourceId ?? downloadedMediaSourceId ?? savedVersion?.sourceId;

  final launchIdentity = VideoPlayerLaunchIdentity(
    metadata: metadata,
    mediaIndex: mediaIndex,
    selectedMediaSourceId: mediaSourceId,
    selectedQualityPreset: selectedQualityPreset,
    isOffline: isOffline,
    routeKind: VideoPlayerRouteKind.vod,
  );
  var markedInFlight = false;
  if (!usePushReplacement) {
    markedInFlight = _videoPlayerNavigationInFlightGuard.tryStart(launchIdentity);
    if (!markedInFlight) {
      appLogger.d(
        'Video player navigation already in flight for ${metadata.id} (mediaIndex=$mediaIndex), '
        'skipping duplicate navigation',
      );
      return null;
    }
  }

  // Deliberately not awaited inside the try: the route future completes when
  // the player pops, but the in-flight guard must release once the push is
  // committed. Returned after the finally so the guard timing is unchanged.
  Future<bool?>? pushFuture;
  try {
    // Check if external player is enabled. The platform guard comes first so
    // platforms that can never launch an external player skip the settings
    // lookup, and the singleton the saved-version resolve above already
    // initialized is reused — getInstance() is awaited at most once per
    // launch on this path.
    try {
      if (PlatformDetector.supportsExternalPlayers()) {
        final settingsService = SettingsService.instanceOrNull ?? await SettingsService.getInstance();
        if (!launchCurrent()) return null;
        if (settingsService.read(SettingsService.useExternalPlayer)) {
          bool launched = false;

          if (isOffline) {
            final globalKey = metadata.globalKey;
            final videoPath = await downloadProvider.getVideoFilePath(
              globalKey,
              mediaIndex: mediaIndex,
              mediaSourceId: mediaSourceId,
            );
            if (!launchCurrent()) return null;
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
      }
    } catch (e) {
      appLogger.w('External player launch failed, falling back to built-in player', error: e);
    }

    // Prevent stacking an identical video player when already active.
    if (!usePushReplacement && VideoPlayerScreenState.isNavigationActive(launchIdentity)) {
      appLogger.d(
        'Video player already active for ${metadata.globalKey} (mediaIndex=$mediaIndex), skipping duplicate navigation',
      );
      return null;
    }

    // The source route can be removed while the version/preference/external
    // player awaits above run (e.g. the detail deleted from under the launch);
    // a push now would land on top of whatever is current instead. Only the
    // route matters: the launching widget itself (a menu entry, a card) may
    // legitimately be gone by now.
    if (sourceRoute != null && !sourceRoute.isActive) {
      appLogger.d('Video player navigation source route is gone for ${metadata.globalKey}, skipping navigation');
      return null;
    }
    if (!launchCurrent()) return null;

    final route = buildVideoPlayerRoute(
      builder: (_) => VideoPlayerScreen(
        metadata: metadata,
        preferredAudioTrack: preferredAudioTrack,
        preferredSubtitleTrack: preferredSubtitleTrack,
        preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
        selectedMediaIndex: mediaIndex,
        selectedMediaSourceId: mediaSourceId,
        preferredVersionSignature: savedVersion?.signature,
        selectedQualityPreset: selectedQualityPreset,
        isOffline: isOffline,
        watchTogetherLease: playbackLease,
      ),
    );

    pushFuture = usePushReplacement ? navigator.pushReplacement<bool, bool>(route) : navigator.push<bool>(route);
  } finally {
    if (markedInFlight) {
      _videoPlayerNavigationInFlightGuard.finish(launchIdentity);
    }
  }
  return pushFuture;
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
  bool Function()? isLaunchCurrent,
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
    isLaunchCurrent: isLaunchCurrent,
  );

  appLogger.d('Returned from playback, refreshing metadata');

  if (!isOffline && onRefresh != null && context.mounted && (isLaunchCurrent?.call() ?? true)) {
    onRefresh();
  }

  return result;
}

/// Sum of [MediaPart.sizeBytes] across all parts of [version]. Returns
/// null when any part is missing a size (a partial sum would be misleading
/// for the "Original" row in the quality picker).
int? _versionSizeBytes(MediaVersion? version) {
  if (version == null || version.parts.isEmpty) return null;
  var total = 0;
  for (final p in version.parts) {
    final s = p.sizeBytes;
    if (s == null || s <= 0) return null;
    total += s;
  }
  return total > 0 ? total : null;
}

/// The shared "Play Version..." flow behind the detail screen's split Play
/// segment and the context menu entry: pick a version when the item has a
/// choice, pick a transcode quality when the backend can transcode, persist
/// the pick, and launch playback.
///
/// Returns true when playback navigation started; false when the user
/// dismissed a picker or the context went away. The returned future completes
/// after the player route pops, so callers can refresh on return.
Future<bool> promptAndPlayVersion(BuildContext context, MediaItem item) async {
  final itemServerId = serverIdOrNull(item.serverId);
  final client = context.tryGetMediaClientForServer(itemServerId);
  final itemServerOnline =
      itemServerId != null && context.read<MultiServerProvider>().serverManager.isClientOnline(itemServerId);
  // Same flag the in-player Version & Quality sheet reads — keeps both
  // surfaces honest about what the active backend can actually do. Also
  // requires a reachable server: capabilities are static, and a server
  // dropping between surface build and tap must not offer transcodes.
  final canTranscode = itemServerOnline && (client?.capabilities.videoTranscoding ?? false);
  final versions = client == null
      ? item.mediaVersions ?? const <MediaVersion>[]
      : await resolveMediaVersions(item, client);
  if (!context.mounted) return false;

  int selectedVersionIndex = 0;
  if (versions.length > 1) {
    final picked = await showVersionPickerDialog(context, versions, t.mediaMenu.playVersion);
    if (picked == null || !context.mounted) return false;
    selectedVersionIndex = picked;
  }

  final selectedVersion = selectedVersionIndex < versions.length ? versions[selectedVersionIndex] : null;
  TranscodeQualityPreset selectedQuality = TranscodeQualityPreset.original;
  if (canTranscode) {
    final picked = await showQualityPickerDialog(
      context,
      sourceBitrateKbps: selectedVersion?.bitrate,
      sourceDurationMs: item.durationMs,
      sourceSizeBytes: _versionSizeBytes(selectedVersion),
    );
    if (picked == null || !context.mounted) return false;
    selectedQuality = picked;
  }

  // Remember the pick so Continue Watching / plain Play resume this version
  // (#1492) — same store the in-player version switch writes.
  if (versions.length > 1) {
    await saveMediaVersionPreferenceFor(item, index: selectedVersionIndex, versions: versions);
    if (!context.mounted) return false;
  }

  await navigateToVideoPlayer(
    context,
    metadata: item,
    selectedMediaIndex: selectedVersionIndex,
    selectedMediaSourceId: selectedVersion?.id,
    selectedQualityPreset: selectedQuality,
  );
  return true;
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
  final watchTogether = context.read<WatchTogetherProvider>();
  final lease = watchTogether.capturePlaybackLease();
  if (lease == null) return false;
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

  if (!watchTogether.isPlaybackLeaseCurrent(lease) ||
      watchTogether.currentMediaRatingKey != ratingKey ||
      watchTogether.currentMediaServerId != serverId) {
    appLogger.d('WatchTogether: Skipping stale navigation to $ratingKey');
    return false;
  }

  onBeforeNavigate?.call();
  unawaited(navigateToVideoPlayer(context, metadata: metadata, watchTogetherLease: lease));
  return true;
}
