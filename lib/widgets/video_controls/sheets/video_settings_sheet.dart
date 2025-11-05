import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../services/settings_service.dart';
import '../../../services/sleep_timer_service.dart';

enum _SettingsView { menu, speed, sleep, audioSync }

/// Unified settings sheet for playback adjustments with in-sheet navigation
class VideoSettingsSheet extends StatefulWidget {
  final Player player;
  final int audioSyncOffset;

  const VideoSettingsSheet({
    super.key,
    required this.player,
    required this.audioSyncOffset,
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

  static void show(BuildContext context, Player player, int audioSyncOffset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
      builder: (context) =>
          VideoSettingsSheet(player: player, audioSyncOffset: audioSyncOffset),
    );
  }

  @override
  State<VideoSettingsSheet> createState() => _VideoSettingsSheetState();
}

class _VideoSettingsSheetState extends State<VideoSettingsSheet> {
  _SettingsView _currentView = _SettingsView.menu;
  late int _audioSyncOffset;
  late double _currentAudioOffset;

  @override
  void initState() {
    super.initState();
    _audioSyncOffset = widget.audioSyncOffset;
    _currentAudioOffset = widget.audioSyncOffset.toDouble();
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

  String _formatSleepTimerDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Widget _buildHeader() {
    final sleepTimer = SleepTimerService();
    final isIconActive =
        _currentView == _SettingsView.menu &&
        (sleepTimer.isActive || _audioSyncOffset != 0);

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

    return ListView(
      children: [
        // Playback Speed
        StreamBuilder<double>(
          stream: widget.player.stream.rate,
          initialData: widget.player.state.rate,
          builder: (context, snapshot) {
            final currentRate = snapshot.data ?? 1.0;
            return ListTile(
              leading: const Icon(Icons.speed, color: Colors.white70),
              title: const Text(
                'Playback Speed',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatSpeed(currentRate),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              onTap: () => _navigateTo(_SettingsView.speed),
            );
          },
        ),

        // Sleep Timer
        ListenableBuilder(
          listenable: sleepTimer,
          builder: (context, _) {
            final isActive = sleepTimer.isActive;
            return ListTile(
              leading: Icon(
                isActive ? Icons.bedtime : Icons.bedtime_outlined,
                color: isActive ? Colors.amber : Colors.white70,
              ),
              title: const Text(
                'Sleep Timer',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatSleepTimer(sleepTimer),
                    style: TextStyle(
                      color: isActive ? Colors.amber : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              onTap: () => _navigateTo(_SettingsView.sleep),
            );
          },
        ),

        // Audio Sync
        ListTile(
          leading: Icon(
            Icons.sync,
            color: _audioSyncOffset != 0 ? Colors.amber : Colors.white70,
          ),
          title: const Text(
            'Audio Sync',
            style: TextStyle(color: Colors.white),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatAudioSync(_audioSyncOffset),
                style: TextStyle(
                  color: _audioSyncOffset != 0 ? Colors.amber : Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
          onTap: () => _navigateTo(_SettingsView.audioSync),
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

    return ListenableBuilder(
      listenable: sleepTimer,
      builder: (context, _) {
        final durations = [5, 10, 15, 30, 45, 60, 90, 120];
        final remainingTime = sleepTimer.remainingTime;

        return Column(
          children: [
            // Active timer status
            if (sleepTimer.isActive && remainingTime != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    const Text(
                      'Timer Active',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Playback will pause in ${_formatSleepTimerDuration(remainingTime)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('+15 min'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          onPressed: () {
                            sleepTimer.extendTimer(const Duration(minutes: 15));
                          },
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            sleepTimer.cancelTimer();
                            Navigator.pop(context); // Close after cancel
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
            ],

            // Duration list
            Expanded(
              child: ListView.builder(
                itemCount: durations.length,
                itemBuilder: (context, index) {
                  final minutes = durations[index];
                  final label = minutes < 60
                      ? '$minutes minutes'
                      : '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} ${minutes == 60 ? 'hour' : 'hours'}';

                  return ListTile(
                    leading: const Icon(Icons.timer, color: Colors.white70),
                    title: Text(
                      label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      sleepTimer.startTimer(Duration(minutes: minutes), () {
                        widget.player.pause();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sleep timer completed - playback paused',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                      Navigator.pop(context); // Close after selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sleep timer set for $label'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioSyncView() {
    void applyOffset(double offsetMs) async {
      final offsetSeconds = offsetMs / 1000.0;
      await (widget.player.platform as dynamic).setProperty(
        'audio-delay',
        offsetSeconds.toString(),
      );

      final settings = await SettingsService.getInstance();
      await settings.setAudioSyncOffset(offsetMs.round());

      setState(() {
        _audioSyncOffset = offsetMs.round();
      });
    }

    void resetOffset() {
      setState(() {
        _currentAudioOffset = 0;
      });
      applyOffset(0);
    }

    String formatOffset(double offsetMs) {
      final sign = offsetMs >= 0 ? '+' : '';
      return '$sign${offsetMs.round()}ms';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current offset display
          Text(
            formatOffset(_currentAudioOffset),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentAudioOffset > 0
                ? 'Audio plays later'
                : _currentAudioOffset < 0
                ? 'Audio plays earlier'
                : 'No offset',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          // Slider
          Row(
            children: [
              const Text('-2s', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _currentAudioOffset,
                  min: -2000,
                  max: 2000,
                  divisions: 80,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _currentAudioOffset = value;
                    });
                  },
                  onChangeEnd: (value) {
                    applyOffset(value);
                  },
                ),
              ),
              const Text('+2s', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 24),
          // Reset button
          ElevatedButton.icon(
            onPressed: _currentAudioOffset != 0 ? resetOffset : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to 0ms'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[850],
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
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
                }
              }(),
            ),
          ],
        ),
      ),
    );
  }
}
