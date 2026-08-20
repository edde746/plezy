/// Routes vertical D-pad movement between ordered hub rows.
///
/// A valid target and the bottom boundary are consumed. The top boundary can
/// either invoke an explicit focus handoff or propagate to the row's
/// `onNavigateUp` callback.
bool navigateVerticalHubRows({
  required int hubCount,
  required int hubIndex,
  required bool isUp,
  required void Function(int targetIndex) requestFocus,
  void Function()? onTopBoundary,
  void Function()? onBottomBoundary,
  bool propagateTopBoundary = false,
}) {
  if (hubCount <= 0) return false;

  final targetIndex = isUp ? hubIndex - 1 : hubIndex + 1;
  if (targetIndex < 0) {
    if (onTopBoundary != null) {
      onTopBoundary();
      return true;
    }
    return !propagateTopBoundary;
  }

  if (targetIndex >= hubCount) {
    onBottomBoundary?.call();
    return true;
  }

  requestFocus(targetIndex);
  return true;
}
