import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/services/media_browser_paths.dart';

/// Route table for the endpoints where the two MediaBrowser dialects diverge.
///
/// Every Emby expectation below was measured against Emby 4.9.5; the Jellyfin
/// spelling of the same route returns 404 there (500 for `/Users/Me`, which
/// binds `Me` as a user id). These are the exact strings the client sends, so a
/// regression here is a silent loss of watch state or Continue Watching.
void main() {
  const jellyfin = MediaBrowserPaths(dialect: MediaBrowserDialect.jellyfin, userId: 'user-1');
  const emby = MediaBrowserPaths(dialect: MediaBrowserDialect.emby, userId: 'user-1');

  group('Jellyfin uses the 10.9+ unprefixed routes', () {
    test('current user', () => expect(jellyfin.currentUser, '/Users/Me'));
    test('resume', () => expect(jellyfin.resumeItems, '/UserItems/Resume'));
    test('played', () => expect(jellyfin.playedItem('item-9'), '/UserPlayedItems/item-9'));
    test('favorite', () => expect(jellyfin.favoriteItem('item-9'), '/UserFavoriteItems/item-9'));
    test('rating', () => expect(jellyfin.itemRating('item-9'), '/UserItems/item-9/Rating'));
    test('trailers', () => expect(jellyfin.localTrailers('item-9'), '/Items/item-9/LocalTrailers'));
    test('extras', () => expect(jellyfin.specialFeatures('item-9'), '/Items/item-9/SpecialFeatures'));
  });

  group('Emby uses the original user-scoped routes', () {
    test('current user', () => expect(emby.currentUser, '/Users/user-1'));
    test('resume', () => expect(emby.resumeItems, '/Users/user-1/Items/Resume'));
    test('played', () => expect(emby.playedItem('item-9'), '/Users/user-1/PlayedItems/item-9'));
    test('favorite', () => expect(emby.favoriteItem('item-9'), '/Users/user-1/FavoriteItems/item-9'));
    test('rating', () => expect(emby.itemRating('item-9'), '/Users/user-1/Items/item-9/Rating'));
    test('trailers', () => expect(emby.localTrailers('item-9'), '/Users/user-1/Items/item-9/LocalTrailers'));
    test('extras', () => expect(emby.specialFeatures('item-9'), '/Users/user-1/Items/item-9/SpecialFeatures'));
  });

  group('path segment encoding', () {
    test('item ids are percent-encoded so a hostile id cannot escape the path', () {
      expect(emby.playedItem('a/b?c'), '/Users/user-1/PlayedItems/a%2Fb%3Fc');
      expect(jellyfin.playedItem('a/b?c'), '/UserPlayedItems/a%2Fb%3Fc');
    });

    test('user ids are percent-encoded in the user-scoped forms', () {
      const hostile = MediaBrowserPaths(dialect: MediaBrowserDialect.emby, userId: 'u/1');
      expect(hostile.currentUser, '/Users/u%2F1');
      expect(hostile.resumeItems, '/Users/u%2F1/Items/Resume');
    });

    test('Emby item ids are opaque numeric strings and pass through unchanged', () {
      // Emby ids look like "7330"; Jellyfin's are 32-char hex GUIDs. Both are
      // treated as opaque.
      expect(emby.playedItem('7330'), '/Users/user-1/PlayedItems/7330');
    });
  });
}
