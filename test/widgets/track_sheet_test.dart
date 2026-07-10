import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/widgets/video_controls/models/track_controls_state.dart';
import 'package:plezy/widgets/video_controls/sheets/track_sheet.dart';

const _testTokens = MonoTokens(
  radiusSm: 8,
  radiusMd: 12,
  radiusLg: 20,
  radiusXs: 5,
  groupGap: 2,
  space: 8,
  fast: Duration(milliseconds: 1),
  normal: Duration(milliseconds: 1),
  slow: Duration(milliseconds: 1),
  expressive: Duration(milliseconds: 1),
  bg: Colors.black,
  surface: Colors.black,
  outline: Colors.white24,
  text: Colors.white,
  textMuted: Colors.white70,
  splashFactory: NoSplash.splashFactory,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('TrackSheet subtitle controls', () {
    testWidgets('shows subtitle search when Plex search is available without subtitle tracks', (tester) async {
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          audio: [
            AudioTrack(id: 'a1'),
            AudioTrack(id: 'a2'),
          ],
        ),
        track: const TrackSelection(
          audio: AudioTrack(id: 'a1'),
          subtitle: SubtitleTrack.off,
        ),
      );

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: const TrackControlsState(
          ratingKey: '123',
          serverId: 'plex-server',
          subtitleSearchSupported: true,
        ),
      );

      expect(find.text('Search Subtitles'), findsOneWidget);
    });

    testWidgets('hides subtitle search when external subtitle search is unsupported', (tester) async {
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          audio: [
            AudioTrack(id: 'a1'),
            AudioTrack(id: 'a2'),
          ],
        ),
        track: const TrackSelection(
          audio: AudioTrack(id: 'a1'),
          subtitle: SubtitleTrack.off,
        ),
      );

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: const TrackControlsState(
          ratingKey: '123',
          serverId: 'jellyfin-server',
          subtitleSearchSupported: false,
        ),
      );

      expect(find.text('Search Subtitles'), findsNothing);
    });
  });

  group('TrackSheet two-line labels', () {
    testWidgets('renders language as the primary line and tech detail below', (tester) async {
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          audio: [
            AudioTrack(id: 'a1', language: 'eng', codec: 'aac', channels: 2),
            AudioTrack(
              id: 'a2',
              title: 'Dolby Digital Plus 5.1 with Atmos',
              language: 'ta',
              codec: 'eac3',
              channels: 6,
            ),
          ],
        ),
        track: const TrackSelection(
          audio: AudioTrack(id: 'a1', language: 'eng', codec: 'aac', channels: 2),
          subtitle: SubtitleTrack.off,
        ),
      );

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: const TrackControlsState(subtitleSearchSupported: false),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('AAC · Stereo'), findsOneWidget);
      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('Dolby Digital Plus 5.1 with Atmos · E-AC3 · 5.1'), findsOneWidget);
    });
  });

  group('TrackControlsState.hasSubtitleControls', () {
    test('counts source subtitles only when source switching is available', () {
      final sourceSubtitle = MediaSubtitleTrack(id: 1, selected: false, forced: false);

      expect(
        TrackControlsState(
          isTranscoding: true,
          sourceSubtitleTracks: [sourceSubtitle],
        ).hasSubtitleControls(const Tracks()),
        isFalse,
      );
      expect(
        TrackControlsState(
          isTranscoding: true,
          sourceSubtitleTracks: [sourceSubtitle],
          onSwitchSubtitleStreamId: (_) {},
        ).hasSubtitleControls(const Tracks()),
        isTrue,
      );
    });

    test('ignores player subtitle placeholders', () {
      const state = TrackControlsState(subtitleSearchSupported: false);

      expect(state.hasSubtitleControls(const Tracks(subtitle: [SubtitleTrack.auto, SubtitleTrack.off])), isFalse);
      expect(state.hasSubtitleControls(const Tracks(subtitle: [SubtitleTrack(id: 's1')])), isTrue);
    });
  });
}

Future<void> _pumpTrackSheet(
  WidgetTester tester, {
  required Player player,
  required TrackControlsState trackControlsState,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [_testTokens]),
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: 400,
          child: TrackSheet(player: player, trackControlsState: trackControlsState),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeTrackSheetPlayer implements Player {
  _FakeTrackSheetPlayer({required Tracks tracks, required TrackSelection track})
    : _state = PlayerState(tracks: tracks, track: track),
      _streams = PlayerStreams(
        playing: const Stream<bool>.empty(),
        completed: const Stream<bool>.empty(),
        buffering: const Stream<bool>.empty(),
        position: const Stream<Duration>.empty(),
        duration: const Stream<Duration>.empty(),
        seekable: const Stream<bool>.empty(),
        buffer: const Stream<Duration>.empty(),
        volume: const Stream<double>.empty(),
        rate: const Stream<double>.empty(),
        tracks: const Stream<Tracks>.empty(),
        track: const Stream<TrackSelection>.empty(),
        log: const Stream<PlayerLog>.empty(),
        error: const Stream<PlayerError>.empty(),
        audioDevice: const Stream<AudioDevice>.empty(),
        audioDevices: const Stream<List<AudioDevice>>.empty(),
        bufferRanges: const Stream<List<BufferRange>>.empty(),
        playbackRestart: const Stream<void>.empty(),
        backendSwitched: const Stream<void>.empty(),
      );

  final PlayerState _state;
  final PlayerStreams _streams;

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

  @override
  bool get supportsSecondarySubtitles => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
