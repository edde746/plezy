import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/i18n/strings.g.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/play_queue.dart';
import 'package:vibe_stream/mpv/mpv.dart';
import 'package:vibe_stream/providers/playback_state_provider.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/theme/mono_tokens.dart';
import 'package:vibe_stream/widgets/video_controls/sheets/queue_sheet.dart';
import 'package:vibe_stream/widgets/video_controls/widgets/content_strip.dart';
import 'package:vibe_stream/widgets/video_controls/widgets/media_selector_thumbnail.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

const _testTokens = MonoTokens(
  radiusSm: 8,
  radiusMd: 12,
  space: 8,
  fast: Duration(milliseconds: 1),
  normal: Duration(milliseconds: 1),
  slow: Duration(milliseconds: 1),
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
          showQueueTab: true,
          onQueueItemSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    final thumbnails = tester.widgetList<MediaSelectorThumbnail>(find.byType(MediaSelectorThumbnail)).toList();

    expect(thumbnails.map((thumbnail) => thumbnail.blurThumbnail), [true, false, false]);
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
        MediaItem(
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
  return MediaItem(
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
  @override
  PlayerState get state => PlayerState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
