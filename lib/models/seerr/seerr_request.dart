import 'package:json_annotation/json_annotation.dart';

import 'seerr_media.dart';

part 'seerr_request.g.dart';

/// Approval state of a Seerr request (`MediaRequest.status`) — identical
/// wire codes in Overseerr and Jellyseerr. FAILED is set when the arr
/// submission is rejected; COMPLETED once the request's media is available.
enum SeerrRequestStatus {
  pending(1),
  approved(2),
  declined(3),
  failed(4),
  completed(5);

  final int code;
  const SeerrRequestStatus(this.code);

  /// An unrecognized code deliberately falls back to [pending]: it renders
  /// as "requested" and blocks re-submission, the conservative reading for
  /// a state this client does not understand.
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

  /// Arr tag ids. An empty list is a real override (no tags); null leaves
  /// the instance defaults in place.
  final List<int>? tags;

  const SeerrRequestPayload({
    required this.mediaType,
    required this.mediaId,
    this.seasons,
    this.is4k = false,
    this.serverId,
    this.profileId,
    this.rootFolder,
    this.languageProfileId,
    this.tags,
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
    if (tags != null) 'tags': tags,
  };
}
