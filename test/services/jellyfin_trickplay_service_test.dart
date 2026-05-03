import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show ImageProvider, MemoryImage;
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_trickplay_service.dart';
import 'package:plezy/services/scrub_preview_source.dart';

JellyfinConnection _conn() => JellyfinConnection(
  id: 'srv-1/user-1',
  baseUrl: 'https://jf.example.com',
  serverName: 'Home',
  serverMachineId: 'srv-1',
  userId: 'user-1',
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

TrickplayInfo _info({
  int width = 320,
  int height = 180,
  int tileWidth = 10,
  int tileHeight = 10,
  int thumbnailCount = 250,
  int interval = 1000,
  int bandwidth = 0,
}) => TrickplayInfo(
  width: width,
  height: height,
  tileWidth: tileWidth,
  tileHeight: tileHeight,
  thumbnailCount: thumbnailCount,
  interval: interval,
  bandwidth: bandwidth,
);

/// Stub that returns a constant 1×1 transparent image for any URL — keeps
/// tests off path_provider / the image disk cache.
ImageProvider _fakeSheet(String _) => MemoryImage(Uint8List.fromList(const [0]));

void main() {
  group('JellyfinTrickplayService.create — width selection', () {
    late JellyfinClient client;

    setUp(() async {
      client = await JellyfinClient.create(_conn());
    });

    tearDown(() => client.close());

    test('returns null on empty manifest', () {
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-1',
        mediaSourceId: null,
        manifest: const {},
        sheetImageBuilder: _fakeSheet,
      );
      expect(svc, isNull);
    });

    test('picks the smallest width >= target tooltip width', () {
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-1',
        mediaSourceId: null,
        manifest: {160: _info(width: 160), 240: _info(width: 240), 320: _info(width: 320)},
        sheetImageBuilder: _fakeSheet,
      );
      expect(svc, isNotNull);
      // Indirectly: at t=0 the tile crop's width matches the chosen tile width.
      expect(svc!.tileLocationFor(Duration.zero)?.sourceTileSize.width, 160);
    });

    test('falls back to largest available when nothing meets the target', () {
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-1',
        mediaSourceId: null,
        manifest: {80: _info(width: 80), 120: _info(width: 120)},
        sheetImageBuilder: _fakeSheet,
      );
      expect(svc, isNotNull);
      expect(svc!.tileLocationFor(Duration.zero)?.sourceTileSize.width, 120);
    });
  });

  group('JellyfinTrickplayService.tileLocationFor — index math', () {
    late JellyfinClient client;
    // 250 thumbnails, 1s apart, 10×10 tiles per sheet ⇒ 3 sheets.
    // sheet 0: indices 0..99
    // sheet 1: indices 100..199 (full)
    // sheet 2: indices 200..249 (last sheet, only 50 thumbs ⇒ 5 rows)

    setUp(() async {
      client = await JellyfinClient.create(_conn());
    });

    tearDown(() => client.close());

    JellyfinTrickplayService make({String? sourceId, int width = 320}) {
      return JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-1',
        mediaSourceId: sourceId,
        manifest: {width: _info(width: width)},
        sheetImageBuilder: _fakeSheet,
      )!;
    }

    test('t=0 maps to sheet 0, tile (0,0)', () {
      final loc = make().tileLocationFor(Duration.zero)!;
      expect(loc.sheetIndex, 0);
      expect(loc.tileColumn, 0);
      expect(loc.tileRow, 0);
    });

    test('t=99s maps to sheet 0, tile (9,9) — last tile in sheet 0', () {
      final loc = make().tileLocationFor(const Duration(seconds: 99))!;
      expect(loc.sheetIndex, 0);
      expect(loc.tileColumn, 9);
      expect(loc.tileRow, 9);
    });

    test('t=100s rolls into sheet 1, tile (0,0)', () {
      final loc = make().tileLocationFor(const Duration(seconds: 100))!;
      expect(loc.sheetIndex, 1);
      expect(loc.tileColumn, 0);
      expect(loc.tileRow, 0);
      // Sheet 1 is full ⇒ 10 cols × 10 rows.
      expect(loc.sheetColumns, 10);
      expect(loc.sheetRows, 10);
    });

    test('t=249s lands at the last tile of the last (partial) sheet', () {
      // index 249 ⇒ sheet 2, tile-in-sheet 49, col=9, row=4
      final loc = make().tileLocationFor(const Duration(seconds: 249))!;
      expect(loc.sheetIndex, 2);
      expect(loc.tileColumn, 9);
      expect(loc.tileRow, 4);
      // Sheet 2 has 50 thumbs ⇒ 5 rows, full 10 cols
      expect(loc.sheetColumns, 10);
      expect(loc.sheetRows, 5);
    });

    test('clamps past the end to the last available thumbnail', () {
      final loc = make().tileLocationFor(const Duration(seconds: 10000))!;
      expect(loc.sheetIndex, 2);
      expect(loc.tileColumn, 9);
      expect(loc.tileRow, 4);
    });

    test('isAvailable is true while there are thumbnails', () {
      expect(make().isAvailable, isTrue);
    });

    test('dispose flips isAvailable to false and frames to null', () {
      final svc = make();
      svc.dispose();
      expect(svc.isAvailable, isFalse);
      expect(svc.tileLocationFor(Duration.zero), isNull);
      expect(svc.getFrame(Duration.zero), isNull);
    });
  });

  group('JellyfinTrickplayService — partial last sheet sizing', () {
    late JellyfinClient client;

    setUp(() async {
      client = await JellyfinClient.create(_conn());
    });

    tearDown(() => client.close());

    test('last sheet with 1 thumbnail reports 1 col × 1 row', () {
      // 17 thumbs, 4×4 sheet ⇒ sheet 0 full (16), sheet 1 has 1 thumb only.
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-1',
        mediaSourceId: null,
        manifest: {
          320: _info(width: 320, height: 180, tileWidth: 4, tileHeight: 4, thumbnailCount: 17, interval: 1000),
        },
        sheetImageBuilder: _fakeSheet,
      )!;
      final loc = svc.tileLocationFor(const Duration(seconds: 16))!;
      expect(loc.sheetIndex, 1);
      expect(loc.tileColumn, 0);
      expect(loc.tileRow, 0);
      expect(loc.sheetColumns, 1);
      expect(loc.sheetRows, 1);
    });
  });

  group('JellyfinTrickplayService — sheet URL forwarding', () {
    test('sheet URL includes selected width, sheet index, and MediaSourceId', () async {
      final client = await JellyfinClient.create(_conn());
      addTearDown(client.close);
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-99',
        mediaSourceId: 'src-2',
        manifest: {320: _info(width: 320)},
        sheetImageBuilder: _fakeSheet,
      )!;
      final url = svc.sheetUrlFor(1);
      final uri = Uri.parse(url);
      expect(uri.path, '/Videos/item-99/Trickplay/320/1.jpg');
      expect(uri.queryParameters['MediaSourceId'], 'src-2');
      expect(uri.queryParameters['api_key'], 'tok-abc');
    });

    test('sheet URL omits MediaSourceId when null', () async {
      final client = await JellyfinClient.create(_conn());
      addTearDown(client.close);
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-99',
        mediaSourceId: null,
        manifest: {320: _info(width: 320)},
        sheetImageBuilder: _fakeSheet,
      )!;
      final uri = Uri.parse(svc.sheetUrlFor(0));
      expect(uri.queryParameters.containsKey('MediaSourceId'), isFalse);
    });
  });

  group('JellyfinTrickplayService.getFrame — SheetScrubFrame integration', () {
    test('builds a SheetScrubFrame with the injected ImageProvider', () async {
      final client = await JellyfinClient.create(_conn());
      addTearDown(client.close);
      final probe = MemoryImage(Uint8List.fromList(const [0]));
      final svc = JellyfinTrickplayService.create(
        client: client,
        itemId: 'item-1',
        mediaSourceId: null,
        manifest: {320: _info(width: 320)},
        sheetImageBuilder: (_) => probe,
      )!;
      final frame = svc.getFrame(Duration.zero);
      expect(frame, isA<SheetScrubFrame>());
      final sheet = (frame as SheetScrubFrame).sheet;
      expect(identical(sheet, probe), isTrue);
      expect(frame.tileColumn, 0);
      expect(frame.tileRow, 0);
      expect(frame.sourceTileSize, equals(const Size(320, 180)));
    });
  });
}

// Pin: keep ScrubPreviewSource referenced — JellyfinTrickplayService
// implements it but the tests rarely need to upcast, and the import
// otherwise looks unused to the analyzer.
// ignore: unused_element
ScrubPreviewSource? _unused;
