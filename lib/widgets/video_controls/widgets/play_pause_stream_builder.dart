import 'package:flutter/widgets.dart';

import '../../../mpv/mpv.dart';

/// Subscribes to [Player.streams.playing] and exposes the current
/// play/pause state plus the matching icon to a [builder].
class PlayPauseStreamBuilder extends StatelessWidget {
  final Player player;
  final Widget Function(BuildContext context, bool isPlaying) builder;

  const PlayPauseStreamBuilder({super.key, required this.player, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.streams.playing,
      initialData: player.state.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return builder(context, isPlaying);
      },
    );
  }
}
