import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_first_character.dart';

void main() {
  group('LibraryAlphaBucket.of', () {
    test('files a title under its first letter or digit, not its first character', () {
      // Every one of these is a real `sort_name` from the reference Music
      // Assistant library, paired with where that server actually sorted it.
      // The rule has to match the server or the bucket is a lie: `#10` sits
      // among the tens, `¡tre!` sits 90% of the way through under `t`.
      expect(LibraryAlphaBucket.of('#10'), '1');
      expect(LibraryAlphaBucket.of('=1'), '1');
      expect(LibraryAlphaBucket.of('"99" (kat krazy remix)'), '9');
      expect(LibraryAlphaBucket.of('¡tre!'), 'T');
      expect(LibraryAlphaBucket.of("'03 bonnie and clyde"), '0');
      expect(LibraryAlphaBucket.of('a/b'), 'A');
      expect(LibraryAlphaBucket.of('abbey road'), 'A');
    });

    test('keeps numeric titles under their number rather than folding them into #', () {
      // These are findable titles. A user who owns 1989 looks for it under 1,
      // which is where Music Assistant, Plex, Jellyfin and Navidrome all put it.
      expect(LibraryAlphaBucket.of('1989'), '1');
      expect(LibraryAlphaBucket.of('808 state'), '8');
      expect(LibraryAlphaBucket.of('9 lazy 9'), '9');
      expect(LibraryAlphaBucket.isOther('1989'), isFalse);
    });

    test('sends a title with no letter and no digit to the # bucket', () {
      for (final unsortable in ['@', '!!!!!!!', '...', '/', '+', '-', '÷', '( )', r'$$$', '(@#)', '🌈', '∞', '[ ]']) {
        expect(LibraryAlphaBucket.of(unsortable), LibraryAlphaBucket.other, reason: unsortable);
        expect(LibraryAlphaBucket.isOther(unsortable), isTrue, reason: unsortable);
      }
    });

    test('keeps non-Latin scripts out of the # bucket', () {
      // The reference library holds CJK, Hangul and Cyrillic titles. They are
      // real titles with real names; dumping them in with `!!!!!!!` would be the
      // same mistake in a different alphabet.
      for (final title in ['奥井雅美', '김동현', 'хелависа', 'ꭱꭿꮝꮫ ꮰꮣ']) {
        expect(LibraryAlphaBucket.isOther(title), isFalse, reason: title);
      }
    });

    test('treats an empty title as unsortable rather than throwing', () {
      expect(LibraryAlphaBucket.of(''), LibraryAlphaBucket.other);
    });
  });
}
