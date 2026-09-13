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

  group('TranscodeQualityPreset.resolveStartupDefault', () {
    test('a backend without transcoding starts at original regardless of saved defaults', () {
      expect(
        TranscodeQualityPreset.resolveStartupDefault(
          serverSupportsTranscoding: false,
          onCellularOnly: true,
          cellularDefault: TranscodeQualityPreset.p720_2mbps,
          generalDefault: TranscodeQualityPreset.p1080_8mbps,
        ),
        TranscodeQualityPreset.original,
      );
    });

    test('cellular-only applies its explicit default', () {
      expect(
        TranscodeQualityPreset.resolveStartupDefault(
          serverSupportsTranscoding: true,
          onCellularOnly: true,
          cellularDefault: TranscodeQualityPreset.p720_2mbps,
          generalDefault: TranscodeQualityPreset.original,
        ),
        TranscodeQualityPreset.p720_2mbps,
      );
    });

    test('otherwise follows the general default', () {
      expect(
        TranscodeQualityPreset.resolveStartupDefault(
          serverSupportsTranscoding: true,
          onCellularOnly: false,
          cellularDefault: TranscodeQualityPreset.p240_320,
          generalDefault: TranscodeQualityPreset.p1080_8mbps,
        ),
        TranscodeQualityPreset.p1080_8mbps,
      );
    });
  });

  group('TranscodeQualityPreset.coversSource', () {
    test('covers a source at or below both caps', () {
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 6206, heightPx: 1080), isTrue);
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 10000, heightPx: 1080), isTrue);
    });

    test('does not cover a source over either cap or with unknown metrics', () {
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 13137, heightPx: 1080), isFalse);
      expect(TranscodeQualityPreset.p480_1_5mbps.coversSource(bitrateKbps: 179, heightPx: 1080), isFalse);
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: null, heightPx: 1080), isFalse);
      expect(TranscodeQualityPreset.original.coversSource(bitrateKbps: 1, heightPx: 1), isFalse);
    });
  });
}
