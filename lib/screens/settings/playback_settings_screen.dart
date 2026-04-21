import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../mpv/player/platform/player_android.dart';
import '../../services/discord_rpc_service.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
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
  late settings.SettingsService _settingsService;
  KeyboardShortcutsService? _keyboardService;
  bool _isLoading = true;

  bool _enableHardwareDecoding = true;
  int _bufferSize = 0;
  int _seekTimeSmall = 10;
  int _seekTimeLarge = 30;
  int _rewindOnResume = 0;
  int _sleepTimerDuration = 30;
  bool _rememberTrackSelections = true;
  bool _clickVideoTogglesPlayback = false;
  bool _autoSkipIntro = false;
  bool _autoSkipCredits = false;
  int _autoSkipDelay = 5;
  String _introPattern = settings.SettingsService.defaultIntroPattern;
  String _creditsPattern = settings.SettingsService.defaultCreditsPattern;
  int _maxVolume = 100;
  bool _enableDiscordRPC = false;
  bool _enableCompanionRemoteServer = false;
  bool _autoPip = true;
  bool _matchContentFrameRate = false;
  bool _matchRefreshRate = false;
  bool _matchDynamicRange = false;
  int _displaySwitchDelay = 0;
  bool _tunneledPlayback = true;
  bool _useExoPlayer = true;
  bool _useExternalPlayer = false;
  String _selectedExternalPlayerName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    if (KeyboardShortcutsService.isPlatformSupported()) {
      _keyboardService = await KeyboardShortcutsService.getInstance();
    }

    if (!mounted) return;
    setState(() {
      _enableHardwareDecoding = _settingsService.getEnableHardwareDecoding();
      _bufferSize = _settingsService.getBufferSize();
      _seekTimeSmall = _settingsService.getSeekTimeSmall();
      _seekTimeLarge = _settingsService.getSeekTimeLarge();
      _rewindOnResume = _settingsService.getRewindOnResume();
      _sleepTimerDuration = _settingsService.getSleepTimerDuration();
      _rememberTrackSelections = _settingsService.getRememberTrackSelections();
      _clickVideoTogglesPlayback = _settingsService.getClickVideoTogglesPlayback();
      _autoSkipIntro = _settingsService.getAutoSkipIntro();
      _autoSkipCredits = _settingsService.getAutoSkipCredits();
      _autoSkipDelay = _settingsService.getAutoSkipDelay();
      _introPattern = _settingsService.getIntroPattern();
      _creditsPattern = _settingsService.getCreditsPattern();
      _maxVolume = _settingsService.getMaxVolume();
      _enableDiscordRPC = _settingsService.getEnableDiscordRPC();
      _enableCompanionRemoteServer = _settingsService.getEnableCompanionRemoteServer();
      _autoPip = _settingsService.getAutoPip();
      _matchContentFrameRate = _settingsService.getMatchContentFrameRate();
      _matchRefreshRate = _settingsService.getMatchRefreshRate();
      _matchDynamicRange = _settingsService.getMatchDynamicRange();
      _displaySwitchDelay = _settingsService.getDisplaySwitchDelay();
      _tunneledPlayback = _settingsService.getTunneledPlayback();
      _useExoPlayer = _settingsService.getUseExoPlayer();
      _useExternalPlayer = _settingsService.getUseExternalPlayer();
      _selectedExternalPlayerName = _settingsService.getSelectedExternalPlayer().name;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FocusedScrollScaffold(
        title: Text(t.settings.videoPlayback),
        slivers: [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

    final isMobile = PlatformDetector.isMobile(context);

    return FocusedScrollScaffold(
      title: Text(t.settings.videoPlayback),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // --- Player ---
            SettingsSectionHeader(t.settings.player),
            if (Platform.isAndroid) _buildPlayerBackendSelector(),
            _buildExternalPlayerTile(),
            _buildHardwareDecoding(),
            if ((Platform.isAndroid && !PlatformDetector.isTV()) || Platform.isIOS || Platform.isMacOS) _buildAutoPip(),
            if (Platform.isAndroid) _buildMatchContentFrameRate(),
            if (Platform.isWindows) _buildMatchRefreshRate(),
            if (Platform.isWindows) _buildMatchDynamicRange(),
            if ((Platform.isWindows && (_matchRefreshRate || _matchDynamicRange)) ||
                (Platform.isAndroid && _matchContentFrameRate))
              _buildDisplaySwitchDelay(),
            if (Platform.isAndroid && _useExoPlayer) _buildTunneledPlayback(),
            _buildBufferSizeSelector(),

            // --- Subtitles & Config ---
            SettingsSectionHeader(t.settings.subtitlesAndConfig),
            _buildSubtitleStylingTile(),
            if (!Platform.isAndroid || !_useExoPlayer) _buildMpvConfigTile(),

            // --- Seek & Timing ---
            SettingsSectionHeader(t.settings.seekAndTiming),
            _buildSmallSkipDuration(),
            _buildLargeSkipDuration(),
            _buildRewindOnResume(),
            _buildDefaultSleepTimer(),
            _buildMaxVolume(),

            // --- Behavior ---
            SettingsSectionHeader(t.settings.behavior),
            if (DiscordRPCService.isAvailable) _buildDiscordRPC(),
            if (PlatformDetector.shouldActAsRemoteHost(context)) _buildCompanionRemoteServer(),
            _buildRememberTrackSelections(),
            if (!isMobile) _buildClickVideoTogglesPlayback(),

            // --- Auto-Skip ---
            SettingsSectionHeader(t.settings.autoSkip),
            _buildAutoSkipIntro(),
            _buildAutoSkipCredits(),
            _buildAutoSkipDelay(),
            _buildIntroPattern(),
            _buildCreditsPattern(),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  // --- Player section ---

  Widget _buildPlayerBackendSelector() {
    return SegmentedSetting<bool>(
      icon: Symbols.play_circle_rounded,
      title: t.settings.playerBackend,
      segments: [
        ButtonSegment(value: true, label: Text(t.settings.exoPlayer)),
        ButtonSegment(value: false, label: Text(t.settings.mpv)),
      ],
      selected: _useExoPlayer,
      onChanged: (value) async {
        setState(() => _useExoPlayer = value);
        await _settingsService.setUseExoPlayer(value);
      },
    );
  }

  Widget _buildExternalPlayerTile() {
    return ListTile(
      leading: const AppIcon(Symbols.open_in_new_rounded, fill: 1),
      title: Text(t.externalPlayer.title),
      subtitle: Text(_useExternalPlayer ? _selectedExternalPlayerName : t.externalPlayer.off),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const ExternalPlayerScreen()));
        final s = await settings.SettingsService.getInstance();
        if (!mounted) return;
        setState(() {
          _useExternalPlayer = s.getUseExternalPlayer();
          _selectedExternalPlayerName = s.getSelectedExternalPlayer().name;
        });
      },
    );
  }

  Widget _buildHardwareDecoding() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.hardware_rounded, fill: 1),
      title: Text(t.settings.hardwareDecoding),
      subtitle: Text(t.settings.hardwareDecodingDescription),
      value: _enableHardwareDecoding,
      onChanged: (value) async {
        setState(() => _enableHardwareDecoding = value);
        await _settingsService.setEnableHardwareDecoding(value);
      },
    );
  }

  Widget _buildAutoPip() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.picture_in_picture_alt_rounded, fill: 1),
      title: Text(t.settings.autoPip),
      subtitle: Text(t.settings.autoPipDescription),
      value: _autoPip,
      onChanged: (value) async {
        setState(() => _autoPip = value);
        await _settingsService.setAutoPip(value);
      },
    );
  }

  Widget _buildMatchContentFrameRate() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.display_settings_rounded, fill: 1),
      title: Text(t.settings.matchContentFrameRate),
      subtitle: Text(t.settings.matchContentFrameRateDescription),
      value: _matchContentFrameRate,
      onChanged: (value) async {
        setState(() => _matchContentFrameRate = value);
        await _settingsService.setMatchContentFrameRate(value);
      },
    );
  }

  Widget _buildMatchRefreshRate() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.display_settings_rounded, fill: 1),
      title: Text(t.settings.matchRefreshRate),
      subtitle: Text(t.settings.matchRefreshRateDescription),
      value: _matchRefreshRate,
      onChanged: (value) async {
        setState(() => _matchRefreshRate = value);
        await _settingsService.setMatchRefreshRate(value);
      },
    );
  }

  Widget _buildMatchDynamicRange() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.hdr_on_rounded, fill: 1),
      title: Text(t.settings.matchDynamicRange),
      subtitle: Text(t.settings.matchDynamicRangeDescription),
      value: _matchDynamicRange,
      onChanged: (value) async {
        setState(() => _matchDynamicRange = value);
        await _settingsService.setMatchDynamicRange(value);
      },
    );
  }

  Widget _buildDisplaySwitchDelay() {
    return ListTile(
      leading: const AppIcon(Symbols.timer_rounded, fill: 1),
      title: Text(t.settings.displaySwitchDelay),
      subtitle: Text(t.settings.secondsUnit(seconds: _displaySwitchDelay.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.displaySwitchDelay,
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 0,
        max: 10,
        currentValue: _displaySwitchDelay,
        onSave: (value) async {
          setState(() => _displaySwitchDelay = value);
          await _settingsService.setDisplaySwitchDelay(value);
        },
      ),
    );
  }

  Widget _buildTunneledPlayback() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.tv_options_input_settings_rounded, fill: 1),
      title: Text(t.settings.tunneledPlayback),
      subtitle: Text(t.settings.tunneledPlaybackDescription),
      value: _tunneledPlayback,
      onChanged: (value) async {
        setState(() => _tunneledPlayback = value);
        await _settingsService.setTunneledPlayback(value);
      },
    );
  }

  Widget _buildBufferSizeSelector() {
    return ListTile(
      leading: const AppIcon(Symbols.memory_rounded, fill: 1),
      title: Text(t.settings.bufferSize),
      subtitle: Text(
        _bufferSize == 0 ? t.settings.bufferSizeAuto : t.settings.bufferSizeMB(size: _bufferSize.toString()),
      ),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () async {
        final bufferOptions = [0, 64, 128, 256, 512, 1024];
        final value = await showSelectionDialog<int>(
          context: context,
          title: t.settings.bufferSize,
          options: bufferOptions
              .map((size) => DialogOption(value: size, title: size == 0 ? t.settings.bufferSizeAuto : '${size}MB'))
              .toList(),
          currentValue: _bufferSize,
        );
        if (value != null) {
          setState(() {
            _bufferSize = value;
            _settingsService.setBufferSize(value);
          });
          if (Platform.isAndroid && value > 0) {
            final heapMB = await PlayerAndroid.getHeapSize();
            if (heapMB > 0 && value > heapMB ~/ 4 && mounted) {
              showAppSnackBar(context, t.settings.bufferSizeWarning(heap: heapMB.toString(), size: value.toString()));
            }
          }
        }
      },
    );
  }

  // --- Subtitles & Config section ---

  Widget _buildSubtitleStylingTile() {
    return ListTile(
      leading: const AppIcon(Symbols.subtitles_rounded, fill: 1),
      title: Text(t.settings.subtitleStyling),
      subtitle: Text(t.settings.subtitleStylingDescription),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SubtitleStylingScreen()));
      },
    );
  }

  Widget _buildMpvConfigTile() {
    return ListTile(
      leading: const AppIcon(Symbols.tune_rounded, fill: 1),
      title: Text(t.mpvConfig.title),
      subtitle: Text(t.mpvConfig.description),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MpvConfigScreen()));
      },
    );
  }

  // --- Seek & Timing section ---

  Widget _buildSmallSkipDuration() {
    return ListTile(
      leading: const AppIcon(Symbols.replay_10_rounded, fill: 1),
      title: Text(t.settings.smallSkipDuration),
      subtitle: Text(t.settings.secondsUnit(seconds: _seekTimeSmall.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.smallSkipDuration,
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 1,
        max: 120,
        currentValue: _seekTimeSmall,
        onSave: (value) async {
          setState(() {
            _seekTimeSmall = value;
            _settingsService.setSeekTimeSmall(value);
          });
          await _keyboardService?.refreshFromStorage();
        },
      ),
    );
  }

  Widget _buildLargeSkipDuration() {
    return ListTile(
      leading: const AppIcon(Symbols.replay_30_rounded, fill: 1),
      title: Text(t.settings.largeSkipDuration),
      subtitle: Text(t.settings.secondsUnit(seconds: _seekTimeLarge.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.largeSkipDuration,
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 1,
        max: 120,
        currentValue: _seekTimeLarge,
        onSave: (value) async {
          setState(() {
            _seekTimeLarge = value;
            _settingsService.setSeekTimeLarge(value);
          });
          await _keyboardService?.refreshFromStorage();
        },
      ),
    );
  }

  Widget _buildRewindOnResume() {
    return ListTile(
      leading: const AppIcon(Symbols.replay_rounded, fill: 1),
      title: Text(t.settings.rewindOnResume),
      subtitle: Text(t.settings.secondsUnit(seconds: _rewindOnResume.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.rewindOnResume,
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 0,
        max: 10,
        currentValue: _rewindOnResume,
        onSave: (value) async {
          setState(() {
            _rewindOnResume = value;
            _settingsService.setRewindOnResume(value);
          });
        },
      ),
    );
  }

  Widget _buildDefaultSleepTimer() {
    return ListTile(
      leading: const AppIcon(Symbols.bedtime_rounded, fill: 1),
      title: Text(t.settings.defaultSleepTimer),
      subtitle: Text(t.settings.minutesUnit(minutes: _sleepTimerDuration.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.defaultSleepTimer,
        labelText: t.settings.minutesLabel,
        suffixText: t.settings.minutesShort,
        min: 5,
        max: 240,
        currentValue: _sleepTimerDuration,
        onSave: (value) async {
          setState(() => _sleepTimerDuration = value);
          await _settingsService.setSleepTimerDuration(value);
        },
      ),
    );
  }

  Widget _buildMaxVolume() {
    return ListTile(
      leading: const AppIcon(Symbols.volume_up_rounded, fill: 1),
      title: Text(t.settings.maxVolume),
      subtitle: Text(t.settings.maxVolumePercent(percent: _maxVolume.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.maxVolume,
        labelText: t.settings.maxVolumeDescription,
        suffixText: '%',
        min: 100,
        max: 300,
        currentValue: _maxVolume,
        onSave: (value) async {
          setState(() => _maxVolume = value);
          await _settingsService.setMaxVolume(value);
        },
      ),
    );
  }

  // --- Behavior section ---

  Widget _buildDiscordRPC() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.chat_rounded, fill: 1),
      title: Text(t.settings.discordRichPresence),
      subtitle: Text(t.settings.discordRichPresenceDescription),
      value: _enableDiscordRPC,
      onChanged: (value) async {
        setState(() => _enableDiscordRPC = value);
        await _settingsService.setEnableDiscordRPC(value);
        await DiscordRPCService.instance.setEnabled(value);
      },
    );
  }

  Widget _buildCompanionRemoteServer() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.phone_android_rounded, fill: 1),
      title: Text(t.settings.companionRemoteServer),
      subtitle: Text(t.settings.companionRemoteServerDescription),
      value: _enableCompanionRemoteServer,
      onChanged: (value) async {
        setState(() => _enableCompanionRemoteServer = value);
        await _settingsService.setEnableCompanionRemoteServer(value);
      },
    );
  }

  Widget _buildRememberTrackSelections() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.bookmark_rounded, fill: 1),
      title: Text(t.settings.rememberTrackSelections),
      subtitle: Text(t.settings.rememberTrackSelectionsDescription),
      value: _rememberTrackSelections,
      onChanged: (value) async {
        setState(() => _rememberTrackSelections = value);
        await _settingsService.setRememberTrackSelections(value);
      },
    );
  }

  Widget _buildClickVideoTogglesPlayback() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.play_pause_rounded, fill: 1),
      title: Text(t.settings.clickVideoTogglesPlayback),
      subtitle: Text(t.settings.clickVideoTogglesPlaybackDescription),
      value: _clickVideoTogglesPlayback,
      onChanged: (value) async {
        setState(() => _clickVideoTogglesPlayback = value);
        await _settingsService.setClickVideoTogglesPlayback(value);
      },
    );
  }

  // --- Auto-Skip section ---

  Widget _buildAutoSkipIntro() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.fast_forward_rounded, fill: 1),
      title: Text(t.settings.autoSkipIntro),
      subtitle: Text(t.settings.autoSkipIntroDescription),
      value: _autoSkipIntro,
      onChanged: (value) async {
        setState(() => _autoSkipIntro = value);
        await _settingsService.setAutoSkipIntro(value);
      },
    );
  }

  Widget _buildAutoSkipCredits() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.skip_next_rounded, fill: 1),
      title: Text(t.settings.autoSkipCredits),
      subtitle: Text(t.settings.autoSkipCreditsDescription),
      value: _autoSkipCredits,
      onChanged: (value) async {
        setState(() => _autoSkipCredits = value);
        await _settingsService.setAutoSkipCredits(value);
      },
    );
  }

  Widget _buildAutoSkipDelay() {
    return ListTile(
      leading: const AppIcon(Symbols.timer_rounded, fill: 1),
      title: Text(t.settings.autoSkipDelay),
      subtitle: Text(t.settings.autoSkipDelayDescription(seconds: _autoSkipDelay.toString())),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showNumericInputDialog(
        context: context,
        title: t.settings.autoSkipDelay,
        labelText: t.settings.secondsLabel,
        suffixText: t.settings.secondsShort,
        min: 1,
        max: 30,
        currentValue: _autoSkipDelay,
        onSave: (value) async {
          setState(() => _autoSkipDelay = value);
          await _settingsService.setAutoSkipDelay(value);
        },
      ),
    );
  }

  Widget _buildIntroPattern() {
    return ListTile(
      leading: const AppIcon(Symbols.match_case_rounded, fill: 1),
      title: Text(t.settings.introPattern),
      subtitle: Text(t.settings.introPatternDescription),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showRegexInputDialog(
        context: context,
        title: t.settings.introPattern,
        currentValue: _introPattern,
        defaultValue: settings.SettingsService.defaultIntroPattern,
        onSave: (value) async {
          setState(() => _introPattern = value);
          await _settingsService.setIntroPattern(value);
        },
      ),
    );
  }

  Widget _buildCreditsPattern() {
    return ListTile(
      leading: const AppIcon(Symbols.match_case_rounded, fill: 1),
      title: Text(t.settings.creditsPattern),
      subtitle: Text(t.settings.creditsPatternDescription),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () => showRegexInputDialog(
        context: context,
        title: t.settings.creditsPattern,
        currentValue: _creditsPattern,
        defaultValue: settings.SettingsService.defaultCreditsPattern,
        onSave: (value) async {
          setState(() => _creditsPattern = value);
          await _settingsService.setCreditsPattern(value);
        },
      ),
    );
  }
}
