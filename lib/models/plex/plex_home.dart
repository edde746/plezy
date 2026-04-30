import 'package:json_annotation/json_annotation.dart';

import 'plex_home_user.dart';

part 'plex_home.g.dart';

@JsonSerializable()
class PlexHome {
  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  final int? guestUserID;
  @JsonKey(defaultValue: '')
  final String guestUserUUID;
  @JsonKey(defaultValue: false)
  final bool guestEnabled;
  @JsonKey(defaultValue: false)
  final bool subscription;
  @JsonKey(defaultValue: <PlexHomeUser>[])
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

  factory PlexHome.fromJson(Map<String, dynamic> json) => _$PlexHomeFromJson(json);

  Map<String, dynamic> toJson() => _$PlexHomeToJson(this);

  PlexHomeUser? get adminUser => users.where((user) => user.admin).firstOrNull;

  List<PlexHomeUser> get managedUsers => users.where((user) => !user.admin).toList();

  List<PlexHomeUser> get restrictedUsers => users.where((user) => user.restricted).toList();

  PlexHomeUser? getUserByUUID(String uuid) {
    try {
      return users.firstWhere((user) => user.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  bool get hasMultipleUsers => users.length > 1;
}
