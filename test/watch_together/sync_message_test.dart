import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';

void main() {
  test('join messages match reviewed v3 examples, including host-only zero and legacy omission', () {
    const examples = [(true, ControlMode.anyone, 1), (true, ControlMode.hostOnly, 0), (false, null, null)];
    for (final (isHost, mode, wireMode) in examples) {
      final message = SyncMessage.join(peerId: 'p1', displayName: 'Participant', isHost: isHost, controlMode: mode);
      final expected = {
        't': 'join',
        'ts': message.timestamp,
        'pid': 'p1',
        'name': 'Participant',
        'host': isHost,
        'v': 3,
        'cm': ?wireMode,
      };
      expect(jsonDecode(message.toJson()), expected);

      // Decode an independently authored peer message, not the encoder output.
      final decoded = SyncMessage.fromJson(jsonEncode({...expected, 'ts': 1000}));
      expect(decoded.type, SyncMessageType.join);
      expect(decoded.timestamp, 1000);
      expect(decoded.peerId, 'p1');
      expect(decoded.displayName, 'Participant');
      expect(decoded.isHost, isHost);
      expect(decoded.controlMode, mode);
      expect(decoded.version, 3);
    }
  });

  test('unknown join control ordinals from a newer peer remain unknown', () {
    for (final ordinal in [-1, 99]) {
      final decoded = SyncMessage.fromJson(
        '{"t":"join","ts":1000,"pid":"p1","name":"Host","host":true,"v":3,"cm":$ordinal}',
      );
      expect(decoded.controlMode, isNull);
    }
  });

  test('state requests carry only the request envelope', () {
    final message = SyncMessage.requestState(peerId: 'p1');
    expect(jsonDecode(message.toJson()), {'t': 'requestState', 'ts': message.timestamp, 'pid': 'p1'});
    final decoded = SyncMessage.fromJson('{"t":"requestState","ts":1000,"pid":"p1"}');
    expect(decoded.type, SyncMessageType.requestState);
    expect(decoded.timestamp, 1000);
    expect(decoded.peerId, 'p1');
  });
}
