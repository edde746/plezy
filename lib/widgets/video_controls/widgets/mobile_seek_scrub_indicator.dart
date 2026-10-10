import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../../../utils/formatters.dart';

/// Transient feedback for the horizontal swipe-to-seek gesture.
///
/// Deliberately a centred pill rather than a timeline: the whole point of the
/// gesture is reaching a moment without raising the chrome, so the readout has
/// to carry the target, the size of the jump, and the direction on its own.
class MobileSeekScrubIndicator extends StatelessWidget {
  const MobileSeekScrubIndicator({super.key, required this.target, required this.delta, required this.forward});

  /// Where the seek will land if the finger lifts now.
  final Duration target;

  /// Signed distance from where the gesture started.
  final Duration delta;

  final bool forward;

  @override
  Widget build(BuildContext context) {
    final icon = forward ? Symbols.fast_forward_rounded : Symbols.fast_rewind_rounded;
    final sign = layoutDirectionSign(context) * (forward ? 1 : -1);
    final magnitude = delta.abs();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            Row(
              mainAxisSize: .min,
              children: [
                AppIcon(icon, fill: 1, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${sign > 0 ? '+' : '-'}${formatDurationTimestamp(magnitude)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1,
                    fontWeight: .w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatDurationTimestamp(target),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
                height: 1,
                fontWeight: .w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// +1 in a left-to-right layout, -1 in a right-to-left one, so the direction
/// prefix matches the way the pill itself is read.
int layoutDirectionSign(BuildContext context) => Directionality.of(context) == TextDirection.rtl ? -1 : 1;
