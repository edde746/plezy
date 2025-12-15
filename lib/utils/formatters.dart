import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import '../i18n/strings.g.dart';

/// Formats a number with a minimum number of digits using leading zeros.
///
/// Example: `padNumber(5, 3)` returns "005"
String padNumber(int number, int width) {
  return number.toString().padLeft(width, '0');
}

/// Utility class for formatting byte sizes and speeds
class ByteFormatter {
  ByteFormatter._();

  static const int _kb = 1024;
  static const int _mb = _kb * 1024;
  static const int _gb = _mb * 1024;

  /// Format bytes to human-readable string (e.g., "1.5 GB", "256.3 MB")
  ///
  /// [bytes] The number of bytes to format
  /// [decimals] Number of decimal places (default: 1 for KB/MB, 2 for GB)
  static String formatBytes(int bytes, {int? decimals}) {
    if (bytes < _kb) return '$bytes B';
    if (bytes < _mb) {
      return '${(bytes / _kb).toStringAsFixed(decimals ?? 1)} KB';
    }
    if (bytes < _gb) {
      return '${(bytes / _mb).toStringAsFixed(decimals ?? 1)} MB';
    }
    return '${(bytes / _gb).toStringAsFixed(decimals ?? 2)} GB';
  }

  /// Format speed in bytes per second to human-readable string
  ///
  /// [bytesPerSecond] The speed in bytes per second
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < _kb) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < _mb) {
      return '${(bytesPerSecond / _kb).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / _mb).toStringAsFixed(1)} MB/s';
  }

  /// Format bitrate in kbps to human-readable string
  ///
  /// [kbps] The bitrate in kilobits per second
  static String formatBitrate(int kbps) {
    if (kbps < 1000) return '$kbps kbps';
    return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
  }

  /// Format bitrate in bps to human-readable string
  ///
  /// [bps] The bitrate in bits per second
  /// Returns formatted string like "8.5 Mbps", "256 Kbps", or "128 bps"
  static String formatBitrateBps(int bps) {
    const kbps = 1000;
    const mbps = kbps * 1000;

    if (bps >= mbps) {
      return '${(bps / mbps).toStringAsFixed(2)} Mbps';
    } else if (bps >= kbps) {
      return '${(bps / kbps).toStringAsFixed(2)} Kbps';
    } else {
      return '$bps bps';
    }
  }
}

/// Formats a duration in human-readable textual format (e.g., "1h 23m" or "1 hour 23 minutes").
/// Uses localized unit names based on the current app locale.
/// Shows hours and minutes only (no seconds).
///
/// Used for: media cards, media details, playlists.
String formatDurationTextual(int milliseconds, {bool abbreviated = true}) {
  final duration = Duration(milliseconds: milliseconds);

  // Get the appropriate locale for the duration package
  final durationLocale = _getDurationLocale();

  // Format with abbreviated or full units (h, m) but no seconds
  return prettyDuration(
    duration,
    abbreviated: abbreviated,
    locale: durationLocale,
    delimiter: abbreviated ? ' ' : ', ',
    spacer: '',
    // Configure to show only hours and minutes
    tersity: DurationTersity.minute,
  );
}

/// Formats a duration in human-readable textual format with seconds (e.g., "1h 23m 45s").
/// Uses localized unit names based on the current app locale.
/// Shows hours, minutes, and seconds.
///
/// Used for: sleep timer countdown.
String formatDurationWithSeconds(Duration duration) {
  // Get the appropriate locale for the duration package
  final durationLocale = _getDurationLocale();

  // Format with abbreviated units (h, m, s) including seconds
  return prettyDuration(
    duration,
    abbreviated: true,
    locale: durationLocale,
    delimiter: ' ',
    spacer: '',
    // Show all non-zero units
    tersity: DurationTersity.second,
  );
}

/// Formats a duration in timestamp format (e.g., "1:23:45" or "23:45").
/// This format is not localized as it follows universal digital clock conventions.
/// Shows H:MM:SS or M:SS depending on duration.
///
/// Used for: video controls, chapters, episode durations.
String formatDurationTimestamp(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  } else {
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Formats a sync offset in milliseconds with sign indicator (e.g., "+150ms", "-250ms").
/// This format is used for audio/subtitle synchronization adjustments.
///
/// Used for: audio sync sheet, sync offset controls.
String formatSyncOffset(double offsetMs) {
  final sign = offsetMs >= 0 ? '+' : '';
  return '$sign${offsetMs.round()}ms';
}

/// Gets the duration package locale based on the current app locale.
/// Falls back to English if the locale is not supported by the duration package.
DurationLocale _getDurationLocale() {
  // Get the current locale from slang's LocaleSettings
  final appLocale = LocaleSettings.currentLocale;
  final languageCode = appLocale.languageCode;

  // Map supported locales to duration package locales
  // The duration package supports many languages, but we'll focus on the ones
  // that our app supports: en, de, it, nl, sv, zh
  try {
    return DurationLocale.fromLanguageCode(languageCode) ?? const EnglishDurationLocale();
  } catch (e) {
    // Fallback to English if language code is not supported
    return const EnglishDurationLocale();
  }
}
