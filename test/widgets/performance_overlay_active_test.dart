import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/widgets/video_controls/widgets/performance_overlay/performance_overlay.dart';

/// Player fake that only counts how often the overlay polls it.
class _CountingStatsPlayer implements Player {
  int statsCalls = 0;

  @override
  final PlayerStreams streams = const PlayerStreams(
    playing: Stream.empty(),
    completed: Stream.empty(),
    buffering: Stream.empty(),
    position: Stream.empty(),
    duration: Stream.empty(),
    seekable: Stream.empty(),
    buffer: Stream.empty(),
    volume: Stream.empty(),
    rate: Stream.empty(),
    tracks: Stream.empty(),
    track: Stream.empty(),
    log: Stream.empty(),
    error: Stream.empty(),
    audioDevice: Stream.empty(),
    audioDevices: Stream.empty(),
    bufferRanges: Stream.empty(),
    playbackRestart: Stream.empty(),
    fileStarted: Stream.empty(),
    fileLoaded: Stream.empty(),
    fileLoadFailed: Stream.empty(),
    primaryMediaReady: Stream.empty(),
    backendSwitched: Stream.empty(),
  );

  @override
  bool get providesNativeStats => true;

  @override
  Future<Map<String, dynamic>> getStats() async {
    statsCalls++;
    return {'playerType': 'mpv', 'demuxer-cache-state': '{"fw-bytes":12582912}'};
  }

  @override
  Future<String> runtimePlayerType() async => 'mpv';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('an auto-hidden overlay stops polling and resumes when it comes back', (tester) async {
    // Auto-hide only fades the card; the State stays mounted, so without the
    // `active` gate the 500 ms poll kept issuing ~37 blocking native property
    // reads per tick behind a fully transparent widget.
    final player = _CountingStatsPlayer();

    await tester.pumpWidget(wrap(PlayerPerformanceOverlay(player: player, active: false)));
    await tester.pump(const Duration(seconds: 2));

    expect(player.statsCalls, 0);

    await tester.pumpWidget(wrap(PlayerPerformanceOverlay(player: player, active: true)));
    await tester.pump(const Duration(seconds: 2));

    final whileVisible = player.statsCalls;
    expect(whileVisible, greaterThan(1));

    // Hiding it again has to stop the timer, not merely skip a tick.
    await tester.pumpWidget(wrap(PlayerPerformanceOverlay(player: player, active: false)));
    await tester.pump(const Duration(seconds: 2));

    expect(player.statsCalls, whileVisible);

    await tester.pumpWidget(wrap(const SizedBox.shrink()));
  });
}
