import 'package:json_annotation/json_annotation.dart';

part 'plex_first_character.g.dart';

@JsonSerializable()
class PlexFirstCharacter {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: 0)
  final int size;

  PlexFirstCharacter({required this.key, required this.title, required this.size});

  factory PlexFirstCharacter.fromJson(Map<String, dynamic> json) => _$PlexFirstCharacterFromJson(json);

  Map<String, dynamic> toJson() => _$PlexFirstCharacterToJson(this);
}
