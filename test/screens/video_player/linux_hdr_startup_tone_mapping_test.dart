import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// Startup pushes the stored tone-mapping mode at the plane, and the refusal is
/// swallowed for the same reason `hdr-enabled`'s is: an older libmpv rejects the
/// property outright, and a tone-mapping preference is no reason to fail
/// playback. And as with `hdr-enabled`, the plugin holds a mode of its own and
/// reverts it on a refused transaction, so swallowing alone leaves Dart naming
/// `player` while the plane tone-maps in the compositor - a disagreement the
/// settings sheet renders and no later write corrects.
///
/// Dropping the correction in video_player_screen.dart makes this fail on the
/// stored-mode expectation. See installHdrStartupHarness for why this case needs
/// an isolate of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('a refused tone-mapping write leaves the stored mode matching the plane', (tester) async {
    await expectRefusedToneMappingRestoresStoredMode(
      tester,
      PlatformException(code: 'SET_PROPERTY_FAILED', message: 'property not found'),
    );
  });
}
