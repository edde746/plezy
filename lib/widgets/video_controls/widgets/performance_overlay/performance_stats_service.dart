import 'dart:async';
import 'dart:io' show Platform, ProcessInfo;

import 'package:flutter/scheduler.dart';

import '../../../../mpv/mpv.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/codec_utils.dart';
import 'performance_stats.dart';

/// Service that polls player properties and provides performance stats via a stream.
///
/// Supports both MPV (desktop/iOS) and ExoPlayer (Android) backends.
/// Handles runtime backend switching (e.g., ExoPlayer -> MPV fallback on Android).
///
/// Usage:
/// ```dart
/// final service = PerformanceStatsService(player);
/// service.startPolling();
/// service.statsStream.listen((stats) => print(stats.resolution));
/// service.stopPolling();
/// service.dispose();
/// ```
class PerformanceStatsService {
  final Player player;
  Timer? _pollingTimer;
  final _statsController = StreamController<PerformanceStats>.broadcast();

  /// The interval between stats updates.
  static const pollInterval = Duration(milliseconds: 500);

  // FPS tracking
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  double? _currentUiFps;
  bool _fpsTrackingActive = false;
  bool _fpsCallbackRegistered = false;

  // Track runtime player type for logging (can differ from Dart object type after fallback)
  // Values: 'exoplayer', 'mpv', or 'unknown'
  String _runtimePlayerType = 'unknown';
  StreamSubscription<void>? _backendSwitchedSubscription;
  bool _fetchInProgress = false;
  bool _disposed = false;

  PerformanceStatsService(this.player);

  /// Stream of performance stats updates.
  Stream<PerformanceStats> get statsStream => _statsController.stream;

  /// Start polling for stats at regular intervals.
  void startPolling() {
    _pollingTimer?.cancel();

    // Listen for backend switches (only the Android ExoPlayer -> MPV
    // fallback ever emits; the stream is silent elsewhere).
    _backendSwitchedSubscription?.cancel();
    _backendSwitchedSubscription = player.streams.backendSwitched.listen((_) {
      _updateRuntimePlayerType();
    });

    // Start FPS tracking
    _startFpsTracking();
    // Fetch immediately, then poll
    _fetchStats();
    _pollingTimer = Timer.periodic(pollInterval, (_) => _fetchStats());
  }

  /// Update the runtime player type by querying the native layer.
  Future<void> _updateRuntimePlayerType() async {
    _runtimePlayerType = await player.runtimePlayerType();
    appLogger.d('Performance stats: runtime player type updated to $_runtimePlayerType');
  }

  /// Start tracking UI frame rate.
  void _startFpsTracking() {
    _frameCount = 0;
    _lastFpsUpdate = DateTime.now();
    _fpsTrackingActive = true;
    if (!_fpsCallbackRegistered) {
      _fpsCallbackRegistered = true;
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    }
  }

  /// Called with completed frame timings to count FPS without retaining an
  /// app-lifetime persistent callback.
  void _onFrameTimings(List<FrameTiming> timings) {
    if (!_fpsTrackingActive) return;
    _frameCount += timings.length;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate);
    if (elapsed.inMilliseconds >= 1000) {
      _currentUiFps = _frameCount * 1000 / elapsed.inMilliseconds;
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }

  /// Stop polling for stats.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _fpsTrackingActive = false;
    _currentUiFps = null;
    if (_fpsCallbackRegistered) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      _fpsCallbackRegistered = false;
    }
  }

  /// Fetch all performance stats from the player.
  Future<void> _fetchStats() async {
    if (_disposed || _fetchInProgress) return;
    _fetchInProgress = true;
    try {
      // Ensure we know the runtime type on first fetch
      if (_runtimePlayerType == 'unknown') {
        await _updateRuntimePlayerType();
      }

      if (player.providesNativeStats) {
        // Android (ExoPlayer or MPV fallback): the native side returns
        // appropriate stats based on which backend is active.
        await _fetchAndroidStats();
      } else {
        // For mpv-channel players, use MPV property queries
        await _fetchMpvStats();
      }
    } catch (e) {
      if (!_disposed) appLogger.w('Failed to fetch performance stats', error: e);
    } finally {
      _fetchInProgress = false;
    }
  }

  /// Fetch stats from Android player (ExoPlayer or MPV fallback).
  /// The native side returns appropriate stats based on the active backend.
  Future<void> _fetchAndroidStats() async {
    final statsMap = await player.getStats();
    final playerType = statsMap['playerType'] as String? ?? 'unknown';

    // Get app memory usage
    int? appMemory;
    try {
      appMemory = ProcessInfo.currentRss;
    } catch (_) {}

    if (playerType == 'mpv') {
      // Parse MPV stats format (returned when in fallback mode)
      final audio = _resolveAudioDisplay(
        format: statsMap['audio-params/format'] as String?,
        samplerate: statsMap['audio-params/samplerate'] as String?,
        hrChannels: statsMap['audio-params/hr-channels'] as String?,
        demuxSamplerate: statsMap['current-tracks/audio/demux-samplerate'] as String?,
        demuxChannelCount: statsMap['current-tracks/audio/demux-channel-count'] as String?,
      );
      final stats = PerformanceStats(
        playerType: 'mpv',
        videoCodec: _formatVideoCodecName(statsMap['video-codec'] as String?),
        videoWidth: _parseInt(statsMap['video-params/w'] as String?),
        videoHeight: _parseInt(statsMap['video-params/h'] as String?),
        videoFps: _parseDouble(statsMap['container-fps'] as String?),
        actualFps: _parseDouble(statsMap['estimated-vf-fps'] as String?),
        videoBitrate: _parseInt(statsMap['video-bitrate'] as String?),
        hwdecCurrent: statsMap['hwdec-current'] as String?,
        audioCodec: _formatAudioCodecName(statsMap['audio-codec-name'] as String?),
        audioSamplerate: audio.samplerate,
        audioChannels: audio.channels,
        audioPassthroughFormat: audio.passthroughFormat,
        audioBitrate: _parseInt(statsMap['audio-bitrate'] as String?),
        avsyncChange: _parseDouble(statsMap['total-avsync-change'] as String?),
        cacheUsed: _parseInt(statsMap['cache-used'] as String?),
        cacheLimit: _parseInt(statsMap['demuxer-max-bytes'] as String?),
        cacheSpeed: _parseDouble(statsMap['cache-speed'] as String?),
        displayFps: _parseDouble(statsMap['display-fps'] as String?),
        frameDropCount: _parseInt(statsMap['frame-drop-count'] as String?),
        decoderFrameDropCount: _parseInt(statsMap['decoder-frame-drop-count'] as String?),
        cacheDuration: _parseDouble(statsMap['demuxer-cache-duration'] as String?),
        // Color/Format properties
        pixelformat: statsMap['video-params/pixelformat'] as String?,
        hwPixelformat: statsMap['video-params/hw-pixelformat'] as String?,
        colormatrix: statsMap['video-params/colormatrix'] as String?,
        primaries: statsMap['video-params/primaries'] as String?,
        gamma: statsMap['video-params/gamma'] as String?,
        // HDR metadata
        maxLuma: _parseDouble(statsMap['video-params/max-luma'] as String?),
        minLuma: _parseDouble(statsMap['video-params/min-luma'] as String?),
        maxCll: _parseDouble(statsMap['video-params/max-cll'] as String?),
        maxFall: _parseDouble(statsMap['video-params/max-fall'] as String?),
        // Other
        aspectName: statsMap['video-params/aspect-name'] as String?,
        rotate: _parseInt(statsMap['video-params/rotate'] as String?),
        appMemoryBytes: appMemory,
        uiFps: _currentUiFps,
      );
      _emit(stats);
    } else {
      // Parse ExoPlayer stats format
      final stats = PerformanceStats(
        playerType: 'exoplayer',
        // Video metrics
        videoCodec: _formatVideoCodecName(statsMap['videoCodec'] as String?),
        videoWidth: statsMap['videoWidth'] as int?,
        videoHeight: statsMap['videoHeight'] as int?,
        videoFps: (statsMap['videoFps'] as num?)?.toDouble(),
        videoBitrate: statsMap['videoBitrate'] as int?,
        videoDecoderName: statsMap['videoDecoderName'] as String?,
        // Audio metrics
        audioCodec: _formatAudioCodecName(statsMap['audioCodec'] as String?),
        audioSamplerate: statsMap['audioSampleRate'] as int?,
        audioChannels: CodecUtils.formatAudioChannels(statsMap['audioChannels'] as int?),
        audioBitrate: statsMap['audioBitrate'] as int?,
        audioDecoderName: statsMap['audioDecoderName'] as String?,
        // Tunneling
        tunneledPlayback: statsMap['tunneledPlayback'] == true,
        tunnelingStatus: statsMap['tunnelingStatus'] as String?,
        // Performance metrics
        frameDropCount: statsMap['videoDroppedFrames'] as int?,
        // Buffer metrics - convert ms to seconds for duration
        cacheDuration: ((statsMap['totalBufferedDurationMs'] as int?) ?? 0) / 1000.0,
        bufferTargetBytes: statsMap['bufferTargetBytes'] as int?,
        bufferMaxMs: statsMap['bufferMaxMs'] as int?,
        // DV conversion
        dvConversionActive: statsMap['dvConversionActive'] == true,
        dvConversionMode: statsMap['dvConversionMode'] as String? ?? '',
        dvConvertedRpus: (statsMap['dvConvertedRpus'] as num?)?.toInt(),
        dvRpuConversionFailures: (statsMap['dvRpuConversionFailures'] as num?)?.toInt(),
        dvAvgRpuConversionUs: (statsMap['dvAvgRpuConversionUs'] as num?)?.toInt(),
        dvAvgSampleProcessingUs: (statsMap['dvAvgSampleProcessingUs'] as num?)?.toInt(),
        dvSourceProfile: (statsMap['dvSourceProfile'] as num?)?.toInt(),
        dvPlaybackPath: statsMap['dvPlaybackPath'] as String?,
        // App metrics
        appMemoryBytes: appMemory,
        uiFps: _currentUiFps,
      );
      _emit(stats);
    }
  }

  /// Fetch stats from MPV via property queries.
  Future<void> _fetchMpvStats() async {
    // Fetch core properties in parallel
    final results = await Future.wait([
      player.getProperty('video-codec'), // 0
      player.getProperty('video-params/w'), // 1
      player.getProperty('video-params/h'), // 2
      player.getProperty('container-fps'), // 3
      player.getProperty('estimated-vf-fps'), // 4
      player.getProperty('video-bitrate'), // 5
      player.getProperty('hwdec-current'), // 6
      player.getProperty('audio-codec-name'), // 7
      player.getProperty('audio-params/samplerate'), // 8
      player.getProperty('audio-params/hr-channels'), // 9
      player.getProperty('audio-bitrate'), // 10
      player.getProperty('total-avsync-change'), // 11
      player.getProperty('cache-used'), // 12
      player.getProperty('demuxer-max-bytes'), // 13
      player.getProperty('cache-speed'), // 14
      player.getProperty('frame-drop-count'), // 15
      player.getProperty('decoder-frame-drop-count'), // 16
      player.getProperty('demuxer-cache-duration'), // 17
      player.getProperty('audio-params/format'), // 18
      player.getProperty('current-tracks/audio/demux-samplerate'), // 19
      player.getProperty('current-tracks/audio/demux-channel-count'), // 20
    ]);

    final hasVideo = results[1] != null;

    // Only query video-dependent properties when a video track is active.
    // On Android, skip properties that are typically unavailable (display-fps,
    // hw-pixelformat, HDR metadata) — MPV's native layer logs errors for these
    // that we cannot suppress.
    List<String?>? videoResults;
    if (hasVideo) {
      final isAndroid = Platform.isAndroid;
      videoResults = await Future.wait([
        isAndroid ? Future.value(null) : player.getProperty('display-fps'), // 0
        player.getProperty('video-params/pixelformat'), // 1
        isAndroid ? Future.value(null) : player.getProperty('video-params/hw-pixelformat'), // 2
        player.getProperty('video-params/colormatrix'), // 3
        player.getProperty('video-params/primaries'), // 4
        player.getProperty('video-params/gamma'), // 5
        isAndroid ? Future.value(null) : player.getProperty('video-params/max-luma'), // 6
        isAndroid ? Future.value(null) : player.getProperty('video-params/min-luma'), // 7
        isAndroid ? Future.value(null) : player.getProperty('video-params/max-cll'), // 8
        isAndroid ? Future.value(null) : player.getProperty('video-params/max-fall'), // 9
        player.getProperty('video-params/aspect-name'), // 10
        player.getProperty('video-params/rotate'), // 11
      ]);
    }

    // Get app memory usage
    int? appMemory;
    try {
      appMemory = ProcessInfo.currentRss;
    } catch (_) {
      // ProcessInfo not available on all platforms
    }

    final audio = _resolveAudioDisplay(
      format: results[18],
      samplerate: results[8],
      hrChannels: results[9],
      demuxSamplerate: results[19],
      demuxChannelCount: results[20],
    );

    final stats = PerformanceStats(
      playerType: 'mpv',
      videoCodec: _formatVideoCodecName(results.first),
      videoWidth: _parseInt(results[1]),
      videoHeight: _parseInt(results[2]),
      videoFps: _parseDouble(results[3]),
      actualFps: _parseDouble(results[4]),
      videoBitrate: _parseInt(results[5]),
      hwdecCurrent: results[6],
      audioCodec: _formatAudioCodecName(results[7]),
      audioSamplerate: audio.samplerate,
      audioChannels: audio.channels,
      audioPassthroughFormat: audio.passthroughFormat,
      audioBitrate: _parseInt(results[10]),
      avsyncChange: _parseDouble(results[11]),
      cacheUsed: _parseInt(results[12]),
      cacheLimit: _parseInt(results[13]),
      cacheSpeed: _parseDouble(results[14]),
      frameDropCount: _parseInt(results[15]),
      decoderFrameDropCount: _parseInt(results[16]),
      cacheDuration: _parseDouble(results[17]),
      // Video-dependent properties
      displayFps: _parseDouble(videoResults?.first),
      pixelformat: videoResults?[1],
      hwPixelformat: videoResults?[2],
      colormatrix: videoResults?[3],
      primaries: videoResults?[4],
      gamma: videoResults?[5],
      maxLuma: _parseDouble(videoResults?[6]),
      minLuma: _parseDouble(videoResults?[7]),
      maxCll: _parseDouble(videoResults?[8]),
      maxFall: _parseDouble(videoResults?[9]),
      aspectName: videoResults?[10],
      rotate: _parseInt(videoResults?[11]),
      appMemoryBytes: appMemory,
      uiFps: _currentUiFps,
    );

    _emit(stats);
  }

  void _emit(PerformanceStats stats) {
    if (!_disposed && !_statsController.isClosed) _statsController.add(stats);
  }

  /// Parse a string to int, returning null if parsing fails.
  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Resolves the displayed audio sample rate and channel layout.
  ///
  /// When mpv bitstreams (`audio-params/format` is 'spdif-*'), audio-params
  /// describe the IEC 61937 carrier — 192 kHz "stereo" for E-AC-3 — which is
  /// transport framing, not audio. Reporters read that as "downgraded to
  /// 2ch PCM" (#1300), so show the source track's values instead.
  ({int? samplerate, String? channels, String? passthroughFormat}) _resolveAudioDisplay({
    required String? format,
    required String? samplerate,
    required String? hrChannels,
    required String? demuxSamplerate,
    required String? demuxChannelCount,
  }) {
    if (format == null || !format.startsWith('spdif-')) {
      return (samplerate: _parseInt(samplerate), channels: hrChannels, passthroughFormat: null);
    }
    return (
      samplerate: _parseInt(demuxSamplerate),
      channels: CodecUtils.formatAudioChannels(_parseInt(demuxChannelCount)),
      passthroughFormat: format,
    );
  }

  /// Parse a string to double, returning null if parsing fails.
  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  /// Format a video codec name for display. Handles mpv's descriptive
  /// strings ('hevc (Main 10)') and ExoPlayer's RFC 6381 codec IDs
  /// ('hvc1.2.4.L153.B0', 'av01.0.08M.10').
  String? _formatVideoCodecName(String? codec) {
    if (codec == null || codec.isEmpty) return null;
    final upper = codec.toUpperCase();
    if (upper.contains('HEVC') || upper.contains('H265') || upper.contains('HVC1') || upper.contains('HEV1')) {
      return 'HEVC';
    }
    if (upper.contains('H264') || upper.contains('AVC')) return 'H.264';
    if (upper.contains('AV1') || upper.contains('AV01')) return 'AV1';
    if (upper.contains('VP9') || upper.contains('VP09')) return 'VP9';
    return codec;
  }

  /// Format an audio codec name for display. Both mpv's ffmpeg names and
  /// ExoPlayer's RFC 6381 codec IDs go through the shared mapping.
  String? _formatAudioCodecName(String? codec) {
    if (codec == null || codec.isEmpty) return null;
    return CodecUtils.formatAudioCodec(codec);
  }

  /// Dispose of the service and release resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _backendSwitchedSubscription?.cancel();
    _backendSwitchedSubscription = null;
    stopPolling();
    _statsController.close();
  }
}
