import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_source_info.dart';
import '../../mpv/player/audio_spectrum.dart';
import '../../services/music/music_playback_service.dart';
import '../../sources/source_playback.dart';
import '../../theme/mono_tokens.dart';
import '../../focus/focusable_button.dart';
import '../app_icon.dart';
import 'music_visualizer_painter.dart';
import 'music_visualizer_preset.dart';

export 'music_visualizer_preset.dart';

/// Original, full-bleed music scenes that prefer Plex's analyzed loudness
/// profile and can react to compact live MPV audio statistics when available.
/// Raw PCM and frequency-bin data never leave the native player.
class MusicVisualizer extends StatefulWidget {
  const MusicVisualizer({
    super.key,
    required this.service,
    required this.trackKey,
    required this.duration,
    required this.preset,
    required this.onPresetChanged,
  }) : sourcePlayback = null;

  const MusicVisualizer.forSource({
    super.key,
    required SourcePlayback playback,
    required this.preset,
    required this.onPresetChanged,
  }) : sourcePlayback = playback,
       service = null,
       trackKey = '',
       duration = Duration.zero;

  final MusicPlaybackService? service;
  final SourcePlayback? sourcePlayback;
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
  AudioSpectrumSample? _spectrumSample;
  AudioSpectrumAnalyzer? _spectrumAnalyzer;
  // Lifecycle cleanup is centralized in _stopSpectrumAnalysis.
  // ignore: cancel_subscriptions
  StreamSubscription<AudioSpectrumSample?>? _spectrumSubscription;
  Timer? _spectrumMonitor;
  Duration? _lastSpectrumAt;
  Duration? _missingSpectrumSince;
  Duration _spectrumMonitorElapsed = Duration.zero;
  StreamSubscription<Duration>? _reducedMotionPositionSubscription;
  bool _profileLoadStarted = false;
  bool _profileLoaded = false;
  bool _reduceMotion = false;
  bool _appResumed = true;
  int _profileRequestId = 0;
  Duration? _lastElapsed;
  double _phaseSeconds = 0;
  String? _observedSourceIdentity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appResumed = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.resumed => true,
      _ => false,
    };
    _ticker = createTicker(_onTick);
    _playbackListenable.addListener(_onSourceChanged);
    _observedSourceIdentity = _sourceIdentity;
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
    final listenableChanged = oldWidget.service != widget.service || oldWidget.sourcePlayback != widget.sourcePlayback;
    final sourceChanged = listenableChanged || oldWidget.trackKey != widget.trackKey;
    if (listenableChanged) {
      _listenableFor(oldWidget).removeListener(_onSourceChanged);
      _playbackListenable.addListener(_onSourceChanged);
      _syncReducedMotionPositionListener();
    }
    if (sourceChanged) {
      _stopSpectrumAnalysis();
      _spectrumSample = null;
      _observedSourceIdentity = _sourceIdentity;
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
    _playbackListenable.removeListener(_onSourceChanged);
    final reducedMotionSubscription = _reducedMotionPositionSubscription;
    _reducedMotionPositionSubscription = null;
    if (reducedMotionSubscription != null) unawaited(reducedMotionSubscription.cancel());
    final spectrumSubscription = _spectrumSubscription;
    _spectrumSubscription = null;
    if (spectrumSubscription != null) unawaited(spectrumSubscription.cancel());
    _stopSpectrumAnalysis();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  Listenable get _playbackListenable => _listenableFor(widget);

  static Listenable _listenableFor(MusicVisualizer widget) => widget.service ?? widget.sourcePlayback!;

  String? get _sourceIdentity => widget.service != null
      ? widget.service!.currentTrack?.globalKey
      : widget.sourcePlayback?.active == true
      ? '${widget.sourcePlayback!.entry?.key}:${widget.sourcePlayback!.fileIndex}'
      : null;

  bool get _sourceReady {
    final service = widget.service;
    if (service != null) {
      return service.currentTrack?.globalKey == widget.trackKey &&
          service.status != MusicPlaybackStatus.loading &&
          service.status != MusicPlaybackStatus.idle &&
          service.status != MusicPlaybackStatus.error;
    }
    final playback = widget.sourcePlayback;
    return playback != null && playback.active && !playback.opening && !playback.video && playback.player != null;
  }

  AudioSpectrumAnalyzer? get _availableAnalyzer {
    final sourcePlayback = widget.sourcePlayback;
    if (sourcePlayback != null) {
      final player = sourcePlayback.player;
      return player is AudioSpectrumAnalyzer ? player as AudioSpectrumAnalyzer : null;
    }
    final service = widget.service;
    return service is MusicAudioSpectrumService ? (service as MusicAudioSpectrumService).audioSpectrumAnalyzer : null;
  }

  Duration get _position => widget.service?.position ?? Duration(milliseconds: widget.sourcePlayback?.positionMs ?? 0);

  Duration get _duration {
    final configured = widget.duration;
    if (configured > Duration.zero) return configured;
    final sourceDuration = widget.sourcePlayback?.durationMs ?? 0;
    if (sourceDuration > 0) return Duration(milliseconds: sourceDuration);
    return widget.service?.duration ?? Duration.zero;
  }

  bool get _isPlaying => widget.service?.isPlaying ?? widget.sourcePlayback?.playing ?? false;

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
    if (widget.service == null) return;
    if (_reduceMotion && _reducedMotionPositionSubscription == null) {
      _reducedMotionPositionSubscription = widget.service!.positionStream.listen((_) => _publishFrame());
    } else if (!_reduceMotion && _reducedMotionPositionSubscription != null) {
      unawaited(_reducedMotionPositionSubscription!.cancel());
      _reducedMotionPositionSubscription = null;
    }
  }

  void _onSourceChanged() {
    final identity = _sourceIdentity;
    if (identity != _observedSourceIdentity) {
      _observedSourceIdentity = identity;
      _spectrumSample = null;
      _lastSpectrumAt = null;
      _missingSpectrumSince = null;
      _spectrumMonitorElapsed = Duration.zero;
    }
    if (!_profileLoadStarted && _sourceReady) _beginProfileLoad();
    if (_profileLoaded && _profile == null && _sourceReady) _syncSpectrumAnalyzer();
    _publishFrame();
  }

  void _beginProfileLoad() {
    if (_profileLoadStarted || !_sourceReady) return;
    _profileLoadStarted = true;
    final requestId = ++_profileRequestId;
    final service = widget.service;
    if (service == null) {
      _profileLoaded = true;
      _syncSpectrumAnalyzer();
      return;
    }
    if (service is! MusicLoudnessProfileService) {
      _profileLoaded = true;
      _syncSpectrumAnalyzer();
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
      if (_profile == null) {
        _syncSpectrumAnalyzer();
      } else {
        _stopSpectrumAnalysis();
        _spectrumSample = null;
      }
      _publishFrame();
    } catch (_) {
      // Loudness is optional; keep the scenes available and avoid surfacing a
      // network or server error from a decorative, best-effort request.
      developer.log('Optional Plex loudness data is unavailable', name: 'MusicVisualizer', level: 800);
      if (!mounted || requestId != _profileRequestId) return;
      setState(() => _profileLoaded = true);
      _syncSpectrumAnalyzer();
    }
  }

  void _syncSpectrumAnalyzer() {
    final analyzer = _availableAnalyzer;
    if (!_sourceReady || analyzer == null || _profile != null) {
      if (_spectrumAnalyzer != null && (analyzer != _spectrumAnalyzer || _profile != null || !_sourceReady)) {
        _stopSpectrumAnalysis();
      }
      return;
    }
    if (identical(analyzer, _spectrumAnalyzer) && _spectrumSubscription != null) {
      _ensureSpectrumMonitor();
      return;
    }
    _stopSpectrumAnalysis();
    _spectrumAnalyzer = analyzer;
    _spectrumSubscription = analyzer.audioSpectrumStream.listen((sample) {
      if (!mounted || !identical(analyzer, _spectrumAnalyzer)) return;
      final wasVisible = _spectrumSample != null;
      _spectrumSample = sample;
      _lastSpectrumAt = sample == null ? null : _spectrumMonitorElapsed;
      _missingSpectrumSince = null;
      if (wasVisible != (sample != null)) setState(() {});
      _publishFrame();
    });
    unawaited(_requestSpectrumAnalysis(analyzer));
    _ensureSpectrumMonitor();
  }

  Future<void> _requestSpectrumAnalysis(AudioSpectrumAnalyzer analyzer) async {
    try {
      await analyzer.setAudioSpectrumAnalysisEnabled(true);
    } on Object {
      // Analysis is decorative; the existing ambient scene remains available.
    }
    if (mounted && identical(analyzer, _spectrumAnalyzer)) _ensureSpectrumMonitor();
  }

  void _ensureSpectrumMonitor() {
    if (_spectrumMonitor != null || _spectrumAnalyzer == null) return;
    const interval = Duration(milliseconds: 500);
    _spectrumMonitorElapsed = Duration.zero;
    _spectrumMonitor = Timer.periodic(interval, (_) {
      final analyzer = _spectrumAnalyzer;
      if (!mounted || analyzer == null) return;
      _spectrumMonitorElapsed += interval;
      final now = _spectrumMonitorElapsed;
      if (_spectrumSample != null && _lastSpectrumAt != null && now - _lastSpectrumAt! > const Duration(seconds: 2)) {
        _spectrumSample = null;
        setState(() {});
        _publishFrame();
      }
      if (!_isPlaying || analyzer.audioPassthroughActive) {
        _missingSpectrumSince = null;
        return;
      }
      if (_lastSpectrumAt != null && now - _lastSpectrumAt! <= const Duration(seconds: 2)) {
        _missingSpectrumSince = null;
        return;
      }
      _missingSpectrumSince ??= now;
      if (now - _missingSpectrumSince! >= const Duration(seconds: 3)) {
        _stopSpectrumAnalysis();
        _publishFrame();
      }
    });
  }

  void _stopSpectrumAnalysis() {
    _spectrumMonitor?.cancel();
    _spectrumMonitor = null;
    _missingSpectrumSince = null;
    _spectrumMonitorElapsed = Duration.zero;
    final analyzer = _spectrumAnalyzer;
    _spectrumAnalyzer = null;
    final subscription = _spectrumSubscription;
    _spectrumSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (analyzer != null) unawaited(analyzer.setAudioSpectrumAnalysisEnabled(false));
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
    final position = _position;
    final duration = _duration;
    final progress = duration <= Duration.zero
        ? 0.0
        : (position.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0).toDouble();
    final db = _profile?.levelAt(position, duration);
    final spectrum = _profile == null ? _spectrumSample : null;
    final energy = db == null
        ? spectrum == null
              ? 0.39 + 0.055 * math.sin(_phaseSeconds * 0.21) + 0.035 * math.sin(_phaseSeconds * 0.43 + 1.7)
              : _energyFromSpectrum(spectrum)
        : _energyFromDb(db);
    final previousDb = _profile?.levelAt(position - const Duration(milliseconds: 850), duration);
    final transient = db != null && previousDb != null
        ? ((db - previousDb - 1.5) / 11).clamp(0.0, 1.0).toDouble()
        : spectrum == null
        ? 0.0
        : ((spectrum.normalizedCentroid * 0.65 + spectrum.flatness * 0.35 - 0.32) * 2.6).clamp(0.0, 1.0).toDouble();

    _frame.value = MusicVisualizerFrame(
      timeSeconds: _reduceMotion ? 0 : _phaseSeconds,
      energy: energy.clamp(0.08, 1.0).toDouble(),
      transient: transient,
      progress: progress,
      playing: _isPlaying,
    );
  }

  static double _energyFromDb(double db) => ((db + 72) / 62).clamp(0.04, 1.0).toDouble();

  static double _energyFromSpectrum(AudioSpectrumSample sample) =>
      (0.18 + sample.normalizedCentroid * 0.52 + sample.flatness * 0.24).clamp(0.08, 1.0).toDouble();

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
        ? _spectrumSample == null
              ? t.music.visualizerAmbientMotion
              : t.music.visualizerLiveAudio
        : t.music.visualizerPlexLoudness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLabelWidth = (constraints.maxWidth - 92).clamp(72, 190).toDouble();
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
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildPresetControls(context, status, maxLabelWidth: maxLabelWidth),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetControls(BuildContext context, String status, {required double maxLabelWidth}) {
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
                constraints: BoxConstraints(maxWidth: maxLabelWidth, minHeight: 40),
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
