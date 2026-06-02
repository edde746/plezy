part of '../../jellyfin_client.dart';

mixin _JellyfinMetadataEditMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  MediaServerHttpClient get _http;

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

  Future<List<Map<String, dynamic>>> getItemImageInfos(String itemId) async {
    final response = await _http.get('/Items/${_segment(itemId)}/Images');
    throwIfHttpError(response);
    final data = response.data;
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : const <Map<String, dynamic>>[];
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
