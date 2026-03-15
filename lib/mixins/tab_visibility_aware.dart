/// Mixin for screens that need to react to tab visibility changes.
///
/// Used by MainScreen to pause expensive work (e.g. animation tickers)
/// when the screen's tab is no longer visible, and resume it when shown again.
mixin TabVisibilityAware {
  void onTabShown();
  void onTabHidden();
}
