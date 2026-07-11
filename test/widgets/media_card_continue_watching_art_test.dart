import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/optimized_media_image.dart';

import '../test_helpers/prefs.dart';

MediaItem _unwatchedEpisode({String? grandparentArtPath, String? artPath}) => MediaItem(
  id: 'episode_1',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Spoiler Episode',
  grandparentTitle: 'Show',
  parentIndex: 1,
  index: 1,
  thumbPath: 'https://example.invalid/thumb.jpg',
  grandparentArtPath: grandparentArtPath,
  artPath: artPath,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    await SettingsService.instance.write(SettingsService.hideSpoilers, true);
  });

  testWidgets('toggle off keeps the blurred episode thumbnail', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(
          item: _unwatchedEpisode(grandparentArtPath: 'https://example.invalid/art.jpg'),
          width: 200,
          height: 112,
          forceGridMode: true,
          isOffline: true,
          isInContinueWatching: true,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(
      tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).imagePath,
      'https://example.invalid/thumb.jpg',
    );
  });

  testWidgets('toggle on swaps to unblurred show artwork', (tester) async {
    await SettingsService.instance.write(SettingsService.continueWatchingShowArt, true);

    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(
          item: _unwatchedEpisode(grandparentArtPath: 'https://example.invalid/art.jpg'),
          width: 200,
          height: 112,
          forceGridMode: true,
          isOffline: true,
          isInContinueWatching: true,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);
    expect(
      tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).imagePath,
      'https://example.invalid/art.jpg',
    );
  });

  testWidgets('toggle on but no spoiler-safe art falls back to blur', (tester) async {
    await SettingsService.instance.write(SettingsService.continueWatchingShowArt, true);

    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(
          item: _unwatchedEpisode(),
          width: 200,
          height: 112,
          forceGridMode: true,
          isOffline: true,
          isInContinueWatching: true,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('toggle on but show art fails to load reverts to the blurred thumbnail', (tester) async {
    await SettingsService.instance.write(SettingsService.continueWatchingShowArt, true);

    // Unique art URL so recording its failure can't leak into other tests via
    // the process-global failed-poster set.
    const failingArt = 'https://example.invalid/art_fail.jpg';
    final item = MediaItem(
      id: 'episode_fail',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Spoiler Episode',
      grandparentTitle: 'Show',
      parentIndex: 1,
      index: 1,
      thumbPath: 'https://example.invalid/thumb.jpg',
      grandparentArtPath: failingArt,
    );

    Widget app() => _TestApp(
      child: MediaCard(
        item: item,
        width: 200,
        height: 112,
        forceGridMode: true,
        isOffline: true,
        isInContinueWatching: true,
      ),
    );

    await tester.pumpWidget(app());

    // Show art is used and carries an error fallback so a failed load can
    // revert to the blur.
    final art = tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage));
    expect(art.imagePath, failingArt);
    expect(art.errorWidget, isNotNull);
    expect(find.byType(ImageFiltered), findsNothing);

    // Simulate the show art failing to load. The error callback records the
    // failed URL (and renders the blurred thumbnail inline).
    final context = tester.element(find.byType(OptimizedMediaImage));
    art.errorWidget!(context, failingArt, 'load failed');

    // On the next rebuild the failed URL is skipped, so the card falls through
    // to the blurred episode thumbnail.
    await tester.pumpWidget(app());
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(
      tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).imagePath,
      'https://example.invalid/thumb.jpg',
    );
  });

  testWidgets('toggle on but not in Continue Watching keeps the blur', (tester) async {
    await SettingsService.instance.write(SettingsService.continueWatchingShowArt, true);

    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(
          item: _unwatchedEpisode(grandparentArtPath: 'https://example.invalid/art.jpg'),
          width: 200,
          height: 112,
          forceGridMode: true,
          isOffline: true,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
