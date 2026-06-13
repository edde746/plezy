import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_display_criteria.dart';

void main() {
  group('MediaDisplayCriteria', () {
    test('can prime native display criteria from frame rate and dimensions', () {
      const criteria = MediaDisplayCriteria(fps: 23.976, width: 1920, height: 1080);

      expect(criteria.canPrimeNativeDisplayCriteria, isTrue);
    });

    test('cannot prime native display criteria without dimensions', () {
      const criteria = MediaDisplayCriteria(fps: 23.976);

      expect(criteria.canPrimeNativeDisplayCriteria, isFalse);
    });
  });
}
