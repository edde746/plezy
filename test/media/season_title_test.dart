import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/i18n/strings.g.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_item_types.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/season_title.dart';

/// Pins the #1271 behavior: a server's generic English "Season N" title is
/// re-localized to the current app locale, while custom / already-localized
/// names pass through untouched.
void main() {
  // Locales are lazy-loaded, so the non-base locale must be set asynchronously.
  setUpAll(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDownAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  MediaItem season({String? title, int? index}) => MediaItem(
    id: 'sn',
    backend: MediaBackend.plex,
    kind: MediaKind.season,
    title: title,
    index: index,
    parentTitle: 'Scrubs',
    serverId: 's1',
  );

  group('localizedSeasonLabel (fr locale)', () {
    test('generic English "Season N" is re-localized', () {
      expect(localizedSeasonLabel(title: 'Season 3', index: 3), 'Saison 3');
    });

    test('case-insensitive match', () {
      expect(localizedSeasonLabel(title: 'SEASON 1', index: 1), 'Saison 1');
    });

    test('index is preferred over the number parsed from the title', () {
      expect(localizedSeasonLabel(title: 'Season 99', index: 5), 'Saison 5');
    });

    test('falls back to digits parsed from the title when index is null', () {
      expect(localizedSeasonLabel(title: 'Season 3'), 'Saison 3');
    });

    test('empty title with an index is localized', () {
      expect(localizedSeasonLabel(title: '', index: 5), 'Saison 5');
      expect(localizedSeasonLabel(title: null, index: 5), 'Saison 5');
    });

    test('already-localized title is preserved', () {
      expect(localizedSeasonLabel(title: 'Saison 3', index: 3), 'Saison 3');
    });

    test('custom season name is preserved', () {
      expect(localizedSeasonLabel(title: 'Specials', index: 0), 'Specials');
      expect(localizedSeasonLabel(title: 'The Lost Episodes', index: 1), 'The Lost Episodes');
    });

    test('nothing usable falls back to the provided fallback', () {
      expect(localizedSeasonLabel(title: null, index: null, fallback: 'Unknown Season'), 'Unknown Season');
      expect(localizedSeasonLabel(title: '  ', index: null), '');
    });
  });

  group('MediaItem.localizedSeasonTitle', () {
    test('re-localizes a generic season title', () {
      expect(season(title: 'Season 2', index: 2).localizedSeasonTitle, 'Saison 2');
    });

    test('falls back to displayTitle when there is no usable title or index', () {
      // displayTitle for a season prefers the show name (parentTitle).
      expect(season(title: null, index: null).localizedSeasonTitle, 'Scrubs');
    });
  });
}
