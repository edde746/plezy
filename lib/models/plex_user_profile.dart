/// Represents a Plex user's profile preferences
/// Fetched from https://clients.plex.tv/api/v2/user
class PlexUserProfile {
  final bool autoSelectAudio;
  final int defaultAudioAccessibility;
  final String? defaultAudioLanguage;
  final List<String>? defaultAudioLanguages;
  final String? defaultSubtitleLanguage;
  final List<String>? defaultSubtitleLanguages;
  final int autoSelectSubtitle;
  final int defaultSubtitleAccessibility;
  final int defaultSubtitleForced;
  final int watchedIndicator;
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

    return PlexUserProfile(
      autoSelectAudio: profile['autoSelectAudio'] as bool? ?? true,
      defaultAudioAccessibility:
          profile['defaultAudioAccessibility'] as int? ?? 0,
      defaultAudioLanguage: profile['defaultAudioLanguage'] as String?,
      defaultAudioLanguages: profile['defaultAudioLanguages'] != null
          ? List<String>.from(profile['defaultAudioLanguages'] as List)
          : null,
      defaultSubtitleLanguage: profile['defaultSubtitleLanguage'] as String?,
      defaultSubtitleLanguages: profile['defaultSubtitleLanguages'] != null
          ? List<String>.from(profile['defaultSubtitleLanguages'] as List)
          : null,
      autoSelectSubtitle: profile['autoSelectSubtitle'] as int? ?? 0,
      defaultSubtitleAccessibility:
          profile['defaultSubtitleAccessibility'] as int? ?? 0,
      defaultSubtitleForced: profile['defaultSubtitleForced'] as int? ?? 1,
      watchedIndicator: profile['watchedIndicator'] as int? ?? 1,
      mediaReviewsVisibility: profile['mediaReviewsVisibility'] as int? ?? 0,
      mediaReviewsLanguages: profile['mediaReviewsLanguages'] != null
          ? List<String>.from(profile['mediaReviewsLanguages'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': {
        'autoSelectAudio': autoSelectAudio,
        'defaultAudioAccessibility': defaultAudioAccessibility,
        'defaultAudioLanguage': defaultAudioLanguage,
        'defaultAudioLanguages': defaultAudioLanguages,
        'defaultSubtitleLanguage': defaultSubtitleLanguage,
        'defaultSubtitleLanguages': defaultSubtitleLanguages,
        'autoSelectSubtitle': autoSelectSubtitle,
        'defaultSubtitleAccessibility': defaultSubtitleAccessibility,
        'defaultSubtitleForced': defaultSubtitleForced,
        'watchedIndicator': watchedIndicator,
        'mediaReviewsVisibility': mediaReviewsVisibility,
        'mediaReviewsLanguages': mediaReviewsLanguages,
      },
    };
  }

  /// Returns true if subtitles should be automatically selected
  bool get shouldAutoSelectSubtitle => autoSelectSubtitle > 0;

  /// Returns true if forced subtitles should be preferred
  bool get preferForcedSubtitles => defaultSubtitleForced == 1;
}
