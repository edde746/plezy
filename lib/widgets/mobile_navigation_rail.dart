import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../navigation/navigation_tabs.dart';
import 'app_icon.dart';

/// The mobile shell's navigation in landscape: the bottom [NavigationBar]'s
/// destinations on a leading Material [NavigationRail], so a wide, short
/// viewport keeps its height for content. Deliberately not the desktop/TV
/// sidebar — it carries no libraries, no expansion, no focus choreography.
///
/// Mirrors the bottom bar's extras: the offline reconnect affordance (as the
/// rail's leading action) and the long-press library quick picker on the
/// Libraries destination.
class MobileNavigationRail extends StatelessWidget {
  const MobileNavigationRail({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.showLabels,
    required this.onDestinationSelected,
    this.onLibrariesLongPress,
    this.isOffline = false,
    this.isReconnecting = false,
    this.onReconnect,
  });

  final List<NavigationTab> tabs;
  final NavigationTabId selectedTab;
  final bool showLabels;
  final ValueChanged<NavigationTabId> onDestinationSelected;
  final VoidCallback? onLibrariesLongPress;
  final bool isOffline;
  final bool isReconnecting;
  final VoidCallback? onReconnect;

  /// Material 3 rail indicator size; the long-press target matches it so the
  /// hold works anywhere on the visible pill, not only on the glyph.
  static const Size _indicatorSize = Size(56, 32);

  /// Material 3 labelled-destination extent (indicator, label, spacing) and
  /// the leading action's extent, used to decide whether labels fit.
  /// Estimates: the scroll view below is the exact fallback.
  static const double _labelledExtent = 72;
  static const double _leadingExtent = 56;

  /// Whether every destination fits at once with labels on a rail of
  /// [height]: a phone in landscape has ~410dp, six labelled destinations
  /// need more, so labels give way before anything has to scroll.
  @visibleForTesting
  static bool labelsFit({required int destinations, required bool hasLeading, required double height}) {
    final needed = destinations * _labelledExtent + (hasLeading ? _leadingExtent : 0);
    return needed <= height;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = tabs.indexWhere((tab) => tab.id == selectedTab);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final labelled = showLabels && labelsFit(destinations: tabs.length, hasLeading: isOffline, height: height);
        final rail = NavigationRail(
          selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
          onDestinationSelected: (index) => onDestinationSelected(tabs[index].id),
          labelType: labelled ? NavigationRailLabelType.all : NavigationRailLabelType.none,
          groupAlignment: 0,
          leading: isOffline ? _reconnectAction(context) : null,
          destinations: [for (final tab in tabs) _destination(context, tab)],
        );
        // NavigationRail needs a bounded height. Give it at least the viewport
        // and let it grow past that inside a scroll view when even icon-only
        // destinations cannot fit (seven tabs plus reconnect on a small phone).
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: IntrinsicHeight(child: rail),
          ),
        );
      },
    );
  }

  Widget _reconnectAction(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        tooltip: t.common.reconnect,
        onPressed: isReconnecting ? null : onReconnect,
        icon: isReconnecting
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
            : AppIcon(Symbols.wifi_rounded, size: 18, color: primary),
      ),
    );
  }

  NavigationRailDestination _destination(BuildContext context, NavigationTab tab) {
    Widget icon = AppIcon(tab.icon, fill: 1);
    final onLongPress = onLibrariesLongPress;
    if (tab.id == NavigationTabId.libraries && onLongPress != null) {
      // Only a long-press recogniser: taps fall through to the rail's own
      // destination handling, exactly like the bottom bar's overlay.
      icon = GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onLongPress: () {
          Feedback.forLongPress(context);
          onLongPress();
        },
        child: SizedBox.fromSize(
          size: _indicatorSize,
          child: Center(child: icon),
        ),
      );
    }
    return NavigationRailDestination(icon: icon, label: Text(tab.getLabel()));
  }
}
