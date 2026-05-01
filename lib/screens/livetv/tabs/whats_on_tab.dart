import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../focus/key_event_utils.dart';
import '../../../focus/locked_hub_controller.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_item_types.dart';
import '../../../models/livetv_channel.dart';
import '../../../models/livetv_hub_result.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../theme/mono_tokens.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/provider_extensions.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focus_builders.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../utils/scroll_utils.dart';
import '../../../widgets/horizontal_scroll_with_arrows.dart';
import '../../../widgets/optimized_media_image.dart';
import '../live_tv_actions_mixin.dart';
import '../live_tv_show_schedule_screen.dart';

class WhatsOnTab extends StatefulWidget {
  final List<LiveTvChannel> channels;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onBack;

  const WhatsOnTab({super.key, required this.channels, this.onNavigateUp, this.onBack});

  @override
  State<WhatsOnTab> createState() => WhatsOnTabState();
}

class WhatsOnTabState extends State<WhatsOnTab> with LiveTvActionsMixin<WhatsOnTab> {
  List<LiveTvHubResult> _hubs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  List<GlobalKey<_LiveTvHubSectionState>> _hubKeys = [];

  @override
  List<LiveTvChannel> get liveTvChannels => widget.channels;

  @override
  void initState() {
    super.initState();
    _loadHubs();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadHubs();
    });
  }

  void pauseRefresh() => _refreshTimer?.cancel();

  void resumeRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadHubs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHubs() async {
    if (!mounted) return;
    setState(() => _isLoading = _hubs.isEmpty);

    try {
      final multiServer = context.read<MultiServerProvider>();
      final liveTvServers = multiServer.liveTvServers;
      final allHubs = <LiveTvHubResult>[];
      final queriedServers = <String>{};

      for (final serverInfo in liveTvServers) {
        if (!queriedServers.add(serverInfo.serverId)) continue;
        try {
          // Plex-only: Live TV hubs API is Plex-specific.
          final client = multiServer.getPlexClientForServer(serverInfo.serverId);
          if (client == null) continue;

          final hubs = await client.getLiveTvHubs();
          allHubs.addAll(hubs);
        } catch (e) {
          appLogger.e('Failed to load hubs from server ${serverInfo.serverId}', error: e);
        }
      }

      if (!mounted) return;
      setState(() {
        _hubs = allHubs;
        _hubKeys = List.generate(allHubs.length, (_) => GlobalKey<_LiveTvHubSectionState>());
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load live TV hubs', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Focus the first hub (called from parent when tab bar navigates down)
  void focusFirstHub() {
    if (_hubKeys.isNotEmpty) {
      _hubKeys.first.currentState?.requestFocusFromMemory();
    }
  }

  bool _handleVerticalNavigation(int hubIndex, bool isUp) {
    if (_hubKeys.isEmpty) return false;

    if (isUp && hubIndex == 0) {
      widget.onNavigateUp?.call();
      return true;
    }

    final targetIndex = isUp ? hubIndex - 1 : hubIndex + 1;

    if (targetIndex < 0 || targetIndex >= _hubKeys.length) {
      return true; // At boundary, consume the event
    }

    final targetState = _hubKeys[targetIndex].currentState;
    if (targetState != null) {
      targetState.requestFocusFromMemory();
      return true;
    }

    return false;
  }

  void _onItemTap(LiveTvHubEntry entry) {
    final channel = findChannel(entry.program.channelIdentifier);

    if (entry.program.isCurrentlyAiring && channel != null) {
      // Live → play directly
      tuneChannel(channel);
    } else if (entry.metadata.isShow) {
      // Show with upcoming episodes → show full schedule
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveTvShowScheduleScreen(
            showTitle: entry.metadata.displayTitle,
            serverId: entry.metadata.serverId ?? '',
            channels: widget.channels,
          ),
        ),
      );
    } else {
      // Individual program (episode, movie, etc.) → bottom sheet
      showProgramDetails(
        program: entry.program,
        channel: channel,
        posterThumb: entry.metadata.grandparentThumbPath ?? entry.metadata.thumbPath,
        posterServerId: entry.metadata.serverId ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hubs.isEmpty) {
      return Center(child: Text(t.liveTv.noPrograms));
    }

    return OverlaySheetHost(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.none,
        itemCount: _hubs.length,
        itemBuilder: (context, index) {
          return _LiveTvHubSection(
            key: _hubKeys[index],
            hub: _hubs[index],
            onTap: _onItemTap,
            onLongPress: (entry) => showProgramDetails(
              program: entry.program,
              channel: findChannel(entry.program.channelIdentifier),
              posterThumb: entry.metadata.grandparentThumbPath ?? entry.metadata.thumbPath,
              posterServerId: entry.metadata.serverId ?? '',
            ),
            onVerticalNavigation: (isUp) => _handleVerticalNavigation(index, isUp),
            onBack: widget.onBack,
          );
        },
      ),
    );
  }
}

// Hub section — horizontal scrolling row of poster cards (always 2:3 aspect)
// Uses locked focus pattern: single Focus node at hub level, visual index in state.

class _LiveTvHubSection extends StatefulWidget {
  final LiveTvHubResult hub;
  final void Function(LiveTvHubEntry) onTap;
  final void Function(LiveTvHubEntry) onLongPress;
  final bool Function(bool isUp)? onVerticalNavigation;
  final VoidCallback? onBack;

  const _LiveTvHubSection({
    super.key,
    required this.hub,
    required this.onTap,
    required this.onLongPress,
    this.onVerticalNavigation,
    this.onBack,
  });

  @override
  State<_LiveTvHubSection> createState() => _LiveTvHubSectionState();
}

class _LiveTvHubSectionState extends State<_LiveTvHubSection> {
  static const _longPressDuration = Duration(milliseconds: 500);

  late FocusNode _hubFocusNode;
  final ScrollController _scrollController = ScrollController();

  int _focusedIndex = 0;
  double _itemExtent = 0;
  static const double _leadingPadding = 12.0;

  Timer? _longPressTimer;
  bool _isSelectKeyDown = false;
  bool _longPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _hubFocusNode = FocusNode(debugLabel: 'livetv_hub_${widget.hub.hubKey}');
    _hubFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_LiveTvHubSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hub.entries.length != oldWidget.hub.entries.length) {
      final maxIndex = widget.hub.entries.isEmpty ? 0 : widget.hub.entries.length - 1;
      if (_focusedIndex > maxIndex) {
        _focusedIndex = maxIndex;
      }
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _hubFocusNode.removeListener(_onFocusChange);
    _hubFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_hubFocusNode.hasFocus) {
      _longPressTimer?.cancel();
      _isSelectKeyDown = false;
      _longPressTriggered = false;
    }
    // ignore: no-empty-block - setState triggers rebuild to update focus styling
    if (mounted) setState(() {});
  }

  void requestFocusAt(int index) {
    if (widget.hub.entries.isEmpty) return;

    final clamped = index.clamp(0, widget.hub.entries.length - 1);
    _focusedIndex = clamped;
    HubFocusMemory.setForHub(widget.hub.hubKey, clamped);
    _scrollToIndex(clamped);
    _hubFocusNode.requestFocus();
    // ignore: no-empty-block - setState triggers rebuild to update focus styling
    if (mounted) setState(() {});
    _scrollHubIntoView();
  }

  void requestFocusFromMemory() {
    final index = HubFocusMemory.getForHub(widget.hub.hubKey, widget.hub.entries.length);
    requestFocusAt(index);
  }

  void _scrollHubIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    scrollListToIndex(
      _scrollController,
      index,
      itemExtent: _itemExtent,
      leadingPadding: _leadingPadding,
      animate: animate,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isSelectKey) {
      if (event is KeyDownEvent) {
        if (!_isSelectKeyDown) {
          _isSelectKeyDown = true;
          _longPressTriggered = false;
          _longPressTimer?.cancel();
          _longPressTimer = Timer(_longPressDuration, () {
            if (!mounted) return;
            if (_isSelectKeyDown) {
              _longPressTriggered = true;
              SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
              _activateLongPress();
            }
          });
        }
        return KeyEventResult.handled;
      } else if (event is KeyRepeatEvent) {
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        final timerWasActive = _longPressTimer?.isActive ?? false;
        _longPressTimer?.cancel();
        if (!_longPressTriggered && timerWasActive && _isSelectKeyDown) {
          _activateCurrentItem();
        }
        _isSelectKeyDown = false;
        _longPressTriggered = false;
        return KeyEventResult.handled;
      }
    }

    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) {
        return backResult;
      }
    }

    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final itemCount = widget.hub.entries.length;
    if (itemCount == 0) return KeyEventResult.ignored;

    if (key.isLeftKey) {
      if (_focusedIndex > 0) {
        setState(() {
          _focusedIndex--;
        });
        HubFocusMemory.setForHub(widget.hub.hubKey, _focusedIndex);
        _scrollToIndex(_focusedIndex);
      } else {
        widget.onBack?.call();
      }
      return KeyEventResult.handled;
    }

    if (key.isRightKey) {
      if (_focusedIndex < itemCount - 1) {
        setState(() {
          _focusedIndex++;
        });
        HubFocusMemory.setForHub(widget.hub.hubKey, _focusedIndex);
        _scrollToIndex(_focusedIndex);
      }
      return KeyEventResult.handled;
    }

    if (key.isUpKey) {
      widget.onVerticalNavigation?.call(true);
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      widget.onVerticalNavigation?.call(false);
      return KeyEventResult.handled;
    }

    if (key.isContextMenuKey) {
      _activateLongPress();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _activateCurrentItem() {
    if (_focusedIndex >= widget.hub.entries.length) return;
    widget.onTap(widget.hub.entries[_focusedIndex]);
  }

  void _activateLongPress() {
    if (_focusedIndex >= widget.hub.entries.length) return;
    widget.onLongPress(widget.hub.entries[_focusedIndex]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _focusedIndex = index;
    });
    HubFocusMemory.setForHub(widget.hub.hubKey, index);
    _hubFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _hubFocusNode.hasFocus;
    final settings = context.watch<SettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hub header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(Symbols.live_tv_rounded, fill: 1),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.hub.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),

        // Horizontal cards with locked focus control
        if (widget.hub.entries.isNotEmpty)
          Focus(
            focusNode: _hubFocusNode,
            onKeyEvent: _handleKeyEvent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = GridSizeCalculator.getCellWidth(
                  constraints.maxWidth,
                  context,
                  settings.libraryDensity,
                );
                final posterWidth = cardWidth - 16;
                final posterHeight = posterWidth * 1.5; // 2:3 aspect
                final containerHeight = posterHeight + 66;
                _itemExtent = cardWidth + 4;

                return SizedBox(
                  height: containerHeight,
                  child: HorizontalScrollWithArrows(
                    controller: _scrollController,
                    builder: (scrollController) => ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      itemCount: widget.hub.entries.length,
                      itemBuilder: (context, index) {
                        final entry = widget.hub.entries[index];
                        final isItemFocused = hasFocus && index == _focusedIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _LiveTvPosterCard(
                            entry: entry,
                            width: cardWidth,
                            posterHeight: posterHeight,
                            isFocused: isItemFocused,
                            onTap: () {
                              _onItemTapped(index);
                              widget.onTap(entry);
                            },
                            onLongPress: () {
                              _onItemTapped(index);
                              widget.onLongPress(entry);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LiveTvPosterCard extends StatelessWidget {
  final LiveTvHubEntry entry;
  final double width;
  final double posterHeight;
  final bool isFocused;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LiveTvPosterCard({
    required this.entry,
    required this.width,
    required this.posterHeight,
    required this.isFocused,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = entry.metadata;
    // Always use poster image: show poster for episodes, thumb for others
    final posterImage = metadata.grandparentThumbPath ?? metadata.thumbPath;

    return FocusBuilders.buildLockedFocusWrapper(
      context: context,
      isFocused: isFocused,
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              SizedBox(
                width: double.infinity,
                height: posterHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                  child: OptimizedMediaImage.poster(
                    client: context.tryGetMediaClientWithFallback(metadata.serverId),
                    imagePath: posterImage,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Title
              Text(
                metadata.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
              ),
              // Subtitle
              if (metadata.displaySubtitle != null)
                Text(
                  metadata.displaySubtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
