import '../../data/iso_639_data.dart';
import '../../media/account_preferences.dart';
import '../../media/media_server_user_profile.dart';
import '../../utils/json_utils.dart';

/// Maps MediaBrowser `UserConfiguration` values to the neutral account model
/// and merges sparse changes into the server's full raw configuration.
class JellyfinAccountPreferences {
  const JellyfinAccountPreferences._();

  static AccountPreferences fromConfiguration(Map<String, dynamic> configuration) {
    return AccountPreferences(
      preferredAudioLanguage: _language(configuration['AudioLanguagePreference']),
      playDefaultAudioTrack: flexibleBoolNullable(configuration['PlayDefaultAudioTrack']),
      preferredSubtitleLanguage: _language(configuration['SubtitleLanguagePreference']),
      subtitlePlaybackMode: SubtitlePlaybackMode.fromServerValue(configuration['SubtitleMode']),
      rememberAudioSelections: flexibleBoolNullable(configuration['RememberAudioSelections']),
      rememberSubtitleSelections: flexibleBoolNullable(configuration['RememberSubtitleSelections']),
      autoPlayNextEpisode: flexibleBoolNullable(configuration['EnableNextEpisodeAutoPlay']),
      displayMissingEpisodes: flexibleBoolNullable(configuration['DisplayMissingEpisodes']),
      hidePlayedInLatest: flexibleBoolNullable(configuration['HidePlayedInLatest']),
      displayCollectionsView: flexibleBoolNullable(configuration['DisplayCollectionsView']),
    );
  }

  static Map<String, dynamic> mergePatch(Map<String, dynamic> configuration, AccountPreferencesPatch patch) {
    final merged = Map<String, dynamic>.from(configuration);
    for (final entry in patch.values.entries) {
      switch (entry.key) {
        case AccountPreferenceKey.preferredAudioLanguage:
          merged['AudioLanguagePreference'] = _serverLanguage(entry.value as String?);
          break;
        case AccountPreferenceKey.autoSelectAudio:
          merged['PlayDefaultAudioTrack'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.preferredSubtitleLanguage:
          merged['SubtitleLanguagePreference'] = _serverLanguage(entry.value as String?);
          break;
        case AccountPreferenceKey.subtitleMode:
          merged['SubtitleMode'] = _serverSubtitleMode(entry.value as SubtitlePlaybackMode?);
          break;
        case AccountPreferenceKey.rememberAudioSelections:
          merged['RememberAudioSelections'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.rememberSubtitleSelections:
          merged['RememberSubtitleSelections'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.autoPlayNextEpisode:
          merged['EnableNextEpisodeAutoPlay'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.displayMissingEpisodes:
          merged['DisplayMissingEpisodes'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.hidePlayedInLatest:
          merged['HidePlayedInLatest'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.displayCollectionsView:
          merged['DisplayCollectionsView'] = entry.value as bool?;
          break;
        case AccountPreferenceKey.watchedIndicator ||
            AccountPreferenceKey.mediaReviewsVisibility ||
            AccountPreferenceKey.subtitleAccessibility ||
            AccountPreferenceKey.forcedSubtitles:
          throw ArgumentError.value(entry.key, 'key', 'Unsupported MediaBrowser account preference');
      }
    }
    return merged;
  }

  static String? _language(Object? value) {
    final language = stringOrEmpty(value);
    return language.isEmpty ? null : language;
  }

  static String _serverLanguage(String? value) {
    if (value == null || value.isEmpty) return '';
    return languageEntries[value.toLowerCase()]?.code2 ?? value;
  }

  static String? _serverSubtitleMode(SubtitlePlaybackMode? mode) => switch (mode) {
    null => null,
    SubtitlePlaybackMode.none => 'None',
    SubtitlePlaybackMode.defaultMode => 'Default',
    SubtitlePlaybackMode.always => 'Always',
    SubtitlePlaybackMode.onlyForced => 'OnlyForced',
    SubtitlePlaybackMode.smart => 'Smart',
  };
}
