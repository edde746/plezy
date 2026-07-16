part of '../clip_editor_sheet.dart';

class _ClipPreviewPlayer extends StatelessWidget {
  final ClipPreviewPlayerController controller;
  final ScrubFrame? Function(Duration position) frameFor;
  final ClipSelection selection;
  final ValueChanged<Duration> onSeek;
  final bool forcePoster;
  final double height;

  const _ClipPreviewPlayer({
    required this.controller,
    required this.frameFor,
    required this.selection,
    required this.onSeek,
    required this.forcePoster,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return ValueListenableBuilder<ClipPreviewPlayerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final position = state.position < selection.start || state.position > selection.end
            ? selection.start
            : state.position;
        final relative = _relativePreviewPosition(position, selection);
        final durationMs = selection.duration.inMilliseconds;
        final maxMs = durationMs <= 0 ? 1.0 : durationMs.toDouble();
        final value = relative.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                key: const ValueKey('clip_preview_surface'),
                height: height,
                child: _ClipPreviewPlayerSurface(
                  controller: controller,
                  state: state,
                  poster: _ClipPreviewPoster(frame: frameFor(position)),
                  forcePoster: forcePoster,
                ),
              ),
            ),
            ColoredBox(
              color: colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        key: const ValueKey('clip_preview_play_pause'),
                        visualDensity: VisualDensity.compact,
                        tooltip: state.playing ? 'Pause' : 'Play',
                        onPressed: () => state.playing ? unawaited(controller.pause()) : unawaited(controller.play()),
                        icon: Icon(state.playing ? Symbols.pause_rounded : Symbols.play_arrow_rounded),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          ),
                          child: Slider(
                            key: const ValueKey('clip_preview_scrubber'),
                            min: 0,
                            max: maxMs,
                            value: value,
                            onChanged: (next) => onSeek(selection.start + Duration(milliseconds: next.round())),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ClipExportService.formatClipTimestamp(relative)} / ${ClipExportService.formatClipTimestamp(selection.duration)}',
                        style: labelStyle,
                      ),
                    ],
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        state.error!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Duration _relativePreviewPosition(Duration position, ClipSelection selection) {
    final relative = position - selection.start;
    if (relative.isNegative) return Duration.zero;
    if (relative > selection.duration) return selection.duration;
    return relative;
  }
}

class _ClipPreviewPlayerSurface extends StatelessWidget {
  final ClipPreviewPlayerController controller;
  final ClipPreviewPlayerState state;
  final Widget poster;
  final bool forcePoster;

  const _ClipPreviewPlayerSurface({
    required this.controller,
    required this.state,
    required this.poster,
    required this.forcePoster,
  });

  @override
  Widget build(BuildContext context) {
    final player = controller.player;
    final hasEmbeddedSurface = player != null && (player.textureId != null || player is VideoRectSupport);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasEmbeddedSurface) Video(player: player, backgroundColor: Colors.transparent),
        if (forcePoster || !hasEmbeddedSurface || !state.firstFrame) poster,
      ],
    );
  }
}

class _ClipPreviewPoster extends StatelessWidget {
  final ScrubFrame? frame;

  const _ClipPreviewPoster({required this.frame});

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('clip_preview_poster'),
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        _ClipFrameView(frame: frame),
      ],
    );
  }
}

class _ClipFrameView extends StatelessWidget {
  final ScrubFrame? frame;

  const _ClipFrameView({required this.frame});

  @override
  Widget build(BuildContext context) {
    final frame = this.frame;
    if (frame == null) {
      return Center(child: Icon(Symbols.image_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant));
    }

    return ScrubFrameView(frame: frame, fit: BoxFit.contain);
  }
}
