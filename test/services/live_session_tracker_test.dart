import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/live_session_tracker.dart';

import '../test_helpers/playback_report_fakes.dart';

class _FakeJellyfinClient with PlaybackReportRecorder implements JellyfinClient {
  final calls = <String>[];
  final startGate = Completer<void>();

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {
    final identity = '${call.itemId}:${call.playSessionId}:${call.mediaSourceId}:${call.liveStreamId}';
    switch (call.kind) {
      case PlaybackReportKind.started:
        await startGate.future;
        calls.add('started:$identity:${call.playMethod}');
      case PlaybackReportKind.progress:
        calls.add('${call.isPaused ? 'paused' : 'playing'}:$identity');
      case PlaybackReportKind.stopped:
        calls.add('stopped:$identity');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('coalesces duplicate live starts and orders stop after in-flight start', () async {
    final client = _FakeJellyfinClient();
    final tracker = JellyfinLiveSessionTracker(
      playSessionId: 'live-session-1',
      mediaSourceId: 'source-1',
      liveStreamId: 'live-stream-1',
      playMethod: 'Transcode',
    );

    final first = tracker.report(
      client: client,
      itemId: 'channel-1',
      state: 'playing',
      position: Duration.zero,
      duration: Duration.zero,
    );
    final second = tracker.report(
      client: client,
      itemId: 'channel-1',
      state: 'playing',
      position: const Duration(seconds: 1),
      duration: Duration.zero,
    );
    await Future<void>.delayed(Duration.zero);
    final stopped = tracker.report(
      client: client,
      itemId: 'channel-1',
      state: 'stopped',
      position: const Duration(seconds: 2),
      duration: Duration.zero,
    );

    await Future<void>.delayed(Duration.zero);
    expect(client.calls, isEmpty);

    client.startGate.complete();
    await Future.wait([first, second, stopped]);

    expect(client.calls, [
      'started:channel-1:live-session-1:source-1:live-stream-1:Transcode',
      'stopped:channel-1:live-session-1:source-1:live-stream-1',
    ]);
  });

  test('stopping before the first heartbeat still reports the negotiated live identity', () async {
    final client = _FakeJellyfinClient();
    final tracker = JellyfinLiveSessionTracker(
      playSessionId: 'live-session-1',
      mediaSourceId: 'source-1',
      liveStreamId: 'live-stream-1',
    );

    await tracker.report(
      client: client,
      itemId: 'channel-1',
      state: 'stopped',
      position: Duration.zero,
      duration: Duration.zero,
    );

    expect(client.calls, ['stopped:channel-1:live-session-1:source-1:live-stream-1']);
  });
}
