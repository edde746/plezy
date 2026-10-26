import 'package:intl/intl.dart';

import 'app_locale_utils.dart';
import 'locale_preferences.dart';
import 'locale_units.g.dart';
import 'locale_lists.g.dart';
import 'strings.g.dart';

/// Display only: never use localized output in protocol parameters or storage.
String formatDecimal(num value, {int minimumDecimals = 0, int maximumDecimals = 2, bool grouping = false}) {
  final format = _cachedFormat('decimal:$minimumDecimals:$maximumDecimals:$grouping', (locale) {
    final result = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = minimumDecimals
      ..maximumFractionDigits = maximumDecimals;
    if (!grouping) result.turnOffGrouping();
    return result;
  });
  return format.format(value);
}

String formatCount(num value) => formatDecimal(value, maximumDecimals: 0, grouping: true);

String formatPercent(num ratio, {int decimals = 0}) => _cachedFormat(
  'percent:$decimals',
  (locale) => NumberFormat.percentPattern(locale)
    ..minimumFractionDigits = decimals
    ..maximumFractionDigits = decimals,
).format(ratio);

/// CLDR supplies grammar as well as symbols: Arabic dual forms, for example,
/// can legitimately omit a separate numeral. Numbers use the selected region;
/// unit words and their grammatical categories use the interface language.
String formatLocalizedUnit(num value, String unit, {String width = 'narrow', int decimals = 0}) {
  final locale = LocaleSettings.currentLocale;
  final patterns = localizedUnitPatterns[locale.languageTag] ?? localizedUnitPatterns[locale.languageCode]!;
  final forms = patterns[unit]![width]!;
  final displayedValue = num.parse(value.toStringAsFixed(decimals));
  final category = Intl.pluralLogic(
    displayedValue,
    locale: locale.intlLocaleName,
    precision: decimals,
    zero: 'zero',
    one: 'one',
    two: 'two',
    few: 'few',
    many: 'many',
    other: 'other',
  );
  return (forms[category] ?? forms['other']!).replaceAll(
    '{value}',
    formatDecimal(value, minimumDecimals: decimals, maximumDecimals: decimals),
  );
}

/// Isolate externally supplied titles, paths and numeric timelines so they
/// cannot reorder surrounding RTL UI. Strip explicit bidi controls supplied
/// by external metadata; the original stored value is never modified.
String isolateDisplayText(String value) => '\u2068${value.replaceAll(_bidiControls, '')}\u2069';
final _bidiControls = RegExp('[\u202A-\u202E\u2066-\u2069]');

String? _cachedLocale;
final _numberFormats = <String, NumberFormat>{};
NumberFormat _cachedFormat(String key, NumberFormat Function(String) create) {
  final locale = LocalePreferences.formattingLocaleName;
  if (_cachedLocale != locale) {
    _numberFormats.clear();
    _cachedLocale = locale;
  }
  // These are UI formats, not a cache of media values; cap custom precisions.
  if (_numberFormats.length >= 32 && !_numberFormats.containsKey(key)) _numberFormats.clear();
  return _numberFormats.putIfAbsent(key, () => create(locale));
}

/// Accept decimal digits from common system keyboards while keeping integer
/// settings strict: grouping separators, fractions and exponents are rejected.
/// This is an input boundary helper, never a change to persisted/protocol data.
int? parseLocalizedInteger(String text) => int.tryParse(
  normalizeDecimalDigits(text).replaceAll(RegExp('[\u061c\u200e\u200f]'), '').replaceAll('−', '-').trim(),
);

String normalizeDecimalDigits(String text) {
  const zeroes = [
    0x0030,
    0x0660,
    0x06f0,
    0x0966,
    0x09e6,
    0x0a66,
    0x0ae6,
    0x0b66,
    0x0be6,
    0x0c66,
    0x0ce6,
    0x0d66,
    0x0de6,
    0x0e50,
    0x0ed0,
    0x0f20,
    0x1040,
    0x1090,
    0x17e0,
    0x1810,
    0xff10,
  ];
  return String.fromCharCodes(
    text.runes.map((rune) {
      for (final zero in zeroes) {
        if (rune >= zero && rune <= zero + 9) return 0x30 + rune - zero;
      }
      return rune;
    }),
  );
}

/// CLDR list punctuation for a duration's two or three unit components.
String formatUnitList(List<String> parts, {bool abbreviated = true}) {
  if (parts.length < 2) return parts.join();
  final locale = LocaleSettings.currentLocale;
  // Retain the established compact English timeline labels.
  if (abbreviated && locale.languageCode == 'en') return parts.join(' ');
  final patterns = localizedUnitLists[locale.languageTag]!;
  final template = patterns[abbreviated ? 'narrow' : 'long']![parts.length - 2];
  return template.replaceAllMapped(RegExp(r'\{([0-2])\}'), (match) => parts[int.parse(match[1]!)]);
}
