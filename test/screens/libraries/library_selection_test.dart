import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/screens/libraries/library_selection.dart';
import '../../test_helpers/media_items.dart';

void main() {
  test('selection survives cache eviction and distinguishes servers', () {
    final a = testMediaItem(id: '1', serverId: 'a');
    final b = testMediaItem(id: '1', serverId: 'b');
    final loaded = {0: a, 1: b};
    final selection = LibrarySelection()
      ..toggle(0, loaded)
      ..toggle(1, loaded);
    loaded.clear();
    expect(selection.count, 2);
    expect(selection.contains(a), isTrue);
    selection.remove(a);
    expect(selection.items, [b]);
  });

  test('Shift range selects loaded video items in both directions', () {
    final loaded = {
      0: testMediaItem(id: '0'),
      1: testMediaItem(id: '1', kind: MediaKind.artist),
      3: testMediaItem(id: '3'),
      4: testMediaItem(id: '4'),
    };
    final selection = LibrarySelection()
      ..toggle(4, loaded)
      ..toggle(0, loaded, range: true);
    expect(selection.items.map((e) => e.id), ['4', '0', '3']);
    selection.clear();
    selection.toggle(0, loaded);
    selection.toggle(4, loaded, range: true);
    expect(selection.items.map((e) => e.id), ['0', '3', '4']);
  });

  test('plain click toggles; clearing retires the range anchor', () {
    final loaded = {0: testMediaItem(id: '0'), 1: testMediaItem(id: '1')};
    final selection = LibrarySelection()
      ..toggle(0, loaded)
      ..toggle(0, loaded);
    expect(selection.count, 0);
    selection.clear();
    selection.toggle(1, loaded, range: true);
    expect(selection.items, [loaded[1]]);
  });
}
