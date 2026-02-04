/// Shader preset types available in the app
enum ShaderPresetType { none, nvscaler, anime4k }

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

/// Configuration for Anime4K preset
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
      quality: Anime4KQuality.values.firstWhere((e) => e.name == json['quality'], orElse: () => Anime4KQuality.fast),
      mode: Anime4KMode.values.firstWhere((e) => e.name == json['mode'], orElse: () => Anime4KMode.modeA),
    );
  }
}

/// Configuration for NVScaler preset
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

/// Represents a shader preset configuration
class ShaderPreset {
  final String id;
  final String name;
  final ShaderPresetType type;
  final Anime4KConfig? anime4kConfig;
  final NVScalerConfig? nvscalerConfig;

  const ShaderPreset({
    required this.id,
    required this.name,
    required this.type,
    this.anime4kConfig,
    this.nvscalerConfig,
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

  /// Get display name for the mode
  String get modeDisplayName {
    if (anime4kConfig != null) {
      return _getModeName(anime4kConfig!.mode);
    }
    return '';
  }

  /// Get all available preset options
  static List<ShaderPreset> get allPresets {
    return [
      none,
      nvscalerDefault,
      // Anime4K Fast presets
      anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeA),
      anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeB),
      anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeC),
      anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeAA),
      anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeBB),
      anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeCA),
      // Anime4K HQ presets
      anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeA),
      anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeB),
      anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeC),
      anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeAA),
      anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeBB),
      anime4kPreset(Anime4KQuality.hq, Anime4KMode.modeCA),
    ];
  }

  /// Find a preset by its ID
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
    if (anime4kConfig != null) 'anime4kConfig': anime4kConfig!.toJson(),
    if (nvscalerConfig != null) 'nvscalerConfig': nvscalerConfig!.toJson(),
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
      type: ShaderPresetType.values.firstWhere((e) => e.name == json['type'], orElse: () => ShaderPresetType.none),
      anime4kConfig: json['anime4kConfig'] != null ? Anime4KConfig.fromJson(json['anime4kConfig']) : null,
      nvscalerConfig: json['nvscalerConfig'] != null ? NVScalerConfig.fromJson(json['nvscalerConfig']) : null,
    );
  }
}
