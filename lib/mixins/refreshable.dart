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
  void setSearchQuery(String query);
}

mixin LibraryLoadable {
  void loadLibraryByKey(String libraryGlobalKey);
}
