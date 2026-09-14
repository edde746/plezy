/// Monotonic milliseconds for every sync-layer timestamp: ping send times,
/// expectation deadlines, state anchors, and the host's pong clock.
///
/// Anchored to the wall clock once so values look like epoch milliseconds in
/// logs, then advanced by a [Stopwatch]. A wall-clock step (NTP correction,
/// manual time change, time zone fix) must not move this clock: a guest that
/// stepped 800 ms forward mid-session would otherwise read every anchor as
/// 800 ms stale and hard-seek the whole file forward, and a host's pongs
/// would poison every guest's offset window. Only differences between two
/// readings of the same peer's clock are ever used, so the base is arbitrary.
/// Deep sleep can pause the stopwatch on some platforms; the offset window
/// re-converges after wake exactly as it does for any other clock jump.
int watchTogetherSystemNowMs() => _monotonicBaseMs + _monotonic.elapsedMilliseconds;

final int _monotonicBaseMs = DateTime.now().millisecondsSinceEpoch;
final Stopwatch _monotonic = Stopwatch()..start();

bool orderedStringListsEqual(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}
