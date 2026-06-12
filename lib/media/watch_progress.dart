/// Single source of truth for the "progress crossed the watched threshold"
/// decision. All comparison sites (online progress events, external-player
/// returns, offline queueing) must route through this so edge-case handling
/// (zero/unknown duration, exact-threshold) can't drift between paths.
bool isWatchedProgress({required int positionMs, required int durationMs, required double threshold}) {
  if (durationMs <= 0) return false;
  return positionMs / durationMs >= threshold;
}
