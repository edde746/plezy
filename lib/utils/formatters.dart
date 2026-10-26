import 'package:intl/intl.dart';
import '../i18n/locale_preferences.dart';
import '../i18n/presentation_formats.dart';
import '../i18n/strings.g.dart';

/// Formats a number with a minimum number of digits using leading zeros.
///
/// Example: `padNumber(5, 3)` returns "005"
String padNumber(int number, int width) {
  return number.toString().padLeft(width, '0');
}

class ByteFormatter {
  ByteFormatter._();

  // Preserve the established English symbols while other languages use CLDR.
  static const _englishSymbols = {'byte': 'B', 'kilobyte': 'KB', 'megabyte': 'MB', 'gigabyte': 'GB',
    'byte-per-second': 'B/s', 'kilobyte-per-second': 'KB/s', 'megabyte-per-second': 'MB/s',
    'kilobit-per-second': 'kbps', 'megabit-per-second': 'Mbps'};
  static String _dataUnit(num value, String unit, {int decimals = 0}) =>
      LocaleSettings.currentLocale.languageCode == 'en'
        ? '${formatDecimal(value, minimumDecimals: decimals, maximumDecimals: decimals)} ${_englishSymbols[unit]}'
        : formatLocalizedUnit(value, unit, width: 'short', decimals: decimals);

  static const int _kb = 1024;
  static const int _mb = _kb * 1024;
  static const int _gb = _mb * 1024;

  /// Format bytes to human-readable string (e.g., "1.5 GB", "256.3 MB")
  static String formatBytes(int bytes, {int? decimals}) {
    if (bytes < _kb) return _dataUnit(bytes, 'byte');
    if (bytes < _mb) return _dataUnit(bytes / _kb, 'kilobyte', decimals: decimals ?? 1);
    if (bytes < _gb) return _dataUnit(bytes / _mb, 'megabyte', decimals: decimals ?? 1);
    return _dataUnit(bytes / _gb, 'gigabyte', decimals: decimals ?? 2);
  }

  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < _kb) return _dataUnit(bytesPerSecond, 'byte-per-second');
    if (bytesPerSecond < _mb) return _dataUnit(bytesPerSecond / _kb, 'kilobyte-per-second', decimals: 1);
    return _dataUnit(bytesPerSecond / _mb, 'megabyte-per-second', decimals: 1);
  }

  static String formatBitrate(int kbps) => kbps < 1000
      ? _dataUnit(kbps, 'kilobit-per-second')
      : _dataUnit(kbps / 1000, 'megabit-per-second', decimals: 1);

}

/// Formats a duration in human-readable textual format (e.g., "1h 23m" or "1 hour 23 minutes").
/// Uses localized unit names based on the current app locale.
/// Shows hours and minutes only (no seconds).
///
/// Used for: media cards, media details, playlists.
String formatDurationTextual(int milliseconds, {bool abbreviated = true}) {
  return _formatDurationUnits(Duration(milliseconds: milliseconds), abbreviated: abbreviated, includeSeconds: false);
}

/// Localized duration with seconds for countdowns and sleep timers.
String formatDurationWithSeconds(Duration duration) =>
    _formatDurationUnits(duration, abbreviated: true, includeSeconds: true);

String _formatDurationUnits(Duration duration, {required bool abbreviated, required bool includeSeconds}) {
  final positive = duration.abs();
  final hours = positive.inHours;
  final minutes = positive.inMinutes.remainder(60);
  final seconds = positive.inSeconds.remainder(60);
  final width = abbreviated ? 'narrow' : 'long';
  final parts = <String>[
    if (hours > 0) formatLocalizedUnit(hours, 'hour', width: width),
    if (minutes > 0) formatLocalizedUnit(minutes, 'minute', width: width),
    if ((includeSeconds && seconds > 0) || (hours == 0 && minutes == 0))
      formatLocalizedUnit(seconds, 'second', width: width),
  ];
  return '${duration.isNegative ? '−' : ''}${parts.join(abbreviated ? ' ' : ', ')}';
}

/// Formats a duration in timestamp format (e.g., "1:23:45" or "23:45").
/// This format is not localized as it follows universal digital clock conventions.
/// Shows H:MM:SS or M:SS depending on duration.
///
/// Used for: video controls, chapters, episode durations.
String formatDurationTimestamp(Duration duration) {
  final isNegative = duration.isNegative;
  final absoluteDuration = duration.abs();

  final hours = absoluteDuration.inHours;
  final minutes = absoluteDuration.inMinutes.remainder(60);
  final seconds = absoluteDuration.inSeconds.remainder(60);

  final result = hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
      : '$minutes:${seconds.toString().padLeft(2, '0')}';

  return isNegative ? '-$result' : result;
}

/// Formats a sync offset in milliseconds with sign indicator (e.g., "+150ms", "-15.1s").
/// Shows milliseconds for values < 10s, decimal seconds for larger values.
///
/// Used for: audio sync sheet, sync offset controls.
String formatSyncOffset(double offsetMs) {
  final sign = offsetMs >= 0 ? '+' : '-';
  final absMs = offsetMs.abs().round();
  if (absMs >= 10_000) {
    return '$sign${formatLocalizedUnit(offsetMs.abs() / 1000, 'second', decimals: 1)}';
  }
  return '$sign${formatLocalizedUnit(absMs, 'millisecond')}';
}

/// Formats a [DateTime] as a clock time string, respecting the system 24-hour preference.
/// Optionally includes seconds for precise timeline hover and scrub positions.
String formatClockTime(DateTime time, {required bool is24Hour, bool includeSeconds = false}) {
  final locale = LocalePreferences.formattingLocaleName;
  final formatter = is24Hour
      ? (includeSeconds ? DateFormat.Hms(locale) : DateFormat.Hm(locale))
      : (includeSeconds ? DateFormat.jms(locale) : DateFormat.jm(locale));
  return formatter.format(time);
}

/// Formats a date as Today/Tomorrow or a localized abbreviated weekday.
String formatRelativeDayLabel(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  // Whole calendar days, counted in UTC: local midnights are 23 or 25 hours
  // apart across a DST change, which inDays would truncate.
  final today = DateTime.utc(reference.year, reference.month, reference.day);
  final targetDay = DateTime.utc(date.year, date.month, date.day);
  final diff = targetDay.difference(today).inDays;
  return switch (diff) {
    0 => t.liveTv.today,
    1 => t.liveTv.tomorrow,
    _ => DateFormat.E(LocalePreferences.formattingLocaleName).format(date),
  };
}

String toBulletedString(List<String> parts) {
  return parts.join(' · ');
}

String? formatSeasonEpisodeLabel(int? season, int? episode) {
  if (season == null || episode == null) return null;
  return 'S$season E$episode';
}

String formatRating(double value) => formatDecimal(value, maximumDecimals: 1);

/// Format a playback rate for display (e.g. 1.25 → "1.25x", 2.0 → "2x").
/// When [normalAtOne] is true, 1.0 renders with the localized normal-speed
/// label for menus; the in-player pill passes false to keep a numeric indicator.
String formatPlaybackRate(double rate, {bool normalAtOne = false}) {
  if (normalAtOne && (rate - 1.0).abs() < 0.005) return t.videoSettings.normalSpeed;
  return '${formatDecimal(rate)}x';
}

/// Takes a date string in the format "YYYY-MM-DD" and returns a localized full date string
/// If there is any error, `dateString` is returned as is
String formatFullDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);

    final formatter = DateFormat.yMMMMd(LocalePreferences.formattingLocaleName);

    return formatter.format(date);
  } catch (e) {
    return dateString;
  }
}

/// Like [formatFullDate] but uses an abbreviated month name (`DateFormat.yMMMd`)
/// to keep the result compact for space-constrained, single-line layouts.
/// If there is any error, `dateString` is returned as is
String formatAbbreviatedDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);

    final formatter = DateFormat.yMMMd(LocalePreferences.formattingLocaleName);

    return formatter.format(date);
  } catch (e) {
    return dateString;
  }
}
