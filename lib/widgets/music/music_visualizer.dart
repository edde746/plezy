import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_source_info.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../../focus/focusable_button.dart';
import '../app_icon.dart';
import 'music_visualizer_painter.dart';
import 'music_visualizer_preset.dart';

export 'music_visualizer_preset.dart';

/// Original, full-bleed music scenes that react to Plex's analyzed loudness
/// profile when one is available. Rendering follows display vsync; raw PCM and
/// live FFT data are not exposed by Plezy's current player abstraction.
class MusicVisualizer extends StatefulWidget {
  const MusicVisualizer({
    super.key,
    required this.service,
    required this.trackKey,
    required this.duration,
    required this.preset,
    required this.onPresetChanged,
  });

  final MusicPlaybackService service;
  final String trackKey;
  final Duration duration;
  final MusicVisualizerPreset preset;
  final ValueChanged<MusicVisualizerPreset> onPresetChanged;

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final ValueNotifier<MusicVisualizerFrame> _frame = ValueNotifier(const MusicVisualizerFrame());
  AudioLoudnessProfile? _profile;
  StreamSubscription<Duration>? _reducedMotionPositionSubscription;
  bool _profileLoadStarted = false;
  bool _profileLoaded = false;
  bool _reduceMotion = false;
  bool _appResumed = true;
  int _profileRequestId = 0;
  Duration? _lastElapsed;
  double _phaseSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appResumed = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.resumed => true,
      _ => false,
    };
    _ticker = createTicker(_onTick);
    widget.service.addListener(_onServiceChanged);
    if (_sourceReady) _beginProfileLoad();
    _publishFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      _syncReducedMotionPositionListener();
      _publishFrame();
    }
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant MusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = oldWidget.service != widget.service;
    final sourceChanged = serviceChanged || oldWidget.trackKey != widget.trackKey;
    if (serviceChanged) {
      oldWidget.service.removeListener(_onServiceChanged);
      widget.service.addListener(_onServiceChanged);
      _syncReducedMotionPositionListener();
    }
    if (sourceChanged) {
      _profileRequestId++;
      _profile = null;
      _profileLoadStarted = false;
      _profileLoaded = false;
      if (_sourceReady) _beginProfileLoad();
    }
    _publishFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.service.removeListener(_onServiceChanged);
    _reducedMotionPositionSubscription?.cancel();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  bool get _sourceReady =>
      widget.service.currentTrack?.globalKey == widget.trackKey &&
      widget.service.status != MusicPlaybackStatus.loading &&
      widget.service.status != MusicPlaybackStatus.idle &&
      widget.service.status != MusicPlaybackStatus.error;

  void _syncTicker() {
    final shouldAnimate = !_reduceMotion && _appResumed;
    if (shouldAnimate && !_ticker.isActive) {
      _lastElapsed = null;
      _ticker.start();
    } else if (!shouldAnimate && _ticker.isActive) {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  void _syncReducedMotionPositionListener() {
    if (_reduceMotion && _reducedMotionPositionSubscription == null) {
      _reducedMotionPositionSubscription = widget.service.positionStream.listen((_) => _publishFrame());
    } else if (!_reduceMotion && _reducedMotionPositionSubscription != null) {
      unawaited(_reducedMotionPositionSubscription!.cancel());
      _reducedMotionPositionSubscription = null;
    }
  }

  void _onServiceChanged() {
    if (!_profileLoadStarted && _sourceReady) _beginProfileLoad();
  }

  void _beginProfileLoad() {
    if (_profileLoadStarted || !_sourceReady) return;
    _profileLoadStarted = true;
    final requestId = ++_profileRequestId;
    final service = widget.service;
    if (service is! MusicLoudnessProfileService) {
      _profileLoaded = true;
      return;
    }
    unawaited(_loadProfile(service as MusicLoudnessProfileService, requestId));
  }

  Future<void> _loadProfile(MusicLoudnessProfileService service, int requestId) async {
    try {
      final profile = await service.loadCurrentTrackLoudnessProfile();
      if (!mounted || requestId != _profileRequestId) return;
      setState(() {
        _profile = profile == null || profile.isEmpty ? null : profile;
        _profileLoaded = true;
      });
      _publishFrame();
    } catch (_) {
      // Loudness is optional; keep the scenes available and avoid surfacing a
      // network or server error from a decorative, best-effort request.
      developer.log('Optional Plex loudness data is unavailable', name: 'MusicVisualizer', level: 800);
      if (!mounted || requestId != _profileRequestId) return;
      setState(() => _profileLoaded = true);
    }
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous != null) {
      final delta = elapsed - previous;
      // Ignore large catch-up intervals after a route or app has been hidden;
      // normal frames remain driven by every display vsync.
      final seconds = delta.inMicroseconds.clamp(0, 250000) / Duration.microsecondsPerSecond;
      _phaseSeconds += seconds;
    }
    _publishFrame();
  }

  void _publishFrame() {
    final position = widget.service.position;
    final duration = widget.duration > Duration.zero ? widget.duration : widget.service.duration ?? Duration.zero;
    final progress = duration <= Duration.zero
        ? 0.0
        : (position.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0).toDouble();
    final db = _profile?.levelAt(position, duration);
    final energy = db == null
        ? 0.39 + 0.055 * math.sin(_phaseSeconds * 0.21) + 0.035 * math.sin(_phaseSeconds * 0.43 + 1.7)
        : _energyFromDb(db);
    final previousDb = _profile?.levelAt(position - const Duration(milliseconds: 850), duration);
    final transient = db == null || previousDb == null
        ? 0.0
        : ((db - previousDb - 1.5) / 11).clamp(0.0, 1.0).toDouble();

    _frame.value = MusicVisualizerFrame(
      timeSeconds: _reduceMotion ? 0 : _phaseSeconds,
      energy: energy.clamp(0.08, 1.0).toDouble(),
      transient: transient,
      progress: progress,
      playing: widget.service.isPlaying,
    );
  }

  static double _energyFromDb(double db) => ((db + 72) / 62).clamp(0.04, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final palette = MusicVisualizerPalette.fromTheme(
      accent: tk.accent,
      background: tk.bg,
      surface: tk.surface,
      outline: tk.outline,
      preset: widget.preset,
    );
    final status = !_profileLoaded
        ? t.music.visualizerProfileLoading
        : _profile == null
        ? t.music.visualizerAmbientMotion
        : t.music.visualizerPlexLoudness;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tk.surface,
        borderRadius: BorderRadius.circular(tk.radiusLg),
        border: Border.all(color: tk.outline.withValues(alpha: 0.32)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tk.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: MusicVisualizerPainter(
                    frame: _frame,
                    preset: widget.preset,
                    palette: palette,
                    profile: _profile,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned(top: 12, left: 12, child: _buildPresetControls(context, status)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetControls(BuildContext context, String status) {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(tk.radiusMd);
    final selectedName = _presetName(widget.preset);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: t.music.visualizer,
      value: '$selectedName, $status',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tk.surface.withValues(alpha: 0.84),
          borderRadius: borderRadius,
          border: Border.all(color: tk.outline.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusableButton(
                onPressed: () => widget.onPresetChanged(widget.preset.previous),
                child: IconButton(
                  tooltip: t.music.visualizerPreviousPreset,
                  onPressed: () => widget.onPresetChanged(widget.preset.previous),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  icon: const AppIcon(Symbols.chevron_left_rounded, fill: 1, size: 22),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190, minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(color: tk.textMuted, height: 1.1),
                      ),
                    ],
                  ),
                ),
              ),
              FocusableButton(
                onPressed: () => widget.onPresetChanged(widget.preset.next),
                child: IconButton(
                  tooltip: t.music.visualizerNextPreset,
                  onPressed: () => widget.onPresetChanged(widget.preset.next),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  icon: const AppIcon(Symbols.chevron_right_rounded, fill: 1, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _presetName(MusicVisualizerPreset preset) => switch (preset) {
    MusicVisualizerPreset.aurora => t.music.visualizerPresetAurora,
    MusicVisualizerPreset.bloom => t.music.visualizerPresetBloom,
    MusicVisualizerPreset.orbitals => t.music.visualizerPresetOrbitals,
    MusicVisualizerPreset.prism => t.music.visualizerPresetPrism,
    MusicVisualizerPreset.tunnel => t.music.visualizerPresetTunnel,
    MusicVisualizerPreset.trackMap => t.music.visualizerPresetTrackMap,
  };
}
