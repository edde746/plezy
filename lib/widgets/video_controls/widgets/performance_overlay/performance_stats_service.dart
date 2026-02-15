import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';

import '../../../../mpv/mpv.dart';
import '../../../../utils/process_info_helper.dart';
import '../../../../mpv/player/player_android.dart';
import '../../../../utils/app_logger.dart';
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

  // Track runtime player type for logging (can differ from Dart object type after fallback)
  // Values: 'exoplayer', 'mpv', or 'unknown'
  String _runtimePlayerType = 'unknown';
  StreamSubscription<void>? _backendSwitchedSubscription;

  PerformanceStatsService(this.player);

  /// Stream of performance stats updates.
  Stream<PerformanceStats> get statsStream => _statsController.stream;

  /// Start polling for stats at regular intervals.
  void startPolling() {
    _pollingTimer?.cancel();

    // Listen for backend switches on Android (ExoPlayer -> MPV fallback)
    if (player is PlayerAndroid) {
      _backendSwitchedSubscription?.cancel();
      _backendSwitchedSubscription = player.streams.backendSwitched.listen((_) {
        _updateRuntimePlayerType();
      });
    }

    // Start FPS tracking
    _startFpsTracking();
    // Fetch immediately, then poll
    _fetchStats();
    _pollingTimer = Timer.periodic(pollInterval, (_) => _fetchStats());
  }

  /// Update the runtime player type by querying the native layer.
  Future<void> _updateRuntimePlayerType() async {
    if (player is PlayerAndroid) {
      _runtimePlayerType = await (player as PlayerAndroid).getPlayerType();
      appLogger.d('Performance stats: runtime player type updated to $_runtimePlayerType');
    } else {
      _runtimePlayerType = 'mpv'; // Non-Android always uses MPV
    }
  }

  /// Start tracking UI frame rate.
  void _startFpsTracking() {
    _frameCount = 0;
    _lastFpsUpdate = DateTime.now();
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  /// Called every frame to count FPS.
  void _onFrame(Duration timestamp) {
    _frameCount++;
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
  }

  /// Fetch all performance stats from the player.
  Future<void> _fetchStats() async {
    try {
      // Ensure we know the runtime type on first fetch
      if (_runtimePlayerType == 'unknown') {
        await _updateRuntimePlayerType();
      }

      if (player is PlayerAndroid) {
        // For Android (ExoPlayer or MPV fallback), always use getStats()
        // The native side returns appropriate stats based on which backend is active
        await _fetchAndroidStats();
      } else {
        // For non-Android platforms, use MPV property queries
        await _fetchMpvStats();
      }
    } catch (e) {
      appLogger.w('Failed to fetch performance stats', error: e);
    }
  }

  /// Fetch stats from Android player (ExoPlayer or MPV fallback).
  /// The native side returns appropriate stats based on the active backend.
  Future<void> _fetchAndroidStats() async {
    final androidPlayer = player as PlayerAndroid;
    final statsMap = await androidPlayer.getStats();
    final playerType = statsMap['playerType'] as String? ?? 'unknown';

    // Get app memory usage
    int? appMemory;
    try {
      appMemory = getProcessMemoryRss();
    } catch (_) {}

    if (playerType == 'mpv') {
      // Parse MPV stats format (returned when in fallback mode)
      final stats = PerformanceStats(
        playerType: 'mpv',
        videoCodec: _formatCodecName(statsMap['video-codec'] as String?),
        videoWidth: _parseInt(statsMap['video-params/w'] as String?),
        videoHeight: _parseInt(statsMap['video-params/h'] as String?),
        videoFps: _parseDouble(statsMap['container-fps'] as String?),
        actualFps: _parseDouble(statsMap['estimated-vf-fps'] as String?),
        videoBitrate: _parseInt(statsMap['video-bitrate'] as String?),
        hwdecCurrent: statsMap['hwdec-current'] as String?,
        audioCodec: _formatCodecName(statsMap['audio-codec-name'] as String?),
        audioSamplerate: _parseInt(statsMap['audio-params/samplerate'] as String?),
        audioChannels: statsMap['audio-params/hr-channels'] as String?,
        audioBitrate: _parseInt(statsMap['audio-bitrate'] as String?),
        avsyncChange: _parseDouble(statsMap['total-avsync-change'] as String?),
        cacheUsed: _parseInt(statsMap['cache-used'] as String?),
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
      _statsController.add(stats);
    } else {
      // Parse ExoPlayer stats format
      final stats = PerformanceStats(
        playerType: 'exoplayer',
        // Video metrics
        videoCodec: _formatCodecName(statsMap['videoCodec'] as String?),
        videoWidth: statsMap['videoWidth'] as int?,
        videoHeight: statsMap['videoHeight'] as int?,
        videoFps: (statsMap['videoFps'] as num?)?.toDouble(),
        videoBitrate: statsMap['videoBitrate'] as int?,
        videoDecoderName: statsMap['videoDecoderName'] as String?,
        // Audio metrics
        audioCodec: _formatCodecName(statsMap['audioCodec'] as String?),
        audioSamplerate: statsMap['audioSampleRate'] as int?,
        audioChannels: _formatChannels(statsMap['audioChannels'] as int?),
        audioBitrate: statsMap['audioBitrate'] as int?,
        // Performance metrics
        frameDropCount: statsMap['videoDroppedFrames'] as int?,
        // Buffer metrics - convert ms to seconds for duration
        cacheDuration: ((statsMap['totalBufferedDurationMs'] as int?) ?? 0) / 1000.0,
        // App metrics
        appMemoryBytes: appMemory,
        uiFps: _currentUiFps,
      );
      _statsController.add(stats);
    }
  }

  /// Format channel count to string (e.g., "2" -> "Stereo", "6" -> "5.1")
  String? _formatChannels(int? channels) {
    if (channels == null) return null;
    return switch (channels) {
      1 => 'Mono',
      2 => 'Stereo',
      6 => '5.1',
      8 => '7.1',
      _ => '$channels ch',
    };
  }

  /// Fetch stats from MPV via property queries.
  Future<void> _fetchMpvStats() async {
    // Fetch all properties in parallel for efficiency
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
      player.getProperty('cache-speed'), // 13
      player.getProperty('display-fps'), // 14
      player.getProperty('frame-drop-count'), // 15
      player.getProperty('decoder-frame-drop-count'), // 16
      player.getProperty('demuxer-cache-duration'), // 17
      // Color/Format properties
      player.getProperty('video-params/pixelformat'), // 18
      player.getProperty('video-params/hw-pixelformat'), // 19
      player.getProperty('video-params/colormatrix'), // 20
      player.getProperty('video-params/primaries'), // 21
      player.getProperty('video-params/gamma'), // 22
      // HDR metadata
      player.getProperty('video-params/max-luma'), // 23
      player.getProperty('video-params/min-luma'), // 24
      player.getProperty('video-params/max-cll'), // 25
      player.getProperty('video-params/max-fall'), // 26
      // Other
      player.getProperty('video-params/aspect-name'), // 27
      player.getProperty('video-params/rotate'), // 28
    ]);

    // Get app memory usage
    int? appMemory;
    try {
      appMemory = getProcessMemoryRss();
    } catch (_) {
      // ProcessInfo not available on all platforms
    }

    final stats = PerformanceStats(
      playerType: 'mpv',
      videoCodec: _formatCodecName(results[0]),
      videoWidth: _parseInt(results[1]),
      videoHeight: _parseInt(results[2]),
      videoFps: _parseDouble(results[3]),
      actualFps: _parseDouble(results[4]),
      videoBitrate: _parseInt(results[5]),
      hwdecCurrent: results[6],
      audioCodec: _formatCodecName(results[7]),
      audioSamplerate: _parseInt(results[8]),
      audioChannels: results[9],
      audioBitrate: _parseInt(results[10]),
      avsyncChange: _parseDouble(results[11]),
      cacheUsed: _parseInt(results[12]),
      cacheSpeed: _parseDouble(results[13]),
      displayFps: _parseDouble(results[14]),
      frameDropCount: _parseInt(results[15]),
      decoderFrameDropCount: _parseInt(results[16]),
      cacheDuration: _parseDouble(results[17]),
      // Color/Format properties
      pixelformat: results[18],
      hwPixelformat: results[19],
      colormatrix: results[20],
      primaries: results[21],
      gamma: results[22],
      // HDR metadata
      maxLuma: _parseDouble(results[23]),
      minLuma: _parseDouble(results[24]),
      maxCll: _parseDouble(results[25]),
      maxFall: _parseDouble(results[26]),
      // Other
      aspectName: results[27],
      rotate: _parseInt(results[28]),
      appMemoryBytes: appMemory,
      uiFps: _currentUiFps,
    );

    _statsController.add(stats);
  }

  /// Parse a string to int, returning null if parsing fails.
  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Parse a string to double, returning null if parsing fails.
  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  /// Format codec name for display (uppercase common codecs).
  String? _formatCodecName(String? codec) {
    if (codec == null || codec.isEmpty) return null;
    // Common codec name mappings
    final upper = codec.toUpperCase();
    if (upper.contains('HEVC') || upper.contains('H265')) return 'HEVC';
    if (upper.contains('H264') || upper.contains('AVC')) return 'H.264';
    if (upper.contains('AV1')) return 'AV1';
    if (upper.contains('VP9')) return 'VP9';
    if (upper.contains('AAC')) return 'AAC';
    if (upper.contains('AC3') || upper.contains('AC-3')) return 'AC3';
    if (upper.contains('EAC3') || upper.contains('E-AC-3')) return 'EAC3';
    if (upper.contains('DTS')) return 'DTS';
    if (upper.contains('TRUEHD')) return 'TrueHD';
    if (upper.contains('FLAC')) return 'FLAC';
    if (upper.contains('OPUS')) return 'Opus';
    if (upper.contains('VORBIS')) return 'Vorbis';
    if (upper.contains('MP3')) return 'MP3';
    return codec;
  }

  /// Dispose of the service and release resources.
  void dispose() {
    _backendSwitchedSubscription?.cancel();
    _backendSwitchedSubscription = null;
    stopPolling();
    _statsController.close();
  }
}
