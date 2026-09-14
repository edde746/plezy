/// Manages focus memory for one browse surface.
///
/// Tracks two things:
/// 1. Per-hub memory: Each hub remembers which item was last focused
/// 2. Last column hint: When entering a hub that hasn't been visited,
///    we use the column position from the last focused hub as a hint
class HubFocusMemory {
  final Map<String, int> _perHubMemory = {};
  int _lastColumnHint = 0;

  void setForHub(String hubKey, int index) {
    _perHubMemory[hubKey] = index;
    _lastColumnHint = index;
  }

  /// Get the remembered index for a hub, or fall back to column hint
  int getForHub(String hubKey, int itemCount) {
    if (itemCount <= 0) return 0;

    // If this hub has memory, use it
    if (_perHubMemory.containsKey(hubKey)) {
      return _perHubMemory[hubKey]!.clamp(0, itemCount - 1);
    }

    // Otherwise use the last column hint (clamped to this hub's item count)
    return _lastColumnHint.clamp(0, itemCount - 1);
  }

  /// Get only this hub's remembered index, without falling back to the last column hint.
  int getForHubOnly(String hubKey, int itemCount, {int fallback = 0}) {
    if (itemCount <= 0) return 0;
    final remembered = _perHubMemory[hubKey];
    return (remembered ?? fallback).clamp(0, itemCount - 1);
  }

  /// Rewrite a hub's remembered index in place after its content reordered
  /// underneath it (a Continue Watching refresh, not user navigation). Unlike
  /// [setForHub] this never moves the cross-hub column hint, and it is a no-op
  /// for hubs without memory.
  void remapForHub(String hubKey, int index) {
    if (_perHubMemory.containsKey(hubKey)) _perHubMemory[hubKey] = index;
  }
}
