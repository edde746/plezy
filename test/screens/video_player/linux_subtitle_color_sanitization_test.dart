import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';

import '../../test_helpers/hdr_startup.dart';

/// mpv 0.40's OPT_COLOR parser accepts only #RRGGBB/#AARRGGBB, so a stored
/// subtitle colour that does not parse (named colour, 3-digit hex) would make
/// the `sub-color`/`sub-border-color`/`sub-back-color` writes fail with
/// MPV_ERROR_PROPERTY_FORMAT. Startup canonicalizes the values to hex and
/// replaces unparseable ones with the defaults, so a bad preference degrades
/// to the default colour instead of failing playback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await installHdrStartupHarness();
    // Deliberately unparseable stored values: a named colour, a 3-digit hex,
    // and another named colour for the background (with a full opacity so the
    // composed sub-back-color is deterministic).
    await SettingsService.instance.write(SettingsService.subtitleTextColor, 'white');
    await SettingsService.instance.write(SettingsService.subtitleBorderColor, '#FFF');
    await SettingsService.instance.write(SettingsService.subtitleBackgroundColor, 'red');
    await SettingsService.instance.write(SettingsService.subtitleBackgroundOpacity, 100);
  });

  testWidgets('unparseable subtitle colours are canonicalized to defaults on the wire', (tester) async {
    await expectSanitizedSubtitleColorsOnTheWire(tester);
  });
}
