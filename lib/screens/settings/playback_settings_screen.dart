import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../models/audio_quality_preset.dart';
import '../../models/transcode_quality_preset.dart';
import '../../models/player_setting_scope.dart';
import '../../providers/libraries_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/quality_preset_labels.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart';
import '../../services/storage_service.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'external_player_screen.dart';
import 'mpv_config_screen.dart';
import 'settings_utils.dart';
import 'subtitle_styling_screen.dart';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  KeyboardShortcutsService? _keyboardService;
  String? _prerollLibraryGlobalKey;
  Set<String> _prerollSelectedItemKeys = {};

  @override
  void initState() {
    super.initState();
    if (KeyboardShortcutsService.isPlatformSupported()) {
      KeyboardShortcutsService.getInstance().then((s) {
        if (mounted) _keyboardService = s;
      });
    }
    _loadPrerollStorage();
  }

  Future<void> _loadPrerollStorage() async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    setState(() {
      _prerollLibraryGlobalKey = storage.getPrerollLibraryGlobalKey();
      _prerollSelectedItemKeys = storage.getPrerollSelectedItemKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformDetector.isMobile(context);

    // Visibility of several Player tiles is pref-reactive; hoisted here so
    // group children can use plain `if`s (a SizedBox.shrink() child would
    // corrupt the SettingsGroup corner shapes).
    return SettingsBuilder(
      prefs: const [
        SettingsService.useExoPlayer,
        SettingsService.matchRefreshRate,
        SettingsService.matchDynamicRange,
        SettingsService.matchContentFrameRate,
        SettingsService.matchContentResolution,
        SettingsService.audioDownmix,
      ],
      builder: (context) {
        final svc = SettingsService.instance;
        final exoActive = Platform.isAndroid && svc.read(SettingsService.useExoPlayer);
        final downmixOn = svc.read(SettingsService.audioDownmix);
        final showDisplaySwitchDelay =
            PlatformDetector.isAppleTV() ||
            (Platform.isWindows &&
                (svc.read(SettingsService.matchRefreshRate) || svc.read(SettingsService.matchDynamicRange))) ||
            (Platform.isAndroid &&
                (svc.read(SettingsService.matchContentFrameRate) || svc.read(SettingsService.matchContentResolution)));

        return SettingsPage(
          title: Text(t.settings.videoPlayback),
          children: [
            SettingsGroup(
              title: t.settings.player,
              children: [
                if (Platform.isAndroid) _playerBackendSelector(),
                if (PlatformDetector.supportsExternalPlayers()) _externalPlayerTile(),
                if (!exoActive) _mpvConfigTile(),
                _hardwareDecodingTile(),
                if (exoActive) _playbackBufferTile(),
                if (exoActive) _tunneledPlaybackTile(),
                if (PlatformDetector.supportsPictureInPicture()) _autoPipTile(),
              ],
            ),

            SettingsGroup(
              title: t.settings.videoAndDisplay,
              children: [
                if (Platform.isAndroid) _matchContentFrameRateTile(),
                if (Platform.isAndroid && PlatformDetector.isTV()) _matchContentResolutionTile(),
                if (Platform.isWindows) _matchRefreshRateTile(),
                if (Platform.isWindows) _matchDynamicRangeTile(),
                if (showDisplaySwitchDelay) _displaySwitchDelayTile(),
                if (Platform.isAndroid) _dvConversionModeTile(),
                // mpv-only (#2149): ExoPlayer has no filter chain, so the
                // tile disappears while the ExoPlayer backend is active.
                if (!exoActive) _deinterlaceTile(),
                // TODO: "Extend video into display cutout" toggle (#1769)
                // goes here, Android-only.
              ],
            ),

            SettingsGroup(
              title: t.settings.audio,
              children: [
                if (PlatformDetector.supportsAudioPassthrough()) _audioPassthroughTile(),
                _audioDownmixTile(),
                if (downmixOn) _downmixCenterBoostTile(),
                if (downmixOn) _downmixNormalizeTile(),
                _maxVolumeTile(),
              ],
            ),

            SettingsGroup(
              title: t.settings.quality,
              children: [
                _defaultQualityTile(),
                // Only a phone/tablet has a cellular radio; desktop and TV
                // never report a cellular-only connection.
                if (isMobile) _cellularQualityTile(),
                // TODO: "Remote streaming quality" selector (#2064) goes here,
                // mirroring cellularQualityPreset's nullable "same as default"
                // pattern; needs local/remote connection detection in the
                // failover client.
                _directPlayCoveredQualityTile(),
                _musicQualityTile(),
              ],
            ),

            SettingsGroup(
              title: t.settings.subtitles,
              children: [
                SettingNavigationTile(
                  icon: Symbols.subtitles_rounded,
                  title: t.settings.subtitleStyling,
                  subtitle: t.settings.subtitleStylingDescription,
                  destinationBuilder: (_) => const SubtitleStylingScreen(),
                ),
              ],
            ),

            _seekAndTimingGroup(),
            _autoPlayAndSkipGroup(),
            _behaviorGroup(context, isMobile),
            if (isMobile) _gesturesGroup(),
            _rememberPlayerChangesGroup(),
            _prerollGroup(context),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _seekAndTimingGroup() => SettingsGroup(
    title: t.settings.seekAndTiming,
    children: [
      SettingNumberTile(
        pref: SettingsService.seekTimeSmall,
        icon: Symbols.replay_10_rounded,
        title: t.settings.smallSkipDuration,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 1,
        max: 120,
        onAfterWrite: (_) => _keyboardService?.refreshFromStorage(),
      ),
      SettingNumberTile(
        pref: SettingsService.seekTimeLarge,
        icon: Symbols.replay_30_rounded,
        title: t.settings.largeSkipDuration,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 1,
        max: 120,
        onAfterWrite: (_) => _keyboardService?.refreshFromStorage(),
      ),
      SettingNumberTile(
        pref: SettingsService.rewindOnResume,
        icon: Symbols.replay_rounded,
        title: t.settings.rewindOnResume,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 0,
        max: 10,
      ),
      SettingNumberTile(
        pref: SettingsService.sleepTimerDuration,
        icon: Symbols.bedtime_rounded,
        title: t.settings.defaultSleepTimer,
        subtitleBuilder: (v) => t.settings.minutesUnit(minutes: v.toString()),
        labelText: t.settings.minutesLabel,
        suffixText: t.settings.minutesShort,
        min: 5,
        max: 240,
      ),
    ],
  );

  Widget _rememberPlayerChangesGroup() => SettingsGroup(
    title: t.settings.rememberPlayerChanges,
    children: [
      _playerScopeTile(
        pref: SettingsService.playbackSpeedScope,
        icon: Symbols.speed_rounded,
        title: t.settings.scopePlaybackSpeed,
      ),
      _playerScopeTile(
        pref: SettingsService.shaderPresetScope,
        icon: Symbols.auto_fix_high_rounded,
        title: t.settings.scopeShaderPreset,
      ),
      _playerScopeTile(
        pref: SettingsService.boxFitScope,
        icon: Symbols.aspect_ratio_rounded,
        title: t.settings.scopeAspectRatio,
      ),
      _playerScopeTile(
        pref: SettingsService.syncOffsetScope,
        icon: Symbols.sync_rounded,
        title: t.settings.scopeSyncOffsets,
      ),
    ],
  );

  Widget _playerScopeTile({
    required EnumPref<PlayerSettingScope> pref,
    required IconData icon,
    required String title,
  }) => SettingSelectionTile<PlayerSettingScope>(
    pref: pref,
    icon: icon,
    title: title,
    subtitleBuilder: (scope) => '${_playerScopeLabel(scope)} · ${t.settings.rememberPlayerChangesDescription}',
    options: PlayerSettingScope.values.map((s) => DialogOption(value: s, title: _playerScopeLabel(s))).toList(),
  );

  String _playerScopeLabel(PlayerSettingScope scope) => switch (scope) {
    PlayerSettingScope.off => t.settings.playerScopeOff,
    PlayerSettingScope.global => t.settings.playerScopeGlobal,
    PlayerSettingScope.library => t.settings.playerScopeLibrary,
    PlayerSettingScope.title => t.settings.playerScopeTitle,
  };

  Widget _behaviorGroup(BuildContext context, bool isMobile) => SettingsGroup(
    title: t.settings.behavior,
    children: [
      SettingSwitchTile(
        pref: SettingsService.rememberTrackSelections,
        icon: Symbols.bookmark_rounded,
        title: t.settings.rememberTrackSelections,
        subtitle: t.settings.rememberTrackSelectionsDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.followServerTrackSelections,
        icon: Symbols.dns_rounded,
        title: t.settings.followServerTrackSelections,
        subtitle: t.settings.followServerTrackSelectionsDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.resumeMusicOnLaunch,
        icon: Symbols.music_history_rounded,
        title: t.settings.resumeMusicOnLaunch,
        subtitle: t.settings.resumeMusicOnLaunchDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.showChapterMarkersOnTimeline,
        icon: Symbols.bookmarks_rounded,
        title: t.settings.showChapterMarkersOnTimeline,
        subtitle: t.settings.showChapterMarkersOnTimelineDescription,
      ),
      SettingSelectionTile<SpecialsOrdering>(
        pref: SettingsService.specialsOrdering,
        icon: Symbols.low_priority_rounded,
        title: t.settings.specialsOrdering,
        subtitleBuilder: (mode) => '${_specialsOrderingLabel(mode)} · ${t.settings.specialsOrderingDescription}',
        options: SpecialsOrdering.values.map((m) => DialogOption(value: m, title: _specialsOrderingLabel(m))).toList(),
      ),
      if (!isMobile)
        SettingSwitchTile(
          pref: SettingsService.clickVideoTogglesPlayback,
          icon: Symbols.play_pause_rounded,
          title: t.settings.clickVideoTogglesPlayback,
          subtitle: t.settings.clickVideoTogglesPlaybackDescription,
        ),
      if (PlatformDetector.isDesktopOS())
        SettingSwitchTile(
          pref: SettingsService.exitFullscreenOnPlayerClose,
          icon: Symbols.fullscreen_exit_rounded,
          title: t.settings.exitFullscreenOnPlayerClose,
          subtitle: t.settings.exitFullscreenOnPlayerCloseDescription,
        ),
      // TODO: "Enter fullscreen when playback starts" toggle (#1641) goes
      // here, desktop-only, paired with exitFullscreenOnPlayerClose.
    ],
  );

  String _specialsOrderingLabel(SpecialsOrdering mode) => switch (mode) {
    SpecialsOrdering.respectServer => t.settings.specialsOrderingServer,
    SpecialsOrdering.airDate => t.settings.specialsOrderingAirDate,
    SpecialsOrdering.specialsLast => t.settings.specialsOrderingLast,
  };

  Widget _autoPlayAndSkipGroup() => SettingsGroup(
    title: t.settings.autoPlayAndSkip,
    children: [
      // Also togglable from the in-player settings sheet; both write the same
      // pref, and this pref gates the play-next prompt.
      SettingSwitchTile(
        pref: SettingsService.autoPlayNextEpisode,
        icon: Symbols.skip_next_rounded,
        title: t.settings.autoPlayNextEpisode,
        subtitle: t.settings.autoPlayNextEpisodeDescription,
      ),
      SettingNumberTile(
        pref: SettingsService.playNextCountdown,
        icon: Symbols.timer_rounded,
        title: t.settings.playNextCountdown,
        subtitleBuilder: (v) =>
            v == 0 ? t.settings.playNextCountdownImmediate : t.settings.secondsUnit(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 0,
        max: 30,
      ),
      SettingSelectionTile<SkipMarkerMode>(
        pref: SettingsService.skipIntroMode,
        icon: Symbols.fast_forward_rounded,
        title: t.settings.skipIntroMode,
        subtitleBuilder: (mode) => '${_skipMarkerModeLabel(mode)} · ${_skipIntroModeDescription(mode)}',
        options: SkipMarkerMode.values.map((m) => DialogOption(value: m, title: _skipMarkerModeLabel(m))).toList(),
      ),
      SettingSelectionTile<SkipMarkerMode>(
        pref: SettingsService.skipCreditsMode,
        icon: Symbols.skip_next_rounded,
        title: t.settings.skipCreditsMode,
        subtitleBuilder: (mode) => '${_skipMarkerModeLabel(mode)} · ${_skipCreditsModeDescription(mode)}',
        options: SkipMarkerMode.values.map((m) => DialogOption(value: m, title: _skipMarkerModeLabel(m))).toList(),
      ),
      SettingSwitchTile(
        pref: SettingsService.forceSkipMarkerFallback,
        icon: Symbols.tune_rounded,
        title: t.settings.forceSkipMarkerFallback,
        subtitle: t.settings.forceSkipMarkerFallbackDescription,
      ),
      SettingNumberTile(
        pref: SettingsService.autoSkipDelay,
        icon: Symbols.timer_rounded,
        title: t.settings.autoSkipDelay,
        subtitleBuilder: (v) => t.settings.autoSkipDelayDescription(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 1,
        max: 30,
      ),
      SettingRegexTile(
        pref: SettingsService.introPattern,
        icon: Symbols.match_case_rounded,
        title: t.settings.introPattern,
        subtitle: t.settings.introPatternDescription,
        defaultValue: SettingsService.defaultIntroPattern,
      ),
      SettingRegexTile(
        pref: SettingsService.creditsPattern,
        icon: Symbols.match_case_rounded,
        title: t.settings.creditsPattern,
        subtitle: t.settings.creditsPatternDescription,
        defaultValue: SettingsService.defaultCreditsPattern,
      ),
    ],
  );

  String _skipMarkerModeLabel(SkipMarkerMode mode) => switch (mode) {
    SkipMarkerMode.off => t.settings.skipMarkerModeOff,
    SkipMarkerMode.button => t.settings.skipMarkerModeButton,
    SkipMarkerMode.auto => t.settings.skipMarkerModeAuto,
  };

  String _skipIntroModeDescription(SkipMarkerMode mode) => switch (mode) {
    SkipMarkerMode.off => t.settings.skipIntroModeOffDescription,
    SkipMarkerMode.button => t.settings.skipIntroModeButtonDescription,
    SkipMarkerMode.auto => t.settings.skipIntroModeAutoDescription,
  };

  String _skipCreditsModeDescription(SkipMarkerMode mode) => switch (mode) {
    SkipMarkerMode.off => t.settings.skipCreditsModeOffDescription,
    SkipMarkerMode.button => t.settings.skipCreditsModeButtonDescription,
    SkipMarkerMode.auto => t.settings.skipCreditsModeAutoDescription,
  };

  bool _isPrerollCapable(MediaLibrary library) => library.kind == MediaKind.movie || library.kind == MediaKind.clip;

  Widget _prerollGroup(BuildContext context) {
    final libraries = context.watch<LibrariesProvider>().libraries.where(_isPrerollCapable).toList();
    return SettingsBuilder(
      prefs: const [SettingsService.playPrerollsBeforeMovies],
      builder: (_) {
        final enabled = SettingsService.instance.read(SettingsService.playPrerollsBeforeMovies);
        MediaLibrary? library;
        for (final candidate in libraries) {
          if (candidate.globalKey == _prerollLibraryGlobalKey) {
            library = candidate;
            break;
          }
        }
        final selectedCount = _prerollSelectedItemKeys.length;
        final selectionSubtitle = library == null
            ? t.settings.prerollSelectionPickLibraryFirst
            : selectedCount == 0
            ? t.settings.prerollSelectionNoneSelected
            : t.settings.prerollSelectionCount(count: selectedCount.toString());

        return SettingsGroup(
          title: t.settings.prerolls,
          children: [
            SettingSwitchTile(
              pref: SettingsService.playPrerollsBeforeMovies,
              icon: Symbols.movie_rounded,
              title: t.settings.playPrerollsBeforeMovies,
              subtitle: t.settings.playPrerollsBeforeMoviesDescription,
            ),
            if (enabled)
              SettingNavigationTile(
                icon: Symbols.video_library_rounded,
                title: t.settings.prerollLibrary,
                subtitle: library?.title ?? t.settings.prerollLibraryNotSet,
                onTap: () => _showPrerollLibraryPicker(context, libraries),
              ),
            if (enabled && library != null)
              SettingNavigationTile(
                icon: Symbols.checklist_rounded,
                title: t.settings.prerollSelection,
                subtitle: selectionSubtitle,
                onTap: () => _showPrerollItemPicker(context, library!),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showPrerollLibraryPicker(BuildContext context, List<MediaLibrary> libraries) async {
    if (libraries.isEmpty) {
      showAppSnackBar(context, t.settings.prerollLibraryNoneFound);
      return;
    }
    final picked = await showOptionPickerDialog<MediaLibrary>(
      context,
      title: t.settings.prerollLibrary,
      options: [for (final library in libraries) (icon: null, label: library.title, value: library)],
    );
    if (picked == null) return;
    final storage = await StorageService.getInstance();
    await storage.savePrerollLibraryGlobalKey(picked.globalKey);
    await storage.savePrerollSelectedItemKeys(const {});
    if (!mounted) return;
    setState(() {
      _prerollLibraryGlobalKey = picked.globalKey;
      _prerollSelectedItemKeys = {};
    });
  }

  Future<void> _showPrerollItemPicker(BuildContext context, MediaLibrary library) async {
    await showScopedDialog<void>(
      context: context,
      builder: (_) => _PrerollItemPickerDialog(library: library),
    );
    if (!mounted) return;
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    setState(() => _prerollSelectedItemKeys = storage.getPrerollSelectedItemKeys());
  }

  /// Optional touch gestures on the player surface (#1810); the group only
  /// renders on mobile, matching where the gestures exist.
  Widget _gesturesGroup() => SettingsGroup(
    title: t.settings.gestures,
    children: [
      SettingSwitchTile(
        pref: SettingsService.gestureBrightnessSwipe,
        icon: Symbols.brightness_6_rounded,
        title: t.settings.gestureBrightnessSwipe,
        subtitle: t.settings.gestureBrightnessSwipeDescription,
      ),
      // Remember the last swiped level between playbacks (#2178).
      SettingSwitchTile(
        pref: SettingsService.rememberBrightnessLevel,
        icon: Symbols.settings_brightness_rounded,
        title: t.settings.rememberBrightnessLevel,
        subtitle: t.settings.rememberBrightnessLevelDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.gestureVolumeSwipe,
        icon: Symbols.volume_up_rounded,
        title: t.settings.gestureVolumeSwipe,
        subtitle: t.settings.gestureVolumeSwipeDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.gesturePinchToZoom,
        icon: Symbols.pinch_rounded,
        title: t.settings.gesturePinchToZoom,
        subtitle: t.settings.gesturePinchToZoomDescription,
      ),
    ],
  );

  Widget _playerBackendSelector() => SettingSegmentedTile<bool>(
    pref: SettingsService.useExoPlayer,
    icon: Symbols.play_circle_rounded,
    title: t.settings.playerBackend,
    segments: [
      ButtonSegment(value: true, label: Text(t.settings.exoPlayer)),
      ButtonSegment(value: false, label: Text(t.settings.mpv)),
    ],
  );

  Widget _externalPlayerTile() => SettingsBuilder(
    prefs: [SettingsService.useExternalPlayer, SettingsService.selectedExternalPlayer],
    builder: (context) {
      final svc = SettingsService.instance;
      final useExt = svc.read(SettingsService.useExternalPlayer);
      final player = svc.read(SettingsService.selectedExternalPlayer);
      return SettingNavigationTile(
        icon: Symbols.open_in_new_rounded,
        title: t.externalPlayer.title,
        subtitle: useExt
            ? (player.id == 'system_default' ? t.externalPlayer.systemDefault : player.name)
            : t.externalPlayer.off,
        destinationBuilder: (_) => const ExternalPlayerScreen(),
      );
    },
  );

  Widget _hardwareDecodingTile() => SettingSwitchTile(
    pref: SettingsService.enableHardwareDecoding,
    icon: Symbols.hardware_rounded,
    title: t.settings.hardwareDecoding,
    subtitle: t.settings.hardwareDecodingDescription,
  );

  Widget _autoPipTile() => SettingSwitchTile(
    pref: SettingsService.autoPip,
    icon: Symbols.picture_in_picture_alt_rounded,
    title: t.settings.autoPip,
    subtitle: t.settings.autoPipDescription,
  );

  Widget _matchContentFrameRateTile() => SettingSwitchTile(
    pref: SettingsService.matchContentFrameRate,
    icon: Symbols.display_settings_rounded,
    title: t.settings.matchContentFrameRate,
    subtitle: t.settings.matchContentFrameRateDescription,
  );

  // Android TV only: on phone/tablet panels "match the video's resolution"
  // would downshift the panel below native for most content, which is
  // surprising rather than useful. The native switch path itself is generic.
  Widget _matchContentResolutionTile() => SettingSwitchTile(
    pref: SettingsService.matchContentResolution,
    icon: Symbols.aspect_ratio_rounded,
    title: t.settings.matchContentResolution,
    subtitle: t.settings.matchContentResolutionDescription,
  );

  Widget _matchRefreshRateTile() => SettingSwitchTile(
    pref: SettingsService.matchRefreshRate,
    icon: Symbols.display_settings_rounded,
    title: t.settings.matchRefreshRate,
    subtitle: t.settings.matchRefreshRateDescription,
  );

  Widget _matchDynamicRangeTile() => SettingSwitchTile(
    pref: SettingsService.matchDynamicRange,
    icon: Symbols.hdr_on_rounded,
    title: t.settings.matchDynamicRange,
    subtitle: t.settings.matchDynamicRangeDescription,
  );

  Widget _deinterlaceTile() => SettingSwitchTile(
    pref: SettingsService.deinterlace,
    icon: Symbols.deblur_rounded,
    title: t.settings.deinterlace,
    subtitle: t.settings.deinterlaceDescription,
  );

  Widget _audioPassthroughTile() => SettingSwitchTile(
    pref: SettingsService.audioPassthrough,
    icon: Symbols.surround_sound_rounded,
    title: t.settings.audioPassthrough,
    subtitle: PlatformDetector.isAppleTV()
        ? t.settings.audioPassthroughDescriptionAppleTv
        : t.settings.audioPassthroughDescription,
  );

  Widget _audioDownmixTile() => SettingSwitchTile(
    pref: SettingsService.audioDownmix,
    icon: Symbols.headphones_rounded,
    title: t.settings.audioDownmix,
    subtitle: t.settings.audioDownmixDescription,
  );

  Widget _downmixCenterBoostTile() => SettingNumberTile(
    pref: SettingsService.downmixCenterBoost,
    icon: Symbols.record_voice_over_rounded,
    title: t.settings.downmixCenterBoost,
    subtitleBuilder: (v) => t.settings.downmixCenterBoostValue(db: v.toString()),
    labelText: t.settings.downmixCenterBoostLabel,
    suffixText: t.settings.downmixCenterBoostShort,
    min: 0,
    max: 12,
  );

  Widget _downmixNormalizeTile() => SettingSwitchTile(
    pref: SettingsService.audioDownmixNormalize,
    icon: Symbols.graphic_eq_rounded,
    title: t.settings.audioDownmixNormalize,
    subtitle: t.settings.audioDownmixNormalizeDescription,
  );

  Widget _maxVolumeTile() => SettingNumberTile(
    pref: SettingsService.maxVolume,
    icon: Symbols.volume_up_rounded,
    title: t.settings.maxVolume,
    subtitleBuilder: (v) => t.settings.maxVolumePercent(percent: v.toString()),
    labelText: t.settings.maxVolumeDescription,
    suffixText: '%',
    min: 100,
    max: 300,
  );

  // Visibility for this and the tiles around it is decided by the hoisted
  // SettingsBuilder in build().
  Widget _displaySwitchDelayTile() => SettingNumberTile(
    pref: SettingsService.displaySwitchDelay,
    icon: Symbols.timer_rounded,
    title: t.settings.displaySwitchDelay,
    subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v.toString()),
    labelText: t.settings.secondsLabel,
    suffixText: t.settings.secondsShort,
    min: 0,
    max: 10,
  );

  Widget _tunneledPlaybackTile() => SettingSwitchTile(
    pref: SettingsService.tunneledPlayback,
    icon: Symbols.tv_options_input_settings_rounded,
    title: t.settings.tunneledPlayback,
    subtitle: t.settings.tunneledPlaybackDescription,
  );

  Widget _dvConversionModeTile() => SettingSelectionTile<DvConversionModePreference>(
    pref: SettingsService.dvConversionMode,
    icon: Symbols.hdr_strong_rounded,
    title: t.settings.dvConversionMode,
    subtitleBuilder: (mode) => '${_dvConversionModeLabel(mode)} · ${t.settings.dvConversionModeDescription}',
    options: DvConversionModePreference.values
        .map((m) => DialogOption(value: m, title: _dvConversionModeLabel(m)))
        .toList(),
  );

  String _dvConversionModeLabel(DvConversionModePreference mode) => switch (mode) {
    DvConversionModePreference.auto => t.settings.dvConversionAuto,
    DvConversionModePreference.disabled => t.settings.dvConversionNative,
    DvConversionModePreference.dv81 => t.settings.dvConversionDv81,
    DvConversionModePreference.hevcStrip => t.settings.dvConversionHevcStrip,
  };

  Widget _playbackBufferTile() => SettingSelectionTile<PlaybackBufferTier>(
    pref: SettingsService.playbackBufferTier,
    icon: Symbols.hourglass_top_rounded,
    title: t.settings.playbackBuffer,
    subtitleBuilder: (tier) => '${_playbackBufferLabel(tier)} · ${t.settings.playbackBufferDescription}',
    options: PlaybackBufferTier.values
        .map((tier) => DialogOption(value: tier, title: _playbackBufferLabel(tier)))
        .toList(),
  );

  String _playbackBufferLabel(PlaybackBufferTier tier) => switch (tier) {
    PlaybackBufferTier.auto => t.settings.playbackBufferAuto,
    PlaybackBufferTier.large => t.settings.playbackBufferLarge,
    PlaybackBufferTier.extraLarge => t.settings.playbackBufferExtraLarge,
  };

  Widget _defaultQualityTile() => SettingSelectionTile<TranscodeQualityPreset>(
    pref: SettingsService.defaultQualityPreset,
    icon: Symbols.high_quality_rounded,
    title: t.settings.defaultQualityTitle,
    subtitleBuilder: qualityPresetLabel,
    options: TranscodeQualityPreset.displayOrder
        .map((p) => DialogOption(value: p, title: qualityPresetLabel(p)))
        .toList(),
  );

  Widget _cellularQualityTile() => SettingSelectionTile<TranscodeQualityPreset?>(
    pref: SettingsService.cellularQualityPreset,
    icon: Symbols.signal_cellular_alt_rounded,
    title: t.settings.cellularQualityTitle,
    subtitleBuilder: (p) => p == null ? t.settings.cellularQualitySameAsDefault : qualityPresetLabel(p),
    options: [
      DialogOption<TranscodeQualityPreset?>(value: null, title: t.settings.cellularQualitySameAsDefault),
      ...TranscodeQualityPreset.displayOrder.map(
        (p) => DialogOption<TranscodeQualityPreset?>(value: p, title: qualityPresetLabel(p)),
      ),
    ],
  );

  // Plex-only effect: MediaBrowser servers make the equivalent
  // direct-play-vs-transcode call server-side (#2152, #2193).
  Widget _directPlayCoveredQualityTile() => SettingSwitchTile(
    pref: SettingsService.directPlayCoveredQuality,
    icon: Symbols.bolt_rounded,
    title: t.settings.directPlayCoveredQuality,
    subtitle: t.settings.directPlayCoveredQualityDescription,
  );

  Widget _musicQualityTile() => SettingSelectionTile<AudioQualityPreset>(
    pref: SettingsService.musicQualityPreset,
    icon: Symbols.music_note_rounded,
    title: t.settings.musicQualityTitle,
    subtitleBuilder: _musicQualityLabel,
    options: AudioQualityPreset.values.map((p) => DialogOption(value: p, title: _musicQualityLabel(p))).toList(),
  );

  String _musicQualityLabel(AudioQualityPreset preset) =>
      preset.isOriginal ? t.videoControls.qualityOriginal : '${preset.bitrateKbps} kbps';

  Widget _mpvConfigTile() => SettingNavigationTile(
    icon: Symbols.tune_rounded,
    title: t.mpvConfig.title,
    subtitle: t.mpvConfig.description,
    destinationBuilder: (_) => const MpvConfigScreen(),
  );
}

class _PrerollItemPickerDialog extends StatefulWidget {
  final MediaLibrary library;

  const _PrerollItemPickerDialog({required this.library});

  @override
  State<_PrerollItemPickerDialog> createState() => _PrerollItemPickerDialogState();
}

class _PrerollItemPickerDialogState extends State<_PrerollItemPickerDialog> {
  List<MediaItem>? _items;
  String? _error;
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final storage = await StorageService.getInstance();
      final client = context.getMediaClientForLibrary(widget.library);
      final items = await drainPages<MediaItem>(
        (start, size) => client.fetchLibraryPagedContent(
          widget.library.id,
          query: LibraryQuery(offset: start, limit: size),
        ),
        pageSize: 200,
        stopOnShortPage: true,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _selected = storage.getPrerollSelectedItemKeys();
        });
      }
    } catch (e, st) {
      appLogger.w('Preroll item picker load failed', error: e, stackTrace: st);
      if (mounted) setState(() => _error = t.settings.prerollItemPickerLoadFailed);
    }
  }

  Future<void> _toggle(String globalKey, bool checked) async {
    final updated = _selected.toSet();
    if (checked) {
      updated.add(globalKey);
    } else {
      updated.remove(globalKey);
    }
    setState(() => _selected = updated);
    final storage = await StorageService.getInstance();
    await storage.savePrerollSelectedItemKeys(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.settings.prerollItemPicker),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _items == null
            ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
            : ListView.builder(
                itemCount: _items!.length,
                itemBuilder: (_, index) {
                  final item = _items![index];
                  return FocusableCheckboxListTile(
                    title: Text(item.title ?? item.id),
                    value: _selected.contains(item.globalKey),
                    onChanged: (checked) => unawaited(_toggle(item.globalKey, checked ?? false)),
                  );
                },
              ),
      ),
      actions: [DialogActionButton(autofocus: true, onPressed: () => Navigator.pop(context), label: t.common.close)],
    );
  }
}
