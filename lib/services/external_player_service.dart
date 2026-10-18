import 'dart:async';
import '../media/ids.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../media/media_item.dart';
import '../media/media_part_timeline.dart';
import '../media/media_server_client.dart';
import '../media/watch_progress.dart';
import '../models/external_player_models.dart';
import '../mpv/models.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/watch_state_notifier.dart';
import '../i18n/strings.g.dart';
import 'settings_service.dart';
import 'offline_watch_sync_service.dart';
import 'playback_initialization_service.dart';
import 'trackers/tracker_coordinator.dart';

const _externalPlayerChannel = MethodChannel('com.plezy/external_player');

class _ExternalPlayerLaunchResult {
  const _ExternalPlayerLaunchResult({
    required this.launched,
    this.positionMs,
    this.durationMs,
    this.playbackCompleted = false,
    this.playbackError = false,
  });

  final bool launched;
  final int? positionMs;
  final int? durationMs;
  final bool playbackCompleted;
  final bool playbackError;

  factory _ExternalPlayerLaunchResult.fromMap(Map<String, Object?>? map) {
    if (map == null) return const _ExternalPlayerLaunchResult(launched: true);
    return _ExternalPlayerLaunchResult(
      launched: map['launched'] == true,
      positionMs: _asInt(map['positionMs']),
      durationMs: _asInt(map['durationMs']),
      playbackCompleted: map['playbackCompleted'] == true,
      playbackError: map['playbackError'] == true,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ExternalPlayerService {
  /// Launch an external player with either a pre-resolved [videoUrl] (the
  /// local file of a downloaded copy) or by asking [client] to resolve the
  /// stream for [metadata]. Each backend implements `resolveExternalPlayback`
  /// for the right URL shape (Plex part URL, Jellyfin
  /// `/Videos/{id}/stream.{container}?Static=true`) and its external
  /// subtitle files, which Android players receive through the intent.
  static Future<bool> launch({
    required BuildContext context,
    MediaItem? metadata,
    MediaServerClient? client,
    OfflineWatchSyncService? offlineWatchService,
    int mediaIndex = 0,
    String? mediaSourceId,
    String? videoUrl,
    bool Function()? isLaunchCurrent,
    VoidCallback? onHandoffPending,
    VoidCallback? onLaunched,
  }) async {
    if (!PlatformDetector.supportsExternalPlayers()) return false;
    bool current() => context.mounted && (isLaunchCurrent?.call() ?? true);
    if (!current()) return false;

    try {
      String resolvedUrl;
      var subtitles = const <SubtitleTrack>[];
      // An external player is handed one file. For an item stacked across
      // several files that is one part, on that part's clock.
      MediaPartTimeline? partTimeline;
      final resume = (metadata?.viewOffsetMs ?? 0) > 0 ? Duration(milliseconds: metadata!.viewOffsetMs!) : null;

      if (videoUrl != null) {
        resolvedUrl = videoUrl;
        // A downloaded copy is handed over as its first file.
        final versions = metadata?.mediaVersions;
        if (versions != null && mediaIndex >= 0 && mediaIndex < versions.length) {
          partTimeline = MediaPartTimeline.fromParts(versions[mediaIndex].parts);
        }
      } else if (client != null && metadata != null) {
        final target = await client.resolveExternalPlayback(
          metadata,
          mediaIndex: mediaIndex,
          mediaSourceId: mediaSourceId,
          position: resume,
        );
        if (target == null || target.url.isEmpty) {
          if (context.mounted) {
            showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
          }
          return false;
        }
        resolvedUrl = target.url;
        subtitles = target.subtitles;
        partTimeline = target.partTimeline;
      } else {
        appLogger.e('ExternalPlayerService.launch requires either videoUrl or client+metadata');
        return false;
      }
      final startPosition = partTimeline == null
          ? resume
          : resume != null && partTimeline.covers(resume)
          ? resume - partTimeline.current.start
          : null;

      final settings = await SettingsService.getInstance();
      if (!current()) return false;
      final player = settings.read(SettingsService.selectedExternalPlayer);
      // Nothing to hand off to: System Default on Apple TV is the case this
      // exists for, since it stays the stored default there.
      if (!player.isAvailable) {
        if (context.mounted) showErrorSnackBar(context, t.externalPlayer.launchFailed);
        return false;
      }

      // On Android, always use native intent to avoid url_launcher opening in browser
      if (Platform.isAndroid && context.mounted) {
        // A downloaded copy's subtitles are the sidecar files saved with it.
        if (videoUrl != null && metadata != null) {
          subtitles = await _downloadedSubtitles(
            context.read<AppDatabase>(),
            videoUrl,
            metadata: metadata,
            client: client,
            mediaIndex: mediaIndex,
          );
          if (!context.mounted || !current()) return false;
        }
        onHandoffPending?.call();
        final launchResult = await _launchAndroidNative(
          resolvedUrl,
          player,
          context,
          metadata: metadata,
          startPosition: startPosition,
          subtitles: subtitles,
        );
        if (launchResult.launched && current()) onLaunched?.call();
        if (launchResult.launched && metadata != null && current()) {
          await _reportAndroidExternalProgress(
            launchResult,
            metadata: metadata,
            client: client,
            offlineWatchService: offlineWatchService,
            mediaSourceId: mediaSourceId,
            partTimeline: partTimeline,
            isLaunchCurrent: current,
          );
        }
        return launchResult.launched;
      }

      if (!current()) return false;
      onHandoffPending?.call();
      final launched = await player.launch(resolvedUrl);
      if (launched && current()) onLaunched?.call();
      if (!launched && context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.appNotInstalled(name: player.name));
      }
      return launched;
    } catch (e) {
      appLogger.e('Failed to launch external player', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.launchFailed);
      }
      return false;
    }
  }

  /// Sidecar subtitles saved with the downloaded copy at [videoUrl].
  /// Best-effort: a copy whose subtitles can't be listed still launches,
  /// just without them.
  static Future<List<SubtitleTrack>> _downloadedSubtitles(
    AppDatabase database,
    String videoUrl, {
    required MediaItem metadata,
    required MediaServerClient? client,
    required int mediaIndex,
  }) async {
    final videoPath = videoUrl.startsWith('file://') ? videoUrl.substring('file://'.length) : videoUrl;
    try {
      final sidecars = await PlaybackInitializationService(
        client: client,
        database: database,
      ).discoverDownloadedSubtitles(metadata, videoPath: videoPath, mediaIndex: mediaIndex);
      return [for (final sidecar in sidecars) sidecar.track];
    } catch (e, stackTrace) {
      appLogger.w('Could not list downloaded subtitles for the external player', error: e, stackTrace: stackTrace);
      return const [];
    }
  }

  /// Launch a video on Android using native ACTION_VIEW intent.
  /// Handles local files (file://, content://, absolute paths) and remote URLs.
  static Future<_ExternalPlayerLaunchResult> _launchAndroidNative(
    String url,
    ExternalPlayer player,
    BuildContext context, {
    MediaItem? metadata,
    Duration? startPosition,
    List<SubtitleTrack> subtitles = const [],
  }) async {
    try {
      final packages = player.id == 'system_default' ? const <String>[] : KnownPlayers.androidPackageCandidates(player);
      final result = await _externalPlayerChannel.invokeMapMethod<String, Object?>('openVideo', {
        'filePath': url,
        if (metadata?.title?.trim().isNotEmpty == true) 'title': metadata!.title!.trim(),
        if (startPosition != null && startPosition > Duration.zero) 'startPositionMs': startPosition.inMilliseconds,
        if (packages.isNotEmpty) 'packages': packages,
        if (subtitles.isNotEmpty) 'subtitles': [for (final track in subtitles) ?_subtitleArgument(track)],
      });
      return _ExternalPlayerLaunchResult.fromMap(result);
    } on PlatformException catch (e) {
      if (e.code == 'APP_NOT_FOUND' && context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.appNotInstalled(name: player.name));
      } else if (context.mounted) {
        showErrorSnackBar(context, t.externalPlayer.launchFailed);
      }
      return const _ExternalPlayerLaunchResult(launched: false);
    }
  }

  /// One `subtitles` entry for the native intent builder. Local sidecars go
  /// as plain paths, the same shape as a downloaded video, so the native side
  /// shares them through its FileProvider.
  static Map<String, Object?>? _subtitleArgument(SubtitleTrack track) {
    final uri = track.uri;
    if (uri == null || uri.isEmpty) return null;
    final name = track.title?.trim();
    return {
      'uri': uri.startsWith('file:') ? Uri.parse(uri).toFilePath() : uri,
      if (name != null && name.isNotEmpty) 'name': name,
      'enabled': track.isDefault,
    };
  }

  /// [partTimeline] places the handed-over file on its item when the item is
  /// stacked across several files: the external player's position is on that
  /// file's clock and its duration is that file's, so both are mapped onto
  /// the item, and playing out a file with another after it leaves the item
  /// at the next file instead of finished.
  static Future<void> _reportAndroidExternalProgress(
    _ExternalPlayerLaunchResult result, {
    required MediaItem metadata,
    required MediaServerClient? client,
    OfflineWatchSyncService? offlineWatchService,
    String? mediaSourceId,
    MediaPartTimeline? partTimeline,
    bool Function()? isLaunchCurrent,
  }) async {
    bool current() => isLaunchCurrent?.call() ?? true;
    if (!current()) return;
    if (result.playbackError) {
      appLogger.d('External player returned an error result for ${metadata.id}; skipping progress sync');
      return;
    }

    final int? durationMs;
    final int? reportedPositionMs;
    if (partTimeline != null) {
      final part = partTimeline.current;
      durationMs = partTimeline.duration.inMilliseconds;
      final filePositionMs = _positive(result.positionMs);
      reportedPositionMs = filePositionMs != null
          ? part.start.inMilliseconds + filePositionMs
          : (result.playbackCompleted ? part.end.inMilliseconds : null);
    } else {
      durationMs = _positive(result.durationMs) ?? _positive(metadata.durationMs);
      reportedPositionMs = _positive(result.positionMs) ?? (result.playbackCompleted ? durationMs : null);
    }
    if (reportedPositionMs == null) return;

    final positionMs = durationMs == null ? reportedPositionMs : reportedPositionMs.clamp(0, durationMs).toInt();
    final position = Duration(milliseconds: positionMs);
    final duration = durationMs == null ? null : Duration(milliseconds: durationMs);
    if (client == null) {
      await _queueExternalProgress(metadata, offlineWatchService, position: position, duration: duration);
      return;
    }

    var startedSucceeded = false;
    try {
      await client.reportPlaybackStarted(
        itemId: metadata.id,
        position: position,
        duration: duration,
        playMethod: 'DirectPlay',
        mediaSourceId: mediaSourceId,
      );
      startedSucceeded = true;
    } catch (e) {
      appLogger.d('External player progress: started call failed (continuing)', error: e);
    }

    if (!current()) return;
    try {
      await client.reportPlaybackStopped(
        itemId: metadata.id,
        position: position,
        duration: duration,
        mediaSourceId: mediaSourceId,
      );
    } catch (e) {
      appLogger.w('Failed to sync external player progress for ${metadata.id}', error: e);
      if (!current()) return;
      await _queueExternalProgress(metadata, offlineWatchService, position: position, duration: duration);
      return;
    }

    if (!current()) return;
    if (duration == null) return;

    WatchStateNotifier().notifyProgress(
      item: metadata,
      cacheServerId: client.cacheServerId,
      viewOffset: position.inMilliseconds,
      duration: duration.inMilliseconds,
      watchedThreshold: client.watchedThreshold,
      // MediaBrowser persists stopped progress only for a session opened by
      // Started; Plex persists every timeline report independently.
      serverAcknowledged: !metadata.backend.usesMediaBrowserApi || startedSucceeded,
    );

    if (isWatchedProgress(
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      threshold: client.watchedThreshold,
    )) {
      try {
        // reportPlaybackStopped above marks the item played on backends that
        // support it (Jellyfin); markWatchedFromPlaybackStop then only emits the
        // local watch event there to avoid double-scrobbling via the Trakt
        // plugin (#1287). Plex still issues the explicit server call.
        await client.markWatchedFromPlaybackStop(metadata);
        if (!current()) return;
        unawaited(TrackerCoordinator.instance.markWatched(metadata, client));
      } catch (e) {
        appLogger.w('Failed to mark external playback watched for ${metadata.id}', error: e);
      }
    }
  }

  @visibleForTesting
  static Future<void> reportAndroidExternalProgressForTesting({
    required int? positionMs,
    required int? durationMs,
    bool playbackCompleted = false,
    bool playbackError = false,
    required MediaItem metadata,
    required MediaServerClient? client,
    OfflineWatchSyncService? offlineWatchService,
    String? mediaSourceId,
    MediaPartTimeline? partTimeline,
  }) {
    return _reportAndroidExternalProgress(
      _ExternalPlayerLaunchResult(
        launched: true,
        positionMs: positionMs,
        durationMs: durationMs,
        playbackCompleted: playbackCompleted,
        playbackError: playbackError,
      ),
      metadata: metadata,
      client: client,
      offlineWatchService: offlineWatchService,
      mediaSourceId: mediaSourceId,
      partTimeline: partTimeline,
    );
  }

  static Future<void> _queueExternalProgress(
    MediaItem metadata,
    OfflineWatchSyncService? offlineWatchService, {
    required Duration position,
    required Duration? duration,
  }) async {
    final serverId = metadata.serverId;
    if (offlineWatchService == null || serverId == null) return;
    await offlineWatchService.queueProgressUpdate(
      serverId: ServerId(serverId),
      itemId: metadata.id,
      viewOffset: duration == null
          ? position.inMilliseconds
          : position.inMilliseconds.clamp(0, duration.inMilliseconds).toInt(),
      duration: duration?.inMilliseconds,
    );
  }

  static int? _positive(int? value) => value != null && value > 0 ? value : null;
}
