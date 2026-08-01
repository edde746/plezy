mixin Refreshable {
  void refresh();
}

mixin FullRefreshable {
  void fullRefresh();
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
