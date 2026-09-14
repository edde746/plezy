import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// On Linux the `hdr-enabled` write must survive *whatever* it fails with, not
/// only the one code the native plane answers with today.
///
/// The refusal used here deliberately carries no HDR-specific code, because the
/// tolerance has to hold for more than one failure. `HDR_UNSUPPORTED` is the
/// plane saying it can never carry HDR, but a refused colour transaction - mpv
/// declining one of the four output properties - comes back as a generic
/// property failure instead. A narrow `if (code != 'HDR_UNSUPPORTED') rethrow`
/// would pass every other test in the suite and still turn "this session cannot
/// do HDR" into "this session cannot play video". Why the tolerance exists at
/// all is documented where it lives, in VideoPlayerScreen.
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
