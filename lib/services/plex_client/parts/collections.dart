part of '../../plex_client.dart';

mixin _PlexCollectionMethods on MediaServerCacheMixin {
  FailoverHttpClient get _http;

  Future<MediaServerResponse> _getWithFailover(
    String path, {
    Map<String, dynamic>? queryParameters,
    // ignore: unused_element_parameter
    Map<String, String>? headers,
    // ignore: unused_element_parameter
    Duration? timeout,
    AbortController? abort,
    // ignore: unused_element_parameter
    bool allowEndpointFailover = true,
  });

  Map<String, dynamic>? _getMediaContainer(MediaServerResponse response);
  Map<String, dynamic> _buildPaginationParams(int? start, int? size);

  _LibraryContentResult _extractLibraryContentResult(
    MediaServerResponse response, {
    int? librarySectionID,
    // ignore: unused_element_parameter
    String? librarySectionTitle,
    int? start,
    int? requestedSize,
  });

  Future<_LibraryContentResult> _fetchPaginatedList(
    String path, {
    int? start,
    int? size,
    AbortController? abort,
    int? librarySectionID,
    String? librarySectionTitle,
  });

  Future<List<PlexMetadataDto>> _fetchAllPages(
    Future<_LibraryContentResult> Function(int start, int size, AbortController? abort) fetchPage, {
    // ignore: unused_element_parameter
    AbortController? abort,
  });

  Future<bool> _wrapBoolApiCall(Future<MediaServerResponse> Function() apiCall, String errorMessage);

  Future<String> buildMetadataUri(String ratingKey);

  Future<_LibraryContentResult> _getLibraryCollectionsPage(
    String sectionId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final queryParameters = _buildPaginationParams(start, size)..['includeGuids'] = 1;
    final response = await _getWithFailover(
      '/library/sections/$sectionId/collections',
      queryParameters: queryParameters,
      abort: abort,
    );
    return _extractLibraryContentResult(
      response,
      librarySectionID: _librarySectionIdFromString(sectionId),
      start: start,
      requestedSize: size,
    );
  }

  Future<List<PlexMetadataDto>> _getLibraryCollections(String sectionId) async {
    try {
      return _fetchAllPages(
        (start, size, abort) => _getLibraryCollectionsPage(sectionId, start: start, size: size, abort: abort),
      );
    } catch (e, st) {
      appLogger.e('Failed to get library collections', error: e, stackTrace: st);
      return [];
    }
  }

  Future<_LibraryContentResult> _getCollectionItems(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? librarySectionID,
    String? librarySectionTitle,
  }) => _fetchPaginatedList(
    '/library/collections/$collectionId/children',
    start: start,
    size: size,
    abort: abort,
    librarySectionID: _librarySectionIdFromString(librarySectionID),
    librarySectionTitle: librarySectionTitle,
  );

  Future<_LibraryContentResult> _getPersonMedia(String personId, {int? start, int? size, AbortController? abort}) =>
      _fetchPaginatedList('/library/people/$personId/media', start: start, size: size, abort: abort);

  Future<List<PlexMetadataDto>> _fetchAllPersonMediaDto(String personId) {
    return _fetchAllPages((start, size, abort) => _getPersonMedia(personId, start: start, size: size, abort: abort));
  }

  @override
  Future<List<MediaItem>> fetchCollections(String libraryId) async {
    final raw = await _getLibraryCollections(libraryId);
    return raw.map(PlexMappers.mediaItem).toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionsPage(
    String libraryId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getLibraryCollectionsPage(libraryId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map(PlexMappers.mediaItem).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) async {
    final result = await _getCollectionItems(
      collectionId,
      start: start,
      size: size,
      abort: abort,
      librarySectionID: libraryId,
      librarySectionTitle: libraryTitle,
    );
    return LibraryPage<MediaItem>(
      items: result.items.map(PlexMappers.mediaItem).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPersonMediaPage(
    String personId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getPersonMedia(personId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map(PlexMappers.mediaItem).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  @override
  Future<List<MediaItem>> fetchPersonMedia(String personId) {
    return fetchAllPersonMediaAsMediaItems(personId);
  }

  Future<List<MediaItem>> fetchAllPersonMediaAsMediaItems(String personId) async {
    final raw = await _fetchAllPersonMediaDto(personId);
    return raw.map(PlexMappers.mediaItem).toList();
  }

  @override
  Future<bool> deleteCollection(MediaItem collection) {
    return deleteCollectionById(collection.libraryId ?? '', collection.id);
  }

  Future<bool> deleteCollectionById(String sectionId, String collectionId) async {
    appLogger.d(
      'Deleting collection: sectionId=$sectionId, '
      'collectionId=$collectionId',
    );
    final result = await _wrapBoolApiCall(
      () => _http.delete('/library/collections/$collectionId'),
      'Failed to delete collection',
    );
    if (result) appLogger.d('Delete collection response: 200');
    return result;
  }

  @override
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  }) async {
    final uri = items.isEmpty ? '' : await buildMetadataUri(items.map((item) => item.id).join(','));
    final type = switch (itemKind) {
      MediaKind.movie => 1,
      MediaKind.show => 2,
      MediaKind.season => 3,
      MediaKind.episode => 4,
      _ => null,
    };
    return createCollectionFromUri(sectionId: libraryId, title: title, uri: uri, type: type);
  }

  Future<String?> createCollectionFromUri({
    required String sectionId,
    required String title,
    required String uri,
    int? type,
  }) async {
    try {
      appLogger.d('Creating collection: sectionId=$sectionId, title=$title, type=$type');
      final response = await _http.post(
        '/library/collections',
        queryParameters: {'type': ?type, 'title': title, 'smart': 0, 'sectionId': sectionId, 'uri': uri},
      );
      throwIfHttpError(response);
      appLogger.d('Create collection response: ${response.statusCode}');

      final metadata = _getMediaContainer(response)?['Metadata'];
      if (metadata is List && metadata.isNotEmpty) {
        final collectionId = metadata.first['ratingKey']?.toString();
        appLogger.d('Created collection with ID: $collectionId');
        return collectionId;
      }
      return null;
    } catch (e) {
      appLogger.e('Failed to create collection', error: e);
      return null;
    }
  }

  @override
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final uri = await buildMetadataUri(items.map((item) => item.id).join(','));
    return addItemsToCollectionByUri(collectionId: collectionId, uri: uri);
  }

  Future<bool> addItemsToCollectionByUri({required String collectionId, required String uri}) async {
    appLogger.d('Adding items to collection: collectionId=$collectionId');
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/collections/$collectionId/items', queryParameters: {'uri': uri}),
      'Failed to add items to collection',
    );
    if (result) appLogger.d('Add to collection response: 200');
    return result;
  }

  @override
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item}) async {
    appLogger.d(
      'Removing item from collection: collectionId=$collectionId, '
      'itemId=${item.id}',
    );
    final result = await _wrapBoolApiCall(
      () => _http.delete('/library/collections/$collectionId/items/${item.id}'),
      'Failed to remove item from collection',
    );
    if (result) appLogger.d('Remove from collection response: 200');
    return result;
  }
}
