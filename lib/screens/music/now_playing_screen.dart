import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_theme.dart';
import '../../focus/focusable_action_bar.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_slider.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../media/lyrics.dart';
import '../../media/media_item.dart';
import '../../media/stepped_seek.dart';
import '../../media/media_server_client.dart';
import '../../mixins/context_menu_tap_mixin.dart';
import '../../services/device_performance.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_motion.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/formatters.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/music_navigation.dart';
import '../../utils/platform_detector.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/media_context_menu.dart';
import '../../widgets/music/lyrics_view.dart';
import '../../widgets/music/repeat_mode.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/overlay_sheet.dart';
import 'queue_sheet.dart';

/// Full-screen music player. Pushed via [openNowPlaying]; popping never
/// touches playback — audio continues under the mini-player.
///
/// Layouts: mobile portrait (big art / transport stack), desktop & landscape
/// (two-pane with an inline queue panel), and TV (full-bleed art with a
/// d-pad transport chain).
///
/// D-pad chain (TV): transport row autofocuses play/pause (LEFT/RIGHT rove,
/// edges trapped) · UP → seek bar (LEFT/RIGHT = ±10s with key-repeat
/// acceleration) · seek UP → ⋮ overflow · transport DOWN → utility row
/// (Lyrics, Queue) · Lyrics toggle focuses the lyrics pane (BACK/DOWN-out
/// returns to transport) · BACK pops. Focus is always a text-based
/// background fill.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with ContextMenuTapMixin<NowPlayingScreen>, SingleTickerProviderStateMixin {
  MusicPlaybackService? _service;
  StreamSubscription<Object>? _errorsSub;

  bool _showLyrics = false;
  final Map<String, Future<Lyrics?>> _lyricsCache = {};

  /// Key for getting a context below this screen's own OverlaySheetHost —
  /// the State's context sits ABOVE it, so sheet calls made with `context`
  /// would miss the host and fall back to a hostless modal sheet.
  final GlobalKey _overlayChildKey = GlobalKey();

  BuildContext get _sheetContext => _overlayChildKey.currentContext ?? context;

  /// Swipe-down-to-dismiss (mobile portrait). The offset feeds a
  /// ValueListenableBuilder-wrapped Transform so drag frames never rebuild
  /// the screen.
  final ValueNotifier<double> _dismissDrag = ValueNotifier<double>(0);
  late final AnimationController _dismissSettle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(_onDismissSettleTick);
  double _dismissSettleFrom = 0;

  final FocusNode _seekFocusNode = FocusNode(debugLabel: 'now_playing_seek');
  final FocusNode _overflowFocusNode = FocusNode(debugLabel: 'now_playing_overflow');
  final FocusNode _playPauseFocusNode = FocusNode(debugLabel: 'now_playing_play_pause');
  final FocusNode _lyricsPaneFocusNode = FocusNode(debugLabel: 'now_playing_lyrics_pane');
  final GlobalKey<FocusableActionBarState> _utilityBarKey = GlobalKey<FocusableActionBarState>();

  bool _poppedForIdle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<MusicPlaybackService>();
    if (service != _service) {
      _errorsSub?.cancel();
      _service = service;
      // Surface playback failures while the screen is open — the service
      // already recovers (skip / stop) by itself.
      _errorsSub = service.errors.listen((error) {
        if (mounted) showErrorSnackBar(context, t.messages.errorLoading(error: error.toString()));
      });
    }
  }

  @override
  void dispose() {
    _errorsSub?.cancel();
    _dismissSettle.dispose();
    _dismissDrag.dispose();
    _seekFocusNode.dispose();
    _overflowFocusNode.dispose();
    _playPauseFocusNode.dispose();
    _lyricsPaneFocusNode.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------

  Future<Lyrics?> _lyricsFutureFor(MediaItem track) =>
      _lyricsCache.putIfAbsent(track.globalKey, () => context.read<MusicPlaybackService>().fetchLyrics(track));

  void _toggleLyrics() {
    setState(() => _showLyrics = !_showLyrics);
    if (_showLyrics && InputModeTracker.isKeyboardMode(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showLyrics) _lyricsPaneFocusNode.requestFocus();
      });
    }
  }

  void _focusTransport() => _playPauseFocusNode.requestFocus();

  void _pop() => Navigator.pop(context);

  // Swipe-down anywhere above the transport controls closes the screen —
  // the standard music-player gesture. The content follows the finger;
  // releasing past the threshold pops (the route's reverse slide+fade
  // continues the motion from where the finger left off), otherwise the
  // content settles back.

  void _onDismissSettleTick() {
    _dismissDrag.value = _dismissSettleFrom * (1 - Curves.easeOutCubic.transform(_dismissSettle.value));
  }

  void _onDismissDragStart(DragStartDetails details) => _dismissSettle.stop();

  void _onDismissDragUpdate(DragUpdateDetails details) {
    _dismissDrag.value = math.max(0, _dismissDrag.value + details.delta.dy);
  }

  void _onDismissDragEnd(DragEndDetails details) {
    final offset = _dismissDrag.value;
    if (offset <= 0) return;
    // Same thresholds as the overlay sheet system's drag-to-dismiss.
    if (offset > MediaQuery.sizeOf(context).height * 0.25 || (details.primaryVelocity ?? 0) > 500) {
      _pop();
    } else {
      _onDismissDragCancel();
    }
  }

  void _onDismissDragCancel() {
    if (_dismissDrag.value <= 0) return;
    _dismissSettleFrom = _dismissDrag.value;
    _dismissSettle.forward(from: 0);
  }

  /// Artist line tap — the track's grandparent is the artist. Mirrors the
  /// album screen's artist link (fetch, then navigate; soft-fail).
  Future<void> _openArtist(MediaItem track) async {
    final artistId = track.grandparentId;
    final client = context.getMediaClientForItemOrNull(track);
    if (artistId == null || client == null) return;
    MediaItem? artist;
    try {
      artist = await client.fetchItem(artistId);
    } catch (e) {
      appLogger.w('Failed to fetch artist $artistId for track ${track.id}', error: e);
    }
    if (artist == null || !mounted) return;
    await navigateToArtist(context, artist);
  }

  Future<void> _showSleepTimerSheet() async {
    final service = context.read<MusicPlaybackService>();
    final timed = service.sleepTimerActive && !service.sleepTimerEndOfTrack;
    final selected = await OverlaySheetController.showAdaptive<String>(
      _sheetContext,
      showDragHandle: true,
      builder: (context) => AppMenuSheet<String>(
        title: t.music.sleepTimer,
        entries: [
          AppMenuItem(
            value: 'off',
            icon: Symbols.timer_off_rounded,
            label: t.common.off,
            selected: !service.sleepTimerActive,
          ),
          for (final minutes in const [15, 30, 60])
            AppMenuItem(
              value: '$minutes',
              icon: Symbols.timer_rounded,
              label: t.music.sleepTimerMinutes(n: minutes),
              selected: timed && service.sleepTimerDuration == Duration(minutes: minutes),
            ),
          AppMenuItem(
            value: 'end_of_track',
            icon: Symbols.music_note_rounded,
            label: t.music.sleepTimerEndOfTrack,
            selected: service.sleepTimerEndOfTrack,
          ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case 'off':
        service.setSleepTimer(null);
      case 'end_of_track':
        service.setSleepTimer(null, endOfTrack: true);
      default:
        final minutes = int.tryParse(selected);
        if (minutes != null) service.setSleepTimer(Duration(minutes: minutes));
    }
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final service = context.watch<MusicPlaybackService>();
    final track = service.currentTrack;

    if (track == null) {
      // Session ended elsewhere (stop / error / video claimed audio) — an
      // empty player is a dead end, leave the screen.
      if (!_poppedForIdle) {
        _poppedForIdle = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        });
      }
      return Scaffold(backgroundColor: tk.bg, body: const SizedBox.expand());
    }

    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(track.serverId));
    final isTV = PlatformDetector.isTV();

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        _Background(track: track, client: client, heavyScrim: isTV),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isTV) return _buildTvLayout(service, track, client);
              final twoPane = constraints.maxWidth >= 800 && constraints.maxWidth > constraints.maxHeight;
              return twoPane ? _buildWideLayout(service, track, client) : _buildPortraitLayout(service, track, client);
            },
          ),
        ),
      ],
    );

    if (PlatformDetector.isDesktopOS() && !isTV) {
      content = CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.space): () => unawaited(service.togglePlayPause())},
        child: FocusScope(child: Focus(autofocus: true, skipTraversal: true, child: content)),
      );
    }

    // Own OverlaySheetHost so the queue / sleep-timer sheets have a host on
    // TV; the host also owns system back (a back with a sheet open closes
    // the sheet, otherwise the route pops natively — audio continues).
    return OverlaySheetHost(
      canPop: true,
      child: Scaffold(
        key: _overlayChildKey,
        backgroundColor: tk.bg,
        body: ValueListenableBuilder<double>(
          valueListenable: _dismissDrag,
          builder: (context, offset, child) => Transform.translate(offset: Offset(0, offset), child: child),
          child: content,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Layouts
  // -------------------------------------------------------------------

  Widget _buildPortraitLayout(MusicPlaybackService service, MediaItem track, MediaServerClient? client) {
    Widget upper = Column(
      children: [
        _buildTopBar(track, service.playContext?.title),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildArtworkOrLyrics(service, track, client),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(32, 8, 32, 0), child: _buildTrackInfo(track, centered: true)),
      ],
    );
    // Touch only — desktop keeps mouse drags for text selection and the
    // lyrics pane. A drag starting on the lyrics scrollable still scrolls
    // (the descendant recognizer wins the arena).
    if (!PlatformDetector.isDesktopOS()) {
      upper = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onDismissDragStart,
        onVerticalDragUpdate: _onDismissDragUpdate,
        onVerticalDragEnd: _onDismissDragEnd,
        onVerticalDragCancel: _onDismissDragCancel,
        child: upper,
      );
    }
    return Column(
      children: [
        Expanded(child: upper),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _buildSeekBar()),
        _buildTransportRow(service),
        _buildUtilityRow(showQueueButton: true),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWideLayout(MusicPlaybackService service, MediaItem track, MediaServerClient? client) {
    final tk = tokens(context);
    return Column(
      children: [
        _buildTopBar(track, service.playContext?.title),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                Expanded(flex: 9, child: _buildArtworkOrLyrics(service, track, client)),
                const SizedBox(width: 32),
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      _buildTrackInfo(track, centered: false),
                      const SizedBox(height: 8),
                      _buildSeekBar(),
                      _buildWideControlBand(service),
                      const SizedBox(height: 12),
                      // Inline queue panel — same widget the queue sheet uses.
                      Expanded(
                        child: Material(
                          color: tk.bg.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(tk.radiusLg),
                          clipBehavior: Clip.antiAlias,
                          child: const QueueList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTvLayout(MusicPlaybackService service, MediaItem track, MediaServerClient? client) {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final playContextTitle = service.playContext?.title;
    final artist = track.trackArtistTitle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildArtworkOrLyrics(service, track, client, tvArt: true)),
          const SizedBox(width: 48),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: playContextTitle == null || playContextTitle.isEmpty
                          ? const SizedBox.shrink()
                          : Text(
                              t.music.playingFrom(title: playContextTitle),
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: TextStyle(fontSize: 14, color: tk.textMuted),
                            ),
                    ),
                    _buildOverflowButton(track, focusable: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  track.title ?? '',
                  maxLines: 2,
                  overflow: .ellipsis,
                  style: textTheme.headlineMedium?.copyWith(fontWeight: .w600, color: tk.text),
                ),
                if (artist != null && artist.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: textTheme.bodyLarge?.copyWith(color: tk.textMuted),
                  ),
                ],
                const SizedBox(height: 28),
                _buildSeekBar(),
                const SizedBox(height: 8),
                _buildTransportRow(service),
                _buildUtilityRow(showQueueButton: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Pieces
  // -------------------------------------------------------------------

  /// [playContextTitle] is passed in (not selected) because this builds
  /// inside the layout-phase LayoutBuilder, where `context.select` on the
  /// screen's element asserts; the screen already watches the service.
  Widget _buildTopBar(MediaItem track, String? playContextTitle) {
    final tk = tokens(context);
    // macOS pins the traffic lights at y=21 (16pt buttons → center 29, see
    // WindowUtilsPlugin.customButtonPositions); a fixed 58px row centers the
    // close button on that line regardless of the platform visual density
    // shrinking the IconButton box.
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, isMacOS ? 0 : 4, 8, 0),
      child: SizedBox(
        height: isMacOS ? 58 : null,
        child: Row(
          children: [
            // Inset past the macOS traffic lights — this screen is a fullscreen
            // route, so the close button would otherwise sit underneath them.
            DesktopAppBarHelper.buildAdjustedLeading(
              FocusableButton(
                onPressed: _pop,
                child: IconButton(
                  icon: AppIcon(Symbols.keyboard_arrow_down_rounded, fill: 1, color: tk.text),
                  tooltip: t.common.close,
                  onPressed: _pop,
                ),
              ),
              context: context,
            )!,
            Expanded(
              child: playContextTitle == null || playContextTitle.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      t.music.playingFrom(title: playContextTitle),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(fontSize: 13, color: tk.textMuted),
                    ),
            ),
            _buildOverflowButton(track),
          ],
        ),
      ),
    );
  }

  /// Wide-layout control band: the transport row stays exactly centered
  /// (equal-width flanks), with lyrics + a desktop volume slider as a
  /// right-aligned cluster that scales down instead of overflowing when the
  /// pane is narrow.
  Widget _buildWideControlBand(MusicPlaybackService service) {
    final tk = tokens(context);
    final colorScheme = Theme.of(context).colorScheme;

    final cluster = Row(
      mainAxisSize: .min,
      children: [
        FocusableButton(
          onPressed: _toggleLyrics,
          child: IconButton(
            icon: AppIcon(
              Symbols.lyrics_rounded,
              fill: 1,
              size: 22,
              color: _showLyrics ? colorScheme.primary : tk.textMuted,
            ),
            tooltip: t.music.lyrics,
            onPressed: _toggleLyrics,
          ),
        ),
        if (PlatformDetector.isDesktop(context)) ...[const SizedBox(width: 4), _buildVolumeCluster(service)],
      ],
    );

    return Row(
      children: [
        const Expanded(child: SizedBox()),
        _buildTransportRow(service),
        Expanded(
          child: Align(
            alignment: .centerRight,
            child: FittedBox(fit: BoxFit.scaleDown, child: cluster),
          ),
        ),
      ],
    );
  }

  /// Desktop volume control (0–100), persisted by the service across
  /// sessions. Mono styling matches the seek bar: text-colored active track
  /// on outline.
  Widget _buildVolumeCluster(MusicPlaybackService service) {
    return ValueListenableBuilder<double>(
      valueListenable: service.volumeListenable,
      builder: (context, volume, _) {
        final tk = tokens(context);
        final icon = volume <= 0
            ? Symbols.volume_off_rounded
            : volume < 50
            ? Symbols.volume_down_rounded
            : Symbols.volume_up_rounded;
        return Row(
          mainAxisSize: .min,
          children: [
            AppIcon(icon, fill: 1, size: 20, color: tk.textMuted),
            SizedBox(
              width: 140,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: tk.text,
                  inactiveTrackColor: tk.outline,
                  thumbColor: tk.text,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: FocusableSlider(
                  value: volume.clamp(0.0, 100.0),
                  max: 100,
                  onChanged: (value) => unawaited(service.setVolume(value, persist: false)),
                  onChangeEnd: (value) => unawaited(service.setVolume(value)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ⋮ — the current track's standard context menu plus the Sleep timer
  /// entry. On TV ([focusable]) it joins the d-pad chain above the seek bar.
  Widget _buildOverflowButton(MediaItem track, {bool focusable = false}) {
    final tk = tokens(context);
    void showMenu() => contextMenuKey.currentState?.showContextMenu(context);

    return MediaContextMenu(
      key: contextMenuKey,
      item: track,
      extraEntries: [
        MediaMenuExtraEntry(icon: Symbols.bedtime_rounded, label: t.music.sleepTimer, onSelected: _showSleepTimerSheet),
      ],
      child: FocusableButton(
        focusNode: focusable ? _overflowFocusNode : null,
        onPressed: showMenu,
        onNavigateDown: focusable ? _seekFocusNode.requestFocus : null,
        onNavigateUp: focusable ? () {} : null,
        onNavigateLeft: focusable ? () {} : null,
        onNavigateRight: focusable ? () {} : null,
        onBack: focusable ? _pop : null,
        useBackgroundFocus: focusable,
        child: IconButton(
          icon: AppIcon(Symbols.more_vert_rounded, fill: 1, color: tk.text),
          onPressed: showMenu,
          tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        ),
      ),
    );
  }

  Widget _buildTrackInfo(MediaItem track, {required bool centered}) {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final artist = track.trackArtistTitle;

    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          track.title ?? '',
          maxLines: 1,
          overflow: .ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: textTheme.headlineSmall?.copyWith(fontWeight: .w600, color: tk.text),
        ),
        if (artist != null && artist.isNotEmpty)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => unawaited(_openArtist(track)),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  artist,
                  maxLines: 1,
                  overflow: .ellipsis,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildArtworkOrLyrics(
    MusicPlaybackService service,
    MediaItem track,
    MediaServerClient? client, {
    bool tvArt = false,
  }) {
    return AnimatedSwitcher(
      duration: MonoMotion.fill(context),
      child: _showLyrics
          ? KeyedSubtree(
              key: const ValueKey('now_playing_lyrics'),
              child: LyricsView(
                lyricsFuture: _lyricsFutureFor(track),
                focusNode: _lyricsPaneFocusNode,
                onExit: _focusTransport,
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('now_playing_art'),
              child: _Artwork(track: track, client: client, tvSized: tvArt),
            ),
    );
  }

  Widget _buildSeekBar() {
    return _NowPlayingSeekBar(
      focusNode: _seekFocusNode,
      onNavigateUp: PlatformDetector.isTV() ? _overflowFocusNode.requestFocus : null,
      onNavigateDown: _focusTransport,
      onBack: _pop,
    );
  }

  /// One transport icon with the shared text-fill focus pill.
  Widget _transportIcon(
    FocusableActionBuildState state, {
    required IconData icon,
    required VoidCallback onPressed,
    bool active = true,
    String? tooltip,
    double size = 26,
  }) {
    final tk = tokens(context);
    return AnimatedContainer(
      duration: state.animationDuration,
      decoration: FocusTheme.textFillFocusDecoration(
        context,
        isFocused: state.showFocus,
        borderRadius: MonoTokens.radiusFull,
      ),
      child: IconButton(
        icon: AppIcon(icon, fill: 1, size: size, color: active ? tk.text : tk.textMuted),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTransportRow(MusicPlaybackService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        // Scale down instead of overflowing when the hosting column is
        // narrower than the row's intrinsic width (e.g. TV layout on a
        // narrow display or a small desktop window).
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: FocusableActionBar(
            spacing: 8,
            onNavigateUp: _seekFocusNode.requestFocus,
            onNavigateDown: () => _utilityBarKey.currentState?.requestFocusOnFirst(),
            onBack: _pop,
            actions: [
              FocusableAction(
                debugLabel: 'np_shuffle',
                onPressed: service.toggleShuffle,
                builder: (context, state) => _transportIcon(
                  state,
                  icon: Symbols.shuffle_rounded,
                  active: service.shuffled,
                  tooltip: t.common.shuffle,
                  onPressed: service.toggleShuffle,
                  size: 22,
                ),
              ),
              FocusableAction(
                debugLabel: 'np_previous',
                onPressed: () => unawaited(service.previous()),
                builder: (context, state) => _transportIcon(
                  state,
                  icon: Symbols.skip_previous_rounded,
                  tooltip: t.music.previousTrack,
                  onPressed: () => unawaited(service.previous()),
                  size: 32,
                ),
              ),
              FocusableAction(
                debugLabel: 'np_play_pause',
                focusNode: _playPauseFocusNode,
                autofocus: PlatformDetector.isTV(),
                onPressed: () => unawaited(service.togglePlayPause()),
                builder: (context, state) =>
                    _PlayPauseButton(state: state, onPressed: () => unawaited(service.togglePlayPause())),
              ),
              FocusableAction(
                debugLabel: 'np_next',
                onPressed: () => unawaited(service.next()),
                builder: (context, state) => _transportIcon(
                  state,
                  icon: Symbols.skip_next_rounded,
                  tooltip: t.music.nextTrack,
                  onPressed: () => unawaited(service.next()),
                  size: 32,
                ),
              ),
              FocusableAction(
                debugLabel: 'np_repeat',
                onPressed: () => service.setRepeatMode(nextRepeatMode(service.repeatMode)),
                builder: (context, state) => _transportIcon(
                  state,
                  icon: repeatModeIcon(service.repeatMode),
                  active: service.repeatMode != MusicRepeatMode.off,
                  tooltip: repeatModeLabel(service.repeatMode),
                  onPressed: () => service.setRepeatMode(nextRepeatMode(service.repeatMode)),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityRow({required bool showQueueButton}) {
    return Center(
      child: FocusableActionBar(
        key: _utilityBarKey,
        spacing: 16,
        onNavigateUp: _focusTransport,
        // Bottom of the chain — trap DOWN so focus can't escape the screen.
        // ignore: no-empty-block
        onNavigateDown: () {},
        onBack: _pop,
        actions: [
          FocusableAction(
            debugLabel: 'np_lyrics',
            onPressed: _toggleLyrics,
            builder: (context, state) => _transportIcon(
              state,
              icon: Symbols.lyrics_rounded,
              active: _showLyrics,
              tooltip: t.music.lyrics,
              onPressed: _toggleLyrics,
              size: 22,
            ),
          ),
          if (showQueueButton)
            FocusableAction(
              debugLabel: 'np_queue',
              onPressed: () => unawaited(showQueueSheet(_sheetContext)),
              builder: (context, state) => _transportIcon(
                state,
                icon: Symbols.queue_music_rounded,
                active: false,
                tooltip: t.music.queue,
                onPressed: () => unawaited(showQueueSheet(_sheetContext)),
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Artwork
// ---------------------------------------------------------------------

/// Square artwork with the M3E pause shape-morph: large-radius while
/// playing, ~28 when paused.
class _Artwork extends StatelessWidget {
  final MediaItem track;
  final MediaServerClient? client;

  /// TV sizes the art off the screen height instead of hugging width.
  final bool tvSized;

  const _Artwork({required this.track, required this.client, required this.tvSized});

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final isPlaying = context.select<MusicPlaybackService, bool>((s) => s.isPlaying);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = tvSized
            ? math.min(constraints.maxWidth, constraints.maxHeight * 0.62)
            : math.min(constraints.maxWidth * 0.85, constraints.maxHeight);
        if (side <= 0 || !side.isFinite) return const SizedBox.shrink();
        return Center(
          child: AnimatedContainer(
            duration: MonoMotion.shape(context),
            curve: MonoMotion.emphasized,
            width: side,
            height: side,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(isPlaying ? tk.radiusLg : 28)),
            child: OptimizedMediaImage(
              client: client,
              imagePath: track.thumbPath,
              imageType: ImageType.square,
              width: side,
              height: side,
              fallbackIcon: Symbols.music_note_rounded,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------

/// Blurred album art at low opacity under a bg scrim. Skipped entirely on
/// the reduced performance tier (plain background).
class _Background extends StatelessWidget {
  final MediaItem track;
  final MediaServerClient? client;
  final bool heavyScrim;

  const _Background({required this.track, required this.client, required this.heavyScrim});

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    if (DevicePerformance.isReduced || track.thumbPath == null) {
      return ColoredBox(color: tk.bg);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tk.bg),
        Opacity(
          opacity: heavyScrim ? 0.22 : 0.3,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.mirror),
            child: OptimizedMediaImage(
              client: client,
              imagePath: track.thumbPath,
              imageType: ImageType.square,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Play / pause morph button
// ---------------------------------------------------------------------

/// 72px inverse-surface button: circle while paused, rounded square while
/// playing (M3E shape morph). Focus reads through the action bar's dimming
/// plus a small scale.
class _PlayPauseButton extends StatelessWidget {
  final FocusableActionBuildState state;
  final VoidCallback onPressed;

  const _PlayPauseButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying = context.select<MusicPlaybackService, bool>((s) => s.isPlaying);
    final isLoading = context.select<MusicPlaybackService, bool>((s) => s.status == MusicPlaybackStatus.loading);

    return AnimatedScale(
      scale: state.showFocus ? 1.08 : 1.0,
      duration: state.animationDuration,
      child: AnimatedContainer(
        duration: MonoMotion.shape(context),
        curve: MonoMotion.emphasized,
        width: 72,
        height: 72,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(isPlaying ? tk.radiusLg + 4 : 36),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.onInverseSurface),
                    )
                  : AppIcon(
                      isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                      fill: 1,
                      size: 36,
                      color: colorScheme.onInverseSurface,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Seek bar
// ---------------------------------------------------------------------

/// Thin mono slider driven by the position stream — an isolated widget so
/// per-second ticks never rebuild the screen. The thumb only appears while
/// dragging. As a d-pad region, LEFT/RIGHT seek ±10s with the video
/// timeline's stepped key-repeat acceleration; focus renders as a
/// text-based background pill behind the bar.
class _NowPlayingSeekBar extends StatefulWidget {
  final FocusNode focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback onBack;

  const _NowPlayingSeekBar({
    required this.focusNode,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onBack,
  });

  @override
  State<_NowPlayingSeekBar> createState() => _NowPlayingSeekBarState();
}

class _NowPlayingSeekBarState extends State<_NowPlayingSeekBar> {
  static const int _baseStepMs = 10000;

  double? _dragValueMs;
  bool _focused = false;

  int _seekRepeatCount = 0;
  LogicalKeyboardKey? _seekDirection;
  late final DebouncedSeekAccumulator _keySeek;

  @override
  void initState() {
    super.initState();
    _keySeek = DebouncedSeekAccumulator(
      currentPosition: () => context.read<MusicPlaybackService>().position,
      duration: () => context.read<MusicPlaybackService>().duration ?? Duration.zero,
      seek: (target) => unawaited(context.read<MusicPlaybackService>().seek(target)),
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _keySeek.dispose();
    super.dispose();
  }

  void _resetSeekState() {
    _seekRepeatCount = 0;
    _seekDirection = null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyUpEvent && (key.isLeftKey || key.isRightKey)) {
      _keySeek.flush();
      _resetSeekState();
      return KeyEventResult.handled;
    }

    final backResult = handleBackKeyAction(event, widget.onBack);
    if (backResult != KeyEventResult.ignored) return backResult;

    if (!event.isActionable) return KeyEventResult.ignored;

    if (key.isUpKey) {
      if (widget.onNavigateUp == null) return KeyEventResult.handled; // trap
      widget.onNavigateUp!();
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      widget.onNavigateDown?.call();
      return KeyEventResult.handled;
    }

    if (key.isLeftKey || key.isRightKey) {
      final service = context.read<MusicPlaybackService>();
      final duration = service.duration;
      if (duration == null || duration.inMilliseconds <= 0) return KeyEventResult.handled;

      if (_seekDirection != key) {
        _seekDirection = key;
        _seekRepeatCount = 0;
      }
      if (event is KeyRepeatEvent) _seekRepeatCount++;
      final multiplier = event is KeyRepeatEvent ? steppedSeekMultiplier(_seekRepeatCount) : 1.0;
      final stepMs = (_baseStepMs * multiplier).round();

      final step = Duration(milliseconds: stepMs);
      _keySeek.seekBy(key.isRightKey ? step : -step);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final service = context.read<MusicPlaybackService>();
    final showFocus = _focused && InputModeTracker.isKeyboardMode(context);

    final bar = StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, snapshot) {
        final duration = service.duration ?? Duration.zero;
        final durationMs = duration.inMilliseconds.toDouble();
        final hasDuration = durationMs > 0;
        final rawPositionMs =
            _dragValueMs ??
            _keySeek.pendingPosition?.inMilliseconds.toDouble() ??
            (snapshot.data ?? service.position).inMilliseconds.toDouble();
        final positionMs = hasDuration ? rawPositionMs.clamp(0.0, durationMs) : 0.0;
        final dragging = _dragValueMs != null;

        return Column(
          mainAxisSize: .min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: tk.text,
                inactiveTrackColor: tk.outline,
                thumbColor: tk.text,
                trackGap: dragging ? 4 : 0,
                thumbSize: const WidgetStatePropertyAll(Size(4, 18)),
                thumbShape: dragging ? null : SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                max: hasDuration ? durationMs : 1,
                value: positionMs,
                onChangeStart: hasDuration
                    ? (value) {
                        _keySeek.cancel();
                        setState(() => _dragValueMs = value);
                      }
                    : null,
                onChanged: hasDuration ? (value) => setState(() => _dragValueMs = value) : null,
                onChangeEnd: hasDuration
                    ? (value) {
                        unawaited(service.seek(Duration(milliseconds: value.round())));
                        setState(() => _dragValueMs = null);
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
              child: Row(
                children: [
                  Text(
                    formatDurationTimestamp(Duration(milliseconds: positionMs.round())),
                    style: TextStyle(fontSize: 12, color: tk.textMuted),
                  ),
                  const Spacer(),
                  Text(formatDurationTimestamp(duration), style: TextStyle(fontSize: 12, color: tk.textMuted)),
                ],
              ),
            ),
          ],
        );
      },
    );

    return Focus(
      focusNode: widget.focusNode,
      descendantsAreFocusable: false,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          _keySeek.flush();
          _resetSeekState();
        }
        setState(() => _focused = hasFocus);
      },
      child: AnimatedContainer(
        duration: FocusTheme.getAnimationDuration(context),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: FocusTheme.textFillFocusDecoration(context, isFocused: showFocus, borderRadius: tk.radiusLg),
        child: bar,
      ),
    );
  }
}
