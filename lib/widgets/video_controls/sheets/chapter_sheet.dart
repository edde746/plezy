import 'dart:async' show Stream, StreamSubscription, unawaited;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/media_bookmark.dart';
import '../../../media/ids.dart';
import '../../../media/media_server_client.dart';
import '../../../mpv/mpv.dart';
import '../../../services/download_storage_service.dart';
import '../../../services/media_bookmark_service.dart';
import '../../../media/media_source_info.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/dialogs.dart';
import '../../../utils/player_utils.dart';
import '../../../utils/provider_extensions.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../utils/scroll_utils.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import '../widgets/media_selector_thumbnail.dart';
import 'base_video_control_sheet.dart';
import '../../optimized_media_image.dart';

/// Bottom sheet for selecting chapters
class ChapterSheet extends StatefulWidget {
  final Player player;
  final List<MediaChapter> chapters;
  final bool chaptersLoaded;
  final bool canControl;
  final String? serverId; // Server ID for the metadata these chapters belong to
  final String? bookmarkMediaKey;
  final bool isLive;
  final Future<void> Function(Duration position)? onSeekRequested;
  final Function(Duration position)? onSeekCompleted;

  const ChapterSheet({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    required this.canControl,
    this.serverId,
    this.bookmarkMediaKey,
    this.isLive = false,
    this.onSeekRequested,
    this.onSeekCompleted,
  });

  @override
  State<ChapterSheet> createState() => _ChapterSheetState();
}

class _ChapterSheetState extends State<ChapterSheet> {
  final _initialScroll = InitialItemScrollController();
  late Stream<int?> _chapterIndexStream;
  Duration? _loopStart;
  Duration? _loopEnd;
  bool _loopBusy = false;
  List<MediaBookmark> _bookmarks = const [];
  bool _bookmarkBusy = false;
  StreamSubscription<PlayerSourceStarted>? _sourceStartedSubscription;
  StreamSubscription<bool>? _seekableSubscription;

  bool get _canShowBookmarks =>
      !widget.isLive &&
      widget.canControl &&
      widget.player.state.seekable &&
      widget.bookmarkMediaKey != null &&
      widget.bookmarkMediaKey!.isNotEmpty;

  bool get _canSetSegmentLoop =>
      !widget.isLive &&
      widget.canControl &&
      widget.player.playerType == 'mpv' &&
      widget.player.state.seekable &&
      widget.player.state.duration > Duration.zero;

  @override
  void initState() {
    super.initState();
    _bindChapterIndexStream();
    _bindSourceStartedStream();
    _bindSeekableStream();
    _loadBookmarks();
    if (_canSetSegmentLoop) unawaited(_loadSegmentLoop());
  }

  @override
  void didUpdateWidget(ChapterSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player) ||
        !identical(oldWidget.chapters, widget.chapters) ||
        oldWidget.bookmarkMediaKey != widget.bookmarkMediaKey) {
      _bindChapterIndexStream();
      _loadBookmarks();
      if (!identical(oldWidget.player, widget.player)) {
        _loopStart = null;
        _loopEnd = null;
        _bindSourceStartedStream();
        _bindSeekableStream();
        if (_canSetSegmentLoop) unawaited(_loadSegmentLoop());
      }
    }
  }

  void _bindChapterIndexStream() {
    _chapterIndexStream = widget.player.streams.position
        .map((position) => MediaChapter.indexAtPosition(position, widget.chapters))
        .distinct();
  }

  void _bindSourceStartedStream() {
    unawaited(_sourceStartedSubscription?.cancel());
    _sourceStartedSubscription = widget.player.playerType == 'mpv'
        ? widget.player.streams.sourceStarted.listen((_) {
            if (!mounted) return;
            setState(() {
              _loopStart = null;
              _loopEnd = null;
            });
          })
        : null;
  }

  void _bindSeekableStream() {
    unawaited(_seekableSubscription?.cancel());
    _seekableSubscription = widget.player.streams.seekable.listen((_) {
      if (!mounted) return;
      setState(() {});
      if (_canSetSegmentLoop) unawaited(_loadSegmentLoop());
    });
  }

  @override
  void dispose() {
    unawaited(_sourceStartedSubscription?.cancel());
    unawaited(_seekableSubscription?.cancel());
    _initialScroll.dispose();
    super.dispose();
  }

  Future<void> _handleChapterTap(Duration position) async {
    if (!widget.canControl || !widget.player.state.seekable) return;
    final clamped = clampSeekPosition(widget.player, position);
    await (widget.onSeekRequested ?? widget.player.seek)(clamped);
    if (mounted) {
      widget.onSeekCompleted?.call(clamped);
      OverlaySheetController.of(context).close();
    }
  }

  Future<void> _loadSegmentLoop() async {
    try {
      final values = await Future.wait([
        widget.player.getProperty('ab-loop-a'),
        widget.player.getProperty('ab-loop-b'),
      ]);
      if (!mounted) return;
      setState(() {
        _loopStart = _parseLoopPosition(values[0]);
        _loopEnd = _parseLoopPosition(values[1]);
      });
    } on Object catch (error, stackTrace) {
      appLogger.d('MPV segment loop state is unavailable', error: error, stackTrace: stackTrace);
    }
  }

  void _loadBookmarks() {
    final mediaKey = widget.bookmarkMediaKey;
    _bookmarks = mediaKey == null || mediaKey.isEmpty ? const [] : MediaBookmarkService.forMedia(mediaKey);
  }

  Future<void> _addBookmark() async {
    final mediaKey = widget.bookmarkMediaKey;
    if (!_canShowBookmarks || mediaKey == null || mediaKey.isEmpty || _bookmarkBusy) return;
    final currentPosition = widget.player.currentPosition;
    final label = await showTextInputDialog(
      context,
      title: t.videoControls.addBookmark,
      labelText: t.videoControls.bookmarkName,
      hintText: t.videoControls.bookmarkNameHint,
      initialValue: t.videoControls.bookmarkDefaultName(n: _bookmarks.length + 1),
      validator: (value) => value.trim().isEmpty ? t.videoControls.bookmarkNameRequired : null,
    );
    if (!mounted || label == null || !_canShowBookmarks) return;
    setState(() => _bookmarkBusy = true);
    try {
      final bookmark = await MediaBookmarkService.add(mediaKey, label, currentPosition.inMilliseconds);
      if (mounted) setState(() => _bookmarks = [..._bookmarks, bookmark]);
    } on MediaBookmarkLimitException {
      if (mounted) showSnackBar(context, t.videoControls.bookmarkLimitReached);
    } on Object catch (error, stackTrace) {
      appLogger.w('Failed to save media bookmark', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.videoControls.bookmarkUnavailable);
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _deleteBookmark(MediaBookmark bookmark) async {
    final mediaKey = widget.bookmarkMediaKey;
    if (mediaKey == null || mediaKey.isEmpty || _bookmarkBusy) return;
    setState(() => _bookmarkBusy = true);
    try {
      await MediaBookmarkService.remove(mediaKey, bookmark.id);
      if (mounted) setState(() => _bookmarks = _bookmarks.where((value) => value.id != bookmark.id).toList());
    } on Object catch (error, stackTrace) {
      appLogger.w('Failed to delete media bookmark', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.videoControls.bookmarkUnavailable);
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Duration? _parseLoopPosition(String? value) {
    final seconds = double.tryParse(value ?? '');
    if (seconds == null || !seconds.isFinite || seconds < 0) return null;
    return Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round());
  }

  Future<void> _setLoopStart() async {
    if (!_canSetSegmentLoop || _loopBusy) return;
    setState(() => _loopBusy = true);
    final position = widget.player.currentPosition;
    try {
      await widget.player.setProperty('ab-loop-b', 'no');
      await widget.player.setProperty(
        'ab-loop-a',
        (position.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(3),
      );
      if (mounted) {
        setState(() {
          _loopStart = position;
          _loopEnd = null;
        });
      }
    } on Object catch (error, stackTrace) {
      appLogger.w('Failed to set MPV segment loop start', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.videoControls.segmentLoopUnavailable);
    } finally {
      if (mounted) setState(() => _loopBusy = false);
    }
  }

  Future<void> _setLoopEnd() async {
    if (!_canSetSegmentLoop || _loopBusy) return;
    final start = _loopStart;
    if (start == null) {
      showSnackBar(context, t.videoControls.setLoopStartFirst);
      return;
    }
    final position = widget.player.currentPosition;
    if (position <= start) {
      showSnackBar(context, t.videoControls.loopEndAfterStart);
      return;
    }
    setState(() => _loopBusy = true);
    try {
      await widget.player.setProperty(
        'ab-loop-b',
        (position.inMicroseconds / Duration.microsecondsPerSecond).toStringAsFixed(3),
      );
      if (mounted) setState(() => _loopEnd = position);
    } on Object catch (error, stackTrace) {
      appLogger.w('Failed to set MPV segment loop end', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.videoControls.segmentLoopUnavailable);
    } finally {
      if (mounted) setState(() => _loopBusy = false);
    }
  }

  Future<void> _clearSegmentLoop() async {
    if (!_canSetSegmentLoop || _loopBusy || _loopStart == null && _loopEnd == null) return;
    setState(() => _loopBusy = true);
    try {
      await widget.player.setProperty('ab-loop-a', 'no');
      await widget.player.setProperty('ab-loop-b', 'no');
      if (mounted) {
        setState(() {
          _loopStart = null;
          _loopEnd = null;
        });
      }
    } on Object catch (error, stackTrace) {
      appLogger.w('Failed to clear MPV segment loop', error: error, stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context, t.videoControls.segmentLoopUnavailable);
    } finally {
      if (mounted) setState(() => _loopBusy = false);
    }
  }

  /// Get the media client for chapters, or null if unavailable (offline mode).
  MediaServerClient? _tryGetClientForChapters(BuildContext context) {
    return context.tryGetMediaClientForServer(serverIdOrNull(widget.serverId));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: _chapterIndexStream,
      initialData: MediaChapter.indexAtPosition(widget.player.state.position, widget.chapters),
      builder: (context, chapterSnapshot) {
        final currentChapterIndex = chapterSnapshot.data;
        final chapters = widget.chapters;
        if (currentChapterIndex != null) _initialScroll.maybeScrollTo(currentChapterIndex);
        final content = ListView(
          shrinkWrap: true,
          controller: _initialScroll.controller,
          children: [
            if (_canShowBookmarks) ...[
              if (_bookmarks.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(t.videoControls.bookmarksHelp, style: TextStyle(color: tokens(context).textMuted)),
                ),
              FocusableListTile(
                leading: const AppIcon(Symbols.bookmark_add_rounded),
                title: Text(t.videoControls.addBookmark),
                onTap: _canShowBookmarks && !_bookmarkBusy ? () => unawaited(_addBookmark()) : null,
              ),
              for (final bookmark in _bookmarks)
                FocusableListTile(
                  key: ValueKey('bookmark-${bookmark.id}'),
                  leading: const AppIcon(Symbols.bookmark_rounded),
                  title: Text(bookmark.label),
                  subtitle: Text(formatDurationTimestamp(Duration(milliseconds: bookmark.positionMs))),
                  trailing: IconButton(
                    tooltip: t.videoControls.deleteBookmark,
                    onPressed: _bookmarkBusy ? null : () => unawaited(_deleteBookmark(bookmark)),
                    icon: const AppIcon(Symbols.delete_outline_rounded),
                  ),
                  onTap: _canShowBookmarks
                      ? () => unawaited(_handleChapterTap(Duration(milliseconds: bookmark.positionMs)))
                      : null,
                ),
            ],
            if (_canSetSegmentLoop) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(t.videoControls.segmentLoopHelp, style: TextStyle(color: tokens(context).textMuted)),
              ),
              FocusableListTile(
                leading: const AppIcon(Symbols.first_page_rounded),
                title: Text(t.videoControls.setLoopStart),
                subtitle: Text(
                  _loopStart == null ? t.videoControls.loopPointNotSet : formatDurationTimestamp(_loopStart!),
                ),
                onTap: _loopBusy ? null : () => unawaited(_setLoopStart()),
              ),
              FocusableListTile(
                leading: const AppIcon(Symbols.last_page_rounded),
                title: Text(t.videoControls.setLoopEnd),
                subtitle: Text(_loopEnd == null ? t.videoControls.loopPointNotSet : formatDurationTimestamp(_loopEnd!)),
                onTap: _loopBusy ? null : () => unawaited(_setLoopEnd()),
              ),
              if (_loopStart != null || _loopEnd != null)
                FocusableListTile(
                  leading: const AppIcon(Symbols.restart_alt_rounded),
                  title: Text(t.videoControls.clearSegmentLoop),
                  onTap: _loopBusy ? null : () => unawaited(_clearSegmentLoop()),
                ),
            ],
            if (!widget.chaptersLoaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(heightFactor: 1, child: CircularProgressIndicator()),
              )
            else if (chapters.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  heightFactor: 1,
                  child: Text(
                    _canShowBookmarks && _bookmarks.isNotEmpty
                        ? t.videoControls.noChaptersAvailable
                        : t.videoControls.noChaptersOrBookmarks,
                    style: TextStyle(color: tokens(context).textMuted),
                  ),
                ),
              )
            else
              for (var index = 0; index < chapters.length; index++)
                _buildChapterTile(context, chapters[index], index, currentChapterIndex),
          ],
        );

        return BaseVideoControlSheet(
          title: t.videoControls.chaptersAndBookmarks,
          icon: Symbols.bookmarks_rounded,
          child: content,
        );
      },
    );
  }

  Widget _buildChapterTile(BuildContext context, MediaChapter chapter, int index, int? currentChapterIndex) {
    final isCurrentChapter = currentChapterIndex == index;
    final localThumbPath = widget.serverId != null && chapter.thumb != null
        ? DownloadStorageService.instance.getArtworkPathSync(ServerId(widget.serverId!), chapter.thumb!)
        : null;
    return FocusableListTile(
      key: index == 0 ? _initialScroll.firstItemKey : null,
      leading: chapter.thumb == null
          ? null
          : MediaSelectorThumbnail(
              width: 60,
              height: 34,
              thumbnail: OptimizedMediaImage.thumb(
                client: _tryGetClientForChapters(context),
                imagePath: chapter.thumb,
                localFilePath: localThumbPath,
                width: 60,
                height: 34,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const AppIcon(Symbols.image_rounded, fill: 1, color: Colors.white54, size: 34),
              ),
              isCurrent: isCurrentChapter,
              borderColor: Theme.of(context).colorScheme.primary,
            ),
      title: Text(
        chapter.label,
        style: TextStyle(
          color: isCurrentChapter ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        formatDurationTimestamp(chapter.startTime),
        style: TextStyle(
          color: isCurrentChapter
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
              : tokens(context).textMuted,
          fontSize: 12,
        ),
      ),
      trailing: isCurrentChapter
          ? AppIcon(Symbols.play_circle_rounded, fill: 1, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: widget.canControl && widget.player.state.seekable
          ? () => unawaited(_handleChapterTap(chapter.startTime))
          : null,
    );
  }
}
