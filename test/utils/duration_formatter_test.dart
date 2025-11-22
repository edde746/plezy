import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/duration_formatter.dart';

void main() {
  group('formatDurationTimestamp', () {
    test('formats duration with hours', () {
      final duration = Duration(hours: 1, minutes: 23, seconds: 45);
      expect(formatDurationTimestamp(duration), '1:23:45');
    });

    test('formats duration without hours', () {
      final duration = Duration(minutes: 23, seconds: 45);
      expect(formatDurationTimestamp(duration), '23:45');
    });

    test('pads minutes and seconds with leading zeros for hours format', () {
      final duration = Duration(hours: 2, minutes: 5, seconds: 8);
      expect(formatDurationTimestamp(duration), '2:05:08');
    });

    test('pads seconds but not minutes for no-hours format', () {
      final duration = Duration(minutes: 5, seconds: 8);
      expect(formatDurationTimestamp(duration), '5:08');
    });

    test('handles zero duration', () {
      final duration = Duration.zero;
      expect(formatDurationTimestamp(duration), '0:00');
    });

    test('handles very long duration', () {
      final duration = Duration(hours: 99, minutes: 59, seconds: 59);
      expect(formatDurationTimestamp(duration), '99:59:59');
    });

    test('handles one second', () {
      final duration = Duration(seconds: 1);
      expect(formatDurationTimestamp(duration), '0:01');
    });

    test('handles one minute', () {
      final duration = Duration(minutes: 1);
      expect(formatDurationTimestamp(duration), '1:00');
    });

    test('handles 59 minutes 59 seconds', () {
      final duration = Duration(minutes: 59, seconds: 59);
      expect(formatDurationTimestamp(duration), '59:59');
    });

    test('handles exactly 1 hour', () {
      final duration = Duration(hours: 1);
      expect(formatDurationTimestamp(duration), '1:00:00');
    });

    test('handles multiple hours with zero minutes and seconds', () {
      final duration = Duration(hours: 3);
      expect(formatDurationTimestamp(duration), '3:00:00');
    });
  });

  group('formatSyncOffset', () {
    test('formats positive offset with plus sign', () {
      expect(formatSyncOffset(150.0), '+150ms');
    });

    test('formats negative offset with minus sign', () {
      expect(formatSyncOffset(-250.0), '-250ms');
    });

    test('formats zero offset with plus sign', () {
      expect(formatSyncOffset(0.0), '+0ms');
    });

    test('rounds decimal values', () {
      expect(formatSyncOffset(150.7), '+151ms');
      expect(formatSyncOffset(150.3), '+150ms');
      expect(formatSyncOffset(-150.7), '-151ms');
    });

    test('handles large positive offset', () {
      expect(formatSyncOffset(10000.0), '+10000ms');
    });

    test('handles large negative offset', () {
      expect(formatSyncOffset(-10000.0), '-10000ms');
    });

    test('handles very small positive offset', () {
      expect(formatSyncOffset(0.1), '+0ms');
    });

    test('handles negative zero', () {
      expect(formatSyncOffset(-0.0), '+0ms');
    });
  });

  group('formatDurationTextual', () {
    test('formats duration with hours and minutes abbreviated', () {
      final milliseconds = Duration(hours: 1, minutes: 23).inMilliseconds;
      final result = formatDurationTextual(milliseconds);
      // The exact format depends on locale, but should contain hour and minute indicators
      expect(result.isNotEmpty, true);
      // Check that it doesn't include seconds when abbreviated
      expect(result.contains('s'), false);
    });

    test('formats duration with only minutes abbreviated', () {
      final milliseconds = Duration(minutes: 45).inMilliseconds;
      final result = formatDurationTextual(milliseconds);
      expect(result.isNotEmpty, true);
    });

    test('formats zero duration', () {
      final result = formatDurationTextual(0);
      expect(result.isNotEmpty, true);
    });

    test('formats with full unit names when not abbreviated', () {
      final milliseconds = Duration(hours: 2, minutes: 30).inMilliseconds;
      final result = formatDurationTextual(milliseconds, abbreviated: false);
      expect(result.isNotEmpty, true);
      // Full format should be longer than abbreviated
      final abbreviated = formatDurationTextual(milliseconds, abbreviated: true);
      expect(result.length >= abbreviated.length, true);
    });
  });

  group('formatDurationWithSeconds', () {
    test('formats duration with hours, minutes, and seconds', () {
      final duration = Duration(hours: 1, minutes: 23, seconds: 45);
      final result = formatDurationWithSeconds(duration);
      expect(result.isNotEmpty, true);
    });

    test('formats duration with only seconds', () {
      final duration = Duration(seconds: 30);
      final result = formatDurationWithSeconds(duration);
      expect(result.isNotEmpty, true);
    });

    test('formats zero duration', () {
      final result = formatDurationWithSeconds(Duration.zero);
      expect(result.isNotEmpty, true);
    });

    test('formats duration with minutes and seconds', () {
      final duration = Duration(minutes: 5, seconds: 30);
      final result = formatDurationWithSeconds(duration);
      expect(result.isNotEmpty, true);
    });
  });
}
