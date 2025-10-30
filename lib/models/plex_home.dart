import 'plex_home_user.dart';

class PlexHome {
  final int id;
  final String name;
  final int guestUserID;
  final String guestUserUUID;
  final bool guestEnabled;
  final bool subscription;
  final List<PlexHomeUser> users;

  PlexHome({
    required this.id,
    required this.name,
    required this.guestUserID,
    required this.guestUserUUID,
    required this.guestEnabled,
    required this.subscription,
    required this.users,
  });

  factory PlexHome.fromJson(Map<String, dynamic> json) {
    final List<dynamic> usersJson = json['users'] as List<dynamic>;
    final users = usersJson
        .map(
          (userJson) => PlexHomeUser.fromJson(userJson as Map<String, dynamic>),
        )
        .toList();

    return PlexHome(
      id: json['id'] as int,
      name: json['name'] as String,
      guestUserID: json['guestUserID'] as int,
      guestUserUUID: json['guestUserUUID'] as String,
      guestEnabled: json['guestEnabled'] as bool,
      subscription: json['subscription'] as bool,
      users: users,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guestUserID': guestUserID,
      'guestUserUUID': guestUserUUID,
      'guestEnabled': guestEnabled,
      'subscription': subscription,
      'users': users.map((user) => user.toJson()).toList(),
    };
  }

  PlexHomeUser? get adminUser => users.where((user) => user.admin).firstOrNull;

  List<PlexHomeUser> get managedUsers =>
      users.where((user) => !user.admin).toList();

  List<PlexHomeUser> get restrictedUsers =>
      users.where((user) => user.restricted).toList();

  PlexHomeUser? getUserByUUID(String uuid) {
    try {
      return users.firstWhere((user) => user.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  bool get hasMultipleUsers => users.length > 1;
}
