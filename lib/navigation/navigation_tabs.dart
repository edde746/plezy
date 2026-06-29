import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../utils/platform_detector.dart';

/// Navigation tab identifiers
enum NavigationTabId { discover, libraries, liveTv, search, seerr, downloads, settings }

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
  static int indexFor(NavigationTabId id, {required bool isOffline, bool hasLiveTv = false, bool hasSeerr = false}) {
    final tabs = getVisibleTabs(isOffline: isOffline, hasLiveTv: hasLiveTv, hasSeerr: hasSeerr);
    return tabs.indexWhere((tab) => tab.id == id);
  }

  /// Get tabs filtered by offline mode and feature availability
  static List<NavigationTab> getVisibleTabs({required bool isOffline, bool hasLiveTv = false, bool hasSeerr = false}) {
    return allNavigationTabs.where((tab) {
      if (isOffline && tab.onlineOnly) return false;
      if (tab.id == NavigationTabId.liveTv && !hasLiveTv) return false;
      if (tab.id == NavigationTabId.seerr && !hasSeerr) return false;
      if (tab.id == NavigationTabId.downloads && PlatformDetector.isAppleTV()) return false;
      return true;
    }).toList();
  }

  /// Resolve which tab the app should open to on launch.
  ///
  /// Offline mode prefers Downloads when available. Online, honours the user's
  /// [preferredStartup] section when it is currently visible, otherwise falls
  /// back to the first visible tab (Home).
  static NavigationTabId resolveDefaultTab({
    required bool isOffline,
    required bool hasLiveTv,
    bool hasSeerr = false,
    required NavigationTabId? preferredStartup,
  }) {
    final tabs = getVisibleTabs(isOffline: isOffline, hasLiveTv: hasLiveTv, hasSeerr: hasSeerr);
    if (isOffline && tabs.any((t) => t.id == NavigationTabId.downloads)) {
      return NavigationTabId.downloads;
    }
    if (preferredStartup != null && tabs.any((t) => t.id == preferredStartup)) {
      return preferredStartup;
    }
    return tabs.first.id;
  }
}

// Label getters (must be top-level for const constructor)
String _getHomeLabel() => t.common.home;
String _getLibrariesLabel() => t.navigation.libraries;
String _getLiveTvLabel() => t.navigation.liveTv;
String _getSearchLabel() => t.common.search;
String _getSeerrLabel() => t.seerr.tab;
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
  NavigationTab(id: NavigationTabId.liveTv, onlineOnly: true, icon: Symbols.live_tv_rounded, getLabel: _getLiveTvLabel),
  NavigationTab(id: NavigationTabId.search, onlineOnly: true, icon: Symbols.search_rounded, getLabel: _getSearchLabel),
  NavigationTab(
    id: NavigationTabId.seerr,
    onlineOnly: true,
    icon: Symbols.playlist_add_check_rounded,
    getLabel: _getSeerrLabel,
  ),
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
