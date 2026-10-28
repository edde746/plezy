import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_slider.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../mpv/mpv.dart';
import '../../../services/player_sync_offsets.dart';
import '../../../services/scoped_player_prefs.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/latest_async_write.dart';

/// Reusable widget for adjusting sync offsets (audio or subtitle)
class SyncOffsetControl extends StatefulWidget {
  final Player player;
  final String propertyName; // 'audio-delay' or 'sub-delay'
  final int initialOffset;
  final Future<void> Function(int offset) onOffsetChanged;

  /// Focus node for the reset button. When provided from the parent, allows
  /// the close button's left-press to focus the reset button.
  final FocusNode? resetFocusNode;

  /// Focus node for the close button. When provided, pressing select/enter
  /// on the slider moves focus here.
  final FocusNode? closeFocusNode;

  /// Focus node for the slider. When provided, allows the parent to
  /// auto-focus the slider when the bar opens.
  final FocusNode? sliderFocusNode;

  const SyncOffsetControl({
    super.key,
    required this.player,
    required this.propertyName,
    required this.initialOffset,
    required this.onOffsetChanged,
    this.resetFocusNode,
    this.closeFocusNode,
    this.sliderFocusNode,
  });

  @override
  State<SyncOffsetControl> createState() => _SyncOffsetControlState();
}

final Expando<LatestAsyncWrite<String>> _syncOffsetWrites = Expando<LatestAsyncWrite<String>>();

class _SyncOffsetControlState extends State<SyncOffsetControl> {
  // Range constants
  static const double _sliderMin = -10_000; // ±10s slider range for fine control
  static const double _sliderMax = 10_000;
  static const double _absoluteMin = ScopedPlayerPrefs.minimumSyncOffsetMs * 1.0;
  static const double _absoluteMax = ScopedPlayerPrefs.maximumSyncOffsetMs * 1.0;
  // Audio gets 10ms steps, the lip-sync granularity other players offer
  // (#2620); subtitle corrections run to seconds, so they keep 50ms. The
  // slider step is also the D-pad step on TV, where the slider holds focus
  // and owns left/right; long-press keeps a 1s stride for large corrections.
  static const double _longPressStep = 1000;

  double get _step => widget.propertyName == PlayerSyncOffsets.audioProperty ? 10 : 50;
  int get _sliderDivisions => (_sliderMax - _sliderMin) ~/ _step;

  late double _currentOffset;
  late double _confirmedOffset;
  int _writeGeneration = 0;
  int _bindingGeneration = 0;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _currentOffset = widget.initialOffset.toDouble();
    _confirmedOffset = _currentOffset;
  }

  @override
  void didUpdateWidget(SyncOffsetControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOffset != oldWidget.initialOffset ||
        widget.player != oldWidget.player ||
        widget.propertyName != oldWidget.propertyName) {
      ++_writeGeneration;
      ++_bindingGeneration;
      _currentOffset = widget.initialOffset.toDouble();
      _confirmedOffset = _currentOffset;
    }
  }

  @override
  void dispose() {
    ++_writeGeneration;
    ++_bindingGeneration;
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _applyOffset(double offsetMs) {
    final targetPlayer = widget.player;
    final propertyName = widget.propertyName;
    final persistOffset = widget.onOffsetChanged;
    final coordinator = _syncOffsetWrites[targetPlayer] ??= LatestAsyncWrite<String>();
    final writeToken = coordinator.begin(propertyName);
    final generation = ++_writeGeneration;
    final bindingGeneration = _bindingGeneration;
    unawaited(() async {
      try {
        final committed = await coordinator.commitIfLatest(propertyName, writeToken, () async {
          // Convert milliseconds to seconds for mpv. Keep the native write and
          // persistence on the same per-player/property queue so an older
          // native write can never complete after a newer one.
          final offsetSeconds = offsetMs / 1000.0;
          await targetPlayer.setProperty(propertyName, offsetSeconds.toString());
          PlayerSyncOffsets.of(targetPlayer).recordApplied(propertyName, offsetMs.round());
          await persistOffset(offsetMs.round());
          if (mounted &&
              bindingGeneration == _bindingGeneration &&
              targetPlayer == widget.player &&
              propertyName == widget.propertyName) {
            // A write may finish successfully after a newer intent was queued.
            // Keep it as the rollback baseline without replacing the newer
            // optimistic value currently shown by the control.
            _confirmedOffset = offsetMs;
          }
        });
        if (!committed ||
            !mounted ||
            generation != _writeGeneration ||
            targetPlayer != widget.player ||
            propertyName != widget.propertyName) {
          return;
        }
      } catch (error, stackTrace) {
        appLogger.w('Failed to update playback sync offset', error: error, stackTrace: stackTrace);
        if (!mounted ||
            generation != _writeGeneration ||
            targetPlayer != widget.player ||
            propertyName != widget.propertyName) {
          return;
        }
        setState(() {
          _currentOffset = _confirmedOffset;
        });
      }
    }());
  }

  void _resetOffset() {
    setState(() {
      _currentOffset = 0;
    });
    _applyOffset(0);
  }

  void _incrementOffset() {
    final newOffset = (_currentOffset + _step).clamp(_absoluteMin, _absoluteMax);
    setState(() {
      _currentOffset = newOffset;
    });
    _applyOffset(newOffset);
  }

  void _decrementOffset() {
    final newOffset = (_currentOffset - _step).clamp(_absoluteMin, _absoluteMax);
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

  String get _syncTitle => widget.propertyName == PlayerSyncOffsets.subtitleProperty
      ? t.videoSettings.subtitleSync
      : t.videoSettings.audioSync;

  Future<void> _editExactOffset() async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: _currentOffset.round().toString());
    final offset = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          if (!(formKey.currentState?.validate() ?? false)) return;
          Navigator.of(dialogContext).pop(int.parse(controller.text.trim()));
        }

        return AlertDialog(
          title: Text(_syncTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: _syncTitle,
                hintText: formatSyncOffset(_currentOffset),
                helperText: t.validationErrorDuration(
                  min: ScopedPlayerPrefs.minimumSyncOffsetMs,
                  max: ScopedPlayerPrefs.maximumSyncOffsetMs,
                  unit: 'ms',
                ),
                suffixText: 'ms',
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null) return t.validationErrorEnterNumber;
                if (parsed < ScopedPlayerPrefs.minimumSyncOffsetMs ||
                    parsed > ScopedPlayerPrefs.maximumSyncOffsetMs) {
                  return t.validationErrorDuration(
                    min: ScopedPlayerPrefs.minimumSyncOffsetMs,
                    max: ScopedPlayerPrefs.maximumSyncOffsetMs,
                    unit: 'ms',
                  );
                }
                return null;
              },
              onFieldSubmitted: (_) => submit(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.common.cancel),
            ),
            TextButton(onPressed: submit, child: Text(t.common.save)),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || offset == null) return;
    setState(() => _currentOffset = offset.toDouble());
    _applyOffset(offset.toDouble());
  }

  Widget _buildExactOffsetButton() {
    return FocusableWrapper(
      onSelect: _editExactOffset,
      borderRadius: 8,
      autoScroll: false,
      useBackgroundFocus: true,
      child: Semantics(
        button: true,
        label: _syncTitle,
        value: formatSyncOffset(_currentOffset),
        child: GestureDetector(
          onTap: _editExactOffset,
          child: Container(
            width: 80,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              formatSyncOffset(_currentOffset),
              style: TextStyle(
                fontSize: 16,
                fontWeight: .bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepButton({
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: AppIcon(icon, color: tokens(context).text, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = _currentOffset.clamp(_sliderMin, _sliderMax);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStepButton(
            icon: Symbols.remove_rounded,
            onTap: _decrementOffset,
            onLongPressStart: _startLongPressDecrement,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(tickMarkShape: SliderTickMarkShape.noTickMark),
              child: FocusableSlider(
                focusNode: widget.sliderFocusNode,
                value: sliderValue,
                min: _sliderMin,
                max: _sliderMax,
                divisions: _sliderDivisions,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context).colorScheme.outlineVariant,
                onSelect: widget.closeFocusNode?.requestFocus,
                onChanged: (value) => setState(() => _currentOffset = value),
                onChangeEnd: _applyOffset,
              ),
            ),
          ),
          _buildStepButton(
            icon: Symbols.add_rounded,
            onTap: _incrementOffset,
            onLongPressStart: _startLongPressIncrement,
          ),
          const SizedBox(width: 12),
          _buildExactOffsetButton(),
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
                alignment: .center,
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
}
