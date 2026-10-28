import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, ProcessInfo;

import 'package:flutter/scheduler.dart';

import '../../../../models/motion_processing_mode.dart';
import '../../../../models/playback_capability_report.dart';
import '../../../../mpv/mpv.dart';
import '../../../../media/media_display_criteria.dart';
import '../../../../services/motion_processing_service.dart';
import '../../../../services/settings_service.dart';
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
  bool isLive;
  Timer? _pollingTimer;
  final _statsController = StreamController<PerformanceStats>.broadcast();

  /// The interval between stats updates.
  static const pollInterval = Duration(milliseconds: 500);

  // FPS tracking
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  MotionProcessingResolution? _resolveMotionProcessing({
    String? currentVideoOutput,
    String? nativeInterpolationStatus,
    String? neuralProviderStatus,
    PlaybackCapabilityReport? capabilityReport,
  }) {
    final settings = SettingsService.instanceOrNull;
    final mode = settings?.read(SettingsService.motionProcessingMode);
    return mode == null
        ? null
        : MotionProcessingService.resolveForPlayer(
            player,
            mode,
            currentVideoOutput: currentVideoOutput,
            nativeInterpolationStatus: nativeInterpolationStatus,
            neuralProviderStatus: neuralProviderStatus,
            capabilityReport: capabilityReport,
            isLive: isLive,
            neuralPreset: settings!.read(SettingsService.neuralInterpolationPreset),
          );
  }

  double? _currentUiFps;
  bool _fpsTrackingActive = false;
  bool _fpsCallbackRegistered = false;

  // Track runtime player type for logging (can differ from Dart object type after fallback)
  // Values: 'exoplayer', 'mpv', or 'unknown'
  String _runtimePlayerType = 'unknown';
  StreamSubscription<void>? _backendSwitchedSubscription;
  bool _fetchInProgress = false;
  bool _disposed = false;
  MediaDisplayCriteria? _sourceDisplayCriteria;
  bool? _isTranscoding;

  PerformanceStatsService(
    this.player, {
    MediaDisplayCriteria? sourceDisplayCriteria,
    bool? isTranscoding,
    this.isLive = false,
  }) {
    _sourceDisplayCriteria = sourceDisplayCriteria;
    _isTranscoding = isTranscoding;
  }

  void updateSourceMetadata({MediaDisplayCriteria? displayCriteria, bool? isTranscoding}) {
    _sourceDisplayCriteria = displayCriteria;
    _isTranscoding = isTranscoding;
  }

  int? get _sourceDolbyVisionProfile => _isTranscoding == true ? null : _sourceDisplayCriteria?.doviProfile;

  String? _sourceDolbyVisionLayersFor(int? profile) {
    if (profile == null || profile != _sourceDolbyVisionProfile) return null;
    final criteria = _sourceDisplayCriteria!;
    final flags = <String?>[
      if (criteria.doviBaseLayerPresent != null) 'BL${criteria.doviBaseLayerPresent! ? '+' : '−'}',
      if (criteria.doviEnhancementLayerPresent != null) 'EL${criteria.doviEnhancementLayerPresent! ? '+' : '−'}',
      if (criteria.doviRpuPresent != null) 'RPU${criteria.doviRpuPresent! ? '+' : '−'}',
    ];
    return flags.isEmpty ? null : flags.join(' / ');
  }

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
      final neuralProvider = statsMap['anvil-provider']?.toString();
      final neuralProviderVendor = statsMap['anvil-provider-vendor']?.toString();
      final neuralGpuProvider = switch (statsMap['anvil-gpu']?.toString()) {
        null || '' || 'cpu' => null,
        final provider => provider,
      };
      final neuralOutputObserved =
          _parseBool(statsMap['anvil-active']?.toString()) == true ||
          (_parseInt(statsMap['anvil-generated-frames']?.toString()) ?? 0) > 0;
      final capabilityReport = PlaybackCapabilityReport(
        playerType: 'mpv',
        videoOutput: statsMap['current-vo']?.toString(),
        hardwareDecoder: statsMap['hwdec-current'] as String?,
        pixelFormat: statsMap['video-params/pixelformat'] as String?,
        sourceWidth: _parseInt(statsMap['video-params/w'] as String?),
        sourceHeight: _parseInt(statsMap['video-params/h'] as String?),
        sourceIsHdr: _isHdrTransfer(
          statsMap['video-params/gamma'] as String?,
          hasHdrMetadata: _hasMpvHdrMetadata(
            statsMap['video-params/min-luma'],
            statsMap['video-params/max-luma'],
            statsMap['video-params/max-cll'],
            statsMap['video-params/max-fall'],
          ),
        ),
        dolbyVisionProfile: (statsMap['dvSourceProfile'] as num?)?.toInt(),
        sourceFps: _parseDouble(statsMap['container-fps'] as String?),
        displayFps: _parseDouble(statsMap['display-fps'] as String?),
        renderedFps: _parseDouble(statsMap['estimated-vf-fps'] as String?),
        droppedFrames: _parseInt(statsMap['frame-drop-count'] as String?),
        decoderDroppedFrames: _parseInt(statsMap['decoder-frame-drop-count'] as String?),
        rendererInterpolationActive: _parseBool(statsMap['interpolation']?.toString()),
        thermalStatus: MotionProcessingService.thermalStatusForPlayer(player),
        neuralProviderReady: _isNeuralProviderReady(neuralProvider, outputObserved: neuralOutputObserved),
        neuralProvider: neuralProvider,
        neuralProviderVendor: neuralProviderVendor,
        neuralPowerMode: statsMap['anvil-power-mode']?.toString(),
        neuralOutputObserved: neuralOutputObserved,
        neuralInferenceP95Ms: _parseDouble(statsMap['anvil-inference-p95-ms']?.toString()),
        neuralGeneratedFrames: _parseInt(statsMap['anvil-generated-frames']?.toString()),
        neuralSourceFrames: _parseInt(statsMap['anvil-source-frames']?.toString()),
        neuralSceneCutBypasses: _parseInt(statsMap['anvil-scene-cut-bypasses']?.toString()),
        neuralDeadlineMisses: _parseInt(statsMap['anvil-deadline-misses']?.toString()),
        neuralDeadlineGovernor: statsMap['anvil-deadline-governor']?.toString(),
        neuralDeadlineBackoffs: _parseInt(statsMap['anvil-deadline-backoffs']?.toString()),
        neuralDeadlineBypassFrames: _parseInt(statsMap['anvil-deadline-bypass-frames']?.toString()),
        neuralGpuProvider: neuralGpuProvider,
        imageEnhancementConfigured: statsMap['videoUpscalingConfigured'] == true,
        imageEnhancementProvider: statsMap['videoUpscalingProvider'] as String?,
        imageEnhancementStatus: statsMap['videoUpscalingStatus'] as String?,
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
        cacheUsed: _parseCacheForwardBytes(statsMap['demuxer-cache-state'] as String?),
        cacheLimit: _parseCacheLimitBytes(
          statsMap['demuxer-max-bytes'] as String?,
          statsMap['demuxer-max-back-bytes'] as String?,
        ),
        cacheSpeed: _parseDouble(statsMap['cache-speed'] as String?),
        displayFps: _parseDouble(statsMap['display-fps'] as String?),
        currentVideoOutput: statsMap['current-vo']?.toString(),
        videoSync: statsMap['video-sync']?.toString(),
        motionInterpolationActive: _parseBool(statsMap['interpolation']?.toString()),
        motionProviderStatus: statsMap['video-out-interpolation']?.toString(),
        neuralProvider: neuralProvider,
        neuralProviderVendor: neuralProviderVendor,
        neuralInferenceMs: _parseDouble(statsMap['anvil-inference-ms']?.toString()),
        neuralInferenceP95Ms: _parseDouble(statsMap['anvil-inference-p95-ms']?.toString()),
        neuralGeneratedFrames: _parseInt(statsMap['anvil-generated-frames']?.toString()),
        neuralSceneCutBypasses: _parseInt(statsMap['anvil-scene-cut-bypasses']?.toString()),
        neuralDeadlineMisses: _parseInt(statsMap['anvil-deadline-misses']?.toString()),
        neuralGpuProvider: neuralGpuProvider,
        videoUpscalingRequested: statsMap['videoUpscalingRequested'] == true,
        videoUpscalingConfigured: statsMap['videoUpscalingConfigured'] == true,
        videoUpscalingStatus: statsMap['videoUpscalingStatus'] as String?,
        videoUpscalingProvider: statsMap['videoUpscalingProvider'] as String?,
        motionProcessingResolution: _resolveMotionProcessing(
          currentVideoOutput: statsMap['current-vo']?.toString(),
          nativeInterpolationStatus: statsMap['video-out-interpolation']?.toString(),
          neuralProviderStatus: neuralProvider,
          capabilityReport: capabilityReport,
        ),
        playbackCapabilityReport: capabilityReport,
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
        // Dolby Vision: the bitstream's profile and what decodes it
        dvSourceProfile: (statsMap['dvSourceProfile'] as num?)?.toInt() ?? _sourceDolbyVisionProfile,
        dvSourceLayers: _sourceDolbyVisionLayersFor(
          (statsMap['dvSourceProfile'] as num?)?.toInt() ?? _sourceDolbyVisionProfile,
        ),
        dvRoute: DvRoute.fromId(statsMap['dvRoute'] as String?),
        appMemoryBytes: appMemory,
        uiFps: _currentUiFps,
      );
      _emit(stats);
    } else {
      // Parse ExoPlayer stats format
      final capabilityReport = PlaybackCapabilityReport(
        playerType: 'exoplayer',
        videoOutput: 'exoplayer-surface',
        hardwareDecoder: statsMap['videoDecoderName'] as String?,
        sourceWidth: statsMap['videoWidth'] as int?,
        sourceHeight: statsMap['videoHeight'] as int?,
        sourceIsHdr: statsMap['sourceIsHdr'] as bool?,
        dolbyVisionProfile: (statsMap['dvSourceProfile'] as num?)?.toInt(),
        sourceFps: (statsMap['videoFps'] as num?)?.toDouble(),
        droppedFrames: statsMap['videoDroppedFrames'] as int?,
        rendererInterpolationActive: false,
        imageEnhancementConfigured: statsMap['videoUpscalingConfigured'] == true,
        imageEnhancementProvider: statsMap['videoUpscalingProvider'] as String?,
        imageEnhancementStatus: statsMap['videoUpscalingStatus'] as String?,
      );
      final stats = PerformanceStats(
        playerType: 'exoplayer',
        // Video metrics
        videoCodec: _formatVideoCodecName((statsMap['videoCodec'] ?? statsMap['videoMimeType']) as String?),
        videoWidth: statsMap['videoWidth'] as int?,
        videoHeight: statsMap['videoHeight'] as int?,
        videoFps: (statsMap['videoFps'] as num?)?.toDouble(),
        videoBitrate: statsMap['videoBitrate'] as int?,
        videoDecoderName: statsMap['videoDecoderName'] as String?,
        // Audio metrics
        audioCodec: _formatAudioCodecName((statsMap['audioCodec'] ?? statsMap['audioMimeType']) as String?),
        audioSamplerate: statsMap['audioSampleRate'] as int?,
        audioChannels: CodecUtils.formatAudioChannels(statsMap['audioChannels'] as int?),
        audioBitrate: statsMap['audioBitrate'] as int?,
        audioDecoderName: statsMap['audioDecoderName'] as String?,
        // Tunneling
        tunneledPlayback: statsMap['tunneledPlayback'] == true,
        tunnelingStatus: statsMap['tunnelingStatus'] as String?,
        videoUpscalingRequested: statsMap['videoUpscalingRequested'] == true,
        videoUpscalingConfigured: statsMap['videoUpscalingConfigured'] == true,
        videoUpscalingStatus: statsMap['videoUpscalingStatus'] as String?,
        videoUpscalingProvider: statsMap['videoUpscalingProvider'] as String?,
        motionProcessingResolution: _resolveMotionProcessing(capabilityReport: capabilityReport),
        playbackCapabilityReport: capabilityReport,
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
        dvSourceProfile: (statsMap['dvSourceProfile'] as num?)?.toInt() ?? _sourceDolbyVisionProfile,
        dvSourceLayers: _sourceDolbyVisionLayersFor(
          (statsMap['dvSourceProfile'] as num?)?.toInt() ?? _sourceDolbyVisionProfile,
        ),
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
      player.getProperty('demuxer-cache-state'), // 12
      player.getProperty('demuxer-max-bytes'), // 13
      player.getProperty('cache-speed'), // 14
      player.getProperty('frame-drop-count'), // 15
      player.getProperty('decoder-frame-drop-count'), // 16
      player.getProperty('demuxer-cache-duration'), // 17
      player.getProperty('audio-params/format'), // 18
      player.getProperty('current-tracks/audio/demux-samplerate'), // 19
      player.getProperty('current-tracks/audio/demux-channel-count'), // 20
      player.getProperty('demuxer-max-back-bytes'), // 21
    ]);

    final webosDimensions = player.playerType == 'webos'
        ? await Future.wait([_optionalPlayerProperty('width'), _optionalPlayerProperty('height')])
        : const <String?>[];
    final hasVideo = results[1] != null || (webosDimensions.isNotEmpty && webosDimensions.first != null);

    // Only query video-dependent properties when a video track is active.
    // On Android, skip properties that are typically unavailable (display-fps,
    // hw-pixelformat, HDR metadata) — MPV's native layer logs errors for these
    // that we cannot suppress.
    List<String?>? videoResults;
    if (hasVideo) {
      final isAndroid = Platform.isAndroid;
      final hasPmeMetadata = Platform.isWindows || Platform.isLinux;
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
        player.getProperty('current-tracks/video/dolby-vision-profile'), // 12
        player.getProperty('current-vo'), // 13
        Platform.isLinux ? player.getProperty('plezyng-dv-renderer') : Future.value(null), // 14
        player.getProperty('video-sync'), // 15
        player.getProperty('interpolation'), // 16
        (Platform.isIOS || Platform.isMacOS) ? player.getProperty('video-out-interpolation') : Future.value(null), // 17
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/provider') : Future.value(null), // 18
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/active') : Future.value(null), // 19
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/inference-p95-ms') : Future.value(null), // 20
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/generated-frames') : Future.value(null), // 21
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/scene-cut-bypasses') : Future.value(null), // 22
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/deadline-misses') : Future.value(null), // 23
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/gpu') : Future.value(null), // 24
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/provider-vendor') : Future.value(null), // 25
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/device-kind') : Future.value(null), // 26
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/deadline-governor') : Future.value(null), // 27
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/power-mode') : Future.value(null), // 28
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/deadline-backoffs') : Future.value(null), // 29
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/deadline-bypass-frames') : Future.value(null), // 30
        hasPmeMetadata ? _optionalPlayerProperty('vf-metadata/plezy-pme/source-frames') : Future.value(null), // 31
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

    final nativeInterpolationStatus = videoResults?[17];
    final metadataProvider = videoResults?[18];
    final metadataProviderVendor = videoResults?[25];
    final metadataDeviceKind = videoResults?[26];
    final neuralProvider =
        (metadataProvider == null ? null : _normalizePmeProvider(metadataProvider, metadataDeviceKind)) ??
        ((Platform.isIOS || Platform.isMacOS) &&
                const {'initializing', 'ready', 'active'}.contains(nativeInterpolationStatus)
            ? 'videotoolbox'
            : null);
    final neuralGeneratedFrames = _parseInt(videoResults?[21]);
    final neuralSourceFrames = _parseInt(videoResults?[31]);
    final neuralGpuProvider = switch (videoResults?[24]) {
      null || '' || 'cpu' => null,
      final provider => provider,
    };
    final neuralOutputObserved =
        _parseBool(videoResults?[19]) == true ||
        (neuralGeneratedFrames != null && neuralGeneratedFrames > 0) ||
        nativeInterpolationStatus == 'active';
    final playbackPlayerType = player.playerType;
    final reportedVideoOutput = videoResults?[13] ?? (playbackPlayerType == 'webos' ? 'webos-native' : null);
    final videoWidth = _parseInt(results[1] ?? (webosDimensions.isEmpty ? null : webosDimensions[0]));
    final videoHeight = _parseInt(results[2] ?? (webosDimensions.length < 2 ? null : webosDimensions[1]));
    final sourceWidth = _parseInt(results[1]);
    final sourceHeight = _parseInt(results[2]);
    final dolbyVisionProfile = _parseInt(videoResults?[12]);
    final capabilityReport = PlaybackCapabilityReport(
      playerType: playbackPlayerType,
      videoOutput: reportedVideoOutput,
      hardwareDecoder: results[6],
      pixelFormat: videoResults?[1],
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      sourceIsHdr: _isHdrTransfer(
        videoResults?[5],
        hasHdrMetadata: _hasMpvHdrMetadata(
          videoResults?[6],
          videoResults?[7],
          videoResults?[8],
          videoResults?[9],
        ),
      ),
      dolbyVisionProfile: dolbyVisionProfile,
      sourceFps: _parseDouble(results[3]),
      displayFps: _parseDouble(videoResults?.first),
      renderedFps: _parseDouble(results[4]),
      droppedFrames: _parseInt(results[15]),
      decoderDroppedFrames: _parseInt(results[16]),
      rendererInterpolationActive: _parseBool(videoResults?[16]),
      nativeInterpolationStatus: nativeInterpolationStatus,
      thermalStatus: playbackPlayerType == 'mpv' && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
          ? MotionProcessingService.thermalStatusForPlayer(player)
          : null,
      neuralProviderReady:
          _isNeuralProviderReady(metadataProvider, outputObserved: neuralOutputObserved) ||
          ((Platform.isIOS || Platform.isMacOS) && const {'ready', 'active'}.contains(nativeInterpolationStatus)),
      neuralProvider: neuralProvider,
      neuralProviderVendor: metadataProviderVendor,
      neuralPowerMode: videoResults?[28],
      neuralOutputObserved: neuralOutputObserved,
      neuralInferenceP95Ms: _parseDouble(videoResults?[20]),
      neuralGeneratedFrames: neuralGeneratedFrames,
      neuralSourceFrames: neuralSourceFrames,
      neuralSceneCutBypasses: _parseInt(videoResults?[22]),
      neuralDeadlineMisses: _parseInt(videoResults?[23]),
      neuralDeadlineGovernor: videoResults?[27],
      neuralDeadlineBackoffs: _parseInt(videoResults?[29]),
      neuralDeadlineBypassFrames: _parseInt(videoResults?[30]),
      neuralGpuProvider: neuralGpuProvider,
    );

    final stats = PerformanceStats(
      playerType: player.playerType,
      videoCodec: _formatVideoCodecName(results.first),
      videoWidth: videoWidth,
      videoHeight: videoHeight,
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
      cacheUsed: _parseCacheForwardBytes(results[12]),
      cacheLimit: _parseCacheLimitBytes(results[13], results[21]),
      cacheSpeed: _parseDouble(results[14]),
      frameDropCount: _parseInt(results[15]),
      decoderFrameDropCount: _parseInt(results[16]),
      cacheDuration: _parseDouble(results[17]),
      // Video-dependent properties
      displayFps: _parseDouble(videoResults?.first),
      currentVideoOutput: reportedVideoOutput,
      videoSync: videoResults?[15],
      motionInterpolationActive: _parseBool(videoResults?[16]),
      motionProviderStatus: videoResults?[17],
      neuralProvider: neuralProvider,
      neuralProviderVendor: metadataProviderVendor,
      neuralInferenceP95Ms: _parseDouble(videoResults?[20]),
      neuralGeneratedFrames: neuralGeneratedFrames,
      neuralSceneCutBypasses: _parseInt(videoResults?[22]),
      neuralDeadlineMisses: _parseInt(videoResults?[23]),
      motionProcessingResolution: _resolveMotionProcessing(
        currentVideoOutput: reportedVideoOutput,
        nativeInterpolationStatus: videoResults?[17],
        neuralProviderStatus: neuralProvider,
        capabilityReport: capabilityReport,
      ),
      playbackCapabilityReport: capabilityReport,
      neuralGpuProvider: neuralGpuProvider,
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
      dvSourceProfile: dolbyVisionProfile ?? _sourceDolbyVisionProfile,
      dvSourceLayers: _sourceDolbyVisionLayersFor(dolbyVisionProfile ?? _sourceDolbyVisionProfile),
      dvPlaybackPath: dolbyVisionProfile == null ? null : (videoResults?[14] ?? videoResults?[13]),
      appMemoryBytes: appMemory,
      uiFps: _currentUiFps,
    );

    _emit(stats);
  }

  void _emit(PerformanceStats stats) {
    if (!_disposed && !_statsController.isClosed) _statsController.add(stats);
  }

  Future<String?> _optionalPlayerProperty(String name) async {
    try {
      return await player.getProperty(name);
    } catch (_) {
      return null;
    }
  }

  /// Parse a string to int, returning null if parsing fails.
  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  bool? _parseBool(String? value) => switch (value) {
    'yes' || 'true' || '1' => true,
    'no' || 'false' || '0' => false,
    _ => null,
  };

  bool? _isHdrTransfer(String? transfer, {bool hasHdrMetadata = false}) {
    if (hasHdrMetadata) return true;
    final normalized = transfer?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == 'auto') return null;
    if (const {'pq', 'smpte2084', 'arib-std-b67', 'hlg'}.contains(normalized)) return true;
    if (const {
      'bt.1886',
      'srgb',
      'gamma1.8',
      'gamma2.0',
      'gamma2.2',
      'gamma2.4',
      'gamma2.6',
      'gamma2.8',
      'prophoto',
    }.contains(normalized)) {
      return false;
    }
    return null;
  }

  bool _hasMpvHdrMetadata(Object? minLuma, Object? maxLuma, Object? maxCll, Object? maxFall) => [
    minLuma,
    maxLuma,
    maxCll,
    maxFall,
  ].any((value) => _parseDouble(value?.toString()) != null);

  bool _isNeuralProviderReady(String? provider, {required bool outputObserved}) {
    final normalized = provider?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    if (const {'ready', 'active'}.contains(normalized) || normalized.endsWith('-ready')) return true;
    if (RegExp(r'^qnn-htp-v\d+(-ready)?$').hasMatch(normalized)) {
      // ANVIL reports `qnn-htp-vN-ready` after asynchronous context setup and
      // drops `-ready` only after a successful HTP inference.
      return true;
    }
    if (const {'off', 'unavailable', 'failed', 'error', 'initializing', 'cpu-fallback'}.contains(normalized) ||
        normalized.endsWith('-initializing') ||
        normalized.endsWith('-unavailable') ||
        normalized.endsWith('-failed') ||
        normalized.endsWith('-error')) {
      return false;
    }
    // Provider names alone are selection metadata. For every provider outside
    // the explicitly defined ANVIL status contract, require generated output.
    return outputObserved;
  }

  String _normalizePmeProvider(String provider, String? deviceKind) {
    final normalized = provider.trim().toLowerCase();
    final ready = normalized.endsWith('-ready');
    final name = ready ? normalized.substring(0, normalized.length - '-ready'.length) : normalized;
    final device = deviceKind?.trim().toLowerCase();
    final deviceSuffix = const {'npu', 'gpu', 'cpu'}.contains(device) ? '-$device' : '';
    final String token;
    if (name.contains('openvino')) {
      token = 'openvino$deviceSuffix';
    } else if (name.contains('qnn')) {
      token = switch (device) {
        'npu' => 'qnn-npu',
        'gpu' => 'qnn-gpu',
        _ => 'qnn-htp',
      };
    } else if (name.contains('cuda')) {
      token = 'cuda-gpu';
    } else if (name.contains('vitisai')) {
      token = 'vitisai-npu';
    } else if (name.contains('nvtensorrtrx')) {
      token = 'nvtensorrtrtx-gpu';
    } else if (name.contains('migraphx')) {
      token = 'migraphx-gpu';
    } else if (name.contains('directml') || name.contains('dml')) {
      token = 'directml-gpu';
    } else if (name.contains('winml')) {
      token = 'winml$deviceSuffix';
    } else {
      token = name;
    }
    return ready ? '$token-ready' : token;
  }

  /// Reads `fw-bytes` out of mpv's `demuxer-cache-state`.
  ///
  /// `cache-used` was deleted with mpv's stream cache (v0.41.0), so polling it
  /// answered NOT_FOUND every tick and rendered a permanent "N/A". The
  /// replacement quantity lives in `demuxer-cache-state`, which mpv serialises
  /// as JSON when read as a string — a `demuxer-cache-state/fw-bytes` property
  /// path does *not* work, because that property implements neither
  /// `m_property_read_sub` nor a key action and answers PROPERTY_ERROR.
  ///
  /// Parsed here rather than in Kotlin so Android and the desktop/Apple
  /// property path share one parser. `fw-bytes` is exactly the quantity
  /// `demuxer-max-bytes` (shown as the cache limit) bounds.
  int? _parseCacheForwardBytes(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      final fwBytes = decoded['fw-bytes'];
      if (fwBytes is int) return fwBytes;
      if (fwBytes is num) return fwBytes.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// The resident demuxer ceiling: the forward bound plus the back bound.
  ///
  /// `demuxer-donate-buffer` defaults on, so mpv lets the back cache absorb
  /// forward bytes the reader has not claimed; `demuxer-max-bytes` alone is
  /// not a ceiling on anything the process holds, and reporting it read a
  /// Fire TV's 96 MB budget as 64 MB. Null only when neither bound is
  /// available, so a libmpv that answers one and not the other still shows
  /// a number.
  int? _parseCacheLimitBytes(String? maxBytes, String? maxBackBytes) {
    final ahead = _parseInt(maxBytes);
    final back = _parseInt(maxBackBytes);
    if (ahead == null && back == null) return null;
    return (ahead ?? 0) + (back ?? 0);
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
  /// strings ('hevc (Main 10)'), ExoPlayer's RFC 6381 codec IDs
  /// ('hvc1.2.4.L153.B0', 'av01.0.08M.10'), and `video/...` MIME types
  /// ('video/hevc') used as a fallback when the container carries no
  /// codecs string.
  String? _formatVideoCodecName(String? codec) {
    if (codec == null || codec.isEmpty) return null;
    final upper = codec.toUpperCase();
    if (upper.contains('DVHE') || upper.contains('DVH1') || upper.contains('DOLBY-VISION')) {
      return 'Dolby Vision';
    }
    if (upper.contains('HEVC') || upper.contains('H265') || upper.contains('HVC1') || upper.contains('HEV1')) {
      return 'HEVC';
    }
    if (upper.contains('H264') || upper.contains('AVC')) return 'H.264';
    if (upper.contains('AV1') || upper.contains('AV01')) return 'AV1';
    if (upper.contains('VP9') || upper.contains('VP09')) return 'VP9';
    if (upper.contains('VP8') || upper.contains('VP08')) return 'VP8';
    if (upper.contains('MP4V')) return 'MPEG-4';
    if (upper.contains('MPEG2')) return 'MPEG-2';
    if (upper.startsWith('VIDEO/')) return codec.substring('video/'.length).toUpperCase();
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
