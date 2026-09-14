import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// The other arm of the preference. linux_hdr_startup_test.dart covers a stored
/// `true`, which on its own cannot tell "sends the preference" apart from "sends
/// `yes`": with HDR turned off, startup owes the plane an explicit `no` - the
/// property is not simply skipped, since the plane may still be describing HDR
/// from a previous session and would otherwise keep passthrough on.
///
/// Its own file because a second `VideoPlayerScreen` in the same isolate never
/// reaches `initialize` - see installHdrStartupHarness.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => installHdrStartupHarness(enableHdr: false));

  testWidgets('HDR turned off sends the passthrough preference as no', (tester) async {
    await expectStartupSurvivesHdrRefusal(
      tester,
      PlatformException(code: 'HDR_UNSUPPORTED', message: 'output is not in HDR'),
      title: 'Linux HDR disabled startup video',
    );
  });
}
