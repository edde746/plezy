import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// Startup pushes the HDR preference at a native plane that is allowed to refuse
/// it: the Linux plugin answers `HDR_UNSUPPORTED` when the video plane and
/// compositor cannot describe HDR, or the output the window sits on is not in HDR.
/// That gate runs before any source is considered - startup happens before the
/// media is open - so a plain SDR monitor is enough to trigger it, and losing
/// playback over it would make the feature worse than not having it.
///
/// `audio-delay` is the write immediately after the HDR block, so its arrival is
/// what says initialization carried on past the refusal - and it is asserted
/// *after* `hdr-enabled` so a refactor that reorders the two cannot leave this
/// test passing while proving nothing. Reinstating the rethrow makes it fail,
/// because `audio-delay` never arrives.
///
/// Its companion - that the tolerance is *not* narrowed to `HDR_UNSUPPORTED`,
/// so any refusal survives - is in linux_hdr_startup_refusal_test.dart; see
/// installHdrStartupHarness for why the two cannot share an isolate. The
/// negative control, that a non-Linux host still aborts, is in
/// linux_hdr_startup_non_linux_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('an SDR output refusing HDR passthrough does not stop playback starting', (tester) async {
    await expectStartupSurvivesHdrRefusal(
      tester,
      PlatformException(code: 'HDR_UNSUPPORTED', message: 'output is not in HDR'),
    );
  });
}
