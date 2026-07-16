import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/jellyfin_time.dart';

void main() {
  group('Jellyfin time conversions', () {
    test('converts ticks and milliseconds in both directions', () {
      expect(jellyfinTicksToMs(12_345_678), 1234);
      expect(jellyfinTicksToMs(12.5), 0);
      expect(jellyfinTicksToMs('10000'), isNull);
      expect(msToJellyfinTicks(1234), 12_340_000);
    });

    test('converts ISO timestamps to UTC epoch seconds', () {
      expect(jellyfinIsoToEpochSeconds('1970-01-01T00:00:01.999Z'), 1);
      expect(jellyfinIsoToEpochSeconds('1970-01-01T01:00:01+01:00'), 1);
    });

    test('returns null for missing or invalid ISO timestamps', () {
      expect(jellyfinIsoToEpochSeconds(null), isNull);
      expect(jellyfinIsoToEpochSeconds(''), isNull);
      expect(jellyfinIsoToEpochSeconds('not-a-date'), isNull);
    });

    test('truncates ISO timestamps to the calendar date', () {
      expect(jellyfinIsoToYmd('2026-07-12T09:30:00Z'), '2026-07-12');
      expect(jellyfinIsoToYmd('2026-07-12'), '2026-07-12');
      expect(jellyfinIsoToYmd(''), isNull);
    });
  });
}
