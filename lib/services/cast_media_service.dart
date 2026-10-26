import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../mpv/models.dart';
import '../widgets/app_icon.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/watch_state_notifier.dart';
import 'playback_report_session.dart';
import 'trackers/tracker_coordinator.dart';

/// Google Cast handoff for server-resolved streams.
///
/// Plex, Jellyfin and Emby URLs are resolved by their existing client adapters;
/// credentials stay in the self-contained stream URL, so the default Cast
/// receiver does not need custom request headers or a fork-specific receiver.
class CastMediaService extends ChangeNotifier {
  CastMediaService._();

  static final CastMediaService instance = CastMediaService._();

  static bool get isSupportedPlatform => Platform.isAndroid || (Platform.isIOS && !PlatformDetector.isAppleTV());

  final _discovery = GoogleCastDiscoveryManager.instance;
  final _sessions = GoogleCastSessionManager.instance;
  final _remote = GoogleCastRemoteMediaClient.instance;

  bool _initialized = false;
  String? _deviceName;
  MediaItem? _activeItem;
  MediaServerClient? _activeClient;
  Duration _partStart = Duration.zero;
  Duration? _duration;
  PlaybackReportSession? _reportSession;
  Timer? _progressTimer;
  StreamSubscription<GoogleCastSession?>? _sessionSubscription;
  StreamSubscription<GoggleCastMediaStatus?>? _statusSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  bool _finishingPlayback = false;
  bool? _lastPausedState;

  bool get isConnected => isSupportedPlatform && _sessions.hasConnectedSession;
  String? get deviceName => _deviceName ?? _sessions.currentSession?.device?.friendlyName;
  MediaItem? get activeItem => _activeItem;
  GoggleCastMediaStatus? get mediaStatus => _remote.mediaStatus;
  Duration get playerPosition => _remote.playerPosition;

  Future<void> initialize() async {
    if (_initialized || !isSupportedPlatform) return;
    const applicationId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
    final options = Platform.isAndroid
        ? GoogleCastOptionsAndroid(appId: applicationId, stopCastingOnAppTerminated: false)
        : IOSGoogleCastOptions(
            GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(applicationId),
            stopCastingOnAppTerminated: false,
          );
    await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
    _sessionSubscription = _sessions.currentSessionStream.listen(_onSessionChanged);
    _statusSubscription = _remote.mediaStatusStream.listen(_onMediaStatusChanged);
    _positionSubscription = _remote.playerPositionStream.listen((_) => notifyListeners());
    _initialized = true;
  }

  Future<void> handleCastPressed(
    BuildContext context, {
    required MediaServerClient client,
    required MediaItem item,
    int mediaIndex = 0,
    String? mediaSourceId,
  }) async {
    await initialize();
    if (_sessions.hasConnectedSession) {
      if (_activeItem?.id == item.id && _activeItem?.serverId == item.serverId) {
        if (context.mounted) await showControls(context);
      } else {
        await _startSessionAndLoad(
          null,
          client: client,
          item: item,
          mediaIndex: mediaIndex,
          mediaSourceId: mediaSourceId,
        );
      }
      return;
    }

    if (!context.mounted) return;
    final device = await _pickDevice(context);
    if (device == null || !context.mounted) return;
    await _startSessionAndLoad(
      device,
      client: client,
      item: item,
      mediaIndex: mediaIndex,
      mediaSourceId: mediaSourceId,
    );
  }

  Future<GoogleCastDevice?> _pickDevice(BuildContext context) async {
    await _discovery.startDiscovery(activeScan: Platform.isAndroid);
    try {
      if (!context.mounted) return null;
      return await showModalBottomSheet<GoogleCastDevice>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                  child: Text(t.cast.chooseDevice, style: Theme.of(sheetContext).textTheme.titleLarge),
                ),
                Expanded(
                  child: StreamBuilder<List<GoogleCastDevice>>(
                    stream: _discovery.devicesStream,
                    initialData: _discovery.devices,
                    builder: (context, snapshot) {
                      final devices = snapshot.data ?? const <GoogleCastDevice>[];
                      if (devices.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(t.cast.searching),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return ListTile(
                            leading: const AppIcon(Symbols.cast_rounded),
                            title: Text(device.friendlyName),
                            subtitle: device.modelName == null ? null : Text(device.modelName!),
                            onTap: () => Navigator.of(context).pop(device),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      await _discovery.stopDiscovery();
    }
  }

  Future<void> _startSessionAndLoad(
    GoogleCastDevice? device, {
    required MediaServerClient client,
    required MediaItem item,
    required int mediaIndex,
    String? mediaSourceId,
  }) async {
    var createdSession = false;
    if (device != null) {
      final started = await _sessions.startSessionWithDevice(device);
      if (!started) throw const CastPlaybackException('Could not connect to that Cast device.');
      createdSession = true;
    } else if (!_sessions.hasConnectedSession) {
      throw const CastPlaybackException('The Cast device is no longer connected.');
    }

    try {
      if (device != null) await _waitForConnection();
      final resume = item.viewOffsetMs != null && item.viewOffsetMs! > 0
          ? Duration(milliseconds: item.viewOffsetMs!)
          : null;
      final target = await client.resolveExternalPlayback(
        item,
        mediaIndex: mediaIndex,
        mediaSourceId: mediaSourceId,
        position: resume,
      );
      if (target == null || target.url.isEmpty) {
        throw const CastPlaybackException('This item is not available for casting.');
      }
      final uri = Uri.tryParse(target.url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        throw const CastPlaybackException('The server did not provide a Cast-compatible stream.');
      }

      final part = target.partTimeline?.current;
      final partStart = part?.start ?? Duration.zero;
      final filePosition = target.partTimeline == null
          ? resume ?? Duration.zero
          : resume != null && target.partTimeline!.covers(resume)
          ? resume - partStart
          : Duration.zero;
      final duration =
          target.partTimeline?.duration ??
          (item.durationMs != null && item.durationMs! > 0 ? Duration(milliseconds: item.durationMs!) : null);
      final textTracks = _castTracks(target.subtitles);
      final streamType = CastMediaStreamType.buffered;
      final information = GoogleCastMediaInformation(
        contentId: uri.toString(),
        contentUrl: uri,
        contentType: _contentType(uri),
        streamType: streamType,
        duration: duration,
        metadata: GoogleCastGenericMediaMetadata(title: item.displayTitle, subtitle: item.displaySubtitle),
        tracks: textTracks.tracks.isEmpty ? null : textTracks.tracks,
      );
      await _remote.loadMedia(
        information,
        autoPlay: true,
        playPosition: filePosition,
        activeTrackIds: textTracks.defaultTrackIds.isEmpty ? null : textTracks.defaultTrackIds,
      );

      _deviceName = device?.friendlyName ?? _sessions.currentSession?.device?.friendlyName ?? _deviceName;
      _activeItem = item;
      _activeClient = client;
      _partStart = partStart;
      _duration = duration;
      _lastPausedState = null;
      _beginProgressReporting();
      notifyListeners();
    } catch (error) {
      if (createdSession) await _sessions.endSessionAndStopCasting();
      if (error is CastPlaybackException) rethrow;
      appLogger.w('Google Cast could not load media (${error.runtimeType})');
      throw const CastPlaybackException('Could not start playback on this Cast device.');
    }
  }

  Future<void> _waitForConnection() async {
    if (_sessions.hasConnectedSession) return;
    await _sessions.currentSessionStream
        .firstWhere((session) => session?.connectionState == GoogleCastConnectState.connected)
        .timeout(const Duration(seconds: 30));
  }

  ({List<GoogleCastMediaTrack> tracks, List<int> defaultTrackIds}) _castTracks(List<SubtitleTrack> subtitles) {
    final tracks = <GoogleCastMediaTrack>[];
    final defaults = <int>[];
    for (final subtitle in subtitles) {
      final rawUri = subtitle.uri;
      if (rawUri == null) continue;
      final uri = Uri.tryParse(rawUri);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) continue;
      final extension = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'vtt' => 'text/vtt',
        'srt' => 'application/x-subrip',
        _ => null,
      };
      if (contentType == null) continue;
      final id = tracks.length + 1;
      tracks.add(
        GoogleCastMediaTrack(
          trackId: id,
          type: TrackType.text,
          subtype: TextTrackType.subtitles,
          trackContentId: uri.toString(),
          trackContentType: contentType,
          name: subtitle.title ?? subtitle.language ?? t.cast.subtitle,
        ),
      );
      if (subtitle.isDefault) defaults.add(id);
    }
    return (tracks: tracks, defaultTrackIds: defaults);
  }

  static String _contentType(Uri uri) {
    final name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last.toLowerCase();
    if (name.endsWith('.m3u8')) return 'application/x-mpegURL';
    if (name.endsWith('.mpd')) return 'application/dash+xml';
    if (name.endsWith('.webm')) return 'video/webm';
    if (name.endsWith('.mov')) return 'video/quicktime';
    if (name.endsWith('.mkv')) return 'video/x-matroska';
    if (name.endsWith('.ts')) return 'video/mp2t';
    if (name.endsWith('.mp3')) return 'audio/mpeg';
    if (name.endsWith('.m4a')) return 'audio/mp4';
    return 'video/mp4';
  }

  void _beginProgressReporting() {
    final item = _activeItem;
    final client = _activeClient;
    final duration = _duration;
    if (item == null || client == null) return;

    if (duration != null && duration > Duration.zero) {
      _reportSession = PlaybackReportSession(client: client, itemId: item.id, playMethod: 'DirectPlay');
      unawaited(_reportPosition(_currentItemPosition(), isStopped: false));
    }
    unawaited(TrackerCoordinator.instance.startPlayback(item, client));
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_reportPosition(_currentItemPosition(), isStopped: false));
    });
  }

  Duration _currentItemPosition() => _partStart + _remote.playerPosition;

  Future<void> _reportPosition(Duration position, {required bool isStopped}) async {
    final item = _activeItem;
    final client = _activeClient;
    final duration = _duration;
    final reportSession = _reportSession;
    if (item == null || client == null) return;

    final clampedPosition = duration == null
        ? position
        : Duration(milliseconds: position.inMilliseconds.clamp(0, duration.inMilliseconds).toInt());
    final status = _remote.mediaStatus;
    final paused = status?.playerState == CastMediaPlayerState.paused;
    var stoppedReportSucceeded = false;
    if (_lastPausedState != null && _lastPausedState != paused) {
      if (paused) {
        unawaited(TrackerCoordinator.instance.pausePlayback());
      } else {
        unawaited(TrackerCoordinator.instance.resumePlayback());
      }
    }
    _lastPausedState = paused;
    TrackerCoordinator.instance.updatePosition(clampedPosition);

    if (reportSession != null && duration != null) {
      try {
        final delivered = await reportSession.report(
          PlaybackReportSnapshot(
            state: isStopped
                ? 'stopped'
                : paused
                ? 'paused'
                : 'playing',
            position: clampedPosition,
            duration: duration,
          ),
        );
        if (isStopped) stoppedReportSucceeded = delivered;
        if (!isStopped) {
          WatchStateNotifier().notifyProgress(
            item: item,
            cacheServerId: client.cacheServerId,
            viewOffset: clampedPosition.inMilliseconds,
            duration: duration.inMilliseconds,
            watchedThreshold: client.watchedThreshold,
            serverAcknowledged: true,
          );
        }
      } catch (error) {
        appLogger.d('Google Cast progress report failed (${error.runtimeType})');
      }
    }

    if (!isStopped ||
        !stoppedReportSucceeded ||
        duration == null ||
        clampedPosition.inMilliseconds < duration.inMilliseconds * client.watchedThreshold) {
      return;
    }
    try {
      await client.markWatchedFromPlaybackStop(item);
      WatchStateNotifier().notifyWatched(item: item, cacheServerId: client.cacheServerId, serverAcknowledged: true);
      await TrackerCoordinator.instance.markWatched(item, client);
    } catch (error) {
      appLogger.d('Google Cast watched-state update failed (${error.runtimeType})');
    }
  }

  void _onSessionChanged(GoogleCastSession? session) {
    if (session == null && _activeItem != null && !_finishingPlayback) {
      unawaited(_finishPlayback(_currentItemPosition()));
    }
    if (session?.device?.friendlyName case final String name) _deviceName = name;
    notifyListeners();
  }

  void _onMediaStatusChanged(GoggleCastMediaStatus? status) {
    if (_activeItem != null) {
      if (status?.playerState == CastMediaPlayerState.idle &&
          status?.idleReason != null &&
          status?.idleReason != GoogleCastMediaIdleReason.none) {
        unawaited(_finishPlayback(_currentItemPosition()));
      } else if ((status?.playerState == CastMediaPlayerState.playing ||
              status?.playerState == CastMediaPlayerState.paused) &&
          _lastPausedState != (status?.playerState == CastMediaPlayerState.paused)) {
        unawaited(_reportPosition(_currentItemPosition(), isStopped: false));
      }
    }
    notifyListeners();
  }

  Future<void> _finishPlayback(Duration position) async {
    if (_finishingPlayback) return;
    _finishingPlayback = true;
    try {
      _progressTimer?.cancel();
      _progressTimer = null;
      await _reportPosition(position, isStopped: true);
      await TrackerCoordinator.instance.stopPlayback();
      _reportSession = null;
      _activeItem = null;
      _activeClient = null;
      _partStart = Duration.zero;
      _duration = null;
      _lastPausedState = null;
      notifyListeners();
    } finally {
      _finishingPlayback = false;
    }
  }

  Future<void> showControls(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: this,
        builder: (context, _) {
          final status = _remote.mediaStatus;
          final isPaused = status?.playerState == CastMediaPlayerState.paused;
          final isPlaying =
              status?.playerState == CastMediaPlayerState.playing ||
              status?.playerState == CastMediaPlayerState.buffering;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.cast.connectedTo(device: deviceName ?? t.cast.device),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(_activeItem?.displayTitle ?? t.cast.readyToCast, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 18),
                  StreamBuilder<Duration>(
                    stream: _remote.playerPositionStream,
                    initialData: _remote.playerPosition,
                    builder: (context, snapshot) {
                      final position = _partStart + (snapshot.data ?? Duration.zero);
                      final duration = _duration;
                      return Text(
                        duration == null
                            ? _formatDuration(position)
                            : '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: isPaused ? t.common.resume : t.common.pause,
                        onPressed: !isPaused && !isPlaying
                            ? null
                            : () => unawaited(isPaused ? _remote.play() : _remote.pause()),
                        icon: AppIcon(isPaused ? Symbols.play_arrow_rounded : Symbols.pause_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: t.cast.stopCasting,
                        onPressed: () async {
                          await _remote.stop();
                          await _sessions.endSessionAndStopCasting();
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        },
                        icon: const AppIcon(Symbols.stop_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatDuration(Duration value) {
    String two(int number) => number.toString().padLeft(2, '0');
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return hours > 0 ? '$hours:${two(minutes)}:${two(seconds)}' : '$minutes:${two(seconds)}';
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    unawaited(_sessionSubscription?.cancel());
    unawaited(_statusSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    super.dispose();
  }
}

class CastPlaybackException implements Exception {
  const CastPlaybackException(this.message);
  final String message;
}
