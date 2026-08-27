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
}
