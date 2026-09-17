import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/screens/video_player/live_tv_session_state.dart';

void main() {
  test('resolving a new stream never reports its requested target as reached', () {
    final state = LiveTvSessionState(null);
    final initial = state.beginClockOpen(1000);
    state.bindClockOpen(initial, 1);
    state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration(seconds: 52)));
    expect(state.playbackPosition(const Duration(seconds: 62)).epoch, 1010);

    final next = state.beginClockOpen(1500);
    // Old-stream position events and pending requests are different facts.
    expect(state.playbackPosition(const Duration(seconds: 63)).epoch, 1010);
    state.failClockOpen(next);
    expect(state.playbackPosition(const Duration(seconds: 62)).epoch, 1010);
  });
}
