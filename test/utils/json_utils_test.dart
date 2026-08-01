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

  test('flexibleIntOrZero defaults unsupported values to zero', () {
    expect(flexibleIntOrZero(3.9), 3);
    expect(flexibleIntOrZero('42'), 42);
    expect(flexibleIntOrZero(null), 0);
    expect(flexibleIntOrZero('bad'), 0);
    expect(flexibleIntOrZero(true), 0);
  });

  test('stringOrEmpty stringifies values and defaults null', () {
    expect(stringOrEmpty('value'), 'value');
    expect(stringOrEmpty(42), '42');
    expect(stringOrEmpty(true), 'true');
    expect(stringOrEmpty(null), '');
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

    test("maps '1' and true strings to true, other strings to false", () {
      expect(flexibleBool('1'), isTrue);
      expect(flexibleBool('true'), isTrue);
      expect(flexibleBool('TRUE'), isTrue);
      expect(flexibleBool('0'), isFalse);
      expect(flexibleBool('false'), isFalse);
      expect(flexibleBool(''), isFalse);
    });

    test('returns false for null and unsupported types', () {
      expect(flexibleBool(null), isFalse);
      expect(flexibleBool(1.0), isFalse);
      expect(flexibleBool(<String, Object>{}), isFalse);
    });
  });

  group('flexibleBoolNullable', () {
    test('returns bool as-is', () {
      expect(flexibleBoolNullable(true), isTrue);
      expect(flexibleBoolNullable(false), isFalse);
    });

    test('maps 1 to true, other ints to false', () {
      expect(flexibleBoolNullable(1), isTrue);
      expect(flexibleBoolNullable(0), isFalse);
      expect(flexibleBoolNullable(2), isFalse);
    });

    test("maps '1' and true strings to true, false strings to false", () {
      expect(flexibleBoolNullable('1'), isTrue);
      expect(flexibleBoolNullable('true'), isTrue);
      expect(flexibleBoolNullable('TRUE'), isTrue);
      expect(flexibleBoolNullable('0'), isFalse);
      expect(flexibleBoolNullable('false'), isFalse);
      expect(flexibleBoolNullable('FALSE'), isFalse);
    });

    test('returns null for null and unsupported types', () {
      expect(flexibleBoolNullable(null), isNull);
      expect(flexibleBoolNullable(1.0), isNull);
      expect(flexibleBoolNullable(<String, Object>{}), isNull);
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

  group('flexibleStringList', () {
    test('passes a list of strings through, dropping non-strings', () {
      expect(flexibleStringList(<dynamic>['tt1', 2, 'tt3', null]), ['tt1', 'tt3']);
    });

    test('wraps a single string in a list', () {
      expect(flexibleStringList('tt1'), ['tt1']);
    });

    test('returns null for null input', () {
      expect(flexibleStringList(null), isNull);
    });

    test('returns null for an empty list', () {
      expect(flexibleStringList(<dynamic>[]), isNull);
    });

    test('returns null when no element is a string', () {
      expect(flexibleStringList(<dynamic>[1, 2, 3]), isNull);
    });
  });

  group('flexibleCsvStringList', () {
    test('passes a list of strings through', () {
      expect(flexibleCsvStringList(<dynamic>['en', 'sv']), ['en', 'sv']);
    });

    test('wraps a bare string in a list', () {
      expect(flexibleCsvStringList('en'), ['en']);
    });

    test('splits a CSV string', () {
      expect(flexibleCsvStringList('en,sv'), ['en', 'sv']);
    });

    test('trims parts and drops empties', () {
      expect(flexibleCsvStringList('en, sv , ,fr'), ['en', 'sv', 'fr']);
      expect(flexibleCsvStringList(','), isNull);
      expect(flexibleCsvStringList(''), isNull);
    });

    test('splits CSV inside list elements and drops non-strings', () {
      expect(flexibleCsvStringList(<dynamic>['en,sv', 'fr']), ['en', 'sv', 'fr']);
      expect(flexibleCsvStringList(<dynamic>[1, 'en']), ['en']);
    });

    test('returns null for null and empty input', () {
      expect(flexibleCsvStringList(null), isNull);
      expect(flexibleCsvStringList(<dynamic>[]), isNull);
    });
  });

  group('flexible JSON objects', () {
    String parseId(Map<String, dynamic> json) => json['id'] as String;

    test('list parser keeps valid siblings around malformed entries', () {
      final parsed = parseFlexibleJsonList([
        {'id': 'first'},
        {'id': 2},
        'not-a-map',
        {'id': 'last'},
      ], parseId);

      expect(parsed, ['first', 'last']);
    });

    test('object parser finds the first map and contains parse failures', () {
      expect(
        parseFlexibleJsonObject([
          'not-a-map',
          {'id': 'value'},
        ], parseId),
        'value',
      );
      expect(parseFlexibleJsonObject({'id': 2}, parseId), isNull);
      expect(parseFlexibleJsonObject(null, parseId), isNull);
    });
  });
}
