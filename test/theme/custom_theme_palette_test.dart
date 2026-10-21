import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_export_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/palette_contrast.dart';

import '../test_helpers/prefs.dart';

const _palette = MonoPalette(
  bg: Color(0xFF101820),
  surface: Color(0xFF1B2733),
  outline: Color(0x33FFFFFF),
  text: Color(0xFFF2F2F2),
  textMuted: Color(0xB3F2F2F2),
  accent: Color(0xFFFFB000),
);

final _key = SettingsService.customThemePalette.key;

Future<SettingsService> _restart() async {
  BaseSharedPreferencesService.resetForTesting();
  SettingsService.resetForTesting();
  return SettingsService.getInstance();
}

void main() {
  setUp(resetSharedPreferencesForTest);

  group('custom theme palette pref', () {
    test('is unset until saved, then survives a restart colour for colour', () async {
      var settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.customThemePalette), isNull);

      await settings.write(SettingsService.customThemePalette, _palette);
      settings = await _restart();

      final restored = settings.read(SettingsService.customThemePalette);
      expect(restored, _palette);
      // Alpha is part of every colour, not only the opaque ones.
      expect(restored!.outline.toARGB32(), 0x33FFFFFF);
      expect(restored.textMuted.toARGB32(), 0xB3F2F2F2);
    });

    test('stores readable #AARRGGBB colours keyed by slot', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.customThemePalette, _palette);
      expect(jsonDecode(settings.prefs.getString(_key)!), {
        'bg': '#FF101820',
        'surface': '#FF1B2733',
        'outline': '#33FFFFFF',
        'text': '#FFF2F2F2',
        'textMuted': '#B3F2F2F2',
        'accent': '#FFFFB000',
      });
    });

    final complete = _palette.toJson();
    for (final (name, stored) in [
      ('not JSON', '{bg: oops'),
      ('a JSON list', jsonEncode([complete])),
      ('missing a colour', jsonEncode({...complete}..remove('accent'))),
      ('a colour that is not hex', jsonEncode({...complete, 'text': 'white'})),
      ('a colour of the wrong length', jsonEncode({...complete, 'bg': '#12345'})),
      ('a colour stored as a number', jsonEncode({...complete, 'surface': 0xFF1B2733})),
    ]) {
      test('$name reads as no palette instead of throwing', () async {
        resetSharedPreferencesForTest(initialAsync: {_key: stored});
        final settings = await SettingsService.getInstance();
        expect(settings.read(SettingsService.customThemePalette), isNull);
      });
    }

    test('a value of the wrong storage type reads as no palette', () async {
      resetSharedPreferencesForTest(initialAsync: {_key: 42});
      final settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.customThemePalette), isNull);
    });

    test('accepts #RRGGBB as opaque and ignores keys it does not know', () {
      final palette = MonoPalette.fromJson({...complete, 'bg': '#101820', 'future': '#FFFFFFFF'});
      expect(palette, _palette);
    });

    test('travels in a settings export and is cleared by Reset All Settings', () async {
      var settings = await SettingsService.getInstance();
      await settings.write(SettingsService.customThemePalette, _palette);
      final export = SettingsExportService.buildExportMap(settings.prefs, currentUserUuid: 'alice');
      expect((export['prefs'] as Map)[_key], {'type': 'string', 'value': jsonEncode(_palette.toJson())});

      await settings.resetAllSettings();
      expect(settings.read(SettingsService.customThemePalette), isNull);

      final result = await SettingsExportService.applyImportMap(export, settings.prefs, currentUserUuid: 'bob');
      expect(result.keysSkipped, 0);
      settings = await _restart();
      expect(settings.read(SettingsService.customThemePalette), _palette);
    });

    test('an import carrying a broken palette is skipped and leaves the saved one', () async {
      var settings = await SettingsService.getInstance();
      await settings.write(SettingsService.customThemePalette, _palette);

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            _key: {
              'type': 'string',
              'value': jsonEncode({..._palette.toJson()}..remove('bg')),
            },
          },
        },
        settings.prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 0);
      expect(result.keysSkipped, 1);
      settings = await _restart();
      expect(settings.read(SettingsService.customThemePalette), _palette);
    });
  });

  group('hex colours', () {
    test('parse #RRGGBB as opaque and #AARRGGBB with alpha, with or without #', () {
      expect(tryParseHexColor('#1a2B3c'), const Color(0xFF1A2B3C));
      expect(tryParseHexColor('801A2B3C'), const Color(0x801A2B3C));
      expect(tryParseHexColor(' #00000000 '), const Color(0x00000000));
      for (final invalid in ['', '#', '#12345', '#1234567', '#GGGGGG', 'red', '#123456789']) {
        expect(tryParseHexColor(invalid), isNull, reason: invalid);
      }
    });

    test('print as upper-case #AARRGGBB', () {
      expect(colorToArgbHex(const Color(0x0A1b2c3d)), '#0A1B2C3D');
    });
  });

  group('contrast checks', () {
    test('every built-in and preset palette passes all of them', () {
      for (final palette in [
        MonoPalette.light,
        MonoPalette.dark,
        MonoPalette.oled,
        MonoPalette.ember,
        MonoPalette.glacier,
        MonoPalette.forest,
        MonoPalette.plum,
        MonoPalette.paper,
      ]) {
        expect(PaletteContrastCheck.failing(palette), isEmpty, reason: '$palette');
      }
    });

    test('text on the page fails just under 4.5:1 and passes at it', () {
      // #767676 on white is the classic 4.54:1; #777777 is 4.48:1.
      final page = MonoPalette.light.withColor(MonoPaletteSlot.bg, const Color(0xFFFFFFFF));
      final passing = page.withColor(MonoPaletteSlot.text, const Color(0xFF767676));
      final failing = page.withColor(MonoPaletteSlot.text, const Color(0xFF777777));
      expect(PaletteContrastCheck.textOnBg.passes(passing), isTrue);
      expect(PaletteContrastCheck.textOnBg.passes(failing), isFalse);
      expect(PaletteContrastCheck.textOnBg.ratioIn(failing), closeTo(4.48, 0.01));
    });

    test('the accent needs only 3:1 against the page', () {
      // #949494 on white is 3.03:1; #959595 is 2.99:1.
      final page = MonoPalette.light.withColor(MonoPaletteSlot.bg, const Color(0xFFFFFFFF));
      expect(
        PaletteContrastCheck.accentOnBg.passes(page.withColor(MonoPaletteSlot.accent, const Color(0xFF949494))),
        isTrue,
      );
      expect(
        PaletteContrastCheck.accentOnBg.passes(page.withColor(MonoPaletteSlot.accent, const Color(0xFF959595))),
        isFalse,
      );
    });

    test('translucent text is judged as painted over its background', () {
      // Opaque black on white passes easily; at 20% it is a pale grey.
      final page = MonoPalette.light.withColor(MonoPaletteSlot.bg, const Color(0xFFFFFFFF));
      final faint = page.withColor(MonoPaletteSlot.textMuted, const Color(0x33000000));
      expect(PaletteContrastCheck.textMutedOnBg.passes(faint), isFalse);
      expect(PaletteContrastCheck.textMutedOnBg.ratioIn(faint), lessThan(2));
    });
  });
}
