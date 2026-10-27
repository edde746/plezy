import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/presentation_formats.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../services/music/music_playback_service.dart';
import '../theme/mono_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/music/music_visualizer.dart';
import '../utils/formatters.dart';
import 'workspace_controller.dart';

/// Compact music adapter backed by Plezy's existing queue and playback owner.
class MusicWorkspaceSurface extends StatefulWidget {
  const MusicWorkspaceSurface({super.key, required this.service, required this.controller, required this.sessionId});

  final MusicPlaybackService service;
  final MultiviewWorkspaceController controller;
  final String sessionId;

  @override
  State<MusicWorkspaceSurface> createState() => _MusicWorkspaceSurfaceState();
}

class _MusicWorkspaceSurfaceState extends State<MusicWorkspaceSurface> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
  }

  @override
  void didUpdateWidget(covariant MusicWorkspaceSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_onServiceChanged);
      widget.service.addListener(_onServiceChanged);
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    final track = widget.service.currentTrack;
    if (track == null) {
      widget.controller.unregister(widget.sessionId);
      return;
    }
    final existing = widget.controller.session(widget.sessionId);
    if (existing == null) return;
    final descriptor = existing.descriptor.copyWith(
      title: track.title?.trim().isNotEmpty == true ? track.title!.trim() : t.common.unknown,
      subtitle: track.trackArtistTitle,
      clearSubtitle: track.trackArtistTitle == null,
      mediaKey: track.globalKey,
    );
    widget.controller.updateDescriptor(descriptor);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final track = service.currentTrack;
        if (track == null) {
          return ColoredBox(
            color: tokens(context).bg,
            child: Center(
              child: Text(t.common.unknown, style: TextStyle(color: tokens(context).textMuted)),
            ),
          );
        }
        return _MusicWorkspaceTrack(service: service, track: track);
      },
    );
  }
}

class _MusicWorkspaceTrack extends StatelessWidget {
  const _MusicWorkspaceTrack({required this.service, required this.track});

  final MusicPlaybackService service;
  final MediaItem track;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final artist = track.trackArtistTitle;
    final duration = service.duration ?? Duration.zero;

    return Material(
      color: tk.bg,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            MusicVisualizer(
              service: service,
              trackKey: track.globalKey,
              duration: duration,
              preset: MusicVisualizerPreset.bloom,
              onPresetChanged: (_) {},
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xC9000000)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tk.space),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    isolateDisplayText(track.title ?? t.common.unknown),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  if (artist != null && artist.isNotEmpty) ...[
                    SizedBox(height: tk.space * 0.25),
                    Text(
                      isolateDisplayText(artist),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                  SizedBox(height: tk.space * 0.7),
                  _MusicProgress(service: service, duration: duration),
                  SizedBox(height: tk.space * 0.45),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: t.music.previousTrack,
                        onPressed: () => unawaited(service.previous()),
                        icon: const AppIcon(Symbols.skip_previous_rounded, color: Colors.white),
                      ),
                      IconButton.filledTonal(
                        tooltip: service.isPlaying ? t.common.pause : t.common.play,
                        onPressed: () => unawaited(service.togglePlayPause()),
                        icon: AppIcon(
                          service.isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: t.music.nextTrack,
                        onPressed: () => unawaited(service.next()),
                        icon: const AppIcon(Symbols.skip_next_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicProgress extends StatelessWidget {
  const _MusicProgress({required this.service, required this.duration});

  final MusicPlaybackService service;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: service.positionStream,
      initialData: service.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final fraction = duration.inMilliseconds <= 0
            ? 0.0
            : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0).toDouble();
        return Column(
          children: [
            LinearProgressIndicator(
              value: fraction,
              minHeight: 3,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDurationTimestamp(position),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
                Text(
                  formatDurationTimestamp(duration),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
