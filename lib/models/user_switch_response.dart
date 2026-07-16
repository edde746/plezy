import '../utils/app_logger.dart';
import '../utils/json_utils.dart';
import 'plex/plex_user_profile.dart';

class UserSwitchResponse {
  final int id;
  final String uuid;
  final String username;
  final String title;
  final String email;
  final String? friendlyName;
  final String? locale;
  final bool confirmed;
  final int joinedAt;
  final bool emailOnlyAuth;
  final bool hasPassword;
  final bool protected;
  final String thumb;
  final String authToken;
  final bool? mailingListActive;
  final String scrobbleTypes;
  final String country;
  final bool restricted;
  final bool? anonymous;
  final bool home;
  final bool guest;
  final int homeSize;
  final bool homeAdmin;
  final int maxHomeSize;
  final PlexUserProfile profile;
  final bool twoFactorEnabled;
  final bool backupCodesCreated;
  final String? attributionPartner;

  UserSwitchResponse({
    required this.id,
    required this.uuid,
    required this.username,
    required this.title,
    required this.email,
    this.friendlyName,
    this.locale,
    required this.confirmed,
    required this.joinedAt,
    required this.emailOnlyAuth,
    required this.hasPassword,
    required this.protected,
    required this.thumb,
    required this.authToken,
    this.mailingListActive,
    required this.scrobbleTypes,
    required this.country,
    required this.restricted,
    this.anonymous,
    required this.home,
    required this.guest,
    required this.homeSize,
    required this.homeAdmin,
    required this.maxHomeSize,
    required this.profile,
    required this.twoFactorEnabled,
    required this.backupCodesCreated,
    this.attributionPartner,
  });

  /// INVARIANT (#1488): a successful token mint must never be lost to parsing
  /// of decorative fields. `authToken` is the only field any caller consumes
  /// (see plex_home_switch.dart) — it alone parses strictly; every other
  /// field tolerates missing/wrong-typed values with sane defaults. Plex has
  /// changed field shapes on this endpoint before (July 2026: profile
  /// language lists became CSV strings), and each drift used to brick token
  /// minting outright.
  factory UserSwitchResponse.fromJson(Map<String, dynamic> json) {
    final authToken = json['authToken'];
    if (authToken is! String || authToken.isEmpty) {
      throw const FormatException('Plex /switch response has no usable authToken');
    }

    PlexUserProfile profile;
    try {
      profile = PlexUserProfile.fromJson(json);
    } catch (e, st) {
      appLogger.w('UserSwitchResponse: profile blob failed to parse; using defaults', error: e, stackTrace: st);
      profile = PlexUserProfile.defaults();
    }

    String? optString(String key) => json[key]?.toString();

    return UserSwitchResponse(
      id: flexibleInt(json['id']) ?? 0,
      uuid: optString('uuid') ?? '',
      username: optString('username') ?? '',
      title: optString('title') ?? '',
      email: optString('email') ?? '',
      friendlyName: optString('friendlyName'),
      locale: optString('locale'),
      confirmed: flexibleBool(json['confirmed']),
      joinedAt: flexibleInt(json['joinedAt']) ?? 0,
      emailOnlyAuth: flexibleBool(json['emailOnlyAuth']),
      hasPassword: flexibleBool(json['hasPassword']),
      protected: flexibleBool(json['protected']),
      thumb: optString('thumb') ?? '',
      authToken: authToken,
      mailingListActive: flexibleBoolNullable(json['mailingListActive']),
      scrobbleTypes: optString('scrobbleTypes') ?? '',
      country: optString('country') ?? '',
      restricted: flexibleBool(json['restricted']),
      anonymous: flexibleBoolNullable(json['anonymous']),
      home: flexibleBool(json['home']),
      guest: flexibleBool(json['guest']),
      homeSize: flexibleInt(json['homeSize']) ?? 1,
      homeAdmin: flexibleBool(json['homeAdmin']),
      maxHomeSize: flexibleInt(json['maxHomeSize']) ?? 1,
      profile: profile,
      twoFactorEnabled: flexibleBool(json['twoFactorEnabled']),
      backupCodesCreated: flexibleBool(json['backupCodesCreated']),
      attributionPartner: optString('attributionPartner'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'username': username,
      'title': title,
      'email': email,
      'friendlyName': friendlyName,
      'locale': locale,
      'confirmed': confirmed,
      'joinedAt': joinedAt,
      'emailOnlyAuth': emailOnlyAuth,
      'hasPassword': hasPassword,
      'protected': protected,
      'thumb': thumb,
      'authToken': authToken,
      'mailingListActive': mailingListActive,
      'scrobbleTypes': scrobbleTypes,
      'country': country,
      'restricted': restricted,
      'anonymous': anonymous,
      'home': home,
      'guest': guest,
      'homeSize': homeSize,
      'homeAdmin': homeAdmin,
      'maxHomeSize': maxHomeSize,
      'profile': profile.toJson()['profile'],
      'twoFactorEnabled': twoFactorEnabled,
      'backupCodesCreated': backupCodesCreated,
      'attributionPartner': attributionPartner,
    };
  }

  String get displayName => friendlyName ?? title;

  bool get isAdminUser => homeAdmin;
  bool get isRestrictedUser => restricted;
  bool get isGuestUser => guest;
  bool get requiresPassword => hasPassword;
}
