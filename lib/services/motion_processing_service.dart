import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../media/media_stream.dart';
import '../media/media_version.dart';
import '../models/motion_processing_mode.dart';
import '../models/playback_capability_report.dart';
import '../mpv/player/player.dart';
import '../mpv/player/player_native.dart';
import 'neural_model_pack_service.dart';
import 'power_source_service.dart';
import 'settings_service.dart';
import '../utils/app_logger.dart';

/// Applies display-synced MPV temporal interpolation. Windows uses gpu-next;
/// Linux's Wayland video plane supplies monitor refresh and render-swap
/// feedback to libmpv. Android keeps direct MediaCodec output for Off and opts
/// into an arbiter-managed GPU output for eligible MPV/Neural sessions. Apple Neural
/// requests use the AVFoundation VO's VideoToolbox frame processor.
abstract final class MotionProcessingService {
  static final Expando<_OriginalMotionProperties> _originals = Expando('motion-processing-originals');
  static final Expando<_OriginalAppleMotionOptions> _appleOriginals = Expando('motion-processing-apple-originals');
  static final Expando<bool> _appleNeuralEligible = Expando('motion-processing-apple-neural-eligible');
  static final Expando<_OriginalAndroidMotionOptions> _androidOriginals = Expando(
    'motion-processing-android-originals',
  );
  static final Expando<bool> _androidAnvilActive = Expando('motion-processing-android-anvil-active');
  static final Expando<bool> _androidMpvOutputActive = Expando('motion-processing-android-mpv-output-active');
  static final Expando<bool> _interpolationBufferReady = Expando('motion-processing-buffer-ready');
  static final Expando<bool> _desktopPmeActive = Expando('motion-processing-desktop-pme-active');
  static final Expando<bool> _powerLimited = Expando('motion-processing-power-limited');
  static final Expando<bool> _thermalLimited = Expando('motion-processing-thermal-limited');
  static final Expando<String> _thermalStatus = Expando('motion-processing-thermal-status');
  static final Expando<Timer> _thermalTimers = Expando('motion-processing-thermal-timer');
  static final Expando<bool> _thermalPollInFlight = Expando('motion-processing-thermal-poll-in-flight');
  static final Expando<int> _thermalGeneration = Expando('motion-processing-thermal-generation');
  static final Expando<bool> _powerSuspendedForSession = Expando('motion-processing-power-suspended');
  static final Expando<bool> _neuralRequested = Expando('motion-processing-neural-requested');
  static final Expando<StreamSubscription<bool?>> _powerSubscriptions = Expando('motion-processing-power-subscription');
  static final Expando<int> _powerSourceGeneration = Expando('motion-processing-power-generation');
  static final Expando<_OriginalDesktopPmeOptions> _desktopPmeOriginals = Expando(
    'motion-processing-desktop-pme-originals',
  );

  /// Windows uses MPV's embedded gpu-next output. Linux's Wayland plane uses
  /// libmpv and reports both display refresh and successful swaps. Android
  /// keeps direct-to-surface MediaCodec by default and requests a GPU VO through
  /// the native surface arbiter only for an eligible motion-processing path.
  static bool get isMpvPlatformSupported =>
      Platform.isWindows || Platform.isLinux || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  static bool get _isApplePlatform => Platform.isIOS || Platform.isMacOS;

  static bool get _isDesktopPmePlatform => Platform.isWindows || Platform.isLinux;

  static bool supportsPlayer(Player player) => isMpvPlatformSupported && player.playerType == 'mpv';

  /// Resolves a request to a provider available on this player's output path.
  /// Apple Neural mode is available only while the AVFoundation VideoToolbox
  /// processor reports initialization, readiness, or actual frame output.
  static MotionProcessingResolution resolveForPlayer(
    Player player,
    MotionProcessingMode requested, {
    String? currentVideoOutput,
    String? nativeInterpolationStatus,
    String? neuralProviderStatus,
    PlaybackCapabilityReport? capabilityReport,
    bool isLive = false,
    NeuralInterpolationPreset neuralPreset = NeuralInterpolationPreset.balanced,
  }) {
    final appleOutput = _isApplePlatform && (currentVideoOutput == null || currentVideoOutput == 'avfoundation');
    final rendererAvailable =
        supportsPlayer(player) &&
        !appleOutput &&
        (currentVideoOutput == null ? capabilityReport == null : _supportsVideoOutput(currentVideoOutput)) &&
        (capabilityReport == null || capabilityReport.rendererInterpolationActive == true);
    final providerReady =
        capabilityReport?.neuralProviderReady ??
        (neuralProviderStatus != null &&
            RegExp(
              r'^(qnn-htp(-v\d+)?|qnn-(npu|gpu)|litert-(npu|gpu)|openvino(-npu|-gpu|-cpu)?|cuda-gpu|directml-gpu|vitisai-npu|nvtensorrtrtx-gpu|migraphx-gpu|winml(-npu|-gpu|-cpu)?)(-ready)?$|^pme:(openvino|qnn|cuda|directml|cpu)(:(npu|gpu|cpu))?(-ready)?$',
            ).hasMatch(neuralProviderStatus));
    final nativeProviderReady =
        (appleOutput && const {'initializing', 'ready', 'active'}.contains(nativeInterpolationStatus)) ||
        (rendererAvailable &&
            providerReady &&
            !const {'mpv-bypass', 'recovery-probe'}.contains(capabilityReport?.neuralDeadlineGovernor));
    final streamSupported = capabilityReport == null || _supportsReportedMotionStream(capabilityReport);
    return resolveMotionProcessing(
      requested: requested,
      mpvRendererAvailable: rendererAvailable && streamSupported,
      neuralProviderAvailable: nativeProviderReady && streamSupported,
      neuralPowerLimited:
          _powerLimited[player] == true &&
          (SettingsService.instanceOrNull?.read(SettingsService.neuralOnlyWhenPluggedIn) ?? true),
      neuralThermalLimited: _thermalLimited[player] == true,
      isLive: isLive,
      streamSupported: streamSupported,
      neuralPreset: neuralPreset,
    );
  }

  /// Active stream facts can invalidate a previously configured path after a
  /// track or file transition. Missing facts remain unknown; positive evidence
  /// outside the initial SDR 24/30 fps, up-to-1080p scope resolves the request
  /// to Off.
  static bool _supportsReportedMotionStream(PlaybackCapabilityReport report) {
    if (report.sourceIsHdr == true || report.dolbyVisionProfile != null) return false;

    final width = report.sourceWidth;
    final height = report.sourceHeight;
    if ((width != null && width > 1920) || (height != null && height > 1920)) return false;
    if (width != null && width > 0 && height != null && height > 0) {
      final longerEdge = width > height ? width : height;
      final shorterEdge = width > height ? height : width;
      if (longerEdge > 1920 || shorterEdge > 1080) return false;
    }

    final fps = report.sourceFps;
    if (fps != null && fps > 0 && (fps - 24).abs() > 0.1 && (fps - 30).abs() > 0.1) return false;
    return true;
  }

  static bool _supportsVideoOutput(String output) {
    if (Platform.isWindows) return output == 'gpu' || output == 'gpu-next';
    if (Platform.isLinux) return output == 'libmpv';
    if (Platform.isAndroid) return output == 'gpu' || output == 'gpu-next';
    return false;
  }

  /// Last platform thermal tier seen by the Neural governor. Null means the
  /// OS or device did not report a value.
  static String? thermalStatusForPlayer(Player player) => _thermalStatus[player];

  /// Resolve Android before `loadfile` from its active VO or configured chain.
  /// An explicit eligible MPV request may replace the default
  /// `mediacodec,gpu` priority with the GPU renderer for this session.
  static Future<String?> _videoOutputForConfiguration(Player player) async {
    final current = await player.getProperty('current-vo');
    if (current != null && current.isNotEmpty) return current;
    if (Platform.isAndroid || _isApplePlatform) return player.getProperty('vo');
    return null;
  }

  /// Whether this player has its platform motion path configured, making
  /// in-session option changes safe. Live streams stay excluded.
  static bool canChangeLive(Player player, {required MotionProcessingMode mode, bool isLive = false}) {
    if (isLive || !supportsPlayer(player) || _interpolationBufferReady[player] != true) return false;
    // Neural mode changes the decoder and filter graph, so it is staged for
    // the next media open on these routes. Apple's native provider can change
    // its interpolation mode within the current VideoToolbox session.
    if (mode == MotionProcessingMode.neural && (Platform.isAndroid || _isDesktopPmePlatform)) return false;
    if (_isApplePlatform && mode == MotionProcessingMode.neural && _appleNeuralEligible[player] != true) {
      return false;
    }
    // Moving Android away from the direct MediaCodec surface must happen
    // before the next file opens so the renderer can size its frame queue.
    if (Platform.isAndroid &&
        mode == MotionProcessingMode.mpv &&
        (_androidMpvOutputActive[player] != true || _androidAnvilActive[player] == true)) {
      return false;
    }
    return true;
  }

  /// Configure interpolation before the first file opens so MPV can size its
  /// renderer references and any hardware-decoder surface pool.
  static Future<void> configureForPlayback(
    Player player,
    MotionProcessingMode mode, {
    bool isLive = false,
    bool isTranscoding = false,
    MediaVersion? selectedVersion,
    NeuralInterpolationPreset neuralPreset = NeuralInterpolationPreset.balanced,
  }) async {
    if (!supportsPlayer(player)) return;
    _powerSuspendedForSession[player] = false;
    final powerLimited = await _preparePowerPolicy(player, mode);
    final thermalLimited = await _prepareThermalPolicy(player, mode);
    final effectiveMode = powerLimited || thermalLimited
        ? (_isApplePlatform ? MotionProcessingMode.off : MotionProcessingMode.mpv)
        : mode;
    await _configureForPlaybackImpl(
      player,
      effectiveMode,
      isLive: isLive,
      isTranscoding: isTranscoding,
      selectedVersion: selectedVersion,
      neuralPreset: neuralPreset,
    );
    // A power-source event can arrive while provider setup is awaiting a model
    // or runtime. Recheck the latch after setup so a late initialization never
    // re-enables inference on battery.
    if (mode == MotionProcessingMode.neural && _powerLimited[player] == true) {
      if (!await _suspendNeuralForPower(player)) _powerLimited[player] = false;
    }
    if (mode == MotionProcessingMode.neural && !powerLimited && !thermalLimited) {
      final androidNeuralActive = Platform.isAndroid && _androidAnvilActive[player] == true;
      final appleNeuralEligible = _isApplePlatform && _appleNeuralEligible[player] == true;
      if (androidNeuralActive || appleNeuralEligible) _watchPlatformThermalStatus(player);
    }
  }

  static Future<void> _configureForPlaybackImpl(
    Player player,
    MotionProcessingMode mode, {
    bool isLive = false,
    bool isTranscoding = false,
    MediaVersion? selectedVersion,
    NeuralInterpolationPreset neuralPreset = NeuralInterpolationPreset.balanced,
  }) async {
    if (!supportsPlayer(player)) return;
    if (_isApplePlatform) {
      final output = await _videoOutputForConfiguration(player);
      final avfoundationOutput = output == null || output == 'avfoundation';
      final sourceEligible =
          avfoundationOutput && !isLive && selectedVersion != null && _supportsMotionSource(selectedVersion);
      _appleNeuralEligible[player] = sourceEligible;
      await _applyAppleInterpolation(player, sourceEligible && mode == MotionProcessingMode.neural, neuralPreset);
      _interpolationBufferReady[player] = avfoundationOutput;
      return;
    }

    if (Platform.isAndroid && mode == MotionProcessingMode.mpv) {
      final canKeepConfiguredRenderer =
          _androidMpvOutputActive[player] == true &&
          _androidAnvilActive[player] != true &&
          !isLive &&
          !isTranscoding &&
          selectedVersion != null &&
          _supportsMotionSource(selectedVersion);
      if (!canKeepConfiguredRenderer) {
        await _restoreAndroidMotionPath(player);
        final originalMpv = _originals[player];
        if (originalMpv != null) await _restoreOriginalProperties(player, originalMpv);
      }
      final configured = await _configureAndroidMpvRenderer(
        player,
        selectedVersion: selectedVersion,
        isLive: isLive,
        isTranscoding: isTranscoding,
      );
      if (configured) {
        try {
          await _applyMpvInterpolation(player);
          _interpolationBufferReady[player] = true;
          return;
        } catch (_) {
          await _restoreAndroidMotionPath(player);
          rethrow;
        }
      }
      _interpolationBufferReady[player] = false;
      return;
    }

    if (Platform.isAndroid && mode == MotionProcessingMode.neural) {
      _interpolationBufferReady[player] = false;
      final originalMpv = _originals[player];
      if (originalMpv != null) await _restoreOriginalProperties(player, originalMpv);
      final configured = await _configureAndroidAnvil(
        player,
        selectedVersion: selectedVersion,
        neuralPreset: neuralPreset,
        isLive: isLive,
        isTranscoding: isTranscoding,
      );
      if (configured) {
        try {
          // ANVIL emits a midpoint frame per source pair; MPV's display-sync
          // scheduler paces those frames against the active refresh rate.
          await _applyMpvInterpolation(player);
          _interpolationBufferReady[player] = true;
          return;
        } catch (_) {
          await _restoreAndroidMotionPath(player);
          rethrow;
        }
      }
      await _restoreAndroidMotionPath(player);
      final fallbackOriginalMpv = _originals[player];
      if (fallbackOriginalMpv != null) await _restoreOriginalProperties(player, fallbackOriginalMpv);
      final fallbackRenderer = await _configureAndroidMpvRenderer(
        player,
        selectedVersion: selectedVersion,
        isLive: isLive,
        isTranscoding: isTranscoding,
      );
      if (fallbackRenderer) {
        try {
          await _applyMpvInterpolation(player);
          _interpolationBufferReady[player] = true;
          appLogger.i(
            'MotionProcessingService: Android Neural processing is unavailable for this session; using MPV smoothing.',
          );
        } catch (_) {
          await _restoreAndroidMotionPath(player);
          rethrow;
        }
        return;
      }
      appLogger.i(
        'MotionProcessingService: Android Neural processing is unavailable for this item; preserving its normal playback path.',
      );
      return;
    }
    if (Platform.isAndroid) await _restoreAndroidMotionPath(player);

    if (_isDesktopPmePlatform && mode == MotionProcessingMode.neural) {
      _interpolationBufferReady[player] = false;
      final configured = await _configureDesktopPme(
        player,
        selectedVersion: selectedVersion,
        neuralPreset: neuralPreset,
        isLive: isLive,
        isTranscoding: isTranscoding,
      );
      if (configured) {
        try {
          await _applyMpvInterpolation(player);
          _interpolationBufferReady[player] = true;
          return;
        } catch (_) {
          await _restoreDesktopPme(player);
          rethrow;
        }
      }
      await _restoreDesktopPme(player);
      final output = await _videoOutputForConfiguration(player);
      final fallback = resolveForPlayer(player, mode, currentVideoOutput: output, isLive: isLive);
      final mpvFallbackEligible =
          !isLive && !isTranscoding && selectedVersion != null && _supportsMotionSource(selectedVersion);
      if (mpvFallbackEligible && fallback.usesMpvInterpolation) {
        await _applyMpvInterpolation(player);
        _interpolationBufferReady[player] = true;
        appLogger.i(
          'MotionProcessingService: desktop Neural path is preparing or unavailable; using MPV interpolation.',
        );
      } else {
        final original = _originals[player];
        if (original != null) await _restoreOriginalProperties(player, original);
      }
      return;
    }
    if (_isDesktopPmePlatform) await _restoreDesktopPme(player);

    if (_isDesktopPmePlatform &&
        mode != MotionProcessingMode.off &&
        (isLive || isTranscoding || selectedVersion == null || !_supportsMotionSource(selectedVersion))) {
      final original = _originals[player];
      if (original != null) await _restoreOriginalProperties(player, original);
      _interpolationBufferReady[player] = false;
      return;
    }

    final currentVideoOutput = await _videoOutputForConfiguration(player);
    final resolution = resolveForPlayer(player, mode, currentVideoOutput: currentVideoOutput, isLive: isLive);
    _interpolationBufferReady[player] = false;

    // A reused player may still have interpolation enabled from the previous
    // VOD item. Live streams have no stable pair/cadence window, so always
    // restore MPV's original timing before opening one.
    if (isLive || !resolution.usesMpvInterpolation) {
      final original = _originals[player];
      if (original != null) await _restoreOriginalProperties(player, original);
      return;
    }

    try {
      await _applyMpvInterpolation(player);
      _interpolationBufferReady[player] = true;
      if (resolution.fallback == MotionProcessingFallback.neuralUnavailable) {
        appLogger.i(
          'MotionProcessingService: Neural provider unavailable on this playback path; using MPV interpolation.',
        );
      }
    } catch (_) {
      _interpolationBufferReady[player] = false;
      rethrow;
    }
  }

  /// Applies [mode] to the current MPV player. When switching back to Off,
  /// restore the user's original MPV timing properties rather than assuming
  /// MPV's defaults.
  static Future<void> apply(
    Player player,
    MotionProcessingMode mode, {
    NeuralInterpolationPreset neuralPreset = NeuralInterpolationPreset.balanced,
  }) async {
    if (!supportsPlayer(player)) throw UnsupportedError('MPV motion interpolation is unavailable on this player.');

    if (mode == MotionProcessingMode.neural) {
      if (await _preparePowerPolicy(player, mode)) {
        if (!await _suspendNeuralForPower(player)) _powerLimited[player] = false;
        return;
      }
      if (await _prepareThermalPolicy(player, mode)) {
        if (_isApplePlatform) {
          await player.setProperty('avfoundation-motion-interpolation', 'no');
        } else if (_androidAnvilActive[player] == true) {
          await _suspendNeuralForThermal(player, _thermalStatus[player] ?? 'moderate');
        }
        return;
      }
    } else {
      _neuralRequested[player] = false;
      await _stopPowerMonitoring(player);
      await _stopThermalMonitoring(player);
      _powerLimited[player] = false;
      _thermalLimited[player] = false;
      _thermalStatus[player] = null;
      _powerSuspendedForSession[player] = false;
    }

    if (_isApplePlatform) {
      final output = await _videoOutputForConfiguration(player);
      final avfoundationOutput = output == null || output == 'avfoundation';
      await _applyAppleInterpolation(
        player,
        avfoundationOutput && _appleNeuralEligible[player] == true && mode == MotionProcessingMode.neural,
        neuralPreset,
      );
      _interpolationBufferReady[player] = avfoundationOutput;
      return;
    }

    if (_isDesktopPmePlatform) {
      if (mode == MotionProcessingMode.neural) {
        if (_desktopPmeActive[player] != true) {
          appLogger.i('MotionProcessingService: desktop Neural mode takes effect on the next media open.');
        }
        return;
      }
      await _restoreDesktopPme(player);
    }

    if (Platform.isAndroid) {
      if (mode == MotionProcessingMode.neural) {
        // Neural changes require the model and the software decode/render path
        // to be prepared before loadfile. They are applied on the next media
        // open, where the selected version metadata is available.
        if (_androidAnvilActive[player] != true) {
          appLogger.i('MotionProcessingService: Android Neural mode takes effect on the next media open.');
        }
        return;
      }
      if (mode == MotionProcessingMode.mpv) {
        if (_androidMpvOutputActive[player] != true || _androidAnvilActive[player] == true) {
          appLogger.i('MotionProcessingService: Android MPV smoothing will take effect on the next media open.');
          return;
        }
        await _applyMpvInterpolation(player);
        _interpolationBufferReady[player] = true;
        return;
      }
      await _restoreAndroidMotionPath(player);
    }

    final currentVideoOutput = Platform.isAndroid ? await _videoOutputForConfiguration(player) : null;
    final resolution = resolveForPlayer(player, mode, currentVideoOutput: currentVideoOutput);
    if (!resolution.usesMpvInterpolation) {
      final original = _originals[player];
      if (original != null) await _restoreOriginalProperties(player, original);
      _interpolationBufferReady[player] = false;
      return;
    }

    await _applyMpvInterpolation(player);
    _interpolationBufferReady[player] = true;
    if (resolution.fallback == MotionProcessingFallback.neuralUnavailable) {
      appLogger.i(
        'MotionProcessingService: Neural provider unavailable on this playback path; using MPV interpolation.',
      );
    }
  }

  static Future<void> _applyAppleInterpolation(Player player, bool enabled, NeuralInterpolationPreset preset) async {
    var original = _appleOriginals[player];
    if (original == null) {
      original = _OriginalAppleMotionOptions(
        interpolation: await player.getProperty('avfoundation-motion-interpolation'),
        preset: await player.getProperty('avfoundation-motion-preset'),
        videoSync: await player.getProperty('video-sync'),
      );
      _appleOriginals[player] = original;
    }

    final presetName = switch (preset) {
      NeuralInterpolationPreset.performance => 'performance',
      NeuralInterpolationPreset.balanced => 'balanced',
      NeuralInterpolationPreset.quality => 'quality',
    };
    if (enabled) {
      // Apple frame synthesis follows mpv's display-resample schedule. The VO
      // passes each source frame's refresh-slot count to VideoToolbox, which
      // selects timestamps within the chosen preset's synthesis budget.
      await player.setProperty('video-sync', 'display-resample');
      await player.setProperty('avfoundation-motion-preset', presetName);
      await player.setProperty('avfoundation-motion-interpolation', 'yes');
    } else {
      await player.setProperty('avfoundation-motion-interpolation', original.interpolation ?? 'no');
      await player.setProperty('avfoundation-motion-preset', original.preset ?? 'balanced');
      await player.setProperty('video-sync', original.videoSync ?? 'audio');
    }
  }

  static Future<void> _applyMpvInterpolation(Player player) async {
    var original = _originals[player];
    if (original == null) {
      original = _OriginalMotionProperties(
        videoSync: await player.getProperty('video-sync'),
        interpolation: await player.getProperty('interpolation'),
        tscale: await player.getProperty('tscale'),
        tscaleBlur: await player.getProperty('tscale-blur'),
        tscaleClamp: await player.getProperty('tscale-clamp'),
      );
      _originals[player] = original;
    }

    try {
      // `interpolation` is ignored unless the VO synchronizes to the
      // display. Keep these writes before the first file during startup so
      // MPV can size its frame references and decoder surface pool.
      await player.setProperty('video-sync', 'display-resample');
      await player.setProperty('tscale', 'mitchell');
      await player.setProperty('tscale-blur', '1.0');
      await player.setProperty('tscale-clamp', '1.0');
      await player.setProperty('interpolation', 'yes');
    } catch (error, stackTrace) {
      _interpolationBufferReady[player] = false;
      appLogger.w('MotionProcessingService: Failed to apply MPV interpolation', error: error, stackTrace: stackTrace);
      try {
        await _restoreOriginalProperties(player, original);
      } catch (restoreError, restoreStackTrace) {
        appLogger.w(
          'MotionProcessingService: Failed to restore MPV timing after an interpolation error',
          error: restoreError,
          stackTrace: restoreStackTrace,
        );
      }
      rethrow;
    }
  }

  static Future<bool> _preparePowerPolicy(Player player, MotionProcessingMode requested) async {
    final settings = SettingsService.instanceOrNull;
    final limitToExternalPower = settings?.read(SettingsService.neuralOnlyWhenPluggedIn) ?? true;
    if (requested != MotionProcessingMode.neural || !limitToExternalPower) {
      _neuralRequested[player] = false;
      _powerLimited[player] = false;
      _powerSuspendedForSession[player] = false;
      await _stopPowerMonitoring(player);
      return false;
    }

    _neuralRequested[player] = true;
    final generation = _powerSourceGeneration[player] ?? 0;
    // Subscribe before sampling the current state so a battery transition
    // during provider/model setup cannot fall into the gap between the read
    // and listener registration. Keep any event delivered while the read is
    // in flight; the battery plugin may resolve its snapshot after that event.
    _watchPowerSource(player);
    final externalPower = await PowerSourceService.isConnected();
    if ((_powerSourceGeneration[player] ?? 0) == generation) {
      _powerLimited[player] = externalPower == false;
    }
    return _powerLimited[player] == true;
  }

  static Future<bool> _prepareThermalPolicy(Player player, MotionProcessingMode requested) async {
    if ((!Platform.isAndroid && !_isApplePlatform) ||
        requested != MotionProcessingMode.neural ||
        player is! PlayerNative) {
      _thermalLimited[player] = false;
      _thermalStatus[player] = null;
      await _stopThermalMonitoring(player);
      return false;
    }

    try {
      final status = await player.getMotionProcessingThermalStatus();
      _thermalStatus[player] = status;
      final limited = _thermalStatusRequiresFallback(status);
      _thermalLimited[player] = limited;
      if (limited) await _stopThermalMonitoring(player);
      return limited;
    } catch (error, stackTrace) {
      // Missing thermal reporting is unknown, not a reason to disable Neural.
      appLogger.d(
        'MotionProcessingService: platform thermal status is unavailable',
        error: error,
        stackTrace: stackTrace,
      );
      _thermalStatus[player] = null;
      _thermalLimited[player] = false;
      return false;
    }
  }

  static bool _thermalStatusRequiresFallback(String? status) =>
      const {'moderate', 'severe', 'critical', 'emergency', 'shutdown'}.contains(status);

  static void _watchPlatformThermalStatus(Player player) {
    if ((!Platform.isAndroid && !_isApplePlatform) || player is! PlayerNative || _thermalTimers[player] != null) return;
    final generation = (_thermalGeneration[player] ?? 0) + 1;
    _thermalGeneration[player] = generation;

    Future<void> poll() async {
      if (_thermalPollInFlight[player] == true || player.disposed) return;
      _thermalPollInFlight[player] = true;
      try {
        final status = await player.getMotionProcessingThermalStatus();
        if (player.disposed || _thermalGeneration[player] != generation) return;
        if (status == null) {
          _thermalStatus[player] = null;
          _thermalLimited[player] = false;
          // API levels or devices without thermal reporting stay eligible and
          // should not pay for an unsupported poll every five seconds.
          await _stopThermalMonitoring(player);
          return;
        }
        _thermalStatus[player] = status;
        if (Platform.isAndroid && _androidAnvilActive[player] != true) {
          await _stopThermalMonitoring(player);
          return;
        }
        if (_thermalStatusRequiresFallback(status)) {
          final providerActive = Platform.isAndroid
              ? _androidAnvilActive[player] == true
              : _appleNeuralEligible[player] == true;
          if (!providerActive) {
            await _stopThermalMonitoring(player);
            return;
          }
          _thermalLimited[player] = true;
          if (await _suspendNeuralForThermal(player, status)) {
            await _stopThermalMonitoring(player);
          } else {
            // Keep observing and retry the transition while the provider is
            // still active. Do not report a successful thermal fallback until
            // the active provider has actually stopped.
            _thermalLimited[player] = false;
          }
        }
      } catch (error, stackTrace) {
        appLogger.d('MotionProcessingService: platform thermal polling failed', error: error, stackTrace: stackTrace);
      } finally {
        if (_thermalGeneration[player] == generation) _thermalPollInFlight[player] = false;
      }
    }

    unawaited(poll());
    _thermalTimers[player] = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(poll()));
  }

  static Future<void> _stopThermalMonitoring(Player player) async {
    _thermalGeneration[player] = (_thermalGeneration[player] ?? 0) + 1;
    _thermalTimers[player]?.cancel();
    _thermalTimers[player] = null;
    _thermalPollInFlight[player] = false;
  }

  static Future<bool> _suspendNeuralForThermal(Player player, String status) async {
    if ((!Platform.isAndroid && !_isApplePlatform) || !supportsPlayer(player)) return false;
    try {
      var fallbackReady = true;
      if (_isApplePlatform) {
        await player.setProperty('avfoundation-motion-interpolation', 'no');
      } else {
        if (_androidAnvilActive[player] == true) {
          if (!await _removeAndroidAnvilFilter(player)) return false;
          _androidAnvilActive[player] = false;
        }
        try {
          await _applyMpvInterpolation(player);
        } catch (error, stackTrace) {
          fallbackReady = false;
          appLogger.w(
            'MotionProcessingService: MPV smoothing could not resume after thermal backoff',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      _thermalLimited[player] = true;
      _interpolationBufferReady[player] = fallbackReady;
      appLogger.i(
        _isApplePlatform
            ? 'MotionProcessingService: VideoToolbox interpolation paused at Apple thermal status $status.'
            : fallbackReady
            ? 'MotionProcessingService: Neural processing paused at Android thermal status $status; MPV smoothing remains available.'
            : 'MotionProcessingService: Neural processing paused at Android thermal status $status; playback continues without MPV smoothing.',
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: could not pause Neural processing during thermal backoff',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static void _watchPowerSource(Player player) {
    if (_powerSubscriptions[player] != null) return;
    try {
      _powerSubscriptions[player] = PowerSourceService.changes.listen(
        (externalPower) {
          if (externalPower == null || _neuralRequested[player] != true) return;
          _powerSourceGeneration[player] = (_powerSourceGeneration[player] ?? 0) + 1;
          if (externalPower) {
            // Reconnection does not hot-start a model that was already
            // suspended, but it clears a stale limit during initial setup.
            if (_powerSuspendedForSession[player] != true) _powerLimited[player] = false;
            return;
          }
          final settings = SettingsService.instanceOrNull;
          if (settings?.read(SettingsService.neuralOnlyWhenPluggedIn) != true) return;
          _powerLimited[player] = true;
          _powerSuspendedForSession[player] = true;
          unawaited(
            _suspendNeuralForPower(player).then((disabled) {
              if (!disabled) _powerLimited[player] = false;
            }),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          appLogger.d('MotionProcessingService: power-source updates are unavailable', error: error);
        },
      );
    } on Object catch (error) {
      // A platform that has no battery plugin reports unknown power status;
      // it remains eligible and keeps the regular playback path.
      appLogger.d('MotionProcessingService: power-source monitoring is unavailable', error: error);
    }
  }

  static Future<void> _stopPowerMonitoring(Player player) async {
    final subscription = _powerSubscriptions[player];
    _powerSubscriptions[player] = null;
    await subscription?.cancel();
  }

  /// Stop Neural output promptly when a battery-backed device is unplugged.
  /// The already-selected MPV path remains available; model inference resumes
  /// at the next item boundary after external power is restored.
  static Future<bool> _suspendNeuralForPower(Player player) async {
    if (!supportsPlayer(player)) return false;
    _powerSuspendedForSession[player] = true;
    try {
      if (_isApplePlatform) {
        await player.setProperty('avfoundation-motion-interpolation', 'no');
      } else if (_isDesktopPmePlatform && _desktopPmeActive[player] == true) {
        if (!await _removeDesktopPmeFilter(player)) return false;
        _desktopPmeActive[player] = false;
        try {
          await _applyMpvInterpolation(player);
        } catch (error, stackTrace) {
          appLogger.w(
            'MotionProcessingService: MPV smoothing could not resume after Neural paused',
            error: error,
            stackTrace: stackTrace,
          );
        }
      } else if (Platform.isAndroid && _androidAnvilActive[player] == true) {
        if (!await _removeAndroidAnvilFilter(player)) return false;
        _androidAnvilActive[player] = false;
        try {
          await _applyMpvInterpolation(player);
        } catch (error, stackTrace) {
          appLogger.w(
            'MotionProcessingService: MPV smoothing could not resume after Neural paused',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      await _stopThermalMonitoring(player);
      _interpolationBufferReady[player] = true;
      appLogger.i(
        _isApplePlatform
            ? 'MotionProcessingService: Neural processing paused on battery.'
            : 'MotionProcessingService: Neural processing paused on battery; MPV smoothing remains available.',
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: could not pause Neural processing on battery',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Releases the per-player power observer when its video route is disposed.
  static Future<void> stopPowerSourceMonitoring(Player player) async {
    _neuralRequested[player] = false;
    await _stopPowerMonitoring(player);
    await _stopThermalMonitoring(player);
    _thermalStatus[player] = null;
  }

  /// Apply a changed power preference to the currently open session. Turning
  /// the guard off does not hot-start a model that was already suspended; that
  /// route is prepared at the next item boundary.
  static Future<void> refreshPowerPolicyForPlayer(Player player) async {
    if (_neuralRequested[player] != true) return;
    final settings = SettingsService.instanceOrNull;
    final enabled = settings?.read(SettingsService.neuralOnlyWhenPluggedIn) ?? true;
    if (!enabled) {
      _powerLimited[player] = false;
      _powerSuspendedForSession[player] = false;
      await _stopPowerMonitoring(player);
      return;
    }

    final externalPower = await PowerSourceService.isConnected();
    if (externalPower == false) {
      _powerLimited[player] = true;
      _powerSuspendedForSession[player] = true;
      _watchPowerSource(player);
      if (!await _suspendNeuralForPower(player)) _powerLimited[player] = false;
    } else if (externalPower == true && _powerSuspendedForSession[player] != true) {
      _powerLimited[player] = false;
      _watchPowerSource(player);
    }
  }

  static Future<bool> _configureDesktopPme(
    Player player, {
    required MediaVersion? selectedVersion,
    required NeuralInterpolationPreset neuralPreset,
    required bool isLive,
    required bool isTranscoding,
  }) async {
    if (!_isDesktopPmePlatform || player.playerType != 'mpv' || isLive || isTranscoding || selectedVersion == null) {
      return false;
    }
    if (!_supportsDesktopPmeSource(selectedVersion)) return false;

    final model = await NeuralModelPackService.installedOrStartInstall(neuralPreset);
    if (model == null) {
      appLogger.i('MotionProcessingService: starting the Neural model download; playback remains on MPV smoothing.');
      return false;
    }
    final runtime = await _findDesktopPmeRuntime();
    if (runtime == null) {
      appLogger.w('MotionProcessingService: desktop PME runtime bundle is not installed.');
      return false;
    }

    try {
      var original = _desktopPmeOriginals[player];
      if (original == null) {
        original = _OriginalDesktopPmeOptions(
          hwdec: await player.getProperty('hwdec'),
          decoderOptions: await player.getProperty('vd-lavc-o'),
        );
        _desktopPmeOriginals[player] = original;
      }
      if (_desktopPmeActive[player] == true) await _removeDesktopPmeFilter(player);

      // The filter requires FFmpeg motion-vector side data and CPU-readable
      // YUV420P frames. auto-copy may retain a hardware decoder that does not
      // export those vectors, so this route deliberately selects software
      // decode for the Neural session.
      await player.setProperty('hwdec', 'no');
      await player.setProperty('vd-lavc-o', _withExportMotionVectors(original.decoderOptions ?? ''));
      final filterOptions = <String, String>{
        'model': model.path,
        'runtime': runtime.ortLibrary,
        'providers': runtime.providerManifest,
        'pme-library': runtime.pmeLibrary,
        'preset': neuralPreset.name,
        'allow-cpu': 'no',
        'require-neural': 'yes',
      }.entries.map((entry) => entry.key + '=' + _escapeMpvFilterValue(entry.value)).join(':');
      await player.command(['vf', 'add', '@plezy-pme:plezy-pme=$filterOptions']);
      _desktopPmeActive[player] = true;
      return true;
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: desktop PME filter could not be attached',
        error: error,
        stackTrace: stackTrace,
      );
      await _restoreDesktopPme(player);
      return false;
    }
  }

  static bool _supportsDesktopPmeSource(MediaVersion version) {
    if (version.width != 1920 || version.height != 1080) return false;
    final streams = version.parts
        .expand((part) => part.streams)
        .where((stream) => stream.kind == MediaStreamKind.video)
        .toList(growable: false);
    final video = streams.firstWhere(
      (stream) => stream.selected,
      orElse: () => streams.length == 1 ? streams.single : const MediaStream(id: '', kind: MediaStreamKind.unknown),
    );
    if (video.kind != MediaStreamKind.video || video.interlaced != false || video.hdr || video.dolbyVision) {
      return false;
    }
    final codec = (video.codec ?? version.videoCodec ?? '').toLowerCase();
    if (!const {'h264', 'avc', 'avc1'}.contains(codec)) return false;
    final fps = video.frameRate;
    return fps != null && ((fps - 24).abs() <= 0.1 || (fps - 30).abs() <= 0.1);
  }

  static Future<_DesktopPmeRuntime?> _findDesktopPmeRuntime() async {
    final executableDirectory = Directory(p.dirname(Platform.resolvedExecutable));
    final directories = <Directory>[];
    final runtimeOverride = Platform.environment['PLEZY_PME_RUNTIME_DIR']?.trim();
    if (runtimeOverride != null && runtimeOverride.isNotEmpty) {
      directories.add(Directory(runtimeOverride));
    }
    directories.addAll(<Directory>[
      executableDirectory,
      Directory(p.join(executableDirectory.path, 'lib')),
      Directory(p.normalize(p.join(executableDirectory.path, '..', 'lib'))),
      Directory(p.normalize(p.join(executableDirectory.path, '..', 'lib', 'plezy'))),
      Directory(p.normalize(p.join(executableDirectory.path, '..', 'lib', 'plezyng'))),
    ]);
    final windows = Platform.isWindows;
    final manifestName = windows ? 'providers.windows.tsv' : 'providers.linux.tsv';
    final pmeName = windows ? 'plezy_motion_engine.dll' : 'libplezy_motion_engine.so';
    final ortName = windows ? 'onnxruntime.dll' : 'libonnxruntime.so';
    for (final directory in directories) {
      final manifest = File(p.join(directory.path, manifestName));
      final pme = File(p.join(directory.path, pmeName));
      final ort = File(p.join(directory.path, ortName));
      if (await manifest.exists() && await pme.exists() && await ort.exists()) {
        return _DesktopPmeRuntime(providerManifest: manifest.path, pmeLibrary: pme.path, ortLibrary: ort.path);
      }
    }
    return null;
  }

  static String _escapeMpvFilterValue(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll(':', '\\:').replaceAll(',', '\\,');

  static Future<bool> _removeDesktopPmeFilter(Player player) async {
    try {
      await player.command(['vf', 'remove', '@plezy-pme']);
      return true;
    } catch (error) {
      appLogger.d('MotionProcessingService: desktop PME filter was not active', error: error);
      return false;
    }
  }

  static Future<void> _restoreDesktopPme(Player player) async {
    final original = _desktopPmeOriginals[player];
    if (original == null) return;
    if (_desktopPmeActive[player] == true) await _removeDesktopPmeFilter(player);
    for (final (property, value) in <(String, String?)>[
      ('hwdec', original.hwdec),
      ('vd-lavc-o', original.decoderOptions),
    ]) {
      if (value == null) continue;
      try {
        await player.setProperty(property, value);
      } catch (error, stackTrace) {
        appLogger.w(
          'MotionProcessingService: desktop PME option $property could not be restored',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _desktopPmeActive[player] = false;
    _desktopPmeOriginals[player] = null;
  }

  static bool _supportsMotionSource(MediaVersion version) {
    final width = version.width;
    final height = version.height;
    if (width == null || height == null || width < 1 || height < 1 || width > 1920 || height > 1920) return false;
    if (width * height > 1920 * 1080) return false;
    final streams = version.parts
        .expand((part) => part.streams)
        .where((stream) => stream.kind == MediaStreamKind.video)
        .toList(growable: false);
    final video = streams.firstWhere(
      (stream) => stream.selected,
      orElse: () => streams.length == 1 ? streams.single : const MediaStream(id: '', kind: MediaStreamKind.unknown),
    );
    if (video.kind != MediaStreamKind.video || video.interlaced != false || video.hdr || video.dolbyVision) {
      return false;
    }
    final fps = video.frameRate;
    return fps != null && ((fps - 24).abs() <= 0.1 || (fps - 30).abs() <= 0.1);
  }

  static Future<bool> _configureAndroidMpvRenderer(
    Player player, {
    required MediaVersion? selectedVersion,
    required bool isLive,
    required bool isTranscoding,
  }) async {
    if (isLive || isTranscoding || selectedVersion == null || !_supportsMotionSource(selectedVersion)) {
      return false;
    }

    if (player is! PlayerNative) return false;
    // Preserve the user's decoder choice while asking the native output policy
    // to select a GPU path and, on hardware sessions, transfer surface ownership.
    try {
      final installed = await player.setAndroidMotionProcessingRenderer('gpu');
      if (installed) {
        _androidMpvOutputActive[player] = true;
        return true;
      }
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: Android GPU output could not be enabled for MPV smoothing.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _restoreAndroidMotionPath(player);
    return false;
  }

  static Future<bool> _configureAndroidAnvil(
    Player player, {
    required MediaVersion? selectedVersion,
    required NeuralInterpolationPreset neuralPreset,
    required bool isLive,
    required bool isTranscoding,
  }) async {
    if (player is! PlayerNative || isLive || isTranscoding || selectedVersion == null) {
      return false;
    }

    try {
      final capabilities = await player.getAndroidMotionRuntimeCapabilities();
      if (capabilities == null) return false;
      if (capabilities['qnnHtpAvailable'] == true &&
          await _configureAndroidAnvilQnn(
            player,
            capabilities: capabilities,
            selectedVersion: selectedVersion,
            neuralPreset: neuralPreset,
          )) {
        return true;
      }
      return _configureAndroidAnvilLiteRt(
        player,
        capabilities: capabilities,
        selectedVersion: selectedVersion,
        neuralPreset: neuralPreset,
      );
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: Android neural provider setup failed',
        error: error,
        stackTrace: stackTrace,
      );
      await _restoreAndroidMotionPath(player);
      return false;
    }
  }

  static Future<bool> _configureAndroidAnvilQnn(
    PlayerNative player, {
    required Map<Object?, Object?> capabilities,
    required MediaVersion selectedVersion,
    required NeuralInterpolationPreset neuralPreset,
  }) async {
    final architecture = capabilities['qnnHtpArchitecture'] as String?;
    final resolution = capabilities['qnnHtpResolution'] as String?;
    if (architecture == null || resolution == null || !_supportsAndroidAnvilSource(selectedVersion, resolution)) {
      return false;
    }

    final modelId = NeuralModelPackService.androidContextModelId(resolution, neuralPreset);
    final packagedContextIds = capabilities['anvilContextIds'];
    final packagedContext = packagedContextIds is List && packagedContextIds.contains(modelId);
    final publishedV75Context = architecture == 'v75' && modelId == 'anvil-s-1080p';
    if (!publishedV75Context && !packagedContext) return false;

    final context = packagedContext
        ? null
        : await NeuralModelPackService.installedOrStartAndroidHtpContext(architecture, modelId);
    if (publishedV75Context && !packagedContext && context == null) {
      appLogger.i(
        'MotionProcessingService: verified V75 ANVIL context is downloading; checking the LiteRT provider for this open.',
      );
      return false;
    }
    final qnnDirectory = await player.prepareAndroidAnvilRuntime(contextPath: context?.path, modelId: modelId);
    if (qnnDirectory == null || qnnDirectory.isEmpty) return false;

    final original = await _captureAndroidMotionOptions(player);
    if (_androidAnvilActive[player] == true) await _removeAndroidAnvilFilter(player);

    await player.setProperty('hwdec', 'no');
    await player.setProperty('vd-lavc-o', _withExportMotionVectors(original.decoderOptions ?? ''));
    final rendererInstalled = await player.setAndroidMotionProcessingRenderer('gpu-next');
    if (!rendererInstalled) {
      await _restoreAndroidMotionPath(player);
      return false;
    }

    final htpPerformance = switch (neuralPreset) {
      NeuralInterpolationPreset.performance => 'burst',
      NeuralInterpolationPreset.balanced => 'sustained',
      NeuralInterpolationPreset.quality => 'sustained',
    };
    try {
      await player.command([
        'vf',
        'add',
        '@plezy-anvil:anvil=qnn-dir=$qnnDirectory:qnn-perf=$htpPerformance:require-qnn=yes',
      ]);
      _androidAnvilActive[player] = true;
      _androidMpvOutputActive[player] = false;
      return true;
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: Android QNN filter could not be attached',
        error: error,
        stackTrace: stackTrace,
      );
      await _restoreAndroidMotionPath(player);
      return false;
    }
  }

  static Future<bool> _configureAndroidAnvilLiteRt(
    PlayerNative player, {
    required Map<Object?, Object?> capabilities,
    required MediaVersion selectedVersion,
    required NeuralInterpolationPreset neuralPreset,
  }) async {
    final npuAvailable = capabilities['litertNpuAvailable'] == true;
    final gpuAvailable = capabilities['litertGpuAvailable'] == true;
    if (!npuAvailable && !gpuAvailable) return false;

    final resolution = selectedVersion.width == 1280 ? '720p' : '1080p';
    if (!_supportsAndroidAnvilSource(selectedVersion, resolution)) return false;
    final modelId = NeuralModelPackService.androidContextModelId(resolution, neuralPreset);
    final runtime = await player.prepareAndroidLiteRtMotionRuntime(modelId: modelId);
    if (runtime == null) return false;
    final npuModel = runtime['npuModelPath'] as String?;
    final gpuModel = runtime['gpuModelPath'] as String?;
    final npuModelBackend = runtime['npuModelBackend'] as String?;
    final npuModelExecution = runtime['npuModelExecution'] as String?;
    final npuModelTarget = runtime['npuModelTarget'] as String?;
    final libraryDir = runtime['libraryDir'] as String?;
    final cacheDir = runtime['cacheDir'] as String?;
    if ((npuModel == null && gpuModel == null) || libraryDir == null || cacheDir == null) return false;

    final original = await _captureAndroidMotionOptions(player);
    if (_androidAnvilActive[player] == true) await _removeAndroidAnvilFilter(player);
    await player.setProperty('hwdec', 'no');
    await player.setProperty('vd-lavc-o', _withExportMotionVectors(original.decoderOptions ?? ''));
    final rendererInstalled = await player.setAndroidMotionProcessingRenderer('gpu-next');
    if (!rendererInstalled) {
      await _restoreAndroidMotionPath(player);
      return false;
    }

    final options = <String>[
      'litert-library-dir=$libraryDir',
      'litert-cache-dir=$cacheDir',
      if (npuModel != null) 'litert-model=$npuModel',
      if (gpuModel != null) 'litert-gpu-model=$gpuModel',
      if (npuModel != null && npuModelBackend != null && RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(npuModelBackend))
        'litert-npu-backend=$npuModelBackend',
      if (npuModel != null && const {'aot', 'jit'}.contains(npuModelExecution))
        'litert-npu-execution=$npuModelExecution',
      if (npuModel != null && npuModelTarget != null && RegExp(r'^[A-Z0-9_-]{1,32}$').hasMatch(npuModelTarget))
        'litert-npu-target=$npuModelTarget',
      'require-neural=yes',
    ].join(':');
    try {
      await player.command(['vf', 'add', '@plezy-anvil:anvil=$options']);
      _androidAnvilActive[player] = true;
      _androidMpvOutputActive[player] = false;
      return true;
    } catch (error, stackTrace) {
      appLogger.w(
        'MotionProcessingService: Android LiteRT filter could not be attached',
        error: error,
        stackTrace: stackTrace,
      );
      await _restoreAndroidMotionPath(player);
      return false;
    }
  }

  static Future<_OriginalAndroidMotionOptions> _captureAndroidMotionOptions(PlayerNative player) async {
    var original = _androidOriginals[player];
    if (original == null) {
      original = _OriginalAndroidMotionOptions(
        hwdec: await player.getProperty('hwdec'),
        decoderOptions: await player.getProperty('vd-lavc-o'),
      );
      _androidOriginals[player] = original;
    }
    return original;
  }

  static bool _supportsAndroidAnvilSource(MediaVersion version, String resolution) {
    final expectedWidth = resolution == '720p' ? 1280 : 1920;
    final expectedHeight = resolution == '720p' ? 720 : 1080;
    if (version.width != expectedWidth || version.height != expectedHeight) return false;
    final streams = version.parts
        .expand((part) => part.streams)
        .where((stream) => stream.kind == MediaStreamKind.video);
    final videoStreams = streams.toList(growable: false);
    final video = videoStreams.firstWhere(
      (stream) => stream.selected,
      orElse: () =>
          videoStreams.length == 1 ? videoStreams.single : const MediaStream(id: '', kind: MediaStreamKind.unknown),
    );
    if (video.kind != MediaStreamKind.video || video.interlaced != false || video.hdr || video.dolbyVision) {
      return false;
    }
    final codec = (video.codec ?? version.videoCodec ?? '').toLowerCase();
    if (!const {'h264', 'avc', 'avc1'}.contains(codec)) return false;
    final fps = video.frameRate;
    return fps != null && ((fps - 24).abs() <= 0.1 || (fps - 30).abs() <= 0.1);
  }

  static String _withExportMotionVectors(String decoderOptions) {
    final options = <String>[];
    var current = StringBuffer();
    var escaped = false;
    for (final unit in decoderOptions.runes) {
      final character = String.fromCharCode(unit);
      if (escaped) {
        current.write(character);
        escaped = false;
      } else if (character == r'\') {
        current.write(character);
        escaped = true;
      } else if (character == ',') {
        options.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(character);
      }
    }
    if (current.isNotEmpty) options.add(current.toString());

    final flagsIndex = options.indexWhere((option) => option.trimLeft().startsWith('flags2='));
    if (flagsIndex < 0) {
      options.add('flags2=+export_mvs');
    } else {
      final prefixLength = options[flagsIndex].indexOf('flags2=') + 'flags2='.length;
      final value = options[flagsIndex].substring(prefixLength);
      // FFmpeg flag strings allow both `+flag` and `-flag`; a negative entry
      // must not suppress enabling export_mvs for the ANVIL decoder path.
      final exportIsEnabled = RegExp(r'(^|\+)export_mvs($|[+-])').hasMatch(value);
      if (!exportIsEnabled) {
        final separator = value.isEmpty || value.endsWith('+') || value.endsWith('-') ? '' : '+';
        options[flagsIndex] = '${options[flagsIndex]}${separator}export_mvs';
      }
    }
    return options.where((option) => option.isNotEmpty).join(',');
  }

  static Future<bool> _removeAndroidAnvilFilter(Player player) async {
    try {
      await player.command(['vf', 'remove', '@plezy-anvil']);
      return true;
    } catch (error) {
      appLogger.d('MotionProcessingService: Android ANVIL filter was not active', error: error);
      return false;
    }
  }

  static Future<void> _restoreAndroidMotionPath(Player player) async {
    _androidMpvOutputActive[player] = false;
    final original = _androidOriginals[player];
    if (_androidAnvilActive[player] == true) await _removeAndroidAnvilFilter(player);
    if (player is PlayerNative) {
      try {
        final restored = await player.setAndroidMotionProcessingRenderer(null);
        if (!restored) {
          appLogger.w('MotionProcessingService: Android motion renderer did not return to its requested output.');
        }
      } catch (error, stackTrace) {
        appLogger.w(
          'MotionProcessingService: Android motion renderer could not be restored',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (original == null) {
      _androidAnvilActive[player] = false;
      return;
    }
    final restore = <(String, String?)>[('hwdec', original.hwdec), ('vd-lavc-o', original.decoderOptions)];
    for (final (property, value) in restore) {
      if (value == null) continue;
      try {
        await player.setProperty(property, value);
      } catch (error, stackTrace) {
        appLogger.w(
          'MotionProcessingService: Android motion option $property could not be restored',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _androidAnvilActive[player] = false;
    _androidOriginals[player] = null;
  }

  static Future<void> _restoreOriginalProperties(Player player, _OriginalMotionProperties original) async {
    await player.setProperty('interpolation', original.interpolation ?? 'no');
    if (original.tscale != null) await player.setProperty('tscale', original.tscale!);
    if (original.tscaleBlur != null) await player.setProperty('tscale-blur', original.tscaleBlur!);
    if (original.tscaleClamp != null) await player.setProperty('tscale-clamp', original.tscaleClamp!);
    await player.setProperty('video-sync', original.videoSync ?? 'audio');
  }
}

final class _OriginalMotionProperties {
  final String? videoSync;
  final String? interpolation;
  final String? tscale;
  final String? tscaleBlur;
  final String? tscaleClamp;

  const _OriginalMotionProperties({
    required this.videoSync,
    required this.interpolation,
    required this.tscale,
    required this.tscaleBlur,
    required this.tscaleClamp,
  });
}

final class _OriginalAppleMotionOptions {
  final String? interpolation;
  final String? preset;
  final String? videoSync;

  const _OriginalAppleMotionOptions({required this.interpolation, required this.preset, required this.videoSync});
}

final class _OriginalAndroidMotionOptions {
  final String? hwdec;
  final String? decoderOptions;

  const _OriginalAndroidMotionOptions({required this.hwdec, required this.decoderOptions});
}

final class _DesktopPmeRuntime {
  final String providerManifest;
  final String pmeLibrary;
  final String ortLibrary;

  const _DesktopPmeRuntime({required this.providerManifest, required this.pmeLibrary, required this.ortLibrary});
}

final class _OriginalDesktopPmeOptions {
  final String? hwdec;
  final String? decoderOptions;

  const _OriginalDesktopPmeOptions({required this.hwdec, required this.decoderOptions});
}
