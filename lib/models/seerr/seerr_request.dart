import 'seerr_media_info.dart';
import 'seerr_user.dart';

/// Lifecycle status of a single Seerr media request.
/// Maps to Seerr's `MediaRequestStatus`:
///   1 = PENDING_APPROVAL, 2 = APPROVED, 3 = DECLINED, 4 = FAILED, 5 = COMPLETED
enum SeerrRequestStatus {
  pendingApproval(1),
  approved(2),
  declined(3),
  failed(4),
  completed(5);

  final int value;
  const SeerrRequestStatus(this.value);

  static SeerrRequestStatus fromValue(int? raw) {
    return switch (raw) {
      2 => SeerrRequestStatus.approved,
      3 => SeerrRequestStatus.declined,
      4 => SeerrRequestStatus.failed,
      5 => SeerrRequestStatus.completed,
      _ => SeerrRequestStatus.pendingApproval,
    };
  }
}

/// One season's worth of a TV request.
class SeerrRequestedSeason {
  final int seasonNumber;
  final SeerrRequestStatus status;

  const SeerrRequestedSeason({required this.seasonNumber, required this.status});

  factory SeerrRequestedSeason.fromJson(Map<String, dynamic> json) {
    return SeerrRequestedSeason(
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
      status: SeerrRequestStatus.fromValue((json['status'] as num?)?.toInt()),
    );
  }
}

/// A `MediaRequest` record returned by `/api/v1/request`, `/request/{id}`,
/// and `/user/{id}/requests`.
class SeerrRequest {
  final int id;
  final SeerrRequestStatus status;
  final SeerrMediaInfo? media;
  final SeerrUser? requestedBy;
  final bool is4k;
  final String mediaType;
  final List<SeerrRequestedSeason> seasons;

  const SeerrRequest({
    required this.id,
    required this.status,
    this.media,
    this.requestedBy,
    required this.is4k,
    required this.mediaType,
    this.seasons = const [],
  });

  factory SeerrRequest.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'];
    final requestedByJson = json['requestedBy'];
    final rawSeasons = json['seasons'];
    final seasons = <SeerrRequestedSeason>[];
    if (rawSeasons is List) {
      for (final s in rawSeasons) {
        if (s is Map<String, dynamic>) seasons.add(SeerrRequestedSeason.fromJson(s));
      }
    }
    final type = (json['type'] as String?) ?? (mediaJson is Map<String, dynamic> ? mediaJson['mediaType'] as String? : null);
    return SeerrRequest(
      id: (json['id'] as num).toInt(),
      status: SeerrRequestStatus.fromValue((json['status'] as num?)?.toInt()),
      media: mediaJson is Map<String, dynamic> ? SeerrMediaInfo.fromJson(mediaJson) : null,
      requestedBy: requestedByJson is Map<String, dynamic> ? SeerrUser.fromJson(requestedByJson) : null,
      is4k: json['is4k'] as bool? ?? false,
      mediaType: type ?? 'movie',
      seasons: seasons,
    );
  }
}

/// Write-side body for `POST /api/v1/request`. Either a movie request
/// (omit [seasons]) or a TV request (omit [seasons] for "all current + future",
/// or supply specific season numbers).
class SeerrRequestPayload {
  final String mediaType;
  final int mediaId;
  final int? tvdbId;
  final List<int>? seasons;
  final bool? is4k;
  final int? serverId;
  final int? profileId;
  final String? rootFolder;
  final int? languageProfileId;
  final int? userId;

  const SeerrRequestPayload({
    required this.mediaType,
    required this.mediaId,
    this.tvdbId,
    this.seasons,
    this.is4k,
    this.serverId,
    this.profileId,
    this.rootFolder,
    this.languageProfileId,
    this.userId,
  });

  factory SeerrRequestPayload.movie(int tmdbId, {bool? is4k, int? userId}) =>
      SeerrRequestPayload(mediaType: 'movie', mediaId: tmdbId, is4k: is4k, userId: userId);

  /// TV request. Pass `seasons: null` for "all current + future seasons"; pass
  /// an explicit list (`[1, 3]`) for a partial request.
  factory SeerrRequestPayload.tv(int tmdbId, {int? tvdbId, List<int>? seasons, bool? is4k, int? userId}) =>
      SeerrRequestPayload(
        mediaType: 'tv',
        mediaId: tmdbId,
        tvdbId: tvdbId,
        seasons: seasons,
        is4k: is4k,
        userId: userId,
      );

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{'mediaType': mediaType, 'mediaId': mediaId};
    if (tvdbId != null) body['tvdbId'] = tvdbId;
    if (seasons != null) body['seasons'] = seasons;
    if (is4k != null) body['is4k'] = is4k;
    if (serverId != null) body['serverId'] = serverId;
    if (profileId != null) body['profileId'] = profileId;
    if (rootFolder != null) body['rootFolder'] = rootFolder;
    if (languageProfileId != null) body['languageProfileId'] = languageProfileId;
    if (userId != null) body['userId'] = userId;
    return body;
  }
}
