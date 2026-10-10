import 'dart:convert';

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

  // Hand-reviewed protocol-v3 examples: compact field names and append-only
  // enum ordinals are peer-facing contracts, not encoder/decoder round trips.
  test('state messages match full and minimal wire examples independently in both directions', () {
    const minimal = PlaybackState(
      seq: 1,
      ratingKey: 'rk',
      serverId: 'sid',
      phase: PlaybackPhase.loading,
      anchorPositionMs: 0,
      anchorHostTimeMs: 1000,
      rate: 1,
      controlMode: ControlMode.hostOnly,
    );
    const examples = [
      (
        fullState,
        '{"t":"state","ts":1000,"pid":"host-1","st":{"q":42,"rk":"12345","sid":"srv-1",'
            '"ti":"Some Episode","ph":3,"ap":90000,"at":1718700000000,"r":1.5,"cm":1,'
            '"w":["peer-a","peer-b"],"ab":"peer-a","ah":2}}',
      ),
      (
        minimal,
        '{"t":"state","ts":1000,"pid":"host-1","st":{"q":1,"rk":"rk","sid":"sid",'
            '"ph":0,"ap":0,"at":1000,"r":1.0,"cm":0}}',
      ),
    ];
    for (final (state, wire) in examples) {
      final decoded = _expectWire(
        SyncMessage(
          type: SyncMessageType.state,
          timestamp: 1000,
          peerId: 'before-relay',
          state: state,
        ).copyWith(peerId: 'host-1'),
        wire,
      );
      expect(decoded.state, state);
      expect(decoded.state!.waitingOn, state.waitingOn);
    }
  });

  test('status wire examples preserve measured RTT and distinguish unknown from zero', () {
    const examples = [
      (
        PeerStatus(mediaKey: 'srv-1:12345', ready: true, buffering: false, positionMs: 1234, rttMs: 80),
        '{"t":"status","ts":1000,"pid":"guest-1","su":{"mk":"srv-1:12345","rdy":true,'
            '"buf":false,"pos":1234,"rtt":80}}',
      ),
      (
        PeerStatus(mediaKey: 'k', ready: false, buffering: true, positionMs: 0),
        '{"t":"status","ts":1000,"pid":"guest-1","su":{"mk":"k","rdy":false,"buf":true,"pos":0}}',
      ),
      (
        PeerStatus(mediaKey: 'k', ready: true, buffering: false, positionMs: 0, rttMs: 0),
        '{"t":"status","ts":1000,"pid":"guest-1","su":{"mk":"k","rdy":true,"buf":false,"pos":0,"rtt":0}}',
      ),
    ];
    for (final (status, wire) in examples) {
      final decoded = _expectWire(
        SyncMessage(type: SyncMessageType.status, timestamp: 1000, peerId: 'guest-1', status: status),
        wire,
      );
      expect(decoded.status, status);
    }
  });

  test('control wire examples retain every action and omit unrelated payload fields', () {
    const examples = [
      (ControlRequest(kind: ControlRequestKind.play, positionMs: 5000), '{"k":0,"pos":5000}'),
      (ControlRequest(kind: ControlRequestKind.pause), '{"k":1}'),
      (ControlRequest(kind: ControlRequestKind.seek, positionMs: 60000), '{"k":2,"pos":60000}'),
      (ControlRequest(kind: ControlRequestKind.rate, rate: 1.25), '{"k":3,"r":1.25}'),
    ];
    for (final (control, payload) in examples) {
      final decoded = _expectWire(
        SyncMessage(type: SyncMessageType.control, timestamp: 1000, peerId: 'guest-1', control: control),
        '{"t":"control","ts":1000,"pid":"guest-1","co":$payload}',
      );
      expect(decoded.control, control);
    }
  });

  test('unknown state enum ordinals from a newer peer retain safe fallbacks', () {
    final decoded = SyncMessage.fromJson(
      '{"t":"state","ts":1000,"st":{"q":1,"rk":"rk","sid":"sid","ph":99,'
      '"ap":0,"at":1000,"r":1,"cm":99,"ah":99}}',
    ).state!;
    expect(decoded.phase, PlaybackPhase.paused);
    expect(decoded.actionHint, isNull);
    expect(decoded.controlMode, ControlMode.hostOnly);
  });

  group('targetPositionMs', () {
    test('extrapolates from the anchor while playing', () {
      expect(fullState.targetPositionMs(1718700002000), 93000);
    });

    test('clamps to the anchor before a scheduled start', () {
      expect(fullState.targetPositionMs(1718699995000), 90000);
    });

    test('returns the anchor for non-playing phases', () {
      final paused = fullState.copyWith(phase: PlaybackPhase.paused);
      expect(paused.targetPositionMs(1718700060000), 90000);
    });
  });
}

SyncMessage _expectWire(SyncMessage message, String wire) {
  expect(jsonDecode(message.toJson()), jsonDecode(wire));
  final decoded = SyncMessage.fromJson(wire);
  expect(decoded.type, message.type);
  expect(decoded.timestamp, message.timestamp);
  expect(decoded.peerId, message.peerId);
  return decoded;
}
