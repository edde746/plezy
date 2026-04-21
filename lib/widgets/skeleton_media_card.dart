import 'package:flutter/widgets.dart';

import 'media_card.dart';

/// Placeholder that mirrors the poster + title + subtitle layout of a real
/// media card. Rendered in a sparse grid while items for that slot are in
/// flight. Not focusable — dpad navigation skips over these.
class SkeletonMediaCard extends StatelessWidget {
  const SkeletonMediaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: SkeletonLoader(child: SizedBox.expand()),
            ),
          ),
          SizedBox(height: 4),
          SkeletonLoader(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: SizedBox(height: 13, width: double.infinity),
          ),
          SizedBox(height: 3),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.6,
            child: SkeletonLoader(borderRadius: BorderRadius.all(Radius.circular(4)), child: SizedBox(height: 11)),
          ),
        ],
      ),
    );
  }
}
