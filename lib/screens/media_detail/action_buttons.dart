part of '../media_detail_screen.dart';

extension _MediaDetailActionButtons on _MediaDetailScreenState {
  Widget _buildActionButtons(MediaItem metadata) {
    final isTv = PlatformDetector.isTV();
    final tvScale = TvLayoutConstants.scaleOf(context);
    final actionSize = isTv ? _tvDetailActionSize * tvScale : 48.0;
    final playButtonLabel = _getPlayButtonLabel(metadata);
    final playIconSize = isTv ? 22 * tvScale : 20.0;
    final playTextStyle = TextStyle(fontSize: isTv ? 17 * tvScale : 16, fontWeight: .w700);
    final playButtonIcon = AppIcon(_getPlayButtonIcon(metadata), fill: 1, size: playIconSize);

    Future<void> onPlayPressed() async {
      // For TV shows, play the OnDeck episode if available
      // Otherwise, play the first episode of the first season
      if (metadata.isShow) {
        if (_onDeckEpisode != null) {
          appLogger.d('Playing on deck episode: ${_onDeckEpisode!.title}');
          await navigateToVideoPlayerWithRefresh(
            context,
            metadata: _onDeckEpisode!,
            isOffline: widget.isOffline,
            onRefresh: _loadFullMetadata,
          );
        } else {
          // No on deck episode, fetch first episode of first season
          await _playFirstEpisode();
        }
      } else if (metadata.isSeason) {
        // For seasons, play the first episode
        if (_episodes.isNotEmpty) {
          await navigateToVideoPlayerWithRefresh(
            context,
            metadata: _episodes.first,
            isOffline: widget.isOffline,
            onRefresh: _loadFullMetadata,
          );
        } else {
          await _playFirstEpisode();
        }
      } else {
        appLogger.d('Playing: ${metadata.title}');
        // For movies or episodes, play directly
        await navigateToVideoPlayerWithRefresh(
          context,
          metadata: metadata,
          isOffline: widget.isOffline,
          onRefresh: _loadFullMetadata,
        );
      }
    }

    final primaryTrailer = _getPrimaryTrailer();

    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final colorScheme = Theme.of(context).colorScheme;

    // In keyboard/d-pad mode, focused buttons get a prominent style.
    // overlayColor is set to transparent to prevent the Material focus
    // overlay from dimming the background color we set.
    final focusBg = colorScheme.inverseSurface;
    final focusFg = colorScheme.onInverseSurface;
    final tonalBg = colorScheme.secondaryContainer;
    final idleBg = isTv ? tonalBg.withValues(alpha: 0.38) : tonalBg;
    final tonalFg = colorScheme.onSecondaryContainer;
    final noOverlay = WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) return Colors.transparent;
      return null; // default for other states
    });

    ButtonStyle actionButtonStyle({Color? foregroundColor, EdgeInsetsGeometry? padding, bool showFocus = false}) {
      if (!isKeyboardMode && !isTv) {
        if (padding != null) {
          return FilledButton.styleFrom(padding: padding);
        }
        return IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          maximumSize: const Size(48, 48),
          foregroundColor: foregroundColor,
        );
      }

      return ButtonStyle(
        padding: padding != null ? WidgetStatePropertyAll(padding) : null,
        minimumSize: WidgetStatePropertyAll(padding == null ? Size.square(actionSize) : Size(0, actionSize)),
        maximumSize: padding == null ? WidgetStatePropertyAll(Size.square(actionSize)) : null,
        fixedSize: padding == null ? WidgetStatePropertyAll(Size.square(actionSize)) : null,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        overlayColor: noOverlay,
        backgroundColor: WidgetStatePropertyAll(showFocus ? focusBg : idleBg),
        foregroundColor: WidgetStatePropertyAll(showFocus ? focusFg : foregroundColor ?? tonalFg),
      );
    }

    // Plays the resolved trailer. Shared by the row's trailer button and the
    // ⋮ menu item so the trailer stays reachable when the row hides its button.
    final VoidCallback? onPlayTrailer = primaryTrailer == null
        ? null
        : () => unawaited(navigateToVideoPlayer(context, metadata: primaryTrailer));

    final gap = isTv ? 8.0 * tvScale : 12.0;

    Widget playButton(FocusableActionBuildState state) {
      return SizedBox(
        height: actionSize,
        child: FilledButton(
          onPressed: onPlayPressed,
          style: actionButtonStyle(
            showFocus: state.showFocus,
            padding: .symmetric(horizontal: isTv ? 17 * tvScale : 16, vertical: isTv ? 9 * tvScale : 0),
          ),
          child: playButtonLabel.isNotEmpty
              ? Row(
                  mainAxisSize: .min,
                  children: [
                    playButtonIcon,
                    SizedBox(width: isTv ? 7 * tvScale : 8),
                    Text(playButtonLabel, style: playTextStyle),
                  ],
                )
              : playButtonIcon,
        ),
      );
    }

    Widget iconActionButton(
      FocusableActionBuildState state, {
      required Widget icon,
      required VoidCallback? onPressed,
      String? tooltip,
      Color? foregroundColor,
    }) {
      return IconButton.filledTonal(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        iconSize: isTv ? 21 * tvScale : 20,
        style: actionButtonStyle(foregroundColor: foregroundColor, showFocus: state.showFocus),
      );
    }

    final playAction = FocusableAction(
      debugLabel: 'detail_play',
      focusNode: _playButtonFocusNode,
      autofocus: isKeyboardMode,
      onPressed: onPlayPressed,
      builder: (context, state) => playButton(state),
    );

    final trailerAction = primaryTrailer == null
        ? null
        : FocusableAction(
            debugLabel: 'detail_trailer',
            onPressed: onPlayTrailer,
            builder: (context, state) => iconActionButton(
              state,
              onPressed: onPlayTrailer,
              icon: const AppIcon(Symbols.theaters_rounded, fill: 1),
              tooltip: t.tooltips.playTrailer,
            ),
          );

    final shuffleAction = (metadata.isShow || metadata.isSeason)
        ? FocusableAction(
            debugLabel: 'detail_shuffle',
            onPressed: () async {
              await _handleShufflePlayWithQueue(context, metadata);
            },
            builder: (context, state) => iconActionButton(
              state,
              onPressed: () async {
                await _handleShufflePlayWithQueue(context, metadata);
              },
              icon: const AppIcon(Symbols.shuffle_rounded, fill: 1),
              tooltip: t.tooltips.shufflePlay,
            ),
          )
        : null;

    final downloadAction = !widget.isOffline && !PlatformDetector.isAppleTV()
        ? FocusableAction(
            debugLabel: 'detail_download',
            onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
            builder: (context, state) =>
                _buildDownloadButton(metadata, actionButtonStyle, tvScale, showFocus: state.showFocus),
          )
        : null;

    final watchedAction = FocusableAction(
      debugLabel: 'detail_watched',
      onPressed: () => unawaited(_handleWatchedTogglePressed(metadata)),
      builder: (context, state) =>
          _buildWatchedToggleButton(metadata, actionButtonStyle, tvScale, showFocus: state.showFocus),
    );

    void showMoreActions() => _contextMenuKey.currentState?.showContextMenu(context);

    final moreActionsAction = widget.isOffline
        ? null
        : FocusableAction(
            debugLabel: 'detail_more',
            onPressed: showMoreActions,
            builder: (context, state) => _buildMoreActionsButton(
              metadata,
              actionButtonStyle,
              tvScale,
              onPlayTrailer: onPlayTrailer,
              showFocus: state.showFocus,
            ),
          );

    final allActions = <FocusableAction>[
      playAction,
      ?trailerAction,
      ?shuffleAction,
      ?downloadAction,
      watchedAction,
      ?moreActionsAction,
    ];

    double playButtonWidthEstimate() {
      if (playButtonLabel.isEmpty) return 64.0;
      final textPainter = TextPainter(
        text: TextSpan(text: playButtonLabel, style: playTextStyle),
        maxLines: 1,
        textDirection: Directionality.of(context),
      )..layout();
      final textWidth = textPainter.width;
      textPainter.dispose();
      final horizontalPadding = isTv ? 34.0 * tvScale : 32.0;
      final iconGap = isTv ? 7.0 * tvScale : 8.0;
      return (horizontalPadding + playIconSize + iconGap + textWidth).clamp(64.0, double.infinity).toDouble();
    }

    final estimatedPlayWidth = playButtonWidthEstimate();
    double estimatedRowWidth(List<FocusableAction> actions) {
      if (actions.isEmpty) return 0;
      return estimatedPlayWidth + (actions.length - 1) * actionSize + (actions.length - 1) * gap;
    }

    List<FocusableAction> compactActionsFor(double maxWidth) {
      if (widget.isOffline) {
        final compact = <FocusableAction>[playAction, watchedAction];
        if (maxWidth.isFinite && estimatedRowWidth(compact) > maxWidth) return [playAction];
        return compact;
      }

      final medium = <FocusableAction>[playAction, ?downloadAction, watchedAction, ?moreActionsAction];
      if (!maxWidth.isFinite || estimatedRowWidth(medium) <= maxWidth) return medium;

      final compact = <FocusableAction>[playAction, watchedAction, ?moreActionsAction];
      if (estimatedRowWidth(compact) <= maxWidth) return compact;

      return [playAction, ?moreActionsAction];
    }

    Widget actionBar(List<FocusableAction> actions) {
      return FocusableActionBar(
        actions: actions,
        spacing: gap,
        onFocusChange: isTv ? _setTvDetailActionRowFocus : null,
        onNavigateUp: _focusAboveActionRow,
        onNavigateDown: _focusBelowActionRow,
      );
    }

    // TV screens are wide and D-pad focus should see every direct action.
    // On smaller online screens, hidden actions remain available from ⋮.
    if (isTv) return actionBar(allActions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || estimatedRowWidth(allActions) <= maxWidth) {
          return actionBar(allActions);
        }
        return actionBar(compactActionsFor(maxWidth));
      },
    );
  }

  Future<void> _handleWatchedTogglePressed(MediaItem metadata) async {
    try {
      final isWatched = metadata.isWatched;
      final outcome = await WatchActions.setWatched(context, metadata, watched: !isWatched, offline: widget.isOffline);
      if (!mounted) return;
      switch (outcome) {
        case WatchMarkOutcome.queuedOffline:
          showAppSnackBar(context, isWatched ? t.messages.markedAsUnwatchedOffline : t.messages.markedAsWatchedOffline);
        case WatchMarkOutcome.marked:
          _watchStateChanged = true;
          showSuccessSnackBar(context, isWatched ? t.messages.markedAsUnwatched : t.messages.markedAsWatched);
        case WatchMarkOutcome.skipped:
          break;
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  Widget _buildWatchedToggleButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding, required bool showFocus})
    actionButtonStyle,
    double tvScale, {
    bool showFocus = false,
  }) {
    return IconButton.filledTonal(
      onPressed: () => unawaited(_handleWatchedTogglePressed(metadata)),
      icon: AppIcon(metadata.isWatched ? Symbols.remove_done_rounded : Symbols.check_rounded, fill: 1),
      tooltip: metadata.isWatched ? t.tooltips.markAsUnwatched : t.tooltips.markAsWatched,
      iconSize: PlatformDetector.isTV() ? 21 * tvScale : 20,
      style: actionButtonStyle(showFocus: showFocus),
    );
  }

  Widget _buildMoreActionsButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding, required bool showFocus})
    actionButtonStyle,
    double tvScale, {
    VoidCallback? onPlayTrailer,
    bool showFocus = false,
  }) {
    return MediaContextMenu(
      key: _contextMenuKey,
      item: metadata,
      onRefresh: (itemId) => unawaited(_refreshItemInPlace(itemId)),
      onPlayTrailer: onPlayTrailer,
      child: Builder(
        builder: (buttonContext) => IconButton.filledTonal(
          onPressed: () {
            final renderBox = buttonContext.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
              _contextMenuKey.currentState?.showContextMenu(buttonContext, position: position);
            }
          },
          icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
          iconSize: PlatformDetector.isTV() ? 21 * tvScale : 20,
          style: actionButtonStyle(showFocus: showFocus),
        ),
      ),
    );
  }

  Future<void> _handleDownloadButtonPressed(MediaItem metadata) async {
    final downloadProvider = context.read<DownloadProvider>();
    final globalKey = metadata.globalKey;
    final ruleKey = _syncRuleKeyForMetadata(context, downloadProvider, metadata);
    final progress = downloadProvider.getProgress(globalKey);

    if (downloadProvider.isQueueing(globalKey) ||
        progress?.status == DownloadStatus.queued ||
        progress?.status == DownloadStatus.downloading) {
      return;
    }

    if (progress?.status == DownloadStatus.paused) {
      final client = _getMediaClientForMetadata(context);
      if (client == null) return;
      await downloadProvider.resumeDownload(globalKey, client);
      if (mounted) showAppSnackBar(context, t.downloads.downloadResumed);
      return;
    }

    if (progress?.status == DownloadStatus.failed) {
      final client = _getMediaClientForMetadata(context);
      if (client == null) return;

      final versionConfig = await _resolveDownloadVersion(context, metadata, client);
      if (versionConfig == null || !mounted) return;

      await downloadProvider.deleteDownload(globalKey);
      try {
        await downloadProvider.queueDownload(metadata, client, versionConfig: versionConfig);
        if (mounted) showSuccessSnackBar(context, t.downloads.downloadQueued);
      } on CellularDownloadBlockedException {
        if (mounted) showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
      return;
    }

    if (progress?.status == DownloadStatus.cancelled) {
      final retry = await showConfirmDialog(
        context,
        title: t.downloads.cancelledDownloadTitle,
        message: t.downloads.cancelledDownloadMessage,
        cancelText: t.common.delete,
        confirmText: t.common.retry,
      );

      if (!retry && mounted) {
        await downloadProvider.deleteDownload(globalKey);
        if (mounted) showSuccessSnackBar(context, t.downloads.downloadDeleted);
      } else if (retry && mounted) {
        final client = _getMediaClientForMetadata(context);
        if (client == null) return;

        final versionConfig = await _resolveDownloadVersion(context, metadata, client);
        if (versionConfig == null || !mounted) return;

        await downloadProvider.deleteDownload(globalKey);
        try {
          await downloadProvider.queueDownload(metadata, client, versionConfig: versionConfig);
          if (mounted) showSuccessSnackBar(context, t.downloads.downloadQueued);
        } on CellularDownloadBlockedException {
          if (mounted) showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
        }
      }
      return;
    }

    if (progress?.status == DownloadStatus.partial) {
      if (downloadProvider.hasSyncRule(ruleKey)) {
        await _showSyncRuleActions(context, downloadProvider, metadata, ruleKey: ruleKey, downloadGlobalKey: globalKey);
        return;
      }

      final client = _getMediaClientForMetadata(context);
      if (client == null) return;

      final versionConfig = await _resolveDownloadVersion(context, metadata, client);
      if (versionConfig == null || !mounted) return;

      final count = await downloadProvider.queueMissingEpisodes(metadata, client, versionConfig: versionConfig);
      if (mounted) {
        final message = count > 0 ? t.downloads.episodesQueued(count: count) : t.downloads.allEpisodesAlreadyDownloaded;
        showAppSnackBar(context, message);
      }
      return;
    }

    if (downloadProvider.isDownloaded(globalKey)) {
      if (downloadProvider.hasSyncRule(ruleKey)) {
        await _showSyncRuleActions(context, downloadProvider, metadata, ruleKey: ruleKey, downloadGlobalKey: globalKey);
        return;
      }

      final canDownloadMore = metadata.isShow || metadata.isSeason;
      Future<void> confirmAndDelete() async {
        final confirmed = await showDeleteConfirmation(
          context,
          title: t.downloads.deleteDownload,
          message: t.downloads.deleteConfirm(title: metadata.displayTitle),
        );
        if (confirmed && mounted) {
          await downloadProvider.deleteDownload(globalKey);
          if (mounted) showSuccessSnackBar(context, t.downloads.downloadDeleted);
        }
      }

      if (!canDownloadMore) {
        await confirmAndDelete();
        return;
      }

      final client = _getMediaClientForMetadata(context);
      if (client == null) return;
      try {
        final result = await showDownloadOptionsAndQueue(
          context,
          metadata: metadata,
          client: client,
          downloadProvider: downloadProvider,
          onDelete: confirmAndDelete,
        );
        if (result == null || !mounted) return;
        showSuccessSnackBar(context, result.toSnackBarMessage());
      } on CellularDownloadBlockedException {
        if (mounted) showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
      return;
    }

    final client = _getMediaClientForMetadata(context);
    if (client == null) return;

    try {
      final result = await showDownloadOptionsAndQueue(
        context,
        metadata: metadata,
        client: client,
        downloadProvider: downloadProvider,
      );
      if (result == null || !mounted) return;

      showSuccessSnackBar(context, result.toSnackBarMessage());
    } on CellularDownloadBlockedException {
      if (mounted) showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
    }
  }

  Widget _buildDownloadButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding, required bool showFocus})
    actionButtonStyle,
    double tvScale, {
    bool showFocus = false,
  }) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final iconSize = PlatformDetector.isTV() ? 21.0 * tvScale : 20.0;
        final globalKey = metadata.globalKey;
        final ruleKey = _syncRuleKeyForMetadata(context, downloadProvider, metadata);
        final progress = downloadProvider.getProgress(globalKey);
        final isQueueing = downloadProvider.isQueueing(globalKey);

        // Debug logging
        if (progress != null) {
          appLogger.d('UI rebuilding for $globalKey: status=${progress.status}, progress=${progress.progress}%');
        }

        // State 1: Queueing (building download queue)
        if (isQueueing) {
          return IconButton.filledTonal(
            onPressed: null,
            icon: LoadingIndicatorBox(size: iconSize),
            iconSize: iconSize,
            style: actionButtonStyle(showFocus: showFocus),
          );
        }

        // State 2: Queued (waiting to download)
        if (progress?.status == DownloadStatus.queued) {
          final currentFile = progress?.currentFile;
          final tooltip = currentFile != null && currentFile.contains('episodes')
              ? t.downloads.queuedFilesTooltip(files: currentFile)
              : t.downloads.queuedTooltip;

          return IconButton.filledTonal(
            onPressed: null,
            tooltip: tooltip,
            icon: const AppIcon(Symbols.schedule_rounded, fill: 1),
            iconSize: iconSize,
            style: actionButtonStyle(showFocus: showFocus),
          );
        }

        // State 3: Downloading (active download)
        if (progress?.status == DownloadStatus.downloading) {
          // Show episode count in tooltip for shows/seasons
          final currentFile = progress?.currentFile;
          final tooltip = currentFile != null && currentFile.contains('episodes')
              ? t.downloads.downloadingFilesTooltip(files: currentFile)
              : t.downloads.downloadingTooltip;

          return IconButton.filledTonal(
            onPressed: null,
            tooltip: tooltip,
            icon: _buildRadialProgress(progress?.progressPercent),
            iconSize: iconSize,
            style: actionButtonStyle(showFocus: showFocus),
          );
        }

        // State 4: Paused (can resume)
        if (progress?.status == DownloadStatus.paused) {
          return IconButton.filledTonal(
            onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
            icon: const AppIcon(Symbols.pause_circle_outline_rounded, fill: 1),
            tooltip: t.downloads.resumeDownload,
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.amber, showFocus: showFocus),
          );
        }

        // State 5: Failed (can retry)
        if (progress?.status == DownloadStatus.failed) {
          return IconButton.filledTonal(
            onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
            icon: const AppIcon(Symbols.error_outline_rounded, fill: 1),
            tooltip: t.downloads.retryDownload,
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.red, showFocus: showFocus),
          );
        }

        // State 6: Cancelled (can delete or retry)
        if (progress?.status == DownloadStatus.cancelled) {
          return IconButton.filledTonal(
            onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
            icon: const AppIcon(Symbols.cancel_rounded, fill: 1),
            tooltip: t.downloads.cancelledDownload,
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.grey, showFocus: showFocus),
          );
        }

        // State 7: Partial Download (some episodes downloaded, not all)
        if (progress?.status == DownloadStatus.partial) {
          final hasSyncRule = downloadProvider.hasSyncRule(ruleKey);
          final currentFile = progress?.currentFile;

          if (hasSyncRule) {
            // Synced partial — this is the normal state for sync rules
            final syncRule = downloadProvider.getSyncRule(ruleKey);
            final isEnabled = syncRule?.enabled ?? true;
            final tooltip = currentFile != null
                ? t.downloads.syncingFile(
                    file: currentFile,
                    status: t.downloads.keepNUnwatched(count: syncRule?.episodeCount.toString() ?? '?'),
                  )
                : t.downloads.keepSynced;

            return IconButton.filledTonal(
              onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
              tooltip: tooltip,
              icon: AppIcon(isEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
              iconSize: iconSize,
              style: actionButtonStyle(foregroundColor: isEnabled ? Colors.teal : Colors.grey, showFocus: showFocus),
            );
          }

          final tooltip = currentFile != null
              ? t.downloads.downloadedFileClickToComplete(file: currentFile)
              : t.downloads.partialDownloadClickToComplete;

          return IconButton.filledTonal(
            onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
            tooltip: tooltip,
            icon: const AppIcon(Symbols.downloading_rounded, fill: 1),
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.orange, showFocus: showFocus),
          );
        }

        // State 8: Downloaded/Completed (can delete)
        if (downloadProvider.isDownloaded(globalKey)) {
          final hasSyncRule = downloadProvider.hasSyncRule(ruleKey);

          if (hasSyncRule) {
            // Synced + complete — show sync icon
            final syncRule = downloadProvider.getSyncRule(ruleKey);
            final isEnabled = syncRule?.enabled ?? true;
            return IconButton.filledTonal(
              onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
              icon: AppIcon(isEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
              tooltip: t.downloads.keepNUnwatched(count: syncRule?.episodeCount.toString() ?? '?'),
              iconSize: iconSize,
              style: actionButtonStyle(foregroundColor: isEnabled ? Colors.teal : Colors.grey, showFocus: showFocus),
            );
          }

          // Shows/seasons may have more episodes to fetch; movies/episodes don't.
          final canDownloadMore = metadata.isShow || metadata.isSeason;

          return IconButton.filledTonal(
            onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
            icon: const AppIcon(Symbols.download_rounded, fill: 1),
            tooltip: canDownloadMore ? t.downloads.manage : t.downloads.deleteDownload,
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.orange, showFocus: showFocus),
          );
        }

        // State 9: Not downloaded (default - can download)
        return IconButton.filledTonal(
          onPressed: () => unawaited(_handleDownloadButtonPressed(metadata)),
          icon: const AppIcon(Symbols.download_rounded, fill: 1),
          tooltip: t.downloads.downloadNow,
          iconSize: iconSize,
          style: actionButtonStyle(showFocus: showFocus),
        );
      },
    );
  }
}
