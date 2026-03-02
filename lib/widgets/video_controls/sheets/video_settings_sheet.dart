import 'dart:io';

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
import '../../../focus/focusable_wrapper.dart';
import '../../../utils/formatters.dart';
import '../../../utils/platform_detector.dart';
import '../../../theme/mono_tokens.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
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

  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.valueText,
    required this.onTap,
    this.isHighlighted = false,
    this.allowValueOverflow = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final valueWidget = Text(
      valueText,
      style: TextStyle(color: isHighlighted ? Colors.amber : t.textMuted, fontSize: 14),
      overflow: allowValueOverflow ? TextOverflow.ellipsis : null,
    );

    return FocusableListTile(
      leading: AppIcon(icon, fill: 1, color: isHighlighted ? Colors.amber : t.textMuted),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allowValueOverflow) Flexible(child: valueWidget) else valueWidget,
          const SizedBox(width: 8),
          AppIcon(Symbols.chevron_right_rounded, fill: 1, color: t.textMuted),
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

  /// Whether this is a live TV stream (hides speed settings).
  final bool isLive;

  /// Optional shader service for MPV shader control
  final ShaderService? shaderService;

  /// Called when shader preset changes
  final VoidCallback? onShaderChanged;

  /// Whether ambient lighting is currently enabled
  final bool isAmbientLightingEnabled;

  /// Called to toggle ambient lighting on/off (null if unsupported)
  final VoidCallback? onToggleAmbientLighting;

  /// Called to cancel the video controls auto-hide timer.
  final VoidCallback? onCancelAutoHide;

  /// Called to restart the video controls auto-hide timer.
  final VoidCallback? onStartAutoHide;

  /// Called when a sync offset changes (so the parent can update its state).
  final void Function(String propertyName, int offset)? onSyncOffsetChanged;

  const VideoSettingsSheet({
    super.key,
    required this.player,
    required this.audioSyncOffset,
    required this.subtitleSyncOffset,
    this.canControl = true,
    this.isLive = false,
    this.shaderService,
    this.onShaderChanged,
    this.isAmbientLightingEnabled = false,
    this.onToggleAmbientLighting,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.onSyncOffsetChanged,
  });

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
  bool _audioPassthrough = false;
  bool _audioNormalization = false;

  @override
  void initState() {
    super.initState();
    _audioSyncOffset = widget.audioSyncOffset;
    _subtitleSyncOffset = widget.subtitleSyncOffset;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      _enableHDR = settings.getEnableHDR();
      _showPerformanceOverlay = settings.getShowPerformanceOverlay();
      _autoPlayNextEpisode = settings.getAutoPlayNextEpisode();
      _audioPassthrough = settings.getAudioPassthrough();
      _audioNormalization = settings.getAudioNormalization();
    });
  }

  Future<void> _toggleHDR() async {
    final newValue = !_enableHDR;
    final settings = await SettingsService.getInstance();
    await settings.setEnableHDR(newValue);
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _showPerformanceOverlay = newValue;
    });
  }

  Future<void> _toggleAutoPlayNextEpisode() async {
    final newValue = !_autoPlayNextEpisode;
    final settings = await SettingsService.getInstance();
    await settings.setAutoPlayNextEpisode(newValue);
    if (!mounted) return;
    setState(() {
      _autoPlayNextEpisode = newValue;
    });
  }

  Future<void> _toggleAudioPassthrough() async {
    final newValue = !_audioPassthrough;
    final settings = await SettingsService.getInstance();
    await settings.setAudioPassthrough(newValue);
    if (!mounted) return;
    setState(() {
      _audioPassthrough = newValue;
    });
    await widget.player.setAudioPassthrough(newValue);
  }

  Future<void> _toggleAudioNormalization() async {
    final newValue = !_audioNormalization;
    final settings = await SettingsService.getInstance();
    await settings.setAudioNormalization(newValue);
    if (!mounted) return;
    setState(() {
      _audioNormalization = newValue;
    });
    await widget.player.setProperty('af', newValue ? 'loudnorm=I=-14:TP=-3:LRA=4' : '');
  }

  void _navigateTo(_SettingsView view) {
    // Sync views open as a compact top bar instead of a sub-view
    if (view == _SettingsView.audioSync || view == _SettingsView.subtitleSync) {
      _openSyncBar(view);
      return;
    }
    setState(() {
      _currentView = view;
    });
    OverlaySheetController.maybeOf(context)?.refocus();
  }

  void _openSyncBar(_SettingsView view) {
    final controller = OverlaySheetController.maybeOf(context);
    if (controller == null) return;

    final isSubtitle = view == _SettingsView.subtitleSync;
    final title = isSubtitle ? t.videoSettings.subtitleSync : t.videoSettings.audioSync;
    final icon = isSubtitle ? Symbols.subtitles_rounded : Symbols.sync_rounded;
    final propertyName = isSubtitle ? 'sub-delay' : 'audio-delay';
    final initialOffset = isSubtitle ? _subtitleSyncOffset : _audioSyncOffset;

    // Created here so we can pass it as initialFocusNode to the overlay sheet,
    // ensuring the slider gets focus when the bar opens. Disposed by _CompactSyncBar.
    final sliderFocusNode = FocusNode(debugLabel: 'SyncSlider');

    // show() with new alignment replaces the current sheet (completing the
    // settings sheet future, which restarts the auto-hide timer via
    // whenComplete in track_chapter_controls). Cancel it again here.
    controller.show(
      alignment: Alignment.topCenter,
      constraints: const BoxConstraints(maxHeight: 80, maxWidth: 900),
      initialFocusNode: sliderFocusNode,
      builder: (_) => _CompactSyncBar(
        title: title,
        icon: icon,
        player: widget.player,
        propertyName: propertyName,
        initialOffset: initialOffset,
        sliderFocusNode: sliderFocusNode,
        onOffsetChanged: (offset) async {
          final settings = await SettingsService.getInstance();
          if (isSubtitle) {
            await settings.setSubtitleSyncOffset(offset);
          } else {
            await settings.setAudioSyncOffset(offset);
          }
          widget.onSyncOffsetChanged?.call(propertyName, offset);
        },
      ),
    ).whenComplete(() {
      widget.onStartAutoHide?.call();
    });

    // Cancel auto-hide after show() — the previous sheet's whenComplete
    // fires as a microtask and restarts the timer, so schedule our cancel
    // to run after that microtask.
    Future.microtask(() => widget.onCancelAutoHide?.call());
  }

  void _navigateBack() {
    setState(() {
      _currentView = _SettingsView.menu;
    });
    OverlaySheetController.maybeOf(context)?.refocus();
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
        // Playback Speed - hidden for live TV and when user cannot control playback
        if (widget.canControl && !widget.isLive)
          StreamBuilder<double>(
            stream: widget.player.streams.rate,
            initialData: widget.player.state.rate,
            builder: (context, snapshot) {
              final currentRate = snapshot.data ?? 1.0;
              return _SettingsMenuItem(
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
              icon: Symbols.bedtime_rounded,
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
        if (Platform.isIOS || Platform.isMacOS || Platform.isWindows)
          ListTile(
            leading: AppIcon(Symbols.hdr_strong_rounded, fill: 1, color: _enableHDR ? Colors.amber : tokens(context).textMuted),
            title: Text(t.videoSettings.hdr),
            trailing: Switch(value: _enableHDR, onChanged: (_) => _toggleHDR(), activeThumbColor: Colors.amber),
            onTap: _toggleHDR,
          ),

        // Auto-Play Next Episode Toggle
        ListTile(
          leading: AppIcon(
            Symbols.skip_next_rounded,
            fill: 1,
            color: _autoPlayNextEpisode ? Colors.amber : tokens(context).textMuted,
          ),
          title: Text(t.videoControls.autoPlayNext),
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
                  : currentDevice.description;

              return _SettingsMenuItem(
                icon: Symbols.speaker_rounded,
                title: t.videoSettings.audioOutput,
                valueText: deviceLabel,
                allowValueOverflow: true,
                onTap: () => _navigateTo(_SettingsView.audioDevice),
              );
            },
          ),

        // Audio Passthrough (Desktop only)
        if (isDesktop)
          ListTile(
            leading: AppIcon(
              Symbols.surround_sound_rounded,
              fill: 1,
              color: _audioPassthrough ? Colors.amber : tokens(context).textMuted,
            ),
            title: Text(t.videoSettings.audioPassthrough),
            trailing: Switch(
              value: _audioPassthrough,
              onChanged: (_) => _toggleAudioPassthrough(),
              activeThumbColor: Colors.amber,
            ),
            onTap: _toggleAudioPassthrough,
          ),

        // Audio Normalization (MPV only)
        if (widget.player.playerType == 'mpv')
          ListTile(
            leading: AppIcon(
              Symbols.graphic_eq_rounded,
              fill: 1,
              color: _audioNormalization ? Colors.amber : tokens(context).textMuted,
            ),
            title: Text(t.videoSettings.audioNormalization),
            trailing: Switch(
              value: _audioNormalization,
              onChanged: (_) => _toggleAudioNormalization(),
              activeThumbColor: Colors.amber,
            ),
            onTap: _toggleAudioNormalization,
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

        // Ambient Lighting (MPV only)
        if (widget.onToggleAmbientLighting != null)
          ListTile(
            leading: AppIcon(
              Symbols.blur_on,
              fill: 1,
              color: widget.isAmbientLightingEnabled ? Colors.amber : tokens(context).textMuted,
            ),
            title: Text(t.videoControls.ambientLighting),
            trailing: Switch(
              value: widget.isAmbientLightingEnabled,
              onChanged: (_) {
                widget.onToggleAmbientLighting?.call();
                OverlaySheetController.of(context).close();
              },
              activeThumbColor: Colors.amber,
            ),
            onTap: () {
              widget.onToggleAmbientLighting?.call();
              OverlaySheetController.of(context).close();
            },
          ),

        // Performance Overlay Toggle
        ListTile(
          leading: AppIcon(
            Symbols.analytics_rounded,
            fill: 1,
            color: _showPerformanceOverlay ? Colors.amber : tokens(context).textMuted,
          ),
          title: Text(t.videoSettings.performanceOverlay),
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
              title: Text(label, style: TextStyle(color: isSelected ? Colors.blue : null)),
              trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.blue) : null,
              onTap: () async {
                widget.player.setRate(speed);
                // Save as default playback speed
                final settings = await SettingsService.getInstance();
                await settings.setDefaultPlaybackSpeed(speed);
                if (context.mounted) {
                  OverlaySheetController.of(context).close(); // Close sheet after selection
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

    return SleepTimerContent(player: widget.player, sleepTimer: sleepTimer, onCancel: () => OverlaySheetController.of(context).close());
  }

  // Audio/subtitle sync views are now opened as compact top bars via _openSyncBar()

  /// Extract the audio backend name from a device name (e.g. "coreaudio" from "coreaudio/BuiltIn").
  static String _audioBackend(String name) {
    final slash = name.indexOf('/');
    return slash > 0 ? name.substring(0, slash) : name;
  }

  /// Pretty-print a backend identifier.
  static String _formatBackend(String backend) {
    const labels = {
      'coreaudio': 'CoreAudio',
      'avfoundation': 'AVFoundation',
      'wasapi': 'WASAPI',
      'pulse': 'PulseAudio',
      'pipewire': 'PipeWire',
      'alsa': 'ALSA',
      'jack': 'JACK',
      'oss': 'OSS',
    };
    return labels[backend] ?? backend;
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

            // Check for duplicate descriptions (same physical device across multiple backends).
            final descCounts = <String, int>{};
            for (final d in devices) {
              final desc = d.description.isEmpty ? d.name : d.description;
              descCounts[desc] = (descCounts[desc] ?? 0) + 1;
            }
            final hasDuplicates = descCounts.values.any((c) => c > 1);

            if (!hasDuplicates) {
              return _buildFlatDeviceList(devices, currentDevice);
            }

            // Group devices by backend, keeping "auto" at the top ungrouped.
            final ungrouped = <AudioDevice>[];
            final groups = <String, List<AudioDevice>>{};
            for (final d in devices) {
              final backend = _audioBackend(d.name);
              if (!d.name.contains('/')) {
                ungrouped.add(d);
              } else {
                (groups[backend] ??= []).add(d);
              }
            }

            return ListView(
              children: [
                for (final d in ungrouped) _buildDeviceTile(d, currentDevice),
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      _formatBackend(entry.key),
                      style: TextStyle(color: tokens(context).textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  for (final d in entry.value) _buildDeviceTile(d, currentDevice),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFlatDeviceList(List<AudioDevice> devices, AudioDevice currentDevice) {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) => _buildDeviceTile(devices[index], currentDevice),
    );
  }

  Widget _buildDeviceTile(AudioDevice device, AudioDevice currentDevice) {
    final isSelected = device.name == currentDevice.name;
    final label = device.description.isEmpty ? device.name : device.description;

    return ListTile(
      title: Text(label, style: TextStyle(color: isSelected ? Colors.blue : null)),
      trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.blue) : null,
      onTap: () {
        widget.player.setAudioDevice(device);
        OverlaySheetController.of(context).close();
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
              title: Text(preset.name, style: TextStyle(color: isSelected ? Colors.amber : null)),
              subtitle: _getShaderSubtitle(preset) != null
                  ? Text(_getShaderSubtitle(preset)!, style: TextStyle(color: tokens(context).textMuted, fontSize: 12))
                  : null,
              trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.amber) : null,
              onTap: () async {
                // Disable ambient lighting when selecting a shader
                if (preset.type != ShaderPresetType.none && widget.isAmbientLightingEnabled) {
                  widget.onToggleAmbientLighting?.call();
                }
                await widget.shaderService!.applyPreset(preset);
                await shaderProvider.setPreset(preset);
                widget.onShaderChanged?.call();
                if (context.mounted) OverlaySheetController.of(context).close();
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

    return BaseVideoControlSheet(
      title: _getTitle(),
      icon: _getIcon(),
      iconColor: () {
        if (isIconActive) return Colors.amber;
        if (_currentView == _SettingsView.shader && isShaderActive) return Colors.amber;
        return null;
      }(),
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
          case _SettingsView.subtitleSync:
            return _buildMenuView(); // Sync views open as top bars, fallback to menu
          case _SettingsView.audioDevice:
            return _buildAudioDeviceView();
          case _SettingsView.shader:
            return _buildShaderView();
        }
      }(),
    );
  }
}

/// Compact sync bar shown at the top of the screen so subtitles remain visible.
class _CompactSyncBar extends StatefulWidget {
  final String title;
  final IconData icon;
  final Player player;
  final String propertyName;
  final int initialOffset;
  final Future<void> Function(int offset) onOffsetChanged;
  final FocusNode sliderFocusNode;

  const _CompactSyncBar({
    required this.title,
    required this.icon,
    required this.player,
    required this.propertyName,
    required this.initialOffset,
    required this.onOffsetChanged,
    required this.sliderFocusNode,
  });

  @override
  State<_CompactSyncBar> createState() => _CompactSyncBarState();
}

class _CompactSyncBarState extends State<_CompactSyncBar> {
  final _resetFocusNode = FocusNode(debugLabel: 'SyncResetButton');
  final _closeFocusNode = FocusNode(debugLabel: 'SyncCloseButton');

  @override
  void dispose() {
    widget.sliderFocusNode.dispose();
    _resetFocusNode.dispose();
    _closeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        AppIcon(widget.icon, fill: 1, color: tokens(context).textMuted, size: 20),
        const SizedBox(width: 8),
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Expanded(
          child: SyncOffsetControl(
            player: widget.player,
            propertyName: widget.propertyName,
            initialOffset: widget.initialOffset,
            labelText: widget.title,
            onOffsetChanged: widget.onOffsetChanged,
            compact: true,
            sliderFocusNode: widget.sliderFocusNode,
            resetFocusNode: _resetFocusNode,
            closeFocusNode: _closeFocusNode,
          ),
        ),
        const SizedBox(width: 8),
        FocusableWrapper(
          focusNode: _closeFocusNode,
          onSelect: () => OverlaySheetController.of(context).close(),
          onNavigateLeft: () => _resetFocusNode.requestFocus(),
          borderRadius: 18,
          autoScroll: false,
          useBackgroundFocus: true,
          child: GestureDetector(
            onTap: () => OverlaySheetController.of(context).close(),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: AppIcon(Symbols.close_rounded, fill: 1, color: tokens(context).textMuted, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
