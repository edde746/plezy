import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';

void main() {
  group('join control mode wire format', () {
    test('a host join round-trips its control mode', () {
      final decoded = SyncMessage.fromJson(
        SyncMessage.join(peerId: 'p1', displayName: 'Host', isHost: true, controlMode: ControlMode.anyone).toJson(),
      );
      expect(decoded.type, SyncMessageType.join);
      expect(decoded.controlMode, ControlMode.anyone);
      expect(decoded.version, SyncMessage.protocolVersion);
    });

    test('hostOnly (index 0) is serialized, not dropped as falsy', () {
      final decoded = SyncMessage.fromJson(
        SyncMessage.join(peerId: 'p1', displayName: 'Host', isHost: true, controlMode: ControlMode.hostOnly).toJson(),
      );
      expect(decoded.controlMode, ControlMode.hostOnly);
    });

    test('a join without a control mode omits the key and parses to unknown', () {
      final message = SyncMessage.join(peerId: 'p1', displayName: 'Guest', isHost: false);
      final map = jsonDecode(message.toJson()) as Map<String, dynamic>;
      expect(map.containsKey('cm'), isFalse, reason: 'pre-cm clients must see the exact 2.13.0 join shape');
      expect(SyncMessage.fromJson(message.toJson()).controlMode, isNull);
    });

    test('an out-of-range control mode index from a newer peer parses to unknown', () {
      final map =
          jsonDecode(SyncMessage.join(peerId: 'p1', displayName: 'Host', isHost: true).toJson())
              as Map<String, dynamic>;
      map['cm'] = 99;
      expect(SyncMessage.fromJson(jsonEncode(map)).controlMode, isNull);
    });

    test('the relay sender stamp preserves the control mode', () {
      final stamped = SyncMessage.join(
        peerId: 'p1',
        displayName: 'Host',
        isHost: true,
        controlMode: ControlMode.hostOnly,
      ).copyWith(peerId: 'relay-stamped');
      expect(stamped.controlMode, ControlMode.hostOnly);
      expect(stamped.peerId, 'relay-stamped');
    });
  });

  group('join capabilities wire format', () {
    test('a join advertises this build\'s capabilities and round-trips them', () {
      final decoded = SyncMessage.fromJson(SyncMessage.join(peerId: 'p1', displayName: 'G', isHost: false).toJson());
      expect(decoded.capabilities, contains(SyncCapability.hostTransfer));
    });

    test('a join without a capability list parses to none advertised, not a failure', () {
      final decoded = SyncMessage.fromJson('{"t":"join","ts":0,"pid":"p1","name":"Old","host":false,"v":3}');
      expect(decoded.capabilities, isNull);
    });

    test('unknown and malformed capability entries from a newer peer are tolerated', () {
      final decoded = SyncMessage.fromJson(
        '{"t":"join","ts":0,"pid":"p1","name":"New","host":false,"v":3,"cap":["hostTransfer","future",7]}',
      );
      expect(decoded.capabilities, {'hostTransfer', 'future'});
    });
  });
}
