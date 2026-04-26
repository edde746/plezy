/// A cast or crew member attached to a media item.
class MediaRole {
  final String? id;
  final String tag;
  final String? role;
  final String? thumbPath;

  const MediaRole({this.id, required this.tag, this.role, this.thumbPath});
}
