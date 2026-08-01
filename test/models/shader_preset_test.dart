import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/shader_preset.dart';

void main() {
  group('ShaderPreset ArtCNN presets', () {
    test('exposes the complete built-in catalog in stable order', () {
      expect(ShaderPreset.allPresets.map((preset) => preset.toJson()).toList(), [
        {'id': 'none', 'name': 'Off', 'type': 'none'},
        {
          'id': 'nvscaler',
          'name': 'NVScaler',
          'type': 'nvscaler',
          'nvscalerConfig': {'autoHdrSkip': true},
        },
        {
          'id': 'artcnn_c4f16_neutral',
          'name': 'ArtCNN C4F16',
          'type': 'artcnn',
          'artcnnConfig': {'model': 'c4f16', 'variant': 'neutral'},
        },
        {
          'id': 'artcnn_c4f16_dn',
          'name': 'ArtCNN C4F16 Denoise',
          'type': 'artcnn',
          'artcnnConfig': {'model': 'c4f16', 'variant': 'denoise'},
        },
        {
          'id': 'artcnn_c4f16_ds',
          'name': 'ArtCNN C4F16 Denoise + Sharpen',
          'type': 'artcnn',
          'artcnnConfig': {'model': 'c4f16', 'variant': 'denoiseSharpen'},
        },
        {
          'id': 'artcnn_c4f32_neutral',
          'name': 'ArtCNN C4F32',
          'type': 'artcnn',
          'artcnnConfig': {'model': 'c4f32', 'variant': 'neutral'},
        },
        {
          'id': 'artcnn_c4f32_dn',
          'name': 'ArtCNN C4F32 Denoise',
          'type': 'artcnn',
          'artcnnConfig': {'model': 'c4f32', 'variant': 'denoise'},
        },
        {
          'id': 'artcnn_c4f32_ds',
          'name': 'ArtCNN C4F32 Denoise + Sharpen',
          'type': 'artcnn',
          'artcnnConfig': {'model': 'c4f32', 'variant': 'denoiseSharpen'},
        },
        for (final entry in const [
          ('fast', 'modeA', 'Anime4K Fast A'),
          ('fast', 'modeB', 'Anime4K Fast B'),
          ('fast', 'modeC', 'Anime4K Fast C'),
          ('fast', 'modeAA', 'Anime4K Fast A+A'),
          ('fast', 'modeBB', 'Anime4K Fast B+B'),
          ('fast', 'modeCA', 'Anime4K Fast C+A'),
          ('hq', 'modeA', 'Anime4K HQ A'),
          ('hq', 'modeB', 'Anime4K HQ B'),
          ('hq', 'modeC', 'Anime4K HQ C'),
          ('hq', 'modeAA', 'Anime4K HQ A+A'),
          ('hq', 'modeBB', 'Anime4K HQ B+B'),
          ('hq', 'modeCA', 'Anime4K HQ C+A'),
        ])
          {
            'id': 'anime4k_${entry.$1}_${entry.$2}',
            'name': entry.$3,
            'type': 'anime4k',
            'anime4kConfig': {'quality': entry.$1, 'mode': entry.$2},
          },
      ]);
    });

    test('shares an unmodifiable catalog and canonical id lookup', () {
      final first = ShaderPreset.allPresets;
      final second = ShaderPreset.allPresets;

      expect(identical(first, second), isTrue);
      expect(() => first.add(ShaderPreset.none), throwsUnsupportedError);
      expect(() => first.removeLast(), throwsUnsupportedError);
      for (final preset in first) {
        expect(identical(ShaderPreset.fromId(preset.id), preset), isTrue);
        expect(identical(ShaderPreset.fromJson(preset.toJson()), preset), isTrue);
      }
      expect(ShaderPreset.fromId('unknown'), isNull);
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
