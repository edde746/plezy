import 'dart:async';

import '../exceptions/media_server_exceptions.dart';
import '../media/media_item.dart';
import '../media/media_item_merge.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/title_copies.dart';
import '../utils/external_ids.dart';
import '../utils/media_server_http_client.dart';
import 'data_aggregation_service.dart';

typedef ContinueWatchingCopyLookup = ({List<MediaItem> copies, bool isComplete});
typedef ContinueWatchingTitleFinder = Future<LibraryLookupResult> Function(TitleQuery query, {AbortController? abort});

/// Profile-owned, short-lived catalogue results for the library-copy menu action.
/// Hub entries are useful choices, but are not a complete library inventory.
class ContinueWatchingCopyResolver {
  ContinueWatchingCopyResolver({
    required this.clientFor,
    required this.findCopies,
    DateTime Function()? now,
    this.cacheTtl = const Duration(minutes: 1),
    this.deadline = const Duration(seconds: 30),
  }) : _now = now ?? DateTime.now;

  final MediaServerClient? Function(String serverId) clientFor;
  final ContinueWatchingTitleFinder findCopies;
  final DateTime Function() _now;
  final Duration cacheTtl;
  final Duration deadline;
  final _cache = <String, ({DateTime at, List<MediaItem> copies})>{};
  int _generation = 0;

  void clear() {
    _generation++;
    _cache.clear();
  }

  Future<ContinueWatchingCopyLookup> resolve(
    MediaItem item, {
    required List<MediaItem> knownCopies,
    required Set<String> hiddenLibraryKeys,
    required String Function() scopeKey,
    AbortController? abort,
  }) async {
    final scope = scopeKey();
    final generation = _generation;
    final hidden = hiddenLibraryKeys.toList()..sort();
    String keyFor(MediaItem copy) => '$scope/${copy.globalKey}/${copy.parentIndex}/${copy.index}/${hidden.join(',')}';
    final key = keyFor(item);
    final request = AbortController();
    if (abort != null) unawaited(abort.trigger.then((_) => request.abort()));
    void checkCurrent() {
      abort?.throwIfAborted();
      request.throwIfAborted();
      if (scopeKey() != scope) {
        request.abort();
        request.throwIfAborted();
      }
    }

    List<MediaItem> choices(Iterable<MediaItem> discovered) {
      // Keep the current hub row's progress when detail metadata omits it.
      final merged = mergeLibraryCopies(discovered, [...knownCopies, item]);
      return [
        for (final copy in merged)
          if (!hiddenLibraryKeys.contains('${copy.serverId}:${copy.libraryId}')) _withResumeFallback(item, copy),
      ];
    }

    checkCurrent();
    final cached = _cache[key];
    if (cached != null && _now().difference(cached.at) < cacheTtl) {
      return (copies: choices(cached.copies), isComplete: true);
    }
    try {
      final lookup =
          await Future.any<LibraryLookupResult?>([
            _lookup(item, request, checkCurrent),
            request.trigger.then<LibraryLookupResult?>((_) {
              request.throwIfAborted();
              return null;
            }),
          ]).timeout(
            deadline,
            onTimeout: () {
              request.abort();
              throw TimeoutException('Continue Watching copy lookup timed out');
            },
          );
      checkCurrent();
      final found = (lookup?.items ?? const <MediaItem>[]).where((copy) => _sameEpisode(item, copy)).toList();
      final complete =
          lookup != null &&
          lookup.failedServerIds.isEmpty &&
          lookup.cancelledServerIds.isEmpty &&
          lookup.unqueriedServerIds.isEmpty;
      if (complete && generation == _generation) {
        for (final copy in [...found, item]) {
          if (_cache.length >= 40) _cache.remove(_cache.keys.first);
          _cache[keyFor(copy)] = (at: _now(), copies: found);
        }
      }
      return (copies: choices(found), isComplete: complete);
    } catch (error) {
      abort?.throwIfAborted();
      if (scopeKey() != scope || error is MediaServerHttpException && error.isCancellation) rethrow;
      return (copies: choices(const []), isComplete: false);
    }
  }

  Future<LibraryLookupResult?> _lookup(MediaItem item, AbortController abort, void Function() checkCurrent) async {
    final client = item.serverId == null ? null : clientFor(item.serverId!);
    if (client == null) return null;
    final TitleQuery query;
    if (item.kind == MediaKind.movie) {
      final ids = await client.fetchExternalIds(item.id);
      checkCurrent();
      query = TitleQuery.movie(title: item.title ?? '', year: item.year, ids: ids, plexGuid: item.guid);
    } else if (item.kind == MediaKind.episode &&
        item.grandparentId != null &&
        item.parentIndex != null &&
        item.index != null) {
      final metadata = await Future.wait<Object?>([
        client.fetchExternalIds(item.grandparentId!),
        client.fetchItem(item.grandparentId!),
        client.fetchExternalIds(item.id),
      ]);
      checkCurrent();
      final show = metadata[1] as MediaItem?;
      query = TitleQuery.episode(
        showTitle: show?.title ?? item.grandparentTitle ?? '',
        showYear: show?.year,
        showIds: metadata[0] as ExternalIds,
        showPlexGuid: show?.guid,
        season: item.parentIndex!,
        episode: item.index!,
        ids: metadata[2] as ExternalIds,
        title: item.title ?? '',
      );
    } else {
      return null;
    }
    return findCopies(query, abort: abort);
  }

  static bool _sameEpisode(MediaItem source, MediaItem copy) =>
      source.kind == copy.kind &&
      (source.kind != MediaKind.episode || source.parentIndex == copy.parentIndex && source.index == copy.index);

  static MediaItem _withResumeFallback(MediaItem source, MediaItem copy) {
    final offset = source.viewOffsetMs;
    final duration = source.durationMs;
    final copyDuration = copy.durationMs;
    if (!_sameEpisode(source, copy) ||
        copy.viewOffsetMs != null ||
        offset == null ||
        offset <= 0 ||
        duration == null ||
        copyDuration == null ||
        offset >= duration ||
        offset >= copyDuration ||
        (duration - copyDuration).abs() > 2000 ||
        source.editionTitle != copy.editionTitle) {
      return copy;
    }
    return copy.copyWith(viewOffsetMs: offset);
  }
}
