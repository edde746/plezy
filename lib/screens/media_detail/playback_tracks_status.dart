part of '../media_detail_screen.dart';

/// The action row's trailing status: what Play will do with this item's
/// picture, audio, and subtitles, computed by the player's own selection
/// ladder ([previewPlaybackTracks]). Read-only — it describes the episode the
/// hero shows, and on TV that changes with rail focus, so there is no per-
/// episode target for a control here to act on.
extension _MediaDetailPlaybackTracksStatus on _MediaDetailScreenState {
  /// The item Play would start: the hero's episode for a show, the first
  /// episode for a season, the item itself otherwise. Null while a show has
  /// not resolved any episode yet.
  MediaItem? _playbackTargetItem(MediaItem metadata) {
    final MediaItem? target;
    if (metadata.isShow) {
      target = _showPlayEpisode();
    } else if (metadata.isSeason) {
      target = _episodes.isEmpty ? null : _episodes.first;
    } else {
      target = metadata;
    }
    return target;
  }

  Future<void> _listenForPlaybackVersionChanges() async {
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    _playbackVersionPreferences = settings.listenableOf(SettingsService.mediaVersionPreferences);
    _playbackVersionPreferences!.addListener(_onPlaybackVersionChanged);
  }

  void _onPlaybackVersionChanged() {
    _invalidatePlaybackProbes(refreshItems: false);
  }

  void _invalidatePlaybackProbes({required bool refreshItems}) {
    _playbackProbeGeneration++;
    _playbackProbeTimer?.cancel();
    _playbackProbeRequests.clear();
    _playbackSources.clear();
    if (refreshItems) _probedPlaybackItems.clear();
    _playbackStatusRevision.value++;
  }

  /// Fetch metadata once, then resolve the saved selection independently.
  /// Rendering never starts PlaybackInfo or a transcode. Offline only reads
  /// the completed download's identity, never a server or track probe.
  void _scheduleTargetProbe(BuildContext context, MediaItem target) {
    final key = target.globalKey;
    if (_playbackSources.containsKey(key) || _playbackProbeRequests.containsKey(key)) return;
    final client = widget.isOffline ? null : _getMediaClientForMetadata(context);
    if (!widget.isOffline && client == null) return;
    final downloads = widget.isOffline ? context.read<DownloadProvider>() : null;
    _playbackProbeTimer?.cancel();
    final generation = _playbackProbeGeneration;
    _playbackProbeTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || generation != _playbackProbeGeneration || _playbackProbeRequests.containsKey(key)) return;
      unawaited(_probeTarget(client, downloads, target, generation));
    });
  }

  Future<void> _probeTarget(
    MediaServerClient? client,
    DownloadProvider? downloads,
    MediaItem target,
    int generation,
  ) async {
    final key = target.globalKey;
    final request = Object();
    _playbackProbeRequests[key] = request;
    bool current() => mounted && generation == _playbackProbeGeneration && _playbackProbeRequests[key] == request;
    try {
      MediaItem item;
      MediaSourceInfo? source;
      int? mediaIndex;
      if (downloads != null) {
        final downloaded = await downloads.getCompletedDownload(key);
        if (!current()) return;
        item = target;
        if (downloaded != null) {
          final versions = item.mediaVersions;
          final byId = downloaded.mediaSourceId == null
              ? -1
              : versions?.indexWhere((version) => version.id == downloaded.mediaSourceId) ?? -1;
          mediaIndex = byId >= 0 ? byId : downloaded.mediaIndex;
          if (versions == null || mediaIndex < 0 || mediaIndex >= versions.length) mediaIndex = null;
        }
      } else {
        final fetched = _probedPlaybackItems[key] ?? await client!.fetchItem(target.id);
        if (!current() || fetched == null) return;
        item = fetched.copyWith(
          serverId: target.serverId ?? fetched.serverId,
          serverName: target.serverName ?? fetched.serverName,
        );
        _probedPlaybackItems[key] = item;
        final selection = await resolveSavedMediaVersionFor(item);
        if (!current()) return;
        source = await client!.fetchCachedMediaSourceInfo(
          item.id,
          mediaIndex: selection?.index ?? 0,
          mediaSourceId: selection?.sourceId,
          preferredVersionSignature: selection?.signature,
        );
        if (!current() || source == null) return;
        mediaIndex = source.mediaIndex ?? selection?.index ?? 0;
      }
      if (!current()) return;
      _playbackSources[key] = (item: item, source: source, mediaIndex: mediaIndex);
      // Only the status repaints: do not rebuild the rail or replace its
      // focused item with a cached probe snapshot.
      _playbackStatusRevision.value++;
    } catch (e, stackTrace) {
      appLogger.d('Playback track probe failed for ${target.id}', error: e, stackTrace: stackTrace);
    } finally {
      if (_playbackProbeRequests[key] == request) _playbackProbeRequests.remove(key);
    }
  }

  /// The listener stays mounted while a source is resolving, without adding
  /// a semantic or focus target when there is nothing to predict.
  Widget _buildPlaybackTracksStatus(
    BuildContext context,
    MediaItem metadata, {
    required bool isTv,
    required double tvScale,
    required double maxWidth,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: _playbackStatusRevision,
      builder: (context, _, _) =>
          _playbackTracksStatus(context, metadata, isTv: isTv, tvScale: tvScale, maxWidth: maxWidth) ??
          const SizedBox.shrink(),
    );
  }

  Widget? _playbackTracksStatus(
    BuildContext context,
    MediaItem metadata, {
    required bool isTv,
    required double tvScale,
    required double maxWidth,
  }) {
    final target = _playbackTargetItem(metadata);
    if (target == null) return null;
    if (_playbackStatusTarget != target.globalKey) {
      _playbackStatusTarget = target.globalKey;
      final cached = _playbackSources[target.globalKey]?.source;
      if (!widget.isOffline && cached != null && !mediaSourceHasTrackRows(cached)) {
        _playbackSources.remove(target.globalKey);
      }
    }

    // Profile-scoped in the app; nullable so a bare detail screen (widget
    // tests) still previews with the ladder's non-profile tiers.
    final probed = _playbackSources[target.globalKey];
    final source = probed?.source;
    final preview = source == null
        ? null
        : previewPlaybackTracks(
            probed!.item,
            source,
            profile: context.watch<AccountPreferencesController?>()?.activePreferences,
          );
    final videoLabels = probed?.mediaIndex == null
        ? const <String>[]
        : buildMediaVideoLabels(probed!.item, versionIndex: probed.mediaIndex!, partIndex: source?.partIndex);
    if (probed == null) _scheduleTargetProbe(context, target);
    if (preview == null && videoLabels.isEmpty) return null;

    final audioLabel = preview?.audio?.label;
    final subtitleLabel = preview?.subtitle?.label;
    final parts = <MetadataLinePart>[
      // Shed order on a tight row: the long codec details first (subtitle's,
      // then audio's — the details sheet has them in full), then the short
      // picture labels, then the audio track; the subtitle decision always
      // stays.
      for (final label in videoLabels) MetadataLineText(label, dropPriority: 2),
      if (audioLabel != null)
        MetadataLineIconText(
          Symbols.volume_up_rounded,
          audioLabel.primary,
          detail: audioLabel.secondary,
          dropPriority: 1,
          detailDropPriority: 3,
        ),
      if (preview != null)
        MetadataLineIconText(
          Symbols.subtitles_rounded,
          subtitleLabel?.primary ?? t.common.off,
          detail: subtitleLabel?.secondary,
          dropPriority: 0,
          detailDropPriority: 3,
        ),
    ];
    final semanticsLabel =
        '${t.videoControls.tracksButton}: ${[for (final part in parts) switch (part) {
            MetadataLineText(:final text) => text,
            MetadataLineIconText(:final text, :final detail) => detail == null ? text : '$text${MetadataLineIconText.detailSeparator}$detail',
            MetadataLineRatings() => '',
          }].join(', ')}';

    // Same ink as the hero's metadata line, one step lighter in weight and
    // size so it reads as a footnote to the buttons rather than a sixth one.
    final textStyle = TextStyle(
      color: isTv ? _tvDetailForegroundColor(context) : Theme.of(context).colorScheme.onSurface,
      fontSize: isTv ? 15 * tvScale : 12.5,
      fontWeight: .w600,
      letterSpacing: 0.1,
      height: 1.2,
    );

    return Semantics(
      key: const ValueKey('detail_playback_tracks'),
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FittedMetadataLine(textStyle: textStyle, parts: parts, ratingIconSize: textStyle.fontSize! * 1.15),
      ),
    );
  }
}
