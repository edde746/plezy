import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/widgets/video_controls/sheets/queue_sheet.dart';
import 'package:plezy/widgets/video_controls/widgets/content_strip.dart';
import 'package:plezy/widgets/video_controls/widgets/media_selector_thumbnail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

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

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('MediaSelectorThumbnail applies blur only to real thumbnails', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaSelectorThumbnail(
          width: 60,
          height: 34,
          thumbnail: ColoredBox(color: Colors.red),
          isCurrent: true,
          borderColor: Colors.white,
          blurThumbnail: true,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaSelectorThumbnail(
          width: 60,
          height: 34,
          thumbnail: null,
          isCurrent: true,
          borderColor: Colors.white,
          blurThumbnail: true,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('content strip queue blurs spoiler episode thumbnails', (tester) async {
    await SettingsService.instance.write(SettingsService.hideSpoilers, true);
    final playback = _playbackWithQueue();
    addTearDown(playback.dispose);

    await tester.pumpWidget(
      _queueHarness(
        playback: playback,
        child: ContentStrip(
          player: _FakePlayer(),
          chapters: const [],
          chaptersLoaded: true,
          canControl: true,
          showQueueTab: true,
          onQueueItemSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    final thumbnails = tester.widgetList<MediaSelectorThumbnail>(find.byType(MediaSelectorThumbnail)).toList();

    expect(thumbnails.map((thumbnail) => thumbnail.blurThumbnail), [true, false, false]);
  });

  testWidgets('denied chapter remains visible but touch and select do not seek', (tester) async {
    final playback = PlaybackStateProvider();
    addTearDown(playback.dispose);
    final player = _FakePlayer();
    final stripKey = GlobalKey<ContentStripState>();
    final chapter = MediaChapter(id: 1, startTimeOffset: 10000, title: 'Chapter One');

    await tester.pumpWidget(
      _queueHarness(
        playback: playback,
        child: ContentStrip(
          key: stripKey,
          player: player,
          chapters: [chapter],
          chaptersLoaded: true,
          canControl: false,
          useFocusNavigation: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Chapter One'), findsOneWidget);
    await tester.tap(find.text('Chapter One'));
    stripKey.currentState!.requestInitialFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(player.seeks, isEmpty);
  });

  testWidgets('authorized chapter touch seeks exactly once', (tester) async {
    final playback = PlaybackStateProvider();
    addTearDown(playback.dispose);
    final player = _FakePlayer();
    final chapter = MediaChapter(id: 1, startTimeOffset: 10000, title: 'Chapter One');

    await tester.pumpWidget(
      _queueHarness(
        playback: playback,
        child: ContentStrip(player: player, chapters: [chapter], chaptersLoaded: true, canControl: true),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Chapter One'));
    await tester.pump();
    expect(player.seeks, [const Duration(seconds: 10)]);
  });

  testWidgets('missing authorized queue callback keeps queue items non-interactive', (tester) async {
    final playback = _playbackWithQueue();
    addTearDown(playback.dispose);

    await tester.pumpWidget(
      _queueHarness(
        playback: playback,
        child: ContentStrip(
          player: _FakePlayer(),
          chapters: const [],
          chaptersLoaded: true,
          canControl: true,
          showQueueTab: true,
          onQueueItemSelected: null,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Spoiler Episode'), findsNothing);
  });

  testWidgets('queue sheet blurs spoiler episode thumbnails', (tester) async {
    await SettingsService.instance.write(SettingsService.hideSpoilers, true);
    final playback = _playbackWithQueue();
    addTearDown(playback.dispose);

    await tester.pumpWidget(
      _queueHarness(
        playback: playback,
        child: QueueSheet(onItemSelected: (_) {}),
      ),
    );
    await tester.pump();

    final thumbnails = tester.widgetList<MediaSelectorThumbnail>(find.byType(MediaSelectorThumbnail)).toList();

    expect(thumbnails.map((thumbnail) => thumbnail.blurThumbnail), [true, false, false]);
  });
}

Widget _queueHarness({required PlaybackStateProvider playback, required Widget child}) {
  return ChangeNotifierProvider<PlaybackStateProvider>.value(
    value: playback,
    child: MaterialApp(
      theme: ThemeData(extensions: const [_testTokens]),
      home: Scaffold(body: SizedBox(width: 600, height: 400, child: child)),
    ),
  );
}

PlaybackStateProvider _playbackWithQueue() {
  final playback = PlaybackStateProvider();
  playback.setPlaybackFromLocalQueue(
    LocalPlayQueue(
      id: 'test-queue',
      backendId: MediaBackend.plex.id,
      currentIndex: 0,
      items: [
        _episode('spoiler-episode', title: 'Spoiler Episode'),
        _episode('watched-episode', title: 'Watched Episode', viewCount: 1),
        testMediaItem(
          id: 'movie',
          backend: MediaBackend.plex,
          kind: MediaKind.movie,
          title: 'Movie',
          thumbPath: 'https://example.invalid/movie.jpg',
        ),
      ],
    ),
  );
  return playback;
}

MediaItem _episode(String id, {required String title, int? viewCount}) {
  return testMediaItem(
    id: id,
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: title,
    grandparentTitle: 'Show',
    parentIndex: 1,
    index: 1,
    viewCount: viewCount,
    thumbPath: 'https://example.invalid/$id.jpg',
  );
}

class _FakePlayer implements Player {
  final List<Duration> seeks = [];

  @override
  PlayerState get state => PlayerState(duration: const Duration(minutes: 30));

  @override
  PlayerStreams get streams => const PlayerStreams(
    playing: Stream<bool>.empty(),
    completed: Stream<bool>.empty(),
    buffering: Stream<bool>.empty(),
    position: Stream<Duration>.empty(),
    duration: Stream<Duration>.empty(),
    seekable: Stream<bool>.empty(),
    buffer: Stream<Duration>.empty(),
    volume: Stream<double>.empty(),
    rate: Stream<double>.empty(),
    tracks: Stream<Tracks>.empty(),
    track: Stream<TrackSelection>.empty(),
    log: Stream<PlayerLog>.empty(),
    error: Stream<PlayerError>.empty(),
    audioDevice: Stream<AudioDevice>.empty(),
    audioDevices: Stream<List<AudioDevice>>.empty(),
    bufferRanges: Stream<List<BufferRange>>.empty(),
    playbackRestart: Stream<void>.empty(),
    backendSwitched: Stream<void>.empty(),
  );

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
