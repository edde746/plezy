import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'plex_home_user.g.dart';

/// Parsed from the clients.plex.tv `/api/v2/home/users` account API — the
/// same drift-prone surface as PlexUserProfile (#1488), so scalar fields
/// coerce tolerantly instead of hard-casting.
@JsonSerializable()
class PlexHomeUser {
  @JsonKey(fromJson: flexibleIntOrZero)
  final int id;
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String uuid;
  @JsonKey(readValue: readStringField, defaultValue: 'Unknown')
  final String title;
  @JsonKey(readValue: readStringField)
  final String? username;
  @JsonKey(readValue: readStringField)
  final String? email;
  @JsonKey(readValue: readStringField)
  final String? friendlyName;
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String thumb;
  @JsonKey(fromJson: flexibleBool)
  final bool hasPassword;
  @JsonKey(fromJson: flexibleBool)
  final bool restricted;
  @JsonKey(fromJson: flexibleInt)
  final int? updatedAt;
  @JsonKey(fromJson: flexibleBool)
  final bool admin;
  @JsonKey(fromJson: flexibleBool)
  final bool guest;
  @JsonKey(fromJson: flexibleBool)
  final bool protected;

  PlexHomeUser({
    required this.id,
    required this.uuid,
    required this.title,
    this.username,
    this.email,
    this.friendlyName,
    required this.thumb,
    required this.hasPassword,
    required this.restricted,
    required this.updatedAt,
    required this.admin,
    required this.guest,
    required this.protected,
  });

  factory PlexHomeUser.fromJson(Map<String, dynamic> json) => _$PlexHomeUserFromJson(json);

  Map<String, dynamic> toJson() => _$PlexHomeUserToJson(this);

  String get displayName => friendlyName ?? title;

  bool get isAdminUser => admin;
  bool get isRestrictedUser => restricted;
  bool get isGuestUser => guest;
  bool get requiresPassword => protected;
}
