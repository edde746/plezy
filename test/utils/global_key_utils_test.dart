import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/utils/global_key_utils.dart';

void main() {
  group('buildGlobalKey', () {
    test('joins with a colon', () {
      expect(buildGlobalKey(ServerId('server'), '123'), 'server:123');
    });

    test('allows empty ratingKey', () {
      expect(buildGlobalKey(ServerId('server'), ''), 'server:');
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

    test('rejects empty serverId', () {
      expect(parseGlobalKey(':42'), isNull);
    });

    test('allows empty ratingKey', () {
      final result = parseGlobalKey('server:');
      expect(result, isNotNull);
      expect(result!.serverId, 'server');
      expect(result.ratingKey, '');
    });
  });
}
