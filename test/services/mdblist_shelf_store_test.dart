import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/catalog/mdblist_explore_shelf.dart';
import 'package:plezy/services/mdblist_shelf_store.dart';

void main() {
  test('absent settings are empty and malformed settings are reported', () {
    expect(MdblistShelfStore.decode(null), isEmpty);
    expect(() => MdblistShelfStore.decode('{'), throwsFormatException);
    expect(() => MdblistShelfStore.decode('{}'), throwsFormatException);
  });

  test('round trip preserves order, name overrides and disabled shelves', () {
    final restored = MdblistShelfStore.decode(
      MdblistShelfStore.encode(const [
        MdblistExploreShelf(listId: 2, sourceName: 'TV', displayName: 'Evening', enabled: false),
        MdblistExploreShelf(listId: 1, sourceName: 'Movies'),
      ]),
    );
    expect(restored.map((shelf) => shelf.listId), [2, 1]);
    expect(restored.first.title, 'Evening');
    expect(restored.first.enabled, isFalse);
    expect(restored.first.copyWith(displayName: '').title, 'TV');
  });

  test('invalid entries are ignored and duplicate IDs keep their first position', () {
    final shelves = MdblistShelfStore.decode(
      '[null,{"id":1,"name":"First"},{"id":-1,"name":"Invalid"},'
      '{"id":2,"name":""},{"id":1,"name":"Duplicate"},{"id":3,"name":"Last"}]',
    );
    expect(shelves.map((shelf) => shelf.title), ['First', 'Last']);
    expect(() => shelves.add(const MdblistExploreShelf(listId: 4, sourceName: 'New')), throwsUnsupportedError);
    expect(MdblistShelfStore.keyFor('profile-1'), isNot(MdblistShelfStore.keyFor('profile-2')));
  });
}
