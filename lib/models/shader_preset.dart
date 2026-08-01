// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shader_preset.freezed.dart';
part 'shader_preset.g.dart';

enum ShaderPresetType { none, nvscaler, artcnn, anime4k, custom }

/// ArtCNN real-time model sizes.
enum ArtCNNModel {
  /// Lightweight real-time model
  c4f16('C4F16'),

  /// Higher-quality real-time model
  c4f32('C4F32');

  const ArtCNNModel(this.label);

  /// Display label for the model.
  final String label;
}

/// ArtCNN luma doubler variants.
enum ArtCNNVariant {
  /// Neutral luma doubler
  neutral('Neutral', 'neutral'),

  /// Denoise and soften
  denoise('Denoise', 'dn'),

  /// Denoise and sharpen
  denoiseSharpen('Denoise + Sharpen', 'ds');

  const ArtCNNVariant(this.label, this.slug);

  /// Display label for the variant.
  final String label;

  /// Stable slug used in built-in preset ids and shader asset keys.
  final String slug;
}

/// Quality tiers for Anime4K presets
enum Anime4KQuality {
  /// Fast quality using Mode L shaders
  fast,

  /// High quality using Mode VL/UL shaders
  hq,
}

/// Anime4K modes that define shader combinations
enum Anime4KMode {
  /// Mode A: Clamp + Restore
  modeA('A'),

  /// Mode B: Clamp + Restore + Upscale + Downscale
  modeB('B'),

  /// Mode C: Clamp + Upscale + Downscale
  modeC('C'),

  /// Mode A+A: Clamp + Restore + Restore
  modeAA('A+A'),

  /// Mode B+B: Clamp + Restore + Restore + Upscale + Downscale
  modeBB('B+B'),

  /// Mode C+A: Clamp + Upscale + Restore + Downscale
  modeCA('C+A');

  const Anime4KMode(this.label);

  /// Display label for the mode.
  final String label;
}

@freezed
sealed class Anime4KConfig with _$Anime4KConfig {
  const factory Anime4KConfig({
    @JsonKey(unknownEnumValue: Anime4KQuality.fast) required Anime4KQuality quality,
    @JsonKey(unknownEnumValue: Anime4KMode.modeA) required Anime4KMode mode,
  }) = _Anime4KConfig;

  factory Anime4KConfig.fromJson(Map<String, dynamic> json) => _$Anime4KConfigFromJson(json);
}

@freezed
sealed class ArtCNNConfig with _$ArtCNNConfig {
  const factory ArtCNNConfig({
    @JsonKey(unknownEnumValue: ArtCNNModel.c4f16) required ArtCNNModel model,
    @JsonKey(unknownEnumValue: ArtCNNVariant.neutral) required ArtCNNVariant variant,
  }) = _ArtCNNConfig;

  factory ArtCNNConfig.fromJson(Map<String, dynamic> json) => _$ArtCNNConfigFromJson(json);
}

@freezed
sealed class NVScalerConfig with _$NVScalerConfig {
  const factory NVScalerConfig({
    /// Whether to automatically skip NVScaler on HDR content
    @Default(true) bool autoHdrSkip,
  }) = _NVScalerConfig;

  factory NVScalerConfig.fromJson(Map<String, dynamic> json) => _$NVScalerConfigFromJson(json);
}

class ShaderPreset {
  final String id;
  final String name;
  final ShaderPresetType type;
  final ArtCNNConfig? artcnnConfig;
  final Anime4KConfig? anime4kConfig;
  final NVScalerConfig? nvscalerConfig;

  /// File name of the custom shader in the custom shaders directory
  final String? fileName;

  const ShaderPreset({
    required this.id,
    required this.name,
    required this.type,
    this.artcnnConfig,
    this.anime4kConfig,
    this.nvscalerConfig,
    this.fileName,
  });

  /// No shader preset (off)
  static const none = ShaderPreset(id: 'none', name: 'Off', type: ShaderPresetType.none);

  /// NVScaler default preset with auto HDR skip
  static const nvscalerDefault = ShaderPreset(
    id: 'nvscaler',
    name: 'NVScaler',
    type: ShaderPresetType.nvscaler,
    nvscalerConfig: NVScalerConfig(),
  );

  /// Create an ArtCNN preset with the specified model and variant
  static ShaderPreset artcnnPreset(ArtCNNModel model, ArtCNNVariant variant) => ShaderPreset(
    id: 'artcnn_${model.name}_${variant.slug}',
    name: variant == ArtCNNVariant.neutral ? 'ArtCNN ${model.label}' : 'ArtCNN ${model.label} ${variant.label}',
    type: ShaderPresetType.artcnn,
    artcnnConfig: ArtCNNConfig(model: model, variant: variant),
  );

  /// Create an Anime4K preset with the specified quality and mode
  static ShaderPreset anime4kPreset(Anime4KQuality quality, Anime4KMode mode) {
    final qualityName = quality == Anime4KQuality.fast ? 'Fast' : 'HQ';

    return ShaderPreset(
      id: 'anime4k_${quality.name}_${mode.name}',
      name: 'Anime4K $qualityName ${mode.label}',
      type: ShaderPresetType.anime4k,
      anime4kConfig: Anime4KConfig(quality: quality, mode: mode),
    );
  }

  String get modeDisplayName => anime4kConfig?.mode.label ?? '';

  String get artcnnModelDisplayName => artcnnConfig?.model.label ?? '';

  static final List<ShaderPreset> _builtInPresets = List.unmodifiable([
    none,
    nvscalerDefault,
    artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.neutral),
    artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.denoise),
    artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.denoiseSharpen),
    artcnnPreset(ArtCNNModel.c4f32, ArtCNNVariant.neutral),
    artcnnPreset(ArtCNNModel.c4f32, ArtCNNVariant.denoise),
    artcnnPreset(ArtCNNModel.c4f32, ArtCNNVariant.denoiseSharpen),
    anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeA),
    anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeB),
    anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeC),
    anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeAA),
    anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeBB),
    anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeCA),
    anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeA),
    anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeB),
    anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeC),
    anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeAA),
    anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeBB),
    anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeCA),
  ]);

  static final Map<String, ShaderPreset> _builtInPresetsById = Map.unmodifiable({
    for (final preset in _builtInPresets) preset.id: preset,
  });

  static List<ShaderPreset> get allPresets => _builtInPresets;

  static ShaderPreset? fromId(String id) => _builtInPresetsById[id];

  bool get isEnabled => type != ShaderPresetType.none;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShaderPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    if (artcnnConfig != null) 'artcnnConfig': artcnnConfig!.toJson(),
    if (anime4kConfig != null) 'anime4kConfig': anime4kConfig!.toJson(),
    if (nvscalerConfig != null) 'nvscalerConfig': nvscalerConfig!.toJson(),
    if (fileName != null) 'fileName': fileName,
  };

  factory ShaderPreset.fromJson(Map<String, dynamic> json) {
    // Try to find by ID first for built-in presets
    final id = json['id'] as String?;
    if (id != null) {
      final builtIn = fromId(id);
      if (builtIn != null) return builtIn;
    }

    // Otherwise create from JSON
    return ShaderPreset(
      id: id ?? 'custom',
      name: json['name'] as String? ?? 'Custom',
      type: ShaderPresetType.values.asNameMap()[json['type']] ?? ShaderPresetType.none,
      artcnnConfig: json['artcnnConfig'] != null ? ArtCNNConfig.fromJson(json['artcnnConfig']) : null,
      anime4kConfig: json['anime4kConfig'] != null ? Anime4KConfig.fromJson(json['anime4kConfig']) : null,
      nvscalerConfig: json['nvscalerConfig'] != null ? NVScalerConfig.fromJson(json['nvscalerConfig']) : null,
      fileName: json['fileName'] as String?,
    );
  }
}
