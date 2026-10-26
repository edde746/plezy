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
