import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/mpv/font_loader.dart';

import '../test_helpers/io_fakes.dart';

/// Guards the subtitle-font extraction contract: libass on Android MPV has no
/// fontconfig/system fallback, so every script must ship inside the one
/// directory this loader produces. Losing a font here silently regresses
/// glyph coverage for subtitles (e.g. #1932, Korean Hangul).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late PathProviderPlatform originalPlatform;

  setUp(() {
    originalPlatform = PathProviderPlatform.instance;
    tempRoot = Directory.systemTemp.createTempSync('font_loader_test');
    PathProviderPlatform.instance = FakePathProvider(tempRoot);
    SubtitleFontLoader.resetForTesting();
  });

  tearDown(() {
    SubtitleFontLoader.resetForTesting();
    PathProviderPlatform.instance = originalPlatform;
    tempRoot.deleteSync(recursive: true);
  });

  test('extracts the default and Hangul fonts into one directory', () async {
    final fontDir = await SubtitleFontLoader.loadSubtitleFont();
    expect(fontDir, isNotNull);
    expect(Directory(fontDir!).existsSync(), isTrue);

    for (final font in SubtitleFontLoader.fonts) {
      final fontFile = File(p.join(fontDir, font.fileName));
      expect(fontFile.existsSync(), isTrue, reason: '${font.fileName} missing');
      final bytes = fontFile.readAsBytesSync();
      expect(bytes.length, font.length, reason: '${font.fileName} is not a full copy');
      // TrueType magic: 0x00010000. Catches a corrupt/truncated asset.
      expect(bytes.sublist(0, 4), Uint8List.fromList([0x00, 0x01, 0x00, 0x00]));
    }
  });

  test('the pinned lengths are the bundled assets', () async {
    // The extracted copy is judged current by length alone, so a regenerated
    // asset whose pin was not updated would never replace the old copy on an
    // existing install.
    for (final font in SubtitleFontLoader.fonts) {
      final asset = await rootBundle.load(font.asset);
      expect(asset.lengthInBytes, font.length, reason: '${font.asset} length pin is stale');
    }
  });

  test('replaces a copy from an earlier build and drops files that are not bundled fonts', () async {
    // The cache directory survives app updates. A font regenerated under the
    // same file name (the Hangul companion was) must still reach an install
    // that extracted the old one, and libass loads every file it finds there.
    final tempDir = await PathProviderPlatform.instance.getTemporaryPath();
    final fontDir = Directory(p.join(tempDir!, 'subtitle_fonts'))..createSync(recursive: true);
    final companion = SubtitleFontLoader.fonts.last;
    final stale = File(p.join(fontDir.path, companion.fileName))..writeAsBytesSync(List.filled(4096, 0xAB));
    final leftover = File(p.join(fontDir.path, 'go-noto-old-companion.ttf'))..writeAsBytesSync([1, 2, 3]);
    final partial = File(p.join(fontDir.path, '${companion.fileName}.partial'))..writeAsBytesSync([4, 5, 6]);

    final resolved = await SubtitleFontLoader.loadSubtitleFont();

    expect(resolved, fontDir.path);
    expect(stale.lengthSync(), companion.length, reason: 'stale companion was kept');
    expect(leftover.existsSync(), isFalse, reason: 'unrelated file survived');
    expect(partial.existsSync(), isFalse, reason: 'interrupted write survived');
    expect(fontDir.listSync().map((e) => p.basename(e.path)).toSet(), {
      for (final font in SubtitleFontLoader.fonts) font.fileName,
    });
  });

  test('default font name stays Go Noto Current-Regular', () {
    // configureSubtitleFonts() sets sub-font to this exact name.
    expect(SubtitleFontLoader.fontName, 'Go Noto Current-Regular');
  });

  test('every extracted font carries the sub-font family name', () async {
    // libass only scores fonts whose Microsoft-platform family (name ID 1)
    // equals sub-font, then picks per codepoint the one that has the glyph.
    // A companion under its upstream family is never a candidate, so Korean
    // would render from the primary's jamo instead of its syllables.
    final fontDir = await SubtitleFontLoader.loadSubtitleFont();
    expect(fontDir, isNotNull);
    for (final font in SubtitleFontLoader.fonts) {
      final families = _microsoftFamilyNames(File(p.join(fontDir!, font.fileName)).readAsBytesSync());
      expect(families, isNotEmpty, reason: '${font.fileName} has no Microsoft-platform family record');
      expect(families, everyElement(SubtitleFontLoader.fontName), reason: font.fileName);
    }
  });
}

/// Name-ID-1 (family) strings of an sfnt's Microsoft-platform records, the
/// records libass reads; they are UTF-16BE by spec.
List<String> _microsoftFamilyNames(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  const platformMicrosoft = 3;
  const nameIdFamily = 1;

  final numTables = data.getUint16(4);
  int? nameTable;
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    if (String.fromCharCodes(bytes, record, record + 4) == 'name') {
      nameTable = data.getUint32(record + 8);
      break;
    }
  }
  if (nameTable == null) return const [];

  final count = data.getUint16(nameTable + 2);
  final storage = nameTable + data.getUint16(nameTable + 4);
  final families = <String>[];
  for (var i = 0; i < count; i++) {
    final record = nameTable + 6 + i * 12;
    if (data.getUint16(record) != platformMicrosoft || data.getUint16(record + 6) != nameIdFamily) continue;
    final length = data.getUint16(record + 8);
    final offset = storage + data.getUint16(record + 10);
    families.add(String.fromCharCodes([for (var j = 0; j < length; j += 2) data.getUint16(offset + j)]));
  }
  return families;
}
