import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// On Linux the `hdr-enabled` write must survive *whatever* it fails with, not
/// only the one code the native plane answers with today.
///
/// The refusal used here is what an older libmpv actually produces: the plugin
/// only intercepts `hdr-enabled` while it can describe the plane, and otherwise
/// the write falls through to mpv as `target-colorspace-hint=auto`, which is
/// only a legal value from mpv 0.40 - newer than the libmpv the distro packages
/// link on every current LTS. That comes back as a generic property failure
/// carrying no HDR-specific code, so a narrow `if (code != 'HDR_UNSUPPORTED')
/// rethrow` would pass every other test in the suite and still turn "this
/// session cannot do HDR" into "this session cannot play video". Why the
/// tolerance exists at all is documented where it lives, in VideoPlayerScreen.
///
/// Separate file, one test - see installHdrStartupHarness for why these cannot
/// share an isolate. The negative control is in
/// linux_hdr_startup_non_linux_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('a refusal that is not HDR_UNSUPPORTED still does not stop playback starting', (tester) async {
    await expectStartupSurvivesHdrRefusal(
      tester,
      PlatformException(code: 'SET_PROPERTY_FAILED', message: 'property not found'),
    );
  });
}
