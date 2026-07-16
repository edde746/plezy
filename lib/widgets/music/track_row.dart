import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_tile_mixin.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import '../../media/media_item.dart';
import '../../mixins/context_menu_tap_mixin.dart';
import '../../models/download_models.dart';
import '../../providers/download_provider.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/formatters.dart';
import '../app_icon.dart';
import '../download_status_icon.dart';
import '../media_context_menu.dart';
import 'equalizer_icon.dart';

/// List row for a music track:
/// `[track # | equalizer] [title + optional artist] [duration] [⋮]`.
///
/// Rows sit inside the M3E grouped-card idiom (see `SettingsGroup`):
/// [isFirst]/[isLast] pick large outer / small inner corner radii, and the
/// hosting list inserts `tokens.groupGap` between adjacent rows.
///
/// D-pad model: one focus node with two columns — column 0 is the row itself
/// (SELECT = [onTap]), RIGHT moves the highlight to the ⋮ button (LEFT
/// returns; SELECT there opens the same context menu as long-press /
/// right-click). Focus is rendered as a background fill, never an outline.
class TrackRow extends StatefulWidget {
  /// Fixed row height, sized for title + optional subtitle.
  static const double height = 56;

  final MediaItem item;
  final VoidCallback? onTap;
  final void Function(MediaItem source)? onRefresh;

  /// Grouped-card corner shaping (see class doc).
  final bool isFirst;
  final bool isLast;

  /// Always show the performing-artist subtitle — for surfaces outside an
  /// album context. Within an album the subtitle only appears when the track
  /// artist differs from the album artist (compilations).
  final bool showArtist;

  /// Optional external focus node for programmatic focus control.
  final FocusNode? focusNode;

  /// Called on UP from the row (wired by the host on the first row only, so
  /// the list edge escapes to the action bar).
  final VoidCallback? onNavigateUp;

  /// Called on BACK while the row is focused.
  final VoidCallback? onBack;

  final ValueChanged<bool>? onFocusChange;

  /// Replace the trailing ⋮ context-menu button with a dedicated action
  /// (e.g. the queue sheet's remove button). SELECT on the trailing column
  /// runs [onTrailingTap] instead of opening the context menu.
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  /// Disable the long-press / right-click context menu — hosts that own the
  /// long-press gesture themselves (the queue sheet's drag-to-reorder) must
  /// opt out so the recognizers don't fight in the gesture arena.
  final bool enableContextMenu;

  /// Override the service-derived "is this the current track" check. Hosts
  /// that can render the same track at several queue positions (the queue
  /// sheet) pass the exact positional match so only the playing entry gets
  /// the equalizer; null keeps the by-id fallback for album/track lists.
  final bool? isCurrent;

  /// Mute the title — the queue sheet marks already-played entries this way.
  final bool dimmed;

  /// Hide the leading album track number (the 32px slot stays, keeping
  /// titles aligned with the current row's equalizer). The queue sheet
  /// turns it off: album-relative numbers read as a sorting bug in a
  /// mixed-album queue.
  final bool showTrackNumber;

  /// Show a compact download-status indicator (muted [DownloadStatusIcon])
  /// between the duration and the trailing ⋮ when the track has a download
  /// record. Off by default — surfaces without download affordances (queue
  /// sheet) keep the row untouched. Renders nothing when no
  /// [DownloadProvider] is in scope.
  final bool showDownloadStatus;

  const TrackRow({
    super.key,
    required this.item,
    this.onTap,
    this.onRefresh,
    this.isFirst = false,
    this.isLast = false,
    this.showArtist = false,
    this.focusNode,
    this.onNavigateUp,
    this.onBack,
    this.onFocusChange,
    this.trailingIcon,
    this.onTrailingTap,
    this.enableContextMenu = true,
    this.isCurrent,
    this.dimmed = false,
    this.showTrackNumber = true,
    this.showDownloadStatus = false,
  });

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> with ContextMenuTapMixin<TrackRow>, FocusableTileStateMixin<TrackRow> {
  /// 0 = row (SELECT plays), 1 = ⋮ button (SELECT opens the context menu).
  int _focusedColumn = 0;
  bool _hasFocus = false;

  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    initFocusNode();
  }

  @override
  void didUpdateWidget(TrackRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateFocusNode(oldWidget.focusNode);
  }

  @override
  void dispose() {
    disposeFocusNode();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _hasFocus = hasFocus;
      if (!hasFocus) _focusedColumn = 0;
    });
    widget.onFocusChange?.call(hasFocus);
  }

  void _activateFocusedColumn() {
    if (_focusedColumn == 0) {
      widget.onTap?.call();
    } else if (widget.onTrailingTap != null) {
      widget.onTrailingTap!();
    } else {
      // Keyboard/gamepad activation — the menu centers on the row.
      showContextMenu();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) return backResult;
    }
    return dpadKeyHandler(
      onSelect: _activateFocusedColumn,
      onUp: widget.onNavigateUp,
      onLeft: _focusedColumn == 1 ? () => setState(() => _focusedColumn = 0) : null,
      onRight: _focusedColumn == 0 ? () => setState(() => _focusedColumn = 1) : null,
      // Detail screens have nothing beside the list — keep focus on the row.
      trapHorizontalEdges: true,
    )(node, event);
  }

  void _showMenuAt(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject() as RenderBox?;
    Offset? position;
    if (box != null) position = box.localToGlobal(box.size.center(Offset.zero));
    contextMenuKey.currentState?.showContextMenu(context, position: position);
  }

  String? get _subtitle {
    final trackArtist = widget.item.trackArtistTitle;
    if (trackArtist == null || trackArtist.isEmpty) return null;
    if (widget.showArtist) return trackArtist;
    return trackArtist != widget.item.albumArtistTitle ? trackArtist : null;
  }

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Both selects run unconditionally every build (provider contract).
    // globalKey, not id: a bare ratingKey is server-scoped, so a track on
    // another server with the same id would falsely light up as current.
    final isCurrentById = context.select<MusicPlaybackService, bool>(
      (s) => s.currentTrack?.globalKey == widget.item.globalKey,
    );
    final serviceIsPlaying = context.select<MusicPlaybackService, bool>((s) => s.isPlaying);
    final isCurrent = widget.isCurrent ?? isCurrentById;

    final showFocus = _hasFocus && InputModeTracker.isKeyboardMode(context);
    final radii = BorderRadius.vertical(
      top: Radius.circular(widget.isFirst ? tk.radiusLg : tk.radiusXs),
      bottom: Radius.circular(widget.isLast ? tk.radiusLg : tk.radiusXs),
    );

    final subtitle = _subtitle;
    final durationMs = widget.item.durationMs;
    final withContextMenu = widget.enableContextMenu;

    final row = Focus(
      focusNode: effectiveFocusNode,
      descendantsAreFocusable: false,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: _handleFocusChange,
      child: Material(
        color: tk.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radii),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: widget.onTap,
          onTapDown: withContextMenu ? storeTapPosition : null,
          onLongPress: withContextMenu ? showContextMenuFromTap : null,
          onSecondaryTapDown: withContextMenu ? storeTapPosition : null,
          onSecondaryTap: withContextMenu ? showContextMenuFromTap : null,
          child: Container(
            height: TrackRow.height,
            // Text-based fill (mono theme focusColor convention) — the
            // white-based FocusTheme fill is invisible on the light row
            // surface.
            decoration: BoxDecoration(
              borderRadius: radii,
              color: showFocus && _focusedColumn == 0 ? tk.text.withValues(alpha: 0.12) : Colors.transparent,
            ),
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: isCurrent
                        ? EqualizerIcon(animate: serviceIsPlaying, color: colorScheme.primary)
                        : widget.showTrackNumber
                        ? Text('${widget.item.trackNumber ?? ''}', style: TextStyle(fontSize: 13, color: tk.textMuted))
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        widget.item.title ?? '',
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          color: isCurrent ? tk.text : (widget.dimmed ? tk.textMuted : null),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TextStyle(fontSize: 12, color: tk.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (durationMs != null)
                  Text(
                    formatDurationTimestamp(Duration(milliseconds: durationMs)),
                    style: TextStyle(fontSize: 13, color: tk.textMuted),
                  ),
                if (widget.showDownloadStatus) _TrackDownloadStatus(item: widget.item),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: showFocus && _focusedColumn == 1 ? tk.text.withValues(alpha: 0.12) : Colors.transparent,
                  ),
                  child: Builder(
                    builder: (buttonContext) => IconButton(
                      icon: AppIcon(
                        widget.trailingIcon ?? Symbols.more_vert_rounded,
                        fill: 1,
                        size: 20,
                        color: tk.textMuted,
                      ),
                      onPressed: widget.onTrailingTap ?? () => _showMenuAt(buttonContext),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!withContextMenu) return row;
    return MediaContextMenu(
      key: contextMenuKey,
      item: widget.item,
      onRefresh: widget.onRefresh,
      onTap: widget.onTap,
      child: row,
    );
  }
}

/// Compact per-track download indicator, mirroring the episode-card pattern:
/// a queueing spinner while the queue is being built, then a muted
/// [DownloadStatusIcon] for any live download record. A [Selector] slice
/// keeps unrelated provider ticks from rebuilding the row.
class _TrackDownloadStatus extends StatelessWidget {
  final MediaItem item;

  const _TrackDownloadStatus({required this.item});

  @override
  Widget build(BuildContext context) {
    // Graceful no-op when no DownloadProvider is in scope (tests, playback
    // queue contexts) or the item can't have a download record.
    if (item.serverId == null || context.read<DownloadProvider?>() == null) {
      return const SizedBox.shrink();
    }

    return Selector<DownloadProvider, (DownloadStatus?, double?, bool)>(
      selector: (_, p) {
        final progress = p.getProgress(item.globalKey);
        return (progress?.status, progress?.progressPercent, p.isQueueing(item.globalKey));
      },
      builder: (context, slice, _) {
        final (status, progressPercent, isQueueing) = slice;
        final mutedBase = tokens(context).textMuted;

        final Widget? icon;
        if (isQueueing) {
          icon = DownloadQueueingSpinner(size: 12, color: mutedBase);
        } else if (status != null) {
          icon = DownloadStatusIcon(
            status: status,
            size: status == DownloadStatus.downloading ? 14 : 12,
            variant: DownloadStatusIconVariant.muted,
            mutedBase: mutedBase,
            progress: progressPercent,
          );
        } else {
          icon = null;
        }

        if (icon == null) return const SizedBox.shrink();
        return Padding(padding: const EdgeInsets.only(left: 8), child: icon);
      },
    );
  }
}
