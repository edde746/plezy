import '../../media/media_server_user_profile.dart';

/// Jellyfin user playback preferences, sourced from `User.Configuration`
/// (returned by `/Users/{userId}` or `/Users/Me`). Jellyfin exposes only a
/// single ranked audio/subtitle language, so the multi-list accessors on
/// [MediaServerUserProfile] return null.
class JellyfinUserProfile implements MediaServerUserProfile {
  @override
  final bool autoSelectAudio;

  @override
  final String? defaultAudioLanguage;

  @override
  final String? defaultSubtitleLanguage;

  /// Server-reported subtitle mode (None / Default / Always / OnlyForced /
  /// Smart).
  @override
  final SubtitlePlaybackMode? subtitleMode;

  const JellyfinUserProfile({
    required this.autoSelectAudio,
    this.defaultAudioLanguage,
    this.defaultSubtitleLanguage,
    this.subtitleMode,
  });

  @override
  List<String>? get defaultAudioLanguages => null;

  @override
  List<String>? get defaultSubtitleLanguages => null;

  /// Build from `/Users/Me` (or `/Users/{userId}`) response — pulls the
  /// `Configuration` block; missing values fall back to server defaults
  /// (auto-select on, no language preference).
  factory JellyfinUserProfile.fromUserDto(Map<String, dynamic> json) {
    final config = json['Configuration'] as Map<String, dynamic>? ?? const {};
    final audio = config['AudioLanguagePreference'] as String?;
    final subtitle = config['SubtitleLanguagePreference'] as String?;
    final playDefault = config['PlayDefaultAudioTrack'] as bool? ?? true;
    return JellyfinUserProfile(
      autoSelectAudio: playDefault,
      defaultAudioLanguage: (audio == null || audio.isEmpty) ? null : audio,
      defaultSubtitleLanguage: (subtitle == null || subtitle.isEmpty) ? null : subtitle,
      subtitleMode: SubtitlePlaybackMode.fromServerValue(config['SubtitleMode']),
    );
  }
}
