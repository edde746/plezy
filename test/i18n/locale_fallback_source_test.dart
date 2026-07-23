import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recovery and error locale entries are absent or non-empty', () {
    const recoveryPaths = <List<String>>[
      ['auth', 'localDataRecoveryRequired'],
      ['settings', 'watchTogetherRelayInvalid'],
      ['settings', 'saveFailed'],
      ['messages', 'playbackAuthenticationRequired'],
      ['messages', 'playbackServerUnavailable'],
      ['messages', 'playbackDataInvalid'],
      ['messages', 'playbackCancelled'],
      ['messages', 'playbackFailed'],
      ['profiles', 'borrowLoadFailed'],
      ['liveTv', 'favoritesUpdateFailed'],
      ['settings', 'downloadLocationPickerUnavailable'],
    ];
    final sourceDirectory = Directory('lib/i18n');
    final english = _decodeLocale(File('${sourceDirectory.path}/en.i18n.json'));
    final localeFiles = sourceDirectory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.i18n.json') && !file.path.endsWith('en.i18n.json'),
    );

    for (final path in recoveryPaths) {
      expect(_valueAt(english, path), isNotEmpty, reason: 'English base value ${path.join('.')} must be usable');
      for (final localeFile in localeFiles) {
        final locale = _decodeLocale(localeFile);
        final value = _valueAt(locale, path);
        expect(value, anyOf(isNull, isNotEmpty), reason: '${localeFile.path} must omit or translate ${path.join('.')}');
      }
    }
  });
}

Map<String, dynamic> _decodeLocale(File file) => jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

String? _valueAt(Map<String, dynamic> locale, List<String> path) {
  Object? value = locale;
  for (final segment in path) {
    if (value is! Map<String, dynamic> || !value.containsKey(segment)) return null;
    value = value[segment];
  }
  return value as String?;
}
