import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/global_key_utils.dart';

void main() {
  group('buildGlobalKey', () {
    test('joins with a colon', () {
      expect(buildGlobalKey('server', '123'), 'server:123');
    });

    test('passes through empty components', () {
      expect(buildGlobalKey('', '123'), ':123');
      expect(buildGlobalKey('server', ''), 'server:');
      expect(buildGlobalKey('', ''), ':');
    });
  });

  group('parseGlobalKey', () {
    test('parses simple key', () {
      final result = parseGlobalKey('abc:42');
      expect(result, isNotNull);
      expect(result!.serverId, 'abc');
      expect(result.ratingKey, '42');
    });

    test('returns null when no colon', () {
      expect(parseGlobalKey('no-colon-here'), isNull);
      expect(parseGlobalKey(''), isNull);
    });

    test('preserves colons inside ratingKey (uses first colon only)', () {
      final result = parseGlobalKey('server:path:with:colons');
      expect(result, isNotNull);
      expect(result!.serverId, 'server');
      expect(result.ratingKey, 'path:with:colons');
    });

    test('allows empty serverId', () {
      final result = parseGlobalKey(':42');
      expect(result, isNotNull);
      expect(result!.serverId, '');
      expect(result.ratingKey, '42');
    });

    test('allows empty ratingKey', () {
      final result = parseGlobalKey('server:');
      expect(result, isNotNull);
      expect(result!.serverId, 'server');
      expect(result.ratingKey, '');
    });
  });

  test('round-trip build → parse returns original components', () {
    for (final pair in const [('s1', '42'), ('serverXYZ', '/library/metadata/123'), ('', 'abc'), ('s', '')]) {
      final built = buildGlobalKey(pair.$1, pair.$2);
      final parsed = parseGlobalKey(built);
      expect(parsed, isNotNull);
      expect(parsed!.serverId, pair.$1);
      expect(parsed.ratingKey, pair.$2);
    }
  });
}
