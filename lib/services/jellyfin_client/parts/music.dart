part of '../../jellyfin_client.dart';

/// Music browsing + playback-adjacent reads: artist discography, album track
/// listings, instant mix, and lyrics. Endpoint conventions follow the
/// Jellyfin web client's music surface (cross-checked against the Kotlin
/// SDK), mirroring the style notes at the top of `browse.dart`.
mixin _JellyfinMusicMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  FailoverHttpClient get _http;
  List<MediaItem> _mapItems(Iterable<Map<String, dynamic>> items);

  /// Albums credited to [artistId], newest first. Queries `AlbumArtistIds`
  /// rather than `ParentId` because Jellyfin links albums to artists via
  /// tags — an artist's albums are usually not its folder children.
  @override
  Future<List<MediaItem>> fetchArtistAlbums(String artistId) async {
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'AlbumArtistIds': artistId,
        'IncludeItemTypes': 'MusicAlbum',
        'Recursive': 'true',
        'SortBy': 'PremiereDate,ProductionYear,SortName',
        'SortOrder': 'Descending',
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  /// Tracks of [albumId] in disc/track order. `AlbumIds` (not `ParentId`) so
  /// tag-based albums whose files share one physical folder still resolve;
  /// `ParentIndexNumber,IndexNumber` yields correct multi-disc ordering.
  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) async {
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'AlbumIds': albumId,
        'IncludeItemTypes': 'Audio',
        'Recursive': 'true',
        'SortBy': 'ParentIndexNumber,IndexNumber,SortName',
        'SortOrder': 'Ascending',
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  /// Server-built radio seeded from a track/album/artist/playlist id.
  @override
  Future<List<MediaItem>> fetchInstantMix(String itemId, {int limit = 100}) async {
    final response = await _http.get(
      '/Items/${_segment(itemId)}/InstantMix',
      queryParameters: {
        'userId': connection.userId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  /// Lyrics for [track] from `/Audio/{id}/Lyrics`. Jellyfin's `LyricDto`
  /// carries per-line `Start` offsets in ticks when the source is an LRC /
  /// synced provider; `IsSynced` is absent on some server versions, so
  /// synced-ness is inferred from any line carrying a `Start`. 404 means
  /// the track has no lyrics → `null`.
  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async {
    try {
      final response = await _http.get('/Audio/${_segment(track.id)}/Lyrics');
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final rawLines = data['Lyrics'];
      if (rawLines is! List) return null;
      final lines = <LyricLine>[];
      var synced = false;
      for (final raw in rawLines) {
        if (raw is! Map<String, dynamic>) continue;
        final startMs = jellyfinTicksToMs(raw['Start']);
        if (startMs != null) synced = true;
        lines.add(LyricLine(text: raw['Text'] as String? ?? '', startMs: startMs));
      }
      if (lines.isEmpty) return null;
      return Lyrics(synced: synced, lines: lines);
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
