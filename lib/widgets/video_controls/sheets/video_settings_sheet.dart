import '../../../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:provider/provider.dart';

import '../../../models/shader_preset.dart';
import '../../../mpv/mpv.dart';
import '../../../providers/shader_provider.dart';
import '../../../services/settings_service.dart';
import '../../../services/shader_service.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/formatters.dart';
import '../../../utils/platform_detector.dart';
import '../../../widgets/focusable_bottom_sheet.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../widgets/sync_offset_control.dart';
import '../widgets/sleep_timer_content.dart';
import '../../../i18n/strings.g.dart';
import 'base_video_control_sheet.dart';

enum _SettingsView { menu, speed, sleep, audioSync, subtitleSync, audioDevice, shader }

/// Reusable menu item widget for settings sheet
class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueText;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool allowValueOverflow;
  final FocusNode? focusNode;

  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.valueText,
    required this.onTap,
    this.isHighlighted = false,
    this.allowValueOverflow = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      valueText,
      style: TextStyle(color: isHighlighted ? Colors.amber : Colors.white70, fontSize: 14),
      overflow: allowValueOverflow ? TextOverflow.ellipsis : null,
    );

    return FocusableListTile(
      focusNode: focusNode,
      leading: AppIcon(icon, fill: 1, color: isHighlighted ? Colors.amber : Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allowValueOverflow) Flexible(child: valueWidget) else valueWidget,
          const SizedBox(width: 8),
          const AppIcon(Symbols.chevron_right_rounded, fill: 1, color: Colors.white70),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Unified settings sheet for playback adjustments with in-sheet navigation
class VideoSettingsSheet extends StatefulWidget {
  final Player player;
  final int audioSyncOffset;
  final int subtitleSyncOffset;

  /// Whether the user can control playback (false hides speed option in host-only mode).
  final bool canControl;

  /// Optional shader service for MPV shader control
  final ShaderService? shaderService;

  /// Called when shader preset changes
  final VoidCallback? onShaderChanged;

  const VideoSettingsSheet({
    super.key,
    required this.player,
    required this.audioSyncOffset,
    required this.subtitleSyncOffset,
    this.canControl = true,
    this.shaderService,
    this.onShaderChanged,
  });

  static Future<void> show(
    BuildContext context,
    Player player,
    int audioSyncOffset,
    int subtitleSyncOffset, {
    VoidCallback? onOpen,
    VoidCallback? onClose,
    bool canControl = true,
    ShaderService? shaderService,
    VoidCallback? onShaderChanged,
  }) {
    return BaseVideoControlSheet.showSheet(
      context: context,
      onOpen: onOpen,
      onClose: onClose,
      builder: (context) => VideoSettingsSheet(
        player: player,
        audioSyncOffset: audioSyncOffset,
        subtitleSyncOffset: subtitleSyncOffset,
        canControl: canControl,
        shaderService: shaderService,
        onShaderChanged: onShaderChanged,
      ),
    );
  }

  @override
  State<VideoSettingsSheet> createState() => _VideoSettingsSheetState();
}

class _VideoSettingsSheetState extends State<VideoSettingsSheet> {
  _SettingsView _currentView = _SettingsView.menu;
  late int _audioSyncOffset;
  late int _subtitleSyncOffset;
  bool _enableHDR = true;
  bool _showPerformanceOverlay = false;
  bool _autoPlayNextEpisode = true;
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _audioSyncOffset = widget.audioSyncOffset;
    _subtitleSyncOffset = widget.subtitleSyncOffset;
    _initialFocusNode = FocusNode(debugLabel: 'VideoSettingsInitialFocus');
    _loadSettings();
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getInstance();
    setState(() {
      _enableHDR = settings.getEnableHDR();
      _showPerformanceOverlay = settings.getShowPerformanceOverlay();
      _autoPlayNextEpisode = settings.getAutoPlayNextEpisode();
    });
  }

  Future<void> _toggleHDR() async {
    final newValue = !_enableHDR;
    final settings = await SettingsService.getInstance();
    await settings.setEnableHDR(newValue);
    setState(() {
      _enableHDR = newValue;
    });
    // Apply to player immediately
    await widget.player.setProperty('hdr-enabled', newValue ? 'yes' : 'no');
  }

  Future<void> _togglePerformanceOverlay() async {
    final newValue = !_showPerformanceOverlay;
    final settings = await SettingsService.getInstance();
    await settings.setShowPerformanceOverlay(newValue);
    setState(() {
      _showPerformanceOverlay = newValue;
    });
  }

  Future<void> _toggleAutoPlayNextEpisode() async {
    final newValue = !_autoPlayNextEpisode;
    final settings = await SettingsService.getInstance();
    await settings.setAutoPlayNextEpisode(newValue);
    setState(() {
      _autoPlayNextEpisode = newValue;
    });
  }

  void _navigateTo(_SettingsView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _navigateBack() {
    setState(() {
      _currentView = _SettingsView.menu;
    });
  }

  String _getTitle() {
    switch (_currentView) {
      case _SettingsView.menu:
        return t.videoSettings.playbackSettings;
      case _SettingsView.speed:
        return t.videoSettings.playbackSpeed;
      case _SettingsView.sleep:
        return t.videoSettings.sleepTimer;
      case _SettingsView.audioSync:
        return t.videoSettings.audioSync;
      case _SettingsView.subtitleSync:
        return t.videoSettings.subtitleSync;
      case _SettingsView.audioDevice:
        return t.videoSettings.audioOutput;
      case _SettingsView.shader:
        return t.shaders.title;
    }
  }

  IconData _getIcon() {
    switch (_currentView) {
      case _SettingsView.menu:
        return Symbols.tune_rounded;
      case _SettingsView.speed:
        return Symbols.speed_rounded;
      case _SettingsView.sleep:
        return Symbols.bedtime_rounded;
      case _SettingsView.audioSync:
        return Symbols.sync_rounded;
      case _SettingsView.subtitleSync:
        return Symbols.subtitles_rounded;
      case _SettingsView.audioDevice:
        return Symbols.speaker_rounded;
      case _SettingsView.shader:
        return Symbols.auto_fix_high_rounded;
    }
  }

  String _formatSpeed(double speed) {
    if (speed == 1.0) return 'Normal';
    return '${speed.toStringAsFixed(2)}x';
  }

  String _formatSleepTimer(SleepTimerService sleepTimer) {
    if (!sleepTimer.isActive) return 'Off';
    final remaining = sleepTimer.remainingTime;
    if (remaining == null) return 'Off';
    return 'Active (${formatDurationWithSeconds(remaining)})';
  }

  Widget _buildMenuView() {
    final sleepTimer = SleepTimerService();
    final isDesktop = PlatformDetector.isDesktop(context);

    return ListView(
      children: [
        // Playback Speed - only show if user can control playback
        if (widget.canControl)
          StreamBuilder<double>(
            stream: widget.player.streams.rate,
            initialData: widget.player.state.rate,
            builder: (context, snapshot) {
              final currentRate = snapshot.data ?? 1.0;
              return _SettingsMenuItem(
                focusNode: _initialFocusNode,
                icon: Symbols.speed_rounded,
                title: t.videoSettings.playbackSpeed,
                valueText: _formatSpeed(currentRate),
                onTap: () => _navigateTo(_SettingsView.speed),
              );
            },
          ),

        // Sleep Timer
        ListenableBuilder(
          listenable: sleepTimer,
          builder: (context, _) {
            final isActive = sleepTimer.isActive;
            return _SettingsMenuItem(
              icon: isActive ? Symbols.bedtime_rounded : Symbols.bedtime_rounded,
              title: t.videoSettings.sleepTimer,
              valueText: _formatSleepTimer(sleepTimer),
              isHighlighted: isActive,
              onTap: () => _navigateTo(_SettingsView.sleep),
            );
          },
        ),

        // Audio Sync
        _SettingsMenuItem(
          icon: Symbols.sync_rounded,
          title: t.videoSettings.audioSync,
          valueText: formatSyncOffset(_audioSyncOffset.toDouble()),
          isHighlighted: _audioSyncOffset != 0,
          onTap: () => _navigateTo(_SettingsView.audioSync),
        ),

        // Subtitle Sync
        _SettingsMenuItem(
          icon: Symbols.subtitles_rounded,
          title: t.videoSettings.subtitleSync,
          valueText: formatSyncOffset(_subtitleSyncOffset.toDouble()),
          isHighlighted: _subtitleSyncOffset != 0,
          onTap: () => _navigateTo(_SettingsView.subtitleSync),
        ),

        // HDR Toggle (iOS, macOS, and Windows)
        if (AppPlatform.isIOS || AppPlatform.isMacOS || AppPlatform.isWindows)
          ListTile(
            leading: AppIcon(Symbols.hdr_strong_rounded, fill: 1, color: _enableHDR ? Colors.amber : Colors.white70),
            title: Text(t.videoSettings.hdr, style: const TextStyle(color: Colors.white)),
            trailing: Switch(value: _enableHDR, onChanged: (_) => _toggleHDR(), activeThumbColor: Colors.amber),
            onTap: _toggleHDR,
          ),

        // Auto-Play Next Episode Toggle
        ListTile(
          leading: AppIcon(
            Symbols.skip_next_rounded,
            fill: 1,
            color: _autoPlayNextEpisode ? Colors.amber : Colors.white70,
          ),
          title: Text(t.videoControls.autoPlayNext, style: const TextStyle(color: Colors.white)),
          trailing: Switch(
            value: _autoPlayNextEpisode,
            onChanged: (_) => _toggleAutoPlayNextEpisode(),
            activeThumbColor: Colors.amber,
          ),
          onTap: _toggleAutoPlayNextEpisode,
        ),

        // Audio Output Device (Desktop only)
        if (isDesktop)
          StreamBuilder<AudioDevice>(
            stream: widget.player.streams.audioDevice,
            initialData: widget.player.state.audioDevice,
            builder: (context, snapshot) {
              final currentDevice = snapshot.data ?? widget.player.state.audioDevice;
              final deviceLabel = currentDevice.description.isEmpty
                  ? currentDevice.name
                  : '${currentDevice.name} · ${currentDevice.description}';

              return _SettingsMenuItem(
                icon: Symbols.speaker_rounded,
                title: t.videoSettings.audioOutput,
                valueText: deviceLabel,
                allowValueOverflow: true,
                onTap: () => _navigateTo(_SettingsView.audioDevice),
              );
            },
          ),

        // Shader Preset (MPV only)
        if (widget.shaderService != null && widget.shaderService!.isSupported)
          _SettingsMenuItem(
            icon: Symbols.auto_fix_high_rounded,
            title: t.shaders.title,
            valueText: widget.shaderService!.currentPreset.name,
            isHighlighted: widget.shaderService!.currentPreset.isEnabled,
            onTap: () => _navigateTo(_SettingsView.shader),
          ),

        // Performance Overlay Toggle
        ListTile(
          leading: AppIcon(
            Symbols.analytics_rounded,
            fill: 1,
            color: _showPerformanceOverlay ? Colors.amber : Colors.white70,
          ),
          title: Text(t.videoSettings.performanceOverlay, style: const TextStyle(color: Colors.white)),
          trailing: Switch(
            value: _showPerformanceOverlay,
            onChanged: (_) => _togglePerformanceOverlay(),
            activeThumbColor: Colors.amber,
          ),
          onTap: _togglePerformanceOverlay,
        ),
      ],
    );
  }

  Widget _buildSpeedView() {
    return StreamBuilder<double>(
      stream: widget.player.streams.rate,
      initialData: widget.player.state.rate,
      builder: (context, snapshot) {
        final currentRate = snapshot.data ?? 1.0;
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0];

        return ListView.builder(
          itemCount: speeds.length,
          itemBuilder: (context, index) {
            final speed = speeds[index];
            final isSelected = (currentRate - speed).abs() < 0.01;
            final label = speed == 1.0 ? 'Normal' : '${speed.toStringAsFixed(2)}x';

            return ListTile(
              title: Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
              trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.blue) : null,
              onTap: () async {
                widget.player.setRate(speed);
                // Save as default playback speed
                final settings = await SettingsService.getInstance();
                await settings.setDefaultPlaybackSpeed(speed);
                if (context.mounted) {
                  Navigator.pop(context); // Close sheet after selection
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSleepView() {
    final sleepTimer = SleepTimerService();

    return SleepTimerContent(player: widget.player, sleepTimer: sleepTimer, onCancel: () => Navigator.pop(context));
  }

  Widget _buildAudioSyncView() {
    return SyncOffsetControl(
      player: widget.player,
      propertyName: 'audio-delay',
      initialOffset: _audioSyncOffset,
      labelText: t.videoControls.audioLabel,
      onOffsetChanged: (offset) async {
        final settings = await SettingsService.getInstance();
        await settings.setAudioSyncOffset(offset);
        setState(() {
          _audioSyncOffset = offset;
        });
      },
    );
  }

  Widget _buildSubtitleSyncView() {
    return SyncOffsetControl(
      player: widget.player,
      propertyName: 'sub-delay',
      initialOffset: _subtitleSyncOffset,
      labelText: t.videoControls.subtitlesLabel,
      onOffsetChanged: (offset) async {
        final settings = await SettingsService.getInstance();
        await settings.setSubtitleSyncOffset(offset);
        setState(() {
          _subtitleSyncOffset = offset;
        });
      },
    );
  }

  Widget _buildAudioDeviceView() {
    return StreamBuilder<List<AudioDevice>>(
      stream: widget.player.streams.audioDevices,
      initialData: widget.player.state.audioDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        return StreamBuilder<AudioDevice>(
          stream: widget.player.streams.audioDevice,
          initialData: widget.player.state.audioDevice,
          builder: (context, selectedSnapshot) {
            final currentDevice = selectedSnapshot.data ?? widget.player.state.audioDevice;

            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelected = device.name == currentDevice.name;
                final label = device.description.isEmpty ? device.name : device.description;

                return ListTile(
                  title: Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
                  trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.blue) : null,
                  onTap: () {
                    widget.player.setAudioDevice(device);
                    Navigator.pop(context); // Close sheet after selection
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShaderView() {
    if (widget.shaderService == null) return const SizedBox.shrink();

    return Consumer<ShaderProvider>(
      builder: (context, shaderProvider, _) {
        final currentPreset = widget.shaderService!.currentPreset;
        final presets = ShaderPreset.allPresets;

        return ListView.builder(
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            final isSelected = preset.id == currentPreset.id;

            return FocusableListTile(
              title: Text(preset.name, style: TextStyle(color: isSelected ? Colors.amber : Colors.white)),
              subtitle: _getShaderSubtitle(preset) != null
                  ? Text(_getShaderSubtitle(preset)!, style: const TextStyle(color: Colors.white54, fontSize: 12))
                  : null,
              trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.amber) : null,
              onTap: () async {
                await widget.shaderService!.applyPreset(preset);
                await shaderProvider.setPreset(preset);
                widget.onShaderChanged?.call();
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  String? _getShaderSubtitle(ShaderPreset preset) {
    switch (preset.type) {
      case ShaderPresetType.none:
        return t.shaders.noShaderDescription;
      case ShaderPresetType.nvscaler:
        return t.shaders.nvscalerDescription;
      case ShaderPresetType.anime4k:
        if (preset.anime4kConfig != null) {
          final quality = preset.anime4kConfig!.quality == Anime4KQuality.fast
              ? t.shaders.qualityFast
              : t.shaders.qualityHQ;
          final mode = preset.modeDisplayName;
          return '$quality - ${t.shaders.mode} $mode';
        }
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepTimer = SleepTimerService();
    final isShaderActive = widget.shaderService != null && widget.shaderService!.currentPreset.isEnabled;
    final isIconActive =
        _currentView == _SettingsView.menu &&
        (sleepTimer.isActive || _audioSyncOffset != 0 || _subtitleSyncOffset != 0 || isShaderActive);

    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: BaseVideoControlSheet(
        title: _getTitle(),
        icon: _getIcon(),
        iconColor: isIconActive
            ? Colors.amber
            : (_currentView == _SettingsView.shader && isShaderActive ? Colors.amber : Colors.white),
        onBack: _currentView != _SettingsView.menu ? _navigateBack : null,
        child: () {
          switch (_currentView) {
            case _SettingsView.menu:
              return _buildMenuView();
            case _SettingsView.speed:
              return _buildSpeedView();
            case _SettingsView.sleep:
              return _buildSleepView();
            case _SettingsView.audioSync:
              return _buildAudioSyncView();
            case _SettingsView.subtitleSync:
              return _buildSubtitleSyncView();
            case _SettingsView.audioDevice:
              return _buildAudioDeviceView();
            case _SettingsView.shader:
              return _buildShaderView();
          }
        }(),
      ),
    );
  }
}
