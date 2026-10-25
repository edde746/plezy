import '../utils/global_key_utils.dart';
import 'ids.dart';
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

  /// Explicit item kinds for this library's flat root browse. Mixed libraries
  /// use this when no single [kind] can describe the server's root view.
  final List<MediaKind> defaultBrowseKinds;

  /// Optional ISO language code of the library's metadata locale.
  final String? language;

  /// Server-side last-update timestamp in seconds.
  final int? updatedAt;
  final int? createdAt;

  /// Server-reported root item count when available. `null` means the backend
  /// did not include a count; it must not be treated as empty.
  final int? itemCount;

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
    this.defaultBrowseKinds = const [],
    this.language,
    this.updatedAt,
    this.createdAt,
    this.itemCount,
    this.hidden = false,
    this.isShared = false,
    this.serverId,
    this.serverName,
  });

  String get globalKey => serverId != null ? buildGlobalKey(ServerId(serverId!), id) : id;
}

/// Shared library visibility rule used by the sidebar, picker, and library
/// browser. Unknown counts remain visible because they are not proof of an
/// empty library.
List<MediaLibrary> visibleMediaLibraries(
  Iterable<MediaLibrary> libraries, {
  required Set<String> hiddenKeys,
  required bool hideEmpty,
}) => [
  for (final library in libraries)
    if (!hiddenKeys.contains(library.globalKey) && !(hideEmpty && library.itemCount == 0)) library,
];
