import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_source_info.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../app_icon.dart';

/// Native, progress-aware visualizer for Plex's analyzed loudness profile.
/// The profile is sampled only while this panel is visible; playback itself
/// never waits for the optional request.
class MusicVisualizer extends StatefulWidget {
  const MusicVisualizer({super.key, required this.service, required this.trackKey, required this.duration});

  final MusicPlaybackService service;
  final String trackKey;
  final Duration duration;

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer> {
  late Future<AudioLoudnessProfile?> _profileFuture;
  bool _readyProfileLoadStarted = false;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
    _readyProfileLoadStarted = widget.service.status == MusicPlaybackStatus.playing;
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant MusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged = oldWidget.service != widget.service || oldWidget.trackKey != widget.trackKey;
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_onServiceChanged);
      widget.service.addListener(_onServiceChanged);
    }
    if (sourceChanged) {
      _readyProfileLoadStarted = widget.service.status == MusicPlaybackStatus.playing;
      _profileFuture = _loadProfile();
    }
  }

  bool get _sourceReady =>
      widget.service.currentTrack?.globalKey == widget.trackKey &&
      widget.service.status != MusicPlaybackStatus.loading &&
      widget.service.status != MusicPlaybackStatus.idle &&
      widget.service.status != MusicPlaybackStatus.error;

  void _onServiceChanged() {
    if (_readyProfileLoadStarted || !_sourceReady || !mounted) return;
    _readyProfileLoadStarted = true;
    setState(() => _profileFuture = _loadProfile());
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  Future<AudioLoudnessProfile?> _loadProfile() {
    final service = widget.service;
    return service is MusicLoudnessProfileService
        ? (service as MusicLoudnessProfileService).loadCurrentTrackLoudnessProfile()
        : Future<AudioLoudnessProfile?>.value();
  }

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(tk.radiusLg),
        border: Border.all(color: tk.outline.withValues(alpha: 0.32)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tk.radiusLg),
        child: FutureBuilder<AudioLoudnessProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _VisualizerMessage(
                icon: Symbols.graphic_eq_rounded,
                label: t.music.visualizerLoading,
                spinning: true,
              );
            }
            final profile = snapshot.data;
            if (profile == null || profile.isEmpty) {
              return _VisualizerMessage(icon: Symbols.graphic_eq_rounded, label: t.music.visualizerUnavailable);
            }

            return StreamBuilder<Duration>(
              stream: widget.service.positionStream,
              initialData: widget.service.position,
              builder: (context, positionSnapshot) {
                return CustomPaint(
                  painter: _LoudnessPainter(
                    levelsDb: profile.levelsDb,
                    position: positionSnapshot.data ?? Duration.zero,
                    duration: widget.duration,
                    active: Theme.of(context).colorScheme.primary,
                    inactive: tk.textMuted,
                    outline: tk.outline,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VisualizerMessage extends StatelessWidget {
  const _VisualizerMessage({required this.icon, required this.label, this.spinning = false});

  final IconData icon;
  final String label;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinning)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
              )
            else
              AppIcon(icon, fill: 1, size: 30, color: tk.textMuted),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tk.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoudnessPainter extends CustomPainter {
  const _LoudnessPainter({
    required this.levelsDb,
    required this.position,
    required this.duration,
    required this.active,
    required this.inactive,
    required this.outline,
  });

  final List<double> levelsDb;
  final Duration position;
  final Duration duration;
  final Color active;
  final Color inactive;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || levelsDb.isEmpty) return;
    final progress = duration <= Duration.zero
        ? 0.0
        : (position.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0).toDouble();
    final count = math.min(64, levelsDb.length);
    final barWidth = math.min(6.0, size.width / (count * 1.8));
    final gap = (size.width - count * barWidth) / (count + 1);
    final centerY = size.height * 0.53;
    final maxBarHeight = size.height * 0.48;
    final backgroundPaint = Paint()..color = outline.withValues(alpha: 0.28);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), backgroundPaint);

    for (var i = 0; i < count; i++) {
      final sampleIndex = count == 1 ? 0 : (i * (levelsDb.length - 1) / (count - 1)).round();
      final db = levelsDb[sampleIndex].clamp(-72.0, -10.0).toDouble();
      final level = ((db + 72) / 62).clamp(0.06, 1.0).toDouble();
      final barHeight = math.max(5.0, level * maxBarHeight);
      final x = gap + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - barHeight, barWidth, barHeight * 2),
        Radius.circular(barWidth / 2),
      );
      final isPlayed = count == 1 || i / (count - 1) <= progress;
      canvas.drawRRect(rect, Paint()..color = (isPlayed ? active : inactive).withValues(alpha: isPlayed ? 0.92 : 0.30));
    }

    final playheadX = size.width * progress;
    canvas.drawLine(
      Offset(playheadX, size.height * 0.16),
      Offset(playheadX, size.height * 0.88),
      Paint()
        ..color = active.withValues(alpha: 0.8)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(playheadX, size.height * 0.16), 3, Paint()..color = active);
  }

  @override
  bool shouldRepaint(covariant _LoudnessPainter oldDelegate) =>
      !identical(oldDelegate.levelsDb, levelsDb) ||
      oldDelegate.position != position ||
      oldDelegate.duration != duration ||
      oldDelegate.active != active ||
      oldDelegate.inactive != inactive ||
      oldDelegate.outline != outline;
}
