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
}
