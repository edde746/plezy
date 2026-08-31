import 'package:flutter/material.dart';

import '../../theme/mono_tokens.dart';

/// Fill for "currently airing" live TV cards: one text-alpha step above the
/// idle surface card. Shared by the guide's airing blocks, the recordings
/// tab's in-progress tile, and the show schedule's live tile.
Color airingFill(BuildContext context) {
  final tk = tokens(context);
  return Color.alphaBlend(tk.text.withValues(alpha: 0.08), tk.surface);
}

/// Remap target for a channel logo rendered on [surface].
///
/// Broadcast logos are white-on-transparent marks designed for dark UIs; on a
/// light backdrop they vanish (issue #2197), so light surfaces recolor
/// light-toned logos toward [foreground]. Dark backdrops — dark theme cards,
/// or the light theme's inverted focus card — render the original artwork.
/// Pass the result to `OptimizedMediaImage.logoToneTarget`.
Color? channelLogoToneTarget({required Color surface, required Color foreground}) {
  return surface.computeLuminance() > 0.5 ? foreground : null;
}

/// Tinted M3E status pill (LIVE badge, recording / error state).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(Radius.circular(MonoTokens.radiusFull)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: .w700),
      ),
    );
  }
}
