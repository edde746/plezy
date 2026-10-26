import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_library_controller.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/games/game_streaming_client.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';

class FakeEngine implements GameStreamingClient {
  Completer<List<StreamGame>>? waiting;
  bool cancelled = false;
  @override
  Future<GameClientCapabilities> capabilities(GameHost host) async =>
      const GameClientCapabilities(available: true, inlinePairing: true, library: true);
  @override
  Future<void> pair(GameHost host, String pin) async {}
  @override
  Future<List<StreamGame>> games(GameHost host) => waiting?.future ?? Future.value([]);
  @override
  Future<void> open(GameHost host, {required StreamGame game, bool touchControls = true}) async {}
  @override
  void cancel() {
    cancelled = true;
  }
}

void main() {
  late SourceDatabase db;
  late SourceRepository repository;
  late FakeEngine client;
  late GameLibraryController controller;
  var current = true;
  final host = GameHost(id: 'pc', name: 'PC', address: '192.168.1.2', protocol: GameProtocol.gameStream);
  late StreamGame game;
  setUp(() {
    current = true;
    db = SourceDatabase(NativeDatabase.memory());
    repository = SourceRepository(db);
    client = FakeEngine();
    controller = GameLibraryController(
      repository: repository,
      profileId: 'alice',
      sessionCurrent: () => current,
      client: client,
    );
    game = StreamGame(hostKey: host.key, id: '1', name: 'Desktop');
  });
  tearDown(() async {
    controller.dispose();
    await db.close();
  });
  test('profile persistence keeps libraries separate', () async {
    await controller.saveHost(host);
    await controller.saveGame(game);
    await controller.toggleFavorite(game);
    await controller.opened(game);
    expect(await repository.preference('bob', GameLibraryController.preferenceKey), isEmpty);
    await controller.load();
    expect(controller.library.favorites, {game.key});
    expect(controller.library.recent, [game.key]);
  });
  test('serialized edits do not overwrite each other', () async {
    await controller.saveHost(host);
    await Future.wait([
      controller.saveGame(game),
      controller.saveGame(StreamGame(hostKey: host.key, id: '2', name: 'Game')),
    ]);
    expect(controller.library.games, hasLength(2));
  });
  test('forget removes dependent shortcuts, favorites and recents', () async {
    await controller.saveHost(host);
    await controller.saveGame(game);
    await controller.toggleFavorite(game);
    await controller.opened(game);
    await controller.removeHost(host);
    expect(controller.library.games, isEmpty);
    expect(controller.library.favorites, isEmpty);
    expect(controller.library.recent, isEmpty);
  });
  test('late library result cannot publish into a retired profile session', () async {
    await controller.saveHost(host);
    client.waiting = Completer();
    final pending = controller.refreshGames(host);
    current = false;
    client.waiting!.complete([game]);
    await expectLater(pending, throwsA(isA<GameClientException>()));
    expect(controller.library.games, isEmpty);
    expect(
      GameLibrary.fromJson(await repository.preference('alice', GameLibraryController.preferenceKey)).games,
      isEmpty,
    );
  });
  test('a deleted profile cannot be resurrected by a stale write', () async {
    await repository.forgetProfile('alice');
    await expectLater(controller.saveHost(host), throwsA(isA<SourceException>()));
    expect(await repository.preference('alice', GameLibraryController.preferenceKey), isEmpty);
  });
  test('failed library refresh preserves the last usable library', () async {
    await controller.saveHost(host);
    await controller.saveGame(game);
    client.waiting = Completer()..completeError(const GameClientException(GameClientFailure.unavailable));
    await expectLater(controller.refreshGames(host), throwsA(isA<GameClientException>()));
    expect(controller.library.games.single.id, '1');
  });
}
