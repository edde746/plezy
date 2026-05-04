// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaProviderInfo _$MediaProviderInfoFromJson(Map<String, dynamic> json) => MediaProviderInfo(
  id: flexibleInt(json['id']),
  parentID: flexibleInt(json['parentID']),
  identifier: json['identifier'] as String? ?? '',
  providerIdentifier: json['providerIdentifier'] as String?,
  title: json['title'] as String?,
  types: json['types'] as String?,
  protocols: json['protocols'] as String?,
  epgSource: json['epgSource'] as String?,
  friendlyName: json['friendlyName'] as String?,
  features: json['Feature'] == null ? const [] : _parseFeatures(json['Feature']),
);

MediaProviderFeature _$MediaProviderFeatureFromJson(Map<String, dynamic> json) => MediaProviderFeature(
  key: json['key'] as String?,
  type: json['type'] as String? ?? '',
  flavor: json['flavor'] as String?,
  scrobbleKey: json['scrobbleKey'] as String?,
  unscrobbleKey: json['unscrobbleKey'] as String?,
  directories: json['Directory'] == null ? const [] : _parseRawMaps(json['Directory']),
  actions: json['Action'] == null ? const [] : _parseRawMaps(json['Action']),
  pivots: json['Pivot'] == null ? const [] : _parseRawMaps(json['Pivot']),
);
