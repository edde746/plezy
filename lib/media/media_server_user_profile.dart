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
/// fields the player needs for auto-track selection. [AccountPreferences] is
/// the implementation, so playback reads the same cache the Account
/// preferences screen writes.
///
/// Language strings are server-shaped (Plex returns 639-2/B like "fre",
/// Jellyfin returns 639-2/T like "fra"); [LanguageCodes.getVariations]
/// handles either when matching against mpv-reported track languages.
abstract class MediaServerUserProfile {
  /// Whether the player should auto-pick an audio track based on the
  /// language preferences. False means "keep the file's default track".
  bool get autoSelectAudio;

  /// Preferred audio language. May be null when the user has no preference
  /// set. Plex also stores a ranked list, but PMS applies that itself when
  /// stamping `selected`; the client only needs the primary as a fallback.
  String? get defaultAudioLanguage;

  /// Preferred subtitle language. May be null.
  String? get defaultSubtitleLanguage;

  /// Server-side subtitle mode when exposed by the backend. Plex's
  /// `autoSelectSubtitle` maps onto none/smart/always; a backend without a
  /// mode returns null and keeps the selected-stream behavior.
  SubtitlePlaybackMode? get subtitleMode => null;
}
