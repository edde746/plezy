import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import 'plex_home_user.dart';

part 'plex_home.g.dart';

@JsonSerializable()
class PlexHome {
  @JsonKey(fromJson: flexibleIntOrZero)
  final int id;
  @JsonKey(defaultValue: <PlexHomeUser>[])
  final List<PlexHomeUser> users;

  PlexHome({required this.id, required this.users});

  factory PlexHome.fromJson(Map<String, dynamic> json) => _$PlexHomeFromJson(json);

  Map<String, dynamic> toJson() => _$PlexHomeToJson(this);

  PlexHomeUser? get adminUser => users.where((user) => user.admin).firstOrNull;
}
