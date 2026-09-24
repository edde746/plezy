import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/track_language_match.dart';

void main() {
  group('trackLanguageMatches', () {
    test('matches an exact ISO code', () {
      expect(trackLanguageMatches(query: 'eng', language: 'eng'), isTrue);
    });

    test('matches a full language name against an ISO 639-2 code', () {
      // mpv reports "eng"; a person says "english".
      expect(trackLanguageMatches(query: 'english', language: 'eng'), isTrue);
      expect(trackLanguageMatches(query: 'hebrew', language: 'heb'), isTrue);
      expect(trackLanguageMatches(query: 'spanish', language: 'spa'), isTrue);
    });

    test('matches a full language name against an ISO 639-1 code', () {
      expect(trackLanguageMatches(query: 'english', language: 'en'), isTrue);
    });

    test('matches a short code against a longer track language', () {
      expect(trackLanguageMatches(query: 'en', language: 'eng'), isTrue);
    });

    test('matches names whose ISO 639-2/B code shares no prefix', () {
      expect(trackLanguageMatches(query: 'japanese', language: 'jpn'), isTrue);
      expect(trackLanguageMatches(query: 'romanian', language: 'rum'), isTrue);
      expect(trackLanguageMatches(query: 'german', language: 'ger'), isTrue);
      expect(trackLanguageMatches(query: 'dutch', language: 'dut'), isTrue);
    });

    test('falls back to the track title when the language field is absent', () {
      expect(trackLanguageMatches(query: 'english', title: 'English SDH'), isTrue);
    });

    test('does not match an unrelated language', () {
      expect(trackLanguageMatches(query: 'english', language: 'heb'), isFalse);
      expect(trackLanguageMatches(query: 'hebrew', language: 'eng'), isFalse);
    });

    test('does not match on an empty query', () {
      expect(trackLanguageMatches(query: '', language: 'eng'), isFalse);
      expect(trackLanguageMatches(query: '   ', language: 'eng'), isFalse);
    });

    test('ignores case and surrounding whitespace', () {
      expect(trackLanguageMatches(query: '  English  ', language: 'ENG'), isTrue);
    });

    test('does not match when the track carries no language or title', () {
      expect(trackLanguageMatches(query: 'english'), isFalse);
    });
  });
}
