import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';

part 'bonfire_profile.g.dart';

/// Parsed from the Bonfire/JellyProfiles plugin's `GET /plugins/profiles/list`.
///
/// Bonfire profiles are backed by real Jellyfin users the plugin manages; the
/// plugin enforces library/tag restrictions server-side, so what the app sees
/// through the profile's own session token is already scoped. Scalar fields
/// coerce tolerantly (same policy as [PlexHomeUser]) because plugin point
/// releases add and reshape fields.
@JsonSerializable()
class BonfireProfile {
  /// Jellyfin user id (GUID) the plugin assigned to this profile.
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String profileUserId;

  @JsonKey(readValue: readStringField, defaultValue: '')
  final String profileName;

  @JsonKey(readValue: readStringField, defaultValue: '')
  final String avatarInitial;

  @JsonKey(readValue: readStringField, defaultValue: '')
  final String avatarColor;

  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool transparentAvatar;

  /// Whether a PIN must be entered to switch into this profile right now —
  /// false on the LAN when `bypassPinOnLocalNetwork` is set. Prompt on this.
  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool requiresPin;

  /// Whether a PIN is configured at all. Display PIN state from this, never
  /// from [requiresPin].
  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool hasPin;

  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool isMaster;

  /// Sent for masters only; a UI warning signal, never an authorisation one.
  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool isAdministrator;

  @JsonKey(fromJson: flexibleIntOrZero)
  final int lockoutMinutes;

  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool bypassPinOnLocalNetwork;

  @JsonKey(fromJson: _stringListOrEmpty)
  final List<String> allowedDeviceIds;

  /// True when the profile belongs to a linked (remote) Bonfire household.
  @JsonKey(fromJson: flexibleBool, defaultValue: false)
  final bool isBonfire;

  /// `/plugins/profiles/image/{id}?v=…` for a stored picture, an absolute
  /// http(s) URL the user pasted, or null.
  @JsonKey(readValue: readStringField)
  final String? profileImage;

  @JsonKey(readValue: readStringField, defaultValue: '')
  final String masterUserId;

  BonfireProfile({
    required this.profileUserId,
    required this.profileName,
    required this.avatarInitial,
    required this.avatarColor,
    required this.transparentAvatar,
    required this.requiresPin,
    required this.hasPin,
    required this.isMaster,
    required this.isAdministrator,
    required this.lockoutMinutes,
    required this.bypassPinOnLocalNetwork,
    required this.allowedDeviceIds,
    required this.isBonfire,
    this.profileImage,
    required this.masterUserId,
  });

  factory BonfireProfile.fromJson(Map<String, dynamic> json) => _$BonfireProfileFromJson(json);

  Map<String, dynamic> toJson() => _$BonfireProfileToJson(this);

  String get displayName => profileName.trim().isNotEmpty ? profileName : profileUserId;

  /// Absolute URL for the profile picture, resolved against [baseUrl] when the
  /// plugin returned its relative `/plugins/profiles/image/...` path.
  /// [thumb] appends `size=thumb` to stored-image URLs only — an externally
  /// pasted URL must not be rewritten.
  String? imageUrlFor(String baseUrl, {bool thumb = true}) {
    final image = profileImage;
    if (image == null || image.isEmpty) return null;
    if (image.startsWith('http://') || image.startsWith('https://')) return image;
    final path = image.startsWith('/') ? image : '/$image';
    final withThumb = thumb && !path.contains('size=') ? '$path${path.contains('?') ? '&' : '?'}size=thumb' : path;
    return '$baseUrl$withThumb';
  }

  /// Value equality over the full payload so stream diffing (provider, picker)
  /// treats a re-fetch of unchanged data as unchanged.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BonfireProfile &&
          other.profileUserId == profileUserId &&
          other.profileName == profileName &&
          other.avatarInitial == avatarInitial &&
          other.avatarColor == avatarColor &&
          other.transparentAvatar == transparentAvatar &&
          other.requiresPin == requiresPin &&
          other.hasPin == hasPin &&
          other.isMaster == isMaster &&
          other.isAdministrator == isAdministrator &&
          other.lockoutMinutes == lockoutMinutes &&
          other.bypassPinOnLocalNetwork == bypassPinOnLocalNetwork &&
          other.isBonfire == isBonfire &&
          other.profileImage == profileImage &&
          other.masterUserId == masterUserId &&
          _sameStringList(other.allowedDeviceIds, allowedDeviceIds);

  @override
  int get hashCode => Object.hashAll([
    profileUserId,
    profileName,
    avatarInitial,
    avatarColor,
    transparentAvatar,
    requiresPin,
    hasPin,
    isMaster,
    isAdministrator,
    lockoutMinutes,
    bypassPinOnLocalNetwork,
    isBonfire,
    profileImage,
    masterUserId,
    Object.hashAll(allowedDeviceIds),
  ]);
}

List<String> _stringListOrEmpty(Object? value) => switch (value) {
  final List<Object?> list => [for (final item in list) if (item != null) item.toString()],
  _ => const <String>[],
};

bool _sameStringList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
