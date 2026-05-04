import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'livetv_channel.dart';

part 'livetv_lineup.g.dart';

List<LiveTvChannel> _parseChannels(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) LiveTvChannel.fromJson(item),
  ];
}

@JsonSerializable(createToJson: false)
class LiveTvCountry {
  final String? key;
  final String? type;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String code;
  final String? language;
  final String? languageTitle;
  final String? example;
  @JsonKey(fromJson: flexibleInt)
  final int? flavor;

  const LiveTvCountry({
    this.key,
    this.type,
    required this.title,
    required this.code,
    this.language,
    this.languageTitle,
    this.example,
    this.flavor,
  });

  factory LiveTvCountry.fromJson(Map<String, dynamic> json) => _$LiveTvCountryFromJson(json);
}

@JsonSerializable(createToJson: false)
class LiveTvLanguage {
  @JsonKey(defaultValue: '')
  final String code;
  @JsonKey(defaultValue: '')
  final String title;

  const LiveTvLanguage({required this.code, required this.title});

  factory LiveTvLanguage.fromJson(Map<String, dynamic> json) => _$LiveTvLanguageFromJson(json);
}

@JsonSerializable(createToJson: false)
class LiveTvRegion {
  @JsonKey(defaultValue: '')
  final String key;
  final String? type;
  @JsonKey(defaultValue: '')
  final String title;

  const LiveTvRegion({required this.key, this.type, required this.title});

  factory LiveTvRegion.fromJson(Map<String, dynamic> json) => _$LiveTvRegionFromJson(json);
}

@JsonSerializable(createToJson: false)
class LiveTvLineup {
  @JsonKey(defaultValue: '')
  final String uuid;
  final String? type;
  final String? title;
  @JsonKey(fromJson: flexibleInt)
  final int? lineupType;
  final String? location;
  @JsonKey(name: 'Channel', fromJson: _parseChannels)
  final List<LiveTvChannel> channels;

  const LiveTvLineup({
    required this.uuid,
    this.type,
    this.title,
    this.lineupType,
    this.location,
    this.channels = const [],
  });

  factory LiveTvLineup.fromJson(Map<String, dynamic> json) => _$LiveTvLineupFromJson(json);
}

class LiveTvLineupResult {
  final String? lineupGroupUuid;
  final List<LiveTvLineup> lineups;

  const LiveTvLineupResult({this.lineupGroupUuid, required this.lineups});
}
