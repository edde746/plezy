import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/continue_watching_copy_resolver.dart';
import 'package:plezy/utils/dialogs.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/widgets/continue_watching_copy_dialog.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';

const source = MediaItem.plex(
  id: 'uhd',
  kind: MediaKind.episode,
  title: 'Episode',
  serverId: 'server',
  serverName: 'Media Server',
  libraryTitle: 'Series - 4K',
);
final hd = source.copyWith(id: 'hd', libraryTitle: 'Series');
final dv = source.copyWith(id: 'dv', libraryTitle: 'Series - 4K DolbyVision');

Future<Completer<MediaItem?>> openDialog(
  WidgetTester tester,
  Future<ContinueWatchingCopyLookup> Function(AbortController) resolve,
) async {
  final selected = Completer<MediaItem?>();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            child: const Text('Open'),
            onPressed: () async => selected.complete(
              await showScopedDialog<MediaItem>(
                context: context,
                builder: (_) => ContinueWatchingCopyDialog(resolve: resolve),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
  return selected;
}

void main() {
  testWidgets('lookup exposes all three libraries and returns the actual chosen item', (tester) async {
    final selected = await openDialog(tester, (_) async => (copies: [source, hd, dv], isComplete: true));
    await tester.pumpAndSettle();
    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Series - 4K'), findsOneWidget);
    await tester.tap(find.text('Series - 4K DolbyVision'));
    await tester.pumpAndSettle();
    expect((await selected.future)!.id, 'dv');
  });

  testWidgets('cancel while loading never selects an item after the lookup completes', (tester) async {
    final pending = Completer<ContinueWatchingCopyLookup>();
    AbortController? abort;
    final selected = await openDialog(tester, (value) {
      abort = value;
      return pending.future;
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('continue-watching-copy-loading')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await selected.future, isNull);
    expect(abort!.isAborted, isTrue);
    pending.complete((copies: [source, hd, dv], isComplete: true));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one verified copy stays in the chooser until explicitly selected', (tester) async {
    final selected = await openDialog(tester, (_) async => (copies: [source], isComplete: true));
    await tester.pumpAndSettle();
    expect(selected.isCompleted, isFalse);
    expect(find.byType(FocusableListTile), findsOneWidget);
    expect(find.text('Media Server'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await selected.future, isNull);
  });

  testWidgets('copies are grouped under each server and retain the chosen server identity', (tester) async {
    final remote = hd.copyWith(serverId: 'remote', serverName: 'Remote Server', libraryTitle: 'Remote Series');
    final selected = await openDialog(tester, (_) async => (copies: [source, remote, dv], isComplete: true));
    await tester.pumpAndSettle();
    expect(find.text('Media Server'), findsOneWidget);
    expect(find.text('Remote Server'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Media Server')).dy, lessThan(tester.getTopLeft(find.text('Series - 4K')).dy));
    expect(
      tester.getTopLeft(find.text('Series - 4K DolbyVision')).dy,
      lessThan(tester.getTopLeft(find.text('Remote Server')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Remote Server')).dy,
      lessThan(tester.getTopLeft(find.text('Remote Series')).dy),
    );
    await tester.tap(find.text('Remote Series'));
    await tester.pumpAndSettle();
    expect((await selected.future)!.serverId, 'remote');
  });

  testWidgets('back dismissal ignores a result arriving during the closing animation', (tester) async {
    final pending = Completer<ContinueWatchingCopyLookup>();
    final selected = await openDialog(tester, (_) => pending.future);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.binding.handlePopRoute();
    pending.complete((copies: [source], isComplete: true));
    await tester.pumpAndSettle();
    expect(await selected.future, isNull);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed server does not silently auto-select the sole known copy', (tester) async {
    final selected = await openDialog(tester, (_) async => (copies: [source], isComplete: false));
    await tester.pumpAndSettle();
    expect(selected.isCompleted, isFalse);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Series - 4K'));
    await tester.pumpAndSettle();
    expect(await selected.future, source);
  });
}
