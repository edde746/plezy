import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:unorm_dart/unorm_dart.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_person.dart';
import '../media/search_hit.dart';

const int defaultMediaSearchLimit = 100;

final RegExp _searchSeparatorPattern = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

List<MediaItem> rankMediaSearchResults(List<MediaItem> items, String query, {int? limit}) =>
    _rankBySearchRelevance(items, query, _mediaScore, limit: limit);

List<MediaPerson> rankPeopleSearchResults(List<MediaPerson> people, String query, {int? limit}) =>
    _rankBySearchRelevance(people, query, _personScore, limit: limit);

/// Titles and people on one scale; see [_personNameWeight] for how the two
/// compare. Equal scores keep input order, so a caller that lists titles first
/// breaks ties toward titles.
List<SearchHit> rankSearchHits(List<SearchHit> hits, String query, {int? limit}) =>
    _rankBySearchRelevance(hits, query, _hitScore, limit: limit);

List<T> _rankBySearchRelevance<T>(
  List<T> items,
  String query,
  double Function(T item, _NormalizedSearchQuery query) scoreOf, {
  int? limit,
}) {
  if (limit != null) {
    RangeError.checkNotNegative(limit, 'limit');
    if (limit == 0) return const [];
  }
  if (items.isEmpty) return const [];

  final searchQuery = _NormalizedSearchQuery(query);
  if (searchQuery.text.isEmpty) {
    return limit == null ? List<T>.of(items) : items.take(limit).toList();
  }

  if (limit == null || limit >= items.length) {
    final ranked = <_Ranked<T>>[
      for (var i = 0; i < items.length; i++)
        _Ranked(item: items[i], score: scoreOf(items[i], searchQuery), originalIndex: i),
    ]..sort(_compareRankedBestFirst);
    return [for (final entry in ranked) entry.item];
  }

  final retained = HeapPriorityQueue<_Ranked<T>>(_compareRankedWorstFirst);
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final score = scoreOf(item, searchQuery);
    if (retained.length < limit) {
      retained.add(_Ranked(item: item, score: score, originalIndex: i));
      continue;
    }

    final worst = retained.first;
    if (score > worst.score || (score == worst.score && i < worst.originalIndex)) {
      retained
        ..removeFirst()
        ..add(_Ranked(item: item, score: score, originalIndex: i));
    }
  }

  final ranked = retained.toList()..sort(_compareRankedBestFirst);
  return [for (final entry in ranked) entry.item];
}

double _hitScore(SearchHit hit, _NormalizedSearchQuery query) => switch (hit) {
  MediaSearchHit(:final item) => _mediaScore(item, query),
  PersonSearchHit(:final person) => _personScore(person, query),
};

double _mediaScore(MediaItem item, _NormalizedSearchQuery query) {
  var best = query.score(item.title, 1.0);
  best = math.max(best, query.score(item.titleSort, 0.98));
  best = math.max(best, query.score(item.originalTitle, 0.96));
  best = math.max(best, query.score(item.grandparentTitle, 0.9));
  best = math.max(best, query.score(item.parentTitle, _parentWeight(item)));
  return best;
}

/// `parentTitle` holds a season on an episode and an album on a track — weak
/// containers, worth 0.8 — but on an *album* row it holds the artist, which is
/// the same signal a track carries in `grandparentTitle`. Weighting an album's
/// artist as if it were a season is what put a mashup above the artist's own
/// records: both matched, and the album's match was discounted for sitting in
/// the wrong slot of a model that was designed around television.
double _parentWeight(MediaItem item) => item.kind == MediaKind.album ? 0.9 : 0.8;

/// A person ranks below every title matched the same way, and above anything
/// matched a weaker way. Names are shorter than titles, so on closeness alone
/// "Rick" put every actor named Rick above *Rick and Morty*. Dropping a person
/// one whole within-tier step keeps the kind of match in charge: an exact name
/// still beats every partial title, and a name prefix beats a title that merely
/// contains the query.
double _personScore(MediaPerson person, _NormalizedSearchQuery query) {
  final score = query.score(person.name, 1.0);
  return score == 0 ? 0 : score - _withinStride - _weightStride;
}

/// Produces an accent-sensitive search key where canonical/compatibility
/// equivalents and Unicode typography compare alike.
String normalizeSearchText(String? value) {
  if (value == null) return '';
  return nfkc(value).toLowerCase().replaceAll(_searchSeparatorPattern, ' ').trim();
}

/// How strongly a field matched, worst to best. The ordinal is the score's
/// leading term, so a stronger kind of match always wins **whatever field it
/// landed on**.
///
/// That separation is the point. The score used to be one number multiplied by
/// the field's weight, which let a discount jump a tier: an exact hit on a
/// 0.8-weight field scored 800, below a bare substring hit on a 1.0-weight
/// field (800 + a closeness bonus). Searching an artist's name therefore put
/// two mashups whose titles happen to contain the word — substring hits on the
/// title — above twenty-one albums by that exact artist, and on a phone with
/// the keyboard up only the mashups were on screen. Weight now only ranks
/// fields *within* a tier; it can no longer overturn one.
enum _MatchTier { fuzzy, someTokens, allTokens, contains, prefix, exact }

/// Tiers are three orders of magnitude apart so nothing below can reach them.
const double _tierStride = 1e9;

/// Within a tier, how close the match is — scaled by the field's weight, so a
/// near-perfect hit on a secondary field can still beat a poor one on the
/// title without either escaping the tier.
const double _withinStride = 1e6;

/// Breaks a within-tier draw (notably the exact tier, where there is nothing
/// left to measure) in favour of the more important field.
const double _weightStride = 1e3;

double _fieldScore(_MatchTier tier, double within, double weight) =>
    tier.index * _tierStride + within * weight * _withinStride + weight * _weightStride;

double _scoreNormalizedField(_NormalizedSearchQuery query, String candidate, double weight) {
  if (candidate == query.text) return _fieldScore(_MatchTier.exact, 1, weight);

  if (candidate.startsWith(query.text)) {
    return _fieldScore(_MatchTier.prefix, _lengthCloseness(query.text, candidate), weight);
  }

  if (candidate.contains(query.text)) {
    return _fieldScore(_MatchTier.contains, _lengthCloseness(query.text, candidate), weight);
  }

  final queryTokens = query.tokens;
  final candidateTokens = _tokens(candidate);
  if (queryTokens.isEmpty || candidateTokens.isEmpty) return 0;

  final candidateTokenSet = candidateTokens.toSet();
  final matchingTokens = queryTokens.where(candidateTokenSet.contains).length;
  final sortedCandidate = _sortedTokens(candidateTokens);
  final tokenSimilarity = StringSimilarity.compareTwoStrings(query.sortedTokens, sortedCandidate);
  final rawSimilarity = StringSimilarity.compareTwoStrings(query.text, candidate);
  final similarity = math.max(rawSimilarity, tokenSimilarity);

  if (matchingTokens == queryTokens.length) {
    return _fieldScore(_MatchTier.allTokens, tokenSimilarity, weight);
  }
  if (matchingTokens > 0) {
    return _fieldScore(_MatchTier.someTokens, math.max(matchingTokens / queryTokens.length, similarity), weight);
  }

  return _fieldScore(_MatchTier.fuzzy, similarity, weight);
}

List<String> _tokens(String value) => value.split(' ').where((token) => token.isNotEmpty).toList();

String _sortedTokens(List<String> tokens) {
  final sorted = List<String>.of(tokens)..sort();
  return sorted.join(' ');
}

/// 1 when the two are the same length, falling to 0 as the candidate outgrows
/// the query — the difference between "Target" and "A Target Story".
double _lengthCloseness(String query, String candidate) {
  final longest = math.max(query.length, candidate.length);
  if (longest == 0) return 0;
  final distance = (candidate.length - query.length).abs();
  return math.max(0.0, math.min(1.0, 1 - distance / longest));
}

int _compareRankedBestFirst<T>(_Ranked<T> a, _Ranked<T> b) {
  final scoreComparison = b.score.compareTo(a.score);
  if (scoreComparison != 0) return scoreComparison;
  return a.originalIndex.compareTo(b.originalIndex);
}

int _compareRankedWorstFirst<T>(_Ranked<T> a, _Ranked<T> b) {
  final scoreComparison = a.score.compareTo(b.score);
  if (scoreComparison != 0) return scoreComparison;
  return b.originalIndex.compareTo(a.originalIndex);
}

class _NormalizedSearchQuery {
  _NormalizedSearchQuery(String value) : text = normalizeSearchText(value);

  final String text;
  late final List<String> tokens = _tokens(text);
  late final String sortedTokens = _sortedTokens(tokens);

  /// Relevance of [value] to this query: the kind of match first, then how
  /// close it is, with [weight] ranking fields within one kind.
  double score(String? value, double weight) {
    final candidate = normalizeSearchText(value);
    if (candidate.isEmpty) return 0;
    return _scoreNormalizedField(this, candidate, weight);
  }
}

class _Ranked<T> {
  const _Ranked({required this.item, required this.score, required this.originalIndex});

  final T item;
  final double score;
  final int originalIndex;
}
