/// Plain data models for the Music Assistant WebSocket API.
///
/// Hand-written rather than code-generated: the server is loosely typed (a
/// `volume_level` observed as `null` on a registered player, `metadata.images`
/// absent on nested items) and every parser here has to tolerate that without a
/// build step. See `docs/music_assistant_protocol.md`.
library;

import '../../utils/json_utils.dart';

/// The four library collections that support `library_items` and `count`.
enum MaLibraryType {
  albums,
  artists,
  tracks,
  playlists;

  /// Path segment used by `music/<segment>/library_items`.
  String get segment => name;

  /// Singular form used by `music/search`'s `media_types` argument.
  String get mediaType => switch (this) {
    MaLibraryType.albums => 'album',
    MaLibraryType.artists => 'artist',
    MaLibraryType.tracks => 'track',
    MaLibraryType.playlists => 'playlist',
  };
}

/// `order_by` values verified against a live 2.6.3 server.
///
/// This exists as a closed set because the server handles a wrong `order_by`
/// in two different bad ways, neither of which is a clean rejection:
///
/// - A value it does not recognise at all (`bogus_field_xyz`, `track_number`,
///   `original_sort_name`) is dropped, and the query runs with **no `ORDER BY`
///   whatsoever** — insertion order, not the `sort_name` default. A typo
///   therefore produces a list that looks shuffled and reports success.
/// - A value it recognises but which is not a column on that collection
///   (`year` on tracks, `duration` on albums) reaches SQL and comes back as
///   `error_code: 999 — no such column: …`, i.e. a hard failure that shows the
///   user an empty, broken list.
///
/// Descending is a `_desc` suffix on the field name — the SQL-looking
/// `"timestamp_added DESC"` is accepted and then ordered *ascending*.
abstract final class MaOrder {
  /// The server default: collation key, A→Z. Contiguous across page
  /// boundaries, which is why paged lists must not be re-sorted client-side.
  static const String sortName = 'sort_name';
  static const String sortNameDesc = 'sort_name_desc';
  static const String name = 'name';

  static const String oldestFirst = 'timestamp_added';

  /// Newest first — the "Recently added" ordering.
  static const String newestFirst = 'timestamp_added_desc';

  /// Albums only. `artists`, `tracks` and `playlists` answer
  /// `error_code: 999 — no such column: year`, which is a failed page rather
  /// than the usual silent fallback, so this must be gated on the collection.
  static const String year = 'year';
  static const String yearDesc = 'year_desc';

  /// Tracks only, for the same reason: `albums`, `artists` and `playlists`
  /// answer `error_code: 999 — no such column: duration`.
  static const String duration = 'duration';
  static const String durationDesc = 'duration_desc';

  /// A genuine server-side shuffle: two identical requests return different
  /// items. Better for a discovery row than paging at a random offset, which
  /// only reshuffles the *window*.
  static const String random = 'random';
}

/// Greeting frame the server pushes unsolicited immediately after the socket
/// opens, before any command is sent.
/// Only the four fields anything reads. The greeting also carries
/// `min_supported_schema_version`, `homeassistant_addon` and `onboard_done`;
/// they are left unparsed rather than parsed and ignored, so a field appearing
/// here means something depends on it.
class MaServerInfo {
  final String serverId;
  final String serverVersion;
  final int schemaVersion;

  /// Server-advertised HTTP base, e.g. `http://10.0.2.107:8095`. May be empty.
  final String baseUrl;

  const MaServerInfo({
    required this.serverId,
    required this.serverVersion,
    required this.schemaVersion,
    required this.baseUrl,
  });

  factory MaServerInfo.fromJson(Map<String, dynamic> json) => MaServerInfo(
    serverId: json['server_id']?.toString() ?? '',
    serverVersion: json['server_version']?.toString() ?? '',
    schemaVersion: flexibleInt(json['schema_version']) ?? 0,
    baseUrl: json['base_url']?.toString() ?? '',
  );

  @override
  String toString() => 'MaServerInfo($serverVersion, schema $schemaVersion)';
}

/// A library media item: album, artist, track or playlist.
///
/// One class covers all four because the server returns the same envelope for
/// each and only adds type-specific keys (`year` on albums, `duration` and
/// `track_number` on tracks).
class MaItem {
  final String itemId;

  /// Provider instance or domain that owns this item — `library` for anything
  /// already indexed. Doubles as `provider_instance_id_or_domain` on the
  /// children commands.
  final String provider;
  final String name;

  /// Collation key. Disagrees with [name] for roughly one item in nine, so
  /// paged lists must be rendered in server order rather than re-sorted.
  final String sortName;

  /// `library://album/9560` — the handle every playback command takes.
  final String uri;

  /// Free-form: `album`, `artist`, `track`, `playlist`, `radio`, `podcast`, …
  /// Left as a string because the server's vocabulary is open-ended.
  final String mediaType;
  final bool favorite;
  final int? year;
  final int? durationSeconds;
  final int? trackNumber;
  final int? discNumber;
  final List<MaItem> artists;
  final MaItem? album;

  /// `metadata.images[].path`, to be fed to the server's `/imageproxy`.
  final String? imagePath;

  /// `metadata.images[].provider` for [imagePath]. `/imageproxy` returns 404
  /// without it — the path alone does not identify an image, because the same
  /// path can exist under several providers.
  final String? imageProvider;

  const MaItem({
    required this.itemId,
    required this.provider,
    required this.name,
    required this.sortName,
    required this.uri,
    required this.mediaType,
    this.favorite = false,
    this.year,
    this.durationSeconds,
    this.trackNumber,
    this.discNumber,
    this.artists = const [],
    this.album,
    this.imagePath,
    this.imageProvider,
  });

  factory MaItem.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final image = _imageFrom(json);
    return MaItem(
      itemId: json['item_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      name: name,
      // Absent on nested items; falling back to `name` keeps sorting stable
      // rather than collapsing every such row under the empty string.
      sortName: json['sort_name']?.toString() ?? name,
      uri: json['uri']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? '',
      favorite: json['favorite'] as bool? ?? false,
      year: flexibleInt(json['year']),
      durationSeconds: flexibleInt(json['duration']),
      trackNumber: flexibleInt(json['track_number']),
      discNumber: flexibleInt(json['disc_number']),
      artists: maItemsFromJson(json['artists']),
      album: json['album'] is Map<String, dynamic> ? MaItem.fromJson(json['album'] as Map<String, dynamic>) : null,
      imagePath: image?.path,
      imageProvider: image?.provider,
    );
  }

  /// Stable identity for deduplicating appended pages.
  ///
  /// `item_id` alone is not unique — it is scoped to [provider], and the same
  /// numeric id exists under `library` and under each backing provider.
  String get id => uri.isNotEmpty ? uri : '$provider:$itemId';

  /// First credited artist, or null. Convenience for list rows.
  MaItem? get primaryArtist => artists.isEmpty ? null : artists.first;

  @override
  String toString() => 'MaItem($mediaType $itemId "$name")';
}

/// Parses a `result` list (or a nested `artists` array) into items, skipping
/// anything that is not a JSON object.
List<MaItem> maItemsFromJson(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is Map<String, dynamic>) MaItem.fromJson(entry),
  ];
}

/// Grouped `music/search` result. Every bucket is always present in the
/// response, empty when there are no matches.
class MaSearchResults {
  final List<MaItem> albums;
  final List<MaItem> artists;
  final List<MaItem> tracks;
  final List<MaItem> playlists;
  final List<MaItem> radio;
  final List<MaItem> audiobooks;
  final List<MaItem> podcasts;

  const MaSearchResults({
    this.albums = const [],
    this.artists = const [],
    this.tracks = const [],
    this.playlists = const [],
    this.radio = const [],
    this.audiobooks = const [],
    this.podcasts = const [],
  });

  factory MaSearchResults.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return const MaSearchResults();
    return MaSearchResults(
      albums: maItemsFromJson(value['albums']),
      artists: maItemsFromJson(value['artists']),
      tracks: maItemsFromJson(value['tracks']),
      playlists: maItemsFromJson(value['playlists']),
      radio: maItemsFromJson(value['radio']),
      audiobooks: maItemsFromJson(value['audiobooks']),
      podcasts: maItemsFromJson(value['podcasts']),
    );
  }

  bool get isEmpty =>
      albums.isEmpty &&
      artists.isEmpty &&
      tracks.isEmpty &&
      playlists.isEmpty &&
      radio.isEmpty &&
      audiobooks.isEmpty &&
      podcasts.isEmpty;

  int get totalCount =>
      albums.length +
      artists.length +
      tracks.length +
      playlists.length +
      radio.length +
      audiobooks.length +
      podcasts.length;
}

/// Picks the artwork reference from an item's metadata.
///
/// Prefers a `thumb`; falls back to any image, then to the single `image` map
/// that nested (non-expanded) items carry instead of a `metadata` block.
///
/// Path and provider travel together because `/imageproxy` needs both.
({String path, String? provider})? _imageFrom(Map<String, dynamic> json) {
  ({String path, String? provider})? read(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final path = value['path']?.toString();
    if (path == null || path.isEmpty) return null;
    return (path: path, provider: value['provider']?.toString());
  }

  final metadata = json['metadata'];
  if (metadata is Map<String, dynamic>) {
    final images = metadata['images'];
    if (images is List) {
      ({String path, String? provider})? fallback;
      for (final image in images) {
        final parsed = read(image);
        if (parsed == null) continue;
        if (image is Map<String, dynamic> && image['type'] == 'thumb') return parsed;
        fallback ??= parsed;
      }
      if (fallback != null) return fallback;
    }
  }
  return read(json['image']);
}
