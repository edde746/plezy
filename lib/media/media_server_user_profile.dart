/// Backend-neutral subtitle playback modes used by server-side user profiles.
enum SubtitlePlaybackMode {
  none,
  defaultMode,
  always,
  onlyForced,
  smart;

  static SubtitlePlaybackMode? fromServerValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'none' => SubtitlePlaybackMode.none,
      'default' => SubtitlePlaybackMode.defaultMode,
      'always' => SubtitlePlaybackMode.always,
      'onlyforced' => SubtitlePlaybackMode.onlyForced,
      'smart' => SubtitlePlaybackMode.smart,
      _ => null,
    };
  }
}

/// Backend-neutral subset of a server-stored user profile, scoped to the
/// fields the player needs for auto-track selection. Each backend exposes
/// these on its own concrete type ([PlexUserProfile], [JellyfinUserProfile]).
///
/// Language strings are server-shaped (Plex returns 639-2/B like "fre",
/// Jellyfin returns 639-2/T like "fra"); [LanguageCodes.getVariations]
/// handles either when matching against mpv-reported track languages.
abstract class MediaServerUserProfile {
  /// Whether the player should auto-pick an audio track based on the
  /// language preferences. False means "keep the file's default track".
  bool get autoSelectAudio;

  /// Primary preferred audio language. May be null when the user has no
  /// preference set.
  String? get defaultAudioLanguage;

  /// Additional ranked audio language preferences. Plex exposes a list,
  /// Jellyfin only the primary; Jellyfin implementations return null.
  List<String>? get defaultAudioLanguages;

  /// Primary preferred subtitle language. May be null.
  String? get defaultSubtitleLanguage;

  /// Additional ranked subtitle language preferences. Same Plex/Jellyfin
  /// difference as the audio list.
  List<String>? get defaultSubtitleLanguages;

  /// Server-side subtitle mode when exposed by the backend. Plex does not map
  /// cleanly to Jellyfin's mode enum, so it returns null and keeps existing
  /// Plex-selected-stream behavior.
  SubtitlePlaybackMode? get subtitleMode => null;
}
