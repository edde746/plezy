part of '../video_controls.dart';

extension _PlexVideoControlsPlaybackExtrasMethods on _PlexVideoControlsState {
  Future<void> _loadPlaybackExtras({bool forceRefresh = false}) async {
    // Live TV metadata uses EPG rating keys, not library items
    if (widget.isLive) return;
    if (_isLoadingExtras) return;
    _isLoadingExtras = true;

    final serverId = widget.metadata.serverId;
    // Read providers before any await — `context` after an async gap is
    // a lint trigger and can crash if the widget unmounts mid-load.
    final client = serverId != null ? context.tryGetMediaClientForServer(serverId) : null;
    final database = context.read<AppDatabase>();

    try {
      final extras = await VideoControlsPlaybackExtrasLoader(
        metadata: widget.metadata,
        database: database,
        client: client,
      ).load(forceRefresh: forceRefresh);
      if (extras != null) _applyPlaybackExtras(extras);
    } finally {
      _isLoadingExtras = false;
    }
  }

  void _applyPlaybackExtras(PlaybackExtras extras) {
    if (!mounted) return;
    _setControlsState(() {
      _chapters = extras.chapters;
      _markers = extras.markers;
      _chaptersLoaded = true;
      _markersLoaded = true;
    });
  }
}
