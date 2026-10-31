import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

import '../../test_helpers/pump.dart';
import '../../test_helpers/server_limit_harness.dart';

/// The transcode is refused with HTTP 500 too: that is the server's
/// final answer, so the dialog comes back without the offer and nothing else
/// is opened. One test per file (see [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final harness = ServerLimitHarness();
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('a refused transcode shows the dialog without the offer and opens nothing more', (tester) async {
    await runServerLimitPlayer(
      tester,
      harness: harness,
      preset: TranscodeQualityPreset.original,
      refuses: (_, _) => true,
      body: (run) async {
        await pumpUntil(
          tester,
          () => run.playButton.evaluate().isNotEmpty,
          describe: () => 'loadfiles=${run.loadfileUrls}, no offer on the first 500',
        );
        await tester.tap(run.playButton);
        await pumpUntil(
          tester,
          () => run.loadfileUrls.length == 2,
          describe: () => 'loadfiles=${run.loadfileUrls}, no second open',
        );
        expect(run.loadfileUrls[1], serverLimitTranscodeUrl(TranscodeQualityPreset.original));

        await pumpUntil(
          tester,
          () => run.dialogTitle.evaluate().isNotEmpty,
          describe: () => 'no dialog after the transcode was refused',
        );
        expect(run.playButton, findsNothing, reason: 'one transcode attempt per item');
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(run.loadfileUrls, hasLength(2), reason: 'no third open after the second refusal');
        expect(run.dialogTitle, findsOneWidget);

        await tester.tap(find.text(t.common.close));
        await pumpUntil(
          tester,
          () => find.text('Browse').evaluate().isNotEmpty,
          describe: () => 'Close did not leave the player',
        );
        expect(run.loadfileUrls, hasLength(2));
      },
    );
  });
}
