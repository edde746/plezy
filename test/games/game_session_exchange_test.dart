import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_session_exchange.dart';

void main() {
  late GameSessionExchange host, client;
  late Object owner;
  var allowed = false, executions = 0;
  final sent = <Map<String, dynamic>>[];
  setUp(() {
    allowed = false;
    executions = 0;
    owner = Object();
    sent.clear();
    host = GameSessionExchange(
      isHost: true,
      allowed: () => allowed,
      targets: () => [
        GameSessionControlTarget(
          owner: owner,
          title: 'Portal\u202e 2',
          audible: false,
          execute: (_) {
            executions++;
            return true;
          },
        ),
      ],
      send: (m) => client.receive(m),
    );
    client = GameSessionExchange(
      isHost: false,
      allowed: () => false,
      targets: () => throw StateError('remote cannot inspect'),
      send: (m) {
        sent.add(m);
        host.receive(m);
      },
    );
  });
  tearDown(() {
    host.close();
    client.close();
  });

  test('off by default, titles and controls require explicit permission', () async {
    expect((await client.request(GameSessionAction.list)).status, GameSessionControlStatus.denied);
    allowed = true;
    final reply = await client.request(GameSessionAction.list);
    expect(reply.status, GameSessionControlStatus.ok);
    expect(reply.sessions.single.title, 'Portal 2');
    expect(reply.sessions.single.id, matches(RegExp(r'^[a-f0-9]{32}$')));
    final controlled = await client.request(GameSessionAction.listen, target: reply.sessions.single.id);
    expect(controlled.status, GameSessionControlStatus.submitted);
    expect(executions, 1);
    host.receive(sent.last); // Repeat after acknowledgement.
    await Future<void>.delayed(Duration.zero);
    expect(executions, 1);
  });

  test('replacing a session with the same game cannot reuse a control handle', () async {
    allowed = true;
    final id = (await client.request(GameSessionAction.list)).sessions.single.id;
    owner = Object();
    expect(
      (await client.request(GameSessionAction.disconnect, target: id)).status,
      GameSessionControlStatus.unavailable,
    );
    expect(executions, 0);
  });

  test('permission revocation and disconnect invalidate control', () async {
    allowed = true;
    final id = (await client.request(GameSessionAction.list)).sessions.single.id;
    allowed = false;
    expect((await client.request(GameSessionAction.disconnect, target: id)).status, GameSessionControlStatus.denied);
    allowed = true;
    host.reset();
    expect(
      (await client.request(GameSessionAction.disconnect, target: id)).status,
      GameSessionControlStatus.unavailable,
    );
    expect(executions, 0);
  });

  test('arbitrary data, missing handles and invented actions cannot execute', () async {
    allowed = true;
    final id = (await client.request(GameSessionAction.list)).sessions.single.id;
    for (final (index, patch) in <Map<String, dynamic>>[
      {'url': 'steam://exit'},
      {'action': 'quit'},
      {'target': 'internal-session-id'},
      {'target': null},
    ].indexed) {
      host.receive({
        'version': 1,
        'op': 'request',
        'request': (index + 1).toRadixString(16).padLeft(32, '0'),
        'action': 'disconnect',
        'target': id,
        ...patch,
      });
    }
    expect(executions, 0);
  });

  test('a retired peer cannot receive an acknowledgement from old work', () async {
    final work = Completer<bool>();
    final replies = <Map<String, dynamic>>[];
    host.close();
    host = GameSessionExchange(
      isHost: true,
      allowed: () => true,
      targets: () => [
        GameSessionControlTarget(owner: owner, title: 'Portal', audible: false, execute: (_) => work.future),
      ],
      send: (m) {
        replies.add(m);
        client.receive(m);
      },
    );
    final id = (await client.request(GameSessionAction.list)).sessions.single.id;
    final pending = client.request(GameSessionAction.mute, target: id);
    await Future<void>.delayed(Duration.zero);
    host.reset();
    client.reset();
    work.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect((await pending).status, GameSessionControlStatus.unavailable);
    expect(replies, hasLength(1));
  });

  test('malformed and oversized replies never publish remote sessions', () async {
    client.close();
    Map<String, dynamic>? request;
    client = GameSessionExchange(isHost: false, allowed: () => false, targets: () => [], send: (m) => request = m);
    final pending = client.request(GameSessionAction.list);
    client.receive({
      'version': 1,
      'op': 'result',
      'request': request!['request'],
      'status': 'ok',
      'sessions': List.generate(9, (_) => {'id': 'a' * 32, 'title': 'Title', 'audible': false}),
    });
    final reply = await pending;
    expect(reply.status, GameSessionControlStatus.unavailable);
    expect(reply.sessions, isEmpty);
  });

  test('send failure and close finish the pending request', () async {
    client.close();
    client = GameSessionExchange(
      isHost: false,
      allowed: () => false,
      targets: () => [],
      send: (_) => throw StateError('closed'),
    );
    expect((await client.request(GameSessionAction.list)).status, GameSessionControlStatus.unavailable);
  });
}
