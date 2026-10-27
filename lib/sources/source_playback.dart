import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../mpv/mpv.dart';
import '../services/media_control_router.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_coordinator.dart';
import '../services/music/music_hardware_transport.dart';
import '../services/driver_distraction.dart';
import '../services/car_ux_restrictions_service.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/notification_permission.dart';
import '../screens/video_player/wakelock_controller.dart';
import 'content_access.dart';
import 'source_controller.dart';
import 'source_models.dart';

/// The book session owns source-time progress independently of the music queue.
/// Commands serialize, and each native generation ignores stale event delivery.
class SourcePlayback extends ChangeNotifier with WidgetsBindingObserver {
  SourcePlayback(
    this.sources, {
    this._playerFactory,
    MediaControlsManager Function()? controlsFactory,
    WakelockPlatformToggle? wakelockToggle,
  }) : _wakelock = WakelockController(platformToggle: wakelockToggle),
       _controlsFactory = controlsFactory ?? MediaControlsManager.new {
    sources.stopPlayback = stop;
    PlaybackCoordinator.instance.registerFileSession(stop, isActive: () => active || opening);
    WidgetsBinding.instance.addObserver(this);
    if (PlatformDetector.isAutomotive()) CarUxRestrictionsService.instance.listenable.addListener(_carChanged);
  }
  void _carChanged() {
    if (!_valid) return;
    if (!automotivePlaybackAllowedNow()) unawaited(pause());
    unawaited(
      _controls?.setBackgroundMode(
        !video &&
            CarUxRestrictionsService.instance.state != CarUxRestrictionState.unknown &&
            automotivePlaybackAllowedNow(),
      ),
    );
  }

  final SourceController sources;
  final WakelockController _wakelock;
  final Player Function(bool)? _playerFactory;
  VideoPlayerSlot? videoPlayerSlot;
  VideoPlayerLease? _videoPlayerLease;
  final MediaControlsManager Function() _controlsFactory;
  Player? player;
  SourceEntry? entry;
  List<PublicationFile> files = const [];
  List<BookChapter> chapters = const [];
  PublicationProgress? progress;
  PublicationMode mode = PublicationMode.listening;
  SourceFailure? failure;
  bool opening = false;
  bool fullPlayerVisible = false;
  Map<String, Uri> _localOverrides = const {};
  bool _persistProgress = true;
  bool _liveInput = false;
  List<File> _temporaryMediaFiles = const [];
  File? _streamRecordingTarget;
  File? _streamRecordingPartial;
  File? _streamRecordingBackup;
  bool _pictureAdjustmentTouched = false;
  bool _disposed = false;
  bool _workspaceAudioEnabled = true;
  bool _resumeAfterInterruption = false;
  bool _useEntryChapters = false;
  int _fileEpoch = 0;
  int _completedEpoch = -1;
  String? _profile;
  int _profileGeneration = 0;
  int _generation = 0;
  int _fileIndex = 0;
  final Map<int, int> _durations = {};
  final Map<int, List<BookChapter>> _fileChapters = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<File> _temporarySubtitles = [];
  SourceStreamGateway? _gateway;
  MediaControlsManager? _controls;
  MusicHardwareTransportHandler? _hardware;
  Future<void> _commands = Future.value();
  Future<void> _writes = Future.value();
  Timer? _saveTimer;
  Timer? _sleepTimer;
  int? _sleepAtMs;
  int? _sleepUntilFile;
  int? _sleepBoundaryFile;
  ({int file, int position})? _undoSeek;
  bool chapterTimeline = false;
  DateTime? sleepDeadline;
  DateTime? _pausedAt;
  bool smartRewind = true;
  int backwardSeconds = 15;
  int forwardSeconds = 30;
  bool get canUndoSeek => _undoSeek != null;
  int get currentFilePositionMs => player?.currentPosition.inMilliseconds ?? 0;
  int get currentFileDurationMs => _durations[_fileIndex] ?? player?.state.duration.inMilliseconds ?? 0;
  int get timelineStartMs => chapterTimeline && currentChapter != null
      ? currentChapter!.startMs
      : hasCompleteTimeline
      ? 0
      : _offset;
  int get timelineEndMs => chapterTimeline && (currentChapter?.endMs ?? 0) > timelineStartMs
      ? currentChapter!.endMs
      : hasCompleteTimeline
      ? durationMs
      : _offset + currentFileDurationMs;
  int? get bookRemainingMs =>
      hasCompleteTimeline ? ((durationMs - positionMs).clamp(0, durationMs) / speed).round() : null;
  int? get chapterRemainingMs => currentChapter != null && currentChapter!.endMs > positionMs
      ? ((currentChapter!.endMs - positionMs) / speed).round()
      : null;
  bool get active => entry != null;
  bool get video => mode == PublicationMode.watching;
  bool get isTransientInput => !_persistProgress;
  bool get isLiveInput => _liveInput;
  bool get isRecordingStream => _streamRecordingPartial != null;
  bool get playing => player?.state.isActive ?? false;

  void markPictureAdjustmentChanged() {
    _pictureAdjustmentTouched = true;
  }

  Future<void> startStreamRecording(File destination, {required bool replaceExisting}) async {
    if (!_valid || !_liveInput || player?.playerType != 'mpv') {
      throw const SourceException(SourceFailure.unsupported);
    }
    if (isRecordingStream) throw const SourceException(SourceFailure.conflict);
    final native = player!;
    final generation = _generation;

    final target = File(destination.absolute.path);
    final extension = p.extension(target.path).toLowerCase();
    final supportedExtensions = video ? const {'.mkv', '.ts'} : const {'.mka', '.mkv'};
    if (!supportedExtensions.contains(extension)) throw const SourceException(SourceFailure.unsupported);

    final parent = target.parent;
    if (!await parent.exists()) throw const SourceException(SourceFailure.storageUnavailable);
    File? backup;
    if (await target.exists()) {
      if (!replaceExisting) throw const SourceException(SourceFailure.conflict);
      backup = File('${target.path}.plezy-backup-${const Uuid().v4()}');
      await target.rename(backup.path);
    }

    if (!_valid || player != native || _generation != generation) {
      if (backup != null && await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      throw const SourceException(SourceFailure.cancelled);
    }

    final partial = File(
      p.join(parent.path, '.${p.basenameWithoutExtension(target.path)}.plezy-recording-${const Uuid().v4()}$extension'),
    );
    try {
      await native.setProperty('file-local-options/stream-record', partial.path);
      _streamRecordingTarget = target;
      _streamRecordingPartial = partial;
      _streamRecordingBackup = backup;
      _notify();
    } catch (_) {
      if (backup != null && await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  Future<File?> stopStreamRecording() async {
    final target = _streamRecordingTarget;
    final partial = _streamRecordingPartial;
    final backup = _streamRecordingBackup;
    if (target == null || partial == null) return null;

    _streamRecordingTarget = null;
    _streamRecordingPartial = null;
    _streamRecordingBackup = null;
    try {
      final native = player;
      if (native != null && !native.disposed) {
        await native.setProperty('file-local-options/stream-record', '');
      }
      if (!await partial.exists() || await partial.length() == 0) {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (await target.exists()) throw const SourceException(SourceFailure.conflict);
      await partial.rename(target.path);
      if (backup != null && await backup.exists()) await backup.delete();
      return target;
    } catch (_) {
      // Playback teardown still proceeds if finalizing the stream failed.
      if (await partial.exists()) {
        try {
          await partial.delete();
        } catch (_) {
          // A stale recording partial is safer than disrupting playback teardown.
        }
      }
      if (backup != null && await backup.exists() && !await target.exists()) {
        try {
          await backup.rename(target.path);
        } catch (_) {
          // Keep the backup in place if the destination cannot be restored.
        }
      }
      rethrow;
    } finally {
      _notify();
    }
  }

  Future<void> setWorkspaceAudioEnabled(bool enabled) async {
    if (_disposed || _workspaceAudioEnabled == enabled) return;
    _workspaceAudioEnabled = enabled;
    final native = player;
    if (native == null || native.disposed) return;
    if (enabled) {
      try {
        await native.setWorkspaceAudioFocusEnabled(true);
        if (native.state.isActive) await native.requestAudioFocus();
      } catch (error, stackTrace) {
        appLogger.w('Source workspace audio focus handoff failed', error: error, stackTrace: stackTrace);
      }
      await native.setVolume(100);
      return;
    }

    try {
      await native.setVolume(0);
    } finally {
      try {
        await native.setWorkspaceAudioFocusEnabled(false);
      } catch (error, stackTrace) {
        appLogger.w('Source workspace audio focus release failed', error: error, stackTrace: stackTrace);
      }
    }
  }

  double get speed => progress?.speed ?? 1;
  int get fileIndex => _fileIndex;
  int get _offset => List.generate(_fileIndex, (i) => _durations[i] ?? 0).fold(0, (a, b) => a + b);
  bool get hasCompleteTimeline => List.generate(files.length, (i) => _durations[i] ?? 0).every((d) => d > 0);
  int get durationMs => List.generate(files.length, (i) => _durations[i] ?? 0).fold(0, (a, b) => a + b);
  int get positionMs => _offset + (player?.currentPosition.inMilliseconds ?? 0);
  BookChapter? get currentChapter =>
      chapters.where((c) => positionMs >= c.startMs && (c.endMs <= c.startMs || positionMs < c.endMs)).lastOrNull;
  bool get _valid =>
      !_disposed && sources.current(_profileGeneration) && !sources.blocked && sources.profileId == _profile;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _commands.then((_) => operation());
    _commands = next.catchError((Object error) {
      failure = error is SourceException ? error.reason : SourceFailure.unavailable;
      opening = false;
      _notify();
    });
    return next;
  }

  Future<void> start(
    SourceEntry item,
    List<PublicationFile> selected, {
    PublicationMode? playbackMode,
    Map<String, Uri> localOverrides = const {},
    bool persistProgress = true,
    bool liveInput = false,
    List<File> temporaryMediaFiles = const [],
  }) => _serialize(() async {
    await _stop();
    try {
      sources.requireSession();
      if (selected.isEmpty) throw const SourceException(SourceFailure.unsupported);
      if (PlatformDetector.isAutomotive()) await CarUxRestrictionsService.instance.ensureResolved();
      final requestedMode =
          playbackMode ?? (item.kind == SourceItemKind.video ? PublicationMode.watching : PublicationMode.listening);
      final coordinator = PlaybackCoordinator.instance;
      if (requestedMode == PublicationMode.watching) {
        // This SourcePlayback is itself the registered file owner. Asking the
        // coordinator to stop that callback while this serialized start is
        // running would wait on this same operation. _stop() above retires its
        // previous item; claimVideoSlot reserves one of the two native video slots.
        final lease = await coordinator.claimVideoSlot(stopFileSession: false);
        _videoPlayerLease = lease;
        videoPlayerSlot = lease.slot;
      } else {
        videoPlayerSlot = null;
        await coordinator.claimFiles(preserveWorkspaceVideo: true, preserveWorkspaceMusic: true);
      }
      // A retained music pane is the default audible surface until the user
      // selects this source session. Start muted before opening the native
      // player so registration cannot race an audible burst.
      _workspaceAudioEnabled =
          !coordinator.workspaceHasCompetingAudioOwner &&
          !coordinator.workspaceRetainsMusic &&
          (requestedMode != PublicationMode.watching || videoPlayerSlot == VideoPlayerSlot.primary);
      sources.requireSession();
      _profile = sources.profileId;
      _profileGeneration = sources.generation;
      entry = item;
      files = List.unmodifiable(selected);
      _localOverrides = Map.unmodifiable(localOverrides);
      _persistProgress = persistProgress;
      _liveInput = liveInput;
      _temporaryMediaFiles = List.unmodifiable(temporaryMediaFiles);
      mode = requestedMode;
      _useEntryChapters =
          selected.length == item.audio.length &&
          List.generate(
            selected.length,
            (i) => selected[i].fingerprint == item.audio[i].fingerprint,
          ).every((same) => same);
      chapters = _useEntryChapters ? item.chapters : const [];
      failure = null;
      _durations.clear();
      _fileChapters.clear();
      for (var i = 0; i < files.length; i++) {
        if ((files[i].durationMs ?? 0) > 0) _durations[i] = files[i].durationMs!;
      }
      final edition = sourceDigest(jsonEncode(files.map((f) => f.fingerprint).toList()));
      final initial = PublicationProgress(entryKey: item.key, edition: edition, mode: mode, session: const Uuid().v4());
      if (persistProgress) {
        progress = await sources.openProgress(item, initial);
        if (sources.cloudConflict(initial.key) ||
            await sources.repository.remoteConflict(_profile!, initial.key) != null) {
          throw const SourceException(SourceFailure.conflict);
        }
        sources.holdProgress(initial.key);
      } else {
        progress = initial;
      }
      _undoSeek = null;
      if (persistProgress && progress!.finished) {
        progress = await sources.repository.saveProgress(
          _profile!,
          progress!.copyWith(positionMs: 0, filePositionMs: 0, fileIndex: 0, fraction: 0, finished: false),
          kind: 'restart',
        );
      }
      final specific = await sources.repository.preference(_profile!, 'playback:$edition');
      final settings = {...await sources.repository.preference(_profile!, 'playback-defaults'), ...specific};
      chapterTimeline = settings['chapterTimeline'] == true;
      smartRewind = settings['smartRewind'] as bool? ?? true;
      backwardSeconds = (sourceInt(settings['backwardSeconds']) ?? 15).clamp(5, 120);
      forwardSeconds = (sourceInt(settings['forwardSeconds']) ?? 30).clamp(5, 120);
      if (!_valid) {
        await _stop();
        return;
      }
      _fileIndex = progress!.fileIndex.clamp(0, files.length - 1);
      var localPosition = progress!.filePositionMs;
      if (hasCompleteTimeline) {
        _fileIndex = _indexAt(progress!.positionMs);
        localPosition = progress!.positionMs - _offset;
      }
      if (smartRewind && progress!.updatedAt > 0 && !progress!.finished) {
        final away = DateTime.now().millisecondsSinceEpoch - progress!.updatedAt;
        final rewind = away > 300000
            ? 15000
            : away > 30000
            ? 5000
            : 0;
        if (hasCompleteTimeline) {
          final target = math.max(0, progress!.positionMs - rewind);
          _fileIndex = _indexAt(target);
          localPosition = target - _offset;
        } else {
          localPosition = math.max(0, localPosition - rewind);
        }
      }
      // Unknown-duration multipart books persist file-relative time explicitly.
      _gateway = SourceStreamGateway(valid: () => _valid && entry == item);
      final native =
          _playerFactory?.call(video) ??
          (video ? Player(companionSession: videoPlayerSlot == VideoPlayerSlot.companion) : Player.audio());
      player = native;
      await native.setWorkspaceAudioFocusEnabled(_workspaceAudioEnabled);
      await native.setVolume(_workspaceAudioEnabled ? 100 : 0);
      _controls = _controlsFactory();
      await _controls!.setBackgroundMode(
        !video &&
            (!PlatformDetector.isAutomotive() ||
                CarUxRestrictionsService.instance.state != CarUxRestrictionState.unknown &&
                    automotivePlaybackAllowedNow()),
      );
      _subscriptions.add(_controls!.controlEvents.listen(_onControl));
      _hardware = MusicHardwareTransportHandler(
        hasActiveSession: () => _valid && active,
        onPlay: () => unawaited(play()),
        onPause: () => unawaited(pause()),
        onTogglePlayPause: () => unawaited(toggle()),
        onNext: () => unawaited(nextChapter()),
        onPrevious: () => unawaited(previousChapter()),
        onStop: () => unawaited(stop()),
        onSkipForward: () => unawaited(skip(forwardSeconds)),
        onSkipBackward: () => unawaited(skip(-backwardSeconds)),
      )..register();
      await _controls!.setControlsEnabled(
        canPlayPause: true,
        canSeek: !_liveInput,
        canGoNext: true,
        canGoPrevious: true,
        canStop: true,
        canSkip: !_liveInput,
        canSetSpeed: true,
        preferSkipOverTrackButtons: true,
        skipInterval: Duration(seconds: backwardSeconds),
      );
      final generation = ++_generation;
      bool current() => _valid && generation == _generation && player == native;
      _subscriptions.add(
        native.streams.position.listen((_) {
          if (!current()) return;
          if (_sleepAtMs != null && positionMs >= _sleepAtMs!) {
            _sleepBoundaryFile = _fileIndex;
            clearSleep();
            unawaited(pause());
          }
          unawaited(
            _controls?.updatePlaybackState(
              isPlaying: playing,
              position: Duration(milliseconds: positionMs),
              speed: speed,
            ),
          );
          _notify();
        }),
      );
      _subscriptions.add(
        native.streams.playing.listen((playing) {
          if (current()) {
            unawaited(_wakelock.setEnabled(video && playing));
            _notify();
          }
        }),
      );
      _subscriptions.add(
        native.streams.duration.listen((duration) {
          if (!current() || opening || duration.inMilliseconds <= 0) return;
          _durations[_fileIndex] = duration.inMilliseconds;
          _rebuildChapters();
          _notify();
        }),
      );
      _subscriptions.add(
        native.streams.fileLoaded.listen((_) {
          if (current()) unawaited(_readChapters(native, generation, _fileIndex));
        }),
      );
      _subscriptions.add(
        native.streams.error.listen((_) {
          if (current()) {
            failure = SourceFailure.unavailable;
            opening = false;
            _notify();
          }
        }),
      );
      _subscriptions.add(
        native.streams.completed.listen((completed) {
          if (!completed || !current() || opening || _completedEpoch == _fileEpoch) return;
          final epoch = _fileEpoch;
          _completedEpoch = epoch;
          unawaited(
            _serialize(() async {
              if (!current() || _fileEpoch != epoch) return;
              if (_sleepBoundaryFile == _fileIndex ||
                  (_sleepAtMs != null && _offset + (_durations[_fileIndex] ?? 0) >= _sleepAtMs!) ||
                  (_sleepUntilFile != null && _fileIndex >= _sleepUntilFile!)) {
                _sleepBoundaryFile = _fileIndex;
                clearSleep();
                await native.pause();
                _pausedAt = DateTime.now();
                await _persist();
                _notify();
                return;
              }
              if (_fileIndex + 1 < files.length) {
                await _persist();
                await _openFile(_fileIndex + 1, 0);
              } else {
                await _persist(finished: true);
                await native.pause();
                _notify();
              }
            }),
          );
        }),
      );
      await _openFile(_fileIndex, localPosition);
      _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_valid && active) unawaited(_persist());
      });
    } catch (_) {
      await _stop();
      rethrow;
    }
  });
  Future<void> applyExternalSubtitle({required String name, required List<int> bytes}) async {
    final native = player;
    final profile = _profile;
    if (!_valid || !video || native == null || profile == null) {
      throw const SourceException(SourceFailure.cancelled);
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final requestedExtension = p.extension(name).toLowerCase();
    final extension = const {'.srt', '.ass', '.ssa', '.vtt', '.sub'}.contains(requestedExtension)
        ? requestedExtension
        : '.srt';
    final directory = Directory(p.join(sources.downloads.directory.path, sourceDigest(profile), 'external-subtitles'));
    await directory.create(recursive: true);
    if (!_valid || native != player) throw const SourceException(SourceFailure.cancelled);
    final file = File(p.join(directory.path, '${const Uuid().v4()}$extension'));
    try {
      await file.writeAsBytes(bytes, flush: true);
      if (!_valid || native != player) throw const SourceException(SourceFailure.cancelled);
      await native.command(['sub-add', file.path, 'select']);
      if (!_valid || native != player) throw const SourceException(SourceFailure.cancelled);
      _temporarySubtitles.add(file);
      _notify();
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  int _indexAt(int absolute) {
    var total = 0;
    for (var i = 0; i < files.length; i++) {
      total += _durations[i] ?? 0;
      if (absolute < total) return i;
    }
    return files.length - 1;
  }

  Future<void> _openFile(int index, int localPosition, {bool play = true}) async {
    if (!_valid || player == null) return;
    if (_streamRecordingPartial != null && index != _fileIndex) {
      try {
        await stopStreamRecording();
      } on SourceException catch (error) {
        if (error.reason != SourceFailure.invalidData) rethrow;
      }
    }
    opening = true;
    _fileEpoch++;
    _notify();
    _fileIndex = index;
    final file = files[index], item = entry!, native = player!;
    final cached = await sources.downloads.local(_profile!, item.sourceId, file);
    final Uri uri;
    if (_localOverrides[file.id] != null) {
      final override = _localOverrides[file.id]!;
      uri = const {'http', 'https'}.contains(override.scheme) ? await _gateway!.registerUri(override) : override;
    } else if (cached != null) {
      uri = cached.uri;
    } else {
      final adapter = sources.adapter(item.sourceId);
      if (adapter.source.kind == FileSourceKind.local) {
        uri = (await adapter.resolve(file)).uri;
      } else {
        uri = await _gateway!.register(adapter, file);
      }
    }
    if (!_valid || player != native) return;
    if (const {'rtsp', 'rtmp', 'rtmps', 'udp', 'rtp', 'dvd', 'bd', 'cdda'}.contains(uri.scheme) &&
        native.playerType != 'mpv') {
      throw const SourceException(SourceFailure.unsupported);
    }
    if (!PlatformDetector.isAutomotive()) unawaited(NotificationPermission.ensure());
    await native.requestAudioFocus();
    await native.open(
      Media(uri.toString(), start: Duration(milliseconds: math.max(0, localPosition))),
      play: play && automotivePlaybackAllowedNow(),
    );
    await native.setRate(speed);
    if (!_valid || player != native) return;
    await _controls?.updateFileMetadata(
      title: item.displayTitle,
      author: item.narrator.isEmpty ? item.author : item.narrator,
      duration: hasCompleteTimeline ? Duration(milliseconds: durationMs) : null,
    );
    final measured = native.state.duration.inMilliseconds;
    if (measured > 0) _durations[index] = measured;
    _rebuildChapters();
    opening = false;
    _notify();
  }

  Future<void> _readChapters(Player native, int generation, int index) async {
    try {
      final raw = await native.getProperty('chapter-list');
      if (!_valid || generation != _generation || index != _fileIndex || raw == null) return;
      final rows = sourceList(jsonDecode(raw)).map(sourceMap).toList();
      _fileChapters[index] = List.generate(
        rows.length,
        (i) => BookChapter(
          title: rows[i]['title'] as String? ?? '${i + 1}',
          startMs: ((rows[i]['time'] as num? ?? 0) * 1000).round(),
          endMs: i + 1 < rows.length ? ((rows[i + 1]['time'] as num? ?? 0) * 1000).round() : (_durations[index] ?? 0),
        ),
      );
      _rebuildChapters();
      _notify();
    } catch (_) {
      /* A container without chapter metadata still has file navigation. */
    }
  }

  void _rebuildChapters() {
    if (_useEntryChapters && entry?.chapters.isNotEmpty == true) return;
    final result = <BookChapter>[];
    var offset = 0;
    for (var i = 0; i < files.length; i++) {
      final embedded = _fileChapters[i];
      if (embedded?.isNotEmpty == true) {
        for (final c in embedded!) {
          result.add(BookChapter(title: c.title, startMs: offset + c.startMs, endMs: offset + c.endMs));
        }
      } else {
        result.add(BookChapter(title: files[i].name, startMs: offset, endMs: offset + (_durations[i] ?? 0)));
      }
      offset += _durations[i] ?? 0;
    }
    chapters = result;
  }

  Future<void> _persist({bool? finished}) {
    if (!_persistProgress) return Future.value();
    final item = entry, profile = _profile, current = progress, native = player;
    if (item == null || profile == null || current == null || native == null) return Future.value();
    final index = _fileIndex, position = positionMs, filePosition = native.currentPosition.inMilliseconds;
    final fraction = hasCompleteTimeline && durationMs > 0
        ? (positionMs / durationMs).clamp(0.0, 1.0)
        : current.fraction;
    final future = _writes.then((_) async {
      final latest = progress;
      if (latest == null || latest.key != current.key) return;
      progress = await sources.repository.saveProgress(
        profile,
        latest.copyWith(
          positionMs: position,
          filePositionMs: filePosition,
          fileIndex: index,
          fraction: fraction,
          finished: finished,
        ),
        kind: finished == true ? 'finished' : 'position',
      );
    });
    _writes = future.catchError((Object error) {
      failure = error is SourceException ? error.reason : SourceFailure.unavailable;
      _notify();
    });
    return _writes;
  }

  Future<void> play() => _serialize(() async {
    if (!_valid || player == null || !automotivePlaybackAllowedNow()) return;
    if (_persistProgress && !playing && progress != null && entry != null) {
      final old = progress!;
      sources.releaseProgress(old.key);
      try {
        final latest = await sources.openProgress(entry!, old);
        if (!_valid) return;
        if (sources.cloudConflict(old.key) || await sources.repository.remoteConflict(_profile!, old.key) != null) {
          throw const SourceException(SourceFailure.conflict);
        }
        if (latest.revision != old.revision) {
          progress = latest;
          final index = latest.fileIndex.clamp(0, files.length - 1);
          if (index != _fileIndex) {
            await _openFile(index, latest.filePositionMs, play: false);
          } else {
            await player!.seek(Duration(milliseconds: latest.filePositionMs));
          }
          await player!.setRate(latest.speed);
        }
      } finally {
        if (_valid) sources.holdProgress(old.key);
      }
    }
    if (_sleepBoundaryFile == _fileIndex && _completedEpoch == _fileEpoch && _fileIndex + 1 < files.length) {
      await _openFile(_fileIndex + 1, 0, play: false);
    }
    _sleepBoundaryFile = null;
    if (smartRewind && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!).inSeconds;
      final rewind = away > 300
          ? 15
          : away > 30
          ? 5
          : 0;
      if (rewind > 0) await _seek(math.max(0, positionMs - rewind * 1000));
    }
    _pausedAt = null;
    await player!.play();
    _notify();
  });
  Future<void> pause() => _serialize(() async {
    await player?.pause();
    _pausedAt = DateTime.now();
    await _persist();
    if (_persistProgress) sources.scheduleSync();
    _notify();
  });
  Future<void> toggle() => playing ? pause() : play();
  Future<void> seek(int milliseconds) => _serialize(() async {
    if (!_valid || player == null) return;
    _undoSeek = (file: _fileIndex, position: currentFilePositionMs);
    await _seek(milliseconds);
  });
  Future<void> seekBookmark(BookAnnotation annotation) => _serialize(() async {
    if (!_valid || player == null) return;
    _undoSeek = (file: _fileIndex, position: currentFilePositionMs);
    final index = annotation.fileIndex, offset = annotation.filePositionMs;
    if (!hasCompleteTimeline && index != null && offset != null) {
      if (index < 0 || index >= files.length || offset < 0) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final shouldPlay = playing;
      await _persist();
      await _openFile(index, offset, play: shouldPlay);
      await _persist();
      _notify();
    } else if (annotation.positionMs != null) {
      await _seek(annotation.positionMs!);
    }
  });
  Future<void> undoSeek() => _serialize(() async {
    final previous = _undoSeek;
    if (!_valid || previous == null || player == null) return;
    _undoSeek = null;
    final shouldPlay = playing;
    if (previous.file != _fileIndex) {
      await _openFile(previous.file, previous.position, play: shouldPlay);
    } else {
      await player!.seek(Duration(milliseconds: previous.position));
    }
    await _persist();
    _notify();
  });
  Future<void> _seek(int milliseconds) async {
    if (!_valid || player == null || _liveInput) return;
    final maximum = hasCompleteTimeline
        ? durationMs
        : (_durations[_fileIndex] ?? player!.state.duration.inMilliseconds) + _offset;
    final target = milliseconds.clamp(0, math.max(0, maximum)).toInt();
    final index = hasCompleteTimeline ? _indexAt(target) : _fileIndex;
    final shouldPlay = playing;
    if (index != _fileIndex) {
      await _persist();
      var offset = 0;
      for (var i = 0; i < index; i++) {
        offset += _durations[i] ?? 0;
      }
      await _openFile(index, target - offset, play: shouldPlay);
    } else {
      await player!.seek(Duration(milliseconds: math.max(0, target - _offset)));
    }
    await _persist();
    _notify();
  }

  Future<void> seekChapter(int index) async {
    if (index < 0 || index >= chapters.length) return;
    if (!hasCompleteTimeline && chapters.length == files.length) {
      await _serialize(() async {
        _undoSeek = (file: _fileIndex, position: currentFilePositionMs);
        final shouldPlay = playing;
        await _persist();
        await _openFile(index, 0, play: shouldPlay);
      });
    } else {
      await seek(chapters[index].startMs);
    }
  }

  Future<void> skip(int seconds) => _liveInput ? Future.value() : seek(positionMs + seconds * 1000);
  Future<void> nextChapter() async {
    if (!hasCompleteTimeline && chapters.length == files.length) {
      if (_fileIndex + 1 < files.length) await seekChapter(_fileIndex + 1);
      return;
    }
    final next = chapters.where((c) => c.startMs > positionMs + 500).firstOrNull;
    if (next != null) {
      await seek(next.startMs);
    } else if (_fileIndex + 1 < files.length) {
      await _serialize(() async {
        await _persist();
        await _openFile(_fileIndex + 1, 0);
      });
    }
  }

  Future<void> previousChapter() async {
    if (!hasCompleteTimeline && chapters.length == files.length) {
      await seekChapter(currentFilePositionMs > 3000 ? _fileIndex : math.max(0, _fileIndex - 1));
      return;
    }
    final previous = chapters.where((c) => c.startMs < positionMs - 3000).lastOrNull;
    if (previous != null) {
      await seek(previous.startMs);
    } else {
      await seek(0);
    }
  }

  Future<void> setSpeed(double value) => _serialize(() async {
    if (!value.isFinite || value < .25 || value > 8) throw const SourceException(SourceFailure.invalidData);
    await player?.setRate(value);
    progress = progress?.copyWith(speed: value);
    await _persist();
    _notify();
  });
  Future<void> savePreferences({bool asDefault = false}) async {
    if (!_persistProgress || _profile == null || progress == null) return;
    final settings = <String, dynamic>{
      'chapterTimeline': chapterTimeline,
      'smartRewind': smartRewind,
      'backwardSeconds': backwardSeconds,
      'forwardSeconds': forwardSeconds,
    };
    await sources.repository.savePreference(_profile!, 'playback:${progress!.edition}', settings);
    if (asDefault) await sources.repository.savePreference(_profile!, 'playback-defaults', settings);
    await _controls?.setControlsEnabled(
      canPlayPause: true,
      canSeek: !_liveInput,
      canGoNext: true,
      canGoPrevious: true,
      canStop: true,
      canSkip: !_liveInput,
      canSetSpeed: true,
      preferSkipOverTrackButtons: true,
      skipInterval: Duration(seconds: backwardSeconds),
    );
    _notify();
  }

  void sleepFor(Duration duration) {
    if (duration <= Duration.zero || duration > const Duration(hours: 24)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    clearSleep();
    sleepDeadline = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      clearSleep();
      unawaited(pause());
    });
    _notify();
  }

  void extendSleep(Duration duration) {
    final left = sleepDeadline?.difference(DateTime.now()) ?? Duration.zero;
    sleepFor((left.isNegative ? Duration.zero : left) + duration);
  }

  void sleepAfterChapter({int count = 1}) {
    if (count < 1 || count > 100) throw const SourceException(SourceFailure.invalidData);
    clearSleep();
    if (hasCompleteTimeline && chapters.isNotEmpty) {
      final current = chapters.indexOf(currentChapter ?? chapters.first);
      final index = (current + count - 1).clamp(0, chapters.length - 1);
      _sleepAtMs = chapters[index].endMs > 0 ? chapters[index].endMs : durationMs;
    } else {
      _sleepUntilFile = (_fileIndex + count - 1).clamp(0, files.length - 1);
    }
    _notify();
  }

  bool get sleepEnabled => _sleepTimer != null || _sleepAtMs != null || _sleepUntilFile != null;
  void clearSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAtMs = null;
    _sleepUntilFile = null;
    sleepDeadline = null;
    _notify();
  }

  Future<void> bookmark({String note = ''}) async {
    if (!_persistProgress || entry == null || progress == null || _profile == null) return;
    await sources.repository.saveAnnotation(
      _profile!,
      BookAnnotation(
        id: const Uuid().v4(),
        entryKey: entry!.key,
        edition: progress!.edition,
        mode: mode,
        positionMs: positionMs,
        fileIndex: _fileIndex,
        filePositionMs: currentFilePositionMs,
        note: note,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    sources.scheduleSync();
  }

  void _onControl(MediaControlEvent event) {
    if (!_valid || entry == null) return;
    final router = MediaControlRouter(
      canControlPlayback: () => true,
      canNavigateMediaItems: automotivePlaybackAllowedNow,
      onPlay: () => unawaited(play()),
      onPause: () => unawaited(pause()),
      onTogglePlayPause: () => unawaited(toggle()),
      onSeek: (p) {
        if (!_liveInput) unawaited(seek(p.inMilliseconds));
      },
      onNext: () => unawaited(nextChapter()),
      onPrevious: () => unawaited(previousChapter()),
      onStop: () => unawaited(stop()),
      onSkipForward: (d) {
        if (!_liveInput) unawaited(skip(d?.inSeconds ?? forwardSeconds));
      },
      onSkipBackward: (d) {
        if (!_liveInput) unawaited(skip(-(d?.inSeconds ?? backwardSeconds)));
      },
      onSetSpeed: (s) => unawaited(setSpeed(s)),
    );
    if (router.route(event)) return;
    if (event is AudioRouteOldDeviceUnavailableEvent) {
      _resumeAfterInterruption = false;
      unawaited(pause());
    } else if (event is AudioInterruptionBeganEvent) {
      _resumeAfterInterruption = playing;
      unawaited(pause());
    } else if (event is AudioInterruptionEndedEvent) {
      final resume = event.shouldResume && _resumeAfterInterruption;
      _resumeAfterInterruption = false;
      if (resume) unawaited(play());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(_persist());
      if (video || PlatformDetector.isTV()) unawaited(pause());
    }
  }

  Future<void> stop() => _serialize(_stop);
  Future<void> _stop() async {
    Object? error;
    StackTrace? stack;
    Future<void> release(FutureOr<void> Function() action) async {
      try {
        await action();
      } catch (e, trace) {
        error ??= e;
        stack ??= trace;
      }
    }

    await _wakelock.setEnabled(false);
    _saveTimer?.cancel();
    _saveTimer = null;
    clearSleep();
    await _persist();
    await _writes;
    await release(() async {
      await stopStreamRecording();
    });
    if (_persistProgress && progress != null) sources.releaseProgress(progress!.key);
    _pausedAt = null;
    _sleepBoundaryFile = null;
    _undoSeek = null;
    if (_persistProgress) sources.scheduleSync();
    _generation++;
    for (final sub in _subscriptions) {
      await release(sub.cancel);
    }
    _subscriptions.clear();
    await release(() => _hardware?.unregister());
    _hardware = null;
    final native = player;
    player = null;
    final videoLease = _videoPlayerLease;
    _videoPlayerLease = null;
    videoPlayerSlot = null;
    if (_pictureAdjustmentTouched && native?.playerType == 'mpv') {
      for (final property in const ['brightness', 'contrast', 'gamma', 'hue', 'saturation']) {
        await release(() async => native!.setProperty(property, '0'));
      }
      try {
        await native!.command(['vf', 'del', '@plezy360']);
      } on Object {
        // The filter may already have left the playback chain.
      }
    }
    _pictureAdjustmentTouched = false;
    await release(() async => native?.stop());
    await release(() async => native?.dispose());
    videoLease?.release();
    for (final file in _temporarySubtitles) {
      await release(() async {
        if (await file.exists()) await file.delete();
      });
    }
    _temporarySubtitles.clear();
    for (final file in _temporaryMediaFiles) {
      await release(() async {
        if (await file.exists()) await file.delete();
      });
    }
    _temporaryMediaFiles = const [];
    await release(() async => _controls?.clear());
    await release(() => _controls?.dispose());
    _controls = null;
    await release(() async => _gateway?.close());
    _gateway = null;
    entry = null;
    files = const [];
    _localOverrides = const {};
    _persistProgress = true;
    _liveInput = false;
    progress = null;
    opening = false;
    _notify();
    if (error != null) Error.throwWithStackTrace(error!, stack!);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    CarUxRestrictionsService.instance.listenable.removeListener(_carChanged);
    PlaybackCoordinator.instance.unregisterFileSession(stop);
    if (sources.stopPlayback == stop) sources.stopPlayback = null;
    unawaited(stop());
    super.dispose();
  }
}
