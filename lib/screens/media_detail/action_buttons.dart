part of '../media_detail_screen.dart';

extension _MediaDetailActionButtons on _MediaDetailScreenState {
  Widget _buildActionButtons(MediaItem metadata) {
    final isTv = PlatformDetector.isTV();
    final tvScale = TvLayoutConstants.scaleOf(context);
    final actionSize = isTv ? _tvDetailActionSize * tvScale : 48.0;
    final playButtonLabel = _getPlayButtonLabel(metadata);
    final playButtonIcon = AppIcon(_getPlayButtonIcon(metadata), fill: 1, size: isTv ? 22 * tvScale : 20);

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

    ButtonStyle actionButtonStyle({Color? foregroundColor, EdgeInsetsGeometry? padding}) {
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
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return focusBg;
          return idleBg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return focusFg;
          return foregroundColor ?? tonalFg;
        }),
      );
    }

    // Predicted widths feed the narrow-screen drop logic in
    // [DetailActionsRow]. Icon-only buttons match the styled action size;
    // the play button's width depends on its (possibly long, possibly
    // localized) label, so it's measured with a TextPainter. The gap
    // matches the SizedBox spacing the old Row used between siblings.
    final double gap = isTv ? 8 * tvScale : 12.0;
    final playLabelStyle = TextStyle(fontSize: isTv ? 17 * tvScale : 16.0, fontWeight: FontWeight.w700);
    final double playIconSize = isTv ? 22 * tvScale : 20.0;
    final double playHorizontalPadding = isTv ? 17 * tvScale : 16.0;
    final double playIconLabelGap = isTv ? 7 * tvScale : 8.0;
    final double playVerticalPadding = isTv ? 9 * tvScale : 0.0;
    final double playButtonWidth;
    if (playButtonLabel.isEmpty) {
      // No label — FilledButton renders only the icon, ~square at actionSize.
      playButtonWidth = actionSize;
    } else {
      final painter = TextPainter(
        text: TextSpan(text: playButtonLabel, style: playLabelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      playButtonWidth = playHorizontalPadding * 2 + playIconSize + playIconLabelGap + painter.width;
    }

    final trailerButton = primaryTrailer == null
        ? null
        : IconButton.filledTonal(
            onPressed: () async {
              await navigateToVideoPlayer(context, metadata: primaryTrailer);
            },
            icon: const AppIcon(Symbols.theaters_rounded, fill: 1),
            tooltip: t.tooltips.playTrailer,
            iconSize: isTv ? 21 * tvScale : 20,
            style: actionButtonStyle(),
          );

    final actions = <DetailAction>[
      DetailAction(
        predictedWidth: playButtonWidth,
        child: SizedBox(
          height: actionSize,
          child: FilledButton(
            focusNode: _playButtonFocusNode,
            autofocus: isKeyboardMode,
            onPressed: onPlayPressed,
            style: actionButtonStyle(
              padding: EdgeInsets.symmetric(horizontal: playHorizontalPadding, vertical: playVerticalPadding),
            ),
            child: playButtonLabel.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      playButtonIcon,
                      SizedBox(width: playIconLabelGap),
                      Text(playButtonLabel, style: playLabelStyle),
                    ],
                  )
                : playButtonIcon,
          ),
        ),
      ),
      // Trailer button (only if trailer is available). Drops after Watched.
      if (trailerButton != null) DetailAction(predictedWidth: actionSize, dropPriority: 2, child: trailerButton),
      // Combined "Play random" button (only for shows and seasons). On multi-
      // season shows it opens a picker letting the user choose between
      // shuffling the whole show and shuffling the current season; on
      // single-season shows and season detail pages there's only one
      // meaningful action, so it shuffles directly. Drops last of the three.
      if (metadata.isShow || metadata.isSeason)
        DetailAction(
          predictedWidth: actionSize,
          dropPriority: 1,
          child: _buildPlayRandomButton(metadata, actionButtonStyle, tvScale, isTv),
        ),
      // Download button (hide in offline mode - already downloaded, and on
      // Apple TV where there's no user file storage). Never dropped.
      if (!widget.isOffline && !PlatformDetector.isAppleTV())
        DetailAction(predictedWidth: actionSize, child: _buildDownloadButton(metadata, actionButtonStyle, tvScale)),
      // Mark as watched/unwatched toggle (works offline too). Drops first
      // when there isn't room — the same action is reachable from the
      // three-dots menu.
      DetailAction(
        predictedWidth: actionSize,
        dropPriority: 3,
        child: _buildWatchedToggleButton(metadata, actionButtonStyle, tvScale),
      ),
      // Three-dots menu button (hidden in offline mode). Never dropped —
      // dropping it would orphan any inline actions the menu also exposes.
      if (!widget.isOffline)
        DetailAction(
          predictedWidth: actionSize,
          child: _buildMoreActionsButton(metadata, actionButtonStyle, tvScale, primaryTrailer: primaryTrailer),
        ),
    ];

    return Focus(
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (isTv) _setTvDetailActionRowFocus(hasFocus);
      },
      onKeyEvent: _handlePlayButtonKeyEvent,
      child: DetailActionsRow(actions: actions, gap: gap),
    );
  }

  /// Builds the combined "Play random" action. On multi-season shows where
  /// the selected season has loaded, a tap opens a picker offering "All
  /// episodes" or the current season. Otherwise the picker is skipped —
  /// season detail pages and single-season shows shuffle directly because
  /// there's only one meaningful action to take.
  Widget _buildPlayRandomButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
    double tvScale,
    bool isTv,
  ) {
    return IconButton.filledTonal(
      onPressed: () async {
        await _handlePlayRandom(context, metadata);
      },
      icon: const AppIcon(Symbols.shuffle_rounded, fill: 1),
      tooltip: t.tooltips.playRandom,
      iconSize: isTv ? 21 * tvScale : 20,
      style: actionButtonStyle(),
    );
  }

  /// Routes a "Play random" tap. Season detail pages shuffle that season.
  /// Single-season shows shuffle the whole show. Multi-season shows with a
  /// loaded current season open a picker so the user can pick which scope.
  /// If the current season isn't ready yet, we degrade to shuffling the
  /// whole show — same end state the old disabled-season-button gave us.
  Future<void> _handlePlayRandom(BuildContext context, MediaItem metadata) async {
    if (metadata.isSeason) {
      await _handleShuffleCurrentSeason(context, metadata);
      return;
    }

    final season = _seasonForCurrentSeasonShuffle(metadata);
    final hasEpisodes = _episodes.isNotEmpty && !_isLoadingSeasonEpisodes;
    if (season == null || !hasEpisodes) {
      await _handleShufflePlayWithQueue(context, metadata);
      return;
    }

    // `title` is the season's own name ("Season 3", "Specials"); the season
    // tabs use the same field. `displayTitle` would hoist to the show name.
    final seasonTitle = season.title ?? '';
    final choice = await showOptionPickerDialog<_PlayRandomChoice>(
      context,
      title: t.tooltips.playRandom,
      options: [
        (
          icon: Symbols.shuffle_rounded,
          label: t.tooltips.playRandomAllEpisodes,
          value: _PlayRandomChoice.allEpisodes,
        ),
        (
          icon: Symbols.shuffle_on_rounded,
          label: seasonTitle,
          value: _PlayRandomChoice.currentSeason,
        ),
      ],
    );
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _PlayRandomChoice.allEpisodes:
        await _handleShufflePlayWithQueue(context, metadata);
      case _PlayRandomChoice.currentSeason:
        await _handleShuffleCurrentSeason(context, metadata);
    }
  }

  Widget _buildWatchedToggleButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
    double tvScale,
  ) {
    return IconButton.filledTonal(
      onPressed: () async {
        try {
          final isWatched = metadata.isWatched;
          if (widget.isOffline) {
            // Offline mode: queue action for later sync
            final offlineWatch = context.read<OfflineWatchProvider>();
            if (isWatched) {
              await offlineWatch.markAsUnwatched(serverId: metadata.serverId!, itemId: metadata.id);
            } else {
              await offlineWatch.markAsWatched(serverId: metadata.serverId!, itemId: metadata.id);
            }
            if (mounted) {
              showAppSnackBar(
                context,
                isWatched ? t.messages.markedAsUnwatchedOffline : t.messages.markedAsWatchedOffline,
              );
            }
          } else {
            // Online mode: dispatch via the right backend's neutral method so
            // Jellyfin items hit /UserPlayedItems and Plex items hit /:/scrobble.
            final serverId = metadata.serverId;
            if (serverId == null) return;
            final client = context.tryGetMediaClientForServer(serverId);
            if (client == null) return;

            if (isWatched) {
              await client.markUnwatched(metadata);
              unawaited(TrackerCoordinator.instance.markUnwatched(metadata, client));
            } else {
              await client.markWatched(metadata);
              unawaited(TrackerCoordinator.instance.markWatched(metadata, client));
            }
            if (mounted) {
              _watchStateChanged = true;
              showSuccessSnackBar(context, isWatched ? t.messages.markedAsUnwatched : t.messages.markedAsWatched);
            }
          }
        } catch (e) {
          if (mounted) {
            showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
          }
        }
      },
      icon: AppIcon(metadata.isWatched ? Symbols.remove_done_rounded : Symbols.check_rounded, fill: 1),
      tooltip: metadata.isWatched ? t.tooltips.markAsUnwatched : t.tooltips.markAsWatched,
      iconSize: PlatformDetector.isTV() ? 21 * tvScale : 20,
      style: actionButtonStyle(),
    );
  }

  Widget _buildMoreActionsButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
    double tvScale, {
    MediaItem? primaryTrailer,
  }) {
    return MediaContextMenu(
      key: _contextMenuKey,
      item: metadata,
      primaryTrailer: primaryTrailer,
      onShufflePlay: (metadata.isShow || metadata.isSeason) ? () => _handlePlayRandom(context, metadata) : null,
      onRefresh: (itemId) => unawaited(_refreshItemInPlace(itemId)),
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
          style: actionButtonStyle(),
        ),
      ),
    );
  }

  /// The season currently selected in the show's season tabs, when the
  /// download dialog should offer to restrict to it. Null for single-season
  /// shows (redundant) and when the viewed item is itself a season/movie.
  MediaItem? _selectedSeasonForDownload(MediaItem metadata) {
    if (!metadata.isShow) return null;
    if (_seasons.length < 2) return null;
    if (_selectedSeasonIndex < 0 || _selectedSeasonIndex >= _seasons.length) return null;
    final season = _seasons[_selectedSeasonIndex];
    return season.isSeason ? season : null;
  }

  Widget _buildDownloadButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
    double tvScale,
  ) {
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
            style: actionButtonStyle(),
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
            style: actionButtonStyle(),
          );
        }

        // State 3: Downloading (active download)
        if (progress?.status == DownloadStatus.downloading) {
          // Show episode count in tooltip for shows/seasons. Tappable so the
          // user can queue more episodes / set up a sync rule mid-download
          // instead of waiting for it to finish — routes through the same
          // dialog every other actionable button uses, which also means it
          // can no longer accidentally queue the entire series on a stray tap.
          final currentFile = progress?.currentFile;
          final baseTooltip = currentFile != null && currentFile.contains('episodes')
              ? t.downloads.downloadingFilesTooltip(files: currentFile)
              : t.downloads.downloadingTooltip;
          final tooltip = '$baseTooltip — tap to add more or sync';

          return IconButton.filledTonal(
            onPressed: () async {
              final client = _getMediaClientForMetadata(context);
              if (client == null) return;

              try {
                final result = await showDownloadOptionsAndQueue(
                  context,
                  metadata: metadata,
                  client: client,
                  downloadProvider: downloadProvider,
                  currentSeason: _selectedSeasonForDownload(metadata),
                );
                if (result == null || !context.mounted) return;
                showSuccessSnackBar(context, result.toSnackBarMessage());
              } on CellularDownloadBlockedException {
                if (context.mounted) {
                  showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                }
              }
            },
            tooltip: tooltip,
            icon: _buildRadialProgress(progress?.progressPercent),
            iconSize: iconSize,
            style: actionButtonStyle(),
          );
        }

        // State 4: Paused (can resume)
        if (progress?.status == DownloadStatus.paused) {
          return IconButton.filledTonal(
            onPressed: () async {
              final client = _getMediaClientForMetadata(context);
              if (client == null) return;
              await downloadProvider.resumeDownload(globalKey, client);
              if (context.mounted) {
                showAppSnackBar(context, 'Download resumed');
              }
            },
            icon: const AppIcon(Symbols.pause_circle_outline_rounded, fill: 1),
            tooltip: 'Resume download',
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.amber),
          );
        }

        // State 5: Failed (can retry)
        if (progress?.status == DownloadStatus.failed) {
          return IconButton.filledTonal(
            onPressed: () async {
              final client = _getMediaClientForMetadata(context);
              if (client == null) return;

              final versionConfig = await _resolveDownloadVersion(context, metadata, client);
              if (versionConfig == null || !context.mounted) return;

              await downloadProvider.deleteDownload(globalKey);
              try {
                await downloadProvider.queueDownload(metadata, client, versionConfig: versionConfig);

                if (context.mounted) {
                  showSuccessSnackBar(context, t.downloads.downloadQueued);
                }
              } on CellularDownloadBlockedException {
                if (context.mounted) {
                  showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                }
              }
            },
            icon: const AppIcon(Symbols.error_outline_rounded, fill: 1),
            tooltip: 'Retry download',
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.red),
          );
        }

        // State 6: Cancelled (can delete or retry)
        if (progress?.status == DownloadStatus.cancelled) {
          return IconButton.filledTonal(
            onPressed: () async {
              // Show options: Delete or Retry
              final retry = await showConfirmDialog(
                context,
                title: 'Cancelled Download',
                message: 'This download was cancelled. What would you like to do?',
                cancelText: t.common.delete,
                confirmText: 'Retry',
              );

              if (!retry && context.mounted) {
                await downloadProvider.deleteDownload(globalKey);
                if (context.mounted) {
                  showSuccessSnackBar(context, t.downloads.downloadDeleted);
                }
              } else if (retry && context.mounted) {
                final client = _getMediaClientForMetadata(context);
                if (client == null) return;

                final versionConfig = await _resolveDownloadVersion(context, metadata, client);
                if (versionConfig == null || !context.mounted) return;

                await downloadProvider.deleteDownload(globalKey);
                try {
                  await downloadProvider.queueDownload(metadata, client, versionConfig: versionConfig);
                  if (context.mounted) {
                    showSuccessSnackBar(context, t.downloads.downloadQueued);
                  }
                } on CellularDownloadBlockedException {
                  if (context.mounted) {
                    showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                  }
                }
              }
            },
            icon: const AppIcon(Symbols.cancel_rounded, fill: 1),
            tooltip: 'Cancelled download',
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.grey),
          );
        }

        // State 7: Partial Download (some episodes downloaded, not all)
        if (progress?.status == DownloadStatus.partial) {
          final currentFile = progress?.currentFile;
          // Collect any sync rules that govern this view — the show's own rule
          // when present, plus any season-scoped rules that "Download only from
          // {season}" may have created against children of this show.
          final scopedRules = _collectScopedSyncRules(context, downloadProvider, metadata, ruleKey);

          if (scopedRules.isNotEmpty) {
            final anyEnabled = scopedRules.any((r) => r.rule.enabled);
            final tooltip = _scopedSyncTooltip(metadata, scopedRules, currentFile);
            return IconButton.filledTonal(
              onPressed: () => _manageScopedSyncRules(
                context,
                downloadProvider,
                metadata,
                downloadGlobalKey: globalKey,
                rules: scopedRules,
              ),
              tooltip: tooltip,
              icon: AppIcon(anyEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
              iconSize: iconSize,
              style: actionButtonStyle(foregroundColor: anyEnabled ? Colors.teal : Colors.grey),
            );
          }

          // No sync rule anywhere under this show — open the full download
          // options dialog (same one the never-downloaded button uses) so the
          // user can add more one-off episodes, restrict to a season, pick
          // random, or set up a sync rule. Already-downloaded episodes dedupe
          // at _queueSingleDownload, so picking "All episodes" is safe.
          final tooltip = currentFile != null
              ? '$currentFile downloaded — tap to add more or sync'
              : 'Partially downloaded — tap to add more or sync';

          return IconButton.filledTonal(
            onPressed: () async {
              final client = _getMediaClientForMetadata(context);
              if (client == null) return;

              try {
                final result = await showDownloadOptionsAndQueue(
                  context,
                  metadata: metadata,
                  client: client,
                  downloadProvider: downloadProvider,
                  currentSeason: _selectedSeasonForDownload(metadata),
                );
                if (result == null || !context.mounted) return;
                showSuccessSnackBar(context, result.toSnackBarMessage());
              } on CellularDownloadBlockedException {
                if (context.mounted) {
                  showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
                }
              }
            },
            tooltip: tooltip,
            icon: const AppIcon(Symbols.download_rounded, fill: 1),
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.orange),
          );
        }

        // State 8: Downloaded/Completed (can delete)
        if (downloadProvider.isDownloaded(globalKey)) {
          // Same widening as the partial branch: a season-scoped sync rule
          // governs this show too if the show is fully downloaded via that rule.
          final scopedRules = _collectScopedSyncRules(context, downloadProvider, metadata, ruleKey);

          if (scopedRules.isNotEmpty) {
            final anyEnabled = scopedRules.any((r) => r.rule.enabled);
            final tooltip = _scopedSyncTooltip(metadata, scopedRules, null);
            return IconButton.filledTonal(
              onPressed: () => _manageScopedSyncRules(
                context,
                downloadProvider,
                metadata,
                downloadGlobalKey: globalKey,
                rules: scopedRules,
              ),
              icon: AppIcon(anyEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
              tooltip: tooltip,
              iconSize: iconSize,
              style: actionButtonStyle(foregroundColor: anyEnabled ? Colors.teal : Colors.grey),
            );
          }

          return IconButton.filledTonal(
            onPressed: () async {
              // Show delete download confirmation
              final confirmed = await showDeleteConfirmation(
                context,
                title: t.downloads.deleteDownload,
                message: t.downloads.deleteConfirm(title: metadata.displayTitle),
              );

              if (confirmed && context.mounted) {
                await downloadProvider.deleteDownload(globalKey);
                if (context.mounted) {
                  showSuccessSnackBar(context, t.downloads.downloadDeleted);
                }
              }
            },
            icon: const AppIcon(Symbols.file_download_done_rounded, fill: 1),
            tooltip: t.downloads.deleteDownload,
            iconSize: iconSize,
            style: actionButtonStyle(foregroundColor: Colors.green),
          );
        }

        // State 9: Not downloaded (default - can download)
        return IconButton.filledTonal(
          onPressed: () async {
            final client = _getMediaClientForMetadata(context);
            if (client == null) return;

            try {
              final result = await showDownloadOptionsAndQueue(
                context,
                metadata: metadata,
                client: client,
                downloadProvider: downloadProvider,
                currentSeason: _selectedSeasonForDownload(metadata),
              );
              if (result == null || !context.mounted) return;

              showSuccessSnackBar(context, result.toSnackBarMessage());
            } on CellularDownloadBlockedException {
              if (context.mounted) {
                showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
              }
            }
          },
          icon: const AppIcon(Symbols.download_rounded, fill: 1),
          tooltip: t.downloads.downloadNow,
          iconSize: iconSize,
          style: actionButtonStyle(),
        );
      },
    );
  }

  /// Collect every sync rule that governs [metadata] or one of its seasons.
  ///
  /// Season-restricted downloads (the "Download only from {season}" toggle)
  /// create a rule keyed to the season's rating key, not the show's. The
  /// show-detail download button looks up by the show's key, so without this
  /// widening it would treat the show as unsynced and route a tap to
  /// `queueMissingEpisodes` — which queues the entire series.
  List<({String key, SyncRuleItem rule, MediaItem target})> _collectScopedSyncRules(
    BuildContext context,
    DownloadProvider downloadProvider,
    MediaItem metadata,
    String ruleKey,
  ) {
    final results = <({String key, SyncRuleItem rule, MediaItem target})>[];
    final ownRule = downloadProvider.getSyncRule(ruleKey);
    if (ownRule != null) {
      results.add((key: ruleKey, rule: ownRule, target: metadata));
    }
    if (!metadata.isShow) return results;
    for (final season in _seasons) {
      if (!season.isSeason) continue;
      final seasonKey = _syncRuleKeyForMetadata(context, downloadProvider, season);
      if (seasonKey == ruleKey) continue; // already covered as the own-rule
      final rule = downloadProvider.getSyncRule(seasonKey);
      if (rule != null) {
        results.add((key: seasonKey, rule: rule, target: season));
      }
    }
    return results;
  }

  String _scopedSyncTargetLabel(MediaItem target) {
    if (target.isSeason) {
      final idx = target.index;
      return target.title ?? (idx != null ? 'Season $idx' : 'Season');
    }
    return target.displayTitle;
  }

  String _scopedSyncTooltip(
    MediaItem metadata,
    List<({String key, SyncRuleItem rule, MediaItem target})> rules,
    String? currentFile,
  ) {
    if (rules.length == 1) {
      final r = rules.first;
      final base = r.rule.episodeCount > 0
          ? t.downloads.keepNUnwatched(count: r.rule.episodeCount.toString())
          : t.downloads.keepSynced;
      if (r.target.id != metadata.id) {
        final label = _scopedSyncTargetLabel(r.target);
        return currentFile != null ? '$currentFile · $base ($label)' : '$base ($label)';
      }
      return currentFile != null ? '$currentFile · $base' : base;
    }
    final labels = rules.map((r) => _scopedSyncTargetLabel(r.target)).join(', ');
    return currentFile != null
        ? '$currentFile · ${t.downloads.keepSynced} ($labels)'
        : '${t.downloads.keepSynced} ($labels)';
  }

  Future<void> _manageScopedSyncRules(
    BuildContext context,
    DownloadProvider downloadProvider,
    MediaItem metadata, {
    required String downloadGlobalKey,
    required List<({String key, SyncRuleItem rule, MediaItem target})> rules,
  }) async {
    if (rules.isEmpty) return;
    ({String key, SyncRuleItem rule, MediaItem target}) selected;
    if (rules.length == 1) {
      selected = rules.first;
    } else {
      final pickedKey = await showOptionPickerDialog<String>(
        context,
        title: t.downloads.manageSyncRule,
        options: [
          for (final r in rules)
            (
              icon: r.rule.enabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded,
              label: _scopedSyncTargetLabel(r.target),
              value: r.key,
            ),
        ],
      );
      if (pickedKey == null || !context.mounted) return;
      selected = rules.firstWhere((r) => r.key == pickedKey);
    }
    // For season-scoped rules, route the actions sheet (edit count / remove /
    // delete download) to the season so its title shows up in confirmations
    // and "Delete download" wipes the season's files rather than the show's.
    final isOwnRule = selected.target.id == metadata.id;
    await _showSyncRuleActions(
      context,
      downloadProvider,
      selected.target,
      ruleKey: selected.key,
      downloadGlobalKey: isOwnRule ? downloadGlobalKey : selected.target.globalKey,
    );
  }
}
