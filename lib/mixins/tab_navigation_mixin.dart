import 'package:flutter/material.dart';
import '../services/gamepad_service.dart';
import '../screens/main_screen.dart';

/// Mixin that provides common tab navigation infrastructure.
///
/// Handles:
/// - [TabController] creation and disposal
/// - L1/R1 gamepad registration for tab switching
/// - [suppressAutoFocus] flag management
/// - Tab chip focus node lookup
/// - Tab bar back navigation to sidebar
///
/// Subclasses must provide [tabChipFocusNodes] — one [FocusNode] per tab.
mixin TabNavigationMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late TabController tabController;

  /// When true, suppress auto-focus in tabs (used when navigating via tab bar).
  bool suppressAutoFocus = false;

  /// Subclasses provide focus nodes as a list indexed by tab position.
  List<FocusNode> get tabChipFocusNodes;

  /// Number of tabs — derived from [tabChipFocusNodes].
  int get tabCount => tabChipFocusNodes.length;

  /// Initialise the [TabController] and register gamepad callbacks.
  /// Call from [initState].
  void initTabNavigation() {
    tabController = TabController(length: tabCount, vsync: this);
    tabController.addListener(onTabChanged);
    GamepadService.onL1Pressed = goToPreviousTab;
    GamepadService.onR1Pressed = goToNextTab;
  }

  /// Dispose the [TabController] and clear gamepad callbacks.
  /// Call from [dispose].
  void disposeTabNavigation() {
    tabController.removeListener(onTabChanged);
    tabController.dispose();
    GamepadService.onL1Pressed = null;
    GamepadService.onR1Pressed = null;
  }

  void goToPreviousTab() {
    if (tabController.index > 0) {
      setState(() {
        suppressAutoFocus = true;
        tabController.index = tabController.index - 1;
      });
      getTabChipFocusNode(tabController.index).requestFocus();
    }
  }

  void goToNextTab() {
    if (tabController.index < tabController.length - 1) {
      setState(() {
        suppressAutoFocus = true;
        tabController.index = tabController.index + 1;
      });
      getTabChipFocusNode(tabController.index).requestFocus();
    }
  }

  /// Called when the tab index changes. Override to add custom behaviour
  /// (e.g. persisting the tab index), then call `super.onTabChanged()`.
  void onTabChanged() {
    // ignore: no-empty-block - setState triggers rebuild to reflect new tab
    setState(() {});
  }

  FocusNode getTabChipFocusNode(int index) => tabChipFocusNodes[index];

  /// Focus the currently selected tab chip.
  void focusTabBar() {
    setState(() {
      suppressAutoFocus = true;
    });
    getTabChipFocusNode(tabController.index).requestFocus();
  }

  /// Navigate back from the tab bar to the sidebar.
  void onTabBarBack() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }
}
