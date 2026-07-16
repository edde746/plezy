import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../focus/focusable_button.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_item.dart';
import '../../../providers/playback_state_provider.dart';
import '../../../services/pip_service.dart';
import '../../../utils/platform_detector.dart';
import '../../../watch_together/providers/watch_together_provider.dart';
import '../../../watch_together/widgets/watch_together_overlay.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/video_controls/player_chrome_controller.dart';

class VideoPlayerMacPipPlaceholder extends StatelessWidget {
  const VideoPlayerMacPipPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipService().isPipActive,
      builder: (context, isInPip, child) {
        if (!isInPip) return const SizedBox.shrink();
        return Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  AppIcon(Symbols.picture_in_picture_alt_rounded, size: 48, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    t.videoControls.pipActive,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class VideoPlayerBufferingOverlay extends StatelessWidget {
  final ValueListenable<bool> isBuffering;
  final ValueListenable<bool> hasFirstFrame;
  final ValueListenable<bool> isExiting;

  const VideoPlayerBufferingOverlay({
    super.key,
    required this.isBuffering,
    required this.hasFirstFrame,
    required this.isExiting,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipService().isPipActive,
      builder: (context, isInPip, child) {
        if (isInPip) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: isBuffering,
          builder: (context, buffering, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: hasFirstFrame,
              builder: (context, hasFrame, child) {
                if ((!buffering && hasFrame) || isExiting.value) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class VideoPlayerWatchTogetherOverlays extends StatelessWidget {
  const VideoPlayerWatchTogetherOverlays({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Selector<WatchTogetherProvider, bool>(
            selector: (_, provider) => provider.isWaitingForHostReconnect,
            builder: (context, isWaiting, child) {
              if (!isWaiting) return const SizedBox.shrink();
              return Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        if (PlatformDetector.isTV())
                          const AppIcon(Symbols.sync_rounded, size: 14, color: Colors.white)
                        else
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          t.watchTogether.reconnectingToHost,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const ParticipantNotificationOverlay(),
          const WaitingForParticipantsIndicator(),
          const SyncingIndicator(),
        ],
      ),
    );
  }
}

class VideoPlayerExitOverlay extends StatelessWidget {
  final ValueListenable<bool> isExiting;

  const VideoPlayerExitOverlay({super.key, required this.isExiting});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isExiting,
      builder: (context, exiting, child) {
        if (!exiting) return const SizedBox.shrink();
        return const Positioned.fill(child: ColoredBox(color: Colors.black));
      },
    );
  }
}

class VideoPlayerPlayNextOverlay extends StatelessWidget {
  final bool visible;
  final MediaItem? nextEpisode;
  final int autoPlayCountdown;
  final FocusNode cancelFocusNode;
  final FocusNode confirmFocusNode;
  final PlayerChromeController chromeController;
  final VoidCallback onCancel;
  final VoidCallback onPlayNext;

  const VideoPlayerPlayNextOverlay({
    super.key,
    required this.visible,
    required this.nextEpisode,
    required this.autoPlayCountdown,
    required this.cancelFocusNode,
    required this.confirmFocusNode,
    required this.chromeController,
    required this.onCancel,
    required this.onPlayNext,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipService().isPipActive,
      builder: (context, isInPip, child) {
        final episode = nextEpisode;
        if (isInPip || !visible || episode == null) {
          return const SizedBox.shrink();
        }
        return _VideoPlayerPromptPosition(
          chromeController: chromeController,
          child: _VideoPlayerPromptInteractionHold(
            chromeController: chromeController,
            focusNodes: [cancelFocusNode, confirmFocusNode],
            child: _VideoPlayerPromptCard(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  _PlayNextEpisodeHeader(episode: episode),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FocusableButton(
                          focusNode: cancelFocusNode,
                          onPressed: onCancel,
                          autoScroll: false,
                          onNavigateRight: () => confirmFocusNode.requestFocus(),
                          onNavigateUp: () {},
                          onNavigateDown: () {},
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(t.common.cancel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FocusableButton(
                          focusNode: confirmFocusNode,
                          onPressed: onPlayNext,
                          autoScroll: false,
                          onNavigateLeft: () => cancelFocusNode.requestFocus(),
                          onNavigateUp: () {},
                          onNavigateDown: () {},
                          useBackgroundFocus: true,
                          child: FilledButton(
                            onPressed: onPlayNext,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: .center,
                              children: [
                                if (autoPlayCountdown > 0) ...[
                                  Text('$autoPlayCountdown'),
                                  const SizedBox(width: 4),
                                  const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 18),
                                ] else
                                  Text(t.videoControls.playNext),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayNextEpisodeHeader extends StatelessWidget {
  final MediaItem episode;

  const _PlayNextEpisodeHeader({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Consumer<PlaybackStateProvider>(
                builder: (context, playbackState, child) {
                  final isShuffleActive = playbackState.isShuffleActive;
                  return Row(
                    children: [
                      Text(
                        'Next Episode',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: .w500),
                      ),
                      if (isShuffleActive) ...[
                        const SizedBox(width: 4),
                        AppIcon(Symbols.shuffle_rounded, fill: 1, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              if (episode.parentIndex != null && episode.index != null)
                Text(
                  'S${episode.parentIndex} E${episode.index} · ${episode.title}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: .w600),
                  maxLines: 2,
                  overflow: .ellipsis,
                )
              else
                Text(
                  episode.title!,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: .w600),
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class VideoPlayerStillWatchingOverlay extends StatelessWidget {
  final bool visible;
  final int countdown;
  final FocusNode pauseFocusNode;
  final FocusNode continueFocusNode;
  final PlayerChromeController chromeController;
  final VoidCallback onPause;
  final VoidCallback onContinue;

  const VideoPlayerStillWatchingOverlay({
    super.key,
    required this.visible,
    required this.countdown,
    required this.pauseFocusNode,
    required this.continueFocusNode,
    required this.chromeController,
    required this.onPause,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipService().isPipActive,
      builder: (context, isInPip, child) {
        if (isInPip || !visible) {
          return const SizedBox.shrink();
        }
        return _VideoPlayerPromptPosition(
          chromeController: chromeController,
          child: _VideoPlayerPromptInteractionHold(
            chromeController: chromeController,
            focusNodes: [pauseFocusNode, continueFocusNode],
            child: _VideoPlayerPromptCard(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    t.videoControls.stillWatching,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: .w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.videoControls.pausingIn(seconds: '$countdown'),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: .w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FocusableButton(
                          focusNode: pauseFocusNode,
                          onPressed: onPause,
                          autoScroll: false,
                          onNavigateRight: () => continueFocusNode.requestFocus(),
                          onNavigateUp: () {},
                          onNavigateDown: () {},
                          child: OutlinedButton(
                            onPressed: onPause,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(t.videoControls.pauseButton),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FocusableButton(
                          focusNode: continueFocusNode,
                          onPressed: onContinue,
                          autoScroll: false,
                          onNavigateLeft: () => pauseFocusNode.requestFocus(),
                          onNavigateUp: () {},
                          onNavigateDown: () {},
                          useBackgroundFocus: true,
                          child: FilledButton(
                            onPressed: onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: .center,
                              children: [
                                Text('$countdown'),
                                const SizedBox(width: 4),
                                Text(t.videoControls.continueWatching),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoPlayerPromptPosition extends StatelessWidget {
  final PlayerChromeController chromeController;
  final Widget child;

  const _VideoPlayerPromptPosition({required this.chromeController, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: chromeController,
      builder: (context, controlsShown, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          right: 24,
          bottom: controlsShown ? 100 : 24,
          child: child!,
        );
      },
      child: child,
    );
  }
}

class _VideoPlayerPromptCard extends StatelessWidget {
  final Widget child;

  const _VideoPlayerPromptCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: child,
    );
  }
}

class _VideoPlayerPromptInteractionHold extends StatefulWidget {
  final PlayerChromeController chromeController;
  final List<FocusNode> focusNodes;
  final Widget child;

  const _VideoPlayerPromptInteractionHold({
    required this.chromeController,
    required this.focusNodes,
    required this.child,
  });

  @override
  State<_VideoPlayerPromptInteractionHold> createState() => _VideoPlayerPromptInteractionHoldState();
}

class _VideoPlayerPromptInteractionHoldState extends State<_VideoPlayerPromptInteractionHold> {
  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _addFocusListeners(widget.focusNodes);
    _syncFocusState();
  }

  @override
  void didUpdateWidget(_VideoPlayerPromptInteractionHold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.focusNodes, widget.focusNodes)) {
      _removeFocusListeners(oldWidget.focusNodes);
      _addFocusListeners(widget.focusNodes);
      _syncFocusState();
    }
    if (oldWidget.chromeController != widget.chromeController) {
      oldWidget.chromeController.release(PlayerChromeHold.promptInteraction);
      _syncHold();
    }
  }

  @override
  void dispose() {
    _removeFocusListeners(widget.focusNodes);
    widget.chromeController.release(PlayerChromeHold.promptInteraction, notify: false, restartAutoHide: false);
    super.dispose();
  }

  void _addFocusListeners(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.addListener(_syncFocusState);
    }
  }

  void _removeFocusListeners(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.removeListener(_syncFocusState);
    }
  }

  void _syncFocusState() {
    final focused = widget.focusNodes.any((node) => node.hasFocus);
    if (_focused == focused) return;
    _focused = focused;
    _syncHold();
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) return;
    _hovered = hovered;
    if (hovered) widget.chromeController.recordPointerActivity();
    _syncHold();
  }

  void _syncHold() {
    if (_hovered || _focused) {
      widget.chromeController.hold(PlayerChromeHold.promptInteraction);
    } else {
      widget.chromeController.release(PlayerChromeHold.promptInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onHover: (_) => widget.chromeController.recordPointerActivity(),
      onExit: (_) => _setHovered(false),
      child: widget.child,
    );
  }
}
