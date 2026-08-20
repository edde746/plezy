/// One entry from `GET /anime/{id}/characters`: the character node plus its
/// entry-level `role` (`Main` / `Supporting`). MAL's API exposes characters
/// only — no voice actors. Hand-parsed because the interesting fields span
/// the entry and its node.
class MalCharacter {
  final String name;
  final String? role;
  final String? imageUrl;

  const MalCharacter({required this.name, this.role, this.imageUrl});

  factory MalCharacter.fromEntry(Map<String, dynamic> entry) {
    final node = entry['node'];
    final map = node is Map ? node.cast<String, dynamic>() : const <String, dynamic>{};
    final first = map['first_name'];
    final last = map['last_name'];
    final name = [
      if (first is String && first.isNotEmpty) first,
      if (last is String && last.isNotEmpty) last,
    ].join(' ');
    final picture = map['main_picture'];
    final medium = picture is Map ? picture['medium'] : null;
    final role = entry['role'];
    return MalCharacter(
      name: name,
      role: role is String && role.isNotEmpty ? role : null,
      imageUrl: medium is String && medium.isNotEmpty ? medium : null,
    );
  }
}
