import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../services/settings_service.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/platform_detector.dart';
import '../widgets/sync_offset_control.dart';
import '../widgets/sleep_timer_content.dart';
import '../../../i18n/strings.g.dart';

enum _SettingsView { menu, speed, sleep, audioSync, subtitleSync, audioDevice }

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
    final valueWidget = Text(
      valueText,
      style: TextStyle(
        color: isHighlighted ? Colors.amber : Colors.white70,
        fontSize: 14,
      ),
      overflow: allowValueOverflow ? TextOverflow.ellipsis : null,
    );

    return ListTile(
      leading: Icon(
        icon,
        color: isHighlighted ? Colors.amber : Colors.white70,
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allowValueOverflow)
            Flexible(child: valueWidget)
          else
            valueWidget,
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white70),
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

  const VideoSettingsSheet({
    super.key,
    required this.player,
    required this.audioSyncOffset,
    required this.subtitleSyncOffset,
  });

  static BoxConstraints getBottomSheetConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  static Future<void> show(
    BuildContext context,
    Player player,
    int audioSyncOffset,
    int subtitleSyncOffset,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
      builder: (context) => VideoSettingsSheet(
        player: player,
        audioSyncOffset: audioSyncOffset,
        subtitleSyncOffset: subtitleSyncOffset,
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

  @override
  void initState() {
    super.initState();
    _audioSyncOffset = widget.audioSyncOffset;
    _subtitleSyncOffset = widget.subtitleSyncOffset;
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
        return 'Playback Settings';
      case _SettingsView.speed:
        return 'Playback Speed';
      case _SettingsView.sleep:
        return 'Sleep Timer';
      case _SettingsView.audioSync:
        return 'Audio Sync';
      case _SettingsView.subtitleSync:
        return 'Subtitle Sync';
      case _SettingsView.audioDevice:
        return 'Audio Output';
    }
  }

  IconData _getIcon() {
    switch (_currentView) {
      case _SettingsView.menu:
        return Icons.tune;
      case _SettingsView.speed:
        return Icons.speed;
      case _SettingsView.sleep:
        return Icons.bedtime;
      case _SettingsView.audioSync:
        return Icons.sync;
      case _SettingsView.subtitleSync:
        return Icons.subtitles;
      case _SettingsView.audioDevice:
        return Icons.speaker;
    }
  }

  String _formatSpeed(double speed) {
    if (speed == 1.0) return 'Normal';
    return '${speed.toStringAsFixed(2)}x';
  }

  String _formatAudioSync(int offsetMs) {
    if (offsetMs == 0) return '0ms';
    final sign = offsetMs >= 0 ? '+' : '';
    return '$sign${offsetMs}ms';
  }

  String _formatSleepTimer(SleepTimerService sleepTimer) {
    if (!sleepTimer.isActive) return 'Off';
    final remaining = sleepTimer.remainingTime;
    if (remaining == null) return 'Off';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);

    if (minutes > 0) {
      return 'Active (${minutes}m ${seconds}s)';
    } else {
      return 'Active (${seconds}s)';
    }
  }


  Widget _buildHeader() {
    final sleepTimer = SleepTimerService();
    final isIconActive =
        _currentView == _SettingsView.menu &&
        (sleepTimer.isActive ||
            _audioSyncOffset != 0 ||
            _subtitleSyncOffset != 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button or icon
          if (_currentView != _SettingsView.menu)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _navigateBack,
            )
          else
            Icon(_getIcon(), color: isIconActive ? Colors.amber : Colors.white),
          const SizedBox(width: 12),
          Text(
            _getTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuView() {
    final sleepTimer = SleepTimerService();
    final isDesktop = PlatformDetector.isDesktop(context);

    return ListView(
      children: [
        // Playback Speed
        StreamBuilder<double>(
          stream: widget.player.stream.rate,
          initialData: widget.player.state.rate,
          builder: (context, snapshot) {
            final currentRate = snapshot.data ?? 1.0;
            return _SettingsMenuItem(
              icon: Icons.speed,
              title: 'Playback Speed',
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
              icon: isActive ? Icons.bedtime : Icons.bedtime_outlined,
              title: 'Sleep Timer',
              valueText: _formatSleepTimer(sleepTimer),
              isHighlighted: isActive,
              onTap: () => _navigateTo(_SettingsView.sleep),
            );
          },
        ),

        // Audio Sync
        _SettingsMenuItem(
          icon: Icons.sync,
          title: 'Audio Sync',
          valueText: _formatAudioSync(_audioSyncOffset),
          isHighlighted: _audioSyncOffset != 0,
          onTap: () => _navigateTo(_SettingsView.audioSync),
        ),

        // Subtitle Sync
        _SettingsMenuItem(
          icon: Icons.subtitles,
          title: 'Subtitle Sync',
          valueText: _formatAudioSync(_subtitleSyncOffset),
          isHighlighted: _subtitleSyncOffset != 0,
          onTap: () => _navigateTo(_SettingsView.subtitleSync),
        ),

        // Audio Output Device (Desktop only)
        if (isDesktop)
          StreamBuilder<AudioDevice>(
            stream: widget.player.stream.audioDevice,
            initialData: widget.player.state.audioDevice,
            builder: (context, snapshot) {
              final currentDevice =
                  snapshot.data ?? widget.player.state.audioDevice;
              final deviceLabel = currentDevice.description.isEmpty
                  ? currentDevice.name
                  : currentDevice.description;

              return _SettingsMenuItem(
                icon: Icons.speaker,
                title: 'Audio Output',
                valueText: deviceLabel,
                allowValueOverflow: true,
                onTap: () => _navigateTo(_SettingsView.audioDevice),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSpeedView() {
    return StreamBuilder<double>(
      stream: widget.player.stream.rate,
      initialData: widget.player.state.rate,
      builder: (context, snapshot) {
        final currentRate = snapshot.data ?? 1.0;
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0];

        return ListView.builder(
          itemCount: speeds.length,
          itemBuilder: (context, index) {
            final speed = speeds[index];
            final isSelected = (currentRate - speed).abs() < 0.01;
            final label = speed == 1.0
                ? 'Normal'
                : '${speed.toStringAsFixed(2)}x';

            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                widget.player.setRate(speed);
                Navigator.pop(context); // Close sheet after selection
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSleepView() {
    final sleepTimer = SleepTimerService();

    return SleepTimerContent(
      player: widget.player,
      sleepTimer: sleepTimer,
      onCancel: () => Navigator.pop(context),
    );
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
      stream: widget.player.stream.audioDevices,
      initialData: widget.player.state.audioDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        return StreamBuilder<AudioDevice>(
          stream: widget.player.stream.audioDevice,
          initialData: widget.player.state.audioDevice,
          builder: (context, selectedSnapshot) {
            final currentDevice =
                selectedSnapshot.data ?? widget.player.state.audioDevice;

            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelected = device.name == currentDevice.name;
                final label = device.description.isEmpty
                    ? device.name
                    : device.description;

                return ListTile(
                  title: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.white,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
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
                }
              }(),
            ),
          ],
        ),
      ),
    );
  }
}
