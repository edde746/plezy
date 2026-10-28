import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../mpv/mpv.dart';
import '../services/media_control_router.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_coordinator.dart';
import '../services/settings_service.dart';
import '../services/music/music_hardware_transport.dart';
import '../services/player_sync_offsets.dart';
import '../services/scoped_player_prefs.dart';
import '../services/music/music_playback_service.dart';
import '../services/driver_distraction.dart';
import '../services/car_ux_restrictions_service.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../utils/subtitle_forced_semantics.dart';
import '../utils/notification_permission.dart';
import '../screens/video_player/wakelock_controller.dart';
import 'content_access.dart';
import 'source_controller.dart';
import 'source_models.dart';

typedef LocalPlaylistExportItem = ({String title, Uri uri});

/// The book session owns source-time progress independently of the music queue.
/// Commands serialize, and each native generation ignores stale event delivery.
class SourcePlayback extends ChangeNotifier with WidgetsBindingObserver {
  SourcePlayback(
    this.sources, {
    this._playerFactory,
    MediaControlsManager Function()? controlsFactory,
    WakelockPlatformToggle? wakelockToggle,
    math.Random? shuffleRandom,
  }) : _shuffleRandom = shuffleRandom ?? math.Random(),
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
  final math.Random _shuffleRandom;
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
  Map<String, String> _directPlayerAddresses = const {};
  Map<String, String> _localPlayerOptions = const {};
  bool _persistProgress = true;
  bool _liveInput = false;
  List<File> _temporaryMediaFiles = const [];
  File? _streamRecordingTarget;
  File? _streamRecordingPartial;
  File? _streamRecordingBackup;
  bool _pictureAdjustmentTouched = false;
  bool _disposed = false;
  bool _workspaceAudioEnabled = true;
  bool _userMuted = false;
  int _subtitleMuteGeneration = 0;
  Future<void> _subtitleMuteQueue = Future<void>.value();
  ({Player player, int fileIndex, String fingerprint, SubtitleTrack previousTrack, String temporaryTrackId})?
  _subtitleMuteRestore;
  bool _resumeAfterInterruption = false;
  bool _useEntryChapters = false;
  int _fileEpoch = 0;
  int _completedEpoch = -1;
  String? _profile;
  int _profileGeneration = 0;
  int _generation = 0;
  int _fileIndex = 0;
  List<int> _queueOrder = const [];
  bool _queueShuffled = false;
  MusicRepeatMode _queueRepeatMode = MusicRepeatMode.off;
  int _lastKnownFilePositionMs = 0;
  int? _failedFilePositionMs;
  final Map<int, int> _durations = {};
  final Map<int, List<BookChapter>> _fileChapters = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<File> _temporarySubtitles = [];
  SourceStreamGateway? _gateway;
  MediaControlsManager? _controls;
  MusicHardwareTransportHandler? _hardware;
  Future<void> _commands = Future.value();
  Future<void> _subtitleSyncWrites = Future.value();
  Future<void> _writes = Future.value();
  String? _selectedExternalSubtitlePath;
  String? _activeExternalSubtitleSyncBinding;
  Timer? _saveTimer;
  Timer? _sleepTimer;
  int? _sleepAtMs;
  int? _sleepUntilQueuePosition;
  int? _sleepBoundaryFile;
  int? _sleepChapterFile;
  int? _sleepChapterFilePosition;
  ({int file, int position})? _undoSeek;
  bool chapterTimeline = false;
  DateTime? sleepDeadline;
  DateTime? _pausedAt;
  bool smartRewind = true;
  int backwardSeconds = 15;
  int forwardSeconds = 30;
  bool get canUndoSeek => _undoSeek != null;
  bool get muted => _userMuted;
  int get currentFilePositionMs => _failedFilePositionMs ?? _lastKnownFilePositionMs;
  bool get canRetry =>
      _valid &&
      player != null &&
      files.isNotEmpty &&
      !opening &&
      (failure == SourceFailure.unavailable || failure == SourceFailure.authentication);
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
      : _offset   currentFileDurationMs;
  int? get bookRemainingMs =>
      hasCompleteTimeline ? ((durationMs - positionMs).clamp(0, durationMs) / speed).round() : null;
  int? get chapterRemainingMs => currentChapter != null && currentChapter!.endMs > positionMs
      ? ((currentChapter!.endMs - positionMs) / speed).round()
      : null;
  bool get active => entry != null;
  bool get video => mode == PublicationMode.watching;
  bool get isTransientInput => !_persistProgress;
  bool get isLiveInput => _liveInput;
  bool get isCapturePreview =>
      _fileIndex >= 0 && _fileIndex < files.length && _directPlayerAddresses.containsKey(files[_fileIndex].id);
  bool get isRecordingStream => _streamRecordingPartial != null;
  bool get hasSelectedPersistentExternalSubtitle => _isSelectedExternalSubtitlePath(
    player?.state.track.subtitle,
    _selectedExternalSubtitlePath,
  );
  File? get activePersistentExternalSubtitleFile {
    final path = _selectedExternalSubtitlePath;
    return hasSelectedPersistentExternalSubtitle && path != null ? File(path) : null;
  }
  bool get canExportActiveExternalSubtitle {
    final file = activePersistentExternalSubtitleFile;
    return file != null && const {'.srt', '.vtt', '.ass', '.ssa'}.contains(p.extension(file.path).toLowerCase());
  }
  String? get activeExternalSubtitleIdentity {
    final native = player;
    final selectedPath = _selectedExternalSubtitlePath;
    final item = entry;
    if (native == null || selectedPath == null || item == null || files.isEmpty || _fileIndex < 0 || _fileIndex >= files.length) {
      return null;
    }
    return [item.key, progress?.edition ?? '', files[_fileIndex].fingerprint, selectedPath, _subtitleAudioIdentity(native)].join('|');
  }
  bool get playing => player?.state.isActive ?? false;
  bool get canUseDirectQueueControls =>
      isTransientInput &&
      !isLiveInput &&
      files.length > 1 &&
      (entry?.kind == SourceItemKind.music || entry?.kind == SourceItemKind.video);
  bool get queueShuffled => _queueShuffled;
  MusicRepeatMode get queueRepeatMode => _queueRepeatMode;
  int get currentQueuePosition => _queuePosition;
  List<int> get queueFileIndices => List.unmodifiable(_queueOrder);

  /// Whether the current queue can be offered for a same-folder M3U export.
  /// Temporary copies, network addresses, and picker paths without stable
  /// desktop-file semantics are deliberately excluded.
  bool get canExportLocalPlaylist {
    if (!PlatformDetector.isDesktopOS() || _temporaryMediaFiles.isNotEmpty || files.length < 2) return false;
    String normalizedParent(String value) {
      final normalized = p.normalize(value);
      return Platform.isWindows ? normalized.toLowerCase() : normalized;
    }

    String? parent;
    for (final index in _queueOrder) {
      final item = files[index];
      final uri = _localOverrides[item.id];
      if (uri == null || uri.scheme != 'file') return false;
      final path = p.normalize(uri.toFilePath());
      final currentParent = normalizedParent(p.dirname(path));
      if (parent != null && parent != currentParent) return false;
      parent = currentParent;
    }
    return true;
  }

  /// Returns validated durable local files only when they share a real folder.
  /// The caller writes only sibling names into the exported playlist.
  Future<List<LocalPlaylistExportItem>?> localPlaylistExportItems() async {
    if (!canExportLocalPlaylist) return null;
    final result = <LocalPlaylistExportItem>[];
    String? parent;
    for (final index in _queueOrder) {
      final item = files[index];
      try {
        final uri = _localOverrides[item.id]!;
        final path = await File.fromUri(uri).resolveSymbolicLinks();
        final file = File(path);
        if ((await file.stat()).type != FileSystemEntityType.file) return null;
        final kind = classifySourceFile(p.basename(path));
        if (kind != SourceItemKind.video && kind != SourceItemKind.music && kind != SourceItemKind.audiobook) {
          return null;
        }
        final currentParentRaw = p.dirname(path);
        final currentParent = Platform.isWindows ? currentParentRaw.toLowerCase() : currentParentRaw;
        if (parent != null && parent != currentParent) return null;
        parent = currentParent;
        result.add((title: item.name, uri: file.uri));
      } on FileSystemException {
        return null;
      }
    }
    return result.length == files.length ? List.unmodifiable(result) : null;
  }

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
      await native.setVolume(_userMuted ? 0 : 100);
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

  Future<void> setMuted(bool muted) async {
    if (_disposed || _userMuted == muted) return;
    _userMuted = muted;
    final generation = _subtitleMuteGeneration += 1;
    final native = player;
    if (native != null && !native.disposed) {
      await native.setVolume(_workspaceAudioEnabled && !muted ? 100 : 0);
      if (muted) {
        if (SettingsService.instance.read(SettingsService.subtitleOnMute) && video) {
          await _selectSubtitleForMute(native, generation);
        }
      } else {
        await _restoreSubtitleAfterMute(generation);
      }
    } else if (!muted) {
      await _restoreSubtitleAfterMute(generation);
    }
    _notify();
  }

  Future<void> _selectSubtitleForMute(
    Player native,
    int generation, {
    List<SubtitleTrack>? availableTracks,
  }) async {
    if (!_userMuted ||
        _disposed ||
        !video ||
        !identical(player, native) ||
        !SettingsService.instance.read(SettingsService.subtitleOnMute) ||
        _subtitleMuteRestore != null ||
        opening) {
      return;
    }
    final current = native.state.track.subtitle;
    if (current != null && current.id != SubtitleTrack.off.id && current.id != SubtitleTrack.auto.id) return;
    final tracks = (availableTracks ?? native.state.tracks.subtitle)
        .where((track) => track.id != SubtitleTrack.off.id && track.id != SubtitleTrack.auto.id)
        .toList(growable: false);
    if (tracks.isEmpty || _fileIndex < 0 || _fileIndex >= files.length) return;

    SubtitleTrack? candidate;
    for (final track in tracks) {
      if (track.isDefault && !track.effectiveForced) {
        candidate = track;
        break;
      }
    }
    if (candidate == null) {
      for (final track in tracks) {
        if (!track.effectiveForced) {
          candidate = track;
          break;
        }
      }
    }
    candidate ??= tracks.first;
    if (candidate.id == current?.id) return;
    final restore = (
      player: native,
      fileIndex: _fileIndex,
      fingerprint: files[_fileIndex].fingerprint,
      previousTrack: current ?? SubtitleTrack.off,
      temporaryTrackId: candidate.id,
    );
    _subtitleMuteRestore = restore;
    await _queueSubtitleMuteMutation(() async {
      if (generation != _subtitleMuteGeneration ||
          !_userMuted ||
          !identical(player, native) ||
          _fileIndex != restore.fileIndex ||
          _fileIndex < 0 ||
          _fileIndex >= files.length ||
          files[_fileIndex].fingerprint != restore.fingerprint) {
        return;
      }
      final selected = native.state.track.subtitle;
      if (selected != null && selected.id != SubtitleTrack.off.id && selected.id != SubtitleTrack.auto.id) {
        _subtitleMuteRestore = null;
        return;
      }
      await native.selectSubtitleTrack(candidate);
    });
  }

  Future<void> _restoreSubtitleAfterMute(int generation) async {
    final restore = _subtitleMuteRestore;
    if (restore == null) return;
    _subtitleMuteRestore = null;
    await _queueSubtitleMuteMutation(() async {
      if (generation != _subtitleMuteGeneration ||
          _userMuted ||
          !identical(player, restore.player) ||
          _fileIndex != restore.fileIndex ||
          _fileIndex < 0 ||
          _fileIndex >= files.length ||
          files[_fileIndex].fingerprint != restore.fingerprint) {
        return;
      }
      if (restore.player.state.track.subtitle?.id != restore.temporaryTrackId) return;
      await restore.player.selectSubtitleTrack(restore.previousTrack);
    });
  }

  Future<void> _queueSubtitleMuteMutation(Future<void> Function() action) async {
    final previous = _subtitleMuteQueue;
    final operation = previous.catchError((Object _, StackTrace __) {}).then((_) => action());
    _subtitleMuteQueue = operation.catchError((Object error, StackTrace stackTrace) {
      appLogger.w('Standalone subtitle-on-mute operation failed', error: error, stackTrace: stackTrace);
    });
    await _subtitleMuteQueue;
  }

  double get speed => progress?.speed ?? 1;
  int get fileIndex => _fileIndex;
  int get _queuePosition {
    final position = _queueOrder.indexOf(_fileIndex);
    return position < 0 ? 0 : position;
  }

  int get _offset => _offsetBefore(_fileIndex);
  int _offsetBefore(int fileIndex) {
    var offset = 0;
    for (final index in _queueOrder) {
      if (index == fileIndex) return offset;
      offset  = _durations[index] ?? 0;
    }
    return offset;
  }

  bool get hasCompleteTimeline => List.generate(files.length, (i) => _durations[i] ?? 0).every((d) => d > 0);
  int get durationMs => List.generate(files.length, (i) => _durations[i] ?? 0).fold(0, (a, b) => a   b);
  int get positionMs => _offset   currentFilePositionMs;

  Future<void> toggleQueueShuffle() => _serialize(() async {
    if (!canUseDirectQueueControls || _queueOrder.length < 2) return;
    final currentPosition = _queuePosition;
    final playedPrefix = _queueOrder.take(currentPosition   1).toList();
    final remaining = _queueOrder.skip(currentPosition   1).toList();
    if (_queueShuffled) {
      remaining.sort();
    } else {
      remaining.shuffle(_shuffleRandom);
    }
    _queueOrder = [...playedPrefix, ...remaining];
    _queueShuffled = !_queueShuffled;
    _rebuildChapters();
    if (_sleepChapterFile != null && _sleepChapterFilePosition != null) {
      _sleepAtMs = _offsetBefore(_sleepChapterFile!)   _sleepChapterFilePosition!;
    }
    _notify();
  });

  Future<void> setQueueRepeatMode(MusicRepeatMode mode) => _serialize(() async {
    if (!canUseDirectQueueControls || _queueRepeatMode == mode) return;
    _queueRepeatMode = mode;
    _notify();
  });

  Future<void> selectQueueFile(int fileIndex) => _serialize(() async {
    if (!canUseDirectQueueControls || !_queueOrder.contains(fileIndex) || player == null) return;
    if (fileIndex == _fileIndex) return;
    await _persist();
    await _openFile(fileIndex, 0);
  });

  int? _nextPlaybackFileIndex() {
    if (canUseDirectQueueControls) {
      final nextPosition = _queuePosition   1;
      if (nextPosition < _queueOrder.length) return _queueOrder[nextPosition];
      if (_queueRepeatMode == MusicRepeatMode.all) return _queueOrder.first;
      return null;
    }
    return _fileIndex   1 < files.length ? _fileIndex   1 : null;
  }

  int? _previousPlaybackFileIndex() {
    if (canUseDirectQueueControls) {
      final previousPosition = _queuePosition - 1;
      if (previousPosition >= 0) return _queueOrder[previousPosition];
      if (_queueRepeatMode == MusicRepeatMode.all) return _queueOrder.last;
      return null;
    }
    return _fileIndex > 0 ? _fileIndex - 1 : null;
  }

  /// Stable, non-reversible local key for a temporary direct-media item.
  /// The URL or filesystem path itself is never stored in bookmark settings.
  String? get localMediaBookmarkKey {
    if (!isTransientInput ||
        isLiveInput ||
        player?.state.seekable != true ||
        _fileIndex < 0 ||
        _fileIndex >= files.length ||
        currentFileDurationMs <= 0) {
      return null;
    }
    final uri = _localOverrides[files[_fileIndex].id];
    if (uri == null) return null;
    return 'open-media:${sourceDigest(uri.toString())}';
  }

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
    Map<String, String> directPlayerAddresses = const {},
    Map<String, String> localPlayerOptions = const {},
  }) => _serialize(() async {
    await _stop();
    try {
      sources.requireSession();
      if (selected.isEmpty) throw const SourceException(SourceFailure.unsupported);
      if (PlatformDetector.isAutomotive()) await CarUxRestrictionsService.instance.ensureResolved();
      final requestedMode =
          playbackMode ?? (item.kind == SourceItemKind.video ? PublicationMode.watching : PublicationMode.listening);
      if (directPlayerAddresses.isNotEmpty || localPlayerOptions.isNotEmpty) {
        const captureFormats = {'gdigrab', 'dshow', 'avfoundation', 'x11grab', 'v4l2'};
        const allowedOptions = {'demuxer-lavf-format', 'demuxer-lavf-o'};
        if (!PlatformDetector.isDesktopOS() ||
            persistProgress ||
            !liveInput ||
            requestedMode != PublicationMode.watching ||
            selected.length != 1 ||
            directPlayerAddresses.length != 1 ||
            directPlayerAddresses.keys.single != selected.single.id ||
            localPlayerOptions.keys.toSet().difference(allowedOptions).isNotEmpty) {
          throw const SourceException(SourceFailure.unsupported);
        }
        final format = localPlayerOptions['demuxer-lavf-format'];
        final options = localPlayerOptions['demuxer-lavf-o'];
        if (format == null ||
            !captureFormats.contains(format) ||
            options == null ||
            !RegExp(r'^framerate=(15|30|60)(,draw_mouse=1)?$').hasMatch(options) ||
            !directPlayerAddresses.values.single.startsWith('av://$format:')) {
          throw const SourceException(SourceFailure.unsupported);
        }
      }
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
      _queueOrder = List<int>.generate(files.length, (index) => index);
      _queueShuffled = false;
      _queueRepeatMode = MusicRepeatMode.off;
      _localOverrides = Map.unmodifiable(localOverrides);
      _directPlayerAddresses = Map.unmodifiable(directPlayerAddresses);
      _localPlayerOptions = Map.unmodifiable(localPlayerOptions);
      _persistProgress = persistProgress;
      _liveInput = liveInput;
      _temporaryMediaFiles = List.unmodifiable(temporaryMediaFiles);
      mode = requestedMode;
      _userMuted = false;
      _subtitleMuteRestore = null;
      _subtitleMuteGeneration += 1;
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
      for (var i = 0; i < files.length; i  ) {
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
      final generation =   _generation;
      bool current() => _valid && generation == _generation && player == native;
      _subscriptions.add(
        native.streams.position.listen((_) {
          if (!current() || opening || _failedFilePositionMs != null) return;
          final position = native.currentPosition.inMilliseconds;
          // Native backends can reset to zero immediately before reporting a
          // stream failure. Explicit seeks/open operations set zero themselves.
          if (position > 0 || _lastKnownFilePositionMs == 0) {
            _lastKnownFilePositionMs = math.max(0, position);
          }
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
        native.streams.track.listen((_) {
          if (current()) {
            _notify();
            unawaited(_reapplySelectedExternalSubtitleSyncForCurrentTrack());
          }
        }),
      );
      _subscriptions.add(
        native.streams.seekable.listen((_) {
          if (current()) _notify();
        }),
      );
      _subscriptions.add(
        native.streams.tracks.listen((tracks) {
          if (!current()) return;
          _notify();
          if (tracks.subtitle.isNotEmpty && _userMuted) {
            unawaited(_selectSubtitleForMute(native, _subtitleMuteGeneration, availableTracks: tracks.subtitle));
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
            _failedFilePositionMs ??= _lastKnownFilePositionMs;
            failure = SourceFailure.unavailable;
            opening = false;
            // Save the last reliable sample, never a decoder's reset position.
            unawaited(_persist());
            _notify();
          }
        }),
      );
      _subscriptions.add(
        native.streams.completed.listen((completed) {
          if (!completed || !current() || opening || failure != null || _completedEpoch == _fileEpoch) return;
          final epoch = _fileEpoch;
          _completedEpoch = epoch;
          unawaited(
            _serialize(() async {
              if (!current() || _fileEpoch != epoch) return;
              if (_sleepBoundaryFile == _fileIndex ||
                  (_sleepAtMs != null && _offset   (_durations[_fileIndex] ?? 0) >= _sleepAtMs!) ||
                  (_sleepUntilQueuePosition != null && _queuePosition >= _sleepUntilQueuePosition!)) {
                _sleepBoundaryFile = _fileIndex;
                clearSleep();
                await native.pause();
                _pausedAt = DateTime.now();
                await _persist();
                _notify();
                return;
              }
              if (canUseDirectQueueControls && _queueRepeatMode == MusicRepeatMode.one) {
                await _persist();
                await _openFile(_fileIndex, 0);
              } else if (_nextPlaybackFileIndex() case final nextIndex?) {
                await _persist();
                await _openFile(nextIndex, 0);
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
        if (_valid && active && failure == null && !opening) unawaited(_persist());
      });
    } catch (_) {
      await _stop();
      rethrow;
    }
  });
  Future<void> applyExternalSubtitle({
    required String name,
    required List<int> bytes,
    String languageCode = '',
    bool forced = false,
    bool hearingImpaired = false,
  }) => _serialize(() async {
    final native = player;
    final profile = _profile;
    final item = entry;
    final currentProgress = progress;
    if (!_valid || !video || native == null || profile == null || item == null) {
      throw const SourceException(SourceFailure.cancelled);
    }
    if (native.playerType != 'mpv' || files.isEmpty || _fileIndex < 0 || _fileIndex >= files.length) {
      throw const SourceException(SourceFailure.unsupported);
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final requestedExtension = p.extension(name).toLowerCase();
    final extension = const {'.srt', '.ass', '.ssa', '.vtt', '.sub'}.contains(requestedExtension)
        ? requestedExtension
        : '.srt';
    if (!native.supportedLocalSubtitleExtensions.contains(extension.substring(1))) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final generation = _generation;
    final fileEpoch = _fileEpoch;
    final edition = currentProgress?.edition;
    final normalizedLanguage = _normalizeSubtitleLanguage(languageCode);
    final fileIndex = _fileIndex;
    final publicationFile = files[fileIndex];
    bool current() => _isCurrentExternalSubtitleScope(
      native: native,
      item: item,
      publicationFile: publicationFile,
      fileIndex: fileIndex,
      profile: profile,
      edition: edition,
      generation: generation,
      fileEpoch: fileEpoch,
    );

    final persistent = _persistProgress && !_liveInput && currentProgress != null && edition != null;
    if (!persistent) {
      final directory = Directory(
        p.join(sources.downloads.directory.path, sourceDigest(profile), 'external-subtitles'),
      );
      await directory.create(recursive: true);
      if (!current()) throw const SourceException(SourceFailure.cancelled);
      final file = File(p.join(directory.path, '${const Uuid().v4()}$extension'));
      try {
        await file.writeAsBytes(bytes, flush: true);
        if (!current()) throw const SourceException(SourceFailure.cancelled);
        final offsets = PlayerSyncOffsets.of(native);
        final previousDelayMs = offsets.subtitleMs;
        final previousRate = offsets.subtitleRate;
        try {
          await _applyExternalSubtitleSync(native, delayMs: 0, rate: 1.0);
          await native.command(
            _externalSubtitleCommand(
              path: file.path,
              language: normalizedLanguage,
              forced: forced,
              hearingImpaired: hearingImpaired,
            ),
          );
          if (!current()) throw const SourceException(SourceFailure.cancelled);
        } catch (_) {
          try {
            await _applyExternalSubtitleSync(native, delayMs: previousDelayMs, rate: previousRate);
          } on Object catch (error, stackTrace) {
            appLogger.w('Could not restore subtitle timing after import failed', error: error, stackTrace: stackTrace);
          }
          rethrow;
        }
        _temporarySubtitles.add(file);
        _notify();
      } catch (_) {
        if (await file.exists()) await file.delete();
        rethrow;
      }
      return;
    }

    final directory = _externalSubtitleAssetDirectory(
      profile: profile,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    await directory.create(recursive: true);
    if (!current()) throw const SourceException(SourceFailure.cancelled);
    final manifestFile = File(p.join(directory.path, 'manifest.json'));
    final previousManifest = await _readExternalSubtitleManifest(
      directory: directory,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    final oldAssets = (previousManifest?['assets'] as List<Map<String, dynamic>>?) ?? const [];
    final slot = sha256
        .convert(utf8.encode(jsonEncode([normalizedLanguage, forced, hearingImpaired])))
        .toString();
    final checksum = sha256.convert(bytes).toString();
    Map<String, dynamic>? previousSlotAsset;
    for (final asset in oldAssets) {
      if (asset['slot'] == slot) {
        previousSlotAsset = asset;
        break;
      }
    }
    final preserveSync = previousSlotAsset?['sha256'] == checksum;
    final syncByAudio = preserveSync
        ? Map<String, dynamic>.from(previousSlotAsset!['syncByAudio'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final selectedSync = _subtitleSyncForAudio(syncByAudio, _subtitleAudioIdentity(native));
    final assetName = '$checksum$extension';
    final assetFile = File(p.join(directory.path, assetName));
    final nextAssets = <Map<String, dynamic>>[
      ...oldAssets.where((asset) => asset['slot'] != slot),
      {
        'slot': slot,
        'sha256': checksum,
        'file': assetName,
        'size': bytes.length,
        'language': normalizedLanguage,
        'forced': forced,
        'hearingImpaired': hearingImpaired,
        'syncByAudio': syncByAudio,
      },
    ];
    final uniqueFiles = nextAssets.map((asset) => asset['file'] as String).toSet();
    final totalBytes = uniqueFiles.fold<int>(
      0,
      (total, fileName) => total   (nextAssets.firstWhere((asset) => asset['file'] == fileName)['size'] as int),
    );
    if (nextAssets.length > 8 || totalBytes > 20 * 1024 * 1024) {
      throw const SourceException(SourceFailure.quotaExceeded);
    }
    final nextManifest = <String, dynamic>{
      'version': 2,
      'entry': sourceDigest(item.key),
      'edition': edition,
      'fileFingerprint': publicationFile.fingerprint,
      'selected': slot,
      'assets': nextAssets,
    };

    final stagedAsset = File('${assetFile.path}.${const Uuid().v4()}.pending');
    final hadAsset = await assetFile.exists();
    var manifestWritten = false;
    try {
      if (!hadAsset ||
          await assetFile.length() != bytes.length ||
          sha256.convert(await assetFile.readAsBytes()).toString() != checksum) {
        await stagedAsset.writeAsBytes(bytes, flush: true);
        if (!current()) throw const SourceException(SourceFailure.cancelled);
        if (await assetFile.exists()) await assetFile.delete();
        await stagedAsset.rename(assetFile.path);
      }
      if (!current()) throw const SourceException(SourceFailure.cancelled);
      await _writeExternalSubtitleManifest(manifestFile, nextManifest);
      manifestWritten = true;
      final offsets = PlayerSyncOffsets.of(native);
      final previousDelayMs = offsets.subtitleMs;
      final previousRate = offsets.subtitleRate;
      try {
        if (!current()) throw const SourceException(SourceFailure.cancelled);
        await _applyExternalSubtitleSync(native, delayMs: selectedSync.delayMs, rate: selectedSync.rate);
        await native.command(['sub-add', assetFile.path, 'select']);
        if (!current()) throw const SourceException(SourceFailure.cancelled);
      } catch (_) {
        try {
          await _applyExternalSubtitleSync(native, delayMs: previousDelayMs, rate: previousRate);
        } on Object catch (error, stackTrace) {
          appLogger.w('Could not restore subtitle timing after subtitle import failed', error: error, stackTrace: stackTrace);
        }
        if (previousManifest == null) {
          if (await manifestFile.exists()) await manifestFile.delete();
          manifestWritten = false;
        } else {
          await _writeExternalSubtitleManifest(manifestFile, previousManifest);
        }
        if (!hadAsset && !oldAssets.any((asset) => asset['file'] == assetName) && await assetFile.exists()) {
          await assetFile.delete();
        }
        rethrow;
      }
      _selectedExternalSubtitlePath = assetFile.absolute.path;
      _activeExternalSubtitleSyncBinding = _externalSubtitleSyncBinding(native, assetFile.absolute.path);
      try {
        await _pruneExternalSubtitleAssets(directory, nextAssets);
      } on Object {
        // Playback and the committed manifest remain valid if cache pruning fails.
      }
      _notify();
    } catch (_) {
      if (await stagedAsset.exists()) await stagedAsset.delete();
      if (!hadAsset && !manifestWritten && await assetFile.exists()) await assetFile.delete();
      rethrow;
    }
  });

  Future<({int delayMs, double rate})?> activeExternalSubtitleSync() async {
    final native = player;
    final item = entry;
    final profile = _profile;
    final edition = progress?.edition;
    if (!_valid ||
        !video ||
        _liveInput ||
        !_persistProgress ||
        native == null ||
        native.playerType != 'mpv' ||
        item == null ||
        profile == null ||
        edition == null ||
        files.isEmpty ||
        _fileIndex < 0 ||
        _fileIndex >= files.length ||
        !hasSelectedPersistentExternalSubtitle) {
      return null;
    }
    final publicationFile = files[_fileIndex];
    final fileIndex = _fileIndex;
    final generation = _generation;
    final fileEpoch = _fileEpoch;
    bool current() => _isCurrentExternalSubtitleScope(
      native: native,
      item: item,
      publicationFile: publicationFile,
      fileIndex: fileIndex,
      profile: profile,
      edition: edition,
      generation: generation,
      fileEpoch: fileEpoch,
    );
    final directory = _externalSubtitleAssetDirectory(
      profile: profile,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    final manifest = await _readExternalSubtitleManifest(
      directory: directory,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    if (!current() || manifest == null) return null;
    final selected = manifest['selected'];
    final assets = manifest['assets'] as List<Map<String, dynamic>>;
    final selectedPath = _selectedExternalSubtitlePath;
    if (selectedPath == null) return null;
    for (final asset in assets) {
      if (asset['slot'] != selected || asset['file'] != p.basename(selectedPath)) continue;
      final file = File(p.join(directory.path, asset['file'] as String));
      if (!await file.exists() || !current()) return null;
      if (await file.length() != asset['size'] || !current()) return null;
      if (sha256.convert(await file.readAsBytes()).toString() != asset['sha256'] || !current()) return null;
      final sync = asset['syncByAudio'] as Map<String, dynamic>;
      return _subtitleSyncForAudio(sync, _subtitleAudioIdentity(native));
    }
    return null;
  }

  /// Aligns a chosen subtitle cue's start to a captured playback position.
  ///
  /// The correction is scoped to the active subtitle asset and selected audio
  /// stream. The player's value is restored if the manifest write fails.
  Future<int> alignExternalSubtitleCueNow({
    required String expectedIdentity,
    required int cueStartMs,
    required int playbackPositionMs,
  }) async {
    if (cueStartMs < 0 || cueStartMs > 60 * 24 * 60 * 60 * 1000 || playbackPositionMs < 0) {
      throw RangeError('Subtitle cue and playback times must be non-negative and within the supported range.');
    }
    if (activeExternalSubtitleIdentity != expectedIdentity) {
      throw const SourceException(SourceFailure.cancelled);
    }
    final native = player;
    final previous = await activeExternalSubtitleSync();
    if (native == null ||
        player != native ||
        previous == null ||
        activeExternalSubtitleIdentity != expectedIdentity ||
        !previous.rate.isFinite) {
      throw const SourceException(SourceFailure.cancelled);
    }
    final nextDelayMs = playbackPositionMs - (cueStartMs * previous.rate).round();
    if (nextDelayMs < ScopedPlayerPrefs.minimumSyncOffsetMs ||
        nextDelayMs > ScopedPlayerPrefs.maximumSyncOffsetMs) {
      throw RangeError.range(
        nextDelayMs,
        ScopedPlayerPrefs.minimumSyncOffsetMs,
        ScopedPlayerPrefs.maximumSyncOffsetMs,
        'delayMs',
      );
    }

    await _applyExternalSubtitleSync(native, delayMs: nextDelayMs, rate: previous.rate);
    try {
      if (player != native || activeExternalSubtitleIdentity != expectedIdentity) {
        throw const SourceException(SourceFailure.cancelled);
      }
      await persistExternalSubtitleSync(delayMs: nextDelayMs);
      if (player != native || activeExternalSubtitleIdentity != expectedIdentity) {
        throw const SourceException(SourceFailure.cancelled);
      }
    } on Object catch (error, stackTrace) {
      if (player == native && activeExternalSubtitleIdentity == expectedIdentity) {
        try {
          await _applyExternalSubtitleSync(native, delayMs: previous.delayMs, rate: previous.rate);
        } on Object catch (rollbackError, rollbackStackTrace) {
          appLogger.w(
            'Could not restore subtitle timing after one-cue alignment failed',
            error: rollbackError,
            stackTrace: rollbackStackTrace,
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return nextDelayMs;
  }


  /// Seeks to a cue's corrected display time while the same external subtitle,
  /// audio track, file, and playback generation remain active.
  Future<bool> seekExternalSubtitleCue({
    required String expectedIdentity,
    required int cueStartMs,
    required int delayMs,
    required double rate,
    required int prerollMs,
  }) => _serialize(() async {
    if (cueStartMs < 0 ||
        cueStartMs > 24 * 60 * 60 * 1000 ||
        prerollMs < 0 ||
        prerollMs > 5000 ||
        delayMs < ScopedPlayerPrefs.minimumSyncOffsetMs ||
        delayMs > ScopedPlayerPrefs.maximumSyncOffsetMs ||
        !rate.isFinite ||
        rate < ScopedPlayerPrefs.minimumSubtitleSyncRate ||
        rate > ScopedPlayerPrefs.maximumSubtitleSyncRate) {
      throw RangeError('Subtitle cue seek values are outside the supported range.');
    }
    final native = player;
    if (!_valid ||
        !video ||
        _liveInput ||
        native == null ||
        native.playerType != 'mpv' ||
        !native.state.seekable ||
        !canExportActiveExternalSubtitle ||
        activeExternalSubtitleIdentity != expectedIdentity) {
      return false;
    }

    final durationMs = currentFileDurationMs;
    if (durationMs <= 0) return false;
    final correctedCueStartMs = (cueStartMs * rate).round() + delayMs;
    final targetInFileMs = correctedCueStartMs - prerollMs;
    if (targetInFileMs >= durationMs) return false;

    final currentFileStartMs = positionMs - currentFilePositionMs;
    final targetInFile = targetInFileMs.clamp(0, durationMs - 1).toInt();
    _undoSeek = (file: _fileIndex, position: currentFilePositionMs);
    await _seek(currentFileStartMs + targetInFile);
    return activeExternalSubtitleIdentity == expectedIdentity;
  });

  Future<void> persistExternalSubtitleSync({int? delayMs, double? rate}) async {
    if (delayMs == null && rate == null) return;
    if (delayMs != null &&
        (delayMs < ScopedPlayerPrefs.minimumSyncOffsetMs || delayMs > ScopedPlayerPrefs.maximumSyncOffsetMs)) {
      throw RangeError.range(
        delayMs,
        ScopedPlayerPrefs.minimumSyncOffsetMs,
        ScopedPlayerPrefs.maximumSyncOffsetMs,
        'delayMs',
      );
    }
    if (rate != null &&
        (!rate.isFinite ||
            rate < ScopedPlayerPrefs.minimumSubtitleSyncRate ||
            rate > ScopedPlayerPrefs.maximumSubtitleSyncRate)) {
      throw RangeError.range(
        rate,
        ScopedPlayerPrefs.minimumSubtitleSyncRate,
        ScopedPlayerPrefs.maximumSubtitleSyncRate,
        'rate',
      );
    }
    final next = _subtitleSyncWrites.then((_) async {
      await _commands;
      final native = player;
      final item = entry;
      final profile = _profile;
      final edition = progress?.edition;
      final selectedPath = _selectedExternalSubtitlePath;
      if (!_valid ||
          !video ||
          _liveInput ||
          !_persistProgress ||
          native == null ||
          native.playerType != 'mpv' ||
          item == null ||
          profile == null ||
          edition == null ||
          selectedPath == null ||
          files.isEmpty ||
          _fileIndex < 0 ||
          _fileIndex >= files.length ||
          !hasSelectedPersistentExternalSubtitle) {
        throw const SourceException(SourceFailure.cancelled);
      }
      final publicationFile = files[_fileIndex];
      final fileIndex = _fileIndex;
      final generation = _generation;
      final fileEpoch = _fileEpoch;
      bool current() => _isCurrentExternalSubtitleScope(
        native: native,
        item: item,
        publicationFile: publicationFile,
        fileIndex: fileIndex,
        profile: profile,
        edition: edition,
        generation: generation,
        fileEpoch: fileEpoch,
      );
      final directory = _externalSubtitleAssetDirectory(
        profile: profile,
        item: item,
        edition: edition,
        publicationFile: publicationFile,
      );
      final manifest = await _readExternalSubtitleManifest(
        directory: directory,
        item: item,
        edition: edition,
        publicationFile: publicationFile,
      );
      if (!current() || manifest == null) throw const SourceException(SourceFailure.cancelled);
      final selected = manifest['selected'];
      final assets = (manifest['assets'] as List<Map<String, dynamic>>)
          .map((asset) => Map<String, dynamic>.from(asset))
          .toList();
      final index = assets.indexWhere(
        (asset) => asset['slot'] == selected && asset['file'] == p.basename(selectedPath),
      );
      if (index < 0) throw const SourceException(SourceFailure.cancelled);
      final updated = Map<String, dynamic>.from(assets[index]);
      final syncByAudio = Map<String, dynamic>.from(updated['syncByAudio'] as Map<String, dynamic>);
      final audioIdentity = _subtitleAudioIdentity(native);
      final currentSync = _subtitleSyncForAudio(syncByAudio, audioIdentity);
      final nextSync = <String, dynamic>{
        'delayMs': delayMs ?? currentSync.delayMs,
        'rate': rate ?? currentSync.rate,
      };
      syncByAudio.remove('legacy');
      syncByAudio.remove(audioIdentity);
      syncByAudio[audioIdentity] = nextSync;
      while (syncByAudio.length > 16) {
        syncByAudio.remove(syncByAudio.keys.first);
      }
      updated['syncByAudio'] = syncByAudio;
      assets[index] = updated;
      final manifestFile = File(p.join(directory.path, 'manifest.json'));
      await _writeExternalSubtitleManifest(manifestFile, {
        'version': 2,
        'entry': sourceDigest(item.key),
        'edition': edition,
        'fileFingerprint': publicationFile.fingerprint,
        'selected': selected,
        'assets': assets,
      });
      if (!current()) throw const SourceException(SourceFailure.cancelled);
    });
    _subtitleSyncWrites = next.catchError((Object _) {});
    await next;
  }

  String _subtitleAudioIdentity(Player native) {
    final audio = native.state.track.audio;
    final descriptor = audio == null
        ? const ['no-selected-audio']
        : [
            audio.id,
            audio.language?.trim().toLowerCase() ?? '',
            audio.title?.trim() ?? '',
            audio.codec?.trim().toLowerCase() ?? '',
            audio.channels ?? 0,
            audio.sampleRate ?? 0,
          ];
    return sha256.convert(utf8.encode(jsonEncode(descriptor))).toString();
  }

  ({int delayMs, double rate}) _subtitleSyncForAudio(Map<String, dynamic> syncByAudio, String audioIdentity) {
    final raw = syncByAudio[audioIdentity] ?? syncByAudio['legacy'];
    if (raw is! Map) return (delayMs: 0, rate: 1.0);
    final values = Map<String, dynamic>.from(raw);
    final rawDelay = values['delayMs'];
    final rawRate = values['rate'];
    if (rawDelay is! int || rawRate is! num) return (delayMs: 0, rate: 1.0);
    final delayMs = rawDelay;
    final rate = rawRate.toDouble();
    if (delayMs < ScopedPlayerPrefs.minimumSyncOffsetMs ||
        delayMs > ScopedPlayerPrefs.maximumSyncOffsetMs ||
        !rate.isFinite ||
        rate < ScopedPlayerPrefs.minimumSubtitleSyncRate ||
        rate > ScopedPlayerPrefs.maximumSubtitleSyncRate) {
      return (delayMs: 0, rate: 1.0);
    }
    return (delayMs: delayMs, rate: rate);
  }

  String _externalSubtitleSyncBinding(Player native, String path) =>
      _subtitleAudioIdentity(native)   '|'   (native.state.track.subtitle?.id ?? 'off')   '|'   path;

  Future<void> _reapplySelectedExternalSubtitleSyncForCurrentTrack() async {
    await _commands;
    if (opening) return;
    final native = player;
    final item = entry;
    final profile = _profile;
    if (native == null ||
        item == null ||
        profile == null ||
        _fileIndex < 0 ||
        _fileIndex >= files.length ||
        _selectedExternalSubtitlePath == null) {
      return;
    }
    await _reapplyExternalSubtitleSyncForTrackChange(
      native: native,
      item: item,
      publicationFile: files[_fileIndex],
      fileIndex: _fileIndex,
      profile: profile,
      edition: progress?.edition,
      generation: _generation,
      fileEpoch: _fileEpoch,
    );
  }

  Future<void> _reapplyExternalSubtitleSyncForTrackChange({
    required Player native,
    required SourceEntry item,
    required PublicationFile publicationFile,
    required int fileIndex,
    required String profile,
    required String? edition,
    required int generation,
    required int fileEpoch,
  }) async {
    final path = _selectedExternalSubtitlePath;
    if (path == null ||
        !_isSelectedExternalSubtitlePath(native.state.track.subtitle, path) ||
        !_isCurrentExternalSubtitleScope(
          native: native,
          item: item,
          publicationFile: publicationFile,
          fileIndex: fileIndex,
          profile: profile,
          edition: edition,
          generation: generation,
          fileEpoch: fileEpoch,
        )) {
      return;
    }
    final binding = _externalSubtitleSyncBinding(native, path);
    if (binding == _activeExternalSubtitleSyncBinding || edition == null) return;
    final directory = _externalSubtitleAssetDirectory(
      profile: profile,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    final manifest = await _readExternalSubtitleManifest(
      directory: directory,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    if (manifest == null) return;
    final selected = manifest['selected'];
    for (final asset in manifest['assets'] as List<Map<String, dynamic>>) {
      if (asset['slot'] != selected || asset['file'] != p.basename(path)) continue;
      final sync = _subtitleSyncForAudio(
        asset['syncByAudio'] as Map<String, dynamic>,
        _subtitleAudioIdentity(native),
      );
      if (!_isCurrentExternalSubtitleScope(
        native: native,
        item: item,
        publicationFile: publicationFile,
        fileIndex: fileIndex,
        profile: profile,
        edition: edition,
        generation: generation,
        fileEpoch: fileEpoch,
      ) ||
          !_isSelectedExternalSubtitlePath(native.state.track.subtitle, path)) {
        return;
      }
      try {
        await _applyExternalSubtitleSync(native, delayMs: sync.delayMs, rate: sync.rate);
        _activeExternalSubtitleSyncBinding = binding;
        _notify();
      } on Object catch (error, stackTrace) {
        appLogger.w('Could not apply saved subtitle timing for the selected audio', error: error, stackTrace: stackTrace);
      }
      return;
    }
  }

  bool _isSelectedExternalSubtitlePath(SubtitleTrack? track, String? path) {
    if (track == null || !track.isExternal || path == null || track.uri == null) return false;
    final actual = track.uri!;
    if (actual == path || actual == File(path).uri.toString()) return true;
    final uri = Uri.tryParse(actual);
    return uri != null && uri.scheme == 'file' && File.fromUri(uri).absolute.path == path;
  }

  Future<void> _applyExternalSubtitleSync(Player native, {required int delayMs, required double rate}) async {
    if (native.playerType != 'mpv' ||
        delayMs < ScopedPlayerPrefs.minimumSyncOffsetMs ||
        delayMs > ScopedPlayerPrefs.maximumSyncOffsetMs ||
        !rate.isFinite ||
        rate < ScopedPlayerPrefs.minimumSubtitleSyncRate ||
        rate > ScopedPlayerPrefs.maximumSubtitleSyncRate) {
      throw const SourceException(SourceFailure.unsupported);
    }
    await native.setProperty(PlayerSyncOffsets.subtitleRateProperty, rate.toStringAsFixed(6));
    await native.setProperty(PlayerSyncOffsets.subtitleProperty, (delayMs / 1000.0).toString());
    final appliedRate = double.tryParse(
      await native.getProperty(PlayerSyncOffsets.subtitleRateProperty) ?? '',
    );
    final appliedDelay = double.tryParse(
      await native.getProperty(PlayerSyncOffsets.subtitleProperty) ?? '',
    );
    if (appliedRate == null ||
        !appliedRate.isFinite ||
        appliedDelay == null ||
        !appliedDelay.isFinite ||
        (appliedRate - rate).abs() > 0.001 ||
        (appliedDelay * 1000 - delayMs).abs() > 2) {
      throw StateError('The player did not apply the external subtitle timing.');
    }
    final offsets = PlayerSyncOffsets.of(native);
    offsets.recordSubtitleRate(appliedRate);
    offsets.recordApplied(PlayerSyncOffsets.subtitleProperty, (appliedDelay * 1000).round());
  }

  bool _isCurrentExternalSubtitleScope({
    required Player native,
    required SourceEntry item,
    required PublicationFile publicationFile,
    required int fileIndex,
    required String profile,
    required String? edition,
    required int generation,
    required int fileEpoch,
  }) =>
      _valid &&
      player == native &&
      entry == item &&
      _profile == profile &&
      _generation == generation &&
      _fileEpoch == fileEpoch &&
      _fileIndex == fileIndex &&
      fileIndex >= 0 &&
      fileIndex < files.length &&
      files[fileIndex].fingerprint == publicationFile.fingerprint &&
      progress?.edition == edition;

  Directory _externalSubtitleAssetDirectory({
    required String profile,
    required SourceEntry item,
    required String edition,
    required PublicationFile publicationFile,
  }) {
    final digestPattern = RegExp(r'^[0-9a-f]{64}$');
    if (!digestPattern.hasMatch(edition) || !digestPattern.hasMatch(publicationFile.fingerprint)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return Directory(
      p.join(
        sources.downloads.directory.path,
        sourceDigest(profile),
        'external-subtitles',
        sourceDigest(item.key),
        edition,
        publicationFile.fingerprint,
      ),
    );
  }

  String _normalizeSubtitleLanguage(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    return RegExp(r'^[a-z]{2,3}(?:-[a-z0-9]{2,8})?$').hasMatch(normalized) ? normalized : '';
  }

  List<String> _externalSubtitleCommand({
    required String path,
    required String language,
    required bool forced,
    required bool hearingImpaired,
  }) {
    final flags = [
      'select',
      if (forced) 'forced',
      if (hearingImpaired) 'hearing-impaired',
    ].join(' ');
    final title = language.isEmpty ? 'External subtitle' : language;
    return ['sub-add', path, flags, title, if (language.isNotEmpty) language];
  }

  Map<String, dynamic>? _safeExternalSubtitleAsset(Object? value) {
    if (value is! Map) return null;
    final asset = Map<String, dynamic>.from(value);
    final slot = asset['slot'];
    final checksum = asset['sha256'];
    final fileName = asset['file'];
    final size = asset['size'];
    final language = asset['language'];
    final forced = asset['forced'];
    final hearingImpaired = asset['hearingImpaired'];
    final rawSyncByAudio = asset['syncByAudio'];
    final rawSyncByAudioMap = rawSyncByAudio is Map ? Map<String, dynamic>.from(rawSyncByAudio) : null;
    final legacyDelay = asset['syncDelayMs'] ?? 0;
    final legacyRate = asset['syncRate'] ?? 1.0;
    final syncByAudio = rawSyncByAudioMap ??
        <String, dynamic>{
          'legacy': {'delayMs': legacyDelay, 'rate': legacyRate},
        };

    if (syncByAudio.length > 16) return null;
    for (final entry in syncByAudio.entries) {
      if (entry.key != 'legacy' && !RegExp(r'^[0-9a-f]{64}$').hasMatch(entry.key)) return null;
      if (entry.value is! Map) return null;
      final values = Map<String, dynamic>.from(entry.value as Map);
      final rawDelay = values['delayMs'];
      final rawRate = values['rate'];
      if (rawDelay is! int || rawRate is! num) return null;
      final rate = rawRate.toDouble();
      if (rawDelay < ScopedPlayerPrefs.minimumSyncOffsetMs ||
          rawDelay > ScopedPlayerPrefs.maximumSyncOffsetMs ||
          !rate.isFinite ||
          rate < ScopedPlayerPrefs.minimumSubtitleSyncRate ||
          rate > ScopedPlayerPrefs.maximumSubtitleSyncRate) {
        return null;
      }
    }

    if (slot is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(slot) ||
        checksum is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum) ||
        fileName is! String ||
        p.basename(fileName) != fileName ||
        size is! int ||
        size <= 0 ||
        size > 5 * 1024 * 1024 ||
        language is! String ||
        _normalizeSubtitleLanguage(language) != language ||
        forced is! bool ||
        hearingImpaired is! bool) {
      return null;
    }
    final extension = p.extension(fileName).toLowerCase();
    if (!const {'.srt', '.ass', '.ssa', '.vtt', '.sub'}.contains(extension) ||
        fileName != '$checksum$extension' ||
        slot !=
            sha256
                .convert(utf8.encode(jsonEncode([language, forced, hearingImpaired])))
                .toString()) {
      return null;
    }
    return {
      'slot': slot,
      'sha256': checksum,
      'file': fileName,
      'size': size,
      'language': language,
      'forced': forced,
      'hearingImpaired': hearingImpaired,
      'syncByAudio': syncByAudio,
    };
  }

  Future<Map<String, dynamic>?> _readExternalSubtitleManifest({
    required Directory directory,
    required SourceEntry item,
    required String edition,
    required PublicationFile publicationFile,
  }) async {
    final manifestFile = File(p.join(directory.path, 'manifest.json'));
    final backupFile = File('${manifestFile.path}.backup');
    try {
      if (!await manifestFile.exists() && await backupFile.exists()) {
        await backupFile.rename(manifestFile.path);
      } else if (await manifestFile.exists() && await backupFile.exists()) {
        await backupFile.delete();
      }
      if (!await manifestFile.exists() || await manifestFile.length() > 64 * 1024) return null;
      final decoded = jsonDecode(await manifestFile.readAsString());
      if (decoded is! Map) return null;
      final manifest = Map<String, dynamic>.from(decoded);
      if ((manifest['version'] != 1 && manifest['version'] != 2) ||
          manifest['entry'] != sourceDigest(item.key) ||
          manifest['edition'] != edition ||
          manifest['fileFingerprint'] != publicationFile.fingerprint ||
          manifest['assets'] is! List) {
        return null;
      }
      final rawAssets = manifest['assets'] as List;
      if (rawAssets.length > 8) return null;
      final assets = rawAssets.map(_safeExternalSubtitleAsset).whereType<Map<String, dynamic>>().toList();
      final selected = manifest['selected'];
      return {
        'version': 2,
        'entry': sourceDigest(item.key),
        'edition': edition,
        'fileFingerprint': publicationFile.fingerprint,
        'selected': selected is String && assets.any((asset) => asset['slot'] == selected) ? selected : '',
        'assets': assets,
      };
    } on Object {
      return null;
    }
  }

  Future<void> _writeExternalSubtitleManifest(File manifestFile, Map<String, dynamic> manifest) async {
    final staged = File('${manifestFile.path}.${const Uuid().v4()}.pending');
    final backup = File('${manifestFile.path}.backup');
    try {
      await staged.writeAsString(jsonEncode(manifest), flush: true);
      if (await backup.exists()) await backup.delete();
      if (await manifestFile.exists()) await manifestFile.rename(backup.path);
      try {
        await staged.rename(manifestFile.path);
        if (await backup.exists()) {
          try {
            await backup.delete();
          } on Object {
            // The main manifest is already committed; recover by preferring it next time.
          }
        }
      } catch (_) {
        if (!await manifestFile.exists() && await backup.exists()) {
          await backup.rename(manifestFile.path);
        }
        rethrow;
      }
    } finally {
      if (await staged.exists()) await staged.delete();
    }
  }

  Future<void> _pruneExternalSubtitleAssets(
    Directory directory,
    List<Map<String, dynamic>> assets,
  ) async {
    final keep = assets.map((asset) => asset['file'] as String).toSet();
    final ownedAsset = RegExp(r'^[0-9a-f]{64}\.(?:srt|ass|ssa|vtt|sub)$');
    for (final entity in await directory.list(followLinks: false).toList()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (ownedAsset.hasMatch(name) && !keep.contains(name)) {
        try {
          await entity.delete();
        } on Object {
          // Stale, unreferenced cache cleanup is best effort.
        }
      } else if (name.endsWith('.pending')) {
        try {
          await entity.delete();
        } on Object {
          // Stale, unreferenced cache cleanup is best effort.
        }
      }
    }
  }

  Future<void> _restoreExternalSubtitleAssets({
    required Player native,
    required SourceEntry item,
    required PublicationFile publicationFile,
    required int fileIndex,
    required String profile,
    required String edition,
    required int generation,
    required int fileEpoch,
  }) async {
    if (!_persistProgress || _liveInput || !video || native.playerType != 'mpv') return;
    final directory = _externalSubtitleAssetDirectory(
      profile: profile,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    final manifest = await _readExternalSubtitleManifest(
      directory: directory,
      item: item,
      edition: edition,
      publicationFile: publicationFile,
    );
    if (manifest == null) return;
    final assets = (manifest['assets'] as List<Map<String, dynamic>>)
        .where(
          (asset) => native.supportedLocalSubtitleExtensions.contains(
            p.extension(asset['file'] as String).substring(1),
          ),
        )
        .toList();
    final selected = manifest['selected'];
    assets.sort((a, b) => (a['slot'] == selected ? 1 : 0).compareTo(b['slot'] == selected ? 1 : 0));
    for (final asset in assets) {
      if (!_isCurrentExternalSubtitleScope(
        native: native,
        item: item,
        publicationFile: publicationFile,
        fileIndex: fileIndex,
        profile: profile,
        edition: edition,
        generation: generation,
        fileEpoch: fileEpoch,
      )) {
        return;
      }
      final fileName = asset['file'] as String;
      final file = File(p.join(directory.path, fileName));
      try {
        if (!await file.exists() || await file.length() != asset['size']) continue;
        final contents = await file.readAsBytes();
        if (sha256.convert(contents).toString() != asset['sha256']) continue;
        if (!_isCurrentExternalSubtitleScope(
          native: native,
          item: item,
          publicationFile: publicationFile,
          fileIndex: fileIndex,
          profile: profile,
          edition: edition,
          generation: generation,
          fileEpoch: fileEpoch,
        )) {
          return;
        }
        await native.command(
          _externalSubtitleCommand(
            path: file.path,
            language: asset['language'] as String,
            forced: asset['forced'] as bool,
            hearingImpaired: asset['hearingImpaired'] as bool,
          ),
        );
        if (asset['slot'] == selected) {
          final sync = _subtitleSyncForAudio(
            asset['syncByAudio'] as Map<String, dynamic>,
            _subtitleAudioIdentity(native),
          );
          await _applyExternalSubtitleSync(native, delayMs: sync.delayMs, rate: sync.rate);
          _selectedExternalSubtitlePath = file.absolute.path;
          _activeExternalSubtitleSyncBinding = _externalSubtitleSyncBinding(native, file.absolute.path);
        }
      } on Object {
        appLogger.w('Saved external subtitle could not be restored');
      }
    }
  }

  Future<({String movieHash, int fileSize})?> currentOpenSubtitlesFingerprint() async {
    final native = player;
    final item = entry;
    final profile = _profile;
    if (!_valid ||
        !video ||
        _liveInput ||
        !_persistProgress ||
        native == null ||
        item == null ||
        profile == null ||
        files.isEmpty ||
        _fileIndex < 0 ||
        _fileIndex >= files.length) {
      return null;
    }
    final publicationFile = files[_fileIndex];
    final fileIndex = _fileIndex;
    final generation = _generation;
    final fileEpoch = _fileEpoch;
    final edition = progress?.edition;
    if (publicationFile.streamOnly || publicationFile.size == null) return null;
    bool current() =>
        _valid &&
        player == native &&
        entry == item &&
        _profile == profile &&
        _generation == generation &&
        _fileEpoch == fileEpoch &&
        _fileIndex == fileIndex &&
        fileIndex < files.length &&
        files[fileIndex].fingerprint == publicationFile.fingerprint &&
        progress?.edition == edition;

    try {
      final cached = await sources.downloads.local(profile, item.sourceId, publicationFile);
      final Uri uri;
      if (cached != null) {
        uri = cached.uri;
      } else {
        final adapter = sources.adapter(item.sourceId);
        if (adapter.source.kind != FileSourceKind.local) return null;
        uri = (await adapter.resolve(publicationFile)).uri;
      }
      if (!current() || uri.scheme != 'file') return null;

      final sourceFile = File.fromUri(uri);
      final input = await sourceFile.open(mode: FileMode.read);
      try {
        const chunkSize = 64 * 1024;
        final size = await input.length();
        if (size < chunkSize * 2 || size != publicationFile.size || !current()) return null;
        final mask = (BigInt.one << 64) - BigInt.one;
        var hash = BigInt.from(size);
        for (final offset in <int>[0, size - chunkSize]) {
          await input.setPosition(offset);
          final bytes = await input.read(chunkSize);
          if (bytes.length != chunkSize) return null;
          for (var wordOffset = 0; wordOffset < chunkSize; wordOffset  = 8) {
            var word = BigInt.zero;
            for (var byteOffset = 7; byteOffset >= 0; byteOffset--) {
              word = (word << 8) | BigInt.from(bytes[wordOffset   byteOffset]);
            }
            hash = (hash   word) & mask;
          }
        }
        if (!current()) return null;
        return (movieHash: hash.toRadixString(16).padLeft(16, '0'), fileSize: size);
      } finally {
        await input.close();
      }
    } on Object {
      // A local hash is an optional precision improvement; unavailable files
      // and source changes keep the ordinary title/ID search usable.
      return null;
    }
  }

  int _indexAt(int absolute) {
    var total = 0;
    for (final index in _queueOrder) {
      total  = _durations[index] ?? 0;
      if (absolute < total) return index;
    }
    return _queueOrder.isEmpty ? 0 : _queueOrder.last;
  }

  Future<void> _openFile(int index, int localPosition, {bool play = true}) async {
    if (!_valid || player == null) return;
    _subtitleMuteGeneration += 1;
    _subtitleMuteRestore = null;
    if (_streamRecordingPartial != null && index != _fileIndex) {
      try {
        await stopStreamRecording();
      } on SourceException catch (error) {
        if (error.reason != SourceFailure.invalidData) rethrow;
      }
    }
    opening = true;
    _selectedExternalSubtitlePath = null;
    _activeExternalSubtitleSyncBinding = null;
    _fileEpoch += 1;
    final generation = _generation;
    final fileEpoch = _fileEpoch;
    final edition = progress?.edition;
    _notify();
    _fileIndex = index;
    _lastKnownFilePositionMs = math.max(0, localPosition);
    _failedFilePositionMs = null;
    final file = files[index], item = entry!, native = player!;
    final directAddress = _directPlayerAddresses[file.id];
    final Uri? uri;
    final String mediaAddress;
    if (directAddress != null) {
      if (native.playerType != 'mpv' || !directAddress.startsWith('av://')) {
        throw const SourceException(SourceFailure.unsupported);
      }
      uri = null;
      mediaAddress = directAddress;
    } else {
      final cached = await sources.downloads.local(_profile!, item.sourceId, file);
      late final Uri resolvedUri;
      if (_localOverrides[file.id] != null) {
        final override = _localOverrides[file.id]!;
        resolvedUri = const {'http', 'https'}.contains(override.scheme)
            ? await _gateway!.registerUri(override)
            : override;
      } else if (cached != null) {
        resolvedUri = cached.uri;
      } else {
        final adapter = sources.adapter(item.sourceId);
        if (adapter.source.kind == FileSourceKind.local) {
          resolvedUri = (await adapter.resolve(file)).uri;
        } else {
          resolvedUri = await _gateway!.register(adapter, file);
        }
      }
      uri = resolvedUri;
      mediaAddress = resolvedUri.toString();
    }
    if (!_valid || player != native) return;
    if (uri != null &&
        const {'rtsp', 'rtmp', 'rtmps', 'udp', 'rtp', 'dvd', 'bd', 'cdda'}.contains(uri.scheme) &&
        native.playerType != 'mpv') {
      throw const SourceException(SourceFailure.unsupported);
    }
    if (!PlatformDetector.isAutomotive()) unawaited(NotificationPermission.ensure());
    await native.requestAudioFocus();
    for (final option in _localPlayerOptions.entries) {
      await native.setProperty('file-local-options/${option.key}', option.value);
    }
    await native.open(
      Media(mediaAddress, start: Duration(milliseconds: math.max(0, localPosition))),
      play: play && automotivePlaybackAllowedNow(),
      isLive: _liveInput,
    );
    await native.setRate(speed);
    if (!_valid || player != native || generation != _generation || fileEpoch != _fileEpoch) return;
    if (native.playerType == 'mpv') {
      try {
        await _applyExternalSubtitleSync(native, delayMs: 0, rate: 1.0);
      } on Object catch (error, stackTrace) {
        appLogger.w('Could not reset subtitle timing for the new source file', error: error, stackTrace: stackTrace);
      }
    }
    if (edition != null) {
      await _restoreExternalSubtitleAssets(
        native: native,
        item: item,
        publicationFile: file,
        fileIndex: index,
        profile: _profile!,
        edition: edition,
        generation: generation,
        fileEpoch: fileEpoch,
      );
    }
    if (!_valid || player != native || generation != _generation || fileEpoch != _fileEpoch) return;
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
    if (_userMuted) unawaited(_selectSubtitleForMute(native, _subtitleMuteGeneration));
  }

  Future<void> _readChapters(Player native, int generation, int index) async {
    try {
      final raw = await native.getProperty('chapter-list');
      if (!_valid || generation != _generation || index != _fileIndex || raw == null) return;
      final rows = sourceList(jsonDecode(raw)).map(sourceMap).toList();
      _fileChapters[index] = List.generate(
        rows.length,
        (i) => BookChapter(
          title: rows[i]['title'] as String? ?? '${i   1}',
          startMs: ((rows[i]['time'] as num? ?? 0) * 1000).round(),
          endMs: i   1 < rows.length ? ((rows[i   1]['time'] as num? ?? 0) * 1000).round() : (_durations[index] ?? 0),
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
    for (final index in _queueOrder) {
      final embedded = _fileChapters[index];
      if (embedded?.isNotEmpty == true) {
        for (final c in embedded!) {
          result.add(BookChapter(title: c.title, startMs: offset   c.startMs, endMs: offset   c.endMs));
        }
      } else {
        result.add(BookChapter(title: files[index].name, startMs: offset, endMs: offset   (_durations[index] ?? 0)));
      }
      offset  = _durations[index] ?? 0;
    }
    chapters = result;
  }

  Future<void> _persist({bool? finished}) {
    if (!_persistProgress || opening) return Future.value();
    final item = entry, profile = _profile, current = progress, native = player;
    if (item == null || profile == null || current == null || native == null) return Future.value();
    final index = _fileIndex, position = positionMs, filePosition = currentFilePositionMs;
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

  /// A deliberate retry reacquires this exact file's content lease (or its
  /// verified download). It never chooses another title, edition or file index.
  Future<void> retry() => _serialize(() async {
    if (!canRetry || !automotivePlaybackAllowedNow()) return;
    final position = currentFilePositionMs;
    final epoch = _profileGeneration;
    final currentProgress = progress;
    if (_persistProgress &&
        currentProgress != null &&
        (sources.cloudConflict(currentProgress.key) ||
            await sources.repository.remoteConflict(_profile!, currentProgress.key) != null)) {
      throw const SourceException(SourceFailure.conflict);
    }
    sources.requireSession(epoch);
    failure = null;
    try {
      await _openFile(_fileIndex, position);
      if (failure == null) {
        _failedFilePositionMs = null;
        await _persist();
      }
    } catch (_) {
      _failedFilePositionMs ??= position;
      rethrow;
    }
    _notify();
  });

  Future<void> play() => canRetry
      ? retry()
      : _serialize(() async {
          if (!_valid || player == null || !automotivePlaybackAllowedNow()) return;
          if (_persistProgress && !playing && progress != null && entry != null) {
            final old = progress!;
            sources.releaseProgress(old.key);
            try {
              final latest = await sources.openProgress(entry!, old);
              if (!_valid) return;
              if (sources.cloudConflict(old.key) ||
                  await sources.repository.remoteConflict(_profile!, old.key) != null) {
                throw const SourceException(SourceFailure.conflict);
              }
              if (latest.revision != old.revision) {
                progress = latest;
                final index = latest.fileIndex.clamp(0, files.length - 1);
                if (index != _fileIndex) {
                  await _openFile(index, latest.filePositionMs, play: false);
                } else {
                  _lastKnownFilePositionMs = math.max(0, latest.filePositionMs);
                  await player!.seek(Duration(milliseconds: latest.filePositionMs));
                }
                await player!.setRate(latest.speed);
              }
            } finally {
              if (_valid) sources.holdProgress(old.key);
            }
          }
          if (_sleepBoundaryFile == _fileIndex && _completedEpoch == _fileEpoch) {
            final nextIndex = _nextPlaybackFileIndex();
            if (nextIndex != null) await _openFile(nextIndex, 0, play: false);
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
      _lastKnownFilePositionMs = math.max(0, previous.position);
      await player!.seek(Duration(milliseconds: previous.position));
    }
    await _persist();
    _notify();
  });
  Future<void> _seek(int milliseconds) async {
    if (!_valid || player == null || _liveInput) return;
    final maximum = hasCompleteTimeline
        ? durationMs
        : (_durations[_fileIndex] ?? player!.state.duration.inMilliseconds)   _offset;
    final target = milliseconds.clamp(0, math.max(0, maximum)).toInt();
    final index = hasCompleteTimeline ? _indexAt(target) : _fileIndex;
    final shouldPlay = playing;
    if (index != _fileIndex) {
      await _persist();
      final offset = _offsetBefore(index);
      await _openFile(index, target - offset, play: shouldPlay);
    } else {
      _lastKnownFilePositionMs = math.max(0, target - _offset);
      await player!.seek(Duration(milliseconds: _lastKnownFilePositionMs));
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
        await _openFile(_queueOrder[index], 0, play: shouldPlay);
      });
    } else {
      await seek(chapters[index].startMs);
    }
  }

  Future<void> skip(int seconds) => _liveInput ? Future.value() : seek(positionMs   seconds * 1000);
  Future<void> nextChapter() async {
    if (!hasCompleteTimeline && chapters.length == files.length) {
      final nextPosition = _queuePosition   1;
      if (nextPosition < _queueOrder.length) {
        await seekChapter(nextPosition);
      } else if (canUseDirectQueueControls && _queueRepeatMode == MusicRepeatMode.all) {
        await seekChapter(0);
      }
      return;
    }
    final next = chapters.where((c) => c.startMs > positionMs   500).firstOrNull;
    if (next != null) {
      await seek(next.startMs);
    } else if (_nextPlaybackFileIndex() case final nextIndex?) {
      await _serialize(() async {
        await _persist();
        await _openFile(nextIndex, 0);
      });
    }
  }

  Future<void> previousChapter() async {
    if (!hasCompleteTimeline && chapters.length == files.length) {
      final targetPosition = currentFilePositionMs > 3000 ? _queuePosition : math.max(0, _queuePosition - 1);
      final wrappedPosition =
          _queuePosition == 0 &&
              currentFilePositionMs <= 3000 &&
              canUseDirectQueueControls &&
              _queueRepeatMode == MusicRepeatMode.all
          ? _queueOrder.length - 1
          : targetPosition;
      await seekChapter(wrappedPosition);
      return;
    }
    final previous = chapters.where((c) => c.startMs < positionMs - 3000).lastOrNull;
    if (previous != null) {
      await seek(previous.startMs);
    } else if (canUseDirectQueueControls) {
      final previousIndex = _previousPlaybackFileIndex();
      if (previousIndex != null) {
        await selectQueueFile(previousIndex);
      } else {
        await seek(0);
      }
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
    sleepFor((left.isNegative ? Duration.zero : left)   duration);
  }

  void sleepAfterChapter({int count = 1}) {
    if (count < 1 || count > 100) throw const SourceException(SourceFailure.invalidData);
    clearSleep();
    if (hasCompleteTimeline && chapters.isNotEmpty) {
      final current = chapters.indexOf(currentChapter ?? chapters.first);
      final index = (current   count - 1).clamp(0, chapters.length - 1);
      final endMs = chapters[index].endMs > 0 ? chapters[index].endMs : durationMs;
      _sleepAtMs = endMs;
      if (canUseDirectQueueControls) {
        _sleepChapterFile = _indexAt(math.max(0, endMs - 1));
        _sleepChapterFilePosition = (endMs - _offsetBefore(_sleepChapterFile!)).clamp(
          0,
          _durations[_sleepChapterFile!] ?? 0,
        );
      }
    } else {
      if (_queueOrder.isEmpty) return;
      _sleepUntilQueuePosition = (_queuePosition   count - 1).clamp(0, _queueOrder.length - 1);
    }
    _notify();
  }

  bool get sleepEnabled => _sleepTimer != null || _sleepAtMs != null || _sleepUntilQueuePosition != null;
  void clearSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAtMs = null;
    _sleepUntilQueuePosition = null;
    _sleepChapterFile = null;
    _sleepChapterFilePosition = null;
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
    _generation += 1;
    _subtitleMuteGeneration += 1;
    _subtitleMuteRestore = null;
    _userMuted = false;
    for (final sub in _subscriptions) {
      await release(sub.cancel);
    }
    _subscriptions.clear();
    await release(() => _hardware?.unregister());
    _hardware = null;
    _selectedExternalSubtitlePath = null;
    _activeExternalSubtitleSyncBinding = null;
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
    chapters = const [];
    _queueOrder = const [];
    _queueShuffled = false;
    _queueRepeatMode = MusicRepeatMode.off;
    _localOverrides = const {};
    _directPlayerAddresses = const {};
    _localPlayerOptions = const {};
    _persistProgress = true;
    _liveInput = false;
    progress = null;
    _lastKnownFilePositionMs = 0;
    _failedFilePositionMs = null;
    failure = null;
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
