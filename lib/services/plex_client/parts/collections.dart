part of '../../plex_client.dart';

mixin _PlexCollectionMethods on _PlexClientInternals {
  _LibraryContentResult _extractLibraryContentResult(
    MediaServerResponse response, {
    int? librarySectionID,
    // ignore: unused_element_parameter
    String? librarySectionTitle,
    int? start,
    int? requestedSize,
  });

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

  /// PMS caps `X-Plex-Container-Size` at 120 on
  /// `/library/collections/{id}/children`. Some servers answer a larger page
  /// with HTTP 400; the rest log that they eventually will (#2468).
  static const int _collectionChildrenMaxPageSize = 120;

  /// Serves [size] items from [start], split into requests the server
  /// accepts. A null [size] reads to the end of the collection.
  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) async {
    final offset = start ?? 0;
    final items = <PlexMetadataDto>[];
    int totalSize;
    while (true) {
      final remaining = size == null ? _collectionChildrenMaxPageSize : size - items.length;
      final result = await _getCollectionItems(
        collectionId,
        start: offset + items.length,
        size: remaining.clamp(0, _collectionChildrenMaxPageSize),
        abort: abort,
        librarySectionID: libraryId,
        librarySectionTitle: libraryTitle,
      );
      items.addAll(result.items);
      totalSize = result.totalSize;
      if (result.items.isEmpty || offset + items.length >= totalSize) break;
      if (size != null && items.length >= size) break;
    }
    return LibraryPage<MediaItem>(
      items: items.map(PlexMappers.mediaItem).toList(),
      totalCount: totalSize,
      offset: offset,
    );
  }

  /// Ids per batched `/library/metadata/{ids}` request. Plex ids are short,
  /// so 100 keeps the URL well under proxy limits.
  static const int _membershipLookupChunkSize = 100;

  /// Page size for listing a library's collections during a membership lookup.
  static const int _membershipCollectionsPageSize = 200;

  /// `collectionMode` of a collection set to "Hide collection": it never
  /// shows in the library, so it never groups downloads either.
  static const String _collectionModeHidden = '0';

  /// `collectionSort` values. Release date (`0`) is the default when absent.
  static const String _collectionSortAlphabetical = '1';
  static const String _collectionSortCustom = '2';

  /// Membership comes from the items' `Collection` tags, whose `id` is the
  /// collection's `index`. Batched detail rows carry those ids where list
  /// rows carry only the tag text, which can differ from the collection's
  /// title in case. Only a custom-ordered collection needs its children read;
  /// release and alphabetical order follow from the members' own fields.
  @override
  Future<List<CollectionMembership>> fetchCollectionMemberships(Set<String> itemIds, {AbortController? abort}) async {
    final ids = itemIds.toList()..sort();
    final membersByTag = <int, List<Map<String, dynamic>>>{};
    final tagsByLibrary = <String, Set<int>>{};
    for (var start = 0; start < ids.length; start += _membershipLookupChunkSize) {
      final end = start + _membershipLookupChunkSize < ids.length ? start + _membershipLookupChunkSize : ids.length;
      final chunk = ids.sublist(start, end);
      final response = await _getWithFailover(
        '/library/metadata/${chunk.join(',')}',
        queryParameters: _buildPaginationParams(0, chunk.length),
        abort: abort,
      );
      final rows = _getMediaContainer(response)?['Metadata'];
      if (rows is! List) continue;
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final itemId = row['ratingKey']?.toString();
        final libraryId = row['librarySectionID']?.toString();
        final tags = row['Collection'];
        if (itemId == null || !itemIds.contains(itemId) || libraryId == null || tags is! List) continue;
        for (final tag in tags.whereType<Map<String, dynamic>>()) {
          final tagId = flexibleInt(tag['id']);
          if (tagId == null) continue;
          membersByTag.putIfAbsent(tagId, () => []).add(row);
          tagsByLibrary.putIfAbsent(libraryId, () => {}).add(tagId);
        }
      }
    }

    final memberships = <CollectionMembership>[];
    for (final MapEntry(key: libraryId, value: tagIds) in tagsByLibrary.entries) {
      for (final json in await _libraryCollectionsJson(libraryId, abort: abort)) {
        final tagId = flexibleInt(json['index']);
        if (tagId == null || !tagIds.contains(tagId)) continue;
        if (flexibleBool(json['smart']) || json['collectionMode']?.toString() == _collectionModeHidden) continue;
        final collection = PlexMappers.mediaItem(
          _createTaggedMetadataWithLibrary(json, librarySectionID: int.tryParse(libraryId)),
        );
        final memberIds = await _collectionOrderedMemberIds(
          collection.id,
          json['collectionSort']?.toString(),
          membersByTag[tagId]!,
          abort: abort,
        );
        memberships.add((collection: collection, memberIds: memberIds));
      }
    }
    return memberships;
  }

  /// Every raw collection row of [libraryId], smart and hidden ones included.
  Future<List<Map<String, dynamic>>> _libraryCollectionsJson(String libraryId, {AbortController? abort}) async {
    final collections = <Map<String, dynamic>>[];
    while (true) {
      final response = await _getWithFailover(
        '/library/sections/$libraryId/collections',
        queryParameters: _buildPaginationParams(collections.length, _membershipCollectionsPageSize),
        abort: abort,
      );
      final container = _getMediaContainer(response);
      final rows = container?['Metadata'];
      final page = rows is List ? rows.whereType<Map<String, dynamic>>().toList() : const <Map<String, dynamic>>[];
      collections.addAll(page);
      final total = flexibleInt(container?['totalSize']) ?? collections.length;
      if (page.isEmpty || collections.length >= total) return collections;
    }
  }

  /// The ids of [members] in the collection's [sort] order.
  Future<List<String>> _collectionOrderedMemberIds(
    String collectionId,
    String? sort,
    List<Map<String, dynamic>> members, {
    AbortController? abort,
  }) async {
    if (sort == _collectionSortCustom) {
      final memberIds = {for (final member in members) member['ratingKey'].toString()};
      final children = await drainPages(
        (start, size) => fetchCollectionPage(collectionId, start: start, size: size, abort: abort),
        pageSize: _collectionChildrenMaxPageSize,
        abort: abort,
      );
      return [
        for (final child in children)
          if (memberIds.remove(child.id)) child.id,
      ];
    }

    String titleKey(Map<String, dynamic> row) => (row['titleSort'] ?? row['title'] ?? '').toString().toLowerCase();
    final sorted = List.of(members)
      ..sort((a, b) {
        if (sort != _collectionSortAlphabetical) {
          // Release order; undated members after dated ones.
          final aDate = a['originallyAvailableAt']?.toString() ?? '${a['year'] ?? ''}';
          final bDate = b['originallyAvailableAt']?.toString() ?? '${b['year'] ?? ''}';
          if (aDate.isEmpty != bDate.isEmpty) return aDate.isEmpty ? 1 : -1;
          final byDate = aDate.compareTo(bDate);
          if (byDate != 0) return byDate;
        }
        return titleKey(a).compareTo(titleKey(b));
      });
    return [for (final member in sorted) member['ratingKey'].toString()];
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
    // Plex collections are only created for video kinds; music kinds send no type.
    final type = itemKind == null || itemKind.isMusic ? null : PlexMetadataType.forKind(itemKind);
    return createCollectionFromUri(sectionId: libraryId, title: title, uri: uri, type: type);
  }

  Future<String?> createCollectionFromUri({
    required String sectionId,
    required String title,
    required String uri,
    int? type,
  }) async {
    appLogger.d('Creating collection: sectionId=$sectionId, title=$title, type=$type');
    final response = await _http.post(
      '/library/collections',
      queryParameters: {'type': ?type, 'title': title, 'smart': 0, 'sectionId': sectionId, 'uri': uri},
    );
    throwIfHttpError(response);
    appLogger.d('Create collection response: ${response.statusCode}');

    final metadata = _getMediaContainer(response)?['Metadata'];
    if (metadata is! List || metadata.isEmpty || metadata.first is! Map) return null;
    final collectionId = (metadata.first as Map)['ratingKey']?.toString().trim();
    if (collectionId == null || collectionId.isEmpty) return null;
    appLogger.d('Created collection with ID: $collectionId');
    return collectionId;
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
