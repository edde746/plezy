import '../utils/global_key_utils.dart';
import 'media_backend.dart';

/// Backend-neutral playlist record. Holds metadata only — items are fetched
/// separately via the client.
class MediaPlaylist {
  /// Backend-opaque identifier (Plex `ratingKey`, Jellyfin playlist `Id`).
  final String id;
  final MediaBackend backend;
  final String title;
  final String? summary;
  final String? guid;

  /// Plex smart-playlist marker; always false for Jellyfin (no equivalent).
  final bool smart;

  /// `video`, `audio`, or `photo`. Drives default sort and rendering.
  final String playlistType;

  final int? durationMs;

  /// Number of items in the playlist.
  final int? leafCount;
  final int? viewCount;

  final int? addedAt;
  final int? updatedAt;
  final int? lastViewedAt;

  /// Plex composite (auto-generated grid). Null on Jellyfin.
  final String? compositeImagePath;
  final String? thumbPath;

  final String? serverId;
  final String? serverName;

  const MediaPlaylist({
    required this.id,
    required this.backend,
    required this.title,
    required this.playlistType,
    this.summary,
    this.guid,
    this.smart = false,
    this.durationMs,
    this.leafCount,
    this.viewCount,
    this.addedAt,
    this.updatedAt,
    this.lastViewedAt,
    this.compositeImagePath,
    this.thumbPath,
    this.serverId,
    this.serverName,
  });

  /// Image used to represent the playlist in browse views.
  String? get displayImagePath => compositeImagePath ?? thumbPath;

  /// Display-friendly title (alias of [title] for parity with [MediaItem]).
  String get displayTitle => title;

  /// Whether this playlist's contents can be reordered/edited by the client.
  /// Plex smart playlists are read-only; manual playlists and Jellyfin
  /// playlists are editable.
  bool get isEditable => !smart;

  String get globalKey => serverId != null ? buildGlobalKey(serverId!, id) : id;

  MediaPlaylist copyWith({
    String? id,
    MediaBackend? backend,
    String? title,
    String? summary,
    String? guid,
    bool? smart,
    String? playlistType,
    int? durationMs,
    int? leafCount,
    int? viewCount,
    int? addedAt,
    int? updatedAt,
    int? lastViewedAt,
    String? compositeImagePath,
    String? thumbPath,
    String? serverId,
    String? serverName,
  }) {
    return MediaPlaylist(
      id: id ?? this.id,
      backend: backend ?? this.backend,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      guid: guid ?? this.guid,
      smart: smart ?? this.smart,
      playlistType: playlistType ?? this.playlistType,
      durationMs: durationMs ?? this.durationMs,
      leafCount: leafCount ?? this.leafCount,
      viewCount: viewCount ?? this.viewCount,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      compositeImagePath: compositeImagePath ?? this.compositeImagePath,
      thumbPath: thumbPath ?? this.thumbPath,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}
