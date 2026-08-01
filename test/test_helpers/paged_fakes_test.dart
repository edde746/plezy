import 'package:flutter_test/flutter_test.dart';

import 'paged_fakes.dart';

void main() {
  test('fakeLibraryPage uses the shared 200-item default', () {
    final items = List<int>.generate(250, (index) => index);

    final first = fakeLibraryPage(items);
    final second = fakeLibraryPage(items, start: fakeMediaPageSize);

    expect(first.items, orderedEquals(List<int>.generate(200, (index) => index)));
    expect(first.totalCount, 250);
    expect(first.offset, 0);
    expect(second.items, orderedEquals(List<int>.generate(50, (index) => index + 200)));
    expect(second.offset, 200);
  });

  test('fakeLibraryPage honors explicit bounds and empty trailing pages', () {
    final items = List<int>.generate(10, (index) => index);

    expect(fakeLibraryPage(items, start: 3, size: 4).items, [3, 4, 5, 6]);
    final trailing = fakeLibraryPage(items, start: 20, size: 4);
    expect(trailing.items, isEmpty);
    expect(trailing.totalCount, 10);
    expect(trailing.offset, 20);
  });
}
