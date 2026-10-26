import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:uuid/uuid.dart';

import '../mpv/mpv.dart';
import '../services/media_control_router.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_coordinator.dart';
import '../services/music/music_hardware_transport.dart';
import '../services/driver_distraction.dart';
import '../services/car_ux_restrictions_service.dart';
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
    Player Function(bool video)? playerFactory,
    MediaControlsManager Function()? controlsFactory,
    WakelockPlatformToggle? wakelockToggle,
  }) : _playerFactory = playerFactory ?? ((video) => video ? Player() : Player.audio()),
       _wakelock = WakelockController(platformToggle: wakelockToggle),
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
  final Player Function(bool) _playerFactory;
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
  bool _disposed = false;
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
  SourceStreamGateway? _gateway;
  MediaControlsManager? _controls;
  MusicHardwareTransportHandler? _hardware;
  Future<void> _commands = Future.value();
  Future<void> _writes = Future.value();
  Timer? _saveTimer;
  Timer? _sleepTimer;
  int? _sleepAtMs;
  DateTime? sleepDeadline;
  DateTime? _pausedAt;
  bool smartRewind = true;
  int backwardSeconds = 15;
  int forwardSeconds = 30;
  bool get active => entry != null;
  bool get video => mode == PublicationMode.watching;
  bool get playing => player?.state.isActive ?? false;
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
  }) => _serialize(() async {
    await _stop();
    try {
      sources.requireSession();
      if (selected.isEmpty) throw const SourceException(SourceFailure.unsupported);
      if (PlatformDetector.isAutomotive()) await CarUxRestrictionsService.instance.ensureResolved();
      await PlaybackCoordinator.instance.claimFiles();
      sources.requireSession();
      _profile = sources.profileId;
      _profileGeneration = sources.generation;
      entry = item;
      files = List.unmodifiable(selected);
      _localOverrides = Map.unmodifiable(localOverrides);
      mode = playbackMode ?? (item.kind == SourceItemKind.video ? PublicationMode.watching : PublicationMode.listening);
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
      progress = await sources.openProgress(item, initial);
      if (await sources.repository.remoteConflict(_profile!, initial.key) != null) {
        throw const SourceException(SourceFailure.conflict);
      }
      if (progress!.finished) {
        progress = await sources.repository.saveProgress(
          _profile!,
          progress!.copyWith(positionMs: 0, filePositionMs: 0, fileIndex: 0, fraction: 0, finished: false),
          kind: 'restart',
        );
      }
      final settings = await sources.repository.preference(_profile!, 'playback:$edition');
      smartRewind = settings['smartRewind'] as bool? ?? true;
      backwardSeconds = (sourceInt(settings['backwardSeconds']) ?? 15).clamp(5, 120);
      forwardSeconds = (sourceInt(settings['forwardSeconds']) ?? 30).clamp(5, 120);
      if (!_valid) return;
      _fileIndex = progress!.fileIndex.clamp(0, files.length - 1);
      var localPosition = progress!.filePositionMs;
      if (hasCompleteTimeline) {
        _fileIndex = _indexAt(progress!.positionMs);
        localPosition = progress!.positionMs - _offset;
      }
      // Unknown-duration multipart books persist file-relative time explicitly.
      _gateway = SourceStreamGateway(valid: () => _valid && entry == item);
      final native = _playerFactory(video);
      player = native;
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
        canSeek: true,
        canGoNext: true,
        canGoPrevious: true,
        canStop: true,
        canSkip: true,
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
    opening = true;
    _fileEpoch++;
    _notify();
    _fileIndex = index;
    final file = files[index], item = entry!, native = player!;
    final cached = await sources.downloads.local(_profile!, item.sourceId, file);
    final Uri uri;
    if (_localOverrides[file.id] != null) {
      uri = _localOverrides[file.id]!;
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
    _notify();
  });
  Future<void> toggle() => playing ? pause() : play();
  Future<void> seek(int milliseconds) => _serialize(() => _seek(milliseconds));
  Future<void> _seek(int milliseconds) async {
    if (!_valid || player == null) return;
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
        await _persist();
        await _openFile(index, 0);
      });
    } else {
      await seek(chapters[index].startMs);
    }
  }

  Future<void> skip(int seconds) => seek(positionMs + seconds * 1000);
  Future<void> nextChapter() async {
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
  Future<void> savePreferences() async {
    if (_profile == null || progress == null) return;
    await sources.repository.savePreference(_profile!, 'playback:${progress!.edition}', {
      'smartRewind': smartRewind,
      'backwardSeconds': backwardSeconds,
      'forwardSeconds': forwardSeconds,
    });
    _notify();
  }

  void sleepFor(Duration duration) {
    clearSleep();
    sleepDeadline = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      clearSleep();
      unawaited(pause());
    });
    _notify();
  }

  void sleepAfterChapter() {
    clearSleep();
    _sleepAtMs = currentChapter?.endMs ?? (_offset + (_durations[_fileIndex] ?? 0));
    _notify();
  }

  bool get sleepEnabled => _sleepTimer != null || _sleepAtMs != null;
  void clearSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAtMs = null;
    sleepDeadline = null;
    _notify();
  }

  Future<void> bookmark({String note = ''}) async {
    if (entry == null || progress == null || _profile == null) return;
    await sources.repository.saveAnnotation(
      _profile!,
      BookAnnotation(
        id: const Uuid().v4(),
        entryKey: entry!.key,
        edition: progress!.edition,
        mode: mode,
        positionMs: positionMs,
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
      onSeek: (p) => unawaited(seek(p.inMilliseconds)),
      onNext: () => unawaited(nextChapter()),
      onPrevious: () => unawaited(previousChapter()),
      onStop: () => unawaited(stop()),
      onSkipForward: (d) => unawaited(skip(d?.inSeconds ?? forwardSeconds)),
      onSkipBackward: (d) => unawaited(skip(-(d?.inSeconds ?? backwardSeconds))),
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
    sources.scheduleSync();
    _generation++;
    for (final sub in _subscriptions) {
      await release(sub.cancel);
    }
    _subscriptions.clear();
    await release(() => _hardware?.unregister());
    _hardware = null;
    final native = player;
    player = null;
    await release(() async => native?.stop());
    await release(() async => native?.dispose());
    await release(() async => _controls?.clear());
    await release(() => _controls?.dispose());
    _controls = null;
    await release(() async => _gateway?.close());
    _gateway = null;
    entry = null;
    files = const [];
    _localOverrides = const {};
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
