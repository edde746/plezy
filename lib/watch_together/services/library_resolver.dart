import 'dart:async';

import 'package:openwatchparty/openwatchparty.dart' as owp;

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../media/media_version.dart';
import '../../media/title_copies.dart';
import '../../services/data_aggregation_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../../utils/media_server_http_client.dart';
import '../models/watch_copy.dart';
import 'media_descriptor.dart';

/// Looks the room's media up across every server of the active profile.
typedef TitleCopyFinder = Future<LibraryLookupResult> Function(TitleQuery query, {AbortController? abort});

/// The active profile's online client for a server, or null.
typedef ServerClientLookup = MediaServerClient? Function(String serverId);

/// Thrown when no copy was found and some server couldn't be asked: the SDK
/// reports it as `ResolveFailedEvent`, and searching again may still find one.
class LibraryLookupIncomplete implements Exception {
  const LibraryLookupIncomplete(this.failedServerIds);

  final Set<String> failedServerIds;

  @override
  String toString() => 'LibraryLookupIncomplete($failedServerIds)';
}

/// Finds this user's own copies of another participant's media (SDK.md §9.2):
/// every version of every copy is a candidate, with its length so the SDK can
/// match it by duration.
///
/// 1. The `app.plezy` shortcut: when the descriptor names a server this
///    profile reaches, that item's versions come first, the shared version
///    leading.
/// 2. Movies and episodes by catalogue identity on every server
///    ([DataAggregationService.findTitleCopiesAcrossServers]): IDs first, the
///    title only when no ID matched; episodes through their show and numbers.
///
/// A `video` has no catalogue identity, so only the shortcut finds it.
final class LibraryResolver implements owp.Resolver<WatchCopy> {
  LibraryResolver({required this.clientFor, required this.findCopies});

  final ServerClientLookup clientFor;
  final TitleCopyFinder findCopies;

  @override
  Future<List<owp.Candidate<WatchCopy>>> resolve(owp.Media media, owp.Cancellation cancel) async {
    final abort = AbortController();
    unawaited(cancel.whenCancelled.then((_) => abort.abort()));
    final candidates = <owp.Candidate<WatchCopy>>[];
    final seen = <WatchCopy>{};
    void addItem(MediaItem item, {String? firstVersionId}) {
      if (item.serverId == null || !_kindMatches(media.kind, item.kind)) return;
      final versions = [...?item.mediaVersions]..retainWhere((version) => version.isPlayable);
      if (firstVersionId != null) {
        final first = versions.indexWhere((version) => version.id == firstVersionId);
        if (first > 0) versions.insert(0, versions.removeAt(first));
      }
      for (final version in versions.isEmpty ? const <MediaVersion?>[null] : versions) {
        final candidate = candidateFor(item, version, clientFor: clientFor);
        if (seen.add(candidate.ref)) candidates.add(candidate);
      }
    }

    final ext = plezyExt(media);
    final extClient = ext == null ? null : clientFor(ext.server);
    if (ext != null && extClient != null) {
      try {
        final item = await extClient.fetchItem(ext.item);
        if (cancel.isCancelled) return const [];
        if (item != null) addItem(item, firstVersionId: ext.version);
      } catch (error, stackTrace) {
        if (cancel.isCancelled) return const [];
        appLogger.w(
          'WatchTogether: shared item is not readable on ${ext.server}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final query = titleQueryFor(media);
    if (query == null) return candidates;
    final result = await findCopies(query, abort: abort);
    if (cancel.isCancelled) return const [];
    for (final item in result.items) {
      addItem(item);
    }
    if (candidates.isEmpty && result.failedServerIds.isNotEmpty) {
      throw LibraryLookupIncomplete(result.failedServerIds);
    }
    return candidates;
  }
}

bool _kindMatches(owp.MediaKind kind, MediaKind itemKind) => switch (kind) {
  owp.MediaKind.movie => itemKind == MediaKind.movie,
  owp.MediaKind.episode => itemKind == MediaKind.episode,
  owp.MediaKind.video => itemKind.isVideo,
};

/// The candidate for [version] of [item]: its length when the server knows
/// it, else a probe that reads the item again for it.
owp.Candidate<WatchCopy> candidateFor(MediaItem item, MediaVersion? version, {ServerClientLookup? clientFor}) {
  final copy = WatchCopy.of(item, version);
  final parts = version?.parts ?? const [];
  final sizes = parts.map((part) => part.sizeBytes).toList();
  final durationMs = copy.durationMs;
  final client = clientFor?.call(copy.serverId);
  return owp.Candidate<WatchCopy>(
    id: '${copy.serverId}:${copy.itemId}:${copy.versionId}',
    ref: copy,
    durationMs: durationMs,
    sizeBytes: sizes.isNotEmpty && sizes.every((size) => size != null) ? sizes.fold<int>(0, (a, b) => a + b!) : null,
    name: parts.length == 1 ? fileBaseName(parts.single.file) : null,
    probe: durationMs != null || client == null
        ? null
        : (cancel) async {
            final fresh = await client.fetchItem(item.id);
            if (fresh == null || cancel.isCancelled) return null;
            final versions = fresh.mediaVersions ?? const <MediaVersion>[];
            final match = versions.where((v) => v.id == copy.versionId).firstOrNull;
            return versionDurationMs(fresh, match ?? (versions.length == 1 ? versions.single : null));
          },
  );
}

/// What to look for: a movie by its IDs and title, an episode by its show and
/// numbers. Null for a `video`, and for an episode without its numbers.
TitleQuery? titleQueryFor(owp.Media media) {
  switch (media.kind) {
    case owp.MediaKind.movie:
      return TitleQuery.movie(
        title: media.title,
        year: media.year,
        ids: externalIdsOf(media.ids),
        plexGuid: _plexGuid(media.ids),
      );
    case owp.MediaKind.episode:
      final series = media.series;
      final season = media.season;
      final episode = media.episode;
      if (series == null || season == null || episode == null) return null;
      return TitleQuery.episode(
        showTitle: series.title,
        showYear: series.year,
        showIds: externalIdsOf(series.ids),
        showPlexGuid: _plexGuid(series.ids),
        season: season,
        episode: episode,
        ids: externalIdsOf(media.ids),
        title: media.title,
      );
    case owp.MediaKind.video:
      return null;
  }
}

final _imdbId = RegExp(r'^tt\d{1,12}$');
final _numericId = RegExp(r'^\d{1,12}$');
final _plexGuidPattern = RegExp(r'^plex://(movie|show|season|episode)/[A-Za-z0-9]{1,64}$');

/// The descriptor's [ids] that Plezy can search by. Untrusted (SDK.md §9.7):
/// only well-formed IDs pass, and they are only ever search terms.
ExternalIds externalIdsOf(Map<String, String> ids) {
  int? number(String? value) => value != null && _numericId.hasMatch(value) ? int.parse(value) : null;
  final imdb = ids['imdb'];
  return ExternalIds(
    imdb: imdb != null && _imdbId.hasMatch(imdb) ? imdb : null,
    tmdb: number(ids['tmdb']),
    tvdb: number(ids['tvdb']),
    anidb: number(ids['anidb']),
  );
}

String? _plexGuid(Map<String, String> ids) {
  final guid = ids['plex'];
  return guid != null && _plexGuidPattern.hasMatch(guid) ? guid : null;
}
