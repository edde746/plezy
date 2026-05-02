import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../models/transcode_quality_preset.dart';
import '../../mpv/player/platform/player_android.dart';
import '../../utils/quality_preset_labels.dart';
import '../../services/discord_rpc_service.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
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

    return FocusedScrollScaffold(
      title: Text(t.settings.videoPlayback),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            SettingsSectionHeader(t.settings.player),
            if (Platform.isAndroid) _playerBackendSelector(),
            _externalPlayerTile(),
            _hardwareDecodingTile(),
            if ((Platform.isAndroid && !PlatformDetector.isTV()) || Platform.isIOS || Platform.isMacOS) _autoPipTile(),
            if (Platform.isAndroid) _matchContentFrameRateTile(),
            if (Platform.isWindows) _matchRefreshRateTile(),
            if (Platform.isWindows) _matchDynamicRangeTile(),
            _displaySwitchDelayTile(),
            _tunneledPlaybackTile(),
            _bufferSizeTile(),
            _defaultQualityTile(),

            SettingsSectionHeader(t.settings.subtitlesAndConfig),
            SettingNavigationTile(
              icon: Symbols.subtitles_rounded,
              title: t.settings.subtitleStyling,
              subtitle: t.settings.subtitleStylingDescription,
              destinationBuilder: (_) => const SubtitleStylingScreen(),
            ),
            _mpvConfigTile(),

            SettingsSectionHeader(t.settings.seekAndTiming),
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

            SettingsSectionHeader(t.settings.behavior),
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
              ),
            SettingSwitchTile(
              pref: SettingsService.rememberTrackSelections,
              icon: Symbols.bookmark_rounded,
              title: t.settings.rememberTrackSelections,
              subtitle: t.settings.rememberTrackSelectionsDescription,
            ),
            if (!isMobile)
              SettingSwitchTile(
                pref: SettingsService.clickVideoTogglesPlayback,
                icon: Symbols.play_pause_rounded,
                title: t.settings.clickVideoTogglesPlayback,
                subtitle: t.settings.clickVideoTogglesPlaybackDescription,
              ),

            SettingsSectionHeader(t.settings.autoSkip),
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
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

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
      final svc = SettingsService.instanceOrNull!;
      final useExt = svc.read(SettingsService.useExternalPlayer);
      final player = svc.read(SettingsService.selectedExternalPlayer);
      return SettingNavigationTile(
        icon: Symbols.open_in_new_rounded,
        title: t.externalPlayer.title,
        subtitle: useExt ? player.name : t.externalPlayer.off,
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

  Widget _displaySwitchDelayTile() => SettingsBuilder(
    prefs: const [
      SettingsService.matchRefreshRate,
      SettingsService.matchDynamicRange,
      SettingsService.matchContentFrameRate,
    ],
    builder: (context) {
      final svc = SettingsService.instanceOrNull!;
      final shouldShow =
          (Platform.isWindows &&
              (svc.read(SettingsService.matchRefreshRate) || svc.read(SettingsService.matchDynamicRange))) ||
          (Platform.isAndroid && svc.read(SettingsService.matchContentFrameRate));
      if (!shouldShow) return const SizedBox.shrink();
      return SettingNumberTile(
        pref: SettingsService.displaySwitchDelay,
        icon: Symbols.timer_rounded,
        title: t.settings.displaySwitchDelay,
        subtitleBuilder: (v) => t.settings.secondsUnit(seconds: v.toString()),
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 0,
        max: 10,
      );
    },
  );

  Widget _tunneledPlaybackTile() => SettingValueBuilder<bool>(
    pref: SettingsService.useExoPlayer,
    builder: (_, useExo, _) {
      if (!Platform.isAndroid || !useExo) return const SizedBox.shrink();
      return SettingSwitchTile(
        pref: SettingsService.tunneledPlayback,
        icon: Symbols.tv_options_input_settings_rounded,
        title: t.settings.tunneledPlayback,
        subtitle: t.settings.tunneledPlaybackDescription,
      );
    },
  );

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

  Widget _mpvConfigTile() => SettingValueBuilder<bool>(
    pref: SettingsService.useExoPlayer,
    builder: (_, useExo, _) {
      if (Platform.isAndroid && useExo) return const SizedBox.shrink();
      return SettingNavigationTile(
        icon: Symbols.tune_rounded,
        title: t.mpvConfig.title,
        subtitle: t.mpvConfig.description,
        destinationBuilder: (_) => const MpvConfigScreen(),
      );
    },
  );
}
