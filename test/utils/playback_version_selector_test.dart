import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/media_version_preference.dart';
import 'package:plezy/utils/download_version_utils.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/playback_version_selector.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';

Widget _launcher({
  required PlaybackVersionLoader loader,
  MediaVersionPreference? preferredVersion,
  required ValueChanged<PlaybackVersionSelection?> onComplete,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            onComplete(
              await showPlaybackVersionSelector(
                context,
                title: 'Play Version',
                loadVersions: loader,
                preferredVersion: preferredVersion,
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

MediaVersion _version(String id, String name) => MediaVersion(id: id, name: name);

void main() {
  testWidgets('loading discovery is cancellable and aborts the request', (tester) async {
    final pending = Completer<List<MediaVersion>>();
    AbortController? requestAbort;
    PlaybackVersionSelection? result;
    var completed = false;

    await tester.pumpWidget(
      _launcher(
        loader: (abort) {
          requestAbort = abort;
          return pending.future;
        },
        onComplete: (value) {
          result = value;
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.byKey(const ValueKey('playback-version-loading')), findsOneWidget);
    expect(requestAbort, isNotNull);
    expect(requestAbort!.isAborted, isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(requestAbort!.isAborted, isTrue);
    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byKey(const ValueKey('playback-version-discovery')), findsNothing);
  });

  testWidgets('single discovered source proceeds without showing a chooser', (tester) async {
    PlaybackVersionSelection? result;
    final onlyVersion = _version('only', 'Only source');

    await tester.pumpWidget(_launcher(loader: (_) async => [onlyVersion], onComplete: (value) => result = value));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('media-version-picker')), findsNothing);
    expect(result?.index, 0);
    expect(result?.version.id, 'only');
  });

  testWidgets('failure remains retryable, then preserves order and highlights saved source', (tester) async {
    var attempts = 0;
    PlaybackVersionSelection? result;
    final versions = [_version('first', 'First source\nAIO description'), _version('saved', 'Saved source')];

    await tester.pumpWidget(
      _launcher(
        loader: (_) async {
          attempts++;
          if (attempts == 1) throw Exception('temporarily unavailable');
          return versions;
        },
        preferredVersion: const MediaVersionPreference(versionId: 'saved', index: 0),
        onComplete: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('playback-version-error')), findsOneWidget);
    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('media-version-picker')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('playback-version-retry')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('First source AIO description'), findsOneWidget);
    expect(find.text('First source\nAIO description'), findsNothing);

    final first = find.byKey(const ValueKey('media-version-option-0'));
    final second = find.byKey(const ValueKey('media-version-option-1'));
    expect(tester.getTopLeft(first).dy, lessThan(tester.getTopLeft(second).dy));
    expect(tester.widget<FocusableListTile>(first).selected, isFalse);
    expect(tester.widget<FocusableListTile>(second).selected, isTrue);

    await tester.tap(second);
    await tester.pumpAndSettle();

    expect(result?.index, 1);
    expect(result?.version.id, 'saved');
  });

  testWidgets('desktop picker expands and shows the complete AIOStreams formatter label', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const formatterLabel =
        '1080P (nzb) ⚡ 〈Web-dl〉 ★★★★★ That Time I Got Reincarnated as a Slime S04·E15 '
        'AVC AAC 1.64 GB · 9.12 Mbps · 18h [AIO] altHUB · SubsPlease · SKYANIME · '
        'Dual Audio · English Subtitles · Cached Download · Complete Release Metadata';
    final longVersion = _version('aio-long', formatterLabel);
    final expectedLabel = mediaVersionPickerLabel(longVersion);

    await tester.pumpWidget(
      _launcher(loader: (_) async => [longVersion, _version('alternate', 'Alternate source')], onComplete: (_) {}),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final picker = find.byKey(const ValueKey('media-version-picker'));
    final pickerRect = tester.getRect(picker);
    expect(pickerRect.width, greaterThanOrEqualTo(900));
    expect(pickerRect.left, greaterThanOrEqualTo(0));
    expect(pickerRect.right, lessThanOrEqualTo(1440));

    final label = find.text(expectedLabel);
    expect(label, findsOneWidget);
    final text = tester.widget<Text>(label);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);

    final richText = find.descendant(of: label, matching: find.byType(RichText));
    expect(richText, findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(richText).didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
