import 'plex_user_profile.dart';

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

  factory UserSwitchResponse.fromJson(Map<String, dynamic> json) {
    return UserSwitchResponse(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      username: json['username'] as String? ?? '',
      title: json['title'] as String,
      email: json['email'] as String? ?? '',
      friendlyName: json['friendlyName'] as String?,
      locale: json['locale'] as String?,
      confirmed: json['confirmed'] as bool,
      joinedAt: json['joinedAt'] as int,
      emailOnlyAuth: json['emailOnlyAuth'] as bool,
      hasPassword: json['hasPassword'] as bool,
      protected: json['protected'] as bool,
      thumb: json['thumb'] as String,
      authToken: json['authToken'] as String,
      mailingListActive: json['mailingListActive'] as bool?,
      scrobbleTypes: json['scrobbleTypes'] as String? ?? '',
      country: json['country'] as String? ?? '',
      restricted: json['restricted'] as bool,
      anonymous: json['anonymous'] as bool?,
      home: json['home'] as bool,
      guest: json['guest'] as bool,
      homeSize: json['homeSize'] as int,
      homeAdmin: json['homeAdmin'] as bool,
      maxHomeSize: json['maxHomeSize'] as int,
      profile: PlexUserProfile.fromJson(json),
      twoFactorEnabled: json['twoFactorEnabled'] as bool,
      backupCodesCreated: json['backupCodesCreated'] as bool,
      attributionPartner: json['attributionPartner'] as String?,
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
  bool get isSecureUser => twoFactorEnabled || backupCodesCreated;
}
