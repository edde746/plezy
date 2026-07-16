part of '../../plex_client.dart';

mixin _PlexPlayQueueMethods on MediaServerCacheMixin {
  FailoverHttpClient get _http;

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

  PlexMetadataDto _createTaggedMetadataWithLibrary(
    Map<String, dynamic> json, {
    int? librarySectionID,
    String? librarySectionTitle,
  });

  Future<String> buildMetadataUri(String ratingKey);

  PlayQueueResponse _parsePlayQueueResponse(dynamic data, {int? librarySectionID, String? librarySectionTitle}) {
    final container = data is Map && data['MediaContainer'] is Map
        ? data['MediaContainer'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    final containerSectionID = _librarySectionIdFromJson(container) ?? librarySectionID;
    final containerSectionTitle = _librarySectionTitleFromJson(container) ?? librarySectionTitle;
    final metadata = container['Metadata'];
    List<MediaItem>? items;
    if (metadata is List) {
      items = [
        for (final entry in metadata)
          if (entry is Map<String, dynamic>)
            PlexMappers.mediaItem(
              _createTaggedMetadataWithLibrary(
                entry,
                librarySectionID: containerSectionID,
                librarySectionTitle: containerSectionTitle,
              ),
            ),
      ];
    }
    final playQueueID = flexibleInt(container['playQueueID']);
    final playQueueVersion = flexibleInt(container['playQueueVersion']);
    if (playQueueID == null || playQueueVersion == null) {
      throw const FormatException('Plex play queue response is missing its numeric id or version');
    }
    return PlayQueueResponse(
      playQueueID: playQueueID,
      playQueueSelectedItemID: flexibleInt(container['playQueueSelectedItemID']),
      playQueueSelectedItemOffset: flexibleInt(container['playQueueSelectedItemOffset']),
      playQueueSelectedMetadataItemID: container['playQueueSelectedMetadataItemID'] as String?,
      playQueueShuffled: flexibleBool(container['playQueueShuffled']),
      playQueueSourceURI: container['playQueueSourceURI'] as String?,
      playQueueTotalCount: flexibleInt(container['playQueueTotalCount']),
      playQueueVersion: playQueueVersion,
      size: flexibleInt(container['size']),
      items: items,
    );
  }

  Future<PlayQueueResponse?> createPlayQueue({
    String? uri,
    int? playlistID,
    required String type,
    String? key,
    int shuffle = 0,
    int repeat = 0,
    int continuous = 0,
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'type': type,
        'shuffle': shuffle,
        'repeat': repeat,
        'continuous': continuous,
        'uri': ?uri,
        'playlistID': ?playlistID,
        'key': ?key,
      };
      final response = await _http.post('/playQueues', queryParameters: queryParameters);
      throwIfHttpError(response);
      return _parsePlayQueueResponse(
        response.data,
        librarySectionID: _librarySectionIdFromString(librarySectionID),
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e) {
      appLogger.e('Failed to create play queue', error: e);
      return null;
    }
  }

  Future<PlayQueueResponse?> getPlayQueue(
    int playQueueId, {
    String? center,
    int window = 50,
    int includeBefore = 1,
    int includeAfter = 1,
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'window': window,
        'includeBefore': includeBefore,
        'includeAfter': includeAfter,
        'center': ?center,
      };
      final response = await _getWithFailover('/playQueues/$playQueueId', queryParameters: queryParameters);
      return _parsePlayQueueResponse(
        response.data,
        librarySectionID: _librarySectionIdFromString(librarySectionID),
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e) {
      appLogger.e('Failed to get play queue: $e');
      return null;
    }
  }

  Future<PlayQueueResponse?> createShowPlayQueue({
    required String showRatingKey,
    int shuffle = 0,
    String? startingEpisodeKey,
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    try {
      // `/allLeaves` preserves Plex's aired episode order and interleaves
      // specials; `/children` groups specials into a separate season.
      final uri = '${await buildMetadataUri(showRatingKey)}/allLeaves';
      return createPlayQueue(
        uri: uri,
        type: 'video',
        shuffle: shuffle,
        key: startingEpisodeKey == null ? null : '/library/metadata/$startingEpisodeKey',
        continuous: startingEpisodeKey != null && shuffle == 0 ? 1 : 0,
        librarySectionID: librarySectionID,
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e) {
      appLogger.e('Failed to create show play queue', error: e);
      return null;
    }
  }
}
