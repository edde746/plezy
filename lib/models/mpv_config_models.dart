/// Represents a saved preset of MPV configurations
class MpvPreset {
  final String name;
  final String text;
  final DateTime createdAt;

  const MpvPreset({required this.name, required this.text, required this.createdAt});

  factory MpvPreset.fromJson(Map<String, dynamic> json) {
    return MpvPreset(
      name: json['name'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}
