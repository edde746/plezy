/// Time-unit conversions for Jellyfin's wire format.
///
/// Jellyfin reports durations and offsets in "ticks" (100-nanosecond units, a
/// .NET `DateTime.Ticks` legacy) and timestamps as ISO-8601 strings. The app
/// otherwise speaks milliseconds + Unix epoch seconds, so every Jellyfin
/// boundary needs a conversion. Centralised here so the shape is consistent
/// across mappers, the client, and the playback bundle.
library;

const int _ticksPerMs = 10000;

/// Jellyfin ticks → milliseconds. Returns `null` for non-numeric input.
int? jellyfinTicksToMs(Object? ticks) {
  if (ticks is num) return ticks ~/ _ticksPerMs;
  return null;
}

/// Milliseconds → Jellyfin ticks. Used when reporting playback position back
/// to the server (`PositionTicks`).
int msToJellyfinTicks(int ms) => ms * _ticksPerMs;

/// ISO-8601 date string → Unix epoch seconds. Returns `null` for empty,
/// missing, or unparseable input.
int? jellyfinIsoToEpochSeconds(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  return dt.millisecondsSinceEpoch ~/ 1000;
}

/// Truncate a Jellyfin ISO-8601 datetime to `YYYY-MM-DD` so it lines up with
/// Plex's `originallyAvailableAt` shape. Returns `null` for empty input.
String? jellyfinIsoToYmd(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final i = iso.indexOf('T');
  return i > 0 ? iso.substring(0, i) : iso;
}
