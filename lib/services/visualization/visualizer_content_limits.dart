import 'dart:convert';
import 'dart:typed_data';

/// Header-only checks before handing community assets to a native decoder.
/// These bound allocations; they do not replace codec validation or isolation.
abstract final class VisualizerContentLimits {
  static const maxPresetBytes = 2 * 1024 * 1024;
  static const maxImageDimension = 4096;
  static const maxImagePixels = 8 * 1024 * 1024;
  static const maxPackImagePixels = 32 * 1024 * 1024;
  static const imageExtensions = {'.png', '.jpg', '.jpeg', '.bmp', '.tga', '.gif', '.dds'};
  static const _dataExtensions = {'.milk', '.milk2', '.json', '.txt', '.md', '.license'};

  static void checkAssetPath(String path, {bool isNotice = false}) {
    final name = path.split('/').last.toLowerCase();
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot);
    // Notices may be extensionless (LICENSE/COPYING), but never native/code files.
    if (_dataExtensions.contains(extension) || imageExtensions.contains(extension) ||
        (isNotice && extension.isEmpty)) return;
    throw FormatException('Unsupported pack asset type: $path. Executable plugins are not imported.');
  }

  static void checkPreset(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxPresetBytes || bytes.contains(0)) {
      throw const FormatException('Preset text is empty, binary, or larger than 2 MB.');
    }
    // Latin-1 keeps the original bytes intact and also recognizes ASCII
    // directives in historical encodings. Native parsing still owns semantics.
    final text = latin1.decode(bytes);
    final include = RegExp(r'(^|[=;])\s*`?\s*#\s*include\b', caseSensitive: false);
    for (final line in const LineSplitter().convert(text)) {
      final source = line.trimLeft();
      if (!source.startsWith('//') && include.hasMatch(source)) {
        throw const FormatException('Shader includes are not allowed in imported presets. Keep assets inside the pack.');
      }
    }
  }

  /// Returns pixels for the aggregate pack budget. No image is decoded here.
  static int imagePixels(String extension, Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    int u16(int offset) => data.getUint16(offset, Endian.little);
    int u32(int offset) => data.getUint32(offset, Endian.little);
    bool prefix(List<int> signature) => bytes.length >= signature.length &&
        List.generate(signature.length, (i) => bytes[i] == signature[i]).every((v) => v);
    Never malformed() => throw const FormatException('Texture header is malformed or uses an unsupported image layout.');
    int width = 0, height = 0;
    switch (extension.toLowerCase()) {
      case '.png':
        if (bytes.length < 33 || !prefix([137, 80, 78, 71, 13, 10, 26, 10]) ||
            data.getUint32(8) != 13 || ascii.decode(bytes.sublist(12, 16), allowInvalid: true) != 'IHDR') malformed();
        width = data.getUint32(16); height = data.getUint32(20);
      case '.jpg' || '.jpeg':
        if (!prefix([0xff, 0xd8])) malformed();
        var offset = 2;
        while (offset + 3 < bytes.length) {
          if (bytes[offset++] != 0xff) malformed();
          while (offset < bytes.length && bytes[offset] == 0xff) { offset++; }
          if (offset >= bytes.length) malformed();
          final marker = bytes[offset++];
          if (marker == 0xd9 || marker == 0xda) break;
          if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
          if (offset + 2 > bytes.length) malformed();
          final length = data.getUint16(offset);
          if (length < 2 || offset + length > bytes.length) malformed();
          if ({0xc0, 0xc1, 0xc2}.contains(marker)) {
            if (length < 8 || bytes[offset + 2] != 8) malformed();
            height = data.getUint16(offset + 3); width = data.getUint16(offset + 5);
            break;
          }
          offset += length;
        }
      case '.bmp':
        if (bytes.length < 54 || !prefix([66, 77]) || u32(14) < 40 || u16(26) != 1) malformed();
        width = data.getInt32(18, Endian.little); height = data.getInt32(22, Endian.little).abs();
      case '.tga':
        if (bytes.length < 18 || bytes[1] != 0 || !{2, 3, 10, 11}.contains(bytes[2]) ||
            !{8, 16, 24, 32}.contains(bytes[16])) malformed();
        width = u16(12); height = u16(14);
      case '.gif':
        if (bytes.length < 13 || !(prefix(ascii.encode('GIF87a')) || prefix(ascii.encode('GIF89a')))) malformed();
        width = u16(6); height = u16(8);
      case '.dds':
        if (bytes.length < 128 || !prefix(ascii.encode('DDS ')) || u32(4) != 124 ||
            u32(76) != 32 || u32(24) > 1 || u32(28) > 13 || u32(112) != 0) malformed();
        // Only bounded two-dimensional legacy DDS, not cubemaps/arrays/DX10.
        final fourCC = ascii.decode(bytes.sublist(84, 88), allowInvalid: true);
        if ((u32(80) & 4) != 0) {
          if (!{'DXT1', 'DXT3', 'DXT5'}.contains(fourCC)) malformed();
        } else if ((u32(80) & 64) == 0 || !{24, 32}.contains(u32(88))) { malformed(); }
        width = u32(16); height = u32(12);
      default:
        throw const FormatException('Unsupported texture format.');
    }
    if (width <= 0 || height <= 0 || width > maxImageDimension || height > maxImageDimension ||
        width * height > maxImagePixels) {
      throw const FormatException('Textures must be at most 4096 pixels per side and 8 megapixels.');
    }
    return width * height;
  }
}
