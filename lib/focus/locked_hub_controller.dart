/// Manages focus memory for hub navigation.
///
/// Tracks two things:
/// 1. Per-hub memory: Each hub remembers which item was last focused
/// 2. Global column hint: When entering a hub that hasn't been visited,
///    we use the column position from the last focused hub as a hint
class HubFocusMemory {
  static final Map<String, int> _perHubMemory = {};
  static int _lastColumnHint = 0;

  /// Remember the focused index for a specific hub
  static void setForHub(String hubKey, int index) {
    _perHubMemory[hubKey] = index;
    _lastColumnHint = index;
  }

  /// Get the remembered index for a hub, or fall back to column hint
  static int getForHub(String hubKey, int itemCount) {
    if (itemCount <= 0) return 0;

    // If this hub has memory, use it
    if (_perHubMemory.containsKey(hubKey)) {
      return _perHubMemory[hubKey]!.clamp(0, itemCount - 1);
    }

    // Otherwise use the last column hint (clamped to this hub's item count)
    return _lastColumnHint.clamp(0, itemCount - 1);
  }

  /// Clear all memory (e.g., when leaving a screen)
  static void clear() {
    _perHubMemory.clear();
    _lastColumnHint = 0;
  }
}
