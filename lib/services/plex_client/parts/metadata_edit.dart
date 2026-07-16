part of '../../plex_client.dart';

mixin _PlexMetadataEditMethods on MediaServerCacheMixin {
  FailoverHttpClient get _http;
  PlexApiCache get _cache;
  @override
  ServerId get serverId;

  Future<MediaServerResponse> _getWithFailover(
    String path, {
    Map<String, dynamic>? queryParameters,
    // ignore: unused_element_parameter
    Map<String, String>? headers,
    // ignore: unused_element_parameter
    Duration? timeout,
    // ignore: unused_element_parameter
    AbortController? abort,
    // ignore: unused_element_parameter
    bool allowEndpointFailover = true,
  });

  Map<String, dynamic>? _getMediaContainer(MediaServerResponse response);

  Future<bool> _wrapBoolApiCall(Future<MediaServerResponse> Function() apiCall, String errorMessage);

  Future<List<T>> _wrapListApiCall<T>(
    Future<MediaServerResponse> Function() apiCall,
    List<T> Function(MediaServerResponse response) parseResponse,
    String errorMessage,
  );

  Future<bool> updateMetadata({
    required int sectionId,
    required String ratingKey,
    required int typeNumber,
    String? title,
    String? titleSort,
    String? originalTitle,
    String? originallyAvailableAt,
    String? contentRating,
    String? studio,
    String? tagline,
    String? summary,
    Map<String, ({List<String> current, List<String> original})>? tagChanges,
  }) async {
    final queryParameters = <String, dynamic>{'type': typeNumber, 'id': ratingKey};

    void addField(String name, String? value) {
      if (value == null) return;
      queryParameters['$name.value'] = value;
      queryParameters['$name.locked'] = '1';
    }

    addField('title', title);
    addField('titleSort', titleSort);
    addField('originalTitle', originalTitle);
    addField('originallyAvailableAt', originallyAvailableAt);
    addField('contentRating', contentRating);
    addField('studio', studio);
    addField('tagline', tagline);
    addField('summary', summary);

    if (tagChanges != null) {
      for (final entry in tagChanges.entries) {
        final field = entry.key;
        final current = entry.value.current;
        final original = entry.value.original;
        for (var index = 0; index < current.length; index++) {
          queryParameters['$field[$index].tag.tag'] = current[index];
        }
        final removed = original.where((tag) => !current.contains(tag));
        if (removed.isNotEmpty) {
          queryParameters['$field[].tag.tag-'] = removed.map(Uri.encodeComponent).join(',');
        }
        queryParameters['$field.locked'] = '1';
      }
    }

    final result = await _wrapBoolApiCall(
      () => _http.put('/library/sections/$sectionId/all', queryParameters: queryParameters),
      'Failed to update metadata',
    );
    if (result) await _deleteMetadataEditCache(ratingKey);
    return result;
  }

  Future<List<PlexMatchResult>> findMatches(
    String ratingKey, {
    String? title,
    String? year,
    String? agent,
    String? language,
  }) {
    final queryParameters = <String, dynamic>{
      'manual': 1,
      if (title != null && title.isNotEmpty) 'title': title,
      if (year != null && year.isNotEmpty) 'year': year,
      if (agent != null && agent.isNotEmpty) 'agent': agent,
      if (language != null && language.isNotEmpty) 'language': language,
    };
    return _wrapListApiCall<PlexMatchResult>(
      () => _getWithFailover('/library/metadata/$ratingKey/matches', queryParameters: queryParameters),
      (response) {
        final results = _getMediaContainer(response)?['SearchResult'];
        if (results is! List) return [];
        return results.map((json) => PlexMatchResult.fromJson(json as Map<String, dynamic>)).toList();
      },
      'Failed to search for matches',
    );
  }

  Future<bool> applyMatch(String ratingKey, {required String guid, String? name, String? year}) async {
    final queryParameters = <String, dynamic>{
      'guid': guid,
      if (name != null && name.isNotEmpty) 'name': name,
      if (year != null && year.isNotEmpty) 'year': year,
    };
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/match', queryParameters: queryParameters),
      'Failed to apply match',
    );
    if (result) await _deleteMetadataEditCache(ratingKey);
    return result;
  }

  Future<bool> unmatchItem(String ratingKey) async {
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/unmatch'),
      'Failed to unmatch item',
    );
    if (result) await _deleteMetadataEditCache(ratingKey);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAvailableArtwork(String ratingKey, String element) async {
    try {
      final response = await _getWithFailover('/library/metadata/$ratingKey/$element');
      final metadata = _getMediaContainer(response)?['Metadata'];
      return metadata is List ? metadata.cast<Map<String, dynamic>>() : const [];
    } catch (e) {
      appLogger.e('Failed to get available artwork', error: e);
      return [];
    }
  }

  Future<bool> setArtworkFromUrl(String ratingKey, String element, String url) async {
    final target = _artworkTarget(element);
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/$target', queryParameters: {'url': url}),
      'Failed to set artwork from URL',
    );
    if (result) await _deleteMetadataEditCache(ratingKey);
    return result;
  }

  Future<bool> uploadArtwork(String ratingKey, String element, List<int> bytes) async {
    final target = _artworkTarget(element);
    final result = await _wrapBoolApiCall(
      () => _http.put(
        '/library/metadata/$ratingKey/$target',
        body: bytes,
        headers: {'Content-Type': 'application/octet-stream', 'Content-Length': '${bytes.length}'},
      ),
      'Failed to upload artwork',
    );
    if (result) await _deleteMetadataEditCache(ratingKey);
    return result;
  }

  Future<bool> updateMetadataPrefs(String ratingKey, Map<String, String> prefs) async {
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/prefs', queryParameters: prefs),
      'Failed to update metadata preferences',
    );
    if (result) await _deleteMetadataEditCache(ratingKey);
    return result;
  }

  String _artworkTarget(String element) {
    return element.endsWith('s') ? element.substring(0, element.length - 1) : element;
  }

  Future<void> _deleteMetadataEditCache(String ratingKey) async {
    try {
      await _cache.deleteForItem(serverId, ratingKey);
    } catch (e, st) {
      appLogger.w('Plex metadata edit cache invalidation failed', error: e, stackTrace: st);
    }
  }
}
