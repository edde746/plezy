import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:package_info_plus/package_info_plus.dart';

import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../media/media_version.dart';
import '../../media/title_copies.dart';
import '../../services/data_aggregation_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/media_server_http_client.dart';
import '../models/watch_copy.dart';
import '../models/watch_notice.dart';
import '../services/library_resolver.dart';
import '../services/media_descriptor.dart';
import '../services/player_adapter.dart';
import '../services/recent_rooms_service.dart';
import '../services/watch_party_relays.dart';

typedef WatchPartyFactory =
    owp.WatchParty<WatchCopy> Function({
      required owp.Relays relays,
      required String client,
      required String name,
      required owp.Resolver<WatchCopy>? resolver,
    });

/// Opens [copy] for the room: in place in an open player, or by pushing one.
/// Returns whether it is opening.
typedef ChoiceOpener = Future<bool> Function(WatchCopy copy);

/// What an open player screen gives the room.
class WatchPlayerHooks {
  const WatchPlayerHooks({required this.openInPlace, required this.exitPlayer});

  /// Switches the open player to [copy].
  final ChoiceOpener openInPlace;

  /// Closes the player: the room stopped its media.
  final VoidCallback exitPlayer;
}

/// Watch Together on Open Watch Party: one [owp.WatchParty] per room session,
/// the user's player attached to it, and the room's state and notices for the
/// UI.
///
/// The provider lives in the profile session, so a profile switch disposes of
/// it and the party with it.
class WatchTogetherProvider extends ChangeNotifier {
  /// Without [clientFor] and [findCopies] the user has no libraries: other
  /// participants' media finds nothing (widget tests that only need a room).
  WatchTogetherProvider({
    ServerClientLookup? clientFor,
    TitleCopyFinder? findCopies,
    String Function()? displayName,
    String? Function()? profileId,
    String? Function()? customRelayBaseUrl,
    Future<String> Function()? clientName,
    WatchPartyFactory? partyFactory,
    this.shareDurationWait = const Duration(seconds: 30),
  }) : _clientFor = clientFor ?? _noClient,
       _displayName = displayName ?? _defaultName,
       _profileId = profileId ?? _noProfile,
       _customRelayBaseUrl = customRelayBaseUrl ?? _relaySetting,
       _clientName = clientName ?? _plezyClientName,
       _partyFactory = partyFactory ?? _defaultParty,
       _resolver = LibraryResolver(clientFor: clientFor ?? _noClient, findCopies: findCopies ?? _noCopies);

  static MediaServerClient? _noClient(String serverId) => null;
  static String _defaultName() => 'Plezy';
  static String? _noProfile() => null;
  static String? _relaySetting() => SettingsService.instanceOrNull?.read(SettingsService.watchPartyRelayUrl);
  static Future<LibraryLookupResult> _noCopies(TitleQuery query, {AbortController? abort}) async => (
    items: const <MediaItem>[],
    succeededServerIds: const <String>{},
    cancelledServerIds: const <String>{},
    failedServerIds: const <String>{},
    unqueriedServerIds: const <String>{},
  );

  final ServerClientLookup _clientFor;
  final String Function() _displayName;
  final String? Function() _profileId;
  final String? Function() _customRelayBaseUrl;
  final Future<String> Function() _clientName;
  final WatchPartyFactory _partyFactory;

  /// How long a host's share waits for the player's length.
  final Duration shareDurationWait;
  final LibraryResolver _resolver;

  owp.WatchParty<WatchCopy>? _party;
  StreamSubscription<owp.PartyState<WatchCopy>>? _stateSubscription;
  StreamSubscription<owp.PartyEvent>? _eventSubscription;
  owp.PartyState<WatchCopy> _state = const owp.PartyState.initial();
  final _notices = StreamController<WatchNotice>.broadcast();

  ({owp.Relays relays, String? base})? _relays;

  /// The player that has a file open, whether or not the room follows it.
  ({PlezyPlayerAdapter adapter, bool shareable})? _player;
  bool _attached = false;

  /// Why the user is away from the player (the app in the background, a car
  /// that forbids video): the room stops waiting for them meanwhile.
  final Set<_Away> _away = {};
  bool get _isAway => _away.isNotEmpty;
  bool _playBlocked = false;
  bool _disposed = false;
  bool _notifyScheduled = false;
  String? _openedKey;
  int _shareGeneration = 0;

  WatchPlayerHooks? _playerHooks;
  Object? _playerHooksOwner;

  /// Opens the room's file when no player is open; set by the main screen.
  ChoiceOpener? navigatorOpener;

  static Future<String> _plezyClientName() async {
    final info = await PackageInfo.fromPlatform();
    return 'Plezy/${info.version}';
  }

  static owp.WatchParty<WatchCopy> _defaultParty({
    required owp.Relays relays,
    required String client,
    required String name,
    required owp.Resolver<WatchCopy>? resolver,
  }) => owp.WatchParty<WatchCopy>(relays: relays, client: client, name: name, resolver: resolver);

  // ---------------------------------------------------------------------------
  // State

  owp.PartyState<WatchCopy> get state => _state;
  owp.Connection get connection => _state.connection;

  /// In a room, or joining one.
  bool get isInSession =>
      connection == owp.Connection.connecting ||
      connection == owp.Connection.connected ||
      connection == owp.Connection.reconnecting;
  bool get isConnected => connection == owp.Connection.connected;
  bool get isReconnecting => connection == owp.Connection.reconnecting;
  owp.Room? get room => isInSession ? _state.room : null;
  String? get roomCode => room?.code;
  String? get formattedRoomCode => roomCode == null ? null : owp.formatCode(roomCode!);
  List<owp.Participant> get participants => room?.participants ?? const [];
  int get participantCount => participants.length;
  String? get myPeerId => _state.peerId;
  bool get isHost => isInSession && _state.isHost;
  bool get canControl => isInSession && _state.canControl;
  owp.Control get control => room?.control ?? owp.Control.host;
  bool get isLocked => room?.locked ?? false;
  owp.Media? get media => isInSession ? _state.media : null;
  bool get hasMedia => media != null;

  /// The room's file is open in this user's player and the room drives it.
  bool get isFollowing {
    final player = _player;
    return player != null && follows(player.adapter);
  }

  /// The room drives [adapter]: it is the attached player and has the room's
  /// file open.
  bool follows(PlezyPlayerAdapter adapter) {
    final choice = _state.choice;
    final match = _state.match?.state;
    return isConnected &&
        _attached &&
        identical(_player?.adapter, adapter) &&
        choice != null &&
        choice.ref == adapter.copy &&
        (match == owp.MatchState.matched || match == owp.MatchState.mismatched);
  }

  /// The room's file this user would open: their match, or the media they
  /// shared themselves (id `""`). Null while searching or without a copy.
  owp.Candidate<WatchCopy>? get roomCopy => isInSession ? _state.choice : null;

  /// The room plays a file this user has but isn't watching: offer to join.
  bool get canJoinPlayback {
    final copy = roomCopy;
    return isConnected && copy != null && media != null && (_player == null || _player!.adapter.copy != copy.ref);
  }

  /// The player refused to start; the user has to press play on it.
  bool get playBlocked => _playBlocked;

  /// Events for snackbars and toasts.
  Stream<WatchNotice> get notices => _notices.stream;

  /// The participant who is host.
  owp.Participant? get host => participants.where((p) => p.host).firstOrNull;

  // ---------------------------------------------------------------------------
  // Rooms

  owp.Relays _currentRelays() {
    final base = _customRelayBaseUrl();
    final cached = _relays;
    if (cached != null && cached.base == base) return cached.relays;
    final relays = relaysFor(base);
    _relays = (relays: relays, base: base);
    return relays;
  }

  /// The relay setting's scope, for recent rooms.
  String get relayScope => relayScopeOf(_customRelayBaseUrl());

  /// The self-hosted relay's base URL rooms use; null for the public relays.
  String? get customRelayBaseUrl => _customRelayBaseUrl();

  /// The profile whose recent rooms this provider remembers.
  String? get profileId => _profileId();

  Future<owp.WatchParty<WatchCopy>> _newParty() async {
    await _closeParty();
    final name = _sanitizedName(_displayName());
    final party = _partyFactory(relays: _currentRelays(), client: await _clientName(), name: name, resolver: _resolver);
    _party = party;
    _openedKey = null;
    _playBlocked = false;
    _stateSubscription = party.states.listen(_onState);
    _eventSubscription = party.events.listen(_onEvent);
    final player = _player;
    if (player != null && !_isAway) {
      party.attachPlayer(player.adapter, player.adapter.copy);
      _attached = true;
    }
    return party;
  }

  /// Creates a room and joins it as host; returns its code. Throws
  /// [owp.PartyException] with the SDK's code when it fails.
  Future<String> createRoom() async {
    final party = await _newParty();
    final code = await party.create();
    await _rememberRoom(code);
    final player = _player;
    if (player != null && player.shareable) {
      unawaited(shareCopy(player.adapter, positionMs: player.adapter.positionMs));
    }
    return code;
  }

  /// Joins the room with [code] as typed or pasted. Throws
  /// [owp.PartyException] with the SDK's code when it fails.
  Future<void> joinRoom(String code) async {
    final normalized = normalizeRoomCode(code);
    if (normalized == null) throw const owp.PartyException(owp.ErrorCode.invalidCode, 'not a room code');
    final party = await _newParty();
    await party.join(normalized);
    await _rememberRoom(normalized);
  }

  Future<void> _rememberRoom(String code) async {
    final profileId = _profileId();
    if (profileId == null) return;
    try {
      await RecentRoomsService.addOrUpdateRoom(code, profileId: profileId, relayScope: relayScope);
    } catch (error, stackTrace) {
      appLogger.w('WatchTogether: could not remember room', error: error, stackTrace: stackTrace);
    }
  }

  /// Leaves the room, or cancels a create or join under way.
  void leave() => _party?.leave();

  /// Host: ends the room for everyone.
  void endRoom() => _guard(() => _party?.end());

  void setControl(owp.Control mode) => _guard(() => _party?.setControl(mode));
  void transferHost(String peerId) => _guard(() => _party?.transferHost(peerId));
  void kick(String peerId) => _guard(() => _party?.kick(peerId));
  void setLocked(bool locked) => _guard(() => _party?.lock(locked));

  /// Host: stops the media for everyone.
  void stopMedia() => _guard(() => _party?.clearMedia());

  void _guard(void Function() command) {
    try {
      command();
    } on owp.PartyException catch (error) {
      appLogger.d('WatchTogether: ${error.code}: ${error.message}');
      _notify(RefusedNotice(error.code));
    }
  }

  // ---------------------------------------------------------------------------
  // Matching

  void acceptMismatch() => _guard(() => _party?.acceptMismatch());
  void declineMismatch() => _guard(() => _party?.declineMismatch());

  /// Searches the libraries again for the room's media.
  void searchAgain() => _guard(() => _party?.resolveAgain());

  /// Plays [candidate] for the room's media. False when it can't (no length,
  /// the media changed meanwhile).
  Future<bool> choose(owp.Candidate<WatchCopy> candidate) async {
    final party = _party;
    if (party == null) return false;
    try {
      return await party.choose(candidate);
    } on owp.PartyException catch (error) {
      _notify(RefusedNotice(error.code));
      return false;
    }
  }

  /// Plays [version] of [item], found anywhere in the app, for the room's media.
  Future<bool> chooseCopy(MediaItem item, MediaVersion? version) {
    if (item.serverId == null) return Future.value(false);
    return choose(candidateFor(item, version, clientFor: _clientFor));
  }

  /// Shifts this user's file against the room: local = room + [offsetMs].
  void setOffset(int offsetMs) => _guard(() => _party?.setOffset(offsetMs.clamp(-maxRoomOffsetMs, maxRoomOffsetMs)));

  // ---------------------------------------------------------------------------
  // Playback presses. Each returns true when the room took it: the screen must
  // then leave the player alone, since the party commands it.

  bool _routes() => isFollowing && _party != null;

  bool _refuseWithoutControl() {
    if (canControl) return false;
    _notify(const ControlRefusedNotice());
    return true;
  }

  /// False while the player refused to start in a playing room: the user's
  /// press then starts the player itself (SDK.md §15).
  bool play() {
    if (!_routes()) return false;
    if (_playBlocked && room?.phase == owp.Phase.playing) {
      _playBlocked = false;
      notifyListeners();
      return false;
    }
    if (_refuseWithoutControl()) return true;
    _guard(() => _party!.play());
    return true;
  }

  /// Starts the player that refused to start in a playing room, from the
  /// player's own prompt (SDK.md §15). Refused again, it stays blocked.
  Future<void> playBlockedPlayer() async {
    final adapter = _player?.adapter;
    if (!_playBlocked || adapter == null || !follows(adapter)) return;
    _playBlocked = false;
    notifyListeners();
    try {
      await adapter.commands.play();
    } catch (error) {
      appLogger.d('WatchTogether: the player refused to start again: $error');
      if (_disposed || !follows(adapter)) return;
      _notify(_blocked());
    }
  }

  bool pause() {
    if (!_routes()) return false;
    if (_refuseWithoutControl()) return true;
    _guard(() => _party!.pause());
    return true;
  }

  /// [position] is in this user's own file.
  bool seek(Duration position) {
    if (!_routes()) return false;
    if (_refuseWithoutControl()) return true;
    _guard(() => _party!.seek(position.inMilliseconds < 0 ? 0 : position.inMilliseconds));
    return true;
  }

  bool setRate(double rate) {
    if (!_routes()) return false;
    if (_refuseWithoutControl()) return true;
    _guard(() => _party!.setRate(rate.clamp(minRoomRate, maxRoomRate)));
    return true;
  }

  /// The room sets this player's rate, so its rate changes are not the user's.
  bool get syncOwnsRate => isFollowing;

  /// The room's playback rate: the speed the user chose for everyone, as
  /// opposed to the player's momentary drift-correcting rate.
  double? get roomRate => room?.rate;

  // ---------------------------------------------------------------------------
  // The player

  /// The screen registered as the player, for tests.
  @visibleForTesting
  Object? get debugPlayerOwner => _playerHooksOwner;

  /// An open player screen registers how the room switches it to another file
  /// and closes it. Replaces any earlier registration.
  void registerPlayer(Object owner, WatchPlayerHooks hooks) {
    _playerHooksOwner = owner;
    _playerHooks = hooks;
  }

  void unregisterPlayer(Object owner) {
    if (!identical(_playerHooksOwner, owner)) return;
    _playerHooksOwner = null;
    _playerHooks = null;
  }

  /// The player opened [adapter]'s file. [shareable] is false for files the
  /// room can't get (downloads, Live TV). [roomLaunch] is true when the room
  /// asked for this file.
  ///
  /// A host shares the file with the room. A guest's player follows the room
  /// when it opened the room's file, and else sits out so the room doesn't
  /// wait for it.
  void playerOpened(PlezyPlayerAdapter adapter, {required bool shareable, required bool roomLaunch}) {
    final previous = _player?.adapter;
    if (previous != null && !identical(previous, adapter)) previous.release();
    _player = (adapter: adapter, shareable: shareable);
    final party = _party;
    if (party == null || _isAway) return;
    final copy = adapter.copy;
    if (!isConnected) {
      party.attachPlayer(adapter, copy);
      _attached = true;
      return;
    }
    if (isHost) {
      if (!shareable) {
        // The room keeps its media; this file plays on its own meanwhile.
        _attached = false;
        unawaited(party.detachPlayer());
        _notify(const NotSharedNotice());
      } else {
        party.attachPlayer(adapter, copy);
        _attached = true;
        if (!(_state.choice?.ref == copy && _state.choice?.id == '')) {
          unawaited(shareCopy(adapter, positionMs: adapter.positionMs));
        }
      }
      notifyListeners();
      return;
    }
    if (_state.choice?.ref == copy) {
      party.attachPlayer(adapter, copy);
      _attached = true;
    } else if (roomLaunch && media != null && copy.item != null) {
      party.attachPlayer(adapter, copy);
      _attached = true;
      unawaited(chooseCopy(copy.item!, copy.version));
    } else {
      _attached = false;
      unawaited(party.detachPlayer());
    }
    notifyListeners();
  }

  /// The player is going away. A host's media stops for everyone unless
  /// [continuing] (another player takes over, such as the next episode).
  /// Completes once the party no longer commands [adapter]: dispose of the
  /// player after it.
  Future<void> playerClosed(PlezyPlayerAdapter adapter, {required bool continuing}) {
    adapter.release();
    if (!identical(_player?.adapter, adapter)) return Future.value();
    _player = null;
    _attached = false;
    _playBlocked = false;
    final party = _party;
    if (party == null) return Future.value();
    if (!continuing && isConnected && isHost && _state.choice?.ref == adapter.copy && _state.choice?.id == '') {
      _guard(party.clearMedia);
    }
    final released = party.detachPlayer(adapter);
    notifyListeners();
    return released;
  }

  /// The app went to the background (or came back): the room stops waiting
  /// for this user meanwhile, and catches the player up on return.
  void setBackgrounded(bool backgrounded) => _setAway(_Away.background, backgrounded);

  /// The car forbids video while driving (or allows it again), as
  /// [setBackgrounded].
  void setVehicleRestricted(bool restricted) => _setAway(_Away.vehicle, restricted);

  void _setAway(_Away reason, bool away) {
    final wasAway = _isAway;
    if (away) {
      _away.add(reason);
    } else {
      _away.remove(reason);
    }
    if (wasAway == _isAway) return;
    final party = _party;
    final player = _player;
    if (party == null) return;
    if (_isAway) {
      if (player != null) unawaited(party.detachPlayer(player.adapter));
      _attached = false;
      notifyListeners();
    } else if (player != null) {
      playerOpened(player.adapter, shareable: player.shareable, roomLaunch: false);
    }
  }

  /// The player's state changed: the party reads it now.
  void playerChanged(PlezyPlayerAdapter adapter) {
    if (_attached && identical(_player?.adapter, adapter)) _party?.playerChanged();
  }

  /// Host: shares the file [adapter] has open with the room, starting at
  /// [positionMs]. Waits up to 30 s for the player's length when the server
  /// has none. When the room can't get it, the room's media stops and the
  /// host is told.
  Future<bool> shareCopy(PlezyPlayerAdapter adapter, {int positionMs = 0}) async {
    final party = _party;
    final copy = adapter.copy;
    if (party == null || !isHost || copy.item == null) return false;
    final generation = ++_shareGeneration;
    bool current() =>
        !_disposed && identical(_party, party) && generation == _shareGeneration && isHost && !adapter.isReleased;
    final client = _clientFor(copy.serverId);
    if (client == null) return _shareFailed(party, current);
    var result = await describeCopy(copy, client: client, playerDurationMs: adapter.durationMs);
    if (result.failure == DescribeFailure.noDuration) {
      final waited = clock.stopwatch()..start();
      while (current() && adapter.durationMs == null && waited.elapsed < shareDurationWait) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!current()) return false;
      result = await describeCopy(copy, client: client, playerDurationMs: adapter.durationMs);
    }
    if (!current()) return false;
    final media = result.media;
    if (media == null) return _shareFailed(party, current);
    try {
      party.setMedia(media, copy, positionMs: positionMs < 0 ? 0 : positionMs);
      return true;
    } on owp.PartyException catch (error) {
      appLogger.w('WatchTogether: setMedia refused: ${error.code} ${error.message}');
      return _shareFailed(party, current);
    }
  }

  bool _shareFailed(owp.WatchParty<WatchCopy> party, bool Function() current) {
    if (!current()) return false;
    _notify(const ShareFailedNotice());
    if (_state.media != null) _guard(party.clearMedia);
    return false;
  }

  /// Opens the room's file for this user, from the Watch Together screen's
  /// "join playback" card.
  Future<bool> openRoomCopy() {
    final copy = roomCopy;
    if (copy == null) return Future.value(false);
    _openedKey = _keyFor(copy);
    return _open(copy.ref);
  }

  // ---------------------------------------------------------------------------
  // SDK streams

  String _keyFor(owp.Candidate<WatchCopy> choice) => '${_state.room?.epoch}|${choice.ref}';

  void _onState(owp.PartyState<WatchCopy> next) {
    final previous = _state;
    final wasFollowing = isFollowing;
    _state = next;
    if (next.connection == owp.Connection.ended || next.room?.phase != owp.Phase.playing) _playBlocked = false;
    // The room stopped the media this guest was watching with it.
    if (wasFollowing &&
        previous.media != null &&
        next.media == null &&
        next.connection == owp.Connection.connected &&
        !next.isHost) {
      _playerHooks?.exitPlayer();
    }
    _openChoice();
    notifyListeners();
  }

  /// SDK.md §16.7: opens a new choice once per epoch and file. The party's
  /// own media (id `""`) is never reopened on its own: the host is offered it.
  void _openChoice() {
    final choice = _state.choice;
    if (choice == null || choice.id.isEmpty || _isAway || !isConnected) return;
    if (_player?.adapter.copy == choice.ref) return;
    final key = _keyFor(choice);
    if (key == _openedKey) return;
    _openedKey = key;
    unawaited(_open(choice.ref));
  }

  Future<bool> _open(WatchCopy copy) async {
    final opener = _playerHooks?.openInPlace ?? navigatorOpener;
    var opening = false;
    try {
      opening = opener != null && await opener(copy);
    } catch (error, stackTrace) {
      appLogger.w('WatchTogether: could not open $copy', error: error, stackTrace: stackTrace);
    }
    if (!opening && !_disposed && _player == null && isConnected) {
      _notify(const OpenFailedNotice());
      unawaited(_party?.detachPlayer());
    }
    return opening;
  }

  void _onEvent(owp.PartyEvent event) {
    final notice = switch (event) {
      owp.ActionEvent(:final kind, :final by, :final byMe, :final room) when !byMe => ActionNotice(
        kind: kind,
        name: by?.name,
        positionMs: kind == 'seek' ? room.positionMs + _state.offsetMs : null,
        rate: kind == 'rate' ? room.rate : null,
      ),
      owp.ParticipantJoinedEvent(:final participant) => JoinedNotice(participant.name),
      owp.ParticipantLeftEvent(:final participant) => LeftNotice(participant.name),
      owp.ErrorEvent(:final error) => RefusedNotice(error.code),
      owp.ResolveFailedEvent(:final error) => _resolveFailed(error),
      owp.PlayBlockedEvent() => _blocked(),
      owp.EndedEvent(:final reason) => _ended(reason),
      _ => null,
    };
    if (notice != null) _notify(notice);
  }

  WatchNotice _resolveFailed(Object error) {
    appLogger.w('WatchTogether: library search failed: $error');
    return const SearchFailedNotice();
  }

  WatchNotice _blocked() {
    _playBlocked = true;
    notifyListeners();
    return const PlayBlockedNotice();
  }

  WatchNotice? _ended(owp.EndReason reason) {
    _attached = false;
    final party = _party;
    // A player that keeps its file open is the next party's to attach.
    if (party != null) {
      scheduleMicrotask(() {
        if (identical(_party, party) && party.state.connection == owp.Connection.ended) unawaited(_closeParty());
      });
    }
    return reason == owp.EndReason.left ? null : EndedNotice(reason);
  }

  void _notify(WatchNotice notice) {
    if (!_disposed) _notices.add(notice);
  }

  Future<void> _closeParty() async {
    final party = _party;
    if (party == null) return;
    _party = null;
    _attached = false;
    // Cancelling stops the callbacks at once; the party closes now rather than
    // after the cancels' futures, which may only complete on a later turn.
    unawaited(_stateSubscription?.cancel());
    unawaited(_eventSubscription?.cancel());
    _stateSubscription = null;
    _eventSubscription = null;
    // The last state stays readable (the end reason) until the next party.
    _state = party.state;
    await party.close();
    notifyListeners();
  }

  /// Batches the notifications of one turn (a room snapshot often changes
  /// several things at once) into one rebuild, and keeps a player screen's
  /// dispose, which reports its release here, from rebuilding a locked tree.
  @override
  void notifyListeners() {
    if (_disposed || _notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (!_disposed) super.notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _player?.adapter.release();
    _player = null;
    unawaited(_closeParty());
    unawaited(_notices.close());
    super.dispose();
  }
}

/// [name] as an Open Watch Party display name: 1 to 32 code points of
/// protocol text; "Plezy" when nothing is left.
String _sanitizedName(String name) {
  final text = descriptorText(name);
  if (text == null) return 'Plezy';
  final kept = String.fromCharCodes(text.runes.take(32)).trim();
  return kept.isEmpty ? 'Plezy' : kept;
}

enum _Away { background, vehicle }
