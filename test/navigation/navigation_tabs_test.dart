import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/navigation/navigation_tabs.dart';

void main() {
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
