part of '../../jellyfin_client.dart';

mixin _JellyfinCollectionMethods on _JellyfinClientInternals {
  static const int _collectionsPageSize = 36;

  String? _boxSetsViewId;

  @override
  Future<List<MediaItem>> fetchCollections(String libraryId) => drainPages<MediaItem>(
    (start, size) => fetchCollectionsPage(libraryId, start: start, size: size),
    pageSize: _collectionsPageSize,
  );

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionsPage(
    String libraryId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final s = start ?? 0;
    final pageSize = size ?? _collectionsPageSize;
    final boxSetsViewId = await _fetchBoxSetsViewId(abort: abort);
    if (boxSetsViewId == null) {
      return LibraryPage<MediaItem>(items: const [], totalCount: 0, offset: s);
    }

    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'ParentId': boxSetsViewId,
        'IncludeItemTypes': 'BoxSet',
        'Recursive': 'true',
        'StartIndex': s.toString(),
        'Limit': pageSize.toString(),
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedItems(response.data, offset: s, requestedSize: pageSize, map: _mapItems);
  }

  Future<String?> _fetchBoxSetsViewId({AbortController? abort}) async {
    if (_boxSetsViewId != null) return _boxSetsViewId;

    final response = await _http.get('/Users/${_segment(connection.userId)}/Views', abort: abort);
    throwIfHttpError(response);
    for (final view in _itemsArray(response.data)) {
      final collectionType = (view['CollectionType'] as String?)?.toLowerCase();
      final id = view['Id'] as String?;
      if (collectionType == 'boxsets' && id != null && id.isNotEmpty) {
        _boxSetsViewId = id;
        return id;
      }
    }
    return null;
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
    final s = start ?? 0;
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'ParentId': collectionId,
        'StartIndex': s.toString(),
        if (size != null) 'Limit': size.toString(),
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedItems(response.data, offset: s, requestedSize: size, map: _mapItems);
  }

  @override
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  }) async {
    // ParentId is optional on Jellyfin's `/Collections` endpoint — when
    // omitted the server picks a default BoxSet root. We pass libraryId so
    // the new collection lives in the same library as the seeded items.
    final response = await _http.post(
      '/Collections',
      queryParameters: {
        'Name': title,
        if (items.isNotEmpty) 'Ids': items.map((i) => i.id).join(','),
        if (libraryId.isNotEmpty) 'ParentId': libraryId,
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    return data is Map<String, dynamic> ? data['Id'] as String? : null;
  }

  @override
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final response = await _http.post(
      '/Collections/${_segment(collectionId)}/Items',
      queryParameters: {'Ids': items.map((i) => i.id).join(',')},
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item}) async {
    final response = await _http.delete(
      '/Collections/${_segment(collectionId)}/Items',
      queryParameters: {'Ids': item.id},
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> deleteCollection(MediaItem collection) async {
    final response = await _http.delete('/Items/${_segment(collection.id)}');
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> deleteMediaItem(MediaItem item) async {
    final response = await _http.delete('/Items/${_segment(item.id)}');
    throwIfHttpError(response);
    return true;
  }
}
