import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/initials_palette.dart';

void main() {
  group('initialOf', () {
    test('keeps fallback, trimming, and ordinary casing behavior', () {
      expect(initialOf(''), '?');
      expect(initialOf('   \t\n'), '?');
      expect(initialOf('  alice  '), 'A');
    });

    test('returns the complete first extended grapheme', () {
      expect(initialOf('🇯🇵 Japan'), '🇯🇵');
      expect(initialOf('👍🏽 Approved'), '👍🏽');
      expect(initialOf('👨‍👩‍👧‍👦 Family'), '👨‍👩‍👧‍👦');
      expect(initialOf('e\u0301clair'), 'E\u0301');
    });
  });
}
