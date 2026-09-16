import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// A runner linked against a distro libmpv older than the pinned build (Ubuntu
/// 24.04's 2.2.0 / mpv 0.37) refuses `sub-ass-video-aspect-override` (mpv 0.39+)
/// with MPV_ERROR_PROPERTY_NOT_FOUND. Unwrapped, that escaped
/// _runPlayerInitializationAttempt into the error screen on every open, so a
/// source/AUR build had no playback at all. The write is a preference: it is
/// attempted, logged, and the sibling writes and initialization run on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('an unknown subtitle property refusal does not abort initialization', (tester) async {
    await expectUnknownSubtitlePropertyRefusalDoesNotAbortStartup(tester);
  });
}
