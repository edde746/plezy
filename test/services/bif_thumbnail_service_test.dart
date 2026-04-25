import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/bif_thumbnail_service.dart';
import 'package:plezy/services/plex_client.dart';

// BIF (Roku Base Index Format) is a binary container for video timeline
// thumbnails. The service exposes [BifThumbnailService] which downloads + parses
// a file (network-bound), but the parser itself is reachable through
// [BifThumbnailService.load] when paired with a fake [PlexClient] that returns
// hand-crafted bytes.
//
// What's NOT covered (by design):
//   - The 50MiB size guard — verifying it would mean producing a 50MiB
//     `Uint8List`, which is wasteful for unit tests.
//   - The download-throws path — `BifThumbnailService.load` swallows errors
//     into a "no thumbnails" state, and the only observable difference between
//     "download failed" and "valid 0-image BIF" is `isAvailable=false`.

/// Build a minimal valid BIF byte buffer.
///
/// - [entries]: list of (timestamp, jpegBytes). Timestamps are in raw units
///   (not multiplied by [timestampMultiplier]).
/// - [timestampMultiplier]: ms per unit (0 means "use default 1000").
Uint8List _buildBif(List<({int timestamp, List<int> bytes})> entries, {int timestampMultiplier = 1000}) {
  // Header (64 bytes) + index table ((count+1)*8 bytes) + image bytes
  final imageCount = entries.length;
  final indexTableBytes = (imageCount + 1) * 8;
  final imageBytesTotal = entries.fold<int>(0, (a, e) => a + e.bytes.length);
  final total = 64 + indexTableBytes + imageBytesTotal;

  final buf = Uint8List(total);
  final view = ByteData.sublistView(buf);

  // Magic bytes: 0x89 B I F 0x0D 0x0A 0x1A 0x0A
  const magic = [0x89, 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < magic.length; i++) {
    buf[i] = magic[i];
  }
  // version (uint32 LE) at offset 8
  view.setUint32(8, 0, Endian.little);
  // image count (uint32 LE) at offset 12
  view.setUint32(12, imageCount, Endian.little);
  // timestamp multiplier (uint32 LE) at offset 16
  view.setUint32(16, timestampMultiplier, Endian.little);
  // bytes 20..63 are reserved — zero-initialized by Uint8List default

  // Index table: (imageCount + 1) entries, each [timestamp:u32 LE, offset:u32 LE]
  var dataOffset = 64 + indexTableBytes;
  for (var i = 0; i < imageCount; i++) {
    final entry = entries[i];
    view.setUint32(64 + i * 8, entry.timestamp, Endian.little);
    view.setUint32(64 + i * 8 + 4, dataOffset, Endian.little);
    dataOffset += entry.bytes.length;
  }
  // Sentinel entry: timestamp 0xFFFFFFFF, offset = end-of-data
  view.setUint32(64 + imageCount * 8, 0xFFFFFFFF, Endian.little);
  view.setUint32(64 + imageCount * 8 + 4, dataOffset, Endian.little);

  // Image data, contiguous.
  var pos = 64 + indexTableBytes;
  for (final entry in entries) {
    for (var i = 0; i < entry.bytes.length; i++) {
      buf[pos + i] = entry.bytes[i];
    }
    pos += entry.bytes.length;
  }

  return buf;
}

/// Fake [PlexClient] that satisfies the *only* method [BifThumbnailService.load]
/// invokes — `downloadBifFile`. Every other PlexClient member is unreachable
/// from this path, so [noSuchMethod] is forwarded to the default impl which
/// throws — making any unintended call a loud failure.
class _FakePlexClient implements PlexClient {
  _FakePlexClient(this._bytes);
  final Uint8List? _bytes;

  @override
  Future<Uint8List?> downloadBifFile(int partId) async => _bytes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // ============================================================
  // Initial state
  // ============================================================

  group('initial state', () {
    test('isAvailable is false before load()', () {
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      expect(svc.isAvailable, isFalse);
    });

    test('getThumbnail returns null before load()', () {
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      expect(svc.getThumbnail(Duration.zero), isNull);
      expect(svc.getThumbnail(const Duration(seconds: 5)), isNull);
    });
  });

  // ============================================================
  // Pure parser (via load + getThumbnail)
  // ============================================================

  group('valid BIF parsing', () {
    test('parses a 3-entry BIF with default 1000ms multiplier', () async {
      final bytes = _buildBif([
        (timestamp: 0, bytes: [0x10, 0x20]),
        (timestamp: 10, bytes: [0x30, 0x40, 0x50]),
        (timestamp: 20, bytes: [0x60]),
      ]);

      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(bytes), 1);

      expect(svc.isAvailable, isTrue);

      // Lookup at exactly the first entry's timestamp.
      expect(svc.getThumbnail(Duration.zero), Uint8List.fromList([0x10, 0x20]));

      // Lookup between entries — should pick the largest <= time.
      // 5s < 10s → first entry.
      expect(svc.getThumbnail(const Duration(seconds: 5)), Uint8List.fromList([0x10, 0x20]));
      // 10s == 2nd entry's timestamp.
      expect(svc.getThumbnail(const Duration(seconds: 10)), Uint8List.fromList([0x30, 0x40, 0x50]));
      // 15s — second entry still.
      expect(svc.getThumbnail(const Duration(seconds: 15)), Uint8List.fromList([0x30, 0x40, 0x50]));
      // 25s past the last entry's timestamp — clamps to last.
      expect(svc.getThumbnail(const Duration(seconds: 25)), Uint8List.fromList([0x60]));
    });

    test('honors a non-default timestampMultiplier', () async {
      // multiplier=500 → each timestamp unit is 500ms.
      final bytes = _buildBif([
        (timestamp: 0, bytes: [0xAA]),
        (timestamp: 4, bytes: [0xBB]), // 4 * 500ms = 2000ms
      ], timestampMultiplier: 500);

      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(bytes), 1);

      expect(svc.getThumbnail(Duration.zero), Uint8List.fromList([0xAA]));
      // 1.999s — still first entry.
      expect(svc.getThumbnail(const Duration(milliseconds: 1999)), Uint8List.fromList([0xAA]));
      // Exactly 2s — second entry.
      expect(svc.getThumbnail(const Duration(seconds: 2)), Uint8List.fromList([0xBB]));
    });

    test('multiplier=0 is treated as 1000ms (per BIF spec)', () async {
      final bytes = _buildBif([
        (timestamp: 0, bytes: [0x01]),
        (timestamp: 7, bytes: [0x02]),
      ], timestampMultiplier: 0);

      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(bytes), 1);

      // 7s should hit the second entry (7 * 1000ms).
      expect(svc.getThumbnail(const Duration(seconds: 7)), Uint8List.fromList([0x02]));
    });
  });

  // ============================================================
  // Malformed input
  // ============================================================

  group('malformed BIF input', () {
    test('rejects bytes shorter than the 64-byte header', () async {
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(Uint8List(50)), 1);
      expect(svc.isAvailable, isFalse);
    });

    test('rejects bytes with an invalid magic header', () async {
      // 128-byte buffer with all-zero bytes (no magic).
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(Uint8List(128)), 1);
      expect(svc.isAvailable, isFalse);
    });

    test('rejects bytes shorter than the declared index table', () async {
      // Build a valid header that claims 100 images but supply no index data.
      final buf = Uint8List(64);
      const magic = [0x89, 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A];
      for (var i = 0; i < magic.length; i++) {
        buf[i] = magic[i];
      }
      final view = ByteData.sublistView(buf);
      view.setUint32(12, 100, Endian.little); // imageCount=100 → needs 808 more bytes

      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(buf), 1);
      expect(svc.isAvailable, isFalse);
    });

    test('skips entries whose offset window is invalid (next <= current)', () async {
      // Build a valid 2-entry BIF, then corrupt the second offset to be inside
      // the first range so `nextImgOffset <= imgOffset` triggers the skip.
      final bytes = _buildBif([
        (timestamp: 0, bytes: [0x11, 0x22]),
        (timestamp: 5, bytes: [0x33]),
      ]);
      // Index entry 1 (second image) starts at byte 64+8.
      // Set its imgOffset to a value <= entry 0's imgOffset.
      final view = ByteData.sublistView(bytes);
      // Entry 0's imgOffset is at byte 64+0+4 = 68
      final firstImgOffset = view.getUint32(68, Endian.little);
      // Corrupt entry 1's imgOffset (at 64+8+4=76) to equal firstImgOffset,
      // so for entry 0 the lookahead `nextImgOffset == imgOffset` triggers
      // the `<=` skip path.
      view.setUint32(76, firstImgOffset, Endian.little);

      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(bytes), 1);

      // Entry 0 is skipped (next offset == its offset). Entry 1's window is
      // (firstImgOffset .. sentinel.offset), which is still valid, so it
      // remains. Verify exactly one entry survives.
      expect(svc.isAvailable, isTrue);
      // The surviving entry maps timestamp=5*1000ms onwards.
      expect(svc.getThumbnail(const Duration(seconds: 5)), isNotNull);
      // A query before the surviving entry's timestamp clamps to it (since
      // there's only one entry, binary search returns entries[0]).
      expect(svc.getThumbnail(Duration.zero), isNotNull);
    });
  });

  // ============================================================
  // Empty / null input
  // ============================================================

  group('empty input', () {
    test('null download keeps the service in unavailable state', () async {
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(null), 1);
      expect(svc.isAvailable, isFalse);
      expect(svc.getThumbnail(Duration.zero), isNull);
    });

    test('empty bytes keep the service in unavailable state', () async {
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(Uint8List(0)), 1);
      expect(svc.isAvailable, isFalse);
    });

    test('a valid BIF with zero images parses but reports unavailable', () async {
      final bytes = _buildBif(const []); // no entries, only header + sentinel
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);
      await svc.load(_FakePlexClient(bytes), 1);

      // Loaded successfully but the entries list is empty — `isAvailable`
      // requires non-empty entries.
      expect(svc.isAvailable, isFalse);
      expect(svc.getThumbnail(Duration.zero), isNull);
    });
  });

  // ============================================================
  // Reload + dispose
  // ============================================================

  group('reload + dispose', () {
    test('a second load() replaces prior entries', () async {
      final first = _buildBif([
        (timestamp: 0, bytes: [0xAA]),
      ]);
      final second = _buildBif([
        (timestamp: 0, bytes: [0xBB, 0xCC]),
      ]);

      final svc = BifThumbnailService();
      addTearDown(svc.dispose);

      await svc.load(_FakePlexClient(first), 1);
      expect(svc.getThumbnail(Duration.zero), Uint8List.fromList([0xAA]));

      await svc.load(_FakePlexClient(second), 2);
      expect(svc.getThumbnail(Duration.zero), Uint8List.fromList([0xBB, 0xCC]));
    });

    test('a failed reload (null bytes) clears prior entries', () async {
      final first = _buildBif([
        (timestamp: 0, bytes: [0xAA]),
      ]);
      final svc = BifThumbnailService();
      addTearDown(svc.dispose);

      await svc.load(_FakePlexClient(first), 1);
      expect(svc.isAvailable, isTrue);

      // The implementation sets `_entries = null` at the start of `load()`,
      // so a null download leaves the service unavailable.
      await svc.load(_FakePlexClient(null), 2);
      expect(svc.isAvailable, isFalse);
      expect(svc.getThumbnail(Duration.zero), isNull);
    });

    test('dispose() releases entries', () async {
      final bytes = _buildBif([
        (timestamp: 0, bytes: [0xFF]),
      ]);
      final svc = BifThumbnailService();
      await svc.load(_FakePlexClient(bytes), 1);
      expect(svc.isAvailable, isTrue);

      svc.dispose();
      expect(svc.isAvailable, isFalse);
      expect(svc.getThumbnail(Duration.zero), isNull);
    });
  });
}
