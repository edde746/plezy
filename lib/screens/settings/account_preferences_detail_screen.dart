import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/account_preferences.dart';
import '../../media/account_preferences_target.dart';
import '../../media/media_server_user_profile.dart';
import '../../services/account_preferences_repository.dart';
import '../../utils/app_logger.dart';
import '../../utils/language_codes.dart';
import '../../widgets/account_setting_tile.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import '../libraries/state_messages.dart';
import 'settings_utils.dart';

/// "No preference" in a language row.
///
/// The empty string, not `null`: it is what Jellyfin returns for a language it
/// has no preference for, what [AccountPreferences] narrows an empty value to,
/// and — being non-null — it lets the row tell "the user chose no preference"
/// apart from "the picker was dismissed". Patches carry `null` instead, because
/// that is what the transports read as "clear this".
const _noLanguage = '';

/// Every ISO 639-1 language as a picker option, built once: both language rows
/// share the list, [LanguageCodes.getAllLanguages] allocates and sorts a fresh
/// copy per call, and the body rebuilds after every write. The names come from
/// the generated ISO table rather than translations, so caching is safe across
/// a locale change.
final _languageOptions = <DialogOption<String>>[
  for (final language in LanguageCodes.getAllLanguages()) DialogOption(value: language.code, title: language.name),
];

/// One account's server-stored preferences.
///
/// Nothing on this screen is a device setting. Every row reads and writes the
/// account's own record — Jellyfin/Emby `UserConfiguration`, plex.tv
/// `/api/v2/user/profile` — so a change here follows the account into every
/// Plezy install and into the server's own apps.
///
/// The audio and subtitle rows in particular are *applied by the server* when
/// it answers a query (see [AccountPreferenceKey.appliedByServer]): storing the
/// value is the whole job. Do not add client-side enforcement on top of them,
/// or the preference gets applied twice.
class AccountPreferencesDetailScreen extends StatelessWidget {
  final AccountPreferenceTarget target;

  const AccountPreferencesDetailScreen({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return SettingsPage.slivers(
      title: Text(target.label),
      slivers: [AccountPreferencesBody(target: target)],
    );
  }
}

/// The rows themselves, as a sliver, so the section's entry point can host them
/// inline when there is only one account instead of pushing a second screen
/// whose list has exactly one row.
class AccountPreferencesBody extends StatefulWidget {
  final AccountPreferenceTarget target;

  const AccountPreferencesBody({super.key, required this.target});

  @override
  State<AccountPreferencesBody> createState() => _AccountPreferencesBodyState();
}

class _AccountPreferencesBodyState extends State<AccountPreferencesBody> {
  late final AccountPreferencesRepository _repository;

  /// Loaded values; null while the first (or a retried) read is outstanding.
  AccountPreferences? _preferences;

  /// Why the read failed. Takes precedence over [_preferences] so a failed
  /// retry never leaves editable rows backed by values the server rejected.
  Object? _error;

  @override
  void initState() {
    super.initState();
    _repository = context.read<AccountPreferencesRepository>();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final preferences = await _repository.load(widget.target.ref, forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _error = null;
      });
    } on Exception catch (error, stackTrace) {
      appLogger.e('Account preferences load failed', error: error, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _retry() {
    setState(() {
      _preferences = null;
      _error = null;
    });
    unawaited(_load(forceRefresh: true));
  }

  /// Writes one key and adopts the account's state afterwards. Failures
  /// propagate so the row that started the write reverts and reports them.
  Future<void> _write(AccountPreferenceKey key, Object? value) async {
    final updated = await _repository.update(widget.target.ref, AccountPreferencesPatch.of(key, value));
    if (!mounted) return;
    setState(() => _preferences = updated);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      final unavailable = error is AccountPreferencesUnavailableException;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateWidget(
          message: unavailable ? t.accountPreferences.unavailable : t.accountPreferences.loadFailed,
          icon: unavailable ? Symbols.cloud_off_rounded : Symbols.sync_problem_rounded,
          onRetry: _retry,
          actionUseBackgroundFocus: true,
        ),
      );
    }

    final preferences = _preferences;
    if (preferences == null) return LoadingIndicatorBox.sliver;

    // Capabilities are a pure function of the backend, so the rows a Plex
    // account can never store are absent rather than disabled.
    final capabilities = _repository.capabilitiesFor(widget.target.ref);
    final audio = _audioRows(capabilities, preferences);
    final library = _libraryRows(capabilities, preferences);
    final personal = _personalMediaRows(capabilities, preferences);
    final theme = Theme.of(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Every group below carries a title, and SettingsSectionHeader already
        // pads 24 above it; a bottom inset here would stack on top of that.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            t.accountPreferences.storedOnAccount,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (audio.isNotEmpty) SettingsGroup(title: t.accountPreferences.groups.audioAndSubtitles, children: audio),
        if (library.isNotEmpty) SettingsGroup(title: t.accountPreferences.groups.libraryDisplay, children: library),
        if (personal.isNotEmpty) SettingsGroup(title: t.accountPreferences.groups.personalMedia, children: personal),
        const SizedBox(height: 24),
      ]),
    );
  }

  List<Widget> _audioRows(AccountPreferencesCapabilities capabilities, AccountPreferences preferences) {
    // Both language rows share one option list; the "no preference" entry is
    // prepended per build because its label is translated.
    final languageOptions = <DialogOption<String>>[
      DialogOption(value: _noLanguage, title: t.accountPreferences.noPreference),
      ..._languageOptions,
    ];

    return [
      if (capabilities.supports(AccountPreferenceKey.preferredAudioLanguage))
        _languageRow(
          preferenceKey: AccountPreferenceKey.preferredAudioLanguage,
          icon: Symbols.audiotrack_rounded,
          title: t.accountPreferences.preferredAudioLanguage,
          code1: preferences.preferredAudioLanguageCode1,
          options: languageOptions,
        ),
      if (capabilities.supports(AccountPreferenceKey.autoSelectAudio))
        AccountSettingSwitchTile(
          value: preferences.autoSelectAudio,
          icon: Symbols.graphic_eq_rounded,
          title: t.accountPreferences.autoSelectAudio,
          subtitle: t.accountPreferences.autoSelectAudioDescription,
          onChanged: (value) => _write(AccountPreferenceKey.autoSelectAudio, value),
        ),
      if (capabilities.supports(AccountPreferenceKey.preferredSubtitleLanguage))
        _languageRow(
          preferenceKey: AccountPreferenceKey.preferredSubtitleLanguage,
          icon: Symbols.subtitles_rounded,
          title: t.accountPreferences.preferredSubtitleLanguage,
          code1: preferences.preferredSubtitleLanguageCode1,
          options: languageOptions,
        ),
      if (capabilities.supports(AccountPreferenceKey.subtitleMode))
        AccountSettingSelectionTile<SubtitlePlaybackMode>(
          value: preferences.subtitlePlaybackMode,
          icon: Symbols.closed_caption_rounded,
          title: t.accountPreferences.subtitleMode,
          subtitleBuilder: (mode) => mode == null ? t.accountPreferences.notSet : _subtitleModeLabel(mode),
          options: [
            // Enum order, not set order, so the list reads the same every time.
            for (final mode in SubtitlePlaybackMode.values)
              if (capabilities.subtitleModes.contains(mode))
                DialogOption(value: mode, title: _subtitleModeLabel(mode), subtitle: _subtitleModeDescription(mode)),
          ],
          onChanged: (mode) => _write(AccountPreferenceKey.subtitleMode, mode),
        ),
      if (capabilities.supports(AccountPreferenceKey.subtitleAccessibility))
        AccountSettingSelectionTile<SubtitleAccessibilityPreference>(
          value: preferences.subtitleAccessibility,
          icon: Symbols.hearing_rounded,
          title: t.accountPreferences.subtitleAccessibility,
          subtitleBuilder: (value) => value == null ? t.accountPreferences.notSet : _accessibilityLabel(value),
          options: [
            for (final value in SubtitleAccessibilityPreference.values)
              DialogOption(value: value, title: _accessibilityLabel(value)),
          ],
          onChanged: (value) => _write(AccountPreferenceKey.subtitleAccessibility, value),
        ),
      if (capabilities.supports(AccountPreferenceKey.forcedSubtitles))
        AccountSettingSelectionTile<ForcedSubtitlePreference>(
          value: preferences.forcedSubtitles,
          icon: Symbols.flag_rounded,
          title: t.accountPreferences.forcedSubtitles,
          subtitleBuilder: (value) => value == null ? t.accountPreferences.notSet : _forcedLabel(value),
          options: [
            for (final value in ForcedSubtitlePreference.values) DialogOption(value: value, title: _forcedLabel(value)),
          ],
          onChanged: (value) => _write(AccountPreferenceKey.forcedSubtitles, value),
        ),
    ];
  }

  List<Widget> _libraryRows(AccountPreferencesCapabilities capabilities, AccountPreferences preferences) => [
    if (capabilities.supports(AccountPreferenceKey.displayMissingEpisodes))
      AccountSettingSwitchTile(
        value: preferences.displayMissingEpisodes,
        icon: Symbols.dvr_rounded,
        title: t.accountPreferences.displayMissingEpisodes,
        subtitle: t.accountPreferences.displayMissingEpisodesDescription,
        onChanged: (value) => _write(AccountPreferenceKey.displayMissingEpisodes, value),
      ),
    if (capabilities.supports(AccountPreferenceKey.hidePlayedInLatest))
      AccountSettingSwitchTile(
        value: preferences.hidePlayedInLatest,
        icon: Symbols.visibility_off_rounded,
        title: t.accountPreferences.hidePlayedInLatest,
        subtitle: t.accountPreferences.hidePlayedInLatestDescription,
        onChanged: (value) => _write(AccountPreferenceKey.hidePlayedInLatest, value),
      ),
    if (capabilities.supports(AccountPreferenceKey.displayCollectionsView))
      AccountSettingSwitchTile(
        value: preferences.displayCollectionsView,
        icon: Symbols.collections_rounded,
        title: t.accountPreferences.displayCollectionsView,
        subtitle: t.accountPreferences.displayCollectionsViewDescription,
        onChanged: (value) => _write(AccountPreferenceKey.displayCollectionsView, value),
      ),
    if (capabilities.supports(AccountPreferenceKey.rewatchingInNextUp))
      AccountSettingSwitchTile(
        value: preferences.rewatchingInNextUp ?? false,
        icon: Symbols.replay_rounded,
        title: t.accountPreferences.rewatchingInNextUp,
        subtitle: t.accountPreferences.rewatchingInNextUpDescription,
        onChanged: (value) => _write(AccountPreferenceKey.rewatchingInNextUp, value),
      ),
  ];

  List<Widget> _personalMediaRows(AccountPreferencesCapabilities capabilities, AccountPreferences preferences) => [
    if (capabilities.supports(AccountPreferenceKey.watchedIndicator))
      AccountSettingSelectionTile<WatchedIndicatorScope>(
        value: preferences.watchedIndicator,
        icon: Symbols.visibility_rounded,
        title: t.accountPreferences.watchedIndicator,
        subtitleBuilder: (value) => value == null ? t.accountPreferences.notSet : _watchedIndicatorLabel(value),
        options: [
          for (final value in WatchedIndicatorScope.values)
            DialogOption(value: value, title: _watchedIndicatorLabel(value)),
        ],
        onChanged: (value) => _write(AccountPreferenceKey.watchedIndicator, value),
      ),
    if (capabilities.supports(AccountPreferenceKey.mediaReviewsVisibility))
      AccountSettingSelectionTile<MediaReviewsVisibility>(
        value: preferences.mediaReviewsVisibility,
        icon: Symbols.reviews_rounded,
        title: t.accountPreferences.mediaReviewsVisibility,
        subtitleBuilder: (value) => value == null ? t.accountPreferences.notSet : _reviewsLabel(value),
        options: [
          for (final value in MediaReviewsVisibility.values) DialogOption(value: value, title: _reviewsLabel(value)),
        ],
        onChanged: (value) => _write(AccountPreferenceKey.mediaReviewsVisibility, value),
      ),
  ];

  Widget _languageRow({
    required AccountPreferenceKey preferenceKey,
    required IconData icon,
    required String title,
    required String? code1,
    required List<DialogOption<String>> options,
  }) {
    return AccountSettingSelectionTile<String>(
      value: code1 ?? _noLanguage,
      icon: icon,
      title: title,
      subtitleBuilder: (code) => code == null || code == _noLanguage
          ? t.accountPreferences.noPreference
          : LanguageCodes.getLanguageName(code) ?? code,
      options: options,
      onChanged: (code) => _write(preferenceKey, code == _noLanguage ? null : code),
    );
  }
}

/// Labels shared by a row's subtitle and its picker, so the chosen option and
/// the collapsed row never word the same value differently.
String _subtitleModeLabel(SubtitlePlaybackMode mode) => switch (mode) {
  SubtitlePlaybackMode.none => t.accountPreferences.subtitleModes.none,
  SubtitlePlaybackMode.defaultMode => t.accountPreferences.subtitleModes.defaultMode,
  SubtitlePlaybackMode.always => t.accountPreferences.subtitleModes.always,
  SubtitlePlaybackMode.onlyForced => t.accountPreferences.subtitleModes.onlyForced,
  SubtitlePlaybackMode.smart => t.accountPreferences.subtitleModes.smart,
};

String _subtitleModeDescription(SubtitlePlaybackMode mode) => switch (mode) {
  SubtitlePlaybackMode.none => t.accountPreferences.subtitleModes.noneDescription,
  SubtitlePlaybackMode.defaultMode => t.accountPreferences.subtitleModes.defaultModeDescription,
  SubtitlePlaybackMode.always => t.accountPreferences.subtitleModes.alwaysDescription,
  SubtitlePlaybackMode.onlyForced => t.accountPreferences.subtitleModes.onlyForcedDescription,
  SubtitlePlaybackMode.smart => t.accountPreferences.subtitleModes.smartDescription,
};

String _accessibilityLabel(SubtitleAccessibilityPreference value) => switch (value) {
  SubtitleAccessibilityPreference.preferNonSdh => t.accountPreferences.subtitleAccessibilityOptions.preferNonSdh,
  SubtitleAccessibilityPreference.preferSdh => t.accountPreferences.subtitleAccessibilityOptions.preferSdh,
  SubtitleAccessibilityPreference.onlySdh => t.accountPreferences.subtitleAccessibilityOptions.onlySdh,
  SubtitleAccessibilityPreference.onlyNonSdh => t.accountPreferences.subtitleAccessibilityOptions.onlyNonSdh,
};

String _forcedLabel(ForcedSubtitlePreference value) => switch (value) {
  ForcedSubtitlePreference.preferNonForced => t.accountPreferences.forcedSubtitleOptions.preferNonForced,
  ForcedSubtitlePreference.preferForced => t.accountPreferences.forcedSubtitleOptions.preferForced,
  ForcedSubtitlePreference.onlyForced => t.accountPreferences.forcedSubtitleOptions.onlyForced,
  ForcedSubtitlePreference.onlyNonForced => t.accountPreferences.forcedSubtitleOptions.onlyNonForced,
};

String _watchedIndicatorLabel(WatchedIndicatorScope value) => switch (value) {
  WatchedIndicatorScope.none => t.accountPreferences.watchedIndicatorOptions.none,
  WatchedIndicatorScope.moviesAndShows => t.accountPreferences.watchedIndicatorOptions.moviesAndShows,
  WatchedIndicatorScope.movies => t.accountPreferences.watchedIndicatorOptions.movies,
  WatchedIndicatorScope.shows => t.accountPreferences.watchedIndicatorOptions.shows,
};

String _reviewsLabel(MediaReviewsVisibility value) => switch (value) {
  MediaReviewsVisibility.usersAndCritics => t.accountPreferences.mediaReviewsOptions.usersAndCritics,
  MediaReviewsVisibility.usersOnly => t.accountPreferences.mediaReviewsOptions.usersOnly,
  MediaReviewsVisibility.criticsOnly => t.accountPreferences.mediaReviewsOptions.criticsOnly,
  MediaReviewsVisibility.nobody => t.accountPreferences.mediaReviewsOptions.nobody,
};
