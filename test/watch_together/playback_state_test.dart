import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/models/playback_state.dart';
import 'package:plezy/watch_together/models/sync_message.dart';
import 'package:plezy/watch_together/models/watch_session.dart';

void main() {
  const fullState = PlaybackState(
    seq: 42,
    ratingKey: '12345',
    serverId: 'srv-1',
    mediaTitle: 'Some Episode',
    phase: PlaybackPhase.playing,
    anchorPositionMs: 90000,
    anchorHostTimeMs: 1718700000000,
    rate: 1.5,
    controlMode: ControlMode.anyone,
    waitingOn: ['peer-a', 'peer-b'],
    actorPeerId: 'peer-a',
    actionHint: PlaybackActionHint.seek,
  );

  group('PlaybackState', () {
    test('round-trips through map with all fields', () {
      expect(PlaybackState.fromMap(fullState.toMap()), fullState);
    });

    test('round-trips with optionals omitted and omits empty keys', () {
      const minimal = PlaybackState(
        seq: 1,
        ratingKey: 'rk',
        serverId: 'sid',
        phase: PlaybackPhase.loading,
        anchorPositionMs: 0,
        anchorHostTimeMs: 1000,
        rate: 1.0,
        controlMode: ControlMode.hostOnly,
      );
      final map = minimal.toMap();
      expect(map.containsKey('ti'), isFalse);
      expect(map.containsKey('w'), isFalse);
      expect(map.containsKey('ab'), isFalse);
      expect(map.containsKey('ah'), isFalse);
      expect(PlaybackState.fromMap(map), minimal);
    });

    test('round-trips through the SyncMessage envelope', () {
      final message = SyncMessage.state(fullState, peerId: 'host-1');
      final decoded = SyncMessage.fromJson(message.toJson());
      expect(decoded.type, SyncMessageType.state);
      expect(decoded.state, fullState);
      expect(decoded.peerId, 'host-1');
    });

    test('unknown enum indexes decode to safe fallbacks instead of throwing', () {
      final map = fullState.toMap()
        ..['ph'] = 99
        ..['ah'] = 99
        ..['cm'] = 99;
      final decoded = PlaybackState.fromMap(map);
      expect(decoded.phase, PlaybackPhase.paused);
      expect(decoded.actionHint, isNull);
      expect(decoded.controlMode, ControlMode.hostOnly);
    });

    group('targetPositionMs', () {
      test('extrapolates from the anchor while playing', () {
        final target = fullState.targetPositionMs(fullState.anchorHostTimeMs + 2000);
        expect(target, 90000 + (2000 * 1.5).round());
      });

      test('clamps to the anchor before a scheduled start', () {
        expect(fullState.targetPositionMs(fullState.anchorHostTimeMs - 5000), 90000);
      });

      test('returns the anchor for non-playing phases', () {
        final paused = fullState.copyWith(phase: PlaybackPhase.paused);
        expect(paused.targetPositionMs(fullState.anchorHostTimeMs + 60000), 90000);
      });
    });

    test('mediaKey matches mediaKeyFor', () {
      expect(fullState.mediaKey, PlaybackState.mediaKeyFor(ratingKey: '12345', serverId: 'srv-1'));
    });
  });

  group('PeerStatus', () {
    test('round-trips through map and envelope', () {
      const status = PeerStatus(mediaKey: 'srv-1:12345', ready: true, buffering: false, positionMs: 1234, rttMs: 80);
      expect(PeerStatus.fromMap(status.toMap()), status);

      final decoded = SyncMessage.fromJson(SyncMessage.status(status, peerId: 'guest-1').toJson());
      expect(decoded.type, SyncMessageType.status);
      expect(decoded.status, status);
    });

    test('omits rtt when unknown', () {
      const status = PeerStatus(mediaKey: 'k', ready: false, buffering: true, positionMs: 0);
      expect(status.toMap().containsKey('rtt'), isFalse);
      expect(PeerStatus.fromMap(status.toMap()), status);
    });
  });

  group('ControlRequest', () {
    test('round-trips all kinds', () {
      const requests = [
        ControlRequest(kind: ControlRequestKind.play, positionMs: 5000),
        ControlRequest(kind: ControlRequestKind.pause),
        ControlRequest(kind: ControlRequestKind.seek, positionMs: 60000),
        ControlRequest(kind: ControlRequestKind.rate, rate: 1.25),
      ];
      for (final request in requests) {
        expect(ControlRequest.fromMap(request.toMap()), request);
        final decoded = SyncMessage.fromJson(SyncMessage.control(request, peerId: 'g').toJson());
        expect(decoded.control, request);
      }
    });
  });

  group('SyncMessage v2 envelope', () {
    test('join carries the protocol version', () {
      final join = SyncMessage.join(peerId: 'p', displayName: 'Name', isHost: false);
      final decoded = SyncMessage.fromJson(join.toJson());
      expect(decoded.version, SyncMessage.protocolVersion);
    });

    test('requestState round-trips', () {
      final decoded = SyncMessage.fromJson(SyncMessage.requestState(peerId: 'p').toJson());
      expect(decoded.type, SyncMessageType.requestState);
      expect(decoded.peerId, 'p');
    });

    test('copyWith preserves v2 payloads', () {
      final relabeled = SyncMessage.state(fullState).copyWith(peerId: 'relay-id');
      expect(relabeled.state, fullState);
      expect(relabeled.peerId, 'relay-id');
    });
  });
}
