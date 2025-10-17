import 'package:json_annotation/json_annotation.dart';

part 'plex_server_info.g.dart';

@JsonSerializable()
class PlexServerInfo {
  final String name;
  final String? host;
  final int? port;
  final String? machineIdentifier;
  final String version;
  final bool? owned;
  final bool? https;

  PlexServerInfo({
    required this.name,
    this.host,
    this.port,
    this.machineIdentifier,
    required this.version,
    this.owned,
    this.https,
  });

  factory PlexServerInfo.fromJson(Map<String, dynamic> json) =>
      _$PlexServerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PlexServerInfoToJson(this);
}
