import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';

void main() {
  test('capture snapshots preserve fractional wire coordinates', () {
    final buffer = CaptureBuffer.fromTranscodeSession({
      'timeStamp': '1000.25',
      'minOffsetAvailable': '2.2',
      'maxOffsetAvailable': 10.8,
    });
    expect(buffer!.startedAt, 1000.25);
    expect(buffer.seekStartSeconds, 2.2);
    expect(buffer.seekEndSeconds, 10.8);
  });

  test('malformed timing never becomes a seekable capture snapshot', () {
    for (final fields in [
      {'timeStamp': 'NaN', 'minOffsetAvailable': 0, 'maxOffsetAvailable': 10},
      {'timeStamp': 1000, 'minOffsetAvailable': 0, 'maxOffsetAvailable': double.infinity},
      {'timeStamp': 1000, 'minOffsetAvailable': 20, 'maxOffsetAvailable': 10},
      {'timeStamp': 1000, 'minOffsetAvailable': 0},
    ]) {
      expect(CaptureBuffer.fromTranscodeSession(fields), isNull);
    }
  });
}
