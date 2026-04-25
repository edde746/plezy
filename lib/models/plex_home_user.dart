import 'package:json_annotation/json_annotation.dart';

part 'plex_home_user.g.dart';

@JsonSerializable()
class PlexHomeUser {
  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(defaultValue: '')
  final String uuid;
  @JsonKey(defaultValue: 'Unknown')
  final String title;
  final String? username;
  final String? email;
  final String? friendlyName;
  @JsonKey(defaultValue: '')
  final String thumb;
  @JsonKey(defaultValue: false)
  final bool hasPassword;
  @JsonKey(defaultValue: false)
  final bool restricted;
  final int? updatedAt;
  @JsonKey(defaultValue: false)
  final bool admin;
  @JsonKey(defaultValue: false)
  final bool guest;
  @JsonKey(defaultValue: false)
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
