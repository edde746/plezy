import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_action_bar.dart';
import '../../i18n/strings.g.dart';
import '../app_icon.dart';

/// Standard action list for the music detail screens (album/artist):
/// a labeled Play pill, a shuffle icon, an optional Instant Mix icon (pass
/// null when the server lacks the capability), an optional [download]
/// action (the album download button), and an optional [trailing] action
/// (the album overflow ⋮). Render inside a [FocusableActionBar] —
/// icon actions get the bar's default focus-background treatment.
List<FocusableAction> buildMusicActions({
  required VoidCallback onPlay,
  required VoidCallback onShuffle,
  VoidCallback? onInstantMix,
  FocusableAction? download,
  FocusableAction? trailing,
}) {
  return [
    FocusableAction(
      debugLabel: 'music_play',
      onPressed: onPlay,
      builder: (context, state) => _MusicPlayButton(onPressed: onPlay, showFocus: state.showFocus),
    ),
    FocusableAction(
      debugLabel: 'music_shuffle',
      icon: Symbols.shuffle_rounded,
      tooltip: t.common.shuffle,
      onPressed: onShuffle,
    ),
    if (onInstantMix != null)
      FocusableAction(
        debugLabel: 'music_instant_mix',
        icon: Symbols.instant_mix_rounded,
        tooltip: t.music.instantMix,
        onPressed: onInstantMix,
      ),
    ?download,
    ?trailing,
  ];
}

/// Labeled Play pill. D-pad focus swaps the background to the inverse
/// surface (no outline), mirroring the media detail action row.
class _MusicPlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool showFocus;

  const _MusicPlayButton({required this.onPressed, required this.showFocus});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: onPressed,
      style: showFocus
          ? FilledButton.styleFrom(
              backgroundColor: colorScheme.inverseSurface,
              foregroundColor: colorScheme.onInverseSurface,
            )
          : null,
      icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 20),
      label: Text(t.common.play, style: const TextStyle(fontWeight: .w700)),
    );
  }
}
