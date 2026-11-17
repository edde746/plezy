// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrRequest _$SeerrRequestFromJson(Map<String, dynamic> json) => SeerrRequest(
  id: (json['id'] as num).toInt(),
  status: SeerrRequestStatus.fromCode((json['status'] as num?)?.toInt()),
  is4k: json['is4k'] as bool?,
  media: json['media'] == null
      ? null
      : SeerrMediaInfo.fromJson(json['media'] as Map<String, dynamic>),
  seasons: (json['seasons'] as List<dynamic>?)
      ?.map((e) => SeerrRequestSeason.fromJson(e as Map<String, dynamic>))
      .toList(),
  type: json['type'] as String?,
  requestedBy: json['requestedBy'] == null
      ? null
      : SeerrRequestUser.fromJson(json['requestedBy'] as Map<String, dynamic>),
  createdAt: json['createdAt'] as String?,
  canRemove: json['canRemove'] as bool?,
);

SeerrRequestUser _$SeerrRequestUserFromJson(Map<String, dynamic> json) =>
    SeerrRequestUser(
      id: (json['id'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
    );

SeerrRequestSeason _$SeerrRequestSeasonFromJson(Map<String, dynamic> json) =>
    SeerrRequestSeason(seasonNumber: (json['seasonNumber'] as num).toInt());
