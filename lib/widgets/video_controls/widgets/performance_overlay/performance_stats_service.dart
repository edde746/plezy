import 'dart:async';
import 'dart:io' show ProcessInfo;

import 'package:flutter/scheduler.dart';

import '../../../../mpv/mpv.dart';
import '../../../../mpv/player/player_android.dart';
import '../../../../utils/app_logger.dart';
import 'performance_stats.dart';

/// Service that polls player properties and provides performance stats via a stream.
///
/// Supports both MPV (desktop/iOS) and ExoPlayer (Android) backends.
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

  /// Whether we're using ExoPlayer (Android) or MPV
  bool get _isExoPlayer => player is PlayerAndroid;

  PerformanceStatsService(this.player);

  /// Stream of performance stats updates.
  Stream<PerformanceStats> get statsStream => _statsController.stream;

  /// Start polling for stats at regular intervals.
  void startPolling() {
    _pollingTimer?.cancel();
    // Start FPS tracking
    _startFpsTracking();
    // Fetch immediately, then poll
    _fetchStats();
    _pollingTimer = Timer.periodic(pollInterval, (_) => _fetchStats());
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
      if (_isExoPlayer) {
        await _fetchExoPlayerStats();
      } else {
        await _fetchMpvStats();
      }
    } catch (e) {
      appLogger.w('Failed to fetch performance stats', error: e);
    }
  }

  /// Fetch stats from ExoPlayer via native method channel.
  Future<void> _fetchExoPlayerStats() async {
    final exoPlayer = player as PlayerAndroid;
    final statsMap = await exoPlayer.getStats();

    // Get app memory usage
    int? appMemory;
    try {
      appMemory = ProcessInfo.currentRss;
    } catch (_) {}

    final stats = PerformanceStats(
      playerType: (statsMap['playerType'] as String?) ?? 'exoplayer',
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
      appMemory = ProcessInfo.currentRss;
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
    stopPolling();
    _statsController.close();
  }
}
