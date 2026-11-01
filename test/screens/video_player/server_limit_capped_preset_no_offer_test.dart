import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

import '../../test_helpers/pump.dart';
import '../../test_helpers/server_limit_harness.dart';

/// A request that was already a capped transcode gets today's dialog: the
/// offer is only for a refused Original file. Live TV is covered by
/// server_limit_transcode_offer_test.dart. One test per file (see
/// [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final harness = ServerLimitHarness();
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('a 500 on a capped preset shows the dialog without the offer', (tester) async {
    await runServerLimitPlayer(
      tester,
      harness: harness,
      preset: TranscodeQualityPreset.p720_3mbps,
      refuses: (_, _) => true,
      body: (run) async {
        await pumpUntil(
          tester,
          () => run.dialogTitle.evaluate().isNotEmpty,
          describe: () => 'loadfiles=${run.loadfileUrls}, no server-limit dialog',
        );
        expect(run.loadfileUrls, [serverLimitTranscodeUrl(TranscodeQualityPreset.p720_3mbps)]);
        expect(run.playButton, findsNothing);

        await tester.tap(find.text(t.common.close));
        await pumpUntil(
          tester,
          () => find.text('Browse').evaluate().isNotEmpty,
          describe: () => 'Close did not leave the player',
        );
        expect(run.loadfileUrls, hasLength(1));
      },
    );
  });
}
