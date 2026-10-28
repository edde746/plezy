import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/steam_host_actions.dart';

void main() {
  test('host action URLs accept only fixed verbs and uint32 AppIDs', () {
    expect(steamHostActionUri(SteamHostAction.launch, 620).toString(), 'steam://rungameid/620');
    expect(steamHostActionUri(SteamHostAction.install, 620).toString(), 'steam://install/620');
    expect(steamHostActionUri(SteamHostAction.downloads, null).toString(), 'steam://open/downloads');
    for (final id in [-1, 0, 0x100000000]) {
      expect(() => steamHostActionUri(SteamHostAction.launch, id), throwsFormatException);
    }
    expect(() => steamHostActionUri(SteamHostAction.library, 620), throwsFormatException);
  });

  test('permissions are opt-in and launch acknowledgement is only submission', () async {
    late SteamHostActionExchange host, client;
    var permitted = false, executed = 0;
    host = SteamHostActionExchange(
      isHost: true,
      allowed: (_) => permitted,
      execute: (action, appId, current) async {
        expect(current(), isTrue);
        expect(appId, 620);
        executed++;
        return true;
      },
      send: (message) => client.receive(message),
    );
    client = SteamHostActionExchange(
      isHost: false,
      allowed: (_) => false,
      execute: (_, _, _) => throw StateError('remote cannot execute'),
      send: host.receive,
    );
    addTearDown(host.close);
    addTearDown(client.close);
    expect(await client.request(SteamHostAction.launch, appId: 620), SteamHostActionResult.denied);
    expect(executed, 0);
    permitted = true;
    expect(await client.request(SteamHostAction.launch, appId: 620), SteamHostActionResult.submitted);
    expect(executed, 1);
  });

  test('replayed requests cannot launch twice and arbitrary arguments are rejected', () async {
    var executed = 0;
    final replies = <Map<String, dynamic>>[];
    final host = SteamHostActionExchange(
      isHost: true,
      allowed: (_) => true,
      execute: (_, _, _) async {
        executed++;
        return true;
      },
      send: replies.add,
    );
    addTearDown(host.close);
    final message = {'version': 1, 'op': 'request', 'request': 'a' * 32, 'action': 'launch', 'appId': 620};
    host.receive(message);
    await Future<void>.delayed(Duration.zero);
    host.receive(message);
    await Future<void>.delayed(Duration.zero);
    expect(executed, 1);
    expect(replies, hasLength(1));
    host.receive({...message, 'request': 'b' * 32, 'url': 'steam://run/620/unsafe'});
    expect(replies.last['result'], 'denied');
    expect(executed, 1);
    host.receive({...message, 'request': 'c' * 32, 'appId': '620/unsafe'});
    expect(replies.last['result'], 'denied');
    expect(executed, 1);
  });

  test('disconnect while inspecting the host cannot later execute a launch', () async {
    final release = Completer<void>();
    var executed = false;
    final host = SteamHostActionExchange(
      isHost: true,
      allowed: (_) => true,
      execute: (_, _, current) async {
        await release.future;
        if (current()) executed = true;
        return executed;
      },
      send: (_) => fail('retired operation must not reply'),
    );
    host.receive({'version': 1, 'op': 'request', 'request': 'd' * 32, 'action': 'launch', 'appId': 620});
    host.reset();
    release.complete();
    await Future<void>.delayed(Duration.zero);
    expect(executed, isFalse);
    host.close();
  });

  test('revoking permission during inspection prevents launch', () async {
    final release = Completer<void>();
    var permitted = true, executed = false;
    final host = SteamHostActionExchange(
      isHost: true,
      allowed: (_) => permitted,
      execute: (_, _, current) async {
        await release.future;
        if (current()) executed = true;
        return executed;
      },
      send: (_) {},
    );
    addTearDown(host.close);
    host.receive({'version': 1, 'op': 'request', 'request': 'e' * 32, 'action': 'install', 'appId': 620});
    permitted = false;
    release.complete();
    await Future<void>.delayed(Duration.zero);
    expect(executed, isFalse);
  });

  test('unsolicited results do not complete a different request', () async {
    Map<String, dynamic>? sent;
    final client = SteamHostActionExchange(
      isHost: false,
      allowed: (_) => false,
      execute: (_, _, _) async => false,
      send: (m) => sent = m,
    );
    final pending = client.request(SteamHostAction.library);
    client.receive({'version': 1, 'op': 'result', 'request': 'f' * 32, 'result': 'submitted'});
    expect(sent?['op'], 'request');
    client.close();
    expect(await pending, SteamHostActionResult.unavailable);
  });
}
