import 'package:flutter/material.dart';

import 'focusable_filter_chip.dart';

/// Height of an [OptionsChipsBar] (padding + chip + padding).
const double optionsChipsBarHeight = 32.0;

/// Describes one chip in an [OptionsChipsBar].
///
/// Pure data: the bar renders each descriptor as a [FocusableFilterChip] and
/// wires LEFT/RIGHT traversal between adjacent chips itself, so a descriptor
/// only carries what is unique to its chip.
class OptionsChipDescriptor {
  /// Leading icon inside the chip.
  final IconData icon;

  /// Chip label.
  final String label;

  /// Invoked on tap or D-pad select.
  final VoidCallback onPressed;

  /// External focus node for programmatic focus control (focus handoff,
  /// restoration). Owned and disposed by the caller.
  final FocusNode focusNode;

  /// Key used to locate the chip's render box when anchoring a popup menu to
  /// it — see `chipAnchorRect` in `anchored_option_menus.dart`.
  final GlobalKey? anchorKey;

  /// Override for LEFT. Defaults to focusing the previous chip, or
  /// [OptionsChipsBar.onNavigateLeftEdge] on the first chip.
  final VoidCallback? onNavigateLeft;

  /// Override for RIGHT. Defaults to focusing the next chip; the last chip
  /// consumes RIGHT without moving (chip key handling always traps RIGHT).
  final VoidCallback? onNavigateRight;

  /// Override for DOWN. Defaults to [OptionsChipsBar.onNavigateDown].
  final VoidCallback? onNavigateDown;

  /// Override for UP. Defaults to [OptionsChipsBar.onNavigateUp].
  final VoidCallback? onNavigateUp;

  /// Override for BACK. Defaults to [OptionsChipsBar.onBack].
  final VoidCallback? onBack;

  const OptionsChipDescriptor({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.focusNode,
    this.anchorKey,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onNavigateDown,
    this.onNavigateUp,
    this.onBack,
  });
}

/// A horizontal bar of [FocusableFilterChip]s (grouping, filters, sort, …)
/// with D-pad traversal wired between adjacent chips.
///
/// LEFT/RIGHT move focus between neighboring chips; LEFT on the first chip
/// falls back to [onNavigateLeftEdge] (or bubbles up when unset). DOWN, UP
/// and BACK default to the bar-level callbacks and can be overridden per
/// chip. Focused chips reveal themselves via the chip's own scroll-into-view
/// behavior.
class OptionsChipsBar extends StatelessWidget {
  /// Chips to render, in order.
  final List<OptionsChipDescriptor> chips;

  /// Invoked on DOWN from any chip (typically hands focus to the content
  /// below the bar).
  final VoidCallback? onNavigateDown;

  /// Invoked on UP from any chip (typically hands focus to the chrome above).
  final VoidCallback? onNavigateUp;

  /// Invoked on LEFT from the first chip (typically focuses the sidebar).
  final VoidCallback? onNavigateLeftEdge;

  /// Invoked on BACK from any chip.
  final VoidCallback? onBack;

  const OptionsChipsBar({
    super.key,
    required this.chips,
    this.onNavigateDown,
    this.onNavigateUp,
    this.onNavigateLeftEdge,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: .centerLeft,
      child: Row(
        mainAxisSize: .min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: 8), _buildChip(i)],
        ],
      ),
    );
  }

  Widget _buildChip(int index) {
    final chip = chips[index];
    final previous = index > 0 ? chips[index - 1] : null;
    final next = index + 1 < chips.length ? chips[index + 1] : null;
    return FocusableFilterChip(
      key: chip.anchorKey,
      focusNode: chip.focusNode,
      icon: chip.icon,
      label: chip.label,
      onPressed: chip.onPressed,
      onNavigateDown: chip.onNavigateDown ?? onNavigateDown,
      onNavigateUp: chip.onNavigateUp ?? onNavigateUp,
      onNavigateLeft: chip.onNavigateLeft ?? previous?.focusNode.requestFocus ?? onNavigateLeftEdge,
      onNavigateRight: chip.onNavigateRight ?? next?.focusNode.requestFocus,
      onBack: chip.onBack ?? onBack,
    );
  }
}

/// SliverPersistentHeader delegate hosting an [OptionsChipsBar] (or any
/// fixed-height chrome) as a floating header that scrolls off with content
/// and snaps back into view on upward direction reversal.
class OptionsChipsBarDelegate extends SliverPersistentHeaderDelegate {
  /// Builds the bar content on every header build.
  final WidgetBuilder builder;

  /// Fixed bar height; defaults to [optionsChipsBarHeight].
  final double height;

  const OptionsChipsBarDelegate({required this.builder, this.height = optionsChipsBarHeight});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: builder(context));
  }

  @override
  bool shouldRebuild(covariant OptionsChipsBarDelegate oldDelegate) =>
      builder != oldDelegate.builder || height != oldDelegate.height;
}
