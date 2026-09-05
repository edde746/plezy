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
    if (target == null) return null;
    return _probedPlaybackItems[target.id]?.item ?? target;
  }

  /// The ladder needs the version's [MediaSourceInfo] — the rows and server
  /// defaults Play will use — which only the item's own fetch puts in the
  /// metadata cache; a listing episode reached through the rail has none
  /// until then. One request per item, debounced past D-pad scrubbing, cached
  /// for the screen's lifetime; the result reaches the hero through the
  /// focused-episode notifier so the rail does not rebuild.
  void _scheduleTargetProbe(BuildContext context, MediaItem target) {
    if (widget.isOffline || _probedPlaybackItems.containsKey(target.id)) return;
    final client = _getMediaClientForMetadata(context);
    if (client == null) return;

    _playbackProbeTimer?.cancel();
    _playbackProbeTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _probedPlaybackItems.containsKey(target.id)) return;
      unawaited(_probeTarget(client, target));
    });
  }

  Future<void> _probeTarget(MediaServerClient client, MediaItem target) async {
    final MediaItem? fetched;
    final MediaSourceInfo? source;
    try {
      fetched = await client.fetchItem(target.id);
      source = fetched == null ? null : await client.fetchCachedMediaSourceInfo(target.id);
    } catch (e, stackTrace) {
      appLogger.d('Playback track probe failed for ${target.id}', error: e, stackTrace: stackTrace);
      return;
    }
    if (!mounted || fetched == null) return;
    // A source without rows is not worth caching: the next focus retries.
    if (source == null || !mediaSourceHasTrackRows(source)) return;
    final probed = fetched.copyWith(
      serverId: target.serverId ?? fetched.serverId,
      serverName: target.serverName ?? fetched.serverName,
    );
    _probedPlaybackItems[target.id] = (item: probed, source: source);
    if (_tvDetailFocusedEpisode.value?.id == target.id) {
      _tvDetailFocusedEpisode.value = probed;
    } else {
      setStateIfMounted(() {});
    }
  }

  /// Null when there is nothing to say: no version at all, or a container
  /// summary without a resolution.
  Widget? _buildPlaybackTracksStatus(
    BuildContext context,
    MediaItem metadata, {
    required bool isTv,
    required double tvScale,
    required double maxWidth,
  }) {
    final target = _playbackTargetItem(metadata);
    if (target == null) return null;

    // Profile-scoped in the app; nullable so a bare detail screen (widget
    // tests) still previews with the ladder's non-profile tiers.
    final probed = _probedPlaybackItems[target.id];
    final preview = probed == null
        ? null
        : previewPlaybackTracks(
            probed.item,
            probed.source,
            profile: context.read<AccountPreferencesController?>()?.activePreferences,
          );
    final videoLabels = buildMediaVideoLabels(target);
    if (preview == null && videoLabels.isEmpty) return null;
    if (preview == null) _scheduleTargetProbe(context, target);

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
