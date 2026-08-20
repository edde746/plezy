import 'package:json_annotation/json_annotation.dart';

import 'seerr_media.dart';

part 'seerr_request.g.dart';

/// Approval state of a Seerr request (`MediaRequest.status`).
enum SeerrRequestStatus {
  pending(1),
  approved(2),
  declined(3);

  final int code;
  const SeerrRequestStatus(this.code);

  static SeerrRequestStatus fromCode(int? code) =>
      values.where((v) => v.code == code).firstOrNull ?? SeerrRequestStatus.pending;
}

/// A media request as returned by `POST /request` and `GET /request`.
@JsonSerializable(createToJson: false)
class SeerrRequest {
  final int id;
  @JsonKey(name: 'status', fromJson: SeerrRequestStatus.fromCode)
  final SeerrRequestStatus status;
  final bool? is4k;
  final SeerrMediaInfo? media;

  /// TV only: the seasons this request covers.
  final List<SeerrRequestSeason>? seasons;

  const SeerrRequest({required this.id, required this.status, this.is4k, this.media, this.seasons});

  factory SeerrRequest.fromJson(Map<String, dynamic> json) => _$SeerrRequestFromJson(json);
}

/// One season within a request (`MediaRequest.seasons[]`).
@JsonSerializable(createToJson: false)
class SeerrRequestSeason {
  final int seasonNumber;

  const SeerrRequestSeason({required this.seasonNumber});

  factory SeerrRequestSeason.fromJson(Map<String, dynamic> json) => _$SeerrRequestSeasonFromJson(json);
}

/// Body of `POST /request`. Advanced fields require `REQUEST_ADVANCED`;
/// `is4k` requires the 4K request permissions.
class SeerrRequestPayload {
  final String mediaType;

  /// TMDB id.
  final int mediaId;

  /// TV only: season numbers, or null for `all`.
  final List<int>? seasons;
  final bool is4k;
  final int? serverId;
  final int? profileId;
  final String? rootFolder;
  final int? languageProfileId;

  const SeerrRequestPayload({
    required this.mediaType,
    required this.mediaId,
    this.seasons,
    this.is4k = false,
    this.serverId,
    this.profileId,
    this.rootFolder,
    this.languageProfileId,
  });

  Map<String, Object?> toJson() => {
    'mediaType': mediaType,
    'mediaId': mediaId,
    if (mediaType == 'tv') 'seasons': seasons ?? 'all',
    'is4k': is4k,
    if (serverId != null) 'serverId': serverId,
    if (profileId != null) 'profileId': profileId,
    if (rootFolder != null) 'rootFolder': rootFolder,
    if (languageProfileId != null) 'languageProfileId': languageProfileId,
  };
}
