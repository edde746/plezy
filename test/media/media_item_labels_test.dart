import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/app_locale_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_item_labels.dart';
import 'package:plezy/media/media_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async {
    AppLocaleEnvironment.debugDeviceLocales = null;
    await LocaleSettings.setLocale(AppLocale.en);
  });
  MediaItem item({
    MediaKind kind = MediaKind.movie,
    String? grandparentTitle,
    int? parentIndex,
    int? index,
    int? year,
    String? editionTitle,
  }) => MediaItem.plex(
    id: 'item',
    kind: kind,
    grandparentTitle: grandparentTitle,
    parentIndex: parentIndex,
    index: index,
    year: year,
    editionTitle: editionTitle,
  );

  test('formats episodes with show and season/episode numbers', () {
    expect(
      formatQueueItemSubtitle(item(kind: MediaKind.episode, grandparentTitle: 'Show', parentIndex: 2, index: 3)),
      'Show \u00b7 S2E3',
    );
  });

  test('falls back through show, year and edition, then media kind', () {
    expect(formatQueueItemSubtitle(item(grandparentTitle: 'Show')), 'Show');
    expect(formatQueueItemSubtitle(item(year: 2026, editionTitle: 'Director Cut')), '2026 \u00b7 Director Cut');
    expect(formatQueueItemSubtitle(item(year: 2026)), '2026');
    expect(formatQueueItemSubtitle(item()), t.common.mediaKind.movie);
  });

  test('Arabic queue subtitles localize episode labels and year digits', () async {
    AppLocaleEnvironment.debugDeviceLocales = const [Locale('ar', 'EG')];
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(
      formatQueueItemSubtitle(item(kind: MediaKind.episode, grandparentTitle: 'Show', parentIndex: 2, index: 3)),
      'Show · م٢ ح٣',
    );
    expect(formatQueueItemSubtitle(item(year: 2026, editionTitle: 'Director Cut')), '٢٠٢٦ · Director Cut');
  });
}
