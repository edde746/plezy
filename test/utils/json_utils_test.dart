import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/json_utils.dart';

void main() {
  group('flexibleInt', () {
    test('parses int as-is', () {
      expect(flexibleInt(42), 42);
      expect(flexibleInt(0), 0);
      expect(flexibleInt(-7), -7);
    });

    test('truncates double to int', () {
      expect(flexibleInt(3.9), 3);
      expect(flexibleInt(-3.9), -3);
    });

    test('parses numeric string', () {
      expect(flexibleInt('123'), 123);
      expect(flexibleInt('-45'), -45);
    });

    test('returns null for unparseable string', () {
      expect(flexibleInt('abc'), isNull);
      expect(flexibleInt('12abc'), isNull);
      expect(flexibleInt(''), isNull);
    });

    test('returns null for null or unsupported types', () {
      expect(flexibleInt(null), isNull);
      expect(flexibleInt(true), isNull);
      expect(flexibleInt(<int>[1]), isNull);
      expect(flexibleInt(<String, Object>{'a': 1}), isNull);
    });
  });

  group('flexibleBool', () {
    test('returns bool as-is', () {
      expect(flexibleBool(true), isTrue);
      expect(flexibleBool(false), isFalse);
    });

    test('maps 1 to true, other ints to false', () {
      expect(flexibleBool(1), isTrue);
      expect(flexibleBool(0), isFalse);
      expect(flexibleBool(2), isFalse);
      expect(flexibleBool(-1), isFalse);
    });

    test("maps '1' string to true, other strings to false", () {
      expect(flexibleBool('1'), isTrue);
      expect(flexibleBool('0'), isFalse);
      expect(flexibleBool('true'), isFalse);
      expect(flexibleBool(''), isFalse);
    });

    test('returns false for null and unsupported types', () {
      expect(flexibleBool(null), isFalse);
      expect(flexibleBool(1.0), isFalse);
      expect(flexibleBool(<String, Object>{}), isFalse);
    });
  });

  group('flexibleDouble', () {
    test('parses num as double', () {
      expect(flexibleDouble(1.5), 1.5);
      expect(flexibleDouble(2), 2.0);
      expect(flexibleDouble(0), 0.0);
    });

    test('parses numeric string', () {
      expect(flexibleDouble('3.14'), 3.14);
      expect(flexibleDouble('-2.5'), -2.5);
      expect(flexibleDouble('7'), 7.0);
    });

    test('returns null for unparseable string', () {
      expect(flexibleDouble('abc'), isNull);
      expect(flexibleDouble(''), isNull);
    });

    test('returns null for null and unsupported types', () {
      expect(flexibleDouble(null), isNull);
      expect(flexibleDouble(true), isNull);
      expect(flexibleDouble(<int>[1]), isNull);
    });
  });

  group('readStringField', () {
    test('coerces int to String', () {
      expect(readStringField({'x': 42}, 'x'), '42');
    });

    test('coerces double to String', () {
      expect(readStringField({'x': 3.14}, 'x'), '3.14');
    });

    test('leaves String alone', () {
      expect(readStringField({'x': 'hello'}, 'x'), 'hello');
    });

    test('returns null for missing key', () {
      expect(readStringField({'x': 1}, 'y'), isNull);
    });

    test('returns null for null value', () {
      expect(readStringField({'x': null}, 'x'), isNull);
    });
  });

  group('flexibleList', () {
    test('passes list through unchanged', () {
      final input = <dynamic>[1, 2, 3];
      expect(flexibleList(input), same(input));
    });

    test('wraps single Map in a List', () {
      final item = <String, Object>{'key': 'value'};
      expect(flexibleList(item), [item]);
    });

    test('wraps single String in a List', () {
      expect(flexibleList('solo'), ['solo']);
    });

    test('returns null for null input', () {
      expect(flexibleList(null), isNull);
    });

    test('handles empty list', () {
      expect(flexibleList(<dynamic>[]), <dynamic>[]);
    });
  });
}
