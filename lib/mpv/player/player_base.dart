import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier, listEquals, protected, visibleForTesting;
import 'package:flutter/services.dart';

import '../../media/media_display_criteria.dart';
import '../../utils/app_logger.dart';
import '../../utils/track_label_builder.dart';
import '../font_loader.dart';
import '../models.dart';
import 'mpv_node_decoder.dart';
import 'audio_rendering_mode.dart';
import 'player.dart';
import 'player_state.dart';
import 'player_stream_controllers.dart';
import 'player_streams.dart';

/// Abstract base class for player implementations.
///
/// This class contains shared logic for both [PlayerAndroid] (ExoPlayer)
/// and [PlayerNative] (MPV) implementations, including:
/// - State management
/// - Stream controller setup
/// - Event handling infrastructure
/// - Property change handlers
/// - Track parsing and selection
/// - Common lifecycle methods
abstract class PlayerBase with PlayerStreamControllersMixin implements Player {
  PlayerState _state = const PlayerState();

  /// The Flutter GL texture id published by the platform when video is
  /// composited as a texture (the Linux SDR fallback path). Null everywhere
  /// else and before publication; [video.dart] keys its render surface off it.
  final ValueNotifier<int?> _textureId = ValueNotifier<int?>(null);

  int? get textureId => _textureId.value;

  /// Listenable form of [textureId] for widgets that rebuild on publication.
  ValueListenable<int?> get textureIdListenable => _textureId;

  /// Publishes (or clears) the Flutter texture id backing this player.
  @protected
  void setTextureId(int? value) {
    if (!_disposed) _textureId.value = value;
  }

  @override
  PlayerState get state => _state;

  @override
  Duration get currentPosition => Duration(milliseconds: _positionMs);

  @override
  bool get audioPassthroughActive => false;

  /// Gapless-audio arming — meaningful only on the audio players, which
  /// override this. Video backends ignore it.
  @override
  Future<void> setNext(Media? media) async {}

  late final PlayerStreams _streams;

  @override
  PlayerStreams get streams => _streams;

  StreamSubscription? _eventSubscription;
  StreamSubscription? _logSubscription;
  bool _disposed = false;
  late final Future<void>? _nativeOwnershipReady;
  final Completer<void> _nativeRelease = Completer<void>();
  final _throttleSw = Stopwatch()..start();
  int _lastEmitMs = 0;
  int _lastCacheStateMs = 0;
  int _positionMs = 0;

  /// Overlapping-seek bookkeeping. Each [runSeek] optimistically writes its own
  /// target, so only the last of a group to settle can tell where the backend
  /// actually left the playhead — and because the backend applies commands in
  /// the order they were issued, "which one landed" is decided by request
  /// order, not by which reply came back first.
  ///
  /// A playhead move from outside [runSeek] detaches the active group: it is
  /// newer information than any of that group's outcomes, and seeks starting
  /// after it belong to a fresh group anchored where it left the playhead.
  /// Issue-time id for anything that asks the playhead to move — a seek
  /// request, a relocation claim, a source install. Monotonic, so it also
  /// orders [runSeek] calls inside a group.
  int _playheadOperations = 0;

  /// The newest operation the backend actually accepted. A completion may only
  /// speak for the playhead while nothing newer has been accepted; asking is
  /// not owning, so a rejected request never silences an accepted one.
  int _acceptedOperation = 0;

  /// A relocation whose destination arrived while a newer seek was still in
  /// flight. Held rather than published: that seek will define the playhead if
  /// it lands, and this is still the truth if it does not.
  ({int token, Duration? position})? _deferredRelocation;

  /// Which operation last wrote a position into state. Compared by identity,
  /// not by value: a successor seeking to the same timestamp is still a
  /// different write and must not be repaired away by its predecessor.
  int _lastPositionWriter = 0;

  /// Stands in for the backend in [_lastPositionWriter]: a reported position is
  /// authoritative and beats anything Dart wrote optimistically, whatever its
  /// value happens to be.
  static const int _backendReportedWriter = -1;

  _SeekGroup? _activeSeekGroup;

  @override
  Duration? get outgoingSourcePosition => _outgoingSourcePosition;
  Duration? _outgoingSourcePosition;

  /// The last position the backend reported *for the source now playing*, as
  /// distinct from [_positionMs], which also carries Dart's optimistic writes.
  /// Only an observation can say where a source actually got to, and an
  /// observation of one source says nothing about the next — so installing a
  /// source clears this rather than letting it carry over.
  int _lastReportedPositionMs = 0;

  /// Set by [freezeOutgoingSourcePosition] when a source boundary is seen on
  /// the same flow that carries position reports. Preferred by
  /// [takeSourceOwnership], which cannot make that ordering guarantee itself.
  int? _frozenOutgoingPositionMs;

  /// Wall-clock slack added to a seek's flight time before converting to media
  /// time, absorbing tick granularity and clock jitter.
  static const _landedProgressSlack = Duration(milliseconds: 250);

  /// Claim the playhead for a relocation whose destination the backend has not
  /// reported yet, and take the token that says so.
  ///
  /// Claiming is what makes two overlapping relocations distinguishable:
  /// reading a shared revision would let them both think they still speak for
  /// the playhead.
  ///
  /// Claiming alone changes nothing else. A command that is then rejected never
  /// moved the playhead, so an in-flight seek group stays authoritative and
  /// reconciles its own outcome. A command that is accepted hands the token to
  /// [commitPlayheadRelocation], which takes ownership even when the
  /// destination cannot be read back, and then to [publishPlayheadRelocation]
  /// when there is a destination to report.
  @protected
  int beginPlayheadRelocation() => ++_playheadOperations;

  /// Record that a claimed relocation actually moved the playhead, even though
  /// its destination could not be read back.
  ///
  /// Unknown movement is still movement: an in-flight seek group settling
  /// afterwards must not roll back across it, so ownership passes here while
  /// the position itself waits for the backend's next tick.
  @protected
  void commitPlayheadRelocation(int token) {
    if (_disposed || token < _acceptedOperation) return;
    _takeOperationOwnership(token);
    // A newer seek is still in flight: keep its group so it can arbitrate
    // against this relocation when it resolves. Recorded without a destination,
    // because an accepted command moved the playhead whether or not its
    // position can be read — the group must not roll back across it.
    if (_hasUnresolvedSeekNewerThan(token)) {
      _deferredRelocation = (token: token, position: null);
      return;
    }
    // The claim already made this token the owner; taking the playhead from the
    // seek group is all that is left. The token stays valid so the same
    // relocation can still publish a destination once it reads one back.
    _activeSeekGroup = null;
  }

  Duration? _timelineDuration;
  int _nextPropId = 0;
  final Map<int, String> _propIdToName = {};
  Map<String, List<SubtitleTrack>> _externalSubtitleMetadataByUri = const {};
  bool _primaryMediaLoadStarted = false;
  bool _primaryMediaReadyEmitted = false;

  /// How long a disposing player waits for its predecessor's native release
  /// before force-disposing with its own [nativeInstanceId] (the native side
  /// no-ops a stale token, so this can never tear down a successor's core).
  @visibleForTesting
  static Duration debugNativeOwnershipDisposeTimeout = const Duration(seconds: 3);

  /// How long a command waits for a predecessor's native release before
  /// giving up. Longer than the dispose-side wait: a slow but healthy
  /// teardown should delay the next session's first command, not fail it.
  @visibleForTesting
  static Duration debugNativeOwnershipInvokeTimeout = const Duration(seconds: 8);

  /// Identifies this instance to the native side across `initialize` and
  /// `dispose`, so a dispose that lost the ownership race is provably stale
  /// and can be sent anyway instead of being skipped. Skipping is what used
  /// to leave a hung predecessor's release chained forever (the permanent
  /// "Playback could not be started" wedge).
  static int _nativeInstanceCounter = 0;
  final int nativeInstanceId = ++_nativeInstanceCounter;

  static const _maximumDurationMilliseconds = 9223372036854775;

  static double? _finiteDouble(Object? value) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }

  static int? _millisecondsFromSeconds(Object? value, {bool round = false}) {
    final seconds = _finiteDouble(value);
    if (seconds == null) return null;
    final milliseconds = seconds * Duration.millisecondsPerSecond;
    if (!milliseconds.isFinite ||
        milliseconds < -_maximumDurationMilliseconds ||
        milliseconds > _maximumDurationMilliseconds) {
      return null;
    }
    return round ? milliseconds.round() : milliseconds.toInt();
  }

  static int? _finiteInt(Object? value) {
    if (value is int) return value;
    final result = _finiteDouble(value);
    if (result == null || result < -9007199254740991 || result > 9007199254740991) return null;
    return result.toInt();
  }

  @protected
  bool initialized = false;

  @override
  bool get disposed => _disposed;

  MethodChannel get methodChannel;

  EventChannel get eventChannel;

  String get logPrefix;

  PlayerBase() {
    _nativeOwnershipReady = _eventChannelOwners[eventChannel.name]?._nativeRelease.future;
    _streams = createStreams();
    _setupEventListener();
    _logSubscription = logController.stream.listen(_forwardToAppLogger);
  }

  void _forwardToAppLogger(PlayerLog log) {
    final message = '[$logPrefix:${log.prefix}] ${log.text}'.trimRight();
    switch (log.level) {
      case PlayerLogLevel.fatal:
      case PlayerLogLevel.error:
        appLogger.e(message);
      case PlayerLogLevel.warn:
        appLogger.w(message);
      case PlayerLogLevel.info:
      case PlayerLogLevel.verbose:
        appLogger.i(message);
      case PlayerLogLevel.debug:
      case PlayerLogLevel.trace:
        appLogger.d(message);
    }
  }

  /// Backends expose static per-backend [EventChannel]s, so two overlapping
  /// instances (episode handoff, quick exit/reopen) share one channel name.
  /// The engine allows a single active stream per channel: a newer instance's
  /// listen displaces the older sink, and the older instance's late cancel
  /// would then tear down the *newer* stream — leaving it eventless — while
  /// the final cancel gets an engine "No active stream to cancel" error.
  /// Only the instance recorded here may send the native cancel.
  static final Map<String, PlayerBase> _eventChannelOwners = {};

  void _setupEventListener() {
    _eventChannelOwners[eventChannel.name] = this;
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        if (_disposed) return;
        errorController.add(PlayerError(error.toString()));
      },
    );
  }

  /// The (name, format) registrations every backend makes at init — the
  /// properties [handlePropertyChange] needs for core [PlayerState].
  /// `track-list` is registered separately because mpv uses node format on
  /// Apple platforms; backend-specific extras (mpv: secondary-sid /
  /// demuxer-cache-state / audio-device*; ExoPlayer: demuxer-cache-time)
  /// are appended by the subclasses.
  static const List<(String, String)> corePropertyObservations = [
    ('time-pos', 'double'),
    ('duration', 'double'),
    ('seekable', 'flag'),
    ('pause', 'flag'),
    ('paused-for-cache', 'flag'),
    ('eof-reached', 'flag'),
    ('volume', 'double'),
    ('speed', 'double'),
    ('aid', 'string'),
    ('sid', 'string'),
  ];

  /// Register [corePropertyObservations] plus `track-list` in the
  /// backend's preferred format. Called from each subclass's initialize.
  @protected
  Future<void> observeCoreProperties({required String trackListFormat}) async {
    for (final (name, format) in corePropertyObservations) {
      await observeProperty(name, format);
    }
    await observeProperty('track-list', trackListFormat);
  }

  @protected
  Future<void> observeProperty(String name, String format) async {
    final propId = _nextPropId++;
    _propIdToName[propId] = name;
    await invoke('observeProperty', {'name': name, 'format': format, 'id': propId});
  }

  void _handleEvent(dynamic event) {
    if (_disposed) return;
    if (event is List && event.length == 2) {
      final propertyId = event.first;
      if (propertyId is! int) return;
      final name = _propIdToName[propertyId];
      if (name != null) {
        handlePropertyChange(name, event[1]);
      }
    } else if (event is Map) {
      final type = event['type'];
      final name = event['name'];
      if (type == 'event' && name is String) {
        final rawData = event['data'];
        handlePlayerEvent(name, rawData is Map ? rawData : null);
      }
    }
  }

  void handlePropertyChange(String name, dynamic value) {
    if (_disposed) return;
    switch (name) {
      case 'pause':
        final playing = value == false;
        _state = _state.copyWith(playing: playing);
        playingController.add(playing);
        break;

      case 'eof-reached':
        final completed = value == true;
        _state = _state.copyWith(completed: completed);
        completedController.add(completed);
        break;

      case 'paused-for-cache':
        final buffering = value == true;
        _state = _state.copyWith(buffering: buffering);
        bufferingController.add(buffering);
        break;

      case 'time-pos':
        final positionMs = _millisecondsFromSeconds(value, round: true);
        if (positionMs != null) {
          final pos = Duration(milliseconds: positionMs);
          _positionMs = positionMs;
          // The backend has spoken, so no Dart-side optimistic write is on top
          // any more — whatever the value happens to be.
          _lastPositionWriter = _backendReportedWriter;
          _lastReportedPositionMs = positionMs;
          // Only allocate PlayerState + emit at ~4Hz (250ms). The raw integer
          // remains current for synchronous position reads on every tick.
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastEmitMs >= 250) {
            _lastEmitMs = nowMs;
            _state = _state.copyWith(position: pos);
            positionController.add(pos);
          }
        }
        break;

      case 'duration':
        final durationMs = _millisecondsFromSeconds(value);
        if (durationMs != null) {
          final duration = _timelineDuration ?? Duration(milliseconds: durationMs);
          _state = _state.copyWith(duration: duration);
          durationController.add(duration);
        }
        break;

      case 'seekable':
        if (value is bool) {
          setSeekable(value);
        }
        break;

      case 'demuxer-cache-time':
        final bufferMs = _millisecondsFromSeconds(value);
        if (bufferMs != null) {
          final nowMs = _throttleSw.elapsedMilliseconds;
          if (nowMs - _lastCacheStateMs < 250) break;
          _lastCacheStateMs = nowMs;
          final buffer = Duration(milliseconds: bufferMs);
          final rangeStart = _state.position;
          final previousRanges = _state.bufferRanges;
          final rangesChanged =
              previousRanges.length != 1 ||
              previousRanges.first.start != rangeStart ||
              previousRanges.first.end != buffer;
          final ranges = rangesChanged ? [BufferRange(start: rangeStart, end: buffer)] : previousRanges;
          _state = _state.copyWith(buffer: buffer, bufferRanges: ranges);
          bufferController.add(buffer);
          if (rangesChanged) {
            bufferRangesController.add(ranges);
          }
        }
        break;

      case 'demuxer-cache-state':
        _handleDemuxerCacheState(value);
        break;

      case 'volume':
        final volume = _finiteDouble(value);
        if (volume != null) {
          setVolumeState(volume);
        }
        break;

      case 'speed':
        final rate = _finiteDouble(value);
        if (rate != null) {
          setRateState(rate);
        }
        break;

      case 'track-list':
        final trackList = MpvNodeDecoder.decodeList(value);
        if (trackList != null) {
          if (_primaryMediaLoadStarted && !_primaryMediaReadyEmitted && _hasPrimaryMediaTrack(trackList)) {
            _primaryMediaReadyEmitted = true;
            primaryMediaReadyController.add(null);
          }
          final result = parseTrackList(trackList);
          _state = _state.copyWith(tracks: result.tracks);
          tracksController.add(result.tracks);
          // Derive selection from mpv's "selected" field in the track data.
          // This is the source of truth and handles cases where aid/sid
          // values don't match track IDs (e.g. "auto", "0", "no").
          if (result.selectedAudioId != null) {
            updateSelectedAudioTrack(result.selectedAudioId);
          }
          if (result.selectedSubtitleId != null) {
            updateSelectedSubtitleTrack(result.selectedSubtitleId);
          }
          // Deselection still arrives through the secondary-sid observation
          // ('no'), which stays the clearing path; track-list only ever
          // asserts a selection it can attribute via main-selection.
          if (result.selectedSecondarySubtitleId != null) {
            updateSelectedSecondarySubtitleTrack(result.selectedSecondarySubtitleId);
          }
        }
        break;

      case 'aid':
        updateSelectedAudioTrack(value);
        break;

      case 'sid':
        updateSelectedSubtitleTrack(value);
        break;

      case 'secondary-sid':
        updateSelectedSecondarySubtitleTrack(value);
        break;

      case 'audio-device-list':
        final deviceList = MpvNodeDecoder.decodeList(value);
        if (deviceList != null) {
          final devices = <AudioDevice>[];
          for (final entry in deviceList) {
            if (entry is! Map) continue;
            final name = entry['name'];
            final description = entry['description'];
            if (name is! String) continue;
            devices.add(AudioDevice(name: name, description: description is String ? description : ''));
          }
          _state = _state.copyWith(audioDevices: devices);
          audioDevicesController.add(devices);
        }
        break;

      case 'audio-device':
        if (value is String && value.isNotEmpty) {
          final device = _state.audioDevices.firstWhereOrNull((d) => d.name == value) ?? AudioDevice(name: value);
          _state = _state.copyWith(audioDevice: device);
          audioDeviceController.add(device);
        }
        break;
    }
  }

  /// Parse demuxer-cache-state property to extract seekable ranges and buffer end.
  void _handleDemuxerCacheState(dynamic value) {
    if (value is String && value.isNotEmpty) {
      // Throttle JSON parsing to avoid ANR on low-end devices
      final nowMs = _throttleSw.elapsedMilliseconds;
      if (nowMs - _lastCacheStateMs < 250) return;
      _lastCacheStateMs = nowMs;
    }
    final cacheState = MpvNodeDecoder.decodeMap(value);
    if (cacheState == null) return;

    // Extract cache-end for the single buffer duration (replaces demuxer-cache-time)
    final cacheEndMs = _millisecondsFromSeconds(cacheState['cache-end']);
    final buffer = cacheEndMs == null ? _state.buffer : Duration(milliseconds: cacheEndMs);

    // Extract seekable-ranges array
    List<BufferRange>? parsedRanges;
    final seekableRanges = cacheState['seekable-ranges'];
    if (seekableRanges is List) {
      parsedRanges = <BufferRange>[];
      for (final range in seekableRanges) {
        if (range is! Map) continue;
        final startMs = _millisecondsFromSeconds(range['start']);
        final endMs = _millisecondsFromSeconds(range['end']);
        if (startMs != null && endMs != null) {
          parsedRanges.add(
            BufferRange(
              start: Duration(milliseconds: startMs),
              end: Duration(milliseconds: endMs),
            ),
          );
        }
      }
    }

    var ranges = _state.bufferRanges;
    var rangesChanged = false;
    if (parsedRanges != null && !listEquals(ranges, parsedRanges)) {
      ranges = parsedRanges;
      rangesChanged = true;
    }
    if (cacheEndMs == null && !rangesChanged) return;

    _state = _state.copyWith(buffer: buffer, bufferRanges: ranges);
    if (cacheEndMs != null) {
      bufferController.add(buffer);
    }
    if (rangesChanged) {
      bufferRangesController.add(ranges);
    }
  }

  void handlePlayerEvent(String name, Map? data) {
    if (_disposed) return;
    switch (name) {
      case 'start-file':
        _primaryMediaLoadStarted = true;
        _primaryMediaReadyEmitted = false;
        fileStartedController.add(null);
        break;

      case 'end-file':
        _primaryMediaLoadStarted = false;
        setSeekable(false);
        final rawReason = data?['reason'];
        final reason = switch (rawReason) {
          0 => 'eof',
          2 => 'stop',
          3 => 'quit',
          4 => 'error',
          5 => 'redirect',
          final String s => s,
          _ => null,
        };
        if (reason == 'eof') {
          _state = _state.copyWith(completed: true);
          completedController.add(true);
        } else if (reason == 'error') {
          fileLoadFailedController.add(null);
          final rawMessage = data?['message'];
          final rawCause = data?['cause'];
          errorController.add(
            PlayerError(
              rawMessage is String ? rawMessage : 'Playback error',
              cause: rawCause is String ? rawCause : null,
            ),
          );
        }
        break;

      case 'file-loaded':
        _state = _state.copyWith(completed: false);
        completedController.add(false);
        fileLoadedController.add(null);
        break;

      case 'playback-restart':
        playbackRestartController.add(null);
        break;

      case 'hdr-output-changed':
        hdrOutputChangedController.add(null);
        break;

      case 'log-message':
        final rawPrefix = data?['prefix'];
        final rawLevel = data?['level'];
        final rawText = data?['text'];
        final prefix = rawPrefix is String ? rawPrefix : '';
        final level = parseLogLevel(rawLevel is String ? rawLevel : 'info');
        final text = rawText is String ? rawText : '';
        logController.add(PlayerLog(level: level, prefix: prefix, text: text));
        break;
    }
  }

  bool _hasPrimaryMediaTrack(List trackList) {
    for (final track in trackList) {
      if (track is! Map || track['external'] == true) continue;
      final type = track['type'];
      if (type == 'audio') return true;
      // mpv exposes embedded/external cover art as a video track. It is not
      // evidence that the primary audio file has finished discovery, so it
      // must not start the external-sidecar timeout on its own.
      if (type == 'video' && track['albumart'] != true) return true;
    }
    return false;
  }

  PlayerLogLevel parseLogLevel(String level) {
    return switch (level) {
      'fatal' => PlayerLogLevel.fatal,
      'error' => PlayerLogLevel.error,
      'warn' => PlayerLogLevel.warn,
      'info' => PlayerLogLevel.info,
      'v' || 'verbose' => PlayerLogLevel.verbose,
      'debug' => PlayerLogLevel.debug,
      'trace' => PlayerLogLevel.trace,
      _ => PlayerLogLevel.info,
    };
  }

  ({Tracks tracks, String? selectedAudioId, String? selectedSubtitleId, String? selectedSecondarySubtitleId})
  parseTrackList(List trackList) {
    final audioTracks = <AudioTrack>[];
    final subtitleTracks = <SubtitleTrack>[];
    String? selectedAudioId;
    String? selectedSubtitleId;
    String? selectedSecondarySubtitleId;
    final containerMetadataIndexes = <String, int>{};

    for (final track in trackList) {
      if (track is! Map) continue;

      final rawType = track['type'];
      if (rawType is! String) continue;
      final type = rawType;
      final rawId = track['id'];
      final id = rawId is String || rawId is num ? rawId.toString() : '';
      final selected = track['selected'] == true;

      if (type == 'audio') {
        final rawExternalFilename = track['external-filename'];
        final externalFilename = rawExternalFilename is String ? rawExternalFilename : null;
        final externalMetadata = externalFilename == null ? null : _externalSubtitleMetadataByUri[externalFilename];
        // Container sidecars are opened only to expose their subtitle tracks.
        // Do not let their audio streams participate in normal track matching.
        if (externalMetadata?.any((metadata) => metadata.isContainer) == true) continue;

        if (selected) selectedAudioId = id;
        audioTracks.add(
          AudioTrack(
            id: id,
            title: cleanTrackMetadataValue(track['title'] is String ? track['title'] as String : null),
            language: cleanTrackMetadataValue(track['lang'] is String ? track['lang'] as String : null),
            codec: track['codec'] is String ? track['codec'] as String : null,
            channels: _finiteInt(track['demux-channel-count']),
            sampleRate: _finiteInt(track['demux-samplerate']),
            isDefault: track['default'] == true,
          ),
        );
      } else if (type == 'sub') {
        if (selected) {
          // mpv marks both the `sid` and the `--secondary-sid` track as
          // selected; `main-selection` (0 = primary, 1 = secondary) tells them
          // apart. Backends that never report it (ExoPlayer) keep the plain
          // selected-means-primary reading.
          final mainSelection = _finiteInt(track['main-selection']);
          if (mainSelection == null || mainSelection == 0) {
            selectedSubtitleId = id;
          } else if (mainSelection == 1) {
            selectedSecondarySubtitleId = id;
          }
        }
        final rawCodec = track['codec'];
        final codec = rawCodec is String ? rawCodec : null;
        final rawTitle = track['title'];
        final rawLanguage = track['lang'];
        final rawExternalFilename = track['external-filename'];
        final externalFilename = rawExternalFilename is String ? rawExternalFilename : null;
        final externalMetadata = externalFilename == null ? null : _externalSubtitleMetadataByUri[externalFilename];
        final isContainer =
            track['container'] == true || externalMetadata?.any((metadata) => metadata.isContainer) == true;
        SubtitleTrack? matchedMetadata;
        if (externalMetadata != null && externalMetadata.isNotEmpty) {
          if (isContainer && externalFilename != null) {
            final metadataIndex = containerMetadataIndexes[externalFilename] ?? 0;
            containerMetadataIndexes[externalFilename] = metadataIndex + 1;
            if (metadataIndex < externalMetadata.length && externalMetadata[metadataIndex].isContainer) {
              matchedMetadata = externalMetadata[metadataIndex];
            }
          } else {
            matchedMetadata = externalMetadata.first;
          }
        }
        subtitleTracks.add(
          SubtitleTrack(
            id: id,
            // mpv may synthesize a container track title from the signed
            // source filename. Source-catalog metadata is both safer and more
            // accurate there, including on builds that drop disposition flags.
            // Ordinary sidecars still fall back to metadata reported by mpv.
            title: isContainer
                ? matchedMetadata?.title
                : matchedMetadata?.title ?? cleanSubtitleTitle(rawTitle is String ? rawTitle : null, codec: codec),
            language: isContainer
                ? matchedMetadata?.language
                : matchedMetadata?.language ?? cleanTrackMetadataValue(rawLanguage is String ? rawLanguage : null),
            codec: matchedMetadata?.codec ?? codec,
            isDefault: matchedMetadata?.isDefault ?? (track['default'] == true),
            isForced: matchedMetadata?.isForced ?? (track['forced'] == true),
            isExternal: track['external'] == true,
            isContainer: isContainer,
            uri: externalFilename,
          ),
        );
      }
    }

    return (
      tracks: Tracks(audio: audioTracks, subtitle: subtitleTracks),
      selectedAudioId: selectedAudioId,
      selectedSubtitleId: selectedSubtitleId,
      selectedSecondarySubtitleId: selectedSecondarySubtitleId,
    );
  }

  void updateSelectedAudioTrack(dynamic trackId) {
    final id = trackId?.toString();
    final selectedTrack = (id == null || id == 'no')
        ? null
        : _state.tracks.audio.firstWhereOrNull((track) => track.id == id);
    if (id != null && id != 'no' && selectedTrack == null) return;

    _state = _state.copyWith(track: _state.track.copyWith(audio: selectedTrack));
    trackController.add(_state.track);
  }

  void updateSelectedSubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    final selectedTrack = (id == null || id == 'no')
        ? SubtitleTrack.off
        : _state.tracks.subtitle.firstWhereOrNull((track) => track.id == id);

    if (selectedTrack == null) return;
    _state = _state.copyWith(track: _state.track.copyWith(subtitle: selectedTrack));
    trackController.add(_state.track);
  }

  void updateSelectedSecondarySubtitleTrack(dynamic trackId) {
    final id = trackId?.toString();
    SubtitleTrack? selectedTrack;

    if (id == null || id == 'no') {
      selectedTrack = null;
    } else {
      selectedTrack = _state.tracks.subtitle.firstWhereOrNull((t) => t.id == id);
    }

    _state = _state.copyWith(track: _state.track.copyWith(secondarySubtitle: selectedTrack));
    trackController.add(_state.track);
  }

  @protected
  void clearTracks() {
    const empty = Tracks();
    _state = _state.copyWith(tracks: empty, track: const TrackSelection());
    tracksController.add(empty);
  }

  @protected
  void setExternalSubtitleMetadata(List<SubtitleTrack>? externalSubtitles) {
    final metadataByUri = <String, List<SubtitleTrack>>{};
    for (final subtitle in externalSubtitles ?? const <SubtitleTrack>[]) {
      final uri = subtitle.uri;
      if (uri != null && uri.isNotEmpty) {
        (metadataByUri[uri] ??= <SubtitleTrack>[]).add(subtitle);
      }
    }
    _externalSubtitleMetadataByUri = metadataByUri;
  }

  @protected
  Map<String, List<SubtitleTrack>> snapshotExternalSubtitleMetadata() =>
      Map<String, List<SubtitleTrack>>.of(_externalSubtitleMetadataByUri);

  @protected
  void restoreExternalSubtitleMetadata(Map<String, List<SubtitleTrack>> snapshot) {
    _externalSubtitleMetadataByUri = Map<String, List<SubtitleTrack>>.of(snapshot);
  }

  @protected
  void setVolumeState(double volume) {
    if (_state.volume == volume) return;
    _state = _state.copyWith(volume: volume);
    volumeController.add(volume);
  }

  @protected
  void setRateState(double rate) {
    if (_state.rate == rate) return;
    _state = _state.copyWith(rate: rate);
    rateController.add(rate);
  }

  @protected
  void setSeekable(bool seekable) {
    if (_state.seekable == seekable) return;
    _state = _state.copyWith(seekable: seekable);
    seekableController.add(seekable);
  }

  @protected
  void configureTimeline({Duration? duration}) {
    _timelineDuration = duration;
  }

  /// Report that something is moving the playhead discontinuously, to [target]
  /// — or somewhere only the backend knows, when [target] is null. Announced
  /// when the move is requested, so it is intent rather than an observed
  /// landing; see `PlayerStreams.playheadJump`.
  ///
  /// Guards disposal: several callers announce after an await, by which point
  /// the controllers may already be closed.
  @protected
  void announcePlayheadJump(Duration? target) {
    if (_disposed) return;
    playheadJumpController.add(target);
  }

  /// Publish a playhead position the backend chose for itself, after a command
  /// that relocates it without going through [runSeek].
  ///
  /// Writes state as well as announcing: `PlayerState.position` is what
  /// consumers rebase relative seeks from, and its tick updates are throttled,
  /// so announcing alone would leave them working off the pre-command position.
  ///
  /// Arbitration is by acceptance, not by request: a seek that has only been
  /// asked for does not invalidate a relocation the backend already took, and a
  /// destination arriving while a newer seek is still unresolved is held rather
  /// than published — publishing would read as a foreign jump to whoever is
  /// coalescing that seek, and discarding would lose the cue if it is rejected.
  @protected
  void publishPlayheadRelocation(Duration position, {int? token}) {
    if (_disposed) return;
    // Something newer has claimed or moved the playhead since this relocation
    // started, so its answer is stale.
    if (token != null && token < _acceptedOperation) return;
    // A newer seek is still in flight, so it — not this answer about the past —
    // will define where the playhead ends up if it lands. Publishing now would
    // read as a foreign jump to whoever is coalescing that seek and cost them
    // the burst; discarding would lose the cue if that seek is then rejected.
    // Hold it until the group resolves.
    if (token != null && _hasUnresolvedSeekNewerThan(token)) {
      _deferredRelocation = (token: token, position: position);
      return;
    }
    final writer = token ?? ++_playheadOperations;
    _takeOperationOwnership(writer);
    _lastPositionWriter = writer;
    _activeSeekGroup = null;
    _setPlaybackPosition(position);
    announcePlayheadJump(position);
  }

  /// Where the playhead is, given [target] was accepted [since] ago.
  ///
  /// A reported position at or shortly past the target is playback running on
  /// from it and is fresher than the target itself; anything else is a stale
  /// observation from before the seek. "Shortly" is the media time the elapsed
  /// wall clock could actually cover at the current rate — a fixed window would
  /// rewind real progress at 8x and preserve stale ticks in slow motion — and a
  /// paused player covers none at all.
  Duration _progressedFrom(Duration target, Stopwatch? since) {
    // Only the backend observes playback. `_positionMs` also carries Dart's own
    // optimistic writes, and a rejected request's target sitting a few
    // milliseconds past an accepted one is not progress — reading it as such
    // would keep the position the backend refused.
    if (_lastPositionWriter != _backendReportedWriter) return target;
    final observed = Duration(milliseconds: _positionMs);
    final drift = observed - target;
    if (drift.isNegative) return target;
    final rate = _state.rate.isFinite && _state.rate > 0 ? _state.rate : 1.0;
    final elapsed = since?.elapsedMicroseconds ?? 0;
    final covered = _state.playing
        ? Duration(microseconds: ((elapsed + _landedProgressSlack.inMicroseconds) * rate).round())
        : Duration.zero;
    return drift <= covered ? observed : target;
  }

  /// Mark [operation] as the newest thing the backend accepted, retiring any
  /// relocation that was waiting to see whether it would land.
  void _takeOperationOwnership(int operation) {
    _acceptedOperation = operation;
    if ((_deferredRelocation?.token ?? operation) < operation) _deferredRelocation = null;
  }

  /// Settle a held relocation now that the group arbitrating it has drained.
  ///
  /// It wins when it is newer than anything that group landed; otherwise the
  /// group's own outcome stands and the cue is history either way.
  bool _resolveDeferredRelocation(_SeekGroup group) {
    final deferred = _deferredRelocation;
    _deferredRelocation = null;
    if (deferred == null || _disposed || deferred.token <= group.landedRequest) return false;
    _takeOperationOwnership(deferred.token);
    // Winning without a destination still means the group must not undo itself
    // across this relocation; there is simply nothing new to publish, and the
    // backend's next tick supplies the position.
    final position = deferred.position;
    if (position != null) {
      _setPlaybackPosition(position);
      announcePlayheadJump(position);
      return true;
    }
    // Destination unknown, and suppressing the group's rollback would leave a
    // rejected request's optimistic target on top of state — certainly not
    // where an accepted relocation put the playhead.
    _repairRejectedWrite(group);
    // The null this relocation sent before dispatch predates the seek it was
    // waiting on, so that seek's own echo has since re-armed any coalescing
    // consumer. Say again that the playhead is somewhere they did not put it.
    announcePlayheadJump(null);
    return true;
  }

  /// Record where the playing source got to, before its successor can report
  /// anything.
  ///
  /// [takeSourceOwnership] runs from the backend's event flow, which is not
  /// ordered against the property flow carrying position reports, so by then an
  /// incoming report may already have replaced the outgoing one. Callers that
  /// observe the boundary *on the property flow* can close that window by
  /// calling this; whoever finalises the outgoing item then gets its real last
  /// position instead of its successor's first.
  @protected
  void freezeOutgoingSourcePosition() {
    if (_disposed) return;
    _frozenOutgoingPositionMs = _lastReportedPositionMs;
  }

  /// The handover this froze a position for is not going to happen. Drop it, or
  /// a later advance whose boundary edge is dropped would prefer this snapshot
  /// over the position actually reported since.
  @protected
  void discardFrozenOutgoingPosition() => _frozenOutgoingPositionMs = null;

  /// The backend rolled into a different source on its own — a gapless
  /// advance. Nothing that was in flight against the old one may speak for the
  /// playhead any more.
  @protected
  void takeSourceOwnership() {
    if (_disposed) return;
    // Recorded before anything below overwrites it: whoever finalises the
    // outgoing item needs where it got to, and every position reachable from
    // here on belongs to the new source.
    _outgoingSourcePosition = Duration(milliseconds: _frozenOutgoingPositionMs ?? _lastReportedPositionMs);
    _frozenOutgoingPositionMs = null;
    _lastReportedPositionMs = 0;
    _takeOperationOwnership(++_playheadOperations);
    _activeSeekGroup = null;
    // A gapless advance starts the new source at its beginning, which is known
    // rather than guessed. Published unconditionally: the alternative is to
    // preserve whatever position was last reported, and at this boundary that
    // is far more likely to be the outgoing track's last tick than an early
    // one from the incoming track. If an early new-source tick really did
    // arrive, its successor corrects this within one tick.
    _lastPositionWriter = _playheadOperations;
    _setPlaybackPosition(Duration.zero);
    announcePlayheadJump(Duration.zero);
  }

  /// Lift a rejected request's optimistic target off state, if it is still the
  /// thing on top.
  ///
  /// What replaces it is the closest position actually known: what the backend
  /// last reported, else the newest target this group had accepted, else where
  /// it started. Nothing is announced — a rejected request's abandonment is
  /// announced by whoever rejected it.
  void _repairRejectedWrite(_SeekGroup group) {
    if (_disposed) return;
    // A later group is running: its optimistic write owns state, and even a
    // backend report arriving now belongs inside its window, not this one's.
    if (_activeSeekGroup != null && !identical(_activeSeekGroup, group)) return;

    if (_lastPositionWriter == _backendReportedWriter) {
      // The backend has reported since, so it is authoritative whatever the
      // value — this must be checked before anything that infers ownership from
      // the value itself. `PlayerState.position` is throttled and can still be
      // showing an abandoned target, so bring it into line.
      final ticked = Duration(milliseconds: _positionMs);
      if (_state.position != ticked) _setPlaybackPosition(ticked);
      return;
    }

    if (group.landedRequest == group.newestRequest) return;
    // Someone else wrote since; their value stands even if it happens to match
    // this group's target.
    if (_lastPositionWriter != group.newestRequest) return;
    _setPlaybackPosition(group.landedTarget ?? group.anchor);
  }

  bool _hasUnresolvedSeekNewerThan(int token) {
    // Asked of the requests still outstanding, not of the group's newest: that
    // one may already have settled while an older sibling holds the group open.
    final group = _activeSeekGroup;
    return group != null && group.unsettled.any((request) => request > token);
  }

  @protected
  Duration? get configuredTimelineDuration => _timelineDuration;

  /// Install a freshly opened source at [sourcePosition].
  ///
  /// An in-place reload — dead-stream recovery, a quality/version switch, a
  /// background-suspend resume — places the playhead here rather than through
  /// [runSeek], so this is the second way it can move discontinuously.
  @protected
  void resetPlaybackProgress(Duration sourcePosition) {
    final position = sourcePosition;
    _positionMs = position.inMilliseconds;
    // A source is being installed at this position; nothing has been reported
    // about it yet, and its predecessor's position says nothing about it.
    _lastReportedPositionMs = position.inMilliseconds;
    _state = _state.copyWith(
      completed: false,
      position: position,
      duration: _timelineDuration ?? Duration.zero,
      buffer: Duration.zero,
      bufferRanges: const [],
    );
    _takeOperationOwnership(++_playheadOperations);
    _lastPositionWriter = _playheadOperations;
    _activeSeekGroup = null;
    completedController.add(false);
    positionController.add(position);
    announcePlayheadJump(position);
    durationController.add(_timelineDuration ?? Duration.zero);
    bufferController.add(Duration.zero);
    bufferRangesController.add(const []);
  }

  @protected
  void restoreTracks(PlayerState snapshot) {
    _state = _state.copyWith(tracks: snapshot.tracks, track: snapshot.track);
    tracksController.add(snapshot.tracks);
    trackController.add(snapshot.track);
  }

  /// Put back the state a failed open tore down.
  ///
  /// [resetPlaybackProgress] already announced the start position the open was
  /// aiming for, so undoing it has to be announced too — otherwise a consumer
  /// that pinned the abandoned resume target keeps building on it.
  @protected
  void restorePlaybackProgress(PlayerState snapshot, {Duration? position}) {
    final restoredPosition = position ?? snapshot.position;
    _positionMs = restoredPosition.inMilliseconds;
    _state = _state.copyWith(
      completed: snapshot.completed,
      position: restoredPosition,
      duration: snapshot.duration,
      buffer: snapshot.buffer,
      bufferRanges: snapshot.bufferRanges,
    );
    _takeOperationOwnership(++_playheadOperations);
    _lastPositionWriter = _playheadOperations;
    _activeSeekGroup = null;
    completedController.add(snapshot.completed);
    positionController.add(restoredPosition);
    announcePlayheadJump(restoredPosition);
    durationController.add(snapshot.duration);
    bufferController.add(snapshot.buffer);
    bufferRangesController.add(snapshot.bufferRanges);
  }

  @protected
  Future<T?> invoke<T>(String method, [dynamic args]) async {
    if (_disposed) return null;
    if (_nativeOwnershipReady case final ready?) {
      try {
        await ready.timeout(debugNativeOwnershipInvokeTimeout);
      } on TimeoutException {
        return null;
      }
    }
    if (_disposed) return null;
    return methodChannel.invokeMethod<T>(method, args);
  }

  @override
  Future<void> playOrPause() async {
    if (_disposed) return;
    if (_state.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {}

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    if (_disposed) return false;
    try {
      await invoke('setVisible', {'visible': visible, 'restoreOnWindowVisible': restoreOnWindowVisible});
      return true;
    } catch (e) {
      errorController.add(PlayerError('Failed to set visibility: $e'));
      return false;
    }
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> updateFrame() async {}

  @override
  Future<bool> isHdrOutputSupported() async => false;

  @override
  Future<bool> setVideoFrameRate(
    double fps,
    int durationMs, {
    int extraDelayMs = 0,
    int videoWidth = 0,
    int videoHeight = 0,
    bool matchResolution = false,
  }) async => false;

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> clearVideoFrameRate() async {}

  @override
  // ignore: no-empty-block - base no-op, ExoPlayer styles subtitles natively
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
  }) async {}

  @override
  // ignore: no-empty-block - base no-op, mpv scales via panscan/aspect-override
  Future<void> setBoxFitMode(int mode) async {}

  @override
  // ignore: no-empty-block - base no-op, non-Apple mpv zooms via the video-zoom property
  Future<void> setVideoZoom(double scale) async {}

  @override
  Future<Map<String, dynamic>> getStats() async => const {};

  @override
  Future<String> runtimePlayerType() async => playerType;

  @override
  Future<bool> requestAudioFocus() async {
    // Default returns true, overridden by Android
    return true;
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> abandonAudioFocus() async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setAudioDevice(AudioDevice device) async {}

  @override
  bool get supportsSecondarySubtitles => true;

  @override
  bool get attachesExternalSubtitlesAtOpen => false;

  @override
  bool get detectsFpsAfterRender => false;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  bool get providesNativeStats => false;

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> selectSecondarySubtitleTrack(SubtitleTrack track) async {}

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  Future<AudioRenderingMode?> getAudioRenderingMode() async => null;

  /// mpv loudnorm targeting streaming-style loudness; mirrored by the
  /// Android ExoPlayer effect parameters in AudioNormalizationEffect.kt.
  ///
  /// Dynamic-mode loudnorm always outputs float64 at 192 kHz, which made the
  /// AO open at f64/192k and forced the OS mixer to convert/resample on the
  /// deadline-critical path (~4x the per-cycle DSP work), underrunning during
  /// playback startup (#1720). The trailing mpv-native format filter pins the
  /// chain back to 48 kHz float, so the conversion runs once on the buffered
  /// decode side. mpv's own `format` filter is used instead of lavfi
  /// `aformat` because the bundled Linux ffmpeg prunes lavfi filters.
  static const _loudnormFilter = 'loudnorm=I=-14:TP=-3:LRA=4,format=srate=48000:format=floatp';

  @override
  Future<void> setAudioNormalization(bool enabled) async {
    await setProperty('af', enabled ? _loudnormFilter : '');
  }

  @override
  Future<void> setAudioDownmix({required bool enabled, required int centerBoostDb, required bool normalize}) async {
    if (enabled) {
      // Kodi's mechanism: center coefficient = 10^((-3 + boost)/20); the
      // surround (-3 dB) and LFE (dropped) swresample defaults already match.
      final c = math.pow(10, (-3 + centerBoostDb.clamp(0, 12)) / 20).toStringAsFixed(4);
      // Swresample AVOptions are read once at audio-filter creation, so they
      // must land before audio-channels triggers the chain (re)build.
      await setProperty('audio-swresample-o', 'center_mix_level=$c');
      await setProperty('audio-normalize-downmix', normalize ? 'yes' : 'no');
      // Bounce through auto-safe so boost/normalize changes re-apply while
      // downmix is already active (same-value option sets are no-ops in mpv).
      await setProperty('audio-channels', 'auto-safe');
      await setProperty('audio-channels', 'stereo');
    } else {
      await setProperty('audio-channels', 'auto-safe');
      await setProperty('audio-swresample-o', '');
      await setProperty('audio-normalize-downmix', 'no');
    }
  }

  @override
  // ignore: no-empty-block - base no-op, overridden by platform subclasses
  Future<void> setLogLevel(String level) async {}

  @override
  Future<void> configureSubtitleFonts() async {
    try {
      final fontDir = await SubtitleFontLoader.loadSubtitleFont();
      if (fontDir != null) {
        await setProperty('sub-fonts-dir', fontDir);
        await setProperty('sub-font', SubtitleFontLoader.fontName);
      }
    } catch (e) {
      // Font configuration is not critical - continue without it
      logController.add(
        PlayerLog(prefix: 'fonts', level: PlayerLogLevel.warn, text: 'Failed to configure subtitle fonts: $e'),
      );
    }
  }

  void _setPlaybackPosition(Duration position) {
    _positionMs = position.inMilliseconds;
    _state = _state.copyWith(position: position);
    positionController.add(position);
  }

  /// Run a backend-specific seek call, swallowing the common "not ready" errors
  /// the native channel throws when the engine was torn down mid-seek.
  ///
  /// Seeks can overlap, and each one optimistically writes its own target, so
  /// no single call knows where the playhead really ended up. The last of an
  /// overlapping group to settle owns the correction: if any of them landed the
  /// backend is at that target, and if none did, nothing moved and the position
  /// from before the group is the truth.
  @protected
  Future<void> runSeek(Duration position, Future<void> Function() seekFn) async {
    if (_disposed) return;

    final request = ++_playheadOperations;
    // Measures how much media time playback could legitimately have covered
    // while the command was in flight; a fixed media-time window cannot tell a
    // fast-rate advance from a stale pre-seek tick.
    final elapsedInFlight = Stopwatch()..start();
    final group = _activeSeekGroup ??= _SeekGroup(Duration(milliseconds: _positionMs));
    group.unsettled.add(request);
    group.newestRequest = request;
    _lastPositionWriter = request;
    _setPlaybackPosition(position);
    // Announce the request, not its completion: consumers coalescing their own
    // seeks need to know the playhead moved out from under them while the
    // backend is still working, which is exactly the window a late signal would
    // miss.
    announcePlayheadJump(position);

    void settle({required bool landed}) {
      // A newer request in this group has already displaced the playhead
      // optimistically, so nothing here can read the backend's position: record
      // the exact target and let the group reconcile once that newer request
      // resolves.
      if (landed && request != group.newestRequest) {
        if (request > group.landedRequest) {
          group.landedRequest = request;
          group.landedTarget = position;
          group.landedSince = elapsedInFlight;
        }
        if (request > _acceptedOperation) _takeOperationOwnership(request);
      } else if (landed) {
        final authoritative = _progressedFrom(position, elapsedInFlight);

        if (request > group.landedRequest) {
          // The backend applies commands in issue order, so the newest request
          // it accepted is where it ends up — whichever reply came back first.
          group.landedRequest = request;
          group.landedTarget = authoritative;
          group.landedSince = elapsedInFlight;
        }
        if (request > _acceptedOperation) {
          // Newest thing the backend has accepted, so the playhead is here.
          // Applied now rather than at group drain: the group may be detached
          // by a relocation or still waiting on an older member, and neither
          // changes the fact that nothing newer has been accepted.
          _takeOperationOwnership(request);
          if (_positionMs != authoritative.inMilliseconds || _state.position != authoritative) {
            _setPlaybackPosition(authoritative);
          }
        }
      }
      group.unsettled.remove(request);
      if (group.unsettled.isNotEmpty) return;
      if (!identical(_activeSeekGroup, group)) {
        // Detached: something outside the group took the playhead after it
        // started — a relocation, or a different source starting. A deferred
        // relocation is deliberately left alone here — it is held against
        // whichever group is active now, which may well be a later one than
        // this, and resolving it from here would publish into that group's
        // window or restore an anchor from a timeline it never saw. Its own
        // rejected write is still its to clean up, though.
        _repairRejectedWrite(group);
        return;
      }
      _activeSeekGroup = null;
      if (_disposed) return;

      if (_resolveDeferredRelocation(group)) return;

      final anchor = group.anchor;
      final landedTarget = group.landedTarget;
      final newestRequestFailed = group.landedRequest != group.newestRequest;

      if (landedTarget != null) {
        // Something landed and already applied itself. Only a rejected newest
        // request needs undoing here: its optimistic write is still on top, and
        // the accepted target of a newest request went out as its own request.
        if (newestRequestFailed) {
          // The rejected newest request's optimistic write is still on top.
          // Replace it with the accepted target, or with a tick that has since
          // run on from it — rewinding real progress would be its own bug.
          final settled = _progressedFrom(landedTarget, group.landedSince);
          _setPlaybackPosition(settled);
          announcePlayheadJump(settled);
        }
        return;
      }

      // Every seek in the group was rejected, so the playhead never went where
      // it was announced. Undo it in state and on the stream, or a consumer
      // keeps building on a position the backend refused.
      if (_lastPositionWriter == _backendReportedWriter) {
        // The backend reported a position while the group was in flight, so the
        // pre-group position is not what to restore — but `PlayerState.position`
        // is throttled and can still be showing an abandoned target, so publish
        // the reported value rather than leaving that on display.
        final ticked = Duration(milliseconds: _positionMs);
        _setPlaybackPosition(ticked);
        announcePlayheadJump(ticked);
        return;
      }
      _setPlaybackPosition(anchor);
      announcePlayheadJump(anchor);
    }

    try {
      await seekFn();
      settle(landed: true);
    } on PlatformException catch (e) {
      settle(landed: false);
      if (e.code == 'COMMAND_FAILED' || e.code == 'NOT_INITIALIZED') {
        appLogger.w('Seek failed (${e.code}), player not ready');
        return;
      }
      rethrow;
    } catch (_) {
      settle(landed: false);
      rethrow;
    }
  }

  /// Injects the log + error events that would fire when the server rejects the
  /// stream with [status]. Used by the in-player debug buttons to preview the
  /// end-to-end detection path without needing a real misbehaving server: 500
  /// is a shared-user bandwidth/transcoding limit, 404 a file the server can no
  /// longer read, 503 a server that keeps refusing the stream (the error event
  /// stands in for the open-phase watchdog, which cannot arm once playback has
  /// a frame). The warn-level log mirrors ffmpeg's real wording, which is what
  /// [PlayerError.httpStatusFromLog] parses.
  void debugSimulateServerHttpError(int status) {
    if (_disposed) return;
    logController.add(
      PlayerLog(level: PlayerLogLevel.warn, prefix: 'ffmpeg', text: 'https: HTTP error $status Simulated'),
    );
    final cause = switch (status) {
      500 => PlayerError.serverHttp500,
      404 => PlayerError.serverHttp404,
      503 => PlayerError.serverHttp503,
      _ => null,
    };
    errorController.add(PlayerError('HTTP $status', cause: cause));
  }

  /// Whether this backend's native `dispose` handler validates the
  /// `instanceId` token and no-ops a stale one. Only a guarded handler may
  /// receive a dispose after the ownership wait times out — an unguarded
  /// handler would tear down whatever core is current, including a
  /// successor's. Unguarded platforms keep the historical skip-and-chain
  /// behavior (and with it the theoretical wedge) until they gain the guard.
  @protected
  bool get nativeDisposeIsStaleGuarded => false;

  /// Returns whether the native `dispose` may be sent.
  Future<bool> _waitForNativeOwnershipForDispose() async {
    final ready = _nativeOwnershipReady;
    if (ready == null) return true;
    try {
      await ready.timeout(debugNativeOwnershipDisposeTimeout);
      return true;
    } on TimeoutException catch (error, stackTrace) {
      if (nativeDisposeIsStaleGuarded) {
        appLogger.w(
          'Timed out waiting for the previous player to release the native channel; '
          'force-disposing with a stale-guarded token',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      }
      appLogger.w(
        'Timed out waiting for the previous player to release the native channel; skipping native dispose',
        error: error,
        stackTrace: stackTrace,
      );
      if (!_nativeRelease.isCompleted) _nativeRelease.complete(ready);
      return false;
    }
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    if (_disposed) return;
    _disposed = true;
    // The texture is going away with the player; clear the id first so a
    // still-mounted Video widget stops keying off it before the notifier is
    // disposed below.
    _textureId.value = null;

    final channelName = eventChannel.name;
    if (identical(_eventChannelOwners[channelName], this)) {
      // Keep this owner registered while its native release is pending so a
      // player created during disposal inherits the complete release chain.
      // The newer listen cannot interleave before cancel() is invoked on this
      // isolate; after the first await, ownership is checked again at removal.
      try {
        await _eventSubscription?.cancel();
      } on PlatformException catch (e, st) {
        appLogger.d('Player event stream already detached during dispose', error: e, stackTrace: st);
      } on MissingPluginException catch (e, st) {
        appLogger.d('Player event stream plugin missing during dispose', error: e, stackTrace: st);
      }
    } else {
      // A newer instance owns the channel; cancelling would send a stray
      // native 'cancel' that kills *its* stream. Drop ours without cancelling
      // — the newer listen already replaced this subscription's routing.
      appLogger.d('Player event stream handed off to a newer instance, skipping cancel');
    }
    _eventSubscription = null;
    await _logSubscription?.cancel();
    final sendNativeDispose = await _waitForNativeOwnershipForDispose();
    try {
      if (sendNativeDispose) {
        // Sent even when the ownership wait timed out on a guarded backend:
        // the token makes a stale dispose provable, so the native side no-ops
        // it rather than tearing down a successor's core. Skipping instead
        // used to chain this release onto a predecessor that might never
        // complete, wedging every future playback session until the app was
        // killed.
        await methodChannel.invokeMethod('dispose', {
          'preserveDisplayMode': preserveDisplayMode,
          'instanceId': nativeInstanceId,
        }); // Direct call — invoke() is disabled once _disposed is set.
      }
    } on PlatformException catch (e, st) {
      appLogger.w('Player native dispose failed during teardown', error: e, stackTrace: st);
    } on MissingPluginException catch (e, st) {
      appLogger.w('Player native dispose plugin missing during teardown', error: e, stackTrace: st);
    } finally {
      if (sendNativeDispose && !_nativeRelease.isCompleted) _nativeRelease.complete();
    }

    // On the skip path the release above was completed *with* the
    // predecessor's future, so the ownership slot stays occupied until that
    // chain settles; on every other path it settles in the finally.
    if (_nativeRelease.isCompleted) {
      unawaited(
        _nativeRelease.future.whenComplete(() {
          if (identical(_eventChannelOwners[channelName], this)) {
            _eventChannelOwners.remove(channelName);
          }
        }),
      );
    }
    await closeStreamControllers();
    _textureId.dispose();
  }
}

/// One run of overlapping [PlayerBase.runSeek] calls.
///
/// Each seek writes its own target optimistically, so no single call knows
/// where the backend actually ended up; the last one to settle reconciles the
/// group. [anchor] is where the playhead was before the first of them started.
class _SeekGroup {
  _SeekGroup(this.anchor);

  final Duration anchor;

  /// The source this group was issued against.
  final Set<int> unsettled = <int>{};
  int newestRequest = 0;
  int landedRequest = 0;
  Duration? landedTarget;

  /// The winning request's own flight clock, still running. A drain uses it to
  /// tell playback progressing from [landedTarget] apart from a stale
  /// observation; restarting it at settlement would undercount media time the
  /// backend covered while a slow command was still being answered.
  Stopwatch? landedSince;
}
