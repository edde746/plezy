import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../media/ids.dart';
import '../../utils/app_logger.dart';
import '../multi_server_manager.dart';
import '../music_assistant/music_assistant_players.dart';
import '../music_assistant_client.dart';
import '../settings_service.dart';
import 'music_output.dart';
import '../../i18n/strings.g.dart';

/// The `players/*` handle for the server that owns [output].
///
/// Throws [StateError] when that server is not bound — which is a real state
/// (the user removed the connection while a speaker was selected) and one the
/// caller must not paper over by playing on the phone instead without saying
/// so.
MusicAssistantPlayers musicAssistantPlayersFor(MultiServerManager serverManager, MusicOutput output) {
  final serverId = output.serverId;
  if (serverId == null) {
    throw StateError('${output.name} is not a Music Assistant player');
  }
  final client = serverManager.getClient(ServerId(serverId));
  if (client is! MusicAssistantClient) {
    throw StateError('The Music Assistant server behind ${output.name} is not connected');
  }
  return MusicAssistantPlayers(client.api);
}

/// Discovers every output the user could play to, and remembers which one they
/// chose.
///
/// ### Why the phone wins a tie
///
/// With no stored choice this stays on the phone. Preferring a speaker was
/// tried and was wrong in three ways at once: the speaker picked is whichever
/// discovery returned first, so it is arbitrary; the app then mirrors that
/// player's queue, which reports `playing` for audio this session never sent
/// and leaves `currentTrack` null; and tapping a track sends it to a room the
/// listener may not be in.
///
/// The device in someone's hand is the only output they are certainly present
/// for. A speaker is a deliberate choice, and the stored choice always wins.
///
/// ### Fan-out
///
/// One `players/all` per server per refresh, serialized. The Music Assistant
/// socket wedges under concurrent load, so refreshes run one at a time.
class MusicOutputController extends ChangeNotifier {
  /// Earlier builds registered this device as a player, and servers remember it.
  static const String _staleOwnPlayerPrefix = 'ma_plezy_';

  MusicOutputController({required this.serverManager, Future<SettingsService> Function()? settingsLoader})
    : _settingsLoader = settingsLoader ?? SettingsService.getInstance;

  final MultiServerManager serverManager;
  final Future<SettingsService> Function() _settingsLoader;

  StreamSubscription<Map<String, bool>>? _statusSubscription;

  /// Keyed by the client instance being watched, so a replaced client's
  /// subscription can be found and cancelled rather than accumulating.
  final Map<MusicAssistantClient, StreamSubscription<void>> _playerSubscriptions = {};

  /// The last list each server actually answered with.
  ///
  /// A server that cannot be asked right now — its socket dropped, or
  /// `players/all` failed — used to contribute nothing, so its rooms vanished
  /// from the list. [_reconcileSelection] then read the chosen speaker as gone
  /// and fell back to the phone, which stops the remote engine mid-session:
  /// the audio carries on in the room (the server is the one playing it) while
  /// the app loses the track, and with it the only transport the user has.
  ///
  /// Remembering what a server last said turns a momentary silence into
  /// exactly that — a silence — instead of a removal.
  final Map<String, List<MusicOutput>> _lastKnownByServer = {};

  List<MusicOutput> _outputs = const [MusicOutput.thisDevice];
  List<MusicOutput> _groupableRooms = const [];
  MusicOutput _selected = MusicOutput.thisDevice;
  bool _restored = false;
  bool _disposed = false;
  Future<void>? _pendingRefresh;
  Timer? _debounce;

  /// Every output, local first, then remote players in server order.
  ///
  /// Includes unavailable ones: see [MusicOutput.unavailableReason].
  List<MusicOutput> get outputs => List.unmodifiable(_outputs);

  /// Rooms that can be put in a sync group together.
  ///
  /// Not a subset of [outputs]. A room already in a group is hidden there,
  /// because the group is the destination, but is exactly what someone changing
  /// the group needs to see.
  List<MusicOutput> get groupableRooms => List.unmodifiable(_groupableRooms);

  /// Outputs that can actually be played to right now.
  List<MusicOutput> get playableOutputs => _outputs.where((output) => output.available).toList(growable: false);

  MusicOutput get selected => _selected;

  /// True once a remote player has been seen, i.e. the picker is worth showing.
  bool get hasRemoteOutputs => _outputs.any((output) => output.isRemote);

  /// Begin watching for servers and players.
  Future<void> start() async {
    if (_disposed || _statusSubscription != null) return;
    _statusSubscription = serverManager.statusStream.listen(
      (_) => _requestRefresh(),
      onError: (Object error, StackTrace stackTrace) {
        appLogger.w('Music output discovery lost the status stream', error: error, stackTrace: stackTrace);
      },
    );
    await _restoreSelection();
    await refresh();
  }

  /// Re-read the player list from every bound Music Assistant server.
  Future<void> refresh() {
    if (_disposed) return Future<void>.value();
    _pendingRefresh = (_pendingRefresh ?? Future<void>.value()).then((_) => _refresh());
    return _pendingRefresh!;
  }

  /// Coalesce bursts: a group change emits a run of `player_updated` events and
  /// re-reading the whole list for each one is exactly the fan-out that wedges
  /// the server.
  void _requestRefresh() {
    if (_disposed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => unawaited(refresh()));
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    final discovered = <MusicOutput>[MusicOutput.thisDevice];
    final groupable = <MusicOutput>[];
    final live = <MusicAssistantClient>{};

    for (final rawId in serverManager.serverIds) {
      if (_disposed) return;
      final client = serverManager.getClient(ServerId(rawId));
      if (client is! MusicAssistantClient) continue;
      live.add(client);
      if (!client.api.isConnected) {
        discovered.addAll(_unreachable(rawId));
        continue;
      }
      try {
        // Serial by construction: awaited inside the loop, one server at a
        // time, so several Music Assistant servers cannot fan out either.
        final players = await MusicAssistantPlayers(client.api).players();
        final answered = <MusicOutput>[];
        final groupIds = {
          for (final player in players)
            if (player.isGroupPlayer) player.playerId,
        };
        for (final player in players) {
          // This device is already in the list as `thisDevice`; listing our own
          // registration again would offer two names for one speaker.
          //
          // The prefix, not just the current id: an earlier install of this app
          // registered under a different one, and the server remembers it. That
          // stale entry can never be played to — it shows as permanently
          // unavailable — so it is noise in the one menu that has to be clear.
          if (player.playerId.startsWith(_staleOwnPlayerPrefix)) continue;
          if (player.hidden) continue;
          if (player.supportsGrouping && player.available) {
            groupable.add(MusicOutput.fromPlayer(player, serverId: rawId));
          }
          // A sync group's leader looks like a free room, being neither synced
          // to anything nor short of members, but playing to it would pull it
          // out of the group.
          if (groupIds.contains(player.activeGroup)) continue;
          // A grouped *member* is driven through its leader, and offering it as
          // its own destination sends audio the leader immediately overrides.
          //
          // The leader is not that. It reports the group's id as its active
          // group — `MaPlayer.hasForeignSource` says so in as many words —
          // which the old test here also matched, so a stereo pair or any
          // grouped room disappeared from the list entirely. Its owner then
          // looked like a speaker that had gone away, and the selection fell
          // back to the phone mid-session.
          //
          // Children are what separate the two: a leader has them, a follower
          // does not.
          if (player.isFollower) continue;
          final output = MusicOutput.fromPlayer(player, serverId: rawId);
          answered.add(player.isGroupPlayer ? output.copyWith(volume: _memberVolume(player, players)) : output);
        }
        _lastKnownByServer[rawId] = List.unmodifiable(answered);
        discovered.addAll(answered);
        _watchPlayers(client);
      } catch (e, st) {
        // Keep what this server last said rather than dropping its rooms: a
        // failed listing is a server that did not answer, not a server that
        // answered "no rooms".
        appLogger.w('Could not list Music Assistant players for $rawId', error: e, stackTrace: st);
        discovered.addAll(_unreachable(rawId));
      }
    }

    if (_disposed) return;
    _pruneWatchers(live);
    _outputs = List.unmodifiable(discovered);
    _groupableRooms = List.unmodifiable(groupable);
    _reconcileSelection();
    notifyListeners();
  }

  /// What [serverId] last offered, marked unplayable because it cannot be
  /// asked right now. Empty when it has never answered.
  Iterable<MusicOutput> _unreachable(String serverId) => (_lastKnownByServer[serverId] ?? const <MusicOutput>[]).map(
    (output) => output.copyWith(available: false, unavailableReason: t.music.outputServerUnreachable),
  );

  /// Keep the list live without polling: the server already tells us.
  ///
  /// One subscription per live client. This used to append per refresh and
  /// stop at a cap of eight, so after eight rebinds the controller was holding
  /// eight dead subscriptions and had quietly stopped watching the live
  /// client — the speaker list froze with no error anywhere.
  void _watchPlayers(MusicAssistantClient client) {
    if (_playerSubscriptions.containsKey(client)) return;
    _playerSubscriptions[client] = MusicAssistantPlayers(client.api).playerChanges().listen((_) => _requestRefresh());
  }

  /// Drop subscriptions to clients that are no longer bound.
  void _pruneWatchers(Set<MusicAssistantClient> live) {
    _playerSubscriptions.removeWhere((client, subscription) {
      if (live.contains(client)) return false;
      unawaited(subscription.cancel());
      return true;
    });
  }

  /// Play to [rooms] at once: find or create their sync group and select it.
  ///
  /// All of [rooms] must be on one server, since a group cannot span two.
  /// Throws what the server said, for the caller to show: the selection only
  /// moves once the group is real.
  Future<void> selectGroup(List<MusicOutput> rooms) async {
    final first = rooms.first;
    final group = await musicAssistantPlayersFor(
      serverManager,
      first,
    ).syncGroup({for (final room in rooms) room.playerId!}, name: rooms.map((room) => room.name).join(' + '));
    await refresh();
    await select(
      _findById('${first.serverId}|${group.playerId}') ?? MusicOutput.fromPlayer(group, serverId: first.serverId!),
    );
  }

  /// [group]'s volume, read from its rooms.
  ///
  /// A group that has not played yet reports `group_volume: 0`, measured on
  /// 2.10.9 with its rooms at 50. Believing that opens the slider at nothing,
  /// and the next press of a volume button sets every room to almost silent.
  int? _memberVolume(MaPlayer group, List<MaPlayer> players) {
    final levels = [
      for (final player in players)
        if (group.groupChilds.contains(player.playerId)) player.volumeLevel,
    ];
    if (levels.isEmpty) return null;
    return (levels.reduce((a, b) => a + b) / levels.length).round();
  }

  /// Choose where audio comes out. Persisted immediately, so the choice
  /// survives a crash as well as a clean exit.
  Future<void> select(MusicOutput output) async {
    if (_disposed) return;
    // Recorded even when the id is unchanged: choosing the output that was
    // *defaulted* to is a real choice, and it is what stops a later refresh
    // re-deriving a different default.
    final wasChosen = _chosen;
    _chosen = true;
    _storedId = null;
    if (_selected.id == output.id && wasChosen) return;
    _selected = output;
    notifyListeners();
    try {
      final settings = await _settingsLoader();
      await settings.write(SettingsService.musicOutputId, output.id);
    } catch (e, st) {
      appLogger.w('Could not remember the chosen music output', error: e, stackTrace: st);
    }
  }

  Future<void> _restoreSelection() async {
    if (_restored) return;
    _restored = true;
    try {
      final settings = await _settingsLoader();
      final stored = settings.read(SettingsService.musicOutputId);
      if (stored.isNotEmpty) _storedId = stored;
    } catch (e) {
      appLogger.d('Could not read the stored music output: $e');
    }
  }

  String? _storedId;

  /// Whether the current selection is a *choice* rather than a default.
  ///
  /// The distinction cannot be recovered from [_selected] alone, and assuming
  /// it could was a bug: [MusicOutput.thisDevice] is always in the list, so
  /// "the user picked the phone" and "nobody has picked anything" both look
  /// like a selection that is present and valid, and the prefer-a-speaker rule
  /// never fired at all.
  bool _chosen = false;

  /// Re-point the selection at the freshly-read list.
  ///
  /// In order:
  ///
  /// 1. A stored output that is now present — take it. If it is stored but not
  ///    present, keep waiting rather than choosing something else: the server
  ///    may still be connecting, and the phone is a fine place to be
  ///    meanwhile.
  /// 2. Nothing ever chosen — stay on the phone, per the class doc.
  /// 3. A live choice — refresh the availability and volume snapshot on it.
  /// 4. A choice that has gone away (a speaker unplugged, a server removed) —
  ///    fall back to the phone, which is always there. Deliberately *not* a
  ///    silent hop to a different speaker: audio appearing in a room nobody
  ///    chose is worse than audio appearing on the device in their hand.
  void _reconcileSelection() {
    final storedId = _storedId;
    if (storedId != null) {
      final match = _findById(storedId);
      if (match == null) return;
      _storedId = null;
      _chosen = true;
      _selected = match;
      return;
    }

    if (!_chosen) {
      _selected = MusicOutput.thisDevice;
      return;
    }

    final live = _findById(_selected.id);
    if (live != null) {
      _selected = live;
      return;
    }

    if (_selected.isRemote) {
      appLogger.i('Music output ${_selected.name} is gone; falling back to this device');
      _selected = MusicOutput.thisDevice;
    }
  }

  MusicOutput? _findById(String id) {
    for (final output in _outputs) {
      if (output.id == id) return output;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    unawaited(_statusSubscription?.cancel());
    for (final subscription in _playerSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _playerSubscriptions.clear();
    super.dispose();
  }
}
