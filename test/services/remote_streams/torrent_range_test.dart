import 'package:flutter_test/flutter_test.dart';
import 'package:plezy_torrent/plezy_torrent.dart';

void main() {
  test('HTTP range reads match player seek and suffix contracts', () {
    expect(torrentRange(null, 100), (start: 0, end: 99));
    expect(torrentRange('bytes=20-', 100), (start: 20, end: 99));
    expect(torrentRange('bytes=-20', 100), (start: 80, end: 99));
    expect(torrentRange('bytes=20-999', 100), (start: 20, end: 99));
    for (final value in ['bytes=100-', 'bytes=9-1', 'bytes=-0', 'bytes=0-1,8-9', 'other=0-1', 'bytes=-']) {
      expect(() => torrentRange(value, 100), throwsFormatException);
    }
  });
}
