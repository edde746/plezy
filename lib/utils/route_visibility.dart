import 'package:flutter/widgets.dart';

/// Returns true when no route in the nested navigator chain covers [context].
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
