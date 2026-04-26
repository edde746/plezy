import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/live_session_tracker.dart';

class _FakeJellyfinClient implements JellyfinClient {
  final calls = <String>[];
  final startGate = Completer<void>();

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
    await startGate.future;
    calls.add('started:$itemId:$playSessionId');
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
    calls.add('${isPaused ? 'paused' : 'playing'}:$itemId:$playSessionId');
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) async {
    calls.add('stopped:$itemId:$playSessionId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('coalesces duplicate live starts and orders stop after in-flight start', () async {
    final client = _FakeJellyfinClient();
    final tracker = JellyfinLiveSessionTracker(playSessionId: 'live-session-1');

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

    expect(client.calls, ['started:channel-1:live-session-1', 'stopped:channel-1:live-session-1']);
  });
}
