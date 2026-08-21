import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focus_theme.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../media/lyrics.dart';
import '../../screens/libraries/state_messages.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';

/// Lyrics pane for the now-playing screen (swapped in over the artwork).
///
/// Synced lyrics highlight the active line from the service's
/// [MusicPlaybackService.positionStream] (binary search over line offsets)
/// and auto-center it; auto-centering pauses for a few seconds after the
/// user scrolls manually. Tapping a synced line seeks to it.
///
/// D-pad model (when [focusNode] is provided): the pane is ONE focusable
/// region. UP/DOWN move a focused-line highlight (synced) or scroll by lines
/// (unsynced), SELECT seeks to the focused line, BACK — or DOWN past the last
/// line — calls [onExit] so the host returns focus to the transport row.
class LyricsView extends StatefulWidget {
  /// Resolved lazily by the host (which caches per track).
  final Future<Lyrics?> lyricsFuture;

  /// Focus node for the pane region — omit on touch-only layouts.
  final FocusNode? focusNode;

  /// Called on BACK / DOWN-out so the host can move focus back to transport.
  final VoidCallback? onExit;

  const LyricsView({super.key, required this.lyricsFuture, this.focusNode, this.onExit});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  static const Duration _manualScrollHold = Duration(seconds: 3);
  static const double _unsyncedScrollStep = 64;

  final ScrollController _scroll = ScrollController();

  Lyrics? _lyrics;
  bool _loading = true;
  List<GlobalKey> _lineKeys = const [];

  StreamSubscription<Duration>? _positionSub;
  int _activeIndex = -1;
  DateTime? _manualScrollAt;

  bool _paneFocused = false;
  int _focusedLine = 0;

  @override
  void initState() {
    super.initState();
    _resolve(widget.lyricsFuture);
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lyricsFuture != oldWidget.lyricsFuture) {
      setState(() {
        _lyrics = null;
        _loading = true;
        _activeIndex = -1;
        _focusedLine = 0;
        _lineKeys = const [];
      });
      _resolve(widget.lyricsFuture);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _positionSub ??= context.read<MusicPlaybackService>().positionStream.listen(_onPosition);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _resolve(Future<Lyrics?> future) {
    future
        .then((lyrics) {
          if (!mounted || widget.lyricsFuture != future) return;
          setState(() {
            _lyrics = lyrics;
            _loading = false;
            _lineKeys = List.generate(lyrics?.lines.length ?? 0, (_) => GlobalKey());
          });
          // Jump straight to the current line on open.
          _onPosition(context.read<MusicPlaybackService>().position, animate: false);
        })
        .catchError((Object _) {
          if (!mounted || widget.lyricsFuture != future) return;
          setState(() {
            _lyrics = null;
            _loading = false;
          });
        });
  }

  /// Last line whose startMs <= position (binary search; lines without a
  /// start offset never become active).
  int _activeIndexFor(Duration position) {
    final lines = _lyrics?.lines;
    if (lines == null || lines.isEmpty) return -1;
    final ms = position.inMilliseconds;
    var lo = 0, hi = lines.length - 1, best = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final start = lines[mid].startMs;
      if (start == null) {
        // Rare unsynced holes: scan linearly around them.
        break;
      }
      if (start <= ms) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (lo <= hi) {
      // Fallback linear pass for mixed-sync content.
      best = -1;
      for (var i = 0; i < lines.length; i++) {
        final start = lines[i].startMs;
        if (start != null && start <= ms) best = i;
      }
    }
    return best;
  }

  void _onPosition(Duration position, {bool animate = true}) {
    final lyrics = _lyrics;
    if (lyrics == null || !lyrics.synced) return;
    final index = _activeIndexFor(position);
    if (index == _activeIndex) return;
    setState(() {
      _activeIndex = index;
      if (!_paneFocused) _focusedLine = index < 0 ? 0 : index;
    });
    if (index >= 0) _revealLine(index, animate: animate);
  }

  bool get _autoScrollSuppressed {
    final at = _manualScrollAt;
    return at != null && DateTime.now().difference(at) < _manualScrollHold;
  }

  void _revealLine(int index, {bool animate = true, bool force = false}) {
    if (!force && _autoScrollSuppressed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _lineKeys.length) return;
      final lineContext = _lineKeys[index].currentContext;
      if (lineContext == null) return;
      Scrollable.ensureVisible(
        lineContext,
        alignment: 0.4,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final isUserDrag =
        (notification is ScrollStartNotification && notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification && notification.dragDetails != null);
    if (isUserDrag) _manualScrollAt = DateTime.now();
    return false;
  }

  void _seekTo(LyricLine line) {
    final startMs = line.startMs;
    if (startMs == null) return;
    unawaited(context.read<MusicPlaybackService>().seek(Duration(milliseconds: startMs)));
  }

  // -------------------------------------------------------------------
  // D-pad
  // -------------------------------------------------------------------

  void _moveFocusedLine(int delta) {
    final lyrics = _lyrics;
    if (lyrics == null || lyrics.lines.isEmpty) return;
    if (!lyrics.synced) {
      // Unsynced: scroll by lines instead of tracking a highlight.
      if (!_scroll.hasClients) return;
      final target = (_scroll.offset + delta * _unsyncedScrollStep).clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      );
      unawaited(_scroll.animateTo(target, duration: const Duration(milliseconds: 150), curve: Curves.easeOutCubic));
      return;
    }
    final next = _focusedLine + delta;
    if (next >= lyrics.lines.length) {
      widget.onExit?.call();
      return;
    }
    if (next < 0) return;
    setState(() => _focusedLine = next);
    _revealLine(next, force: true);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final onExit = widget.onExit;
    if (onExit != null) {
      final backResult = handleBackKeyAction(event, onExit);
      if (backResult != KeyEventResult.ignored) return backResult;
    }
    return dpadKeyHandler(
      onUp: () => _moveFocusedLine(-1),
      onDown: () => _moveFocusedLine(1),
      onSelect: () {
        final lyrics = _lyrics;
        if (lyrics == null || !lyrics.synced) return;
        if (_focusedLine >= 0 && _focusedLine < lyrics.lines.length) _seekTo(lyrics.lines[_focusedLine]);
      },
      trapHorizontalEdges: true,
    )(node, event);
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tk.textMuted));
    }
    final lyrics = _lyrics;
    if (lyrics == null || lyrics.isEmpty) {
      return StateMessageWidget(icon: Symbols.lyrics_rounded, message: t.music.noLyrics, iconSize: 48);
    }

    final showFocus = _paneFocused && InputModeTracker.isKeyboardMode(context);

    final Widget list = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            for (var i = 0; i < lyrics.lines.length; i++) _buildLine(context, lyrics, i, showFocus: showFocus),
          ],
        ),
      ),
    );

    final focusNode = widget.focusNode;
    if (focusNode == null) return list;
    return Focus(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (hasFocus) => setState(() {
        _paneFocused = hasFocus;
        if (hasFocus && _activeIndex >= 0) _focusedLine = _activeIndex;
      }),
      child: list,
    );
  }

  Widget _buildLine(BuildContext context, Lyrics lyrics, int index, {required bool showFocus}) {
    final tk = tokens(context);
    final line = lyrics.lines[index];
    final isActive = lyrics.synced && index == _activeIndex;
    final isFocusedLine = showFocus && lyrics.synced && index == _focusedLine;

    final text = Text(
      line.text.isEmpty ? '…' : line.text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        height: 1.4,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive || !lyrics.synced ? tk.text : tk.textMuted,
      ),
    );

    return KeyedSubtree(
      key: _lineKeys[index],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: lyrics.synced && line.startMs != null ? () => _seekTo(line) : null,
        child: AnimatedContainer(
          duration: tk.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // Focus renders as a text-based background fill (mono convention).
          decoration: FocusTheme.textFillFocusDecoration(context, isFocused: isFocusedLine, borderRadius: tk.radiusSm),
          child: text,
        ),
      ),
    );
  }
}
