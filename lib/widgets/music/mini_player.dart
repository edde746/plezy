import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../mixins/context_menu_tap_mixin.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_motion.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/music_navigation.dart';
import '../../utils/platform_detector.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/video_player_navigation.dart';
import '../media_context_menu.dart';
import '../optimized_media_image.dart';
import '../overlay_sheet.dart';

/// Suppresses the mini-player while the top PAGE route of the profile
/// navigator is a full-screen playback surface (the video player or the
/// now-playing screen). Popup routes (dialogs, menus) riding on top are
/// skipped when resolving the "top" — a menu over now-playing must not
/// resurface the mini-player, while a detail screen pushed above it must.
///
/// Registered on the profile navigator's `observers` list by
/// `profile_session_screen.dart` and provided to [MusicMiniPlayerOverlay].
class MusicUiRouteObserver extends NavigatorObserver {
  /// True while the mini-player should stay hidden for route reasons.
  final ValueNotifier<bool> suppress = ValueNotifier<bool>(false);

  final List<Route<dynamic>> _stack = [];

  static bool _isSuppressingRoute(Route<dynamic> route) {
    final name = route.settings.name;
    return name == kVideoPlayerRouteName || name == kNowPlayingRouteName;
  }

  void _recompute() {
    var suppressing = false;
    for (var i = _stack.length - 1; i >= 0; i--) {
      final route = _stack[i];
      if (route is PopupRoute) continue;
      suppressing = _isSuppressingRoute(route);
      break;
    }
    suppress.value = suppressing;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _recompute();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _recompute();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _recompute();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute != null) {
        _stack[index] = newRoute;
      } else {
        _stack.removeAt(index);
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _recompute();
  }
}

/// Coordinates the mini-player's vertical placement with the shell:
/// - [MainScreen] reports its measured mobile bottom-bar height (and zeroes
///   it while a pushed detail route covers the bar) so the overlay floats
///   above the true bottom edge;
/// - the overlay reports back [overlayHeight] so music screens can pad their
///   scroll views and keep the last rows reachable.
class MiniPlayerInsetController extends ChangeNotifier {
  double _navBarInset = 0;
  bool _navBarSuspended = false;
  double _overlayHeight = 0;

  /// Height of the mobile bottom navigation area the mini-player must clear;
  /// 0 while a pushed route covers it (safe-area padding takes over).
  double get bottomInset => _navBarSuspended ? 0 : _navBarInset;

  /// Total vertical space the visible mini-player occupies (card + gaps).
  /// 0 while hidden. Music screens add this to their scroll bottom padding.
  double get overlayHeight => _overlayHeight;

  void setNavBarInset(double value) {
    if (_navBarInset == value) return;
    _navBarInset = value;
    notifyListeners();
  }

  /// Zero the nav-bar inset while a pushed route covers the bottom bar
  /// (MainScreen's RouteAware didPushNext/didPopNext).
  void setNavBarSuspended(bool value) {
    if (_navBarSuspended == value) return;
    _navBarSuspended = value;
    notifyListeners();
  }

  void setOverlayHeight(double value) {
    if (_overlayHeight == value) return;
    _overlayHeight = value;
    notifyListeners();
  }
}

/// Persistent floating music mini-player, mounted ABOVE the profile
/// navigator (see `profile_session_screen.dart`) so it survives route
/// changes. Never rendered on TV — the rail's Now Playing item and the
/// auto-pushed now-playing screen cover that surface.
class MusicMiniPlayerOverlay extends StatefulWidget {
  const MusicMiniPlayerOverlay({super.key});

  @override
  State<MusicMiniPlayerOverlay> createState() => _MusicMiniPlayerOverlayState();
}

class _MusicMiniPlayerOverlayState extends State<MusicMiniPlayerOverlay> {
  static const double _cardHeight = 64;
  static final ValueNotifier<bool> _noSuppression = ValueNotifier<bool>(false);

  /// Last non-null track, so the exit animation still has content to show.
  MediaItem? _lastTrack;

  /// Optimistically hides the card the instant a swipe-dismiss lands —
  /// `stop()` tears the audio core down asynchronously and the Dismissible
  /// must leave the tree before that completes.
  bool _dismissed = false;

  void _reportOverlayHeight(double height) {
    final controller = context.read<MiniPlayerInsetController?>();
    if (controller == null || controller.overlayHeight == height) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.setOverlayHeight(height);
    });
  }

  void _handleDismissed() {
    setState(() => _dismissed = true);
    unawaited(context.read<MusicPlaybackService>().stop());
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformDetector.isTV()) return const SizedBox.shrink();

    final track = context.select<MusicPlaybackService, MediaItem?>((s) => s.currentTrack);
    if (track == null) {
      _dismissed = false;
    } else if (_lastTrack != null && track.globalKey != _lastTrack!.globalKey) {
      _dismissed = false;
    }
    if (track != null) _lastTrack = track;

    // Nothing has ever played this session — skip the whole overlay tree
    // (also keeps barren test shells without MonoTokens happy).
    if (_lastTrack == null) return const SizedBox.shrink();

    final suppress = context.read<MusicUiRouteObserver?>()?.suppress ?? _noSuppression;
    final openSheets = OverlaySheetController.openSheetCount;
    return ListenableBuilder(
      listenable: Listenable.merge([suppress, openSheets]),
      builder: (context, _) {
        final hasSession = track != null && !suppress.value && !_dismissed;
        // Sheets render inside the routes' subtrees, BELOW this overlay —
        // hide the card while any sheet is up so it never floats over one.
        final visible = hasSession && openSheets.value == 0;
        final useSideNav = PlatformDetector.shouldUseSideNavigation(context);
        // Report off the session (not sheet) state so the underlying
        // screen's scroll padding doesn't jump while a sheet is open.
        _reportOverlayHeight(hasSession ? _cardHeight + (useSideNav ? 32 : 24) : 0);

        final Widget child = visible
            ? _MiniPlayerCard(
                key: const ValueKey('mini_player_card'),
                track: track,
                desktop: useSideNav,
                onDismissed: _handleDismissed,
              )
            : const SizedBox.shrink(key: ValueKey('mini_player_hidden'));

        final switcher = AnimatedSwitcher(
          duration: MonoMotion.shape(context),
          switchInCurve: MonoMotion.emphasized,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: child,
        );

        if (useSideNav) {
          return Stack(children: [Positioned(right: 16, bottom: 16, width: 380, child: switcher)]);
        }

        final inset = context.select<MiniPlayerInsetController?, double>((c) => c?.bottomInset ?? 0);
        final bottom = 12 + (inset > 0 ? inset : MediaQuery.paddingOf(context).bottom);
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: 12,
              right: 12,
              bottom: bottom,
              child: switcher,
            ),
          ],
        );
      },
    );
  }
}

/// The floating card itself. Takes [track] as data (instead of watching the
/// service) so the AnimatedSwitcher's exit snapshot never renders against a
/// cleared session.
class _MiniPlayerCard extends StatefulWidget {
  final MediaItem track;
  final bool desktop;
  final VoidCallback onDismissed;

  const _MiniPlayerCard({super.key, required this.track, required this.desktop, required this.onDismissed});

  @override
  State<_MiniPlayerCard> createState() => _MiniPlayerCardState();
}

class _MiniPlayerCardState extends State<_MiniPlayerCard> with ContextMenuTapMixin<_MiniPlayerCard> {
  final _detailsFocusNode = FocusNode(debugLabel: 'mini_player_details');
  final _transportKey = GlobalKey<FocusableActionBarState>();

  @override
  void dispose() {
    _detailsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final service = context.read<MusicPlaybackService>();
    final isPlaying = context.select<MusicPlaybackService, bool>((s) => s.isPlaying);
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.track.serverId));
    final artist = widget.track.trackArtistTitle;

    Widget card = Material(
      color: tk.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(tk.radiusLg),
      child: InkWell(
        canRequestFocus: false,
        mouseCursor: SystemMouseCursors.click,
        onTap: () => unawaited(openNowPlaying(context)),
        onTapDown: storeTapPosition,
        onLongPress: showContextMenuFromTap,
        onSecondaryTapDown: storeTapPosition,
        onSecondaryTap: showContextMenuFromTap,
        child: SizedBox(
          height: _MusicMiniPlayerOverlayState._cardHeight,
          child: Stack(
            children: [
              const Positioned.fill(child: _MiniPlayerProgress()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FocusableWrapper(
                        focusNode: _detailsFocusNode,
                        onSelect: () => unawaited(openNowPlaying(context)),
                        enableLongPress: true,
                        onLongPress: showContextMenu,
                        onNavigateRight: () => _transportKey.currentState?.requestFocusOnFirst(),
                        semanticLabel: widget.track.title,
                        descendantsAreFocusable: false,
                        disableScale: true,
                        useBackgroundFocus: true,
                        borderRadius: tk.radiusLg,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(tk.radiusSm),
                              child: OptimizedMediaImage(
                                client: client,
                                imagePath: widget.track.thumbPath,
                                imageType: ImageType.square,
                                width: 48,
                                height: 48,
                                fallbackIcon: Symbols.music_note_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: .center,
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    widget.track.title ?? '',
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                    style: TextStyle(fontSize: 14, fontWeight: .w600, color: tk.text),
                                  ),
                                  if (artist != null && artist.isNotEmpty)
                                    Text(
                                      artist,
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                      style: TextStyle(fontSize: 12, color: tk.textMuted),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FocusableActionBar(
                      key: _transportKey,
                      onNavigateLeft: _detailsFocusNode.requestFocus,
                      actions: [
                        if (widget.desktop)
                          FocusableAction(
                            icon: Symbols.skip_previous_rounded,
                            iconColor: tk.text,
                            tooltip: t.music.previousTrack,
                            onPressed: () => unawaited(service.previous()),
                          ),
                        FocusableAction(
                          icon: isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                          iconColor: tk.text,
                          tooltip: isPlaying ? t.common.pause : t.common.play,
                          onPressed: () => unawaited(service.togglePlayPause()),
                        ),
                        FocusableAction(
                          icon: Symbols.skip_next_rounded,
                          iconColor: tk.text,
                          tooltip: t.music.nextTrack,
                          onPressed: () => unawaited(service.next()),
                        ),
                        if (widget.desktop)
                          FocusableAction(
                            icon: Symbols.close_rounded,
                            iconColor: tk.textMuted,
                            iconSize: 20,
                            tooltip: t.music.stopPlayback,
                            onPressed: widget.onDismissed,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tk.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: card,
    );

    card = MediaContextMenu(key: contextMenuKey, item: widget.track, child: card);

    card = Dismissible(
      key: const ValueKey('mini_player_dismiss'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => widget.onDismissed(),
      child: card,
    );

    return card;
  }
}

/// Isolated progress leaf — positionStream ticks rebuild only this
/// background layer, never the card content above it. The played fraction
/// renders as a subtle full-height tint that fills the card left-to-right.
class _MiniPlayerProgress extends StatelessWidget {
  const _MiniPlayerProgress();

  @override
  Widget build(BuildContext context) {
    final service = context.read<MusicPlaybackService>();
    final tk = tokens(context);
    return StreamBuilder<Duration>(
      stream: service.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? service.position;
        final durationMs = service.duration?.inMilliseconds ?? 0;
        final fraction = durationMs <= 0 ? 0.0 : (position.inMilliseconds / durationMs).clamp(0.0, 1.0);
        return Align(
          alignment: .centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            heightFactor: 1,
            child: ColoredBox(color: tk.text.withValues(alpha: 0.08)),
          ),
        );
      },
    );
  }
}
