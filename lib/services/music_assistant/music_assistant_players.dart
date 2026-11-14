import 'dart:async';

import '../music/music_playback_service.dart' show MusicRepeatMode;
import 'music_assistant_api.dart';

/// Coarse state Music Assistant reports for a player or its queue.
///
/// Deliberately small. The wire vocabulary observed on 2.6.3 is
/// `idle` / `playing` / `paused` / `buffering`, and everything that is not
/// clearly one of the first three collapses into [idle] rather than being
/// invented.
enum MaPlayerState { idle, playing, paused, buffering }

MaPlayerState _stateFromWire(Object? value) => switch (value?.toString()) {
  'playing' => MaPlayerState.playing,
  'paused' => MaPlayerState.paused,
  'buffering' => MaPlayerState.buffering,
  _ => MaPlayerState.idle,
};

/// Rooms a new sync group silently left out.
///
/// `players/create_group_player` drops any member it cannot sync with the first
/// and still succeeds, so this is raised from reading the group back.
class MaGroupRefusedException implements Exception {
  /// The player ids that did not make it in.
  final Set<String> refused;

  const MaGroupRefusedException(this.refused);

  @override
  String toString() => 'MaGroupRefusedException($refused)';
}

/// One output Music Assistant knows about: a Sonos room, a group, another
/// app's builtin player, anything with a `player_id`.
///
/// Only the fields something in Plezy actually reads are decoded. The wire
/// object carries about forty, most of them provider bookkeeping.
class MaPlayer {
  final String playerId;

  /// What to show a user. Music Assistant sets `display_name` from the
  /// speaker's own name, which is where the emoji in "➡️ 🥙 Dining Room" come
  /// from — they are the owner's, and are shown rather than stripped.
  final String name;

  /// `sonos`, `builtin_player`, `chromecast`, …
  final String provider;

  /// Whether the provider currently considers this player reachable and
  /// controllable.
  ///
  /// This is the one field that decides whether an output can be offered.
  /// A Sonos held by another source reports `false` here.
  final bool available;

  final bool powered;
  final MaPlayerState state;

  /// What is currently feeding the player.
  ///
  /// Equal to [playerId] when Music Assistant itself is the source. Anything
  /// else — `airplay`, `Spotify`, a TV's optical input — means somebody else
  /// has the speaker, and is worth *saying* rather than silently hiding: a
  /// room that has vanished from the list looks like a bug, where "in use by
  /// Spotify" is an answer.
  final String? activeSource;

  /// Player ids in the group this one leads, itself included, or empty when it
  /// leads nothing. Empty on a follower too: see [syncedTo]. On a sync group,
  /// its members, which it reports whether or not it is playing.
  final List<String> groupChilds;

  /// The leader this player is synced to, if any.
  ///
  /// The only field that identifies a grouped Sonos room on 2.10.9. Measured
  /// with a follower in a live group: `group_members: []`, `active_group: null`,
  /// `synced_to: <leader>`, `active_source: <leader>`.
  final String? syncedTo;

  /// The group this player has been swallowed by, if any. A grouped member is
  /// controlled through its leader, so it is not offered separately.
  final String? activeGroup;

  /// 0–100, the same scale [MusicPlaybackService] uses.
  final int volumeLevel;

  final bool volumeMuted;

  /// Verbatim `supported_features` strings. Read for capability checks
  /// (`volume_set`, `seek`, `next_previous`) rather than assumed: the builtin
  /// player and a Sonos advertise genuinely different sets.
  final Set<String> supportedFeatures;

  /// Not something to play to, because the server says not to offer it.
  ///
  /// `private` is a player that belongs to one client, such as a browser tab
  /// running Music Assistant's own web player. `hide_in_ui` is the owner's
  /// choice, made in that same web UI.
  final bool hidden;

  /// A group that exists as a player in its own right, with its own queue,
  /// rather than a room that happens to be leading one.
  final bool isGroupPlayer;

  const MaPlayer({
    required this.playerId,
    required this.name,
    required this.provider,
    required this.available,
    required this.powered,
    required this.state,
    required this.volumeLevel,
    this.activeSource,
    this.groupChilds = const [],
    this.syncedTo,
    this.activeGroup,
    this.volumeMuted = false,
    this.supportedFeatures = const {},
    this.hidden = false,
    this.isGroupPlayer = false,
  });

  bool get isGroup => isGroupPlayer || groupChilds.isNotEmpty;

  /// Whether this room can join others in a sync group.
  bool get supportsGrouping => !isGroupPlayer && supportedFeatures.contains('set_members');

  /// Driven by another player, so not a destination of its own.
  ///
  /// Belonging to a group is not enough: the leader belongs to it too, and
  /// reports the group's id exactly as its members do. Only a member lacks
  /// children of its own.
  bool get isFollower {
    final leader = syncedTo;
    if (leader != null && leader.isNotEmpty && leader != playerId) return true;
    final group = activeGroup;
    if (group == null || group.isEmpty) return false;
    if (group == playerId) return false;
    return !isGroup;
  }

  bool get supportsVolume => supportedFeatures.contains('volume_set');

  bool get supportsSeek => supportedFeatures.contains('seek');

  bool get supportsNextPrevious => supportedFeatures.contains('next_previous');

  /// True when something other than Music Assistant is feeding this player.
  ///
  /// [activeSource] equal to the player's own id is Music Assistant driving it
  /// directly; null means nothing is. Neither is a foreign source.
  bool get hasForeignSource {
    final source = activeSource;
    if (source == null || source.isEmpty) return false;
    if (source == playerId) return false;
    // A group leader reports the group's id while it drives its members.
    if (source == activeGroup) return false;
    // A follower reports its leader, whose audio it is playing.
    if (source == syncedTo) return false;
    // A room keeps naming the sync group after the group has stopped, and even
    // after it has been deleted: measured with the room idle and `active_group`
    // null. That is a stale reading, not somebody else holding the speaker.
    if (source.startsWith(MusicAssistantPlayers.syncGroupIdPrefix)) return false;
    return true;
  }

  static MaPlayer? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['player_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final name = (value['display_name'] ?? value['name'])?.toString().trim();
    return MaPlayer(
      playerId: id,
      name: name == null || name.isEmpty ? id : name,
      provider: value['provider']?.toString() ?? '',
      // Absent means available: the field is only written by providers that
      // track reachability, and treating "not reported" as unavailable would
      // hide every player from a provider that does not.
      available: value['available'] as bool? ?? true,
      powered: value['powered'] as bool? ?? true,
      // `playback_state` and `group_members` are the current names; 2.10.9
      // still mirrors them as `state` and `group_childs`, labelled as aliases
      // for backwards compatibility, and 2.6.3 has only the old ones.
      state: _stateFromWire(value['playback_state'] ?? value['state']),
      activeSource: value['active_source']?.toString(),
      groupChilds: _stringList(value['group_members'] ?? value['group_childs']),
      syncedTo: value['synced_to']?.toString(),
      activeGroup: value['active_group']?.toString(),
      // A sync group has no level of its own: `volume_level` is null and the
      // average of its members is in `group_volume`.
      volumeLevel: _intOr(value['volume_level'] ?? value['group_volume'], 0),
      volumeMuted: value['volume_muted'] as bool? ?? false,
      supportedFeatures: _stringList(value['supported_features']).toSet(),
      hidden: value['private'] == true || value['hide_in_ui'] == true,
      isGroupPlayer: value['type'] == 'group',
    );
  }

  @override
  String toString() => 'MaPlayer($playerId, $name, available: $available, state: $state)';
}

/// One reading of a player queue.
///
/// The queue — not the player — is the authority on position. See
/// [MusicAssistantPlayers.queueState] for the measurement that settled that.
class MaQueueState {
  final String queueId;
  final MaPlayerState state;

  /// Seconds into the current item, as of [elapsedAt].
  final double elapsed;

  /// Server clock when [elapsed] was taken, from `elapsed_time_last_updated`.
  ///
  /// Needed because the server only pushes a reading about once a second and
  /// a progress bar runs at 60Hz; the gap is covered by adding wall-clock time
  /// to the last reading rather than by counting locally from zero.
  final DateTime? elapsedAt;

  final int? currentIndex;

  /// Runtime of the current item, as Music Assistant read it out of the file.
  final Duration? currentDuration;

  /// `streamdetails.item_id` of the sounding item.
  ///
  /// For the URLs this feature queues, that is **the exact URL that was sent**
  /// — verified on 2.6.3. It is what maps a reading back to a local track,
  /// and it is an observation of the server's queue rather than a belief
  /// about it.
  /// Every identifier the server gave for the sounding item.
  ///
  /// One reading can carry several — a uri, a stream item id, a bare item id —
  /// and which of them names what this app sent depends on what was queued.
  /// Matching against all of them is the only thing that works for both.
  final Set<String> currentItemIds;

  /// The first identifier, for logging and for callers that just need one.
  String? get currentItemId => currentItemIds.isEmpty ? null : currentItemIds.first;

  /// The name Music Assistant derived from the file's own metadata, e.g.
  /// `":zoviet*france: - Amber Rose Hand"`. Diagnostic only — the app shows
  /// its own title, from the server the user browsed.
  final String? currentItemName;

  /// How many items the server says are in the queue.
  final int itemCount;

  /// True when this reading was synthesised from a `queue_time_updated` tick
  /// rather than received as a queue update.
  ///
  /// A tick reports a position and nothing else, so every identity field on it
  /// is the previous reading's carried forward. It is therefore *not* new
  /// evidence about which queue is playing, and anything deciding that
  /// question has to skip it — a stale handle replayed once a second otherwise
  /// looks like repeated confirmation.
  final bool fromTimeTick;

  const MaQueueState({
    required this.queueId,
    required this.state,
    required this.elapsed,
    this.elapsedAt,
    this.currentIndex,
    this.currentDuration,
    this.currentItemIds = const <String>{},
    this.currentItemName,
    this.itemCount = 0,
    this.fromTimeTick = false,
  });

  /// [elapsed] advanced to now, when the queue is playing.
  ///
  /// Clamped to [currentDuration] so a late reading can never present a
  /// position past the end of the track — the same rule the local session
  /// already applies, and for the same reason: this number reaches the
  /// progress bar and the lock screen.
  Duration positionAt(DateTime now) {
    var seconds = elapsed;
    final takenAt = elapsedAt;
    if (state == MaPlayerState.playing && takenAt != null) {
      final drift = now.difference(takenAt);
      if (!drift.isNegative) seconds += drift.inMilliseconds / 1000.0;
    }
    if (seconds < 0) seconds = 0;
    final duration = currentDuration;
    final position = Duration(milliseconds: (seconds * 1000).round());
    if (duration != null && position > duration) return duration;
    return position;
  }

  static MaQueueState? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['queue_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final item = value['current_item'];
    final itemMap = item is Map<String, dynamic> ? item : const <String, dynamic>{};
    final streamDetails = itemMap['streamdetails'];
    final streamMap = streamDetails is Map<String, dynamic> ? streamDetails : const <String, dynamic>{};
    final durationSeconds = _numOr(itemMap['duration'], -1);
    final updatedAt = _numOr(value['elapsed_time_last_updated'], 0);
    return MaQueueState(
      queueId: id,
      state: _stateFromWire(value['state']),
      elapsed: _numOr(value['elapsed_time'], 0).toDouble(),
      elapsedAt: updatedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch((updatedAt * 1000).round(), isUtc: true).toLocal()
          : null,
      currentIndex: value['current_index'] is num ? (value['current_index'] as num).toInt() : null,
      currentDuration: durationSeconds > 0 ? Duration(milliseconds: (durationSeconds * 1000).round()) : null,
      // Every identifier the server offers, because which one names what this
      // app sent depends on what it queued. A Music Assistant library track
      // comes back as `media_item.uri` (`library://track/23461`, matching what
      // was sent) while its `item_id` is the bare `23461`; a plain URL — what
      // the Plex path queues — comes back as `streamdetails.item_id`, the
      // exact URL that was sent.
      //
      // Preferring one of them broke the other: picking the uri first made
      // every URL queue look like somebody else's, so the session reported no
      // current track and the transport vanished while the speaker played the
      // very track that had just been tapped.
      currentItemIds: <String>{
        for (final candidate in [_mediaItemUri(itemMap), streamMap['item_id'], _mediaItemId(itemMap)])
          if (candidate != null && candidate.toString().isNotEmpty) candidate.toString(),
      },
      currentItemName: itemMap['name']?.toString(),
      itemCount: _intOr(value['items'], 0),
    );
  }

  static Object? _mediaItemId(Map<String, dynamic> item) {
    final media = item['media_item'];
    return media is Map<String, dynamic> ? media['item_id'] : null;
  }

  static Object? _mediaItemUri(Map<String, dynamic> item) {
    final media = item['media_item'];
    return media is Map<String, dynamic> ? media['uri'] : null;
  }

  @override
  String toString() => 'MaQueueState($queueId, $state, elapsed: $elapsed, index: $currentIndex, items: $itemCount)';
}

/// How a queue command treats what is already queued.
enum MaEnqueueOption {
  /// Throw the queue away and play this instead.
  replace,

  /// Append after everything already queued.
  add,

  /// Replace everything *after* the sounding item, leaving it playing.
  replaceNext,
}

String _enqueueWire(MaEnqueueOption option) => switch (option) {
  MaEnqueueOption.replace => 'replace',
  MaEnqueueOption.add => 'add',
  MaEnqueueOption.replaceNext => 'replace_next',
};

/// The `players/*` and `player_queues/*` command families.
///
/// ### Why this is a separate object from the builtin player
///
/// [MusicAssistantBuiltinPlayer] registers *this device* and answers commands
/// aimed at it. This drives *other people's* players, which is the opposite
/// direction, and until now nothing in Plezy did it at all — the app could
/// only ever address the phone.
///
/// ### The measurement that shapes this class
///
/// `players/all` reports an `elapsed_time` per player, and it is **not usable
/// for progress**. Measured against a Sonos playing a 146s track, the player's
/// `elapsed_time` froze at 4.907 and stayed there for the whole 131s the probe
/// ran, while the state stayed `playing` and the audio genuinely played to the
/// end. Over the same run `player_queues/all` reported `elapsed_time` of
/// 4, 9, 14 … 130 — one second per second. So [queueState] is the authority on
/// position and [players] is the authority on existence, availability and
/// volume. Reading position off the player object produces a progress bar that
/// sticks at five seconds and a track that never appears to end.
class MusicAssistantPlayers {
  MusicAssistantPlayers(this._api);

  final MusicAssistantApi _api;

  /// Every player the server knows, including unavailable ones.
  ///
  /// Filtering happens a layer up, in [MusicOutputController], because
  /// "unavailable" is a thing the user is told rather than a thing that is
  /// hidden.
  /// Every sync group's player id starts with this.
  static const String syncGroupIdPrefix = 'syncgroup_';

  static const String _syncGroupProvider = 'sync_group';
  static const int _groupReadAttempts = 5;
  static const Duration _groupReadInterval = Duration(milliseconds: 300);

  Future<List<MaPlayer>> players() async {
    final result = await _api.sendCommand('players/all');
    if (result is! List) {
      throw MaProtocolException('players/all', 'Expected a list, got ${result.runtimeType}');
    }
    return result.map(MaPlayer.fromJson).whereType<MaPlayer>().toList(growable: false);
  }

  /// The sync group holding exactly [memberIds], created as [name] if there is
  /// none yet.
  ///
  /// Reusing an exact match keeps a server from gathering a new group every
  /// time the same rooms are picked. Created as `dynamic`, which is what lets
  /// its members be changed from Music Assistant's own UI while it plays.
  ///
  /// The group is a real player: it has its own queue, so everything that
  /// addresses a player id works on it unchanged. Verified on 2.10.9, including
  /// that `player_queues/next`, `seek` and `pause` work although the group does
  /// not list `next_previous` or `seek` in its features, and that starting a
  /// group takes a member over from whatever it was playing, another group
  /// included. Creating one takes an admin account.
  Future<MaPlayer> syncGroup(Set<String> memberIds, {required String name}) async {
    final existing = _syncGroupIn(await players(), memberIds);
    if (existing != null) return existing;

    final created = await _api.sendCommandForMap(
      'players/create_group_player',
      args: {'provider': _syncGroupProvider, 'name': name, 'members': memberIds.toList(), 'dynamic': true},
    );
    final groupId = created['player_id']?.toString();
    if (groupId == null || groupId.isEmpty) {
      throw const MaProtocolException('players/create_group_player', 'Expected a player id');
    }

    // The reply carries `group_members: []` however many were accepted, and the
    // listing takes a moment to catch up, so only a reading of the group says
    // what the server kept.
    final group = await _awaitMembers(groupId);
    final refused = memberIds.difference(group?.groupChilds.toSet() ?? const {});
    if (group == null || refused.isNotEmpty) {
      await _api.sendCommand('players/remove_group_player', args: {'player_id': groupId});
      throw MaGroupRefusedException(refused);
    }
    return group;
  }

  MaPlayer? _syncGroupIn(List<MaPlayer> all, Set<String> memberIds) {
    for (final player in all) {
      if (player.provider != _syncGroupProvider) continue;
      final members = player.groupChilds.toSet();
      if (members.length == memberIds.length && members.containsAll(memberIds)) return player;
    }
    return null;
  }

  Future<MaPlayer?> _awaitMembers(String groupId) async {
    MaPlayer? group;
    for (var attempt = 0; attempt < _groupReadAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_groupReadInterval);
      for (final player in await players()) {
        if (player.playerId == groupId) group = player;
      }
      if (group?.groupChilds.isNotEmpty ?? false) return group;
    }
    return group;
  }

  /// The queue belonging to [queueId], or null when the server has none.
  ///
  /// A queue id is a player id: Music Assistant gives every player exactly one
  /// queue and names it after the player.
  Future<MaQueueState?> queueState(String queueId) async {
    final result = await _api.sendCommand('player_queues/all');
    if (result is! List) {
      throw MaProtocolException('player_queues/all', 'Expected a list, got ${result.runtimeType}');
    }
    for (final entry in result) {
      final queue = MaQueueState.fromJson(entry);
      if (queue != null && queue.queueId == queueId) return queue;
    }
    return null;
  }

  /// Queue [urls] on [queueId] and start playing.
  ///
  /// The urls are handed over verbatim and Music Assistant fetches them
  /// itself — it resolves title and duration from the file's own metadata and
  /// never consults its own library. That is the whole reason this feature
  /// needs no matching between Plex and Music Assistant: the speaker is told
  /// where the bytes are, and the bytes are Plex's.
  Future<void> playMedia(String queueId, List<String> urls, {MaEnqueueOption option = MaEnqueueOption.replace}) {
    if (urls.isEmpty) return Future<void>.value();
    return _api.sendCommand(
      'player_queues/play_media',
      args: {'queue_id': queueId, 'media': urls, 'option': _enqueueWire(option)},
    );
  }

  Future<void> play(String queueId) => _api.sendCommand('player_queues/play', args: {'queue_id': queueId});

  Future<void> pause(String queueId) => _api.sendCommand('player_queues/pause', args: {'queue_id': queueId});

  Future<void> playPause(String queueId) => _api.sendCommand('player_queues/play_pause', args: {'queue_id': queueId});

  Future<void> next(String queueId) => _api.sendCommand('player_queues/next', args: {'queue_id': queueId});

  Future<void> previous(String queueId) => _api.sendCommand('player_queues/previous', args: {'queue_id': queueId});

  Future<void> stop(String queueId) => _api.sendCommand('player_queues/stop', args: {'queue_id': queueId});

  /// Seek within the sounding item. Positions are item-relative, matching
  /// [MaQueueState.elapsed].
  Future<void> seek(String queueId, Duration position) =>
      _api.sendCommand('player_queues/seek', args: {'queue_id': queueId, 'position': position.inSeconds});

  /// Jump to queue index [index].
  Future<void> playIndex(String queueId, int index) =>
      _api.sendCommand('player_queues/play_index', args: {'queue_id': queueId, 'index': index});

  /// Replace everything queued after the sounding item, leaving it playing.
  ///
  /// An empty [urls] still sends the command: "nothing follows this track" is
  /// a real edit, and it is exactly what "clear upcoming" means.
  Future<void> replaceUpcoming(String queueId, List<String> urls) => _api.sendCommand(
    'player_queues/play_media',
    args: {'queue_id': queueId, 'media': urls, 'option': _enqueueWire(MaEnqueueOption.replaceNext)},
  );

  /// Tell the server how to repeat.
  ///
  /// Required rather than optional, because the server decides what plays
  /// next and never consults the local queue. Leaving it unsent does not
  /// degrade to local behaviour, it degrades to nothing.
  Future<void> setRepeatMode(String queueId, MusicRepeatMode mode) => _api.sendCommand(
    'player_queues/repeat',
    args: {
      'queue_id': queueId,
      'repeat_mode': switch (mode) {
        MusicRepeatMode.off => 'off',
        MusicRepeatMode.all => 'all',
        MusicRepeatMode.one => 'one',
      },
    },
  );

  /// Set volume, 0–100.
  ///
  /// Verified against the real speaker: setting 0 and re-reading `players/all`
  /// returns 0, and restoring 2 returns 2. The read-back is what the caller
  /// should trust — a command that returns without error has only been
  /// *accepted*.
  Future<void> setVolume(String playerId, int volume) {
    final clamped = volume < 0
        ? 0
        : volume > 100
        ? 100
        : volume;
    return _api.sendCommand('players/cmd/volume_set', args: {'player_id': playerId, 'volume_level': clamped});
  }

  /// Volume as the server currently reports it, or null if it has no such
  /// player. For confirming a [setVolume] actually landed.
  Future<int?> volumeOf(String playerId) async {
    final all = await players();
    for (final player in all) {
      if (player.playerId == playerId) return player.volumeLevel;
    }
    return null;
  }

  /// Readings for [queueId], as fast as the server pushes them.
  ///
  /// Three events matter and they carry different things:
  ///
  /// - `queue_updated` — the full queue object, so state, index and the
  ///   sounding item all come from here.
  /// - `queue_time_updated` — a bare position tick, about once a second while
  ///   playing. Carries *only* the elapsed seconds, so it refreshes position
  ///   without disturbing anything else.
  /// - `player_updated` — deliberately **not** used for position, per the
  ///   measurement in this class's doc comment.
  ///
  /// Between ticks the caller extrapolates with [MaQueueState.positionAt].
  Stream<MaQueueState> queueUpdates(String queueId) {
    MaQueueState? latest;
    return _api.events
        .where((event) => event.objectId == queueId)
        .map<MaQueueState?>((event) {
          switch (event.event) {
            case 'queue_updated':
              final next = MaQueueState.fromJson(event.data);
              if (next != null) latest = next;
              return next;
            case 'queue_time_updated':
              final previous = latest;
              if (previous == null) return null;
              final seconds = _queueTimeSeconds(event.rawData);
              if (seconds == null) return null;
              final next = MaQueueState(
                queueId: previous.queueId,
                // A tick only arrives while the queue is running, but it says
                // nothing about state, so the last known state is carried
                // forward rather than assumed to be `playing`.
                state: previous.state,
                elapsed: seconds,
                elapsedAt: DateTime.now(),
                currentIndex: previous.currentIndex,
                currentDuration: previous.currentDuration,
                currentItemIds: previous.currentItemIds,
                currentItemName: previous.currentItemName,
                itemCount: previous.itemCount,
                fromTimeTick: true,
              );
              latest = next;
              return next;
            default:
              return null;
          }
        })
        .where((state) => state != null)
        .cast<MaQueueState>();
  }

  /// `queue_time_updated` carries a bare number on 2.6.3 — measured:
  /// `{"event":"queue_time_updated","object_id":"RINCON_…","data":3}`. The map
  /// shape is accepted too, so a build that wraps it keeps working.
  static double? _queueTimeSeconds(Object? data) {
    if (data is num) return data.toDouble();
    if (data is Map<String, dynamic>) {
      final value = data['elapsed_time'] ?? data['position'] ?? data['seconds'];
      if (value is num) return value.toDouble();
    }
    return null;
  }

  /// Players, whenever the server says one changed.
  ///
  /// Coalescing is the caller's job — a burst of `player_updated` during a
  /// group change is normal.
  Stream<void> playerChanges() => _api.events
      .where(
        (event) => event.event == 'player_updated' || event.event == 'player_added' || event.event == 'player_removed',
      )
      .map((_) {});
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry?.toString())
      .whereType<String>()
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

int _intOr(Object? value, int fallback) => value is num ? value.toInt() : fallback;

num _numOr(Object? value, num fallback) => value is num ? value : fallback;
