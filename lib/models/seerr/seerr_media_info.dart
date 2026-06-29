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

/// Per-title library state attached to discover/search/detail results. Seerr
/// returns `mediaInfo: null` for titles it has never tracked; presence implies
/// at least one request or library hit.
class SeerrMediaInfo {
  final int id;
  final int? tmdbId;
  final int? tvdbId;
  final SeerrMediaStatus status;
  final SeerrMediaStatus status4k;

  const SeerrMediaInfo({
    required this.id,
    this.tmdbId,
    this.tvdbId,
    this.status = SeerrMediaStatus.unknown,
    this.status4k = SeerrMediaStatus.unknown,
  });

  factory SeerrMediaInfo.fromJson(Map<String, dynamic> json) {
    return SeerrMediaInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tmdbId: (json['tmdbId'] as num?)?.toInt(),
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      status: SeerrMediaStatus.fromValue((json['status'] as num?)?.toInt()),
      status4k: SeerrMediaStatus.fromValue((json['status4k'] as num?)?.toInt()),
    );
  }
}
