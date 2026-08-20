import 'package:flutter/widgets.dart';

/// Whether [context]'s enclosing route is the app's top visible route.
///
/// `ModalRoute.of(context).isCurrent` only answers for the route's own
/// navigator. With nested navigators that is not "nothing is on top": a route
/// pushed on an ancestor navigator — e.g. the root-navigator profile picker
/// over the nested profile-session navigator (#2034) — covers this route
/// while its own `isCurrent` stays true. Walks the hosting route of each
/// enclosing navigator up to the root, so any route stacked above [context]'s
/// route on any navigator makes this false.
bool isRouteChainCurrent(BuildContext context) {
  ModalRoute<Object?>? route = ModalRoute.of(context);
  while (route != null) {
    if (!route.isCurrent) return false;
    final navigator = route.navigator;
    if (navigator == null) break;
    route = ModalRoute.of(navigator.context);
  }
  return true;
}
