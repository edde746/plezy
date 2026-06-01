import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_wrapper.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/media_source_info.dart';
import '../../../theme/mono_tokens.dart';
import '../../app_icon.dart';

class SkipMarkerButton extends StatefulWidget {
  final MediaMarker marker;
  final Duration playerDuration;
  final bool hasNextEpisode;
  final bool isAutoSkipActive;
  final bool shouldShowAutoSkip;
  final int autoSkipDelay;
  final double autoSkipProgress;
  final FocusNode focusNode;
  final VoidCallback onCancelAutoSkip;
  final VoidCallback onPerformAutoSkip;
  final VoidCallback onFocusDown;

  const SkipMarkerButton({
    super.key,
    required this.marker,
    required this.playerDuration,
    required this.hasNextEpisode,
    required this.isAutoSkipActive,
    required this.shouldShowAutoSkip,
    required this.autoSkipDelay,
    required this.autoSkipProgress,
    required this.focusNode,
    required this.onCancelAutoSkip,
    required this.onPerformAutoSkip,
    required this.onFocusDown,
  });

  @override
  State<SkipMarkerButton> createState() => _SkipMarkerButtonState();
}

class _SkipMarkerButtonState extends State<SkipMarkerButton> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(SkipMarkerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      _isFocused = widget.focusNode.hasFocus;
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final hasFocus = widget.focusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() => _isFocused = hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredits = widget.marker.isCredits;
    final creditsAtEnd =
        isCredits &&
        widget.playerDuration > Duration.zero &&
        (widget.playerDuration - widget.marker.endTime).inMilliseconds <= 1000;
    final showNextEpisode = creditsAtEnd && widget.hasNextEpisode;
    String baseButtonText;
    if (showNextEpisode) {
      baseButtonText = 'Next Episode';
    } else if (isCredits) {
      baseButtonText = 'Skip Credits';
    } else {
      baseButtonText = 'Skip Intro';
    }

    final remainingSeconds = widget.isAutoSkipActive && widget.shouldShowAutoSkip
        ? (widget.autoSkipDelay - (widget.autoSkipProgress * widget.autoSkipDelay)).ceil().clamp(
            0,
            widget.autoSkipDelay,
          )
        : 0;

    final buttonText = widget.isAutoSkipActive && widget.shouldShowAutoSkip && remainingSeconds > 0
        ? '$baseButtonText ($remainingSeconds)'
        : baseButtonText;
    final buttonIcon = showNextEpisode ? Symbols.skip_next_rounded : Symbols.fast_forward_rounded;

    final showFocused = _isFocused && InputModeTracker.isKeyboardMode(context);
    final primary = Theme.of(context).colorScheme.primary;
    final buttonBgColor = showFocused ? primary : Colors.white.withValues(alpha: 0.9);
    final contentColor = showFocused ? Colors.white : Colors.black;

    return FocusableWrapper(
      focusNode: widget.focusNode,
      onSelect: _activate,
      borderRadius: tokens(context).radiusSm,
      useBackgroundFocus: false,
      disableScale: true,
      autoScroll: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onFocusDown();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _activate,
          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: buttonBgColor,
                  borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(color: contentColor, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    AppIcon(buttonIcon, fill: 1, color: contentColor, size: 20),
                  ],
                ),
              ),
              if (widget.isAutoSkipActive && widget.shouldShowAutoSkip)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (widget.autoSkipProgress * 100).round(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: (showFocused ? Colors.white : primary).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((1.0 - widget.autoSkipProgress) * 100).round(),
                          child: Container(decoration: const BoxDecoration(color: Colors.transparent)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _activate() {
    if (widget.isAutoSkipActive) {
      widget.onCancelAutoSkip();
    }
    widget.onPerformAutoSkip();
  }
}
