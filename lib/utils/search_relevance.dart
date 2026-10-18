import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:unorm_dart/unorm_dart.dart';

import '../media/media_item.dart';
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
  best = math.max(best, query.score(item.parentTitle, 0.8));
  return best;
}

/// A person's name scores 95% of a title's. Within one match class (prefix,
/// substring, tokens) the shorter candidate earns the higher closeness bonus,
/// and names are shorter than titles, so at full weight "Rick" ranked every
/// actor named Rick above *Rick and Morty*. At 0.95 a title beats a person in
/// the same class, while an exact name (950) still beats every partial title
/// match (a prefix peaks just under 950), and a name prefix still beats a
/// title that merely contains the query.
const double _personNameWeight = 0.95;

double _personScore(MediaPerson person, _NormalizedSearchQuery query) => query.score(person.name, _personNameWeight);

/// Produces an accent-sensitive search key where canonical/compatibility
/// equivalents and Unicode typography compare alike.
String normalizeSearchText(String? value) {
  if (value == null) return '';
  return nfkc(value).toLowerCase().replaceAll(_searchSeparatorPattern, ' ').trim();
}

double _scoreNormalizedField(_NormalizedSearchQuery query, String candidate) {
  if (candidate == query.text) return 1000;

  if (candidate.startsWith(query.text)) return 900 + _lengthCloseness(query.text, candidate, 50);

  if (candidate.contains(query.text)) return 800 + _lengthCloseness(query.text, candidate, 50);

  final queryTokens = query.tokens;
  final candidateTokens = _tokens(candidate);
  if (queryTokens.isEmpty || candidateTokens.isEmpty) return 0;

  final candidateTokenSet = candidateTokens.toSet();
  final matchingTokens = queryTokens.where(candidateTokenSet.contains).length;
  final sortedCandidate = _sortedTokens(candidateTokens);
  final tokenSimilarity = StringSimilarity.compareTwoStrings(query.sortedTokens, sortedCandidate);
  final rawSimilarity = StringSimilarity.compareTwoStrings(query.text, candidate);
  final fuzzyScore = math.max(rawSimilarity, tokenSimilarity) * 650;

  if (matchingTokens == queryTokens.length) return math.max(700 + tokenSimilarity * 100, fuzzyScore);
  if (matchingTokens > 0) return math.max(400 + (matchingTokens / queryTokens.length) * 100, fuzzyScore);

  return fuzzyScore;
}

List<String> _tokens(String value) => value.split(' ').where((token) => token.isNotEmpty).toList();

String _sortedTokens(List<String> tokens) {
  final sorted = List<String>.of(tokens)..sort();
  return sorted.join(' ');
}

double _lengthCloseness(String query, String candidate, double maxBonus) {
  final longest = math.max(query.length, candidate.length);
  if (longest == 0) return 0;
  final distance = (candidate.length - query.length).abs();
  final closeness = math.max(0.0, math.min(1.0, 1 - distance / longest));
  return maxBonus * closeness;
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

  /// Relevance of [value] to this query on the 0–1000 scale, times [weight].
  double score(String? value, double weight) {
    final candidate = normalizeSearchText(value);
    if (candidate.isEmpty) return 0;
    return _scoreNormalizedField(this, candidate) * weight;
  }
}

class _Ranked<T> {
  const _Ranked({required this.item, required this.score, required this.originalIndex});

  final T item;
  final double score;
  final int originalIndex;
}
