import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// The user's free-form mpv config is applied at the end of startup, after the
/// HDR preferences have been pushed. `hdr-enabled` and `hdr-tone-mapping` are
/// not mpv properties - the Linux plugin intercepts both and moves its own
/// persistent HDR state - so a config line naming either would win the plane
/// while SettingsService, which is the only thing the settings sheet renders
/// from, kept the app's value. Startup therefore refuses those two names in the
/// custom pass and logs the skip.
///
/// Removing the filter makes this fail on the write lists: the plane sees a
/// second `hdr-enabled`/`hdr-tone-mapping` carrying the config's value. See
/// installHdrStartupHarness for why this case needs an isolate of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('a custom config naming the HDR properties cannot override the stored preferences', (tester) async {
    await expectCustomConfigCannotOverrideHdrPreferences(tester);
  });
}
