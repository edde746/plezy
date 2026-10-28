/// A device-local point in a media item's timeline, saved for quick return.
class VideoBookmark {
  const VideoBookmark({required this.id, required this.label, required this.positionMs, required this.createdAtMs});

  final String id;
  final String label;
  final int positionMs;
  final int createdAtMs;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'positionMs': positionMs, 'createdAtMs': createdAtMs};

  static VideoBookmark? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final label = value['label'];
    final positionMs = value['positionMs'];
    final createdAtMs = value['createdAtMs'];
    if (id is! String || id.isEmpty || label is! String || label.trim().isEmpty) return null;
    if (positionMs is! int || positionMs < 0 || createdAtMs is! int || createdAtMs < 0) return null;
    final normalizedLabel = label.trim();
    if (normalizedLabel.length > 80) return null;
    return VideoBookmark(id: id, label: normalizedLabel, positionMs: positionMs, createdAtMs: createdAtMs);
  }
}
