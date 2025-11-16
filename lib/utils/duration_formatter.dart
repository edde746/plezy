import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import '../i18n/strings.g.dart';

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
    return DurationLocale.fromLanguageCode(languageCode) ??
        const EnglishDurationLocale();
  } catch (e) {
    // Fallback to English if language code is not supported
    return const EnglishDurationLocale();
  }
}
