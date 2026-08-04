mixin Refreshable {
  void refresh();
}

mixin FullRefreshable {
  void fullRefresh();

  /// Online-entry variant, used by `main_screen._primeOnlineServices` on cold
  /// start and on reconnect-from-offline. Its job is to guarantee the tab
  /// loads once servers are up — not to force a refetch.
  ///
  /// Screens that already kick off their own load in `initState` override this
  /// to skip while that pass is still in flight; otherwise the prime queues an
  /// identical trailing pass and the tab fetches everything twice (#1784).
  /// Profile switches go through [fullRefresh] instead, which always refetches.
  void primeRefresh() => fullRefresh();
}

mixin FocusableTab {
  void focusActiveTabIfReady();
}

mixin SearchInputFocusable {
  void focusSearchInput();

  /// Apply a complete query submitted from outside the field (e.g. the Plezy
  /// companion remote): run the search and land focus on the results without
  /// leaving the TV on-screen keyboard open.
  void submitSearchQuery(String query);
}

mixin LibraryLoadable {
  void loadLibraryByKey(String libraryGlobalKey);
}
