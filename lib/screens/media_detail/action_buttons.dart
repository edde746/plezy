part of '../media_detail_screen.dart';

extension _MediaDetailActionButtons on _MediaDetailScreenState {
  Widget _buildActionButtons(MediaItem metadata) {
    final playButtonLabel = _getPlayButtonLabel(metadata);
    final playButtonIcon = AppIcon(_getPlayButtonIcon(metadata), fill: 1, size: 20);

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
    final tonalFg = colorScheme.onSecondaryContainer;
    final noOverlay = WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) return Colors.transparent;
      return null; // default for other states
    });

    ButtonStyle actionButtonStyle({Color? foregroundColor, EdgeInsetsGeometry? padding}) {
      if (!isKeyboardMode) {
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
        minimumSize: padding == null ? const WidgetStatePropertyAll(Size(48, 48)) : null,
        maximumSize: padding == null ? const WidgetStatePropertyAll(Size(48, 48)) : null,
        overlayColor: noOverlay,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return focusBg;
          return tonalBg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return focusFg;
          return foregroundColor ?? tonalFg;
        }),
      );
    }

    return Focus(
      skipTraversal: true,
      onKeyEvent: _handlePlayButtonKeyEvent,
      child: Row(
        children: [
          SizedBox(
            height: 48,
            child: FilledButton(
              focusNode: _playButtonFocusNode,
              autofocus: isKeyboardMode,
              onPressed: onPlayPressed,
              style: actionButtonStyle(padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: playButtonLabel.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        playButtonIcon,
                        const SizedBox(width: 8),
                        Text(playButtonLabel, style: const TextStyle(fontSize: 16)),
                      ],
                    )
                  : playButtonIcon,
            ),
          ),
          const SizedBox(width: 12),
          // Trailer button (only if trailer is available)
          if (primaryTrailer != null) ...[
            IconButton.filledTonal(
              onPressed: () async {
                await navigateToVideoPlayer(context, metadata: primaryTrailer);
              },
              icon: const AppIcon(Symbols.theaters_rounded, fill: 1),
              tooltip: t.tooltips.playTrailer,
              iconSize: 20,
              style: actionButtonStyle(),
            ),
            const SizedBox(width: 12),
          ],
          // Shuffle button (only for shows and seasons)
          if (metadata.isShow || metadata.isSeason) ...[
            IconButton.filledTonal(
              onPressed: () async {
                await _handleShufflePlayWithQueue(context, metadata);
              },
              icon: const AppIcon(Symbols.shuffle_rounded, fill: 1),
              tooltip: t.tooltips.shufflePlay,
              iconSize: 20,
              style: actionButtonStyle(),
            ),
            const SizedBox(width: 12),
          ],
          // Download button (hide in offline mode - already downloaded,
          // and on Apple TV where there's no user file storage).
          if (!widget.isOffline && !PlatformDetector.isAppleTV()) _buildDownloadButton(metadata, actionButtonStyle),
          const SizedBox(width: 12),
          // Mark as watched/unwatched toggle (works offline too)
          _buildWatchedToggleButton(metadata, actionButtonStyle),
          // Three-dots menu button (hidden in offline mode)
          if (!widget.isOffline) ...[const SizedBox(width: 12), _buildMoreActionsButton(metadata, actionButtonStyle)],
        ],
      ),
    );
  }

  Widget _buildWatchedToggleButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
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
              unawaited(_updateWatchStateOffline());
              unawaited(_loadOfflineOnDeckEpisode());
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
            } else {
              await client.markWatched(metadata);
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
      iconSize: 20,
      style: actionButtonStyle(),
    );
  }

  Widget _buildMoreActionsButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
  ) {
    return MediaContextMenu(
      key: _contextMenuKey,
      item: metadata,
      onRefresh: (_) => _loadFullMetadata(),
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
          iconSize: 20,
          style: actionButtonStyle(),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    MediaItem metadata,
    ButtonStyle Function({Color? foregroundColor, EdgeInsetsGeometry? padding}) actionButtonStyle,
  ) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
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
            icon: const LoadingIndicatorBox(size: 20),
            iconSize: 20,
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
            iconSize: 20,
            style: actionButtonStyle(),
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
            iconSize: 20,
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
            iconSize: 20,
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
            iconSize: 20,
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
            iconSize: 20,
            style: actionButtonStyle(foregroundColor: Colors.grey),
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
                ? '$currentFile (syncing ${t.downloads.keepNUnwatched(count: syncRule?.episodeCount.toString() ?? '?')})'
                : t.downloads.keepSynced;

            return IconButton.filledTonal(
              onPressed: () => _showSyncRuleActions(
                context,
                downloadProvider,
                metadata,
                ruleKey: ruleKey,
                downloadGlobalKey: globalKey,
              ),
              tooltip: tooltip,
              icon: AppIcon(isEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
              iconSize: 20,
              style: actionButtonStyle(foregroundColor: isEnabled ? Colors.teal : Colors.grey),
            );
          }

          final tooltip = currentFile != null
              ? 'Downloaded $currentFile - Click to complete'
              : 'Partially downloaded - Click to complete';

          return IconButton.filledTonal(
            onPressed: () async {
              final client = _getMediaClientForMetadata(context);
              if (client == null) return;

              final versionConfig = await _resolveDownloadVersion(context, metadata, client);
              if (versionConfig == null || !context.mounted) return;

              final count = await downloadProvider.queueMissingEpisodes(metadata, client, versionConfig: versionConfig);

              if (context.mounted) {
                final message = count > 0
                    ? t.downloads.episodesQueued(count: count)
                    : 'All episodes already downloaded';
                showAppSnackBar(context, message);
              }
            },
            tooltip: tooltip,
            icon: const AppIcon(Symbols.downloading_rounded, fill: 1),
            iconSize: 20,
            style: actionButtonStyle(foregroundColor: Colors.orange),
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
              onPressed: () => _showSyncRuleActions(
                context,
                downloadProvider,
                metadata,
                ruleKey: ruleKey,
                downloadGlobalKey: globalKey,
              ),
              icon: AppIcon(isEnabled ? Symbols.sync_rounded : Symbols.sync_disabled_rounded, fill: 1),
              tooltip: t.downloads.keepNUnwatched(count: syncRule?.episodeCount.toString() ?? '?'),
              iconSize: 20,
              style: actionButtonStyle(foregroundColor: isEnabled ? Colors.teal : Colors.grey),
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
            iconSize: 20,
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
          iconSize: 20,
          style: actionButtonStyle(),
        );
      },
    );
  }
}
