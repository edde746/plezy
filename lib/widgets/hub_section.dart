import 'package:flutter/material.dart';
import '../models/plex_hub.dart';
import '../screens/hub_detail_screen.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import '../i18n/strings.g.dart';

/// Shared hub section widget used in both discover and library screens
/// Displays a hub title with icon and a horizontal scrollable list of items
class HubSection extends StatelessWidget {
  final PlexHub hub;
  final IconData icon;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool isInContinueWatching;

  const HubSection({
    super.key,
    required this.hub,
    required this.icon,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isInContinueWatching = false,
  });

  void _navigateToHubDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HubDetailScreen(hub: hub)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hub header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: InkWell(
            onTap: hub.more ? () => _navigateToHubDetail(context) : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hub.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (hub.more) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Hub items (horizontal scroll)
        if (hub.items.isNotEmpty)
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
              // Container height = poster + padding + spacing + text + ListView padding
              // 8px top padding + posterHeight + 4px spacing + ~26px text + 8px bottom padding
              // + 10px for ListView vertical padding (5px top + 5px bottom)
              final containerHeight = posterHeight + 56;

              return SizedBox(
                height: containerHeight,
                child: HorizontalScrollWithArrows(
                  builder: (scrollController) => ListView.builder(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    itemCount: hub.items.length,
                    itemBuilder: (context, index) {
                      final item = hub.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        child: MediaCard(
                          key: Key(item.ratingKey),
                          item: item,
                          width: cardWidth,
                          height: posterHeight,
                          onRefresh: onRefresh,
                          onRemoveFromContinueWatching:
                              onRemoveFromContinueWatching,
                          forceGridMode: true,
                          isInContinueWatching: isInContinueWatching,
                        ),
                      );
                    },
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
    );
  }
}
