import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../../media/media_display_criteria.dart';
import '../../utils/app_logger.dart';
import '../models.dart';
import 'audio_rendering_mode.dart';
import 'player_base.dart';

typedef _AudioStateRequest = ({
  bool passthrough,
  bool normalization,
  bool downmix,
  int downmixCenterBoostDb,
  bool downmixNormalize,
  double rate,
});

typedef _AudioStateGenerations = ({int passthrough, int normalization, int downmix, int rate});

/// MPV-backed player for platforms where AetherEngine is not the native route.
class PlayerNative extends PlayerBase {
  /// Video player on the default mpv channels/core.
  PlayerNative()
    : methodChannel = const MethodChannel('com.plezy/mpv_player'),
      eventChannel = const EventChannel('com.plezy/mpv_player/events'),
      audioOnly = false;

  /// Audio-only player on the dedicated music channels/core (see
  /// [Player.audio]). Skips every video concern: no render layer
  /// ([setVisible] no-ops via [audioOnly]), no subtitle plumbing, no
  /// display-mode handling.
  PlayerNative.audio()
    : methodChannel = const MethodChannel('com.plezy/mpv_audio_player'),
      eventChannel = const EventChannel('com.plezy/mpv_audio_player/events'),
      audioOnly = true;

  String _dvConversionMode = 'auto';
  String _dvConversionLog = 'no';

  // Gapless-audio arming state (audioOnly). The native playlist is always
  // [current, next?]; these track whether entry 1 exists and what it plays.
  // _armedNextUri keeps the ORIGINAL media URI (the music service matches
  // trackTransition events against it); _armedNextFd is the content-fd claim
  // when the armed URI needed fdclose:// conversion (see _toPlayableUri).
  bool _hasArmedNext = false;
  String? _armedNextUri;
  int? _armedNextFd;

  /// Host tests aren't Android, so the content:// → fdclose:// path would be
  /// unreachable; forces the conversion regardless of platform.
  @visibleForTesting
  static bool debugForceContentFdConversion = false;

  /// Overrides the Linux video-plane detection in host tests.
  @visibleForTesting
  static bool? debugUseLinuxVideoPlane;

  /// Whether this process drives video through the Linux Wayland plane, which
  /// is `Platform.isLinux` and nothing finer — Linux has no other render path.
  ///
  /// The one place the test override is resolved, so production code and host
  /// tests agree on which path is live without reading a test-only field.
  static bool get usesLinuxVideoPlane => debugUseLinuxVideoPlane ?? Platform.isLinux;

  // Set by open() and consumed by that load's file-loaded event, so it is
  // not mistaken for a gapless advance (see _handleAudioFileLoaded).
  bool _expectOpenFileLoad = false;

  /// Whether this instance drives the audio-only core.
  final bool audioOnly;

  @override
  final MethodChannel methodChannel;

  @override
  final EventChannel eventChannel;

  @override
  String get logPrefix => audioOnly ? 'MPV-audio' : 'MPV';

  @override
  String get playerType => 'mpv';

  @override
  bool get providesNativeStats => Platform.isAndroid;

  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  /// Node properties are returned as structured maps on desktop and Apple
  /// platforms, but as JSON strings on Android.
  static final String _nodeFormat = Platform.isAndroid ? 'string' : 'node';

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

  /// Query-free tail of [uri] for logs (keeps the part id, drops tokens).
  static String _uriTail(String uri) {
    final path = uri.split('?').first;
    return path.length <= 40 ? path : '…${path.substring(path.length - 40)}';
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
        .toSet()
        .map((uri) => _escapePathListEntry(uri, separator))
        .toList();
    if (escapedUris == null || escapedUris.isEmpty) return null;

    return 'sub-files=${_fixedLengthQuote(escapedUris.join(separator))}';
  }

  /// Per-entry `http-header-fields` options for a `loadfile ... append`
  /// options arg. Every header rides its own `-append` entry because mpv's
  /// string-LIST parser splits a plain `http-header-fields=a,b` value on
  /// commas with no way to escape them — a header value containing a comma
  /// (`X-Plex-Device: Mac17,9` on Apple hardware) would be split into a
  /// colon-less garbage line that Plex rejects with 400 "Error parsing HTTP
  /// request". `-append` takes a single verbatim item; the fixed-length
  /// quote shields it from the outer key=value list split. The leading
  /// `-clr` stops the file-local list from inheriting (and duplicating) the
  /// current track's global headers set by [open].
  static String? _httpHeaderFieldsLoadfileOption(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return null;
    final appends = headers.entries
        .map((e) => 'http-header-fields-append=${_fixedLengthQuote('${e.key}: ${e.value}')}')
        .join(',');
    return 'http-header-fields-clr=,$appends';
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
  Future<void> _audioStateTail = Future<void>.value();
  Future<void>? _disposeFuture;
  bool _disposing = false;

  bool get _nativeCoreUnavailable => disposed || _disposing;

  @override
  Future<T?> invoke<T>(String method, [dynamic args]) {
    if (_nativeCoreUnavailable) return Future<T?>.value();
    return super.invoke<T>(method, args);
  }

  double _requestedRate = 1.0;

  Future<void> _ensureInitialized() async {
    if (initialized) return;
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      final result = await invoke<Object>('initialize');
      if (result != true) {
        throw Exception('Failed to initialize player');
      }
      if (_nativeCoreUnavailable) throw StateError('Player was disposed during initialization');

      // Subscribe to MPV properties before flipping `initialized` so partial
      // failures don't leave us in a half-initialized state that the memoized
      // future would falsely treat as ready.
      await observeCoreProperties(trackListFormat: _nodeFormat);
      await observeProperty('secondary-sid', 'string');
      await observeProperty('demuxer-cache-state', _nodeFormat);
      await observeProperty('audio-device-list', _nodeFormat);
      await observeProperty('audio-device', 'string');

      if (audioOnly) {
        // Debug aid only: raw playlist positions in the log trail. Gapless
        // advance DETECTION rides the file-loaded event instead — see
        // _handleAudioFileLoaded for why property edges are unreliable.
        await observeProperty('playlist-pos', _nodeFormat);
        // The Apple audio core sets this at context init; set it defensively
        // here so every mpv audio backend behaves identically. Direct invoke —
        // setProperty() would await _ensureInitialized and deadlock on the
        // memoized future of this very _doInitialize call.
        await invoke('setProperty', {'name': 'gapless-audio', 'value': 'weak'});
        // ao_audiounit requests mixWithOthers unless audio-exclusive is set,
        // and a mixable session disqualifies the app from iOS Now Playing —
        // no lock-screen/headphone controls (#1921). Same contract as the
        // video path (VideoPlayerScreen sets it at playback start). iOS-only:
        // elsewhere audio-exclusive means exclusive device access (hog-mode
        // CoreAudio on macOS, exclusive WASAPI on Windows).
        if (Platform.isIOS) {
          await invoke('setProperty', {'name': 'audio-exclusive', 'value': 'yes'});
        }
      }

      if (_nativeCoreUnavailable) throw StateError('Player was disposed during initialization');
      initialized = true;
    } catch (e) {
      _initFuture = null;
      if (!_nativeCoreUnavailable) {
        errorController.add(PlayerError('Initialization failed: $e'));
      }
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

  /// Closes a detached content fd that mpv will never consume. Fire-and-forget
  /// safe: a failure only leaks one fd.
  Future<void> _closeContentFd(int fd, {bool duringDispose = false}) async {
    try {
      if (duringDispose) {
        await super.invoke('closeContentFd', {'fd': fd});
      } else {
        await invoke('closeContentFd', {'fd': fd});
      }
    } catch (e) {
      appLogger.d('$logPrefix: closeContentFd($fd) failed', error: e);
    }
  }

  /// Converts Android SAF content:// URIs to `fdclose://<fd>` — mpv owns the fd
  /// and closes it when it opens the entry. Returns the loadfile URI and the
  /// opened fd (null when no conversion applied). [strict] throws instead of
  /// falling back to the raw URI when the fd cannot be opened: mpv cannot
  /// open content:// itself, so arming one would stall playback at the track
  /// boundary — setNext must fail loudly so the music service falls back to
  /// an explicit open.
  Future<(String, int?)> _toPlayableUri(String uri, {bool strict = false}) async {
    final convert = (Platform.isAndroid || debugForceContentFdConversion) && uri.startsWith('content://');
    if (!convert) return (uri, null);
    final fd = await _openContentFd(uri);
    if (fd == null) {
      if (strict) throw StateError('openContentFd failed for ${_uriTail(uri)}');
      return (uri, null);
    }
    return ('fdclose://$fd', fd);
  }

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    if (_nativeCoreUnavailable) return;
    await _ensureInitialized();
    if (_nativeCoreUnavailable) return;
    // `loadfile replace` (below) clears the native playlist, dropping any
    // gapless entry armed via setNext — settle its content-fd claim first.
    // No transition is surfaced: the caller is replacing playback anyway.
    await _clearArmedNext(adoptIfRolledIn: false);
    final startPosition = media.start ?? Duration.zero;
    configureTimeline(duration: timelineDuration);
    clearTracks();
    setExternalSubtitleMetadata(externalSubtitles);
    resetPlaybackProgress(startPosition);
    setSeekable(false);

    if (!audioOnly) await setVisible(true);

    // Rebuild the header list via `change-list` items — a plain
    // `setProperty('http-header-fields', joined)` splits on commas inside
    // header VALUES (`X-Plex-Device: Mac17,9` on Apple hardware), producing a
    // malformed request Plex rejects with 400. `append` takes each item
    // verbatim. Always clear first so a previous open's headers never leak
    // into header-less media.
    await command(['change-list', 'http-header-fields', 'clr', '']);
    if (media.headers != null && media.headers!.isNotEmpty) {
      for (final entry in media.headers!.entries) {
        await command(['change-list', 'http-header-fields', 'append', '${entry.key}: ${entry.value}']);
      }
    }

    // 'start' must be set before loadfile. These are playback defaults, not
    // user track selection, and mpv refuses a property write with
    // MPV_ERROR_PROPERTY_FORMAT when the value fails its option parser — the
    // same refusal that surfaces as SET_PROPERTY_FAILED on the channel. A
    // refused default must degrade to mpv's own behaviour, not abort the
    // open: the loadfile below is what actually starts playback.
    try {
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
    } catch (e) {
      appLogger.w('MPV: pre-open playback defaults not applied', error: e);
    }

    // Convert content:// URIs to fdclose:// for MPV on Android (SAF SD card
    // downloads). The immediate `loadfile replace` consumes the fd, so no
    // claim tracking is needed here (unlike setNext).
    final (uri, _) = await _toPlayableUri(media.uri);

    final loadfileArgs = ['loadfile', uri, 'replace'];
    final loadfileOption = _externalSubtitlesLoadfileOption(externalSubtitles);
    if (loadfileOption != null) {
      loadfileArgs.addAll(['-1', loadfileOption]);
    }
    if (audioOnly) _expectOpenFileLoad = true;
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
    if (_nativeCoreUnavailable) return;
    await setProperty('pause', 'no');
  }

  @override
  Future<void> pause() async {
    if (_nativeCoreUnavailable) return;
    await setProperty('pause', 'yes');
  }

  @override
  Future<void> stop() async {
    if (_nativeCoreUnavailable) return;
    // `stop` tears down the playlist without mpv opening the armed entry —
    // settle its content-fd claim first. No transition: playback is ending.
    await _clearArmedNext(adoptIfRolledIn: false);
    await command(['stop']);
    setSeekable(false);
    if (!audioOnly) await invoke('setVisible', {'visible': false});
  }

  @override
  Future<void> seek(Duration position) async {
    if (_nativeCoreUnavailable) return;
    await runSeek(position, () => command(['seek', (position.inMilliseconds / 1000.0).toString(), 'absolute']));
  }

  @override
  Future<void> setNext(Media? media) async {
    if (_nativeCoreUnavailable || !audioOnly || !initialized) return;

    await _clearArmedNext();
    if (media == null) return;

    // Let mpv open the armed entry while the current track still plays
    // (prefetch starts once the current demuxer is fully read) so the
    // network open never sits on the gapless boundary: with a boundary
    // open, any server whose connect+probe outlasts the AO's buffered
    // tail (~0.5s) produces an audible gap on every transition (#1869).
    // A failed or superseded prefetch is discarded by mpv and the entry
    // reopens normally at the boundary, so this can only remove latency.
    // Off for local arms: a prefetch would consume an fdclose:// fd while
    // playlist-pos still reads 0, breaking _clearArmedNext's "provably
    // never opened" proof (double close) — and local opens are instant
    // anyway. Set before the fd claim so a property failure cannot leak it.
    final networkArm = media.uri.startsWith('http://') || media.uri.startsWith('https://');
    await setProperty('prefetch-playlist', networkArm ? 'yes' : 'no');

    final (loadUri, fd) = await _toPlayableUri(media.uri, strict: true);

    // Per-entry options are the 4th loadfile argument on mpv >= 0.38
    // (`loadfile <url> append -1 opt=val`), exactly like open() passes
    // sub-files. `gapless-audio=weak` splices the armed entry into the
    // running audio stream when formats match.
    final args = ['loadfile', loadUri, 'append'];
    final headerOption = _httpHeaderFieldsLoadfileOption(media.headers);
    if (headerOption != null) {
      args.addAll(['-1', headerOption]);
    }
    try {
      await command(args);
    } catch (e) {
      // The entry never joined the playlist, so the fd has no consumer.
      if (fd != null) unawaited(_closeContentFd(fd));
      rethrow;
    }
    _hasArmedNext = true;
    _armedNextUri = media.uri;
    _armedNextFd = fd;
    appLogger.d('MPV-audio: armed next ${_uriTail(media.uri)}');
  }

  /// Clears the armed entry (if any), resolving the arm/advance race and the
  /// content-fd claim. mpv may have already rolled into the armed entry
  /// before this runs; blindly removing index 1 then would remove the
  /// PLAYING entry, so playlist-pos is checked first. fd ownership: mpv owns
  /// the fd from the moment it opens the entry (fdclose closes it at stream
  /// close); Dart may close only when the entry provably never opened —
  /// playlist-pos 0 both before and after a successful remove. Anything
  /// ambiguous leaks the fd (one fd, ms-wide window) rather than risk
  /// closing an fd mpv holds. The remove's success cannot be the ownership
  /// signal: Android's command bridge never surfaces mpv command failures.
  ///
  /// [adoptIfRolledIn]: when mpv already advanced into the armed entry,
  /// surface the transition here (the pending file-loaded event becomes a
  /// no-op once the flags are cleared) — without this a queue edit landing
  /// exactly at the gapless boundary desyncs the music service from the
  /// audio for the whole next track. Callers that replace or stop playback
  /// pass false: no one is listening for that entry anymore.
  Future<void> _clearArmedNext({bool adoptIfRolledIn = true, bool duringDispose = false}) async {
    if (!_hasArmedNext) return;
    final uri = _armedNextUri;
    final fd = _armedNextFd;
    _hasArmedNext = false;
    _armedNextUri = null;
    _armedNextFd = null;

    String? pos;
    try {
      pos = duringDispose
          ? await super.invoke<String>('getProperty', {'name': 'playlist-pos'})
          : await getProperty('playlist-pos');
    } catch (_) {
      // Unknown state — fall through to the remove, never close the fd.
    }
    if (pos == '1') {
      appLogger.d('MPV-audio: clear requested but armed entry already playing');
      if (adoptIfRolledIn) _completeArmedAdvance(uri);
      return;
    }

    // The handover is off: the entry is not playing and is about to be removed.
    // Anything frozen for it would otherwise outlive the arm and be preferred
    // by a later advance whose own boundary edge went missing.
    discardFrozenOutgoingPosition();
    appLogger.d('MPV-audio: clearing armed entry (playlist-remove 1)');
    try {
      if (duringDispose) {
        await super.invoke('command', {
          'args': ['playlist-remove', '1'],
        });
      } else {
        await command(['playlist-remove', '1']);
      }
    } on PlatformException {
      // Entry 1 vanished in the arm/advance race — mpv rolled into it and
      // the file-loaded handler already rebased. The fd (if any) is mpv's.
      return;
    }
    if (fd == null) return;
    String? postPos;
    try {
      postPos = duringDispose
          ? await super.invoke<String>('getProperty', {'name': 'playlist-pos'})
          : await getProperty('playlist-pos');
    } catch (_) {}
    if (pos == '0' && postPos == '0') {
      unawaited(_closeContentFd(fd, duringDispose: duringDispose));
    }
    // Any other combination is ambiguous (mpv advanced mid-clear, idle
    // playlist, property error): leak on doubt.
  }

  /// The armed entry became the playing one (mpv rolled into it): clear the
  /// arm — the fd (if any) was consumed by mpv — remove the spent entry so
  /// the playing entry rebases to index 0, and surface the transition.
  void _completeArmedAdvance(String? uri) {
    // A different source is playing now, so a seek still in flight against the
    // old one must not land its target on this one's timeline (#1819).
    takeSourceOwnership();
    _hasArmedNext = false;
    _armedNextUri = null;
    _armedNextFd = null;
    appLogger.d('MPV-audio: armed entry advanced → playlist-remove 0, ${_uriTail(uri ?? '')}');
    unawaited(_removeSpentPlaylistEntry());
    if (uri != null) trackTransitionController.add(uri);
  }

  Future<void> _removeSpentPlaylistEntry() async {
    try {
      await command(['playlist-remove', '0']);
    } catch (error, stackTrace) {
      appLogger.w('MPV-audio: failed to remove spent playlist entry', error: error, stackTrace: stackTrace);
    }
  }

  @override
  void handlePropertyChange(String name, dynamic value) {
    if (audioOnly && name == 'playlist-pos') {
      // Detection still belongs to _handleAudioFileLoaded, but this is the last
      // point ordered ahead of the new source's own position reports: they ride
      // this same property flow, while `file-loaded` rides the event flow. Take
      // the outgoing track's final position while it is still the current one.
      if (_hasArmedNext) freezeOutgoingSourcePosition();
      appLogger.d('MPV-audio: playlist-pos=$value (armed=$_hasArmedNext)');
      return;
    }
    super.handlePropertyChange(name, value);
  }

  @override
  void handlePlayerEvent(String name, Map? data) {
    if (audioOnly && name == 'file-loaded') _handleAudioFileLoaded();
    super.handlePlayerEvent(name, data);
  }

  /// Gapless auto-advance detection: a `file-loaded` that open() didn't
  /// produce while an entry is armed means mpv rolled into the armed entry.
  /// Surface the transition, then rebase the playlist so the now playing
  /// entry sits at index 0 again ([setNext] always appends at 1). The rebase
  /// only removes the spent entry behind the playing one, so it cannot
  /// disturb position/duration — those refresh with the same file-loaded.
  ///
  /// Detection deliberately rides this EVENT, not `playlist-pos` property
  /// edges: mpv coalesces observed-property notifications per observer
  /// (1→0→1 under delivery lag nets out to nothing) and the Android bridge
  /// additionally drops property changes when its shared 64-slot buffer
  /// overflows (`MutableSharedFlow.tryEmit` from the native event thread),
  /// so an edge can vanish entirely — which stalled playback at the end of
  /// the armed track. `file-loaded` fires exactly once per started file on
  /// the low-volume event flow. Clearing [_hasArmedNext] before emitting
  /// makes a hypothetical duplicate signal a no-op (it cannot double
  /// advance).
  void _handleAudioFileLoaded() {
    if (_expectOpenFileLoad) {
      _expectOpenFileLoad = false;
      appLogger.d('MPV-audio: file-loaded (open)');
      return;
    }
    if (!_hasArmedNext) {
      appLogger.d('MPV-audio: file-loaded (nothing armed, ignored)');
      return;
    }
    _completeArmedAdvance(_armedNextUri);
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) {
    final existing = _disposeFuture;
    if (existing != null) return existing;
    _disposing = true;
    final disposal = _disposeNative(preserveDisplayMode: preserveDisplayMode);
    _disposeFuture = disposal;
    return disposal;
  }

  Future<void> _disposeNative({required bool preserveDisplayMode}) async {
    if (disposed) return;
    // Settle an armed-but-unconsumed content fd before the base teardown
    // disables invoke() — the playlist is torn down without mpv ever opening
    // the entry.
    if (_hasArmedNext) {
      try {
        await _clearArmedNext(adoptIfRolledIn: false, duringDispose: true);
      } catch (_) {
        // Leak on doubt.
      }
    }
    await _audioStateTail;
    await super.dispose(preserveDisplayMode: preserveDisplayMode);
  }

  @override
  Future<void> selectAudioTrack(AudioTrack track) async {
    if (_nativeCoreUnavailable) return;
    await setProperty('aid', track.id);
  }

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    if (_nativeCoreUnavailable) return;
    await setProperty('sid', track.id);
  }

  @override
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {
    if (_nativeCoreUnavailable) return;
    await setProperty('secondary-sid', track.id);
  }

  @override
  Future<void> addSubtitleTrack({required String uri, String? title, String? language, bool select = false}) async {
    if (_nativeCoreUnavailable) return;
    final args = ['sub-add', uri, select ? 'select' : 'auto'];
    if (title != null) args.add('title=$title');
    if (language != null) args.add('lang=$language');
    await command(args);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_nativeCoreUnavailable) return;
    await setProperty('volume', volume.toString());
    if (!_nativeCoreUnavailable) setVolumeState(volume);
  }

  @override
  Future<void> setRate(double rate) {
    if (_nativeCoreUnavailable) return Future<void>.value();
    _requestedRate = rate;
    return _enqueueAudioStateReconciliation(_rateAudioField);
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async {
    if (_nativeCoreUnavailable) return;
    await setProperty('audio-device', device.name);
  }

  /// The system's resolved audio rendering mode, used for the Dolby playback
  /// badge. Apple populates `AVAudioSession.renderingMode` for CarPlay and
  /// AirPlay routes, so an Apple TV on HDMI is expected to report
  /// `notApplicable` — treat that as unknown, never as "not Dolby".
  /// Returns null on platforms without the native method.
  @override
  Future<AudioRenderingMode?> getAudioRenderingMode() async {
    if (!Platform.isIOS || _nativeCoreUnavailable) return null;
    try {
      final raw = await invoke<Map<Object?, Object?>>('getAudioRenderingMode', const {});
      if (raw == null) return null;
      return AudioRenderingMode(
        name: raw['name'] as String? ?? 'unknown',
        rawValue: (raw['rawValue'] as num?)?.toInt() ?? 0,
        route: raw['route'] as String? ?? 'none',
        outputChannels: (raw['outputChannels'] as num?)?.toInt() ?? 0,
        maxOutputChannels: (raw['maxOutputChannels'] as num?)?.toInt() ?? 0,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> setProperty(String name, String value) => _setProperty(name, value, synchronizeRate: true);

  Future<void> _setProperty(String name, String value, {required bool synchronizeRate}) async {
    if (_nativeCoreUnavailable) return;
    final updatesDvMode = (Platform.isIOS || Platform.isMacOS) && name == 'dv-conversion-mode';
    final updatesDvLog = (Platform.isIOS || Platform.isMacOS) && name == 'dv-conversion-log';
    if (updatesDvMode) value = _normalizeDvConversionMode(value);
    if (updatesDvLog) value = _normalizeBoolProperty(value);

    await _ensureInitialized();
    await invoke('setProperty', {'name': name, 'value': value});
    if (_nativeCoreUnavailable) return;
    if (updatesDvMode) _dvConversionMode = value;
    if (updatesDvLog) _dvConversionLog = value;
    if (synchronizeRate && name == 'speed') {
      final rate = double.tryParse(value);
      if (rate != null && rate.isFinite) {
        _currentRate = rate;
        _requestedRate = rate;
        final accepted = _acceptedAudioState;
        _acceptedAudioState = (
          passthrough: accepted.passthrough,
          normalization: accepted.normalization,
          downmix: accepted.downmix,
          downmixCenterBoostDb: accepted.downmixCenterBoostDb,
          downmixNormalize: accepted.downmixNormalize,
          rate: rate,
        );
      } else {
        // The native bridge may accept custom mpv speed syntax. Its numeric
        // value is unknown, so the next typed setRate must write explicitly.
        _currentRate = double.nan;
      }
    }
  }

  @override
  Future<String?> getProperty(String name) async {
    if (_nativeCoreUnavailable) return null;
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
    if (_nativeCoreUnavailable || !Platform.isAndroid) return super.getStats();
    await _ensureInitialized();
    final result = await invoke<Map>('getStats');
    return Map<String, dynamic>.from(result ?? const {});
  }

  /// mpv commands that relocate the playhead while computing their own
  /// destination, so Dart never learns where it landed up front (#1819).
  static const _playheadRelocatingCommands = {'sub-seek'};

  @override
  Future<void> command(List<String> args) async {
    if (_nativeCoreUnavailable) return;
    await _ensureInitialized();
    // Re-checked after the await: initialization can fail, or the core can be
    // torn down, while this call is suspended. Announcing a jump that no
    // command will follow would retire a consumer's pending target for nothing.
    if (_nativeCoreUnavailable) return;
    if (args.isEmpty || !_playheadRelocatingCommands.contains(args.first)) {
      await invoke('command', {'args': args});
      return;
    }

    // Claimed before the announcement so two overlapping subtitle seeks, or a
    // seek issued while this one runs, cannot both think they own the playhead.
    final token = beginPlayheadRelocation();
    // Announced before dispatch for the same reason runSeek announces its
    // request: the stale window is the round trip, not what follows it. The
    // destination is unknown at this point, hence null.
    announcePlayheadJump(null);
    await invoke('command', {'args': args});
    // The command was accepted, so the playhead has moved even if the read
    // below cannot say where. Take ownership now: an in-flight seek group
    // settling afterwards must not roll back across a cue that happened.
    commitPlayheadRelocation(token);
    // Read back where mpv actually went. `PlayerState.position` is what
    // relative seeks rebase from and its tick updates are throttled, so
    // without this a skip pressed straight after would start from the
    // pre-command position.
    //
    // Nothing is published when the read fails: guessing would hand a
    // fabricated position to consumers as authoritative. The null announced
    // before dispatch already told consumers to drop what they were holding,
    // and the backend's next tick supplies the real position.
    final seconds = double.tryParse(await invoke<String>('getProperty', {'name': 'time-pos'}) ?? '');
    if (seconds != null && seconds.isFinite && !seconds.isNegative) {
      publishPlayheadRelocation(Duration(milliseconds: (seconds * 1000).round()), token: token);
    }
  }

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => Platform.isAndroid;

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {
    if (_nativeCoreUnavailable || audioOnly || !Platform.isIOS) return;
    await _ensureInitialized();
    await invoke('setDisplayCriteria', {
      'criteria': _effectiveDisplayCriteria(criteria)?.toJson(),
      'extraDelayMs': extraDelayMs,
    });
  }

  @override
  Future<void> setLogLevel(String level) async {
    if (_nativeCoreUnavailable) return;
    await _ensureInitialized();
    await invoke('setLogLevel', {'level': level});
  }

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    if (_nativeCoreUnavailable) return false;
    final changed = await super.setVisible(visible, restoreOnWindowVisible: restoreOnWindowVisible);
    return changed && !_nativeCoreUnavailable;
  }

  static const int _passthroughAudioField = 1 << 0;
  static const int _normalizationAudioField = 1 << 1;
  static const int _downmixAudioField = 1 << 2;
  static const int _rateAudioField = 1 << 3;

  bool _passthroughRequested = false;
  bool _passthroughActive = false;
  bool _normalizationRequested = false;
  bool _normalizationActive = false;
  bool _downmixRequested = false;
  bool _downmixActive = false;
  int _downmixCenterBoostDb = 0;
  int _activeDownmixCenterBoostDb = 0;
  bool _downmixNormalize = false;
  bool _activeDownmixNormalize = false;
  double _currentRate = 1.0;
  int _passthroughGeneration = 0;
  int _normalizationGeneration = 0;
  int _downmixGeneration = 0;
  int _rateGeneration = 0;
  _AudioStateRequest _acceptedAudioState = const (
    passthrough: false,
    normalization: false,
    downmix: false,
    downmixCenterBoostDb: 0,
    downmixNormalize: false,
    rate: 1.0,
  );

  @override
  bool get audioPassthroughActive => _passthroughActive;

  /// Codecs the platform can take as a bitstream. On iOS/tvOS compressed
  /// audio goes through the system renderer, which only handles Dolby
  /// Digital (Plus); desktop does real device passthrough for the full list.
  static final String _passthroughCodecs = Platform.isIOS ? 'ac3,eac3' : 'ac3,eac3,dts,dts-hd,truehd';

  _AudioStateRequest get _requestedAudioState => (
    passthrough: _passthroughRequested,
    normalization: _normalizationRequested,
    downmix: _downmixRequested,
    downmixCenterBoostDb: _downmixCenterBoostDb,
    downmixNormalize: _downmixNormalize,
    rate: _requestedRate,
  );

  _AudioStateRequest _rebaseAudioState(_AudioStateRequest accepted, _AudioStateRequest requested, int fields) => (
    passthrough: fields & _passthroughAudioField != 0 ? requested.passthrough : accepted.passthrough,
    normalization: fields & _normalizationAudioField != 0 ? requested.normalization : accepted.normalization,
    downmix: fields & _downmixAudioField != 0 ? requested.downmix : accepted.downmix,
    downmixCenterBoostDb: fields & _downmixAudioField != 0
        ? requested.downmixCenterBoostDb
        : accepted.downmixCenterBoostDb,
    downmixNormalize: fields & _downmixAudioField != 0 ? requested.downmixNormalize : accepted.downmixNormalize,
    rate: fields & _rateAudioField != 0 ? requested.rate : accepted.rate,
  );

  void _restoreFailedRequestedFields(_AudioStateRequest previous, int fields, _AudioStateGenerations generations) {
    if (fields & _passthroughAudioField != 0 && generations.passthrough == _passthroughGeneration) {
      _passthroughRequested = previous.passthrough;
    }
    if (fields & _normalizationAudioField != 0 && generations.normalization == _normalizationGeneration) {
      _normalizationRequested = previous.normalization;
    }
    if (fields & _downmixAudioField != 0 && generations.downmix == _downmixGeneration) {
      _downmixRequested = previous.downmix;
      _downmixCenterBoostDb = previous.downmixCenterBoostDb;
      _downmixNormalize = previous.downmixNormalize;
    }
    if (fields & _rateAudioField != 0 && generations.rate == _rateGeneration) {
      _requestedRate = previous.rate;
    }
  }

  Future<void> _enqueueAudioStateReconciliation(int fields) {
    final requested = _requestedAudioState;
    if (fields & _passthroughAudioField != 0) ++_passthroughGeneration;
    if (fields & _normalizationAudioField != 0) ++_normalizationGeneration;
    if (fields & _downmixAudioField != 0) ++_downmixGeneration;
    if (fields & _rateAudioField != 0) ++_rateGeneration;
    final generations = (
      passthrough: _passthroughGeneration,
      normalization: _normalizationGeneration,
      downmix: _downmixGeneration,
      rate: _rateGeneration,
    );
    final operation = _audioStateTail.then((_) => _reconcileAudioState(requested, fields, generations));
    _audioStateTail = operation.catchError((Object _, StackTrace _) {});
    return operation;
  }

  Future<void> _reconcileAudioState(
    _AudioStateRequest requested,
    int fields,
    _AudioStateGenerations generations,
  ) async {
    if (_nativeCoreUnavailable) return;
    final previous = _acceptedAudioState;
    final target = _rebaseAudioState(previous, requested, fields);
    try {
      await _applyAudioState(target);
      if (_nativeCoreUnavailable) return;
      _acceptedAudioState = target;
    } catch (error, stackTrace) {
      try {
        await _applyAudioState(
          previous,
          forceDownmix: fields & _downmixAudioField != 0,
          forceNormalization: fields & _downmixAudioField != 0,
        );
      } catch (rollbackError, rollbackStackTrace) {
        appLogger.e(
          'MPV: failed to restore accepted audio state',
          error: rollbackError,
          stackTrace: rollbackStackTrace,
        );
      }
      _restoreFailedRequestedFields(previous, fields, generations);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _applyAudioState(
    _AudioStateRequest target, {
    bool forceDownmix = false,
    bool forceNormalization = false,
  }) async {
    if (_nativeCoreUnavailable) return;
    final passthroughShouldBeActive = target.passthrough && target.rate == 1.0 && !target.downmix;

    // mpv cannot scaletempo compressed audio and filters cannot process a
    // bitstream. Always leave passthrough before applying either state.
    if (_passthroughActive && !passthroughShouldBeActive) {
      await _applyPassthrough(false);
    }
    if (_currentRate != target.rate) {
      await _setProperty('speed', target.rate.toString(), synchronizeRate: false);
      _currentRate = target.rate;
    }
    if (forceDownmix ||
        _downmixActive != target.downmix ||
        (target.downmix &&
            (_activeDownmixCenterBoostDb != target.downmixCenterBoostDb ||
                _activeDownmixNormalize != target.downmixNormalize))) {
      await super.setAudioDownmix(
        enabled: target.downmix,
        centerBoostDb: target.downmixCenterBoostDb,
        normalize: target.downmixNormalize,
      );
      _downmixActive = target.downmix;
      _activeDownmixCenterBoostDb = target.downmixCenterBoostDb;
      _activeDownmixNormalize = target.downmixNormalize;
    }
    final normalizationShouldBeActive = target.normalization && !passthroughShouldBeActive;
    if (forceNormalization || _normalizationActive != normalizationShouldBeActive) {
      await super.setAudioNormalization(normalizationShouldBeActive);
      _normalizationActive = normalizationShouldBeActive;
    }
    if (passthroughShouldBeActive && !_passthroughActive) {
      await _applyPassthrough(true);
    }
  }

  @override
  Future<void> setAudioPassthrough(bool enabled) {
    if (_nativeCoreUnavailable) return Future<void>.value();
    _passthroughRequested = enabled;
    return _enqueueAudioStateReconciliation(_passthroughAudioField);
  }

  Future<void> _applyPassthrough(bool enabled) async {
    await setProperty('audio-spdif', enabled ? _passthroughCodecs : '');
    if (_nativeCoreUnavailable) return;

    // audio-spdif is the authoritative transition. Publish only after mpv
    // accepts it; audio-exclusive below is an independent device-mode hint.
    _passthroughActive = enabled;
    // audio-exclusive redirects coreaudio to coreaudio_exclusive on macOS
    // (and exclusive WASAPI on Windows); on iOS/tvOS it is set once at
    // playback start and must not be clobbered here.
    if (!Platform.isIOS) {
      try {
        await setProperty('audio-exclusive', enabled ? 'yes' : 'no');
      } catch (error, stackTrace) {
        appLogger.w('MPV: failed to update exclusive-audio hint', error: error, stackTrace: stackTrace);
      }
    }
  }

  @override
  Future<void> setAudioNormalization(bool enabled) {
    if (_nativeCoreUnavailable) return Future<void>.value();
    _normalizationRequested = enabled;
    return _enqueueAudioStateReconciliation(_normalizationAudioField);
  }

  @override
  Future<void> setAudioDownmix({required bool enabled, required int centerBoostDb, required bool normalize}) {
    if (_nativeCoreUnavailable) return Future<void>.value();
    _downmixRequested = enabled;
    _downmixCenterBoostDb = centerBoostDb;
    _downmixNormalize = normalize;
    return _enqueueAudioStateReconciliation(_downmixAudioField);
  }

  @override
  Future<void> updateFrame() async {
    if (_nativeCoreUnavailable || !initialized) return;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      await invoke('updateFrame');
    }
  }

  /// iOS/tvOS scale the native video container instead of mpv's `video-zoom`:
  /// on the avfoundation VO a nonzero zoom re-renders every frame through
  /// Core Image, which destroys HDR/Dolby Vision passthrough (DV renders
  /// near-black on tvOS). macOS keeps the property path — gpu-next zooms
  /// losslessly in-shader.
  @override
  Future<void> setVideoZoom(double scale) async {
    if (_nativeCoreUnavailable || audioOnly || !Platform.isIOS || !initialized) return;
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
    if (_nativeCoreUnavailable || !Platform.isAndroid || !initialized) return false;
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
    if (_nativeCoreUnavailable || !Platform.isAndroid || !initialized) return;
    await invoke('clearVideoFrameRate');
  }

  @override
  Future<bool> requestAudioFocus() async {
    if (_nativeCoreUnavailable) return false;
    if (!Platform.isAndroid) return true;
    await _ensureInitialized();
    return await invoke<bool>('requestAudioFocus') ?? false;
  }

  @override
  Future<void> abandonAudioFocus() async {
    if (_nativeCoreUnavailable || !Platform.isAndroid || !initialized) return;
    await invoke('abandonAudioFocus');
  }

  /// See [Player.isHdrOutputSupported] for why this is a query and not a constant.
  ///
  /// Only Linux delegates to the native side, because only there does the answer
  /// move: it folds in the output the plane currently sits on. Everywhere else it
  /// is a platform constant. Windows has a native query of its own, but nothing
  /// consults this method there - the settings sheet offers HDR on Windows
  /// unconditionally - so asking would only let the two disagree about the same
  /// platform. Nothing is cached on either path.
  @override
  Future<bool> isHdrOutputSupported() async {
    // No video plane without video, on any platform, so this precedes the
    // platform question rather than sitting inside one branch of it.
    if (_nativeCoreUnavailable || audioOnly) return false;
    // Asked through usesLinuxVideoPlane, not Platform.isLinux, so this and the
    // settings sheet's _probesHdrSupport resolve the same way under the test
    // override; on a real Linux host the two are the same answer.
    if (usesLinuxVideoPlane) return await invoke<bool>('isHDRSupported') ?? false;
    return Platform.isIOS || Platform.isMacOS || Platform.isWindows;
  }
}
