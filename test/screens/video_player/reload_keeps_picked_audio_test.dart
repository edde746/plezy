import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_subtitle_resolver.dart';
import 'package:plezy/services/track_selection_service.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/player_screen_harness.dart';
import '../../test_helpers/pump.dart';

/// A pick in the player's audio list must survive a reload: the reload
/// carries the committed source stream, which the pick has to move. One test
/// per file (see [PlayerScreenHarness]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final harness = PlayerScreenHarness();
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('a reload carries the audio picked in the player, not the stream first opened', (tester) async {
    final client = _StreamClient();
    var loads = 0;
    // The engine's audio list, in source order; the selected one plays.
    var playing = 'eng';

    void emitTrackList(PlayerScreenRun run, int sourceId) => run.player.handlePropertyChange('track-list', [
      for (final (index, language) in ['eng', 'fre', 'ger'].indexed)
        {'type': 'audio', 'id': '${index + 1}', 'lang': language, 'selected': language == playing},
    ], sourceId: sourceId);

    await runPlayerScreen(
      tester,
      harness: harness,
      client: client,
      screen: (key) => VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(id: 'film', serverId: 'srv-1', title: 'Film', backend: MediaBackend.jellyfin),
        selectedQualityPreset: TranscodeQualityPreset.original,
        // The account's audio language, which the first open resolves to row 4.
        preferredAudioTrack: const AudioTrack(id: 'pref', language: 'eng'),
      ),
      onLoadfile: (run, url) {
        final sourceId = ++loads;
        run.player.handlePlayerEvent('start-file', {'sourceId': sourceId});
        emitTrackList(run, sourceId);
        run.player.handlePlayerEvent('file-loaded', {'sourceId': sourceId});
        run.player.handlePlayerEvent('playback-restart', {'sourceId': sourceId, 'positionSeconds': 0.0});
      },
      body: (run) async {
        await pumpUntil(tester, () => run.hasFirstFrame?.value == true, describe: () => 'first frame never revealed');
        expect(client.opens.single.preferredAudioTrack?.language, 'eng');

        // French picked in the player; then a downloaded subtitle reloads.
        playing = 'fre';
        emitTrackList(run, loads);
        await run.state.debugPickAudioTrackForTesting(run.player.state.track.audio!);
        final downloaded = MediaSubtitleTrack(id: 9, languageCode: 'ger', codec: 'srt', selected: false, forced: false);
        expect(
          await run.switchSource(
            (state) => state.debugSwitchPlaybackSourceForTesting(
              newSubtitleChoice: PlaybackSourceSubtitleChoice.downloaded(downloaded),
            ),
          ),
          PlaybackSourceChangeOutcome.applied,
        );
        expect(client.opens, hasLength(2));
        expect(client.opens.last.preferredAudioTrack?.language, 'fre', reason: 'the reload carries the pick');
        expect(client.opens.last.selectedAudioStreamId, isNull, reason: 'the rescan may have renumbered the streams');

        // The cycle-audio hotkey moves on to German; then a quality switch reloads.
        run.state.debugCycleAudioTrackForTesting();
        playing = 'ger';
        emitTrackList(run, loads);
        await tester.pump();
        expect(
          await run.switchSource(
            (state) => state.debugSwitchPlaybackSourceForTesting(newPreset: TranscodeQualityPreset.p720_2mbps),
          ),
          PlaybackSourceChangeOutcome.applied,
        );
        expect(client.opens, hasLength(3));
        expect(client.opens.last.selectedAudioStreamId, 6, reason: 'the reload carries the cycled track');
      },
    );
  });
}

/// A Jellyfin file with English, French and German audio (rows 4, 5 and 6),
/// recording every open it is asked for. Like [JellyfinClient], it reports as
/// active the stream it was asked for, by id or by intent, or none.
class _StreamClient extends FakeStreamClient {
  final opens = <PlaybackInitializationOptions>[];

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    opens.add(options);
    final url = 'https://example.invalid/${options.metadata.id}/${opens.length}';
    final rows = [
      for (final (id, language) in [(4, 'eng'), (5, 'fre'), (6, 'ger')])
        MediaAudioTrack(id: id, languageCode: language, codec: 'aac', channels: 2, selected: id == 4),
    ];
    final preferred = options.preferredAudioTrack;
    return PlaybackInitializationResult(
      availableVersions: const [],
      videoUrl: url,
      activeAudioStreamId:
          options.selectedAudioStreamId ??
          (preferred == null ? null : findSourceAudioTrackForIntent(preferred, rows)?.id),
      mediaInfo: MediaSourceInfo(videoUrl: url, audioTracks: rows, subtitleTracks: const [], chapters: const []),
    );
  }
}
