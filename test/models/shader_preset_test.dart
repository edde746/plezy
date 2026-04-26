import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/shader_preset.dart';

void main() {
  group('ShaderPreset ArtCNN presets', () {
    test('exposes stable built-in preset ids in the expected order', () {
      final ids = ShaderPreset.allPresets.map((preset) => preset.id).toList();

      expect(ids.take(8), [
        ShaderPreset.none.id,
        ShaderPreset.nvscalerDefault.id,
        'artcnn_c4f16_neutral',
        'artcnn_c4f16_dn',
        'artcnn_c4f16_ds',
        'artcnn_c4f32_neutral',
        'artcnn_c4f32_dn',
        'artcnn_c4f32_ds',
      ]);
    });

    test('creates ArtCNN presets with names, type, and config', () {
      final neutral = ShaderPreset.artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.neutral);
      final denoise = ShaderPreset.artcnnPreset(ArtCNNModel.c4f32, ArtCNNVariant.denoise);
      final sharpen = ShaderPreset.artcnnPreset(ArtCNNModel.c4f32, ArtCNNVariant.denoiseSharpen);

      expect(neutral.id, 'artcnn_c4f16_neutral');
      expect(neutral.name, 'ArtCNN C4F16');
      expect(neutral.type, ShaderPresetType.artcnn);
      expect(neutral.artcnnConfig, const ArtCNNConfig(model: ArtCNNModel.c4f16, variant: ArtCNNVariant.neutral));
      expect(neutral.artcnnModelDisplayName, 'C4F16');

      expect(denoise.id, 'artcnn_c4f32_dn');
      expect(denoise.name, 'ArtCNN C4F32 Denoise');
      expect(denoise.artcnnConfig, const ArtCNNConfig(model: ArtCNNModel.c4f32, variant: ArtCNNVariant.denoise));

      expect(sharpen.id, 'artcnn_c4f32_ds');
      expect(sharpen.name, 'ArtCNN C4F32 Denoise + Sharpen');
      expect(sharpen.artcnnConfig, const ArtCNNConfig(model: ArtCNNModel.c4f32, variant: ArtCNNVariant.denoiseSharpen));
    });

    test('finds ArtCNN presets by id', () {
      final preset = ShaderPreset.fromId('artcnn_c4f32_ds');

      expect(preset, isNotNull);
      expect(preset!.type, ShaderPresetType.artcnn);
      expect(preset.artcnnConfig, const ArtCNNConfig(model: ArtCNNModel.c4f32, variant: ArtCNNVariant.denoiseSharpen));
    });

    test('round-trips ArtCNN config through json', () {
      final preset = ShaderPreset.artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.denoise);
      final decoded = ShaderPreset.fromJson(preset.toJson());

      expect(decoded, preset);
      expect(decoded.artcnnConfig, preset.artcnnConfig);
    });
  });
}
