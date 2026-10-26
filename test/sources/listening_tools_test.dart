import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/listening_tools.dart';

void main() {
  test('parses audiobook time in minute or hour notation without a 24-hour cap', () {
    expect(parseListeningTime('3:07'), 187000);
    expect(parseListeningTime('128:45:09'), 463509000);
    expect(parseListeningTime('00:00'), 0);
  });

  test('rejects malformed and out-of-range time components', () {
    for (final value in ['3', '-1:00', '1:60', '1:2:60', '1:2:3:4', 'abc', '']) {
      expect(parseListeningTime(value), isNull, reason: value);
    }
  });
}
