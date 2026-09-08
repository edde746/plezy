import 'package:flutter/foundation.dart';

/// Stable storage keys for the device-wide EQ and optional audio-format profiles.
enum EqualizerAudioType { global, stereo, surround, ac3, eac3, dts, truehd }

enum EqualizerPreset { flat, bass, movie, speech }

/// Immutable, validated settings for one audio profile.
@immutable
class EqualizerProfile {
  static const bandCount = 10;
  static const flatGains = <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  static const flat = EqualizerProfile._(flatGains, 0, 0, false);

  final List<double> gains;
  final double preampDb;
  final double bassDb;
  final bool useGlobal;

  const EqualizerProfile._(this.gains, this.preampDb, this.bassDb, this.useGlobal);

  factory EqualizerProfile({
    List<double> gains = flatGains,
    double preampDb = 0,
    double bassDb = 0,
    bool useGlobal = false,
  }) => EqualizerProfile._(
    List.unmodifiable(normalizeBands(gains)),
    normalizeGain(preampDb),
    normalizeGain(bassDb),
    useGlobal,
  );

  static double normalizeGain(dynamic value) =>
      value is num && value.isFinite ? value.toDouble().clamp(-12.0, 12.0) : 0.0;

  static List<double> normalizeBands(dynamic values) =>
      List.generate(bandCount, (i) => values is List && i < values.length ? normalizeGain(values[i]) : 0.0);

  factory EqualizerProfile.fromJson(Map<dynamic, dynamic> json) => EqualizerProfile(
    gains: normalizeBands(json['gains']),
    preampDb: normalizeGain(json['preampDb']),
    bassDb: normalizeGain(json['bassDb']),
    useGlobal: json['useGlobal'] == true,
  );

  Map<String, dynamic> toJson() => {'gains': gains, 'preampDb': preampDb, 'bassDb': bassDb, 'useGlobal': useGlobal};

  EqualizerProfile copyWith({List<double>? gains, double? preampDb, double? bassDb, bool? useGlobal}) =>
      EqualizerProfile(
        gains: gains ?? this.gains,
        preampDb: preampDb ?? this.preampDb,
        bassDb: bassDb ?? this.bassDb,
        useGlobal: useGlobal ?? this.useGlobal,
      );

  bool get isFlat => preampDb == 0 && bassDb == 0 && gains.every((gain) => gain == 0);

  @override
  bool operator ==(Object other) =>
      other is EqualizerProfile &&
      listEquals(gains, other.gains) &&
      preampDb == other.preampDb &&
      bassDb == other.bassDb &&
      useGlobal == other.useGlobal;

  @override
  int get hashCode => Object.hash(Object.hashAll(gains), preampDb, bassDb, useGlobal);
}

/// Device-local EQ profiles. Choosing Global keeps the dormant format profile.
@immutable
class EqualizerSettings {
  final Map<EqualizerAudioType, EqualizerProfile> profiles;

  const EqualizerSettings.empty() : profiles = const {};

  EqualizerSettings(Map<EqualizerAudioType, EqualizerProfile> profiles) : profiles = Map.unmodifiable(profiles);

  factory EqualizerSettings.fromJson(dynamic value) {
    if (value is! Map) return const EqualizerSettings.empty();
    final current = value['profiles'];
    if (current is Map) {
      return EqualizerSettings({
        for (final type in EqualizerAudioType.values)
          if (current[type.name] is Map) type: EqualizerProfile.fromJson(current[type.name] as Map),
      });
    }
    // Migrate the original experimental map (bands plus singleton amp/bass arrays).
    double legacyGain(String key) =>
        value[key] is List && (value[key] as List).isNotEmpty ? EqualizerProfile.normalizeGain(value[key][0]) : 0;
    return EqualizerSettings({
      for (final type in EqualizerAudioType.values)
        if (value[type.name] is List)
          type: EqualizerProfile(
            gains: EqualizerProfile.normalizeBands(value[type.name]),
            preampDb: legacyGain('${type.name}.amp'),
            bassDb: legacyGain('${type.name}.bass'),
          ),
    });
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'profiles': {for (final entry in profiles.entries) entry.key.name: entry.value.toJson()},
  };

  EqualizerProfile resolve(EqualizerAudioType type) {
    final profile = profiles[type];
    return type == EqualizerAudioType.global || profile == null || profile.useGlobal
        ? profiles[EqualizerAudioType.global] ?? EqualizerProfile.flat
        : profile;
  }

  bool inherits(EqualizerAudioType type) => type != EqualizerAudioType.global && (profiles[type]?.useGlobal ?? true);

  EqualizerSettings withProfile(EqualizerAudioType type, EqualizerProfile profile) =>
      EqualizerSettings({...profiles, type: profile});

  EqualizerSettings setInheritance(EqualizerAudioType type, bool useGlobal) =>
      withProfile(type, (profiles[type] ?? resolve(type)).copyWith(useGlobal: useGlobal));

  @override
  bool operator ==(Object other) => other is EqualizerSettings && mapEquals(profiles, other.profiles);

  @override
  int get hashCode => Object.hashAll(EqualizerAudioType.values.map((type) => profiles[type]));
}

class AudioEqualizer {
  static const frequencies = [31.25, 62.5, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];
  static const presetGains = <EqualizerPreset, List<double>>{
    EqualizerPreset.flat: EqualizerProfile.flatGains,
    EqualizerPreset.bass: [5, 4, 3, 1, 0, 0, 0, 0, 0, 0],
    EqualizerPreset.movie: [2, 2, 0, -1, 0, 2, 3, 2, 1, 0],
    EqualizerPreset.speech: [-3, -2, -1, 0, 2, 3, 3, 1, 0, -1],
  };

  /// A forced stereo mix takes precedence over the source codec.
  static EqualizerAudioType audioType({String? codec, int? channels, bool downmix = false}) {
    if (downmix) return EqualizerAudioType.stereo;
    final normalized = codec?.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '') ?? '';
    if (normalized.contains('eac3') || normalized == 'ec3') return EqualizerAudioType.eac3;
    if (normalized == 'ac3') return EqualizerAudioType.ac3;
    if (normalized.startsWith('dts')) return EqualizerAudioType.dts;
    if (normalized == 'truehd' || normalized == 'mlp') return EqualizerAudioType.truehd;
    if (channels != null && channels > 0) {
      return channels <= 2 ? EqualizerAudioType.stereo : EqualizerAudioType.surround;
    }
    return EqualizerAudioType.global;
  }

  /// Null denotes custom band values. Preamp and Bass remain independent.
  static EqualizerPreset? preset(List<double> gains) {
    for (final entry in presetGains.entries) {
      if (listEquals(gains, entry.value)) return entry.key;
    }
    return null;
  }
}
