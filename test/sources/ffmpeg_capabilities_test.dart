import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/ffmpeg_capabilities.dart';

void main() {
  test('parses encoder names with FFmpeg capability flags', () {
    const listing = '''
Encoders:
 V....D libx264             H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10
 A....D aac                 AAC (Advanced Audio Coding)
 A....D libopus             Opus
 S..... dvdsub              DVD subtitles
''';

    expect(FfmpegCapabilities.parseEncoders(listing), {'libx264', 'aac', 'libopus', 'dvdsub'});
  });

  test('parses output-capable muxers with optional demux support flag', () {
    const listing = '''
Muxers:
  E  mp4              MP4 (MPEG-4 Part 14)
 DE matroska          Matroska
''';

    expect(FfmpegCapabilities.parseMuxers(listing), {'mp4', 'matroska'});
  });
}
