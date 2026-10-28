import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/presentation_formats.dart';
import '../../i18n/strings.g.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../models/audio_channel_limit.dart';
import '../../models/audio_quality_preset.dart';
import '../../models/transcode_quality_preset.dart';
import '../../models/player_setting_scope.dart';
import '../../models/motion_clarity.dart';
import '../../providers/libraries_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/audio_channel_limit_labels.dart';
import '../../utils/dialogs.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/quality_preset_labels.dart';
import '../../services/settings_service.dart';
import '../../services/video_decode_capabilities.dart';
import '../../utils/codec_utils.dart';
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
  String? _prerollLibraryGlobalKey;
  Set<String> _prerollSelectedItemKeys = {};

  @override
  void initState() {
    super.initState();
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
        SettingsService.motionClarityPreset,
        SettingsService.motionClarityKernel,
        SettingsService.motionClarityThreshold,
        SettingsService.audioChannelLimit,
        SettingsService.disableDolbyVision,
        SettingsService.experimentalDolbyVision,
      ],
      builder: (context) {
        final svc = SettingsService.instance;
        final exoActive = Platform.isAndroid && svc.read(SettingsService.useExoPlayer);
        // ExoPlayer only has the stereo fold, so a 5.1 limit set on mpv plays
        // (and shows) as Original there.
        final storedChannelLimit = svc.read(SettingsService.audioChannelLimit);
        final channelLimit = exoActive ? storedChannelLimit.onExoPlayer : storedChannelLimit;
        final showDisplaySwitchDelay =
            PlatformDetector.isAppleTV() ||
            (Platform.isWindows &&
                (svc.read(SettingsService.matchRefreshRate) || svc.read(SettingsService.matchDynamicRange))) ||
            (Platform.isAndroid &&
                (svc.read(SettingsService.matchContentFrameRate) || svc.read(SettingsService.matchContentResolution)));
        // The DV output switch is limited to native Android mpv and Apple TV.
        final showDisableDolbyVision = (Platform.isAndroid && !exoActive) || PlatformDetector.isAppleTV();
        // With Dolby Vision disabled mpv strips every Profile 7 file, so the
        // conversion choices would change nothing.
        final showDvConversionMode =
            (Platform.isAndroid && (exoActive || !svc.read(SettingsService.disableDolbyVision))) ||
            ((Platform.isIOS || Platform.isMacOS) &&
                !(PlatformDetector.isAppleTV() && svc.read(SettingsService.disableDolbyVision)));
        final showExperimentalDolbyVision =
            (Platform.isLinux && !PlatformDetector.usesNativeTvMedia()) ||
            Platform.isWindows ||
            (Platform.isAndroid && !exoActive);

        return SettingsPage(
          title: Text(t.settings.videoPlayback),
          children: [
            SettingsGroup(
              title: t.settings.player,
              children: [
                if (Platform.isAndroid) _playerBackendSelector(),
                if (PlatformDetector.supportsExternalPlayers()) _externalPlayerTile(),
                if (!exoActive && !PlatformDetector.isTizenBuild()) _mpvConfigTile(),
                if (!PlatformDetector.isTizenBuild()) _hardwareDecodingTile(),
                if (exoActive) _playbackBufferTile(),
                if (!PlatformDetector.isTizenBuild()) _streamBufferSizeTile(exoActive: exoActive),
                if (exoActive) _tunneledPlaybackTile(),
                if (PlatformDetector.supportsPictureInPicture()) _autoPipTile(),
                if (isMobile && !PlatformDetector.isTV() && !PlatformDetector.isAutomotive())
                  SettingSwitchTile(
                    pref: SettingsService.backgroundVideoAudio,
                    icon: Symbols.headphones_rounded,
                    title: t.videoSettings.backgroundVideoAudio,
                    subtitle: t.videoSettings.backgroundVideoAudioDescription,
                  ),
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
                if (showDisableDolbyVision) _disableDolbyVisionTile(),
                if (showDvConversionMode) _dvConversionModeTile(),
                if (showExperimentalDolbyVision)
                  SettingSwitchTile(
                    pref: SettingsService.experimentalDolbyVision,
                    icon: Symbols.hdr_on_rounded,
                    title: t.settings.experimentalDolbyVision,
                    subtitle: Platform.isLinux
                        ? t.settings.experimentalDolbyVisionDescription
                        : t.settings.dvExperimentUnavailableDescription,
                  ),
                if (Platform.isLinux &&
                    !PlatformDetector.usesNativeTvMedia() &&
                    svc.read(SettingsService.experimentalDolbyVision))
                  SettingSwitchTile(
                    pref: SettingsService.dvCompatibilityFallback,
                    icon: Symbols.hdr_off_rounded,
                    title: t.settings.dvCompatibilityFallback,
                    subtitle: t.settings.dvCompatibilityFallbackDescription,
                  ),
                SettingSwitchTile(
                  pref: SettingsService.dvExperimentDiagnostics,
                  icon: Symbols.info_rounded,
                  title: t.settings.dvExperimentDiagnostics,
                  subtitle: t.settings.dvExperimentDiagnosticsDescription,
                  enabled: !PlatformDetector.usesNativeTvMedia(),
                ),
                // mpv-only: ExoPlayer always leaves the conversion to the device.
                if (Platform.isAndroid && !exoActive) _hdrSdrConversionTile(),
                // mpv-only (#2149): ExoPlayer has no filter chain, so the
                // tile disappears while the ExoPlayer backend is active.
                if (!exoActive && !PlatformDetector.isTizenBuild()) _deinterlaceTile(),
                SettingSelectionTile<MotionClarityPreset>(
                  pref: SettingsService.motionClarityPreset,
                  icon: Symbols.blur_on_rounded,
                  title: t.videoSettings.motionClarity,
                  description: t.videoSettings.motionClarityDescription,
                  subtitleBuilder: (preset) => '${_motionClarityPresetTitle(preset)} · ${_motionClarityPresetDescription(preset)}',
                  options: MotionClarityPreset.values
                      .map(
                        (preset) => DialogOption(
                          value: preset,
                          title: _motionClarityPresetTitle(preset),
                          subtitle: _motionClarityPresetDescription(preset),
                        ),
                      )
                      .toList(),
                ),
                if (svc.read(SettingsService.motionClarityPreset) == MotionClarityPreset.custom) ...[
                  SettingSelectionTile<MotionTemporalKernel>(
                    pref: SettingsService.motionClarityKernel,
                    icon: Symbols.tune_rounded,
                    title: t.videoSettings.motionClarityKernel,
                    description: t.videoSettings.motionClarityDescription,
                    subtitleBuilder: _motionTemporalKernelTitle,
                    options: MotionTemporalKernel.values
                        .map((kernel) => DialogOption(value: kernel, title: _motionTemporalKernelTitle(kernel)))
                        .toList(),
                  ),
                  SettingNumberTile(
                    pref: SettingsService.motionClarityThreshold,
                    icon: Symbols.speed_rounded,
                    title: t.videoSettings.motionClarityThreshold,
                    description: t.videoSettings.motionClarityThresholdDescription,
                    subtitleBuilder: (value) => '$value%',
                    labelText: t.videoSettings.motionClarityThreshold,
                    suffixText: '%',
                  ),
                ],
                if (Platform.isAndroid && !PlatformDetector.isTV())
                  SettingSwitchTile(
                    pref: SettingsService.extendVideoIntoDisplayCutout,
                    icon: Symbols.fullscreen_rounded,
                    title: t.settings.extendVideoIntoDisplayCutout,
                    subtitle: t.settings.extendVideoIntoDisplayCutoutDescription,
                  ),
              ],
            ),

            if (!PlatformDetector.isTizenBuild())
              SettingsGroup(
                title: t.settings.audio,
                children: [
                  if (PlatformDetector.supportsAudioPassthrough()) _audioPassthroughTile(),
                  _audioChannelLimitTile(exoActive: exoActive),
                  // Only a stereo fold mixes the center away; any fold can clip.
                  if (channelLimit == AudioChannelLimit.stereo) _downmixCenterBoostTile(),
                  if (channelLimit != AudioChannelLimit.original) _downmixNormalizeTile(),
                  _maxVolumeTile(),
                ],
              ),

            SettingsGroup(
              title: t.settings.quality,
              children: [
                _defaultQualityTile(),
                _remoteQualityTile(),
                // Only a phone/tablet has a cellular radio; desktop and TV
                // never report a cellular-only connection.
                if (isMobile) _cellularQualityTile(),
                if (!PlatformDetector.isTizenBuild()) _directPlayCoveredQualityTile(),
                // Desktop has no hardware-decode probe, so this is where a
                // machine too weak for a codec says so (#2443).
                if (PlatformDetector.isDesktopOS()) _videoCodecsTile(),
                _musicQualityTile(),
              ],
            ),

            SettingsGroup(
              title: t.settings.subtitles,
              children: [
                SettingSwitchTile(
                  pref: SettingsService.alwaysShowSubtitlesOnDevice,
                  icon: Symbols.subtitles_rounded,
                  title: t.settings.alwaysShowSubtitlesOnDevice,
                  subtitle: t.settings.alwaysShowSubtitlesOnDeviceDescription,
                ),
                SettingSwitchTile(
                  pref: SettingsService.subtitleOnMute,
                  icon: Symbols.subtitles_rounded,
                  title: t.settings.subtitleOnMute,
                  subtitle: t.settings.subtitleOnMuteDescription,
                ),
                SettingSwitchTile(
                  pref: SettingsService.autoDownloadPreferredSubtitle,
                  icon: Symbols.download_rounded,
                  title: t.settings.autoDownloadPreferredSubtitle,
                  subtitle: t.settings.autoDownloadPreferredSubtitleDescription,
                ),
                if (!PlatformDetector.isTizenBuild())
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
            if (!PlatformDetector.isTizenBuild()) _musicPlaybackGroup(),
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
        description: t.settings.smallSkipDurationDescription,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
      ),
      SettingNumberTile(
        pref: SettingsService.seekTimeLarge,
        icon: Symbols.replay_30_rounded,
        title: t.settings.largeSkipDuration,
        description: t.settings.largeSkipDurationDescription,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
      ),
      SettingNumberTile(
        pref: SettingsService.rewindOnResume,
        icon: Symbols.replay_rounded,
        title: t.settings.rewindOnResume,
        description: t.settings.rewindOnResumeDescription,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
      ),
      SettingNumberTile(
        pref: SettingsService.sleepTimerDuration,
        icon: Symbols.bedtime_rounded,
        title: t.settings.defaultSleepTimer,
        description: t.settings.defaultSleepTimerDescription,
        subtitleBuilder: (v) => t.settings.minutesUnit(minutes: v),
        labelText: t.settings.minutesLabel,
        suffixText: t.settings.minutesShort,
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
        pref: SettingsService.motionClarityScope,
        icon: Symbols.blur_on_rounded,
        title: t.videoSettings.motionClarity,
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
    description: t.settings.rememberPlayerChangesDescription,
    subtitleBuilder: (scope) => '${_playerScopeLabel(scope)} · ${t.settings.rememberPlayerChangesDescription}',
    options: PlayerSettingScope.values
        .map(
          (scope) =>
              DialogOption(value: scope, title: _playerScopeLabel(scope), subtitle: _playerScopeDescription(scope)),
        )
        .toList(),
  );

  String _playerScopeDescription(PlayerSettingScope scope) => switch (scope) {
    PlayerSettingScope.off => t.settings.scopeOffDescription,
    PlayerSettingScope.global => t.settings.scopeGlobalDescription,
    PlayerSettingScope.library => t.settings.scopeLibraryDescription,
    PlayerSettingScope.title => t.settings.scopeTitleDescription,
  };

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
        subtitle: '${t.settings.rememberTrackSelectionsDescription} · ${t.settings.rememberTrackSelectionsBackendRule}',
      ),
      SettingSwitchTile(
        pref: SettingsService.chooseTracksBeforePlayback,
        icon: Symbols.subtitles_rounded,
        title: t.settings.chooseTracksBeforePlayback,
        subtitle: t.settings.chooseTracksBeforePlaybackDescription,
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
        description: t.settings.specialsOrderingDescription,
        subtitleBuilder: (mode) => '${_specialsOrderingLabel(mode)} · ${t.settings.specialsOrderingDescription}',
        options: SpecialsOrdering.values
            .map(
              (mode) => DialogOption(
                value: mode,
                title: _specialsOrderingLabel(mode),
                subtitle: _specialsOrderingDescription(mode),
              ),
            )
            .toList(),
      ),
      if (!isMobile)
        SettingSwitchTile(
          pref: SettingsService.clickVideoTogglesPlayback,
          icon: Symbols.play_pause_rounded,
          title: t.settings.clickVideoTogglesPlayback,
          subtitle: t.settings.clickVideoTogglesPlaybackDescription,
        ),
      if (PlatformDetector.isDesktopOS()) ...[
        SettingSwitchTile(
          pref: SettingsService.enterFullscreenOnPlaybackStart,
          icon: Symbols.fullscreen_rounded,
          title: t.settings.enterFullscreenOnPlaybackStart,
          subtitle: t.settings.enterFullscreenOnPlaybackStartDescription,
        ),
        SettingSwitchTile(
          pref: SettingsService.exitFullscreenOnPlayerClose,
          icon: Symbols.fullscreen_exit_rounded,
          title: t.settings.exitFullscreenOnPlayerClose,
          subtitle: t.settings.exitFullscreenOnPlayerCloseDescription,
        ),
      ],
    ],
  );

  String _motionClarityPresetTitle(MotionClarityPreset preset) => switch (preset) {
    MotionClarityPreset.original => t.videoSettings.motionClarityOriginal,
    MotionClarityPreset.cinema => t.videoSettings.motionClarityCinema,
    MotionClarityPreset.balanced => t.videoSettings.motionClarityBalanced,
    MotionClarityPreset.smooth => t.videoSettings.motionClaritySmooth,
    MotionClarityPreset.animation => t.videoSettings.motionClarityAnimation,
    MotionClarityPreset.sports => t.videoSettings.motionClaritySports,
    MotionClarityPreset.oled => t.videoSettings.motionClarityOled,
    MotionClarityPreset.custom => t.videoSettings.motionClarityCustom,
  };

  String _motionClarityPresetDescription(MotionClarityPreset preset) => switch (preset) {
    MotionClarityPreset.original => t.videoSettings.motionClarityOriginalDescription,
    MotionClarityPreset.cinema => t.videoSettings.motionClarityCinemaDescription,
    MotionClarityPreset.balanced => t.videoSettings.motionClarityBalancedDescription,
    MotionClarityPreset.smooth => t.videoSettings.motionClaritySmoothDescription,
    MotionClarityPreset.animation => t.videoSettings.motionClarityAnimationDescription,
    MotionClarityPreset.sports => t.videoSettings.motionClaritySportsDescription,
    MotionClarityPreset.oled => t.videoSettings.motionClarityOledDescription,
    MotionClarityPreset.custom => t.videoSettings.motionClarityCustomDescription,
  };

  String _motionTemporalKernelTitle(MotionTemporalKernel kernel) => switch (kernel) {
    MotionTemporalKernel.oversample => t.videoSettings.motionClarityKernelOversample,
    MotionTemporalKernel.linear => t.videoSettings.motionClarityKernelLinear,
    MotionTemporalKernel.catmullRom => t.videoSettings.motionClarityKernelCatmullRom,
    MotionTemporalKernel.mitchell => t.videoSettings.motionClarityKernelMitchell,
    MotionTemporalKernel.gaussian => t.videoSettings.motionClarityKernelGaussian,
    MotionTemporalKernel.bicubic => t.videoSettings.motionClarityKernelBicubic,
  };

  String _specialsOrderingLabel(SpecialsOrdering mode) => switch (mode) {
    SpecialsOrdering.respectServer => t.settings.specialsOrderingServer,
    SpecialsOrdering.airDate => t.settings.specialsOrderingAirDate,
    SpecialsOrdering.specialsLast => t.settings.specialsOrderingLast,
  };

  String _specialsOrderingDescription(SpecialsOrdering mode) => switch (mode) {
    SpecialsOrdering.respectServer => t.settings.specialsOrderingServerDescription,
    SpecialsOrdering.airDate => t.settings.specialsOrderingAirDateDescription,
    SpecialsOrdering.specialsLast => t.settings.specialsOrderingLastDescription,
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
      SettingSwitchTile(
        pref: SettingsService.shuffleStartsFromBeginning,
        icon: Symbols.shuffle_rounded,
        title: t.settings.shuffleStartsFromBeginning,
        subtitle: t.settings.shuffleStartsFromBeginningDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.plexCinemaPreRoll,
        icon: Symbols.movie_rounded,
        title: t.settings.plexCinemaPreRoll,
        subtitle: t.settings.plexCinemaPreRollDescription,
      ),
      SettingNumberTile(
        pref: SettingsService.playNextCountdown,
        icon: Symbols.timer_rounded,
        title: t.settings.playNextCountdown,
        description: t.settings.playNextCountdownDescription,
        subtitleBuilder: (v) => v == 0 ? t.settings.playNextCountdownImmediate : t.settings.secondsUnit(seconds: v),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
      ),
      SettingSelectionTile<SkipMarkerMode>(
        pref: SettingsService.skipIntroMode,
        icon: Symbols.fast_forward_rounded,
        title: t.settings.skipIntroMode,
        description: t.settings.skipIntroModeDescription,
        subtitleBuilder: (mode) => '${_skipMarkerModeLabel(mode)} · ${_skipIntroModeDescription(mode)}',
        options: SkipMarkerMode.values
            .map(
              (mode) => DialogOption(
                value: mode,
                title: _skipMarkerModeLabel(mode),
                subtitle: _skipIntroModeDescription(mode),
              ),
            )
            .toList(),
      ),
      SettingSelectionTile<SkipMarkerMode>(
        pref: SettingsService.skipCreditsMode,
        icon: Symbols.skip_next_rounded,
        title: t.settings.skipCreditsMode,
        description: t.settings.skipCreditsModeDescription,
        subtitleBuilder: (mode) => '${_skipMarkerModeLabel(mode)} · ${_skipCreditsModeDescription(mode)}',
        options: SkipMarkerMode.values
            .map(
              (mode) => DialogOption(
                value: mode,
                title: _skipMarkerModeLabel(mode),
                subtitle: _skipCreditsModeDescription(mode),
              ),
            )
            .toList(),
      ),
      SettingSelectionTile<SkipMarkerMode>(
        pref: SettingsService.skipAdsMode,
        icon: Symbols.fast_forward_rounded,
        title: t.settings.skipAdsMode,
        description: t.settings.skipAdsModeDescription,
        subtitleBuilder: (mode) => '${_skipMarkerModeLabel(mode)} · ${_skipAdsModeDescription(mode)}',
        options: SkipMarkerMode.values
            .map(
              (mode) =>
                  DialogOption(value: mode, title: _skipMarkerModeLabel(mode), subtitle: _skipAdsModeDescription(mode)),
            )
            .toList(),
      ),
      SettingSwitchTile(
        pref: SettingsService.forceSkipMarkerFallback,
        icon: Symbols.tune_rounded,
        title: t.settings.forceSkipMarkerFallback,
        subtitle: t.settings.forceSkipMarkerFallbackDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.theIntroDbFallback,
        icon: Symbols.public_rounded,
        title: t.settings.theIntroDbFallback,
        subtitle: t.settings.theIntroDbFallbackDescription,
      ),
      SettingNumberTile(
        pref: SettingsService.autoSkipDelay,
        icon: Symbols.timer_rounded,
        title: t.settings.autoSkipDelay,
        description: t.settings.autoSkipDelaySettingDescription,
        subtitleBuilder: (v) => t.settings.autoSkipDelayDescription(seconds: v),

        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
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

  String _skipAdsModeDescription(SkipMarkerMode mode) => switch (mode) {
    SkipMarkerMode.off => t.settings.skipAdsModeOffDescription,
    SkipMarkerMode.button => t.settings.skipAdsModeButtonDescription,
    SkipMarkerMode.auto => t.settings.skipAdsModeAutoDescription,
  };

  Widget _musicPlaybackGroup() => SettingsGroup(
    title: t.settings.musicPlayback,
    children: [
      SettingSwitchTile(
        pref: SettingsService.musicSweetFades,
        icon: Symbols.graphic_eq_rounded,
        title: t.settings.musicSweetFades,
        subtitle: t.settings.musicSweetFadesDescription,
      ),
    ],
  );
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
            : t.settings.prerollSelectionCount(count: formatCount(selectedCount));

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
                subtitle:
                    '${library?.title ?? t.settings.prerollLibraryNotSet} · ${t.settings.prerollLibraryDescription}',
                onTap: () => _showPrerollLibraryPicker(context, libraries),
              ),
            if (enabled && library != null)
              SettingNavigationTile(
                icon: Symbols.checklist_rounded,
                title: t.settings.prerollSelection,
                subtitle: '$selectionSubtitle · ${t.settings.prerollSelectionDescription}',
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
      description: t.settings.prerollLibraryDescription,
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
      SettingSwitchTile(
        pref: SettingsService.gestureSeekSwipe,
        icon: Symbols.swipe_rounded,
        title: t.settings.gestureSeekSwipe,
        subtitle: t.settings.gestureSeekSwipeDescription,
      ),
    ],
  );

  Widget _playerBackendSelector() => SettingSegmentedTile<bool>(
    pref: SettingsService.useExoPlayer,
    icon: Symbols.play_circle_rounded,
    title: t.settings.playerBackend,
    description: t.settings.playerBackendDescription,
    segments: [
      ButtonSegment(value: true, label: Text(t.settings.exoPlayer), tooltip: t.settings.exoPlayerDescription),
      ButtonSegment(value: false, label: Text(t.settings.mpv), tooltip: t.settings.mpvDescription),
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
        subtitle: !useExt
            ? '${t.externalPlayer.off} · ${t.externalPlayer.description}'
            : !player.isAvailable
            ? '${t.externalPlayer.selectPlayer} · ${t.externalPlayer.description}'
            : '${player.id == 'system_default' ? t.externalPlayer.systemDefault : player.name} · ${t.externalPlayer.description}',
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

  Widget _deinterlaceTile() => SettingSelectionTile<DeinterlaceMode>(
    pref: SettingsService.deinterlaceMode,
    icon: Symbols.deblur_rounded,
    title: t.settings.deinterlace,
    description: t.settings.deinterlaceDescription,
    subtitleBuilder: (mode) => '${_deinterlaceModeLabel(mode)} · ${t.settings.deinterlaceDescription}',
    options: [
      DialogOption(
        value: DeinterlaceMode.off,
        title: t.settings.deinterlaceOff,
        subtitle: t.settings.deinterlaceOffDescription,
      ),
      DialogOption(
        value: DeinterlaceMode.video,
        title: t.settings.deinterlaceVideo,
        subtitle: t.settings.deinterlaceVideoDescription,
      ),
      DialogOption(
        value: DeinterlaceMode.film,
        title: t.settings.deinterlaceFilm,
        subtitle: t.settings.deinterlaceFilmDescription,
      ),
    ],
  );

  String _deinterlaceModeLabel(DeinterlaceMode mode) => switch (mode) {
    DeinterlaceMode.off => t.settings.deinterlaceOff,
    DeinterlaceMode.video => t.settings.deinterlaceVideo,
    DeinterlaceMode.film => t.settings.deinterlaceFilm,
  };

  // Normalization wins over passthrough in the player (neither mpv's filter nor
  // ExoPlayer's platform effect can process a bitstream), so the switch reports
  // that override instead of promising bitstreaming that will not happen.
  Widget _audioPassthroughTile() => SettingsBuilder(
    prefs: const [SettingsService.audioNormalization],
    builder: (context) {
      final normalizationOn = SettingsService.instance.read(SettingsService.audioNormalization);
      return SettingSwitchTile(
        pref: SettingsService.audioPassthrough,
        icon: Symbols.surround_sound_rounded,
        title: t.settings.audioPassthrough,
        subtitle: normalizationOn
            ? t.settings.audioPassthroughOverriddenByNormalization
            : Platform.isIOS
            ? t.settings.audioPassthroughDescriptionAppleSpatial
            : Platform.isMacOS
            ? t.settings.audioPassthroughDescriptionApple
            : t.settings.audioPassthroughDescription,
        enabled: !normalizationOn,
      );
    },
  );

  Widget _audioChannelLimitTile({required bool exoActive}) => SettingSelectionTile<AudioChannelLimit>(
    pref: SettingsService.audioChannelLimit,
    icon: Symbols.speaker_group_rounded,
    title: t.settings.audioChannelLimit,
    description: t.settings.audioChannelLimitDescription,
    subtitleBuilder: (limit) =>
        '${audioChannelLimitLabel(exoActive ? limit.onExoPlayer : limit)} · ${t.settings.audioChannelLimitDescription}',
    options: [
      for (final limit in AudioChannelLimit.available(exoPlayer: exoActive))
        DialogOption(value: limit, title: audioChannelLimitLabel(limit), subtitle: audioChannelLimitDescription(limit)),
    ],
  );

  Widget _downmixCenterBoostTile() => SettingNumberTile(
    pref: SettingsService.downmixCenterBoost,
    icon: Symbols.record_voice_over_rounded,
    title: t.settings.downmixCenterBoost,
    description: t.settings.downmixCenterBoostDescription,
    subtitleBuilder: (v) => t.settings.downmixCenterBoostValue(db: formatDecimal(v, maximumDecimals: 0)),

    labelText: t.settings.downmixCenterBoostLabel,
    suffixText: t.settings.downmixCenterBoostShort,
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
    description: t.settings.maxVolumeDescription,
    subtitleBuilder: (v) => t.settings.maxVolumePercent(percent: formatDecimal(v, maximumDecimals: 0)),
    labelText: t.settings.maxVolumeInputLabel,

    suffixText: '%',
  );

  // Visibility for this and the tiles around it is decided by the hoisted
  // SettingsBuilder in build().
  Widget _displaySwitchDelayTile() => SettingNumberTile(
    pref: SettingsService.displaySwitchDelay,
    icon: Symbols.timer_rounded,
    title: t.settings.displaySwitchDelay,
    description: t.settings.displaySwitchDelayDescription,
    subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v),
    labelText: t.settings.secondsLabel,
    suffixText: t.settings.secondsShort,
  );

  Widget _tunneledPlaybackTile() => SettingSwitchTile(
    pref: SettingsService.tunneledPlayback,
    icon: Symbols.tv_options_input_settings_rounded,
    title: t.settings.tunneledPlayback,
    subtitle: t.settings.tunneledPlaybackDescription,
  );

  Widget _disableDolbyVisionTile() => SettingSwitchTile(
    pref: SettingsService.disableDolbyVision,
    icon: Symbols.hdr_off_rounded,
    title: t.settings.disableDolbyVision,
    subtitle: t.settings.disableDolbyVisionDescription,
  );

  Widget _dvConversionModeTile() => SettingSelectionTile<DvConversionModePreference>(
    pref: SettingsService.dvConversionMode,
    icon: Symbols.hdr_strong_rounded,
    title: t.settings.dvConversionMode,
    description: t.settings.dvConversionModeDescription,
    subtitleBuilder: (mode) => '${_dvConversionModeLabel(mode)} · ${t.settings.dvConversionModeDescription}',
    options: DvConversionModePreference.values
        .map(
          (mode) => DialogOption(
            value: mode,
            title: _dvConversionModeLabel(mode),
            subtitle: _dvConversionModeDescription(mode),
          ),
        )
        .toList(),
  );

  String _dvConversionModeDescription(DvConversionModePreference mode) => switch (mode) {
    DvConversionModePreference.auto => t.settings.dvConversionAutoDescription,
    DvConversionModePreference.disabled => t.settings.dvConversionNativeDescription,
    DvConversionModePreference.dv81 => t.settings.dvConversionDv81Description,
    DvConversionModePreference.hevcStrip => t.settings.dvConversionHevcStripDescription,
  };

  String _dvConversionModeLabel(DvConversionModePreference mode) => switch (mode) {
    DvConversionModePreference.auto => t.settings.dvConversionAuto,
    DvConversionModePreference.disabled => t.settings.dvConversionNative,
    DvConversionModePreference.dv81 => t.settings.dvConversionDv81,
    DvConversionModePreference.hevcStrip => t.settings.dvConversionHevcStrip,
  };

  Widget _hdrSdrConversionTile() => SettingSelectionTile<HdrSdrConversion>(
    pref: SettingsService.hdrSdrConversion,
    icon: Symbols.tonality_rounded,
    title: t.settings.hdrSdrConversion,
    description: t.settings.hdrSdrConversionDescription,
    subtitleBuilder: (mode) => '${_hdrSdrConversionLabel(mode)} · ${t.settings.hdrSdrConversionDescription}',
    options: [
      DialogOption(
        value: HdrSdrConversion.auto,
        title: t.settings.hdrSdrConversionAuto,
        subtitle: t.settings.hdrSdrConversionAutoDescription,
      ),
      DialogOption(
        value: HdrSdrConversion.device,
        title: t.settings.hdrSdrConversionDevice,
        subtitle: t.settings.hdrSdrConversionDeviceDescription,
      ),
      DialogOption(
        value: HdrSdrConversion.player,
        title: t.settings.hdrSdrConversionPlayer,
        subtitle: t.settings.hdrSdrConversionPlayerDescription,
      ),
    ],
  );

  String _hdrSdrConversionLabel(HdrSdrConversion mode) => switch (mode) {
    HdrSdrConversion.auto => t.settings.hdrSdrConversionAuto,
    HdrSdrConversion.device => t.settings.hdrSdrConversionDevice,
    HdrSdrConversion.player => t.settings.hdrSdrConversionPlayer,
  };

  Widget _playbackBufferTile() => SettingSelectionTile<PlaybackBufferTier>(
    pref: SettingsService.playbackBufferTier,
    icon: Symbols.hourglass_top_rounded,
    title: t.settings.playbackBuffer,
    description: t.settings.playbackBufferDescription,
    subtitleBuilder: (tier) => '${_playbackBufferLabel(tier)} · ${t.settings.playbackBufferDescription}',
    options: PlaybackBufferTier.values
        .map(
          (tier) =>
              DialogOption(value: tier, title: _playbackBufferLabel(tier), subtitle: _playbackBufferDescription(tier)),
        )
        .toList(),
  );

  // The explanation lives in the subtitle: the TV number dialog never shows labelText.
  Widget _streamBufferSizeTile({required bool exoActive}) => SettingNumberTile(
    pref: SettingsService.streamBufferMb,
    icon: Symbols.memory_rounded,
    title: t.settings.streamBufferSize,
    description: exoActive
        ? '${t.settings.streamBufferSizeDescription} · ${t.settings.streamBufferSizeExoNote}'
        : t.settings.streamBufferSizeDescription,
    subtitleBuilder: (v) => [
      v == 0 ? t.settings.playbackBufferAuto : t.settings.streamBufferSizeValue(size: v),
      t.settings.streamBufferSizeDescription,
      if (exoActive) t.settings.streamBufferSizeExoNote,
    ].join(' · '),
    labelText: t.settings.streamBufferMegabytes,
    suffixText: 'MB',
  );

  String _playbackBufferLabel(PlaybackBufferTier tier) => switch (tier) {
    PlaybackBufferTier.auto => t.settings.playbackBufferAuto,
    PlaybackBufferTier.large => t.settings.playbackBufferLarge,
    PlaybackBufferTier.extraLarge => t.settings.playbackBufferExtraLarge,
  };

  String _playbackBufferDescription(PlaybackBufferTier tier) => switch (tier) {
    PlaybackBufferTier.auto => t.settings.playbackBufferAutoDescription,
    PlaybackBufferTier.large => t.settings.playbackBufferLargeDescription,
    PlaybackBufferTier.extraLarge => t.settings.playbackBufferExtraLargeDescription,
  };

  Widget _defaultQualityTile() => SettingSelectionTile<TranscodeQualityPreset>(
    pref: SettingsService.defaultQualityPreset,
    icon: Symbols.high_quality_rounded,
    title: t.settings.defaultQualityTitle,
    description: t.settings.defaultQualityDescription,
    subtitleBuilder: qualityPresetLabel,
    options: TranscodeQualityPreset.displayOrder
        .map(
          (preset) => DialogOption(
            value: preset,
            title: qualityPresetLabel(preset),
            subtitle: _qualityPresetDescription(preset),
          ),
        )
        .toList(),
  );

  Widget _cellularQualityTile() => SettingSelectionTile<TranscodeQualityPreset?>(
    pref: SettingsService.cellularQualityPreset,
    icon: Symbols.signal_cellular_alt_rounded,
    title: t.settings.cellularQualityTitle,
    description: t.settings.cellularQualityDescription,
    subtitleBuilder: (p) => p == null ? t.settings.cellularQualitySameAsDefault : qualityPresetLabel(p),
    options: [
      DialogOption<TranscodeQualityPreset?>(
        value: null,
        title: t.settings.cellularQualitySameAsDefault,
        subtitle: t.settings.qualityPresetSameAsDefaultDescription,
      ),
      ...TranscodeQualityPreset.displayOrder.map(
        (preset) => DialogOption<TranscodeQualityPreset?>(
          value: preset,
          title: qualityPresetLabel(preset),
          subtitle: _qualityPresetDescription(preset),
        ),
      ),
    ],
  );

  Widget _remoteQualityTile() => SettingSelectionTile<TranscodeQualityPreset?>(
    pref: SettingsService.remoteQualityPreset,
    icon: Symbols.public_rounded,
    title: t.settings.remoteQualityTitle,
    description: t.settings.remoteQualityDescription,
    subtitleBuilder: (p) => p == null ? t.settings.remoteQualitySameAsDefault : qualityPresetLabel(p),
    options: [
      DialogOption<TranscodeQualityPreset?>(
        value: null,
        title: t.settings.remoteQualitySameAsDefault,
        subtitle: t.settings.qualityPresetSameAsDefaultDescription,
      ),
      ...TranscodeQualityPreset.displayOrder.map(
        (preset) => DialogOption<TranscodeQualityPreset?>(
          value: preset,
          title: qualityPresetLabel(preset),
          subtitle: _qualityPresetDescription(preset),
        ),
      ),
    ],
  );

  String _qualityPresetDescription(TranscodeQualityPreset preset) => preset.isOriginal
      ? t.settings.qualityPresetOriginalDescription
      : t.settings.qualityPresetTranscodeOptionDescription;

  // Plex-only effect: MediaBrowser servers make the equivalent
  // direct-play-vs-transcode call server-side (#2152, #2193).
  Widget _directPlayCoveredQualityTile() => SettingSwitchTile(
    pref: SettingsService.directPlayCoveredQuality,
    icon: Symbols.bolt_rounded,
    title: t.settings.directPlayCoveredQuality,
    subtitle: t.settings.directPlayCoveredQualityDescription,
  );

  Widget _videoCodecsTile() => SettingChecklistTile(
    uncheckedPref: SettingsService.refusedVideoCodecs,
    icon: Symbols.video_settings_rounded,
    title: t.settings.videoCodecs,
    description: t.settings.videoCodecsDescription,
    options: [
      for (final codec in RankedVideoCodec.values)
        DialogOption(
          value: codec.id,
          title: CodecUtils.formatVideoCodec(codec.id),
          subtitle: codec.isRefusable ? t.settings.videoCodecOptionDescription : t.settings.videoCodecsAlwaysAccepted,
        ),
    ],
    locked: {
      for (final codec in RankedVideoCodec.values)
        if (!codec.isRefusable) codec.id,
    },
  );

  Widget _musicQualityTile() => SettingSelectionTile<AudioQualityPreset>(
    pref: SettingsService.musicQualityPreset,
    icon: Symbols.music_note_rounded,
    title: t.settings.musicQualityTitle,
    description: t.settings.musicQualityDescription,
    subtitleBuilder: _musicQualityLabel,
    options: AudioQualityPreset.values
        .map(
          (preset) => DialogOption(
            value: preset,
            title: _musicQualityLabel(preset),
            subtitle: preset.isOriginal
                ? t.settings.musicQualityOriginalDescription
                : t.settings.musicQualityTranscodeOptionDescription,
          ),
        )
        .toList(),
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
      final client = context.getMediaClientForLibrary(widget.library);
      final storage = await StorageService.getInstance();
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
    final focusFirstItem = InputModeTracker.isKeyboardMode(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewPadding.vertical - mediaQuery.viewInsets.bottom;
    final pickerHeight = (availableHeight - 220).clamp(0.0, 560.0).toDouble();
    return AlertDialog(
      scrollable: true,
      title: SettingsDialogTitle(
        title: t.settings.prerollItemPicker,
        description: t.settings.prerollSelectionDescription,
      ),

      content: SizedBox(
        width: double.maxFinite,
        height: pickerHeight,
        child: _items == null
            ? Center(
                child: _error != null
                    ? Semantics(liveRegion: true, child: Text(_error!, textAlign: TextAlign.center))
                    : const CircularProgressIndicator(),
              )
            : _items!.isEmpty
            ? Center(child: Text(t.messages.noResultsFound, textAlign: TextAlign.center))
            : ListView.builder(
                itemCount: _items!.length,
                itemBuilder: (_, index) {
                  final item = _items![index];
                  return FocusableCheckboxListTile(
                    title: Text(item.title ?? item.id),
                    value: _selected.contains(item.globalKey),
                    onChanged: (checked) => unawaited(_toggle(item.globalKey, checked ?? false)),
                    autofocus: focusFirstItem && index == 0,
                  );
                },
              ),
      ),
      actions: [
        DialogActionButton(
          autofocus: !focusFirstItem || _items?.isEmpty != false,
          onPressed: () => Navigator.pop(context),
          label: t.common.close,
        ),
      ],
    );
  }
}
