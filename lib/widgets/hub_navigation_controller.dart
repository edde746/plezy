import 'package:flutter/material.dart';

/// Controller that manages navigation between hub sections.
/// Hub sections register themselves, and MediaCards can request
/// to navigate to adjacent hub sections.
class HubNavigationController extends ChangeNotifier {
  final List<HubSectionRegistration> _registrations = [];

  /// Map of hub ID to last focused item index
  final Map<String, int> _focusMemory = {};

  /// Register a hub section with the controller
  /// If a hub with the same ID is already registered, it will be replaced
  /// Registrations are kept sorted by order for consistent navigation
  void register(HubSectionRegistration registration) {
    // Remove any existing registration with the same hubId
    _registrations.removeWhere((r) => r.hubId == registration.hubId);
    _registrations.add(registration);
    // Sort by order to maintain consistent navigation regardless of registration timing
    _registrations.sort((a, b) => a.order.compareTo(b.order));
  }

  /// Unregister a hub section
  void unregister(String hubId) {
    _registrations.removeWhere((r) => r.hubId == hubId);
    _focusMemory.remove(hubId);
  }

  /// Remember the focused item index for a hub
  void rememberFocusedIndex(String hubId, int index) {
    _focusMemory[hubId] = index;
  }

  /// Get the remembered focused index for a hub (or 0 if none)
  int getRememberedIndex(String hubId) {
    return _focusMemory[hubId] ?? 0;
  }

  /// Navigate to the next hub section (direction: 1 for down, -1 for up)
  /// Returns true if navigation was handled
  bool navigateToAdjacentHub(String currentHubId, int direction) {
    final currentIndex = _registrations.indexWhere(
      (r) => r.hubId == currentHubId,
    );
    if (currentIndex == -1) return false;

    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= _registrations.length) return false;

    final targetHub = _registrations[targetIndex];
    if (targetHub.itemCount == 0) {
      // Nothing to focus in the target hub
      return false;
    }
    final rememberedIndex = getRememberedIndex(targetHub.hubId);

    // Focus the remembered item or first item
    targetHub.focusItem(rememberedIndex.clamp(0, targetHub.itemCount - 1));
    return true;
  }

  /// Focus a specific hub and item by order index
  /// [hubIndex] is the index in the sorted list (0 = first hub)
  /// [itemIndex] is the item within that hub (0 = first item)
  void focusHub(int hubIndex, int itemIndex) {
    if (hubIndex < 0 || hubIndex >= _registrations.length) return;

    final hub = _registrations[hubIndex];
    if (hub.itemCount > 0) {
      hub.focusItem(itemIndex.clamp(0, hub.itemCount - 1));
    }
  }
}

/// Registration info for a hub section
class HubSectionRegistration {
  final String hubId;
  final int itemCount;
  final int order; // Visual order on screen (lower = higher on screen)
  final void Function(int index) focusItem;

  HubSectionRegistration({
    required this.hubId,
    required this.itemCount,
    required this.focusItem,
    this.order = 1000, // Default high order for dynamic hubs
  });
}

/// InheritedWidget to provide the HubNavigationController down the tree
class HubNavigationScope extends InheritedWidget {
  final HubNavigationController controller;

  const HubNavigationScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static HubNavigationController? of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HubNavigationScope>();
    return scope?.controller;
  }

  static HubNavigationController? maybeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<HubNavigationScope>();
    return scope?.controller;
  }

  @override
  bool updateShouldNotify(HubNavigationScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
