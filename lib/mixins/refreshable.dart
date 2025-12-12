mixin Refreshable {
  void refresh();
}

/// Mixin for screens that support full refresh (clearing all cached data)
mixin FullRefreshable {
  void fullRefresh();
}

/// Mixin for screens with focusable tab content
mixin FocusableTab {
  void focusActiveTabIfReady();
}

/// Mixin for screens with focusable search input
mixin SearchInputFocusable {
  void focusSearchInput();
}

/// Mixin for screens that can load a specific library by key
mixin LibraryLoadable {
  void loadLibraryByKey(String libraryGlobalKey);
}
