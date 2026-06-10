part of '../video_controls.dart';

extension _PlexVideoControlsPlaybackExtrasMethods on _PlexVideoControlsState {
  Future<void> _loadPlaybackExtras({bool forceRefresh = false}) async {
    // Live TV metadata uses EPG rating keys, not library items
    if (widget.isLive) return;
    final loadKey = widget.metadata.globalKey;
    // Re-entrancy guard is per item: an in-place episode swap may start the
    // new item's load while the old item's is still in flight.
    if (_isLoadingExtras && _extrasLoadKey == loadKey) return;
    _isLoadingExtras = true;
    _extrasLoadKey = loadKey;

    final metadata = widget.metadata;
    final serverId = metadata.serverId;
    // Read providers before any await — `context` after an async gap is
    // a lint trigger and can crash if the widget unmounts mid-load.
    final client = serverId != null ? context.tryGetMediaClientForServer(ServerId(serverId)) : null;
    final database = context.read<AppDatabase>();

    try {
      final extras = await VideoControlsPlaybackExtrasLoader(
        metadata: metadata,
        database: database,
        client: client,
      ).load(forceRefresh: forceRefresh);
      // Discard stale responses — the item may have swapped mid-flight.
      if (extras != null && mounted && widget.metadata.globalKey == loadKey) {
        _applyPlaybackExtras(extras);
      }
    } finally {
      if (_extrasLoadKey == loadKey) _isLoadingExtras = false;
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
    _syncCurrentMarkerForCurrentPosition();
  }
}
