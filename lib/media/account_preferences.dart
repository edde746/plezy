import '../utils/language_codes.dart';
import 'media_server_user_profile.dart';

/// One account-scoped preference. Every key is stored on the media server or on
/// plex.tv, never on the device, and each backend supports a subset — see
/// [AccountPreferencesCapabilities].
enum AccountPreferenceKey {
  /// Preferred audio language. Jellyfin `AudioLanguagePreference` (ISO 639-2),
  /// Plex `defaultAudioLanguage` (ISO 639-1). Applied by the server.
  preferredAudioLanguage(AccountPreferenceValueKind.languageCode),

  /// Auto-pick an audio track from the language preference instead of keeping
  /// the file's default. Jellyfin `PlayDefaultAudioTrack`, Plex
  /// `autoSelectAudio`. Applied by the server.
  autoSelectAudio(AccountPreferenceValueKind.boolean),

  /// Preferred subtitle language. Jellyfin `SubtitleLanguagePreference`,
  /// Plex `defaultSubtitleLanguage`. Applied by the server.
  preferredSubtitleLanguage(AccountPreferenceValueKind.languageCode),

  /// When subtitles are auto-enabled. Jellyfin `SubtitleMode`, Plex
  /// `autoSelectSubtitle`. Applied by the server. Domains differ — see
  /// [AccountPreferencesCapabilities.subtitleModes].
  subtitleMode(AccountPreferenceValueKind.subtitleMode),

  /// Reuse the last audio track the user picked for the next item.
  /// Jellyfin `RememberAudioSelections`. MediaBrowser only.
  rememberAudioSelections(AccountPreferenceValueKind.boolean),

  /// Reuse the last subtitle track the user picked. Jellyfin
  /// `RememberSubtitleSelections`. MediaBrowser only.
  rememberSubtitleSelections(AccountPreferenceValueKind.boolean),

  /// Play the next episode automatically. Jellyfin
  /// `EnableNextEpisodeAutoPlay`. MediaBrowser only — Plex keeps its twin in
  /// the per-device `experience` blob, which Plezy deliberately never writes.
  autoPlayNextEpisode(AccountPreferenceValueKind.boolean),

  /// List episodes the library knows about but has no file for. Jellyfin
  /// `DisplayMissingEpisodes`. Applied by the server. MediaBrowser only.
  displayMissingEpisodes(AccountPreferenceValueKind.boolean),

  /// Exclude already-watched items from "Latest" rows. Jellyfin
  /// `HidePlayedInLatest`. Applied by the server. MediaBrowser only.
  hidePlayedInLatest(AccountPreferenceValueKind.boolean),

  /// Expose the server's Collections view. Jellyfin `DisplayCollectionsView`.
  /// Applied by the server. MediaBrowser only.
  displayCollectionsView(AccountPreferenceValueKind.boolean),

  /// Which item types show a watched badge. Plex `watchedIndicator`.
  /// Enforced by the client. Plex only.
  watchedIndicator(AccountPreferenceValueKind.watchedIndicator),

  /// Whose ratings and reviews to show. Plex `mediaReviewsVisibility`.
  /// Enforced by the client. Plex only.
  mediaReviewsVisibility(AccountPreferenceValueKind.mediaReviewsVisibility),

  /// SDH handling for subtitle *searches*. Plex
  /// `defaultSubtitleAccessibility`. Enforced by the client. Plex only.
  subtitleAccessibility(AccountPreferenceValueKind.subtitleAccessibility),

  /// Forced-subtitle handling for subtitle *searches*. Plex
  /// `defaultSubtitleForced`. Enforced by the client. Plex only.
  forcedSubtitles(AccountPreferenceValueKind.forcedSubtitles),

  /// Keep a finished series in Next Up while the user rewatches it.
  ///
  /// Jellyfin only, and the one key here with no field of its own on the
  /// server: `/Shows/NextUp` takes `EnableRewatching` per request and
  /// `UserConfiguration` has no twin, so Plezy stores it in the account's
  /// `DisplayPreferences` custom prefs and sends the parameter itself. That is
  /// a deliberate departure from jellyfin-web, which keeps the same switch in
  /// browser local storage and therefore loses it on every new device; the
  /// store Plezy uses is keyed by user, so the choice follows the account.
  rewatchingInNextUp(AccountPreferenceValueKind.boolean);

  const AccountPreferenceKey(this.valueKind);

  /// Shape of this key's value, so transports and UI can switch exhaustively.
  final AccountPreferenceValueKind valueKind;

  /// Whether the *server* applies this preference when answering queries, so a
  /// client must store it and otherwise stay out of the way. False means the
  /// client has to honour the value itself.
  bool get appliedByServer => switch (this) {
    AccountPreferenceKey.preferredAudioLanguage ||
    AccountPreferenceKey.autoSelectAudio ||
    AccountPreferenceKey.preferredSubtitleLanguage ||
    AccountPreferenceKey.subtitleMode ||
    AccountPreferenceKey.displayMissingEpisodes ||
    AccountPreferenceKey.hidePlayedInLatest ||
    AccountPreferenceKey.displayCollectionsView => true,
    AccountPreferenceKey.rememberAudioSelections ||
    AccountPreferenceKey.rememberSubtitleSelections ||
    AccountPreferenceKey.autoPlayNextEpisode ||
    AccountPreferenceKey.watchedIndicator ||
    AccountPreferenceKey.mediaReviewsVisibility ||
    AccountPreferenceKey.subtitleAccessibility ||
    AccountPreferenceKey.forcedSubtitles ||
    AccountPreferenceKey.rewatchingInNextUp => false,
  };
}

/// Value shape of an [AccountPreferenceKey].
enum AccountPreferenceValueKind {
  boolean,

  /// ISO 639-1 code, or null for "no preference". Mappers widen to whatever
  /// their backend stores.
  languageCode,
  subtitleMode,
  watchedIndicator,
  mediaReviewsVisibility,
  subtitleAccessibility,
  forcedSubtitles,
}

/// Which item types get a watched badge (Plex `watchedIndicator`).
enum WatchedIndicatorScope {
  none(0),
  moviesAndShows(1),
  movies(2),
  shows(3);

  const WatchedIndicatorScope(this.plexValue);
  final int plexValue;

  static WatchedIndicatorScope? fromPlexValue(int? value) =>
      value == null ? null : WatchedIndicatorScope.values.where((v) => v.plexValue == value).firstOrNull;
}

/// Whose ratings and reviews to surface (Plex `mediaReviewsVisibility`).
enum MediaReviewsVisibility {
  usersAndCritics(0),
  usersOnly(1),
  criticsOnly(2),
  nobody(3);

  const MediaReviewsVisibility(this.plexValue);
  final int plexValue;

  static MediaReviewsVisibility? fromPlexValue(int? value) =>
      value == null ? null : MediaReviewsVisibility.values.where((v) => v.plexValue == value).firstOrNull;
}

/// SDH preference for subtitle searches (Plex `defaultSubtitleAccessibility`).
enum SubtitleAccessibilityPreference {
  preferNonSdh(0),
  preferSdh(1),
  onlySdh(2),
  onlyNonSdh(3);

  const SubtitleAccessibilityPreference(this.plexValue);
  final int plexValue;

  static SubtitleAccessibilityPreference? fromPlexValue(int? value) =>
      value == null ? null : SubtitleAccessibilityPreference.values.where((v) => v.plexValue == value).firstOrNull;
}

/// Forced-subtitle preference for subtitle searches (Plex
/// `defaultSubtitleForced`).
enum ForcedSubtitlePreference {
  preferNonForced(0),
  preferForced(1),
  onlyForced(2),
  onlyNonForced(3);

  const ForcedSubtitlePreference(this.plexValue);
  final int plexValue;

  static ForcedSubtitlePreference? fromPlexValue(int? value) =>
      value == null ? null : ForcedSubtitlePreference.values.where((v) => v.plexValue == value).firstOrNull;
}

/// A read snapshot of one account's server-stored preferences.
///
/// Null means "unset or not supported by this backend"; consult
/// [AccountPreferencesCapabilities] to tell those apart. Language fields keep
/// the **server's own spelling** (Jellyfin returns 639-2 `deu`, Plex returns
/// 639-1 `de`) because [MediaServerUserProfile] consumers match with
/// [LanguageCodes.getVariations]; the UI reads the `*Code1` accessors instead.
class AccountPreferences implements MediaServerUserProfile {
  const AccountPreferences({
    this.preferredAudioLanguage,
    this.playDefaultAudioTrack,
    this.preferredSubtitleLanguage,
    this.subtitlePlaybackMode,
    this.rememberAudioSelections,
    this.rememberSubtitleSelections,
    this.autoPlayNextEpisode,
    this.displayMissingEpisodes,
    this.hidePlayedInLatest,
    this.displayCollectionsView,
    this.watchedIndicator,
    this.mediaReviewsVisibility,
    this.subtitleAccessibility,
    this.forcedSubtitles,
    this.rewatchingInNextUp,
  });

  static const empty = AccountPreferences();

  final String? preferredAudioLanguage;
  final bool? playDefaultAudioTrack;
  final String? preferredSubtitleLanguage;
  final SubtitlePlaybackMode? subtitlePlaybackMode;
  final bool? rememberAudioSelections;
  final bool? rememberSubtitleSelections;
  final bool? autoPlayNextEpisode;
  final bool? displayMissingEpisodes;
  final bool? hidePlayedInLatest;
  final bool? displayCollectionsView;
  final WatchedIndicatorScope? watchedIndicator;
  final MediaReviewsVisibility? mediaReviewsVisibility;
  final SubtitleAccessibilityPreference? subtitleAccessibility;
  final ForcedSubtitlePreference? forcedSubtitles;
  final bool? rewatchingInNextUp;

  /// Preferred audio language narrowed to ISO 639-1 for pickers.
  String? get preferredAudioLanguageCode1 => _code1(preferredAudioLanguage);

  /// Preferred subtitle language narrowed to ISO 639-1 for pickers.
  String? get preferredSubtitleLanguageCode1 => _code1(preferredSubtitleLanguage);

  static String? _code1(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return LanguageCodes.getIso6391Code(raw) ?? raw;
  }

  /// Typed read of a single key, for generic UI rows.
  Object? operator [](AccountPreferenceKey key) => switch (key) {
    AccountPreferenceKey.preferredAudioLanguage => preferredAudioLanguageCode1,
    AccountPreferenceKey.autoSelectAudio => playDefaultAudioTrack,
    AccountPreferenceKey.preferredSubtitleLanguage => preferredSubtitleLanguageCode1,
    AccountPreferenceKey.subtitleMode => subtitlePlaybackMode,
    AccountPreferenceKey.rememberAudioSelections => rememberAudioSelections,
    AccountPreferenceKey.rememberSubtitleSelections => rememberSubtitleSelections,
    AccountPreferenceKey.autoPlayNextEpisode => autoPlayNextEpisode,
    AccountPreferenceKey.displayMissingEpisodes => displayMissingEpisodes,
    AccountPreferenceKey.hidePlayedInLatest => hidePlayedInLatest,
    AccountPreferenceKey.displayCollectionsView => displayCollectionsView,
    AccountPreferenceKey.watchedIndicator => watchedIndicator,
    AccountPreferenceKey.mediaReviewsVisibility => mediaReviewsVisibility,
    AccountPreferenceKey.subtitleAccessibility => subtitleAccessibility,
    AccountPreferenceKey.forcedSubtitles => forcedSubtitles,
    AccountPreferenceKey.rewatchingInNextUp => rewatchingInNextUp,
  };

  // --- MediaServerUserProfile ------------------------------------------------
  // Implemented so the account cache can feed TrackSelectionService directly
  // instead of maintaining a second fetch path for the same fields.

  /// Defaults to true, matching both backends' own defaults
  /// (`PlayDefaultAudioTrack` / `autoSelectAudio`) when unset.
  @override
  bool get autoSelectAudio => playDefaultAudioTrack ?? true;

  @override
  String? get defaultAudioLanguage => preferredAudioLanguage;

  @override
  String? get defaultSubtitleLanguage => preferredSubtitleLanguage;

  @override
  SubtitlePlaybackMode? get subtitleMode => subtitlePlaybackMode;
}

/// A sparse set of changes to apply to one account.
///
/// Writes are patch-shaped because both backends demand it for different
/// reasons: Plex Web sends only the changed keys as query parameters, and
/// Jellyfin's `POST /Users/Configuration` replaces the whole object against
/// constructor defaults, so its transport must merge the patch into a freshly
/// read `Configuration` and preserve the fields Plezy does not model
/// (`OrderedViews`, `CastReceiverId`, …).
class AccountPreferencesPatch {
  AccountPreferencesPatch(Map<AccountPreferenceKey, Object?> values)
    : _values = Map.unmodifiable({for (final entry in values.entries) entry.key: _checked(entry.key, entry.value)});

  AccountPreferencesPatch.of(AccountPreferenceKey key, Object? value) : this({key: value});

  final Map<AccountPreferenceKey, Object?> _values;

  Map<AccountPreferenceKey, Object?> get values => _values;

  Iterable<AccountPreferenceKey> get keys => _values.keys;

  bool get isEmpty => _values.isEmpty;

  bool get isNotEmpty => _values.isNotEmpty;

  bool contains(AccountPreferenceKey key) => _values.containsKey(key);

  /// Value for [key], or null when unset *or* explicitly cleared — callers
  /// gate on [contains] first.
  Object? operator [](AccountPreferenceKey key) => _values[key];

  bool? boolAt(AccountPreferenceKey key) => _values[key] as bool?;

  String? languageAt(AccountPreferenceKey key) => _values[key] as String?;

  AccountPreferencesPatch merge(AccountPreferencesPatch other) =>
      AccountPreferencesPatch({..._values, ...other._values});

  static Object? _checked(AccountPreferenceKey key, Object? value) {
    assert(() {
      if (value == null) return true;
      final ok = switch (key.valueKind) {
        AccountPreferenceValueKind.boolean => value is bool,
        AccountPreferenceValueKind.languageCode => value is String,
        AccountPreferenceValueKind.subtitleMode => value is SubtitlePlaybackMode,
        AccountPreferenceValueKind.watchedIndicator => value is WatchedIndicatorScope,
        AccountPreferenceValueKind.mediaReviewsVisibility => value is MediaReviewsVisibility,
        AccountPreferenceValueKind.subtitleAccessibility => value is SubtitleAccessibilityPreference,
        AccountPreferenceValueKind.forcedSubtitles => value is ForcedSubtitlePreference,
      };
      if (!ok) {
        throw ArgumentError('AccountPreferencesPatch: ${value.runtimeType} is not valid for ${key.name}');
      }
      return true;
    }());
    return value;
  }

  @override
  String toString() => 'AccountPreferencesPatch(${_values.keys.map((k) => k.name).join(',')})';
}

/// What one backend actually stores, so the UI can hide rows it cannot write
/// and callers can distinguish "unset" from "unsupported".
class AccountPreferencesCapabilities {
  const AccountPreferencesCapabilities({required this.supportedKeys, required this.subtitleModes});

  /// Jellyfin: `UserConfiguration`, plus [AccountPreferenceKey.rewatchingInNextUp]
  /// in the account's `DisplayPreferences` custom prefs.
  ///
  /// [AccountPreferenceKey.rememberAudioSelections],
  /// [AccountPreferenceKey.rememberSubtitleSelections] and
  /// [AccountPreferenceKey.autoPlayNextEpisode] are read and round-tripped —
  /// the whole-object write must never reset them — but are deliberately **not**
  /// editable here. Plezy already owns each of those decisions locally
  /// (`SettingsService.rememberTrackSelections`, `followServerTrackSelections`,
  /// `autoPlayNextEpisode`, the last of which is also a toggle in the player's
  /// settings sheet), those local prefs are the only ones the playback path
  /// reads, and they are the only answer available for Plex, which stores no
  /// twin. Surfacing a second switch for the same behaviour would let the two
  /// disagree with no rule for which wins. Making the account authoritative
  /// instead means threading per-account state into `TrackManager`,
  /// `PlaybackProgressTracker` and the in-player sheet, and splitting one local
  /// toggle into Jellyfin's separate audio/subtitle flags — a playback-path
  /// change that belongs in its own commit, not in this section.
  static const jellyfin = AccountPreferencesCapabilities(
    supportedKeys: {
      AccountPreferenceKey.preferredAudioLanguage,
      AccountPreferenceKey.autoSelectAudio,
      AccountPreferenceKey.preferredSubtitleLanguage,
      AccountPreferenceKey.subtitleMode,
      AccountPreferenceKey.displayMissingEpisodes,
      AccountPreferenceKey.hidePlayedInLatest,
      AccountPreferenceKey.displayCollectionsView,
      AccountPreferenceKey.rewatchingInNextUp,
    },
    subtitleModes: _mediaBrowserSubtitleModes,
  );

  /// Emby: the same `UserConfiguration` field set, minus rewatching —
  /// `/Shows/NextUp` has no `EnableRewatching` there
  /// ([MediaBrowserDialect.supportsNextUpRewatching]), so storing the switch
  /// would promise behaviour the server cannot deliver.
  static const emby = AccountPreferencesCapabilities(
    supportedKeys: {
      AccountPreferenceKey.preferredAudioLanguage,
      AccountPreferenceKey.autoSelectAudio,
      AccountPreferenceKey.preferredSubtitleLanguage,
      AccountPreferenceKey.subtitleMode,
      AccountPreferenceKey.displayMissingEpisodes,
      AccountPreferenceKey.hidePlayedInLatest,
      AccountPreferenceKey.displayCollectionsView,
    },
    subtitleModes: _mediaBrowserSubtitleModes,
  );

  static const _mediaBrowserSubtitleModes = {
    SubtitlePlaybackMode.defaultMode,
    SubtitlePlaybackMode.always,
    SubtitlePlaybackMode.onlyForced,
    SubtitlePlaybackMode.none,
    SubtitlePlaybackMode.smart,
  };

  /// plex.tv `/api/v2/user/profile`. `autoSelectSubtitle` has three states
  /// only: manual (`none`), with foreign audio (`smart`), always (`always`).
  static const plex = AccountPreferencesCapabilities(
    supportedKeys: {
      AccountPreferenceKey.preferredAudioLanguage,
      AccountPreferenceKey.autoSelectAudio,
      AccountPreferenceKey.preferredSubtitleLanguage,
      AccountPreferenceKey.subtitleMode,
      AccountPreferenceKey.watchedIndicator,
      AccountPreferenceKey.mediaReviewsVisibility,
      AccountPreferenceKey.subtitleAccessibility,
      AccountPreferenceKey.forcedSubtitles,
    },
    subtitleModes: {SubtitlePlaybackMode.none, SubtitlePlaybackMode.smart, SubtitlePlaybackMode.always},
  );

  static const unsupported = AccountPreferencesCapabilities(supportedKeys: {}, subtitleModes: {});

  final Set<AccountPreferenceKey> supportedKeys;

  /// Subtitle modes this backend can store. Empty when
  /// [AccountPreferenceKey.subtitleMode] is unsupported.
  final Set<SubtitlePlaybackMode> subtitleModes;

  bool supports(AccountPreferenceKey key) => supportedKeys.contains(key);

  bool get isEmpty => supportedKeys.isEmpty;
}
