import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../models/audio_quality_preset.dart';
import '../../models/transcode_quality_preset.dart';
import '../../mpv/player/platform/player_android.dart';
import '../../utils/quality_preset_labels.dart';
import '../../services/companion_remote/companion_remote_host_controller.dart';
import '../../services/discord_rpc_service.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'atmos_diagnostics_screen.dart';
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

  @override
  void initState() {
    super.initState();
    if (KeyboardShortcutsService.isPlatformSupported()) {
      KeyboardShortcutsService.getInstance().then((s) {
        if (mounted) _keyboardService = s;
      });
    }
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
            (Platform.isAndroid && svc.read(SettingsService.matchContentFrameRate));

        return SettingsPage(
          title: Text(t.settings.videoPlayback),
          children: [
            SettingsGroup(
              title: t.settings.player,
              children: [
                if (Platform.isAndroid) _playerBackendSelector(),
                if (PlatformDetector.supportsExternalPlayers()) _externalPlayerTile(),
                _hardwareDecodingTile(),
                if (PlatformDetector.supportsPictureInPicture()) _autoPipTile(),
                if (Platform.isAndroid) _matchContentFrameRateTile(),
                if (Platform.isWindows) _matchRefreshRateTile(),
                if (Platform.isWindows) _matchDynamicRangeTile(),
                if (showDisplaySwitchDelay) _displaySwitchDelayTile(),
                if (exoActive) _tunneledPlaybackTile(),
                if (PlatformDetector.supportsAudioPassthrough()) _audioPassthroughTile(),
                _audioDownmixTile(),
                if (downmixOn) _downmixCenterBoostTile(),
                if (downmixOn) _downmixNormalizeTile(),
                if (PlatformDetector.isAppleTV()) _atmosDiagnosticsTile(),
                if (exoActive) _dvConversionModeTile(),
                _bufferSizeTile(),
                _defaultQualityTile(),
                _musicQualityTile(),
              ],
            ),

            SettingsGroup(
              title: t.settings.subtitlesAndConfig,
              children: [
                SettingNavigationTile(
                  icon: Symbols.subtitles_rounded,
                  title: t.settings.subtitleStyling,
                  subtitle: t.settings.subtitleStylingDescription,
                  destinationBuilder: (_) => const SubtitleStylingScreen(),
                ),
                if (!exoActive) _mpvConfigTile(),
              ],
            ),

            _seekAndTimingGroup(),
            _behaviorGroup(context, isMobile),
            _autoSkipGroup(),
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
      SettingNumberTile(
        pref: SettingsService.maxVolume,
        icon: Symbols.volume_up_rounded,
        title: t.settings.maxVolume,
        subtitleBuilder: (v) => t.settings.maxVolumePercent(percent: v.toString()),
        labelText: t.settings.maxVolumeDescription,
        suffixText: '%',
        min: 100,
        max: 300,
      ),
    ],
  );

  Widget _behaviorGroup(BuildContext context, bool isMobile) => SettingsGroup(
    title: t.settings.behavior,
    children: [
      if (DiscordRPCService.isAvailable)
        SettingSwitchTile(
          pref: SettingsService.enableDiscordRPC,
          icon: Symbols.chat_rounded,
          title: t.settings.discordRichPresence,
          subtitle: t.settings.discordRichPresenceDescription,
          onAfterWrite: (v) => DiscordRPCService.instance.setEnabled(v),
        ),
      if (PlatformDetector.shouldActAsRemoteHost(context))
        SettingSwitchTile(
          pref: SettingsService.enableCompanionRemoteServer,
          icon: Symbols.phone_android_rounded,
          title: t.settings.companionRemoteServer,
          subtitle: t.settings.companionRemoteServerDescription,
          onAfterWrite: (v) => applyCompanionRemoteServerSetting(context, v),
        ),
      SettingSwitchTile(
        pref: SettingsService.rememberTrackSelections,
        icon: Symbols.bookmark_rounded,
        title: t.settings.rememberTrackSelections,
        subtitle: t.settings.rememberTrackSelectionsDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.showChapterMarkersOnTimeline,
        icon: Symbols.bookmarks_rounded,
        title: t.settings.showChapterMarkersOnTimeline,
        subtitle: t.settings.showChapterMarkersOnTimelineDescription,
      ),
      if (!isMobile)
        SettingSwitchTile(
          pref: SettingsService.clickVideoTogglesPlayback,
          icon: Symbols.play_pause_rounded,
          title: t.settings.clickVideoTogglesPlayback,
          subtitle: t.settings.clickVideoTogglesPlaybackDescription,
        ),
    ],
  );

  Widget _autoSkipGroup() => SettingsGroup(
    title: t.settings.autoSkip,
    children: [
      SettingSwitchTile(
        pref: SettingsService.autoSkipIntro,
        icon: Symbols.fast_forward_rounded,
        title: t.settings.autoSkipIntro,
        subtitle: t.settings.autoSkipIntroDescription,
      ),
      SettingSwitchTile(
        pref: SettingsService.autoSkipCredits,
        icon: Symbols.skip_next_rounded,
        title: t.settings.autoSkipCredits,
        subtitle: t.settings.autoSkipCreditsDescription,
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

  Widget _playerBackendSelector() => SettingSegmentedTile<bool, bool>(
    pref: SettingsService.useExoPlayer,
    icon: Symbols.play_circle_rounded,
    title: t.settings.playerBackend,
    segments: [
      ButtonSegment(value: true, label: Text(t.settings.exoPlayer)),
      ButtonSegment(value: false, label: Text(t.settings.mpv)),
    ],
    decode: (s) => s,
    encode: (s) => s,
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

  Widget _atmosDiagnosticsTile() => SettingNavigationTile(
    icon: Symbols.spatial_audio_rounded,
    title: t.settings.atmosDiagnostics,
    subtitle: t.settings.atmosDiagnosticsDescription,
    destinationBuilder: (_) => const AtmosDiagnosticsScreen(),
  );

  // Visibility for this and the three tiles below is decided by the hoisted
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

  Widget _dvConversionModeTile() => SettingSelectionTile<DvConversionModePreference, DvConversionModePreference>(
    pref: SettingsService.dvConversionMode,
    icon: Symbols.hdr_strong_rounded,
    title: t.settings.dvConversionMode,
    subtitleBuilder: (mode) => '${_dvConversionModeLabel(mode)} · ${t.settings.dvConversionModeDescription}',
    options: DvConversionModePreference.values
        .map((m) => DialogOption(value: m, title: _dvConversionModeLabel(m)))
        .toList(),
    decode: (m) => m,
    encode: (m) => m,
  );

  String _dvConversionModeLabel(DvConversionModePreference mode) => switch (mode) {
    DvConversionModePreference.auto => t.settings.dvConversionAuto,
    DvConversionModePreference.disabled => t.settings.dvConversionNative,
    DvConversionModePreference.dv81 => t.settings.dvConversionDv81,
    DvConversionModePreference.hevcStrip => t.settings.dvConversionHevcStrip,
  };

  Widget _bufferSizeTile() {
    final bufferOptions = const [0, 64, 128, 256, 512, 1024];
    return SettingSelectionTile<int, int>(
      pref: SettingsService.bufferSize,
      icon: Symbols.memory_rounded,
      title: t.settings.bufferSize,
      subtitleBuilder: (v) => v == 0 ? t.settings.bufferSizeAuto : t.settings.bufferSizeMB(size: v.toString()),
      options: bufferOptions
          .map((s) => DialogOption(value: s, title: s == 0 ? t.settings.bufferSizeAuto : '${s}MB'))
          .toList(),
      decode: (s) => s,
      encode: (s) => s,
      onAfterWrite: (value) async {
        if (Platform.isAndroid && value > 0) {
          final heapMB = await PlayerAndroid.getHeapSize();
          if (heapMB > 0 && value > heapMB ~/ 4 && mounted) {
            showAppSnackBar(context, t.settings.bufferSizeWarning(heap: heapMB.toString(), size: value.toString()));
          }
        }
      },
    );
  }

  Widget _defaultQualityTile() => SettingSelectionTile<TranscodeQualityPreset, TranscodeQualityPreset>(
    pref: SettingsService.defaultQualityPreset,
    icon: Symbols.high_quality_rounded,
    title: t.settings.defaultQualityTitle,
    subtitleBuilder: qualityPresetLabel,
    options: TranscodeQualityPreset.displayOrder
        .map((p) => DialogOption(value: p, title: qualityPresetLabel(p)))
        .toList(),
    decode: (p) => p,
    encode: (p) => p,
  );

  Widget _musicQualityTile() => SettingSelectionTile<AudioQualityPreset, AudioQualityPreset>(
    pref: SettingsService.musicQualityPreset,
    icon: Symbols.music_note_rounded,
    title: t.settings.musicQualityTitle,
    subtitleBuilder: _musicQualityLabel,
    options: AudioQualityPreset.values.map((p) => DialogOption(value: p, title: _musicQualityLabel(p))).toList(),
    decode: (p) => p,
    encode: (p) => p,
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
