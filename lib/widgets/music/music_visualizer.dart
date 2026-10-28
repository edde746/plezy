import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_source_info.dart';
import '../../services/music/music_playback_service.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/visualization/visualizer_pack_store.dart';
import '../../services/visualization/visualizer_session.dart';
import '../../theme/mono_tokens.dart';
import '../../focus/focusable_button.dart';
import '../app_icon.dart';
import 'visualizer_library_sheet.dart';
import 'music_visualizer_painter.dart';
import 'music_visualizer_preset.dart';
import 'visualizer_preset_browser.dart';

export 'music_visualizer_preset.dart';

/// Original scenes plus an optional native texture driven by the music core's
/// PCM tap. Only control messages and status cross the Flutter platform channel.
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
  final VisualizerSession _native = VisualizerSession();
  final ValueNotifier<int> _optionsRevision = ValueNotifier(0);
  VisualizerPackStore? _store;
  String? _profileId;
  int _preferenceGeneration = 0;
  List<VisualizerPresetFile> _playlist = [];
  Timer? _presetTimer;
  bool _shuffle = false, _locked = true, _fullscreen = false;
  int _intervalSeconds = 30;
  double _resolutionScale = 1;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appResumed = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.resumed => true,
      _ => false,
    };
    _ticker = createTicker(_onTick);
    _native.addListener(_onNativeChanged);
    widget.service.addListener(_onServiceChanged);
    if (_sourceReady) _beginProfileLoad();
    _publishFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = context.watch<ActiveProfileProvider?>()?.activeId;
    if (_store == null || profileId != _profileId) {
      _profileId = profileId;
      _store?.dispose();
      _store = VisualizerPackStore(profileId: profileId);
      _playlist = [];
      unawaited(_native.stop());
      unawaited(_restorePreferences(++_preferenceGeneration));
    }
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
      unawaited(_native.stop());
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
    _syncTicker();
    if (oldWidget.preset != widget.preset) _savePreferences();
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
    _presetTimer?.cancel();
    _native.removeListener(_onNativeChanged);
    _native.dispose();
    _optionsRevision.dispose();
    _store?.dispose();
    _frame.dispose();
    super.dispose();
  }

  bool get _sourceReady =>
      widget.service.currentTrack?.globalKey == widget.trackKey &&
      widget.service.status != MusicPlaybackStatus.loading &&
      widget.service.status != MusicPlaybackStatus.idle &&
      widget.service.status != MusicPlaybackStatus.error;

  void _syncTicker() {
    final visible = _fullscreen || TickerMode.of(context);
    final shouldAnimate = !_reduceMotion && _appResumed && visible && !_native.hasFrame;
    if (shouldAnimate && !_ticker.isActive) {
      _lastElapsed = null;
      _ticker.start();
    } else if (!shouldAnimate && _ticker.isActive) {
      _ticker.stop();
      _lastElapsed = null;
    }
    _native.setPaused(_reduceMotion || !_appResumed || !visible || !widget.service.isPlaying || !_sourceReady);
    _syncPresetTimer();
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
    _syncTicker();
  }

  void _onNativeChanged() {
    if (!mounted) return;
    setState(() {});
    _syncTicker();
  }

  Future<void> _restorePreferences(int generation) async {
    final store = _store!;
    try {
      final prefs = await store.preferences();
      final files = await store.allPresets();
      if (!mounted || generation != _preferenceGeneration) return;
      _shuffle = prefs['shuffle'] == true;
      _locked = prefs['locked'] != false;
      _intervalSeconds = prefs['interval'] is int ? (prefs['interval'] as int).clamp(10, 600).toInt() : 30;
      _resolutionScale = prefs['quality'] == 'low' ? 0.5 : 1;
      final savedQueue = prefs['playlist'];
      final byPath = {for (final file in files) file.libraryPath: file};
      _playlist = savedQueue is List
          ? savedQueue.whereType<String>().map((path) => byPath[path]).whereType<VisualizerPresetFile>().toList()
          : files.where((file) => file.supportsProjectM).toList();
      final original = prefs['original'];
      for (final preset in MusicVisualizerPreset.values) {
        if (preset.name == original) widget.onPresetChanged(preset);
      }
      final selected = byPath[prefs['selected']];
      if (selected != null && selected.supportsProjectM) {
        if (!_playlist.any((file) => file.id == selected.id)) _playlist.add(selected);
        await _native.load(selected);
      }
      if (!mounted || generation != _preferenceGeneration) return;
      setState(() {});
      _syncTicker();
    } on Object catch (error) {
      developer.log('Visualization preferences could not be restored: $error', name: 'MusicVisualizer');
    }
  }

  void _savePreferences() {
    final store = _store;
    if (store == null) return;
    _optionsRevision.value++;
    unawaited(store.savePreferences({
      'selected': _native.preset?.libraryPath,
      'original': widget.preset.name,
      'playlist': _playlist.take(2500).map((file) => file.libraryPath).toList(),
      'shuffle': _shuffle, 'locked': _locked, 'interval': _intervalSeconds,
      'quality': _resolutionScale < 1 ? 'low' : 'balanced',
    }).catchError((Object error) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Could not save visualization choices: $error')));
    }));
  }

  void _syncPresetTimer() {
    final enabled = !_locked && _native.active && _playlist.length > 1 && _appResumed &&
        !_reduceMotion && (_fullscreen || TickerMode.of(context)) && widget.service.isPlaying;
    if (!enabled) { _presetTimer?.cancel(); _presetTimer = null; return; }
    _presetTimer ??= Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
      if (_native.state == 'rendering') _stepPreset(1);
    });
  }

  Future<void> _selectPreset(VisualizerSelection selection) async {
    ++_preferenceGeneration; // A late restore must not replace a user selection.
    _playlist = selection.playlist;
    _syncTicker();
    await _native.load(selection.preset);
    if (!mounted) return;
    _savePreferences(); _syncTicker();
  }

  void _stepPreset(int direction) {
    if (!_native.active || _playlist.isEmpty) {
      widget.onPresetChanged(direction < 0 ? widget.preset.previous : widget.preset.next);
      return;
    }
    final current = _playlist.indexWhere((file) => file.id == _native.preset?.id);
    final offset = _shuffle && _playlist.length > 1 ? 1 + _random.nextInt(_playlist.length - 1) : direction;
    final index = (current + offset) % _playlist.length;
    unawaited(_selectPreset(VisualizerSelection(_playlist[index], _playlist)));
  }

  Future<void> _originalScenes() async {
    ++_preferenceGeneration;
    await _native.stop();
    if (mounted) { _savePreferences(); _syncTicker(); }
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
    final status = _native.active ? (_reduceMotion ? 'Reduced motion · visualization paused' : _native.statusLabel) : !_profileLoaded
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
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.devicePixelRatioOf(context) * _resolutionScale;
          if (!_fullscreen) _native.resize(constraints.maxWidth * scale, constraints.maxHeight * scale);
          return Stack(
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
            if (_native.hasFrame && _native.textureId != null && !_fullscreen)
              Positioned.fill(child: Texture(textureId: _native.textureId!, filterQuality: FilterQuality.low)),
            Positioned(top: 12, left: 12, right: 12, child: Align(alignment: Alignment.topLeft,
              child: _buildPresetControls(context, status))),
          ],
        ); }),
      ),
    );
  }

  Widget _buildPresetControls(BuildContext context, String status) {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(tk.radiusMd);
    final selectedName = _native.preset?.title ?? _presetName(widget.preset);
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
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusableButton(
                onPressed: () => _stepPreset(-1),
                child: IconButton(
                  tooltip: t.music.visualizerPreviousPreset,
                  onPressed: () => _stepPreset(-1),
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
                onPressed: () => _stepPreset(1),
                child: IconButton(
                  tooltip: t.music.visualizerNextPreset,
                  onPressed: () => _stepPreset(1),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  icon: const AppIcon(Symbols.chevron_right_rounded, fill: 1, size: 22),
                ),
              ),
              FocusableButton(
                onPressed: () => _showLibrary(context),
                child: IconButton(
                  tooltip: 'Browse and download presets',
                  onPressed: () => _showLibrary(context),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  icon: const AppIcon(Symbols.library_music_rounded, fill: 1, size: 20),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Visualization options',
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: _option,
                itemBuilder: (_) => [
                  if (_native.active) const PopupMenuItem(value: 'original', child: Text('Original scenes')),
                  if (_native.active) CheckedPopupMenuItem(value: 'lock', checked: _locked, child: const Text('Lock preset')),
                  if (_native.active) CheckedPopupMenuItem(value: 'shuffle', checked: _shuffle, child: const Text('Shuffle presets')),
                  if (_native.active) ...[
                    for (final seconds in [15, 30, 60, 120])
                      CheckedPopupMenuItem(value: 'interval:$seconds', checked: _intervalSeconds == seconds,
                        child: Text('Change every $seconds seconds')),
                    CheckedPopupMenuItem(value: 'quality', checked: _resolutionScale < 1, child: const Text('Lower resolution')),
                    const PopupMenuItem(value: 'retry', child: Text('Reload preset')),
                  ],
                  const PopupMenuItem(value: 'fullscreen', child: Text('Fullscreen')),
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }

  Future<void> _showLibrary(BuildContext context) async {
    final selection = await showModalBottomSheet<VisualizerSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VisualizerLibrarySheet(profileId: _profileId),
    );
    if (mounted && selection != null) await _selectPreset(selection);
  }

  void _option(String action) {
    if (action == 'original') { unawaited(_originalScenes()); return; }
    if (action == 'fullscreen') { unawaited(_showFullscreen()); return; }
    if (action == 'retry' && _native.preset != null) {
      unawaited(_selectPreset(VisualizerSelection(_native.preset!, _playlist))); return;
    }
    setState(() {
      if (action == 'lock') _locked = !_locked;
      if (action == 'shuffle') _shuffle = !_shuffle;
      if (action == 'quality') _resolutionScale = _resolutionScale < 1 ? 1 : 0.5;
      if (action.startsWith('interval:')) _intervalSeconds = int.parse(action.split(':').last);
    });
    _presetTimer?.cancel(); _presetTimer = null;
    _savePreferences(); _syncTicker();
  }

  Future<void> _showFullscreen() async {
    if (_fullscreen) return;
    setState(() => _fullscreen = true);
    _syncTicker();
    await showDialog<void>(context: context, useSafeArea: false, builder: (dialogContext) =>
      Dialog.fullscreen(child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(dialogContext),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _stepPreset(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _stepPreset(1),
        },
        child: Focus(autofocus: true, child: AnimatedBuilder(
          animation: Listenable.merge([_native, _optionsRevision]),
          builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
            final scale = MediaQuery.devicePixelRatioOf(context) * _resolutionScale;
            _native.resize(constraints.maxWidth * scale, constraints.maxHeight * scale);
            final tk = tokens(context);
            return Stack(fit: StackFit.expand, children: [
              if (_native.hasFrame && _native.textureId != null)
                Texture(textureId: _native.textureId!, filterQuality: FilterQuality.low)
              else CustomPaint(painter: MusicVisualizerPainter(frame: _frame, preset: widget.preset, profile: _profile,
                palette: MusicVisualizerPalette.fromTheme(accent: tk.accent, background: tk.bg,
                  surface: tk.surface, outline: tk.outline, preset: widget.preset))),
              SafeArea(child: Align(alignment: Alignment.topCenter, child: Padding(
                padding: const EdgeInsets.all(12), child: Row(children: [
                  Expanded(child: Align(alignment: Alignment.topLeft, child: _buildPresetControls(context,
                    _native.active ? _native.statusLabel : _presetName(widget.preset)))),
                  IconButton(tooltip: 'Exit fullscreen', onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.fullscreen_exit)),
                ]),
              ))),
            ]);
          }),
        )),
      )),
    );
    if (mounted) { setState(() => _fullscreen = false); _syncTicker(); }
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
