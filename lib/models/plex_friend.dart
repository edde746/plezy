class PlexFriend {
  final int id;
  final String uuid;
  final String? username;
  final String? email;
  final String? friendlyName;
  final String title;
  final String thumb;
  final bool home;
  final String status;
  final bool restricted;

  PlexFriend({
    required this.id,
    required this.uuid,
    this.username,
    this.email,
    this.friendlyName,
    required this.title,
    required this.thumb,
    required this.home,
    required this.status,
    required this.restricted,
  });

  factory PlexFriend.fromJson(Map<String, dynamic> json) {
    return PlexFriend(
      id: (json['id'] as num?)?.toInt() ?? 0,
      uuid: json['uuid'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      friendlyName: json['friendlyName'] as String?,
      title: json['title'] as String? ?? 'Unknown',
      thumb: json['thumb'] as String? ?? '',
      home: json['home'] as bool? ?? false,
      status: json['status'] as String? ?? 'unknown',
      restricted: json['restricted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'username': username,
      'email': email,
      'friendlyName': friendlyName,
      'title': title,
      'thumb': thumb,
      'home': home,
      'status': status,
      'restricted': restricted,
    };
  }

  String get displayName => friendlyName ?? title;

  bool get isAccepted => status == 'accepted';
}
