import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';

void main() {
  test('fallbackPageTotal adds a has-more sentinel only for full pages', () {
    expect(fallbackPageTotal(offset: 20, itemCount: 10, requestedSize: 10), 31);
    expect(fallbackPageTotal(offset: 20, itemCount: 11, requestedSize: 10), 32);
    expect(fallbackPageTotal(offset: 20, itemCount: 9, requestedSize: 10), 29);
    expect(fallbackPageTotal(offset: 20, itemCount: 10), 30);
    expect(fallbackPageTotal(offset: 20, itemCount: 10, requestedSize: 0), 30);
    expect(fallbackPageTotal(offset: 20, itemCount: 10, requestedSize: -1), 30);
  });

  group('drainPages onPage', () {
    Future<LibraryPage<int>> Function(int, int) source(List<List<int>> pages, {int? total}) {
      var call = 0;
      return (start, size) async {
        final items = call < pages.length ? pages[call] : const <int>[];
        call++;
        return LibraryPage(
          items: items,
          totalCount: total ?? fallbackPageTotal(offset: start, itemCount: items.length, requestedSize: size),
          offset: start,
        );
      };
    }

    test('fires after each intermediate page, never after the final page', () async {
      final seen = <List<int>>[];
      final all = await drainPages<int>(
        source([
          [1, 2],
          [3, 4],
          [5],
        ]),
        pageSize: 2,
        stopOnShortPage: true,
        onPage: (accumulated) => seen.add(List.of(accumulated)),
      );
      expect(all, [1, 2, 3, 4, 5]);
      expect(seen, [
        [1, 2],
        [1, 2, 3, 4],
      ]);
    });

    test('does not fire for a single-page listing', () async {
      var calls = 0;
      final all = await drainPages<int>(
        source([
          [1, 2],
        ], total: 2),
        pageSize: 2,
        onPage: (_) => calls++,
      );
      expect(all, [1, 2]);
      expect(calls, 0);
    });

    test('does not fire after the page that reaches the authoritative total', () async {
      final seen = <int>[];
      final all = await drainPages<int>(
        source([
          [1, 2],
          [3, 4],
        ], total: 4),
        pageSize: 2,
        onPage: (accumulated) => seen.add(accumulated.length),
      );
      expect(all, [1, 2, 3, 4]);
      expect(seen, [2]);
    });
  });
}
