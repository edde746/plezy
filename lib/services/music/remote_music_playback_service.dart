import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../media/lyrics.dart';
import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../utils/app_logger.dart';
import '../multi_server_manager.dart';
import '../playback_initialization_types.dart';
import '../playback_launch_observer.dart';
import '../music_assistant/music_assistant_players.dart';
import 'music_output.dart';
import 'music_playback_service.dart';
import 'music_queue_controller.dart';
import 'remote_track_url_resolver.dart';

/// Plays to a Music Assistant player — a Sonos room, a group — with this
/// device acting purely as a remote.
///
/// ### The shape of the thing
///
/// Nothing is decoded here. The speaker fetches the audio from Plex itself,
/// over the LAN, using a URL that carries its own credentials; Music Assistant
/// drives the speaker. This process contributes a queue and some button
/// presses. That is why locking the phone, pocketing it, or killing the app
/// does not stop the music: no part of the audio path runs in this process.
///
/// ### Everything visible is a reading
///
/// The single rule this class is built around: **the server's queue is
/// observed, never modelled.** Every wrong-audio bug found while building this
/// came from a client that believed its own record of what it had sent.
///
/// So [currentTrack], [currentIndex], [status], [position] and [duration] all
/// derive from [MaQueueState] readings. The local [MusicQueueController] holds
/// only what the *user* assembled — the list they picked, in the order they
/// picked it — and a reading is matched back to it by the media handle that
/// was sent, which Music Assistant echoes verbatim in
/// `current_item.streamdetails.item_id` (verified on 2.6.3). A reading naming
/// something that was never sent is surfaced as a conflict rather than
/// silently rendered under the wrong title.
///
/// ### Position
///
/// From `player_queues`, never `players`. A player's own `elapsed_time` froze
/// at 4.907 for the entire 131 seconds a probe watched it, while the audio
/// played on and the queue reported 4, 9, 14 … 130. See
/// [MusicAssistantPlayers].
class RemoteMusicPlaybackService extends MusicPlaybackService {
  RemoteMusicPlaybackService({
    required MusicOutput output,
    required MusicAssistantPlayers players,
    required RemoteTrackUrlResolver resolver,
    required MultiServerManager serverManager,
    Duration tickInterval = const Duration(milliseconds: 250),
    @visibleForTesting Duration? pollInterval,
  }) : _output = output,
       _players = players,
       _resolver = resolver,
       _serverManager = serverManager,
       _tickInterval = tickInterval,
       _pollInterval = pollInterval ?? const Duration(seconds: 5) {
    _queueId = output.playerId ?? '';
    _volume = (output.volume ?? 50).toDouble();
    _volumeListenable = ValueNotifier<double>(_volume);
    _subscribe();
  }

  // Written as an initializer list rather than initializing formals because
  // `output` is read in the body to derive the queue id and starting volume,
  // and `pollInterval` carries a fallback a formal cannot express. Keeping the
  // whole list in one style is clearer than mixing the two.
  // ignore_for_file: prefer_initializing_formals

  final MusicOutput _output;
  final MusicAssistantPlayers _players;
  final RemoteTrackUrlResolver _resolver;
  final MultiServerManager _serverManager;
  final Duration _tickInterval;
  final Duration _pollInterval;

  late final String _queueId;
  late final ValueNotifier<double> _volumeListenable;

  final MusicQueueController _queue = MusicQueueController();
  final StreamController<Duration> _positions = StreamController<Duration>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  StreamSubscription<MaQueueState>? _readings;
  Timer? _ticker;
  Timer? _poll;

  MaQueueState? _reading;
  MusicPlayContext? _playContext;
  double _volume = 50;
  int _playIntent = 0;
  int _queueSessionRevision = 0;
  bool _disposed = false;

  /// The media handle sent for each *queue-order* index, so a reading can be
  /// matched back to the track the user chose.
  ///
  /// This is a record of what was sent, and is deliberately never treated as a
  /// record of what the server holds — it is only ever used to *look up* an
  /// item the server has named.
  final List<String> _sentHandles = [];

  /// The local queue index each sent handle came from.
  ///
  /// The server's queue starts at the track the listener chose, so position
  /// *within what was sent* is not a position in the local queue: they differ
  /// by the start index. Treating them as the same made the transport name the
  /// album's first track while its fifth one played — audible music, wrong
  /// title, and no test caught it because they all started at index 0.
  final List<int> _sentIndices = [];

  /// Set when a reading names an item that was never sent to this queue.
  ///
  /// Somebody else — Music Assistant's own web UI, another app, a Sonos
  /// remote — replaced the queue. Adopting it would mean rendering their track
  /// under our title.
  bool _foreignQueue = false;

  /// A transport state asked for and not yet confirmed. See [status].
  MusicPlaybackStatus? _intendedStatus;
  Timer? _intentExpiry;

  /// How long an unconfirmed intent may stand in for the server's own reading.
  ///
  /// Long enough for a speaker on a busy network, short enough that a command
  /// which never lands stops lying about it.
  static const Duration _intentWindow = Duration(seconds: 6);

  /// Consecutive readings naming something this session did not send.
  ///
  /// One is not enough to disown a queue. Between `play_media` returning and
  /// the server reporting the new item, a reading still describes whatever was
  /// playing before — and on the device that single stale reading discarded
  /// the session at the moment it started: `currentTrack` went null, and the
  /// mini player, which is gated on it, vanished just after appearing. Audio
  /// in the room and nothing on screen to stop it.
  ///
  /// A queue somebody else really did take over keeps reporting their track,
  /// so it crosses this threshold on the very next reading.
  int _mismatchStreak = 0;

  static const int _mismatchesBeforeDisowning = 2;

  /// True when the queue currently sounding is somebody else's.
  bool get hasForeignQueue => _foreignQueue;

  /// Surface a failure to the UI, if anyone is still listening.
  ///
  /// Guarded because resolving and appending the tail of a queue outlives the
  /// tap that started it: switching output, or leaving the profile, disposes
  /// this service while that loop is still walking a playlist, and every one
  /// of its failures would then be added to a closed controller. Found by a
  /// test rather than in the field, which is the only reason it is not a
  /// crash report.
  void _report(Object error) {
    if (_disposed || _errors.isClosed) return;
    _errors.add(error);
  }

  MusicOutput get output => _output;

  // ---------------------------------------------------------------- readings

  void _subscribe() {
    _readings = _players
        .queueUpdates(_queueId)
        .listen(
          _onReading,
          onError: (Object error, StackTrace stackTrace) {
            appLogger.w('Lost Music Assistant queue readings for $_queueId', error: error, stackTrace: stackTrace);
          },
        );
    // The event stream is the fast path; this is the safety net. Readings stop
    // arriving if the socket reconnects mid-track, and a progress bar frozen
    // behind a live speaker is exactly the failure this feature exists to
    // avoid.
    _poll = Timer.periodic(_pollInterval, (_) => unawaited(_refreshReading()));
    unawaited(_refreshReading());
  }

  Future<void> _refreshReading() async {
    if (_disposed) return;
    try {
      final state = await _players.queueState(_queueId);
      if (state != null) _onReading(state);
    } catch (e) {
      appLogger.d('Could not re-read the Music Assistant queue: $e');
    }
  }

  void _onReading(MaQueueState state) {
    if (_disposed) return;
    final previousTrack = currentTrack;
    final previousStatus = status;
    _reading = state;
    // The server has caught up with what was asked for, so its reading takes
    // over again. Held only until then — an intent that outlived the truth
    // would hide the speaker being paused by someone else in the room.
    if (_intendedStatus != null && _statusFromReading(state) == _intendedStatus) _clearIntent();
    _reconcile(state);
    _ensureTicker();
    if (!identical(previousTrack, currentTrack) || previousStatus != status) notifyListeners();
  }

  /// Decide whether this reading describes the queue that was sent.
  void _reconcile(MaQueueState state) {
    if (state.currentItemIds.isEmpty) return;
    if (_sentHandles.isEmpty) return;
    // Any of them: a reading carries several identifiers and which one names
    // what was sent depends on whether this was a library track or a URL.
    var index = -1;
    for (final candidate in state.currentItemIds) {
      index = _sentHandles.indexOf(candidate);
      if (index >= 0) break;
    }
    if (index >= 0) {
      _mismatchStreak = 0;
      if (_foreignQueue) {
        appLogger.i('Music Assistant queue $_queueId is back on a track this session sent');
        _foreignQueue = false;
      }
      // The server's index is a *hint*; the handle is what names what is
      // audible. They disagree for a second or two across a track boundary.
      //
      // `index` is a position in what was sent, which starts at the track the
      // listener chose. The local queue keeps the whole album, so the two
      // differ by the start index — hence the recorded local index rather than
      // this one.
      final localIndex = index < _sentIndices.length ? _sentIndices[index] : index;
      if (_queue.cursor != localIndex) _queue.jumpTo(localIndex);
      return;
    }
    // A position tick carries the previous reading's identity forward, so it
    // is the same observation repeated rather than a second one. Counting
    // ticks would let a single stale handle reach the threshold on its own,
    // about a second after playback starts — which is the fade this is here
    // to prevent.
    if (state.fromTimeTick) return;
    if (++_mismatchStreak < _mismatchesBeforeDisowning) {
      appLogger.d('Music Assistant queue $_queueId has not caught up yet; waiting rather than disowning it');
      return;
    }
    if (!_foreignQueue) {
      _foreignQueue = true;
      appLogger.w(
        'Music Assistant queue $_queueId is playing "${state.currentItemName}", which this session did not send',
      );
      _report(StateError('${_output.name} is playing something else'));
    }
  }

  void _ensureTicker() {
    final running = status == MusicPlaybackStatus.playing;
    if (running && _ticker == null) {
      _ticker = Timer.periodic(_tickInterval, (_) {
        if (_positions.isClosed) return;
        _positions.add(position);
      });
    } else if (!running && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
      if (!_positions.isClosed) _positions.add(position);
    }
  }

  // ------------------------------------------------------------------ state

  @override
  MediaItem? get currentTrack {
    if (_foreignQueue) return null;
    return _queue.current;
  }

  @override
  MusicPlaybackStatus get status {
    // What was just asked for, until the server says otherwise.
    //
    // Status was read from the server's last reading alone, so pressing pause
    // changed nothing on screen until a round trip to the speaker came back —
    // a second or more, during which the button looks broken and people press
    // it again. The intent is what the listener just did; the reading is what
    // the room is doing. Showing the first while waiting for the second is the
    // difference between a transport that feels attached to the speaker and
    // one that feels detached from the finger.
    final intended = _intendedStatus;
    if (intended != null) return intended;

    return _statusFromReading(_reading);
  }

  /// The server's own answer, with no intent laid over it.
  MusicPlaybackStatus _statusFromReading(MaQueueState? reading) {
    if (reading == null) return MusicPlaybackStatus.idle;
    switch (reading.state) {
      case MaPlayerState.playing:
        return MusicPlaybackStatus.playing;
      case MaPlayerState.paused:
        return MusicPlaybackStatus.paused;
      case MaPlayerState.buffering:
        return MusicPlaybackStatus.loading;
      case MaPlayerState.idle:
        // Measured, twice, on the real speaker: pausing a queue of plain URLs
        // makes Music Assistant report `idle` rather than `paused`, keeping
        // `current_item` and `elapsed_time` intact, and `player_queues/play`
        // resumes from exactly there. `stop` looks identical on the wire, so
        // the two are genuinely indistinguishable — and calling this state
        // "paused" is the reading that matches what the user can do next,
        // which is press play and hear the rest of the track.
        if (_queue.isEmpty) return MusicPlaybackStatus.idle;
        return reading.currentItemId != null ? MusicPlaybackStatus.paused : MusicPlaybackStatus.idle;
    }
  }

  @override
  Duration? get duration {
    final reported = _reading?.currentDuration;
    if (reported != null) return reported;
    final ms = currentTrack?.durationMs;
    return ms == null ? null : Duration(milliseconds: ms);
  }

  @override
  Duration get position => _reading?.positionAt(DateTime.now()) ?? Duration.zero;

  /// Identical to [position]: each queue item is its own URL, so the audio the
  /// speaker has open *is* the track. Only flow mode makes these differ.
  Duration get streamPosition => position;

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  List<MediaItem> get queue => _queue.queue;

  @override
  int get currentIndex => _foreignQueue ? -1 : _queue.cursor;

  @override
  MusicPlayContext? get playContext => _playContext;

  @override
  bool get shuffled => _queue.shuffled;

  @override
  MusicRepeatMode get repeatMode => _queue.repeatMode;

  @override
  Stream<Object> get errors => _errors.stream;

  @override
  int beginPlayIntent() => ++_playIntent;

  @override
  bool isPlayIntentCurrent(int intent) => intent == _playIntent;

  @override
  int get queueSessionRevision => _queueSessionRevision;

  // -------------------------------------------------------------- transport

  @override
  /// [initialPosition], [offline] and [launchObserver] belong to the
  /// phone's own engine: a speaker streams what the server resolves and
  /// starts each track from the top.
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
    Duration? initialPosition,
    bool offline = false,
    PlaybackLaunchObserver? launchObserver,
  }) async {
    if (tracks.isEmpty) return;
    final intent = beginPlayIntent();
    final startIndex = startTrack == null ? 0 : tracks.indexWhere((track) => track.id == startTrack.id);
    _queue.load(tracks, startIndex: startIndex < 0 ? 0 : startIndex, shuffle: shuffle);
    _playContext = playContext;
    _queueSessionRevision++;
    _sentHandles.clear();
    _sentIndices.clear();
    _foreignQueue = false;
    _mismatchStreak = 0;
    notifyListeners();

    final ordered = _queue.queue;
    final first = _queue.current;
    if (first == null) return;

    // Start the first track on its own so audio begins after one resolve
    // rather than after all of them. An album is a dozen resolves; a playlist
    // can be hundreds, and making the user wait for the last one before the
    // first note is the difference between a remote that feels instant and one
    // that feels broken.
    final String firstHandle;
    try {
      firstHandle = (await _resolver.resolve(first, targetServerId: _output.serverId)).value;
    } catch (e, st) {
      appLogger.w('Could not resolve ${first.displayTitle} for ${_output.name}', error: e, stackTrace: st);
      if (isPlayIntentCurrent(intent)) _report(e);
      return;
    }
    if (!isPlayIntentCurrent(intent)) return;

    try {
      await _players.playMedia(_queueId, [firstHandle]);
    } catch (e, st) {
      appLogger.w('Could not start playback on ${_output.name}', error: e, stackTrace: st);
      if (isPlayIntentCurrent(intent)) _report(e);
      return;
    }
    if (!isPlayIntentCurrent(intent)) return;
    _sentHandles
      ..clear()
      ..add(firstHandle);
    _sentIndices
      ..clear()
      ..add(_queue.cursor);
    unawaited(_refreshReading());

    final cursor = _queue.cursor;
    // Everything after the start track, in queue order. Tracks *before* it are
    // deliberately dropped: the server queue starts where the user pressed
    // play, so index 0 there is the track they chose, and that is what keeps
    // the server's indices and the local ones describing the same list.
    final rest = ordered.sublist(cursor + 1);
    if (rest.isNotEmpty) unawaited(_appendRest(rest, intent, cursor));
  }

  /// Resolve and append the rest of the queue behind the audio that is already
  /// playing.
  ///
  /// Chunked, and serial within the chunk loop: resolving is one request per
  /// track against Plex, and appending is one Music Assistant command per
  /// chunk. Fanning either out is what wedges the server.
  Future<void> _appendRest(List<MediaItem> rest, int intent, int startIndex) async {
    const chunkSize = 20;
    for (var start = 0; start < rest.length; start += chunkSize) {
      if (_disposed || !isPlayIntentCurrent(intent)) return;
      final chunk = rest.sublist(start, (start + chunkSize).clamp(0, rest.length));
      final handles = <String>[];
      final indices = <int>[];
      for (final track in chunk) {
        if (_disposed || !isPlayIntentCurrent(intent)) return;
        try {
          handles.add((await _resolver.resolve(track, targetServerId: _output.serverId)).value);
          indices.add(startIndex + 1 + start + chunk.indexOf(track));
        } catch (e) {
          // One unplayable track must not truncate the queue silently, and it
          // must not be skipped silently either.
          appLogger.w('Skipping ${track.displayTitle} on ${_output.name}: $e');
          _report(e);
        }
      }
      if (handles.isEmpty) continue;
      if (!isPlayIntentCurrent(intent)) return;
      try {
        await _players.playMedia(_queueId, handles, option: MaEnqueueOption.add);
        _sentHandles.addAll(handles);
        _sentIndices.addAll(indices);
      } catch (e, st) {
        appLogger.w('Could not extend the queue on ${_output.name}', error: e, stackTrace: st);
        _report(e);
        return;
      }
    }
  }

  @override
  Future<InstantMixOutcome> playInstantMix(MediaItem seed) async {
    final intent = beginPlayIntent();
    final client = _clientFor(seed);
    if (client == null) {
      if (!isPlayIntentCurrent(intent)) return InstantMixOutcome.superseded;
      throw PlaybackException(t.music.instantMixNoServer, reason: PlaybackFailureReason.serverUnavailable);
    }
    List<MediaItem> tracks;
    try {
      tracks = await client.fetchInstantMix(seed.id);
    } catch (e, st) {
      if (!isPlayIntentCurrent(intent)) return InstantMixOutcome.superseded;
      appLogger.w('Instant mix fetch failed for ${seed.id}', error: e, stackTrace: st);
      rethrow;
    }
    if (!isPlayIntentCurrent(intent)) return InstantMixOutcome.superseded;
    if (tracks.isEmpty) return InstantMixOutcome.empty;
    await playFromList(
      tracks: tracks,
      playContext: MusicPlayContext(title: seed.displayTitle, kind: MusicPlayContextKind.mix),
    );
    return InstantMixOutcome.started;
  }

  @override
  Future<void> play() => _command(() => _players.play(_queueId), intent: MusicPlaybackStatus.playing);

  @override
  Future<void> pause() => _command(() => _players.pause(_queueId), intent: MusicPlaybackStatus.paused);

  @override
  Future<void> togglePlayPause() => status == MusicPlaybackStatus.playing ? pause() : play();

  @override
  Future<void> next() => _command(() => _players.next(_queueId));

  @override
  Future<void> previous() {
    // The server applies the same restart-or-step rule the local session does,
    // and it is the one holding the position that decides which. Re-deciding
    // here from an extrapolated reading would disagree with it near the
    // boundary.
    return _command(() => _players.previous(_queueId));
  }

  @override
  Future<void> seek(Duration position) => _command(() => _players.seek(_queueId, position));

  @override
  Future<void> jumpTo(int index) {
    if (index < 0 || index >= _queue.length) return Future<void>.value();
    return _command(() => _players.playIndex(_queueId, index));
  }

  @override
  Future<void> stop() async {
    beginPlayIntent();
    // Only silence a queue this session actually started.
    //
    // A speaker exists before Plezy touches it and usually has something of
    // its own going on. Selecting an output builds one of these services, and
    // switching away from it stops the outgoing engine — so an unconditional
    // stop here means glancing at a room in the picker, changing your mind,
    // and killing whatever that room was playing. Observed doing exactly that
    // to a Sonos playing Spotify: `active_source` went from `Spotify` to the
    // player's own id and the music stopped, from a session that had never
    // sent it a single track.
    //
    // A queue that has diverged is somebody else's for the same reason, and is
    // left alone too. This is the same rule the flow queue already follows: do
    // not act on a queue that has not been confirmed as ours.
    if (_sentHandles.isNotEmpty && !_foreignQueue) {
      await _command(() => _players.stop(_queueId));
    }
    _queue.clear();
    _sentHandles.clear();
    _sentIndices.clear();
    _playContext = null;
    _foreignQueue = false;
    _queueSessionRevision++;
    notifyListeners();
  }

  /// Issue a command and re-read, rather than assuming it landed.
  Future<void> _command(Future<void> Function() action, {MusicPlaybackStatus? intent}) async {
    if (_disposed) return;
    if (intent != null) _holdIntent(intent);
    try {
      await action();
    } catch (e, st) {
      appLogger.w('Music Assistant command failed for ${_output.name}', error: e, stackTrace: st);
      // A command that never landed must stop claiming it did.
      _clearIntent();
      _report(e);
      return;
    }
    // A command that returns without error has been *accepted*. What actually
    // happened arrives as a reading.
    unawaited(_refreshReading());
  }

  void _holdIntent(MusicPlaybackStatus intent) {
    _intendedStatus = intent;
    _intentExpiry?.cancel();
    _intentExpiry = Timer(_intentWindow, _clearIntent);
    notifyListeners();
  }

  void _clearIntent() {
    if (_intendedStatus == null) return;
    _intendedStatus = null;
    _intentExpiry?.cancel();
    _intentExpiry = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------- volume

  @override
  double get volume => _volume;

  @override
  ValueListenable<double> get volumeListenable => _volumeListenable;

  @override
  Future<void> setVolume(double volume, {bool persist = true}) async {
    final clamped = volume.clamp(0, 100).toDouble();
    _volume = clamped;
    _volumeListenable.value = clamped;
    if (!_output.supportsVolume) return;
    try {
      await _players.setVolume(_output.playerId!, clamped.round());
    } catch (e, st) {
      appLogger.w('Could not set the volume on ${_output.name}', error: e, stackTrace: st);
      _report(e);
      return;
    }
    // Read back: the command is only an acceptance, and a speaker that
    // silently clamps or ignores it would otherwise leave the slider lying.
    try {
      final actual = await _players.volumeOf(_output.playerId!);
      if (actual != null && _volumeListenable.value == clamped) {
        _volume = actual.toDouble();
        _volumeListenable.value = _volume;
      }
    } catch (e) {
      appLogger.d('Could not confirm the volume on ${_output.name}: $e');
    }
  }

  // ------------------------------------------------------------ queue edits

  /// Repeat and shuffle are refused rather than faked.
  ///
  /// Both are decisions about *what plays next*, and the server is the thing
  /// that decides that. Music Assistant does expose `player_queues/repeat` and
  /// a shuffle flag, but they act on the server's queue while these controls
  /// act on the local list, and the two orders would diverge the moment either
  /// was touched — leaving a shuffle toggle that reads as on and changes
  /// nothing audible. Wiring them properly means pushing a reordered queue,
  /// which is the same work as [reorder] below.
  @override
  void setRepeatMode(MusicRepeatMode mode) {
    _queue.repeatMode = mode;
    unawaited(_pushRepeatMode(mode));
    notifyListeners();
  }

  Future<void> _pushRepeatMode(MusicRepeatMode mode) async {
    try {
      await _players.setRepeatMode(_queueId, mode);
    } catch (e) {
      appLogger.d('Could not set repeat mode on ${_output.name}: $e');
    }
  }

  @override
  void toggleShuffle() {
    _queue.toggleShuffle();
    notifyListeners();
    unawaited(_republishUpcoming());
  }

  @override
  void removeAt(int index) {
    if (_queue.removeAt(index)) {
      notifyListeners();
      unawaited(_republishUpcoming());
    }
  }

  @override
  void reorder(int from, int to) {
    _queue.move(from, to);
    notifyListeners();
    unawaited(_republishUpcoming());
  }

  @override
  void addNext(List<MediaItem> tracks) {
    _queue.addNext(tracks);
    notifyListeners();
    unawaited(_republishUpcoming());
  }

  @override
  void addToEnd(List<MediaItem> tracks) {
    _queue.addToEnd(tracks);
    notifyListeners();
    unawaited(_republishUpcoming());
  }

  @override
  void clearUpcoming() {
    _queue.clearUpcoming();
    notifyListeners();
    unawaited(_republishUpcoming());
  }

  /// Re-send everything after the sounding track.
  ///
  /// The local list is what the user edits; the server's copy is what sounds.
  /// An edit that is not pushed means the next track is simply the wrong one.
  ///
  /// Music Assistant has no "replace everything after the current item" for a
  /// queue built from plain URLs, so this stops the divergence at its source:
  /// it re-reads nothing and re-sends the tail, and the sent-handle record is
  /// rebuilt to match so a later reading still resolves.
  Future<void> _republishUpcoming() async {
    if (_disposed || _foreignQueue) return;
    final cursor = _queue.cursor;
    if (cursor < 0) return;
    final upcoming = _queue.queue.sublist(cursor + 1);
    final intent = _playIntent;
    final handles = <String>[];
    for (final track in upcoming) {
      if (_disposed || !isPlayIntentCurrent(intent)) return;
      try {
        handles.add((await _resolver.resolve(track, targetServerId: _output.serverId)).value);
      } catch (e) {
        appLogger.w('Skipping ${track.displayTitle} while re-queueing: $e');
      }
    }
    if (_disposed || !isPlayIntentCurrent(intent)) return;
    try {
      await _players.replaceUpcoming(_queueId, handles);
      // The record now describes: everything up to and including the sounding
      // item, then the tail that was just sent. Kept in step with the server's
      // indices so a later reading still resolves to a local track.
      final keep = (cursor + 1).clamp(0, _sentHandles.length);
      _sentHandles
        ..removeRange(keep, _sentHandles.length)
        ..addAll(handles);
    } catch (e, st) {
      appLogger.w('Could not re-queue ${_output.name}', error: e, stackTrace: st);
      _report(e);
    }
  }

  // ----------------------------------------------------------- sleep timer

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;
  Duration? _sleepTimerDuration;
  bool _sleepTimerEndOfTrack = false;

  @override
  bool get sleepTimerActive => _sleepTimer != null || _sleepTimerEndOfTrack;

  DateTime? get sleepTimerEndsAt => _sleepTimerEndsAt;

  @override
  Duration? get sleepTimerDuration => _sleepTimerDuration;

  @override
  bool get sleepTimerEndOfTrack => _sleepTimerEndOfTrack;

  @override
  void setSleepTimer(Duration? duration, {bool endOfTrack = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndsAt = null;
    _sleepTimerDuration = null;
    _sleepTimerEndOfTrack = endOfTrack;
    if (endOfTrack) {
      notifyListeners();
      return;
    }
    if (duration != null) {
      _sleepTimerDuration = duration;
      _sleepTimerEndsAt = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () {
        _sleepTimer = null;
        _sleepTimerEndsAt = null;
        _sleepTimerDuration = null;
        unawaited(pause());
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // --------------------------------------------------------------- lyrics

  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async {
    final client = _clientFor(track);
    if (client == null) return null;
    return client.fetchLyrics(track);
  }

  MediaServerClient? _clientFor(MediaItem item) {
    final serverId = serverIdOrNull(item.serverId);
    if (serverId == null) return null;
    return _serverManager.getClient(serverId);
  }

  @override
  void dispose() {
    _disposed = true;
    _sleepTimer?.cancel();
    _intentExpiry?.cancel();
    _ticker?.cancel();
    _poll?.cancel();
    unawaited(_readings?.cancel());
    unawaited(_positions.close());
    unawaited(_errors.close());
    _volumeListenable.dispose();
    super.dispose();
  }
}
