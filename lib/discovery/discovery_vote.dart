import 'discovery_choice.dart';

/// Privacy-preserving consensus for ballots collected on one device.
///
/// Scores are in-memory only and never become discovery preferences. Missing
/// votes and explicit vetoes make a candidate ineligible; eligible candidates
/// use maximin agreement, then total score, then original shortlist order.
abstract final class DiscoveryShortlistConsensus {
  static DiscoveryChoice? chooseWinner({
    required List<DiscoveryChoice> choices,
    required List<Map<String, int>> ballots,
  }) {
    DiscoveryChoice? best;
    var bestMinimum = -1;
    var bestTotal = -1;
    for (final candidate in choices) {
      final ratings = ballots.map((ballot) => ballot[candidate.id] ?? 0).toList(growable: false);
      if (ratings.isEmpty || ratings.any((rating) => rating < 1 || rating > 2)) continue;
      final minimum = ratings.reduce((a, b) => a < b ? a : b);
      final total = ratings.fold<int>(0, (sum, rating) => sum + rating);
      if (minimum > bestMinimum || (minimum == bestMinimum && total > bestTotal)) {
        best = candidate;
        bestMinimum = minimum;
        bestTotal = total;
      }
    }
    return best;
  }
}
