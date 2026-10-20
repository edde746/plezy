import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/title_copies.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/models/watch_notice.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/services/library_resolver.dart';
import 'package:plezy/watch_together/services/player_adapter.dart';
import 'package:plezy/watch_together/services/recent_rooms_service.dart';
import 'package:plezy/watch_together/services/watch_party_relays.dart';

import '../test_helpers/fake_owp_relay.dart';
import '../test_helpers/library_lookup.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/watch_together_fakes.dart';

/// One server of a user, answering the descriptor's ID lookups.
class _Server implements MediaServerClient {
  _Server(String id, {this.ids = const {}}) : serverId = ServerId(id);

  @override
  final ServerId serverId;
  final Map<String, ExternalIds> ids;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => ids[itemId] ?? const ExternalIds();

  @override
  Future<MediaItem?> fetchItem(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _alienMs = 7020000;

MediaItem _alien(String id, String serverId, {int? durationMs = _alienMs, String version = 'hd'}) => testMediaItem(
  id: id,
  title: 'Alien',
  year: 1979,
  serverId: serverId,
  durationMs: durationMs,
  mediaVersions: [
    MediaVersion(
      id: version,
      parts: [MediaPart(id: '$version-p', durationMs: durationMs, sizeBytes: 4000000, file: '/m/Alien.mkv')],
    ),
  ],
);

WatchCopy _copyOf(MediaItem item) => WatchCopy.of(item, item.mediaVersions?.first);

final _hostServer = _Server('host-nas', ids: {'alien': const ExternalIds(imdb: 'tt0078748', tmdb: 348)});
final _hostAlien = _alien('alien', 'host-nas');
final _guestAlien = _alien('g-alien', 'guest-nas', durationMs: _alienMs + 800, version: 'g-hd');

typedef _OpenPlayer = ({PlezyPlayerAdapter adapter, FakeSyncPlayer player});

/// A player with [copy] open, as the player screen hands it to the provider.
/// [refusePlay] makes its play command throw, as a car or a browser refusing
/// to start playback would.
_OpenPlayer _openPlayer(WatchCopy copy, {Duration? duration, bool Function()? refusePlay}) {
  final player = FakeSyncPlayer(
    hasRenderedFrame: true,
    duration: duration ?? Duration(milliseconds: copy.durationMs ?? 0),
  );
  final adapter = PlezyPlayerAdapter(
    player: player,
    copy: copy,
    commands: PlayerCommands(
      play: () => refusePlay?.call() ?? false ? Future.error(StateError('playback refused')) : player.play(),
      pause: player.pause,
      seek: player.seek,
      setRate: player.setRate,
    ),
  );
  return (adapter: adapter, player: player);
}

/// A provider and every notice it gave.
final class _Member {
  _Member(this.provider) {
    _subscription = provider.notices.listen(notices.add);
  }

  final WatchTogetherProvider provider;
  final List<WatchNotice> notices = [];
  late final StreamSubscription<WatchNotice> _subscription;

  String get peerId => provider.myPeerId!;

  owp.Participant participant(String peerId) => provider.participants.firstWhere((p) => p.peerId == peerId);

  Iterable<T> noticesOf<T extends WatchNotice>() => notices.whereType<T>();

  /// Not awaiting the cancel: a broadcast subscription's cancel future
  /// belongs to the root zone, which widget-test time never runs.
  void dispose() {
    provider.dispose();
    unawaited(_subscription.cancel());
  }
}

/// The player screen the app opens for the room: it opens the room's file
/// when asked, registers its hooks and reports the player.
final class _Screen {
  _Screen(this.member);

  final _Member member;
  final List<_OpenPlayer> players = [];
  int exits = 0;
  bool refusePlay = false;

  WatchTogetherProvider get _provider => member.provider;

  /// Opens the files the room asks for from now on.
  void listen() => _provider.navigatorOpener = open;

  Future<bool> open(WatchCopy copy) async {
    // A route push: the player reports back after the room's update.
    await Future<void>.delayed(Duration.zero);
    final opened = _openPlayer(copy, refusePlay: () => refusePlay);
    players.add(opened);
    _provider.registerPlayer(this, WatchPlayerHooks(openInPlace: open, exitPlayer: () => exits++));
    _provider.playerOpened(opened.adapter, shareable: true, roomLaunch: true);
    return true;
  }
}

typedef _Following = ({_Member host, _Member guest, _OpenPlayer hostPlayer, _Screen screen});

/// Participants on one relay, the host with Alien on `host-nas`, guests with
/// their own copy on `guest-nas`, and the time the test runs in.
abstract base class _World {
  final List<_Member> _members = [];
  final List<TitleQuery> guestQueries = [];
  Future<LibraryLookupResult> Function(TitleQuery query) guestAnswer = (_) async =>
      libraryLookupResult([_guestAlien], succeeded: {'guest-nas'});

  WatchTogetherProvider newProvider({
    required String name,
    required String? profileId,
    required ServerClientLookup? clientFor,
    required TitleCopyFinder? findCopies,
    required Duration shareDurationWait,
  });

  Future<void> wait(Duration duration);

  Future<void> until(bool Function() check, String what) async {
    for (var i = 0; i < 500; i++) {
      if (check()) return;
      await wait(const Duration(milliseconds: 20));
    }
    fail('timed out waiting until $what');
  }

  /// [future], with time running until it completes.
  Future<T> settle<T>(Future<T> future) async {
    var done = false;
    unawaited(future.then<void>((_) => done = true, onError: (Object _) => done = true));
    await until(() => done, 'the call completed');
    return future;
  }

  /// The `code` of the [owp.PartyException] [future] fails with, time running
  /// until it does; null when it completes. (`expectLater` can't wait here: in
  /// a widget test it holds the tester while time has to run.)
  Future<String?> refusal(Future<void> future) async {
    try {
      await settle(future);
      return null;
    } on owp.PartyException catch (error) {
      return error.code;
    }
  }

  Future<void> noticed<T extends WatchNotice>(_Member member, String what, [bool Function(T notice)? test]) =>
      until(() => member.noticesOf<T>().any(test ?? (_) => true), what);

  _Member member(
    String name, {
    String? profileId,
    ServerClientLookup? clientFor,
    TitleCopyFinder? findCopies,
    Duration shareDurationWait = const Duration(seconds: 30),
  }) {
    final member = _Member(
      newProvider(
        name: name,
        profileId: profileId,
        clientFor: clientFor,
        findCopies: findCopies,
        shareDurationWait: shareDurationWait,
      ),
    );
    _members.add(member);
    return member;
  }

  _Member host({String? profileId, Duration shareDurationWait = const Duration(seconds: 30)}) => member(
    'Host',
    profileId: profileId,
    clientFor: (serverId) => serverId == 'host-nas' ? _hostServer : null,
    shareDurationWait: shareDurationWait,
  );

  _Member guest([String name = 'Guest', String? profileId]) => member(
    name,
    profileId: profileId,
    findCopies: (query, {abort}) {
      guestQueries.add(query);
      return guestAnswer(query);
    },
  );

  Future<void> together(_Member host, List<_Member> guests) async {
    final code = await settle(host.provider.createRoom());
    for (final guest in guests) {
      await settle(guest.provider.joinRoom(code));
    }
    final everyone = [host, ...guests];
    await until(
      () => everyone.every((m) => m.provider.participantCount == everyone.length),
      'everyone sees ${everyone.length} participants',
    );
  }

  /// The host opens [item]; completes once the room plays it.
  Future<_OpenPlayer> hostPlays(_Member host, MediaItem item) async {
    final opened = _openPlayer(_copyOf(item));
    host.provider.playerOpened(opened.adapter, shareable: true, roomLaunch: false);
    await until(() => host.provider.roomCopy?.ref == opened.adapter.copy, 'the room plays the host file');
    return opened;
  }

  /// A room whose host plays Alien and whose guest follows it with its own copy.
  Future<_Following> following() async {
    final h = host();
    final g = guest();
    final screen = _Screen(g)..listen();
    await together(h, [g]);
    final hostPlayer = await hostPlays(h, _hostAlien);
    await until(() => g.provider.isFollowing, 'the guest follows the room');
    return (host: h, guest: g, hostPlayer: hostPlayer, screen: screen);
  }

  /// Disposes of every provider and lets their parties close.
  Future<void> close() async {
    for (final member in _members) {
      member.dispose();
    }
    await wait(const Duration(milliseconds: 300));
  }
}

/// [FakeOwpRelay] in widget-test time.
final class _FakeWorld extends _World {
  _FakeWorld(this.tester);

  final WidgetTester tester;
  final relay = FakeOwpRelay();

  @override
  WatchTogetherProvider newProvider({
    required String name,
    required String? profileId,
    required ServerClientLookup? clientFor,
    required TitleCopyFinder? findCopies,
    required Duration shareDurationWait,
  }) => WatchTogetherProvider(
    partyFactory: relay.party,
    clientName: () async => 'Plezy/9.9.9',
    displayName: () => name,
    profileId: () => profileId,
    clientFor: clientFor,
    findCopies: findCopies,
    shareDurationWait: shareDurationWait,
  );

  @override
  Future<void> wait(Duration duration) => tester.pump(duration);
}

void _roomTest(String description, Future<void> Function(_FakeWorld world) body) {
  testWidgets(description, (tester) async {
    final world = _FakeWorld(tester);
    try {
      await body(world);
    } finally {
      await world.close();
    }
  });
}

Matcher _action(String kind, {String? name, int? positionMs, double? rate}) => isA<ActionNotice>()
    .having((n) => n.kind, 'kind', kind)
    .having((n) => n.name, 'name', name)
    .having((n) => n.positionMs, 'positionMs', positionMs)
    .having((n) => n.rate, 'rate', rate);

Matcher _partyError(String code) => throwsA(isA<owp.PartyException>().having((e) => e.code, 'code', code));

void main() {
  group('outside a room', () {
    setUp(SettingsService.resetForTesting);

    test('works without arguments: no room, presses left to the player, the public relays', () async {
      final provider = WatchTogetherProvider();
      addTearDown(provider.dispose);

      expect(provider.isInSession, isFalse);
      expect(provider.room, isNull);
      expect(provider.participants, isEmpty);
      expect(provider.control, owp.Control.host);
      expect(provider.hasMedia, isFalse);
      expect(provider.relayScope, relayScopeOf(null));
      expect(provider.customRelayBaseUrl, isNull);
      expect(provider.play(), isFalse);
      expect(provider.pause(), isFalse);
      expect(provider.seek(const Duration(seconds: 5)), isFalse);
      expect(provider.setRate(1.5), isFalse);
      provider.leave();

      await expectLater(provider.joinRoom('K7M-Q2'), _partyError(owp.ErrorCode.invalidCode));
      expect(provider.isInSession, isFalse);
    });

    test('a player opened outside a room is only remembered; another one releases it', () async {
      final provider = WatchTogetherProvider();
      addTearDown(provider.dispose);
      final first = _openPlayer(_copyOf(_alien('alien', 'nas')));
      final second = _openPlayer(_copyOf(_alien('alien-2', 'nas')));

      provider.playerOpened(first.adapter, shareable: true, roomLaunch: false);
      expect(provider.isFollowing, isFalse);
      expect(await provider.shareCopy(first.adapter), isFalse);
      expect(first.adapter.isReleased, isFalse);

      provider.playerOpened(second.adapter, shareable: true, roomLaunch: false);
      expect(first.adapter.isReleased, isTrue);

      await provider.playerClosed(second.adapter, continuing: false);
      expect(second.adapter.isReleased, isTrue);
      expect(first.player.commandLog, isEmpty);
    });
  });

  group('in a room', () {
    setUp(() async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      await SettingsService.getInstance();
    });

    _roomTest('create and join: the code, participants with their names and clients, a join notice', (world) async {
      final h = world.host(profileId: 'profile-host');
      final g = world.guest(' \u200FGuest\tOne\n', 'profile-guest');

      final code = await world.settle(h.provider.createRoom());
      expect(code, FakeOwpRelay.code);
      expect((h.provider.roomCode, h.provider.formattedRoomCode), (code, 'K7M-Q2X'));
      expect((h.provider.isConnected, h.provider.isInSession, h.provider.isHost), (true, true, true));
      expect(h.provider.relayScope, relayScopeOf(null));

      await world.settle(g.provider.joinRoom('k7m-q2x'));
      await world.until(() => h.provider.participantCount == 2, 'the host sees the guest');

      expect(g.provider.roomCode, code);
      expect((g.provider.isHost, g.provider.canControl, g.provider.control), (false, false, owp.Control.host));
      expect(g.provider.host?.peerId, h.peerId);
      expect(g.peerId, isNot(h.peerId));
      for (final view in [h, g]) {
        expect(
          {for (final p in view.provider.participants) p.peerId: p.name},
          {h.peerId: 'Host', g.peerId: 'Guest One'},
        );
        expect(view.provider.participants.map((p) => p.client).toSet(), {'Plezy/9.9.9'});
      }
      expect(world.relay.sent('join').single['name'], 'Guest One');
      await world.noticed<JoinedNotice>(h, 'the host is told', (n) => n.name == 'Guest One');
      expect(g.noticesOf<JoinedNotice>(), isEmpty);

      for (final profile in ['profile-host', 'profile-guest']) {
        final rooms = RecentRoomsService.getRecentRooms(profileId: profile, relayScope: relayScopeOf(null));
        expect(rooms.map((r) => r.code), [code], reason: profile);
        expect(
          RecentRoomsService.getRecentRooms(profileId: profile, relayScope: relayScopeOf('http://x.test')),
          isEmpty,
        );
      }
    });

    _roomTest('a code without a room is refused, and a display name without text is Plezy', (world) async {
      final h = world.member('\u202E\n');
      await world.settle(h.provider.createRoom());
      final g = world.guest();

      expect(await world.refusal(g.provider.joinRoom('K7M-Q2Y')), owp.ErrorCode.roomNotFound);
      expect(g.provider.isInSession, isFalse);
      expect(h.provider.participants.single.name, 'Plezy');
    });

    _roomTest('host transfer, control mode and lock; a guest is refused host commands', (world) async {
      final h = world.host();
      final g = world.guest();
      await world.together(h, [g]);

      g.provider.setLocked(true);
      g.provider.setControl(owp.Control.everyone);
      g.provider.transferHost(h.peerId);
      g.provider.endRoom();
      await world.wait(Duration.zero);
      expect(g.noticesOf<RefusedNotice>().map((n) => n.code), List.filled(4, owp.ErrorCode.forbidden));

      h.provider.setControl(owp.Control.everyone);
      await world.until(() => g.provider.canControl && g.provider.control == owp.Control.everyone, 'all control');

      h.provider.setLocked(true);
      await world.until(() => g.provider.isLocked, 'the guest sees the lock');
      final latecomer = world.guest('Late');
      expect(await world.refusal(latecomer.provider.joinRoom(h.provider.roomCode!)), owp.ErrorCode.roomLocked);
      h.provider.setLocked(false);
      await world.until(() => !g.provider.isLocked, 'the guest sees the unlock');
      await world.settle(latecomer.provider.joinRoom(h.provider.roomCode!));
      await world.until(() => h.provider.participantCount == 3, 'the latecomer is in');

      h.provider.transferHost(g.peerId);
      await world.until(() => g.provider.isHost && !h.provider.isHost, 'the guest is host');
      expect(h.provider.host?.peerId, g.peerId);
      expect(latecomer.provider.host?.peerId, g.peerId);
      h.provider.kick(latecomer.peerId);
      await world.wait(Duration.zero);
      expect(h.noticesOf<RefusedNotice>().single.code, owp.ErrorCode.forbidden);
    });

    _roomTest('a kicked guest is told; the room goes on without them', (world) async {
      final h = world.host();
      final g = world.guest();
      await world.together(h, [g]);

      h.provider.kick(g.peerId);
      await world.noticed<EndedNotice>(g, 'the guest is told', (n) => n.reason == owp.EndReason.kicked);
      await world.until(() => !g.provider.isInSession, 'the guest is out');
      expect(g.provider.state.endReason, owp.EndReason.kicked);
      expect(g.provider.room, isNull);
      await world.until(() => h.provider.participantCount == 1, 'the host is alone');
      expect(h.provider.isConnected, isTrue);
      expect(h.noticesOf<EndedNotice>(), isEmpty);
    });

    _roomTest('leaving tells the others without an end notice; ending ends it for everyone', (world) async {
      final h = world.host();
      final g = world.guest();
      final other = world.guest('Other');
      await world.together(h, [g, other]);

      g.provider.leave();
      await world.until(() => !g.provider.isInSession, 'the guest is out');
      await world.noticed<LeftNotice>(h, 'the host is told', (n) => n.name == 'Guest');
      await world.until(() => other.provider.participantCount == 2, 'the other guest sees two');
      expect(g.provider.state.endReason, owp.EndReason.left);
      expect(g.noticesOf<EndedNotice>(), isEmpty);
      g.provider.leave();

      h.provider.endRoom();
      await world.noticed<EndedNotice>(other, 'the other guest is told', (n) => n.reason == owp.EndReason.ended);
      await world.until(() => !h.provider.isInSession && !other.provider.isInSession, 'the room is over');
      expect(other.provider.state.endReason, owp.EndReason.ended);
    });

    _roomTest('the host shares its file; a guest finds its own copy, opens it and follows', (world) async {
      final (host: h, guest: g, :hostPlayer, :screen) = await world.following();

      final shared = world.relay.sent('setMedia').single;
      expect(shared['positionMs'], 0);
      final media = h.provider.media!;
      expect((media.kind, media.title, media.year, media.durationMs), (owp.MediaKind.movie, 'Alien', 1979, _alienMs));
      expect(media.ids, {'imdb': 'tt0078748', 'tmdb': '348'});
      expect(media.ext, {
        'app.plezy': {'server': 'host-nas', 'item': 'alien', 'version': 'hd'},
      });
      expect(h.provider.roomCopy?.id, '');
      expect(h.provider.isFollowing, isTrue);
      expect(h.provider.canJoinPlayback, isFalse);

      // The guest searched by the identity the descriptor carried.
      final query = world.guestQueries.single;
      expect((query.kind, query.title, query.year), (MediaKind.movie, 'Alien', 1979));
      expect(query.ids.toJson(), {'imdb': 'tt0078748', 'tmdb': 348});

      expect(g.provider.media, media);
      expect(g.provider.state.match?.state, owp.MatchState.matched);
      expect(g.provider.state.match?.deltaMs, 800);
      expect(screen.players.single.adapter.copy, _copyOf(_guestAlien));
      expect(g.provider.roomCopy?.ref, _copyOf(_guestAlien));
      expect(g.provider.canJoinPlayback, isFalse);
      await world.until(
        () => h.participant(g.peerId).match?.state == owp.MatchState.matched,
        'the host sees the guest matched',
      );
      expect(hostPlayer.adapter.isReleased, isFalse);
    });

    _roomTest('presses go through the room while following; without control they are refused', (world) async {
      final (host: h, guest: g, :hostPlayer, :screen) = await world.following();
      final bystander = world.guest('Bystander');
      await world.settle(bystander.provider.joinRoom(h.provider.roomCode!));
      await world.until(() => h.provider.participantCount == 3, 'the bystander is in');
      await world.until(() => hostPlayer.player.state.playing, 'the shared file plays');

      expect(g.provider.pause(), isTrue, reason: 'the screen leaves its player alone');
      expect(bystander.provider.pause(), isFalse, reason: 'without the room file open the player is the user own');
      await world.wait(const Duration(milliseconds: 100));
      expect(g.notices.last, isA<ControlRefusedNotice>());
      expect(world.relay.sent('pause'), isEmpty);

      h.provider.setControl(owp.Control.everyone);
      await world.until(() => g.provider.canControl, 'the guest controls');

      expect(g.provider.pause(), isTrue);
      await world.noticed<ActionNotice>(h, 'the host sees the pause', (n) => n.kind == 'pause' && n.name == 'Guest');
      await world.until(() => !hostPlayer.player.state.playing, 'the host player pauses');

      expect(g.provider.play(), isTrue);
      await world.noticed<ActionNotice>(h, 'the host sees the play', (n) => n.kind == 'play');
      await world.until(() => hostPlayer.player.state.playing, 'the host player plays');

      expect(g.provider.seek(const Duration(minutes: 10)), isTrue);
      await world.noticed<ActionNotice>(h, 'the host sees the seek', (n) => n.kind == 'seek');
      expect(h.noticesOf<ActionNotice>().last, _action('seek', name: 'Guest', positionMs: 600000));

      expect(g.provider.setRate(3), isTrue);
      await world.noticed<ActionNotice>(h, 'the host sees the rate', (n) => n.kind == 'rate');
      expect(h.noticesOf<ActionNotice>().last, _action('rate', name: 'Guest', rate: maxRoomRate));
      expect(h.provider.room?.rate, maxRoomRate);

      expect(h.provider.seek(const Duration(milliseconds: -5)), isTrue);
      await world.noticed<ActionNotice>(
        g,
        'the guest sees the host seek',
        (n) => n.kind == 'seek' && n.positionMs == 0,
      );
      expect(world.relay.sent('seek').last['positionMs'], 0);
      expect(g.noticesOf<ActionNotice>().where((n) => n.name == 'Guest'), isEmpty, reason: 'not its own');
      expect(g.noticesOf<RefusedNotice>(), isEmpty);
      expect(screen.players.single.player.commandLog, contains('rate:2.0'));
    });

    _roomTest('a player that refuses to start blocks until the user presses play', (world) async {
      final h = world.host();
      final g = world.guest();
      final screen = _Screen(g)
        ..refusePlay = true
        ..listen();
      await world.together(h, [g]);
      await world.hostPlays(h, _hostAlien);

      await world.noticed<PlayBlockedNotice>(g, 'the guest is told to press play');
      expect(g.provider.playBlocked, isTrue);

      await world.settle(g.provider.playBlockedPlayer());
      expect(g.noticesOf<PlayBlockedNotice>(), hasLength(2), reason: 'refused again, it stays blocked');
      expect(g.provider.playBlocked, isTrue);

      expect(g.provider.room?.phase, owp.Phase.playing);
      expect(g.provider.play(), isFalse, reason: 'the press starts the player itself');
      expect(g.provider.playBlocked, isFalse);
      expect(screen.players.single.player.state.playing, isFalse);
    });

    _roomTest('an offset is the guest own: it shifts its file, bounded, and the room sees it', (world) async {
      final (host: h, guest: g, hostPlayer: _, screen: _) = await world.following();

      g.provider.setOffset(1500);
      await world.until(() => g.provider.state.offsetMs == 1500, 'the guest file is shifted');
      await world.until(() => h.participant(g.peerId).offsetMs == 1500, 'the host sees the offset');

      g.provider.setOffset(maxRoomOffsetMs * 2);
      await world.until(() => g.provider.state.offsetMs == maxRoomOffsetMs, 'the offset stops at 7 days');
      g.provider.setOffset(-maxRoomOffsetMs * 2);
      await world.until(() => g.provider.state.offsetMs == -maxRoomOffsetMs, 'and at minus 7 days');
      expect(g.noticesOf<RefusedNotice>(), isEmpty);
      expect(h.provider.state.offsetMs, 0);
    });

    _roomTest('the host closing its player stops the media, and the following guest player closes', (world) async {
      final (host: h, guest: g, :hostPlayer, :screen) = await world.following();

      await world.settle(h.provider.playerClosed(hostPlayer.adapter, continuing: false));
      expect(hostPlayer.adapter.isReleased, isTrue);
      expect(world.relay.sent('clearMedia'), hasLength(1));
      await world.until(() => !g.provider.hasMedia && !h.provider.hasMedia, 'the room has no media');
      expect(screen.exits, 1);
      expect(h.provider.isFollowing, isFalse);
      expect(g.provider.isInSession, isTrue);
    });

    _roomTest('a host player that hands over to the next file keeps the room media', (world) async {
      final (host: h, guest: g, :hostPlayer, :screen) = await world.following();

      await world.settle(h.provider.playerClosed(hostPlayer.adapter, continuing: true));
      final next = await world.hostPlays(h, _alien('alien-2', 'host-nas', version: 'remux'));

      expect(world.relay.sent('clearMedia'), isEmpty);
      expect(world.relay.sent('setMedia'), hasLength(2));
      await world.until(() => world.guestQueries.length == 2, 'the guest searches for the next media');
      await world.until(() => g.provider.isFollowing, 'the guest follows the next media');
      expect(screen.exits, 0);
      expect(next.adapter.isReleased, isFalse);
    });

    _roomTest('the host sharing the same file again keeps the guest player, and the room still seeks it', (
      world,
    ) async {
      final (host: h, guest: g, :hostPlayer, :screen) = await world.following();
      final guestPlayer = screen.players.single;

      expect(await world.settle(h.provider.shareCopy(hostPlayer.adapter)), isTrue);
      expect(world.relay.sent('setMedia'), hasLength(2));
      await world.until(() => world.guestQueries.length == 2, 'the guest searches for the new epoch');
      await world.until(() => g.provider.isFollowing, 'the guest follows again');
      expect(screen.players, hasLength(1), reason: 'the open file is the match again, so nothing reopens');
      expect(screen.exits, 0);
      expect(guestPlayer.adapter.isReleased, isFalse);

      expect(h.provider.seek(const Duration(minutes: 20)), isTrue);
      await world.until(
        () => guestPlayer.player.commandLog.any(
          (command) => command.startsWith('seek:') && int.parse(command.substring(5)) >= 1200000,
        ),
        'the room seeks the guest player',
      );
      expect(g.noticesOf<RefusedNotice>(), isEmpty);
    });

    _roomTest('a search again that fails keeps the file playing and says the search failed', (world) async {
      final (host: _, guest: g, hostPlayer: _, :screen) = await world.following();
      world.guestAnswer = (_) async => libraryLookupResult(const [], failed: {'guest-nas'});

      g.provider.searchAgain();
      await world.noticed<SearchFailedNotice>(g, 'the guest is told');
      expect(g.provider.searchFailed, isTrue);
      expect(g.provider.state.candidates, isEmpty);
      expect(g.provider.isFollowing, isTrue, reason: 'the open file goes on');
      expect(g.provider.roomCopy?.ref, _copyOf(_guestAlien));
      expect(screen.players.single.adapter.isReleased, isFalse);
    });

    _roomTest('a host that hands over keeps its own file as the room copy, not a search', (world) async {
      final (host: h, guest: g, :hostPlayer, screen: _) = await world.following();

      h.provider.transferHost(g.peerId);
      await world.until(() => g.provider.isHost && !h.provider.isHost, 'the guest is host');
      expect(h.provider.state.match?.state, owp.MatchState.matched);
      expect(h.provider.roomCopy?.id, '', reason: 'the media is still this participant own');
      expect(h.provider.roomCopy?.ref, hostPlayer.adapter.copy);
      expect(h.provider.isFollowing, isTrue);
      expect(h.provider.canJoinPlayback, isFalse);

      // Out of the player, the former host is offered its own file again.
      await world.settle(h.provider.playerClosed(hostPlayer.adapter, continuing: false));
      expect(world.relay.sent('clearMedia'), isEmpty, reason: 'a guest leaving its player keeps the room media');
      await world.wait(const Duration(milliseconds: 100));
      expect(h.provider.hasMedia, isTrue);
      expect(h.provider.roomCopy?.id, '');
      expect(h.provider.canJoinPlayback, isTrue);
    });

    _roomTest('a file the room cannot get is not shared, and stops what the room played', (world) async {
      final h = world.host(shareDurationWait: const Duration(milliseconds: 300));
      final g = world.guest();
      await world.together(h, [g]);
      await world.hostPlays(h, _hostAlien);
      await world.until(() => g.provider.hasMedia, 'the guest has the media');

      // A download: the room keeps its media.
      final download = _openPlayer(_copyOf(_alien('alien', 'host-nas', version: 'sd')));
      h.provider.playerOpened(download.adapter, shareable: false, roomLaunch: false);
      await world.wait(Duration.zero);
      expect(h.notices.last, isA<NotSharedNotice>());
      expect(h.provider.isFollowing, isFalse);
      expect(h.provider.canJoinPlayback, isTrue);

      // No length anywhere: the share waits for the player, then gives up.
      final unknown = _openPlayer(
        _copyOf(_alien('home', 'host-nas', durationMs: null, version: 'raw')),
        duration: Duration.zero,
      );
      h.provider.playerOpened(unknown.adapter, shareable: true, roomLaunch: false);
      await world.wait(const Duration(milliseconds: 200));
      expect(h.noticesOf<ShareFailedNotice>(), isEmpty, reason: 'still waiting for the player length');
      await world.noticed<ShareFailedNotice>(h, 'the host is told');
      await world.until(() => !g.provider.hasMedia && !h.provider.hasMedia, 'the room media stops');

      // A server this profile can't describe from.
      final foreign = _openPlayer(_copyOf(_alien('alien', 'usb-drive')));
      h.provider.playerOpened(foreign.adapter, shareable: true, roomLaunch: false);
      await world.until(() => h.noticesOf<ShareFailedNotice>().length == 2, 'the host is told again');
      expect(world.relay.sent('setMedia'), hasLength(1));
      expect(world.relay.sent('clearMedia'), hasLength(1));
      expect(h.noticesOf<RefusedNotice>(), isEmpty);
    });

    _roomTest('a host file without a server length is shared once the player knows it', (world) async {
      final h = world.host();
      await world.settle(h.provider.createRoom());
      final opened = _openPlayer(
        _copyOf(_alien('home', 'host-nas', durationMs: null, version: 'raw')),
        duration: Duration.zero,
      );
      h.provider.playerOpened(opened.adapter, shareable: true, roomLaunch: false);
      await world.wait(const Duration(seconds: 1));
      expect(world.relay.sent('setMedia'), isEmpty);

      opened.player.emitDuration(const Duration(minutes: 90));
      await world.until(() => h.provider.hasMedia, 'the room plays it');
      expect(h.provider.media?.durationMs, 5400000);
    });

    _roomTest('a file the host opened before the room is shared once the room exists', (world) async {
      final h = world.host();
      final opened = _openPlayer(_copyOf(_hostAlien));
      h.provider.playerOpened(opened.adapter, shareable: true, roomLaunch: false);

      await world.settle(h.provider.createRoom());

      await world.until(() => h.provider.isFollowing, 'the room plays the host file');
      expect(h.provider.media?.title, 'Alien');
      expect(h.provider.roomCopy?.ref, opened.adapter.copy);
    });

    _roomTest('a failed search is reported and searched again; without a player the file is offered', (world) async {
      final h = world.host();
      final g = world.guest();
      var failing = true;
      world.guestAnswer = (_) async => failing
          ? libraryLookupResult(const [], failed: {'guest-nas'})
          : libraryLookupResult([_guestAlien], succeeded: {'guest-nas'});
      await world.together(h, [g]);
      await world.hostPlays(h, _hostAlien);

      await world.noticed<SearchFailedNotice>(g, 'the guest is told the search failed');
      await world.until(() => g.provider.state.match?.state == owp.MatchState.unavailable, 'nothing to play');
      expect(g.provider.roomCopy, isNull);
      expect(g.provider.searchFailed, isTrue, reason: 'nothing found is not taken as absence');

      failing = false;
      g.provider.searchAgain();
      expect(g.provider.searchFailed, isFalse);
      await world.until(() => g.provider.state.match?.state == owp.MatchState.matched, 'the copy is found');
      // Nothing can open the file: the guest sits out and is offered to join.
      await world.noticed<OpenFailedNotice>(g, 'the guest is told the file did not open');
      expect(g.provider.canJoinPlayback, isTrue);
      expect(g.provider.isFollowing, isFalse);

      final screen = _Screen(g);
      g.provider.navigatorOpener = screen.open;
      expect(await world.settle(g.provider.openRoomCopy()), isTrue);
      await world.until(() => g.provider.isFollowing, 'the guest follows');
      expect(screen.players.single.adapter.copy, _copyOf(_guestAlien));
      expect(g.provider.canJoinPlayback, isFalse);
    });
  });

  group('on a real relay', skip: _relayBinary == null ? 'OWP_RELAY_BIN is not set' : false, () {
    late _Relay relay;

    setUpAll(() async => relay = await _Relay.start(_relayBinary!));
    tearDownAll(() => relay.stop());

    test('create, join, share, follow, presses, stop and leave', () async {
      // The widget-test binding answers every HttpClient with a 400.
      await HttpOverrides.runWithHttpOverrides(() async {
        final world = _RealWorld(relay.baseUrl);
        try {
          final (host: h, guest: g, :hostPlayer, :screen) = await world.following();
          expect(h.provider.relayScope, relayScopeOf(relay.baseUrl));
          expect(g.provider.roomCode, h.provider.roomCode);
          expect(g.provider.participants.map((p) => p.name).toSet(), {'Host', 'Guest'});
          await world.noticed<JoinedNotice>(h, 'the host is told', (n) => n.name == 'Guest');
          expect(world.guestQueries.single.ids.toJson(), {'imdb': 'tt0078748', 'tmdb': 348});
          expect(g.provider.state.match?.deltaMs, 800);

          expect(g.provider.pause(), isTrue);
          await world.wait(const Duration(milliseconds: 50));
          expect(g.notices.last, isA<ControlRefusedNotice>());
          h.provider.setControl(owp.Control.everyone);
          await world.until(() => g.provider.canControl, 'the guest controls');
          await world.until(() => h.provider.room?.phase == owp.Phase.playing, 'the room plays');
          expect(g.provider.pause(), isTrue);
          await world.noticed<ActionNotice>(h, 'the host sees the pause', (n) => n.kind == 'pause');
          await world.until(() => !hostPlayer.player.state.playing, 'the host player pauses');
          expect(g.provider.seek(const Duration(minutes: 10)), isTrue);
          await world.noticed<ActionNotice>(h, 'the host sees the seek', (n) => n.kind == 'seek');
          expect(h.noticesOf<ActionNotice>().last, _action('seek', name: 'Guest', positionMs: 600000));

          await h.provider.playerClosed(hostPlayer.adapter, continuing: false);
          await world.until(() => !g.provider.hasMedia, 'the room media stops');
          expect(screen.exits, 1);

          g.provider.leave();
          await world.noticed<LeftNotice>(h, 'the host is told', (n) => n.name == 'Guest');
          expect(g.noticesOf<EndedNotice>(), isEmpty);
        } finally {
          await world.close();
        }
      }, _NetworkHttp());
    });
  });
}

/// The `OWP_RELAY_BIN` relay binary (`go build -o <path> ./cmd/owp-relay` in
/// the Open Watch Party repository); without it the real-relay test is
/// skipped. Tests never reach the public relays.
final String? _relayBinary = switch (Platform.environment['OWP_RELAY_BIN']) {
  final path? when path.isNotEmpty => path,
  _ => null,
};

/// The default [HttpClient], for the real relay's WebSockets.
final class _NetworkHttp extends HttpOverrides {}

/// Providers on [_Relay] in real time.
final class _RealWorld extends _World {
  _RealWorld(this.baseUrl);

  final String baseUrl;

  @override
  WatchTogetherProvider newProvider({
    required String name,
    required String? profileId,
    required ServerClientLookup? clientFor,
    required TitleCopyFinder? findCopies,
    required Duration shareDurationWait,
  }) => WatchTogetherProvider(
    clientName: () async => 'Plezy/9.9.9',
    displayName: () => name,
    customRelayBaseUrl: () => baseUrl,
    profileId: () => profileId,
    clientFor: clientFor,
    findCopies: findCopies,
    shareDurationWait: shareDurationWait,
  );

  @override
  Future<void> wait(Duration duration) => Future<void>.delayed(duration);
}

/// An `owp-relay` on 127.0.0.1, on a free port of this file's range
/// (19030-19069), with its per-IP limits raised: every participant of the
/// test connects from the same address.
final class _Relay {
  _Relay._(this.port, this._process);

  static const _firstPort = 19030;
  static const _lastPort = 19069;

  final int port;
  final Process _process;

  String get baseUrl => 'http://127.0.0.1:$port';

  static Future<_Relay> start(String binary) async {
    for (var port = _firstPort; port <= _lastPort; port++) {
      try {
        await (await ServerSocket.bind(InternetAddress.loopbackIPv4, port)).close();
      } on SocketException {
        continue;
      }
      return _launch(binary, port);
    }
    throw StateError('no free port in $_firstPort-$_lastPort');
  }

  static Future<_Relay> _launch(String binary, int port) async {
    final process = await Process.start(binary, [
      '--addr', '127.0.0.1:$port', //
      '--admin-addr', '',
      '--max-connections-per-ip', '100',
      '--max-rooms-per-ip', '100',
      '--join-burst', '1000',
      '--joins-per-second', '1000',
      '--message-burst', '1000',
      '--messages-per-second', '1000',
    ]);
    final log = StringBuffer();
    process.stdout.transform(utf8.decoder).listen(log.write);
    process.stderr.transform(utf8.decoder).listen(log.write);
    final relay = _Relay._(port, process);
    final waited = Stopwatch()..start();
    while (true) {
      try {
        (await Socket.connect(InternetAddress.loopbackIPv4, port)).destroy();
        return relay;
      } on SocketException {
        if (waited.elapsed > const Duration(seconds: 10)) {
          await relay.stop();
          throw StateError('owp-relay did not listen on $port:\n$log');
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> stop() async {
    _process.kill();
    await _process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return _process.exitCode;
      },
    );
  }
}
