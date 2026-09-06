import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/theme/mono_theme.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/screens/libraries/folder_tree_item.dart';
import '../test_helpers/media_items.dart';

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
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.windows),
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
}
