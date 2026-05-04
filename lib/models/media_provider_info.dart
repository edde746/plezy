import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';

part 'media_provider_info.g.dart';

List<MediaProviderFeature> _parseFeatures(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) MediaProviderFeature.fromJson(item),
  ];
}

List<Map<String, dynamic>> _parseRawMaps(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) item,
  ];
}

@JsonSerializable(createToJson: false)
class MediaProviderInfo {
  @JsonKey(fromJson: flexibleInt)
  final int? id;
  @JsonKey(fromJson: flexibleInt)
  final int? parentID;
  @JsonKey(defaultValue: '')
  final String identifier;
  final String? providerIdentifier;
  final String? title;
  final String? types;
  final String? protocols;
  final String? epgSource;
  final String? friendlyName;
  @JsonKey(name: 'Feature', fromJson: _parseFeatures)
  final List<MediaProviderFeature> features;

  const MediaProviderInfo({
    this.id,
    this.parentID,
    required this.identifier,
    this.providerIdentifier,
    this.title,
    this.types,
    this.protocols,
    this.epgSource,
    this.friendlyName,
    this.features = const [],
  });

  factory MediaProviderInfo.fromJson(Map<String, dynamic> json) => _$MediaProviderInfoFromJson(json);
}

@JsonSerializable(createToJson: false)
class MediaProviderFeature {
  final String? key;
  @JsonKey(defaultValue: '')
  final String type;
  final String? flavor;
  final String? scrobbleKey;
  final String? unscrobbleKey;
  @JsonKey(name: 'Directory', fromJson: _parseRawMaps)
  final List<Map<String, dynamic>> directories;
  @JsonKey(name: 'Action', fromJson: _parseRawMaps)
  final List<Map<String, dynamic>> actions;
  @JsonKey(name: 'Pivot', fromJson: _parseRawMaps)
  final List<Map<String, dynamic>> pivots;

  const MediaProviderFeature({
    this.key,
    required this.type,
    this.flavor,
    this.scrobbleKey,
    this.unscrobbleKey,
    this.directories = const [],
    this.actions = const [],
    this.pivots = const [],
  });

  factory MediaProviderFeature.fromJson(Map<String, dynamic> json) => _$MediaProviderFeatureFromJson(json);
}
