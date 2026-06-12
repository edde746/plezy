import 'dart:async';
import '../media/ids.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/watch_progress.dart';
import '../models/external_player_models.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/watch_state_notifier.dart';
import '../i18n/strings.g.dart';
import 'settings_service.dart';
import 'offline_watch_sync_service.dart';
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
  /// Launch an external player with either a pre-resolved [videoUrl] (e.g.
  /// a local file path for downloaded content) or by asking [client] to
  /// resolve the streaming URL for [metadata]. Each backend implements
  /// `resolveExternalPlaybackUrl` for the right shape (Plex part URL,
  /// Jellyfin `/Videos/{id}/stream?Static=true`).
  static Future<bool> launch({
    required BuildContext context,
    MediaItem? metadata,
    MediaServerClient? client,
    OfflineWatchSyncService? offlineWatchService,
    int mediaIndex = 0,
    String? mediaSourceId,
    String? videoUrl,
  }) async {
    try {
      String resolvedUrl;

      if (videoUrl != null) {
        resolvedUrl = videoUrl;
      } else if (client != null && metadata != null) {
        final url = await client.resolveExternalPlaybackUrl(
          metadata,
          mediaIndex: mediaIndex,
          mediaSourceId: mediaSourceId,
        );
        if (url == null || url.isEmpty) {
          if (context.mounted) {
            showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
          }
          return false;
        }
        resolvedUrl = url;
      } else {
        appLogger.e('ExternalPlayerService.launch requires either videoUrl or client+metadata');
        return false;
      }

      final settings = await SettingsService.getInstance();
      final player = settings.read(SettingsService.selectedExternalPlayer);

      // On Android, always use native intent to avoid url_launcher opening in browser
      if (Platform.isAndroid && context.mounted) {
        final launchResult = await _launchAndroidNative(resolvedUrl, player, context, metadata: metadata);
        if (launchResult.launched && metadata != null) {
          await _reportAndroidExternalProgress(
            launchResult,
            metadata: metadata,
            client: client,
            offlineWatchService: offlineWatchService,
            mediaSourceId: mediaSourceId,
          );
        }
        return launchResult.launched;
      }

      final launched = await player.launch(resolvedUrl);
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

  /// Launch a video on Android using native ACTION_VIEW intent.
  /// Handles local files (file://, content://, absolute paths) and remote URLs.
  static Future<_ExternalPlayerLaunchResult> _launchAndroidNative(
    String url,
    ExternalPlayer player,
    BuildContext context, {
    MediaItem? metadata,
  }) async {
    try {
      final packages = player.id == 'system_default' ? const <String>[] : KnownPlayers.androidPackageCandidates(player);
      final result = await _externalPlayerChannel.invokeMapMethod<String, Object?>('openVideo', {
        'filePath': url,
        if (metadata?.title?.trim().isNotEmpty == true) 'title': metadata!.title!.trim(),
        if ((metadata?.viewOffsetMs ?? 0) > 0) 'startPositionMs': metadata!.viewOffsetMs,
        if (packages.isNotEmpty) 'packages': packages,
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

  static Future<void> _reportAndroidExternalProgress(
    _ExternalPlayerLaunchResult result, {
    required MediaItem metadata,
    required MediaServerClient? client,
    OfflineWatchSyncService? offlineWatchService,
    String? mediaSourceId,
  }) async {
    if (result.playbackError) {
      appLogger.d('External player returned an error result for ${metadata.id}; skipping progress sync');
      return;
    }

    final durationMs = _positive(result.durationMs) ?? _positive(metadata.durationMs);
    final reportedPositionMs = _positive(result.positionMs) ?? (result.playbackCompleted ? durationMs : null);
    if (reportedPositionMs == null) return;

    final positionMs = durationMs == null ? reportedPositionMs : reportedPositionMs.clamp(0, durationMs).toInt();
    final position = Duration(milliseconds: positionMs);
    final duration = durationMs == null ? null : Duration(milliseconds: durationMs);
    if (client == null) {
      await _queueExternalProgress(metadata, offlineWatchService, position: position, duration: duration);
      return;
    }

    try {
      await client.reportPlaybackStarted(
        itemId: metadata.id,
        position: position,
        duration: duration,
        playMethod: 'DirectPlay',
        mediaSourceId: mediaSourceId,
      );
    } catch (e) {
      appLogger.d('External player progress: started call failed (continuing)', error: e);
    }

    try {
      await client.reportPlaybackStopped(
        itemId: metadata.id,
        position: position,
        duration: duration,
        mediaSourceId: mediaSourceId,
      );
    } catch (e) {
      appLogger.w('Failed to sync external player progress for ${metadata.id}', error: e);
      await _queueExternalProgress(metadata, offlineWatchService, position: position, duration: duration);
      return;
    }

    if (duration == null) return;

    WatchStateNotifier().notifyProgress(
      item: metadata,
      viewOffset: position.inMilliseconds,
      duration: duration.inMilliseconds,
      watchedThreshold: client.watchedThreshold,
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
