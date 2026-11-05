import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

import '../../test_helpers/pump.dart';
import '../../test_helpers/server_limit_harness.dart';

/// HTTP 500 on an Original Plex open: the dialog offers a transcode, and
/// picking it reopens the item at Original with direct play withheld, so the
/// server picks the output and the raw file is never requested again. One
/// test per file: a second screen in the same isolate never reaches
/// `initialize` (see [installHdrStartupHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final harness = ServerLimitHarness();
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('the server-limit dialog offers a transcode and picking it opens a forced Original transcode', (
    tester,
  ) async {
    await runServerLimitPlayer(
      tester,
      harness: harness,
      preset: TranscodeQualityPreset.original,
      refuses: (_, url) => url == serverLimitRawUrl,
      body: (run) async {
        await pumpUntil(
          tester,
          () => run.dialogTitle.evaluate().isNotEmpty,
          describe: () => 'loadfiles=${run.loadfileUrls}, no server-limit dialog',
        );
        expect(run.loadfileUrls, [serverLimitRawUrl]);
        expect(run.playButton, findsOneWidget);
        expect(find.text(t.common.close), findsOneWidget);

        await tester.tap(run.playButton);
        await pumpUntil(
          tester,
          () => run.loadfileUrls.length == 2,
          describe: () => 'loadfiles=${run.loadfileUrls}, no second open',
        );
        expect(run.loadfileUrls[1], serverLimitTranscodeUrl(TranscodeQualityPreset.original));

        final reopen = run.client.requests.last;
        expect(reopen.qualityPreset, TranscodeQualityPreset.original, reason: 'no cap of ours; the server picks');
        expect(reopen.forceTranscode, isTrue, reason: 'Original must not serve the refused file again');

        await pumpUntil(
          tester,
          () => run.key.currentState!.debugMediaControlsActiveForTesting,
          describe: () => 'the transcode never came up as playback',
        );
        expect(run.dialogTitle, findsNothing);
        expect(find.text('Browse'), findsNothing, reason: 'the player stays up on the transcode');
      },
    );
  });
}
