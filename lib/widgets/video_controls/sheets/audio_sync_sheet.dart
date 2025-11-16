import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:plezy/services/settings_service.dart';
import '../../../i18n/strings.g.dart';
import 'base_video_control_sheet.dart';

/// Bottom sheet for adjusting audio sync offset
class AudioSyncSheet extends StatefulWidget {
  final Player player;
  final int initialOffset;

  const AudioSyncSheet({
    super.key,
    required this.player,
    required this.initialOffset,
  });

  static void show(BuildContext context, Player player, int initialOffset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: BaseVideoControlSheet.getBottomSheetConstraints(context),
      builder: (context) =>
          AudioSyncSheet(player: player, initialOffset: initialOffset),
    );
  }

  @override
  State<AudioSyncSheet> createState() => _AudioSyncSheetState();
}

class _AudioSyncSheetState extends State<AudioSyncSheet> {
  late double _currentOffset;

  @override
  void initState() {
    super.initState();
    _currentOffset = widget.initialOffset.toDouble();
  }

  void _applyOffset(double offsetMs) async {
    // Convert milliseconds to seconds for media_kit
    final offsetSeconds = offsetMs / 1000.0;

    // Apply to player using setProperty
    await (widget.player.platform as dynamic).setProperty(
      'audio-delay',
      offsetSeconds.toString(),
    );

    // Save to settings
    final settings = await SettingsService.getInstance();
    await settings.setAudioSyncOffset(offsetMs.round());
  }

  void _resetOffset() {
    setState(() {
      _currentOffset = 0;
    });
    _applyOffset(0);
  }

  String _formatOffset(double offsetMs) {
    final sign = offsetMs >= 0 ? '+' : '';
    return '$sign${offsetMs.round()}ms';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.sync, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Audio Sync',
                    style: TextStyle(
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
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current offset display
                    Text(
                      _formatOffset(_currentOffset),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentOffset > 0
                          ? 'Audio plays later'
                          : _currentOffset < 0
                          ? 'Audio plays earlier'
                          : 'No offset',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Slider
                    Row(
                      children: [
                        Text(
                          t.videoControls.minusTime(amount: "2", unit: "s"),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentOffset,
                            min: -2000,
                            max: 2000,
                            divisions: 80, // 50ms steps
                            activeColor: Colors.blue,
                            inactiveColor: Colors.white24,
                            onChanged: (value) {
                              setState(() {
                                _currentOffset = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _applyOffset(value);
                            },
                          ),
                        ),
                        Text(
                          t.videoControls.addTime(amount: "2", unit: "s"),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Reset button
                    ElevatedButton.icon(
                      onPressed: _currentOffset != 0 ? _resetOffset : null,
                      icon: const Icon(Icons.restart_alt),
                      label: Text(t.videoControls.resetToZero),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[850],
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
