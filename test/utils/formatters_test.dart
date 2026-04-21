import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/formatters.dart';

void main() {
  group('padNumber', () {
    test('pads with leading zeros to given width', () {
      expect(padNumber(5, 3), '005');
      expect(padNumber(42, 2), '42');
      expect(padNumber(7, 1), '7');
    });

    test('does not truncate numbers wider than width', () {
      expect(padNumber(1234, 2), '1234');
    });
  });

  group('ByteFormatter.formatBytes', () {
    test('< 1 KB rendered as bytes', () {
      expect(ByteFormatter.formatBytes(0), '0 B');
      expect(ByteFormatter.formatBytes(1023), '1023 B');
    });

    test('1 KB boundary', () {
      expect(ByteFormatter.formatBytes(1024), '1.0 KB');
    });

    test('< 1 MB rendered as KB', () {
      expect(ByteFormatter.formatBytes(2048), '2.0 KB');
      expect(ByteFormatter.formatBytes(1024 * 1024 - 1), '1024.0 KB');
    });

    test('1 MB boundary', () {
      expect(ByteFormatter.formatBytes(1024 * 1024), '1.0 MB');
    });

    test('< 1 GB rendered as MB', () {
      expect(ByteFormatter.formatBytes(500 * 1024 * 1024), '500.0 MB');
    });

    test('>= 1 GB rendered with 2 decimals by default', () {
      expect(ByteFormatter.formatBytes(1024 * 1024 * 1024), '1.00 GB');
    });

    test('decimals override applies to KB/MB/GB branches', () {
      expect(ByteFormatter.formatBytes(1536, decimals: 2), '1.50 KB');
      expect(ByteFormatter.formatBytes(2 * 1024 * 1024, decimals: 0), '2 MB');
      expect(ByteFormatter.formatBytes(1024 * 1024 * 1024, decimals: 0), '1 GB');
    });
  });

  group('ByteFormatter.formatSpeed', () {
    test('< 1 KB/s -> bytes per second, no decimals', () {
      expect(ByteFormatter.formatSpeed(0), '0 B/s');
      expect(ByteFormatter.formatSpeed(512), '512 B/s');
    });

    test('KB/s range', () {
      expect(ByteFormatter.formatSpeed(1024), '1.0 KB/s');
      expect(ByteFormatter.formatSpeed(10 * 1024), '10.0 KB/s');
    });

    test('MB/s range', () {
      expect(ByteFormatter.formatSpeed(1024 * 1024.0), '1.0 MB/s');
      expect(ByteFormatter.formatSpeed(5 * 1024 * 1024.0), '5.0 MB/s');
    });
  });

  group('ByteFormatter.formatBitrate', () {
    test('< 1000 kbps', () {
      expect(ByteFormatter.formatBitrate(0), '0 kbps');
      expect(ByteFormatter.formatBitrate(500), '500 kbps');
      expect(ByteFormatter.formatBitrate(999), '999 kbps');
    });

    test('1000 kbps boundary crosses to Mbps', () {
      expect(ByteFormatter.formatBitrate(1000), '1.0 Mbps');
      expect(ByteFormatter.formatBitrate(2500), '2.5 Mbps');
    });
  });

  group('formatDurationTimestamp', () {
    test('zero duration', () {
      expect(formatDurationTimestamp(Duration.zero), '0:00');
    });

    test('M:SS when < 1 hour', () {
      expect(formatDurationTimestamp(const Duration(seconds: 5)), '0:05');
      expect(formatDurationTimestamp(const Duration(minutes: 3, seconds: 7)), '3:07');
      expect(formatDurationTimestamp(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('H:MM:SS when >= 1 hour', () {
      expect(formatDurationTimestamp(const Duration(hours: 1, minutes: 0, seconds: 0)), '1:00:00');
      expect(formatDurationTimestamp(const Duration(hours: 1, minutes: 23, seconds: 45)), '1:23:45');
    });

    test('negative duration is prefixed with -', () {
      expect(formatDurationTimestamp(const Duration(seconds: -7)), '-0:07');
      expect(formatDurationTimestamp(const Duration(hours: -1, minutes: -2, seconds: -3)), '-1:02:03');
    });
  });

  group('toBulletedString', () {
    test('joins with " · " separator', () {
      expect(toBulletedString(['a', 'b', 'c']), 'a · b · c');
    });

    test('single-element list returns the element', () {
      expect(toBulletedString(['only']), 'only');
    });

    test('empty list returns empty string', () {
      expect(toBulletedString([]), '');
    });
  });

  group('formatPlaybackRate', () {
    test('1x formats as "1x" without normalAtOne', () {
      expect(formatPlaybackRate(1.0), '1x');
    });

    test('1x formats as "Normal" when normalAtOne is true', () {
      expect(formatPlaybackRate(1.0, normalAtOne: true), 'Normal');
      // Within ±0.005 epsilon.
      expect(formatPlaybackRate(1.004, normalAtOne: true), 'Normal');
      expect(formatPlaybackRate(0.996, normalAtOne: true), 'Normal');
    });

    test('just outside epsilon renders numeric', () {
      expect(formatPlaybackRate(1.006, normalAtOne: true), '1.01x');
      expect(formatPlaybackRate(0.994, normalAtOne: true), '0.99x');
    });

    test('strips trailing zeros after decimal', () {
      expect(formatPlaybackRate(2.0), '2x');
      expect(formatPlaybackRate(1.5), '1.5x');
      expect(formatPlaybackRate(1.25), '1.25x');
      expect(formatPlaybackRate(1.1), '1.1x');
    });

    test('non-1 rate with normalAtOne still renders numeric', () {
      expect(formatPlaybackRate(0.5, normalAtOne: true), '0.5x');
      expect(formatPlaybackRate(2.0, normalAtOne: true), '2x');
    });
  });

  group('formatSyncOffset', () {
    test('< 10s: milliseconds with sign', () {
      expect(formatSyncOffset(150), '+150ms');
      expect(formatSyncOffset(-250), '-250ms');
      expect(formatSyncOffset(0), '+0ms');
      expect(formatSyncOffset(9999), '+9999ms');
    });

    test('>= 10s: decimal seconds', () {
      expect(formatSyncOffset(10000), '+10.0s');
      expect(formatSyncOffset(-15100), '-15.1s');
    });
  });

  group('formatFullDate', () {
    test('returns input unchanged when unparseable', () {
      expect(formatFullDate('not-a-date'), 'not-a-date');
      expect(formatFullDate(''), '');
    });

    test('does not throw for a valid ISO date', () {
      // DateFormat may fall back to raw input if intl date symbols aren't
      // initialised in the test runner — just verify no crash and string output.
      expect(formatFullDate('2024-01-15'), isA<String>());
    });
  });
}
