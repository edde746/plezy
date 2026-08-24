part of '../../jellyfin_client.dart';

mixin _JellyfinSubtitleSearchMethods on _JellyfinClientInternals {
  @override
  Future<List<SubtitleSearchResult>> searchSubtitles(
    String ratingKey, {
    required String language,
    String? title,
    int mediaIndex = 0,
    String? mediaSourceId,
    bool? perfectMatch,
    bool? forced,
    bool? hearingImpaired,
  }) async {
    if (dialect != MediaBrowserDialect.emby) {
      throw UnsupportedError('Remote subtitle search is not supported for ${dialect.productName}');
    }

    final sourceId = await _resolveSubtitleMediaSourceId(
      ratingKey,
      mediaIndex: mediaIndex,
      mediaSourceId: mediaSourceId,
    );

    final response = await _http.get(
      '/Items/${_segment(ratingKey)}/RemoteSearch/Subtitles/${_segment(language)}',
      queryParameters: {
        'MediaSourceId': sourceId,
        'IsPerfectMatch': ?perfectMatch,
        'IsForced': ?forced,
        'IsHearingImpaired': ?hearingImpaired,
      },
    );
    throwIfHttpError(response);

    final data = response.data;
    if (data is! List) return const <SubtitleSearchResult>[];

    final normalizedTitle = title?.trim().toLowerCase();
    final results = <SubtitleSearchResult>[];
    for (int i = 0; i < data.length; i++) {
      final raw = data[i];
      if (raw is! Map<String, dynamic>) continue;
      final name = _readString(raw['Name']);
      if (normalizedTitle != null && normalizedTitle.isNotEmpty) {
        if (!name.toLowerCase().contains(normalizedTitle)) continue;
      }
      final providerTitle = _readStringOrNull(raw['ProviderName']);
      final languageName = _readStringOrNull(raw['Language']);
      final format = _readStringOrNull(raw['Format']);
      final comment = _readStringOrNull(raw['Comment']);
      final author = _readStringOrNull(raw['Author']);
      final threeLetter = _readStringOrNull(raw['ThreeLetterISOLanguageName']);
      final languageCode =
          LanguageCodes.getIso6391Code(languageName ?? '') ??
          LanguageCodes.getIso6391Code(threeLetter ?? '') ??
          LanguageCodes.getIso6391Code(language);
      final displayTitleParts = <String>[
        ?providerTitle,
        if (format != null && format.isNotEmpty) format.toUpperCase(),
        ?author,
        if (comment != null && comment.isNotEmpty) comment,
      ];

      results.add(
        SubtitleSearchResult(
          id: i,
          key: _readString(raw['Id']),
          codec: format,
          language: languageName,
          languageCode: languageCode,
          score: flexibleDouble(raw['CommunityRating']),
          providerTitle: providerTitle,
          title: name,
          displayTitle: displayTitleParts.isEmpty ? null : displayTitleParts.join(' - '),
          hearingImpaired: flexibleBool(raw['IsHearingImpaired']),
          perfectMatch: flexibleBool(raw['IsHashMatch']),
          downloaded: false,
          forced: flexibleBool(raw['IsForced']),
        ),
      );
    }

    return results;
  }

  @override
  Future<bool> downloadSubtitle(
    String ratingKey, {
    required String key,
    String? codec,
    String? language,
    bool hearingImpaired = false,
    bool forced = false,
    String? providerTitle,
    int mediaIndex = 0,
    String? mediaSourceId,
  }) async {
    if (dialect != MediaBrowserDialect.emby) {
      throw UnsupportedError('Remote subtitle download is not supported for ${dialect.productName}');
    }

    final sourceId = await _resolveSubtitleMediaSourceId(
      ratingKey,
      mediaIndex: mediaIndex,
      mediaSourceId: mediaSourceId,
    );

    final response = await _http.post(
      '/Items/${_segment(ratingKey)}/RemoteSearch/Subtitles/${_segment(key)}',
      queryParameters: {'MediaSourceId': sourceId},
    );
    throwIfHttpError(response);

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('NewIndex')) {
      final newIndex = flexibleInt(data['NewIndex']);
      if (newIndex != null) {
        rememberDownloadedSubtitleStreamId(ratingKey, sourceId, newIndex);
        return true;
      }
      return false;
    }

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  @override
  Future<int?> consumeDownloadedSubtitleStreamId(String ratingKey, {int mediaIndex = 0, String? mediaSourceId}) async {
    if (dialect != MediaBrowserDialect.emby) return null;
    final sourceId = await _resolveSubtitleMediaSourceId(
      ratingKey,
      mediaIndex: mediaIndex,
      mediaSourceId: mediaSourceId,
    );
    return consumeDownloadedSubtitleStreamIdByKey(ratingKey, sourceId);
  }

  @override
  Future<List<MediaSubtitleTrack>> fetchSourceSubtitleTracks(
    String ratingKey, {
    int mediaIndex = 0,
    String? mediaSourceId,
  }) async {
    final bundle = await fetchPlaybackBundle(ratingKey, sourceIndex: mediaIndex, sourceId: mediaSourceId);
    if (bundle == null) return const <MediaSubtitleTrack>[];
    final info = jellyfinMediaSourceToMediaSourceInfo(
      bundle.selectedSource,
      chapters: bundle.chapters,
      trickplay: bundle.trickplay,
    );
    return info.subtitleTracks;
  }

  Future<String> _resolveSubtitleMediaSourceId(String itemId, {required int mediaIndex, String? mediaSourceId}) async {
    final requested = mediaSourceId?.trim();
    if (requested != null && requested.isNotEmpty) return requested;

    final bundle = await fetchPlaybackBundle(itemId, sourceIndex: mediaIndex, sourceId: requested);
    final resolved = bundle?.selectedSourceId?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;

    throw StateError('No media source id available for subtitle operation');
  }

  static String _readString(Object? value) {
    final text = value is String ? value : value?.toString();
    return text?.trim() ?? '';
  }

  static String? _readStringOrNull(Object? value) {
    final text = _readString(value);
    return text.isEmpty ? null : text;
  }
}
