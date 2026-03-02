import 'dart:isolate';
import 'dart:typed_data';

import 'plex_client.dart';
import '../utils/app_logger.dart';

/// A single BIF thumbnail entry: timestamp in milliseconds + JPEG bytes.
typedef BifEntry = ({int timestampMs, Uint8List imageBytes});

/// Parse raw BIF file bytes into a list of thumbnail entries.
///
/// BIF format:
///   - 0..7   : magic bytes (0x89 "BIF" 0x0D 0x0A 0x1A 0x0A)
///   - 8..11  : version (uint32 LE)
///   - 12..15 : image count (uint32 LE)
///   - 16..19 : timestamp multiplier (uint32 LE, ms per unit; 0 = 1000)
///   - 20..63 : reserved
///   - 64..   : index table — (imageCount + 1) entries of 8 bytes each:
///              [timestamp (uint32 LE), offset (uint32 LE)]
///              The last entry is a sentinel (timestamp = 0xFFFFFFFF).
///
/// Top-level function so it can be passed to [Isolate.run].
List<BifEntry> _parseBifBytes(Uint8List bytes) {
  if (bytes.length < 64) return [];

  final data = ByteData.sublistView(bytes);

  // Validate magic: 0x89 B I F 0x0D 0x0A 0x1A 0x0A
  const magic = [0x89, 0x42, 0x49, 0x46, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic[i]) return [];
  }

  final imageCount = data.getUint32(12, Endian.little);
  var timestampMultiplier = data.getUint32(16, Endian.little);
  if (timestampMultiplier == 0) timestampMultiplier = 1000;

  // Index table starts at byte 64; each entry is 8 bytes.
  // There are (imageCount + 1) entries (last is sentinel).
  final indexTableSize = (imageCount + 1) * 8;
  if (bytes.length < 64 + indexTableSize) return [];

  final entries = <BifEntry>[];
  for (var i = 0; i < imageCount; i++) {
    final entryOffset = 64 + i * 8;
    final timestamp = data.getUint32(entryOffset, Endian.little);
    final imgOffset = data.getUint32(entryOffset + 4, Endian.little);

    // Next entry's offset gives us the end of this image's data.
    final nextEntryOffset = 64 + (i + 1) * 8;
    final nextImgOffset = data.getUint32(nextEntryOffset + 4, Endian.little);

    if (nextImgOffset <= imgOffset || nextImgOffset > bytes.length) continue;

    entries.add((
      timestampMs: timestamp * timestampMultiplier,
      imageBytes: Uint8List.sublistView(bytes, imgOffset, nextImgOffset),
    ));
  }

  return entries;
}

/// Caches a full BIF file in memory and serves thumbnails by timestamp.
class BifThumbnailService {
  List<BifEntry>? _entries;

  /// Download and parse the BIF file for [partId].
  /// Returns silently on failure (thumbnails simply won't be available).
  Future<void> load(PlexClient client, int partId) async {
    _entries = null;
    try {
      final bytes = await client.downloadBifFile(partId);
      if (bytes == null || bytes.isEmpty) return;
      _entries = await Isolate.run(() => _parseBifBytes(bytes));
    } catch (e) {
      appLogger.w('BIF download/parse failed', error: e);
    }
  }

  /// Whether thumbnails have been loaded successfully.
  bool get isAvailable => _entries != null && _entries!.isNotEmpty;

  /// Return the JPEG bytes for the thumbnail nearest to [time].
  /// Uses binary search for O(log n) lookup.
  Uint8List? getThumbnail(Duration time) {
    final entries = _entries;
    if (entries == null || entries.isEmpty) return null;

    final ms = time.inMilliseconds;

    // Binary search for the largest timestamp <= ms.
    var lo = 0;
    var hi = entries.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2; // bias right
      if (entries[mid].timestampMs <= ms) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }

    return entries[lo].imageBytes;
  }

  /// Release cached data.
  void dispose() {
    _entries = null;
  }
}
