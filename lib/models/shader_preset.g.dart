// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shader_preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Anime4KConfig _$Anime4KConfigFromJson(Map<String, dynamic> json) =>
    _Anime4KConfig(
      quality: $enumDecode(
        _$Anime4KQualityEnumMap,
        json['quality'],
        unknownValue: Anime4KQuality.fast,
      ),
      mode: $enumDecode(
        _$Anime4KModeEnumMap,
        json['mode'],
        unknownValue: Anime4KMode.modeA,
      ),
    );

Map<String, dynamic> _$Anime4KConfigToJson(_Anime4KConfig instance) =>
    <String, dynamic>{
      'quality': _$Anime4KQualityEnumMap[instance.quality]!,
      'mode': _$Anime4KModeEnumMap[instance.mode]!,
    };

const _$Anime4KQualityEnumMap = {
  Anime4KQuality.fast: 'fast',
  Anime4KQuality.hq: 'hq',
};

const _$Anime4KModeEnumMap = {
  Anime4KMode.modeA: 'modeA',
  Anime4KMode.modeB: 'modeB',
  Anime4KMode.modeC: 'modeC',
  Anime4KMode.modeAA: 'modeAA',
  Anime4KMode.modeBB: 'modeBB',
  Anime4KMode.modeCA: 'modeCA',
};

_ArtCNNConfig _$ArtCNNConfigFromJson(Map<String, dynamic> json) =>
    _ArtCNNConfig(
      model: $enumDecode(
        _$ArtCNNModelEnumMap,
        json['model'],
        unknownValue: ArtCNNModel.c4f16,
      ),
      variant: $enumDecode(
        _$ArtCNNVariantEnumMap,
        json['variant'],
        unknownValue: ArtCNNVariant.neutral,
      ),
    );

Map<String, dynamic> _$ArtCNNConfigToJson(_ArtCNNConfig instance) =>
    <String, dynamic>{
      'model': _$ArtCNNModelEnumMap[instance.model]!,
      'variant': _$ArtCNNVariantEnumMap[instance.variant]!,
    };

const _$ArtCNNModelEnumMap = {
  ArtCNNModel.c4f16: 'c4f16',
  ArtCNNModel.c4f32: 'c4f32',
};

const _$ArtCNNVariantEnumMap = {
  ArtCNNVariant.neutral: 'neutral',
  ArtCNNVariant.denoise: 'denoise',
  ArtCNNVariant.denoiseSharpen: 'denoiseSharpen',
};

_NVScalerConfig _$NVScalerConfigFromJson(Map<String, dynamic> json) =>
    _NVScalerConfig(autoHdrSkip: json['autoHdrSkip'] as bool? ?? true);

Map<String, dynamic> _$NVScalerConfigToJson(_NVScalerConfig instance) =>
    <String, dynamic>{'autoHdrSkip': instance.autoHdrSkip};
