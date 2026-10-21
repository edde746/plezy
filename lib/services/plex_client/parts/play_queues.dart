part of '../../plex_client.dart';

mixin _PlexPlayQueueMethods on _PlexClientInternals {
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

  /// Build a show play queue. Deliberately best-effort: both callers (the
  /// video player's episode queue and shuffled-show launch) degrade to a
  /// local/empty queue on null rather than failing playback outright.
  ///
  /// Shuffled queues and [SpecialsOrdering.airDate] come from the show's
  /// `/allLeaves`. PMS orders a queue built from that URI purely by
  /// `originallyAvailableAt` (undated first), which interleaves Specials by
  /// air date (#1416). Every other mode gets Plex Web's sequential order via
  /// [_createSequentialShowPlayQueue].
  Future<PlayQueueResponse?> createShowPlayQueue({
    required String showRatingKey,
    int shuffle = 0,
    String? startingEpisodeKey,
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    try {
      if (shuffle != 0 || effectiveSpecialsOrdering() == SpecialsOrdering.airDate) {
        return await createPlayQueue(
          uri: '${await buildMetadataUri(showRatingKey)}/allLeaves',
          type: 'video',
          shuffle: shuffle,
          key: startingEpisodeKey == null ? null : '/library/metadata/$startingEpisodeKey',
          librarySectionID: librarySectionID,
          librarySectionTitle: librarySectionTitle,
        );
      }
      return await _createSequentialShowPlayQueue(
        showRatingKey: showRatingKey,
        startingEpisodeKey: startingEpisodeKey,
        librarySectionID: librarySectionID,
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e) {
      appLogger.e('Failed to create show play queue', error: e);
      return null;
    }
  }

  /// Sequential show queue in Plex Web's order: regular seasons by season
  /// and episode number, then Specials. Plex Web seeds `continuous=1` with
  /// the episode being played, and PMS ignores air dates for such a queue,
  /// so a mis-dated episode cannot jump the run the way it does in an
  /// `/allLeaves` queue (#2770).
  ///
  /// Plex Web's queue starts at its seed, leaving nothing before the playing
  /// episode. Seeding at the show's first episode and selecting
  /// [startingEpisodeKey] with `key` keeps that order with earlier episodes
  /// still in the queue.
  Future<PlayQueueResponse> _createSequentialShowPlayQueue({
    required String showRatingKey,
    String? startingEpisodeKey,
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    Future<PlayQueueResponse> create(String seedKey) async => createPlayQueue(
      uri: await buildMetadataUri(seedKey),
      type: 'video',
      continuous: 1,
      key: startingEpisodeKey == null ? null : '/library/metadata/$startingEpisodeKey',
      librarySectionID: librarySectionID,
      librarySectionTitle: librarySectionTitle,
    );

    final seedKey = await _firstShowEpisodeKey(showRatingKey) ?? startingEpisodeKey;
    if (seedKey == null) {
      throw StateError('Show $showRatingKey has no episode to seed a play queue with');
    }
    final queue = await create(seedKey);
    if (startingEpisodeKey == null || seedKey == startingEpisodeKey || _selectsItem(queue, startingEpisodeKey)) {
      return queue;
    }
    // PMS leaves some episodes out of a continuous queue (seen: an undated
    // one) and then silently selects the seed instead of `key`. Re-seed at
    // the episode itself, which is Plex Web's exact request.
    appLogger.d('Play queue seeded at $seedKey did not select $startingEpisodeKey; re-seeding at it');
    return create(startingEpisodeKey);
  }

  /// The episode a continuous show queue starts from: the first episode of
  /// the first regular season, or of Specials when the show has no regular
  /// season. Null when the show lists no seasons.
  Future<String?> _firstShowEpisodeKey(String showRatingKey) async {
    final season = defaultPlaybackSeason(await fetchChildren(showRatingKey));
    if (season == null) return null;
    final page = await fetchChildrenPage(season.id, start: 0, size: 1);
    for (final item in page.items) {
      if (item.kind == MediaKind.episode) return item.id;
    }
    return null;
  }

  bool _selectsItem(PlayQueueResponse queue, String itemKey) {
    final selectedId = queue.playQueueSelectedItemID;
    if (selectedId == null) return false;
    return queue.items?.any(
          (item) => item is PlexMediaItem && item.playQueueItemId == selectedId && item.id == itemKey,
        ) ??
        false;
  }
}
