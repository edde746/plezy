import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plex_hub.dart';
import '../screens/hub_detail_screen.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'hub_navigation_controller.dart';
import '../i18n/strings.g.dart';
import 'focus/focus_indicator.dart';

/// Shared hub section widget used in both discover and library screens
/// Displays a hub title with icon and a horizontal scrollable list of items
class HubSection extends StatefulWidget {
  final PlexHub hub;
  final IconData icon;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool isInContinueWatching;

  /// Order for navigation (lower = higher on screen). Default is 1000 for dynamic hubs.
  final int navigationOrder;

  const HubSection({
    super.key,
    required this.hub,
    required this.icon,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isInContinueWatching = false,
    this.navigationOrder = 1000,
  });

  @override
  State<HubSection> createState() => _HubSectionState();
}

class _HubSectionState extends State<HubSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;

  /// Focus nodes for each item in the hub
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;
  int? _registeredItemCount;
  int? _registeredOrder;

  String get _hubId => widget.hub.hubIdentifier ?? widget.hub.title;

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    // Create focus nodes for each item
    _itemFocusNodes = List.generate(
      widget.hub.items.length,
      (index) => FocusNode(debugLabel: 'HubItem_${_hubId}_$index'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  @override
  void didUpdateWidget(HubSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If items changed, recreate focus nodes
    if (widget.hub.items.length != _itemFocusNodes.length) {
      _disposeItemFocusNodes();
      _createItemFocusNodes();
    }
    _registerWithController();
  }

  void _unregisterFromController() {
    if (_controller != null && _registeredHubId != null) {
      _controller!.unregister(_registeredHubId!);
    }
    _registeredHubId = null;
    _registeredItemCount = null;
    _registeredOrder = null;
  }

  void _registerWithController() {
    final controller = HubNavigationScope.maybeOf(context);
    final hubId = _hubId;
    final itemCount = widget.hub.items.length;
    final order = widget.navigationOrder;

    if (controller != _controller) {
      _unregisterFromController();
      _controller = controller;
    }

    if (controller == null) return;

    final registrationChanged =
        _registeredHubId != hubId ||
        _registeredItemCount != itemCount ||
        _registeredOrder != order;

    if (registrationChanged) {
      _unregisterFromController();
      controller.register(
        HubSectionRegistration(
          hubId: hubId,
          itemCount: itemCount,
          focusItem: _focusItem,
          order: order,
        ),
      );
      _registeredHubId = hubId;
      _registeredItemCount = itemCount;
      _registeredOrder = order;
    }
  }

  void _focusItem(int index) {
    if (index >= 0 && index < _itemFocusNodes.length) {
      _itemFocusNodes[index].requestFocus();
    }
  }

  void _disposeItemFocusNodes() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    _itemFocusNodes = [];
  }

  @override
  void dispose() {
    _unregisterFromController();
    _headerFocusNode.removeListener(_handleHeaderFocusChange);
    _headerFocusNode.dispose();
    _disposeItemFocusNodes();
    super.dispose();
  }

  void _handleHeaderFocusChange() {
    if (_headerIsFocused != _headerFocusNode.hasFocus) {
      setState(() {
        _headerIsFocused = _headerFocusNode.hasFocus;
      });
    }
  }

  void _navigateToHubDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HubDetailScreen(hub: widget.hub)),
    );
  }

  KeyEventResult _handleHeaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && widget.hub.more) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        _navigateToHubDetail();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hub header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Focus(
              focusNode: _headerFocusNode,
              onKeyEvent: _handleHeaderKeyEvent,
              canRequestFocus: widget.hub.more, // Only focusable if has "more"
              child: FocusIndicator(
                isFocused: _headerIsFocused && widget.hub.more,
                borderRadius: 8,
                child: InkWell(
                  onTap: widget.hub.more ? _navigateToHubDetail : null,
                  borderRadius: BorderRadius.circular(8),
                  focusColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon),
                        const SizedBox(width: 8),
                        Text(
                          widget.hub.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (widget.hub.more) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Hub items (horizontal scroll)
          if (widget.hub.items.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive card width based on screen size
                final screenWidth = constraints.maxWidth;
                final cardWidth = screenWidth > 1600
                    ? 220.0
                    : screenWidth > 1200
                    ? 200.0
                    : screenWidth > 800
                    ? 190.0
                    : 160.0;

                // MediaCard has 8px padding on all sides (16px total horizontally)
                // So actual poster width is cardWidth - 16
                final posterWidth = cardWidth - 16;
                // 2:3 poster aspect ratio (height is 1.5x width)
                final posterHeight = posterWidth * 1.5;
                // Container height = poster + padding + spacing + text + focus indicator headroom
                // 8px top padding + posterHeight + 4px spacing + ~26px text + 8px bottom padding
                // + 10px extra for focus indicator border (3px) and scale effect (1.02x)
                final containerHeight = posterHeight + 46 + 10;

                return SizedBox(
                  height: containerHeight,
                  child: ClipRect(
                    clipBehavior: Clip.none,
                    child: HorizontalScrollWithArrows(
                      builder: (scrollController) => FocusTraversalGroup(
                        child: ListView.builder(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior:
                              Clip.none, // Allow focus indicator to overflow
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          itemCount: widget.hub.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.hub.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: MediaCard(
                                key: Key(item.ratingKey),
                                item: item,
                                width: cardWidth,
                                height: posterHeight,
                                onRefresh: widget.onRefresh,
                                onRemoveFromContinueWatching:
                                    widget.onRemoveFromContinueWatching,
                                forceGridMode: true,
                                isInContinueWatching:
                                    widget.isInContinueWatching,
                                focusNode: _itemFocusNodes.length > index
                                    ? _itemFocusNodes[index]
                                    : null,
                                hubId: _hubId,
                                itemIndex: index,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                t.messages.noItemsAvailable,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
