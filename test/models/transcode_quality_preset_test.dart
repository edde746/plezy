import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

void main() {
  group('TranscodeQualityPreset.resolveStartupDefault', () {
    test('a backend without transcoding starts at original regardless of saved defaults', () {
      final preset = TranscodeQualityPreset.resolveStartupDefault(
        serverSupportsTranscoding: false,
        onCellularOnly: true,
        cellularDefault: TranscodeQualityPreset.p720_2mbps,
        generalDefault: TranscodeQualityPreset.p1080_8mbps,
      );

      expect(preset, TranscodeQualityPreset.original);
    });

    test('cellular-only applies the cellular default when one is set', () {
      final preset = TranscodeQualityPreset.resolveStartupDefault(
        serverSupportsTranscoding: true,
        onCellularOnly: true,
        cellularDefault: TranscodeQualityPreset.p720_2mbps,
        generalDefault: TranscodeQualityPreset.original,
      );

      expect(preset, TranscodeQualityPreset.p720_2mbps);
    });

    test('cellular-only without a cellular default follows the general default', () {
      final preset = TranscodeQualityPreset.resolveStartupDefault(
        serverSupportsTranscoding: true,
        onCellularOnly: true,
        cellularDefault: null,
        generalDefault: TranscodeQualityPreset.p1080_8mbps,
      );

      expect(preset, TranscodeQualityPreset.p1080_8mbps);
    });

    test('off cellular, the cellular default is ignored', () {
      final preset = TranscodeQualityPreset.resolveStartupDefault(
        serverSupportsTranscoding: true,
        onCellularOnly: false,
        cellularDefault: TranscodeQualityPreset.p240_320,
        generalDefault: TranscodeQualityPreset.original,
      );

      expect(preset, TranscodeQualityPreset.original);
    });
  });

  group('TranscodeQualityPreset.coversSource', () {
    test('a source under both caps is covered', () {
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 6206, heightPx: 1080), isTrue);
    });

    test('a source exactly at the caps is covered, because an encode cannot improve on it', () {
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 10000, heightPx: 1080), isTrue);
    });

    test('a source over the bitrate cap is not covered', () {
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 13137, heightPx: 1080), isFalse);
    });

    test('a source over the resolution cap is not covered, however low its bitrate', () {
      expect(TranscodeQualityPreset.p1080_10mbps.coversSource(bitrateKbps: 6534, heightPx: 2160), isFalse);
      expect(TranscodeQualityPreset.p480_1_5mbps.coversSource(bitrateKbps: 179, heightPx: 1080), isFalse);
    });

    test('a missing or non-positive bitrate or height leaves the transcode standing', () {
      const preset = TranscodeQualityPreset.p1080_10mbps;
      expect(preset.coversSource(bitrateKbps: null, heightPx: 1080), isFalse);
      expect(preset.coversSource(bitrateKbps: 6206, heightPx: null), isFalse);
      expect(preset.coversSource(bitrateKbps: 0, heightPx: 1080), isFalse);
      expect(preset.coversSource(bitrateKbps: 6206, heightPx: 0), isFalse);
    });

    test('original has no ceiling to sit inside', () {
      expect(TranscodeQualityPreset.original.coversSource(bitrateKbps: 1, heightPx: 1), isFalse);
    });
  });

  group('matchByName', () {
    test('names for the untranscoded stream all resolve to original', () {
      for (final q in ['original', 'Original', ' source ', 'max', 'maximum', 'best', 'full']) {
        expect(TranscodeQualityPreset.matchByName(q), TranscodeQualityPreset.original, reason: q);
      }
    });

    test('a bare resolution picks the highest bitrate at that resolution', () {
      expect(TranscodeQualityPreset.matchByName('1080p'), TranscodeQualityPreset.p1080_20mbps);
      expect(TranscodeQualityPreset.matchByName('720p'), TranscodeQualityPreset.p720_4mbps);
      expect(TranscodeQualityPreset.matchByName('480'), TranscodeQualityPreset.p480_1_5mbps);
      expect(TranscodeQualityPreset.matchByName('240p'), TranscodeQualityPreset.p240_320);
    });

    test('an explicit bitrate disambiguates within a resolution', () {
      expect(TranscodeQualityPreset.matchByName('720p 3mbps'), TranscodeQualityPreset.p720_3mbps);
      expect(TranscodeQualityPreset.matchByName('720p 2'), TranscodeQualityPreset.p720_2mbps);
      expect(TranscodeQualityPreset.matchByName('1080p 8 mbps'), TranscodeQualityPreset.p1080_8mbps);
      expect(TranscodeQualityPreset.matchByName('1080p 12mbps'), TranscodeQualityPreset.p1080_12mbps);
    });

    test('an unavailable bitrate falls back to the nearest at that resolution', () {
      // 5 mbps at 720p is not in the table, so the nearest bitrate wins.
      expect(TranscodeQualityPreset.matchByName('720p 5mbps'), TranscodeQualityPreset.p720_4mbps);
    });

    test('the storage name matches itself, so pickers and remotes cannot drift', () {
      for (final preset in TranscodeQualityPreset.values) {
        expect(TranscodeQualityPreset.matchByName(preset.name), preset, reason: preset.name);
      }
    });

    test('returns null when nothing sensible matches', () {
      for (final q in ['', '   ', '8k', 'potato', 'subtitles']) {
        expect(TranscodeQualityPreset.matchByName(q), isNull, reason: q);
      }
    });
  });
}
