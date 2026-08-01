import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/lrc_parser.dart';

void main() {
  group('parseLrc', () {
    test('parses synced lines ordered by tick', () {
      final lyrics = parseLrc('[00:20.00]Second line\n[00:10.00]First line\n[01:05.00]Third line');

      expect(lyrics, isNotNull);
      expect(lyrics!.synced, isTrue);
      expect(lyrics.lines.map((l) => l.text), ['First line', 'Second line', 'Third line']);
      expect(lyrics.lines.map((l) => l.startMs), [10000, 20000, 65000]);
    });

    test('emits a multi-timestamp line once per timestamp', () {
      final lyrics = parseLrc('[00:05.00]Verse\n[00:10.00][00:30.00]Chorus');

      expect(lyrics!.lines.map((l) => l.text), ['Verse', 'Chorus', 'Chorus']);
      expect(lyrics.lines.map((l) => l.startMs), [5000, 10000, 30000]);
    });

    test('applies the offset tag and clamps below zero', () {
      final lyrics = parseLrc('[offset:+500]\n[00:01.00]Late start\n[00:00.20]Clamped');

      // offset is subtracted: 1000 - 500 = 500; 200 - 500 clamps to 0.
      expect(lyrics!.lines.map((l) => l.startMs), [0, 500]);
      expect(lyrics.lines.map((l) => l.text), ['Clamped', 'Late start']);
    });

    test('scales fractional part by digit count', () {
      final lyrics = parseLrc('[00:01.5]One digit\n[00:02.50]Two digits\n[00:03.500]Three digits');

      expect(lyrics!.lines.map((l) => l.startMs), [1500, 2500, 3500]);
    });

    test('skips metadata id tags', () {
      final lyrics = parseLrc('[ar:The Synth Pops]\n[ti:Dawn]\n[al:Album]\n[00:01.00]Actual line');

      expect(lyrics!.synced, isTrue);
      expect(lyrics.lines, hasLength(1));
      expect(lyrics.lines.single.text, 'Actual line');
    });

    test('falls back to unsynced plain text when no timestamps exist', () {
      final lyrics = parseLrc('[ar:Artist]\nJust some words\nAnother line');

      expect(lyrics, isNotNull);
      expect(lyrics!.synced, isFalse);
      expect(lyrics.lines.map((l) => l.text), ['Just some words', 'Another line']);
      expect(lyrics.lines.every((l) => l.startMs == null), isTrue);
    });

    test('returns null for blank input', () {
      expect(parseLrc(''), isNull);
      expect(parseLrc('  \n\n  '), isNull);
      expect(parseLrc('[ar:Only tags]'), isNull);
    });
  });
}
