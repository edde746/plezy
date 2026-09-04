import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// A refused subtitle-styling write used to escape _runPlayerInitializationAttempt
/// into the initialization error screen on every open (mpv refuses a colour
/// value its OPT_COLOR parser cannot read with MPV_ERROR_PROPERTY_FORMAT).
/// Styling is a preference, so the refusal is now contained: the write is
/// attempted, logged, and playback continues with mpv's own default styling.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('a refused subtitle style write does not abort initialization', (tester) async {
    await expectSubtitleStyleRefusalDoesNotAbortStartup(tester);
  });
}
