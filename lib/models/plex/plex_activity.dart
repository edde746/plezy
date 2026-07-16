import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'plex_activity.g.dart';

/// Represents a running background task on a Plex Media Server (from /activities endpoint).
@JsonSerializable(createToJson: false)
class PlexActivity {
  @JsonKey(fromJson: stringOrEmpty)
  final String uuid;
  @JsonKey(fromJson: stringOrEmpty)
  final String type;
  @JsonKey(fromJson: stringOrEmpty)
  final String title;
  @JsonKey(readValue: readStringField)
  final String? subtitle;
  @JsonKey(fromJson: flexibleIntOrZero)
  final int progress; // 0–100
  @JsonKey(fromJson: flexibleBool)
  final bool cancellable;

  const PlexActivity({
    required this.uuid,
    required this.type,
    required this.title,
    this.subtitle,
    required this.progress,
    required this.cancellable,
  });

  factory PlexActivity.fromJson(Map<String, dynamic> json) => _$PlexActivityFromJson(json);
}
