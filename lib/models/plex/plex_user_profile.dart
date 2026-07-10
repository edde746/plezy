import 'package:json_annotation/json_annotation.dart';

import '../../media/media_server_user_profile.dart';
import '../../utils/json_utils.dart';

part 'plex_user_profile.g.dart';

/// Represents a Plex user's profile preferences
/// Fetched from https://clients.plex.tv/api/v2/user
///
/// Every field parses tolerantly: the account API drifts (~July 2026 the
/// language-list fields switched from arrays to CSV strings, #1488), and a
/// profile blob must never fail to parse — token minting embeds it (see
/// UserSwitchResponse.fromJson).
@JsonSerializable()
class PlexUserProfile implements MediaServerUserProfile {
  @JsonKey(fromJson: _boolOrTrue)
  @override
  final bool autoSelectAudio;
  @JsonKey(fromJson: _intOr0)
  final int defaultAudioAccessibility;
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
  @JsonKey(fromJson: _intOr0)
  final int autoSelectSubtitle;
  @JsonKey(fromJson: _intOr0)
  final int defaultSubtitleAccessibility;
  @JsonKey(fromJson: _intOr1)
  final int defaultSubtitleForced;
  @JsonKey(fromJson: _intOr1)
  final int watchedIndicator;
  @JsonKey(fromJson: _intOr0)
  final int mediaReviewsVisibility;
  @JsonKey(fromJson: flexibleCsvStringList)
  final List<String>? mediaReviewsLanguages;

  @override
  SubtitlePlaybackMode? get subtitleMode => null;

  PlexUserProfile({
    required this.autoSelectAudio,
    required this.defaultAudioAccessibility,
    this.defaultAudioLanguage,
    this.defaultAudioLanguages,
    this.defaultSubtitleLanguage,
    this.defaultSubtitleLanguages,
    required this.autoSelectSubtitle,
    required this.defaultSubtitleAccessibility,
    required this.defaultSubtitleForced,
    required this.watchedIndicator,
    required this.mediaReviewsVisibility,
    this.mediaReviewsLanguages,
  });

  /// Neutral fallback matching the generated defaults — used when the account
  /// API returns a profile blob that cannot be parsed at all (schema drift
  /// must never break token minting, see UserSwitchResponse.fromJson).
  factory PlexUserProfile.defaults() => PlexUserProfile(
    autoSelectAudio: true,
    defaultAudioAccessibility: 0,
    autoSelectSubtitle: 0,
    defaultSubtitleAccessibility: 0,
    defaultSubtitleForced: 1,
    watchedIndicator: 1,
    mediaReviewsVisibility: 0,
  );

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
int _intOr0(Object? v) => flexibleInt(v) ?? 0;
int _intOr1(Object? v) => flexibleInt(v) ?? 1;
