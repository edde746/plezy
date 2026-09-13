import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/plex/plex_subtitle_search_result.dart';
import 'package:plezy/services/subtitle_auto_download.dart';

MediaSubtitleTrack _track(int id, {String? language, String? languageCode}) => MediaSubtitleTrack(
  id: id,
  index: id,
  language: language,
  languageCode: languageCode,
  selected: false,
  forced: false,
);

PlexSubtitleSearchResult _result(
  String key, {
  double? score,
  bool perfectMatch = false,
  bool hearingImpaired = false,
  bool forced = false,
  String? languageCode,
}) => PlexSubtitleSearchResult(
  id: key.hashCode,
  key: key,
  score: score,
  languageCode: languageCode,
  hearingImpaired: hearingImpaired,
  perfectMatch: perfectMatch,
  downloaded: false,
  forced: forced,
);

void main() {
  group('needsSubtitleDownload', () {
    test('an item with no subtitle rows needs one', () {
      expect(needsSubtitleDownload(const [], 'en'), isTrue);
    });

    test('a matching row means nothing to fetch', () {
      expect(needsSubtitleDownload([_track(1, languageCode: 'eng')], 'en'), isFalse);
    });

    test('matches on the display language when the code is missing', () {
      expect(needsSubtitleDownload([_track(1, language: 'en')], 'eng'), isFalse);
    });

    test('a region variant still counts as a match', () {
      expect(needsSubtitleDownload([_track(1, languageCode: 'en-US')], 'en'), isFalse);
    });

    test('another language does not satisfy the preference', () {
      expect(needsSubtitleDownload([_track(1, languageCode: 'fre')], 'en'), isTrue);
    });

    test('a lookalike code does not satisfy the preference', () {
      // `est` (Estonian) must not pass for `es` (Spanish) — the bug a prefix
      // compare would introduce.
      expect(needsSubtitleDownload([_track(1, languageCode: 'est')], 'es'), isTrue);
    });

    test('an unset preference never triggers a search', () {
      expect(needsSubtitleDownload(const [], ''), isFalse);
    });
  });

  group('pickBestSubtitleResult', () {
    test('nothing to pick from', () {
      expect(pickBestSubtitleResult(const []), isNull);
    });

    test('takes the highest score when nothing stronger separates them', () {
      final best = pickBestSubtitleResult([_result('a', score: 3), _result('b', score: 9), _result('c', score: 5)]);
      expect(best?.key, 'b');
    });

    test('a perfect match beats a better-scored guess', () {
      // The "Target (1985)" case: a provider is confident about a subtitle for
      // a different film that happens to share the title. Only perfectMatch
      // comes from the file itself.
      final best = pickBestSubtitleResult([
        _result('confident-but-wrong', score: 99),
        _result('hash-match', score: 4, perfectMatch: true),
      ]);
      expect(best?.key, 'hash-match');
    });

    test('the requested language beats a better-scored other language', () {
      final best = pickBestSubtitleResult([
        _result('german', score: 90, languageCode: 'deu'),
        _result('english', score: 10, languageCode: 'eng'),
      ], language: 'en');
      expect(best?.key, 'english');
    });

    test('a result that declares no language stays eligible', () {
      final best = pickBestSubtitleResult([_result('unlabelled', score: 10)], language: 'en');
      expect(best?.key, 'unlabelled');
    });

    test('full dialogue beats a better-scored forced or SDH track', () {
      final best = pickBestSubtitleResult([
        _result('forced', score: 80, forced: true),
        _result('sdh', score: 70, hearingImpaired: true),
        _result('full', score: 10),
      ]);
      expect(best?.key, 'full');
    });

    test('forced and SDH remain eligible when nothing else is on offer', () {
      final best = pickBestSubtitleResult([_result('sdh', score: 1, hearingImpaired: true)]);
      expect(best?.key, 'sdh');
    });

    test('score still breaks a tie between equally strong results', () {
      final best = pickBestSubtitleResult([
        _result('a', score: 7, perfectMatch: true),
        _result('b', score: 9, perfectMatch: true),
      ]);
      expect(best?.key, 'b');
    });

    test('a missing score sorts as zero rather than throwing', () {
      final best = pickBestSubtitleResult([_result('a'), _result('b', score: 1)]);
      expect(best?.key, 'b');
    });

    test('skips results with no download key', () {
      final best = pickBestSubtitleResult([_result('', score: 10), _result('b', score: 1)]);
      expect(best?.key, 'b');
    });
  });
}
