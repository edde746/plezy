import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_library.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

PlexLibrary _lib(String key, {String type = 'movie', String? serverId, String title = 'L'}) =>
    PlexLibrary(key: key, title: title, type: type, serverId: serverId);

void main() {
  setUp(resetSharedPreferencesForTest);

  group('LibrariesProvider', () {
    test('starts with initial empty state', () {
      final p = LibrariesProvider();
      expect(p.libraries, isEmpty);
      expect(p.hasLibraries, isFalse);
      expect(p.isLoading, isFalse);
      expect(p.hasLoaded, isFalse);
      expect(p.loadState, LibrariesLoadState.initial);
      expect(p.errorMessage, isNull);
      p.dispose();
    });

    test('loadLibraries before initialize is a no-op', () async {
      final p = LibrariesProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.loadLibraries();

      // Without a DataAggregationService the load short-circuits with no
      // state transition and no listener notification.
      expect(p.loadState, LibrariesLoadState.initial);
      expect(p.libraries, isEmpty);
      expect(notified, 0);

      p.dispose();
    });

    test('refresh before initialize is a no-op', () async {
      final p = LibrariesProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.refresh();
      expect(p.loadState, LibrariesLoadState.initial);
      expect(notified, 0);

      p.dispose();
    });

    test('updateLibraryOrder updates list, notifies, and persists order', () async {
      final p = LibrariesProvider();
      var notified = 0;
      p.addListener(() => notified++);

      final libs = [
        _lib('1', serverId: 'srv', title: 'A'),
        _lib('2', serverId: 'srv', title: 'B'),
        _lib('3', serverId: 'srv', title: 'C'),
      ];

      await p.updateLibraryOrder(libs);
      expect(p.libraries.length, 3);
      expect(p.libraries.map((l) => l.title), ['A', 'B', 'C']);
      expect(notified, 1);

      // Persisted to storage as the list of globalKeys.
      final storage = await StorageService.getInstance();
      expect(storage.getLibraryOrder(), equals(libs.map((l) => l.globalKey).toList()));

      p.dispose();
    });

    test('libraries getter returns an unmodifiable list', () async {
      final p = LibrariesProvider();
      await p.updateLibraryOrder([_lib('1', serverId: 'srv')]);
      expect(() => p.libraries.add(_lib('mutated')), throwsUnsupportedError);
      p.dispose();
    });

    test('clear resets state to initial and notifies', () async {
      final p = LibrariesProvider();
      await p.updateLibraryOrder([_lib('1', serverId: 'srv'), _lib('2', serverId: 'srv')]);
      expect(p.libraries, hasLength(2));

      var notified = 0;
      p.addListener(() => notified++);

      p.clear();
      expect(p.libraries, isEmpty);
      expect(p.hasLibraries, isFalse);
      expect(p.loadState, LibrariesLoadState.initial);
      expect(p.errorMessage, isNull);
      expect(notified, 1);

      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = LibrariesProvider();
      p.dispose();
      // Post-dispose clear / updateLibraryOrder must not throw — the provider
      // uses `safeNotifyListeners` which swallows post-dispose firings.
      p.clear();
      await p.updateLibraryOrder([_lib('1', serverId: 'srv')]);
    });
  });
}
