import 'package:flutter/material.dart';

/// Tracks the currently mounted profile-scoped navigator and main
/// ScaffoldMessenger without making their GlobalKeys app-lifetime widgets.
///
/// The keys are created inside the profile session and registered here only so
/// app-global helpers (mouse back, background snackbars) can reach the active
/// profile surface. A profile switch unregisters the old keys before the new
/// session registers fresh ones.
class ProfileNavigationRegistry {
  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _mainScaffoldMessengerKey;

  NavigatorState? get navigator => _navigatorKey?.currentState;
  ScaffoldMessengerState? get mainScaffoldMessenger => _mainScaffoldMessengerKey?.currentState;

  void attachNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void detachNavigator(GlobalKey<NavigatorState> key) {
    if (identical(_navigatorKey, key)) {
      _navigatorKey = null;
    }
  }

  void attachMainScaffoldMessenger(GlobalKey<ScaffoldMessengerState> key) {
    _mainScaffoldMessengerKey = key;
  }

  void detachMainScaffoldMessenger(GlobalKey<ScaffoldMessengerState> key) {
    if (identical(_mainScaffoldMessengerKey, key)) {
      _mainScaffoldMessengerKey = null;
    }
  }

  Future<bool> maybePopProfileRoute() async {
    final state = navigator;
    if (state == null) return false;
    return state.maybePop();
  }
}

final profileNavigationRegistry = ProfileNavigationRegistry();

class ProfileNavigationScope extends InheritedWidget {
  const ProfileNavigationScope({
    super.key,
    required this.navigatorKey,
    required this.routeObserver,
    required this.mainScaffoldMessengerKey,
    required super.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final RouteObserver<PageRoute<dynamic>> routeObserver;
  final GlobalKey<ScaffoldMessengerState> mainScaffoldMessengerKey;

  static ProfileNavigationScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileNavigationScope>();
    if (scope == null) {
      throw StateError('ProfileNavigationScope is required for profile routes.');
    }
    return scope;
  }

  static ProfileNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProfileNavigationScope>();
  }

  @override
  bool updateShouldNotify(ProfileNavigationScope oldWidget) {
    return navigatorKey != oldWidget.navigatorKey ||
        routeObserver != oldWidget.routeObserver ||
        mainScaffoldMessengerKey != oldWidget.mainScaffoldMessengerKey;
  }
}
