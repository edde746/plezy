import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_wrapper.dart';
import '../../../media/media_source_info.dart';
import '../../../theme/mono_tokens.dart';
import '../../app_icon.dart';

class SkipMarkerButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isCredits = marker.isCredits;
    final creditsAtEnd =
        isCredits && playerDuration > Duration.zero && (playerDuration - marker.endTime).inMilliseconds <= 1000;
    final showNextEpisode = creditsAtEnd && hasNextEpisode;
    String baseButtonText;
    if (showNextEpisode) {
      baseButtonText = 'Next Episode';
    } else if (isCredits) {
      baseButtonText = 'Skip Credits';
    } else {
      baseButtonText = 'Skip Intro';
    }

    final remainingSeconds = isAutoSkipActive && shouldShowAutoSkip
        ? (autoSkipDelay - (autoSkipProgress * autoSkipDelay)).ceil().clamp(0, autoSkipDelay)
        : 0;

    final buttonText = isAutoSkipActive && shouldShowAutoSkip && remainingSeconds > 0
        ? '$baseButtonText ($remainingSeconds)'
        : baseButtonText;
    final buttonIcon = showNextEpisode ? Symbols.skip_next_rounded : Symbols.fast_forward_rounded;

    return FocusableWrapper(
      focusNode: focusNode,
      onSelect: _activate,
      borderRadius: tokens(context).radiusSm,
      useBackgroundFocus: true,
      autoScroll: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
          onFocusDown();
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
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
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    AppIcon(buttonIcon, fill: 1, color: Colors.black, size: 20),
                  ],
                ),
              ),
              if (isAutoSkipActive && shouldShowAutoSkip)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (autoSkipProgress * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((1.0 - autoSkipProgress) * 100).round(),
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
    if (isAutoSkipActive) {
      onCancelAutoSkip();
    }
    onPerformAutoSkip();
  }
}
