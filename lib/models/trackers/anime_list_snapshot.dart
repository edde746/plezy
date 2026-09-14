/// Pre-write snapshot of the viewer's list entry for one anime on a
/// series-progress tracker (MAL, AniList), fetched in the same request as the
/// episode count so preserving rewatch state costs no extra call (issue #2026).
class AnimeListSnapshot {
  /// Total episodes when the service knows it; null while airing or unknown.
  final int? episodeCount;

  /// The entry is an in-progress rewatch (AniList `REPEATING`,
  /// MAL `is_rewatching`).
  final bool rewatching;

  /// The entry's list status is completed (AniList `COMPLETED`,
  /// MAL `completed`).
  final bool completed;

  /// Finished rewatch count (AniList `repeat`, MAL `num_times_rewatched`).
  /// Zero when the entry is absent or the service omitted the field.
  final int rewatchCount;

  const AnimeListSnapshot({this.episodeCount, this.rewatching = false, this.completed = false, this.rewatchCount = 0});
}
