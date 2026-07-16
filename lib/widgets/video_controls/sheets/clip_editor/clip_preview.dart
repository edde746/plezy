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
                      _ClipPreviewVolumeControl(
                        controller: controller,
                        volume: state.volume,
                        maxVolume: controller.maxVolume,
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

class _ClipPreviewPlayerSurface extends StatefulWidget {
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
  State<_ClipPreviewPlayerSurface> createState() => _ClipPreviewPlayerSurfaceState();
}

class _ClipPreviewPlayerSurfaceState extends State<_ClipPreviewPlayerSurface> {
  bool _hovering = false;

  Future<void> _saveScreenshot() async {
    try {
      final outputPath = await widget.controller.saveScreenshot();
      if (mounted) showSuccessSnackBar(context, '${t.videoControls.screenshotSaved}: ${path.basename(outputPath)}');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.controller.player;
    final hasEmbeddedSurface = player != null && (player.textureId != null || player is VideoRectSupport);
    final rectUpdateListenable =
        OverlaySheetController.maybeOf(context)?.geometryChanges ?? ModalRoute.of(context)?.animation;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasEmbeddedSurface)
            Video(player: player, backgroundColor: Colors.transparent, rectUpdateListenable: rectUpdateListenable),
          if (widget.forcePoster || !hasEmbeddedSurface || !widget.state.firstFrame) widget.poster,
          if (_hovering)
            Positioned(
              left: 8,
              bottom: 8,
              child: IconButton.filledTonal(
                key: const ValueKey('clip_preview_screenshot'),
                tooltip: t.hotkeys.actions.screenshot,
                onPressed: widget.state.firstFrame && !widget.state.screenshotting
                    ? () => unawaited(_saveScreenshot())
                    : null,
                icon: widget.state.screenshotting
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Symbols.photo_camera_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClipPreviewVolumeControl extends StatefulWidget {
  final ClipPreviewPlayerController controller;
  final double volume;
  final double maxVolume;

  const _ClipPreviewVolumeControl({required this.controller, required this.volume, required this.maxVolume});

  @override
  State<_ClipPreviewVolumeControl> createState() => _ClipPreviewVolumeControlState();
}

class _ClipPreviewVolumeControlState extends State<_ClipPreviewVolumeControl> {
  OverlayEntry? _sliderOverlay;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _sliderOverlay?.remove();
    super.dispose();
  }

  void _showSlider() {
    _hideTimer?.cancel();
    if (_sliderOverlay != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;
    if (overlay == null || overlayBox == null || targetBox == null || !targetBox.hasSize) return;

    const sliderSize = Size(40, 132);
    final targetTopLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final maxLeft = (overlayBox.size.width - sliderSize.width - 8).clamp(8.0, double.infinity).toDouble();
    final left = (targetTopLeft.dx + (targetBox.size.width - sliderSize.width) / 2).clamp(8.0, maxLeft).toDouble();
    final top = (targetTopLeft.dy - sliderSize.height - 2).clamp(8.0, double.infinity).toDouble();
    _sliderOverlay = OverlayEntry(builder: (context) => _buildSliderOverlay(context, Offset(left, top)));
    overlay.insert(_sliderOverlay!);
  }

  void _scheduleHideSlider() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 120), _removeSlider);
  }

  void _removeSlider() {
    _hideTimer?.cancel();
    _sliderOverlay?.remove();
    _sliderOverlay = null;
  }

  Widget _buildSliderOverlay(BuildContext context, Offset offset) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: 40,
      height: 132,
      child: MouseRegion(
        onEnter: (_) => _showSlider(),
        onExit: (_) => _scheduleHideSlider(),
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          elevation: 6,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            key: const ValueKey('clip_preview_volume_slider'),
            width: 40,
            height: 132,
            child: RotatedBox(
              quarterTurns: 3,
              child: ValueListenableBuilder<ClipPreviewPlayerState>(
                valueListenable: widget.controller,
                builder: (context, state, _) {
                  return Slider(
                    min: 0,
                    max: widget.maxVolume,
                    value: state.volume.clamp(0.0, widget.maxVolume),
                    onChanged: (volume) => unawaited(widget.controller.setVolume(volume)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = widget.volume == 0;
    return MouseRegion(
      onEnter: (_) => _showSlider(),
      onExit: (_) => _scheduleHideSlider(),
      child: IconButton(
        key: const ValueKey('clip_preview_volume'),
        visualDensity: VisualDensity.compact,
        tooltip: muted ? 'Unmute preview' : 'Mute preview',
        onPressed: () => unawaited(widget.controller.toggleMute()),
        icon: Icon(muted ? Symbols.volume_off_rounded : Symbols.volume_up_rounded),
      ),
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
