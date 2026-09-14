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

  /// `/Items?ids=` rather than `/Users/{id}/Items/{id}`: the single-item route
  /// ignores `Fields` and returns the whole dto (measured 33 KB / ~150 ms on a
  /// remote server), while the list route honours it and answers with a ~0.5 KB
  /// body in ~40 ms. Images and user data are switched off for the same reason.
  ///
  /// An id the user cannot see comes back as an empty `Items` array, which is
  /// the same answer as "not allowed" for gating purposes.
  ///
  /// A context menu waits on this, so the probe carries a real wall-clock
  /// ceiling: [MediaServerHttpClient] applies its `timeout` to the connect and
  /// receive phases separately (so it alone would allow roughly double), and
  /// `allowEndpointFailover: false` keeps a dead endpoint from walking the
  /// candidate list while the user holds a long-press. On expiry the request is
  /// aborted rather than left running, and the timeout propagates so the caller
  /// fails closed.
  // No `@override`: like [fetchSeasonEpisodesPage], this satisfies an optional
  // capability interface that the concrete client implements, not a member of
  // the mixin's superclass constraint.
  Future<bool?> fetchDeletePermission(MediaItem item) async {
    final abort = AbortController();
    try {
      final response = await _http
          .get(
            '/Items',
            queryParameters: {
              'ids': item.id,
              'userId': connection.userId,
              'Fields': 'CanDelete',
              'EnableImages': 'false',
              'EnableUserData': 'false',
              'EnableTotalRecordCount': 'false',
            },
            timeout: MediaServerTimeouts.jellyfinDeletePermission,
            abort: abort,
            allowEndpointFailover: false,
          )
          .namedTimeout(MediaServerTimeouts.jellyfinDeletePermission, operation: 'jellyfin delete permission');
      throwIfHttpError(response);
      final items = _itemsArray(response.data);
      if (items.isEmpty) return false;
      return items.first['CanDelete'] as bool?;
    } on TimeoutException catch (e) {
      // Stop the request rather than leave it running, and hand the caller the
      // same exception shape `MediaServerHttpClient` raises for its own
      // per-phase expiries.
      abort.abort();
      throw MediaServerHttpException.from(e);
    }
  }
}
