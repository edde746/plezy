import 'dart:math' as math;

import 'package:string_similarity/string_similarity.dart';

import '../media/media_item.dart';

const int defaultMediaSearchLimit = 100;

List<MediaItem> rankMediaSearchResults(List<MediaItem> items, String query, {int? limit}) {
  final normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return limit == null ? List<MediaItem>.of(items) : items.take(limit).toList();
  }

  final ranked = <_RankedMediaItem>[
    for (var i = 0; i < items.length; i++)
      _RankedMediaItem(item: items[i], score: mediaSearchRelevanceScore(items[i], normalizedQuery), originalIndex: i),
  ];

  ranked.sort((a, b) {
    final scoreComparison = b.score.compareTo(a.score);
    if (scoreComparison != 0) return scoreComparison;
    return a.originalIndex.compareTo(b.originalIndex);
  });

  final result = ranked.map((entry) => entry.item);
  return limit == null ? result.toList() : result.take(limit).toList();
}

double mediaSearchRelevanceScore(MediaItem item, String query) {
  final normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) return 0;
  final fields = <({String? value, double weight})>[
    (value: item.title, weight: 1.0),
    (value: item.titleSort, weight: 0.98),
    (value: item.originalTitle, weight: 0.96),
    (value: item.grandparentTitle, weight: 0.9),
    (value: item.parentTitle, weight: 0.8),
  ];

  var best = 0.0;
  for (final field in fields) {
    final candidate = normalizeSearchText(field.value);
    if (candidate.isEmpty) continue;
    best = math.max(best, _scoreNormalizedField(normalizedQuery, candidate) * field.weight);
  }
  return best;
}

String normalizeSearchText(String? value) {
  if (value == null) return '';
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0000-\u002f\u003a-\u0040\u005b-\u0060\u007b-\u007f]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double _scoreNormalizedField(String query, String candidate) {
  if (candidate == query) return 1000;

  final queryWithoutArticle = _withoutLeadingArticle(query);
  final candidateWithoutArticle = _withoutLeadingArticle(candidate);
  if (queryWithoutArticle.isNotEmpty && candidateWithoutArticle == queryWithoutArticle) return 980;

  if (candidate.startsWith(query)) return 900 + _lengthCloseness(query, candidate, 50);
  if (queryWithoutArticle.isNotEmpty && candidateWithoutArticle.startsWith(queryWithoutArticle)) {
    return 880 + _lengthCloseness(queryWithoutArticle, candidateWithoutArticle, 50);
  }

  if (candidate.contains(query)) return 800 + _lengthCloseness(query, candidate, 50);

  final queryTokens = _tokens(query);
  final candidateTokens = _tokens(candidate);
  if (queryTokens.isEmpty || candidateTokens.isEmpty) return 0;

  final candidateTokenSet = candidateTokens.toSet();
  final matchingTokens = queryTokens.where(candidateTokenSet.contains).length;
  final sortedQuery = _sortedTokens(queryTokens);
  final sortedCandidate = _sortedTokens(candidateTokens);
  final tokenSimilarity = StringSimilarity.compareTwoStrings(sortedQuery, sortedCandidate);
  final rawSimilarity = StringSimilarity.compareTwoStrings(query, candidate);
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

String _withoutLeadingArticle(String value) {
  for (final article in const ['the ', 'a ', 'an ']) {
    if (value.startsWith(article)) return value.substring(article.length);
  }
  return value;
}

double _lengthCloseness(String query, String candidate, double maxBonus) {
  final longest = math.max(query.length, candidate.length);
  if (longest == 0) return 0;
  final distance = (candidate.length - query.length).abs();
  final closeness = math.max(0.0, math.min(1.0, 1 - distance / longest));
  return maxBonus * closeness;
}

class _RankedMediaItem {
  const _RankedMediaItem({required this.item, required this.score, required this.originalIndex});

  final MediaItem item;
  final double score;
  final int originalIndex;
}
