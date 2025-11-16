import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../i18n/strings.g.dart';

/// Reusable widget for adjusting sync offsets (audio or subtitle)
class SyncOffsetControl extends StatefulWidget {
  final Player player;
  final String propertyName; // 'audio-delay' or 'sub-delay'
  final int initialOffset;
  final String labelText; // 'Audio' or 'Subtitles'
  final Future<void> Function(int offset) onOffsetChanged;

  const SyncOffsetControl({
    super.key,
    required this.player,
    required this.propertyName,
    required this.initialOffset,
    required this.labelText,
    required this.onOffsetChanged,
  });

  @override
  State<SyncOffsetControl> createState() => _SyncOffsetControlState();
}

class _SyncOffsetControlState extends State<SyncOffsetControl> {
  late double _currentOffset;

  @override
  void initState() {
    super.initState();
    _currentOffset = widget.initialOffset.toDouble();
  }

  @override
  void didUpdateWidget(SyncOffsetControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOffset != oldWidget.initialOffset) {
      setState(() {
        _currentOffset = widget.initialOffset.toDouble();
      });
    }
  }

  Future<void> _applyOffset(double offsetMs) async {
    // Convert milliseconds to seconds for media_kit
    final offsetSeconds = offsetMs / 1000.0;

    // Apply to player using setProperty
    await (widget.player.platform as dynamic).setProperty(
      widget.propertyName,
      offsetSeconds.toString(),
    );

    // Notify parent and save to settings
    await widget.onOffsetChanged(offsetMs.round());
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

  String _getDescriptionText() {
    if (_currentOffset > 0) {
      return t.videoControls.playsLater(label: widget.labelText);
    } else if (_currentOffset < 0) {
      return t.videoControls.playsEarlier(label: widget.labelText);
    } else {
      return t.videoControls.noOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            _getDescriptionText(),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
