import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/formatters.dart';

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
  // Range constants
  static const double _sliderMin = -5000; // ±5s for slider
  static const double _sliderMax = 5000;
  static const double _absoluteMin = -60000; // ±60s absolute limit
  static const double _absoluteMax = 60000;
  static const double _tapStep = 100; // 100ms per tap
  static const double _longPressStep = 1000; // 1s per long-press tick
  static const int _sliderDivisions = 200; // 50ms steps for ±5s range

  late double _currentOffset;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _currentOffset = widget.initialOffset.toDouble();
  }

  @override
  void didUpdateWidget(SyncOffsetControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOffset != oldWidget.initialOffset) {
      _currentOffset = widget.initialOffset.toDouble();
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _applyOffset(double offsetMs) async {
    // Convert milliseconds to seconds for mpv
    final offsetSeconds = offsetMs / 1000.0;

    // Apply to player using setProperty
    await widget.player.setProperty(widget.propertyName, offsetSeconds.toString());

    // Notify parent and save to settings
    await widget.onOffsetChanged(offsetMs.round());
  }

  void _resetOffset() {
    setState(() {
      _currentOffset = 0;
    });
    _applyOffset(0);
  }

  void _incrementOffset() {
    final newOffset = (_currentOffset + _tapStep).clamp(_absoluteMin, _absoluteMax);
    setState(() {
      _currentOffset = newOffset;
    });
    _applyOffset(newOffset);
  }

  void _decrementOffset() {
    final newOffset = (_currentOffset - _tapStep).clamp(_absoluteMin, _absoluteMax);
    setState(() {
      _currentOffset = newOffset;
    });
    _applyOffset(newOffset);
  }

  void _startLongPressIncrement() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final newOffset = (_currentOffset + _longPressStep).clamp(_absoluteMin, _absoluteMax);
      setState(() {
        _currentOffset = newOffset;
      });
      _applyOffset(newOffset);
    });
  }

  void _startLongPressDecrement() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final newOffset = (_currentOffset - _longPressStep).clamp(_absoluteMin, _absoluteMax);
      setState(() {
        _currentOffset = newOffset;
      });
      _applyOffset(newOffset);
    });
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
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

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => _stopLongPress(),
      onLongPressCancel: _stopLongPress,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: Icon(icon, color: tokens(context).text, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clamp the slider value to its range, but display the actual offset
    final sliderValue = _currentOffset.clamp(_sliderMin, _sliderMax);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current offset display
          Text(
            formatSyncOffset(_currentOffset),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_getDescriptionText(), style: TextStyle(color: tokens(context).textMuted, fontSize: 16)),
          const SizedBox(height: 48),
          // Slider with +/- buttons
          Row(
            children: [
              // Decrement button
              _buildStepButton(
                icon: Symbols.remove_rounded,
                onTap: _decrementOffset,
                onLongPressStart: _startLongPressDecrement,
              ),
              const SizedBox(width: 12),
              // Slider section
              Text(
                t.videoControls.minusTime(amount: "5", unit: "s"),
                style: TextStyle(color: tokens(context).textMuted),
              ),
              Expanded(
                child: Slider(
                  value: sliderValue,
                  min: _sliderMin,
                  max: _sliderMax,
                  divisions: _sliderDivisions,
                  activeColor: Colors.blue,
                  inactiveColor: Theme.of(context).colorScheme.outlineVariant,
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
                t.videoControls.addTime(amount: "5", unit: "s"),
                style: TextStyle(color: tokens(context).textMuted),
              ),
              const SizedBox(width: 12),
              // Increment button
              _buildStepButton(
                icon: Symbols.add_rounded,
                onTap: _incrementOffset,
                onLongPressStart: _startLongPressIncrement,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Reset button
          ElevatedButton.icon(
            onPressed: _currentOffset != 0 ? _resetOffset : null,
            icon: const AppIcon(Symbols.restart_alt_rounded, fill: 1),
            label: Text(t.videoControls.resetToZero),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
