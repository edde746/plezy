import '../utils/global_key_utils.dart';
import 'media_backend.dart';
import 'media_kind.dart';

/// A top-level browseable section on a server (Plex library section, Jellyfin
/// view).
class MediaLibrary {
  /// Backend-opaque identifier (Plex section id like `"5"`, Jellyfin view UUID).
  final String id;
  final MediaBackend backend;
  final String title;

  /// Primary media kind held by this library — drives default UI affordances
  /// (poster shape, sort options). For mixed libraries this is [MediaKind.unknown].
  final MediaKind kind;

  /// Optional ISO language code of the library's metadata locale.
  final String? language;

  /// Server-side last-update timestamp in seconds.
  final int? updatedAt;
  final int? createdAt;

  /// Whether the user has hidden this library from the home browser.
  final bool hidden;

  /// True for individually-shared items presented as a virtual library
  /// (Plex's "shared with me" surface). Jellyfin returns no such marker.
  final bool isShared;

  final String? serverId;
  final String? serverName;

  const MediaLibrary({
    required this.id,
    required this.backend,
    required this.title,
    this.kind = MediaKind.unknown,
    this.language,
    this.updatedAt,
    this.createdAt,
    this.hidden = false,
    this.isShared = false,
    this.serverId,
    this.serverName,
  });

  String get globalKey => serverId != null ? buildGlobalKey(serverId!, id) : id;

  MediaLibrary copyWith({
    String? id,
    MediaBackend? backend,
    String? title,
    MediaKind? kind,
    String? language,
    int? updatedAt,
    int? createdAt,
    bool? hidden,
    bool? isShared,
    String? serverId,
    String? serverName,
  }) {
    return MediaLibrary(
      id: id ?? this.id,
      backend: backend ?? this.backend,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      language: language ?? this.language,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      hidden: hidden ?? this.hidden,
      isShared: isShared ?? this.isShared,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}
