import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

void main() {
  test('240p preset uses the documented 320x240 resolution', () {
    expect(TranscodeQualityPreset.p240_320.videoResolution, '320x240');
  });

  group('TranscodeQualityPreset.forSource', () {
    test('keeps Original when a source is already below the selected ceiling', () {
      const source = MediaVersion(id: 'source', bitrate: 817, width: 716, height: 480);

      expect(TranscodeQualityPreset.p480_1_5mbps.forSource(source), TranscodeQualityPreset.original);
      expect(TranscodeQualityPreset.p720_2mbps.forSource(source), TranscodeQualityPreset.original);
    });

    test('transcodes when either bitrate or resolution exceeds the ceiling', () {
      const highBitrate = MediaVersion(id: 'bitrate', bitrate: 2500, width: 640, height: 480);
      const highResolution = MediaVersion(id: 'resolution', bitrate: 1000, width: 1920, height: 1080);

      expect(TranscodeQualityPreset.p720_2mbps.forSource(highBitrate), TranscodeQualityPreset.p720_2mbps);
      expect(TranscodeQualityPreset.p720_2mbps.forSource(highResolution), TranscodeQualityPreset.p720_2mbps);
    });

    test('keeps the requested preset when source limits are unknown', () {
      const source = MediaVersion(id: 'source');

      expect(TranscodeQualityPreset.p720_2mbps.forSource(source), TranscodeQualityPreset.p720_2mbps);
    });
  });
}
