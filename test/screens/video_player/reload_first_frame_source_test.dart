import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/player_screen_harness.dart';
import '../../test_helpers/pump.dart';

/// An in-place reload resets the first-frame latch before `loadfile`, while
/// the outgoing file is still mpv's active source. A `playback-restart` of
/// that file landing in the window used to latch the replacement as rendered
/// before it had decoded anything: the spinner dropped over a stale picture
/// and everything keyed to the first frame ran against the wrong stream. The
/// latch now waits for the attempt's own file. One test per file (see
/// [PlayerScreenHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final harness = PlayerScreenHarness();
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('a restart of the outgoing file during a reload does not reveal the replacement early', (tester) async {
    final loadfileUrls = <String>[];

    await runPlayerScreen(
      tester,
      harness: harness,
      client: _StreamClient(),
      screen: (key) => VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(
          id: 'reload-source',
          serverId: 'srv-1',
          title: 'Reload source',
          backend: MediaBackend.jellyfin,
        ),
        selectedQualityPreset: TranscodeQualityPreset.original,
      ),
      onLoadfile: (run, url) {
        loadfileUrls.add(url);
        if (loadfileUrls.length == 1) {
          run.player.handlePlayerEvent('start-file', {'sourceId': 1});
          run.player.handlePlayerEvent('file-loaded', {'sourceId': 1});
          run.player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 0.0});
        } else {
          // The reload has already reset its latch; mpv has not yet ended the
          // outgoing file, so a restart of it (a seek landing late) is still
          // the active source's.
          run.player.handlePlayerEvent('playback-restart', {'sourceId': 1, 'positionSeconds': 42.0});
        }
      },
      body: (run) async {
        await pumpUntil(
          tester,
          () => run.hasFirstFrame?.value == true,
          describe: () => 'loadfiles=$loadfileUrls, first frame never revealed',
        );

        final outcome = await run.switchSource(
          (state) => state.debugSwitchPlaybackSourceForTesting(newPreset: TranscodeQualityPreset.p720_2mbps),
        );
        expect(outcome, PlaybackSourceChangeOutcome.applied);
        expect(loadfileUrls, hasLength(2));
        expect(loadfileUrls[1], endsWith('/p720_2mbps'));
        await tester.pump();

        expect(
          run.hasFirstFrame?.value,
          isFalse,
          reason: 'the outgoing file\'s restart must not stand in for the replacement\'s first frame',
        );

        run.player.handlePlayerEvent('end-file', {'sourceId': 1, 'reason': 2});
        run.player.handlePlayerEvent('start-file', {'sourceId': 2});
        run.player.handlePlayerEvent('file-loaded', {'sourceId': 2});
        run.player.handlePlayerEvent('playback-restart', {'sourceId': 2, 'positionSeconds': 0.0});
        await pumpUntil(
          tester,
          () => run.hasFirstFrame?.value == true,
          describe: () => 'the replacement\'s own first frame never revealed',
        );
      },
    );
  });
}

/// Names the requested preset in the URL so each open says which request
/// produced it.
class _StreamClient extends FakeStreamClient {
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async =>
      PlaybackInitializationResult(
        availableVersions: const [],
        videoUrl: 'https://example.invalid/${options.metadata.id}/${options.qualityPreset.name}',
      );
}
