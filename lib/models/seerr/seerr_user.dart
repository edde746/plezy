import 'package:json_annotation/json_annotation.dart';

part 'seerr_user.g.dart';

/// The signed-in Seerr user, as `GET /auth/me` reports it.
///
/// Not the shape of the `/auth/*` login bodies. Those return whatever `User`
/// instance the handler happened to build, and `POST /auth/local` loads only
/// the columns it needs to check the password, so its body carries the
/// entity's `permissions` default of 0 rather than the stored mask (#2213).
@JsonSerializable(createToJson: false)
class SeerrUser {
  final int id;
  final String? displayName;

  /// Seerr permission bitmask — see `SeerrPermission`.
  final int permissions;

  const SeerrUser({required this.id, this.displayName, required this.permissions});

  factory SeerrUser.fromJson(Map<String, dynamic> json) => _$SeerrUserFromJson(json);
}
