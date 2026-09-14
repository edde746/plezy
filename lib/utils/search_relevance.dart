import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:unorm_dart/unorm_dart.dart';

import '../media/media_item.dart';

const int defaultMediaSearchLimit = 100;

final RegExp _searchSeparatorPattern = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

List<MediaItem> rankMediaSearchResults(List<MediaItem> items, String query, {int? limit}) {
  if (limit != null) {
    RangeError.checkNotNegative(limit, 'limit');
    if (limit == 0) return const [];
  }
  if (items.isEmpty) return const [];

  final searchQuery = _NormalizedSearchQuery(query);
  if (searchQuery.text.isEmpty) {
    return limit == null ? List<MediaItem>.of(items) : items.take(limit).toList();
  }

  if (limit == null || limit >= items.length) {
    final ranked = <_RankedMediaItem>[
      for (var i = 0; i < items.length; i++)
        _RankedMediaItem(
          item: items[i],
          score: _mediaSearchRelevanceScoreNormalized(items[i], searchQuery),
          originalIndex: i,
        ),
    ]..sort(_compareRankedBestFirst);
    return [for (final entry in ranked) entry.item];
  }

  final retained = HeapPriorityQueue<_RankedMediaItem>(_compareRankedWorstFirst);
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final score = _mediaSearchRelevanceScoreNormalized(item, searchQuery);
    if (retained.length < limit) {
      retained.add(_RankedMediaItem(item: item, score: score, originalIndex: i));
      continue;
    }

    final worst = retained.first;
    if (score > worst.score || (score == worst.score && i < worst.originalIndex)) {
      retained
        ..removeFirst()
        ..add(_RankedMediaItem(item: item, score: score, originalIndex: i));
    }
  }

  final ranked = retained.toList()..sort(_compareRankedBestFirst);
  return [for (final entry in ranked) entry.item];
}

double _mediaSearchRelevanceScoreNormalized(MediaItem item, _NormalizedSearchQuery query) {
  var best = _scoreWeightedField(item.title, query, 1.0);
  best = math.max(best, _scoreWeightedField(item.titleSort, query, 0.98));
  best = math.max(best, _scoreWeightedField(item.originalTitle, query, 0.96));
  best = math.max(best, _scoreWeightedField(item.grandparentTitle, query, 0.9));
  best = math.max(best, _scoreWeightedField(item.parentTitle, query, 0.8));
  return best;
}

double _scoreWeightedField(String? value, _NormalizedSearchQuery query, double weight) {
  final candidate = normalizeSearchText(value);
  if (candidate.isEmpty) return 0;
  return _scoreNormalizedField(query, candidate) * weight;
}

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

int _compareRankedBestFirst(_RankedMediaItem a, _RankedMediaItem b) {
  final scoreComparison = b.score.compareTo(a.score);
  if (scoreComparison != 0) return scoreComparison;
  return a.originalIndex.compareTo(b.originalIndex);
}

int _compareRankedWorstFirst(_RankedMediaItem a, _RankedMediaItem b) {
  final scoreComparison = a.score.compareTo(b.score);
  if (scoreComparison != 0) return scoreComparison;
  return b.originalIndex.compareTo(a.originalIndex);
}

class _NormalizedSearchQuery {
  _NormalizedSearchQuery(String value) : text = normalizeSearchText(value);

  final String text;
  late final List<String> tokens = _tokens(text);
  late final String sortedTokens = _sortedTokens(tokens);
}

class _RankedMediaItem {
  const _RankedMediaItem({required this.item, required this.score, required this.originalIndex});

  final MediaItem item;
  final double score;
  final int originalIndex;
}
