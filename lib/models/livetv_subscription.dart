/// Represents a DVR recording subscription (recording rule)
class LiveTvSubscription {
  final String key;
  final String? ratingKey;
  final String? guid;
  final String title;
  final String? summary;
  final String? type;
  final String? thumb;
  final String? art;
  final int? targetLibrarySectionID;
  final int? targetSectionID;
  final int? createdAt;
  final List<SubscriptionSetting> settings;

  // Multi-server support
  final String? serverId;

  LiveTvSubscription({
    required this.key,
    this.ratingKey,
    this.guid,
    required this.title,
    this.summary,
    this.type,
    this.thumb,
    this.art,
    this.targetLibrarySectionID,
    this.targetSectionID,
    this.createdAt,
    this.settings = const [],
    this.serverId,
  });

  factory LiveTvSubscription.fromJson(Map<String, dynamic> json) {
    final settingsList = <SubscriptionSetting>[];
    if (json['Setting'] != null) {
      for (final item in json['Setting'] as List) {
        try {
          settingsList.add(SubscriptionSetting.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    return LiveTvSubscription(
      key: json['key'] as String? ?? '',
      ratingKey: json['ratingKey'] as String?,
      guid: json['guid'] as String?,
      title: json['title'] as String? ?? 'Unknown',
      summary: json['summary'] as String?,
      type: json['type'] as String?,
      thumb: json['thumb'] as String?,
      art: json['art'] as String?,
      targetLibrarySectionID: (json['targetLibrarySectionID'] as num?)?.toInt(),
      targetSectionID: (json['targetSectionID'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num?)?.toInt(),
      settings: settingsList,
    );
  }

  /// Creation time as DateTime
  DateTime? get createdAtTime => createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;
}

/// Represents a setting within a DVR subscription
class SubscriptionSetting {
  final String id;
  final String? label;
  final String? summary;
  final String type; // e.g., "bool", "enum", "int"
  final String? value;
  final String? defaultValue;
  final bool? hidden;
  final bool? advanced;
  final List<SubscriptionSettingOption>? enumValues;

  SubscriptionSetting({
    required this.id,
    this.label,
    this.summary,
    required this.type,
    this.value,
    this.defaultValue,
    this.hidden,
    this.advanced,
    this.enumValues,
  });

  factory SubscriptionSetting.fromJson(Map<String, dynamic> json) {
    List<SubscriptionSettingOption>? options;
    if (json['enumValues'] != null) {
      final parts = (json['enumValues'] as String).split('|');
      options = parts.map((part) {
        final kv = part.split(':');
        return SubscriptionSettingOption(value: kv.first, label: kv.length > 1 ? kv[1] : kv.first);
      }).toList();
    }

    return SubscriptionSetting(
      id: json['id'] as String? ?? '',
      label: json['label'] as String?,
      summary: json['summary'] as String?,
      type: json['type'] as String? ?? 'text',
      value: json['value']?.toString(),
      defaultValue: json['default']?.toString(),
      hidden: json['hidden'] == true || json['hidden'] == 1,
      advanced: json['advanced'] == true || json['advanced'] == 1,
      enumValues: options,
    );
  }
}

/// Represents an option in an enum-type subscription setting
class SubscriptionSettingOption {
  final String value;
  final String label;

  SubscriptionSettingOption({required this.value, required this.label});
}
