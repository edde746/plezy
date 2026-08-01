import 'package:flutter/material.dart';

import '../../theme/mono_tokens.dart';

/// Fill for "currently airing" live TV cards: one text-alpha step above the
/// idle surface card. Shared by the guide's airing blocks, the recordings
/// tab's in-progress tile, and the show schedule's live tile.
Color airingFill(BuildContext context) {
  final tk = tokens(context);
  return Color.alphaBlend(tk.text.withValues(alpha: 0.08), tk.surface);
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
