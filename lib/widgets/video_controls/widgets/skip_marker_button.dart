import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/card_focus_scope.dart';
import '../../../focus/focus_theme.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_source_info.dart';
import '../../../theme/mono_tokens.dart';
import '../../app_icon.dart';
import 'player_focus_disc.dart';

class SkipMarkerButton extends StatelessWidget {
  final MediaMarker marker;
  final Duration playerDuration;
  final bool hasNextEpisode;
  final bool isAutoSkipActive;
  final bool shouldShowAutoSkip;
  final int autoSkipDelay;
  final double autoSkipProgress;
  final FocusNode focusNode;
  final VoidCallback onActivate;
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
    required this.onActivate,
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
      baseButtonText = t.videoControls.nextEpisode;
    } else if (isCredits) {
      baseButtonText = t.videoControls.skipCredits;
    } else {
      baseButtonText = t.videoControls.skipIntro;
    }

    final remainingSeconds = isAutoSkipActive && shouldShowAutoSkip
        ? (autoSkipDelay - (autoSkipProgress * autoSkipDelay)).ceil().clamp(0, autoSkipDelay)
        : 0;

    final showAutoSkipCountdown = isAutoSkipActive && shouldShowAutoSkip;
    final buttonText = showAutoSkipCountdown && remainingSeconds > 0
        ? '$baseButtonText ($remainingSeconds)'
        : baseButtonText;
    final buttonIcon = showNextEpisode ? Symbols.skip_next_rounded : Symbols.fast_forward_rounded;
    final radius = tokens(context).radiusSm;

    return FocusableWrapper(
      focusNode: focusNode,
      onSelect: _activate,
      borderRadius: radius,
      // The button paints its own focus state: a translucent fill behind an
      // already-white pill was invisible, so D-pad users could not tell the
      // button from the timeline or the transport row as the selection.
      delegateFocusBorder: true,
      focusScale: _focusScale,
      autoScroll: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
          onFocusDown();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          // Null outside keyboard/D-pad mode: pointer users keep the solid
          // white pill. In D-pad mode the pill is solid white with a ring only
          // while focused, and a dark outlined pill otherwise.
          final keyboardFocus = CardFocusScope.maybeOf(context);
          final isDpad = keyboardFocus != null;
          final isFocused = keyboardFocus ?? false;
          final isSolid = !isDpad || isFocused;
          final foreground = isSolid ? Colors.black : Colors.white;
          final duration = FocusTheme.getAnimationDuration(context);

          return AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(_ringGap),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius + _ringGap + _ringWidth),
              border: Border.all(
                color: isFocused ? Colors.white : Colors.transparent,
                width: _ringWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: _buildPill(
              context,
              radius: radius,
              duration: duration,
              isSolid: isSolid,
              isFocused: isFocused,
              foreground: foreground,
              buttonText: buttonText,
              buttonIcon: buttonIcon,
            ),
          );
        },
      ),
    );
  }

  static const double _focusScale = 1.08;
  static const double _ringWidth = 3;
  static const double _ringGap = 3;

  Widget _buildPill(
    BuildContext context, {
    required double radius,
    required Duration duration,
    required bool isSolid,
    required bool isFocused,
    required Color foreground,
    required String buttonText,
    required IconData buttonIcon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _activate,
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSolid ? Colors.white : Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isSolid ? Colors.transparent : Colors.white.withValues(alpha: 0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  isFocused
                      ? playerFocusShadow
                      : BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                ],
              ),
              child: Row(
                mainAxisSize: .min,
                children: [
                  Text(
                    buttonText,
                    style: TextStyle(color: foreground, fontSize: 16, fontWeight: .w600),
                  ),
                  const SizedBox(width: 8),
                  AppIcon(buttonIcon, fill: 1, color: foreground, size: 20),
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
    );
  }

  void _activate() => onActivate();
}
