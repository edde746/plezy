import '../../media/account_preferences.dart';
import '../../media/media_server_user_profile.dart';
import '../../utils/json_utils.dart';
import '../../utils/language_codes.dart';

/// Wire mapping for plex.tv `/api/v2/user/profile` account preferences.
///
/// The account API has drifted before, so reads tolerate each field independently
/// rather than allowing one unexpected value to discard the whole profile.
class PlexAccountPreferences {
  const PlexAccountPreferences._();

  /// Maps either a bare profile object or the `profile` envelope returned by
  /// plex.tv's broader `/user` endpoint.
  static AccountPreferences fromProfileJson(Map<String, dynamic> json) {
    final envelope = json['profile'];
    final profile = envelope is Map<String, dynamic> ? envelope : json;

    return AccountPreferences(
      preferredAudioLanguage: _profileLanguage(profile['defaultAudioLanguage']),
      playDefaultAudioTrack: flexibleBoolNullable(profile['autoSelectAudio']),
      preferredSubtitleLanguage: _profileLanguage(profile['defaultSubtitleLanguage']),
      subtitlePlaybackMode: _subtitleMode(profile['autoSelectSubtitle']),
      watchedIndicator: WatchedIndicatorScope.fromPlexValue(flexibleInt(profile['watchedIndicator'])),
      mediaReviewsVisibility: MediaReviewsVisibility.fromPlexValue(flexibleInt(profile['mediaReviewsVisibility'])),
      subtitleAccessibility: SubtitleAccessibilityPreference.fromPlexValue(
        flexibleInt(profile['defaultSubtitleAccessibility']),
      ),
      forcedSubtitles: ForcedSubtitlePreference.fromPlexValue(flexibleInt(profile['defaultSubtitleForced'])),
    );
  }

  /// Converts a sparse patch into the query-string shape expected by plex.tv.
  ///
  /// Plex accepts only its eight account-profile keys here. Unsupported keys
  /// and subtitle modes that have no Plex representation are programming errors.
  static Map<String, String> queryParametersFor(AccountPreferencesPatch patch) {
    final parameters = <String, String>{};

    for (final entry in patch.values.entries) {
      switch (entry.key) {
        case AccountPreferenceKey.preferredAudioLanguage:
          parameters['defaultAudioLanguage'] = _languageQueryValue(entry.key, entry.value);
        case AccountPreferenceKey.autoSelectAudio:
          parameters['autoSelectAudio'] = _boolQueryValue(entry.key, entry.value);
        case AccountPreferenceKey.preferredSubtitleLanguage:
          parameters['defaultSubtitleLanguage'] = _languageQueryValue(entry.key, entry.value);
        case AccountPreferenceKey.subtitleMode:
          parameters['autoSelectSubtitle'] = _subtitleModeQueryValue(entry.key, entry.value);
        case AccountPreferenceKey.watchedIndicator:
          parameters['watchedIndicator'] = _requiredValue<WatchedIndicatorScope>(
            entry.key,
            entry.value,
          ).plexValue.toString();
        case AccountPreferenceKey.mediaReviewsVisibility:
          parameters['mediaReviewsVisibility'] = _requiredValue<MediaReviewsVisibility>(
            entry.key,
            entry.value,
          ).plexValue.toString();
        case AccountPreferenceKey.subtitleAccessibility:
          parameters['defaultSubtitleAccessibility'] = _requiredValue<SubtitleAccessibilityPreference>(
            entry.key,
            entry.value,
          ).plexValue.toString();
        case AccountPreferenceKey.forcedSubtitles:
          parameters['defaultSubtitleForced'] = _requiredValue<ForcedSubtitlePreference>(
            entry.key,
            entry.value,
          ).plexValue.toString();
        case AccountPreferenceKey.rememberAudioSelections:
        case AccountPreferenceKey.rememberSubtitleSelections:
        case AccountPreferenceKey.autoPlayNextEpisode:
        case AccountPreferenceKey.displayMissingEpisodes:
        case AccountPreferenceKey.hidePlayedInLatest:
        case AccountPreferenceKey.displayCollectionsView:
        case AccountPreferenceKey.rewatchingInNextUp:
          throw ArgumentError.value(entry.value, entry.key.name, 'is not supported by Plex account preferences');
      }
    }

    // Plex Web's onSubmit forces subtitles back to manual when audio auto-selection
    // is disabled; sending both keeps the two server-stored settings consistent.
    if (patch[AccountPreferenceKey.autoSelectAudio] == false) {
      parameters['autoSelectSubtitle'] = '0';
    }

    return parameters;
  }

  /// Singular language fields tolerate the array/CSV drift the account API has
  /// shown (#1488) by taking the first entry.
  static String? _profileLanguage(Object? value) => flexibleCsvStringList(value)?.first;

  static SubtitlePlaybackMode? _subtitleMode(Object? value) => switch (flexibleInt(value)) {
    0 => SubtitlePlaybackMode.none,
    1 => SubtitlePlaybackMode.smart,
    2 => SubtitlePlaybackMode.always,
    _ => null,
  };

  static String _languageQueryValue(AccountPreferenceKey key, Object? value) {
    if (value == null) return '';
    if (value is! String) {
      throw ArgumentError.value(value, key.name, 'must be an ISO 639 language code or null');
    }
    if (value.isEmpty) return '';
    return LanguageCodes.getIso6391Code(value) ?? value;
  }

  static String _boolQueryValue(AccountPreferenceKey key, Object? value) =>
      _requiredValue<bool>(key, value) ? '1' : '0';

  static String _subtitleModeQueryValue(AccountPreferenceKey key, Object? value) {
    final mode = _requiredValue<SubtitlePlaybackMode>(key, value);
    return switch (mode) {
      SubtitlePlaybackMode.none => '0',
      SubtitlePlaybackMode.smart => '1',
      SubtitlePlaybackMode.always => '2',
      SubtitlePlaybackMode.defaultMode || SubtitlePlaybackMode.onlyForced => throw ArgumentError.value(
        mode,
        key.name,
        'cannot be represented by Plex autoSelectSubtitle',
      ),
    };
  }

  static T _requiredValue<T>(AccountPreferenceKey key, Object? value) {
    if (value is T) return value;
    throw ArgumentError.value(value, key.name, 'must be a non-null $T');
  }
}
