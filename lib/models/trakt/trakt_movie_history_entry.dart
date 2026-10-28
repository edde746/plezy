import 'trakt_ids.dart';

/// One movie play from Trakt's user history endpoint.
class TraktMovieHistoryEntry {
  final String? historyId;
  final DateTime? watchedAt;
  final String? title;
  final int? year;
  final TraktIds ids;

  const TraktMovieHistoryEntry({
    required this.historyId,
    required this.watchedAt,
    required this.title,
    required this.year,
    required this.ids,
  });

  factory TraktMovieHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawMovie = json['movie'];
    final movie = rawMovie is Map ? Map<String, dynamic>.from(rawMovie) : const <String, dynamic>{};
    final rawIds = movie['ids'];
    final ids = rawIds is Map ? TraktIds.fromJson(Map<String, dynamic>.from(rawIds)) : const TraktIds();
    final rawDate = json['watched_at'];
    final rawYear = movie['year'];

    return TraktMovieHistoryEntry(
      historyId: json['id']?.toString(),
      watchedAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
      title: movie['title'] is String ? movie['title'] as String : null,
      year: rawYear is num ? rawYear.toInt() : int.tryParse(rawYear?.toString() ?? ''),
      ids: ids,
    );
  }
}
