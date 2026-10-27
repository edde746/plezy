import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/dolby_vision_playback.dart';

void main() {
  test('P7 decoder and gpu-next advertisements never establish FEL composition', () {
    for (final route in ['dv-decoder', 'reshaped', 'fel-graph-active', null]) {
      final report = DolbyVisionPlayback.fromStats({'dvSourceProfile': 7, 'dvRoute': route});
      expect(report.enhancement, DolbyVisionLayerUse.unknown);
      expect(report.layerNotation, 'BL / EL?');
    }
  });

  test('mpv conversion and base routes explicitly discard the P7 enhancement', () {
    for (final route in ['dv-decoder-p81', 'base-layer']) {
      final report = DolbyVisionPlayback.fromStats({'dvSourceProfile': 7, 'dvRoute': route});
      expect(report.enhancement, DolbyVisionLayerUse.discarded);
      expect(report.layerNotation, 'BL / EL−');
    }
  });

  test('ExoPlayer must actually activate conversion before reporting discarded EL', () {
    for (final mode in ['DV81', 'HEVC_STRIP']) {
      final requested = {'dvSourceProfile': 7, 'dvConversionMode': mode};
      expect(DolbyVisionPlayback.fromStats(requested).enhancement, DolbyVisionLayerUse.unknown);
      expect(
        DolbyVisionPlayback.fromStats({...requested, 'dvConversionActive': true}).enhancement,
        DolbyVisionLayerUse.discarded,
      );
    }
  });

  test('non-P7 and stale reports cannot acquire a P7 enhancement label', () {
    for (final profile in [null, 5, 8, 10, 20]) {
      expect(
        DolbyVisionPlayback.fromStats({'dvSourceProfile': profile, 'dvRoute': 'dv-decoder-p81'}).layerNotation,
        isEmpty,
      );
    }
    expect(DolbyVisionPlayback.fromStats({'dvSourceProfile': '7'}).layerNotation, 'BL / EL?');
  });
}
