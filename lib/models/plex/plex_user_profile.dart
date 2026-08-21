import 'package:json_annotation/json_annotation.dart';

import '../../media/media_server_user_profile.dart';
import '../../utils/json_utils.dart';

part 'plex_user_profile.g.dart';

/// Represents a Plex user's profile preferences
/// Fetched from https://clients.plex.tv/api/v2/user
///
/// Every field parses tolerantly: the account API drifts (~July 2026 the
/// language-list fields switched from arrays to CSV strings, #1488), and a
/// single drifted field must never sink the whole profile.
@JsonSerializable()
class PlexUserProfile implements MediaServerUserProfile {
  @JsonKey(fromJson: _boolOrTrue)
  @override
  final bool autoSelectAudio;
  @JsonKey(fromJson: _flexibleLanguage)
  @override
  final String? defaultAudioLanguage;
  @JsonKey(fromJson: flexibleCsvStringList)
  @override
  final List<String>? defaultAudioLanguages;
  @JsonKey(fromJson: _flexibleLanguage)
  @override
  final String? defaultSubtitleLanguage;
  @JsonKey(fromJson: flexibleCsvStringList)
  @override
  final List<String>? defaultSubtitleLanguages;

  @override
  SubtitlePlaybackMode? get subtitleMode => null;

  PlexUserProfile({
    required this.autoSelectAudio,
    this.defaultAudioLanguage,
    this.defaultAudioLanguages,
    this.defaultSubtitleLanguage,
    this.defaultSubtitleLanguages,
  });

  factory PlexUserProfile.fromJson(Map<String, dynamic> json) {
    final envelope = json['profile'];
    final profile = envelope is Map<String, dynamic> ? envelope : json;
    return _$PlexUserProfileFromJson(profile);
  }

  Map<String, dynamic> toJson() => {'profile': _$PlexUserProfileToJson(this)};
}

/// Singular language fields tolerate the inverse drift (array/CSV → first entry).
String? _flexibleLanguage(Object? v) => flexibleCsvStringList(v)?.first;

bool _boolOrTrue(Object? v) => flexibleBoolNullable(v) ?? true;
