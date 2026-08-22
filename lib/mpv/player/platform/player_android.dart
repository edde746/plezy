import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../../../services/device_performance.dart';
import '../../../services/settings_service.dart';
import '../../models.dart';
import '../player_base.dart';

/// Android implementation using ExoPlayer with ASS subtitle support via libass-android.
class PlayerAndroid extends PlayerBase {
  static const _methodChannel = MethodChannel('com.plezy/exo_player');
  static const _eventChannel = EventChannel('com.plezy/exo_player/events');

  int? _bufferSizeBytes;
  bool _bufferSizeIsAuto = false;
  String _bufferTier = 'auto';
  bool _tunnelingEnabled = false;
  String _dvConversionMode = 'auto';
  String _demuxerMode = 'ffmpeg';
  bool _audioNormalizationEnabled = false;
  bool _audioPassthroughEnabled = false;
  bool _downmixEnabled = false;
  int _downmixCenterBoostDb = 0;
  bool _downmixNormalize = true;

  /// Server-reported frame rate for the next item, or null when unknown.
  ///
  /// Rides on `open` rather than a standalone call because it is per-item and
  /// must be known before the native side settles tunneling for that item.
  double? _contentFrameRate;

  /// The native plugin switched from ExoPlayer to its mpv fallback for this
  /// session. Sticky for the instance lifetime, mirroring the native flag
  /// (which resets only on initialize/dispose).
  bool _usingMpvFallback = false;

  bool get usingMpvFallback => _usingMpvFallback;

  /// Subtitles are hidden through the player's visibility toggle. Sticky
  /// across media opens, like mpv's global `sub-visibility`, so an episode
  /// change cannot put them back on screen.
  bool _subtitlesHidden = false;

  /// Track that un-hiding restores: whatever was selected when subtitles were
  /// hidden, then whatever was selected for the current media while hidden.
  String? _hiddenSubtitleTrackId;

  @override
  MethodChannel get methodChannel => _methodChannel;

  @override
  EventChannel get eventChannel => _eventChannel;

  @override
  String get logPrefix => 'ExoPlayer';

  @override
  String get playerType => 'exoplayer';

  @override
  bool get supportsSecondarySubtitles => false;

  // ExoPlayer attaches external subtitles to the MediaItem before prepare;
  // the Android mpv fallback mirrors PlayerNative by passing sub-files through
  // loadfile options.
  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  // The fallback runs mpv over MediaCodec — the same display-switch decoder
  // constraint as PlayerNative on Android. The whole startup-gate chain
  // (setVideoFrameRate, playback-restart, seek/drop-buffers refresh,
  // open-paused) already routes per-core natively.
  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => _usingMpvFallback;

  @override
  bool get detectsFpsAfterRender => true;

  @override
  bool get providesNativeStats => true;

  @override
  bool get audioPassthroughActive => _audioPassthroughEnabled;

  @override
  void handlePlayerEvent(String name, Map? data) {
    if (name == 'backend-switched') {
      // Native player switched from ExoPlayer to MPV due to unsupported format.
      // Clear stale ExoPlayer tracks so applyTrackSelectionWhenReady waits for
      // mpv's track-list instead of immediately applying with ExoPlayer IDs.
      final wasUsingMpvFallback = _usingMpvFallback;
      _usingMpvFallback = true;
      if (!wasUsingMpvFallback) {
        clearTracks();
      }
      backendSwitchedController.add(null);
      return;
    }

    super.handlePlayerEvent(name, data);
  }

  // Memoizes the in-flight init Future so concurrent callers share one
  // `invoke('initialize')`. ExoPlayer's native handleInitialize is
  // synchronous and would mask a Dart-side race anyway, but we mirror the
  // pattern from PlayerNative for consistency and to avoid a partial-init
  // hole if any observeProperty call throws.
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() async {
    if (initialized) return;
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      final result = await invoke<bool>('initialize', {
        'bufferSizeBytes': _bufferSizeBytes,
        'bufferSizeAuto': _bufferSizeIsAuto,
        'bufferTier': _bufferTier,
        'tunnelingEnabled': _tunnelingEnabled,
        'dvConversionMode': _dvConversionMode,
        'demuxerMode': _demuxerMode,
        'audioPassthroughEnabled': _audioPassthroughEnabled,
        // Cheap (32-bit) TV boxes run the hardware video path a frame behind a GL
        // subtitle overlay; render the ASS one frame earlier there to realign.
        'assVideoLatencyFrames': DevicePerformance.isLowEndHardware ? 1 : 0,
        // libass overlay raster scale from the "Render Resolution" subtitle setting
        // (Full / ¾ / ½ / ⅓ / ¼); < 1 trades sharpness for throughput on slow GPUs.
        'subtitleRenderScale': SettingsService.instance
            .read(SettingsService.subtitleRenderResolution)
            .androidRenderScale,
      });
      if (disposed) throw StateError('Player was disposed during initialization');
      if (result != true) {
        throw Exception('Failed to initialize ExoPlayer');
      }

      // Register property observers before flipping `initialized` so partial
      // failures don't leave us in a half-initialized state that the memoized
      // future would falsely treat as ready.
      await observeCoreProperties(trackListFormat: 'string');
      await observeProperty('demuxer-cache-time', 'double');
      if (disposed) throw StateError('Player was disposed during initialization');

      // These settings can be queued before any operation initializes the
      // native core. Apply the latest requested values now so ExoPlayer and
      // the already-queued mpv fallback properties start in the same state.
      await invoke('setAudioNormalization', {'enabled': _audioNormalizationEnabled});
      await invoke('setAudioDownmix', {
        'enabled': _downmixEnabled,
        'centerBoostDb': _downmixCenterBoostDb,
        'normalize': _downmixNormalize,
      });
      if (disposed) throw StateError('Player was disposed during initialization');

      initialized = true;
    } catch (e) {
      _initFuture = null;
      if (!disposed) errorController.add(PlayerError('Initialization failed: $e'));
      rethrow;
    }
  }

  // A setting requested before the core is up is applied by _doInitialize from
  // the stored fields; one requested while an init is in flight has to be
  // replayed afterwards, but only if no newer request superseded it.
  Future<void> _applyWhenInitialized(Future<void> Function() apply, bool Function() stillRequested) async {
    final initFuture = _initFuture;
    if (initialized) {
      await apply();
    } else if (initFuture != null) {
      await initFuture;
      if (!disposed && initialized && stillRequested()) {
        await apply();
      }
    }
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    if (disposed) return;
    await _ensureInitialized();
    final startPosition = media.start ?? Duration.zero;
    final hasStartPosition = media.start != null && startPosition > Duration.zero;
    final previousState = state;
    final previousPosition = currentPosition;
    final previousTimelineDuration = configuredTimelineDuration;
    final previousExternalSubtitleMetadata = snapshotExternalSubtitleMetadata();
    configureTimeline(duration: timelineDuration);
    clearTracks();
    setExternalSubtitleMetadata(externalSubtitles);
    resetPlaybackProgress(startPosition);
    setSeekable(false);

    try {
      // Show the video layer
      await setVisible(true);

      await invoke('open', {
        'uri': media.uri,
        'headers': media.headers,
        'startPositionMs': startPosition.inMilliseconds,
        'hasStartPosition': hasStartPosition,
        'autoPlay': play,
        'isLive': isLive,
        if (_contentFrameRate != null) 'contentFrameRate': _contentFrameRate,
        if (externalSubtitles != null && externalSubtitles.isNotEmpty)
          'externalSubtitles': externalSubtitles
              .where((s) => s.uri?.isNotEmpty == true)
              .map(
                (s) => {
                  'uri': s.uri,
                  'title': s.title,
                  'language': s.language,
                  'codec': s.codec,
                  'isDefault': s.isDefault,
                  'isForced': s.isForced,
                  'isContainer': s.isContainer,
                },
              )
              .toList(),
      });
    } catch (_) {
      if (!disposed) {
        configureTimeline(duration: previousTimelineDuration);
        restorePlaybackProgress(previousState, position: previousPosition);
        restoreTracks(previousState);
        restoreExternalSubtitleMetadata(previousExternalSubtitleMetadata);
        setSeekable(previousState.seekable);
      }
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    await invoke('play');
  }

  @override
  Future<void> pause() async {
    await invoke('pause');
  }

  @override
  Future<void> stop() async {
    await invoke('stop');
    setSeekable(false);
    await setVisible(false);
  }

  @override
  Future<void> seek(Duration position) async {
    await runSeek(position, () => invoke('seek', {'positionMs': position.inMilliseconds}));
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    await invoke('selectAudioTrack', {'trackId': track.id});
  }

  /// ExoPlayer has no renderer-level subtitle visibility switch, so hiding is
  /// implemented as deselection (see [setProperty]'s `sub-visibility` case).
  /// A selection arriving while subtitles are hidden — the automatic pass
  /// after an episode change, or a manual pick — becomes what un-hiding
  /// restores instead of putting subtitles back on screen, matching how mpv's
  /// global `sub-visibility` keeps hiding across files (#1779).
  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    if (_subtitlesHidden) {
      _hiddenSubtitleTrackId = track.id == SubtitleTrack.off.id ? null : track.id;
      return _selectSubtitleTrackNatively(SubtitleTrack.off);
    }
    return _selectSubtitleTrackNatively(track);
  }

  Future<void> _selectSubtitleTrackNatively(SubtitleTrack track) async {
    await invoke('selectSubtitleTrack', {'trackId': track.id});
  }

  /// A sidecar flagged default must not draw itself onto a hidden renderer
  /// either; the selection pass that follows the add records it the same way
  /// [selectSubtitleTrack] does.
  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    await invoke('addSubtitleTrack', {
      'uri': uri,
      'title': title,
      'language': language,
      'select': select && !_subtitlesHidden,
    });
  }

  @override
  Future<void> setVolume(double volume) async {
    await invoke('setVolume', {'volume': volume});
    if (!disposed) setVolumeState(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    await invoke('setRate', {'rate': rate});
    // The ExoPlayer core emits no `speed` property, so the mirror below is the
    // only thing that lands the rate in PlayerState — same shape as setVolume.
    if (!disposed) setRateState(rate);
  }

  @override
  Future<void> setProperty(String name, String value) async {
    if (disposed) return;
    switch (name) {
      case 'pause':
        if (value == 'yes') {
          await pause();
        } else {
          await play();
        }
        break;
      case 'volume':
        await setVolume(double.tryParse(value) ?? 100);
        break;
      case 'speed':
        await setRate(double.tryParse(value) ?? 1.0);
        break;
      case 'demuxer-max-bytes':
        _bufferSizeBytes = int.tryParse(value);
        break;
      // Not an mpv property. The heap tiers Dart derives for mpv's demuxer are the wrong
      // shape for ExoPlayer's sample allocator, so on Auto the native side sizes its own
      // LoadControl target instead of reusing `demuxer-max-bytes` (#1618).
      case 'demuxer-max-bytes-auto':
        _bufferSizeIsAuto = value != 'no';
        break;
      // Not an mpv property. mpv read-ahead is owned by the mpv.conf editor; this tier is
      // a named ExoPlayer read-ahead depth rather than a duration because the byte cap can
      // bind first (#1816).
      case 'exo-buffer-tier':
        _bufferTier = value;
        break;
      case 'tunneled-playback':
        _tunnelingEnabled = value != 'no';
        break;
      case 'content-frame-rate':
        final fps = double.tryParse(value);
        _contentFrameRate = fps != null && fps > 0 ? fps : null;
        break;
      case 'dv-conversion-mode':
        _dvConversionMode = value;
        await _applyWhenInitialized(
          () => invoke('setDvConversionMode', {'mode': value}),
          () => _dvConversionMode == value,
        );
        break;
      case 'demuxer-mode':
        _demuxerMode = value;
        await _applyWhenInitialized(() => invoke('setDemuxerMode', {'mode': value}), () => _demuxerMode == value);
        break;
      case 'sub-visibility':
        if (value == 'no') {
          if (_subtitlesHidden) break;
          _subtitlesHidden = true;
          final current = state.track.subtitle;
          _hiddenSubtitleTrackId = current != null && current.id != SubtitleTrack.off.id ? current.id : null;
          if (_hiddenSubtitleTrackId != null) {
            await _selectSubtitleTrackNatively(SubtitleTrack.off);
          }
        } else {
          if (!_subtitlesHidden) break;
          _subtitlesHidden = false;
          final storedId = _hiddenSubtitleTrackId;
          _hiddenSubtitleTrackId = null;
          final track = storedId == null ? null : state.tracks.subtitle.firstWhereOrNull((t) => t.id == storedId);
          if (track != null) {
            await _selectSubtitleTrackNatively(track);
          }
        }
        break;
      default:
        await invoke('setMpvProperty', {'name': name, 'value': value});
    }
  }

  @override
  Future<void> setAudioNormalization(bool enabled) async {
    if (disposed) return;
    _audioNormalizationEnabled = enabled;
    await _applyWhenInitialized(
      () => invoke('setAudioNormalization', {'enabled': enabled}),
      () => _audioNormalizationEnabled == enabled,
    );
    // Keep the mpv af property flowing through setMpvProperty so the plugin's
    // pendingMpvProperties replay applies loudnorm if exo falls back to mpv.
    await super.setAudioNormalization(enabled);
  }

  @override
  Future<void> setAudioDownmix({required bool enabled, required int centerBoostDb, required bool normalize}) async {
    if (disposed) return;
    _downmixEnabled = enabled;
    _downmixCenterBoostDb = centerBoostDb;
    _downmixNormalize = normalize;
    await _applyWhenInitialized(
      () => invoke('setAudioDownmix', {'enabled': enabled, 'centerBoostDb': centerBoostDb, 'normalize': normalize}),
      () => _downmixEnabled == enabled && _downmixCenterBoostDb == centerBoostDb && _downmixNormalize == normalize,
    );
    // Keep the mpv properties flowing through setMpvProperty so the plugin's
    // pendingMpvProperties replay applies downmix if exo falls back to mpv.
    await super.setAudioDownmix(enabled: enabled, centerBoostDb: centerBoostDb, normalize: normalize);
  }

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    if (disposed) return;
    _audioPassthroughEnabled = enabled;
    await _applyWhenInitialized(
      () => invoke('setAudioPassthrough', {'enabled': enabled}),
      () => _audioPassthroughEnabled == enabled,
    );
    // Deliberately no 'audio-spdif' write: unlike normalization and downmix, the
    // mpv value is not this list. mpv force-passthroughs every codec named there
    // with no decode fallback, so the plugin derives it from the audio route when
    // the fallback core starts. Queuing the raw list here would overwrite it and
    // strand TrueHD/DTS-HD on sinks that cannot bitstream them (#1703).
  }

  @override
  Future<String?> getProperty(String name) async {
    if (disposed) return null;
    switch (name) {
      case 'pause':
        return state.playing ? 'no' : 'yes';
      case 'volume':
        return state.volume.toString();
      case 'speed':
        return state.rate.toString();
      case 'time-pos':
        return (state.position.inMilliseconds / 1000.0).toString();
      case 'duration':
        return (state.duration.inMilliseconds / 1000.0).toString();
      case 'seekable':
        return state.seekable ? 'yes' : 'no';
      case 'dv-conversion-mode':
        final stats = await getStats();
        final mode = stats['dvConversionDebugMode'];
        return mode?.toString().toLowerCase();
      case 'container-fps':
        final fpsStats = await getStats();
        final fps = fpsStats['videoFps'];
        return fps?.toString();
      case 'width':
      case 'dwidth':
        final stats = await getStats();
        final width = stats['videoWidth'];
        return width?.toString();
      case 'height':
      case 'dheight':
        final stats = await getStats();
        final height = stats['videoHeight'];
        return height?.toString();
      default:
        return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    if (disposed) return {};
    try {
      final result = await invoke<Map>('getStats');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return {};
    }
  }

  /// First successful (positive) [getHeapSize] result; the device heap is
  /// immutable per process, so one channel round trip serves every caller.
  static int? _cachedHeapSizeMB;

  /// Returns the device's large heap size in MB, or 0 if unavailable (Android only).
  ///
  /// Successful positive results are memoized — the playback-open hot path asks
  /// again on every open. Failures keep returning 0 without being cached, so a
  /// transient channel error can't pin the fallback for the process lifetime.
  static Future<int> getHeapSize() async {
    final cached = _cachedHeapSizeMB;
    if (cached != null) return cached;
    try {
      final result = await _methodChannel.invokeMethod<int>('getHeapSize');
      if (result != null && result > 0) _cachedHeapSizeMB = result;
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @visibleForTesting
  static void debugResetHeapSizeCache() => _cachedHeapSizeMB = null;

  @override
  Future<String> runtimePlayerType() async {
    if (disposed) return 'unknown';
    try {
      final result = await invoke<String>('getPlayerType');
      return result ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Raw mpv commands don't apply to the ExoPlayer backend. Every command
  /// dispatched through the [Player] interface ('change-list', 'drop-buffers',
  /// 'sub-seek', 'screenshot') targets an mpv core and has always been a
  /// silent no-op here — including in the native MPV fallback mode.
  @override
  // ignore: no-empty-block - deliberate no-op, mpv commands target the mpv backend
  Future<void> command(List<String> args) async {}

  /// Apply subtitle styling to the native ExoPlayer layer.
  ///
  /// For non-ASS subtitles, applies CaptionStyleCompat (color, border, background).
  /// For ASS subtitles, applies font scale via libass setFontScale().
  @override
  Future<void> setSubtitleStyle({
    required double fontSize,
    required String textColor,
    required double borderSize,
    required String borderColor,
    required String bgColor,
    required int bgOpacity,
    int subtitlePosition = 100,
    bool bold = false,
    bool italic = false,
    bool anchorToScreen = false,
  }) async {
    if (disposed || !initialized) return;
    await invoke('setSubtitleStyle', {
      'fontSize': fontSize,
      'textColor': textColor,
      'borderSize': borderSize,
      'borderColor': borderColor,
      'bgColor': bgColor,
      'bgOpacity': bgOpacity,
      'subtitlePosition': subtitlePosition,
      'bold': bold,
      'italic': italic,
      'anchorToScreen': anchorToScreen,
    });
  }

  /// Apply the box-fit mode to the native ExoPlayer layer.
  /// Maps to AspectRatioFrameLayout resize mode: 0=FIT, 1=ZOOM, 2=FILL.
  @override
  Future<void> setBoxFitMode(int mode) async {
    if (disposed || !initialized) return;
    await invoke('setBoxFitMode', {'mode': mode});
  }

  /// Apply custom zoom to the native ExoPlayer layer.
  @override
  Future<void> setVideoZoom(double scale) async {
    if (disposed || !initialized) return;
    await invoke('setVideoZoom', {'scale': scale});
  }

  @override
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
  }) async {
    if (disposed || !initialized) return false;
    final result = await invoke<bool>('setVideoFrameRate', {
      'fps': fps,
      'duration': durationMs,
      'extraDelayMs': extraDelayMs,
      'videoWidth': videoWidth,
      'videoHeight': videoHeight,
    });
    return result ?? false;
  }

  @override
  Future<void> clearVideoFrameRate() async {
    if (disposed || !initialized) return;
    await invoke('clearVideoFrameRate');
  }

  @override
  Future<void> updateFrame() async {
    if (disposed || !initialized) return;
    await invoke('updateFrame');
  }

  @override
  Future<bool> requestAudioFocus() async {
    if (disposed) return false;
    await _ensureInitialized();
    return await invoke<bool>('requestAudioFocus') ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    if (disposed || !initialized) return;
    await invoke('abandonAudioFocus');
  }

  @override
  Future<void> setLogLevel(String level) async {
    if (disposed) return;
    await invoke('setLogLevel', {'level': level});
  }
}
