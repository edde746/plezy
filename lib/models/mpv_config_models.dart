/// Represents a single MPV configuration entry
class MpvConfigEntry {
  final String key;
  final String value;
  final bool isEnabled;

  const MpvConfigEntry({required this.key, required this.value, this.isEnabled = true});

  factory MpvConfigEntry.fromJson(Map<String, dynamic> json) {
    return MpvConfigEntry(
      key: json['key'] as String,
      value: json['value'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value, 'isEnabled': isEnabled};

  MpvConfigEntry copyWith({String? key, String? value, bool? isEnabled}) {
    return MpvConfigEntry(key: key ?? this.key, value: value ?? this.value, isEnabled: isEnabled ?? this.isEnabled);
  }
}

/// Represents a saved preset of MPV configurations
class MpvPreset {
  final String name;
  final List<MpvConfigEntry> entries;
  final DateTime createdAt;

  const MpvPreset({required this.name, required this.entries, required this.createdAt});

  factory MpvPreset.fromJson(Map<String, dynamic> json) {
    return MpvPreset(
      name: json['name'] as String,
      entries: (json['entries'] as List).map((e) => MpvConfigEntry.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'entries': entries.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
