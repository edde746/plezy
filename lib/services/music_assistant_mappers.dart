import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_playlist.dart';
import 'music_assistant/music_assistant_models.dart';

/// Default `/imageproxy` size baked into mapped artwork URLs.
///
/// Something has to be baked in: the proxy serves the *original* file when
/// `size` is omitted — 2.4 MB versus 166 KB at 300px for one measured album
/// cover — so a size-less URL reaching an image widget would be a multi-megabyte
/// download per grid tile. [MusicAssistantImageResolver.resized] narrows it when
/// the caller knows the box it is filling.
const int musicAssistantDefaultImageSize = 512;

/// Builds `/imageproxy` URLs for Music Assistant artwork.
///
/// Mirrors `JellyfinImageAbsolutizer`: mapping produces fully-qualified URLs so
/// a [MediaItem] is renderable without holding a client, and cached rows carry
/// the same URLs as live ones. Pure string/Uri work, so it is safe off the main
/// isolate.
class MusicAssistantImageResolver {
  /// `http(s)://host:port` root the client actually connected on.
  final Uri? baseUrl;

  const MusicAssistantImageResolver(this.baseUrl);

  /// Absolute URL for an item's artwork, or `null` when the item has none.
  ///
  /// `provider` is mandatory on the wire — `/imageproxy` answers 404 for a path
  /// without it, because the same path exists under several providers.
  String? imageUrl(String? path, String? provider, {int size = musicAssistantDefaultImageSize}) {
    final base = baseUrl;
    if (base == null || path == null || path.isEmpty) return null;
    return base
        .replace(
          path: '${base.path}/imageproxy',
          queryParameters: {
            'path': path,
            if (provider != null && provider.isNotEmpty) 'provider': provider,
            'size': '$size',
          },
        )
        .toString();
  }

  String? forItem(MaItem? item, {int size = musicAssistantDefaultImageSize}) =>
      item == null ? null : imageUrl(item.imagePath, item.imageProvider, size: size);

  /// Rewrite the `size` of an already-mapped artwork URL.
  ///
  /// Returns [url] untouched when it is not one of ours, so callers can hand
  /// through absolute URLs from elsewhere (offline rows, remote art) without
  /// having to know their provenance.
  static String resized(String url, int size) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.path.endsWith('/imageproxy')) return url;
    return parsed.replace(queryParameters: {...parsed.queryParameters, 'size': '$size'}).toString();
  }
}

/// What a Music Assistant server is called when nothing better is known.
///
/// The greeting carries `server_id` and `base_url` and no name at all —
/// `config/core/get_value {key: server_name}` errors — so there is nothing on
/// the wire to fall back to. The product name is the only honest answer.
const String musicAssistantDefaultName = 'Music Assistant';

/// Anything that reads as a network address rather than a name: `10.0.2.107`,
/// `10.0.2.107:8095`, `http://nas.local:8095`, `[fe80::1]`, `localhost`.
///
/// Deliberately requires either a dot, a bracketed v6 literal or the literal
/// `localhost`, so an ordinary one-word label the user chose (`Attic`,
/// `Basement`) is left alone.
final RegExp _networkAddressLike = RegExp(
  r'^(?:[a-z][a-z0-9+.\-]*://)?'
  r'(?:\[[0-9a-f:]+\]|\d{1,3}(?:\.\d{1,3}){3}|localhost|[a-z0-9\-]+(?:\.[a-z0-9\-]+)+)'
  r'(?::\d+)?/?$',
  caseSensitive: false,
);

/// Pure mapping from the Music Assistant wire model ([MaItem]) into the
/// neutral [MediaItem] / [MediaLibrary] / [MediaPlaylist] domain types.
///
/// Kept as static functions with no client dependency so they can be exercised
/// against canned fixtures, matching `JellyfinMappers`.
class MusicAssistantMappers {
  MusicAssistantMappers._();

  /// The name to show the user for this server's music.
  ///
  /// Music Assistant offers no friendly name of its own, so the connection's
  /// display name is all there is — and until recently that defaulted to the
  /// host, which meant someone's 33,000-album collection was labelled
  /// `10.0.2.107`. This is the last line of defence for connections saved
  /// before that default changed: a display name that is really an address is
  /// not a name, and is replaced rather than shown as the title of a library.
  ///
  /// Applied at the client's [MediaServerClient.serverName] rather than at each
  /// call site, so the library title, every mapped item's `libraryTitle` and
  /// every hub's `serverName` all agree.
  static String serverDisplayName(String? displayName) {
    final name = displayName?.trim() ?? '';
    if (name.isEmpty || _networkAddressLike.hasMatch(name)) return musicAssistantDefaultName;
    return name;
  }

  /// Music Assistant's own `media_type` vocabulary, narrowed to the kinds this
  /// app renders. `radio`, `podcast` and `audiobook` exist on the server but
  /// have no neutral kind and no UI here, so they land on
  /// [MediaKind.unknown] rather than being coerced into `track`.
  static MediaKind kindFor(String mediaType) => switch (mediaType) {
    'album' => MediaKind.album,
    'artist' => MediaKind.artist,
    'track' => MediaKind.track,
    'playlist' => MediaKind.playlist,
    _ => MediaKind.unknown,
  };

  /// Map one library item.
  ///
  /// Returns `null` for an item with no usable identity — [MaItem.id] falls
  /// back to `provider:item_id`, so this only fires on a genuinely empty
  /// payload, where the mapped row would poison cache keys and image URLs.
  ///
  /// Music field conventions follow Plex and Jellyfin exactly: track number in
  /// [MediaItem.index], disc in [MediaItem.parentIndex], the album in
  /// `parent*`, and the album artist in `grandparent*`. An *album's* parent is
  /// its artist, which is what the album detail screen reads to render the
  /// artist line.
  static MediaItem? mediaItem(
    MaItem item, {
    required ServerId serverId,
    String? serverName,
    required MusicAssistantImageResolver images,
    String? libraryId,
    String? libraryTitle,
  }) {
    final id = item.id;
    if (id.isEmpty || id == ':') return null;

    final kind = kindFor(item.mediaType);
    final artist = item.primaryArtist;
    final album = item.album;
    final ownImage = images.forItem(item);

    return MusicAssistantMediaItem(
      id: id,
      kind: kind,
      // The uri is the handle every playback and favourite command takes, so it
      // is worth keeping even though it is usually identical to the id.
      guid: item.uri.isEmpty ? null : item.uri,
      title: item.name,
      titleSort: item.sortName,
      year: item.year,
      parentId: kind == MediaKind.album ? artist?.id : album?.id,
      parentTitle: kind == MediaKind.album ? artist?.name : album?.name,
      parentThumbPath: kind == MediaKind.album ? images.forItem(artist) : images.forItem(album),
      parentIndex: item.discNumber,
      index: item.trackNumber,
      grandparentId: kind == MediaKind.track ? artist?.id : null,
      grandparentTitle: kind == MediaKind.track ? artist?.name : null,
      grandparentThumbPath: kind == MediaKind.track ? images.forItem(artist) : null,
      // Tracks routinely carry no artwork of their own; the server puts the
      // album cover in the track's own images array, but nested-album payloads
      // arrive without one, so fall back explicitly.
      thumbPath: ownImage ?? images.forItem(album),
      durationMs: item.durationSeconds == null ? null : item.durationSeconds! * 1000,
      isFavorite: item.favorite,
      libraryId: libraryId,
      libraryTitle: libraryTitle,
      serverId: serverId,
      serverName: serverName,
      // No `raw`: [MaItem] is already the parsed wire shape and does not retain
      // the source map, and nothing on this backend re-reads backend-native
      // JSON off a MediaItem the way the Plex/Jellyfin video paths do.
    );
  }

  static List<MediaItem> mediaItems(
    Iterable<MaItem> items, {
    required ServerId serverId,
    String? serverName,
    required MusicAssistantImageResolver images,
    String? libraryId,
    String? libraryTitle,
  }) {
    return [
      for (final item in items)
        ?mediaItem(
          item,
          serverId: serverId,
          serverName: serverName,
          images: images,
          libraryId: libraryId,
          libraryTitle: libraryTitle,
        ),
    ];
  }

  /// Map a `music/playlists/library_items` row.
  ///
  /// `playlistType` is always `audio` — Music Assistant has no video or photo
  /// playlists. Item counts are absent from the wire shape, so [leafCount]
  /// stays null rather than being guessed.
  static MediaPlaylist? playlist(
    MaItem item, {
    required ServerId serverId,
    String? serverName,
    required MusicAssistantImageResolver images,
  }) {
    final id = item.id;
    if (id.isEmpty || id == ':') return null;
    return MediaPlaylist(
      id: id,
      backend: MediaBackend.musicAssistant,
      title: item.name,
      playlistType: 'audio',
      guid: item.uri.isEmpty ? null : item.uri,
      thumbPath: images.forItem(item),
      serverId: serverId,
      serverName: serverName,
    );
  }

  /// The single synthetic library every Music Assistant server exposes.
  ///
  /// The server has no library concept at all — it holds one flat music
  /// collection — so the app is given one [MediaKind.artist] library named
  /// after the server. That kind is what makes the browse screen offer the
  /// Artists / Albums / Tracks grouping, which is the whole point: a flat wall
  /// of 370,000 tracks is not browseable.
  static MediaLibrary library({required ServerId serverId, required String serverName, required String libraryId}) {
    return MediaLibrary(
      id: libraryId,
      backend: MediaBackend.musicAssistant,
      title: serverName,
      kind: MediaKind.artist,
      serverId: serverId,
      serverName: serverName,
    );
  }
}
