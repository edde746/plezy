import 'package:json_annotation/json_annotation.dart';

part 'seerr_user.g.dart';

/// The authenticated Seerr user, as returned by the `/auth/*` login
/// endpoints and `GET /auth/me`.
@JsonSerializable(createToJson: false)
class SeerrUser {
  final int id;
  final String? displayName;
  final String? email;
  final int? permissions;
  final String? avatar;

  const SeerrUser({required this.id, this.displayName, this.email, this.permissions, this.avatar});

  factory SeerrUser.fromJson(Map<String, dynamic> json) => _$SeerrUserFromJson(json);
}
