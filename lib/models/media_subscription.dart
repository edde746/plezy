import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'media_grab_operation.dart';

part 'media_subscription.g.dart';

List<MediaSubscription> _parseSubscriptions(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) MediaSubscription.fromJson(item),
  ];
}

List<SubscriptionSetting> _parseSettings(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) SubscriptionSetting.fromJson(item),
  ];
}

List<MediaGrabOperation> _parseGrabOperations(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) MediaGrabOperation.fromJson(item),
  ];
}

Map<String, dynamic>? _mapFromJson(Object? raw) => raw is Map<String, dynamic> ? raw : null;

/// Template wrapper returned by `/media/subscriptions/template`.
@JsonSerializable(createToJson: false)
class SubscriptionTemplate {
  @JsonKey(name: 'MediaSubscription', fromJson: _parseSubscriptions)
  final List<MediaSubscription> subscriptions;

  const SubscriptionTemplate({this.subscriptions = const []});

  factory SubscriptionTemplate.fromJson(Map<String, dynamic> json) => _$SubscriptionTemplateFromJson(json);
}

/// A Plex recording/download rule (`MediaSubscription`).
@JsonSerializable(createToJson: false)
class MediaSubscription {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(fromJson: flexibleInt)
  final int? type;
  final String? provider;
  @JsonKey(fromJson: flexibleInt)
  final int? targetLibrarySectionID;
  @JsonKey(fromJson: flexibleInt)
  final int? targetSectionLocationID;
  final String? title;
  @JsonKey(fromJson: flexibleBoolNullable)
  final bool? selected;
  final String? parameters;
  @JsonKey(fromJson: flexibleInt)
  final int? createdAt;
  @JsonKey(fromJson: flexibleInt)
  final int? storageTotal;
  @JsonKey(fromJson: flexibleInt)
  final int? durationTotal;
  final String? airingsType;
  final String? librarySectionTitle;
  final String? locationPath;
  @JsonKey(name: 'Video', fromJson: _mapFromJson)
  final Map<String, dynamic>? video;
  @JsonKey(name: 'Directory', fromJson: _mapFromJson)
  final Map<String, dynamic>? directory;
  @JsonKey(name: 'Playlist', fromJson: _mapFromJson)
  final Map<String, dynamic>? playlist;
  @JsonKey(name: 'Setting', fromJson: _parseSettings)
  final List<SubscriptionSetting> settings;
  @JsonKey(name: 'MediaGrabOperation', fromJson: _parseGrabOperations)
  final List<MediaGrabOperation> grabOperations;

  const MediaSubscription({
    required this.key,
    this.type,
    this.provider,
    this.targetLibrarySectionID,
    this.targetSectionLocationID,
    this.title,
    this.selected,
    this.parameters,
    this.createdAt,
    this.storageTotal,
    this.durationTotal,
    this.airingsType,
    this.librarySectionTitle,
    this.locationPath,
    this.video,
    this.directory,
    this.playlist,
    this.settings = const [],
    this.grabOperations = const [],
  });

  factory MediaSubscription.fromJson(Map<String, dynamic> json) => _$MediaSubscriptionFromJson(json);
}

@JsonSerializable(createToJson: false)
class SubscriptionSetting {
  @JsonKey(defaultValue: '')
  final String id;
  final String? label;
  final String? summary;
  final String? type;
  @JsonKey(name: 'default')
  final Object? defaultValue;
  final Object? value;
  @JsonKey(fromJson: flexibleBool)
  final bool hidden;
  @JsonKey(fromJson: flexibleBool)
  final bool advanced;
  final String? group;
  final String? enumValues;

  const SubscriptionSetting({
    required this.id,
    this.label,
    this.summary,
    this.type,
    this.defaultValue,
    this.value,
    this.hidden = false,
    this.advanced = false,
    this.group,
    this.enumValues,
  });

  factory SubscriptionSetting.fromJson(Map<String, dynamic> json) => _$SubscriptionSettingFromJson(json);

  List<SubscriptionSettingOption> get options {
    final raw = enumValues;
    if (raw == null || raw.isEmpty) return const [];
    return raw.split('|').map((entry) {
      final separator = entry.indexOf(':');
      if (separator < 0) {
        return SubscriptionSettingOption(value: Uri.decodeComponent(entry), label: Uri.decodeComponent(entry));
      }
      return SubscriptionSettingOption(
        value: Uri.decodeComponent(entry.substring(0, separator)),
        label: Uri.decodeComponent(entry.substring(separator + 1)),
      );
    }).toList();
  }
}

class SubscriptionSettingOption {
  final String value;
  final String label;

  const SubscriptionSettingOption({required this.value, required this.label});
}

/// Query parameters for `POST /media/subscriptions`.
class MediaSubscriptionCreateRequest {
  final int? targetLibrarySectionID;
  final int? targetSectionLocationID;
  final int? type;
  final String? parameters;
  final Map<String, Object?> hints;
  final Map<String, Object?> prefs;
  final Map<String, Object?> params;
  final String? providers;

  const MediaSubscriptionCreateRequest({
    this.targetLibrarySectionID,
    this.targetSectionLocationID,
    this.type,
    this.parameters,
    this.hints = const {},
    this.prefs = const {},
    this.params = const {},
    this.providers,
  });

  factory MediaSubscriptionCreateRequest.fromTemplate(
    MediaSubscription subscription, {
    int? targetLibrarySectionID,
    int? targetSectionLocationID,
    Map<String, Object?> prefs = const {},
  }) {
    final templatePrefs = <String, Object?>{
      for (final setting in subscription.settings)
        if (setting.id.isNotEmpty) setting.id: setting.value ?? setting.defaultValue,
    };
    return MediaSubscriptionCreateRequest(
      targetLibrarySectionID: targetLibrarySectionID ?? subscription.targetLibrarySectionID,
      targetSectionLocationID: targetSectionLocationID ?? subscription.targetSectionLocationID,
      type: subscription.type,
      parameters: subscription.parameters,
      prefs: {...templatePrefs, ...prefs},
    );
  }
}
