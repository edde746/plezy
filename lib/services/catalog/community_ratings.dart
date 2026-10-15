import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';

import '../../media/media_kind.dart';
import '../../media/media_rating.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/app_logger.dart';
import '../trackers/future_coalescer.dart';
import 'catalog_source.dart';

/// One provider's community scores for a title.
typedef CommunityRatingsAnswer = ({CatalogSourceId origin, List<MediaRatingSource> ratings});

/// The order scores are shown in: Rotten Tomatoes' two panels, IMDb, TMDB,
/// Metacritic and Letterboxd, then the trackers' own. Sources outside it
/// (Plex's and Jellyfin's unattributed `critic`/`audience`) follow in their
/// own order.
const List<String> _displayOrder = [
  'rottenTomatoesCritic',
  'rottenTomatoesAudience',
  'imdb',
  'tmdb',
  'metacritic',
  'letterboxd',
  'trakt',
  'simkl',
  'mal',
  'anilist',
];

/// The source key a provider files its own score under; null for MDBList,
/// which reports only other sites' scores.
String? communityRatingKeyFor(CatalogSourceId id) => switch (id) {
  CatalogSourceId.trakt => 'trakt',
  CatalogSourceId.simkl => 'simkl',
  CatalogSourceId.mal => 'mal',
  CatalogSourceId.anilist => 'anilist',
  _ => null,
};

/// One score per source from every answer, in display order. The source's own
/// provider wins (Trakt's score from Trakt, MyAnimeList's from MyAnimeList),
/// then MDBList — the aggregator, which refreshes every score daily — then
/// Simkl, then anyone else.
List<MediaRatingSource> mergeCommunityRatings(Iterable<CommunityRatingsAnswer> answers) {
  final best = <String, ({int precedence, MediaRatingSource rating})>{};
  for (final answer in answers) {
    for (final rating in answer.ratings) {
      final precedence = _precedence(rating.source, answer.origin);
      final current = best[rating.source];
      if (current == null || precedence < current.precedence) {
        best[rating.source] = (precedence: precedence, rating: rating);
      }
    }
  }
  return _inDisplayOrder([for (final entry in best.values) entry.rating]);
}

int _precedence(String source, CatalogSourceId origin) {
  if (communityRatingKeyFor(origin) == source) return 0;
  return switch (origin) {
    CatalogSourceId.mdblist => 1,
    CatalogSourceId.simkl => 2,
    _ => 3,
  };
}

/// [own] — a title's scores from its media server or catalog provider — with
/// [community] merged in, in display order. A community score replaces
/// [own]'s score from the same source: the server's copy is whatever its
/// metadata agent last cached. [own] is returned as is while [community] is
/// empty.
List<MediaRatingSource> withCommunityRatings(List<MediaRatingSource> own, List<MediaRatingSource> community) {
  if (community.isEmpty) return own;
  final covered = {for (final rating in community) _identity(rating.source)};
  return _inDisplayOrder([
    ...community,
    for (final rating in own)
      if (!covered.contains(_identity(rating.source))) rating,
  ]);
}

/// Plex's unsplit Rotten Tomatoes key is the Tomatometer.
String _identity(String source) => source == 'rottenTomatoes' ? 'rottenTomatoesCritic' : source;

List<MediaRatingSource> _inDisplayOrder(List<MediaRatingSource> ratings) {
  int rank(MediaRatingSource rating) {
    final index = _displayOrder.indexOf(_identity(rating.source));
    return index < 0 ? _displayOrder.length : index;
  }

  // Stable, so sources outside the order keep theirs.
  mergeSort(ratings, compare: (a, b) => rank(a).compareTo(rank(b)));
  return ratings;
}

/// Asks every [CatalogCommunityRatings] provider for a title's scores at once
/// and keeps each answer per provider and title for [ttl] (the services
/// refresh their scores daily at most), the [capacity] most recently used. A
/// title a provider does not know is kept as such; a failed request is
/// logged, leaves that provider out and is not kept, so the next visit asks
/// again.
class CommunityRatingsLoader {
  static const Duration ttl = Duration(hours: 12);
  static const int capacity = 300;

  /// Least recently used first.
  final LinkedHashMap<String, ({List<MediaRatingSource> ratings, DateTime at})> _cache = LinkedHashMap();
  final KeyedFutureCoalescer<String, List<MediaRatingSource>> _loads = KeyedFutureCoalescer();

  /// The merged scores ([mergeCommunityRatings]) of every
  /// [CatalogCommunityRatings] provider in [sources] for a [kind] title,
  /// emitted again each time another provider adds some. [idsFor] names the
  /// title in one provider's ids; null leaves that provider out (the title is
  /// outside its domain). Emits nothing when no provider has a score and
  /// closes once every provider answered. Work starts on listen.
  Stream<List<MediaRatingSource>> load(
    MediaKind kind,
    List<CatalogSource> sources,
    Future<CatalogItemIds?> Function(CatalogSource source) idsFor,
  ) {
    final providers = [
      for (final source in sources)
        if (source is CatalogCommunityRatings) source,
    ];
    late final StreamController<List<MediaRatingSource>> controller;
    controller = StreamController(
      onListen: () {
        if (providers.isEmpty) {
          unawaited(controller.close());
          return;
        }
        final answers = <CommunityRatingsAnswer>[];
        var pending = providers.length;
        for (final source in providers) {
          unawaited(
            _answer(kind, source, idsFor)
                .then((ratings) {
                  if (ratings.isEmpty || !controller.hasListener) return;
                  answers.add((origin: source.id, ratings: ratings));
                  controller.add(mergeCommunityRatings(answers));
                })
                .whenComplete(() {
                  if (--pending == 0) unawaited(controller.close());
                }),
          );
        }
      },
    );
    return controller.stream;
  }

  Future<List<MediaRatingSource>> _answer(
    MediaKind kind,
    CatalogSource source,
    Future<CatalogItemIds?> Function(CatalogSource source) idsFor,
  ) async {
    try {
      final ids = await idsFor(source);
      if (ids == null || !ids.hasAny) return const [];
      return await _cached(kind, source, ids);
    } catch (e, stackTrace) {
      appLogger.d('Community ratings from ${source.id.name} left out', error: e, stackTrace: stackTrace);
      return const [];
    }
  }

  Future<List<MediaRatingSource>> _cached(MediaKind kind, CatalogSource source, CatalogItemIds ids) {
    final key = '${source.id.name}/${kind.id}/${ids.allKeys.join(',')}';
    final entry = _cache.remove(key);
    if (entry != null && clock.now().difference(entry.at) < ttl) {
      _cache[key] = entry;
      return Future.value(entry.ratings);
    }
    return _loads.run(key, () async {
      final ratings = await (source as CatalogCommunityRatings).fetchCommunityRatings(kind, ids);
      _cache[key] = (ratings: ratings, at: clock.now());
      while (_cache.length > capacity) {
        _cache.remove(_cache.keys.first);
      }
      return ratings;
    });
  }
}
