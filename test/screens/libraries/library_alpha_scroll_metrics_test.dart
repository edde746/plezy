import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/screens/libraries/library_alpha_scroll_metrics.dart';

void main() {
  test('maps scroll offsets to item indices by row and column count', () {
    const metrics = LibraryAlphaScrollMetrics(columnCount: 4, rowHeight: 100, itemWidth: 150, itemHeight: 90);

    expect(metrics.itemIndexFromScrollOffset(0, contentStartOffset: 50, totalSize: 40), 0);
    expect(metrics.itemIndexFromScrollOffset(149, contentStartOffset: 50, totalSize: 40), 0);
    expect(metrics.itemIndexFromScrollOffset(150, contentStartOffset: 50, totalSize: 40), 4);
    expect(metrics.itemIndexFromScrollOffset(1050, contentStartOffset: 50, totalSize: 40), 39);
  });

  test('maps item indices back to scroll offsets', () {
    const metrics = LibraryAlphaScrollMetrics(columnCount: 4, rowHeight: 100, itemWidth: 150, itemHeight: 90);

    expect(metrics.scrollOffsetForItemIndex(0, contentStartOffset: 50), 50);
    expect(metrics.scrollOffsetForItemIndex(3, contentStartOffset: 50), 50);
    expect(metrics.scrollOffsetForItemIndex(4, contentStartOffset: 50), 150);
    expect(metrics.scrollOffsetForItemIndex(9, contentStartOffset: 50), 250);
  });

  test('counts visible items using one extra trailing row', () {
    const metrics = LibraryAlphaScrollMetrics(columnCount: 3, rowHeight: 100, itemWidth: 150, itemHeight: 90);

    expect(metrics.visibleItemCount(250), 12);
  });
}
