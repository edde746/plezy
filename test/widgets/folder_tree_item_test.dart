import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/theme/mono_theme.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/screens/libraries/folder_tree_item.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/media_image_helper.dart';
import 'package:plezy/widgets/optimized_media_image.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  testWidgets('folder rows use the item title for seasons', (tester) async {
    final item = testMediaItem(
      id: 'season-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      title: 'Season 1',
      grandparentTitle: 'TV Show',
      raw: const {'Type': 'Season', 'IsFolder': true},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: FolderTreeItem(item: item, depth: 1, isFolder: true)),
      ),
    );

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('TV Show'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('folder rows show play and shuffle buttons when callbacks are supplied', (tester) async {
    final item = testMediaItem(
      id: 'folder-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.unknown,
      title: 'Videos',
      raw: const {'Type': 'Folder', 'IsFolder': true},
    );

    var played = false;
    var shuffled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FolderTreeItem(
            item: item,
            depth: 0,
            isFolder: true,
            onPlayAll: () => played = true,
            onShuffle: () => shuffled = true,
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(2));

    await tester.tap(find.byType(IconButton).first);
    await tester.tap(find.byType(IconButton).last);

    expect(played, isTrue);
    expect(shuffled, isTrue);
  });

  testWidgets('folder menu cancellation restores the row but play preserves its focus handoff', (tester) async {
    final row = FocusNode();
    final player = FocusNode();
    addTearDown(row.dispose);
    addTearDown(player.dispose);
    var selected = false;
    final item = testMediaItem(id: 'folder-1', backend: MediaBackend.jellyfin, title: 'Videos');
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.dark).copyWith(platform: TargetPlatform.windows),
        home: Material(
          child: Column(
            children: [
              FolderTreeItem(
                item: item,
                depth: 0,
                isFolder: true,
                focusNode: row,
                onTap: () => selected = true,
                onPlayAll: player.requestFocus,
              ),
              Focus(focusNode: player, child: const Text('Player')),
            ],
          ),
        ),
      ),
    );
    row.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    expect(find.text(t.common.play), findsOneWidget);
    Navigator.of(tester.element(find.byType(FolderTreeItem))).pop();
    await tester.pumpAndSettle();
    expect(row.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.play));
    await tester.pumpAndSettle();
    expect(player.hasPrimaryFocus, isTrue);
    expect(row.hasFocus, isFalse);
  });

  testWidgets('episode row in season poster mode falls back to series poster when season poster fails', (tester) async {
    resetSharedPreferencesForTest();
    MediaImageHelper.clearFailedPosterUrls();
    await SettingsService.getInstance();
    await SettingsService.instance.write(SettingsService.episodePosterMode, EpisodePosterMode.seasonPoster);

    final item = testMediaItem(
      id: 'ep-1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
      parentId: 'season-61183',
      parentThumbPath: null, // Season has no poster on PMS
      grandparentThumbPath: '/library/metadata/show-61182/thumb',
      thumbPath: '/library/metadata/ep-1/thumb',
    );

    Future<void> pumpRow() => tester.pumpWidget(
      MaterialApp(
        home: Material(child: FolderTreeItem(item: item, depth: 0, isFolder: false)),
      ),
    );

    await pumpRow();
    final primaryFinder = find
        .descendant(of: find.byType(FolderTreeItem), matching: find.byType(OptimizedMediaImage))
        .first;
    final primary = tester.widget<OptimizedMediaImage>(primaryFinder);
    expect(primary.imagePath, '/library/metadata/season-61183/thumb');
    expect(primary.errorWidget, isNotNull);

    // Unresolved error (e.g. no client in offline / disconnected state) preserves primary path on rebuild
    final unresolvedFallback = primary.errorWidget!(
      tester.element(primaryFinder),
      '/library/metadata/season-61183/thumb',
      const UnresolvedImageUrl('/library/metadata/season-61183/thumb'),
    );
    expect(unresolvedFallback, isA<OptimizedMediaImage>());
    expect((unresolvedFallback as OptimizedMediaImage).imagePath, '/library/metadata/show-61182/thumb');

    await pumpRow();
    final unresolvedRebuild = tester.widget<OptimizedMediaImage>(primaryFinder);
    expect(unresolvedRebuild.imagePath, '/library/metadata/season-61183/thumb');

    // Attempted-and-failed load (e.g. season has no poster on server -> 404) records dead URL
    final failedFallback = unresolvedRebuild.errorWidget!(
      tester.element(primaryFinder),
      '/library/metadata/season-61183/thumb',
      StateError('404 Not Found'),
    );
    expect(failedFallback, isA<OptimizedMediaImage>());
    expect((failedFallback as OptimizedMediaImage).imagePath, '/library/metadata/show-61182/thumb');
    expect(MediaImageHelper.hasFailedPosterUrl('/library/metadata/season-61183/thumb'), isTrue);

    // Subsequent builds of FolderTreeItem go straight to the remembered fallback series poster
    await pumpRow();
    expect(tester.widget<OptimizedMediaImage>(primaryFinder).imagePath, '/library/metadata/show-61182/thumb');
  });

  testWidgets('episode row in season poster mode uses season poster path when available', (tester) async {
    resetSharedPreferencesForTest();
    MediaImageHelper.clearFailedPosterUrls();
    await SettingsService.getInstance();
    await SettingsService.instance.write(SettingsService.episodePosterMode, EpisodePosterMode.seasonPoster);

    final item = testMediaItem(
      id: 'ep-1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
      parentId: 'season-61183',
      parentThumbPath: '/library/metadata/season-61183/thumb/12345',
      grandparentThumbPath: '/library/metadata/show-61182/thumb',
      thumbPath: '/library/metadata/ep-1/thumb',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: FolderTreeItem(item: item, depth: 0, isFolder: false)),
      ),
    );

    final primaryFinder = find
        .descendant(of: find.byType(FolderTreeItem), matching: find.byType(OptimizedMediaImage))
        .first;
    final primary = tester.widget<OptimizedMediaImage>(primaryFinder);
    expect(primary.imagePath, '/library/metadata/season-61183/thumb/12345');
  });
}
