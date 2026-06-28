import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../media/media_display_criteria.dart';
import '../models.dart';
import 'player_base.dart';

/// MPV-backed player for platforms where AetherEngine is not the native route.
class PlayerNative extends PlayerBase {
  int? _textureIdValue;
  String _dvConversionMode = 'auto';
  String _dvConversionLog = 'no';

  @override
  int? get textureId => _textureIdValue;

  static const _methodChannel = MethodChannel('com.plezy/mpv_player');
  static const _eventChannel = EventChannel('com.plezy/mpv_player/events');

  @override
  MethodChannel get methodChannel => _methodChannel;

  @override
  EventChannel get eventChannel => _eventChannel;

  @override
  String get logPrefix => 'MPV';

  @override
  String get playerType => 'mpv';

  @override
  bool get providesNativeStats => Platform.isAndroid;

  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  /// Node properties are returned as structured maps on macOS/iOS/Linux,
  /// but as JSON strings on Android/Windows.
  static final String _nodeFormat = (Platform.isAndroid || Platform.isWindows) ? 'string' : 'node';

  static String _normalizeDvConversionMode(String value) {
    return switch (value.toLowerCase()) {
      'disabled' || 'native' => 'disabled',
      'dv81' || 'p8' || 'p7_to_p8' || 'p7-to-p8' => 'dv81',
      'hevc' || 'hevc_strip' || 'p7_to_hevc' || 'p7-to-hevc' => 'hevc_strip',
      _ => 'auto',
    };
  }

  static String _normalizeBoolProperty(String value) {
    return switch (value.toLowerCase()) {
      '1' || 'true' || 'yes' || 'on' => 'yes',
      _ => 'no',
    };
  }

  static String _fixedLengthQuote(String value) {
    return '%${utf8.encode(value).length}%$value';
  }

  static String _escapePathListEntry(String value, String separator) {
    return value.replaceAll(r'\', r'\\').replaceAll(separator, '\\$separator');
  }

  static String? _externalSubtitlesLoadfileOption(List<SubtitleTrack>? externalSubtitles) {
    final separator = Platform.isWindows ? ';' : ':';
    final escapedUris = externalSubtitles
        ?.map((subtitle) => subtitle.uri)
        .whereType<String>()
        .where((uri) => uri.isNotEmpty)
        .map((uri) => _escapePathListEntry(uri, separator))
        .toList();
    if (escapedUris == null || escapedUris.isEmpty) return null;

    return 'sub-files=${_fixedLengthQuote(escapedUris.join(separator))}';
  }

  MediaDisplayCriteria? _effectiveDisplayCriteria(MediaDisplayCriteria? criteria) {
    if (criteria == null || (criteria.doviProfile ?? 0) != 7) return criteria;

    final convertToDv81 = _dvConversionMode == 'auto' || _dvConversionMode == 'dv81';
    if (convertToDv81) {
      return MediaDisplayCriteria(
        fps: criteria.fps,
        width: criteria.width,
        height: criteria.height,
        doviProfile: 8,
        doviLevel: criteria.doviLevel,
        doviCompatibilityId: 1,
        transfer: criteria.transfer ?? 'smpte2084',
        primaries: criteria.primaries ?? 'bt2020',
        matrix: criteria.matrix ?? 'bt2020nc',
      );
    }

    return MediaDisplayCriteria(
      fps: criteria.fps,
      width: criteria.width,
      height: criteria.height,
      doviProfile: 0,
      doviCompatibilityId: criteria.doviCompatibilityId ?? 1,
      transfer: criteria.transfer ?? 'smpte2084',
      primaries: criteria.primaries ?? 'bt2020',
      matrix: criteria.matrix ?? 'bt2020nc',
    );
  }

  // Memoizes the in-flight init Future so concurrent callers (e.g. the
  // parallel `requestAudioFocus()` and `setProperty()` paths kicked off in
  // VideoPlayerScreen._initializePlayer) share one `invoke('initialize')`.
  // Two concurrent invokes on Android caused MpvPlayerPlugin.handleInitialize
  // to dispose-and-recreate the in-flight core, hanging playback (#930).
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() async {
    if (initialized) return;
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      final result = await invoke<Object>('initialize');
      final bool ok;
      if (result is int) {
        // Linux: initialize returns the texture ID
        _textureIdValue = result;
        ok = true;
      } else {
        ok = result == true;
      }
      if (!ok) {
        throw Exception('Failed to initialize player');
      }

      // Subscribe to MPV properties before flipping `initialized` so partial
      // failures don't leave us in a half-initialized state that the memoized
      // future would falsely treat as ready.
      await observeCoreProperties(trackListFormat: _nodeFormat);
      await observeProperty('secondary-sid', 'string');
      await observeProperty('demuxer-cache-state', _nodeFormat);
      await observeProperty('audio-device-list', _nodeFormat);
      await observeProperty('audio-device', 'string');

      initialized = true;
    } catch (e) {
      _initFuture = null;
      errorController.add(PlayerError('Initialization failed: $e'));
      rethrow;
    }
  }

  Future<int?> _openContentFd(String contentUri) async {
    try {
      return await invoke<int>('openContentFd', {'uri': contentUri});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration timelineOffset = Duration.zero,
    Duration? timelineDuration,
  }) async {
    if (disposed) return;
    await _ensureInitialized();
    final startPosition = media.start ?? Duration.zero;
    configureTimeline(offset: timelineOffset, duration: timelineDuration);
    clearTracks();
    setExternalSubtitleMetadata(externalSubtitles);
    resetPlaybackProgress(startPosition);
    setSeekable(false);

    await setVisible(true);

    if (media.headers != null && media.headers!.isNotEmpty) {
      final headerList = media.headers!.entries.map((e) => '${e.key}: ${e.value}').toList();
      await setProperty('http-header-fields', headerList.join(','));
    }

    // 'start' must be set before loadfile.
    if (startPosition.inSeconds > 0) {
      await setProperty('start', (startPosition.inMilliseconds / 1000.0).toString());
    } else {
      await setProperty('start', 'none');
    }

    // Prevents race condition that can freeze the video decoder on Android (issue #226).
    if (!play) {
      await setProperty('pause', 'yes');
    }

    // Prevent mpv's own default subtitle selection from racing the
    // server-backed TrackManager decision applied after tracks are discovered.
    await setProperty('sid', 'no');
    await setProperty('secondary-sid', 'no');

    // Convert content:// URIs to fdclose:// for MPV on Android (SAF SD card downloads)
    var uri = media.uri;
    if (Platform.isAndroid && uri.startsWith('content://')) {
      final fd = await _openContentFd(uri);
      if (fd != null) {
        uri = 'fdclose://$fd';
      }
    }

    final loadfileArgs = ['loadfile', uri, 'replace'];
    final loadfileOption = _externalSubtitlesLoadfileOption(externalSubtitles);
    if (loadfileOption != null) {
      loadfileArgs.addAll(['-1', loadfileOption]);
    }
    await command(loadfileArgs);

    // mpv's pause property survives loadfile; in-place reloads pause the old
    // file before resolving, so explicitly unpause for the replacement. Set
    // after loadfile so the paused old file never audibly unpauses
    // pre-replace.
    if (play) {
      await setProperty('pause', 'no');
    }
  }

  @override
  Future<void> play() async {
    await setProperty('pause', 'no');
  }

  @override
  Future<void> pause() async {
    await setProperty('pause', 'yes');
  }

  @override
  Future<void> stop() async {
    await command(['stop']);
    setSeekable(false);
    await invoke('setVisible', {'visible': false});
  }

  @override
  Future<void> seek(Duration position) async {
    final sourcePosition = sourceSeekPosition(position);
    await runSeek(position, () => command(['seek', (sourcePosition.inMilliseconds / 1000.0).toString(), 'absolute']));
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    await setProperty('aid', track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    await setProperty('sid', track.id);
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {
    await setProperty('secondary-sid', track.id);
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    final args = ['sub-add', uri, select ? 'select' : 'auto'];
    if (title != null) args.add('title=$title');
    if (language != null) args.add('lang=$language');
    await command(args);
  }

  @override
  Future<void> setVolume(double volume) async {
    await setProperty('volume', volume.toString());
    if (!disposed) setVolumeState(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    // mpv cannot scaletempo compressed (spdif) audio and silently keeps
    // playing at 1x, so suspend passthrough while the rate is not 1.0.
    _currentRate = rate;
    if (_passthroughActive && rate != 1.0) {
      await _applyPassthrough(false);
    }
    await setProperty('speed', rate.toString());
    if (_passthroughRequested && !_passthroughActive && rate == 1.0) {
      await _applyPassthrough(true);
    }
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    await setProperty('audio-device', device.name);
  }

  @override
  Future<void> setProperty(String name, String value) async {
    if (disposed) return;
    if ((Platform.isIOS || Platform.isMacOS) && name == 'dv-conversion-mode') {
      value = _normalizeDvConversionMode(value);
      _dvConversionMode = value;
    }
    if ((Platform.isIOS || Platform.isMacOS) && name == 'dv-conversion-log') {
      value = _normalizeBoolProperty(value);
      _dvConversionLog = value;
    }
    await _ensureInitialized();
    await invoke('setProperty', {'name': name, 'value': value});
  }

  @override
  Future<String?> getProperty(String name) async {
    if (disposed) return null;
    if ((Platform.isIOS || Platform.isMacOS) && name == 'dv-conversion-mode') {
      return _dvConversionMode;
    }
    if ((Platform.isIOS || Platform.isMacOS) && name == 'dv-conversion-log') {
      return _dvConversionLog;
    }
    await _ensureInitialized();
    return await invoke<String>('getProperty', {'name': name});
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    if (disposed || !Platform.isAndroid) return super.getStats();
    await _ensureInitialized();
    final result = await invoke<Map>('getStats');
    return Map<String, dynamic>.from(result ?? const {});
  }

  @override
  Future<void> command(List<String> args) async {
    if (disposed) return;
    await _ensureInitialized();
    await invoke('command', {'args': args});
  }

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => Platform.isAndroid;

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {
    if (disposed || !Platform.isIOS) return;
    await _ensureInitialized();
    await invoke('setDisplayCriteria', {
      'criteria': _effectiveDisplayCriteria(criteria)?.toJson(),
      'extraDelayMs': extraDelayMs,
    });
  }

  @override
  Future<void> setLogLevel(String level) async {
    if (disposed) return;
    await _ensureInitialized();
    await invoke('setLogLevel', {'level': level});
  }

  bool _passthroughRequested = false;
  bool _passthroughActive = false;
  double _currentRate = 1.0;

  @override
  bool get audioPassthroughActive => _passthroughActive;

  /// Codecs the platform can take as a bitstream. On iOS/tvOS compressed
  /// audio goes through the system renderer, which only handles Dolby
  /// Digital (Plus); desktop does real device passthrough for the full list.
  static final String _passthroughCodecs = Platform.isIOS ? 'ac3,eac3' : 'ac3,eac3,dts,dts-hd,truehd';

  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    _passthroughRequested = enabled;
    // Deferred until the rate returns to 1.0 (see setRate).
    if (enabled && _currentRate != 1.0) return;
    await _applyPassthrough(enabled);
  }

  Future<void> _applyPassthrough(bool enabled) async {
    _passthroughActive = enabled;
    await setProperty('audio-spdif', enabled ? _passthroughCodecs : '');
    // audio-exclusive redirects coreaudio to coreaudio_exclusive on macOS
    // (and exclusive WASAPI on Windows); on iOS/tvOS it is set once at
    // playback start and must not be clobbered here.
    if (!Platform.isIOS) {
      await setProperty('audio-exclusive', enabled ? 'yes' : 'no');
    }
  }

  @override
  Future<void> updateFrame() async {
    if (disposed || !initialized) return;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      await invoke('updateFrame');
    }
  }

  @override
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
  }) async {
    if (!Platform.isAndroid || disposed || !initialized) return false;
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
    if (!Platform.isAndroid || disposed || !initialized) return;
    await invoke('clearVideoFrameRate');
  }

  @override
  Future<bool> requestAudioFocus() async {
    if (disposed) return false;
    if (!Platform.isAndroid) return true;
    await _ensureInitialized();
    return await invoke<bool>('requestAudioFocus') ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    if (!Platform.isAndroid || disposed || !initialized) return;
    await invoke('abandonAudioFocus');
  }
}
