part of '../../video_player_screen.dart';

extension _VideoPlayerClipMethods on VideoPlayerScreenState {
  bool get _canClipCurrentPlayback {
    return PlatformDetector.isDesktopOS() &&
        !widget.isLive &&
        _playbackSession?.result.videoUrl != null &&
        _clipSourceDuration() >= clipMinimumDuration;
  }

  Future<void> _handleClipRequested(BuildContext sheetContext) async {
    if (!_canClipCurrentPlayback) {
      showErrorSnackBar(sheetContext, 'Clips are available for on-demand video playback.');
      return;
    }

    final currentPlayer = player;
    final source = _buildClipSource();
    if (currentPlayer == null || source == null) {
      showErrorSnackBar(sheetContext, 'Clip source is not available for this playback session.');
      return;
    }

    final selection = ClipExportService.defaultSelection(
      position: currentPlayer.currentPosition,
      duration: source.duration,
    );
    if (selection.duration < clipMinimumDuration) {
      showErrorSnackBar(sheetContext, 'Play at least 1 second before clipping.');
      return;
    }

    final previewController = ClipPreviewPlayerController();
    try {
      await OverlaySheetController.showAdaptive<void>(
        sheetContext,
        builder: (_) => ClipEditorSheet(
          source: source,
          initialSelection: selection,
          exportService: _clipExportService,
          previewController: previewController,
          thumbnailDataBuilder: _scrubPreviewSource?.isAvailable == true ? _getThumbnailData : null,
        ),
        constraints: BoxConstraints(maxWidth: 680, maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8),
        backgroundColor: Colors.transparent,
        onCloseStart: previewController.hideSurfaceNow,
      );
    } finally {
      previewController.dispose();
    }
  }

  ClipSource? _buildClipSource() {
    final session = _playbackSession;
    final currentPlayer = player;
    final uri = session?.result.videoUrl;
    if (session == null || uri == null || uri.isEmpty) return null;

    final labels = ClipExportService.metadataLabels(_currentMetadata);
    return ClipSource(
      uri: uri,
      headers: session.streamHeaders ?? const <String, String>{},
      isTranscoding: session.isTranscoding,
      timelineOffset: currentPlayer is PlayerBase ? currentPlayer.timelineOffset : Duration.zero,
      duration: _clipSourceDuration(),
      title: labels.title,
      subtitle: labels.subtitle,
      container: session.result.selectedVersion?.container,
      displayCriteria: session.mediaInfo?.displayCriteria,
    );
  }

  Duration _clipSourceDuration() {
    final playerDuration = player?.state.duration ?? Duration.zero;
    if (playerDuration > Duration.zero) return playerDuration;
    final metadataDurationMs = _currentMetadata.durationMs;
    if (metadataDurationMs != null && metadataDurationMs > 0) {
      return Duration(milliseconds: metadataDurationMs);
    }
    return Duration.zero;
  }
}
