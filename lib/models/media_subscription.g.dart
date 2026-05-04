// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionTemplate _$SubscriptionTemplateFromJson(Map<String, dynamic> json) => SubscriptionTemplate(
  subscriptions: json['MediaSubscription'] == null ? const [] : _parseSubscriptions(json['MediaSubscription']),
);

MediaSubscription _$MediaSubscriptionFromJson(Map<String, dynamic> json) => MediaSubscription(
  key: json['key'] as String? ?? '',
  type: flexibleInt(json['type']),
  provider: json['provider'] as String?,
  targetLibrarySectionID: flexibleInt(json['targetLibrarySectionID']),
  targetSectionLocationID: flexibleInt(json['targetSectionLocationID']),
  title: json['title'] as String?,
  selected: flexibleBoolNullable(json['selected']),
  parameters: json['parameters'] as String?,
  createdAt: flexibleInt(json['createdAt']),
  storageTotal: flexibleInt(json['storageTotal']),
  durationTotal: flexibleInt(json['durationTotal']),
  airingsType: json['airingsType'] as String?,
  librarySectionTitle: json['librarySectionTitle'] as String?,
  locationPath: json['locationPath'] as String?,
  video: _mapFromJson(json['Video']),
  directory: _mapFromJson(json['Directory']),
  playlist: _mapFromJson(json['Playlist']),
  settings: json['Setting'] == null ? const [] : _parseSettings(json['Setting']),
  grabOperations: json['MediaGrabOperation'] == null ? const [] : _parseGrabOperations(json['MediaGrabOperation']),
);

SubscriptionSetting _$SubscriptionSettingFromJson(Map<String, dynamic> json) => SubscriptionSetting(
  id: json['id'] as String? ?? '',
  label: json['label'] as String?,
  summary: json['summary'] as String?,
  type: json['type'] as String?,
  defaultValue: json['default'],
  value: json['value'],
  hidden: json['hidden'] == null ? false : flexibleBool(json['hidden']),
  advanced: json['advanced'] == null ? false : flexibleBool(json['advanced']),
  group: json['group'] as String?,
  enumValues: json['enumValues'] as String?,
);
