import 'package:flutter/material.dart';
import 'package:vibe_stream/navigation/profile_navigation_scope.dart';

Widget withProfileNavigationScope({required Widget child}) {
  return ProfileNavigationScope(
    navigatorKey: GlobalKey<NavigatorState>(),
    routeObserver: RouteObserver<PageRoute<dynamic>>(),
    mainScaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
    child: child,
  );
}
