class PlexHomeUser {
  final int id;
  final String uuid;
  final String title;
  final String? username;
  final String? email;
  final String? friendlyName;
  final String thumb;
  final bool hasPassword;
  final bool restricted;
  final int updatedAt;
  final bool admin;
  final bool guest;
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

  factory PlexHomeUser.fromJson(Map<String, dynamic> json) {
    return PlexHomeUser(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      friendlyName: json['friendlyName'] as String?,
      thumb: json['thumb'] as String,
      hasPassword: json['hasPassword'] as bool,
      restricted: json['restricted'] as bool,
      updatedAt: json['updatedAt'] as int,
      admin: json['admin'] as bool,
      guest: json['guest'] as bool,
      protected: json['protected'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'username': username,
      'email': email,
      'friendlyName': friendlyName,
      'thumb': thumb,
      'hasPassword': hasPassword,
      'restricted': restricted,
      'updatedAt': updatedAt,
      'admin': admin,
      'guest': guest,
      'protected': protected,
    };
  }

  String get displayName => friendlyName ?? title;

  bool get isAdminUser => admin;
  bool get isRestrictedUser => restricted;
  bool get isGuestUser => guest;
  bool get requiresPassword => hasPassword;
}
