import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/playback_report_session.dart';

import '../test_helpers/playback_report_fakes.dart';

class _RecordingClient with PlaybackReportRecorder implements MediaServerClient {
  final calls = <String>[];
  Completer<void>? startGate;
  Completer<void>? stopGate;
  bool failNextStop = false;

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {
    final positionMs = call.position.inMilliseconds;
    switch (call.kind) {
      case PlaybackReportKind.started:
        final start = startGate;
        if (start != null) await start.future;
        calls.add('started:$positionMs:${call.mediaSourceId}:${call.audioStreamIndex}:${call.subtitleStreamIndex}');
      case PlaybackReportKind.progress:
        calls.add('${call.isPaused ? 'paused' : 'playing'}:$positionMs');
      case PlaybackReportKind.stopped:
        calls.add('stopped-attempt:$positionMs:${call.mediaSourceId}');
        final stop = stopGate;
        if (stop != null) await stop.future;
        if (failNextStop) {
          failNextStop = false;
          throw StateError('stop failed');
        }
        calls.add('stopped:$positionMs:${call.mediaSourceId}');
    }
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

  test('resetAfterStop during in-flight stop reopens reporting after stop completes', () async {
    final client = _RecordingClient()..stopGate = Completer<void>();
    final session = PlaybackReportSession(client: client, itemId: 'item-1');

    await session.report(_snapshot('playing', positionMs: 1000));
    client.calls.clear();

    final stopFuture = session.report(_snapshot('stopped', positionMs: 3000));
    await Future<void>.delayed(Duration.zero);
    expect(client.calls, ['stopped-attempt:3000:null']);

    session.resetAfterStop();
    client.stopGate!.complete();
    await stopFuture;

    expect(session.isIdle, isTrue);
    expect(await session.report(_snapshot('playing', positionMs: 4000)), isTrue);
    expect(client.calls, ['stopped-attempt:3000:null', 'stopped:3000:null', 'started:4000:null:null:null']);
  });
}
