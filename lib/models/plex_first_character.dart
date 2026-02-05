class PlexFirstCharacter {
  final String key;
  final String title;
  final int size;

  PlexFirstCharacter({required this.key, required this.title, required this.size});

  factory PlexFirstCharacter.fromJson(Map<String, dynamic> json) {
    return PlexFirstCharacter(key: json['key'] ?? '', title: json['title'] ?? '', size: json['size'] ?? 0);
  }
}
