part of '../../jellyfin_client.dart';

/// [ExternalSubtitleSearchClient] over the server's Open Subtitles plugin
/// (`/Items/{id}/RemoteSearch/Subtitles`). Jellyfin only: Emby gates the same
/// routes behind Premiere, so the probe never runs there.
mixin _JellyfinSubtitleSearchMethods on _JellyfinClientInternals {
  static const _openSubtitlesFetcher = 'Open Subtitles';

  bool _remoteSubtitleSearchAvailable = false;

  /// Per item, its external subtitle paths before the last [downloadSubtitle],
  /// and the language, format and forced-ness that download asked for.
  final _pendingSubtitleDownloads = <String, ({Set<String> paths, String language, String codec, bool forced})>{};

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
      final options = await _http.get(
        '/Libraries/AvailableOptions',
        queryParameters: {'libraryContentType': 'movies'},
        allowEndpointFailover: false,
      );
      throwIfHttpError(options);
      final fetchers = options.data is Map<String, dynamic> ? options.data['SubtitleFetchers'] : null;
      return _remoteSubtitleSearchAvailable =
          fetchers is List && fetchers.any((f) => f is Map && f['Name'] == _openSubtitlesFetcher);
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

  /// Jellyfin resolves two- and three-letter [language] codes alike. Its
  /// search takes no title, so [title] filters the rows by name instead.
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
    String letters(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    final filter = letters(title ?? '');
    return [
      for (final row in rows)
        if (row['Id'] is String && letters('${row['Name'] ?? ''}').contains(filter))
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
  /// in the background, so success shows only in [findDownloadedSubtitle].
  Future<bool> downloadSubtitle(String ratingKey, SubtitleSearchResult result) async {
    final language = result.languageCode ?? '';
    final codec = result.codec ?? 'srt';
    _pendingSubtitleDownloads[ratingKey] = (
      paths: (await _externalSubtitlesByPath(ratingKey)).tracks.keys.toSet(),
      language: language,
      codec: codec,
      forced: result.forced,
    );
    final response = await _http.post('/Items/${_segment(ratingKey)}/RemoteSearch/Subtitles/${_segment(result.key)}');
    throwIfHttpError(response);
    return true;
  }

  /// The rescan inserts external streams ahead of the container's and
  /// renumbers every index, and same-language files share every label, so the
  /// new file is found by path, not by [existingTrackIds].
  Future<MediaSubtitleTrack?> findDownloadedSubtitle(
    String ratingKey, {
    required Set<int> existingTrackIds,
    Duration? position,
  }) async {
    final pending = _pendingSubtitleDownloads[ratingKey];
    if (pending == null) return null;
    final languages = LanguageCodes.getVariations(pending.language);
    final format = CodecUtils.getSubtitleExtension(pending.codec);
    // Bazarr, a scan or another client can add a file in the same window, so
    // only a new file in the chosen language, format and forced-ness counts,
    // and only one. Jellyfin reads the language from the name it saves under,
    // but from 10.11 keeps one whose name has a dash (Greek's "Greek, Modern
    // (1453-)") as that name: the code is then still in the file name.
    bool inLanguage(String path, String? language) =>
        languages.contains(language?.toLowerCase()) ||
        (language != null &&
            LanguageCodes.getLanguageName(language) == null &&
            path.split('/').last.toLowerCase().contains('.${pending.language.toLowerCase()}.'));
    final now = await _externalSubtitlesByPath(ratingKey);
    final added = [
      for (final MapEntry(key: path, value: track) in now.tracks.entries)
        if (!pending.paths.contains(path) &&
            inLanguage(path, track.languageCode) &&
            track.forced == pending.forced &&
            CodecUtils.getSubtitleExtension(track.codec) == format)
          track,
    ];
    if (added.length != 1) return null;
    // For a merged version, the row playback reads cache-first is the primary
    // item's, one of the other versions this item lists: refresh those too,
    // before forgetting the download, so a failed refresh is retried.
    await Future.wait([for (final id in now.otherVersionIds) fetchItem(id)]);
    _pendingSubtitleDownloads.remove(ratingKey);
    return added.single;
  }

  /// Through [fetchItem], which always hits the network and rewrites the row
  /// playback reads cache-first, so the reload after a download sees the
  /// renumbered streams too. Also returns the item's other versions.
  Future<({Map<String, MediaSubtitleTrack> tracks, List<String> otherVersionIds})> _externalSubtitlesByPath(
    String itemId,
  ) async {
    final raw = (await fetchItem(itemId))?.raw;
    final sources = [
      if (raw is Map<String, dynamic> && raw['MediaSources'] is List)
        ...(raw['MediaSources'] as List).whereType<Map<String, dynamic>>(),
    ];
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
