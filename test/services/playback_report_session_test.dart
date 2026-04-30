import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/playback_report_session.dart';

class _RecordingClient implements MediaServerClient {
  final calls = <String>[];
  Completer<void>? startGate;
  bool failNextStop = false;

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final gate = startGate;
    if (gate != null) await gate.future;
    calls.add('started:${position.inMilliseconds}:$mediaSourceId:$audioStreamIndex:$subtitleStreamIndex');
  }

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    calls.add('${isPaused ? 'paused' : 'playing'}:${position.inMilliseconds}');
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) async {
    calls.add('stopped-attempt:${position.inMilliseconds}:$mediaSourceId');
    if (failNextStop) {
      failNextStop = false;
      throw StateError('stop failed');
    }
    calls.add('stopped:${position.inMilliseconds}:$mediaSourceId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlaybackReportSnapshot _snapshot(
  String state, {
  int positionMs = 1000,
  PlaybackStreamSelectionResolver resolveStreamSelection = _noStreamSelection,
}) {
  return PlaybackReportSnapshot(
    state: state,
    position: Duration(milliseconds: positionMs),
    duration: const Duration(minutes: 1),
    resolveStreamSelection: resolveStreamSelection,
  );
}

PlaybackStreamSelection _noStreamSelection() => PlaybackStreamSelection.none;

void main() {
  test('orders stopped after start even when stream selection is still resolving', () async {
    final client = _RecordingClient();
    final session = PlaybackReportSession(client: client, itemId: 'item-1');
    final selectionGate = Completer<PlaybackStreamSelection>();

    final startFuture = session.report(_snapshot('playing', resolveStreamSelection: () => selectionGate.future));
    await Future<void>.delayed(Duration.zero);

    final stopFuture = session.report(_snapshot('stopped', positionMs: 5000));
    await Future<void>.delayed(Duration.zero);
    expect(client.calls, isEmpty);

    selectionGate.complete(const PlaybackStreamSelection(mediaSourceId: 'source-1', audioStreamIndex: 2));
    await stopFuture;
    await startFuture;

    expect(client.calls, ['started:1000:source-1:2:null', 'stopped-attempt:5000:null', 'stopped:5000:null']);
  });

  test('coalesces duplicate starts while start report is in flight', () async {
    final client = _RecordingClient()..startGate = Completer<void>();
    final session = PlaybackReportSession(client: client, itemId: 'item-1');

    final first = session.report(_snapshot('playing', positionMs: 1000));
    final second = session.report(_snapshot('playing', positionMs: 2000));
    await Future<void>.delayed(Duration.zero);
    expect(client.calls, isEmpty);

    client.startGate!.complete();
    await Future.wait([first, second]);

    expect(client.calls, ['started:1000:null:null:null']);
  });

  test('coalesces a state change during start into one progress report after start', () async {
    final client = _RecordingClient()..startGate = Completer<void>();
    final session = PlaybackReportSession(client: client, itemId: 'item-1');

    final first = session.report(_snapshot('playing', positionMs: 1000));
    final second = session.report(_snapshot('paused', positionMs: 2000));
    await Future<void>.delayed(Duration.zero);

    client.startGate!.complete();
    await Future.wait([first, second]);

    expect(client.calls, ['started:1000:null:null:null', 'paused:2000']);
  });

  test('terminal stop suppresses in-flight progress after its stream selection resolves', () async {
    final client = _RecordingClient();
    final session = PlaybackReportSession(client: client, itemId: 'item-1');
    await session.report(_snapshot('playing', positionMs: 1000));
    client.calls.clear();

    final selectionGate = Completer<PlaybackStreamSelection>();
    final progressFuture = session.report(
      _snapshot('playing', positionMs: 2000, resolveStreamSelection: () => selectionGate.future),
    );
    await Future<void>.delayed(Duration.zero);

    final stopFuture = session.report(_snapshot('stopped', positionMs: 3000));
    selectionGate.complete(PlaybackStreamSelection.none);
    await stopFuture;
    expect(await progressFuture, isFalse);

    expect(client.calls, ['stopped-attempt:3000:null', 'stopped:3000:null']);
  });

  test('queued progress resolves false when terminal stop suppresses it during startup', () async {
    final client = _RecordingClient()..startGate = Completer<void>();
    final session = PlaybackReportSession(client: client, itemId: 'item-1');

    final startFuture = session.report(_snapshot('playing', positionMs: 1000));
    final progressFuture = session.report(_snapshot('paused', positionMs: 2000));
    await Future<void>.delayed(Duration.zero);

    final stopFuture = session.report(_snapshot('stopped', positionMs: 3000));
    client.startGate!.complete();

    await stopFuture;
    await startFuture;

    expect(await progressFuture, isFalse);
    expect(client.calls, ['started:1000:null:null:null', 'stopped-attempt:3000:null', 'stopped:3000:null']);
  });

  test('stop failure allows explicit stopped retry but ignores non-stop reports', () async {
    final client = _RecordingClient()..failNextStop = true;
    final session = PlaybackReportSession(client: client, itemId: 'item-1');

    await expectLater(session.report(_snapshot('stopped', positionMs: 1000)), throwsStateError);
    await session.report(_snapshot('playing', positionMs: 2000));
    await session.report(_snapshot('stopped', positionMs: 3000));

    expect(client.calls, ['stopped-attempt:1000:null', 'stopped-attempt:3000:null', 'stopped:3000:null']);
  });
}
