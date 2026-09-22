part of '../../jellyfin_client.dart';

mixin _JellyfinMetadataEditMethods on _JellyfinClientInternals {
  Future<Map<String, dynamic>?> fetchEditableMetadataItem(String itemId) async {
    if (isOfflineMode) return null;
    final response = await _http.get('/Users/${_segment(connection.userId)}/Items/${_segment(itemId)}');
    if (response.statusCode == 404) return null;
    throwIfHttpError(response);
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  Future<bool> updateMetadataItem(String itemId, Map<String, dynamic> item) async {
    final response = await _http.post('/Items/${_segment(itemId)}', body: item);
    throwIfHttpError(response);
    await _deleteMetadataEditCache(itemId);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Server-wide values for a tag-like facet (`'Tags'`, `'Genres'`).
  ///
  /// Item DTOs carry no library id (`jellyfin_mappers` leaves
  /// `MediaItem.libraryId` null), so the facet is read without `ParentId`:
  /// Jellyfin answers the aggregate `/Items/Filters`, Emby the per-facet
  /// route (`/Tags`, `/Genres`). Best-effort — failures return empty so a
  /// suggestion list never blocks editing.
  Future<List<String>> fetchTagFacetValues(String facet) async {
    if (isOfflineMode) return const [];
    try {
      if (!dialect.supportsAggregateItemFilters) return await _fetchFilterFacet('/$facet', null);
      final response = await _http.get(
        '/Items/Filters',
        queryParameters: {'userId': connection.userId},
        timeout: _filtersTimeout,
      );
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) return const [];
      final values = data[facet];
      if (values is! List) return const [];
      return values.whereType<String>().where((v) => v.isNotEmpty).toList();
    } catch (e, st) {
      appLogger.w('JellyfinClient: tag facet $facet unavailable', error: e, stackTrace: st);
      return const [];
    }
  }

  Future<Map<String, dynamic>> getRemoteImages(
    String itemId, {
    required String imageType,
    int startIndex = 0,
    int limit = 60,
    String? providerName,
    bool includeAllLanguages = false,
  }) async {
    final response = await _http.get(
      '/Items/${_segment(itemId)}/RemoteImages',
      queryParameters: {
        'type': imageType,
        'startIndex': startIndex,
        'limit': limit,
        if (providerName != null && providerName.isNotEmpty) 'providerName': providerName,
        'includeAllLanguages': includeAllLanguages,
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
  }

  Future<bool> downloadRemoteImage(String itemId, {required String imageType, required String imageUrl}) async {
    final response = await _http.post(
      '/Items/${_segment(itemId)}/RemoteImages/Download',
      queryParameters: {'type': imageType, 'imageUrl': imageUrl},
    );
    throwIfHttpError(response);
    await _deleteMetadataEditCache(itemId);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Upload custom artwork for [itemId].
  ///
  /// The body must be base64 **text**, not the raw bytes: both dialects reject
  /// a binary body with HTTP 500 (Emby 4.9.5 says so explicitly — `The input is
  /// not a valid Base-64 string` — and Jellyfin 10.11 answers a bare
  /// `Error processing request.`), and both accept the encoded form with 204.
  /// The `Content-Type` still names the *image* type, which is how the server
  /// decides the on-disk extension.
  Future<bool> uploadItemImage(
    String itemId, {
    required String imageType,
    required List<int> bytes,
    required String contentType,
  }) async {
    final response = await _http.post(
      '/Items/${_segment(itemId)}/Images/${_segment(imageType)}',
      body: base64Encode(bytes),
      headers: {'Content-Type': contentType},
    );
    throwIfHttpError(response);
    await _deleteMetadataEditCache(itemId);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<void> _deleteMetadataEditCache(String itemId) async {
    try {
      await cache.deleteForItem(ServerId(cacheServerId), itemId);
    } catch (e, st) {
      appLogger.w('Jellyfin metadata edit cache invalidation failed', error: e, stackTrace: st);
    }
  }
}
