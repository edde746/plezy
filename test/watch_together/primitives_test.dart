import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/primitives.dart';

void main() {
  test('stored room codes preserve the established host peer wire format', () {
    const persistedSessionId = 'Ab12z';

    expect(watchTogetherHostPeerId(persistedSessionId), 'wt-AB12Z');
  });

  test('orderedStringListsEqual preserves order and multiplicity', () {
    expect(orderedStringListsEqual(const ['a', 'b'], const ['a', 'b']), isTrue);
    expect(orderedStringListsEqual(const ['a'], const ['a', 'b']), isFalse);
    expect(orderedStringListsEqual(const ['a', 'b'], const ['b', 'a']), isFalse);
    expect(orderedStringListsEqual(const ['a', 'a'], const ['a', 'b']), isFalse);
  });

  test('watchTogetherSystemNowMs returns wall-clock milliseconds', () {
    final before = DateTime.now().millisecondsSinceEpoch;
    final value = watchTogetherSystemNowMs();
    final after = DateTime.now().millisecondsSinceEpoch;

    expect(value, inInclusiveRange(before, after));
  });
}
