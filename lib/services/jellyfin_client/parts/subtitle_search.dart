part of '../../jellyfin_client.dart';

/// [ExternalSubtitleSearchClient] over the server's subtitle plugins
/// (`/Items/{id}/RemoteSearch/Subtitles`). Jellyfin only: Emby gates the same
/// routes behind Premiere, so the probe never runs there.
mixin _JellyfinSubtitleSearchMethods on _JellyfinClientInternals {
  bool _remoteSubtitleSearchAvailable = false;

  /// Cached result of [probeRemoteSubtitleSearch]; false until it resolves.
  bool get remoteSubtitleSearchAvailable => _remoteSubtitleSearchAvailable;

  /// Whether this user can search subtitles on this server: the search routes
  /// need subtitle-management rights, and answer an empty list unless a
  /// subtitle fetcher is loaded. `/Libraries/AvailableOptions` names the loaded
  /// fetchers to any signed-in user, so admins and users get the same answer.
  /// [policy] is the user's `Policy` when the caller already has it (each
  /// health check does), so permission changes are followed for free. A failed
  /// probe keeps the last answer and never fails the client over to another
  /// endpoint: that is real traffic's call.
  Future<bool> probeRemoteSubtitleSearch({Object? policy}) async {
    if (dialect != MediaBrowserDialect.jellyfin) return false;
    try {
      var userPolicy = policy;
      if (userPolicy == null) {
        final user = await _http.get(paths.currentUser, allowEndpointFailover: false);
        throwIfHttpError(user);
        userPolicy = user.data is Map<String, dynamic> ? user.data['Policy'] : null;
      }
      // Jellyfin lets admins through whatever the flag says.
      final canManage =
          userPolicy is Map<String, dynamic> &&
          (userPolicy['IsAdministrator'] == true || userPolicy['EnableSubtitleManagement'] == true);
      if (!canManage) return _remoteSubtitleSearchAvailable = false;
      final options = await _http.get('/Libraries/AvailableOptions', allowEndpointFailover: false);
      throwIfHttpError(options);
      final fetchers = options.data is Map<String, dynamic> ? options.data['SubtitleFetchers'] : null;
      return _remoteSubtitleSearchAvailable = fetchers is List && fetchers.isNotEmpty;
    } catch (e) {
      appLogger.d('JellyfinClient: remote subtitle search probe failed', error: e);
      return _remoteSubtitleSearchAvailable;
    }
  }

  /// Its rescan after a download can queue behind library scans.
  Duration get subtitleDownloadTimeout => const Duration(seconds: 30);

  /// The rescan puts external subtitles first and renumbers every stream.
  bool get subtitleDownloadKeepsStreamIds => false;

  /// Jellyfin's subtitle providers only search movies and episodes.
  bool canSearchSubtitlesFor(MediaKind kind) => kind == MediaKind.movie || kind == MediaKind.episode;

  /// A merged alternate version is an item of its own, whose media source id
  /// is that item's id, and Jellyfin saves its subtitles next to its file. A
  /// source without an id gets its position as a version id, which is not one.
  String subtitleItemIdFor(String itemId, {String? mediaSourceId}) =>
      mediaSourceId == null || mediaSourceId.isEmpty || int.tryParse(mediaSourceId) != null ? itemId : mediaSourceId;

  /// Jellyfin's search takes no title, so the sheet filters its rows by release name.
  bool get subtitleTitleFiltersByReleaseName => true;

  /// Jellyfin resolves two- and three-letter [language] codes alike. Its
  /// search takes no [title] ([subtitleTitleFiltersByReleaseName]).
  Future<List<SubtitleSearchResult>> searchSubtitles(
    String ratingKey, {
    required String language,
    String? title,
  }) async {
    final response = await _http.get('/Items/${_segment(ratingKey)}/RemoteSearch/Subtitles/${_segment(language)}');
    throwIfHttpError(response);
    final rows = response.data is List
        ? (response.data as List).whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    return [
      for (final row in rows)
        if (row['Id'] is String)
          SubtitleSearchResult(
            key: row['Id'] as String,
            languageCode: language,
            codec: row['Format'] as String?,
            title: row['Name'] as String?,
            displayTitle: [
              row['ProviderName'],
              (row['Format'] as String?)?.toUpperCase(),
              if (row['HearingImpaired'] == true) 'SDH',
            ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            hearingImpaired: row['HearingImpaired'] == true,
            forced: row['Forced'] == true,
            perfectMatch: row['IsHashMatch'] == true,
          ),
    ];
  }

  /// Jellyfin answers 204 even when the provider failed and rescans the item
  /// in the background, so success shows only in the returned download's poll.
  Future<SubtitleDownload?> downloadSubtitle(
    String ratingKey,
    SubtitleSearchResult result, {
    required Set<int> existingTrackIds,
    Duration? position,
  }) async {
    final before = (await _externalSubtitlesByPath(ratingKey)).tracks.keys.toSet();
    final response = await _http.post('/Items/${_segment(ratingKey)}/RemoteSearch/Subtitles/${_segment(result.key)}');
    throwIfHttpError(response);
    return () => _findDownloadedSubtitle(ratingKey, result, before);
  }

  /// The rescan inserts external streams ahead of the container's and
  /// renumbers every index, and same-language files share every label, so the
  /// new file is found by path, against the paths listed [before] the download.
  Future<MediaSubtitleTrack?> _findDownloadedSubtitle(
    String ratingKey,
    SubtitleSearchResult result,
    Set<String> before,
  ) async {
    final searched = result.languageCode ?? '';
    final languages = LanguageCodes.getVariations(searched);
    final format = (result.codec ?? 'srt').toLowerCase();
    // Bazarr, a scan or another client can add a file in the same window, so
    // only a new file in the chosen language, format and forced-ness counts,
    // and only one. Jellyfin reads the language from the name it saves under,
    // but from 10.11 keeps one whose name has a dash (Greek's "Greek, Modern
    // (1453-)") as that name: the code is then still in the file name.
    bool inLanguage(String path, String? language) =>
        languages.contains(language?.toLowerCase()) ||
        (language != null &&
            LanguageCodes.getLanguageName(language) == null &&
            path.split('/').last.toLowerCase().contains('.${searched.toLowerCase()}.'));
    final now = await _externalSubtitlesByPath(ratingKey);
    final added = [
      for (final MapEntry(key: path, value: track) in now.tracks.entries)
        if (!before.contains(path) &&
            inLanguage(path, track.languageCode) &&
            track.forced == result.forced &&
            path.toLowerCase().endsWith('.$format'))
          track,
    ];
    if (added.length != 1) return null;
    // For a merged version, the row playback reads cache-first is the primary
    // item's, one of the other versions this item lists: refresh those too,
    // before reporting the find, so the next poll retries a failed refresh.
    await Future.wait([for (final id in now.otherVersionIds) fetchItem(id)]);
    return added.single;
  }

  /// Straight from the server: an empty or cached listing would pass a file
  /// already there as new. Rewrites the row playback reads cache-first, so the
  /// reload after a download sees the renumbered streams too. Also returns the
  /// item's other versions.
  Future<({Map<String, MediaSubtitleTrack> tracks, List<String> otherVersionIds})> _externalSubtitlesByPath(
    String itemId,
  ) async {
    final endpoint = '/Users/${_segment(connection.userId)}/Items/${_segment(itemId)}';
    final response = await _http.get(endpoint, queryParameters: {'Fields': _detailFields});
    throwIfHttpError(response);
    final raw = response.data;
    if (raw is! Map<String, dynamic> || raw['MediaSources'] is! List) throw const FormatException('No item listing');
    final sources = (raw['MediaSources'] as List).whereType<Map<String, dynamic>>().toList();
    if (sources.isEmpty) throw const FormatException('No item listing');
    await cache
        .put(ServerId(cacheServerId), endpoint, raw)
        .catchError((Object e) => appLogger.w('Cache write', error: e));
    final otherVersionIds = [
      for (final s in sources)
        if (s['Id'] is String && s['Id'] != itemId) s['Id'] as String,
    ];
    final source = sources.where((s) => s['Id'] == itemId).firstOrNull ?? sources.firstOrNull;
    final streams = source?['MediaStreams'];
    if (streams is! List) return (tracks: const <String, MediaSubtitleTrack>{}, otherVersionIds: otherVersionIds);
    final tracks = {for (final t in jellyfinMediaSourceToMediaSourceInfo(source!).subtitleTracks) t.id: t};
    return (
      tracks: {
        for (final stream in streams.whereType<Map<String, dynamic>>())
          if (stream['IsExternal'] == true && stream['Path'] is String && tracks[stream['Index']] != null)
            stream['Path'] as String: tracks[stream['Index']]!,
      },
      otherVersionIds: otherVersionIds,
    );
  }
}
