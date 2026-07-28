import 'dart:async';

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/playback_subtitle_resolver.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/models/track_controls_state.dart';
import 'package:plezy/widgets/video_controls/sheets/track_sheet.dart';

import '../test_helpers/theme.dart';

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

    testWidgets('keeps source stream zero distinct from turning subtitles off', (tester) async {
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(),
        track: const TrackSelection(subtitle: SubtitleTrack.off),
      );
      PlaybackSourceSubtitleChoice? switchedChoice;

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: TrackControlsState(
          isTranscoding: true,
          sourceSubtitleTracks: [MediaSubtitleTrack(id: 0, title: 'Stream zero', selected: false, forced: false)],
          selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.off(),
          onSwitchSubtitle: (choice) async {
            switchedChoice = choice;
          },
          subtitleSearchSupported: false,
        ),
      );

      await tester.tap(find.text('Stream zero'));
      expect(switchedChoice, const PlaybackSourceSubtitleChoice.source(0));
    });

    testWidgets('keeps an unloaded source sidecar selectable', (tester) async {
      const remoteUri = 'https://example.test/source/remote.ass';
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          subtitle: [SubtitleTrack(id: 's1', language: 'eng', codec: 'srt')],
        ),
        track: const TrackSelection(
          subtitle: SubtitleTrack(id: 's1', language: 'eng', codec: 'srt'),
        ),
      );
      PlaybackSourceSubtitleChoice? switchedSourceChoice;

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: TrackControlsState(
          sourceSubtitleTracks: [
            MediaSubtitleTrack(id: 1, languageCode: 'eng', codec: 'srt', selected: true, forced: false),
            MediaSubtitleTrack(
              id: 2,
              title: 'Remote sidecar',
              codec: 'ass',
              external: true,
              selected: false,
              forced: false,
            ),
          ],
          selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(1),
          sourceSubtitleSidecars: [
            PlaybackSubtitleSidecar(
              sourceStreamId: 2,
              track: SubtitleTrack.uri(remoteUri, title: 'Remote sidecar', codec: 'ass'),
            ),
          ],
          onSwitchSubtitle: (choice) async {
            switchedSourceChoice = choice;
          },
          subtitleSearchSupported: false,
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Remote sidecar'), findsOneWidget);

      await tester.tap(find.text('Remote sidecar'));
      expect(switchedSourceChoice, const PlaybackSourceSubtitleChoice.source(2));
    });

    testWidgets('does not duplicate a previously attached sidecar after selecting an embedded track', (tester) async {
      const remoteUri = 'https://example.test/source/attached.ass';
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          subtitle: [
            SubtitleTrack(id: 's1', language: 'eng', codec: 'srt'),
            SubtitleTrack(id: 's2', title: 'Remote sidecar', codec: 'ass', isExternal: true, uri: remoteUri),
          ],
        ),
        track: const TrackSelection(
          subtitle: SubtitleTrack(id: 's1', language: 'eng', codec: 'srt'),
        ),
      );

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: TrackControlsState(
          sourceSubtitleTracks: [
            MediaSubtitleTrack(id: 1, languageCode: 'eng', codec: 'srt', selected: true, forced: false),
            MediaSubtitleTrack(
              id: 2,
              title: 'Remote sidecar',
              codec: 'ass',
              external: true,
              selected: false,
              forced: false,
            ),
          ],
          selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(1),
          sourceSubtitleSidecars: [
            PlaybackSubtitleSidecar(
              sourceStreamId: 2,
              track: SubtitleTrack.uri(remoteUri, title: 'Remote sidecar', codec: 'ass'),
            ),
          ],
          onSwitchSubtitle: (_) async {},
          subtitleSearchSupported: false,
        ),
      );

      expect(find.text('Remote sidecar'), findsOneWidget);
    });

    testWidgets('keeps an unloaded source sidecar beside an unrelated downloaded subtitle', (tester) async {
      const sourceUri = 'https://example.test/source/unloaded.ass';
      const downloadedUri = 'file:///tmp/downloaded.srt';
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          subtitle: [
            SubtitleTrack(id: 's1', title: 'Embedded subtitle', codec: 'srt'),
            SubtitleTrack(
              id: 'downloaded',
              title: 'Downloaded subtitle',
              codec: 'srt',
              isExternal: true,
              uri: downloadedUri,
            ),
          ],
        ),
        track: const TrackSelection(
          subtitle: SubtitleTrack(id: 's1', title: 'Embedded subtitle', codec: 'srt'),
        ),
      );

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: TrackControlsState(
          sourceSubtitleTracks: [
            MediaSubtitleTrack(
              id: 2,
              title: 'Remote sidecar',
              codec: 'ass',
              external: true,
              selected: false,
              forced: false,
            ),
          ],
          selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(1),
          sourceSubtitleSidecars: [
            PlaybackSubtitleSidecar(
              sourceStreamId: 2,
              track: SubtitleTrack.uri(sourceUri, title: 'Remote sidecar', codec: 'ass'),
            ),
          ],
          onSwitchSubtitle: (_) async {},
          subtitleSearchSupported: false,
        ),
      );

      expect(find.text('Downloaded subtitle'), findsOneWidget);
      expect(find.text('Remote sidecar'), findsOneWidget);
    });

    testWidgets('keeps a source sheet open until the async selection commits', (tester) async {
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          subtitle: [SubtitleTrack(id: 's1', language: 'eng', codec: 'srt')],
        ),
        track: const TrackSelection(
          subtitle: SubtitleTrack(id: 's1', language: 'eng', codec: 'srt'),
        ),
      );
      final selectionGate = Completer<void>();
      late BuildContext hostContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: OverlaySheetHost(
            child: Builder(
              builder: (context) {
                hostContext = context;
                return const Scaffold(body: SizedBox.expand());
              },
            ),
          ),
        ),
      );
      final sheetResult = OverlaySheetController.of(hostContext).show<void>(
        builder: (_) => SizedBox(
          height: 400,
          child: TrackSheet(
            player: player,
            trackControlsState: TrackControlsState(
              sourceSubtitleTracks: [
                MediaSubtitleTrack(id: 1, languageCode: 'eng', codec: 'srt', selected: true, forced: false),
                MediaSubtitleTrack(
                  id: 2,
                  title: 'Remote sidecar',
                  codec: 'ass',
                  external: true,
                  selected: false,
                  forced: false,
                ),
              ],
              selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(1),
              sourceSubtitleSidecars: [
                PlaybackSubtitleSidecar(
                  sourceStreamId: 2,
                  track: SubtitleTrack.uri(
                    'https://example.test/source/pending.ass',
                    title: 'Remote sidecar',
                    codec: 'ass',
                  ),
                ),
              ],
              onSwitchSubtitle: (_) => selectionGate.future,
              subtitleSearchSupported: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remote sidecar'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Remote sidecar'), findsOneWidget);

      selectionGate.complete();
      await tester.pumpAndSettle();
      await sheetResult;

      expect(find.text('Remote sidecar'), findsNothing);
    });

    testWidgets('direct-play embedded selection stays on the native player path', (tester) async {
      final player = _FakeTrackSheetPlayer(
        tracks: const Tracks(
          subtitle: [
            SubtitleTrack(id: 's1', language: 'eng', codec: 'srt'),
            SubtitleTrack(id: 's2', language: 'swe', codec: 'srt'),
          ],
        ),
        track: const TrackSelection(
          subtitle: SubtitleTrack(id: 's1', language: 'eng', codec: 'srt'),
        ),
      );
      PlaybackSourceSubtitleChoice? switchedSourceChoice;

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: TrackControlsState(
          sourceSubtitleTracks: [
            MediaSubtitleTrack(id: 1, languageCode: 'eng', selected: true, forced: false),
            MediaSubtitleTrack(id: 2, languageCode: 'swe', selected: false, forced: false),
          ],
          selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(1),
          onSwitchSubtitle: (choice) async {
            switchedSourceChoice = choice;
          },
          subtitleSearchSupported: false,
        ),
      );

      await tester.tap(find.text('Swedish'));

      expect(player.lastSelectedSubtitle?.id, 's2');
      expect(switchedSourceChoice, isNull);
    });

    testWidgets('does not append source sidecars already loaded as primary and secondary tracks', (tester) async {
      const primaryUri = 'https://example.test/source/primary.ass';
      const secondaryUri = 'https://example.test/source/secondary.ass';
      final player = _FakeTrackSheetPlayer(
        supportsSecondarySubtitles: true,
        tracks: const Tracks(
          subtitle: [
            SubtitleTrack(id: 's1', title: 'Primary sidecar', codec: 'ass', isExternal: true, uri: primaryUri),
            SubtitleTrack(id: 's2', title: 'Secondary sidecar', codec: 'ass', isExternal: true, uri: secondaryUri),
          ],
        ),
        track: const TrackSelection(
          subtitle: SubtitleTrack(id: 's1', title: 'Primary sidecar', codec: 'ass', isExternal: true, uri: primaryUri),
          secondarySubtitle: SubtitleTrack(
            id: 's2',
            title: 'Secondary sidecar',
            codec: 'ass',
            isExternal: true,
            uri: secondaryUri,
          ),
        ),
      );

      await _pumpTrackSheet(
        tester,
        player: player,
        trackControlsState: TrackControlsState(
          sourceSubtitleTracks: [
            MediaSubtitleTrack(
              id: 1,
              title: 'Primary sidecar',
              codec: 'ass',
              external: true,
              selected: true,
              forced: false,
            ),
            MediaSubtitleTrack(
              id: 2,
              title: 'Secondary sidecar',
              codec: 'ass',
              external: true,
              selected: false,
              forced: false,
            ),
          ],
          selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(1),
          selectedSecondarySubtitleStreamId: 2,
          sourceSubtitleSidecars: [
            PlaybackSubtitleSidecar(
              sourceStreamId: 1,
              track: SubtitleTrack.uri(primaryUri, title: 'Primary sidecar', codec: 'ass'),
            ),
            PlaybackSubtitleSidecar(
              sourceStreamId: 2,
              track: SubtitleTrack.uri(secondaryUri, title: 'Secondary sidecar', codec: 'ass'),
            ),
          ],
          onSwitchSubtitle: (_) async {},
          subtitleSearchSupported: false,
        ),
      );

      expect(find.text('Primary sidecar'), findsOneWidget);
      expect(find.text('Secondary sidecar'), findsOneWidget);
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

      final englishTile = find.ancestor(of: find.text('English'), matching: find.byType(ListTile));
      final tamilTile = find.ancestor(of: find.text('Tamil'), matching: find.byType(ListTile));
      expect(tester.getSemantics(englishTile).getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
      expect(tester.getSemantics(tamilTile).getSemanticsData().flagsCollection.isSelected, Tristate.isFalse);
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
          onSwitchSubtitle: (_) async {},
        ).hasSubtitleControls(const Tracks()),
        isTrue,
      );
    });

    test('counts direct-play source sidecars without replacing native tracks', () {
      const sourceUri = 'https://example.test/source/available.ass';
      final sourceSidecar = MediaSubtitleTrack(id: 1, external: true, selected: false, forced: false);
      final state = TrackControlsState(
        sourceSubtitleTracks: [sourceSidecar],
        sourceSubtitleSidecars: [
          PlaybackSubtitleSidecar(sourceStreamId: sourceSidecar.id, track: SubtitleTrack.uri(sourceUri)),
        ],
        onSwitchSubtitle: (_) async {},
      );

      expect(state.canUseSourceSubtitles, isFalse);
      expect(state.directPlaySourceSidecars, [sourceSidecar]);
      expect(state.hasSubtitleControls(const Tracks()), isTrue);
    });

    test('does not misclassify a Jellyfin external-delivery embedded row as a sidecar', () {
      final sourceTrack = MediaSubtitleTrack(id: 1, usesExternalDelivery: true, selected: false, forced: false);
      final state = TrackControlsState(sourceSubtitleTracks: [sourceTrack], onSwitchSubtitle: (_) async {});

      expect(state.directPlaySourceSidecars, isEmpty);
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
      theme: ThemeData(extensions: const [testMonoTokens]),
      home: OverlaySheetHost(
        child: Scaffold(
          body: SizedBox(
            width: 700,
            height: 400,
            child: TrackSheet(player: player, trackControlsState: trackControlsState),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeTrackSheetPlayer implements Player {
  _FakeTrackSheetPlayer({
    required Tracks tracks,
    required TrackSelection track,
    this.supportsSecondarySubtitles = false,
  }) : _state = PlayerState(tracks: tracks, track: track),
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
  SubtitleTrack? lastSelectedSubtitle;

  @override
  final bool supportsSecondarySubtitles;

  @override
  PlayerState get state => _state;

  @override
  PlayerStreams get streams => _streams;

  @override
  Future<void> selectSubtitleTrack(SubtitleTrack track) async {
    lastSelectedSubtitle = track;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
