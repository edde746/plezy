/// Seerr's MediaStatus enum (per Overseerr lineage's `lib/constants/media.ts`):
///   1 = UNKNOWN, 2 = PENDING, 3 = PROCESSING,
///   4 = PARTIALLY_AVAILABLE, 5 = AVAILABLE
///
/// Note: the docs are ambiguous between forks on 4/5 ordering. Plezy treats
/// the constants below as canonical and reconfirms against the user's live
/// server during smoke-testing. If mismatch is observed, swap [partiallyAvailable]
/// and [available] integer values and update the test fixture.
enum SeerrMediaStatus {
  unknown(1),
  pending(2),
  processing(3),
  partiallyAvailable(4),
  available(5);

  final int value;
  const SeerrMediaStatus(this.value);

  static SeerrMediaStatus fromValue(int? raw) {
    return switch (raw) {
      2 => SeerrMediaStatus.pending,
      3 => SeerrMediaStatus.processing,
      4 => SeerrMediaStatus.partiallyAvailable,
      5 => SeerrMediaStatus.available,
      _ => SeerrMediaStatus.unknown,
    };
  }
}

/// Per-season library state — `mediaInfo.seasons[]` on a TV detail response.
/// Tells the user which seasons are already available / pending so they can
/// skip them when picking what to request.
class SeerrSeasonStatus {
  final int seasonNumber;
  final SeerrMediaStatus status;
  final SeerrMediaStatus status4k;

  const SeerrSeasonStatus({
    required this.seasonNumber,
    this.status = SeerrMediaStatus.unknown,
    this.status4k = SeerrMediaStatus.unknown,
  });

  factory SeerrSeasonStatus.fromJson(Map<String, dynamic> json) {
    return SeerrSeasonStatus(
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
      status: SeerrMediaStatus.fromValue((json['status'] as num?)?.toInt()),
      status4k: SeerrMediaStatus.fromValue((json['status4k'] as num?)?.toInt()),
    );
  }
}

/// Per-title library state attached to discover/search/detail results. Seerr
/// returns `mediaInfo: null` for titles it has never tracked; presence implies
/// at least one request or library hit.
class SeerrMediaInfo {
  final int id;
  final int? tmdbId;
  final int? tvdbId;
  final SeerrMediaStatus status;
  final SeerrMediaStatus status4k;
  final List<SeerrSeasonStatus> seasons;

  const SeerrMediaInfo({
    required this.id,
    this.tmdbId,
    this.tvdbId,
    this.status = SeerrMediaStatus.unknown,
    this.status4k = SeerrMediaStatus.unknown,
    this.seasons = const [],
  });

  factory SeerrMediaInfo.fromJson(Map<String, dynamic> json) {
    final rawSeasons = json['seasons'];
    final seasons = <SeerrSeasonStatus>[];
    if (rawSeasons is List) {
      for (final s in rawSeasons) {
        if (s is Map<String, dynamic>) seasons.add(SeerrSeasonStatus.fromJson(s));
      }
    }
    return SeerrMediaInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tmdbId: (json['tmdbId'] as num?)?.toInt(),
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      status: SeerrMediaStatus.fromValue((json['status'] as num?)?.toInt()),
      status4k: SeerrMediaStatus.fromValue((json['status4k'] as num?)?.toInt()),
      seasons: seasons,
    );
  }

  /// Lookup status for a given season number (defaults to unknown when the
  /// season isn't tracked at all yet).
  SeerrMediaStatus seasonStatus(int seasonNumber, {bool is4k = false}) {
    final entry = seasons.where((s) => s.seasonNumber == seasonNumber).firstOrNull;
    if (entry == null) return SeerrMediaStatus.unknown;
    return is4k ? entry.status4k : entry.status;
  }
}

extension on Iterable<SeerrSeasonStatus> {
  SeerrSeasonStatus? get firstOrNull => isEmpty ? null : first;
}
