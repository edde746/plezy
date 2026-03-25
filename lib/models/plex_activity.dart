/// Represents a running background task on a Plex Media Server (from /activities endpoint).
class PlexActivity {
  final String uuid;
  final String type;
  final String title;
  final String? subtitle;
  final int progress; // 0–100
  final bool cancellable;

  const PlexActivity({
    required this.uuid,
    required this.type,
    required this.title,
    this.subtitle,
    required this.progress,
    required this.cancellable,
  });

  factory PlexActivity.fromJson(Map<String, dynamic> json) {
    return PlexActivity(
      uuid: json['uuid'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      cancellable: json['cancellable'] as bool? ?? false,
    );
  }
}
