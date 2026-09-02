part of '../media_detail_screen.dart';

/// The action row's trailing status: what Play will do with this item's
/// picture, audio, and subtitles, computed by the player's own selection
/// ladder ([previewPlaybackTracks]). Activating it opens the pre-play chooser.
extension _MediaDetailPlaybackTracksAction on _MediaDetailScreenState {
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
    return _probedPlaybackItems[target.id] ?? target;
  }

  PlaybackTrackPreview? _playbackTrackPreview(BuildContext context, MediaItem target) {
    // Profile-scoped in the app; nullable so a bare detail screen (widget
    // tests) still previews with the ladder's non-profile tiers.
    return previewPlaybackTracks(
      target,
      profile: context.read<AccountPreferencesController?>()?.activePreferences,
      choice: _playbackTrackChoice,
    );
  }

  /// Plex listings describe a file only by its container summary, so an
  /// episode reached through the rail has no stream rows until its own item
  /// is fetched. One request per item, debounced past D-pad scrubbing, cached
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
    try {
      fetched = await client.fetchItem(target.id);
    } catch (e, stackTrace) {
      appLogger.d('Playback track probe failed for ${target.id}', error: e, stackTrace: stackTrace);
      return;
    }
    if (!mounted || fetched == null) return;
    final probed = fetched.copyWith(
      serverId: target.serverId ?? fetched.serverId,
      serverName: target.serverName ?? fetched.serverName,
    );
    // A summary-only answer is not worth caching: the chooser retries on demand.
    if (previewPlaybackTracks(probed) == null) return;
    _probedPlaybackItems[target.id] = probed;
    if (_tvDetailFocusedEpisode.value?.id == target.id) {
      _tvDetailFocusedEpisode.value = probed;
    } else {
      setStateIfMounted(() {});
    }
  }

  /// Null when there is nothing to say: no version at all, or a container
  /// summary without a resolution.
  FocusableAction? _buildPlaybackTracksAction(
    BuildContext context,
    MediaItem metadata, {
    required bool isTv,
    required double tvScale,
    required double actionSize,
    required double maxWidth,
  }) {
    final target = _playbackTargetItem(metadata);
    if (target == null) return null;

    final preview = _playbackTrackPreview(context, target);
    final videoLabels = buildMediaVideoLabels(target);
    if (preview == null && videoLabels.isEmpty) return null;
    if (preview == null) _scheduleTargetProbe(context, target);

    final audioLabel = preview?.audio?.label;
    final subtitleLabel = preview?.subtitle?.label;
    final parts = <MetadataLinePart>[
      // Shed order on a tight row: the long codec details first (subtitle's,
      // then audio's — the sheet has them in full), then the short picture
      // labels, then the audio track; the subtitle decision always stays.
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

    final canChoose =
        preview == null || preview.source.audioTracks.length > 1 || preview.source.subtitleTracks.isNotEmpty;
    final VoidCallback? onPressed = canChoose && !widget.isOffline
        ? () => unawaited(_openPlaybackTrackChooser(context, target))
        : null;

    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontSize: isTv ? 14 * tvScale : 12.5,
      fontWeight: .w600,
      letterSpacing: 0.1,
      height: 1.2,
    );
    final horizontalPadding = isTv ? 12 * tvScale : 10.0;

    return FocusableAction(
      debugLabel: 'detail_playback_tracks',
      onPressed: onPressed,
      builder: (context, state) {
        final foreground = state.showFocus
            ? colorScheme.onInverseSurface
            : colorScheme.onSurface.withValues(alpha: onPressed == null ? 0.6 : 0.78);
        return Semantics(
          label: semanticsLabel,
          button: onPressed != null,
          onTap: onPressed,
          excludeSemantics: true,
          child: SizedBox(
            height: actionSize,
            child: TextButton(
              onPressed: onPressed,
              style: ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: horizontalPadding)),
                minimumSize: WidgetStatePropertyAll(Size(0, actionSize)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStatePropertyAll(
                  state.showFocus ? colorScheme.inverseSurface : Colors.transparent,
                ),
                foregroundColor: WidgetStatePropertyAll(foreground),
                overlayColor: WidgetStatePropertyAll(state.showFocus ? Colors.transparent : null),
                shape: const WidgetStatePropertyAll(StadiumBorder()),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth - horizontalPadding * 2),
                child: FittedMetadataLine(
                  textStyle: textStyle.copyWith(color: foreground),
                  parts: parts,
                  ratingIconSize: textStyle.fontSize! * 1.15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The screen's choice expressed in [target]'s own rows: made on this item
  /// it is passed through; made elsewhere it is the ladder's resolution of
  /// its semantics against this item (see [PlaybackTrackChoice.itemId]).
  /// Members the viewer never chose stay null so the ladder keeps deciding.
  PlaybackTrackChoice _choiceFor(BuildContext context, MediaItem target) {
    final choice = _playbackTrackChoice;
    if (choice.isEmpty || choice.itemId == target.id) return choice;
    final preview = _playbackTrackPreview(context, _probedPlaybackItems[target.id] ?? target);
    if (preview == null) return choice;
    return PlaybackTrackChoice(
      itemId: target.id,
      audio: choice.audio == null ? null : preview.audioTrack,
      subtitle: choice.subtitle == null ? null : preview.subtitleTrack,
    );
  }

  /// Every Play path from this screen goes through here so the chooser's
  /// pick reaches the player as its navigation-tier preference.
  Future<void> _navigateToPlayerWithTrackChoice(MediaItem item) {
    final choice = _choiceFor(context, item);
    return navigateToVideoPlayerWithRefresh(
      context,
      metadata: item,
      isOffline: widget.isOffline,
      onRefresh: _refreshWatchState,
      preferredAudioTrack: choice.audio,
      preferredSubtitleTrack: choice.subtitle,
    );
  }

  Future<void> _openPlaybackTrackChooser(BuildContext context, MediaItem target) async {
    var preview = _playbackTrackPreview(context, target);
    if (preview == null) {
      // The listing only carried the container summary; the full item has the
      // stream rows. One request, on an explicit user action.
      final client = _getMediaClientForMetadata(context);
      final fetched = client == null ? null : await client.fetchItem(target.id);
      if (!context.mounted) return;
      if (fetched != null) {
        preview = _playbackTrackPreview(context, fetched);
        if (preview != null) setStateIfMounted(() => _probedPlaybackItems[target.id] = fetched);
      }
    }
    if (preview == null) {
      showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
      return;
    }
    final resolved = preview;
    final source = resolved.source;
    if (source.audioTracks.length <= 1 && source.subtitleTracks.isEmpty) return;

    await OverlaySheetController.showAdaptive<void>(
      context,
      isScrollControlled: true,
      builder: (_) => PlaybackTrackChooserSheet(
        source: source,
        effectiveAudio: resolved.audio,
        effectiveSubtitle: resolved.subtitle,
        choice: _choiceFor(context, target).copyWith(itemId: target.id),
        onChanged: (choice) => setStateIfMounted(() => _playbackTrackChoice = choice),
      ),
    );
  }
}
