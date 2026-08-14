import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// The user's free-form mpv config is applied as runtime mpv_set_property
/// writes, and the embedded renderer owns the windowed-VO family: a
/// `vo=gpu-next` line (with the gpu-context/gpu-api it rides on) makes mpv
/// re-create its output as a separate, uncontrollable window and orphans the
/// embedded plane. Startup therefore skips those three names in the custom
/// pass and logs the skip with the real reason.
///
/// Removing the filter makes this fail on the write lists: `vo` reaches mpv
/// and the plane is orphaned. See installHdrStartupHarness for why this case
/// needs an isolate of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('a custom config naming the embedded VO family cannot detach the renderer', (tester) async {
    await expectCustomConfigCannotOverrideEmbeddedVo(tester);
  });
}
