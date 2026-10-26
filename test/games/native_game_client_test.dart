import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/games/game_streaming_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final host = GameHost(id: 'pc', name: 'PC', address: '192.168.1.2', protocol: GameProtocol.gameStream);
  tearDown(() => messenger.setMockMethodCallHandler(NativeGameStreamingClient.channel, null));
  test('Steam playback does not imply an imported account catalog', () async {
    final steam = GameHost(id: '123', name: 'Steam PC', address: '192.168.1.2', protocol: GameProtocol.steam);
    messenger.setMockMethodCallHandler(NativeGameStreamingClient.channel, (call) async {
      if (call.method == 'capabilities') return {'available': true, 'inlinePairing': true, 'library': false};
      if (call.method == 'games') return <dynamic>[];
      return null;
    });
    final client = NativeGameStreamingClient();
    final capabilities = await client.capabilities(steam);
    expect(capabilities.available, isTrue);
    expect(capabilities.library, isFalse);
    final games = await client.games(steam);
    expect(games.single.id, '0');
    expect(games.single.hostKey, steam.key);
    messenger.setMockMethodCallHandler(NativeGameStreamingClient.channel, (_) async {
      throw PlatformException(code: 'PAIRING_REQUIRED');
    });
    await expectLater(
      client.games(steam),
      throwsA(isA<GameClientException>().having((e) => e.failure, 'failure', GameClientFailure.pairingRequired)),
    );
  });
  test('a missing native engine reports unavailable and never launches a URL', () async {
    final client = NativeGameStreamingClient();
    expect((await client.capabilities(host)).available, isFalse);
    await expectLater(client.pair(host, '1234'), throwsA(isA<GameClientException>()));
  });
  test('native session receives the host, app and touch setting as structured data', () async {
    MethodCall? call;
    messenger.setMockMethodCallHandler(NativeGameStreamingClient.channel, (value) async {
      call = value;
      return true;
    });
    await NativeGameStreamingClient().open(
      host,
      game: StreamGame(hostKey: host.key, id: '10', name: 'A & B', hdr: true),
      touchControls: false,
    );
    expect(call!.method, 'open');
    expect(call!.arguments['appName'], 'A & B');
    expect(call!.arguments['touchControls'], isFalse);
    expect(call!.arguments['hdr'], isTrue);
    expect(call!.arguments['port'], 47989);
  });
  test('cancel discards a native result that arrives after the profile retired', () async {
    final response = Completer<List<dynamic>>();
    messenger.setMockMethodCallHandler(
      NativeGameStreamingClient.channel,
      (call) async => call.method == 'games' ? response.future : null,
    );
    final client = NativeGameStreamingClient();
    final pending = client.games(host);
    client.cancel();
    response.complete([
      {'id': '1', 'name': 'Desktop'},
    ]);
    await expectLater(
      pending,
      throwsA(isA<GameClientException>().having((e) => e.failure, 'failure', GameClientFailure.cancelled)),
    );
  });
  test('cannot launch a shortcut for another computer', () async {
    await expectLater(
      NativeGameStreamingClient().open(
        host,
        game: StreamGame(hostKey: 'different', id: '1', name: 'Game'),
      ),
      throwsA(isA<GameClientException>()),
    );
  });
}
