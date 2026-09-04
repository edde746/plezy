part of '../../plex_client.dart';

mixin _PlexPlayQueueMethods on _PlexClientInternals {
  PlexMetadataDto _createTaggedMetadataWithLibrary(
    Map<String, dynamic> json, {
    int? librarySectionID,
    String? librarySectionTitle,
  });

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
      playQueueShuffled: flexibleBool(container['playQueueShuffled']),
      playQueueTotalCount: flexibleInt(container['playQueueTotalCount']),
      size: flexibleInt(container['size']),
      items: items,
    );
  }

  /// Create a server-side play queue. Failures propagate as typed exceptions
  /// (usually [MediaServerHttpException]) instead of collapsing into null, so
  /// callers can tell "the server said no" (#2141) from a queue that is
  /// genuinely empty. The POST rides the shared endpoint failover: replaying
  /// it is safe because an orphaned duplicate queue on the server is inert.
  Future<PlayQueueResponse> createPlayQueue({
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
      final response = await _postWithFailover('/playQueues', queryParameters: queryParameters);
      return _parsePlayQueueResponse(
        response.data,
        librarySectionID: _librarySectionIdFromString(librarySectionID),
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e, stackTrace) {
      appLogger.e('Failed to create play queue', error: e, stackTrace: stackTrace);
      rethrow;
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
      // specials (#1416) — both what the server itself does (respectServer)
      // and the explicit airDate mode. `/children` flattens season-by-season,
      // keeping the Specials folder out of the regular run (#1952). Mirrors
      // the client-side choice in [sortEpisodesByWatchOrder].
      final leaf = effectiveSpecialsOrdering() == SpecialsOrdering.specialsLast ? 'children' : 'allLeaves';
      final uri = '${await buildMetadataUri(showRatingKey)}/$leaf';
      return await createPlayQueue(
        uri: uri,
        type: 'video',
        shuffle: shuffle,
        key: startingEpisodeKey == null ? null : '/library/metadata/$startingEpisodeKey',
        continuous: startingEpisodeKey != null && shuffle == 0 ? 1 : 0,
        librarySectionID: librarySectionID,
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e) {
      // Deliberately best-effort: both callers (the video player's episode
      // queue and shuffled-show launch) degrade to a local/empty queue on
      // null rather than failing playback outright.
      appLogger.e('Failed to create show play queue', error: e);
      return null;
    }
  }
}
