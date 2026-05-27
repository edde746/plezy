/// Mixin for players that stream subtitle text for Flutter overlay rendering.
/// Used by PlayerTizen, where video renders in a native overlay window.
abstract interface class SubtitleStreamSupport {
  Stream<String> get subtitleTextStream;

  /// Secondary subtitle stream for dual-subtitle rendering.
  /// Emits empty string when no secondary subtitle is active.
  Stream<String> get secondarySubtitleTextStream;
}
