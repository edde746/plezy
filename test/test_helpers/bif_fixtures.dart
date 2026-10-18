import 'dart:typed_data';

/// Build a minimal valid Roku BIF byte buffer.
///
/// - [entries]: list of (timestamp, jpegBytes). Timestamps are in raw units
///   (not multiplied by [timestampMultiplier]).
/// - [timestampMultiplier]: ms per unit (0 means "use default 1000").
Uint8List buildBif(List<({int timestamp, List<int> bytes})> entries, {int timestampMultiplier = 1000}) {
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
