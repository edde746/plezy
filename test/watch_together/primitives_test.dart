import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/primitives.dart';

void main() {
  test('orderedStringListsEqual preserves order and multiplicity', () {
    expect(orderedStringListsEqual(const ['a', 'b'], const ['a', 'b']), isTrue);
    expect(orderedStringListsEqual(const ['a'], const ['a', 'b']), isFalse);
    expect(orderedStringListsEqual(const ['a', 'b'], const ['b', 'a']), isFalse);
    expect(orderedStringListsEqual(const ['a', 'a'], const ['a', 'b']), isFalse);
  });
}
