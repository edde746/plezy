import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/hdr_startup.dart';

/// The user's free-form mpv config follows mpv.conf syntax, where quotes
/// around a value belong to the syntax, not the value. The entries are applied
/// as runtime mpv_set_property writes, which take strings verbatim, so the
/// parser strips one pair of matching quotes; otherwise `sub-font =
/// 'NetflixSans-Bold'` names a family that does not exist and silently falls
/// back, and `sub-blur = '0.2'` fails mpv's float parse (#2025).
///
/// Removing the stripping makes this fail on the write lists: the quotes reach
/// the wire. See installHdrStartupHarness for why this case needs an isolate
/// of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installHdrStartupHarness);

  testWidgets('quoted custom config values reach mpv unquoted', (tester) async {
    await expectQuotedCustomConfigValuesReachWireUnquoted(tester);
  });
}
