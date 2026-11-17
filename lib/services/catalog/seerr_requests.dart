import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_kind.dart';
import '../../mixins/disposable_change_notifier_mixin.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../models/seerr/seerr_details.dart';
import '../../models/seerr/seerr_media.dart';
import '../../models/seerr/seerr_request.dart';
import '../../models/seerr/seerr_session.dart';
import '../../utils/app_logger.dart';
import '../seerr/seerr_client.dart';
import '../seerr/seerr_constants.dart';
import '../seerr/seerr_exceptions.dart';
import '../trackers/future_coalescer.dart';
import 'catalog_source.dart';

/// The `GET /request` status filters the requests list offers, by Seerr's own
/// filter names. Seerr has no `declined` filter: declined requests only show
/// under [all].
enum SeerrRequestFilter {
  all('all'),
  pending('pending'),
  approved('approved'),
  processing('processing'),
  available('available'),
  failed('failed');

  final String wire;
  const SeerrRequestFilter(this.wire);
}

/// Where one request stands, as a single badge: the approval state until the
/// request is approved, the acquisition state of its variant afterwards.
enum SeerrRequestBadge { pending, approved, processing, partiallyAvailable, available, declined, failed }

/// One request of the signed-in user, with the title it is for.
class SeerrRequestEntry {
  final SeerrRequest request;
  final MediaKind kind;
  final int tmdbId;
  final SeerrRequestBadge badge;

  /// The requested title, or null when its lookup failed — the request is
  /// still listed (and can still be deleted), just without title and poster.
  final CatalogItem? item;

  const SeerrRequestEntry({
    required this.request,
    required this.kind,
    required this.tmdbId,
    required this.badge,
    this.item,
  });

  bool get is4k => request.is4k ?? false;

  DateTime? get requestedAt => switch (request.createdAt) {
    final String raw => DateTime.tryParse(raw),
    null => null,
  };

  /// TV only: the requested season numbers, ascending.
  List<int> get seasonNumbers =>
      [for (final season in request.seasons ?? const <SeerrRequestSeason>[]) season.seasonNumber]..sort();

  /// What Seerr holds for this entry's title as far as the entry itself
  /// shows: its media record and this one request.
  SeerrTitleRequests get title => SeerrTitleRequests(media: request.media, requests: [request]);
}

/// One page of [SeerrRequests.fetchMine].
class SeerrRequestsPage {
  final List<SeerrRequestEntry> entries;
  final bool hasMore;

  /// Seerr's count of all requests matching the filter.
  final int? total;

  /// How many requests Seerr returned for this page, including any dropped
  /// here for lacking a usable title reference — the offset of the next page.
  final int fetched;

  const SeerrRequestsPage({required this.entries, required this.hasMore, required this.fetched, this.total});
}

/// What Seerr is known to hold for one title: its media record and the
/// requests seen for it.
class SeerrTitleRequests {
  final SeerrMediaInfo? media;
  final List<SeerrRequest> requests;

  const SeerrTitleRequests({this.media, this.requests = const []});
}

/// The signed-in Seerr user's requests: listing (with titles resolved through
/// the detail endpoints), the Explore row built from them, and the two
/// destructive actions — withdrawing a request and removing a title entirely.
///
/// Owned by `SeerrCatalogSource`, bound to its [client]. Notifies after every
/// mutation attempt so open surfaces re-read Seerr instead of trusting what
/// they showed before.
///
/// Permission checks here only decide what to *offer*. Seerr stays the
/// authority: a refused call surfaces as [SeerrPermissionException] and the
/// client has by then adopted the current permission mask.
class SeerrRequests extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// Stable id of the Explore hub ([fetchHubs]).
  static const String hubId = 'seerr.myRequests';

  /// Title lookups in flight at once while resolving a page of requests.
  static const int maxConcurrentLookups = 4;

  /// Resolved titles kept for the session (least recently used evicted).
  static const int maxCachedTitles = 300;

  final SeerrClient client;

  /// Maps a detail body to the catalog item the request surfaces render.
  final Future<CatalogItem> Function(SeerrDetails details, MediaKind kind) describe;

  SeerrRequests(this.client, {required this.describe});

  final KeyedFutureCoalescer<String, SeerrDetails> _detailLoads = KeyedFutureCoalescer();
  final KeyedFutureCoalescer<String, CatalogItem> _titleLoads = KeyedFutureCoalescer();

  /// Descriptive data only (title, artwork, year): what Seerr knows about a
  /// title's requests changes, what TMDB says about the title does not.
  final LinkedHashMap<String, CatalogItem> _titles = LinkedHashMap();
  final Map<String, SeerrTitleRequests> _known = {};

  static String _key(MediaKind kind, int tmdbId) => '${kind == MediaKind.movie ? 'movie' : 'tv'}/$tmdbId';

  static MediaKind? _kindOf(SeerrRequest request) => switch (request.type ?? request.media?.mediaType) {
    'movie' => MediaKind.movie,
    'tv' => MediaKind.show,
    _ => null,
  };

  // ---------- Permissions (what to offer) ----------

  int get _permissions => client.session.permissions;

  /// `MANAGE_REQUESTS` (or admin): may delete any request and remove media.
  bool get canManage => seerrHasPermission(_permissions, const [SeerrPermission.manageRequests]);

  /// Seerr's own rule for `DELETE /request/{id}`: managers always, everyone
  /// else only their own requests while those are still pending.
  bool canDeleteRequest(SeerrRequest request) =>
      canManage || (request.status == SeerrRequestStatus.pending && request.requestedBy?.id == client.session.userId);

  /// The variants (false = regular, true = 4K) whose files a complete removal
  /// would delete; empty when the action must not be offered.
  ///
  /// A variant counts only once Seerr has handed it to a Sonarr/Radarr
  /// instance ([SeerrMediaInfo.serviceId]) — the same condition the Seerr web
  /// UI shows its "Remove from Radarr/Sonarr" button under. Without it the
  /// file endpoint would fall back to the default instance and could delete a
  /// copy Seerr never managed. A request's `canRemove` (list responses, for
  /// managers) vetoes a variant whose instance is no longer configured.
  Set<bool> removableVariants(SeerrTitleRequests title) {
    final media = title.media;
    if (!canManage || media == null || media.id == null) return const {};
    bool removable(bool is4k) {
      if ((is4k ? media.serviceId4k : media.serviceId) == null) return false;
      final verdicts = [
        for (final request in title.requests)
          if ((request.is4k ?? false) == is4k)
            if (request.canRemove case final bool verdict) verdict,
      ];
      return verdicts.isEmpty || verdicts.contains(true);
    }

    return {if (removable(false)) false, if (removable(true)) true};
  }

  // ---------- Reads ----------

  /// The title's Seerr detail body. Calls for the same title coalesce while
  /// one is in flight; nothing is cached, so every settled call re-reads.
  Future<SeerrDetails> fetchDetails(MediaKind kind, int tmdbId) {
    final key = _key(kind, tmdbId);
    return _detailLoads.run(key, () async {
      final details = kind == MediaKind.movie ? await client.getMovie(tmdbId) : await client.getTv(tmdbId);
      final media = details.mediaInfo;
      // A detail body lists every request for the title, so it replaces
      // whatever list pages had contributed.
      _known[key] = SeerrTitleRequests(media: media, requests: media?.requests ?? const []);
      return details;
    });
  }

  /// What the last read said Seerr holds for a title, or null when no read
  /// has covered it. Synchronous on purpose: context menus build from it
  /// without a round-trip.
  SeerrTitleRequests? known(MediaKind kind, int tmdbId) => _known[_key(kind, tmdbId)];

  /// The signed-in user's requests, newest first, [take] at offset [skip].
  Future<SeerrRequestsPage> fetchMine({
    int skip = 0,
    int take = 20,
    SeerrRequestFilter filter = SeerrRequestFilter.all,
  }) async {
    final page = await client.getRequests(
      take: take,
      skip: skip,
      filter: filter.wire,
      sort: 'added',
      requestedBy: client.session.userId,
    );
    // The head of the unfiltered list is the freshest full picture there is:
    // start over rather than keep requests that may have been deleted since.
    if (skip == 0 && filter == SeerrRequestFilter.all) _known.clear();

    final located = <({SeerrRequest request, MediaKind kind, int tmdbId})>[];
    for (final request in page.items) {
      final kind = _kindOf(request);
      final tmdbId = request.media?.tmdbId;
      if (kind == null || tmdbId == null) continue;
      located.add((request: request, kind: kind, tmdbId: tmdbId));
    }

    final titles = await _resolveTitles({for (final entry in located) _key(entry.kind, entry.tmdbId): entry});
    // After the lookups: a detail body lists the title's requests without
    // their media or Seerr's `canRemove` verdict, so the list's fuller copy of
    // each request goes on top.
    for (final entry in located) {
      _remember(_key(entry.kind, entry.tmdbId), entry.request);
    }
    final product = client.session.product;
    return SeerrRequestsPage(
      entries: [
        for (final entry in located)
          SeerrRequestEntry(
            request: entry.request,
            kind: entry.kind,
            tmdbId: entry.tmdbId,
            badge: badgeFor(entry.request, product),
            item: titles[_key(entry.kind, entry.tmdbId)],
          ),
      ],
      hasMore: page.hasMore,
      total: page.totalResults,
      fetched: page.items.length,
    );
  }

  void _remember(String key, SeerrRequest request) {
    final previous = _known[key];
    _known[key] = SeerrTitleRequests(
      media: request.media ?? previous?.media,
      requests: [
        for (final other in previous?.requests ?? const <SeerrRequest>[])
          if (other.id != request.id) other,
        request,
      ],
    );
  }

  /// Title and artwork for every title in [wanted], from the session cache
  /// where possible. The rest are looked up at most [maxConcurrentLookups]
  /// at a time; a failed lookup leaves its title out (and uncached, so the
  /// next load retries it).
  Future<Map<String, CatalogItem>> _resolveTitles(
    Map<String, ({SeerrRequest request, MediaKind kind, int tmdbId})> wanted,
  ) async {
    final resolved = <String, CatalogItem>{};
    final missing = Queue<String>();
    for (final key in wanted.keys) {
      final cached = _titles.remove(key);
      if (cached == null) {
        missing.add(key);
      } else {
        _titles[key] = cached; // re-insert: most recently used
        resolved[key] = cached;
      }
    }

    Future<void> worker() async {
      while (missing.isNotEmpty) {
        final key = missing.removeFirst();
        final entry = wanted[key]!;
        try {
          final item = await _titleLoads.run(
            key,
            () async => describe(await fetchDetails(entry.kind, entry.tmdbId), entry.kind),
          );
          if (isDisposed) return;
          resolved[key] = item;
          _titles[key] = item;
          while (_titles.length > maxCachedTitles) {
            _titles.remove(_titles.keys.first);
          }
        } catch (e) {
          appLogger.w('Seerr: title lookup failed for request on $key', error: e);
        }
      }
    }

    // Sized up front: each worker takes its first title as it starts.
    final workers = math.min(maxConcurrentLookups, missing.length);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    return resolved;
  }

  /// Badge for one request. [SeerrRequestStatus.completed] is Seerr's "this
  /// request's media arrived"; an approved request reads its variant's media
  /// status to tell queued from downloading from (partly) there.
  static SeerrRequestBadge badgeFor(SeerrRequest request, SeerrProduct product) {
    final media = request.media;
    final mediaStatus = (request.is4k ?? false) ? media?.status4k(product) : media?.status(product);
    return switch (request.status) {
      SeerrRequestStatus.pending => SeerrRequestBadge.pending,
      SeerrRequestStatus.declined => SeerrRequestBadge.declined,
      SeerrRequestStatus.failed => SeerrRequestBadge.failed,
      SeerrRequestStatus.completed =>
        mediaStatus == SeerrMediaStatus.partiallyAvailable
            ? SeerrRequestBadge.partiallyAvailable
            : SeerrRequestBadge.available,
      SeerrRequestStatus.approved => switch (mediaStatus) {
        SeerrMediaStatus.available => SeerrRequestBadge.available,
        SeerrMediaStatus.partiallyAvailable => SeerrRequestBadge.partiallyAvailable,
        SeerrMediaStatus.processing => SeerrRequestBadge.processing,
        _ => SeerrRequestBadge.approved,
      },
    };
  }

  // ---------- Explore row ----------

  /// The "My requests" Explore shelf: one card per requested title, newest
  /// request first. Empty (no shelf) when the user has no requests.
  ///
  /// Always reports more, so the shelf keeps its View All affordance — that
  /// is the way into the full list with paging, filters and actions.
  Future<List<CatalogHub>> fetchHubs({int limit = 25}) async {
    final page = await fetchMine(take: limit);
    final items = rowItems(page.entries);
    if (items.isEmpty) return const [];
    return [
      CatalogHub(
        id: hubId,
        title: t.seerr.requests.myRequests,
        page: CatalogPage(items: items, hasMore: true, totalResults: page.total),
      ),
    ];
  }

  /// One page of the shelf's titles, for a generic View All grid.
  Future<CatalogPage> fetchHub(String id, {int page = 1, int limit = 25}) async {
    if (id != hubId) throw ArgumentError('Seerr does not serve hub $id');
    final result = await fetchMine(skip: (page - 1) * limit, take: limit);
    return CatalogPage(items: rowItems(result.entries), hasMore: result.hasMore, totalResults: result.total);
  }

  /// Entries as shelf cards: one per title (several requests for one title —
  /// regular and 4K, or separate seasons — share a card), in the order of
  /// each title's newest request. The card's server state is rebuilt from the
  /// requests themselves, so the existing catalog badges show request status
  /// without the cached title data going stale. Unresolved titles are left
  /// out; they have nothing to draw.
  static List<CatalogItem> rowItems(List<SeerrRequestEntry> entries) {
    final byTitle = <String, List<SeerrRequestEntry>>{};
    for (final entry in entries) {
      if (entry.item == null) continue;
      byTitle.putIfAbsent(_key(entry.kind, entry.tmdbId), () => []).add(entry);
    }
    return [
      for (final group in byTitle.values)
        withServerState(group.first.item!, serverStateFor(group), addedAt: group.first.requestedAt),
    ];
  }

  /// The catalog server state a title's requests add up to. Newest request
  /// wins per slot; regular and 4K keep separate slots.
  static CatalogServerState? serverStateFor(List<SeerrRequestEntry> entries) {
    CatalogAvailability? availability;
    CatalogAvailability? availability4k;
    CatalogRequestState? request;
    CatalogRequestState? request4k;
    for (final entry in entries) {
      final available = switch (entry.badge) {
        SeerrRequestBadge.available => CatalogAvailability.available,
        SeerrRequestBadge.partiallyAvailable => CatalogAvailability.partiallyAvailable,
        _ => null,
      };
      final state = switch (entry.badge) {
        SeerrRequestBadge.pending => CatalogRequestState.pending,
        SeerrRequestBadge.approved => CatalogRequestState.approved,
        SeerrRequestBadge.processing => CatalogRequestState.processing,
        SeerrRequestBadge.declined => CatalogRequestState.declined,
        SeerrRequestBadge.failed => CatalogRequestState.failed,
        SeerrRequestBadge.available || SeerrRequestBadge.partiallyAvailable => null,
      };
      if (entry.is4k) {
        availability4k ??= available;
        request4k ??= state;
      } else {
        availability ??= available;
        request ??= state;
      }
    }
    final result = CatalogServerState(
      availability: availability,
      availability4k: availability4k,
      request: request,
      request4k: request4k,
    );
    return result.isEmpty ? null : result;
  }

  /// [item] with its server state replaced (dropped for null), through the
  /// same JSON form catalog cards already round-trip.
  static CatalogItem withServerState(CatalogItem item, CatalogServerState? state, {DateTime? addedAt}) {
    final json = item.toJson()..remove('serverState');
    if (state != null) json['serverState'] = state.toJson();
    if (addedAt != null) json['addedAt'] = addedAt.toIso8601String();
    return CatalogItem.fromJson(json);
  }

  // ---------- Mutations ----------

  /// Withdraw [request] (`DELETE /request/{id}`).
  Future<void> deleteRequest(SeerrRequest request) async {
    try {
      await client.deleteRequest(request.id);
    } finally {
      _afterMutation();
    }
  }

  /// Remove a title completely: delete it — **files included** — from the
  /// Sonarr/Radarr instance of every variant in [variants], then clear
  /// Seerr's record of it along with all its requests.
  ///
  /// The media record is only cleared once every file removal went through,
  /// so a refusal (no instance configured, permission) leaves Seerr's view
  /// intact instead of orphaning files it no longer knows about. A 404 from
  /// the file step means the record is already gone and is not an error.
  Future<void> removeCompletely({required int mediaId, required Set<bool> variants}) async {
    try {
      for (final is4k in const [false, true]) {
        if (!variants.contains(is4k)) continue;
        try {
          await client.deleteMediaFile(mediaId, is4k: is4k);
        } on SeerrApiException catch (e) {
          if (e.statusCode != 404) rethrow;
        }
      }
      await client.deleteMedia(mediaId);
    } finally {
      _afterMutation();
    }
  }

  /// Whatever the outcome, what was known is now suspect: a failure can
  /// still have changed Seerr (one variant removed before the next refused).
  void _afterMutation() {
    _known.clear();
    safeNotifyListeners();
  }
}
