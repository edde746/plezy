import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/navigation/navigation_tabs.dart';

void main() {
  group('NavigationTabId enum', () {
    test('contains watchlist between downloads and settings', () {
      expect(NavigationTabId.values.indexOf(NavigationTabId.watchlist),
          NavigationTabId.values.indexOf(NavigationTabId.downloads) + 1);
      expect(
          NavigationTabId.values.indexOf(NavigationTabId.watchlist),
          NavigationTabId.values.indexOf(NavigationTabId.settings) - 1,
      );
    });
  });

  group('allNavigationTabs', () {
    test('includes watchlist with onlineOnly: false', () {
      final watchlistTab = allNavigationTabs.where((t) => t.id == NavigationTabId.watchlist);
      expect(watchlistTab, hasLength(1));
      expect(watchlistTab.first.onlineOnly, isFalse);
    });

    test('watchlist is positioned between downloads and settings', () {
      final ids = allNavigationTabs.map((t) => t.id).toList();
      final watchlistIdx = ids.indexOf(NavigationTabId.watchlist);
      final downloadsIdx = ids.indexOf(NavigationTabId.downloads);
      final settingsIdx = ids.indexOf(NavigationTabId.settings);
      expect(watchlistIdx, greaterThan(downloadsIdx));
      expect(watchlistIdx, lessThan(settingsIdx));
    });
  });

  group('NavigationTab.getVisibleTabs', () {
    test('includes watchlist when online', () {
      final tabs = NavigationTab.getVisibleTabs(isOffline: false, hasLiveTv: false);
      expect(tabs.any((t) => t.id == NavigationTabId.watchlist), isTrue);
    });

    test('includes watchlist when offline (onlineOnly: false)', () {
      final tabs = NavigationTab.getVisibleTabs(isOffline: true, hasLiveTv: false);
      expect(tabs.any((t) => t.id == NavigationTabId.watchlist), isTrue);
    });
  });

  group('NavigationTab.indexFor', () {
    test('returns correct index for watchlist', () {
      final idx = NavigationTab.indexFor(NavigationTabId.watchlist,
          isOffline: false, hasLiveTv: false);
      expect(idx, isNonNegative);
      final tabs = NavigationTab.getVisibleTabs(isOffline: false, hasLiveTv: false);
      expect(tabs[idx].id, NavigationTabId.watchlist);
    });
  });

  group('NavigationTab.resolveDefaultTab', () {
    test('offline prefers Downloads when available', () {
      expect(
        NavigationTab.resolveDefaultTab(isOffline: true, hasLiveTv: false, preferredStartup: null),
        NavigationTabId.downloads,
      );
    });

    test('offline ignores an online-only preferred section', () {
      expect(
        NavigationTab.resolveDefaultTab(isOffline: true, hasLiveTv: true, preferredStartup: NavigationTabId.liveTv),
        NavigationTabId.downloads,
      );
    });

    test('online honours the preferred section when it is visible', () {
      expect(
        NavigationTab.resolveDefaultTab(isOffline: false, hasLiveTv: true, preferredStartup: NavigationTabId.liveTv),
        NavigationTabId.liveTv,
      );
      expect(
        NavigationTab.resolveDefaultTab(isOffline: false, hasLiveTv: false, preferredStartup: NavigationTabId.search),
        NavigationTabId.search,
      );
    });

    test('online falls back to Home when preferred Live TV is unavailable', () {
      expect(
        NavigationTab.resolveDefaultTab(isOffline: false, hasLiveTv: false, preferredStartup: NavigationTabId.liveTv),
        NavigationTabId.discover,
      );
    });

    test('online defaults to Home when no preference is set', () {
      expect(
        NavigationTab.resolveDefaultTab(isOffline: false, hasLiveTv: true, preferredStartup: null),
        NavigationTabId.discover,
      );
    });
  });
}
