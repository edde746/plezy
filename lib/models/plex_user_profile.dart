import 'package:json_annotation/json_annotation.dart';

part 'plex_user_profile.g.dart';

/// Represents a Plex user's profile preferences
/// Fetched from https://clients.plex.tv/api/v2/user
@JsonSerializable()
class PlexUserProfile {
  @JsonKey(defaultValue: true)
  final bool autoSelectAudio;
  @JsonKey(defaultValue: 0)
  final int defaultAudioAccessibility;
  final String? defaultAudioLanguage;
  final List<String>? defaultAudioLanguages;
  final String? defaultSubtitleLanguage;
  final List<String>? defaultSubtitleLanguages;
  @JsonKey(defaultValue: 0)
  final int autoSelectSubtitle;
  @JsonKey(defaultValue: 0)
  final int defaultSubtitleAccessibility;
  @JsonKey(defaultValue: 1)
  final int defaultSubtitleForced;
  @JsonKey(defaultValue: 1)
  final int watchedIndicator;
  @JsonKey(defaultValue: 0)
  final int mediaReviewsVisibility;
  final List<String>? mediaReviewsLanguages;

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

  factory PlexUserProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    return _$PlexUserProfileFromJson(profile);
  }

  Map<String, dynamic> toJson() => {'profile': _$PlexUserProfileToJson(this)};
}
