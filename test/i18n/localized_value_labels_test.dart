import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';

void main() {
  test('user-facing and accessibility labels are populated in every locale', () async {
    for (final locale in AppLocale.values) {
      final translations = await locale.build();
      final labels = <String, String>{
        'hotkeys.pressToRecord': translations.hotkeys.pressToRecord,
        'hotkeys.recordingShortcut': translations.hotkeys.recordingShortcut,
        'accessibility.expandText': translations.accessibility.expandText,
        'accessibility.collapseText': translations.accessibility.collapseText,
        'watchTogether.openSessionControls': translations.watchTogether.openSessionControls,
        'watchTogether.copySessionCode': translations.watchTogether.copySessionCode,
        'services.deviceCode.copyCode': translations.services.deviceCode.copyCode,
        'services.oauthProxy.copyUrl': translations.services.oauthProxy.copyUrl,
      };

      for (final MapEntry(key: key, value: value) in labels.entries) {
        expect(value.trim(), isNotEmpty, reason: '${locale.languageCode}: $key');
      }
    }
  });
}
