import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/discovery/discovery_choice.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/screens/discovery/discovery_artwork.dart';
import 'package:plezy/utils/media_image_helper.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/optimized_media_image.dart';

import '../../test_helpers/media_items.dart';

DiscoveryChoice choice({String? art, String? parent, String? thumb, String? backdrop}) => DiscoveryChoice(
  id: 'track',
  type: DiscoveryChoiceType.music,
  title: 'Album',
  subtitle: '',
  reason: '',
  summary: '',
  durationMs: null,
  totalDurationMs: null,
  isEstimate: false,
  serverId: 'server',
  mediaId: 'track',
  mediaKind: MediaKind.track,
  sourceId: null,
  entryId: null,
  year: null,
  artworkPath: art,
  mediaItem: testMediaItem(kind: MediaKind.track, thumbPath: thumb, parentThumbPath: parent, artPath: backdrop),
);

Widget frame(DiscoveryArtwork artwork) => MaterialApp(
  theme: monoTheme(MonoPalette.dark),
  home: Scaffold(
    body: Center(child: SizedBox(width: 240, height: 360, child: artwork)),
  ),
);
DiscoveryArtwork artwork({
  List<String> paths = const [],
  String? Function(String)? local,
  Future<File?> Function(bool)? cover,
  Key? key,
  bool decorative = false,
}) => DiscoveryArtwork(
  key: key,
  paths: paths,
  icon: Symbols.album_rounded,
  imageType: ImageType.square,
  fit: BoxFit.contain,
  localPathFor: local,
  loadCover: cover,
  decorative: decorative,
);

void main() {
  test('empty item art does not hide the album cover; paths stay ordered and unique', () {
    expect(discoveryArtworkPaths(choice(art: ' ', thumb: '', parent: '/album', backdrop: '/backdrop')), [
      '/album',
      '/backdrop',
    ]);
    expect(discoveryArtworkPaths(choice(art: '/album', thumb: '/album', parent: '/album')), ['/album']);
    expect(discoveryArtworkPaths(choice(art: '/poster', backdrop: '/backdrop'), backdrop: true).first, '/backdrop');
  });

  testWidgets('unresolved primary falls through to alternate artwork', (tester) async {
    await tester.pumpWidget(frame(artwork(paths: ['/missing-server-poster', 'https://example.invalid/album.jpg'])));
    final images = tester.widgetList<OptimizedMediaImage>(find.byType(OptimizedMediaImage));
    expect(images.map((image) => image.imagePath), contains('https://example.invalid/album.jpg'));
  });

  testWidgets('source loading, missing and retry are distinct; parent rebuilds do not reload', (tester) async {
    final first = Completer<File?>();
    final second = Completer<File?>();
    final calls = <bool>[];
    Future<File?> load(bool refresh) {
      calls.add(refresh);
      return refresh ? second.future : first.future;
    }

    await tester.pumpWidget(frame(artwork(cover: load)));
    expect(find.text('Loading artwork…'), findsOneWidget);
    await tester.pumpWidget(frame(artwork(cover: load)));
    expect(calls, [false]);
    first.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Artwork unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(calls, [false, true]);
    expect(find.text('Loading artwork…'), findsOneWidget);
    second.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Artwork unavailable'), findsOneWidget);
  });

  testWidgets('late source cover cannot overwrite the next card or its backdrop', (tester) async {
    final oldCover = Completer<File?>();
    await tester.pumpWidget(frame(artwork(key: const ValueKey('old'), cover: (_) => oldCover.future)));
    await tester.pumpWidget(
      frame(artwork(key: const ValueKey('new'), paths: ['https://example.invalid/new.jpg'], decorative: true)),
    );
    oldCover.complete(File('/old-cover.png'));
    await tester.pump();
    expect(tester.widgetList<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).map((image) => image.imagePath), [
      'https://example.invalid/new.jpg',
    ]);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('downloaded fallback art is tried before unavailable network art', (tester) async {
    final directory = Directory.systemTemp.createTempSync('plezy-discovery-art-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/cover.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGOcFmDEwMDAxMDAwMDAAAANrgEcyQYr6AAAAABJRU5ErkJggg==',
        ),
      );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        frame(
          artwork(
            paths: ['/show-poster', '/episode-thumb'],
            local: (path) => path == '/episode-thumb' ? file.path : null,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await tester.pump();
    });
    await tester.pumpAndSettle();
    final localImage = tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage).first);
    expect(localImage.localFilePath, file.path);
    expect(localImage.imagePath, isNull);
    expect(find.text('Artwork unavailable'), findsNothing);
  });
}
