import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';

/// Navigation tab identifiers
enum NavigationTabId { discover, libraries, search, downloads, settings }

/// Represents a navigation tab with its configuration
class NavigationTab {
  final NavigationTabId id;
  final bool onlineOnly;
  final IconData icon;
  final String Function() getLabel;

  const NavigationTab({required this.id, required this.onlineOnly, required this.icon, required this.getLabel});

  NavigationDestination toDestination() {
    return NavigationDestination(icon: AppIcon(icon, fill: 1), selectedIcon: AppIcon(icon, fill: 1), label: getLabel());
  }

  /// Get the index for a tab ID in the visible tabs list
  static int indexFor(NavigationTabId id, {required bool isOffline}) {
    final tabs = getVisibleTabs(isOffline: isOffline);
    return tabs.indexWhere((tab) => tab.id == id);
  }

  /// Get tabs filtered by offline mode
  static List<NavigationTab> getVisibleTabs({required bool isOffline}) {
    return allNavigationTabs.where((tab) => !isOffline || !tab.onlineOnly).toList();
  }

  /// Check if a visual index corresponds to a specific tab ID
  static bool isTabAtIndex(NavigationTabId id, int index, {required bool isOffline}) {
    return indexFor(id, isOffline: isOffline) == index;
  }
}

// Label getters (must be top-level for const constructor)
String _getHomeLabel() => t.common.home;
String _getLibrariesLabel() => t.navigation.libraries;
String _getSearchLabel() => t.common.search;
String _getDownloadsLabel() => t.navigation.downloads;
String _getSettingsLabel() => t.common.settings;

/// All navigation tabs in display order
const allNavigationTabs = [
  NavigationTab(id: NavigationTabId.discover, onlineOnly: true, icon: Symbols.home_rounded, getLabel: _getHomeLabel),
  NavigationTab(
    id: NavigationTabId.libraries,
    onlineOnly: true,
    icon: Symbols.video_library_rounded,
    getLabel: _getLibrariesLabel,
  ),
  NavigationTab(id: NavigationTabId.search, onlineOnly: true, icon: Symbols.search_rounded, getLabel: _getSearchLabel),
  NavigationTab(
    id: NavigationTabId.downloads,
    onlineOnly: false,
    icon: Symbols.download_rounded,
    getLabel: _getDownloadsLabel,
  ),
  NavigationTab(
    id: NavigationTabId.settings,
    onlineOnly: false,
    icon: Symbols.settings_rounded,
    getLabel: _getSettingsLabel,
  ),
];
