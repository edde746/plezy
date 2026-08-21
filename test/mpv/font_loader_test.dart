import 'dart:io';
import 'dart:typed_data';

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
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPlatform;
    tempRoot.deleteSync(recursive: true);
  });

  // loadSubtitleFont() caches its result per process, so only this test may
  // trigger extraction.

  test('extracts the default and Hangul fonts into one directory', () async {
    final fontDir = await SubtitleFontLoader.loadSubtitleFont();

    expect(fontDir, isNotNull);
    final dir = Directory(fontDir!);
    expect(dir.existsSync(), isTrue);

    for (final fileName in ['go-noto-current-regular.ttf', 'go-noto-kurrent-hangul.ttf']) {
      final fontFile = File(p.join(fontDir, fileName));
      expect(fontFile.existsSync(), isTrue, reason: '$fileName missing');
      final bytes = fontFile.readAsBytesSync();
      expect(bytes.length, greaterThan(0), reason: '$fileName empty');
      // TrueType magic: 0x00010000. Catches a corrupt/truncated asset.
      expect(bytes.sublist(0, 4), Uint8List.fromList([0x00, 0x01, 0x00, 0x00]));
    }
  });

  test('default font name stays Go Noto Current-Regular', () {
    // configureSubtitleFonts() sets sub-font to this exact name; libass falls
    // back to the Hangul subset for Korean glyphs.
    expect(SubtitleFontLoader.fontName, 'Go Noto Current-Regular');
  });
}
