import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// The negative control for the Linux HDR startup tolerance.
///
/// Swallowing a refused `hdr-enabled` write is scoped to the Linux video path;
/// everywhere else an unexpected refusal must still abort initialization, which
/// is the behaviour that shipped before this feature. Without this test the
/// tolerance could be widened to every platform and both sibling tests would
/// still pass.
///
/// Separate file, one test - see installHdrStartupHarness for why these cannot
/// share an isolate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => installHdrStartupHarness(linuxVideoPath: false));

  testWidgets('a refusal still aborts startup off the Linux video path', (tester) async {
    await expectStartupAbortsOnHdrRefusal(
      tester,
      PlatformException(code: 'HDR_UNSUPPORTED', message: 'output is not in HDR'),
    );
  });
}
