import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../focus/focusable_wrapper.dart';
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

  /// When true, renders as a compact single-row layout for use in a top bar.
  final bool compact;

  /// Focus node for the reset button (compact mode). When provided from the
  /// parent, allows the close button's left-press to focus the reset button.
  final FocusNode? resetFocusNode;

  /// Focus node for the close button (compact mode). When provided, pressing
  /// select/enter on the slider moves focus here.
  final FocusNode? closeFocusNode;

  /// Focus node for the slider (compact mode). When provided, allows the
  /// parent to auto-focus the slider when the bar opens.
  final FocusNode? sliderFocusNode;

  const SyncOffsetControl({
    super.key,
    required this.player,
    required this.propertyName,
    required this.initialOffset,
    required this.labelText,
    required this.onOffsetChanged,
    this.compact = false,
    this.resetFocusNode,
    this.closeFocusNode,
    this.sliderFocusNode,
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
    double size = 48,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => _stopLongPress(),
      onLongPressCancel: _stopLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: Icon(icon, color: tokens(context).text, size: iconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildCompactStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
  }) {
    return FocusableWrapper(
      onSelect: onTap,
      borderRadius: 18,
      autoScroll: false,
      useBackgroundFocus: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => _stopLongPress(),
        onLongPressCancel: _stopLongPress,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.all(Radius.circular(8))),
          child: Icon(icon, color: tokens(context).text, size: 22),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final sliderValue = _currentOffset.clamp(_sliderMin, _sliderMax);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildCompactStepButton(
            icon: Symbols.remove_rounded,
            onTap: _decrementOffset,
            onLongPressStart: _startLongPressDecrement,
          ),
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                // Select/enter on the slider jumps focus to the close button
                if (event.logicalKey.isSelectKey && event is KeyDownEvent) {
                  widget.closeFocusNode?.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              canRequestFocus: false,
              child: Slider(
                focusNode: widget.sliderFocusNode,
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
          ),
          _buildCompactStepButton(
            icon: Symbols.add_rounded,
            onTap: _incrementOffset,
            onLongPressStart: _startLongPressIncrement,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              formatSyncOffset(_currentOffset),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          FocusableWrapper(
            focusNode: widget.resetFocusNode,
            onSelect: _currentOffset != 0 ? _resetOffset : null,
            borderRadius: 18,
            autoScroll: false,
            useBackgroundFocus: true,
            child: GestureDetector(
              onTap: _currentOffset != 0 ? _resetOffset : null,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: AppIcon(
                  Symbols.restart_alt_rounded,
                  fill: 1,
                  color: _currentOffset != 0 ? tokens(context).text : tokens(context).textMuted,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
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
