enum ShaderPresetType { none, nvscaler, artcnn, anime4k, custom }

/// ArtCNN real-time model sizes.
enum ArtCNNModel {
  /// Lightweight real-time model
  c4f16,

  /// Higher-quality real-time model
  c4f32,
}

/// ArtCNN luma doubler variants.
enum ArtCNNVariant {
  /// Neutral luma doubler
  neutral,

  /// Denoise and soften
  denoise,

  /// Denoise and sharpen
  denoiseSharpen,
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
  modeA,

  /// Mode B: Clamp + Restore + Upscale + Downscale
  modeB,

  /// Mode C: Clamp + Upscale + Downscale
  modeC,

  /// Mode A+A: Clamp + Restore + Restore
  modeAA,

  /// Mode B+B: Clamp + Restore + Restore + Upscale + Downscale
  modeBB,

  /// Mode C+A: Clamp + Upscale + Restore + Downscale
  modeCA,
}

class Anime4KConfig {
  final Anime4KQuality quality;
  final Anime4KMode mode;

  const Anime4KConfig({required this.quality, required this.mode});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Anime4KConfig && other.quality == quality && other.mode == mode;
  }

  @override
  int get hashCode => quality.hashCode ^ mode.hashCode;

  Map<String, dynamic> toJson() => {'quality': quality.name, 'mode': mode.name};

  factory Anime4KConfig.fromJson(Map<String, dynamic> json) {
    return Anime4KConfig(
      quality: Anime4KQuality.values.asNameMap()[json['quality']] ?? Anime4KQuality.fast,
      mode: Anime4KMode.values.asNameMap()[json['mode']] ?? Anime4KMode.modeA,
    );
  }
}

class ArtCNNConfig {
  final ArtCNNModel model;
  final ArtCNNVariant variant;

  const ArtCNNConfig({required this.model, required this.variant});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtCNNConfig && other.model == model && other.variant == variant;
  }

  @override
  int get hashCode => model.hashCode ^ variant.hashCode;

  Map<String, dynamic> toJson() => {'model': model.name, 'variant': variant.name};

  factory ArtCNNConfig.fromJson(Map<String, dynamic> json) {
    return ArtCNNConfig(
      model: ArtCNNModel.values.asNameMap()[json['model']] ?? ArtCNNModel.c4f16,
      variant: ArtCNNVariant.values.asNameMap()[json['variant']] ?? ArtCNNVariant.neutral,
    );
  }
}

class NVScalerConfig {
  /// Whether to automatically skip NVScaler on HDR content
  final bool autoHdrSkip;

  const NVScalerConfig({this.autoHdrSkip = true});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NVScalerConfig && other.autoHdrSkip == autoHdrSkip;
  }

  @override
  int get hashCode => autoHdrSkip.hashCode;

  Map<String, dynamic> toJson() => {'autoHdrSkip': autoHdrSkip};

  factory NVScalerConfig.fromJson(Map<String, dynamic> json) {
    return NVScalerConfig(autoHdrSkip: json['autoHdrSkip'] as bool? ?? true);
  }
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
  static ShaderPreset artcnnPreset(ArtCNNModel model, ArtCNNVariant variant) {
    final modelName = _getArtCNNModelName(model);
    final variantName = _getArtCNNVariantName(variant);
    final variantId = _getArtCNNVariantId(variant);

    return ShaderPreset(
      id: 'artcnn_${model.name}_$variantId',
      name: variant == ArtCNNVariant.neutral ? 'ArtCNN $modelName' : 'ArtCNN $modelName $variantName',
      type: ShaderPresetType.artcnn,
      artcnnConfig: ArtCNNConfig(model: model, variant: variant),
    );
  }

  /// Create an Anime4K preset with the specified quality and mode
  static ShaderPreset anime4kPreset(Anime4KQuality quality, Anime4KMode mode) {
    final qualityName = quality == Anime4KQuality.fast ? 'Fast' : 'HQ';
    final modeName = _getModeName(mode);

    return ShaderPreset(
      id: 'anime4k_${quality.name}_${mode.name}',
      name: 'Anime4K $qualityName $modeName',
      type: ShaderPresetType.anime4k,
      anime4kConfig: Anime4KConfig(quality: quality, mode: mode),
    );
  }

  static String _getModeName(Anime4KMode mode) {
    switch (mode) {
      case Anime4KMode.modeA:
        return 'A';
      case Anime4KMode.modeB:
        return 'B';
      case Anime4KMode.modeC:
        return 'C';
      case Anime4KMode.modeAA:
        return 'A+A';
      case Anime4KMode.modeBB:
        return 'B+B';
      case Anime4KMode.modeCA:
        return 'C+A';
    }
  }

  static String _getArtCNNModelName(ArtCNNModel model) {
    switch (model) {
      case ArtCNNModel.c4f16:
        return 'C4F16';
      case ArtCNNModel.c4f32:
        return 'C4F32';
    }
  }

  static String _getArtCNNVariantName(ArtCNNVariant variant) {
    switch (variant) {
      case ArtCNNVariant.neutral:
        return 'Neutral';
      case ArtCNNVariant.denoise:
        return 'Denoise';
      case ArtCNNVariant.denoiseSharpen:
        return 'Denoise + Sharpen';
    }
  }

  static String _getArtCNNVariantId(ArtCNNVariant variant) {
    switch (variant) {
      case ArtCNNVariant.neutral:
        return 'neutral';
      case ArtCNNVariant.denoise:
        return 'dn';
      case ArtCNNVariant.denoiseSharpen:
        return 'ds';
    }
  }

  String get modeDisplayName {
    if (anime4kConfig != null) {
      return _getModeName(anime4kConfig!.mode);
    }
    return '';
  }

  String get artcnnModelDisplayName {
    if (artcnnConfig != null) {
      return _getArtCNNModelName(artcnnConfig!.model);
    }
    return '';
  }

  static List<ShaderPreset> get allPresets {
    return [
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
    ];
  }

  static ShaderPreset? fromId(String id) {
    try {
      return allPresets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

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
