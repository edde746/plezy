import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/home_layout_sync_service.dart';

void main() {
  test('synced prefs keep their concrete types (no erased JsonPref.encode)', () {
    expect(HomeLayoutSyncService.debugSyncedPrefTypesForTesting(), everyElement(isNot(contains('dynamic'))));
  });

  group('changedSinceSnapshot', () {
    final saved = jsonEncode({
      'home_row_order': ['a', 'b'],
      'show_hero_section': true,
    });

    test('same values are not a change', () {
      expect(
        HomeLayoutSyncService.changedSinceSnapshot(saved, {
          'home_row_order': ['a', 'b'],
          'show_hero_section': true,
        }),
        isFalse,
      );
    });

    test('an edited value is a change', () {
      expect(
        HomeLayoutSyncService.changedSinceSnapshot(saved, {
          'home_row_order': ['b', 'a'],
          'show_hero_section': true,
        }),
        isTrue,
      );
    });

    test('a pref newly added to the synced list is not a change', () {
      expect(
        HomeLayoutSyncService.changedSinceSnapshot(saved, {
          'home_row_order': ['a', 'b'],
          'show_hero_section': true,
          'hide_watched_in_hubs': false,
        }),
        isFalse,
      );
    });

    test('no saved snapshot is not a change', () {
      expect(HomeLayoutSyncService.changedSinceSnapshot('', {'home_row_order': <String>[]}), isFalse);
    });
  });
}
